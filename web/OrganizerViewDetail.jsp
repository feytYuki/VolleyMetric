<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="Model.Tournament, Model.TeamRegistration, Model.TeamMember" %>
<%@ page import="DAO.TournamentDAO, DAO.TeamRegistrationDAO, DAO.TeamMemberDAO" %>
<%@ page import="java.util.List" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    // Check if organizer is logged in
    String username = (String) session.getAttribute("organizerUsername");
    String fullname = (String) session.getAttribute("organizerFullname");
    Integer organizerId = (Integer) session.getAttribute("organizerId");

    if (username == null || organizerId == null) {
        response.sendRedirect("OrganizerLogin.jsp");
        return;
    }

    // Get tournament ID
    String tournamentIdStr = request.getParameter("id");
    if (tournamentIdStr == null) {
        response.sendRedirect("OrganizerTournament.jsp");
        return;
    }

    int tournamentId = Integer.parseInt(tournamentIdStr);

    // Get tournament details
    TournamentDAO tournamentDAO = new TournamentDAO();
    Tournament tournament = tournamentDAO.getTournamentById(tournamentId);

    // Verify tournament belongs to this organizer
    if (tournament == null || tournament.getOrganizerId() != organizerId) {
        response.sendRedirect("OrganizerTournament.jsp");
        return;
    }

    // Get all registrations for this tournament
    TeamRegistrationDAO teamRegDAO = new TeamRegistrationDAO();
    TeamMemberDAO teamMemberDAO = new TeamMemberDAO();
    List<TeamRegistration> registrations = teamRegDAO.getRegistrationsByTournament(tournamentId);
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Tournament Details - VolleyMetric</title>
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
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: #fff;
                padding: 0.6rem 1.5rem;
                text-decoration: none;
                border-radius: 5px;
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
                padding: 2rem;
                border-radius: 10px;
                margin-bottom: 2rem;
            }
            .tournament-title {
                font-size: 2rem;
                margin-bottom: 1rem;
            }
            .tournament-meta {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                gap: 1rem;
            }
            .meta-item {
                font-size: 1rem;
            }

            .btn-start-tournament {
                background-color: #ff6b6b;
                color: white;
                padding: 0.8rem 2rem;
                border: none;
                border-radius: 5px;
                font-weight: 600;
                font-size: 1rem;
                cursor: pointer;
                margin-top: 1.5rem;
                transition: all 0.3s;
                text-decoration: none;
                display: inline-block;
            }
            .btn-start-tournament:hover {
                background-color: #ee5a52;
                transform: translateY(-2px);
                box-shadow: 0 4px 12px rgba(255, 107, 107, 0.3);
            }

            .section-title {
                font-size: 1.8rem;
                color: #1a1a2e;
                margin: 2rem 0 1rem;
            }

            .registrations-list {
                display: flex;
                flex-direction: column;
                gap: 1.5rem;
            }
            .registration-card {
                background: white;
                border-radius: 10px;
                padding: 1.5rem;
                box-shadow: 0 4px 15px rgba(0,0,0,0.08);
            }
            .card-header {
                display: flex;
                justify-content: space-between;
                align-items: center;
                margin-bottom: 1rem;
                border-bottom: 2px solid #f0f0f0;
                padding-bottom: 1rem;
            }
            .team-name {
                font-size: 1.3rem;
                font-weight: 700;
                color: #1a1a2e;
            }

            .status-badge {
                padding: 0.4rem 0.8rem;
                border-radius: 20px;
                font-size: 0.85rem;
                font-weight: 600;
                color: white;
            }
            .badge-pending {
                background-color: #f39c12;
            }
            .badge-approved {
                background-color: #27ae60;
            }
            .badge-rejected {
                background-color: #e74c3c;
            }

            .members-table {
                width: 100%;
                margin: 1rem 0;
            }
            .members-table th {
                background-color: #f8f9fa;
                padding: 0.8rem;
                text-align: left;
                font-weight: 600;
                border-bottom: 2px solid #e0e0e0;
            }
            .members-table td {
                padding: 0.8rem;
                border-bottom: 1px solid #f0f0f0;
            }

            .action-buttons {
                display: flex;
                gap: 1rem;
                margin-top: 1rem;
            }
            .btn-approve {
                background-color: #27ae60;
                color: white;
                padding: 0.6rem 1.5rem;
                border: none;
                border-radius: 5px;
                font-weight: 600;
                cursor: pointer;
            }
            .btn-reject {
                background-color: #e74c3c;
                color: white;
                padding: 0.6rem 1.5rem;
                border: none;
                border-radius: 5px;
                font-weight: 600;
                cursor: pointer;
            }
            .btn-approve:hover {
                background-color: #229954;
            }
            .btn-reject:hover {
                background-color: #c0392b;
            }

            .no-registrations {
                text-align: center;
                padding: 3rem;
                background: white;
                border-radius: 10px;
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
                        <li><a href="OrganizerTournament.jsp" class="nav-link active">Tournaments</a></li>
                        <li><a href="OrganizerSchedule.jsp" class="nav-link">Schedule</a></li>
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

        <section class="detail-section">
            <div class="container">
                <div class="detail-container">
                    <!-- Success/Error Messages -->
                    <%
                        String successMessage = (String) session.getAttribute("successMessage");
                        String errorMessage = (String) session.getAttribute("errorMessage");
                        if (successMessage != null) {
                            session.removeAttribute("successMessage");
                    %>
                    <div style="background-color: #d4edda; border: 1px solid #c3e6cb; color: #155724; padding: 1rem; border-radius: 5px; margin-bottom: 1rem;">
                        <%= successMessage%>
                    </div>
                    <% }
                        if (errorMessage != null) {
                            session.removeAttribute("errorMessage");
                    %>
                    <div style="background-color: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; padding: 1rem; border-radius: 5px; margin-bottom: 1rem;">
                        <%= errorMessage%>
                    </div>
                    <% }%>

                    <div class="tournament-header">
                        <h1 class="tournament-title"><%= tournament.getTournamentName()%></h1>
                        <div class="tournament-meta">
                            <div class="meta-item">📍 <%= tournament.getLocation()%></div>
                            <div class="meta-item">📅 <%= new SimpleDateFormat("MMM dd, yyyy").format(tournament.getTournamentDate())%></div>
                            <div class="meta-item">⏰ <%= new SimpleDateFormat("hh:mm a").format(tournament.getStartTime())%></div>
                            <div class="meta-item">👥 <%= tournament.getCurrentTeams()%>/<%= tournament.getMaxTeams()%> Teams</div>
                            <div class="meta-item">🏆 <%= tournament.getCategory().toUpperCase()%> | <%= tournament.getTournamentType().toUpperCase()%></div>
                        </div>
                        <% if ("upcoming".equalsIgnoreCase(tournament.getStatus())) {%>
                        <form action="StartTournamentServlet" method="POST" style="display: inline;" onsubmit="console.log('Form submitting! Tournament ID: <%= tournament.getTournamentId()%>');">
                            <input type="hidden" name="tournamentId" value="<%= tournament.getTournamentId()%>">
                            <button type="submit" class="btn-start-tournament">🚀 Start Tournament</button>
                        </form>
                        <% } else if ("ongoing".equalsIgnoreCase(tournament.getStatus())) { %>
                        <a href="OrganizerSchedule.jsp" class="btn-start-tournament" style="background-color: #27ae60;">✅ View Schedule</a>
                        <% } else if ("completed".equalsIgnoreCase(tournament.getStatus())) { %>
                        <button class="btn-start-tournament" style="background-color: #95a5a6; cursor: not-allowed;" disabled>🏁 Tournament Completed</button>
                        <% } %>
                    </div>

                    <h2 class="section-title">Team Registrations</h2>

                    <% if (registrations.isEmpty()) { %>
                    <div class="no-registrations">
                        <h3>No Team Registrations Yet</h3>
                        <p>Teams will appear here once they register for your tournament.</p>
                    </div>
                    <% } else { %>
                    <div class="registrations-list">
                        <% for (TeamRegistration reg : registrations) {
                                List<TeamMember> members = teamMemberDAO.getMembersByRegistrationId(reg.getRegistrationId());
                                String statusClass = "";
                                String statusText = "";

                                switch (reg.getStatus().toLowerCase()) {
                                    case "pending":
                                        statusClass = "badge-pending";
                                        statusText = "Pending";
                                        break;
                                    case "approved":
                                        statusClass = "badge-approved";
                                        statusText = "Approved";
                                        break;
                                    case "rejected":
                                        statusClass = "badge-rejected";
                                        statusText = "Rejected";
                                        break;
                                }
                        %>
                        <div class="registration-card">
                            <div class="card-header">
                                <div class="team-name">🏐 <%= reg.getTeamName()%></div>
                                <div class="status-badge <%= statusClass%>"><%= statusText%></div>
                            </div>

                            <p><strong>Team Leader:</strong> <%= reg.getTeamLeaderName()%></p>
                            <p><strong>Players:</strong> <%= reg.getNumberOfPlayers()%></p>
                            <p><strong>Registered:</strong> <%= new SimpleDateFormat("MMM dd, yyyy hh:mm a").format(reg.getRegisteredAt())%></p>

                            <table class="members-table">
                                <thead>
                                    <tr>
                                        <th>Name</th>
                                        <th>Position</th>
                                        <th>Jersey #</th>
                                        <th>Role</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% for (TeamMember member : members) {%>
                                    <tr>
                                        <td><%= member.getMemberName()%></td>
                                        <td><%= member.getPosition().replace("_", " ").toUpperCase()%></td>
                                        <td>#<%= member.getJerseyNumber()%></td>
                                        <td><%= member.isCaptain() ? "⭐ Captain" : "Member"%></td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>

                            <% if ("pending".equalsIgnoreCase(reg.getStatus())) {%>
                            <div class="action-buttons">
                                <form action="ApproveRejectTeamServlet" method="POST" style="display: inline;">
                                    <input type="hidden" name="registrationId" value="<%= reg.getRegistrationId()%>">
                                    <input type="hidden" name="action" value="approve">
                                    <button type="submit" class="btn-approve">✓ Approve</button>
                                </form>
                                <form action="ApproveRejectTeamServlet" method="POST" style="display: inline;">
                                    <input type="hidden" name="registrationId" value="<%= reg.getRegistrationId()%>">
                                    <input type="hidden" name="action" value="reject">
                                    <button type="submit" class="btn-reject">✗ Reject</button>
                                </form>
                            </div>
                            <% } %>
                        </div>
                        <% } %>
                    </div>
                    <% }%>
                </div>
            </div>
        </section>
    </body>
</html>