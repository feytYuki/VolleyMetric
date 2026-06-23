<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="Model.Tournament, Model.TeamRegistration, Model.TournamentGroup, Model.Match" %>
<%@ page import="DAO.TournamentDAO, DAO.TeamRegistrationDAO, DAO.TournamentGroupDAO, DAO.MatchDAO" %>
<%@ page import="java.util.List, java.util.Map, java.util.HashMap" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    String username = (String) session.getAttribute("organizerUsername");
    String fullname = (String) session.getAttribute("organizerFullname");
    Integer organizerId = (Integer) session.getAttribute("organizerId");

    if (username == null || organizerId == null) {
        response.sendRedirect("OrganizerLogin.jsp");
        return;
    }

    String tournamentIdStr = request.getParameter("id");
    if (tournamentIdStr == null) {
        response.sendRedirect("OrganizerSchedule.jsp");
        return;
    }

    int tournamentId = Integer.parseInt(tournamentIdStr);

    TournamentDAO tournamentDAO = new TournamentDAO();
    Tournament tournament = tournamentDAO.getTournamentById(tournamentId);

    if (tournament == null || tournament.getOrganizerId() != organizerId) {
        response.sendRedirect("OrganizerSchedule.jsp");
        return;
    }

    TeamRegistrationDAO teamRegDAO = new TeamRegistrationDAO();
    List<TeamRegistration> approvedTeams = teamRegDAO.getApprovedTeamsByTournament(tournamentId);

    TournamentGroupDAO groupDAO = new TournamentGroupDAO();
    Map<String, List<TeamRegistration>> groups = groupDAO.getGroupsWithTeams(tournamentId);

    MatchDAO matchDAO = new MatchDAO();

    // Clean up any duplicate RR matches from prior broken attempts
    matchDAO.cleanDuplicateRRMatches(tournamentId);

    List<Match> allMatches = matchDAO.getMatchesByTournament(tournamentId);

    // Separate group-stage matches (A-D groups or RR) from bracket matches
    List<Match> groupMatches = new java.util.ArrayList<>();
    for (Match m : allMatches) {
        String gn = m.getGroupName();
        if (gn != null && (gn.matches("[A-D]") || "RR".equals(gn))) {
            groupMatches.add(m);
        }
    }

    // Count RR progress
    int rrTotal = 0, rrCompleted = 0;
    boolean isRRTournament = false;
    for (Match m : groupMatches) {
        if ("RR".equals(m.getGroupName())) {
            isRRTournament = true;
            rrTotal++;
            if (m.getWinnerId() != null) rrCompleted++;
        }
    }
    // Also count group-stage (A/B/C/D) matches for progress
    int groupTotal = 0, groupCompleted = 0;
    for (Match m : groupMatches) {
        if (!("RR".equals(m.getGroupName()))) {
            groupTotal++;
            if (m.getWinnerId() != null) groupCompleted++;
        }
    }

    boolean allGroupsDone = (groupTotal > 0 && groupCompleted == groupTotal);
    boolean allRRDone     = (rrTotal > 0 && rrCompleted == rrTotal);
    boolean allMatchesDone = isRRTournament ? allRRDone : allGroupsDone;

    // Bracket state
    List<Match> bracketMatches = matchDAO.getMatchesByTournamentAndType(tournamentId, "bracket");
    List<Match> rrBracket      = matchDAO.getRRMatches(tournamentId);
    boolean bracketExists = !bracketMatches.isEmpty() || !rrBracket.isEmpty();

    int n = approvedTeams == null ? 0 : approvedTeams.size();

    // Determine page state:
    // STATE 1 - Not enough teams
    // STATE 2 - Ready to generate groups (no groups yet, enough teams)
    // STATE 3 - Group stage in progress (groups exist, matches not all done)
    // STATE 4 - All group matches done, bracket not yet generated
    // STATE 5 - Bracket exists → show View Elimination button
    boolean stateNotEnough     = n < 2;
    boolean stateReadyGenerate = !stateNotEnough && groups.isEmpty() && !isRRTournament && bracketMatches.isEmpty();
    boolean stateGroupsActive  = (!groups.isEmpty() || isRRTournament) && !allMatchesDone && !bracketExists;
    boolean stateReadyBracket  = (!groups.isEmpty() || isRRTournament) && allMatchesDone && !bracketExists;
    boolean stateBracketExists = bracketExists;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tournament Schedule - <%= tournament.getTournamentName() %></title>
    <link rel="stylesheet" href="style.css">
    <style>
        .user-info { display: flex; align-items: center; gap: 1rem; }
        .user-details { display: flex; flex-direction: column; align-items: flex-end; background: white; border: 2px solid #764ba2; border-radius: 5px; padding: 4px 10px; }
        .user-role-label { font-size: 0.8rem; font-weight: 600; color: #764ba2; }
        .user-name { font-size: 0.95rem; font-weight: 600; color: #000; }
        .btn-logout { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #fff; padding: 0.6rem 1.5rem; text-decoration: none; border-radius: 5px; font-weight: 600; }

        .schedule-section { padding: 2rem 0; background-color: #f8f9fa; min-height: 80vh; }
        .page-title { font-size: 2.5rem; color: #1a1a2e; text-align: center; margin-bottom: 2rem; font-weight: 800; }

        .section-header { text-align: center; margin: 2rem 0 1.5rem; }
        .section-header h2 { font-size: 2rem; color: #1a1a2e; font-weight: 700; margin-bottom: 0.4rem; }
        .section-header p { color: #666; font-size: 1rem; }

        /* ── Stage progress bar ── */
        .stage-tracker {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 0;
            margin: 0 auto 2.5rem;
            max-width: 640px;
        }
        .stage-step {
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 6px;
            flex: 1;
            position: relative;
        }
        .stage-circle {
            width: 42px; height: 42px;
            border-radius: 50%;
            display: flex; align-items: center; justify-content: center;
            font-size: 1.1rem;
            font-weight: 700;
            border: 3px solid #dee2e6;
            background: white;
            color: #adb5bd;
            z-index: 1;
            transition: all 0.3s;
        }
        .stage-circle.done   { background: #28a745; border-color: #28a745; color: white; }
        .stage-circle.active { background: #667eea; border-color: #667eea; color: white; }
        .stage-label { font-size: 0.78rem; font-weight: 600; color: #adb5bd; text-align: center; }
        .stage-label.done   { color: #28a745; }
        .stage-label.active { color: #667eea; }
        .stage-connector {
            height: 3px;
            flex: 1;
            background: #dee2e6;
            margin-top: -22px;
            transition: background 0.3s;
        }
        .stage-connector.done { background: #28a745; }

        /* ── Groups ── */
        .groups-container {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 1.5rem;
            margin-bottom: 3rem;
            max-width: 1200px;
            margin-left: auto;
            margin-right: auto;
        }
        .group-card { background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08); transition: transform 0.2s, box-shadow 0.2s; }
        .group-card:hover { transform: translateY(-4px); box-shadow: 0 8px 28px rgba(0,0,0,0.14); }
        .group-header-a { background: linear-gradient(135deg, #17a2b8, #138496); color: white; padding: 1.2rem; text-align: center; font-size: 1.5rem; font-weight: 800; }
        .group-header-b { background: linear-gradient(135deg, #e83e8c, #d63384); color: white; padding: 1.2rem; text-align: center; font-size: 1.5rem; font-weight: 800; }
        .group-header-c { background: linear-gradient(135deg, #28a745, #218838); color: white; padding: 1.2rem; text-align: center; font-size: 1.5rem; font-weight: 800; }
        .group-header-d { background: linear-gradient(135deg, #ffc107, #e0a800); color: white; padding: 1.2rem; text-align: center; font-size: 1.5rem; font-weight: 800; }
        .group-header-rr { background: linear-gradient(135deg, #667eea, #764ba2); color: white; padding: 1.2rem; text-align: center; font-size: 1.5rem; font-weight: 800; }
        .group-teams { padding: 1rem; }
        .team-item { padding: 0.9rem 0.8rem; border-bottom: 1px solid #f0f0f0; display: flex; align-items: center; gap: 0.8rem; font-weight: 600; color: #2c3e50; font-size: 1rem; }
        .team-item:last-child { border-bottom: none; }
        .team-flag { font-size: 1.5rem; width: 34px; height: 34px; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, #667eea, #764ba2); border-radius: 50%; }

        /* ── Single action button ── */
        .action-area { text-align: center; margin: 2rem 0 3rem; }
        .btn-action {
            display: inline-block;
            padding: 1rem 3rem;
            border: none;
            border-radius: 50px;
            font-weight: 700;
            font-size: 1.1rem;
            cursor: pointer;
            text-decoration: none;
            transition: all 0.3s;
            box-shadow: 0 4px 15px rgba(0,0,0,0.15);
        }
        .btn-action:hover { transform: translateY(-3px); box-shadow: 0 6px 20px rgba(0,0,0,0.2); }
        .btn-action.green  { background: linear-gradient(135deg, #28a745, #20c997); color: white; }
        .btn-action.purple { background: linear-gradient(135deg, #667eea, #764ba2); color: white; }
        .btn-action.gray   { background: #adb5bd; color: white; cursor: not-allowed; }
        .btn-action.gray:hover { transform: none; box-shadow: 0 4px 15px rgba(0,0,0,0.1); }
        .btn-hint { color: #888; font-size: 0.9rem; margin-top: 0.6rem; }

        /* ── Progress pill ── */
        .progress-pill {
            display: inline-flex; align-items: center; gap: 8px;
            background: #fff8e1; border: 1px solid #f9a825; color: #7a5800;
            border-radius: 50px; padding: 0.5rem 1.2rem;
            font-size: 0.9rem; font-weight: 600; margin-bottom: 1.5rem;
        }
        .progress-pill.done { background: #e8f5e9; border-color: #43a047; color: #1b5e20; }

        /* ── Matches ── */
        .matches-list { display: flex; flex-direction: column; gap: 1.2rem; max-width: 900px; margin: 0 auto; }
        .match-card { background: white; border-radius: 14px; padding: 1.4rem; box-shadow: 0 4px 14px rgba(0,0,0,0.07); }
        .match-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.2rem; padding-bottom: 0.7rem; border-bottom: 2px solid #f0f0f0; }
        .match-title { font-size: 1rem; font-weight: 700; color: #667eea; }
        .match-status { padding: 0.35rem 0.9rem; border-radius: 50px; font-size: 0.72rem; font-weight: 700; text-transform: uppercase; }
        .status-pending  { background: linear-gradient(135deg, #ffc107, #ffb300); color: white; }
        .status-completed { background: linear-gradient(135deg, #28a745, #20c997); color: white; }
        .match-teams { display: grid; grid-template-columns: 1fr auto 1fr; gap: 1.2rem; align-items: center; margin-bottom: 1.2rem; }
        .team-box { padding: 0.9rem; border: 2px solid #e0e0e0; border-radius: 10px; font-weight: 700; font-size: 1rem; text-align: center; background: #fafafa; }
        .team-box.winner { border-color: #28a745; background: linear-gradient(135deg, #d4edda, #c3e6cb); }
        .vs-text { font-size: 1.1rem; font-weight: 800; color: #999; background: #f8f9fa; width: 40px; height: 40px; display: flex; align-items: center; justify-content: center; border-radius: 50%; border: 2px solid #e0e0e0; }
        .winner-selection > strong { display: block; margin-bottom: 0.6rem; font-size: 0.95rem; color: #2c3e50; }
        .winner-buttons { display: grid; grid-template-columns: 1fr 1fr; gap: 0.8rem; }
        .btn-select-winner { padding: 0.8rem; border: 2px solid #667eea; background: white; color: #667eea; border-radius: 10px; font-weight: 700; font-size: 0.9rem; cursor: pointer; transition: all 0.2s; }
        .btn-select-winner:hover { background: #f0f4ff; }
        .btn-select-winner.selected { background: linear-gradient(135deg, #667eea, #764ba2); color: white; border-color: #667eea; }
        .sets-input { margin-top: 1.2rem; padding: 1.2rem; background: linear-gradient(135deg, #f8f9fa, #e9ecef); border-radius: 10px; border: 2px solid #dee2e6; }
        .sets-input > strong { display: block; margin-bottom: 0.8rem; font-size: 1rem; color: #2c3e50; text-align: center; }
        .set-row { display: grid; grid-template-columns: 1fr auto 1fr; gap: 1rem; align-items: center; margin-bottom: 0.8rem; background: white; padding: 0.8rem; border-radius: 8px; }
        .set-row:last-child { margin-bottom: 0; }
        .set-label { font-weight: 700; color: white; font-size: 0.9rem; text-align: center; background: linear-gradient(135deg, #667eea, #764ba2); padding: 0.5rem 1rem; border-radius: 50px; min-width: 80px; }
        .score-input { width: 100%; max-width: 72px; padding: 0.6rem; border: 2px solid #dee2e6; border-radius: 8px; text-align: center; font-weight: 700; font-size: 1.2rem; background: #fafafa; transition: all 0.2s; }
        .score-input:focus { outline: none; border-color: #667eea; background: white; }
        .score-container { display: flex; justify-content: center; }
        .score-display { text-align: center; font-weight: 700; font-size: 1.4rem; color: #2c3e50; }
        .btn-save-match { background: linear-gradient(135deg, #667eea, #764ba2); color: white; padding: 0.9rem 2rem; border: none; border-radius: 50px; font-weight: 700; font-size: 1rem; cursor: pointer; margin-top: 1.2rem; width: 100%; transition: all 0.2s; }
        .btn-save-match:hover { background: linear-gradient(135deg, #5568d3, #6a3f8f); transform: translateY(-2px); }
        .alert { padding: 0.9rem 1.1rem; border-radius: 10px; margin-bottom: 1.2rem; font-weight: 600; }
        .alert-success { background: linear-gradient(135deg, #d4edda, #c3e6cb); border: 2px solid #28a745; color: #155724; }
        .alert-error   { background: linear-gradient(135deg, #f8d7da, #f5c6cb); border: 2px solid #dc3545; color: #721c24; }
        .empty-state { text-align: center; padding: 3rem 2rem; background: white; border-radius: 16px; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
        .empty-state h3 { font-size: 1.5rem; color: #2c3e50; margin-bottom: 0.8rem; }
        .empty-state p  { color: #6c757d; font-size: 1rem; }
    </style>
</head>
<body>
    <header class="header">
        <div class="container">
            <div class="logo">
                <div style="width: 40px; height: 40px; overflow: hidden; background: white; border: 2px solid red;">
                    <img src="umtlogo.png" alt="UMT Logo" style="width: 100%; height: 100%; object-fit: contain;">
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

    <section class="schedule-section">
        <div class="container">
            <h1 class="page-title"><%= tournament.getTournamentName() %></h1>

            <%-- Flash messages --%>
            <%
                String successMsg = (String) session.getAttribute("successMessage");
                String errorMsg   = (String) session.getAttribute("errorMessage");
                if (successMsg != null) { session.removeAttribute("successMessage"); %>
                <div class="alert alert-success"><%= successMsg %></div>
            <% } if (errorMsg != null) { session.removeAttribute("errorMessage"); %>
                <div class="alert alert-error"><%= errorMsg %></div>
            <% } %>

            <%-- ══ Stage progress tracker ══ --%>
            <%
                // step 1 = groups generated, step 2 = all matches done, step 3 = elimination bracket
                boolean step1done = !groups.isEmpty() || isRRTournament;
                boolean step2done = step1done && allMatchesDone;
                boolean step3done = stateBracketExists;
            %>
            <div class="stage-tracker">
                <div class="stage-step">
                    <div class="stage-circle <%= step1done ? "done" : "active" %>">
                        <%= step1done ? "✓" : "1" %>
                    </div>
                    <div class="stage-label <%= step1done ? "done" : "active" %>">Round robin</div>
                </div>
                <div class="stage-connector <%= step1done ? "done" : "" %>"></div>
                <div class="stage-step">
                    <div class="stage-circle <%= step3done ? "done" : step2done ? "active" : "" %>">
                        <%= step3done ? "✓" : "2" %>
                    </div>
                    <div class="stage-label <%= step3done ? "done" : step2done ? "active" : "" %>">Elimination</div>
                </div>
                <div class="stage-connector <%= step3done ? "done" : "" %>"></div>
                <div class="stage-step">
                    <div class="stage-circle <%= step3done ? "active" : "" %>">🏆</div>
                    <div class="stage-label <%= step3done ? "active" : "" %>">Champion</div>
                </div>
            </div>

            <%-- ══ Not enough teams ══ --%>
            <% if (stateNotEnough) { %>
                <div class="empty-state">
                    <h3>⏳ Waiting for teams</h3>
                    <p>At least 2 approved teams are needed to start. Currently <strong><%= n %></strong> approved.</p>
                </div>

            <%-- ══ Ready to generate groups ══ --%>
            <% } else if (stateReadyGenerate) { %>
                <div class="empty-state">
                    <h3>🎯 Ready to start</h3>
                    <p style="margin-bottom:1.5rem;">
                        <strong><%= n %></strong> teams approved.
                        <% if (n <= 5) { %>
                            One round-robin group will be created — each team plays every other team once.
                        <% } else if (n <= 11) { %>
                            Two round-robin groups (A &amp; B) will be created — cross-seeded into the elimination stage.
                        <% } else { %>
                            Four round-robin groups (A, B, C, D) will be created — top 2 from each advance to the elimination stage.
                        <% } %>
                    </p>
                    <form action="GenerateGroupsServlet" method="POST" style="display:inline;">
                        <input type="hidden" name="tournamentId" value="<%= tournamentId %>">
                        <button type="submit" class="btn-action green">🎯 Generate Groups &amp; Matches</button>
                    </form>
                </div>
            <% } %>

            <%-- ══ Groups display ══ --%>
            <% if (!groups.isEmpty() || isRRTournament) { %>
                <div class="section-header">
                    <% if (isRRTournament) { %>
                        <h2>🔄 Round-Robin Stage</h2>
                        <p>Each team plays every other team once &mdash; top 2 advance to the elimination stage</p>
                    <% } else { %>
                        <h2>🏆 Group Stage</h2>
                        <p>Teams play round-robin within their group &mdash; top teams advance to the elimination stage</p>
                    <% } %>
                </div>

                <%-- Match progress pill --%>
                <% if (step1done && !step2done) {
                    int done = isRRTournament ? rrCompleted : groupCompleted;
                    int total = isRRTournament ? rrTotal : groupTotal; %>
                    <div style="text-align:center;">
                        <div class="progress-pill">
                            ⏳ Matches completed: <strong><%= done %> / <%= total %></strong>
                        </div>
                    </div>
                <% } else if (step2done && !step3done) { %>
                    <div style="text-align:center;">
                        <div class="progress-pill done">
                            ✅ All matches complete — ready for the elimination stage!
                        </div>
                    </div>
                <% } %>

                <%-- Group cards --%>
                <div class="groups-container">
                    <% if (isRRTournament) { %>
                        <div class="group-card">
                            <div class="group-header-rr">ROUND ROBIN</div>
                            <div class="group-teams">
                                <% for (TeamRegistration team : approvedTeams) { %>
                                <div class="team-item">
                                    <span class="team-flag">🏐</span>
                                    <span><%= team.getTeamName() %></span>
                                </div>
                                <% } %>
                            </div>
                        </div>
                    <% } else {
                        String[] groupNames = {"A", "B", "C", "D"};
                        String[] headerClasses = {"group-header-a","group-header-b","group-header-c","group-header-d"};
                        int gi = 0;
                        for (String gn : groupNames) {
                            List<TeamRegistration> gt = groups.get(gn);
                            if (gt != null && !gt.isEmpty()) { %>
                        <div class="group-card">
                            <div class="<%= headerClasses[gi] %>">GROUP <%= gn %></div>
                            <div class="group-teams">
                                <% for (TeamRegistration team : gt) { %>
                                <div class="team-item">
                                    <span class="team-flag">🏐</span>
                                    <span><%= team.getTeamName() %></span>
                                </div>
                                <% } %>
                            </div>
                        </div>
                        <% } gi++; } } %>
                </div>
            <% } %>

            <%-- ══ Matches list ══ --%>
            <% if (!groupMatches.isEmpty()) { %>
                <div class="section-header">
                    <h2>⚔️ Matches</h2>
                    <p>Best of 3 sets — first to win 2 sets takes the match</p>
                </div>
                <div class="matches-list">
                    <% for (Match match : groupMatches) {
                        TeamRegistration team1 = teamRegDAO.getRegistrationById(match.getTeam1Id());
                        TeamRegistration team2 = teamRegDAO.getRegistrationById(match.getTeam2Id());
                        boolean isCompleted = match.getWinnerId() != null;
                    %>
                    <div class="match-card">
                        <div class="match-header">
                            <div class="match-title">
                                Match #<%= match.getMatchId() %>
                                <% if (!isRRTournament) { %> &mdash; Group <%= match.getGroupName() %><% } %>
                            </div>
                            <div class="match-status <%= isCompleted ? "status-completed" : "status-pending" %>">
                                <%= isCompleted ? "✓ Completed" : "○ Pending" %>
                            </div>
                        </div>

                        <div class="match-teams">
                            <div class="team-box <%= (match.getWinnerId() != null && team1 != null && match.getWinnerId() == team1.getRegistrationId()) ? "winner" : "" %>">
                                🏐 <%= team1 != null ? team1.getTeamName() : "TBD" %>
                            </div>
                            <div class="vs-text">VS</div>
                            <div class="team-box <%= (match.getWinnerId() != null && team2 != null && match.getWinnerId() == team2.getRegistrationId()) ? "winner" : "" %>">
                                🏐 <%= team2 != null ? team2.getTeamName() : "TBD" %>
                            </div>
                        </div>

                        <% if (!isCompleted) { %>
                        <form action="UpdateMatchResultServlet" method="POST">
                            <input type="hidden" name="matchId" value="<%= match.getMatchId() %>">
                            <input type="hidden" name="tournamentId" value="<%= tournamentId %>">
                            <div class="winner-selection">
                                <strong>Select Winner:</strong>
                                <div class="winner-buttons">
                                    <button type="button" class="btn-select-winner" onclick="selectWinner(this, <%= team1 != null ? team1.getRegistrationId() : 0 %>)">
                                        <%= team1 != null ? team1.getTeamName() : "Team 1" %>
                                    </button>
                                    <button type="button" class="btn-select-winner" onclick="selectWinner(this, <%= team2 != null ? team2.getRegistrationId() : 0 %>)">
                                        <%= team2 != null ? team2.getTeamName() : "Team 2" %>
                                    </button>
                                </div>
                                <input type="hidden" name="winnerId" id="winnerId_<%= match.getMatchId() %>" required>
                            </div>
                            <div class="sets-input">
                                <strong>📊 Set Scores (Best of 3)</strong>
                                <% for (int i = 1; i <= 3; i++) { %>
                                <div class="set-row">
                                    <div class="score-container">
                                        <input type="number" name="team1_set<%= i %>" class="score-input" min="0" max="31" placeholder="0">
                                    </div>
                                    <span class="set-label">Set <%= i %></span>
                                    <div class="score-container">
                                        <input type="number" name="team2_set<%= i %>" class="score-input" min="0" max="31" placeholder="0">
                                    </div>
                                </div>
                                <% } %>
                            </div>
                            <button type="submit" class="btn-save-match">💾 Save Match Result</button>
                        </form>
                        <% } else { %>
                        <div class="sets-input">
                            <strong>📊 Final Score</strong>
                            <% for (int i = 1; i <= 3; i++) {
                                Integer s1 = match.getSetScore(1, i);
                                Integer s2 = match.getSetScore(2, i);
                                if (s1 != null && s2 != null) { %>
                            <div class="set-row">
                                <div class="score-display"><%= s1 %></div>
                                <span class="set-label">Set <%= i %></span>
                                <div class="score-display"><%= s2 %></div>
                            </div>
                            <% } } %>
                        </div>
                        <% } %>
                    </div>
                    <% } %>
                </div>
            <% } %>

            <%-- ══ Single action button area ══ --%>
            <div class="action-area">
                <% if (stateGroupsActive) { %>
                    <%-- Matches in progress — button greyed out --%>
                    <span class="btn-action gray">🏆 Go to Elimination Stage</span>
                    <p class="btn-hint">
                        Complete all
                        <%= isRRTournament ? rrTotal : groupTotal %>
                        matches to unlock the elimination stage.
                    </p>

                <% } else if (stateReadyBracket) { %>
                    <%-- All done — generate bracket --%>
                    <a href="GenerateBracketServlet?id=<%= tournamentId %>" class="btn-action green">
                        🏆 Generate Elimination Stage
                    </a>

                <% } else if (stateBracketExists) { %>
                    <%-- Bracket already exists — view it --%>
                    <a href="OrganizerUpperBracket.jsp?id=<%= tournamentId %>" class="btn-action purple" style="text-decoration:none;">
                        🏆 View Elimination Stage
                    </a>
                <% } %>
            </div>

        </div>
    </section>

    <script>
        function selectWinner(button, teamId) {
            const container = button.parentElement;
            container.querySelectorAll('.btn-select-winner').forEach(b => b.classList.remove('selected'));
            button.classList.add('selected');
            button.closest('.match-card').querySelector('input[name="winnerId"]').value = teamId;
        }
    </script>

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
            </div>
        </div>
    </footer>
</body>
</html>
