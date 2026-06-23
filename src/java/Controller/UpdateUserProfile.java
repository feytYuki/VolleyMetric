package Controller;

import DAO.UserDAO;
import Model.User;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

public class UpdateUserProfile extends HttpServlet {

    private UserDAO userDAO;

    @Override
    public void init() throws ServletException {
        userDAO = new UserDAO();
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();
        String username = (String) session.getAttribute("username");

        if (username == null) {
            response.sendRedirect("Login.jsp");
            return;
        }

        String fullname = request.getParameter("fullname");
        String email    = request.getParameter("email");
        String phone    = request.getParameter("phone");

        if (fullname == null || fullname.trim().isEmpty() ||
            email == null || email.trim().isEmpty() ||
            phone == null || phone.trim().isEmpty()) {
            request.setAttribute("errorMessage", "All fields are required.");
            request.getRequestDispatcher("UserProfile.jsp").forward(request, response);
            return;
        }

        // Fetch user by username to get ID
        User user = userDAO.getUserByUsername(username);
        if (user == null) {
            request.setAttribute("errorMessage", "User not found.");
            request.getRequestDispatcher("UserProfile.jsp").forward(request, response);
            return;
        }

        user.setFullname(fullname.trim());
        user.setEmail(email.trim());
        user.setPhone(phone.trim());

        boolean updated = userDAO.updateUser(user);

        if (updated) {
            // Refresh fullname in session
            session.setAttribute("fullname", fullname.trim());
            session.setAttribute("profileSuccess", "Profile updated successfully!");
            response.sendRedirect("UserProfile.jsp");
        } else {
            request.setAttribute("errorMessage", "Update failed. Please try again.");
            request.getRequestDispatcher("UserProfile.jsp").forward(request, response);
        }
    }
}