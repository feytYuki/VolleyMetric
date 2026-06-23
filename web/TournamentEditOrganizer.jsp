<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="Model.Tournament" %>
<%@ page import="DAO.TournamentDAO" %>
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
    
    // Get tournament ID from parameter
    String tournamentIdStr = request.getParameter("id");
    if (tournamentIdStr == null) {
        response.sendRedirect("OrganizerTournament.jsp");
        return;
    }
    
    int tournamentId = Integer.parseInt(tournamentIdStr);
    
    // Get tournament details
    TournamentDAO tournamentDAO = new TournamentDAO();
    Tournament tournament = tournamentDAO.getTournamentById(tournamentId);
    
    // Check if tournament exists and belongs to this organizer
    if (tournament == null || tournament.getOrganizerId() != organizerId) {
        response.sendRedirect("OrganizerTournament.jsp");
        return;
    }
    
    // Format date and time for hidden input values
    SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");
    SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm");
    String dateStr = dateFormat.format(tournament.getTournamentDate());
    String timeStr = timeFormat.format(tournament.getStartTime());
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Edit Tournament - VolleyMetric</title>
    
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr/dist/themes/material_purple.css">
    
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    
    <link rel="stylesheet" href="style.css">
    <style>
        /* Existing Styles */
        .user-info { display: flex; align-items: center; gap: 1rem; }
        .user-details { display: flex; flex-direction: column; align-items: flex-end; background: white; border: 2px solid #764ba2; border-radius: 5px; padding: 4px 10px; }
        .user-role-label { font-size: 0.8rem; font-weight: 600; color: #764ba2; margin: 0; }
        .user-name { font-size: 0.95rem; font-weight: 600; color: #000; margin: 0; }
        .btn-logout { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #fff; padding: 0.6rem 1.5rem; text-decoration: none; border-radius: 5px; transition: all 0.3s; font-weight: 600; border: none; cursor: pointer; }
        .btn-logout:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4); }

        /* Form Design */
        .form-section { padding: 4rem 0; background-color: #f8f9fa; }
        .form-container { max-width: 800px; margin: 0 auto; background-color: #fff; border-radius: 10px; padding: 3rem; box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1); }
        .form-header { text-align: center; margin-bottom: 2rem; }
        .form-title { font-size: 2rem; color: #1a1a2e; margin-bottom: 0.5rem; }
        .form-subtitle { color: #666; font-size: 1rem; }
        .tournament-form { display: flex; flex-direction: column; gap: 1.5rem; }
        .form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; }
        .form-group { display: flex; flex-direction: column; gap: 0.5rem; }
        .form-group.full-width { grid-column: 1 / -1; }
        .form-label { font-weight: 600; color: #333; font-size: 0.95rem; }
        .form-label .required { color: #ff6b6b; margin-left: 2px; }

        .form-input, .form-select, .form-textarea {
            width: 100%; padding: 0.8rem 1rem; border: 2px solid #e0e0e0; border-radius: 5px;
            font-size: 1rem; transition: all 0.3s; font-family: inherit; box-sizing: border-box;
        }
        
        /* Map Styling */
        #map {
            height: 350px;
            width: 100%;
            border-radius: 8px;
            margin-top: 10px;
            border: 2px solid #e0e0e0;
            z-index: 1;
        }

        .alert { padding: 1rem; border-radius: 5px; margin-bottom: 1.5rem; font-size: 0.95rem; }
        .alert-error { background-color: #fee; border: 1px solid #fcc; color: #c33; }

        .form-actions { display: flex; gap: 1rem; margin-top: 1rem; }
        .btn-submit { flex: 1; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #fff; padding: 1rem; border: none; border-radius: 5px; font-size: 1rem; font-weight: 600; cursor: pointer; transition: all 0.3s; }
        .btn-submit:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4); }
        .btn-cancel { flex: 1; background-color: #e0e0e0; color: #333; padding: 1rem; border: none; border-radius: 5px; font-size: 1rem; font-weight: 600; cursor: pointer; transition: all 0.3s; text-decoration: none; text-align: center; }

        @media (max-width: 768px) { .form-row { grid-template-columns: 1fr; } .form-container { padding: 2rem; } .form-actions { flex-direction: column; } }
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

    <section class="form-section">
        <div class="container">
            <div class="form-container">
                <div class="form-header">
                    <h1 class="form-title">Edit Tournament</h1>
                    <p class="form-subtitle">Update your tournament information</p>
                </div>

                <% String errorMessage = (String) request.getAttribute("errorMessage");
                   if (errorMessage != null) { %>
                    <div class="alert alert-error"><%= errorMessage %></div>
                <% } %>

                <form action="OrganizerEditServlet" method="POST" class="tournament-form">
                    <input type="hidden" name="tournamentId" value="<%= tournament.getTournamentId() %>">
                    
                    <div class="form-group full-width">
                        <label for="tournamentName" class="form-label">Tournament Name<span class="required">*</span></label>
                        <input type="text" id="tournamentName" name="tournamentName" class="form-input" value="<%= tournament.getTournamentName() %>" required />
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label for="tournamentDate" class="form-label">Tournament Date<span class="required">*</span></label>
                            <div class="input-wrapper">
                                <input type="text" id="tournamentDate" name="tournamentDate" class="form-input" value="<%= dateStr %>" required />
                                <span class="input-icon">📅</span>
                            </div>
                        </div>

                        <div class="form-group">
                            <label for="startTime" class="form-label">Start Time<span class="required">*</span></label>
                            <div class="input-wrapper">
                                <input type="text" id="startTime" name="startTime" class="form-input" value="<%= timeStr %>" required />
                                <span class="input-icon">🕒</span>
                            </div>
                        </div>
                    </div>

                    <div class="form-group full-width">
                        <label for="location" class="form-label">Location<span class="required">*</span></label>
                        <input type="text" id="location" name="location" class="form-input" value="<%= tournament.getLocation() %>" placeholder="Click map to adjust address..." required />
                        <div id="map"></div>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label for="category" class="form-label">Category<span class="required">*</span></label>
                            <select id="category" name="category" class="form-select" required>
                                <option value="men" <%= "men".equals(tournament.getCategory()) ? "selected" : "" %>>Men</option>
                                <option value="women" <%= "women".equals(tournament.getCategory()) ? "selected" : "" %>>Women</option>
                                <option value="mixed" <%= "mixed".equals(tournament.getCategory()) ? "selected" : "" %>>Mixed</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label for="tournamentType" class="form-label">Tournament Type<span class="required">*</span></label>
                            <select id="tournamentType" name="tournamentType" class="form-select" required>
                                <option value="indoor" <%= "indoor".equals(tournament.getTournamentType()) ? "selected" : "" %>>Indoor</option>
                                <option value="beach" <%= "beach".equals(tournament.getTournamentType()) ? "selected" : "" %>>Beach</option>
                            </select>
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label for="maxTeams" class="form-label">Max Teams<span class="required">*</span></label>
                            <input type="number" id="maxTeams" name="maxTeams" class="form-input" min="2" max="64" value="<%= tournament.getMaxTeams() %>" required />
                        </div>
                        <div class="form-group">
                            <label for="status" class="form-label">Status<span class="required">*</span></label>
                            <select id="status" name="status" class="form-select" required>
                                <option value="upcoming" <%= "upcoming".equals(tournament.getStatus()) ? "selected" : "" %>>Upcoming</option>
                                <option value="ongoing" <%= "ongoing".equals(tournament.getStatus()) ? "selected" : "" %>>Ongoing</option>
                                <option value="completed" <%= "completed".equals(tournament.getStatus()) ? "selected" : "" %>>Completed</option>
                            </select>
                        </div>
                    </div>

                    <div class="form-group full-width">
                        <label for="description" class="form-label">Description</label>
                        <textarea id="description" name="description" class="form-textarea"><%= tournament.getDescription() != null ? tournament.getDescription() : "" %></textarea>
                    </div>

                    <div class="form-actions">
                        <button type="submit" class="btn-submit">Update Tournament</button>
                        <a href="OrganizerTournament.jsp" class="btn-cancel">Cancel</a>
                    </div>
                </form>
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

    <script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <script>
        // 1. Initialize Flatpickr Pickers
        flatpickr("#tournamentDate", { dateFormat: "Y-m-d", altInput: true, altFormat: "F j, Y", minDate: "today" });
        flatpickr("#startTime", { enableTime: true, noCalendar: true, dateFormat: "H:i", altInput: true, altFormat: "h:i K", time_24hr: false });

        // 2. Initialize Map (Centered on Kuala Terengganu by default)
        var map = L.map('map').setView([5.3302, 103.1408], 13);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { attribution: '&copy; OpenStreetMap' }).addTo(map);

        var marker;
        var existingLocation = "<%= tournament.getLocation() %>";

        // Try to geocode existing location to center map
        if(existingLocation) {
            fetch('https://nominatim.openstreetmap.org/search?format=json&q=' + encodeURIComponent(existingLocation))
                .then(res => res.json())
                .then(data => {
                    if(data.length > 0) {
                        var lat = data[0].lat;
                        var lon = data[0].lon;
                        map.setView([lat, lon], 15);
                        marker = L.marker([lat, lon]).addTo(map);
                    }
                });
        }

        // Allow clicking map to update location
        map.on('click', function(e) {
            if (marker) { marker.setLatLng(e.latlng); } 
            else { marker = L.marker(e.latlng).addTo(map); }

            fetch('https://nominatim.openstreetmap.org/reverse?format=json&lat=' + e.latlng.lat + '&lon=' + e.latlng.lng)
                .then(res => res.json())
                .then(data => { 
                    document.getElementById('location').value = data.display_name; 
                });
        });
    </script>
</body>
</html>