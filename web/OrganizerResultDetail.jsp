<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="Model.*, DAO.*, java.util.*, java.text.SimpleDateFormat" %>
<%
    String username = (String) session.getAttribute("organizerUsername");
    String fullname = (String) session.getAttribute("organizerFullname");
    Integer organizerId = (Integer) session.getAttribute("organizerId");

    if (username == null || organizerId == null) {
        response.sendRedirect("OrganizerLogin.jsp");
        return;
    }

    String tournamentIdStr = request.getParameter("id");
    if (tournamentIdStr == null) {
        response.sendRedirect("OrganizerResult.jsp");
        return;
    }

    int tournamentId = Integer.parseInt(tournamentIdStr);

    TournamentDAO tournamentDAO = new TournamentDAO();
    Tournament tournament = tournamentDAO.getTournamentById(tournamentId);

    if (tournament == null || tournament.getOrganizerId() != organizerId) {
        response.sendRedirect("OrganizerResult.jsp");
        return;
    }

    MatchDAO matchDAO = new MatchDAO();
    TeamRegistrationDAO teamRegDAO = new TeamRegistrationDAO();

    // Get all matches
    List<Match> allMatches = matchDAO.getMatchesByTournament(tournamentId);
    List<Match> bracketMatches = matchDAO.getMatchesByTournamentAndType(tournamentId, "bracket");

    // Calculate rankings
    final Map<Integer, Integer> teamWins = new HashMap<>();
    final Map<Integer, Integer> teamLosses = new HashMap<>();
    final Map<Integer, Integer> setsWon = new HashMap<>();
    final Map<Integer, Integer> setsLost = new HashMap<>();
    final Map<Integer, Integer> pointsScored = new HashMap<>();
    final Map<Integer, Integer> pointsConceded = new HashMap<>();

    // Process all matches for statistics
    for (Match match : allMatches) {
        if (match.getWinnerId() == null) {
            continue;
        }

        int team1Id = match.getTeam1Id();
        int team2Id = match.getTeam2Id();
        int winnerId = match.getWinnerId();
        int loserId = (winnerId == team1Id) ? team2Id : team1Id;

        // Wins and losses
        teamWins.put(winnerId, teamWins.getOrDefault(winnerId, 0) + 1);
        teamLosses.put(loserId, teamLosses.getOrDefault(loserId, 0) + 1);

        // Calculate sets and points
        int team1Sets = 0, team2Sets = 0;
        int team1Points = 0, team2Points = 0;

        for (int i = 1; i <= 5; i++) {
            Integer t1Score = match.getSetScore(1, i);
            Integer t2Score = match.getSetScore(2, i);

            if (t1Score != null && t2Score != null) {
                team1Points += t1Score;
                team2Points += t2Score;

                if (t1Score > t2Score) {
                    team1Sets++;
                } else if (t2Score > t1Score) {
                    team2Sets++;
                }
            }
        }

        setsWon.put(team1Id, setsWon.getOrDefault(team1Id, 0) + team1Sets);
        setsWon.put(team2Id, setsWon.getOrDefault(team2Id, 0) + team2Sets);
        setsLost.put(team1Id, setsLost.getOrDefault(team1Id, 0) + team2Sets);
        setsLost.put(team2Id, setsLost.getOrDefault(team2Id, 0) + team1Sets);

        pointsScored.put(team1Id, pointsScored.getOrDefault(team1Id, 0) + team1Points);
        pointsScored.put(team2Id, pointsScored.getOrDefault(team2Id, 0) + team2Points);
        pointsConceded.put(team1Id, pointsConceded.getOrDefault(team1Id, 0) + team2Points);
        pointsConceded.put(team2Id, pointsConceded.getOrDefault(team2Id, 0) + team1Points);
    }

    // Determine top 3 from bracket
    Integer champion = null, runnerUp = null, third = null;

    Match finalMatch = null;
    Match sf1 = null, sf2 = null;

    for (Match m : bracketMatches) {
        if ("Final".equals(m.getGroupName())) {
            finalMatch = m;
        } else if ("SF1".equals(m.getGroupName())) {
            sf1 = m;
        } else if ("SF2".equals(m.getGroupName())) {
            sf2 = m;
        }
    }

    if (finalMatch != null && finalMatch.getWinnerId() != null) {
        champion = finalMatch.getWinnerId();
        runnerUp = (finalMatch.getWinnerId() == finalMatch.getTeam1Id()) ? finalMatch.getTeam2Id() : finalMatch.getTeam1Id();

        // 3rd place: loser of semifinal with more wins, or first semifinal loser
        if (sf1 != null && sf1.getWinnerId() != null && sf2 != null && sf2.getWinnerId() != null) {
            int sf1Loser = (sf1.getWinnerId() == sf1.getTeam1Id()) ? sf1.getTeam2Id() : sf1.getTeam1Id();
            int sf2Loser = (sf2.getWinnerId() == sf2.getTeam1Id()) ? sf2.getTeam2Id() : sf2.getTeam1Id();

            int sf1LoserWins = teamWins.getOrDefault(sf1Loser, 0);
            int sf2LoserWins = teamWins.getOrDefault(sf2Loser, 0);

            third = (sf1LoserWins >= sf2LoserWins) ? sf1Loser : sf2Loser;
        }
    }

    SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMMM yyyy");
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title><%= tournament.getTournamentName()%> - Results</title>
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

            .results-section {
                padding: 2rem 0;
                background-color: #f8f9fa;
                min-height: 80vh;
            }
            .page-title {
                font-size: 2.5rem;
                color: #1a1a2e;
                text-align: center;
                margin-bottom: 1rem;
                font-weight: 800;
            }
            .tournament-info-header {
                text-align: center;
                color: #666;
                margin-bottom: 3rem;
            }

            /* Podium Section */
            .podium-section {
                margin-bottom: 4rem;
            }

            .section-title {
                font-size: 2rem;
                font-weight: 700;
                text-align: center;
                margin-bottom: 2rem;
                color: #1a1a2e;
            }

            .podium {
                display: grid;
                grid-template-columns: 1fr 1fr 1fr;
                gap: 2rem;
                max-width: 900px;
                margin: 0 auto;
                align-items: end;
            }

            .podium-place {
                background: white;
                border-radius: 20px;
                padding: 2rem;
                text-align: center;
                box-shadow: 0 8px 30px rgba(0,0,0,0.1);
                transition: all 0.3s;
            }

            .podium-place:hover {
                transform: translateY(-8px);
                box-shadow: 0 12px 40px rgba(0,0,0,0.15);
            }

            .podium-place.first {
                order: 2;
                background: linear-gradient(135deg, #ffd700, #ffed4e);
                transform: scale(1.1);
            }

            .podium-place.second {
                order: 1;
                background: linear-gradient(135deg, #c0c0c0, #e8e8e8);
            }

            .podium-place.third {
                order: 3;
                background: linear-gradient(135deg, #cd7f32, #e9a565);
            }

            .medal {
                font-size: 4rem;
                margin-bottom: 1rem;
            }

            .place-label {
                font-size: 1.2rem;
                font-weight: 700;
                margin-bottom: 0.5rem;
                color: #333;
            }

            .team-name-podium {
                font-size: 1.5rem;
                font-weight: 800;
                color: #1a1a2e;
                margin-bottom: 1rem;
            }

            .stats-summary {
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 0.5rem;
                margin-top: 1rem;
                padding-top: 1rem;
                border-top: 2px solid rgba(0,0,0,0.1);
            }

            .stat-item {
                font-size: 0.9rem;
                color: #555;
            }

            .stat-item strong {
                color: #333;
                font-weight: 700;
            }

            /* Standings Table */
            .standings-table {
                background: white;
                border-radius: 20px;
                padding: 2rem;
                box-shadow: 0 8px 30px rgba(0,0,0,0.1);
                margin-bottom: 3rem;
            }

            table {
                width: 100%;
                border-collapse: collapse;
            }

            thead {
                background: linear-gradient(135deg, #667eea, #764ba2);
                color: white;
            }

            th {
                padding: 1rem;
                text-align: left;
                font-weight: 700;
                font-size: 0.95rem;
            }

            th:first-child {
                border-radius: 12px 0 0 0;
            }

            th:last-child {
                border-radius: 0 12px 0 0;
            }

            td {
                padding: 1rem;
                border-bottom: 1px solid #f0f0f0;
            }

            tr:hover {
                background: #f8f9fa;
            }

            .rank {
                font-weight: 700;
                color: #667eea;
                font-size: 1.1rem;
            }

            .team-name {
                font-weight: 600;
                color: #1a1a2e;
            }

            /* Bracket Section */
            .bracket-container {
                background: white;
                border-radius: 20px;
                padding: 2rem;
                box-shadow: 0 8px 30px rgba(0,0,0,0.1);
                overflow-x: auto;
            }

            .bracket {
                display: flex;
                justify-content: center;
                align-items: center;
                min-width: 800px;
                padding: 2rem;
            }

            .round {
                display: flex;
                flex-direction: column;
                justify-content: space-around;
                list-style: none;
                padding: 0;
                margin: 0 40px;
                width: 200px;
            }

            .match-box {
                background: #fff;
                border: 2px solid #e0e0e0;
                border-radius: 12px;
                box-shadow: 0 2px 8px rgba(0,0,0,0.1);
                margin: 20px 0;
                position: relative;
                overflow: hidden;
            }

            .match-box.completed {
                border-color: #28a745;
            }

            .team {
                padding: 12px 16px;
                font-weight: 600;
                font-size: 0.95rem;
                display: flex;
                justify-content: space-between;
                align-items: center;
            }

            .team:first-child {
                border-bottom: 1px solid #f0f0f0;
            }

            .team.winner {
                background: linear-gradient(135deg, #d4edda, #c3e6cb);
                font-weight: 800;
                color: #155724;
            }

            .round-final .match-box {
                border: 3px solid #764ba2;
                transform: scale(1.1);
            }

            .final-header {
                background: linear-gradient(135deg, #667eea, #764ba2);
                color: white;
                justify-content: center;
                font-weight: 800;
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
                        <li><a href="OrganizerTournament.jsp" class="nav-link">Tournaments</a></li>
                        <li><a href="OrganizerSchedule.jsp" class="nav-link">Schedule</a></li>
                        <li><a href="OrganizerResult.jsp" class="nav-link active">Results</a></li>
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

        <section class="results-section">
            <div class="container">
                <h1 class="page-title">🏆 <%= tournament.getTournamentName()%></h1>
                <div class="tournament-info-header">
                    <p>📅 <%= dateFormat.format(tournament.getTournamentDate())%> • 📍 <%= tournament.getLocation()%></p>
                    <p><%= tournament.getCategory().substring(0, 1).toUpperCase() + tournament.getCategory().substring(1)%> • <%= tournament.getTournamentType().substring(0, 1).toUpperCase() + tournament.getTournamentType().substring(1)%></p>
                </div>

                <!-- Podium Section -->
                <% if (champion != null) { %>
                <div class="podium-section">
                    <h2 class="section-title">🥇 Final Rankings</h2>
                    <div class="podium">
                        <%
                            TeamRegistration championTeam = teamRegDAO.getRegistrationById(champion);
                            TeamRegistration runnerUpTeam = (runnerUp != null) ? teamRegDAO.getRegistrationById(runnerUp) : null;
                            TeamRegistration thirdTeam = (third != null) ? teamRegDAO.getRegistrationById(third) : null;
                        %>

                        <div class="podium-place first">
                            <div class="medal">🥇</div>
                            <div class="place-label">CHAMPION</div>
                            <div class="team-name-podium"><%= championTeam.getTeamName()%></div>
                            <div class="stats-summary">
                                <div class="stat-item"><strong><%= teamWins.getOrDefault(champion, 0)%></strong> Wins</div>
                                <div class="stat-item"><strong><%= setsWon.getOrDefault(champion, 0)%></strong> Sets Won</div>
                                <div class="stat-item"><strong><%= pointsScored.getOrDefault(champion, 0)%></strong> Points</div>
                                <div class="stat-item"><strong><%= String.format("%.1f", (double) pointsScored.getOrDefault(champion, 0) / Math.max(1, teamWins.getOrDefault(champion, 0) + teamLosses.getOrDefault(champion, 0)))%></strong> Avg/Match</div>
                            </div>
                        </div>

                        <% if (runnerUpTeam != null) {%>
                        <div class="podium-place second">
                            <div class="medal">🥈</div>
                            <div class="place-label">RUNNER-UP</div>
                            <div class="team-name-podium"><%= runnerUpTeam.getTeamName()%></div>
                            <div class="stats-summary">
                                <div class="stat-item"><strong><%= teamWins.getOrDefault(runnerUp, 0)%></strong> Wins</div>
                                <div class="stat-item"><strong><%= setsWon.getOrDefault(runnerUp, 0)%></strong> Sets Won</div>
                                <div class="stat-item"><strong><%= pointsScored.getOrDefault(runnerUp, 0)%></strong> Points</div>
                                <div class="stat-item"><strong><%= String.format("%.1f", (double) pointsScored.getOrDefault(runnerUp, 0) / Math.max(1, teamWins.getOrDefault(runnerUp, 0) + teamLosses.getOrDefault(runnerUp, 0)))%></strong> Avg/Match</div>
                            </div>
                        </div>
                        <% } %>

                        <% if (thirdTeam != null) {%>
                        <div class="podium-place third">
                            <div class="medal">🥉</div>
                            <div class="place-label">THIRD PLACE</div>
                            <div class="team-name-podium"><%= thirdTeam.getTeamName()%></div>
                            <div class="stats-summary">
                                <div class="stat-item"><strong><%= teamWins.getOrDefault(third, 0)%></strong> Wins</div>
                                <div class="stat-item"><strong><%= setsWon.getOrDefault(third, 0)%></strong> Sets Won</div>
                                <div class="stat-item"><strong><%= pointsScored.getOrDefault(third, 0)%></strong> Points</div>
                                <div class="stat-item"><strong><%= String.format("%.1f", (double) pointsScored.getOrDefault(third, 0) / Math.max(1, teamWins.getOrDefault(third, 0) + teamLosses.getOrDefault(third, 0)))%></strong> Avg/Match</div>
                            </div>
                        </div>
                        <% } %>
                    </div>
                </div>
                <% } %>

                <!-- Full Standings Table -->
                <h2 class="section-title">📊 Complete Statistics</h2>
                <div class="standings-table">
                    <table>
                        <thead>
                            <tr>
                                <th>Rank</th>
                                <th>Team</th>
                                <th>Wins</th>
                                <th>Losses</th>
                                <th>Sets Won</th>
                                <th>Sets Lost</th>
                                <th>Points For</th>
                                <th>Points Against</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                // Create sorted list of teams
                                List<TeamRegistration> allTeams = teamRegDAO.getApprovedTeamsByTournament(tournamentId);
                                Collections.sort(allTeams, new Comparator<TeamRegistration>() {
                                    public int compare(TeamRegistration t1, TeamRegistration t2) {
                                        int wins1 = teamWins.getOrDefault(t1.getRegistrationId(), 0);
                                        int wins2 = teamWins.getOrDefault(t2.getRegistrationId(), 0);
                                        if (wins1 != wins2) {
                                            return wins2 - wins1;
                                        }

                                        int sets1 = setsWon.getOrDefault(t1.getRegistrationId(), 0);
                                        int sets2 = setsWon.getOrDefault(t2.getRegistrationId(), 0);
                                        if (sets1 != sets2) {
                                            return sets2 - sets1;
                                        }

                                        int points1 = pointsScored.getOrDefault(t1.getRegistrationId(), 0);
                                        int points2 = pointsScored.getOrDefault(t2.getRegistrationId(), 0);
                                        return points2 - points1;
                                    }
                                });

                                int rank = 1;
                                for (TeamRegistration team : allTeams) {
                                    int teamId = team.getRegistrationId();
                            %>
                            <tr>
                                <td class="rank">#<%= rank++%></td>
                                <td class="team-name"><%= team.getTeamName()%></td>
                                <td><%= teamWins.getOrDefault(teamId, 0)%></td>
                                <td><%= teamLosses.getOrDefault(teamId, 0)%></td>
                                <td><%= setsWon.getOrDefault(teamId, 0)%></td>
                                <td><%= setsLost.getOrDefault(teamId, 0)%></td>
                                <td><%= pointsScored.getOrDefault(teamId, 0)%></td>
                                <td><%= pointsConceded.getOrDefault(teamId, 0)%></td>
                            </tr>
                            <% }%>
                        </tbody>
                    </table>
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
                            <li><a href="#contact">Contact</a></li>
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