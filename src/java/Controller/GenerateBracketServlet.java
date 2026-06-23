package Controller;

import DAO.TournamentGroupDAO;
import DAO.MatchDAO;
import DAO.TeamRegistrationDAO;
import Model.Match;
import Model.TeamRegistration;
import javax.servlet.ServletException;
import javax.servlet.http.*;
import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.ArrayList;

public class GenerateBracketServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        System.out.println("=== GenerateBracketServlet CALLED ===");

        String idParam = request.getParameter("id");
        if (idParam == null) {
            response.sendRedirect("OrganizerTournament.jsp");
            return;
        }

        int tournamentId = Integer.parseInt(idParam);

        MatchDAO            matchDAO   = new MatchDAO();
        TournamentGroupDAO  groupDAO   = new TournamentGroupDAO();
        TeamRegistrationDAO teamRegDAO = new TeamRegistrationDAO();

        // Clean up duplicate RR matches from any prior broken attempts
        matchDAO.cleanDuplicateRRMatches(tournamentId);

        // Check existing state AFTER cleanup
        List<Match> existingBracket = matchDAO.getMatchesByTournamentAndType(tournamentId, "bracket");
        List<Match> existingRR      = matchDAO.getRRMatches(tournamentId);

        System.out.println("existingBracket.size()=" + existingBracket.size()
                         + " existingRR.size()=" + existingRR.size());

        // If a REAL bracket (with actual teams seeded) already exists, just show it
        boolean bracketSeeded = false;
        for (Match m : existingBracket) {
            if (m.getTeam1Id() > 0 || m.getTeam2Id() > 0) { bracketSeeded = true; break; }
        }
        if (bracketSeeded) {
            System.out.println("Bracket already seeded — checking for missing Final placeholder...");
            // Self-healing: if SF1/SF2 exist but Final is missing, insert it now
            boolean hasSF1 = false, hasSF2 = false, hasFinal = false;
            for (Match m : existingBracket) {
                if ("SF1".equals(m.getGroupName())) hasSF1 = true;
                if ("SF2".equals(m.getGroupName())) hasSF2 = true;
                if ("Final".equals(m.getGroupName())) hasFinal = true;
            }
            if (hasSF1 && hasSF2 && !hasFinal) {
                System.out.println("SF1/SF2 exist but Final is missing — inserting Final placeholder.");
                matchDAO.createBracketMatch(tournamentId, 0, 0, "Final");
            }
            response.sendRedirect("OrganizerUpperBracket.jsp?id=" + tournamentId);
            return;
        }

        // If there are stale empty bracket placeholders, delete them so we can regenerate
        if (!existingBracket.isEmpty()) {
            System.out.println("Deleting stale empty bracket placeholder(s)...");
            matchDAO.deleteMatchesByTournamentAndStages(tournamentId,
                new String[]{"QF1","QF2","QF3","QF4","SF1","SF2","Final"});
        }

        try {
            Map<String, List<TeamRegistration>> standings = groupDAO.getRankedTeamsByGroup(tournamentId);
            List<String> groups = new ArrayList<>(standings.keySet());
            int groupCount = groups.size();
            System.out.println("Group count: " + groupCount);

            if (groupCount == 0) {
                List<TeamRegistration> teams = teamRegDAO.getApprovedTeamsByTournament(tournamentId);
                int n = (teams == null) ? 0 : teams.size();
                System.out.println("No groups. Approved teams: " + n);

                if (n < 2) throw new Exception("Need at least 2 approved teams.");

                if (n == 2) {
                    matchDAO.createBracketMatch(tournamentId,
                        teams.get(0).getRegistrationId(),
                        teams.get(1).getRegistrationId(), "Final");
                    System.out.println("2-team: Direct Final created.");

                } else if (n == 3) {
                    if (existingRR.isEmpty()) {
                        // No RR matches yet — create them + Final placeholder (NULL team IDs)
                        for (int i = 0; i < 3; i++)
                            for (int j = i + 1; j < 3; j++)
                                matchDAO.createMatch(new Match(tournamentId, "RR",
                                    teams.get(i).getRegistrationId(),
                                    teams.get(j).getRegistrationId()));
                        matchDAO.createBracketMatch(tournamentId, 0, 0, "Final");
                        System.out.println("3-team: 3 RR matches + Final placeholder created.");
                    } else {
                        // RR matches already exist — check if all are completed
                        boolean allRRDone = true;
                        for (Match m : existingRR) {
                            if (m.getWinnerId() == null) { allRRDone = false; break; }
                        }

                        if (allRRDone) {
                            // Seed Final directly with real team IDs from RR standings
                            boolean seeded = matchDAO.tryResolveRRFinalDirect(tournamentId, existingRR);
                            System.out.println("3-team: All RR done, seeded Final directly: " + seeded);
                            if (!seeded) throw new Exception("Failed to seed Final from RR results.");
                        } else {
                            // RR still in progress — create placeholder only
                            matchDAO.createBracketMatch(tournamentId, 0, 0, "Final");
                            System.out.println("3-team: RR in progress, Final placeholder created.");
                        }
                    }

                } else {
                    matchDAO.createBracketMatch(tournamentId,
                        teams.get(0).getRegistrationId(), teams.get(3).getRegistrationId(), "SF1");
                    matchDAO.createBracketMatch(tournamentId,
                        teams.get(1).getRegistrationId(), teams.get(2).getRegistrationId(), "SF2");
                    matchDAO.createBracketMatch(tournamentId, 0, 0, "Final");
                    System.out.println("Direct SF bracket created (" + n + " teams).");
                }

            } else if (groupCount == 1) {
                List<TeamRegistration> gAT = standings.get(groups.get(0));
                if (gAT.size() < 2) throw new Exception("Group needs at least 2 teams.");
                matchDAO.createBracketMatch(tournamentId,
                    gAT.get(0).getRegistrationId(), gAT.get(1).getRegistrationId(), "Final");

            } else if (groupCount == 2) {
                List<TeamRegistration> gAT = standings.get(groups.get(0));
                List<TeamRegistration> gBT = standings.get(groups.get(1));
                if (gAT.size() < 2 || gBT.size() < 2)
                    throw new Exception("Each group needs at least 2 teams.");
                matchDAO.createBracketMatch(tournamentId,
                    gAT.get(0).getRegistrationId(), gBT.get(1).getRegistrationId(), "SF1");
                matchDAO.createBracketMatch(tournamentId,
                    gBT.get(0).getRegistrationId(), gAT.get(1).getRegistrationId(), "SF2");
                matchDAO.createBracketMatch(tournamentId, 0, 0, "Final");

            } else if (groupCount == 4) {
                List<TeamRegistration> gAT = standings.get(groups.get(0));
                List<TeamRegistration> gBT = standings.get(groups.get(1));
                List<TeamRegistration> gCT = standings.get(groups.get(2));
                List<TeamRegistration> gDT = standings.get(groups.get(3));
                if (gAT.size()<2||gBT.size()<2||gCT.size()<2||gDT.size()<2)
                    throw new Exception("Each group needs at least 2 teams.");
                matchDAO.createBracketMatch(tournamentId,
                    gAT.get(0).getRegistrationId(), gBT.get(1).getRegistrationId(), "QF1");
                matchDAO.createBracketMatch(tournamentId,
                    gBT.get(0).getRegistrationId(), gAT.get(1).getRegistrationId(), "QF2");
                matchDAO.createBracketMatch(tournamentId,
                    gCT.get(0).getRegistrationId(), gDT.get(1).getRegistrationId(), "QF3");
                matchDAO.createBracketMatch(tournamentId,
                    gDT.get(0).getRegistrationId(), gCT.get(1).getRegistrationId(), "QF4");
                matchDAO.createBracketMatch(tournamentId, 0, 0, "SF1");
                matchDAO.createBracketMatch(tournamentId, 0, 0, "SF2");
                matchDAO.createBracketMatch(tournamentId, 0, 0, "Final");

            } else {
                throw new Exception("Unexpected number of groups (" + groupCount + ").");
            }

            System.out.println("=== Bracket generated successfully ===");
            response.sendRedirect("OrganizerUpperBracket.jsp?id=" + tournamentId);

        } catch (Exception e) {
            e.printStackTrace();
            request.getSession().setAttribute("errorMessage", "Error generating bracket: " + e.getMessage());
            response.sendRedirect("TournamentScheduleDetail.jsp?id=" + tournamentId);
        }
    }
}