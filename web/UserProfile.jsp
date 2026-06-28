<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%
    String username = (String) session.getAttribute("username");
    String fullname = (String) session.getAttribute("fullname");

    if (username == null) {
        response.sendRedirect("Login.jsp");
        return;
    }

    String email = "", phone = "";
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/volleymetric", "root", "");
        pstmt = conn.prepareStatement("SELECT fullname, username, email, phone FROM users WHERE username = ?");
        pstmt.setString(1, username);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            fullname = rs.getString("fullname");
            email = rs.getString("email");
            phone = rs.getString("phone");
        }
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        if (rs != null)    try {
            rs.close();
        } catch (SQLException e) {
        }
        if (pstmt != null) try {
            pstmt.close();
        } catch (SQLException e) {
        }
        if (conn != null)  try {
            conn.close();
        } catch (SQLException e) {
        }
    }

    String successMessage = (String) session.getAttribute("profileSuccess");
    if (successMessage != null)
        session.removeAttribute("profileSuccess");
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>My Profile - VolleyMetric</title>
        <link rel="stylesheet" href="style.css">
        <style>
            .profile-section {
                flex: 1;
                display: flex;
                align-items: center;
                justify-content: center;
                padding: 3rem 20px;
                min-height: calc(100vh - 140px);
                background-color: #f5f5f5;
            }
            .profile-card {
                background: #fff;
                border-radius: 12px;
                padding: 3rem;
                width: 100%;
                max-width: 520px;
                box-shadow: 0 10px 40px rgba(0,0,0,0.1);
            }
            .profile-avatar {
                text-align: center;
                margin-bottom: 2rem;
            }
            .avatar-circle {
                width: 80px;
                height: 80px;
                background: linear-gradient(135deg, #1a1a2e, #667eea);
                border-radius: 50%;
                display: inline-flex;
                align-items: center;
                justify-content: center;
                font-size: 2.2rem;
                margin-bottom: 0.75rem;
            }
            .profile-name {
                font-size: 1.4rem;
                font-weight: 700;
                color: #1a1a2e;
            }
            .profile-role {
                font-size: 0.85rem;
                color: #ff6b6b;
                font-weight: 600;
            }
            .info-group {
                margin-bottom: 1.25rem;
            }
            .info-label {
                font-weight: 600;
                font-size: 0.85rem;
                color: #888;
                text-transform: uppercase;
                letter-spacing: 0.05em;
                margin-bottom: 0.3rem;
            }
            .info-value {
                font-size: 1rem;
                color: #1a1a2e;
                padding: 0.75rem 1rem;
                background: #f9f9f9;
                border: 2px solid #e0e0e0;
                border-radius: 6px;
            }
            .btn-row {
                display: flex;
                gap: 1rem;
                margin-top: 1.75rem;
            }
            .btn {
                padding: 0.8rem 1.5rem;
                border-radius: 6px;
                font-size: 1rem;
                font-weight: 600;
                cursor: pointer;
                border: none;
                text-decoration: none;
                transition: all 0.2s;
                text-align: center;
            }
            .btn-primary {
                background: #ff6b6b;
                color: #fff;
                flex: 1;
            }
            .btn-primary:hover {
                background: #ee5a52;
                transform: translateY(-1px);
                box-shadow: 0 4px 12px rgba(255,107,107,0.3);
            }
            .btn-ghost {
                background: transparent;
                color: #555;
                border: 2px solid #ddd;
            }
            .btn-ghost:hover {
                border-color: #999;
                color: #333;
            }
            .alert-success {
                padding: 0.9rem 1rem;
                border-radius: 6px;
                margin-bottom: 1.25rem;
                font-size: 0.95rem;
                background: #efe;
                border: 1px solid #cfc;
                color: #2a2;
            }
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
                border: none;
                cursor: pointer;
            }
            .btn-logout:hover {
                background-color: #ee5a52;
            }
        </style>
    </head>
    <body style="min-height:100vh; display:flex; flex-direction:column; background:#f5f5f5;">

        <header class="header">
            <div class="container">
                <div class="logo">
                    <div style="width:40px;height:40px;overflow:hidden;background:white;border:2px solid red;">
                        <img src="umtlogo.png" alt="UMT Logo"
                             style="width:100%;height:100%;object-fit:contain;"
                             onerror="this.style.display='none'">
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
                        <a href="UserProfile.jsp" style="text-decoration:none;">
                            <div class="user-details" style="cursor:pointer;">
                                <span class="user-role-label">User:</span>
                                <span class="user-name">👤 <%= fullname != null ? fullname : username%></span>
                            </div>
                        </a>
                        <a href="LogOutServlet" class="btn-logout">Logout</a>
                    </div>
                </div>
            </div>
        </header>

        <section class="profile-section">
            <div class="profile-card">

                <div class="profile-avatar">
                    <div class="avatar-circle">👤</div>
                    <div class="profile-name"><%= fullname%></div>
                    <div class="profile-role">Registered User</div>
                </div>

                <% if (successMessage != null) {%>
                <div class="alert-success"><%= successMessage%></div>
                <% }%>

                <div class="info-group">
                    <div class="info-label">Full Name</div>
                    <div class="info-value"><%= fullname%></div>
                </div>
                <div class="info-group">
                    <div class="info-label">Username</div>
                    <div class="info-value"><%= username%></div>
                </div>
                <div class="info-group">
                    <div class="info-label">Email Address</div>
                    <div class="info-value"><%= email%></div>
                </div>
                <div class="info-group">
                    <div class="info-label">Phone Number</div>
                    <div class="info-value"><%= phone != null && !phone.isEmpty() ? phone : "—"%></div>
                </div>

                <div class="btn-row">
                    <a href="UserHome.jsp" class="btn btn-ghost">← Back</a>
                    <a href="UserEditProfile.jsp" class="btn btn-primary">✏️ Edit Profile</a>
                </div>

            </div>
        </section>

        <footer class="footer">
            <div class="container">
                <div class="footer-bottom" style="display:flex;justify-content:space-between;flex-wrap:wrap;gap:1rem;">
                    <p>&copy; <%= new java.util.Date().getYear() + 1900%> VolleyMetric. All rights reserved.</p>
                    <div>
                        <a href="#privacy" style="color:#aaa;margin-right:1.5rem;">Privacy Policy</a>
                        <a href="#terms" style="color:#aaa;">Terms of Service</a>
                    </div>
                </div>
            </div>
        </footer>

    </body>
</html>