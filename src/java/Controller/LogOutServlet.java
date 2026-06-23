package Controller;

import javax.servlet.ServletException;
//import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

/**
 * Logout Servlet
 * Handles user logout requests
 */
//@WebServlet("/LogoutServlet")
public class LogOutServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        
        if (session != null) {
            String userType = (String) session.getAttribute("userType");
            session.invalidate();
            System.out.println("User logged out successfully");
        }
        
        // Redirect to homepage
        response.sendRedirect("Homepage.jsp");
    }
}