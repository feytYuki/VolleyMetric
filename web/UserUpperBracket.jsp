<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="Model.*, DAO.*, java.util.*" %>
<%
    String username = (String) session.getAttribute("username");
    String fullname = (String) session.getAttribute("fullname");
    Integer userId = (Integer) session.getAttribute("userId");
    
    if (username == null) { response.sendRedirect("Login.jsp"); return; }

    String idParam = request.getParameter("id");
    if (idParam == null) { response.sendRedirect("UserTournament.jsp"); return; }
    
    int tId = Integer.parseInt(idParam);
    Tournament tournament = new TournamentDAO().getTournamentById(tId);

    if (tournament == null) {
        response.sendRedirect("UserTournament.jsp");
        return;
    }

    List<Match> bracketMatches = new MatchDAO().getMatchesByTournamentAndType(tId, "bracket");
    TeamRegistrationDAO teamRegDAO = new TeamRegistrationDAO();

    Map<String, Match> bMap = new HashMap<>();
    for(Match m : bracketMatches) {
        bMap.put(m.getGroupName(), m);
    }

    // Self-heal: if SF winners known but Final teams missing, seed the Final row
    {
        Match _sf1 = bMap.get("SF1");
        Match _sf2 = bMap.get("SF2");
        if (_sf1 != null && _sf1.getWinnerId() != null
         && _sf2 != null && _sf2.getWinnerId() != null) {
            Match _final = bMap.get("Final");
            boolean finalMissing  = (_final == null);
            boolean finalNotReady = (_final != null && _final.getWinnerId() == null
                                     && (_final.getTeam1Id() <= 0 || _final.getTeam2Id() <= 0));
            if (finalMissing || finalNotReady) {
                MatchDAO healDAO = new MatchDAO();
                healDAO.deleteMatchesByTournamentAndStages(tId, new String[]{"Final"});
                healDAO.createBracketMatch(tId, _sf1.getWinnerId(), _sf2.getWinnerId(), "Final");
                bracketMatches = new MatchDAO().getMatchesByTournamentAndType(tId, "bracket");
                bMap.clear();
                for (Match m : bracketMatches) { bMap.put(m.getGroupName(), m); }
            }
        }
    }
%>
<%!
    public String getTeamName(int teamId, TeamRegistrationDAO dao) {
        if (teamId <= 0) return "TBD";
        TeamRegistration t = dao.getRegistrationById(teamId);
        return (t != null) ? t.getTeamName() : "Unknown";
    }
    public String getTeamNameById(Integer id, TeamRegistrationDAO dao) {
        if (id == null || id <= 0) return "TBD";
        TeamRegistration t = dao.getRegistrationById(id);
        return (t != null) ? t.getTeamName() : "Unknown";
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Elimination Stage - VolleyMetric</title>
    <link rel="stylesheet" href="style.css">
    <style>
        /* Shared Styles */
        .bracket-section { padding: 4rem 0; background-color: #f8f9fa; min-height: 100vh; }
        .bracket-container { overflow-x: auto; padding: 40px; text-align: center; }
        
        .bracket { display: flex; justify-content: center; align-items: center; }
        .round { display: flex; flex-direction: column; justify-content: space-around; list-style: none; padding: 0; margin: 0 40px; width: 200px; }
        .match-box { background: #fff; border: 1px solid #ccc; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); margin: 20px 0; position: relative; z-index: 10; }
        .team { padding: 10px; font-weight: 600; font-size: 0.9rem; display: flex; justify-content: space-between; height: 40px; align-items: center; }
        .team:first-child { border-bottom: 1px solid #eee; }

        /* Connector Lines */
        .round .match-box::after { content: ''; position: absolute; right: -20px; top: 50%; width: 20px; height: 2px; background: #ccc; }
        .round-qf .match-box:nth-child(odd)::after { bottom: -50%; top: auto; right: -20px; width: 20px; height: calc(100% + 40px); border-right: 2px solid #ccc; border-top: 2px solid #ccc; background: transparent; }
        .round-qf .match-box:nth-child(even)::after { top: -50%; right: -20px; width: 20px; height: calc(100% + 40px); border-right: 2px solid #ccc; border-bottom: 2px solid #ccc; background: transparent; }
        .round-sf .match-box::after { width: 40px; right: -40px; }
        .round-final .match-box::after { display: none; }
        .round-final .match-box { border: 2px solid #764ba2; transform: scale(1.1); }
        .final-header { background: linear-gradient(135deg, #667eea, #764ba2); color: white; justify-content: center; }

        /* Match Card Styles (Read-Only) */
        .matches-list { display: flex; flex-direction: column; gap: 2rem; max-width: 1000px; margin: 4rem auto 0; }
        .match-card { background: white; border-radius: 20px; padding: 2rem; box-shadow: 0 8px 30px rgba(0,0,0,0.1); transition: all 0.3s; }
        .match-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem; padding-bottom: 1rem; border-bottom: 3px solid #f0f0f0; }
        .match-title { font-size: 1.4rem; font-weight: 700; color: #667eea; }
        
        .match-teams { display: grid; grid-template-columns: 1fr auto 1fr; gap: 2rem; align-items: center; margin-bottom: 2rem; }
        .team-box { padding: 1.5rem; border: 3px solid #e0e0e0; border-radius: 15px; font-weight: 700; font-size: 1.2rem; text-align: center; background: #fafafa; }
        .team-box.winner { border-color: #28a745; background: linear-gradient(135deg, #d4edda, #c3e6cb); box-shadow: 0 4px 15px rgba(40, 167, 69, 0.2); }
        .vs-text { font-size: 1.5rem; font-weight: 800; color: #999; background: #f8f9fa; width: 60px; height: 60px; display: flex; align-items: center; justify-content: center; border-radius: 50%; border: 3px solid #e0e0e0; }

        /* Score Display */
        .sets-display { margin-top: 2rem; padding: 2rem; background: linear-gradient(135deg, #f8f9fa, #e9ecef); border-radius: 15px; border: 2px solid #dee2e6; }
        .set-row { display: grid; grid-template-columns: 1fr auto 1fr; gap: 2rem; align-items: center; margin-bottom: 1rem; background: white; padding: 1rem; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.05); }
        .score-display { text-align: center; font-weight: 700; font-size: 1.5rem; color: #2c3e50; }
        .set-label { font-weight: 700; color: white; background: linear-gradient(135deg, #667eea, #764ba2); padding: 0.5rem 1.5rem; border-radius: 50px; }
        
        .status-completed { background: #28a745; color: white; padding: 0.5rem 1rem; border-radius: 50px; font-size: 0.8rem; font-weight: bold; }
        .status-pending { background: #ffc107; color: white; padding: 0.5rem 1rem; border-radius: 50px; font-size: 0.8rem; font-weight: bold; }

        /* Header/Footer */
        .user-info { display: flex; align-items: center; gap: 1rem; }
        .user-details { display: flex; flex-direction: column; align-items: flex-end; background: white; border: 2px solid red; border-radius: 5px; padding: 4px 10px; }
        .user-role-label { font-size: 0.8rem; font-weight: 600; color: #ff6b6b; }
        .user-name { font-size: 0.95rem; font-weight: 600; color: #000; }
        .btn-logout { background-color: #ff6b6b; color: #fff; padding: 0.6rem 1.5rem; text-decoration: none; border-radius: 5px; font-weight: 600; }
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

    <section class="bracket-section">
        <div class="container">
            <h1 style="text-align:center; margin-bottom: 2rem; color: #1a1a2e; font-size: 2.5rem; font-weight: 800;">
                <%= tournament.getTournamentName() %> - Elimination Stage
            </h1>

            <% if (bracketMatches.isEmpty()) { %>
                <div style="text-align: center; padding: 4rem; background: white; border-radius: 20px; box-shadow: 0 8px 30px rgba(0,0,0,0.1);">
                    <h2 style="color: #666; margin-bottom: 1.5rem;">Bracket Not Yet Available</h2>
                    <p style="color: #888;">The elimination stage matches have not been generated by the organizer yet.</p>
                </div>
            <% } else { %>

            <div class="bracket-container">
                <div class="bracket">
                    <% if (bracketMatches.size() >= 7) { %>
                        <ul class="round round-qf"> 
                            <li class="match-box"><div class="team"><span><%= getTeamName(bMap.get("QF1").getTeam1Id(), teamRegDAO) %></span></div><div class="team"><span><%= getTeamName(bMap.get("QF1").getTeam2Id(), teamRegDAO) %></span></div></li>
                            <li class="match-box"><div class="team"><span><%= getTeamName(bMap.get("QF2").getTeam1Id(), teamRegDAO) %></span></div><div class="team"><span><%= getTeamName(bMap.get("QF2").getTeam2Id(), teamRegDAO) %></span></div></li>
                        </ul>
                        <ul class="round round-sf"> 
                            <li class="match-box"><div class="team"><span><%= getTeamName(bMap.get("SF1").getTeam1Id(), teamRegDAO) %></span></div><div class="team"><span><%= getTeamName(bMap.get("SF1").getTeam2Id(), teamRegDAO) %></span></div></li>
                        </ul>
                        <ul class="round round-final"> 
                            <li class="match-box"><div class="team final-header">FINAL</div><div class="team" style="justify-content:center;"><%= (bMap.get("Final").getWinnerId() != null) ? getTeamName(bMap.get("Final").getWinnerId(), teamRegDAO) : "TBD" %></div></li>
                        </ul>
                        <ul class="round round-sf"> 
                            <li class="match-box"><div class="team"><span><%= getTeamName(bMap.get("SF2").getTeam1Id(), teamRegDAO) %></span></div><div class="team"><span><%= getTeamName(bMap.get("SF2").getTeam2Id(), teamRegDAO) %></span></div></li>
                        </ul>
                        <ul class="round round-qf"> 
                            <li class="match-box"><div class="team"><span><%= getTeamName(bMap.get("QF3").getTeam1Id(), teamRegDAO) %></span></div><div class="team"><span><%= getTeamName(bMap.get("QF3").getTeam2Id(), teamRegDAO) %></span></div></li>
                            <li class="match-box"><div class="team"><span><%= getTeamName(bMap.get("QF4").getTeam1Id(), teamRegDAO) %></span></div><div class="team"><span><%= getTeamName(bMap.get("QF4").getTeam2Id(), teamRegDAO) %></span></div></li>
                        </ul>
                    <% } else if (bracketMatches.size() >= 3) {
                        Match uSF1 = bMap.get("SF1"), uSF2 = bMap.get("SF2"), uFinal = bMap.get("Final");
                    %>
                        <ul class="round round-sf"><li class="match-box">
                            <div class="team"><span><%= uSF1 != null ? getTeamName(uSF1.getTeam1Id(), teamRegDAO) : "TBD" %></span></div>
                            <div class="team"><span><%= uSF1 != null ? getTeamName(uSF1.getTeam2Id(), teamRegDAO) : "TBD" %></span></div>
                        </li></ul>
                        <ul class="round round-final"><li class="match-box">
                            <div class="team final-header">FINAL</div>
                            <div class="team" style="justify-content:center;">
                                <%= (uFinal != null && uFinal.getWinnerId() != null) ? getTeamNameById(uFinal.getWinnerId(), teamRegDAO) : "TBD" %>
                            </div>
                        </li></ul>
                        <ul class="round round-sf"><li class="match-box">
                            <div class="team"><span><%= uSF2 != null ? getTeamName(uSF2.getTeam1Id(), teamRegDAO) : "TBD" %></span></div>
                            <div class="team"><span><%= uSF2 != null ? getTeamName(uSF2.getTeam2Id(), teamRegDAO) : "TBD" %></span></div>
                        </li></ul>
                    <% } else {
                        Match uFinal = bMap.get("Final");
                        String ufT1 = (uFinal != null) ? getTeamName(uFinal.getTeam1Id(), teamRegDAO) : "TBD";
                        String ufT2 = (uFinal != null) ? getTeamName(uFinal.getTeam2Id(), teamRegDAO) : "TBD";
                        String ufWinner = (uFinal != null && uFinal.getWinnerId() != null)
                                          ? getTeamNameById(uFinal.getWinnerId(), teamRegDAO) : "TBD";
                    %>
                        <div style="display:flex; align-items:center; justify-content:center; gap:1.5rem; padding: 2rem 0;">

                            <%-- Grand Final box — keeps original match-box design --%>
                            <ul class="round round-final" style="margin:0;">
                                <li class="match-box" style="transform: scale(1.3);">
                                    <div class="team final-header">GRAND FINAL</div>
                                    <div class="team" style="justify-content:center;">
                                        <%= ufT1 %> vs <%= ufT2 %>
                                    </div>
                                </li>
                            </ul>

                            <%-- Arrow --%>
                            <div style="font-size:1.8rem; color:#aaa; margin: 0 0.5rem;">→</div>

                            <%-- Champion node --%>
                            <div style="
                                background: linear-gradient(135deg,#f7c948,#f5a623);
                                color: #fff;
                                border: 2px solid #e6971a;
                                border-radius: 10px;
                                padding: .6rem .8rem;
                                width: 150px;
                                text-align: center;
                                font-weight: 700;
                                font-size: .9rem;
                                box-shadow: 0 2px 8px rgba(0,0,0,.12);
                                transform: scale(1.3);
                            ">
                                🏅 Champion
                                <div style="font-size:.75rem; font-weight:400; margin-top:.3rem; opacity:.9;">
                                    <%= ufWinner %>
                                </div>
                            </div>

                        </div>
                    <% } %>
                </div>
            </div>

            <h2 style="text-align:center; margin-top: 3rem; font-weight: 800; color:#333;">⚔️ Match Results</h2>
            <div class="matches-list">
                <% for (Match m : bracketMatches) { 
                    TeamRegistration t1 = (m.getTeam1Id() > 0) ? teamRegDAO.getRegistrationById(m.getTeam1Id()) : null;
                    TeamRegistration t2 = (m.getTeam2Id() > 0) ? teamRegDAO.getRegistrationById(m.getTeam2Id()) : null;
                    String t1Name = (t1 != null) ? t1.getTeamName() : "TBD";
                    String t2Name = (t2 != null) ? t2.getTeamName() : "TBD";
                    boolean isCompleted = m.getWinnerId() != null;
                %>
                <div class="match-card">
                    <div class="match-header">
                        <div class="match-title"><%= m.getGroupName() %> Match</div>
                        <div class="<%= isCompleted ? "status-completed" : "status-pending" %>">
                            <%= isCompleted ? "✓ Completed" : "○ Pending" %>
                        </div>
                    </div>
                    
                    <div class="match-teams">
                        <div class="team-box <%= (m.getWinnerId() != null && t1 != null && m.getWinnerId() == t1.getRegistrationId()) ? "winner" : "" %>">
                            🏐 <%= t1Name %>
                        </div>
                        <div class="vs-text">VS</div>
                        <div class="team-box <%= (m.getWinnerId() != null && t2 != null && m.getWinnerId() == t2.getRegistrationId()) ? "winner" : "" %>">
                            🏐 <%= t2Name %>
                        </div>
                    </div>

                    <% if (isCompleted) { %>
                    <div class="sets-display">
                        <div style="text-align:center; font-weight:bold; margin-bottom:1rem; color:#555;">Final Scores</div>
                        <% for(int i=1; i<=5; i++) { 
                            if(m.getSetScore(1, i) != null) { %>
                            <div class="set-row">
                                <div class="score-display"><%= m.getSetScore(1, i) %></div>
                                <span class="set-label">Set <%= i %></span>
                                <div class="score-display"><%= m.getSetScore(2, i) %></div>
                            </div>
                        <% }} %>
                    </div>
                    <% } else { %>
                        <p style="text-align:center; color:#999; font-style:italic; padding: 1rem;">Waiting for match results...</p>
                    <% } %>
                </div>
                <% } %>
            </div>
            <% } %>
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
                            <li><a href="#teams">Teams</a></li>
                            <li><a href="#contact">Contact</a></li>
                        </ul>
                    </div>
                    <div class="footer-section">
                        <h4 class="footer-heading">Resources</h4>
                        <ul class="footer-links">
                            <li><a href="#guide">User Guide</a></li>
                            <li><a href="#rules">Tournament Rules</a></li>
                            <li><a href="#faq">FAQ</a></li>
                            <li><a href="#support">Support</a></li>
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
</body>
</html>