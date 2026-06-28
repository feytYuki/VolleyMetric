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

    TournamentDAO tournamentDAO = new TournamentDAO();
    List<Tournament> completedTournaments = tournamentDAO.getTournamentsByStatus("completed");

    // Filter to show only organizer's tournaments
    List<Tournament> myCompletedTournaments = new ArrayList<>();
    for (Tournament t : completedTournaments) {
        if (t.getOrganizerId() == organizerId) {
            myCompletedTournaments.add(t);
        }
    }

    SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMM yyyy");
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Tournament Results - VolleyMetric</title>
        <link rel="stylesheet" href="style.css">
        <style>
            /* Synchronized Theme Styles */
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
                box-shadow: 0 4px 12px rgba(118, 75, 162, 0.3);
            }

            .results-section {
                padding: 4rem 0;
                background-color: #f8f9fa;
                min-height: 80vh;
            }
            .page-header {
                text-align: center;
                margin-bottom: 3rem;
            }
            .page-title {
                font-size: 2.5rem;
                color: #1a1a2e;
                margin-bottom: 0.5rem;
                font-weight: 800;
            }
            .page-subtitle {
                font-size: 1.2rem;
                color: #666;
            }

            .tournaments-grid {
                display: grid;
                grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
                gap: 2rem;
            }
            .tournament-card {
                background: white;
                border-radius: 20px;
                overflow: hidden;
                box-shadow: 0 8px 30px rgba(0,0,0,0.1);
                transition: all 0.3s;
                position: relative;
            }
            .tournament-card:hover {
                transform: translateY(-8px);
                box-shadow: 0 12px 40px rgba(0,0,0,0.15);
            }

            /* --- HEADER STYLES (Matching UserTournament) --- */
            .tournament-header {
                background: linear-gradient(135deg, #667eea, #764ba2);
                padding: 2rem;
                text-align: center;
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
            }

            .tournament-name {
                font-size: 1.5rem;
                font-weight: 700;
                color: white;
                margin: 0;
                line-height: 1.3;
            }

            .status-badge {
                display: inline-block;
                background: linear-gradient(135deg, #28a745, #20c997); /* Green for Completed */
                color: white;
                padding: 0.4rem 1rem;
                border-radius: 50px;
                font-size: 0.75rem;
                font-weight: 700;
                text-transform: uppercase;
                margin-bottom: 1rem;
            }

            /* --- BODY STYLES --- */
            .tournament-body {
                padding: 2rem;
            }

            .info-item {
                display: flex;
                align-items: center;
                gap: 0.8rem;
                color: #555;
                padding: 0.5rem;
                background: #f8f9fa;
                border-radius: 8px;
                margin-bottom: 0.5rem;
                font-size: 0.95rem;
            }

            .btn-action {
                background: linear-gradient(135deg, #ff6b6b, #ee5a52);
                color: white;
                padding: 0.8rem;
                border: none;
                border-radius: 8px;
                font-weight: 700;
                cursor: pointer;
                width: 100%;
                transition: all 0.3s;
                text-decoration: none;
                display: block;
                text-align: center;
                margin-top: 1rem;
            }
            .btn-action:hover {
                transform: translateY(-3px);
                box-shadow: 0 4px 12px rgba(255, 107, 107, 0.3);
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

            .alert {
                padding: 1.2rem 1.5rem;
                border-radius: 12px;
                margin-bottom: 2rem;
                font-weight: 600;
                box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            }
            .alert-success {
                background: linear-gradient(135deg, #d4edda, #c3e6cb);
                border: 2px solid #28a745;
                color: #155724;
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
                        <li><a href="OrganizerHome.jsp" class="nav-link">Home</a></li>
                        <li><a href="OrganizerTournament.jsp" class="nav-link">Tournaments</a></li>
                        <li><a href="OrganizerSchedule.jsp" class="nav-link">Schedule</a></li>
                        <li><a href="OrganizerResult.jsp" class="nav-link active">Results</a></li>
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

        <section class="results-section">
            <div class="container">
                <div class="page-header">
                    <h1 class="page-title">🏆 Tournament Results</h1>
                    <p class="page-subtitle">View rankings and outcomes of your completed tournaments</p>
                </div>

                <%
                    String successMsg = (String) session.getAttribute("successMessage");
                    if (successMsg != null) {
                    session.removeAttribute("successMessage");%>
                <div class="alert alert-success"><%= successMsg%></div>
                <% } %>

                <% if (myCompletedTournaments.isEmpty()) { %>
                <div class="empty-state">
                    <h3>📋 No Completed Tournaments Yet</h3>
                    <p>Tournaments you conclude will appear here with full results and rankings.</p>
                </div>
                <% } else { %>
                <div class="tournaments-grid">
                    <% for (Tournament tournament : myCompletedTournaments) {%>
                    <div class="tournament-card">
                        <div class="tournament-header">
                            <div class="status-badge">Completed</div>
                            <div class="tournament-name"><%= tournament.getTournamentName()%></div>
                        </div>

                        <div class="tournament-body">
                            <div class="tournament-info">
                                <div class="info-item">
                                    <span>📍</span>
                                    <span><%= tournament.getLocation()%></span>
                                </div>
                                <div class="info-item">
                                    <span>📅</span>
                                    <span><%= dateFormat.format(tournament.getTournamentDate())%></span>
                                </div>
                                <div class="info-item">
                                    <span>👥</span>
                                    <span><strong><%= tournament.getCurrentTeams()%></strong> teams participated</span>
                                </div>
                                <div class="info-item">
                                    <span>🏆</span>
                                    <span><%= tournament.getCategory().substring(0, 1).toUpperCase() + tournament.getCategory().substring(1)%> | <%= tournament.getTournamentType().substring(0, 1).toUpperCase() + tournament.getTournamentType().substring(1)%></span>
                                </div>
                            </div>

                            <a href="OrganizerResultDetail.jsp?id=<%= tournament.getTournamentId()%>" class="btn-action">View Full Results</a>
                        </div>
                    </div>
                    <% } %>
                </div>
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