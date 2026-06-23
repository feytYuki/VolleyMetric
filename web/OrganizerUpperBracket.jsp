<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="Model.*, DAO.*, java.util.*" %>
<%
    String username = (String) session.getAttribute("organizerUsername");
    String fullname = (String) session.getAttribute("organizerFullname");
    Integer organizerId = (Integer) session.getAttribute("organizerId");

    if (username == null) {
        response.sendRedirect("OrganizerLogin.jsp");
        return;
    }

    String idParam = request.getParameter("id");
    if (idParam == null) {
        response.sendRedirect("OrganizerTournament.jsp");
        return;
    }

    int tId = Integer.parseInt(idParam);
    Tournament tournament = new TournamentDAO().getTournamentById(tId);
    if (tournament == null) {
        response.sendRedirect("OrganizerSchedule.jsp");
        return;
    }

    MatchDAO matchDAO = new MatchDAO();
    matchDAO.cleanDuplicateRRMatches(tId);

    List<Match> bracketMatches = matchDAO.getMatchesByTournamentAndType(tId, "bracket");
    List<Match> rrMatches = matchDAO.getRRMatches(tId);
    int rrTotal = rrMatches.size();
    int rrDone = 0;
    for (Match m : rrMatches) {
        if (m.getWinnerId() != null) {
            rrDone++;
        }
    }
    boolean rrInProgress = rrTotal > 0 && rrDone < rrTotal;
    TeamRegistrationDAO teamRegDAO = new TeamRegistrationDAO();

    Map<String, Match> bMap = new HashMap<>();
    for (Match m : bracketMatches) {
        bMap.put(m.getGroupName(), m);
    }

    // Self-heal #1: SF1+SF2 exist but Final row missing → create placeholder
    if (bMap.containsKey("SF1") && bMap.containsKey("SF2") && !bMap.containsKey("Final")) {
        matchDAO.createBracketMatch(tId, 0, 0, "Final");
        bracketMatches = matchDAO.getMatchesByTournamentAndType(tId, "bracket");
        bMap.clear();
        for (Match m : bracketMatches) {
            bMap.put(m.getGroupName(), m);
        }
    }

    // Self-heal #2: If both SF winners are known but Final teams aren't seeded yet,
    // wipe any stale/empty Final rows and create a clean one with the correct team IDs.
    {
        Match _sf1 = bMap.get("SF1");
        Match _sf2 = bMap.get("SF2");
        if (_sf1 != null && _sf1.getWinnerId() != null
                && _sf2 != null && _sf2.getWinnerId() != null) {
            Match _final = bMap.get("Final");
            boolean finalMissing = (_final == null);
            boolean finalNotReady = (_final != null && _final.getWinnerId() == null
                    && (_final.getTeam1Id() <= 0 || _final.getTeam2Id() <= 0));
            if (finalMissing || finalNotReady) {
                // Delete ALL empty Final rows for this tournament, then create a correct one
                matchDAO.deleteMatchesByTournamentAndStages(tId, new String[]{"Final"});
                matchDAO.createBracketMatch(tId, _sf1.getWinnerId(), _sf2.getWinnerId(), "Final");
                bracketMatches = matchDAO.getMatchesByTournamentAndType(tId, "bracket");
                bMap.clear();
                for (Match m : bracketMatches) {
                    bMap.put(m.getGroupName(), m);
                }
            }
        }
    }

    // allMatchesCompleted = true ONLY when the Final match has a winner
    boolean allMatchesCompleted = false;
    Match finalCheck = bMap.get("Final");
    if (finalCheck != null && finalCheck.getWinnerId() != null) {
        allMatchesCompleted = true;
    }

    // allSFsCompleted = true when all SF matches (and QF if present) are done, Final not yet started
    boolean allSFsCompleted = false;
    boolean finalPending = (finalCheck == null || finalCheck.getWinnerId() == null);
    if (finalPending && bMap.containsKey("SF1") && bMap.containsKey("SF2")) {
        Match sf1check = bMap.get("SF1");
        Match sf2check = bMap.get("SF2");
        allSFsCompleted = (sf1check != null && sf1check.getWinnerId() != null)
                && (sf2check != null && sf2check.getWinnerId() != null);
    } else if (finalPending && !bMap.containsKey("SF1") && !bMap.containsKey("SF2")) {
        // Only QFs or direct bracket — check if all non-Final matches done
        boolean nonFinalDone = true;
        for (Match m : bracketMatches) {
            if (!"Final".equals(m.getGroupName()) && m.getWinnerId() == null) {
                nonFinalDone = false;
                break;
            }
        }
        allSFsCompleted = nonFinalDone && !bracketMatches.isEmpty();
    }

    // Determine bracket shape
    boolean hasQF = bMap.containsKey("QF1");
    boolean hasSF = bMap.containsKey("SF1");
    boolean hasFinal = bMap.containsKey("Final");

    // Group-stage data for the flow diagram
    List<Match> groupAMatches = new ArrayList<>();
    List<Match> groupBMatches = new ArrayList<>();
    List<Match> allGroupMatches = matchDAO.getMatchesByTournamentAndType(tId, "group");
    for (Match m : allGroupMatches) {
        if ("A".equals(m.getGroupName())) {
            groupAMatches.add(m);
        } else if ("B".equals(m.getGroupName())) {
            groupBMatches.add(m);
        }
    }
    boolean hasGroups = !groupAMatches.isEmpty() || !groupBMatches.isEmpty();
%>
<%!
    public String getTeamName(int teamId, TeamRegistrationDAO dao) {
        if (teamId <= 0) {
            return "TBD";
        }
        TeamRegistration t = dao.getRegistrationById(teamId);
        return (t != null) ? t.getTeamName() : "Unknown";
    }

    public String winnerName(Match m, TeamRegistrationDAO dao) {
        if (m == null || m.getWinnerId() == null) {
            return "TBD";
        }
        return dao.getRegistrationById(m.getWinnerId()) != null
                ? dao.getRegistrationById(m.getWinnerId()).getTeamName() : "TBD";
    }
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>Elimination Stage - VolleyMetric</title>
        <link rel="stylesheet" href="style.css">
        <style>
            /* ── Page base ── */
            .elim-section {
                padding: 3rem 0 5rem;
                background: #f4f6fb;
                min-height: 100vh;
            }
            .page-title {
                text-align:center;
                font-size:2.2rem;
                font-weight:800;
                color:#1a1a2e;
                margin-bottom:.4rem;
            }
            .page-subtitle {
                text-align:center;
                color:#888;
                font-size:1rem;
                margin-bottom:2.5rem;
            }

            /* ── Alert ── */
            .alert {
                padding:1rem 1.5rem;
                border-radius:12px;
                margin:0 auto 1.5rem;
                font-weight:600;
                max-width:900px;
                box-shadow:0 4px 12px rgba(0,0,0,.08);
            }
            .alert-success {
                background:linear-gradient(135deg,#d4edda,#c3e6cb);
                border:2px solid #28a745;
                color:#155724;
            }
            .alert-error   {
                background:linear-gradient(135deg,#f8d7da,#f5c6cb);
                border:2px solid #dc3545;
                color:#721c24;
            }

            /* ══════════════════════════════════════
               BRACKET FLOW DIAGRAM
            ══════════════════════════════════════ */
            .flow-wrapper {
                max-width:900px;
                margin:0 auto 3rem;
                padding:0 1rem;
            }
            .flow-title {
                font-size:1.1rem;
                font-weight:700;
                color:#444;
                text-align:center;
                margin-bottom:1.5rem;
                letter-spacing:.04em;
                text-transform:uppercase;
            }

            .flow-grid {
                display: grid;
                grid-template-columns: repeat(4, 1fr);
                gap: 0;
                align-items: start;
            }
            /* For SF-only (2 groups): 3 cols */
            .flow-grid.sf-only {
                grid-template-columns: 1fr 1fr 1fr;
            }
            /* For QF (4 groups): 4 cols already */

            .flow-col {
                display:flex;
                flex-direction:column;
                align-items:center;
                gap:0;
            }

            /* Round label above each column */
            .round-label {
                font-size:.72rem;
                font-weight:700;
                letter-spacing:.08em;
                text-transform:uppercase;
                color:#aaa;
                margin-bottom:.6rem;
                text-align:center;
            }

            /* Node cards */
            .flow-node {
                width:130px;
                border-radius:10px;
                padding:.6rem .8rem;
                font-size:.82rem;
                font-weight:700;
                text-align:center;
                box-shadow:0 2px 8px rgba(0,0,0,.12);
                position:relative;
            }
            .node-group  {
                background:#2a9d8f;
                color:#fff;
            }
            .node-qf     {
                background:#e9852a;
                color:#fff;
            }
            .node-sf     {
                background:#c0392b;
                color:#fff;
            }
            .node-final  {
                background:#4a4ae8;
                color:#fff;
                width:150px;
            }
            .node-champion {
                background:linear-gradient(135deg,#f7c948,#f5a623);
                color:#fff;
                width:150px;
                font-size:.9rem;
                border:2px solid #e6971a;
            }
            .node-tbd    {
                opacity:.55;
            }

            .node-sub {
                font-size:.72rem;
                font-weight:400;
                margin-top:.2rem;
                opacity:.85;
            }

            /* Connector arrows between columns */
            .flow-arrow {
                display:flex;
                align-items:center;
                justify-content:center;
                height:100%;
                padding-top:2.4rem; /* align with first node */
            }
            .flow-arrow svg {
                width:32px;
                height:24px;
            }

            /* Vertical spacers so nodes align with their match row */
            .flow-spacer {
                height:2rem;
            }

            /* ══════════════════════════════════════
               MATCH CARDS
            ══════════════════════════════════════ */
            .matches-section {
                max-width:900px;
                margin:0 auto;
                padding:0 1rem;
            }
            .section-heading {
                font-size:1.4rem;
                font-weight:800;
                color:#333;
                margin-bottom:1.5rem;
                text-align:center;
            }

            .match-card {
                background:#fff;
                border-radius:20px;
                padding:2rem;
                box-shadow:0 6px 24px rgba(0,0,0,.08);
                margin-bottom:1.5rem;
                transition:box-shadow .2s;
            }
            .match-card:hover {
                box-shadow:0 10px 36px rgba(0,0,0,.13);
            }

            .match-header {
                display:flex;
                justify-content:space-between;
                align-items:center;
                margin-bottom:1.5rem;
                padding-bottom:1rem;
                border-bottom:2px solid #f0f0f0;
            }
            .match-stage-badge {
                font-size:1.1rem;
                font-weight:800;
                background:linear-gradient(135deg,#667eea,#764ba2);
                -webkit-background-clip:text;
                -webkit-text-fill-color:transparent;
            }
            .status-pill {
                padding:.35rem .9rem;
                border-radius:50px;
                font-size:.78rem;
                font-weight:700;
            }
            .status-completed {
                background:#28a745;
                color:#fff;
            }
            .status-pending   {
                background:#ffc107;
                color:#fff;
            }
            .status-waiting   {
                background:#aaa;
                color:#fff;
            }

            .match-teams {
                display:grid;
                grid-template-columns:1fr auto 1fr;
                gap:1.5rem;
                align-items:center;
                margin-bottom:1.5rem;
            }
            .team-box {
                padding:1.2rem;
                border:2px solid #e0e0e0;
                border-radius:12px;
                font-weight:700;
                font-size:1.05rem;
                text-align:center;
                background:#fafafa;
                transition:all .2s;
            }
            .team-box.winner {
                border-color:#28a745;
                background:linear-gradient(135deg,#d4edda,#c3e6cb);
                box-shadow:0 4px 12px rgba(40,167,69,.15);
            }
            .vs-text {
                font-size:1.3rem;
                font-weight:800;
                color:#bbb;
                width:52px;
                height:52px;
                border-radius:50%;
                display:flex;
                align-items:center;
                justify-content:center;
                border:2px solid #e0e0e0;
                background:#f8f9fa;
            }

            .winner-selection {
                margin:1rem 0;
                text-align:center;
            }
            .winner-selection > strong {
                display:block;
                margin-bottom:.8rem;
                color:#2c3e50;
                font-size:1rem;
            }
            .winner-buttons {
                display:grid;
                grid-template-columns:1fr 1fr;
                gap:1rem;
            }
            .btn-select-winner {
                padding:1rem;
                border:2px solid #667eea;
                background:#fff;
                color:#667eea;
                border-radius:12px;
                font-weight:700;
                cursor:pointer;
                transition:all .2s;
            }
            .btn-select-winner:hover {
                background:#f0f4ff;
                transform:translateY(-2px);
            }
            .btn-select-winner.selected {
                background:linear-gradient(135deg,#667eea,#764ba2);
                color:#fff;
                border-color:#667eea;
            }

            .sets-input {
                margin-top:1.2rem;
                padding:1.5rem;
                background:#f8f9fa;
                border-radius:12px;
                border:2px solid #e9ecef;
            }
            .sets-input > strong {
                display:block;
                margin-bottom:1rem;
                color:#2c3e50;
                text-align:center;
            }
            .set-row {
                display:grid;
                grid-template-columns:1fr auto 1fr;
                gap:1.5rem;
                align-items:center;
                margin-bottom:.7rem;
                background:#fff;
                padding:.8rem;
                border-radius:10px;
                box-shadow:0 1px 4px rgba(0,0,0,.05);
            }
            .set-label {
                background:linear-gradient(135deg,#667eea,#764ba2);
                color:#fff;
                padding:.35rem 1.2rem;
                border-radius:50px;
                font-size:.85rem;
                font-weight:700;
                text-align:center;
                min-width:80px;
            }
            .score-input {
                width:100%;
                max-width:72px;
                padding:.7rem;
                border:2px solid #dee2e6;
                border-radius:10px;
                text-align:center;
                font-weight:700;
                font-size:1.2rem;
                background:#fafafa;
                margin:0 auto;
                display:block;
            }
            .score-input:focus {
                outline:none;
                border-color:#667eea;
            }

            .btn-save {
                background:linear-gradient(135deg,#667eea,#764ba2);
                color:#fff;
                padding:1rem 2.5rem;
                border:none;
                border-radius:50px;
                font-weight:700;
                font-size:1rem;
                cursor:pointer;
                width:100%;
                margin-top:1.2rem;
                transition:all .2s;
            }
            .btn-save:hover {
                transform:translateY(-2px);
                box-shadow:0 6px 20px rgba(102,126,234,.35);
            }

            /* Waiting state */
            .waiting-msg {
                text-align:center;
                color:#aaa;
                font-style:italic;
                padding:1.5rem;
            }

            /* Conclude button */
            .conclude-wrap {
                text-align:center;
                margin-top:3rem;
            }
            .btn-conclude {
                background:linear-gradient(135deg,#28a745,#20c997);
                color:#fff;
                padding:1.2rem 3.5rem;
                border:none;
                border-radius:50px;
                font-weight:700;
                font-size:1.1rem;
                cursor:pointer;
                transition:all .2s;
                box-shadow:0 4px 15px rgba(40,167,69,.3);
            }
            .btn-conclude:hover {
                transform:translateY(-3px);
                box-shadow:0 8px 24px rgba(40,167,69,.4);
            }

            /* Champion banner */
            .champion-banner {
                max-width:500px;
                margin:0 auto 2rem;
                background:linear-gradient(135deg,#f7c948,#f5a623);
                border-radius:20px;
                padding:2rem;
                text-align:center;
                box-shadow:0 8px 30px rgba(245,166,35,.3);
                color:#fff;
            }
            .champion-banner .trophy {
                font-size:3rem;
                display:block;
                margin-bottom:.5rem;
            }
            .champion-banner h2 {
                font-size:1.8rem;
                font-weight:800;
                margin:0 0 .3rem;
            }
            .champion-banner p  {
                font-size:1.1rem;
                margin:0;
                opacity:.9;
            }

            /* Empty state */
            .empty-state {
                text-align:center;
                padding:3rem;
                background:#fff;
                border-radius:20px;
                box-shadow:0 6px 24px rgba(0,0,0,.08);
                max-width:600px;
                margin:0 auto;
            }

            /* User-info header helpers */
            .user-info {
                display:flex;
                align-items:center;
                gap:1rem;
            }
            .user-details {
                display:flex;
                flex-direction:column;
                align-items:flex-end;
                background:#fff;
                border:2px solid #764ba2;
                border-radius:5px;
                padding:4px 10px;
            }
            .user-role-label {
                font-size:.8rem;
                font-weight:600;
                color:#764ba2;
                margin:0;
            }
            .user-name {
                font-size:.95rem;
                font-weight:600;
                color:#000;
                margin:0;
            }
            .btn-logout {
                background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);
                color:#fff;
                padding:.6rem 1.5rem;
                text-decoration:none;
                border-radius:5px;
                font-weight:600;
                border:none;
                cursor:pointer;
            }

            /* Next match banner */
            .next-match-banner {
                max-width:600px;
                margin:0 auto 1.5rem;
                padding:1.5rem;
                background:linear-gradient(135deg,#667eea22,#764ba222);
                border:2px solid #667eea;
                border-radius:16px;
                text-align:center;
            }
            .next-match-title {
                font-size:1.4rem;
                font-weight:800;
                color:#4a4ae8;
                margin-bottom:.4rem;
            }
            .next-match-sub   {
                color:#666;
                margin:0;
                font-size:.95rem;
            }

            .btn-show-final {
                margin-top:1.2rem;
                background:linear-gradient(135deg,#4a4ae8,#764ba2);
                color:#fff;
                border:none;
                border-radius:50px;
                padding:.9rem 2.5rem;
                font-size:1rem;
                font-weight:700;
                cursor:pointer;
                transition:all .2s;
                box-shadow:0 4px 15px rgba(74,74,232,.3);
            }
            .btn-show-final:hover {
                transform:translateY(-2px);
                box-shadow:0 8px 24px rgba(74,74,232,.45);
            }

            /* Grand Final card shown below SFs */
            .final-match-card {
                max-width:700px;
                margin:0 auto;
                background:#fff;
                border-radius:20px;
                padding:2rem;
                box-shadow:0 8px 32px rgba(74,74,232,.15);
                border:2px solid #4a4ae8;
            }
            .final-match-header {
                font-size:1.2rem;
                font-weight:800;
                background:linear-gradient(135deg,#4a4ae8,#764ba2);
                -webkit-background-clip:text;
                -webkit-text-fill-color:transparent;
                text-align:center;
                margin-bottom:1.2rem;
                padding-bottom:1rem;
                border-bottom:2px solid #f0f0f0;
            }
            .final-match-teams {
                display:grid;
                grid-template-columns:1fr auto 1fr;
                gap:1.5rem;
                align-items:center;
                margin-bottom:1.5rem;
            }
            .final-team {
                padding:1.2rem;
                border:2px solid #4a4ae8;
                border-radius:12px;
                font-weight:700;
                font-size:1.1rem;
                text-align:center;
                background:linear-gradient(135deg,#f0f4ff,#e8ecff);
            }
            .final-vs {
                font-size:1.3rem;
                font-weight:800;
                color:#4a4ae8;
                width:52px;
                height:52px;
                border-radius:50%;
                display:flex;
                align-items:center;
                justify-content:center;
                border:2px solid #4a4ae8;
                background:#fff;
            }

            /* Responsive */
            @media(max-width:640px){
                .flow-grid, .flow-grid.sf-only {
                    grid-template-columns:1fr;
                }
                .flow-arrow {
                    display:none;
                }
            }
        </style>
    </head>
    <body>
        <header class="header">
            <div class="container">
                <div class="logo">
                    <div style="width:40px;height:40px;overflow:hidden;background:#fff;border:2px solid red;">
                        <img src="umtlogo.png" alt="UMT Logo" style="width:100%;height:100%;object-fit:contain;">
                    </div>
                    <span class="logo-icon">🏐</span>
                    <span class="logo-text">VolleyMetric</span>
                </div>
                <nav class="nav">
                    <ul class="nav-list">
                        <li><a href="OrganizerHome.jsp" class="nav-link">Home</a></li>
                        <li><a href="OrganizerTournament.jsp" class="nav-link">Tournaments</a></li>
                        <li><a href="OrganizerSchedule.jsp" class="nav-link active">Schedule</a></li>
                        <li><a href="OrganizerResult.jsp" class="nav-link">Results</a></li>
                        <li><a href="OrganizerReport.jsp" class="nav-link">Reports</a></li>
                    </ul>
                </nav>
                <div class="header-actions">
                    <div class="user-info">
                        <a href="OrganizerProfile.jsp" class="user-details" style="text-decoration: none; cursor: pointer;">
                            <span class="user-role-label">Organizer:</span>
                            <span class="user-name">🎯 <%= fullname != null ? fullname : username%></span>
                        </a>
                        <a href="LogOutServlet" class="btn-logout">Logout</a>
                    </div>
                </div>
            </div>
        </header>

        <section class="elim-section">
            <div class="container">
                <h1 class="page-title">🏆 <%= tournament.getTournamentName()%></h1>
                <p class="page-subtitle">Elimination Stage</p>

                <%
                    String successMsg = (String) session.getAttribute("successMessage");
                    String errorMsg = (String) session.getAttribute("errorMessage");
                    if (successMsg != null) {
                        session.removeAttribute("successMessage");%>
                <script>window.addEventListener('DOMContentLoaded', () => showToast('<%= successMsg.replace("'", "\\'")%>', 'success'));</script>
                <% }
                    if (errorMsg != null) {
                        session.removeAttribute("errorMessage");%>
                <script>window.addEventListener('DOMContentLoaded', () => showToast('<%= errorMsg.replace("'", "\\'")%>', 'error'));</script>
                <% } %>

                <%-- ══ CHAMPION BANNER (if tournament is done) ══ --%>
                <% if ("completed".equals(tournament.getStatus()) && hasFinal && bMap.get("Final").getWinnerId() != null) {%>
                <div class="champion-banner">
                    <span class="trophy">🥇</span>
                    <h2>Champion</h2>
                    <p><%= getTeamName(bMap.get("Final").getWinnerId(), teamRegDAO)%></p>
                </div>
                <% } %>

                <%-- ══ EMPTY STATES ══ --%>
                <% if (bracketMatches.isEmpty()) { %>
                <div class="empty-state">
                    <% if (rrInProgress) {%>
                    <h2 style="color:#e67e22;">⏳ Round-Robin In Progress</h2>
                    <p style="color:#888;margin:.5rem 0 1.5rem;">
                        <strong><%= rrDone%> / <%= rrTotal%></strong> matches completed.
                        Complete all matches on the schedule page first.
                    </p>
                    <a href="TournamentScheduleDetail.jsp?id=<%= tId%>"
                       style="background:linear-gradient(135deg,#667eea,#764ba2);color:#fff;
                       padding:1rem 2.5rem;border-radius:50px;text-decoration:none;font-weight:700;">
                        ← Back to Schedule
                    </a>
                    <% } else {%>
                    <h2 style="color:#666;">No bracket generated yet</h2>
                    <p style="color:#888;margin:.5rem 0 1.5rem;">All matches are complete. Click below to generate the elimination stage.</p>
                    <a href="GenerateBracketServlet?id=<%= tId%>"
                       style="background:linear-gradient(135deg,#28a745,#20c997);color:#fff;
                       padding:1rem 2.5rem;border-radius:50px;text-decoration:none;font-weight:700;">
                        ⚡ Generate Elimination Stage
                    </a>
                    <% } %>
                </div>

                <% } else { %>

                <%-- ══════════════════════════════════════
                     VISUAL FLOW DIAGRAM
                ═══════════════════════════════════════ --%>
                <div class="flow-wrapper">
                    <div class="flow-title">Bracket Flow</div>

                    <%-- Determine layout type --%>
                    <% if (hasQF) { %>
                    <%-- QF bracket: QF1+QF2 | SF1 | Final | SF2 | QF3+QF4 (symmetric) --%>
                    <%
                        Match qf1 = bMap.get("QF1"), qf2 = bMap.get("QF2"),
                                qf3 = bMap.get("QF3"), qf4 = bMap.get("QF4");
                        Match sf1qf = bMap.get("SF1"), sf2qf = bMap.get("SF2"), finalQF = bMap.get("Final");
                        String qf1t1 = qf1 != null && qf1.getTeam1Id() > 0 ? getTeamName(qf1.getTeam1Id(), teamRegDAO) : "TBD";
                        String qf1t2 = qf1 != null && qf1.getTeam2Id() > 0 ? getTeamName(qf1.getTeam2Id(), teamRegDAO) : "TBD";
                        String qf2t1 = qf2 != null && qf2.getTeam1Id() > 0 ? getTeamName(qf2.getTeam1Id(), teamRegDAO) : "TBD";
                        String qf2t2 = qf2 != null && qf2.getTeam2Id() > 0 ? getTeamName(qf2.getTeam2Id(), teamRegDAO) : "TBD";
                        String qf3t1 = qf3 != null && qf3.getTeam1Id() > 0 ? getTeamName(qf3.getTeam1Id(), teamRegDAO) : "TBD";
                        String qf3t2 = qf3 != null && qf3.getTeam2Id() > 0 ? getTeamName(qf3.getTeam2Id(), teamRegDAO) : "TBD";
                        String qf4t1 = qf4 != null && qf4.getTeam1Id() > 0 ? getTeamName(qf4.getTeam1Id(), teamRegDAO) : "TBD";
                        String qf4t2 = qf4 != null && qf4.getTeam2Id() > 0 ? getTeamName(qf4.getTeam2Id(), teamRegDAO) : "TBD";
                        String sf1qt1 = sf1qf != null && sf1qf.getTeam1Id() > 0 ? getTeamName(sf1qf.getTeam1Id(), teamRegDAO) : "TBD";
                        String sf1qt2 = sf1qf != null && sf1qf.getTeam2Id() > 0 ? getTeamName(sf1qf.getTeam2Id(), teamRegDAO) : "TBD";
                        String sf2qt1 = sf2qf != null && sf2qf.getTeam1Id() > 0 ? getTeamName(sf2qf.getTeam1Id(), teamRegDAO) : "TBD";
                        String sf2qt2 = sf2qf != null && sf2qf.getTeam2Id() > 0 ? getTeamName(sf2qf.getTeam2Id(), teamRegDAO) : "TBD";
                        String fqt1 = finalQF != null && finalQF.getTeam1Id() > 0 ? getTeamName(finalQF.getTeam1Id(), teamRegDAO) : "TBD";
                        String fqt2 = finalQF != null && finalQF.getTeam2Id() > 0 ? getTeamName(finalQF.getTeam2Id(), teamRegDAO) : "TBD";
                    %>

                    <%-- Column labels --%>
                    <div style="display:flex; justify-content:center; align-items:flex-end; margin-bottom:.6rem; gap:0;">
                        <div class="bracket-label" style="width:150px;">Quarterfinals</div>
                        <div style="width:55px;"></div>
                        <div class="bracket-label" style="width:150px;">Semifinals</div>
                        <div style="width:55px;"></div>
                        <div class="bracket-label" style="width:160px;">Grand Final</div>
                        <div style="width:55px;"></div>
                        <div class="bracket-label" style="width:150px;">Semifinals</div>
                        <div style="width:55px;"></div>
                        <div class="bracket-label" style="width:150px;">Quarterfinals</div>
                    </div>

                    <div class="bracket-layout" style="align-items:center;">

                        <%-- Far Left: QF1 + QF2 stacked --%>
                        <div class="bracket-sf-col" style="gap:20px;">
                            <div class="bracket-sf-box">
                                <div class="sf-header" style="background:#e9852a;">QF 1</div>
                                <div class="sf-team"><%= qf1t1%></div>
                                <div class="sf-team"><%= qf1t2%></div>
                            </div>
                            <div class="bracket-sf-box">
                                <div class="sf-header" style="background:#e9852a;">QF 2</div>
                                <div class="sf-team"><%= qf2t1%></div>
                                <div class="sf-team"><%= qf2t2%></div>
                            </div>
                        </div>

                        <%-- QF1+QF2 → SF1 connector --%>
                        <svg width="55" height="130" style="overflow:visible; flex-shrink:0;">
                        <line x1="0" y1="32"  x2="27" y2="32"  stroke="#ccc" stroke-width="2"/>
                        <line x1="0" y1="98"  x2="27" y2="98"  stroke="#ccc" stroke-width="2"/>
                        <line x1="27" y1="32" x2="27" y2="98"  stroke="#ccc" stroke-width="2"/>
                        <line x1="27" y1="65" x2="55" y2="65"  stroke="#ccc" stroke-width="2"/>
                        </svg>

                        <%-- SF1 --%>
                        <div class="bracket-sf-col">
                            <div class="bracket-sf-box">
                                <div class="sf-header">SEMIFINAL 1</div>
                                <div class="sf-team"><%= sf1qt1%></div>
                                <div class="sf-team"><%= sf1qt2%></div>
                            </div>
                        </div>

                        <%-- SF1 → Final connector --%>
                        <svg width="55" height="100" style="overflow:visible; flex-shrink:0;">
                        <line x1="0" y1="50" x2="55" y2="50" stroke="#ccc" stroke-width="2"/>
                        <polygon points="47,45 55,50 47,55" fill="#aaa"/>
                        </svg>

                        <%-- Center: Final --%>
                        <div class="bracket-final-col">
                            <div class="bracket-final-box">
                                <div class="final-header">FINAL</div>
                                <div class="final-team"><%= fqt1%></div>
                                <div class="final-team"><%= fqt2%></div>
                            </div>
                        </div>

                        <%-- Final → SF2 connector --%>
                        <svg width="55" height="100" style="overflow:visible; flex-shrink:0;">
                        <line x1="0" y1="50" x2="55" y2="50" stroke="#ccc" stroke-width="2"/>
                        <polygon points="8,45 0,50 8,55" fill="#aaa"/>
                        </svg>

                        <%-- SF2 --%>
                        <div class="bracket-sf-col">
                            <div class="bracket-sf-box">
                                <div class="sf-header">SEMIFINAL 2</div>
                                <div class="sf-team"><%= sf2qt1%></div>
                                <div class="sf-team"><%= sf2qt2%></div>
                            </div>
                        </div>

                        <%-- SF2 ← QF3+QF4 connector --%>
                        <svg width="55" height="130" style="overflow:visible; flex-shrink:0;">
                        <line x1="55" y1="32"  x2="28" y2="32"  stroke="#ccc" stroke-width="2"/>
                        <line x1="55" y1="98"  x2="28" y2="98"  stroke="#ccc" stroke-width="2"/>
                        <line x1="28" y1="32"  x2="28" y2="98"  stroke="#ccc" stroke-width="2"/>
                        <line x1="28" y1="65"  x2="0"  y2="65"  stroke="#ccc" stroke-width="2"/>
                        </svg>

                        <%-- Far Right: QF3 + QF4 stacked --%>
                        <div class="bracket-sf-col" style="gap:20px;">
                            <div class="bracket-sf-box">
                                <div class="sf-header" style="background:#e9852a;">QF 3</div>
                                <div class="sf-team"><%= qf3t1%></div>
                                <div class="sf-team"><%= qf3t2%></div>
                            </div>
                            <div class="bracket-sf-box">
                                <div class="sf-header" style="background:#e9852a;">QF 4</div>
                                <div class="sf-team"><%= qf4t1%></div>
                                <div class="sf-team"><%= qf4t2%></div>
                            </div>
                        </div>

                    </div>

                    <% } else if (hasSF) { %>
                    <%-- 2-group SF layout: SF1 + SF2 on sides, Final in center (bracket style) --%>
                    <%
                        Match sf1 = bMap.get("SF1"), sf2 = bMap.get("SF2"), finalM = bMap.get("Final");
                        String sf1t1 = sf1 != null && sf1.getTeam1Id() > 0 ? getTeamName(sf1.getTeam1Id(), teamRegDAO) : "TBD";
                        String sf1t2 = sf1 != null && sf1.getTeam2Id() > 0 ? getTeamName(sf1.getTeam2Id(), teamRegDAO) : "TBD";
                        String sf2t1 = sf2 != null && sf2.getTeam1Id() > 0 ? getTeamName(sf2.getTeam1Id(), teamRegDAO) : "TBD";
                        String sf2t2 = sf2 != null && sf2.getTeam2Id() > 0 ? getTeamName(sf2.getTeam2Id(), teamRegDAO) : "TBD";
                        String finalT1 = finalM != null && finalM.getTeam1Id() > 0 ? getTeamName(finalM.getTeam1Id(), teamRegDAO) : "TBD";
                        String finalT2 = finalM != null && finalM.getTeam2Id() > 0 ? getTeamName(finalM.getTeam2Id(), teamRegDAO) : "TBD";
                    %>
                    <style>
                        .bracket-layout {
                            display: flex;
                            align-items: center;
                            justify-content: center;
                            gap: 0;
                            position: relative;
                            padding: 1rem 0 2rem;
                        }
                        .bracket-sf-col {
                            display: flex;
                            flex-direction: column;
                            gap: 0;
                            align-items: center;
                        }
                        .bracket-sf-box {
                            width: 150px;
                            border-radius: 10px;
                            overflow: hidden;
                            box-shadow: 0 2px 8px rgba(0,0,0,.12);
                        }
                        .bracket-sf-box .sf-header {
                            background: #c0392b;
                            color: #fff;
                            font-weight: 700;
                            font-size: .85rem;
                            padding: .5rem .7rem;
                            text-align: center;
                        }
                        .bracket-sf-box .sf-team {
                            background: #fff;
                            border: 1px solid #e0e0e0;
                            border-top: none;
                            font-size: .82rem;
                            font-weight: 600;
                            padding: .45rem .7rem;
                            text-align: center;
                            color: #333;
                        }
                        .bracket-sf-spacer {
                            height: 60px;
                        }
                        .bracket-connector {
                            display: flex;
                            flex-direction: column;
                            align-items: stretch;
                            width: 60px;
                            position: relative;
                        }
                        .bracket-final-col {
                            display: flex;
                            flex-direction: column;
                            align-items: center;
                            justify-content: center;
                        }
                        .bracket-final-box {
                            width: 160px;
                            border-radius: 10px;
                            overflow: hidden;
                            box-shadow: 0 4px 16px rgba(74,74,232,.25);
                            border: 2px solid #4a4ae8;
                        }
                        .bracket-final-box .final-header {
                            background: linear-gradient(135deg, #4a4ae8, #764ba2);
                            color: #fff;
                            font-weight: 800;
                            font-size: .95rem;
                            padding: .6rem .7rem;
                            text-align: center;
                            letter-spacing: .05em;
                        }
                        .bracket-final-box .final-team {
                            background: #fff;
                            border-top: 1px solid #e0e0e0;
                            font-size: .82rem;
                            font-weight: 600;
                            padding: .45rem .7rem;
                            text-align: center;
                            color: #333;
                        }
                        .bracket-label {
                            font-size: .7rem;
                            font-weight: 700;
                            letter-spacing: .08em;
                            text-transform: uppercase;
                            color: #aaa;
                            text-align: center;
                            margin-bottom: .5rem;
                        }
                        /* SVG connector lines */
                        .bracket-svg-left, .bracket-svg-right {
                            overflow: visible;
                        }
                    </style>

                    <%-- Column labels --%>
                    <div style="display:flex; justify-content:center; align-items:flex-end; gap:0; margin-bottom:.6rem;">
                        <div class="bracket-label" style="width:150px;">Semifinals</div>
                        <div style="width:70px;"></div>
                        <div class="bracket-label" style="width:160px;">Grand Final</div>
                        <div style="width:70px;"></div>
                        <div class="bracket-label" style="width:150px;">Semifinals</div>
                    </div>

                    <div class="bracket-layout">
                        <%-- Left: SF1 --%>
                        <div class="bracket-sf-col">
                            <div class="bracket-sf-box">
                                <div class="sf-header">SEMIFINAL 1</div>
                                <div class="sf-team"><%= sf1t1%></div>
                                <div class="sf-team"><%= sf1t2%></div>
                            </div>
                        </div>

                        <%-- SVG: SF1 → Final (left side, arrow points right toward Final) --%>
                        <svg width="70" height="100" style="overflow:visible; flex-shrink:0;">
                        <line x1="0" y1="50" x2="70" y2="50" stroke="#ccc" stroke-width="2"/>
                        <polygon points="62,45 70,50 62,55" fill="#aaa"/>
                        </svg>

                        <%-- Center: Final --%>
                        <div class="bracket-final-col">
                            <div class="bracket-final-box">
                                <div class="final-header">FINAL</div>
                                <div class="final-team"><%= finalT1%></div>
                                <div class="final-team"><%= finalT2%></div>
                            </div>
                        </div>

                        <%-- SVG: Final → SF2 (right side, arrow points left toward Final) --%>
                        <svg width="70" height="100" style="overflow:visible; flex-shrink:0;">
                        <line x1="0" y1="50" x2="70" y2="50" stroke="#ccc" stroke-width="2"/>
                        <polygon points="8,45 0,50 8,55" fill="#aaa"/>
                        </svg>

                        <%-- Right: SF2 --%>
                        <div class="bracket-sf-col">
                            <div class="bracket-sf-box">
                                <div class="sf-header">SEMIFINAL 2</div>
                                <div class="sf-team"><%= sf2t1%></div>
                                <div class="sf-team"><%= sf2t2%></div>
                            </div>
                        </div>
                    </div>

                    <% } else if (hasFinal) { %>
                    <%-- Direct final (2 or 3 teams) --%>
                    <%  Match finalM = bMap.get("Final");%>
                    <div style="display:flex;justify-content:center;gap:3rem;align-items:center;flex-wrap:wrap;">
                        <div class="flow-node node-final" style="width:180px;">
                            Grand Final<div class="node-sub"><%= finalM != null && finalM.getTeam1Id() > 0 ? getTeamName(finalM.getTeam1Id(), teamRegDAO) + " vs " + getTeamName(finalM.getTeam2Id(), teamRegDAO) : "TBD"%></div>
                        </div>
                        <svg viewBox="0 0 32 24" style="width:32px;"><path d="M2 12 L26 12 M20 6 L26 12 L20 18" stroke="#ccc" stroke-width="2" fill="none" stroke-linecap="round"/></svg>
                        <div class="flow-node node-champion <%= (finalM == null || finalM.getWinnerId() == null) ? "node-tbd" : ""%>" style="width:180px;">
                            🥇 Champion<div class="node-sub"><%= winnerName(finalM, teamRegDAO)%></div>
                        </div>
                    </div>
                    <% } %>

                    <%-- Legend --%>
                    <div style="display:flex;justify-content:center;gap:1.5rem;flex-wrap:wrap;margin-top:1.5rem;font-size:.8rem;font-weight:600;color:#666;">
                        <% if (hasGroups || rrTotal > 0) { %>
                        <span><span style="display:inline-block;width:12px;height:12px;border-radius:3px;background:#2a9d8f;margin-right:5px;"></span>Round Robin</span>
                        <% } %>
                        <% if (hasQF) { %>
                        <span><span style="display:inline-block;width:12px;height:12px;border-radius:3px;background:#e9852a;margin-right:5px;"></span>Quarterfinals</span>
                        <% } %>
                        <% if (hasSF) { %>
                        <span><span style="display:inline-block;width:12px;height:12px;border-radius:3px;background:#c0392b;margin-right:5px;"></span>Semifinals</span>
                        <% } %>
                        <span><span style="display:inline-block;width:12px;height:12px;border-radius:3px;background:#4a4ae8;margin-right:5px;"></span>Grand Final</span>
                        <span><span style="display:inline-block;width:12px;height:12px;border-radius:3px;background:#f5a623;margin-right:5px;"></span>Champion</span>
                    </div>
                </div>

                <%-- ══════════════════════════════════════
                     MATCH DETAIL CARDS
                ═══════════════════════════════════════ --%>
                <div class="matches-section">
                    <h2 class="section-heading">⚔️ Match Details</h2>

                    <% for (Match m : bracketMatches) {
                            if ("Final".equals(m.getGroupName())) {
                                continue; // Grand Final is handled separately below
                            }
                            TeamRegistration t1 = (m.getTeam1Id() > 0) ? teamRegDAO.getRegistrationById(m.getTeam1Id()) : null;
                            TeamRegistration t2 = (m.getTeam2Id() > 0) ? teamRegDAO.getRegistrationById(m.getTeam2Id()) : null;
                            String t1Name = (t1 != null) ? t1.getTeamName() : "TBD";
                            String t2Name = (t2 != null) ? t2.getTeamName() : "TBD";
                            boolean isCompleted = m.getWinnerId() != null;
                            boolean isWaiting = t1 == null || t2 == null;
                            String stageName = m.getGroupName();
                    %>
                    <div class="match-card">
                        <div class="match-header">
                            <div class="match-stage-badge">
                                <%
                                    if ("SF1".equals(stageName) || "SF2".equals(stageName))
                                        out.print("🔴 " + stageName + " — Semifinal");
                                    else if ("QF1".equals(stageName) || "QF2".equals(stageName) || "QF3".equals(stageName) || "QF4".equals(stageName))
                                        out.print("🟠 " + stageName + " — Quarterfinal");
                                    else
                                        out.print("🔵 Grand Final");
                                %>
                            </div>
                            <div class="<%= isCompleted ? "status-pill status-completed" : (isWaiting ? "status-pill status-waiting" : "status-pill status-pending")%>">
                                <%= isCompleted ? "✓ Completed" : (isWaiting ? "⏳ Waiting" : "○ Pending")%>
                            </div>
                        </div>

                        <div class="match-teams">
                            <div class="team-box <%= (isCompleted && t1 != null && m.getWinnerId() == t1.getRegistrationId()) ? "winner" : ""%>">
                                🏐 <%= t1Name%>
                            </div>
                            <div class="vs-text">VS</div>
                            <div class="team-box <%= (isCompleted && t2 != null && m.getWinnerId() == t2.getRegistrationId()) ? "winner" : ""%>">
                                🏐 <%= t2Name%>
                            </div>
                        </div>

                        <% if (isWaiting) { %>
                        <p class="waiting-msg">Waiting for previous round results to advance...</p>
                        <% } else {%>
                        <form action="UpdateMatchResultServlet" method="POST">
                            <input type="hidden" name="matchId"      value="<%= m.getMatchId()%>">
                            <input type="hidden" name="tournamentId" value="<%= tId%>">

                            <% if (!isCompleted) {%>
                            <div class="winner-selection">
                                <strong>🏆 Select Winner:</strong>
                                <div class="winner-buttons">
                                    <button type="button" class="btn-select-winner"
                                            onclick="selectWinner(this, <%= t1.getRegistrationId()%>)">
                                        <%= t1Name%>
                                    </button>
                                    <button type="button" class="btn-select-winner"
                                            onclick="selectWinner(this, <%= t2.getRegistrationId()%>)">
                                        <%= t2Name%>
                                    </button>
                                </div>
                                <input type="hidden" name="winnerId">
                            </div>
                            <% } %>

                            <div class="sets-input">
                                <strong>📊 Set Scores (Best of 3)</strong>
                                <% for (int i = 1; i <= 3; i++) {%>
                                <div class="set-row">
                                    <input type="number" name="team1_set<%= i%>" class="score-input" placeholder="0"
                                           min="0" max="31"
                                           value="<%= m.getSetScore(1, i) != null ? m.getSetScore(1, i) : ""%>"
                                           <%= isCompleted ? "readonly" : ""%>>
                                    <span class="set-label">Set <%= i%></span>
                                    <input type="number" name="team2_set<%= i%>" class="score-input" placeholder="0"
                                           min="0" max="31"
                                           value="<%= m.getSetScore(2, i) != null ? m.getSetScore(2, i) : ""%>"
                                           <%= isCompleted ? "readonly" : ""%>>
                                </div>
                                <% } %>
                            </div>

                            <% if (!isCompleted) { %>
                            <button type="button" class="btn-save" onclick="submitMatch(this)">💾 Save Result &amp; Advance Winner</button>
                            <% } %>
                        </form>
                        <% } %>
                    </div>
                    <% } %>
                </div>

                <%-- ══ NEXT MATCH BUTTON + FINAL CARD (when SFs done but Final not yet played) ══ --%>
                <% if (allSFsCompleted && !allMatchesCompleted && !"completed".equals(tournament.getStatus())) {
                        Match finalReady = bMap.get("Final");
                        boolean finalTeamsReady = (finalReady != null && finalReady.getTeam1Id() > 0 && finalReady.getTeam2Id() > 0);
                        TeamRegistration finalT1 = finalTeamsReady ? teamRegDAO.getRegistrationById(finalReady.getTeam1Id()) : null;
                        TeamRegistration finalT2 = finalTeamsReady ? teamRegDAO.getRegistrationById(finalReady.getTeam2Id()) : null;
                        String t1Name = (finalT1 != null) ? finalT1.getTeamName() : "TBD";
                        String t2Name = (finalT2 != null) ? finalT2.getTeamName() : "TBD";
                %>
                <div class="conclude-wrap">
                    <!-- Banner + reveal button -->
                    <div class="next-match-banner">
                        <div class="next-match-title">🏟️ Semifinals Complete!</div>
                        <p class="next-match-sub">Both semifinal winners have been decided. The Grand Final is ready.</p>
                        <% if (finalTeamsReady) { %>
                        <button class="btn-show-final" onclick="toggleFinalCard()">
                            <span id="btnLabel">⚡ Show Grand Final Match</span>
                        </button>
                        <% } else {%>
                        <p style="color:#e67e22;font-weight:600;margin-top:.8rem;">
                            ⚠️ Final teams not loaded yet —
                            <a href="OrganizerUpperBracket.jsp?id=<%= tId%>" style="color:#4a4ae8;font-weight:700;">refresh the page</a>
                            to continue.
                        </p>
                        <% } %>
                    </div>

                    <!-- Grand Final card (hidden until button clicked) -->
                    <% if (finalTeamsReady) {%>
                    <div id="finalCard" class="final-match-card" style="display:none;">
                        <div class="final-match-header">🔵 Grand Final</div>
                        <div class="final-match-teams">
                            <div class="final-team">🏐 <%= t1Name%></div>
                            <div class="final-vs">VS</div>
                            <div class="final-team">🏐 <%= t2Name%></div>
                        </div>
                        <form id="finalForm" action="UpdateMatchResultServlet" method="POST">
                            <input type="hidden" name="matchId"      value="<%= finalReady.getMatchId()%>">
                            <input type="hidden" name="tournamentId" value="<%= tId%>">
                            <div class="winner-selection">
                                <strong>🏆 Select Grand Final Winner:</strong>
                                <div class="winner-buttons">
                                    <button type="button" class="btn-select-winner"
                                            onclick="selectWinner(this, <%= finalReady.getTeam1Id()%>)">
                                        <%= t1Name%>
                                    </button>
                                    <button type="button" class="btn-select-winner"
                                            onclick="selectWinner(this, <%= finalReady.getTeam2Id()%>)">
                                        <%= t2Name%>
                                    </button>
                                </div>
                                <input type="hidden" name="winnerId" id="finalWinnerId">
                            </div>
                            <div class="sets-input">
                                <strong>📊 Set Scores (Best of 5)</strong>
                                <% for (int i = 1; i <= 5; i++) {%>
                                <div class="set-row">
                                    <input type="number" name="team1_set<%= i%>" class="score-input" placeholder="0" min="0" max="31">
                                    <span class="set-label">Set <%= i%></span>
                                    <input type="number" name="team2_set<%= i%>" class="score-input" placeholder="0" min="0" max="31">
                                </div>
                                <% } %>
                            </div>
                            <button type="submit" class="btn-save" style="background:linear-gradient(135deg,#4a4ae8,#764ba2);">
                                💾 Save Final Result &amp; Crown Champion
                            </button>
                        </form>
                    </div>
                    <% } %>
                </div>
                <% } %>

                <%-- ══ CONCLUDE BUTTON (only when Final has a winner) ══ --%>
                <% if (allMatchesCompleted && !"completed".equals(tournament.getStatus())) {%>
                <div class="conclude-wrap">
                    <form action="ConcludeTournamentServlet" method="POST"
                          onsubmit="event.preventDefault(); confirmConclude(this);">
                        <input type="hidden" name="tournamentId" value="<%= tId%>">
                        <button type="submit" class="btn-conclude">🏆 Conclude Tournament</button>
                    </form>
                </div>
                <% } %>

                <% }
                    /* end bracketMatches not empty */%>
            </div>
        </section>

        <footer class="footer">
            <div class="container">
                <div class="footer-content">
                    <div class="footer-section">
                        <div class="footer-logo">
                            <span class="logo-icon">🏐</span>
                            <span class="logo-text">VolleyMetric</span>
                        </div>
                        <p class="footer-description">FYP project to manage volleyball tournament.</p>
                    </div>
                    <div class="footer-section">
                        <h4 class="footer-heading">Quick Links</h4>
                        <ul class="footer-links">
                            <li><a href="#about">About Us</a></li>
                            <li><a href="#tournaments">Tournaments</a></li>
                            <li><a href="#contact">Contact</a></li>
                        </ul>
                    </div>
                    <div class="footer-section">
                        <h4 class="footer-heading">Contact Info</h4>
                        <ul class="footer-contact">
                            <li>📧 info@volleymetric.com</li>
                            <li>📞 +601-163770661</li>
                            <li>📍 21030 Kuala Nerus, Terengganu</li>
                        </ul>
                    </div>
                </div>
                <div class="footer-bottom">
                    <p>&copy; <%= new java.util.Date().getYear() + 1900%> VolleyMetric. All rights reserved.</p>
                    <div class="footer-bottom-links">
                        <a href="#privacy">Privacy Policy</a>
                        <a href="#terms">Terms of Service</a>
                    </div>
                </div>
            </div>
        </footer>

        <style>
            /* ── Toast Notification ── */
            #toast {
                position: fixed;
                top: 2rem;
                left: 50%;
                transform: translateX(-50%) translateY(-20px);
                min-width: 280px;
                max-width: 420px;
                padding: 1rem 1.5rem;
                border-radius: 14px;
                font-size: .95rem;
                font-weight: 600;
                display: flex;
                align-items: center;
                gap: .75rem;
                box-shadow: 0 8px 32px rgba(0,0,0,.18);
                opacity: 0;
                pointer-events: none;
                transition: opacity .3s ease, transform .3s ease;
                z-index: 9999;
            }
            #toast.show {
                opacity: 1;
                pointer-events: auto;
                transform: translateX(-50%) translateY(0);
            }
            #toast.toast-error   {
                background: #fff0f0;
                border: 2px solid #e74c3c;
                color: #c0392b;
            }
            #toast.toast-warning {
                background: #fffbf0;
                border: 2px solid #f39c12;
                color: #9a6000;
            }
            #toast.toast-success {
                background: #f0fff4;
                border: 2px solid #27ae60;
                color: #1a7a40;
            }
            #toast .toast-icon   {
                font-size: 1.3rem;
                flex-shrink: 0;
            }
            #toast .toast-close  {
                margin-left: auto;
                background: none;
                border: none;
                font-size: 1.1rem;
                cursor: pointer;
                color: inherit;
                opacity: .6;
                padding: 0 .2rem;
            }
            #toast .toast-close:hover {
                opacity: 1;
            }

            /* ── Confirm Dialog ── */
            #confirmOverlay {
                position: fixed;
                inset: 0;
                background: rgba(0,0,0,.45);
                display: flex;
                align-items: center;
                justify-content: center;
                z-index: 10000;
                opacity: 0;
                pointer-events: none;
                transition: opacity .2s ease;
            }
            #confirmOverlay.show {
                opacity: 1;
                pointer-events: auto;
            }
            #confirmBox {
                background: #fff;
                border-radius: 18px;
                padding: 2rem;
                max-width: 380px;
                width: 90%;
                text-align: center;
                box-shadow: 0 16px 48px rgba(0,0,0,.2);
                transform: scale(.95);
                transition: transform .2s ease;
            }
            #confirmOverlay.show #confirmBox {
                transform: scale(1);
            }
            #confirmBox .confirm-icon  {
                font-size: 2.5rem;
                margin-bottom: .5rem;
            }
            #confirmBox .confirm-title {
                font-size: 1.15rem;
                font-weight: 800;
                color: #2c3e50;
                margin-bottom: .4rem;
            }
            #confirmBox .confirm-msg   {
                font-size: .9rem;
                color: #666;
                margin-bottom: 1.5rem;
            }
            #confirmBox .confirm-btns  {
                display: flex;
                gap: .75rem;
                justify-content: center;
            }
            #confirmBox .confirm-btns button {
                padding: .7rem 1.8rem;
                border-radius: 50px;
                font-weight: 700;
                font-size: .9rem;
                cursor: pointer;
                border: none;
                transition: all .2s;
            }
            .btn-confirm-yes {
                background: linear-gradient(135deg,#667eea,#764ba2);
                color: #fff;
            }
            .btn-confirm-yes:hover {
                transform: translateY(-2px);
                box-shadow: 0 4px 14px rgba(102,126,234,.4);
            }
            .btn-confirm-no  {
                background: #f0f0f0;
                color: #555;
            }
            .btn-confirm-no:hover  {
                background: #e0e0e0;
            }
        </style>

        <!-- Toast -->
        <div id="toast">
            <span class="toast-icon" id="toastIcon"></span>
            <span id="toastMsg"></span>
            <button class="toast-close" onclick="hideToast()">✕</button>
        </div>

        <!-- Confirm Dialog -->
        <div id="confirmOverlay">
            <div id="confirmBox">
                <div class="confirm-icon">⚠️</div>
                <div class="confirm-title" id="confirmTitle">Are you sure?</div>
                <div class="confirm-msg" id="confirmMsg"></div>
                <div class="confirm-btns">
                    <button class="btn-confirm-no"  onclick="resolveConfirm(false)">Cancel</button>
                    <button class="btn-confirm-yes" onclick="resolveConfirm(true)">Confirm</button>
                </div>
            </div>
        </div>

        <script>
            /* ── Toast ── */
            let toastTimer;
            function showToast(msg, type = 'error') {
                const t = document.getElementById('toast');
                const icons = {error: '❌', warning: '⚠️', success: '✅'};
                document.getElementById('toastIcon').textContent = icons[type] || '❌';
                document.getElementById('toastMsg').textContent = msg;
                t.className = 'show toast-' + type;
                clearTimeout(toastTimer);
                toastTimer = setTimeout(hideToast, type === 'success' ? 5000 : 4000);
            }
            function hideToast() {
                document.getElementById('toast').classList.remove('show');
            }

            /* ── Confirm Dialog ── */
            let confirmResolve;
            function showConfirm(title, msg) {
                document.getElementById('confirmTitle').textContent = title;
                document.getElementById('confirmMsg').textContent = msg;
                document.getElementById('confirmOverlay').classList.add('show');
                return new Promise(res => confirmResolve = res);
            }
            function resolveConfirm(result) {
                document.getElementById('confirmOverlay').classList.remove('show');
                if (confirmResolve)
                    confirmResolve(result);
            }

            /* ── Winner selection ── */
            function selectWinner(button, teamId) {
                const container = button.closest('.winner-buttons');
                const form = button.closest('form');
                const hidden = form.querySelector('input[name="winnerId"]');
                container.querySelectorAll('.btn-select-winner').forEach(b => b.classList.remove('selected'));
                button.classList.add('selected');
                hidden.value = teamId;
            }

            /* ── Validate & submit regular match (Best of 3) ── */
            function submitMatch(btn) {
                const form = btn.closest('form');
                const winnerInput = form.querySelector('input[name="winnerId"]');
                const winnerId = winnerInput ? winnerInput.value : '';
                if (!winnerId) {
                    // Scroll to and highlight the winner selection area
                    const winnerSection = form.querySelector('.winner-selection');
                    if (winnerSection) {
                        winnerSection.scrollIntoView({ behavior: 'smooth', block: 'center' });
                        winnerSection.style.outline = '2px solid #e74c3c';
                        winnerSection.style.borderRadius = '8px';
                        setTimeout(() => winnerSection.style.outline = '', 2000);
                    }
                    showToast('⚠️ Please select a winner above before saving!', 'warning');
                    return;
                }
                form.submit();
            }

            /* ── Validate & submit Grand Final (Best of 5) ── */
            function submitFinal(btn) {
                // Make card visible FIRST so all inputs are accessible in the DOM
                const card = document.getElementById('finalCard');
                if (card)
                    card.style.display = 'block';

                const form = document.getElementById('finalForm');
                const winnerEl = document.getElementById('finalWinnerId');

                if (!winnerEl || !winnerEl.value) {
                    showToast('Please select a Grand Final winner first!', 'warning');
                    return;
                }

                let filledSets = 0;
                for (let i = 1; i <= 5; i++) {
                    const s1 = form.querySelector(`input[name="team1_set${i}"]`).value.trim();
                    const s2 = form.querySelector(`input[name="team2_set${i}"]`).value.trim();
                    if (s1 !== '' || s2 !== '')
                        filledSets++;
                }
                if (filledSets === 0) {
                    showToast('Please enter set scores before saving the Final result!', 'warning');
                    return;
                }

                form.submit();
            }

            /* ── Conclude tournament confirm ── */
            function confirmConclude(form) {
                showConfirm('Conclude Tournament?', 'This will finalize the tournament and cannot be undone.')
                        .then(yes => {
                            if (yes)
                                form.submit();
                        });
            }

            /* ── Toggle Final card ── */
            function toggleFinalCard() {
                const card = document.getElementById('finalCard');
                const btn = document.getElementById('btnLabel');
                if (card.style.display === 'none') {
                    card.style.display = 'block';
                    card.scrollIntoView({behavior: 'smooth', block: 'start'});
                    btn.textContent = '▲ Hide Grand Final Match';
                } else {
                    card.style.display = 'none';
                    btn.textContent = '⚡ Show Grand Final Match';
                }
            }
        </script>
    </body>
</html>
