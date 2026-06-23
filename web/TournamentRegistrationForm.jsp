<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="Model.Tournament" %>
<%
    // Check if user is logged in
    String username = (String) session.getAttribute("username");
    String fullname = (String) session.getAttribute("fullname");
    Integer userId = (Integer) session.getAttribute("userId");

    if (username == null || userId == null) {
        response.sendRedirect("Login.jsp");
        return;
    }

    // Get tournament from request attribute
    Tournament tournament = (Tournament) request.getAttribute("tournament");
    if (tournament == null) {
        response.sendRedirect("UserTournament.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Register Team - VolleyMetric</title>
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
                background: white;
                border: 2px solid red;
                border-radius: 5px;
                padding: 4px 10px;
            }

            .user-role-label {
                font-size: 0.8rem;
                font-weight: 600;
                color: #ff6b6b;
                padding: 0;
                margin: 0;
            }

            .user-name {
                font-size: 0.95rem;
                font-weight: 600;
                color: #000;
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
                border: none;
                cursor: pointer;
            }

            .btn-logout:hover {
                background-color: #ee5a52;
                transform: translateY(-2px);
            }

            .form-section {
                padding: 4rem 0;
                background-color: #f8f9fa;
                min-height: 80vh;
            }

            .form-container {
                max-width: 900px;
                margin: 0 auto;
                background-color: #fff;
                border-radius: 10px;
                padding: 3rem;
                box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
            }

            .tournament-header {
                text-align: center;
                padding: 1.5rem;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                border-radius: 10px;
                margin-bottom: 2rem;
            }

            .tournament-header h2 {
                color: white;
                font-size: 1.8rem;
                margin: 0;
            }

            .form-title {
                font-size: 1.5rem;
                color: #1a1a2e;
                margin-bottom: 2rem;
                text-align: center;
            }

            .members-container {
                margin-bottom: 2rem;
            }

            .member-row {
                display: grid;
                grid-template-columns: 80px 1fr 200px 120px 50px;
                gap: 1rem;
                align-items: end;
                margin-bottom: 1rem;
                padding: 1rem;
                background-color: #f8f9fa;
                border-radius: 8px;
            }

            .captain-label {
                grid-column: 1 / -1;
                font-size: 0.85rem;
                font-weight: 700;
                color: #ff6b6b;
                text-transform: uppercase;
                letter-spacing: 1px;
                margin-bottom: -0.5rem;
            }

            .form-group {
                display: flex;
                flex-direction: column;
                gap: 0.5rem;
            }

            .form-label {
                font-weight: 600;
                color: #333;
                font-size: 0.9rem;
            }

            .form-input,
            .form-select {
                padding: 0.8rem;
                border: 2px solid #e0e0e0;
                border-radius: 5px;
                font-size: 1rem;
                transition: all 0.3s;
                font-family: inherit;
            }

            .form-input:focus,
            .form-select:focus {
                outline: none;
                border-color: #667eea;
                box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
            }

            .form-input:disabled {
                background-color: #f0f0f0;
                cursor: not-allowed;
            }

            .btn-remove {
                background-color: #ff6b6b;
                color: white;
                border: none;
                width: 40px;
                height: 40px;
                border-radius: 5px;
                cursor: pointer;
                font-size: 1.2rem;
                transition: all 0.3s;
            }

            .btn-remove:hover {
                background-color: #ee5a52;
            }

            .btn-add-member {
                background-color: #4ecdc4;
                color: white;
                padding: 0.8rem 1.5rem;
                border: none;
                border-radius: 5px;
                font-size: 1rem;
                font-weight: 600;
                cursor: pointer;
                transition: all 0.3s;
                width: 100%;
                margin-bottom: 2rem;
            }

            .btn-add-member:hover {
                background-color: #45b8af;
            }

            .btn-add-member:disabled {
                background-color: #ccc;
                cursor: not-allowed;
            }

            .member-count {
                text-align: center;
                font-size: 1rem;
                color: #666;
                margin-bottom: 1rem;
            }

            .form-actions {
                display: flex;
                gap: 1rem;
                margin-top: 2rem;
            }

            .btn-submit {
                flex: 1;
                background-color: #ff6b6b;
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
                background-color: #ee5a52;
                transform: translateY(-2px);
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

            @media (max-width: 768px) {
                .member-row {
                    grid-template-columns: 1fr;
                }

                .captain-label {
                    grid-column: 1;
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

        <section class="form-section">
            <div class="container">
                <div class="form-container">
                    <div class="tournament-header">
                        <h2><%= tournament.getTournamentName()%></h2>
                    </div>

                    <h1 class="form-title">Register Your Team</h1>

                    <%
                        String errorMessage = (String) request.getAttribute("errorMessage");
                        if (errorMessage != null) {
                    %>
                    <div class="alert alert-error">
                        <%= errorMessage%>
                    </div>
                    <% }%>

                    <form action="SubmitTeamRegistration" method="POST" id="registrationForm">
                        <input type="hidden" name="tournamentId" value="<%= tournament.getTournamentId()%>">

                        <div class="form-group" style="margin-bottom: 2rem;">
                            <label class="form-label" style="font-size: 1rem;">Team Name *</label>
                            <input type="text" name="teamName" class="form-input" 
                                   placeholder="Enter your team name" 
                                   style="font-size: 1.1rem; padding: 1rem;"
                                   required>
                        </div>

                        <div class="member-count">
                            <strong>Team Members: <span id="memberCount">1</span>/12</strong>
                        </div>

                        <div class="members-container" id="membersContainer">
                            <!-- Captain (User) -->
                            <div class="member-row">
                                <div class="captain-label">⭐ CAPTAIN</div>
                                <div class="form-group">
                                    <label class="form-label">Name</label>
                                    <input type="text" name="memberName[]" class="form-input" 
                                           value="<%= fullname != null ? fullname : username%>" readonly required>
                                </div>
                                <div class="form-group">
                                    <label class="form-label">Position</label>
                                    <select name="memberPosition[]" class="form-select" required>
                                        <option value="">Select Position</option>
                                        <option value="outside_spiker">Outside Spiker</option>
                                        <option value="opposite">Opposite</option>
                                        <option value="setter">Setter</option>
                                        <option value="middle">Middle Blocker</option>
                                        <option value="libero">Libero</option>
                                    </select>
                                </div>
                                <div class="form-group">
                                    <label class="form-label">Jersey #</label>
                                    <input type="number" name="memberJersey[]" class="form-input" 
                                           min="1" max="99" placeholder="1-99" required>
                                </div>
                                <div></div>
                            </div>
                        </div>

                        <button type="button" class="btn-add-member" id="addMemberBtn">+ Add Team Member</button>

                        <div class="form-actions">
                            <button type="submit" class="btn-submit">Submit Registration</button>
                            <a href="UserTournament.jsp" class="btn-cancel">Cancel</a>
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

        <script>
            let memberCount = 1;
            const maxMembers = 12;
            const membersContainer = document.getElementById('membersContainer');
            const addMemberBtn = document.getElementById('addMemberBtn');
            const memberCountDisplay = document.getElementById('memberCount');

            addMemberBtn.addEventListener('click', function () {
                if (memberCount >= maxMembers) {
                    alert('Maximum 12 members allowed!');
                    return;
                }

                memberCount++;
                updateMemberCount();

                const memberRow = document.createElement('div');
                memberRow.className = 'member-row';
                memberRow.innerHTML = `
                    <div></div>
                    <div class="form-group">
                        <label class="form-label">Name</label>
                        <input type="text" name="memberName[]" class="form-input" placeholder="Enter member name" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Position</label>
                        <select name="memberPosition[]" class="form-select" required>
                            <option value="">Select Position</option>
                            <option value="outside_spiker">Outside Spiker</option>
                            <option value="opposite">Opposite</option>
                            <option value="setter">Setter</option>
                            <option value="middle">Middle Blocker</option>
                            <option value="libero">Libero</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Jersey #</label>
                        <input type="number" name="memberJersey[]" class="form-input" min="1" max="99" placeholder="1-99" required>
                    </div>
                    <button type="button" class="btn-remove" onclick="removeMember(this)">×</button>
                `;

                membersContainer.appendChild(memberRow);

                if (memberCount >= maxMembers) {
                    addMemberBtn.disabled = true;
                    addMemberBtn.textContent = 'Maximum Members Reached';
                }
            });

            function removeMember(button) {
                button.closest('.member-row').remove();
                memberCount--;
                updateMemberCount();

                if (memberCount < maxMembers) {
                    addMemberBtn.disabled = false;
                    addMemberBtn.textContent = '+ Add Team Member';
                }
            }

            function updateMemberCount() {
                memberCountDisplay.textContent = memberCount;
            }

            // Form validation
            document.getElementById('registrationForm').addEventListener('submit', function (e) {
                if (memberCount < 6) {
                    e.preventDefault();
                    alert('Minimum 6 team members required!');
                    return false;
                }

                // Check for duplicate jersey numbers
                const jerseyNumbers = [];
                const jerseyInputs = document.querySelectorAll('input[name="memberJersey[]"]');

                for (let input of jerseyInputs) {
                    const num = input.value;
                    if (jerseyNumbers.includes(num)) {
                        e.preventDefault();
                        alert('Duplicate jersey numbers are not allowed!');
                        input.focus();
                        return false;
                    }
                    jerseyNumbers.push(num);
                }
            });
        </script>
    </body>
</html>