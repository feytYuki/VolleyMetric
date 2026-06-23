<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    // Check if user is logged in
    String username = (String) session.getAttribute("username");
    String fullname = (String) session.getAttribute("fullname");

    if (username == null) {
        response.sendRedirect("Login.jsp");
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
        <title>Dashboard - VolleyMetric</title>
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
                transition: all 0.3s;
                font-weight: 600;
                border: none;
                cursor: pointer;
            }

            .btn-logout:hover {
                background-color: #ee5a52;
                transform: translateY(-2px);
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
                        <li><a href="UserHome.jsp" class="nav-link active">Home</a></li>
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

        <section class="hero">
            <div class="container">
                <div class="hero-content">
                    <h1 class="hero-title">Welcome back, <%= fullname != null ? fullname : username%>!</h1>
                    <p class="hero-subtitle">Manage your volleyball tournaments and track your team's progress</p>
                    <div class="hero-buttons">
                        <a href="UserRegisTour.jsp" class="btn btn-large btn-outline-white">My Tournaments</a>
                    </div>
                </div>
            </div>
        </section>

        <!-- Slideshow Section -->
        <section class="slideshow-section">
            <div class="slideshow-wrapper">
                <div class="slideshow-track" id="slideshowTrack">
                    <!-- Slide 1 -->
                    <div class="slide">
                        <img src="slide1.png" alt="Championship Moments" class="slide-img slide-img-cover">
                        <div class="slide-caption">
                            <span class="slide-tag">Season 2025</span>
                            <h2 class="slide-title">Championship Moments Await</h2>
                        </div>
                    </div>
                    <!-- Slide 2 -->
                    <div class="slide">
                        <img src="slide2.png" alt="Kejohanan Bola Tampar MSSM 2026" class="slide-img slide-img-contain">
                        <div class="slide-caption">
                            <span class="slide-tag">Teams</span>
                            <h2 class="slide-title">Compete at the Highest Level</h2>
                        </div>
                    </div>
                    <!-- Slide 3 -->
                    <div class="slide">
                        <img src="slide3.png" alt="Karnival Sukan MASUM" class="slide-img slide-img-contain">
                        <div class="slide-caption">
                            <span class="slide-tag">Community</span>
                            <h2 class="slide-title">Join the VolleyMetric Community</h2>
                        </div>
                    </div>
                </div>

                <!-- Prev / Next arrows -->
                <button class="slide-arrow slide-prev" onclick="moveSlide(-1)" aria-label="Previous slide">&#8249;</button>
                <button class="slide-arrow slide-next" onclick="moveSlide(1)"  aria-label="Next slide">&#8250;</button>

                <!-- Dot indicators -->
                <div class="slide-dots">
                    <button class="slide-dot active" onclick="goToSlide(0)" aria-label="Slide 1"></button>
                    <button class="slide-dot"        onclick="goToSlide(1)" aria-label="Slide 2"></button>
                    <button class="slide-dot"        onclick="goToSlide(2)" aria-label="Slide 3"></button>
                </div>
            </div>
        </section>

        <style>
            .slideshow-section {
                width: 100%;
                background: #000;
                overflow: hidden;
            }
            .slideshow-wrapper {
                position: relative;
                width: 100%;
                overflow: hidden;
            }
            .slideshow-track {
                display: flex;
                transition: transform 0.5s ease-in-out;
            }
            .slide {
                min-width: 100%;
                position: relative;
                background: #000;
            }
            .slide-img {
                width: 100%;
                height: 500px;
                display: block;
            }
            .slide-img-cover {
                object-fit: contain;
                object-position: center center;
                background: #0d1b2a;
            }
            .slide-img-contain {
                object-fit: contain;
                object-position: center center;
                background: #0a0a1a;
            }
            .slide-caption {
                position: absolute;
                bottom: 0;
                left: 0;
                right: 0;
                padding: 2.5rem 4rem;
                background: linear-gradient(to top, rgba(0,0,0,0.75) 0%, transparent 100%);
                color: #fff;
            }
            .slide:has(.slide-img-contain) .slide-caption {
                background: none;
            }
            .slide-tag {
                display: inline-block;
                background: #40e0b0;
                color: #1a1a2e;
                font-size: 0.78rem;
                font-weight: 700;
                text-transform: uppercase;
                letter-spacing: 0.08em;
                padding: 4px 12px;
                border-radius: 4px;
                margin-bottom: 0.6rem;
            }
            .slide-title {
                font-size: 2rem;
                font-weight: 700;
                color: #fff;
                margin: 0;
                text-shadow: 0 2px 8px rgba(0,0,0,0.6);
            }
            .slide-arrow {
                position: absolute;
                top: 50%;
                transform: translateY(-50%);
                background: rgba(255,255,255,0.15);
                border: none;
                color: #fff;
                font-size: 2.5rem;
                line-height: 1;
                width: 48px;
                height: 48px;
                border-radius: 50%;
                cursor: pointer;
                display: flex;
                align-items: center;
                justify-content: center;
                transition: background 0.2s;
                z-index: 10;
            }
            .slide-arrow:hover { background: rgba(255,255,255,0.35); }
            .slide-prev { left: 1.5rem; }
            .slide-next { right: 1.5rem; }
            .slide-dots {
                position: absolute;
                bottom: 1.2rem;
                right: 2rem;
                display: flex;
                gap: 8px;
                z-index: 10;
            }
            .slide-dot {
                width: 10px;
                height: 10px;
                border-radius: 50%;
                background: rgba(255,255,255,0.45);
                border: none;
                cursor: pointer;
                padding: 0;
                transition: background 0.2s, transform 0.2s;
            }
            .slide-dot.active {
                background: #40e0b0;
                transform: scale(1.25);
            }
        </style>

        <script>
            var currentSlide = 0;
            var totalSlides  = 3;
            var autoTimer    = setInterval(function(){ moveSlide(1); }, 5000);

            function moveSlide(dir) {
                currentSlide = (currentSlide + dir + totalSlides) % totalSlides;
                applySlide();
            }
            function goToSlide(n) {
                currentSlide = n;
                applySlide();
                clearInterval(autoTimer);
                autoTimer = setInterval(function(){ moveSlide(1); }, 5000);
            }
            function applySlide() {
                document.getElementById('slideshowTrack').style.transform =
                    'translateX(-' + (currentSlide * 100) + '%)';
                document.querySelectorAll('.slide-dot').forEach(function(d, i){
                    d.classList.toggle('active', i === currentSlide);
                });
            }
        </script>

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
                    <p style="color: rgba(255,255,255,0.55); font-size: 1rem; margin: 0;">No tournaments available at the moment. Check back soon!</p>
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
                            <a href="ViewTeamDetail.jsp?id=<%= tournament.get("id") %>" style="display:inline-flex; align-items:center; gap:6px; background: <%= iconGrad %>; color:#fff; font-size:0.85rem; font-weight:600; padding: 9px 20px; border-radius:10px; text-decoration:none; transition: opacity 0.2s; box-shadow: 0 4px 14px <%= iconBg %>;"
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
                    <a href="UserTournament.jsp" style="display:inline-flex; align-items:center; gap:8px; color:rgba(255,255,255,0.6); font-size:0.92rem; font-weight:600; text-decoration:none; border: 1px solid rgba(255,255,255,0.15); padding: 10px 28px; border-radius:50px; transition: all 0.2s;"
                       onmouseover="this.style.color='#fff'; this.style.borderColor='rgba(255,255,255,0.4)'"
                       onmouseout="this.style.color='rgba(255,255,255,0.6)'; this.style.borderColor='rgba(255,255,255,0.15)'">
                        View All Tournaments <span>→</span>
                    </a>
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
                    <div class="footer-bottom-links">
                        <a href="#privacy">Privacy Policy</a>
                        <a href="#terms">Terms of Service</a>
                    </div>
                </div>
            </div>
        </footer>
    </body>
</html>