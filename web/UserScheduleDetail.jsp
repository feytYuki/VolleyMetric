<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="Model.Tournament, Model.TeamRegistration, Model.TournamentGroup, Model.Match" %>
<%@ page import="DAO.TournamentDAO, DAO.TeamRegistrationDAO, DAO.TournamentGroupDAO, DAO.MatchDAO" %>
<%@ page import="java.util.List, java.util.Map, java.util.HashMap" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    // Check if user is logged in
    String username = (String) session.getAttribute("username");
    String fullname = (String) session.getAttribute("fullname");
    Integer userId = (Integer) session.getAttribute("userId");
    
    if (username == null || userId == null) {
        response.sendRedirect("Login.jsp");
        return;
    }
    
    // Get tournament ID
    String tournamentIdStr = request.getParameter("id");
    if (tournamentIdStr == null) {
        response.sendRedirect("UserSchedule.jsp");
        return;
    }
    
    int tournamentId = Integer.parseInt(tournamentIdStr);
    
    // Get tournament details
    TournamentDAO tournamentDAO = new TournamentDAO();
    Tournament tournament = tournamentDAO.getTournamentById(tournamentId);
    
    if (tournament == null) {
        response.sendRedirect("UserSchedule.jsp");
        return;
    }
    
    // Get groups
    TournamentGroupDAO groupDAO = new TournamentGroupDAO();
    Map<String, List<TeamRegistration>> groups = groupDAO.getGroupsWithTeams(tournamentId);
    
    // Get matches
    MatchDAO matchDAO = new MatchDAO();
    List<Match> allMatches = matchDAO.getMatchesByTournament(tournamentId);
    
    // Filter to show only group/RR stage matches (exclude bracket: QF/SF/Final)
    List<Match> matches = new java.util.ArrayList<>();
    for (Match match : allMatches) {
        String groupName = match.getGroupName();
        if (groupName != null && (groupName.matches("[A-D]") || "RR".equals(groupName))) {
            matches.add(match);
        }
    }

    // RR tournament state
    boolean isRRTournament = false;
    int rrTotal = 0, rrCompleted = 0;
    for (Match m : matches) {
        if ("RR".equals(m.getGroupName())) {
            isRRTournament = true;
            rrTotal++;
            if (m.getWinnerId() != null) rrCompleted++;
        }
    }

    TeamRegistrationDAO teamRegDAO = new TeamRegistrationDAO();
    List<TeamRegistration> approvedTeams = teamRegDAO.getApprovedTeamsByTournament(tournamentId);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= tournament.getTournamentName() %> - Schedule</title>
    <link rel="stylesheet" href="style.css">
    <style>
        .user-info { display: flex; align-items: center; gap: 1rem; }
        .user-details { display: flex; flex-direction: column; align-items: flex-end; background: white; border: 2px solid red; border-radius: 5px; padding: 4px 10px; }
        .user-role-label { font-size: 0.8rem; font-weight: 600; color: #ff6b6b; }
        .user-name { font-size: 0.95rem; font-weight: 600; color: #000; }
        .btn-logout { background-color: #ff6b6b; color: #fff; padding: 0.6rem 1.5rem; text-decoration: none; border-radius: 5px; font-weight: 600; }

        .schedule-section { padding: 2rem 0; background-color: #f8f9fa; min-height: 80vh; }
        .page-title { font-size: 2.5rem; color: #1a1a2e; text-align: center; margin-bottom: 3rem; font-weight: 800; }
        
        /* Groups Section */
        .section-header { text-align: center; margin: 3rem 0 2rem; }
        .section-header h2 { font-size: 2rem; color: #1a1a2e; font-weight: 700; margin-bottom: 0.5rem; }
        .section-header p { color: #666; font-size: 1.1rem; }
        
        .groups-container { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); 
            gap: 2rem; 
            margin-bottom: 4rem; 
            max-width: 1400px;
            margin-left: auto;
            margin-right: auto;
        }
        
        .group-card { 
            background: white; 
            border-radius: 20px; 
            overflow: hidden; 
            box-shadow: 0 8px 30px rgba(0,0,0,0.12);
            transition: transform 0.3s, box-shadow 0.3s;
        }
        .group-card:hover {
            transform: translateY(-8px);
            box-shadow: 0 12px 40px rgba(0,0,0,0.18);
        }
        
        .group-header-a { 
            background: linear-gradient(135deg, #17a2b8, #138496); 
            color: white; 
            padding: 1.5rem; 
            text-align: center; 
            font-size: 1.8rem; 
            font-weight: 800;
            letter-spacing: 1px;
            text-transform: uppercase;
        }
        .group-header-b { 
            background: linear-gradient(135deg, #e83e8c, #d63384); 
            color: white; 
            padding: 1.5rem; 
            text-align: center; 
            font-size: 1.8rem; 
            font-weight: 800;
            letter-spacing: 1px;
            text-transform: uppercase;
        }
        .group-header-c { 
            background: linear-gradient(135deg, #28a745, #218838); 
            color: white; 
            padding: 1.5rem; 
            text-align: center; 
            font-size: 1.8rem; 
            font-weight: 800;
            letter-spacing: 1px;
            text-transform: uppercase;
        }
        .group-header-d { 
            background: linear-gradient(135deg, #ffc107, #e0a800); 
            color: white; 
            padding: 1.5rem; 
            text-align: center; 
            font-size: 1.8rem; 
            font-weight: 800;
            letter-spacing: 1px;
            text-transform: uppercase;
        }
        
        .group-teams { padding: 1.5rem; }
        .team-item { 
            padding: 1.2rem 1rem; 
            border-bottom: 2px solid #f0f0f0; 
            display: flex; 
            align-items: center; 
            gap: 1rem; 
            font-weight: 600; 
            color: #2c3e50;
            font-size: 1.1rem;
            transition: background 0.2s;
        }
        .team-item:hover {
            background: #f8f9fa;
        }
        .team-item:last-child { border-bottom: none; }
        .team-flag { 
            font-size: 2rem;
            width: 40px;
            height: 40px;
            display: flex;
            align-items: center;
            justify-content: center;
            background: linear-gradient(135deg, #667eea, #764ba2);
            border-radius: 50%;
        }
        
        /* Matches Section */
        .matches-list { 
            display: flex; 
            flex-direction: column; 
            gap: 1.5rem;
            max-width: 1000px;
            margin: 0 auto;
        }
        
        .match-card { 
            background: white; 
            border-radius: 15px; 
            padding: 1.5rem; 
            box-shadow: 0 4px 15px rgba(0,0,0,0.08);
            transition: all 0.3s;
        }
        .match-card:hover {
            box-shadow: 0 6px 20px rgba(0,0,0,0.12);
        }
        
        .match-header { 
            display: flex; 
            justify-content: space-between; 
            align-items: center; 
            margin-bottom: 1.5rem;
            padding-bottom: 0.75rem;
            border-bottom: 2px solid #f0f0f0;
        }
        .match-title { 
            font-size: 1.1rem; 
            font-weight: 700; 
            color: #667eea;
        }
        .match-status { 
            padding: 0.4rem 1rem; 
            border-radius: 50px; 
            font-size: 0.75rem; 
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .status-pending { 
            background: linear-gradient(135deg, #ffc107, #ffb300); 
            color: white;
            box-shadow: 0 2px 8px rgba(255, 193, 7, 0.3);
        }
        .status-completed { 
            background: linear-gradient(135deg, #28a745, #20c997); 
            color: white;
            box-shadow: 0 2px 8px rgba(40, 167, 69, 0.3);
        }
        
        .match-teams { 
            display: grid; 
            grid-template-columns: 1fr auto 1fr; 
            gap: 1.5rem; 
            align-items: center; 
            margin-bottom: 1.5rem;
        }
        
        .team-box { 
            padding: 1rem; 
            border: 2px solid #e0e0e0; 
            border-radius: 12px; 
            font-weight: 700;
            font-size: 1rem;
            text-align: center;
            transition: all 0.3s;
            background: #fafafa;
        }
        .team-box.winner { 
            border-color: #28a745; 
            background: linear-gradient(135deg, #d4edda, #c3e6cb);
            box-shadow: 0 2px 10px rgba(40, 167, 69, 0.2);
        }
        
        .vs-text { 
            font-size: 1.2rem; 
            font-weight: 800; 
            color: #999;
            background: #f8f9fa;
            width: 45px;
            height: 45px;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 50%;
            border: 2px solid #e0e0e0;
        }
        
        /* Score Display */
        .sets-display { 
            margin-top: 1.5rem; 
            padding: 1.5rem; 
            background: linear-gradient(135deg, #f8f9fa, #e9ecef);
            border-radius: 12px;
            border: 2px solid #dee2e6;
        }
        .sets-display > strong { 
            display: block; 
            margin-bottom: 1rem; 
            font-size: 1.1rem; 
            color: #2c3e50;
            text-align: center;
        }
        
        .set-row { 
            display: grid; 
            grid-template-columns: 1fr auto 1fr; 
            gap: 1.5rem; 
            align-items: center; 
            margin-bottom: 1rem;
            background: white;
            padding: 1rem;
            border-radius: 10px;
            box-shadow: 0 2px 6px rgba(0,0,0,0.04);
        }
        .set-row:last-child { margin-bottom: 0; }
        
        .set-label { 
            font-weight: 700; 
            color: #495057;
            font-size: 1rem;
            text-align: center;
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
            padding: 0.6rem 1.2rem;
            border-radius: 50px;
            min-width: 100px;
        }
        
        .score-display {
            text-align: center;
            font-weight: 700;
            font-size: 1.5rem;
            color: #2c3e50;
            padding: 0.3rem;
        }
        
        .pending-message {
            text-align: center;
            padding: 1.5rem;
            color: #666;
            font-style: italic;
            background: white;
            border-radius: 10px;
            margin-top: 0.5rem;
        }
        
        .empty-state { 
            text-align: center; 
            padding: 4rem 2rem; 
            background: white; 
            border-radius: 20px;
            box-shadow: 0 8px 30px rgba(0,0,0,0.1);
        }
        .empty-state h3 { 
            font-size: 1.8rem; 
            color: #2c3e50; 
            margin-bottom: 1rem;
        }
        .empty-state p { 
            color: #6c757d; 
            font-size: 1.1rem;
        }
        
        .btn-upper-bracket {
            display: inline-block;
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
            padding: 1.2rem 3rem;
            border-radius: 50px;
            font-weight: 700;
            font-size: 1.1rem;
            text-decoration: none;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
            transition: all 0.3s;
        }
        .btn-upper-bracket:hover {
            background: linear-gradient(135deg, #5568d3, #6a3f8f);
            transform: translateY(-3px);
            box-shadow: 0 6px 20px rgba(102, 126, 234, 0.4);
        }
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
                    <li><a href="UserHome.jsp" class="nav-link">Home</a></li>
                    <li><a href="UserTournament.jsp" class="nav-link">Tournaments</a></li>
                    <li><a href="UserSchedule.jsp" class="nav-link active">Schedule</a></li>
                    <li><a href="UserResult.jsp" class="nav-link">Results</a></li>
                </ul>
            </nav>
            <div class="header-actions">
                <div class="user-info">
                    <a href="UserProfile.jsp" class="user-details" style="text-decoration: none; cursor: pointer;">
                            <span class="user-role-label">User:</span>
                            <span class="user-name">👤 <%= fullname != null ? fullname : username%></span>
                        </a>
                    <a href="LogOutServlet" class="btn-logout">Logout</a>
                </div>
            </div>
        </div>
    </header>

    <section class="schedule-section">
        <div class="container">
            <h1 class="page-title"><%= tournament.getTournamentName() %></h1>
            
            <!-- Groups Section -->
            <% if (!groups.isEmpty()) { %>
                <div class="section-header">
                    <h2>🏆 Group Stage</h2>
                    <p>Teams are divided into groups for round-robin play</p>
                </div>
                <div class="groups-container">
                    <% 
                        String[] groupNames = {"A", "B", "C", "D"};
                        String[] headerClasses = {"group-header-a", "group-header-b", "group-header-c", "group-header-d"};
                        int groupIndex = 0;
                        for (String groupName : groupNames) {
                            List<TeamRegistration> groupTeams = groups.get(groupName);
                            if (groupTeams != null && !groupTeams.isEmpty()) {
                    %>
                    <div class="group-card">
                        <div class="<%= headerClasses[groupIndex] %>">GROUP <%= groupName %></div>
                        <div class="group-teams">
                            <% for (TeamRegistration team : groupTeams) { %>
                            <div class="team-item">
                                <span class="team-flag">🏐</span>
                                <span><%= team.getTeamName() %></span>
                            </div>
                            <% } %>
                        </div>
                    </div>
                    <% 
                            groupIndex++;
                            }
                        }
                    %>
                </div>
            <% } else if (isRRTournament) { %>
                <div class="section-header">
                    <h2>🔄 Round-Robin Stage</h2>
                    <p>Each team plays every other team once &mdash; top 2 advance to the Final</p>
                </div>
                <% if (rrTotal > 0 && rrCompleted == rrTotal) { %>
                <div class="alert" style="background:#e8f5e9;border:1px solid #43a047;color:#1b5e20;border-radius:10px;padding:1rem 1.5rem;margin-bottom:1rem;">
                    ✅ All round-robin matches complete! See the Elimination Stage for the Final.
                </div>
                <% } else { %>
                <div class="alert" style="background:#fff8e1;border:1px solid #f9a825;color:#7a5800;border-radius:10px;padding:1rem 1.5rem;margin-bottom:1rem;">
                    ⏳ Round-robin in progress: <strong><%= rrCompleted %> / <%= rrTotal %></strong> matches completed.
                </div>
                <% } %>
                <div class="groups-container">
                    <div class="group-card">
                        <div class="group-header-a">ROUND ROBIN</div>
                        <div class="group-teams">
                            <% for (TeamRegistration team : approvedTeams) { %>
                            <div class="team-item">
                                <span class="team-flag">🏐</span>
                                <span><%= team.getTeamName() %></span>
                            </div>
                            <% } %>
                        </div>
                    </div>
                </div>
            <% } %>
            
            <!-- Matches Section -->
            <% if (!matches.isEmpty()) { %>
                <div class="section-header">
                    <h2>⚔️ Matches</h2>
                    <p>Best of 3 sets - First to win 2 sets takes the match</p>
                </div>
                <div class="matches-list">
                    <% for (Match match : matches) { 
                        TeamRegistration team1 = teamRegDAO.getRegistrationById(match.getTeam1Id());
                        TeamRegistration team2 = teamRegDAO.getRegistrationById(match.getTeam2Id());
                        boolean isCompleted = match.getWinnerId() != null;
                    %>
                    <div class="match-card">
                        <div class="match-header">
                            <div class="match-title">
                                Match #<%= match.getMatchId() %> - Group <%= match.getGroupName() %>
                            </div>
                            <div class="match-status <%= isCompleted ? "status-completed" : "status-pending" %>">
                                <%= isCompleted ? "✓ Completed" : "○ Pending" %>
                            </div>
                        </div>
                        
                        <div class="match-teams">
                            <div class="team-box <%= (match.getWinnerId() != null && match.getWinnerId() == team1.getRegistrationId()) ? "winner" : "" %>">
                                🏐 <%= team1.getTeamName() %>
                            </div>
                            <div class="vs-text">VS</div>
                            <div class="team-box <%= (match.getWinnerId() != null && match.getWinnerId() == team2.getRegistrationId()) ? "winner" : "" %>">
                                🏐 <%= team2.getTeamName() %>
                            </div>
                        </div>
                        
                        <% if (isCompleted) { %>
                        <div class="sets-display">
                            <strong>📊 Final Score</strong>
                            <% 
                                boolean hasScores = false;
                                for (int i = 1; i <= 3; i++) { 
                                    Integer team1Score = match.getSetScore(1, i);
                                    Integer team2Score = match.getSetScore(2, i);
                                    if (team1Score != null && team2Score != null) {
                                        hasScores = true;
                            %>
                            <div class="set-row">
                                <div class="score-display"><%= team1Score %></div>
                                <span class="set-label">Set <%= i %></span>
                                <div class="score-display"><%= team2Score %></div>
                            </div>
                            <% 
                                    }
                                }
                                if (!hasScores) {
                            %>
                            <div class="pending-message">
                                Score details not yet available
                            </div>
                            <% } %>
                        </div>
                        <% } else { %>
                        <div class="pending-message">
                            ⏳ Match has not been played yet
                        </div>
                        <% } %>
                    </div>
                    <% } %>
                </div>
            <% } else if (!groups.isEmpty()) { %>
                <div class="empty-state">
                    <h3>📅 No Matches Yet</h3>
                    <p>Matches will be scheduled soon.</p>
                </div>
            <% } else { %>
                <div class="empty-state">
                    <h3>🏐 Tournament Schedule Not Ready</h3>
                    <p>Groups and matches have not been set up yet.</p>
                </div>
            <% } %>
            <div style="text-align: center; margin-top: 3rem; margin-bottom: 5rem;">
                <a href="UserUpperBracket.jsp?id=<%= tournamentId %>" class="btn-upper-bracket">
                    🏆 See Elimination Stage
                </a>
            </div>
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
            </div>
        </div>
    </footer>
</body>
</html>