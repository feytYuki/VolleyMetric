package DAO;

import DB.DBConnection;
import Model.TeamRegistration;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Team Registration Data Access Object
 * Handles all database operations related to Team Registration
 */
public class TeamRegistrationDAO {
    
    /**
     * Register a team for a tournament
     * @param registration TeamRegistration object
     * @return true if registration is successful, false otherwise
     */
    public boolean registerTeam(TeamRegistration registration) {
        String sql = "INSERT INTO team_registrations (tournament_id, user_id, team_name, " +
                    "team_leader_name, contact_phone, contact_email, number_of_players, status) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            
            pstmt.setInt(1, registration.getTournamentId());
            pstmt.setInt(2, registration.getUserId());
            pstmt.setString(3, registration.getTeamName());
            pstmt.setString(4, registration.getTeamLeaderName());
            pstmt.setString(5, registration.getContactPhone());
            pstmt.setString(6, registration.getContactEmail());
            pstmt.setInt(7, registration.getNumberOfPlayers());
            pstmt.setString(8, "pending");
            
            int rowsAffected = pstmt.executeUpdate();
            
            if (rowsAffected > 0) {
                ResultSet rs = pstmt.getGeneratedKeys();
                if (rs.next()) {
                    registration.setRegistrationId(rs.getInt(1));
                }
                System.out.println("Team registered successfully: " + registration.getTeamName());
                return true;
            }
            
        } catch (SQLException e) {
            System.err.println("Error registering team (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error registering team (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return false;
    }
    
    /**
     * Check if user already registered for a tournament
     * @param userId User ID
     * @param tournamentId Tournament ID
     * @return true if already registered, false otherwise
     */
    public boolean isUserRegistered(int userId, int tournamentId) {
        String sql = "SELECT COUNT(*) FROM team_registrations WHERE user_id = ? AND tournament_id = ?";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, userId);
            pstmt.setInt(2, tournamentId);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
            
        } catch (SQLException e) {
            System.err.println("Error checking registration (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error checking registration (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return false;
    }
    
    /**
     * Get all registrations for a tournament
     * @param tournamentId Tournament ID
     * @return List of team registrations
     */
    public List<TeamRegistration> getRegistrationsByTournament(int tournamentId) {
        List<TeamRegistration> registrations = new ArrayList<>();
        String sql = "SELECT * FROM team_registrations WHERE tournament_id = ? ORDER BY registered_at DESC";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, tournamentId);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                registrations.add(extractRegistrationFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting registrations (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error getting registrations (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return registrations;
    }
    
    /**
     * Get all registrations by user
     * @param userId User ID
     * @return List of team registrations
     */
    public List<TeamRegistration> getRegistrationsByUser(int userId) {
        List<TeamRegistration> registrations = new ArrayList<>();
        String sql = "SELECT * FROM team_registrations WHERE user_id = ? ORDER BY registered_at DESC";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, userId);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                registrations.add(extractRegistrationFromResultSet(rs));
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting user registrations (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error getting user registrations (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return registrations;
    }
    
    /**
     * Update registration status
     * @param registrationId Registration ID
     * @param status New status (pending, approved, rejected)
     * @return true if update is successful, false otherwise
     */
    public boolean updateRegistrationStatus(int registrationId, String status) {
        String sql = "UPDATE team_registrations SET status = ? WHERE registration_id = ?";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, status);
            pstmt.setInt(2, registrationId);
            
            int rowsAffected = pstmt.executeUpdate();
            return rowsAffected > 0;
            
        } catch (SQLException e) {
            System.err.println("Error updating registration status (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error updating registration status (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return false;
    }
    
    /**
     * Update team registration (team name and number of players)
     * @param registration TeamRegistration object with updated data
     * @return true if update is successful, false otherwise
     */
    public boolean updateTeamRegistration(TeamRegistration registration) {
        String sql = "UPDATE team_registrations SET team_name = ?, number_of_players = ? WHERE registration_id = ?";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, registration.getTeamName());
            pstmt.setInt(2, registration.getNumberOfPlayers());
            pstmt.setInt(3, registration.getRegistrationId());
            
            int rowsAffected = pstmt.executeUpdate();
            return rowsAffected > 0;
            
        } catch (SQLException e) {
            System.err.println("Error updating team registration (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error updating team registration (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return false;
    }
    
    /**
     * Get registration by ID
     * @param registrationId Registration ID
     * @return TeamRegistration object or null
     */
    public TeamRegistration getRegistrationById(int registrationId) {
        String sql = "SELECT * FROM team_registrations WHERE registration_id = ?";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, registrationId);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return extractRegistrationFromResultSet(rs);
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting registration by ID (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error getting registration by ID (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return null;
    }
    
    /**
     * Count approved registrations for a tournament
     * @param tournamentId Tournament ID
     * @return Number of approved registrations
     */
    public int countApprovedRegistrations(int tournamentId) {
        String sql = "SELECT COUNT(*) FROM team_registrations WHERE tournament_id = ? AND status = 'approved'";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, tournamentId);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1);
            }
            
        } catch (SQLException e) {
            System.err.println("Error counting approved registrations (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error counting approved registrations (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return 0;
    }
    
    /**
     * Check if a team name is already registered for a tournament
     * @param teamName Team name to check
     * @param tournamentId Tournament ID
     * @return true if name is already taken, false otherwise
     */
    public boolean isTeamNameTaken(String teamName, int tournamentId) {
        String sql = "SELECT COUNT(*) FROM team_registrations WHERE tournament_id = ? AND LOWER(team_name) = LOWER(?) AND status != 'rejected'";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, tournamentId);
            pstmt.setString(2, teamName);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
            
        } catch (SQLException e) {
            System.err.println("Error checking team name (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error checking team name (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return false;
    }
    
    /**
     * Extract TeamRegistration object from ResultSet
     * @param rs ResultSet
     * @return TeamRegistration object
     * @throws SQLException if database access error occurs
     */
    private TeamRegistration extractRegistrationFromResultSet(ResultSet rs) throws SQLException {
        TeamRegistration registration = new TeamRegistration();
        registration.setRegistrationId(rs.getInt("registration_id"));
        registration.setTournamentId(rs.getInt("tournament_id"));
        registration.setUserId(rs.getInt("user_id"));
        registration.setTeamName(rs.getString("team_name"));
        registration.setTeamLeaderName(rs.getString("team_leader_name"));
        registration.setContactPhone(rs.getString("contact_phone"));
        registration.setContactEmail(rs.getString("contact_email"));
        registration.setNumberOfPlayers(rs.getInt("number_of_players"));
        registration.setStatus(rs.getString("status"));
        registration.setRegisteredAt(rs.getTimestamp("registered_at"));
        return registration;
    }
    /**
 * Get all approved team registrations for a tournament
 * @param tournamentId Tournament ID
 * @return List of approved team registrations
 */
public List<TeamRegistration> getApprovedTeamsByTournament(int tournamentId) {
    List<TeamRegistration> registrations = new ArrayList<>();
    String sql = "SELECT * FROM team_registrations WHERE tournament_id = ? AND status = 'approved' ORDER BY registered_at";
    
    try (Connection conn = DBConnection.getConnection();
         PreparedStatement pstmt = conn.prepareStatement(sql)) {
        
        pstmt.setInt(1, tournamentId);
        ResultSet rs = pstmt.executeQuery();
        
        while (rs.next()) {
            registrations.add(extractRegistrationFromResultSet(rs));
        }
        
        System.out.println("Retrieved " + registrations.size() + " approved teams for tournament " + tournamentId);
        
    } catch (SQLException e) {
        System.err.println("Error getting approved teams (SQL): " + e.getMessage());
        e.printStackTrace();
    } catch (ClassNotFoundException e) {
        System.err.println("Error getting approved teams (Driver): " + e.getMessage());
        e.printStackTrace();
    }
    
    return registrations;
}
}