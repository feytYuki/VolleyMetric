package Controller;

import DAO.TeamRegistrationDAO;
import DAO.TeamMemberDAO;
import Model.TeamRegistration;
import Model.TeamMember;

import javax.servlet.ServletException;
//import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

//@WebServlet("/UpdateTeamRegistrationServlet")
public class UpdateTeamRegistrationServlet extends HttpServlet {
    
    private TeamRegistrationDAO teamRegDAO;
    private TeamMemberDAO teamMemberDAO;
    
    @Override
    public void init() throws ServletException {
        super.init();
        teamRegDAO = new TeamRegistrationDAO();
        teamMemberDAO = new TeamMemberDAO();
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("Login.jsp");
            return;
        }
        
        Integer userId = (Integer) session.getAttribute("userId");
        String fullname = (String) session.getAttribute("fullname");
        String username = (String) session.getAttribute("username");
        
        try {
            String registrationIdStr = request.getParameter("registrationId");
            String teamName = request.getParameter("teamName");
            String[] memberNames = request.getParameterValues("memberName[]");
            String[] memberPositions = request.getParameterValues("memberPosition[]");
            String[] memberJerseys = request.getParameterValues("memberJersey[]");
            
            if (registrationIdStr == null || teamName == null || teamName.trim().isEmpty()) {
                session.setAttribute("errorMessage", "Team name is required!");
                response.sendRedirect("UserRegisTour.jsp");
                return;
            }
            
            int registrationId = Integer.parseInt(registrationIdStr);
            
            // Verify registration belongs to user
            TeamRegistration registration = teamRegDAO.getRegistrationById(registrationId);
            if (registration == null || registration.getUserId() != userId) {
                response.sendRedirect("UserRegisTour.jsp");
                return;
            }
            
            int memberCount = memberNames.length;
            
            if (memberCount < 6 || memberCount > 12) {
                session.setAttribute("errorMessage", "Team must have between 6 and 12 members!");
                response.sendRedirect("EditTeamRegistration.jsp?registrationId=" + registrationId);
                return;
            }
            
            // Update registration with new team name and member count
            registration.setTeamName(teamName.trim());
            registration.setNumberOfPlayers(memberCount);
            
            // CRITICAL FIX: Actually update the registration in the database
            boolean registrationUpdated = teamRegDAO.updateTeamRegistration(registration);
            
            if (!registrationUpdated) {
                session.setAttribute("errorMessage", "Failed to update team registration!");
                response.sendRedirect("EditTeamRegistration.jsp?registrationId=" + registrationId);
                return;
            }
            
            // Delete old members
            teamMemberDAO.deleteMembersByRegistrationId(registrationId);
            
            // Add updated members
            boolean allMembersAdded = true;
            for (int i = 0; i < memberCount; i++) {
                try {
                    int jerseyNum = Integer.parseInt(memberJerseys[i]);
                    
                    TeamMember member = new TeamMember(
                        registrationId,
                        memberNames[i].trim(),
                        memberPositions[i],
                        jerseyNum,
                        i == 0  // First member is captain
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
                session.setAttribute("successMessage", "Team registration updated successfully!");
                response.sendRedirect("UserRegisTour.jsp");
            } else {
                session.setAttribute("errorMessage", "Failed to update team members!");
                response.sendRedirect("EditTeamRegistration.jsp?registrationId=" + registrationId);
            }
            
        } catch (Exception e) {
            System.err.println("Error in UpdateTeamRegistrationServlet: " + e.getMessage());
            e.printStackTrace();
            session.setAttribute("errorMessage", "An error occurred. Please try again.");
            response.sendRedirect("UserRegisTour.jsp");
        }
    }
}