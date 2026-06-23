package Controller;

import DAO.OrganizerDAO;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

public class UpdateOrganizerPassword extends HttpServlet {

    private OrganizerDAO organizerDAO;

    @Override
    public void init() throws ServletException {
        organizerDAO = new OrganizerDAO();
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        Integer organizerId = (session != null) ? (Integer) session.getAttribute("organizerId") : null;

        if (organizerId == null) {
            response.sendRedirect("OrganizerLogin.jsp");
            return;
        }

        String currentPassword  = request.getParameter("currentPassword");
        String newPassword      = request.getParameter("newPassword");
        String confirmPassword  = request.getParameter("confirmPassword");

        if (currentPassword == null || currentPassword.trim().isEmpty() ||
            newPassword     == null || newPassword.trim().isEmpty()     ||
            confirmPassword == null || confirmPassword.trim().isEmpty()) {
            session.setAttribute("pwError", "All password fields are required.");
            response.sendRedirect("OrganizerEditProfile.jsp");
            return;
        }

        if (!newPassword.equals(confirmPassword)) {
            session.setAttribute("pwError", "New passwords do not match.");
            response.sendRedirect("OrganizerEditProfile.jsp");
            return;
        }

        if (newPassword.length() < 6) {
            session.setAttribute("pwError", "New password must be at least 6 characters.");
            response.sendRedirect("OrganizerEditProfile.jsp");
            return;
        }

        boolean changed = organizerDAO.changePassword(organizerId, currentPassword, newPassword);

        if (changed) {
            session.setAttribute("pwSuccess", "Password changed successfully!");
        } else {
            session.setAttribute("pwError", "Current password is incorrect.");
        }

        response.sendRedirect("OrganizerEditProfile.jsp");
    }
}