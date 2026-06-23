package Controller;

import DAO.OrganizerDAO;
import DAO.UserDAO;
import Model.Organizer;
import Model.User;

import javax.servlet.ServletException;
//import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

/**
 * Handles forgot password and reset password for both User and Organizer.
 *
 * Expected request parameters:
 *   action : "forgot" | "reset"
 *   role   : "user"   | "organizer"
 *
 * Forgot flow  → verifies username exists, stores it in session, redirects to reset JSP.
 * Reset flow   → validates new password, updates DB, clears session, redirects to login.
 */
//@WebServlet("/PasswordResetServlet")
public class PasswordResetServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action"); // "forgot" or "reset"
        String role   = request.getParameter("role");   // "user" or "organizer"

        boolean isOrganizer = "organizer".equals(role);

        if ("forgot".equals(action)) {
            handleForgot(request, response, isOrganizer);
        } else if ("reset".equals(action)) {
            handleReset(request, response, isOrganizer);
        } else {
            // Unknown action — send back to home
            response.sendRedirect(isOrganizer ? "OrganizerLogin.jsp" : "Login.jsp");
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String role = request.getParameter("role");
        response.sendRedirect("organizer".equals(role)
                ? "OrganizerForgotPassword.jsp"
                : "ForgotPassword.jsp");
    }

    // ── Forgot: verify username exists, store in session ──────────────────────

    private void handleForgot(HttpServletRequest request, HttpServletResponse response,
                               boolean isOrganizer) throws ServletException, IOException {

        String forgotJsp = isOrganizer ? "OrganizerForgotPassword.jsp" : "ForgotPassword.jsp";
        String resetJsp  = isOrganizer ? "OrganizerResetPassword.jsp"  : "ResetPassword.jsp";
        String sessionKey = isOrganizer ? "resetOrganizerUsername" : "resetUsername";

        String username = request.getParameter("username");

        if (username == null || username.trim().isEmpty()) {
            request.setAttribute("error", "Please enter your username.");
            request.getRequestDispatcher(forgotJsp).forward(request, response);
            return;
        }

        username = username.trim();
        boolean exists = isOrganizer
                ? checkOrganizerExists(username)
                : checkUserExists(username);

        if (!exists) {
            request.setAttribute("error", "No " + (isOrganizer ? "organizer " : "") + "account found with that username.");
            request.setAttribute("username", username);
            request.getRequestDispatcher(forgotJsp).forward(request, response);
            return;
        }

        HttpSession session = request.getSession();
        session.setAttribute(sessionKey, username);
        response.sendRedirect(resetJsp);
    }

    // ── Reset: validate, update password, clear session ───────────────────────

    private void handleReset(HttpServletRequest request, HttpServletResponse response,
                              boolean isOrganizer) throws ServletException, IOException {

        String resetJsp   = isOrganizer ? "OrganizerResetPassword.jsp"  : "ResetPassword.jsp";
        String forgotJsp  = isOrganizer ? "OrganizerForgotPassword.jsp" : "ForgotPassword.jsp";
        String loginJsp   = isOrganizer ? "OrganizerLogin.jsp?resetSuccess=1" : "Login.jsp?resetSuccess=1";
        String sessionKey = isOrganizer ? "resetOrganizerUsername" : "resetUsername";

        HttpSession session = request.getSession();
        String username = (String) session.getAttribute(sessionKey);

        if (username == null) {
            // Session expired or direct access — restart flow
            response.sendRedirect(forgotJsp);
            return;
        }

        String newPassword     = request.getParameter("newPassword");
        String confirmPassword = request.getParameter("confirmPassword");

        if (newPassword == null || newPassword.trim().isEmpty()) {
            request.setAttribute("error", "Please enter a new password.");
            request.getRequestDispatcher(resetJsp).forward(request, response);
            return;
        }

        if (!newPassword.equals(confirmPassword)) {
            request.setAttribute("error", "Passwords do not match. Please try again.");
            request.getRequestDispatcher(resetJsp).forward(request, response);
            return;
        }

        if (newPassword.length() < 6) {
            request.setAttribute("error", "Password must be at least 6 characters.");
            request.getRequestDispatcher(resetJsp).forward(request, response);
            return;
        }

        boolean success = isOrganizer
                ? new OrganizerDAO().updatePassword(username, newPassword)
                : new UserDAO().updatePassword(username, newPassword);

        if (success) {
            session.removeAttribute(sessionKey);
            response.sendRedirect(loginJsp);
        } else {
            request.setAttribute("error", "Failed to reset password. Please try again.");
            request.getRequestDispatcher(resetJsp).forward(request, response);
        }
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

    private boolean checkUserExists(String username) {
        User user = new UserDAO().getUserByUsername(username);
        return user != null;
    }

    private boolean checkOrganizerExists(String username) {
        Organizer org = new OrganizerDAO().getOrganizerByUsername(username);
        return org != null;
    }
}