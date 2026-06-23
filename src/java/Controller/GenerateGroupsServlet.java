package Controller;

import Model.TournamentGroup;
import Model.Match;
import Model.TeamRegistration;
import DAO.TournamentGroupDAO;
import DAO.MatchDAO;
import DAO.TeamRegistrationDAO;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.util.*;

public class GenerateGroupsServlet extends HttpServlet {

    private TournamentGroupDAO groupDAO;
    private MatchDAO matchDAO;
    private TeamRegistrationDAO teamRegDAO;

    @Override
    public void init() throws ServletException {
        super.init();
        groupDAO = new TournamentGroupDAO();
        matchDAO  = new MatchDAO();
        teamRegDAO = new TeamRegistrationDAO();
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("organizerId") == null) {
            response.sendRedirect("OrganizerLogin.jsp");
            return;
        }

        try {
            String tournamentIdStr = request.getParameter("tournamentId");
            if (tournamentIdStr == null) {
                session.setAttribute("errorMessage", "Invalid tournament ID!");
                response.sendRedirect("OrganizerSchedule.jsp");
                return;
            }

            int tournamentId = Integer.parseInt(tournamentIdStr);

            // ── Get approved teams ────────────────────────────────────────
            List<TeamRegistration> approvedTeams = teamRegDAO.getApprovedTeamsByTournament(tournamentId);

            if (approvedTeams == null || approvedTeams.isEmpty()) {
                session.setAttribute("errorMessage", "No approved teams found for this tournament!");
                response.sendRedirect("TournamentScheduleDetail.jsp?id=" + tournamentId);
                return;
            }

            int n = approvedTeams.size();

            if (n < 4) {
                session.setAttribute("errorMessage",
                    "Need at least 4 approved teams to generate groups. " +
                    "For 2–3 teams, use the direct bracket instead.");
                response.sendRedirect("TournamentScheduleDetail.jsp?id=" + tournamentId);
                return;
            }

            if (groupDAO.groupsExistForTournament(tournamentId)) {
                session.setAttribute("errorMessage", "Groups already exist for this tournament!");
                response.sendRedirect("TournamentScheduleDetail.jsp?id=" + tournamentId);
                return;
            }

            // ── Decide number of groups ───────────────────────────────────
            // Rules:
            //   4–5  teams → 1 group
            //   6–11 teams → 2 groups  (each group ≥ 3 teams)
            //  12–16 teams → 4 groups  (each group ≥ 3 teams)
            int numGroups;
            if (n <= 5) {
                numGroups = 1;
            } else if (n <= 11) {
                numGroups = 2;
            } else {
                numGroups = 4;
            }

            System.out.println("Teams: " + n + "  →  Groups: " + numGroups);

            // ── Distribute teams evenly ───────────────────────────────────
            // base = floor(n / numGroups), remainder r teams get one extra member
            String[] allGroupNames = {"A", "B", "C", "D"};
            String[] groupNames = Arrays.copyOf(allGroupNames, numGroups);

            int base      = n / numGroups;
            int remainder = n % numGroups;

            // groupSizes[i] = base + (i < remainder ? 1 : 0)
            int[] groupSizes = new int[numGroups];
            for (int i = 0; i < numGroups; i++) {
                groupSizes[i] = base + (i < remainder ? 1 : 0);
            }

            // Shuffle for random seeding
            Collections.shuffle(approvedTeams);

            // ── Build group map and persist to DB ─────────────────────────
            Map<String, List<TeamRegistration>> groups = new LinkedHashMap<>();
            for (String gName : groupNames) {
                groups.put(gName, new ArrayList<>());
            }

            boolean allGroupsCreated = true;
            int teamIndex = 0;
            for (int gi = 0; gi < numGroups; gi++) {
                String gName = groupNames[gi];
                for (int ti = 0; ti < groupSizes[gi]; ti++) {
                    TeamRegistration team = approvedTeams.get(teamIndex++);
                    groups.get(gName).add(team);
                    TournamentGroup tg = new TournamentGroup(tournamentId, gName, team.getRegistrationId());
                    if (!groupDAO.createGroup(tg)) {
                        allGroupsCreated = false;
                        System.err.println("Failed to create group entry for team: " + team.getTeamName());
                    }
                }
            }

            if (!allGroupsCreated) {
                session.setAttribute("errorMessage", "Some groups failed to create. Please try again.");
                response.sendRedirect("TournamentScheduleDetail.jsp?id=" + tournamentId);
                return;
            }

            // ── Generate round-robin matches per group ────────────────────
            boolean allMatchesCreated = true;
            int matchCount = 0;

            for (String gName : groupNames) {
                List<TeamRegistration> gt = groups.get(gName);
                for (int i = 0; i < gt.size(); i++) {
                    for (int j = i + 1; j < gt.size(); j++) {
                        Match match = new Match(tournamentId, gName,
                                gt.get(i).getRegistrationId(),
                                gt.get(j).getRegistrationId());
                        if (matchDAO.createMatch(match)) {
                            matchCount++;
                        } else {
                            allMatchesCreated = false;
                        }
                    }
                }
            }

            if (!allMatchesCreated) {
                session.setAttribute("warningMessage", "Groups created but some matches failed to generate.");
                response.sendRedirect("TournamentScheduleDetail.jsp?id=" + tournamentId);
                return;
            }

            // Print group summary
            for (String gName : groupNames) {
                System.out.println("Group " + gName + ": " + groups.get(gName).size() + " teams");
            }
            System.out.println("Total matches generated: " + matchCount);

            session.setAttribute("successMessage",
                "Groups generated: " + numGroups + " group(s), " + matchCount + " match(es) total.");
            response.sendRedirect("TournamentScheduleDetail.jsp?id=" + tournamentId);

        } catch (NumberFormatException e) {
            e.printStackTrace();
            session.setAttribute("errorMessage", "Invalid tournament ID format!");
            response.sendRedirect("OrganizerSchedule.jsp");
        } catch (Exception e) {
            e.printStackTrace();
            session.setAttribute("errorMessage", "An error occurred while generating groups. Please try again.");
            response.sendRedirect("OrganizerSchedule.jsp");
        }
    }
}