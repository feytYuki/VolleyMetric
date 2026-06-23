package Controller;

import Model.Match;
import DAO.MatchDAO;
import javax.servlet.ServletException;
import javax.servlet.http.*;
import java.io.IOException;

public class UpdateMatchResultServlet extends HttpServlet {

    private MatchDAO matchDAO;

    @Override
    public void init() throws ServletException {
        super.init();
        matchDAO = new MatchDAO();
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
            String matchIdStr      = request.getParameter("matchId");
            String tournamentIdStr = request.getParameter("tournamentId");
            String winnerIdStr     = request.getParameter("winnerId");

            if (matchIdStr == null || tournamentIdStr == null
                    || winnerIdStr == null || winnerIdStr.trim().isEmpty()) {
                String tid = (tournamentIdStr != null) ? tournamentIdStr : "";
                session.setAttribute("errorMessage", "Please select a winner before saving!");
                response.sendRedirect("OrganizerUpperBracket.jsp?id=" + tid);
                return;
            }

            int matchId      = Integer.parseInt(matchIdStr);
            int tournamentId = Integer.parseInt(tournamentIdStr);
            int winnerId     = Integer.parseInt(winnerIdStr);

            Match match = matchDAO.getMatchById(matchId);
            if (match == null) {
                session.setAttribute("errorMessage", "Match not found!");
                response.sendRedirect("OrganizerUpperBracket.jsp?id=" + tournamentId);
                return;
            }

            match.setWinnerId(winnerId);

            // Parse set scores (best of 5)
            for (int i = 1; i <= 5; i++) {
                String t1s = request.getParameter("team1_set" + i);
                String t2s = request.getParameter("team2_set" + i);
                if (t1s != null && !t1s.isEmpty() && t2s != null && !t2s.isEmpty()) {
                    int s1 = Integer.parseInt(t1s);
                    int s2 = Integer.parseInt(t2s);

                    // Server-side validation: max 31 points per set
                    if (s1 > 31 || s2 > 31) {
                        session.setAttribute("errorMessage", "Set " + i + " score cannot exceed 31 points!");
                        response.sendRedirect("OrganizerUpperBracket.jsp?id=" + tournamentId);
                        return;
                    }
                    if (s1 < 0 || s2 < 0) {
                        session.setAttribute("errorMessage", "Set scores cannot be negative!");
                        response.sendRedirect("OrganizerUpperBracket.jsp?id=" + tournamentId);
                        return;
                    }

                    switch (i) {
                        case 1: match.setTeam1Set1(s1); match.setTeam2Set1(s2); break;
                        case 2: match.setTeam1Set2(s1); match.setTeam2Set2(s2); break;
                        case 3: match.setTeam1Set3(s1); match.setTeam2Set3(s2); break;
                        case 4: match.setTeam1Set4(s1); match.setTeam2Set4(s2); break;
                        case 5: match.setTeam1Set5(s1); match.setTeam2Set5(s2); break;
                    }
                }
            }

            boolean updated = matchDAO.updateMatchResult(match);

            if (!updated) {
                session.setAttribute("errorMessage", "Failed to save match result!");
                response.sendRedirect("OrganizerUpperBracket.jsp?id=" + tournamentId);
                return;
            }

            String stage = match.getGroupName();

            // ── RR match: check if all 3 done and seed the Final ──────────
            if ("RR".equals(stage)) {
                boolean finalSeeded = matchDAO.tryResolveRRFinal(tournamentId);
                if (finalSeeded) {
                    session.setAttribute("successMessage",
                        "All round-robin matches complete! Final has been seeded. Proceed to the bracket.");
                } else {
                    session.setAttribute("successMessage", "Round-robin match saved!");
                }
                response.sendRedirect("TournamentScheduleDetail.jsp?id=" + tournamentId);
                return;
            }

            // ── Bracket match: advance winner ─────────────────────────────
            String matchType = match.getMatchType();
            boolean isBracket = "bracket".equals(matchType)
                    || "QF1".equals(stage) || "QF2".equals(stage)
                    || "QF3".equals(stage) || "QF4".equals(stage)
                    || "SF1".equals(stage) || "SF2".equals(stage)
                    || "Final".equals(stage);

            if (isBracket) {
                if      ("QF1".equals(stage)) matchDAO.updateFutureMatchTeam(tournamentId, "SF1", 1, winnerId);
                else if ("QF2".equals(stage)) matchDAO.updateFutureMatchTeam(tournamentId, "SF1", 2, winnerId);
                else if ("QF3".equals(stage)) matchDAO.updateFutureMatchTeam(tournamentId, "SF2", 1, winnerId);
                else if ("QF4".equals(stage)) matchDAO.updateFutureMatchTeam(tournamentId, "SF2", 2, winnerId);
                else if ("SF1".equals(stage) || "SF2".equals(stage)) {
                    // ── Guarantee Final row exists before seeding it ──────
                    // This prevents the silent "0 rows updated" bug when the
                    // Final placeholder was never persisted to DB yet.
                    matchDAO.ensureFinalExists(tournamentId);

                    int slot = "SF1".equals(stage) ? 1 : 2;
                    matchDAO.updateFutureMatchTeam(tournamentId, "Final", slot, winnerId);
                }

                session.setAttribute("successMessage", "Match saved! Winner advanced to next round.");
                response.sendRedirect("OrganizerUpperBracket.jsp?id=" + tournamentId);
            } else {
                // Normal group-stage match (A/B/C/D)
                session.setAttribute("successMessage", "Group match result saved!");
                response.sendRedirect("TournamentScheduleDetail.jsp?id=" + tournamentId);
            }

        } catch (NumberFormatException e) {
            e.printStackTrace();
            session.setAttribute("errorMessage", "Invalid input data!");
            response.sendRedirect("OrganizerUpperBracket.jsp");
        } catch (Exception e) {
            e.printStackTrace();
            session.setAttribute("errorMessage", "An error occurred: " + e.getMessage());
            response.sendRedirect("OrganizerUpperBracket.jsp");
        }
    }
}