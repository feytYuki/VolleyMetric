package Controller;

import DAO.TeamRegistrationDAO;
import DAO.TournamentDAO;
import Model.TeamRegistration;

import javax.servlet.ServletException;
//import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

//@WebServlet("/ApproveRejectTeamServlet")
public class ApproveRejectTeamServlet extends HttpServlet {
    
    private TeamRegistrationDAO teamRegDAO;
    private TournamentDAO tournamentDAO;
    
    @Override
    public void init() throws ServletException {
        super.init();
        teamRegDAO = new TeamRegistrationDAO();
        tournamentDAO = new TournamentDAO();
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("organizerId") == null) {
            response.sendRedirect("OrganizerLogin.jsp");
            return;
        }
        
        Integer organizerId = (Integer) session.getAttribute("organizerId");
        
        try {
            String registrationIdStr = request.getParameter("registrationId");
            String action = request.getParameter("action");
            
            if (registrationIdStr == null || action == null) {
                response.sendRedirect("OrganizerTournaments.jsp");
                return;
            }
            
            int registrationId = Integer.parseInt(registrationIdStr);
            
            // Get registration
            TeamRegistration registration = teamRegDAO.getRegistrationById(registrationId);
            if (registration == null) {
                session.setAttribute("errorMessage", "Registration not found!");
                response.sendRedirect("OrganizerTournaments.jsp");
                return;
            }
            
            // Update status
            String newStatus = action.equals("approve") ? "approved" : "rejected";
            boolean updated = teamRegDAO.updateRegistrationStatus(registrationId, newStatus);
            
            if (updated) {
                session.setAttribute("successMessage", 
                    "Team " + (action.equals("approve") ? "approved" : "rejected") + " successfully!");
            } else {
                session.setAttribute("errorMessage", "Failed to update registration status!");
            }
            
            // Redirect back to tournament details
            response.sendRedirect("OrganizerViewDetail.jsp?id=" + registration.getTournamentId());
            
        } catch (Exception e) {
            System.err.println("Error in ApproveRejectTeamServlet: " + e.getMessage());
            e.printStackTrace();
            session.setAttribute("errorMessage", "An error occurred. Please try again.");
            response.sendRedirect("OrganizerTournaments.jsp");
        }
    }
}