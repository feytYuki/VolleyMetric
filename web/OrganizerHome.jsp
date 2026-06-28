<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    // Check if organizer is logged in
    String username = (String) session.getAttribute("organizerUsername");
    String fullname = (String) session.getAttribute("organizerFullname");

    if (username == null) {
        response.sendRedirect("OrganizerLogin.jsp");
        return;
    }

    // Fetch the 3 newest tournaments
    List<Map<String, String>> tournaments = new ArrayList<>();
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/volleymetric", "root", "");

        // Query to get 3 newest tournaments ordered by created_at
        String sql = "SELECT tournament_id, tournament_name, location, tournament_date, start_time, max_teams, status "
                + "FROM tournaments "
                + "ORDER BY created_at DESC "
                + "LIMIT 3";

        pstmt = conn.prepareStatement(sql);
        rs = pstmt.executeQuery();

        SimpleDateFormat inputFormat = new SimpleDateFormat("yyyy-MM-dd");
        SimpleDateFormat outputFormat = new SimpleDateFormat("MMM dd, yyyy");

        while (rs.next()) {
            Map<String, String> tournament = new HashMap<>();
            tournament.put("id", String.valueOf(rs.getInt("tournament_id")));
            tournament.put("name", rs.getString("tournament_name"));
            tournament.put("location", rs.getString("location"));

            // Format the date
            String dateStr = rs.getString("tournament_date");
            try {
                java.util.Date date = inputFormat.parse(dateStr);
                tournament.put("date", outputFormat.format(date));
            } catch (Exception e) {
                tournament.put("date", dateStr);
            }

            tournament.put("time", rs.getString("start_time"));
            tournament.put("maxTeams", String.valueOf(rs.getInt("max_teams")));
            tournament.put("status", rs.getString("status"));
            tournaments.add(tournament);
        }
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        if (rs != null) try {
            rs.close();
        } catch (SQLException e) {
        }
        if (pstmt != null) try {
            pstmt.close();
        } catch (SQLException e) {
        }
        if (conn != null) try {
            conn.close();
        } catch (SQLException e) {
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Organizer Dashboard - VolleyMetric</title>
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

            .btn-logout:hover {
                background-color: #ee5a52;
                transform: translateY(-2px);
            }
        </style>
    </head>
    <body>
        <!-- Header -->
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
                        <li><a href="OrganizerHome.jsp" class="nav-link active">Home</a></li>
                        <li><a href="OrganizerTournament.jsp" class="nav-link">Tournaments</a></li>
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
        </div>
    </header>
    <!-- Hero Section -->
    <section class="hero">
        <div class="container">
            <div class="hero-content">
                <h1 class="hero-title">Welcome back, <%= fullname != null ? fullname : username%>!</h1>
                <p class="hero-subtitle">Manage your volleyball tournaments and track your team's progress</p>
                <div class="hero-buttons">
                    <a href="CreateTournament.jsp" class="btn btn-large btn-primary">Create Tournament</a>
                    <a href="OrganizerTournament.jsp" class="btn btn-large btn-outline-white">My Tournaments</a>
                </div>
            </div>
        </div>
    </section>

    <!-- Newest Tournaments Section -->
    <section style="padding: 5rem 0; background: linear-gradient(160deg, #0f2027, #1a1a3e, #16213e);">
        <div class="container">

            <div style="text-align:center; margin-bottom: 3.5rem;">
                <span style="display:inline-block; background: rgba(64,224,176,0.15); color: #40e0b0; font-size: 0.78rem; font-weight: 700; letter-spacing: 0.12em; text-transform: uppercase; padding: 6px 18px; border-radius: 50px; border: 1px solid rgba(64,224,176,0.3); margin-bottom: 1rem;">Live &amp; Upcoming</span>
                <h2 style="font-size: 2.6rem; font-weight: 800; color: #fff; margin: 0 0 1rem;">Newest Tournaments</h2>
                <p style="color: rgba(255,255,255,0.55); font-size: 1.05rem; max-width: 520px; margin: 0 auto; line-height: 1.7;">Stay up to date with the latest volleyball competitions happening near you.</p>
            </div>

            <% if (tournaments.isEmpty()) { %>
            <div style="background: rgba(255,255,255,0.04); border: 1px solid rgba(255,255,255,0.08); border-radius: 20px; padding: 3.5rem 2rem; text-align:center; max-width: 480px; margin: 0 auto;">
                <div style="font-size: 3rem; margin-bottom: 1rem;">🏐</div>
                <p style="color: rgba(255,255,255,0.55); font-size: 1rem; margin: 0;">No tournaments available at the moment. Start by creating your first tournament!</p>
            </div>
            <% } else { %>

            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1.5rem;">
                <%
                    for (Map<String, String> tournament : tournaments) {
                        String status = tournament.get("status");

                        String badgeText, badgeColor, badgeBg, glowColor, iconBg, iconGrad;
                        if ("upcoming".equalsIgnoreCase(status)) {
                            badgeText  = "Registration Open";
                            badgeColor = "#40e0b0";
                            badgeBg    = "rgba(64,224,176,0.15)";
                            glowColor  = "rgba(64,224,176,0.2)";
                            iconGrad   = "linear-gradient(135deg,#11998e,#38ef7d)";
                            iconBg     = "rgba(17,153,142,0.4)";
                        } else if ("ongoing".equalsIgnoreCase(status)) {
                            badgeText  = "Ongoing";
                            badgeColor = "#f5a623";
                            badgeBg    = "rgba(245,166,35,0.15)";
                            glowColor  = "rgba(245,166,35,0.2)";
                            iconGrad   = "linear-gradient(135deg,#f093fb,#f5a623)";
                            iconBg     = "rgba(245,166,35,0.4)";
                        } else if ("completed".equalsIgnoreCase(status)) {
                            badgeText  = "Completed";
                            badgeColor = "#a78bfa";
                            badgeBg    = "rgba(167,139,250,0.15)";
                            glowColor  = "rgba(102,126,234,0.2)";
                            iconGrad   = "linear-gradient(135deg,#667eea,#764ba2)";
                            iconBg     = "rgba(102,126,234,0.4)";
                        } else if ("cancelled".equalsIgnoreCase(status)) {
                            badgeText  = "Cancelled";
                            badgeColor = "#fc5c7d";
                            badgeBg    = "rgba(252,92,125,0.15)";
                            glowColor  = "rgba(252,92,125,0.2)";
                            iconGrad   = "linear-gradient(135deg,#fc5c7d,#6a3093)";
                            iconBg     = "rgba(252,92,125,0.4)";
                        } else {
                            badgeText  = status;
                            badgeColor = "#fff";
                            badgeBg    = "rgba(255,255,255,0.1)";
                            glowColor  = "rgba(255,255,255,0.1)";
                            iconGrad   = "linear-gradient(135deg,#555,#888)";
                            iconBg     = "rgba(100,100,100,0.4)";
                        }
                %>
                <div style="background: rgba(255,255,255,0.04); border: 1px solid rgba(255,255,255,0.08); border-radius: 20px; padding: 2rem 1.75rem; transition: transform 0.3s, box-shadow 0.3s; position: relative; overflow: hidden; display: flex; flex-direction: column; gap: 0;"
                     onmouseover="this.style.transform='translateY(-6px)'; this.style.boxShadow='0 20px 40px rgba(0,0,0,0.4)'"
                     onmouseout="this.style.transform='translateY(0)'; this.style.boxShadow='none'">

                    <!-- Glow orb -->
                    <div style="position:absolute; top:-30px; right:-30px; width:130px; height:130px; background: radial-gradient(circle, <%= glowColor %>, transparent 70%); border-radius:50%; pointer-events:none;"></div>

                    <!-- Icon + status badge row -->
                    <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom: 1.4rem;">
                        <div style="width:52px; height:52px; background: <%= iconGrad %>; border-radius:14px; display:flex; align-items:center; justify-content:center; font-size:1.5rem; box-shadow: 0 8px 20px <%= iconBg %>; flex-shrink:0;">🏐</div>
                        <span style="display:inline-block; background: <%= badgeBg %>; color: <%= badgeColor %>; font-size:0.73rem; font-weight:700; letter-spacing:0.07em; text-transform:uppercase; padding: 4px 12px; border-radius:50px; border: 1px solid <%= badgeColor %>33;"><%= badgeText %></span>
                    </div>

                    <!-- Name -->
                    <h3 style="font-size:1.15rem; font-weight:700; color:#fff; margin:0 0 1rem; line-height:1.4;"><%= tournament.get("name") %></h3>

                    <!-- Info rows -->
                    <div style="display:flex; flex-direction:column; gap:0.55rem; margin-bottom:1.5rem; flex:1;">
                        <div style="display:flex; align-items:center; gap:10px; color:rgba(255,255,255,0.55); font-size:0.88rem;">
                            <span style="font-size:1rem;">📍</span> <%= tournament.get("location") %>
                        </div>
                        <div style="display:flex; align-items:center; gap:10px; color:rgba(255,255,255,0.55); font-size:0.88rem;">
                            <span style="font-size:1rem;">📅</span> <%= tournament.get("date") %>
                        </div>
                        <div style="display:flex; align-items:center; gap:10px; color:rgba(255,255,255,0.55); font-size:0.88rem;">
                            <span style="font-size:1rem;">👥</span> <%= tournament.get("maxTeams") %> Teams Max
                        </div>
                    </div>

                    <!-- CTA row -->
                    <div style="display:flex; align-items:center; justify-content:space-between; border-top: 1px solid rgba(255,255,255,0.08); padding-top:1.2rem; margin-top:auto;">
                        <a href="OrganizerViewDetail.jsp?id=<%= tournament.get("id") %>" style="display:inline-flex; align-items:center; gap:6px; background: <%= iconGrad %>; color:#fff; font-size:0.85rem; font-weight:600; padding: 9px 20px; border-radius:10px; text-decoration:none; transition: opacity 0.2s; box-shadow: 0 4px 14px <%= iconBg %>;"
                           onmouseover="this.style.opacity='0.85'" onmouseout="this.style.opacity='1'">View Details <span style="font-size:0.85rem;">→</span></a>
                        <div style="display:flex; align-items:center; gap:6px; color:<%= badgeColor %>; font-size:0.8rem; font-weight:600;">
                            <span style="width:20px; height:2px; background:<%= badgeColor %>; border-radius:2px; display:inline-block;"></span>
                            <%= "upcoming".equalsIgnoreCase(status) ? "Join Now" : "ongoing".equalsIgnoreCase(status) ? "Live" : "Finished" %>
                        </div>
                    </div>
                </div>
                <% } %>
            </div>

            <!-- View all link -->
            <div style="text-align:center; margin-top:2.5rem;">
                <a href="OrganizerTournament.jsp" style="display:inline-flex; align-items:center; gap:8px; color:rgba(255,255,255,0.6); font-size:0.92rem; font-weight:600; text-decoration:none; border: 1px solid rgba(255,255,255,0.15); padding: 10px 28px; border-radius:50px; transition: all 0.2s;"
                   onmouseover="this.style.color='#fff'; this.style.borderColor='rgba(255,255,255,0.4)'"
                   onmouseout="this.style.color='rgba(255,255,255,0.6)'; this.style.borderColor='rgba(255,255,255,0.15)'">
                    View All Tournaments <span>→</span>
                </a>
            </div>
            <% } %>

        </div>
    </section>

    <!-- Footer -->
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