package Controller;

import DAO.OrganizerDAO;
import Model.Organizer;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

public class UpdateOrganizerProfile extends HttpServlet {

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

        String fullname = request.getParameter("fullname");
        String email    = request.getParameter("email");
        String phone    = request.getParameter("phone");

        if (fullname == null || fullname.trim().isEmpty() ||
            email    == null || email.trim().isEmpty()) {
            request.setAttribute("errorMessage", "Full name and email are required.");
            request.getRequestDispatcher("OrganizerEditProfile.jsp").forward(request, response);
            return;
        }

        Organizer organizer = organizerDAO.getOrganizerById(organizerId);
        if (organizer == null) {
            request.setAttribute("errorMessage", "Organizer not found.");
            request.getRequestDispatcher("OrganizerEditProfile.jsp").forward(request, response);
            return;
        }

        organizer.setFullname(fullname.trim());
        organizer.setEmail(email.trim());
        organizer.setPhone(phone != null ? phone.trim() : "");

        boolean updated = organizerDAO.updateOrganizer(organizer);

        if (updated) {
            session.setAttribute("organizerFullname", fullname.trim());
            session.setAttribute("profileSuccess", "Profile updated successfully!");
            response.sendRedirect("OrganizerProfile.jsp");
        } else {
            request.setAttribute("errorMessage", "Update failed. Please try again.");
            request.getRequestDispatcher("OrganizerEditProfile.jsp").forward(request, response);
        }
    }
}