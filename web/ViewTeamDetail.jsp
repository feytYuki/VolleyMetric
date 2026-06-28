<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="Model.Tournament, Model.TeamRegistration, Model.TeamMember" %>
<%@ page import="DAO.TournamentDAO, DAO.TeamRegistrationDAO, DAO.TeamMemberDAO" %>
<%@ page import="java.util.List" %>
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
        response.sendRedirect("UserTournament.jsp");
        return;
    }

    int tournamentId = Integer.parseInt(tournamentIdStr);

    // Get tournament details
    TournamentDAO tournamentDAO = new TournamentDAO();
    Tournament tournament = tournamentDAO.getTournamentById(tournamentId);

    if (tournament == null) {
        response.sendRedirect("UserTournament.jsp");
        return;
    }

    // Get all approved registrations for this tournament
    TeamRegistrationDAO teamRegDAO = new TeamRegistrationDAO();
    TeamMemberDAO teamMemberDAO = new TeamMemberDAO();
    List<TeamRegistration> registrations = teamRegDAO.getRegistrationsByTournament(tournamentId);

    // Filter only approved teams
    List<TeamRegistration> approvedTeams = new java.util.ArrayList<>();
    for (TeamRegistration reg : registrations) {
        if ("approved".equalsIgnoreCase(reg.getStatus())) {
            approvedTeams.add(reg);
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Tournament Teams - VolleyMetric</title>
        <link rel="stylesheet" href="style.css">
        <style>
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
                background-color: #ff6b6b;
                color: #fff;
                padding: 0.6rem 1.5rem;
                text-decoration: none;
                border-radius: 5px;
                transition: all 0.3s;
                font-weight: 600;
            }

            .detail-section {
                padding: 4rem 0;
                background-color: #f8f9fa;
                min-height: 80vh;
            }

            .detail-container {
                max-width: 1400px;
                margin: 0 auto;
            }

            .tournament-header {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 2.5rem;
                border-radius: 15px;
                margin-bottom: 3rem;
                box-shadow: 0 10px 30px rgba(102, 126, 234, 0.3);
            }

            .tournament-title {
                font-size: 2.5rem;
                margin-bottom: 1.5rem;
                font-weight: 700;
            }

            .tournament-meta {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                gap: 1.5rem;
            }

            .meta-item {
                font-size: 1.1rem;
                display: flex;
                align-items: center;
                gap: 0.5rem;
            }

            .section-header {
                display: flex;
                justify-content: space-between;
                align-items: center;
                margin-bottom: 2rem;
            }

            .section-title {
                font-size: 2rem;
                color: #1a1a2e;
                font-weight: 700;
            }

            .team-count {
                font-size: 1.2rem;
                color: #667eea;
                font-weight: 600;
            }

            .teams-grid {
                display: grid;
                grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
                gap: 2rem;
                margin-bottom: 3rem;
            }

            .team-card {
                background: white;
                border-radius: 15px;
                padding: 2rem;
                box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
                transition: all 0.3s ease;
                border: 2px solid transparent;
                cursor: pointer;
                text-decoration: none;
                display: block;
                color: inherit;
            }

            .team-card:hover {
                transform: translateY(-5px);
                box-shadow: 0 8px 30px rgba(102, 126, 234, 0.2);
                border-color: #667eea;
            }

            .team-card-header {
                display: flex;
                align-items: center;
                justify-content: space-between;
                margin-bottom: 1.5rem;
                padding-bottom: 1rem;
                border-bottom: 3px solid #f0f0f0;
            }

            .team-name-section {
                display: flex;
                align-items: center;
                gap: 1rem;
                flex: 1;
            }

            .team-icon {
                width: 50px;
                height: 50px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                border-radius: 10px;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 1.8rem;
                flex-shrink: 0;
            }

            .team-name {
                font-size: 1.5rem;
                font-weight: 700;
                color: #1a1a2e;
                line-height: 1.2;
            }

            .status-badge {
                padding: 0.4rem 0.8rem;
                border-radius: 20px;
                font-size: 0.85rem;
                font-weight: 600;
                color: white;
                background-color: #27ae60;
            }

            .team-info {
                display: flex;
                flex-direction: column;
                gap: 1rem;
            }

            .info-row {
                display: flex;
                align-items: center;
                gap: 0.5rem;
                font-size: 1rem;
                color: #555;
            }

            .info-label {
                font-weight: 600;
                color: #333;
            }

            .member-preview {
                margin-top: 1rem;
                padding: 1rem;
                background: #f8f9fa;
                border-radius: 10px;
            }

            .member-preview-title {
                font-size: 0.9rem;
                font-weight: 600;
                color: #666;
                margin-bottom: 0.5rem;
            }

            .member-count-badge {
                display: inline-block;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 0.3rem 0.8rem;
                border-radius: 20px;
                font-size: 0.9rem;
                font-weight: 600;
            }

            .no-teams {
                text-align: center;
                padding: 4rem;
                background: white;
                border-radius: 15px;
                box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
            }

            .no-teams h3 {
                font-size: 1.8rem;
                color: #1a1a2e;
                margin-bottom: 1rem;
            }

            .no-teams p {
                font-size: 1.1rem;
                color: #666;
            }

            .btn-back {
                display: inline-block;
                background-color: #e0e0e0;
                color: #333;
                padding: 0.8rem 2rem;
                text-decoration: none;
                border-radius: 8px;
                font-weight: 600;
                transition: all 0.3s;
            }

            .btn-back:hover {
                background-color: #d0d0d0;
                transform: translateX(-5px);
            }

            @media (max-width: 768px) {
                .teams-grid {
                    grid-template-columns: 1fr;
                }
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
                        <li><a href="UserTournament.jsp" class="nav-link active">Tournaments</a></li>
                        <li><a href="UserSchedule.jsp" class="nav-link">Schedule</a></li>
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

        <section class="detail-section">
            <div class="container">
                <div class="detail-container">
                    <div class="tournament-header">
                        <h1 class="tournament-title">🏐 <%= tournament.getTournamentName()%></h1>
                        <div class="tournament-meta">
                            <div class="meta-item">📍 <%= tournament.getLocation()%></div>
                            <div class="meta-item">📅 <%= new SimpleDateFormat("MMMM dd, yyyy").format(tournament.getTournamentDate())%></div>
                            <div class="meta-item">⏰ <%= new SimpleDateFormat("hh:mm a").format(tournament.getStartTime())%></div>
                            <div class="meta-item">👥 <%= approvedTeams.size()%>/<%= tournament.getMaxTeams()%> Teams Registered</div>
                            <div class="meta-item">🏆 <%= tournament.getCategory().toUpperCase()%> | <%= tournament.getTournamentType().toUpperCase()%></div>
                        </div>
                    </div>

                    <div class="section-header">
                        <h2 class="section-title">Registered Teams</h2>
                        <span class="team-count"><%= approvedTeams.size()%> Teams</span>
                    </div>

                    <% if (approvedTeams.isEmpty()) { %>
                    <div class="no-teams">
                        <h3>No Teams Registered Yet</h3>
                        <p>Be the first team to register for this tournament!</p>
                        <br>
                        <a href="UserTournament.jsp" class="btn-back">← Back to Tournaments</a>
                    </div>
                    <% } else { %>
                    <div class="teams-grid">
                        <% for (TeamRegistration team : approvedTeams) {
                                List<TeamMember> members = teamMemberDAO.getMembersByRegistrationId(team.getRegistrationId());
                                TeamMember captain = null;
                                for (TeamMember m : members) {
                                    if (m.isCaptain()) {
                                        captain = m;
                                        break;
                                    }
                                }
                        %>
                        <a href="ViewTeamMembers.jsp?registrationId=<%= team.getRegistrationId()%>" class="team-card">
                            <div class="team-card-header">
                                <div class="team-name-section">
                                    <div class="team-icon">🏐</div>
                                    <div class="team-name"><%= team.getTeamName()%></div>
                                </div>
                                <div class="status-badge">✓ Approved</div>
                            </div>

                            <div class="team-info">
                                <div class="info-row">
                                    <span class="info-label">⭐ Captain:</span>
                                    <span><%= captain != null ? captain.getMemberName() : team.getTeamLeaderName()%></span>
                                </div>

                                <div class="info-row">
                                    <span class="info-label">👥 Players:</span>
                                    <span><%= team.getNumberOfPlayers()%></span>
                                </div>

                                <div class="info-row">
                                    <span class="info-label">📅 Registered:</span>
                                    <span><%= new SimpleDateFormat("MMM dd, yyyy").format(team.getRegisteredAt())%></span>
                                </div>
                            </div>

                            <div class="member-preview">
                                <div class="member-preview-title">Team Members</div>
                                <span class="member-count-badge"><%= members.size()%> Players</span>
                            </div>
                        </a>
                        <% } %>
                    </div>

                    <div style="text-align: center; margin-top: 2rem;">
                        <a href="UserTournament.jsp" class="btn-back">← Back to Tournaments</a>
                    </div>
                    <% }%>
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