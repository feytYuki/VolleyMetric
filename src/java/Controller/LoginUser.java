package Controller;

import DAO.UserDAO;
import Model.User;

import javax.servlet.ServletException;
//import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

/**
 * Login Servlet
 * Handles user login/authentication requests
 */
//@WebServlet("/loginServlet")
public class LoginUser extends HttpServlet {
    
    private UserDAO userDAO;
    
    @Override
    public void init() throws ServletException {
        super.init();
        userDAO = new UserDAO();
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
                request.getRequestDispatcher("Login.jsp").forward(request, response);
                return;
            }
            
            // Trim whitespace from username
            username = username.trim();
            
            // Validate user credentials
            User user = userDAO.validateUser(username, password);
            
            if (user != null) {
                // Login successful
                HttpSession session = request.getSession();
                session.setAttribute("user", user);
                session.setAttribute("userId", user.getUserId());
                session.setAttribute("username", user.getUsername());
                session.setAttribute("fullname", user.getFullname());
                
                // Set session timeout (30 minutes)
                session.setMaxInactiveInterval(30 * 60);
                
                System.out.println("User logged in: " + user.getUsername());
                
                // Redirect to homepage or dashboard
                response.sendRedirect("UserHome.jsp");
                
            } else {
                // Login failed
                request.setAttribute("errorMessage", "Invalid username or password!");
                request.getRequestDispatcher("Login.jsp").forward(request, response);
            }
            
        } catch (Exception e) {
            System.err.println("Error in LoginServlet: " + e.getMessage());
            e.printStackTrace();
            request.setAttribute("errorMessage", "An error occurred during login. Please try again.");
            request.getRequestDispatcher("Login.jsp").forward(request, response);
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        // Redirect GET requests to the login page
        response.sendRedirect("Login.jsp");
    }
}