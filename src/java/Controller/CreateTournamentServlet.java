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
 * Create Tournament Servlet
 * Handles tournament creation requests
 */
//@WebServlet("/CreateTournamentServlet")
public class CreateTournamentServlet extends HttpServlet {
    
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
            // Get form parameters
            String tournamentName = request.getParameter("tournamentName");
            String tournamentDateStr = request.getParameter("tournamentDate");
            String startTimeStr = request.getParameter("startTime");
            String location = request.getParameter("location");
            String category = request.getParameter("category");
            String tournamentType = request.getParameter("tournamentType");
            String maxTeamsStr = request.getParameter("maxTeams");
            String description = request.getParameter("description");
            
            // Validate input
            if (tournamentName == null || tournamentName.trim().isEmpty() ||
                tournamentDateStr == null || tournamentDateStr.trim().isEmpty() ||
                startTimeStr == null || startTimeStr.trim().isEmpty() ||
                location == null || location.trim().isEmpty() ||
                category == null || category.trim().isEmpty() ||
                tournamentType == null || tournamentType.trim().isEmpty() ||
                maxTeamsStr == null || maxTeamsStr.trim().isEmpty()) {
                
                request.setAttribute("errorMessage", "All required fields must be filled!");
                request.getRequestDispatcher("CreateTournament.jsp").forward(request, response);
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
                    request.getRequestDispatcher("CreateTournament.jsp").forward(request, response);
                    return;
                }
            } catch (NumberFormatException e) {
                request.setAttribute("errorMessage", "Invalid number format for maximum teams!");
                request.getRequestDispatcher("CreateTournament.jsp").forward(request, response);
                return;
            }
            
            // Validate category
            if (!category.equals("men") && !category.equals("women") && !category.equals("mixed")) {
                request.setAttribute("errorMessage", "Invalid category selected!");
                request.getRequestDispatcher("CreateTournament.jsp").forward(request, response);
                return;
            }
            
            // Validate tournament type
            if (!tournamentType.equals("indoor") && !tournamentType.equals("beach")) {
                request.setAttribute("errorMessage", "Invalid tournament type selected!");
                request.getRequestDispatcher("CreateTournament.jsp").forward(request, response);
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
                request.getRequestDispatcher("CreateTournament.jsp").forward(request, response);
                return;
            }
            
            // Check if tournament date is in the future
            Date today = new Date(System.currentTimeMillis());
            if (tournamentDate.before(today)) {
                request.setAttribute("errorMessage", "Tournament date must be in the future!");
                request.getRequestDispatcher("CreateTournament.jsp").forward(request, response);
                return;
            }
            
            // Create tournament object
            Tournament tournament = new Tournament(
                organizerId,
                tournamentName,
                tournamentDate,
                startTime,
                location,
                category,
                tournamentType,
                maxTeams,
                description != null ? description.trim() : null
            );
            
            // Save tournament to database
            boolean isCreated = tournamentDAO.createTournament(tournament);
            
            if (isCreated) {
                // Tournament creation successful
                session.setAttribute("successMessage", "Tournament created successfully!");
                response.sendRedirect("OrganizerHome.jsp");
            } else {
                // Tournament creation failed
                request.setAttribute("errorMessage", "Failed to create tournament. Please try again.");
                request.getRequestDispatcher("CreateTournament.jsp").forward(request, response);
            }
            
        } catch (Exception e) {
            System.err.println("Error in CreateTournamentServlet: " + e.getMessage());
            e.printStackTrace();
            request.setAttribute("errorMessage", "An error occurred while creating the tournament. Please try again.");
            request.getRequestDispatcher("CreateTournament.jsp").forward(request, response);
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        // Redirect GET requests to the create tournament page
        response.sendRedirect("CreateTournament.jsp");
    }
}