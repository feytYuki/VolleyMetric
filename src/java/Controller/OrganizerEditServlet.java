package Controller;

import DAO.TournamentDAO;
import Model.Tournament;

import javax.servlet.ServletException;
//import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.Date;
import java.sql.Time;

/**
 * Update Tournament Servlet
 * Handles tournament update requests
 */
//@WebServlet("/UpdateTournamentServlet")
public class OrganizerEditServlet extends HttpServlet {
    
    private TournamentDAO tournamentDAO;
    
    @Override
    public void init() throws ServletException {
        super.init();
        tournamentDAO = new TournamentDAO();
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        // Set response content type
        response.setContentType("text/html;charset=UTF-8");
        
        // Check if organizer is logged in
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("organizerId") == null) {
            response.sendRedirect("OrganizerLogin.jsp");
            return;
        }
        
        Integer organizerId = (Integer) session.getAttribute("organizerId");
        
        try {
            // Get tournament ID
            String tournamentIdStr = request.getParameter("tournamentId");
            if (tournamentIdStr == null) {
                response.sendRedirect("OrganizerTournament.jsp");
                return;
            }
            
            int tournamentId = Integer.parseInt(tournamentIdStr);
            
            // Verify tournament belongs to this organizer
            Tournament existingTournament = tournamentDAO.getTournamentById(tournamentId);
            if (existingTournament == null || existingTournament.getOrganizerId() != organizerId) {
                response.sendRedirect("OrganizerTournament.jsp");
                return;
            }
            
            // Get form parameters
            String tournamentName = request.getParameter("tournamentName");
            String tournamentDateStr = request.getParameter("tournamentDate");
            String startTimeStr = request.getParameter("startTime");
            String location = request.getParameter("location");
            String category = request.getParameter("category");
            String tournamentType = request.getParameter("tournamentType");
            String maxTeamsStr = request.getParameter("maxTeams");
            String status = request.getParameter("status");
            String description = request.getParameter("description");
            
            // Validate input
            if (tournamentName == null || tournamentName.trim().isEmpty() ||
                tournamentDateStr == null || tournamentDateStr.trim().isEmpty() ||
                startTimeStr == null || startTimeStr.trim().isEmpty() ||
                location == null || location.trim().isEmpty() ||
                category == null || category.trim().isEmpty() ||
                tournamentType == null || tournamentType.trim().isEmpty() ||
                maxTeamsStr == null || maxTeamsStr.trim().isEmpty() ||
                status == null || status.trim().isEmpty()) {
                
                request.setAttribute("errorMessage", "All required fields must be filled!");
                request.getRequestDispatcher("TournamentEditOrganizer.jsp?id=" + tournamentId).forward(request, response);
                return;
            }
            
            // Trim whitespace
            tournamentName = tournamentName.trim();
            location = location.trim();
            
            // Parse max teams
            int maxTeams;
            try {
                maxTeams = Integer.parseInt(maxTeamsStr);
                if (maxTeams < 2 || maxTeams > 64) {
                    request.setAttribute("errorMessage", "Maximum teams must be between 2 and 64!");
                    request.getRequestDispatcher("TournamentEditOrganizer.jsp?id=" + tournamentId).forward(request, response);
                    return;
                }
            } catch (NumberFormatException e) {
                request.setAttribute("errorMessage", "Invalid number format for maximum teams!");
                request.getRequestDispatcher("TournamentEditOrganizer.jsp?id=" + tournamentId).forward(request, response);
                return;
            }
            
            // Check if max teams is less than current teams
            if (maxTeams < existingTournament.getCurrentTeams()) {
                request.setAttribute("errorMessage", "Maximum teams cannot be less than current registered teams (" + existingTournament.getCurrentTeams() + ")!");
                request.getRequestDispatcher("TournamentEditOrganizer.jsp?id=" + tournamentId).forward(request, response);
                return;
            }
            
            // Validate category
            if (!category.equals("men") && !category.equals("women") && !category.equals("mixed")) {
                request.setAttribute("errorMessage", "Invalid category selected!");
                request.getRequestDispatcher("TournamentEditOrganizer.jsp?id=" + tournamentId).forward(request, response);
                return;
            }
            
            // Validate tournament type
            if (!tournamentType.equals("indoor") && !tournamentType.equals("beach")) {
                request.setAttribute("errorMessage", "Invalid tournament type selected!");
                request.getRequestDispatcher("TournamentEditOrganizer.jsp?id=" + tournamentId).forward(request, response);
                return;
            }
            
            // Validate status
            if (!status.equals("upcoming") && !status.equals("ongoing") && 
                !status.equals("completed") && !status.equals("cancelled")) {
                request.setAttribute("errorMessage", "Invalid status selected!");
                request.getRequestDispatcher("TournamentEditOrganizer.jsp?id=" + tournamentId).forward(request, response);
                return;
            }
            
            // Parse date and time
            Date tournamentDate;
            Time startTime;
            try {
                tournamentDate = Date.valueOf(tournamentDateStr);
                startTime = Time.valueOf(startTimeStr + ":00");
            } catch (IllegalArgumentException e) {
                request.setAttribute("errorMessage", "Invalid date or time format!");
                request.getRequestDispatcher("TournamentEditOrganizer.jsp?id=" + tournamentId).forward(request, response);
                return;
            }
            
            // Update tournament object
            existingTournament.setTournamentName(tournamentName);
            existingTournament.setTournamentDate(tournamentDate);
            existingTournament.setStartTime(startTime);
            existingTournament.setLocation(location);
            existingTournament.setCategory(category);
            existingTournament.setTournamentType(tournamentType);
            existingTournament.setMaxTeams(maxTeams);
            existingTournament.setStatus(status);
            existingTournament.setDescription(description != null ? description.trim() : null);
            
            // Update tournament in database
            boolean isUpdated = tournamentDAO.updateTournament(existingTournament);
            
            if (isUpdated) {
                // Tournament update successful
                session.setAttribute("successMessage", "Tournament updated successfully!");
                response.sendRedirect("OrganizerTournament.jsp");
            } else {
                // Tournament update failed
                request.setAttribute("errorMessage", "Failed to update tournament. Please try again.");
                request.getRequestDispatcher("TournamentEditOrganizer.jsp?id=" + tournamentId).forward(request, response);
            }
            
        } catch (Exception e) {
            System.err.println("Error in UpdateTournamentServlet: " + e.getMessage());
            e.printStackTrace();
            request.setAttribute("errorMessage", "An error occurred while updating the tournament. Please try again.");
            request.getRequestDispatcher("OrganizerTournament.jsp").forward(request, response);
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        // Redirect GET requests to tournaments page
        response.sendRedirect("OrganizerTournament.jsp");
    }
}