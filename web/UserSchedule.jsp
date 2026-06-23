<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    String username = (String) session.getAttribute("username");
    String fullname = (String) session.getAttribute("fullname");
    Integer userId = (Integer) session.getAttribute("userId");
    
    if (username == null || userId == null) {
        response.sendRedirect("Login.jsp");
        return;
    }
    
    List<Map<String, String>> ongoingTournaments = new ArrayList<>();
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/volleymetric", "root", "");
        String sql = "SELECT tournament_id, tournament_name, location, tournament_date, start_time, max_teams, current_teams FROM tournaments WHERE status = 'ongoing' ORDER BY tournament_date ASC";
        pstmt = conn.prepareStatement(sql);
        rs = pstmt.executeQuery();
        
        SimpleDateFormat inputFormat = new SimpleDateFormat("yyyy-MM-dd");
        SimpleDateFormat outputFormat = new SimpleDateFormat("MMM dd, yyyy");
        
        while (rs.next()) {
            Map<String, String> tournament = new HashMap<>();
            tournament.put("id", String.valueOf(rs.getInt("tournament_id")));
            tournament.put("name", rs.getString("tournament_name"));
            tournament.put("location", rs.getString("location"));
            String dateStr = rs.getString("tournament_date");
            try {
                java.util.Date date = inputFormat.parse(dateStr);
                tournament.put("date", outputFormat.format(date));
            } catch (Exception e) {
                tournament.put("date", dateStr);
            }
            tournament.put("time", rs.getString("start_time"));
            tournament.put("maxTeams", String.valueOf(rs.getInt("max_teams")));
            tournament.put("currentTeams", String.valueOf(rs.getInt("current_teams")));
            ongoingTournaments.add(tournament);
        }
    } catch (Exception e) { e.printStackTrace(); } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) {}
        if (pstmt != null) try { pstmt.close(); } catch (SQLException e) {}
        if (conn != null) try { conn.close(); } catch (SQLException e) {}
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tournament Schedule - VolleyMetric</title>
    <link rel="stylesheet" href="style.css">
    <style>
        /* Synchronized Theme Styles */
        .user-info { display: flex; align-items: center; gap: 1rem; }
        .user-details { display: flex; flex-direction: column; align-items: flex-end; background: white; border: 2px solid red; border-radius: 5px; padding: 4px 10px; }
        .user-role-label { font-size: 0.8rem; font-weight: 600; color: #ff6b6b; margin: 0; }
        .user-name { font-size: 0.95rem; font-weight: 600; color: #000; margin: 0; }
        .btn-logout { background-color: #ff6b6b; color: #fff; padding: 0.6rem 1.5rem; text-decoration: none; border-radius: 5px; font-weight: 600; transition: all 0.3s; }
        .btn-logout:hover { background-color: #ee5a52; transform: translateY(-2px); }

        .page-section { padding: 4rem 0; background-color: #f8f9fa; min-height: 80vh; }
        .page-header { text-align: center; margin-bottom: 3rem; }
        .page-title { font-size: 2.5rem; color: #1a1a2e; margin-bottom: 0.5rem; font-weight: 800; }
        .page-subtitle { font-size: 1.2rem; color: #666; }
        
        .tournaments-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(350px, 1fr)); gap: 2rem; }
        .tournament-card { background: white; border-radius: 20px; overflow: hidden; box-shadow: 0 8px 30px rgba(0,0,0,0.1); transition: all 0.3s; position: relative; }
        .tournament-card:hover { transform: translateY(-8px); box-shadow: 0 12px 40px rgba(0,0,0,0.15); }
        
        /* --- HEADER STYLES (Matching UserTournament) --- */
        .tournament-header {
            background: linear-gradient(135deg, #667eea, #764ba2);
            padding: 2rem;
            text-align: center;
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

        .status-badge { 
            display: inline-block; 
            background: linear-gradient(135deg, #4ecdc4, #45b7af); /* Teal for Live/Active */
            color: white; 
            padding: 0.4rem 1rem; 
            border-radius: 50px; 
            font-size: 0.75rem; 
            font-weight: 700; 
            text-transform: uppercase; 
            margin-bottom: 1rem; 
        }
        
        /* --- BODY STYLES --- */
        .tournament-body { padding: 2rem; }
        
        .info-item { display: flex; align-items: center; gap: 0.8rem; color: #555; padding: 0.5rem; background: #f8f9fa; border-radius: 8px; margin-bottom: 0.5rem; }
        
        .btn-action { background: linear-gradient(135deg, #ff6b6b, #ee5a52); color: white; padding: 1rem; border: none; border-radius: 50px; font-weight: 700; cursor: pointer; width: 100%; transition: all 0.3s; text-decoration: none; display: block; text-align: center; box-shadow: 0 4px 15px rgba(255, 107, 107, 0.3); margin-top: 1rem; }
        .btn-action:hover { transform: translateY(-3px); box-shadow: 0 6px 20px rgba(255, 107, 107, 0.4); }
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
                    <li><a href="UserSchedule.jsp" class="nav-link active">Schedule</a></li>
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
                <h1 class="page-title">🏐 Live Tournament Schedule</h1>
                <p class="page-subtitle">View ongoing tournaments, groups, and match results</p>
            </div>

            <% if (ongoingTournaments.isEmpty()) { %>
                <div style="text-align: center; padding: 4rem; background: white; border-radius: 20px;">
                    <h3 style="font-size: 2rem; color: #1a1a2e;">No Ongoing Tournaments</h3>
                    <p>There are no live tournaments at the moment.</p>
                </div>
            <% } else { %>
                <div class="tournaments-grid">
                    <% for (Map<String, String> tournament : ongoingTournaments) { %>
                    <div class="tournament-card">
                        <div class="tournament-header">
                            <div class="status-badge">⚡ Live Now</div>
                            <h3 class="tournament-name"><%= tournament.get("name") %></h3>
                        </div>
                        
                        <div class="tournament-body">
                            <div class="tournament-info">
                                <div class="info-item"><span>📍 <strong>Location:</strong> <%= tournament.get("location") %></span></div>
                                <div class="info-item"><span>📅 <strong>Date:</strong> <%= tournament.get("date") %></span></div>
                                <div class="info-item"><span>⏰ <strong>Time:</strong> <%= tournament.get("time") %></span></div>
                                <div class="info-item"><span>👥 <strong>Teams:</strong> <%= tournament.get("currentTeams") %>/<%= tournament.get("maxTeams") %></span></div>
                            </div>
                            <a href="UserScheduleDetail.jsp?id=<%= tournament.get("id") %>" class="btn-action">📊 View Schedule & Results</a>
                        </div>
                    </div>
                    <% } %>
                </div>
            <% } %>
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
            </div>
        </div>
    </footer>
</body>
</html>