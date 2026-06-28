<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Check if organizer is logged in
    String username = (String) session.getAttribute("organizerUsername");
    String fullname = (String) session.getAttribute("organizerFullname");

    if (username == null) {
        response.sendRedirect("OrganizerLogin.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Create Tournament - VolleyMetric</title>

        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css">
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr/dist/themes/material_purple.css">

        <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />

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
                transition: all 0.3s;
                font-weight: 600;
                border: none;
                cursor: pointer;
            }

            .btn-logout:hover {
                transform: translateY(-2px);
                box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
            }

            /* Form Section */
            .form-section {
                padding: 4rem 0;
                background-color: #f8f9fa;
            }

            .form-container {
                max-width: 800px;
                margin: 0 auto;
                background-color: #fff;
                border-radius: 10px;
                padding: 3rem;
                box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
            }

            .form-header {
                text-align: center;
                margin-bottom: 2rem;
            }

            .form-title {
                font-size: 2rem;
                color: #1a1a2e;
                margin-bottom: 0.5rem;
            }

            .form-subtitle {
                color: #666;
                font-size: 1rem;
            }

            .tournament-form {
                display: flex;
                flex-direction: column;
                gap: 1.5rem;
            }

            .form-row {
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 1.5rem;
            }

            .form-group {
                display: flex;
                flex-direction: column;
                gap: 0.5rem;
            }

            .form-group.full-width {
                grid-column: 1 / -1;
            }

            .form-label {
                font-weight: 600;
                color: #333;
                font-size: 0.95rem;
            }

            .form-label .required {
                color: #ff6b6b;
                margin-left: 2px;
            }

            /* Enhanced Input Styling */
            .input-wrapper {
                position: relative;
                display: flex;
                align-items: center;
            }

            .input-icon {
                position: absolute;
                right: 15px;
                color: #764ba2;
                pointer-events: none;
                font-size: 1.1rem;
            }

            .form-input,
            .form-select,
            .form-textarea {
                width: 100%;
                padding: 0.8rem 1rem;
                border: 2px solid #e0e0e0;
                border-radius: 5px;
                font-size: 1rem;
                transition: all 0.3s;
                font-family: inherit;
                box-sizing: border-box;
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

            /* Ensure Flatpickr inputs look consistent */
            .flatpickr-input {
                background-color: #fff !important;
                cursor: pointer;
            }

            .form-input:focus,
            .form-select:focus,
            .form-textarea:focus {
                outline: none;
                border-color: #667eea;
                box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
            }

            .form-textarea {
                resize: vertical;
                min-height: 100px;
            }

            .alert {
                padding: 1rem;
                border-radius: 5px;
                margin-bottom: 1.5rem;
                font-size: 0.95rem;
            }

            .alert-error {
                background-color: #fee;
                border: 1px solid #fcc;
                color: #c33;
            }

            .alert-success {
                background-color: #efe;
                border: 1px solid #cfc;
                color: #3c3;
            }

            .form-actions {
                display: flex;
                gap: 1rem;
                margin-top: 1rem;
            }

            .btn-submit {
                flex: 1;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: #fff;
                padding: 1rem;
                border: none;
                border-radius: 5px;
                font-size: 1rem;
                font-weight: 600;
                cursor: pointer;
                transition: all 0.3s;
            }

            .btn-submit:hover {
                transform: translateY(-2px);
                box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
            }

            .btn-cancel {
                flex: 1;
                background-color: #e0e0e0;
                color: #333;
                padding: 1rem;
                border: none;
                border-radius: 5px;
                font-size: 1rem;
                font-weight: 600;
                cursor: pointer;
                transition: all 0.3s;
                text-decoration: none;
                text-align: center;
            }

            .btn-cancel:hover {
                background-color: #d0d0d0;
            }

            @media (max-width: 768px) {
                .form-row {
                    grid-template-columns: 1fr;
                }

                .form-container {
                    padding: 2rem;
                }

                .form-actions {
                    flex-direction: column;
                }
            }
        </style>
    </head>
    <body>
        <header class="header">
            <div class="container">
                <div class="logo">
                    <div style="width: 40px; height: 40px; overflow: hidden; background: white; border: 2px solid red;">
                        <img src="umtlogo.png" alt="UMT Logo" class="umt-logo"
                             style="width: 100%; height: 100%; object-fit: contain;"
                             onerror="console.log('Image failed to load'); this.style.display='none';">
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
                        <h1 class="form-title">Create New Tournament</h1>
                        <p class="form-subtitle">Fill in the details to create your volleyball tournament</p>
                    </div>

                    <%
                        String errorMessage = (String) request.getAttribute("errorMessage");
                        if (errorMessage != null) {
                    %>
                    <div class="alert alert-error">
                        <%= errorMessage%>
                    </div>
                    <% } %>

                    <%
                        String successMessage = (String) request.getAttribute("successMessage");
                        if (successMessage != null) {
                    %>
                    <div class="alert alert-success">
                        <%= successMessage%>
                    </div>
                    <% }%>

                    <form action="CreateTournamentServlet" method="POST" class="tournament-form">
                        <div class="form-group full-width">
                            <label for="tournamentName" class="form-label">
                                Tournament Name<span class="required">*</span>
                            </label>
                            <input 
                                type="text" 
                                id="tournamentName" 
                                name="tournamentName" 
                                class="form-input" 
                                placeholder="e.g., Summer Championship 2026"
                                value="<%= request.getParameter("tournamentName") != null ? request.getParameter("tournamentName") : ""%>"
                                required
                                />
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label for="tournamentDate" class="form-label">
                                    Tournament Date<span class="required">*</span>
                                </label>
                                <div class="input-wrapper">
                                    <input 
                                        type="text" 
                                        id="tournamentDate" 
                                        name="tournamentDate" 
                                        class="form-input"
                                        placeholder="Select Date.."
                                        value="<%= request.getParameter("tournamentDate") != null ? request.getParameter("tournamentDate") : ""%>"
                                        required
                                        />
                                    <span class="input-icon">📅</span>
                                </div>
                            </div>

                            <div class="form-group">
                                <label for="startTime" class="form-label">
                                    Start Time<span class="required">*</span>
                                </label>
                                <div class="input-wrapper">
                                    <input 
                                        type="text" 
                                        id="startTime" 
                                        name="startTime" 
                                        class="form-input"
                                        placeholder="Select Time.."
                                        value="<%= request.getParameter("startTime") != null ? request.getParameter("startTime") : ""%>"
                                        required
                                        />
                                    <span class="input-icon">🕒</span>
                                </div>
                            </div>
                        </div>

                        <div class="form-group full-width">
                            <label for="location" class="form-label">
                                Location<span class="required">*</span>
                            </label>
                            <input 
                                type="text" 
                                id="location" 
                                name="location" 
                                class="form-input" 
                                placeholder="Click the map to select a location..."
                                value="<%= request.getParameter("location") != null ? request.getParameter("location") : ""%>"
                                required
                                />
                            <div id="map"></div>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label for="category" class="form-label">
                                    Category<span class="required">*</span>
                                </label>
                                <select 
                                    id="category" 
                                    name="category" 
                                    class="form-select"
                                    required
                                    >
                                    <option value="">Select Category</option>
                                    <option value="men" <%= "men".equals(request.getParameter("category")) ? "selected" : ""%>>Men</option>
                                    <option value="women" <%= "women".equals(request.getParameter("category")) ? "selected" : ""%>>Women</option>
                                    <option value="mixed" <%= "mixed".equals(request.getParameter("category")) ? "selected" : ""%>>Mixed</option>
                                </select>
                            </div>

                            <div class="form-group">
                                <label for="tournamentType" class="form-label">
                                    Tournament Type<span class="required">*</span>
                                </label>
                                <select 
                                    id="tournamentType" 
                                    name="tournamentType" 
                                    class="form-select"
                                    required
                                    >
                                    <option value="">Select Type</option>
                                    <option value="indoor" <%= "indoor".equals(request.getParameter("tournamentType")) ? "selected" : ""%>>Indoor</option>
                                    <option value="beach" <%= "beach".equals(request.getParameter("tournamentType")) ? "selected" : ""%>>Beach</option>
                                </select>
                            </div>
                        </div>

                        <div class="form-group full-width">
                            <label for="maxTeams" class="form-label">
                                Maximum Number of Teams<span class="required">*</span>
                            </label>
                            <input 
                                type="number" 
                                id="maxTeams" 
                                name="maxTeams" 
                                class="form-input" 
                                placeholder="e.g., 16"
                                min="2"
                                max="64"
                                value="<%= request.getParameter("maxTeams") != null ? request.getParameter("maxTeams") : ""%>"
                                required
                                />
                        </div>

                        <div class="form-group full-width">
                            <label for="description" class="form-label">
                                Tournament Description
                            </label>
                            <textarea 
                                id="description" 
                                name="description" 
                                class="form-textarea" 
                                placeholder="Enter tournament details, rules, and any additional information..."
                                ><%= request.getParameter("description") != null ? request.getParameter("description") : ""%></textarea>
                        </div>

                        <div class="form-actions">
                            <button type="submit" class="btn-submit">
                                Create Tournament
                            </button>
                            <a href="OrganizerHome.jsp" class="btn-cancel">
                                Cancel
                            </a>
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
            // Date Picker Initialization
            flatpickr("#tournamentDate", {
                dateFormat: "Y-m-d", // Server-side format
                altInput: true, // Show user-friendly input
                altFormat: "F j, Y", // Format: January 18, 2026
                minDate: "today", // No past dates
                disableMobile: "true"
            });

            // Time Picker Initialization
            flatpickr("#startTime", {
                enableTime: true,
                noCalendar: true,
                dateFormat: "H:i", // 24h format for database
                altInput: true, // Show user-friendly input
                altFormat: "h:i K", // Format: 10:00 AM
                time_24hr: false,
                disableMobile: "true"
            });

            // Map Initialization centered on Kuala Terengganu
            var map = L.map('map').setView([5.3302, 103.1408], 13);
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                attribution: '&copy; OpenStreetMap'
            }).addTo(map);

            var marker;

            // Click on map to get address
            map.on('click', function (e) {
                if (marker) {
                    marker.setLatLng(e.latlng);
                } else {
                    marker = L.marker(e.latlng).addTo(map);
                }

                // Reverse Geocoding using Nominatim
                fetch('https://nominatim.openstreetmap.org/reverse?format=json&lat=' + e.latlng.lat + '&lon=' + e.latlng.lng)
                        .then(function (res) {
                            return res.json();
                        })
                        .then(function (data) {
                            document.getElementById('location').value = data.display_name;
                        })
                        .catch(function (err) {
                            console.error('Error fetching address:', err);
                        });
            });
        </script>
    </body>
</html>