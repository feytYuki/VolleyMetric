package Controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

public class StartTournamentServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    // Database connection details
    private static final String DB_URL = "jdbc:mysql://localhost:3306/volleymetric";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "";
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        System.out.println("=== StartTournamentServlet: doPost called ===");
        
        HttpSession session = request.getSession(false);
        
        // Check if organizer is logged in
        if (session == null || session.getAttribute("organizerId") == null) {
            System.out.println("ERROR: No session or organizerId not found");
            response.sendRedirect("OrganizerLogin.jsp");
            return;
        }
        
        Integer organizerId = (Integer) session.getAttribute("organizerId");
        System.out.println("Organizer ID: " + organizerId);
        
        String tournamentIdStr = request.getParameter("tournamentId");
        System.out.println("Tournament ID parameter: " + tournamentIdStr);
        
        if (tournamentIdStr == null || tournamentIdStr.isEmpty()) {
            System.out.println("ERROR: tournamentId is null or empty");
            response.sendRedirect("OrganizerTournament.jsp");
            return;
        }
        
        int tournamentId = Integer.parseInt(tournamentIdStr);
        System.out.println("Parsed Tournament ID: " + tournamentId);
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            System.out.println("Loading MySQL driver...");
            Class.forName("com.mysql.cj.jdbc.Driver");
            
            System.out.println("Connecting to database...");
            conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            System.out.println("Database connected successfully!");
            
            // Update tournament status to 'ongoing'
            String sql = "UPDATE tournaments SET status = 'ongoing', updated_at = NOW() " +
                        "WHERE tournament_id = ? AND organizer_id = ? AND status = 'upcoming'";
            
            System.out.println("Preparing SQL: " + sql);
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, tournamentId);
            pstmt.setInt(2, organizerId);
            
            System.out.println("Executing update...");
            int rowsUpdated = pstmt.executeUpdate();
            System.out.println("Rows updated: " + rowsUpdated);
            
            if (rowsUpdated > 0) {
                System.out.println("SUCCESS: Tournament started!");
                session.setAttribute("successMessage", "Tournament started successfully!");
                response.sendRedirect("OrganizerSchedule.jsp");
            } else {
                System.out.println("WARNING: No rows updated - tournament may not exist or not in 'upcoming' status");
                session.setAttribute("errorMessage", "Unable to start tournament. It may already be ongoing or completed.");
                response.sendRedirect("OrganizerViewDetail.jsp?id=" + tournamentId);
            }
            
        } catch (ClassNotFoundException e) {
            System.err.println("ERROR: Database driver not found!");
            e.printStackTrace();
            session.setAttribute("errorMessage", "Database driver error occurred.");
            response.sendRedirect("OrganizerViewDetail.jsp?id=" + tournamentId);
        } catch (SQLException e) {
            System.err.println("ERROR: SQL Exception occurred!");
            e.printStackTrace();
            session.setAttribute("errorMessage", "Database error occurred while starting tournament.");
            response.sendRedirect("OrganizerViewDetail.jsp?id=" + tournamentId);
        } catch (Exception e) {
            System.err.println("ERROR: Unexpected exception!");
            e.printStackTrace();
            session.setAttribute("errorMessage", "An error occurred. Please try again.");
            response.sendRedirect("OrganizerViewDetail.jsp?id=" + tournamentId);
        } finally {
            try {
                if (pstmt != null) {
                    pstmt.close();
                    System.out.println("PreparedStatement closed");
                }
                if (conn != null) {
                    conn.close();
                    System.out.println("Connection closed");
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
        
        System.out.println("=== StartTournamentServlet: doPost finished ===");
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        System.out.println("=== StartTournamentServlet: doGet called (redirecting to doPost) ===");
        doPost(request, response);
    }
}