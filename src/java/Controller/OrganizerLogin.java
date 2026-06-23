package Controller;

import DAO.OrganizerDAO;
import Model.Organizer;

import javax.servlet.ServletException;
//import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

/**
 * Login Organizer Servlet
 * Handles organizer login requests
 */
//@WebServlet("/LoginOrganizer")
public class OrganizerLogin extends HttpServlet {
    
    private OrganizerDAO organizerDAO;
    
    @Override
    public void init() throws ServletException {
        super.init();
        organizerDAO = new OrganizerDAO();
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        // Set response content type
        response.setContentType("text/html;charset=UTF-8");
        
        try {
            // Get form parameters
            String username = request.getParameter("username");
            String password = request.getParameter("password");
            
            // Validate input
            if (username == null || username.trim().isEmpty() ||
                password == null || password.isEmpty()) {
                
                request.setAttribute("errorMessage", "Username and password are required!");
                request.getRequestDispatcher("OrganizerLogin.jsp").forward(request, response);
                return;
            }
            
            // Trim username
            username = username.trim();
            
            // Validate organizer credentials
            Organizer organizer = organizerDAO.validateOrganizer(username, password);
            
            if (organizer != null) {
                // Login successful
                HttpSession session = request.getSession();
                session.setAttribute("organizerId", organizer.getOrganizerId());
                session.setAttribute("organizerUsername", organizer.getUsername());
                session.setAttribute("organizerFullname", organizer.getFullname());
                session.setAttribute("organizerEmail", organizer.getEmail());
                session.setAttribute("userType", "organizer");
                
                System.out.println("Organizer logged in successfully: " + username);
                
                // Redirect to organizer dashboard
                response.sendRedirect("OrganizerHome.jsp");
            } else {
                // Login failed
                request.setAttribute("errorMessage", "Invalid username or password!");
                request.getRequestDispatcher("OrganizerLogin.jsp").forward(request, response);
            }
            
        } catch (Exception e) {
            System.err.println("Error in LoginOrganizer: " + e.getMessage());
            e.printStackTrace();
            request.setAttribute("errorMessage", "An error occurred during login. Please try again.");
            request.getRequestDispatcher("OrganizerLogin.jsp").forward(request, response);
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        // Redirect GET requests to the login page
        response.sendRedirect("OrganizerLogin.jsp");
    }
}