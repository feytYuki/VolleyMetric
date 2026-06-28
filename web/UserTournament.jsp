<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="Model.Tournament" %>
<%@ page import="DAO.TournamentDAO" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    String username = (String) session.getAttribute("username");
    String fullname = (String) session.getAttribute("fullname");
    Integer userId = (Integer) session.getAttribute("userId");

    if (username == null || userId == null) {
        response.sendRedirect("Login.jsp");
        return;
    }

    TournamentDAO tournamentDAO = new TournamentDAO();
    List<Tournament> tournaments = tournamentDAO.getTournamentsByStatus("upcoming");
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Available Tournaments - VolleyMetric</title>
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
                background-color: #ff6b6b;
                color: #fff;
                padding: 0.6rem 1.5rem;
                text-decoration: none;
                border-radius: 5px;
                font-weight: 600;
                transition: all 0.3s;
            }
            .btn-logout:hover {
                background-color: #ee5a52;
                transform: translateY(-2px);
            }

            .page-section {
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

            /* Alert Styling */
            .alert {
                padding: 1rem;
                border-radius: 8px;
                margin-bottom: 2rem;
                font-size: 0.95rem;
                display: flex;
                align-items: center;
                gap: 0.5rem;
            }
            .alert-success {
                background-color: #d4edda;
                border: 1px solid #c3e6cb;
                color: #155724;
            }
            .alert-error {
                background-color: #f8d7da;
                border: 1px solid #f5c6cb;
                color: #721c24;
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

            /* Tournament Header with gradient background */
            .tournament-header {
                background: linear-gradient(135deg, #667eea, #764ba2);
                padding: 2rem;
                text-align: center;
                /* position: relative; Removed relative positioning requirement for badge */
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

            /* --- UPDATED BADGE CSS --- */
            .status-badge {
                display: inline-block;
                background: linear-gradient(135deg, #4ecdc4, #45b7af);
                color: white;
                padding: 0.4rem 1rem;
                border-radius: 50px;
                font-size: 0.75rem;
                font-weight: 700;
                text-transform: uppercase;
                margin-bottom: 1rem; /* Adds space between badge and name */
                /* Removed absolute positioning (top/right) so it sits in flow */
            }

            /* Tournament body content */
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
                margin-top: 0.5rem;
            }
            .btn-action:hover {
                transform: translateY(-3px);
                box-shadow: 0 4px 12px rgba(255, 107, 107, 0.3);
            }
            .btn-secondary {
                background: linear-gradient(135deg, #667eea, #764ba2);
                margin-bottom: 0.5rem;
            }
            .btn-secondary:hover {
                background: linear-gradient(135deg, #5568d3, #6a3f8f);
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

        <section class="page-section">
            <div class="container">
                <div class="page-header">
                    <h1 class="page-title">Available Tournaments</h1>
                    <p class="page-subtitle">Browse and register for upcoming volleyball tournaments</p>
                </div>

                <%
                    String sessionError = (String) session.getAttribute("errorMessage");
                    if (sessionError != null) {
                %>
                <div class="alert alert-error">
                    ✗ <%= sessionError%>
                </div>
                <%
                        session.removeAttribute("errorMessage");
                    }
                %>

                <%
                    String sessionSuccess = (String) session.getAttribute("successMessage");
                    if (sessionSuccess != null) {
                %>
                <div class="alert alert-success">
                    ✓ <%= sessionSuccess%>
                </div>
                <%
                        session.removeAttribute("successMessage");
                    }
                %>

                <% if (tournaments.isEmpty()) { %>
                <div style="text-align: center; padding: 4rem; background: white; border-radius: 20px;">
                    <h2 style="font-size: 1.8rem; color: #1a1a2e;">No Tournaments Available</h2>
                    <p>There are currently no upcoming tournaments. Check back later!</p>
                </div>
                <% } else { %>
                <div class="tournaments-grid">
                    <% for (Tournament tournament : tournaments) {%>
                    <div class="tournament-card">
                        <div class="tournament-header">
                            <div class="status-badge">Registration Open</div>
                            <h3 class="tournament-name"><%= tournament.getTournamentName()%></h3>
                        </div>

                        <div class="tournament-body">
                            <div class="tournament-info">
                                <div class="info-item">
                                    <span class="info-icon">📍</span>
                                    <span><%= tournament.getLocation()%></span>
                                </div>
                                <div class="info-item">
                                    <span class="info-icon">📅</span>
                                    <span><%= new SimpleDateFormat("MMM dd, yyyy").format(tournament.getTournamentDate())%></span>
                                </div>
                                <div class="info-item">
                                    <span class="info-icon">⏰</span>
                                    <span><%= new SimpleDateFormat("hh:mm a").format(tournament.getStartTime())%></span>
                                </div>
                                <div class="info-item">
                                    <span class="info-icon">👥</span>
                                    <span><%= tournament.getCurrentTeams()%>/<%= tournament.getMaxTeams()%> Teams</span>
                                </div>
                                <div class="info-item">
                                    <span class="info-icon">🏆</span>
                                    <span>
                                        <%= tournament.getCategory().substring(0, 1).toUpperCase() + tournament.getCategory().substring(1)%> | 
                                        <%= tournament.getTournamentType().substring(0, 1).toUpperCase() + tournament.getTournamentType().substring(1)%>
                                    </span>
                                </div>
                            </div>
                            <a href="ViewTeamDetail.jsp?id=<%= tournament.getTournamentId()%>" class="btn-action btn-secondary">View Registered Teams</a>
                            <% if (tournament.isFull()) { %>
                            <button class="btn-action" style="background: #ccc; cursor: not-allowed;" disabled>Tournament Full</button>
                            <% } else {%>
                            <a href="RegisterTournamentServlet?tournamentId=<%= tournament.getTournamentId()%>" class="btn-action">Register Now</a>
                            <% } %>
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