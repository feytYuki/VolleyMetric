<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="Model.*, DAO.*, java.util.*, java.text.SimpleDateFormat" %>
<%
    String username = (String) session.getAttribute("organizerUsername");
    String fullname = (String) session.getAttribute("organizerFullname");
    Integer organizerId = (Integer) session.getAttribute("organizerId");

    if (username == null || organizerId == null) {
        response.sendRedirect("OrganizerLogin.jsp");
        return;
    }

    // Load all completed tournaments belonging to this organizer
    TournamentDAO tournamentDAO = new TournamentDAO();
    List<Tournament> completedTournaments = tournamentDAO.getTournamentsByStatus("completed");
    List<Tournament> myTournaments = new ArrayList<>();
    for (Tournament t : completedTournaments) {
        if (t.getOrganizerId() == organizerId) {
            myTournaments.add(t);
        }
    }

    // Read request parameters
    String reportType = request.getParameter("reportType");
    String filterTourId = request.getParameter("tournamentId");
    String filterFrom = request.getParameter("fromDate");
    String filterTo = request.getParameter("toDate");

    if (reportType == null) {
        reportType = "tournament_summary";
    }

    SimpleDateFormat displayFmt = new SimpleDateFormat("dd MMM yyyy");
    SimpleDateFormat parseFmt = new SimpleDateFormat("yyyy-MM-dd");

    // ── Determine which tournaments match the filters ──────────────────────
    List<Tournament> filteredTournaments = new ArrayList<>();
    for (Tournament t : myTournaments) {
        if (filterTourId != null && !filterTourId.isEmpty() && !filterTourId.equals("all")) {
            if (t.getTournamentId() != Integer.parseInt(filterTourId)) {
                continue;
            }
        }
        try {
            if (filterFrom != null && !filterFrom.isEmpty()) {
                java.util.Date from = parseFmt.parse(filterFrom);
                if (t.getTournamentDate().before(from)) {
                    continue;
                }
            }
            if (filterTo != null && !filterTo.isEmpty()) {
                java.util.Date to = parseFmt.parse(filterTo);
                if (t.getTournamentDate().after(to)) {
                    continue;
                }
            }
        } catch (Exception ignored) {
        }
        filteredTournaments.add(t);
    }

    // ── Build report data per report type ─────────────────────────────────
    MatchDAO matchDAO = new MatchDAO();
    TeamRegistrationDAO teamRegDAO = new TeamRegistrationDAO();
    TeamMemberDAO teamMemberDAO = new TeamMemberDAO();

    // Summary stat counters
    int totalMatches = 0;
    int totalPlayers = 0;

    // Tournament Summary data: list of rows
    // Each row: tournamentName, date, location, category, type, teams, championName
    List<Map<String, String>> summaryRows = new ArrayList<>();

    // Team Standings data: list of rows per tournament
    // Each row: tournamentName, rank, teamName, W, L, SW, SL, PF, PA
    List<Map<String, String>> standingsRows = new ArrayList<>();

    // Player Statistics data: list of rows
    // Each row: tournamentName, teamName, playerName, position, jerseyNumber
    List<Map<String, String>> playerRows = new ArrayList<>();

    for (Tournament t : filteredTournaments) {
        int tid = t.getTournamentId();
        List<Match> allMatches = matchDAO.getMatchesByTournament(tid);
        List<Match> bracketMatches = matchDAO.getMatchesByTournamentAndType(tid, "bracket");
        List<TeamRegistration> teams = teamRegDAO.getApprovedTeamsByTournament(tid);

        totalMatches += allMatches.size();

        // Per-team stats maps
        Map<Integer, Integer> wins = new HashMap<>();
        Map<Integer, Integer> losses = new HashMap<>();
        Map<Integer, Integer> setsWon = new HashMap<>();
        Map<Integer, Integer> setsLost = new HashMap<>();
        Map<Integer, Integer> ptsFor = new HashMap<>();
        Map<Integer, Integer> ptsAgainst = new HashMap<>();

        for (Match m : allMatches) {
            if (m.getWinnerId() == null) {
                continue;
            }
            int t1 = m.getTeam1Id(), t2 = m.getTeam2Id(), winner = m.getWinnerId();
            int loser = (winner == t1) ? t2 : t1;
            wins.put(winner, wins.getOrDefault(winner, 0) + 1);
            losses.put(loser, losses.getOrDefault(loser, 0) + 1);
            int s1 = 0, s2 = 0, p1 = 0, p2 = 0;
            for (int i = 1; i <= 5; i++) {
                Integer sc1 = m.getSetScore(1, i), sc2 = m.getSetScore(2, i);
                if (sc1 != null && sc2 != null) {
                    p1 += sc1;
                    p2 += sc2;
                    if (sc1 > sc2) {
                        s1++;
                    } else if (sc2 > sc1) {
                        s2++;
                    }
                }
            }
            setsWon.put(t1, setsWon.getOrDefault(t1, 0) + s1);
            setsWon.put(t2, setsWon.getOrDefault(t2, 0) + s2);
            setsLost.put(t1, setsLost.getOrDefault(t1, 0) + s2);
            setsLost.put(t2, setsLost.getOrDefault(t2, 0) + s1);
            ptsFor.put(t1, ptsFor.getOrDefault(t1, 0) + p1);
            ptsFor.put(t2, ptsFor.getOrDefault(t2, 0) + p2);
            ptsAgainst.put(t1, ptsAgainst.getOrDefault(t1, 0) + p2);
            ptsAgainst.put(t2, ptsAgainst.getOrDefault(t2, 0) + p1);
        }

        // Find champion from bracket final
        String championName = "—";
        for (Match m : bracketMatches) {
            if ("Final".equals(m.getGroupName()) && m.getWinnerId() != null) {
                TeamRegistration champ = teamRegDAO.getRegistrationById(m.getWinnerId());
                if (champ != null) {
                    championName = champ.getTeamName();
                }
            }
        }

        // ── Tournament Summary row ────────────────────────────────────────
        Map<String, String> sr = new LinkedHashMap<>();
        sr.put("name", t.getTournamentName());
        sr.put("date", displayFmt.format(t.getTournamentDate()));
        sr.put("location", t.getLocation());
        sr.put("category", t.getCategory());
        sr.put("type", t.getTournamentType());
        sr.put("teams", String.valueOf(t.getCurrentTeams()));
        sr.put("champion", championName);
        summaryRows.add(sr);

        // ── Team Standings rows ───────────────────────────────────────────
        final Map<Integer, Integer> wFinal = wins;
        final Map<Integer, Integer> swFinal = setsWon;
        final Map<Integer, Integer> pfFinal = ptsFor;
        final Map<Integer, Integer> lFinal = losses;
        Collections.sort(teams, new Comparator<TeamRegistration>() {
            public int compare(TeamRegistration a, TeamRegistration b) {
                int wa = wFinal.getOrDefault(a.getRegistrationId(), 0);
                int wb = wFinal.getOrDefault(b.getRegistrationId(), 0);
                if (wa != wb) {
                    return wb - wa;
                }
                int sa = swFinal.getOrDefault(a.getRegistrationId(), 0);
                int sb = swFinal.getOrDefault(b.getRegistrationId(), 0);
                if (sa != sb) {
                    return sb - sa;
                }
                int pa = pfFinal.getOrDefault(a.getRegistrationId(), 0);
                int pb = pfFinal.getOrDefault(b.getRegistrationId(), 0);
                return pb - pa;
            }
        });
        int rank = 1;
        for (TeamRegistration team : teams) {
            int rid = team.getRegistrationId();
            int gp = wins.getOrDefault(rid, 0) + losses.getOrDefault(rid, 0);
            double avg = gp > 0 ? (double) ptsFor.getOrDefault(rid, 0) / gp : 0;
            Map<String, String> row = new LinkedHashMap<>();
            row.put("tournament", t.getTournamentName());
            row.put("rank", String.valueOf(rank++));
            row.put("team", team.getTeamName());
            row.put("w", String.valueOf(wins.getOrDefault(rid, 0)));
            row.put("l", String.valueOf(losses.getOrDefault(rid, 0)));
            row.put("sw", String.valueOf(setsWon.getOrDefault(rid, 0)));
            row.put("sl", String.valueOf(setsLost.getOrDefault(rid, 0)));
            row.put("pf", String.valueOf(ptsFor.getOrDefault(rid, 0)));
            row.put("pa", String.valueOf(ptsAgainst.getOrDefault(rid, 0)));
            row.put("avg", String.format("%.1f", avg));
            standingsRows.add(row);
        }

        // ── Player Statistics rows ────────────────────────────────────────
        for (TeamRegistration team : teams) {
            List<TeamMember> members = teamMemberDAO.getMembersByRegistrationId(team.getRegistrationId());
            totalPlayers += members.size();
            for (TeamMember member : members) {
                Map<String, String> row = new LinkedHashMap<>();
                row.put("tournament", t.getTournamentName());
                row.put("team", team.getTeamName());
                row.put("player", member.getMemberName());
                row.put("position", member.getPosition());
                row.put("jersey", String.valueOf(member.getJerseyNumber()));
                playerRows.add(row);
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Generate Report - VolleyMetric</title>
        <link rel="stylesheet" href="style.css">
        <style>
            /* ── Shared Organizer Theme ── */
            .user-info {
                display: flex;
                align-items: center;
                gap: 1rem;
            }
            .user-details {
                display: flex;
                flex-direction: column;
                align-items: flex-end;
                background: rgba(255,255,255,0.1);
                border: 1px solid rgba(255,255,255,0.2);
                border-radius: 8px;
                padding: 5px 12px;
                transition: all 0.3s;
                backdrop-filter: blur(6px);
            }

            .user-details:hover {
                background: rgba(255,255,255,0.18);
                border-color: rgba(255,255,255,0.35);
                transform: translateY(-2px);
                box-shadow: 0 4px 12px rgba(0,0,0,0.2);
            }

            .user-role-label {
                font-size: 0.72rem;
                font-weight: 600;
                color: rgba(255,255,255,0.6);
                padding: 0;
                margin: 0;
                text-transform: uppercase;
                letter-spacing: 0.05em;
            }

            .user-name {
                font-size: 0.92rem;
                font-weight: 600;
                color: #fff;
                padding: 0;
                margin: 0;
            }
            .btn-logout {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: #fff;
                padding: 0.6rem 1.5rem;
                text-decoration: none;
                border-radius: 5px;
                font-weight: 600;
                transition: all 0.3s;
            }
            .btn-logout:hover {
                transform: translateY(-2px);
                box-shadow: 0 4px 12px rgba(118,75,162,0.3);
            }

            /* ── Page Layout ── */
            .report-section {
                padding: 2.5rem 0;
                background-color: #f8f9fa;
                min-height: 80vh;
            }
            .page-header {
                text-align: center;
                margin-bottom: 2rem;
            }
            .page-title {
                font-size: 2.5rem;
                color: #1a1a2e;
                font-weight: 800;
                margin-bottom: 0.4rem;
            }
            .page-subtitle {
                font-size: 1.1rem;
                color: #666;
            }

            /* ── Report Type Tabs ── */
            .report-tabs {
                display: flex;
                gap: 0.75rem;
                justify-content: center;
                margin-bottom: 1.5rem;
                flex-wrap: wrap;
            }
            .tab-btn {
                padding: 0.55rem 1.4rem;
                border-radius: 50px;
                font-size: 0.9rem;
                font-weight: 600;
                border: 2px solid #667eea;
                cursor: pointer;
                text-decoration: none;
                background: white;
                color: #667eea;
                transition: all 0.2s;
            }
            .tab-btn.active, .tab-btn:hover {
                background: linear-gradient(135deg, #667eea, #764ba2);
                color: white;
                border-color: transparent;
            }

            /* ── Filter Panel ── */
            .filter-panel {
                background: white;
                border-radius: 16px;
                padding: 1.5rem;
                box-shadow: 0 4px 20px rgba(0,0,0,0.07);
                margin-bottom: 1.5rem;
                display: flex;
                gap: 1rem;
                align-items: flex-end;
                flex-wrap: wrap;
            }
            .filter-group {
                display: flex;
                flex-direction: column;
                gap: 0.4rem;
                flex: 1;
                min-width: 160px;
            }
            .filter-label {
                font-size: 0.82rem;
                font-weight: 600;
                color: #555;
                text-transform: uppercase;
                letter-spacing: 0.04em;
            }
            .filter-panel select, .filter-panel input[type="date"] {
                padding: 0.55rem 0.8rem;
                border: 1.5px solid #ddd;
                border-radius: 8px;
                font-size: 0.9rem;
                color: #333;
                background: #f9f9f9;
                transition: border 0.2s;
            }
            .filter-panel select:focus, .filter-panel input:focus {
                border-color: #667eea;
                outline: none;
            }
            .btn-generate {
                background: linear-gradient(135deg, #667eea, #764ba2);
                color: white;
                border: none;
                padding: 0.6rem 1.5rem;
                border-radius: 8px;
                font-size: 0.95rem;
                font-weight: 700;
                cursor: pointer;
                transition: all 0.3s;
                white-space: nowrap;
            }
            .btn-generate:hover {
                transform: translateY(-2px);
                box-shadow: 0 4px 12px rgba(118,75,162,0.3);
            }
            .btn-reset {
                background: white;
                color: #888;
                border: 1.5px solid #ddd;
                padding: 0.6rem 1.2rem;
                border-radius: 8px;
                font-size: 0.9rem;
                font-weight: 600;
                cursor: pointer;
                transition: all 0.2s;
                white-space: nowrap;
                text-decoration: none;
                display: inline-block;
            }
            .btn-reset:hover {
                background: #f8f9fa;
                color: #555;
            }

            /* ── Summary Stat Cards ── */
            .stats-grid {
                display: grid;
                grid-template-columns: repeat(4, 1fr);
                gap: 1rem;
                margin-bottom: 1.5rem;
            }
            .stat-card {
                background: white;
                border-radius: 14px;
                padding: 1.2rem 1.4rem;
                box-shadow: 0 4px 16px rgba(0,0,0,0.07);
            }
            .stat-label {
                font-size: 0.82rem;
                color: #888;
                font-weight: 600;
                text-transform: uppercase;
                letter-spacing: 0.04em;
                margin-bottom: 0.4rem;
            }
            .stat-value {
                font-size: 2rem;
                font-weight: 800;
                color: #1a1a2e;
            }
            .stat-icon {
                font-size: 1.8rem;
                float: right;
                margin-top: -0.2rem;
            }

            /* ── Report Table Card ── */
            .report-card {
                background: white;
                border-radius: 20px;
                box-shadow: 0 8px 30px rgba(0,0,0,0.08);
                overflow: hidden;
                margin-bottom: 2rem;
            }
            .report-card-header {
                padding: 1.2rem 1.5rem;
                display: flex;
                justify-content: space-between;
                align-items: center;
                border-bottom: 1.5px solid #f0f0f0;
                flex-wrap: wrap;
                gap: 0.75rem;
            }
            .report-card-title {
                font-size: 1.1rem;
                font-weight: 700;
                color: #1a1a2e;
            }
            .export-btns {
                display: flex;
                gap: 0.6rem;
            }
            .btn-export-csv {
                display: inline-flex;
                align-items: center;
                gap: 6px;
                background: #e8f5e9;
                border: 1.5px solid #4caf50;
                color: #2e7d32;
                padding: 0.45rem 1rem;
                border-radius: 8px;
                font-size: 0.85rem;
                font-weight: 700;
                cursor: pointer;
                text-decoration: none;
                transition: all 0.2s;
            }
            .btn-export-csv:hover {
                background: #c8e6c9;
            }
            .btn-export-pdf {
                display: inline-flex;
                align-items: center;
                gap: 6px;
                background: #ffebee;
                border: 1.5px solid #ef5350;
                color: #c62828;
                padding: 0.45rem 1rem;
                border-radius: 8px;
                font-size: 0.85rem;
                font-weight: 700;
                cursor: pointer;
                text-decoration: none;
                transition: all 0.2s;
            }
            .btn-export-pdf:hover {
                background: #ffcdd2;
            }

            /* ── Data Table ── */
            .data-table-wrap {
                overflow-x: auto;
            }
            .data-table {
                width: 100%;
                border-collapse: collapse;
            }
            .data-table thead tr {
                background: linear-gradient(135deg, #667eea, #764ba2);
            }
            .data-table th {
                padding: 0.9rem 1rem;
                text-align: left;
                color: white;
                font-weight: 700;
                font-size: 0.88rem;
                white-space: nowrap;
            }
            .data-table th:first-child {
                border-radius: 0;
            }
            .data-table td {
                padding: 0.85rem 1rem;
                border-bottom: 1px solid #f5f5f5;
                font-size: 0.9rem;
                color: #444;
            }
            .data-table tbody tr:hover {
                background: #fafafa;
            }
            .data-table tbody tr:last-child td {
                border-bottom: none;
            }
            .col-rank {
                font-weight: 800;
                color: #667eea;
                font-size: 1rem;
            }
            .col-name {
                font-weight: 600;
                color: #1a1a2e;
            }

            /* ── Category/Type badges ── */
            .badge {
                display: inline-block;
                padding: 0.2rem 0.65rem;
                border-radius: 20px;
                font-size: 0.78rem;
                font-weight: 700;
            }
            .badge-men    {
                background: #e3f2fd;
                color: #1565c0;
            }
            .badge-women  {
                background: #fce4ec;
                color: #880e4f;
            }
            .badge-mixed  {
                background: #e8eaf6;
                color: #283593;
            }
            .badge-indoor {
                background: #f3e5f5;
                color: #6a1b9a;
            }
            .badge-beach  {
                background: #e8f5e9;
                color: #1b5e20;
            }

            /* ── Empty State ── */
            .empty-state {
                text-align: center;
                padding: 3rem 2rem;
            }
            .empty-state h3 {
                font-size: 1.5rem;
                color: #2c3e50;
                margin-bottom: 0.75rem;
            }
            .empty-state p  {
                color: #888;
                font-size: 1rem;
            }

            /* ── Alert ── */
            .alert {
                padding: 1rem 1.4rem;
                border-radius: 12px;
                margin-bottom: 1.5rem;
                font-weight: 600;
            }
            .alert-info {
                background: #e3f2fd;
                border: 2px solid #1976d2;
                color: #0d47a1;
            }

            @media (max-width: 768px) {
                .stats-grid {
                    grid-template-columns: repeat(2, 1fr);
                }
                .filter-panel {
                    flex-direction: column;
                }
            }
        </style>
    </head>
    <body>
        <header class="header">
            <div class="container">
                <div class="logo">
                    <div style="width:40px;height:40px;overflow:hidden;background:white;border:2px solid red;">
                        <img src="umtlogo.png" alt="UMT Logo" style="width:100%;height:100%;object-fit:contain;">
                    </div>
                    <span class="logo-icon">🏐</span>
                    <span class="logo-text">VolleyMetric</span>
                </div>
                <nav class="nav">
                    <ul class="nav-list">
                        <li><a href="OrganizerHome.jsp"       class="nav-link">Home</a></li>
                        <li><a href="OrganizerTournament.jsp" class="nav-link">Tournaments</a></li>
                        <li><a href="OrganizerSchedule.jsp"   class="nav-link">Schedule</a></li>
                        <li><a href="OrganizerResult.jsp"     class="nav-link">Results</a></li>
                        <li><a href="OrganizerReport.jsp"     class="nav-link active">Reports</a></li>
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

        <section class="report-section">
            <div class="container">

                <div class="page-header">
                    <h1 class="page-title">📊 Generate Report</h1>
                    <p class="page-subtitle">Select a report type, apply filters, then export to PDF or CSV</p>
                </div>

                <!-- Report type tabs -->
                <div class="report-tabs">
                    <a href="OrganizerReport.jsp?reportType=tournament_summary&tournamentId=<%= filterTourId != null ? filterTourId : "all"%>&fromDate=<%= filterFrom != null ? filterFrom : ""%>&toDate=<%= filterTo != null ? filterTo : ""%>"
                       class="tab-btn <%= "tournament_summary".equals(reportType) ? "active" : ""%>">🏆 Tournament Summary</a>
                    <a href="OrganizerReport.jsp?reportType=team_standings&tournamentId=<%= filterTourId != null ? filterTourId : "all"%>&fromDate=<%= filterFrom != null ? filterFrom : ""%>&toDate=<%= filterTo != null ? filterTo : ""%>"
                       class="tab-btn <%= "team_standings".equals(reportType) ? "active" : ""%>">👥 Team Standings</a>
                    <a href="OrganizerReport.jsp?reportType=player_statistics&tournamentId=<%= filterTourId != null ? filterTourId : "all"%>&fromDate=<%= filterFrom != null ? filterFrom : ""%>&toDate=<%= filterTo != null ? filterTo : ""%>"
                       class="tab-btn <%= "player_statistics".equals(reportType) ? "active" : ""%>">🏃 Team Roster</a>
                </div>

                <!-- Filter Panel -->
                <form method="GET" action="OrganizerReport.jsp">
                    <input type="hidden" name="reportType" value="<%= reportType%>">
                    <div class="filter-panel">
                        <div class="filter-group">
                            <label class="filter-label">Tournament</label>
                            <select name="tournamentId">
                                <option value="all" <%= (filterTourId == null || "all".equals(filterTourId)) ? "selected" : ""%>>All tournaments</option>
                                <% for (Tournament t : myTournaments) {%>
                                <option value="<%= t.getTournamentId()%>"
                                        <%= String.valueOf(t.getTournamentId()).equals(filterTourId) ? "selected" : ""%>>
                                    <%= t.getTournamentName()%>
                                </option>
                                <% }%>
                            </select>
                        </div>
                        <div class="filter-group">
                            <label class="filter-label">From date</label>
                            <input type="date" name="fromDate" value="<%= filterFrom != null ? filterFrom : ""%>">
                        </div>
                        <div class="filter-group">
                            <label class="filter-label">To date</label>
                            <input type="date" name="toDate" value="<%= filterTo != null ? filterTo : ""%>">
                        </div>
                        <button type="submit" class="btn-generate">🔍 Generate</button>
                        <a href="OrganizerReport.jsp" class="btn-reset">Reset</a>
                    </div>
                </form>

                <!-- Summary Stat Cards -->
                <div class="stats-grid">
                    <div class="stat-card">
                        <div class="stat-icon">🏆</div>
                        <div class="stat-label">Tournaments</div>
                        <div class="stat-value"><%= filteredTournaments.size()%></div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon">👥</div>
                        <div class="stat-label">Teams participated</div>
                        <div class="stat-value"><%= standingsRows.size()%></div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon">⚡</div>
                        <div class="stat-label">Matches played</div>
                        <div class="stat-value"><%= totalMatches%></div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon">🏃</div>
                        <div class="stat-label">Total players</div>
                        <div class="stat-value"><%= totalPlayers%></div>
                    </div>
                </div>

                <!-- No data state -->
                <% if (filteredTournaments.isEmpty()) { %>
                <div class="report-card">
                    <div class="empty-state">
                        <h3>📋 No data found</h3>
                        <p>No completed tournaments match your filter criteria. Try adjusting the filters above.</p>
                    </div>
                </div>
                <% } else { %>

                <!-- ══ TOURNAMENT SUMMARY ══════════════════════════════════════════ -->
                <% if ("tournament_summary".equals(reportType)) {%>
                <div class="report-card">
                    <div class="report-card-header">
                        <span class="report-card-title">🏆 Tournament Summary</span>
                        <div class="export-btns">
                            <a href="GenerateReportServlet?reportType=tournament_summary&format=csv&tournamentId=<%= filterTourId != null ? filterTourId : "all"%>&fromDate=<%= filterFrom != null ? filterFrom : ""%>&toDate=<%= filterTo != null ? filterTo : ""%>"
                               class="btn-export-csv">📄 Export CSV</a>
                            <a href="GenerateReportServlet?reportType=tournament_summary&format=pdf&tournamentId=<%= filterTourId != null ? filterTourId : "all"%>&fromDate=<%= filterFrom != null ? filterFrom : ""%>&toDate=<%= filterTo != null ? filterTo : ""%>"
                               class="btn-export-pdf">📑 Export PDF</a>
                        </div>
                    </div>
                    <div class="data-table-wrap">
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>#</th>
                                    <th>Tournament name</th>
                                    <th>Date</th>
                                    <th>Location</th>
                                    <th>Category</th>
                                    <th>Type</th>
                                    <th>Teams</th>
                                    <th>Champion</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% int i = 1;
                            for (Map<String, String> row : summaryRows) {%>
                                <tr>
                                    <td class="col-rank"><%= i++%></td>
                                    <td class="col-name"><%= row.get("name")%></td>
                                    <td><%= row.get("date")%></td>
                                    <td><%= row.get("location")%></td>
                                    <td>
                                        <span class="badge <%="men".equalsIgnoreCase(row.get("category")) ? "badge-men" : "women".equalsIgnoreCase(row.get("category")) ? "badge-women" : "badge-mixed"%>">
                                            <%= row.get("category").substring(0, 1).toUpperCase() + row.get("category").substring(1)%>
                                        </span>
                                    </td>
                                    <td>
                                        <span class="badge <%="indoor".equalsIgnoreCase(row.get("type")) ? "badge-indoor" : "badge-beach"%>">
                                            <%= row.get("type").substring(0, 1).toUpperCase() + row.get("type").substring(1)%>
                                        </span>
                                    </td>
                                    <td><%= row.get("teams")%></td>
                                    <td>🥇 <%= row.get("champion")%></td>
                                </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
                <% } %>

                <!-- ══ TEAM STANDINGS ════════════════════════════════════════════ -->
                <% if ("team_standings".equals(reportType)) {%>
                <div class="report-card">
                    <div class="report-card-header">
                        <span class="report-card-title">👥 Team Standings</span>
                        <div class="export-btns">
                            <a href="GenerateReportServlet?reportType=team_standings&format=csv&tournamentId=<%= filterTourId != null ? filterTourId : "all"%>&fromDate=<%= filterFrom != null ? filterFrom : ""%>&toDate=<%= filterTo != null ? filterTo : ""%>"
                               class="btn-export-csv">📄 Export CSV</a>
                            <a href="GenerateReportServlet?reportType=team_standings&format=pdf&tournamentId=<%= filterTourId != null ? filterTourId : "all"%>&fromDate=<%= filterFrom != null ? filterFrom : ""%>&toDate=<%= filterTo != null ? filterTo : ""%>"
                               class="btn-export-pdf">📑 Export PDF</a>
                        </div>
                    </div>
                    <div class="data-table-wrap">
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>Rank</th>
                                    <th>Tournament</th>
                                    <th>Team name</th>
                                    <th>W</th>
                                    <th>L</th>
                                    <th>Sets W</th>
                                    <th>Sets L</th>
                                    <th>Pts For</th>
                                    <th>Pts Against</th>
                                    <th>Avg Pts/Match</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% for (Map<String, String> row : standingsRows) {%>
                                <tr>
                                    <td class="col-rank">#<%= row.get("rank")%></td>
                                    <td><%= row.get("tournament")%></td>
                                    <td class="col-name"><%= row.get("team")%></td>
                                    <td><%= row.get("w")%></td>
                                    <td><%= row.get("l")%></td>
                                    <td><%= row.get("sw")%></td>
                                    <td><%= row.get("sl")%></td>
                                    <td><%= row.get("pf")%></td>
                                    <td><%= row.get("pa")%></td>
                                    <td><%= row.get("avg")%></td>
                                </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
                <% } %>

                <!-- ══ PLAYER STATISTICS ══════════════════════════════════════════ -->
                <% if ("player_statistics".equals(reportType)) {%>
                <div class="report-card">
                    <div class="report-card-header">
                        <span class="report-card-title">🏃 Player Statistics</span>
                        <div class="export-btns">
                            <a href="GenerateReportServlet?reportType=player_statistics&format=csv&tournamentId=<%= filterTourId != null ? filterTourId : "all"%>&fromDate=<%= filterFrom != null ? filterFrom : ""%>&toDate=<%= filterTo != null ? filterTo : ""%>"
                               class="btn-export-csv">📄 Export CSV</a>
                            <a href="GenerateReportServlet?reportType=player_statistics&format=pdf&tournamentId=<%= filterTourId != null ? filterTourId : "all"%>&fromDate=<%= filterFrom != null ? filterFrom : ""%>&toDate=<%= filterTo != null ? filterTo : ""%>"
                               class="btn-export-pdf">📑 Export PDF</a>
                        </div>
                    </div>
                    <div class="data-table-wrap">
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>#</th>
                                    <th>Tournament</th>
                                    <th>Team</th>
                                    <th>Player name</th>
                                    <th>Position</th>
                                    <th>Jersey no.</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% int j = 1;
                            for (Map<String, String> row : playerRows) {%>
                                <tr>
                                    <td class="col-rank"><%= j++%></td>
                                    <td><%= row.get("tournament")%></td>
                                    <td><%= row.get("team")%></td>
                                    <td class="col-name"><%= row.get("player")%></td>
                                    <td><%= row.get("position").substring(0, 1).toUpperCase() + row.get("position").substring(1).replace("_", " ")%></td>
                                    <td><strong>#<%= row.get("jersey")%></strong></td>
                                </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
                <% } %>

                <% }%>
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
                            <li><a href="OrganizerHome.jsp">Home</a></li>
                            <li><a href="OrganizerTournament.jsp">Tournaments</a></li>
                            <li><a href="OrganizerSchedule.jsp">Schedule</a></li>
                            <li><a href="OrganizerResult.jsp">Results</a></li>
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
