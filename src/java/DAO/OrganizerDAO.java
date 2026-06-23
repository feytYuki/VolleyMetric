package DAO;

import DB.DBConnection;
import Model.Organizer;

import java.sql.*;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/**
 * Organizer Data Access Object
 * Handles all database operations related to Organizer
 */
public class OrganizerDAO {
    
    /**
     * Register a new organizer
     * @param organizer Organizer object containing registration data
     * @return true if registration is successful, false otherwise
     */
    public boolean registerOrganizer(Organizer organizer) {
        String sql = "INSERT INTO organizers (fullname, username, email, phone, password, status) VALUES (?, ?, ?, ?, ?, ?)";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            // Hash the password before storing
            String hashedPassword = hashPassword(organizer.getPassword());
            
            pstmt.setString(1, organizer.getFullname());
            pstmt.setString(2, organizer.getUsername());
            pstmt.setString(3, organizer.getEmail());
            pstmt.setString(4, organizer.getPhone());
            pstmt.setString(5, hashedPassword);
            pstmt.setString(6, "active");
            
            int rowsAffected = pstmt.executeUpdate();
            
            if (rowsAffected > 0) {
                System.out.println("Organizer registered successfully: " + organizer.getUsername());
                return true;
            }
            
        } catch (SQLException e) {
            System.err.println("Error registering organizer (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error registering organizer (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return false;
    }
    
    /**
     * Check if username already exists
     * @param username Username to check
     * @return true if username exists, false otherwise
     */
    public boolean isUsernameExists(String username) {
        String sql = "SELECT COUNT(*) FROM organizers WHERE username = ?";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, username);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
            
        } catch (SQLException e) {
            System.err.println("Error checking username (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error checking username (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return false;
    }
    
    /**
     * Check if email already exists
     * @param email Email to check
     * @return true if email exists, false otherwise
     */
    public boolean isEmailExists(String email) {
        String sql = "SELECT COUNT(*) FROM organizers WHERE email = ?";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, email);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
            
        } catch (SQLException e) {
            System.err.println("Error checking email (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error checking email (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return false;
    }
    
    /**
     * Validate organizer login
     * @param username Username
     * @param password Password
     * @return Organizer object if credentials are valid, null otherwise
     */
    public Organizer validateOrganizer(String username, String password) {
        String sql = "SELECT * FROM organizers WHERE username = ? AND status = 'active'";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, username);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                String storedPassword = rs.getString("password");
                String hashedInputPassword = hashPassword(password);
                
                // Check if password matches
                if (storedPassword.equals(hashedInputPassword)) {
                    Organizer organizer = new Organizer();
                    organizer.setOrganizerId(rs.getInt("organizer_id"));
                    organizer.setFullname(rs.getString("fullname"));
                    organizer.setUsername(rs.getString("username"));
                    organizer.setEmail(rs.getString("email"));
                    organizer.setPhone(rs.getString("phone"));
                    organizer.setStatus(rs.getString("status"));
                    organizer.setCreatedAt(rs.getTimestamp("created_at"));
                    organizer.setUpdatedAt(rs.getTimestamp("updated_at"));
                    
                    System.out.println("Organizer validated successfully: " + username);
                    return organizer;
                }
            }
            
        } catch (SQLException e) {
            System.err.println("Error validating organizer (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error validating organizer (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return null;
    }
    
    /**
     * Get organizer by ID
     * @param organizerId Organizer ID
     * @return Organizer object if found, null otherwise
     */
    public Organizer getOrganizerById(int organizerId) {
        String sql = "SELECT * FROM organizers WHERE organizer_id = ?";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, organizerId);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                Organizer organizer = new Organizer();
                organizer.setOrganizerId(rs.getInt("organizer_id"));
                organizer.setFullname(rs.getString("fullname"));
                organizer.setUsername(rs.getString("username"));
                organizer.setEmail(rs.getString("email"));
                organizer.setPhone(rs.getString("phone"));
                organizer.setStatus(rs.getString("status"));
                organizer.setCreatedAt(rs.getTimestamp("created_at"));
                organizer.setUpdatedAt(rs.getTimestamp("updated_at"));
                
                return organizer;
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting organizer by ID (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error getting organizer by ID (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return null;
    }
    
    /**
     * Update organizer profile
     * @param organizer Organizer object with updated data
     * @return true if update is successful, false otherwise
     */
    public boolean updateOrganizer(Organizer organizer) {
        String sql = "UPDATE organizers SET fullname = ?, email = ?, phone = ? WHERE organizer_id = ?";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, organizer.getFullname());
            pstmt.setString(2, organizer.getEmail());
            pstmt.setString(3, organizer.getPhone());
            pstmt.setInt(4, organizer.getOrganizerId());
            
            int rowsAffected = pstmt.executeUpdate();
            return rowsAffected > 0;
            
        } catch (SQLException e) {
            System.err.println("Error updating organizer (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error updating organizer (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return false;
    }
    
    /**
     * Change organizer password
     * @param organizerId Organizer ID
     * @param oldPassword Old password
     * @param newPassword New password
     * @return true if password change is successful, false otherwise
     */
    public boolean changePassword(int organizerId, String oldPassword, String newPassword) {
        String selectSql = "SELECT password FROM organizers WHERE organizer_id = ?";
        String updateSql = "UPDATE organizers SET password = ? WHERE organizer_id = ?";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement selectStmt = conn.prepareStatement(selectSql)) {
            
            // Verify old password
            selectStmt.setInt(1, organizerId);
            ResultSet rs = selectStmt.executeQuery();
            
            if (rs.next()) {
                String storedPassword = rs.getString("password");
                String hashedOldPassword = hashPassword(oldPassword);
                
                if (storedPassword.equals(hashedOldPassword)) {
                    // Old password is correct, update to new password
                    try (PreparedStatement updateStmt = conn.prepareStatement(updateSql)) {
                        String hashedNewPassword = hashPassword(newPassword);
                        updateStmt.setString(1, hashedNewPassword);
                        updateStmt.setInt(2, organizerId);
                        
                        int rowsAffected = updateStmt.executeUpdate();
                        return rowsAffected > 0;
                    }
                }
            }
            
        } catch (SQLException e) {
            System.err.println("Error changing password (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error changing password (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return false;
    }
    
    /**
     * Deactivate organizer account
     * @param organizerId Organizer ID
     * @return true if deactivation is successful, false otherwise
     */
    public boolean deactivateOrganizer(int organizerId) {
        String sql = "UPDATE organizers SET status = 'inactive' WHERE organizer_id = ?";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, organizerId);
            int rowsAffected = pstmt.executeUpdate();
            return rowsAffected > 0;
            
        } catch (SQLException e) {
            System.err.println("Error deactivating organizer (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error deactivating organizer (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return false;
    }
    
    /**
     * Get organizer by username
     * @param username Organizer username
     * @return Organizer object if found, null otherwise
     */
    public Organizer getOrganizerByUsername(String username) {
        String sql = "SELECT * FROM organizers WHERE username = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, username);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                Organizer organizer = new Organizer();
                organizer.setOrganizerId(rs.getInt("organizer_id"));
                organizer.setFullname(rs.getString("fullname"));
                organizer.setUsername(rs.getString("username"));
                organizer.setEmail(rs.getString("email"));
                organizer.setPhone(rs.getString("phone"));
                organizer.setStatus(rs.getString("status"));
                return organizer;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    /**
     * Update organizer password by username (for forgot password reset)
     * @param username Organizer username
     * @param newPassword New plain text password
     * @return true if update successful
     */
    public boolean updatePassword(String username, String newPassword) {
        String sql = "UPDATE organizers SET password = ? WHERE username = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, hashPassword(newPassword));
            pstmt.setString(2, username);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("Error updating organizer password (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error updating organizer password (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }

    /**
     * Hash password using SHA-256
     * @param password Plain text password
     * @return Hashed password
     */
    private String hashPassword(String password) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hashedBytes = md.digest(password.getBytes());
            
            // Convert bytes to hexadecimal format
            StringBuilder sb = new StringBuilder();
            for (byte b : hashedBytes) {
                sb.append(String.format("%02x", b));
            }
            
            return sb.toString();
            
        } catch (NoSuchAlgorithmException e) {
            System.err.println("Error hashing password: " + e.getMessage());
            e.printStackTrace();
            return password; // Return plain password as fallback (not recommended for production)
        }
    }
}