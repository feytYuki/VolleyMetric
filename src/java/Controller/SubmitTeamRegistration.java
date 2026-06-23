package Controller;

import DAO.TournamentDAO;
import DAO.TeamRegistrationDAO;
import DAO.TeamMemberDAO;
import Model.Tournament;
import Model.TeamRegistration;
import Model.TeamMember;

import javax.servlet.ServletException;
//import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

/**
 * Submit Team Registration Servlet
 * Handles the submission of team registration with members
 */
//@WebServlet("/SubmitTeamRegistration")
public class SubmitTeamRegistration extends HttpServlet {
    
    private TournamentDAO tournamentDAO;
    private TeamRegistrationDAO teamRegistrationDAO;
    private TeamMemberDAO teamMemberDAO;
    
    @Override
    public void init() throws ServletException {
        super.init();
        tournamentDAO = new TournamentDAO();
        teamRegistrationDAO = new TeamRegistrationDAO();
        teamMemberDAO = new TeamMemberDAO();
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
        String fullname = (String) session.getAttribute("fullname");
        String username = (String) session.getAttribute("username");
        String userEmail = (String) session.getAttribute("email");
        
        try {
            // Get tournament ID and team name
            String tournamentIdStr = request.getParameter("tournamentId");
            String teamName = request.getParameter("teamName");
            
            if (tournamentIdStr == null || teamName == null || teamName.trim().isEmpty()) {
                session.setAttribute("errorMessage", "Team name is required!");
                response.sendRedirect("UserTournament.jsp");
                return;
            }
            
            int tournamentId = Integer.parseInt(tournamentIdStr);
            teamName = teamName.trim();
            
            // Get member details
            String[] memberNames = request.getParameterValues("memberName[]");
            String[] memberPositions = request.getParameterValues("memberPosition[]");
            String[] memberJerseys = request.getParameterValues("memberJersey[]");
            
            // Validate input
            if (memberNames == null || memberPositions == null || memberJerseys == null) {
                session.setAttribute("errorMessage", "Team member information is required!");
                response.sendRedirect("UserTournament.jsp");
                return;
            }
            
            int memberCount = memberNames.length;
            
            // Validate member count
            if (memberCount < 6 || memberCount > 12) {
                session.setAttribute("errorMessage", "Team must have between 6 and 12 members!");
                response.sendRedirect("UserTournament.jsp");
                return;
            }
            
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
                response.sendRedirect("UserTournaments.jsp");
                return;
            }
            
            // Check if team name already taken in this tournament
            if (teamRegistrationDAO.isTeamNameTaken(teamName, tournamentId)) {
                session.setAttribute("errorMessage", "The team name \"" + teamName + "\" is already registered for this tournament. Please choose a different name.");
                response.sendRedirect("UserTournament.jsp");
                return;
            }
            
            // Create team registration
            TeamRegistration registration = new TeamRegistration(
                tournamentId,
                userId,
                teamName, // Use user-provided team name
                memberNames[0], // Captain name (first member)
                "", // Will be set from user data
                userEmail != null ? userEmail : "", // Contact email
                memberCount
            );
            
            // Register team
            boolean isRegistered = teamRegistrationDAO.registerTeam(registration);
            
            if (isRegistered) {
                int registrationId = registration.getRegistrationId();
                
                // Add all team members
                boolean allMembersAdded = true;
                for (int i = 0; i < memberCount; i++) {
                    try {
                        int jerseyNum = Integer.parseInt(memberJerseys[i]);
                        
                        TeamMember member = new TeamMember(
                            registrationId,
                            memberNames[i].trim(),
                            memberPositions[i],
                            jerseyNum,
                            i == 0 // First member is captain
                        );
                        
                        if (!teamMemberDAO.addTeamMember(member)) {
                            allMembersAdded = false;
                            break;
                        }
                    } catch (NumberFormatException e) {
                        allMembersAdded = false;
                        break;
                    }
                }
                
                if (allMembersAdded) {
                    // Increment current teams count
                    tournamentDAO.incrementCurrentTeams(tournamentId);
                    
                    session.setAttribute("successMessage", 
                        "Successfully registered for " + tournament.getTournamentName() + 
                        "! Your registration is pending organizer approval.");
                    response.sendRedirect("UserTournament.jsp");
                } else {
                    // Rollback: delete registration if members couldn't be added
                    teamMemberDAO.deleteMembersByRegistrationId(registrationId);
                    session.setAttribute("errorMessage", "Failed to add team members. Please try again.");
                    response.sendRedirect("UserTournament.jsp");
                }
            } else {
                session.setAttribute("errorMessage", "Registration failed! Please try again.");
                response.sendRedirect("UserTournament.jsp");
            }
            
        } catch (Exception e) {
            System.err.println("Error in SubmitTeamRegistration: " + e.getMessage());
            e.printStackTrace();
            session.setAttribute("errorMessage", "An error occurred during registration. Please try again.");
            response.sendRedirect("UserTournament.jsp");
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        response.sendRedirect("UserTournament.jsp");
    }
}