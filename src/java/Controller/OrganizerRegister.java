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
 * Register Organizer Servlet
 * Handles organizer registration requests
 */
//@WebServlet("/RegisterOrganizer")  // FIXED: Uncommented and matches form action
public class OrganizerRegister extends HttpServlet {
    
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
            String fullname = request.getParameter("fullname");
            String username = request.getParameter("username");
            String email = request.getParameter("email");
            String phone = request.getParameter("phone");
            String password = request.getParameter("password");
            String confirmPassword = request.getParameter("confirmPassword");
            
            // Validate input
            if (fullname == null || fullname.trim().isEmpty() ||
                username == null || username.trim().isEmpty() ||
                email == null || email.trim().isEmpty() ||
                phone == null || phone.trim().isEmpty() ||
                password == null || password.isEmpty() ||
                confirmPassword == null || confirmPassword.isEmpty()) {
                
                request.setAttribute("errorMessage", "All fields are required!");
                request.getRequestDispatcher("OrganizerRegister.jsp").forward(request, response);
                return;
            }
            
            // Trim whitespace
            fullname = fullname.trim();
            username = username.trim();
            email = email.trim();
            phone = phone.trim();
            
            // Validate username length
            if (username.length() < 4 || username.length() > 20) {
                request.setAttribute("errorMessage", "Username must be between 4 and 20 characters!");
                request.getRequestDispatcher("OrganizerRegister.jsp").forward(request, response);
                return;
            }
            
            // Validate password length
            if (password.length() < 6) {
                request.setAttribute("errorMessage", "Password must be at least 6 characters long!");
                request.getRequestDispatcher("OrganizerRegister.jsp").forward(request, response);
                return;
            }
            
            // Check if passwords match
            if (!password.equals(confirmPassword)) {
                request.setAttribute("errorMessage", "Passwords do not match!");
                request.getRequestDispatcher("OrganizerRegister.jsp").forward(request, response);
                return;
            }
            
            // Validate email format
            if (!isValidEmail(email)) {
                request.setAttribute("errorMessage", "Invalid email format!");
                request.getRequestDispatcher("OrganizerRegister.jsp").forward(request, response);
                return;
            }
            
            // Check if username already exists
            if (organizerDAO.isUsernameExists(username)) {
                request.setAttribute("errorMessage", "Username already exists! Please choose another one.");
                request.getRequestDispatcher("OrganizerRegister.jsp").forward(request, response);
                return;
            }
            
            // Check if email already exists
            if (organizerDAO.isEmailExists(email)) {
                request.setAttribute("errorMessage", "Email already registered! Please use another email.");
                request.getRequestDispatcher("OrganizerRegister.jsp").forward(request, response);
                return;
            }
            
            // Create new organizer object
            Organizer newOrganizer = new Organizer(fullname, username, email, phone, password);
            
            // Register organizer
            boolean isRegistered = organizerDAO.registerOrganizer(newOrganizer);
            
            if (isRegistered) {
                // Registration successful
                HttpSession session = request.getSession();
                session.setAttribute("successMessage", "Organizer registration successful! Please login.");
                response.sendRedirect("OrganizerLogin.jsp");
            } else {
                // Registration failed
                request.setAttribute("errorMessage", "Registration failed! Please try again.");
                request.getRequestDispatcher("OrganizerRegister.jsp").forward(request, response);
            }
            
        } catch (Exception e) {
            System.err.println("Error in OrganizerRegister: " + e.getMessage());
            e.printStackTrace();
            request.setAttribute("errorMessage", "An error occurred during registration. Please try again.");
            request.getRequestDispatcher("OrganizerRegister.jsp").forward(request, response);
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        // Redirect GET requests to the registration page
        response.sendRedirect("OrganizerRegister.jsp");
    }
    
    /**
     * Validate email format
     * @param email Email to validate
     * @return true if email is valid, false otherwise
     */
    private boolean isValidEmail(String email) {
        String emailRegex = "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$";
        return email.matches(emailRegex);
    }
}