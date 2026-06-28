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

    // Get registration ID from parameter
    String registrationIdStr = request.getParameter("registrationId");
    if (registrationIdStr == null) {
        response.sendRedirect("UserTournament.jsp");
        return;
    }

    int registrationId = Integer.parseInt(registrationIdStr);

    // Get registration details
    TeamRegistrationDAO teamRegDAO = new TeamRegistrationDAO();
    TeamMemberDAO teamMemberDAO = new TeamMemberDAO();
    TournamentDAO tournamentDAO = new TournamentDAO();

    TeamRegistration registration = teamRegDAO.getRegistrationById(registrationId);

    if (registration == null) {
        response.sendRedirect("UserTournament.jsp");
        return;
    }

    // Get tournament details
    Tournament tournament = tournamentDAO.getTournamentById(registration.getTournamentId());

    // Get team members
    List<TeamMember> members = teamMemberDAO.getMembersByRegistrationId(registrationId);
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Team Details - VolleyMetric</title>
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
                max-width: 1200px;
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
                font-size: 2rem;
                margin-bottom: 1rem;
                font-weight: 700;
            }

            .tournament-meta {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                gap: 1rem;
            }

            .meta-item {
                font-size: 1rem;
                display: flex;
                align-items: center;
                gap: 0.5rem;
            }

            .team-card {
                background: white;
                border-radius: 15px;
                padding: 2.5rem;
                box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
                margin-bottom: 2rem;
            }

            .team-header {
                display: flex;
                justify-content: space-between;
                align-items: center;
                margin-bottom: 2rem;
                padding-bottom: 1.5rem;
                border-bottom: 3px solid #f0f0f0;
            }

            .team-name-section {
                display: flex;
                align-items: center;
                gap: 1rem;
            }

            .team-icon {
                width: 60px;
                height: 60px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                border-radius: 12px;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 2rem;
            }

            .team-name {
                font-size: 2rem;
                font-weight: 700;
                color: #1a1a2e;
            }

            .status-badge {
                padding: 0.6rem 1.2rem;
                border-radius: 25px;
                font-size: 0.95rem;
                font-weight: 600;
                color: white;
                background-color: #27ae60;
            }

            .team-info-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                gap: 1.5rem;
                margin-bottom: 2rem;
            }

            .info-box {
                background: #f8f9fa;
                padding: 1.5rem;
                border-radius: 10px;
            }

            .info-label {
                font-size: 0.9rem;
                color: #666;
                margin-bottom: 0.5rem;
            }

            .info-value {
                font-size: 1.2rem;
                font-weight: 600;
                color: #1a1a2e;
            }

            .section-title {
                font-size: 1.8rem;
                color: #1a1a2e;
                margin: 2rem 0 1.5rem;
                font-weight: 700;
            }

            .members-table {
                width: 100%;
                background: white;
                border-radius: 10px;
                overflow: hidden;
                box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
            }

            .members-table thead {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
            }

            .members-table th {
                padding: 1rem;
                text-align: left;
                font-weight: 600;
                font-size: 1rem;
            }

            .members-table td {
                padding: 1rem;
                border-bottom: 1px solid #f0f0f0;
            }

            .members-table tr:last-child td {
                border-bottom: none;
            }

            .members-table tbody tr:hover {
                background-color: #f8f9fa;
            }

            .captain-badge {
                display: inline-block;
                background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%);
                color: white;
                padding: 0.3rem 0.8rem;
                border-radius: 15px;
                font-size: 0.85rem;
                font-weight: 600;
            }

            .position-tag {
                display: inline-block;
                background-color: #e8f0fe;
                color: #1a73e8;
                padding: 0.3rem 0.8rem;
                border-radius: 5px;
                font-size: 0.9rem;
                font-weight: 500;
            }

            .jersey-number {
                display: inline-flex;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                width: 40px;
                height: 40px;
                border-radius: 8px;
                align-items: center;
                justify-content: center;
                font-weight: 700;
                font-size: 1.1rem;
            }

            .action-buttons {
                display: flex;
                gap: 1rem;
                margin-top: 2rem;
            }

            .btn-back {
                flex: 1;
                background-color: #e0e0e0;
                color: #333;
                padding: 1rem;
                border-radius: 8px;
                font-weight: 600;
                text-decoration: none;
                text-align: center;
                transition: all 0.3s;
            }

            .btn-back:hover {
                background-color: #d0d0d0;
                transform: translateY(-2px);
            }

            @media (max-width: 768px) {
                .team-header {
                    flex-direction: column;
                    align-items: flex-start;
                    gap: 1rem;
                }

                .members-table {
                    font-size: 0.9rem;
                }

                .members-table th,
                .members-table td {
                    padding: 0.7rem;
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
                            <div class="meta-item">🏆 <%= tournament.getCategory().toUpperCase()%> | <%= tournament.getTournamentType().toUpperCase()%></div>
                        </div>
                    </div>

                    <div class="team-card">
                        <div class="team-header">
                            <div class="team-name-section">
                                <div class="team-icon">🏐</div>
                                <h2 class="team-name"><%= registration.getTeamName()%></h2>
                            </div>
                            <div class="status-badge">✓ Approved</div>
                        </div>

                        <div class="team-info-grid">
                            <div class="info-box">
                                <div class="info-label">Team Leader</div>
                                <div class="info-value">👤 <%= registration.getTeamLeaderName()%></div>
                            </div>
                            <div class="info-box">
                                <div class="info-label">Total Players</div>
                                <div class="info-value">👥 <%= registration.getNumberOfPlayers()%> Players</div>
                            </div>
                            <div class="info-box">
                                <div class="info-label">Registration Date</div>
                                <div class="info-value">📅 <%= new SimpleDateFormat("MMM dd, yyyy").format(registration.getRegisteredAt())%></div>
                            </div>
                        </div>

                        <h3 class="section-title">Team Members</h3>

                        <table class="members-table">
                            <thead>
                                <tr>
                                    <th>Jersey</th>
                                    <th>Name</th>
                                    <th>Position</th>
                                    <th>Role</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% for (TeamMember member : members) {%>
                                <tr>
                                    <td>
                                        <div class="jersey-number">#<%= member.getJerseyNumber()%></div>
                                    </td>
                                    <td><strong><%= member.getMemberName()%></strong></td>
                                    <td>
                                        <span class="position-tag">
                                            <%= member.getPosition().replace("_", " ").toUpperCase()%>
                                        </span>
                                    </td>
                                    <td>
                                        <% if (member.isCaptain()) { %>
                                        <span class="captain-badge">⭐ CAPTAIN</span>
                                        <% } else { %>
                                        <span style="color: #666;">Member</span>
                                        <% } %>
                                    </td>
                                </tr>
                                <% }%>
                            </tbody>
                        </table>

                        <div class="action-buttons">
                            <a href="ViewTeamDetail.jsp?id=<%= tournament.getTournamentId()%>" class="btn-back">← Back to Tournament Teams</a>
                        </div>
                    </div>
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