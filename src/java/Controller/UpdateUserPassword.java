package Controller;
import DAO.UserDAO;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

public class UpdateUserPassword extends HttpServlet {
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

        String currentPassword = request.getParameter("currentPassword");
        String newPassword     = request.getParameter("newPassword");
        String confirmPassword = request.getParameter("confirmPassword");

        if (currentPassword == null || currentPassword.isEmpty() ||
            newPassword == null || newPassword.isEmpty() ||
            confirmPassword == null || confirmPassword.isEmpty()) {
            request.setAttribute("errorMessage", "All password fields are required.");
            request.getRequestDispatcher("UserEditProfile.jsp").forward(request, response); // changed
            return;
        }

        if (newPassword.length() < 6) {
            request.setAttribute("errorMessage", "New password must be at least 6 characters.");
            request.getRequestDispatcher("UserEditProfile.jsp").forward(request, response); // changed
            return;
        }

        if (!newPassword.equals(confirmPassword)) {
            request.setAttribute("errorMessage", "New passwords do not match.");
            request.getRequestDispatcher("UserEditProfile.jsp").forward(request, response); // changed
            return;
        }

        boolean currentValid = userDAO.validateUser(username, currentPassword) != null;
        if (!currentValid) {
            request.setAttribute("errorMessage", "Current password is incorrect.");
            request.getRequestDispatcher("UserEditProfile.jsp").forward(request, response); // changed
            return;
        }

        boolean updated = userDAO.updatePassword(username, newPassword);
        if (updated) {
            session.setAttribute("profileSuccess", "Password updated successfully!");
            response.sendRedirect("UserProfile.jsp"); // stays — success goes to view page
        } else {
            request.setAttribute("errorMessage", "Password update failed. Please try again.");
            request.getRequestDispatcher("UserEditProfile.jsp").forward(request, response); // changed
        }
    }
}