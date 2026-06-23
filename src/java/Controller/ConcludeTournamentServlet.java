package Controller;

import DAO.TournamentDAO;
import DAO.MatchDAO;
import Model.Match;
import java.io.IOException;
import java.util.List;
import javax.servlet.ServletException;
//import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

//@WebServlet("/ConcludeTournamentServlet")
public class ConcludeTournamentServlet extends HttpServlet {
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        Integer organizerId = (Integer) session.getAttribute("organizerId");
        
        if (organizerId == null) {
            response.sendRedirect("OrganizerLogin.jsp");
            return;
        }
        
        try {
            int tournamentId = Integer.parseInt(request.getParameter("tournamentId"));
            
            TournamentDAO tournamentDAO = new TournamentDAO();
            MatchDAO matchDAO = new MatchDAO();
            
            // Verify all bracket matches are completed
            List<Match> bracketMatches = matchDAO.getMatchesByTournamentAndType(tournamentId, "bracket");
            boolean allCompleted = true;
            
            for (Match match : bracketMatches) {
                if (match.getWinnerId() == null) {
                    allCompleted = false;
                    break;
                }
            }
            
            if (!allCompleted) {
                session.setAttribute("errorMessage", "Cannot conclude tournament. All matches must be completed first.");
                response.sendRedirect("OrganizerUpperBracket.jsp?id=" + tournamentId);
                return;
            }
            
            // Update tournament status to completed
            boolean success = tournamentDAO.updateTournamentStatus(tournamentId, "completed");
            
            if (success) {
                session.setAttribute("successMessage", "🏆 Tournament concluded successfully!");
                response.sendRedirect("OrganizerResult.jsp");
            } else {
                session.setAttribute("errorMessage", "Failed to conclude tournament. Please try again.");
                response.sendRedirect("OrganizerUpperBracket.jsp?id=" + tournamentId);
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            session.setAttribute("errorMessage", "An error occurred: " + e.getMessage());
            response.sendRedirect("OrganizerSchedule.jsp");
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doPost(request, response);
    }
}