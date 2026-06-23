package Controller;

import DAO.TournamentDAO;
import DAO.TeamRegistrationDAO;
import Model.Tournament;
import Model.TeamRegistration;

import javax.servlet.ServletException;
//import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

/**
 * Register Tournament Servlet
 * Handles team registration for tournaments
 */
//@WebServlet("/RegisterTournamentServlet")
public class RegisterTournamentServlet extends HttpServlet {
    
    private TournamentDAO tournamentDAO;
    private TeamRegistrationDAO teamRegistrationDAO;
    
    @Override
    public void init() throws ServletException {
        super.init();
        tournamentDAO = new TournamentDAO();
        teamRegistrationDAO = new TeamRegistrationDAO();
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        // Check if user is logged in
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("Login.jsp");
            return;
        }
        
        Integer userId = (Integer) session.getAttribute("userId");
        String tournamentIdStr = request.getParameter("tournamentId");
        
        if (tournamentIdStr == null) {
            response.sendRedirect("UserTournament.jsp");
            return;
        }
        
        try {
            int tournamentId = Integer.parseInt(tournamentIdStr);
            
            // Get tournament details
            Tournament tournament = tournamentDAO.getTournamentById(tournamentId);
            
            if (tournament == null) {
                session.setAttribute("errorMessage", "Tournament not found!");
                response.sendRedirect("UserTournament.jsp");
                return;
            }
            
            // Check if tournament is full
            if (tournament.isFull()) {
                session.setAttribute("errorMessage", "This tournament is already full!");
                response.sendRedirect("UserTournament.jsp");
                return;
            }
            
            // Check if user already registered
            if (teamRegistrationDAO.isUserRegistered(userId, tournamentId)) {
                session.setAttribute("errorMessage", "You have already registered for this tournament!");
                response.sendRedirect("UserTournament.jsp");
                return;
            }
            
            // Forward to registration form
            request.setAttribute("tournament", tournament);
            request.getRequestDispatcher("TournamentRegistrationForm.jsp").forward(request, response);
            
        } catch (NumberFormatException e) {
            response.sendRedirect("UserTournament.jsp");
        }
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        // Check if user is logged in
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("Login.jsp");
            return;
        }
        
        Integer userId = (Integer) session.getAttribute("userId");
        
        try {
            // Get form parameters
            String tournamentIdStr = request.getParameter("tournamentId");
            String teamName = request.getParameter("teamName");
            String teamLeaderName = request.getParameter("teamLeaderName");
            String contactPhone = request.getParameter("contactPhone");
            String contactEmail = request.getParameter("contactEmail");
            String numberOfPlayersStr = request.getParameter("numberOfPlayers");
            
            // Validate input
            if (tournamentIdStr == null || teamName == null || teamName.trim().isEmpty() ||
                teamLeaderName == null || teamLeaderName.trim().isEmpty() ||
                contactPhone == null || contactPhone.trim().isEmpty() ||
                contactEmail == null || contactEmail.trim().isEmpty() ||
                numberOfPlayersStr == null || numberOfPlayersStr.trim().isEmpty()) {
                
                request.setAttribute("errorMessage", "All fields are required!");
                request.getRequestDispatcher("TournamentRegistrationForm.jsp").forward(request, response);
                return;
            }
            
            int tournamentId = Integer.parseInt(tournamentIdStr);
            int numberOfPlayers = Integer.parseInt(numberOfPlayersStr);
            
            // Validate number of players
            if (numberOfPlayers < 6 || numberOfPlayers > 12) {
                request.setAttribute("errorMessage", "Number of players must be between 6 and 12!");
                request.getRequestDispatcher("TournamentRegistrationForm.jsp").forward(request, response);
                return;
            }
            
            // Trim whitespace
            teamName = teamName.trim();
            teamLeaderName = teamLeaderName.trim();
            contactPhone = contactPhone.trim();
            contactEmail = contactEmail.trim();
            
            // Check if tournament still has space
            Tournament tournament = tournamentDAO.getTournamentById(tournamentId);
            if (tournament == null || tournament.isFull()) {
                session.setAttribute("errorMessage", "This tournament is no longer available!");
                response.sendRedirect("UserTournament.jsp");
                return;
            }
            
            // Check if user already registered
            if (teamRegistrationDAO.isUserRegistered(userId, tournamentId)) {
                session.setAttribute("errorMessage", "You have already registered for this tournament!");
                response.sendRedirect("UserTournament.jsp");
                return;
            }
            
            // Create registration object
            TeamRegistration registration = new TeamRegistration(
                tournamentId,
                userId,
                teamName,
                teamLeaderName,
                contactPhone,
                contactEmail,
                numberOfPlayers
            );
            
            // Register team
            boolean isRegistered = teamRegistrationDAO.registerTeam(registration);
            
            if (isRegistered) {
                // Increment current teams count
                tournamentDAO.incrementCurrentTeams(tournamentId);
                
                session.setAttribute("successMessage", "Successfully registered for the tournament! Your registration is pending approval.");
                response.sendRedirect("UserTournament.jsp");
            } else {
                request.setAttribute("errorMessage", "Registration failed! Please try again.");
                request.getRequestDispatcher("TournamentRegistrationForm.jsp").forward(request, response);
            }
            
        } catch (Exception e) {
            System.err.println("Error in RegisterTournamentServlet: " + e.getMessage());
            e.printStackTrace();
            session.setAttribute("errorMessage", "An error occurred during registration. Please try again.");
            response.sendRedirect("UserTournament.jsp");
        }
    }
}