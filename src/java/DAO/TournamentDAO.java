package DAO;

import DB.DBConnection;
import Model.Tournament;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Tournament Data Access Object
 * Handles all database operations related to Tournament
 */
public class TournamentDAO {
    
    /**
     * Auto-update tournaments to 'completed' if their date has passed
     * and their current status is 'upcoming' or 'ongoing'.
     * This supports date-based auto-detection; admin can still manually override.
     * @return number of tournaments updated
     */
    public int autoUpdateCompletedStatus() {
        // Mark as completed if tournament_date < today AND status is not already completed/cancelled
        String sql = "UPDATE tournaments SET status = 'completed' " +
                     "WHERE tournament_date < CURDATE() " +
                     "AND status NOT IN ('completed', 'cancelled')";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            int rowsUpdated = pstmt.executeUpdate();
            if (rowsUpdated > 0) {
                System.out.println("Auto-completed " + rowsUpdated + " tournament(s) based on date.");
            }
            return rowsUpdated;

        } catch (SQLException e) {
            System.err.println("Error auto-updating completed status (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error auto-updating completed status (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        return 0;
    }

    /**
     * Create a new tournament
     * @param tournament Tournament object containing tournament data
     * @return true if creation is successful, false otherwise
     */
    public boolean createTournament(Tournament tournament) {
        String sql = "INSERT INTO tournaments (organizer_id, tournament_name, tournament_date, " +
                    "start_time, location, category, tournament_type, max_teams, description, " +
                    "current_teams, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            
            pstmt.setInt(1, tournament.getOrganizerId());
            pstmt.setString(2, tournament.getTournamentName());
            pstmt.setDate(3, tournament.getTournamentDate());
            pstmt.setTime(4, tournament.getStartTime());
            pstmt.setString(5, tournament.getLocation());
            pstmt.setString(6, tournament.getCategory());
            pstmt.setString(7, tournament.getTournamentType());
            pstmt.setInt(8, tournament.getMaxTeams());
            pstmt.setString(9, tournament.getDescription());
            pstmt.setInt(10, 0); // current_teams starts at 0
            pstmt.setString(11, "upcoming"); // default status
            
            int rowsAffected = pstmt.executeUpdate();
            
            if (rowsAffected > 0) {
                ResultSet rs = pstmt.getGeneratedKeys();
                if (rs.next()) {
                    tournament.setTournamentId(rs.getInt(1));
                }
                System.out.println("Tournament created successfully: " + tournament.getTournamentName());
                return true;
            }
            
        } catch (SQLException e) {
            System.err.println("Error creating tournament (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error creating tournament (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return false;
    }
    
    /**
     * Get tournament by ID
     * @param tournamentId Tournament ID
     * @return Tournament object if found, null otherwise
     */
    public Tournament getTournamentById(int tournamentId) {
        String sql = "SELECT * FROM tournaments WHERE tournament_id = ?";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, tournamentId);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return extractTournamentFromResultSet(rs);
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting tournament by ID (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error getting tournament by ID (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return null;
    }
    
    /**
     * Get all tournaments by organizer ID
     * @param organizerId Organizer ID
     * @return List of tournaments
     */
    public List<Tournament> getTournamentsByOrganizerId(int organizerId) {
        List<Tournament> tournaments = new ArrayList<>();
        String sql = "SELECT * FROM tournaments WHERE organizer_id = ? ORDER BY tournament_date DESC";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, organizerId);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                tournaments.add(extractTournamentFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting tournaments by organizer (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error getting tournaments by organizer (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return tournaments;
    }
    
    /**
     * Get all tournaments
     * @return List of all tournaments
     */
    public List<Tournament> getAllTournaments() {
        List<Tournament> tournaments = new ArrayList<>();
        String sql = "SELECT * FROM tournaments ORDER BY tournament_date DESC";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                tournaments.add(extractTournamentFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting all tournaments (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error getting all tournaments (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return tournaments;
    }
    
    /**
     * Get tournaments by status
     * @param status Tournament status (upcoming, ongoing, completed, cancelled)
     * @return List of tournaments with the specified status
     */
    public List<Tournament> getTournamentsByStatus(String status) {
        List<Tournament> tournaments = new ArrayList<>();
        String sql = "SELECT * FROM tournaments WHERE status = ? ORDER BY tournament_date DESC";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, status);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                tournaments.add(extractTournamentFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting tournaments by status (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error getting tournaments by status (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return tournaments;
    }
    
    /**
     * Update tournament
     * @param tournament Tournament object with updated data
     * @return true if update is successful, false otherwise
     */
    public boolean updateTournament(Tournament tournament) {
        String sql = "UPDATE tournaments SET tournament_name = ?, tournament_date = ?, " +
                    "start_time = ?, location = ?, category = ?, tournament_type = ?, " +
                    "max_teams = ?, description = ?, status = ? WHERE tournament_id = ?";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, tournament.getTournamentName());
            pstmt.setDate(2, tournament.getTournamentDate());
            pstmt.setTime(3, tournament.getStartTime());
            pstmt.setString(4, tournament.getLocation());
            pstmt.setString(5, tournament.getCategory());
            pstmt.setString(6, tournament.getTournamentType());
            pstmt.setInt(7, tournament.getMaxTeams());
            pstmt.setString(8, tournament.getDescription());
            pstmt.setString(9, tournament.getStatus());
            pstmt.setInt(10, tournament.getTournamentId());
            
            int rowsAffected = pstmt.executeUpdate();
            return rowsAffected > 0;
            
        } catch (SQLException e) {
            System.err.println("Error updating tournament (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error updating tournament (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return false;
    }
    
    /**
     * Update tournament status
     * @param tournamentId Tournament ID
     * @param status New status
     * @return true if update is successful, false otherwise
     */
    public boolean updateTournamentStatus(int tournamentId, String status) {
        String sql = "UPDATE tournaments SET status = ? WHERE tournament_id = ?";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, status);
            pstmt.setInt(2, tournamentId);
            
            int rowsAffected = pstmt.executeUpdate();
            return rowsAffected > 0;
            
        } catch (SQLException e) {
            System.err.println("Error updating tournament status (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error updating tournament status (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return false;
    }
    
    /**
     * Increment current teams count
     * @param tournamentId Tournament ID
     * @return true if update is successful, false otherwise
     */
    public boolean incrementCurrentTeams(int tournamentId) {
        String sql = "UPDATE tournaments SET current_teams = current_teams + 1 WHERE tournament_id = ?";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, tournamentId);
            int rowsAffected = pstmt.executeUpdate();
            return rowsAffected > 0;
            
        } catch (SQLException e) {
            System.err.println("Error incrementing current teams (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error incrementing current teams (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return false;
    }
    
    /**
     * Delete tournament
     * @param tournamentId Tournament ID
     * @return true if deletion is successful, false otherwise
     */
    public boolean deleteTournament(int tournamentId) {
        String sql = "DELETE FROM tournaments WHERE tournament_id = ?";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, tournamentId);
            int rowsAffected = pstmt.executeUpdate();
            return rowsAffected > 0;
            
        } catch (SQLException e) {
            System.err.println("Error deleting tournament (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error deleting tournament (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return false;
    }
    
    /**
     * Extract Tournament object from ResultSet
     * @param rs ResultSet
     * @return Tournament object
     * @throws SQLException if database access error occurs
     */
    private Tournament extractTournamentFromResultSet(ResultSet rs) throws SQLException {
        Tournament tournament = new Tournament();
        tournament.setTournamentId(rs.getInt("tournament_id"));
        tournament.setOrganizerId(rs.getInt("organizer_id"));
        tournament.setTournamentName(rs.getString("tournament_name"));
        tournament.setTournamentDate(rs.getDate("tournament_date"));
        tournament.setStartTime(rs.getTime("start_time"));
        tournament.setLocation(rs.getString("location"));
        tournament.setCategory(rs.getString("category"));
        tournament.setTournamentType(rs.getString("tournament_type"));
        tournament.setMaxTeams(rs.getInt("max_teams"));
        tournament.setCurrentTeams(rs.getInt("current_teams"));
        tournament.setDescription(rs.getString("description"));
        tournament.setStatus(rs.getString("status"));
        tournament.setCreatedAt(rs.getTimestamp("created_at"));
        tournament.setUpdatedAt(rs.getTimestamp("updated_at"));
        return tournament;
    }
}