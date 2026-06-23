<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="Model.Tournament" %>
<%@ page import="DAO.TournamentDAO" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    String username = (String) session.getAttribute("organizerUsername");
    String fullname = (String) session.getAttribute("organizerFullname");
    Integer organizerId = (Integer) session.getAttribute("organizerId");

    if (username == null || organizerId == null) {
        response.sendRedirect("OrganizerLogin.jsp");
        return;
    }

    TournamentDAO tournamentDAO = new TournamentDAO();
    List<Tournament> tournaments = tournamentDAO.getTournamentsByOrganizerId(organizerId);

    List<Tournament> liveList      = new ArrayList<>();
    List<Tournament> upcomingList  = new ArrayList<>();
    List<Tournament> completedList = new ArrayList<>();

    for (Tournament t : tournaments) {
        String status = t.getStatus().toLowerCase();
        if (status.equals("ongoing")) {
            liveList.add(t);
        } else if (status.equals("completed") || status.equals("cancelled")) {
            completedList.add(t);
        } else {
            upcomingList.add(t);
        }
    }

    // Other organizers' tournaments
    List<Tournament> allTournaments = tournamentDAO.getAllTournaments();
    List<Tournament> otherTournaments = new ArrayList<>();
    for (Tournament t : allTournaments) {
        if (t.getOrganizerId() != organizerId) {
            otherTournaments.add(t);
        }
    }

    List<Tournament> otherLiveList      = new ArrayList<>();
    List<Tournament> otherUpcomingList  = new ArrayList<>();
    List<Tournament> otherCompletedList = new ArrayList<>();

    for (Tournament t : otherTournaments) {
        String status = t.getStatus().toLowerCase();
        if (status.equals("ongoing")) {
            otherLiveList.add(t);
        } else if (status.equals("completed") || status.equals("cancelled")) {
            otherCompletedList.add(t);
        } else {
            otherUpcomingList.add(t);
        }
    }

    SimpleDateFormat dateFormat = new SimpleDateFormat("MMM dd, yyyy");
    SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Tournaments - VolleyMetric</title>
    <link rel="stylesheet" href="style.css">
    <style>
        .user-info { display: flex; align-items: center; gap: 1rem; }
        .user-details { display: flex; flex-direction: column; align-items: flex-end; background: white; border: 2px solid #764ba2; border-radius: 5px; padding: 4px 10px; }
        .user-role-label { font-size: 0.8rem; font-weight: 600; color: #764ba2; margin: 0; }
        .user-name { font-size: 0.95rem; font-weight: 600; color: #000; margin: 0; }
        .btn-logout { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #fff; padding: 0.6rem 1.5rem; text-decoration: none; border-radius: 5px; font-weight: 600; border: none; cursor: pointer; transition: all 0.3s; }
        .btn-logout:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(102,126,234,0.4); }

        .tournaments-section { padding: 4rem 0; background-color: #f8f9fa; min-height: 80vh; }

        .section-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem; }
        .section-title { font-size: 2.5rem; color: #1a1a2e; font-weight: 800; }

        .btn-create { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #fff; padding: 0.8rem 1.5rem; text-decoration: none; border-radius: 5px; transition: all 0.3s; font-weight: 600; }
        .btn-create:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(102,126,234,0.4); }

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
        .tab-btn.active-live .count-badge { background: rgba(255,255,255,0.3); color: white; }
        .tab-btn.active-upcoming {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
        }
        .tab-btn.active-upcoming .count-badge { background: rgba(255,255,255,0.3); color: white; }
        .tab-btn.active-completed {
            background: linear-gradient(135deg, #95a5a6, #7f8c8d);
            color: white;
        }
        .tab-btn.active-completed .count-badge { background: rgba(255,255,255,0.3); color: white; }
        .tab-btn:not(.active-live):not(.active-upcoming):not(.active-completed):hover {
            background: #f5f5f5; color: #333;
        }

        .tab-panel { display: none; }
        .tab-panel.active { display: block; }

        /* Live pulse */
        .live-dot {
            width: 8px; height: 8px;
            background: #ff6b6b;
            border-radius: 50%;
            display: inline-block;
            animation: pulse 1.4s infinite;
        }
        @keyframes pulse {
            0%, 100% { opacity: 1; transform: scale(1); }
            50% { opacity: 0.4; transform: scale(1.4); }
        }

        .tournaments-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(350px, 1fr)); gap: 2rem; }

        .tournament-card { background-color: #fff; border-radius: 20px; box-shadow: 0 8px 30px rgba(0,0,0,0.1); transition: all 0.3s; overflow: hidden; position: relative; }
        .tournament-card:hover { transform: translateY(-8px); box-shadow: 0 12px 40px rgba(0,0,0,0.15); }

        .tournament-header {
            padding: 2rem;
            text-align: center;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
        }
        .header-live      { background: linear-gradient(135deg, #ff6b6b, #ee5a52); }
        .header-upcoming  { background: linear-gradient(135deg, #667eea, #764ba2); }
        .header-completed { background: linear-gradient(135deg, #95a5a6, #7f8c8d); }

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
        .badge-live      { background: rgba(255,255,255,0.25); border: 1px solid rgba(255,255,255,0.4); }
        .badge-upcoming  { background: linear-gradient(135deg, #4ecdc4, #45b7af); }
        .badge-completed { background: rgba(255,255,255,0.25); border: 1px solid rgba(255,255,255,0.4); }
        .badge-cancelled { background: linear-gradient(135deg, #636e72, #4a4a4a); }

        .tournament-name { font-size: 1.5rem; font-weight: 700; color: white; margin: 0; line-height: 1.3; }

        .tournament-body { padding: 2rem; }
        .tournament-info { display: flex; flex-direction: column; gap: 0.8rem; margin-bottom: 1.5rem; }
        .info-item { display: flex; align-items: center; color: #666; font-size: 0.95rem; background: #f8f9fa; padding: 0.5rem; border-radius: 8px; }
        .info-icon { font-size: 1.2rem; margin-right: 0.8rem; width: 24px; text-align: center; }

        .card-actions { display: flex; gap: 1rem; }
        .btn-view-details, .btn-edit-tournament {
            flex: 1; padding: 0.8rem; border-radius: 8px; font-weight: 600;
            text-align: center; text-decoration: none; transition: all 0.3s; cursor: pointer; border: none;
        }
        .btn-view-details { background: #4ecdc4; color: white; }
        .btn-view-details:hover { background: #45b8af; transform: translateY(-2px); }
        .btn-edit-tournament { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; }
        .btn-edit-tournament:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(102,126,234,0.3); }

        .empty-state { text-align: center; padding: 4rem 2rem; background: white; border-radius: 20px; box-shadow: 0 8px 30px rgba(0,0,0,0.1); }
        .empty-icon { font-size: 4rem; margin-bottom: 1rem; }
        .empty-title { font-size: 1.8rem; color: #1a1a2e; margin-bottom: 1rem; }
        .empty-text { color: #666; font-size: 1.1rem; margin-bottom: 2rem; }

        @media (max-width: 768px) {
            .tournaments-grid { grid-template-columns: 1fr; }
            .section-header { flex-direction: column; gap: 1rem; align-items: center; text-align: center; }
        }

        /* Other Organizers Section */
        .other-section { padding: 4rem 0; background-color: #eef0f7; }
        .other-section-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem; }
        .other-section-title { font-size: 2.5rem; color: #1a1a2e; font-weight: 800; }
        .other-section-subtitle { color: #666; font-size: 1rem; margin-top: 0.3rem; }

        .other-tab-nav {
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
        .other-tab-btn {
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
        .other-tab-btn .count-badge {
            background: #e0e0e0;
            color: #666;
            border-radius: 50px;
            padding: 1px 8px;
            font-size: 0.75rem;
            font-weight: 700;
            transition: all 0.25s;
        }
        .other-tab-btn.active-live      { background: linear-gradient(135deg, #ff6b6b, #ee5a52); color: white; }
        .other-tab-btn.active-upcoming  { background: linear-gradient(135deg, #667eea, #764ba2); color: white; }
        .other-tab-btn.active-completed { background: linear-gradient(135deg, #95a5a6, #7f8c8d); color: white; }
        .other-tab-btn.active-live .count-badge,
        .other-tab-btn.active-upcoming .count-badge,
        .other-tab-btn.active-completed .count-badge { background: rgba(255,255,255,0.3); color: white; }
        .other-tab-btn:not(.active-live):not(.active-upcoming):not(.active-completed):hover { background: #f5f5f5; color: #333; }

        .other-tab-panel { display: none; }
        .other-tab-panel.active { display: block; }

        /* view-only action button for other organizers */
        .btn-view-only {
            flex: 1; padding: 0.8rem; border-radius: 8px; font-weight: 600;
            text-align: center; text-decoration: none; transition: all 0.3s;
            background: #4ecdc4; color: white;
        }
        .btn-view-only:hover { background: #45b8af; transform: translateY(-2px); }
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

    <section class="tournaments-section">
        <div class="container">

            <div class="section-header">
                <h1 class="section-title">My Tournaments</h1>
                <a href="CreateTournament.jsp" class="btn-create">+ Create Tournament</a>
            </div>

            <!-- Tab Navigation -->
            <div class="tab-nav">
                <button class="tab-btn <%= !liveList.isEmpty() ? "active-live" : "" %>"
                        id="btn-live" onclick="switchTab('live')">
                    <span class="live-dot"></span> Live
                    <span class="count-badge"><%= liveList.size() %></span>
                </button>
                <button class="tab-btn <%= liveList.isEmpty() ? "active-upcoming" : "" %>"
                        id="btn-upcoming" onclick="switchTab('upcoming')">
                    📅 Upcoming
                    <span class="count-badge"><%= upcomingList.size() %></span>
                </button>
                <button class="tab-btn"
                        id="btn-completed" onclick="switchTab('completed')">
                    🏆 Completed
                    <span class="count-badge"><%= completedList.size() %></span>
                </button>
            </div>

            <!-- LIVE TAB -->
            <div class="tab-panel <%= !liveList.isEmpty() ? "active" : "" %>" id="panel-live">
                <% if (liveList.isEmpty()) { %>
                    <div class="empty-state">
                        <div class="empty-icon">🔴</div>
                        <h2 class="empty-title">No Live Tournaments</h2>
                        <p class="empty-text">None of your tournaments are currently ongoing.</p>
                    </div>
                <% } else { %>
                    <div class="tournaments-grid">
                        <% for (Tournament t : liveList) { %>
                        <div class="tournament-card">
                            <div class="tournament-header header-live">
                                <div class="status-badge badge-live">🔴 Live Now</div>
                                <h3 class="tournament-name"><%= t.getTournamentName() %></h3>
                            </div>
                            <div class="tournament-body">
                                <div class="tournament-info">
                                    <div class="info-item"><span class="info-icon">📍</span><span><%= t.getLocation() %></span></div>
                                    <div class="info-item"><span class="info-icon">📅</span><span><%= dateFormat.format(t.getTournamentDate()) %></span></div>
                                    <div class="info-item"><span class="info-icon">⏰</span><span><%= timeFormat.format(t.getStartTime()) %></span></div>
                                    <div class="info-item"><span class="info-icon">👥</span><span><%= t.getCurrentTeams() %>/<%= t.getMaxTeams() %> Teams</span></div>
                                    <div class="info-item"><span class="info-icon">🏆</span><span><%= t.getCategory().substring(0,1).toUpperCase() + t.getCategory().substring(1) %> | <%= t.getTournamentType().substring(0,1).toUpperCase() + t.getTournamentType().substring(1) %></span></div>
                                </div>
                                <div class="card-actions">
                                    <a href="OrganizerViewDetail.jsp?id=<%= t.getTournamentId() %>" class="btn-view-details">View Details</a>
                                    <a href="TournamentEditOrganizer.jsp?id=<%= t.getTournamentId() %>" class="btn-edit-tournament">Edit</a>
                                </div>
                            </div>
                        </div>
                        <% } %>
                    </div>
                <% } %>
            </div>

            <!-- UPCOMING TAB -->
            <div class="tab-panel <%= liveList.isEmpty() ? "active" : "" %>" id="panel-upcoming">
                <% if (upcomingList.isEmpty()) { %>
                    <div class="empty-state">
                        <div class="empty-icon">🏐</div>
                        <h2 class="empty-title">No Upcoming Tournaments</h2>
                        <p class="empty-text">Create a new tournament to get started!</p>
                        <a href="CreateTournament.jsp" class="btn-create">+ Create Tournament</a>
                    </div>
                <% } else { %>
                    <div class="tournaments-grid">
                        <% for (Tournament t : upcomingList) {
                            String badgeClass, badgeText;
                            switch (t.getStatus().toLowerCase()) {
                                case "ongoing":
                                    badgeClass = "badge-upcoming"; badgeText = "Registration Open"; break;
                                default:
                                    badgeClass = "badge-upcoming"; badgeText = "Registration Open"; break;
                            }
                        %>
                        <div class="tournament-card">
                            <div class="tournament-header header-upcoming">
                                <div class="status-badge badge-upcoming">Registration Open</div>
                                <h3 class="tournament-name"><%= t.getTournamentName() %></h3>
                            </div>
                            <div class="tournament-body">
                                <div class="tournament-info">
                                    <div class="info-item"><span class="info-icon">📍</span><span><%= t.getLocation() %></span></div>
                                    <div class="info-item"><span class="info-icon">📅</span><span><%= dateFormat.format(t.getTournamentDate()) %></span></div>
                                    <div class="info-item"><span class="info-icon">⏰</span><span><%= timeFormat.format(t.getStartTime()) %></span></div>
                                    <div class="info-item"><span class="info-icon">👥</span><span><%= t.getCurrentTeams() %>/<%= t.getMaxTeams() %> Teams</span></div>
                                    <div class="info-item"><span class="info-icon">🏆</span><span><%= t.getCategory().substring(0,1).toUpperCase() + t.getCategory().substring(1) %> | <%= t.getTournamentType().substring(0,1).toUpperCase() + t.getTournamentType().substring(1) %></span></div>
                                </div>
                                <div class="card-actions">
                                    <a href="OrganizerViewDetail.jsp?id=<%= t.getTournamentId() %>" class="btn-view-details">View Details</a>
                                    <a href="TournamentEditOrganizer.jsp?id=<%= t.getTournamentId() %>" class="btn-edit-tournament">Edit</a>
                                </div>
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
                        <div class="empty-icon">🏆</div>
                        <h2 class="empty-title">No Completed Tournaments</h2>
                        <p class="empty-text">Finished tournaments will appear here.</p>
                    </div>
                <% } else { %>
                    <div class="tournaments-grid">
                        <% for (Tournament t : completedList) {
                            boolean isCancelled = t.getStatus().equalsIgnoreCase("cancelled");
                        %>
                        <div class="tournament-card">
                            <div class="tournament-header header-completed">
                                <div class="status-badge <%= isCancelled ? "badge-cancelled" : "badge-completed" %>">
                                    <%= isCancelled ? "❌ Cancelled" : "✅ Completed" %>
                                </div>
                                <h3 class="tournament-name"><%= t.getTournamentName() %></h3>
                            </div>
                            <div class="tournament-body">
                                <div class="tournament-info">
                                    <div class="info-item"><span class="info-icon">📍</span><span><%= t.getLocation() %></span></div>
                                    <div class="info-item"><span class="info-icon">📅</span><span><%= dateFormat.format(t.getTournamentDate()) %></span></div>
                                    <div class="info-item"><span class="info-icon">⏰</span><span><%= timeFormat.format(t.getStartTime()) %></span></div>
                                    <div class="info-item"><span class="info-icon">👥</span><span><%= t.getCurrentTeams() %>/<%= t.getMaxTeams() %> Teams</span></div>
                                    <div class="info-item"><span class="info-icon">🏆</span><span><%= t.getCategory().substring(0,1).toUpperCase() + t.getCategory().substring(1) %> | <%= t.getTournamentType().substring(0,1).toUpperCase() + t.getTournamentType().substring(1) %></span></div>
                                </div>
                                <div class="card-actions">
                                    <a href="OrganizerViewDetail.jsp?id=<%= t.getTournamentId() %>" class="btn-view-details">View Details</a>
                                    <% if (!isCancelled) { %>
                                        <a href="OrganizerResult.jsp?id=<%= t.getTournamentId() %>" class="btn-edit-tournament" style="background: linear-gradient(135deg, #f7971e, #ffd200); color: #1a1a2e;">Results</a>
                                    <% } %>
                                </div>
                            </div>
                        </div>
                        <% } %>
                    </div>
                <% } %>
            </div>

        </div>
    </section>

    <!-- ═══════════════════════════════════════════════════ -->
    <!-- OTHER ORGANIZERS' TOURNAMENTS SECTION             -->
    <!-- ═══════════════════════════════════════════════════ -->
    <section class="other-section">
        <div class="container">

            <div class="other-section-header">
                <div>
                    <h1 class="other-section-title">Other Tournaments</h1>
                    <p class="other-section-subtitle">Tournaments created by other organizers</p>
                </div>
            </div>

            <!-- Other Tab Navigation -->
            <div class="other-tab-nav">
                <button class="other-tab-btn <%= !otherLiveList.isEmpty() ? "active-live" : "" %>"
                        id="other-btn-live" onclick="switchOtherTab('live')">
                    <span class="live-dot"></span> Live
                    <span class="count-badge"><%= otherLiveList.size() %></span>
                </button>
                <button class="other-tab-btn <%= otherLiveList.isEmpty() ? "active-upcoming" : "" %>"
                        id="other-btn-upcoming" onclick="switchOtherTab('upcoming')">
                    📅 Upcoming
                    <span class="count-badge"><%= otherUpcomingList.size() %></span>
                </button>
                <button class="other-tab-btn"
                        id="other-btn-completed" onclick="switchOtherTab('completed')">
                    🏆 Completed
                    <span class="count-badge"><%= otherCompletedList.size() %></span>
                </button>
            </div>

            <!-- OTHER LIVE TAB -->
            <div class="other-tab-panel <%= !otherLiveList.isEmpty() ? "active" : "" %>" id="other-panel-live">
                <% if (otherLiveList.isEmpty()) { %>
                    <div class="empty-state">
                        <div class="empty-icon">🔴</div>
                        <h2 class="empty-title">No Live Tournaments</h2>
                        <p class="empty-text">No other organizers have ongoing tournaments right now.</p>
                    </div>
                <% } else { %>
                    <div class="tournaments-grid">
                        <% for (Tournament t : otherLiveList) { %>
                        <div class="tournament-card">
                            <div class="tournament-header header-live">
                                <div class="status-badge badge-live">🔴 Live Now</div>
                                <h3 class="tournament-name"><%= t.getTournamentName() %></h3>
                            </div>
                            <div class="tournament-body">
                                <div class="tournament-info">
                                    <div class="info-item"><span class="info-icon">📍</span><span><%= t.getLocation() %></span></div>
                                    <div class="info-item"><span class="info-icon">📅</span><span><%= dateFormat.format(t.getTournamentDate()) %></span></div>
                                    <div class="info-item"><span class="info-icon">⏰</span><span><%= timeFormat.format(t.getStartTime()) %></span></div>
                                    <div class="info-item"><span class="info-icon">👥</span><span><%= t.getCurrentTeams() %>/<%= t.getMaxTeams() %> Teams</span></div>
                                    <div class="info-item"><span class="info-icon">🏆</span><span><%= t.getCategory().substring(0,1).toUpperCase() + t.getCategory().substring(1) %> | <%= t.getTournamentType().substring(0,1).toUpperCase() + t.getTournamentType().substring(1) %></span></div>
                                </div>
                            </div>
                        </div>
                        <% } %>
                    </div>
                <% } %>
            </div>

            <!-- OTHER UPCOMING TAB -->
            <div class="other-tab-panel <%= otherLiveList.isEmpty() ? "active" : "" %>" id="other-panel-upcoming">
                <% if (otherUpcomingList.isEmpty()) { %>
                    <div class="empty-state">
                        <div class="empty-icon">🏐</div>
                        <h2 class="empty-title">No Upcoming Tournaments</h2>
                        <p class="empty-text">No other organizers have upcoming tournaments.</p>
                    </div>
                <% } else { %>
                    <div class="tournaments-grid">
                        <% for (Tournament t : otherUpcomingList) { %>
                        <div class="tournament-card">
                            <div class="tournament-header header-upcoming">
                                <div class="status-badge badge-upcoming">Registration Open</div>
                                <h3 class="tournament-name"><%= t.getTournamentName() %></h3>
                            </div>
                            <div class="tournament-body">
                                <div class="tournament-info">
                                    <div class="info-item"><span class="info-icon">📍</span><span><%= t.getLocation() %></span></div>
                                    <div class="info-item"><span class="info-icon">📅</span><span><%= dateFormat.format(t.getTournamentDate()) %></span></div>
                                    <div class="info-item"><span class="info-icon">⏰</span><span><%= timeFormat.format(t.getStartTime()) %></span></div>
                                    <div class="info-item"><span class="info-icon">👥</span><span><%= t.getCurrentTeams() %>/<%= t.getMaxTeams() %> Teams</span></div>
                                    <div class="info-item"><span class="info-icon">🏆</span><span><%= t.getCategory().substring(0,1).toUpperCase() + t.getCategory().substring(1) %> | <%= t.getTournamentType().substring(0,1).toUpperCase() + t.getTournamentType().substring(1) %></span></div>
                                </div>
                            </div>
                        </div>
                        <% } %>
                    </div>
                <% } %>
            </div>

            <!-- OTHER COMPLETED TAB -->
            <div class="other-tab-panel" id="other-panel-completed">
                <% if (otherCompletedList.isEmpty()) { %>
                    <div class="empty-state">
                        <div class="empty-icon">🏆</div>
                        <h2 class="empty-title">No Completed Tournaments</h2>
                        <p class="empty-text">No other organizers have completed tournaments yet.</p>
                    </div>
                <% } else { %>
                    <div class="tournaments-grid">
                        <% for (Tournament t : otherCompletedList) {
                            boolean isCancelled = t.getStatus().equalsIgnoreCase("cancelled");
                        %>
                        <div class="tournament-card">
                            <div class="tournament-header header-completed">
                                <div class="status-badge <%= isCancelled ? "badge-cancelled" : "badge-completed" %>">
                                    <%= isCancelled ? "❌ Cancelled" : "✅ Completed" %>
                                </div>
                                <h3 class="tournament-name"><%= t.getTournamentName() %></h3>
                            </div>
                            <div class="tournament-body">
                                <div class="tournament-info">
                                    <div class="info-item"><span class="info-icon">📍</span><span><%= t.getLocation() %></span></div>
                                    <div class="info-item"><span class="info-icon">📅</span><span><%= dateFormat.format(t.getTournamentDate()) %></span></div>
                                    <div class="info-item"><span class="info-icon">⏰</span><span><%= timeFormat.format(t.getStartTime()) %></span></div>
                                    <div class="info-item"><span class="info-icon">👥</span><span><%= t.getCurrentTeams() %>/<%= t.getMaxTeams() %> Teams</span></div>
                                    <div class="info-item"><span class="info-icon">🏆</span><span><%= t.getCategory().substring(0,1).toUpperCase() + t.getCategory().substring(1) %> | <%= t.getTournamentType().substring(0,1).toUpperCase() + t.getTournamentType().substring(1) %></span></div>
                                </div>
                            </div>
                        </div>
                        <% } %>
                    </div>
                <% } %>
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
                <p>&copy; <%= new java.util.Date().getYear() + 1900 %> VolleyMetric. All rights reserved.</p>
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
            document.getElementById('btn-' + tab).classList.add('active-' + tab);
        }

        function switchOtherTab(tab) {
            document.querySelectorAll('.other-tab-panel').forEach(p => p.classList.remove('active'));
            document.querySelectorAll('.other-tab-btn').forEach(b => {
                b.classList.remove('active-live', 'active-upcoming', 'active-completed');
            });
            document.getElementById('other-panel-' + tab).classList.add('active');
            document.getElementById('other-btn-' + tab).classList.add('active-' + tab);
        }
    </script>
</body>
</html>