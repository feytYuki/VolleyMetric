<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="Model.TeamRegistration" %>
<%@ page import="Model.Tournament" %>
<%@ page import="DAO.TeamRegistrationDAO" %>
<%@ page import="DAO.TournamentDAO" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.Date" %>
<%
    String username = (String) session.getAttribute("username");
    String fullname = (String) session.getAttribute("fullname");
    Integer userId = (Integer) session.getAttribute("userId");

    if (username == null || userId == null) {
        response.sendRedirect("Login.jsp");
        return;
    }

    TournamentDAO tournamentDAO = new TournamentDAO();
    tournamentDAO.autoUpdateCompletedStatus();

    TeamRegistrationDAO teamRegistrationDAO = new TeamRegistrationDAO();
    List<TeamRegistration> registrations = teamRegistrationDAO.getRegistrationsByUser(userId);

    // Separate into three buckets
    List<TeamRegistration> liveList = new ArrayList<>();
    List<TeamRegistration> upcomingList = new ArrayList<>();
    List<TeamRegistration> completedList = new ArrayList<>();

    Date now = new Date();
    SimpleDateFormat sdf = new SimpleDateFormat("MMM dd, yyyy");
    SimpleDateFormat stf = new SimpleDateFormat("hh:mm a");

    for (TeamRegistration reg : registrations) {
        Tournament t = tournamentDAO.getTournamentById(reg.getTournamentId());
        if (t == null) {
            continue;
        }

        boolean isCompleted = "completed".equalsIgnoreCase(t.getStatus());
        boolean isLive = "ongoing".equalsIgnoreCase(t.getStatus());

        if (isCompleted) {
            completedList.add(reg);
        } else if (isLive) {
            liveList.add(reg);
        } else {
            // upcoming = approved or pending (not rejected)
            if (!"rejected".equalsIgnoreCase(reg.getStatus())) {
                upcomingList.add(reg);
            } else {
                // still show rejected under upcoming so user knows
                upcomingList.add(reg);
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>My Registered Tournaments - VolleyMetric</title>
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

            /* Tab navigation */
            .tab-nav {
                display: flex;
                justify-content: center;
                gap: 0;
                margin-bottom: 2.5rem;
                background: white;
                border-radius: 14px;
                padding: 6px;
                max-width: 560px;
                margin-left: auto;
                margin-right: auto;
                box-shadow: 0 4px 20px rgba(0,0,0,0.08);
            }
            .tab-btn {
                flex: 1;
                padding: 0.75rem 1rem;
                border: none;
                background: transparent;
                border-radius: 10px;
                font-size: 0.95rem;
                font-weight: 700;
                cursor: pointer;
                color: #888;
                transition: all 0.25s;
                display: flex;
                align-items: center;
                justify-content: center;
                gap: 0.5rem;
            }
            .tab-btn .count-badge {
                background: #e0e0e0;
                color: #666;
                border-radius: 50px;
                padding: 1px 8px;
                font-size: 0.75rem;
                font-weight: 700;
                transition: all 0.25s;
            }
            .tab-btn.active-live {
                background: linear-gradient(135deg, #ff6b6b, #ee5a52);
                color: white;
            }
            .tab-btn.active-live .count-badge {
                background: rgba(255,255,255,0.3);
                color: white;
            }

            .tab-btn.active-upcoming {
                background: linear-gradient(135deg, #667eea, #5a6fd8);
                color: white;
            }
            .tab-btn.active-upcoming .count-badge {
                background: rgba(255,255,255,0.3);
                color: white;
            }

            .tab-btn.active-completed {
                background: linear-gradient(135deg, #4ecdc4, #2eaaa1);
                color: white;
            }
            .tab-btn.active-completed .count-badge {
                background: rgba(255,255,255,0.3);
                color: white;
            }

            .tab-btn:not(.active-live):not(.active-upcoming):not(.active-completed):hover {
                background: #f5f5f5;
                color: #333;
            }

            /* Tab panels */
            .tab-panel {
                display: none;
            }
            .tab-panel.active {
                display: block;
            }

            /* Live pulse indicator */
            .live-dot {
                width: 8px;
                height: 8px;
                background: #ff6b6b;
                border-radius: 50%;
                display: inline-block;
                animation: pulse 1.4s infinite;
            }
            @keyframes pulse {
                0%, 100% {
                    opacity: 1;
                    transform: scale(1);
                }
                50% {
                    opacity: 0.4;
                    transform: scale(1.4);
                }
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

            .tournament-header {
                background: linear-gradient(135deg, #667eea, #764ba2);
                padding: 2rem;
                text-align: center;
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
            }
            .header-live    {
                background: linear-gradient(135deg, #ff6b6b, #ee5a52);
            }
            .header-upcoming{
                background: linear-gradient(135deg, #667eea, #764ba2);
            }
            .header-completed{
                background: linear-gradient(135deg, #4ecdc4, #2eaaa1);
            }

            .status-badge {
                display: inline-block;
                padding: 0.4rem 1rem;
                border-radius: 50px;
                font-size: 0.75rem;
                font-weight: 700;
                color: #fff;
                text-transform: uppercase;
                margin-bottom: 1rem;
            }
            .badge-live      {
                background: rgba(255,255,255,0.25);
                border: 1px solid rgba(255,255,255,0.4);
            }
            .badge-pending   {
                background: linear-gradient(135deg, #f39c12, #e67e22);
            }
            .badge-approved  {
                background: linear-gradient(135deg, #2ecc71, #27ae60);
            }
            .badge-rejected  {
                background: linear-gradient(135deg, #e74c3c, #c0392b);
            }
            .badge-completed {
                background: rgba(255,255,255,0.25);
                border: 1px solid rgba(255,255,255,0.4);
            }

            .tournament-name {
                font-size: 1.5rem;
                font-weight: 700;
                color: white;
                margin: 0;
                line-height: 1.3;
            }

            .tournament-body {
                padding: 2rem;
            }
            .team-display {
                color: #ff6b6b;
                font-weight: 700;
                font-size: 1.1rem;
                margin-bottom: 1.5rem;
                display: block;
                text-align: center;
            }
            .card-completed .team-display {
                color: #2eaaa1;
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
                margin-top: 0.5rem;
            }
            .btn-action:hover {
                transform: translateY(-3px);
                box-shadow: 0 4px 12px rgba(255,107,107,0.3);
            }
            .btn-blue    {
                background: linear-gradient(135deg, #667eea, #5a6fd8);
            }
            .btn-teal    {
                background: linear-gradient(135deg, #4ecdc4, #2eaaa1);
            }
            .btn-results {
                background: linear-gradient(135deg, #f7971e, #ffd200);
                color: #1a1a2e;
            }
            .btn-results:hover {
                box-shadow: 0 4px 12px rgba(247,151,30,0.4);
            }

            .empty-state {
                text-align: center;
                padding: 4rem;
                background: white;
                border-radius: 20px;
            }
            .empty-state h2 {
                font-size: 1.5rem;
                color: #1a1a2e;
                margin-bottom: 0.5rem;
            }
            .empty-state p {
                color: #888;
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
                        <li><a href="UserHome.jsp"       class="nav-link">Home</a></li>
                        <li><a href="UserTournament.jsp" class="nav-link">Tournaments</a></li>
                        <li><a href="UserSchedule.jsp"   class="nav-link">Schedule</a></li>
                        <li><a href="UserResult.jsp"     class="nav-link">Results</a></li>
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
                    <h1 class="page-title">My Registered Tournaments</h1>
                    <p class="page-subtitle">View and manage your team registrations</p>
                </div>

                <!-- Tab Navigation -->
                <div class="tab-nav">
                    <button class="tab-btn <%= liveList.isEmpty() ? "" : "active-live"%>"
                            id="btn-live" onclick="switchTab('live')">
                        <span class="live-dot"></span> Live
                        <span class="count-badge"><%= liveList.size()%></span>
                    </button>
                    <button class="tab-btn <%= liveList.isEmpty() ? "active-upcoming" : ""%>"
                            id="btn-upcoming" onclick="switchTab('upcoming')">
                        📅 Upcoming
                        <span class="count-badge"><%= upcomingList.size()%></span>
                    </button>
                    <button class="tab-btn"
                            id="btn-completed" onclick="switchTab('completed')">
                        🏆 Completed
                        <span class="count-badge"><%= completedList.size()%></span>
                    </button>
                </div>

                <!-- LIVE TAB -->
                <div class="tab-panel <%= liveList.isEmpty() ? "" : "active"%>" id="panel-live">
                    <% if (liveList.isEmpty()) { %>
                    <div class="empty-state">
                        <h2>No Live Tournaments</h2>
                        <p>You have no ongoing tournaments right now.</p>
                    </div>
                    <% } else { %>
                    <div class="tournaments-grid">
                        <% for (TeamRegistration reg : liveList) {
                                Tournament t = tournamentDAO.getTournamentById(reg.getTournamentId());
                                if (t == null)
                                    continue;
                        %>
                        <div class="tournament-card">
                            <div class="tournament-header header-live">
                                <div class="status-badge badge-live">🔴 Live Now</div>
                                <h3 class="tournament-name"><%= t.getTournamentName()%></h3>
                            </div>
                            <div class="tournament-body">
                                <span class="team-display">🏐 Team: <%= reg.getTeamName()%></span>
                                <div class="info-item"><span>📍 <%= t.getLocation()%></span></div>
                                <div class="info-item"><span>📅 <%= sdf.format(t.getTournamentDate())%></span></div>
                                <div class="info-item"><span>⏰ <%= stf.format(t.getStartTime())%></span></div>
                                <div class="info-item"><span>👥 <%= reg.getNumberOfPlayers()%> Players</span></div>
                                <div class="info-item"><span>🏆 <%= t.getCategory()%> | <%= t.getTournamentType()%></span></div>
                                <a href="ViewTeamMembers.jsp?registrationId=<%= reg.getRegistrationId()%>" class="btn-action btn-teal" style="margin-top:1rem;">View Team Details</a>
                            </div>
                        </div>
                        <% } %>
                    </div>
                    <% }%>
                </div>

                <!-- UPCOMING TAB -->
                <div class="tab-panel <%= liveList.isEmpty() ? "active" : ""%>" id="panel-upcoming">
                    <% if (upcomingList.isEmpty()) { %>
                    <div class="empty-state">
                        <h2>No Upcoming Tournaments</h2>
                        <p>Register for a tournament to see it here.</p>
                        <a href="UserTournament.jsp" class="btn-action" style="display:inline-block;width:auto;padding:1rem 2rem;margin-top:1rem;">Browse Tournaments</a>
                    </div>
                    <% } else { %>
                    <div class="tournaments-grid">
                        <% for (TeamRegistration reg : upcomingList) {
                                Tournament t = tournamentDAO.getTournamentById(reg.getTournamentId());
                                if (t == null) {
                                    continue;
                                }
                                String badgeClass = reg.getStatus().equalsIgnoreCase("approved") ? "badge-approved"
                                        : reg.getStatus().equalsIgnoreCase("rejected") ? "badge-rejected"
                                        : "badge-pending";
                        %>
                        <div class="tournament-card">
                            <div class="tournament-header header-upcoming">
                                <div class="status-badge <%= badgeClass%>"><%= reg.getStatus()%></div>
                                <h3 class="tournament-name"><%= t.getTournamentName()%></h3>
                            </div>
                            <div class="tournament-body">
                                <span class="team-display">🏐 Team: <%= reg.getTeamName()%></span>
                                <div class="info-item"><span>📍 <%= t.getLocation()%></span></div>
                                <div class="info-item"><span>📅 <%= sdf.format(t.getTournamentDate())%></span></div>
                                <div class="info-item"><span>⏰ <%= stf.format(t.getStartTime())%></span></div>
                                <div class="info-item"><span>👥 <%= reg.getNumberOfPlayers()%> Players</span></div>
                                <div class="info-item"><span>🏆 <%= t.getCategory()%> | <%= t.getTournamentType()%></span></div>
                                <% if ("approved".equalsIgnoreCase(reg.getStatus())) {%>
                                <a href="ViewTeamMembers.jsp?registrationId=<%= reg.getRegistrationId()%>" class="btn-action btn-teal">View Team Details</a>
                                <a href="EditTeamRegistration.jsp?registrationId=<%= reg.getRegistrationId()%>" class="btn-action btn-blue">Edit Team</a>
                                <% } else if ("pending".equalsIgnoreCase(reg.getStatus())) {%>
                                <a href="EditTeamRegistration.jsp?registrationId=<%= reg.getRegistrationId()%>" class="btn-action btn-blue">Edit Registration</a>
                                <% } else { %>
                                <button class="btn-action" style="background:#ccc;cursor:not-allowed;" disabled>Registration Rejected</button>
                                <% } %>
                            </div>
                        </div>
                        <% } %>
                    </div>
                    <% } %>
                </div>

                <!-- COMPLETED TAB -->
                <div class="tab-panel" id="panel-completed">
                    <% if (completedList.isEmpty()) { %>
                    <div class="empty-state">
                        <h2>No Completed Tournaments</h2>
                        <p>Your finished tournaments will appear here.</p>
                    </div>
                    <% } else { %>
                    <div class="tournaments-grid">
                        <% for (TeamRegistration reg : completedList) {
                                Tournament t = tournamentDAO.getTournamentById(reg.getTournamentId());
                                if (t == null)
                                    continue;
                        %>
                        <div class="tournament-card card-completed">
                            <div class="tournament-header header-completed">
                                <div class="status-badge badge-completed">✅ Completed</div>
                                <h3 class="tournament-name"><%= t.getTournamentName()%></h3>
                            </div>
                            <div class="tournament-body">
                                <span class="team-display">🏐 Team: <%= reg.getTeamName()%></span>
                                <div class="info-item"><span>📍 <%= t.getLocation()%></span></div>
                                <div class="info-item"><span>📅 <%= sdf.format(t.getTournamentDate())%></span></div>
                                <div class="info-item"><span>⏰ <%= stf.format(t.getStartTime())%></span></div>
                                <div class="info-item"><span>👥 <%= reg.getNumberOfPlayers()%> Players</span></div>
                                <div class="info-item"><span>🏆 <%= t.getCategory()%> | <%= t.getTournamentType()%></span></div>
                                <a href="UserResult.jsp?id=<%= t.getTournamentId()%>" class="btn-action btn-results">🏆 View Results</a>
                            </div>
                        </div>
                        <% } %>
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

        <script>
            function switchTab(tab) {
                document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
                document.querySelectorAll('.tab-btn').forEach(b => {
                    b.classList.remove('active-live', 'active-upcoming', 'active-completed');
                });
                document.getElementById('panel-' + tab).classList.add('active');
                const btn = document.getElementById('btn-' + tab);
                btn.classList.add('active-' + tab);
            }
        </script>
    </body>
</html>