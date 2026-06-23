<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="Model.TeamRegistration, Model.TeamMember, Model.Tournament" %>
<%@ page import="DAO.TeamRegistrationDAO, DAO.TeamMemberDAO, DAO.TournamentDAO" %>
<%@ page import="java.util.List" %>
<%
    // Check if user is logged in
    String username = (String) session.getAttribute("username");
    String fullname = (String) session.getAttribute("fullname");
    Integer userId = (Integer) session.getAttribute("userId");
    
    if (username == null || userId == null) {
        response.sendRedirect("Login.jsp");
        return;
    }
    
    // Get registration ID
    String registrationIdStr = request.getParameter("registrationId");
    if (registrationIdStr == null) {
        response.sendRedirect("UserRegisTour.jsp");
        return;
    }
    
    int registrationId = Integer.parseInt(registrationIdStr);
    
    // Get registration details
    TeamRegistrationDAO teamRegDAO = new TeamRegistrationDAO();
    TeamMemberDAO teamMemberDAO = new TeamMemberDAO();
    TournamentDAO tournamentDAO = new TournamentDAO();
    
    TeamRegistration registration = teamRegDAO.getRegistrationById(registrationId);
    
    // Verify registration belongs to this user
    if (registration == null || registration.getUserId() != userId) {
        response.sendRedirect("UserRegisTour.jsp");
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
    <title>Edit Team Registration - VolleyMetric</title>
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
        }
        
        .user-name {
            font-size: 0.95rem;
            font-weight: 600;
            color: #000;
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

        .form-group {
            display: flex;
            flex-direction: column;
            gap: 0.5rem;
            margin-bottom: 2rem;
        }

        .form-label {
            font-weight: 600;
            color: #333;
            font-size: 1rem;
        }

        .form-input {
            padding: 0.8rem;
            border: 2px solid #e0e0e0;
            border-radius: 5px;
            font-size: 1rem;
        }

        .form-input:focus {
            outline: none;
            border-color: #667eea;
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

        .form-select {
            padding: 0.8rem;
            border: 2px solid #e0e0e0;
            border-radius: 5px;
            font-size: 1rem;
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
        }

        .btn-add-member {
            background-color: #4ecdc4;
            color: white;
            padding: 0.8rem;
            border: none;
            border-radius: 5px;
            font-weight: 600;
            cursor: pointer;
            width: 100%;
            margin-bottom: 2rem;
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
        }

        .btn-submit {
            flex: 1;
            background-color: #ff6b6b;
            color: #fff;
            padding: 1rem;
            border: none;
            border-radius: 5px;
            font-weight: 600;
            cursor: pointer;
        }

        .btn-cancel {
            flex: 1;
            background-color: #e0e0e0;
            color: #333;
            padding: 1rem;
            border-radius: 5px;
            font-weight: 600;
            text-decoration: none;
            text-align: center;
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
                    <li><a href="UserTournament.jsp" class="nav-link">Tournaments</a></li>
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
                    <h2><%= tournament.getTournamentName() %></h2>
                </div>

                <h1 class="form-title">Edit Team Registration</h1>

                <form action="UpdateTeamRegistrationServlet" method="POST" id="editForm">
                    <input type="hidden" name="registrationId" value="<%= registrationId %>">

                    <div class="form-group">
                        <label class="form-label">Team Name *</label>
                        <input type="text" name="teamName" class="form-input" 
                               value="<%= registration.getTeamName() %>" required>
                    </div>

                    <div class="member-count">
                        <strong>Team Members: <span id="memberCount"><%= members.size() %></span>/12</strong>
                    </div>

                    <div class="members-container" id="membersContainer">
                        <% for (int i = 0; i < members.size(); i++) { 
                            TeamMember member = members.get(i);
                        %>
                        <div class="member-row">
                            <% if (member.isCaptain()) { %>
                                <div class="captain-label">⭐ CAPTAIN</div>
                            <% } else { %>
                                <div></div>
                            <% } %>
                            <div class="form-group">
                                <label class="form-label">Name</label>
                                <input type="text" name="memberName[]" class="form-input" 
                                       value="<%= member.getMemberName() %>" 
                                       <%= member.isCaptain() ? "readonly" : "" %> required>
                            </div>
                            <div class="form-group">
                                <label class="form-label">Position</label>
                                <select name="memberPosition[]" class="form-select" required>
                                    <option value="outside_spiker" <%= "outside_spiker".equals(member.getPosition()) ? "selected" : "" %>>Outside Spiker</option>
                                    <option value="opposite" <%= "opposite".equals(member.getPosition()) ? "selected" : "" %>>Opposite</option>
                                    <option value="setter" <%= "setter".equals(member.getPosition()) ? "selected" : "" %>>Setter</option>
                                    <option value="middle" <%= "middle".equals(member.getPosition()) ? "selected" : "" %>>Middle Blocker</option>
                                    <option value="libero" <%= "libero".equals(member.getPosition()) ? "selected" : "" %>>Libero</option>
                                </select>
                            </div>
                            <div class="form-group">
                                <label class="form-label">Jersey #</label>
                                <input type="number" name="memberJersey[]" class="form-input" 
                                       value="<%= member.getJerseyNumber() %>" min="1" max="99" required>
                            </div>
                            <% if (!member.isCaptain()) { %>
                                <button type="button" class="btn-remove" onclick="removeMember(this)">×</button>
                            <% } else { %>
                                <div></div>
                            <% } %>
                        </div>
                        <% } %>
                    </div>

                    <button type="button" class="btn-add-member" id="addMemberBtn">+ Add Team Member</button>

                    <div class="form-actions">
                        <button type="submit" class="btn-submit">Update Registration</button>
                        <a href="UserRegisTour.jsp" class="btn-cancel">Cancel</a>
                    </div>
                </form>
            </div>
        </div>
    </section>

    <script>
        let memberCount = <%= members.size() %>;
        const maxMembers = 12;

        document.getElementById('addMemberBtn').addEventListener('click', function() {
            if (memberCount >= maxMembers) {
                alert('Maximum 12 members allowed!');
                return;
            }

            memberCount++;
            document.getElementById('memberCount').textContent = memberCount;

            const memberRow = document.createElement('div');
            memberRow.className = 'member-row';
            memberRow.innerHTML = `
                <div></div>
                <div class="form-group">
                    <label class="form-label">Name</label>
                    <input type="text" name="memberName[]" class="form-input" required>
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
                    <input type="number" name="memberJersey[]" class="form-input" min="1" max="99" required>
                </div>
                <button type="button" class="btn-remove" onclick="removeMember(this)">×</button>
            `;

            document.getElementById('membersContainer').appendChild(memberRow);

            if (memberCount >= maxMembers) {
                document.getElementById('addMemberBtn').disabled = true;
            }
        });

        function removeMember(button) {
            button.closest('.member-row').remove();
            memberCount--;
            document.getElementById('memberCount').textContent = memberCount;
            
            if (memberCount < maxMembers) {
                document.getElementById('addMemberBtn').disabled = false;
            }
        }

        document.getElementById('editForm').addEventListener('submit', function(e) {
            if (memberCount < 6) {
                e.preventDefault();
                alert('Minimum 6 team members required!');
                return false;
            }
        });
    </script>
</body>
</html>