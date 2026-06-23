package DAO;

import DB.DBConnection;
import Model.User;

import java.sql.*;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/**
 * User Data Access Object Handles all database operations related to User
 */
public class UserDAO {

    /**
     * Register a new user
     *
     * @param user User object containing registration data
     * @return true if registration is successful, false otherwise
     */
    public boolean registerUser(User user) {
        String sql = "INSERT INTO users (fullname, username, email, phone, password, status) VALUES (?, ?, ?, ?, ?, ?)";

        try (Connection conn = DBConnection.getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {

            // Hash the password before storing
            String hashedPassword = hashPassword(user.getPassword());

            pstmt.setString(1, user.getFullname());
            pstmt.setString(2, user.getUsername());
            pstmt.setString(3, user.getEmail());
            pstmt.setString(4, user.getPhone());
            pstmt.setString(5, hashedPassword);
            pstmt.setString(6, "active");

            int rowsAffected = pstmt.executeUpdate();

            if (rowsAffected > 0) {
                System.out.println("User registered successfully: " + user.getUsername());
                return true;
            }

        } catch (SQLException e) {
            System.err.println("Error registering user (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error registering user (Driver): " + e.getMessage());
            e.printStackTrace();
        }

        return false;
    }

    /**
     * Check if username already exists
     *
     * @param username Username to check
     * @return true if username exists, false otherwise
     */
    public boolean isUsernameExists(String username) {
        String sql = "SELECT COUNT(*) FROM users WHERE username = ?";

        try (Connection conn = DBConnection.getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {

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
     *
     * @param email Email to check
     * @return true if email exists, false otherwise
     */
    public boolean isEmailExists(String email) {
        String sql = "SELECT COUNT(*) FROM users WHERE email = ?";

        try (Connection conn = DBConnection.getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {

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
     * Validate user login
     *
     * @param username Username
     * @param password Password
     * @return User object if credentials are valid, null otherwise
     */
    public User validateUser(String username, String password) {
        String sql = "SELECT * FROM users WHERE username = ? AND status = 'active'";

        try (Connection conn = DBConnection.getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, username);
            ResultSet rs = pstmt.executeQuery();

            if (rs.next()) {
                String storedPassword = rs.getString("password");
                String hashedInputPassword = hashPassword(password);

                // Check if password matches
                if (storedPassword.equals(hashedInputPassword)) {
                    User user = new User();
                    user.setUserId(rs.getInt("user_id"));
                    user.setFullname(rs.getString("fullname"));
                    user.setUsername(rs.getString("username"));
                    user.setEmail(rs.getString("email"));
                    user.setPhone(rs.getString("phone"));
                    user.setStatus(rs.getString("status"));
                    user.setCreatedAt(rs.getTimestamp("created_at"));
                    user.setUpdatedAt(rs.getTimestamp("updated_at"));

                    System.out.println("User validated successfully: " + username);
                    return user;
                }
            }

        } catch (SQLException e) {
            System.err.println("Error validating user (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error validating user (Driver): " + e.getMessage());
            e.printStackTrace();
        }

        return null;
    }

    /**
     * Get user by ID
     *
     * @param userId User ID
     * @return User object if found, null otherwise
     */
    public User getUserById(int userId) {
        String sql = "SELECT * FROM users WHERE user_id = ?";

        try (Connection conn = DBConnection.getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, userId);
            ResultSet rs = pstmt.executeQuery();

            if (rs.next()) {
                User user = new User();
                user.setUserId(rs.getInt("user_id"));
                user.setFullname(rs.getString("fullname"));
                user.setUsername(rs.getString("username"));
                user.setEmail(rs.getString("email"));
                user.setPhone(rs.getString("phone"));
                user.setStatus(rs.getString("status"));
                user.setCreatedAt(rs.getTimestamp("created_at"));
                user.setUpdatedAt(rs.getTimestamp("updated_at"));

                return user;
            }

        } catch (SQLException e) {
            System.err.println("Error getting user by ID (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error getting user by ID (Driver): " + e.getMessage());
            e.printStackTrace();
        }

        return null;
    }

    /**
     * Update user profile
     *
     * @param user User object with updated data
     * @return true if update is successful, false otherwise
     */
    public boolean updateUser(User user) {
        String sql = "UPDATE users SET fullname = ?, email = ?, phone = ? WHERE user_id = ?";

        try (Connection conn = DBConnection.getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, user.getFullname());
            pstmt.setString(2, user.getEmail());
            pstmt.setString(3, user.getPhone());
            pstmt.setInt(4, user.getUserId());

            int rowsAffected = pstmt.executeUpdate();
            return rowsAffected > 0;

        } catch (SQLException e) {
            System.err.println("Error updating user (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error updating user (Driver): " + e.getMessage());
            e.printStackTrace();
        }

        return false;
    }

    /**
     * Hash password using SHA-256
     *
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

    public User getUserByUsername(String username) {
        String sql = "SELECT * FROM users WHERE username = ?";
        try (Connection conn = DBConnection.getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, username);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                User user = new User();
                user.setUserId(rs.getInt("user_id"));
                user.setFullname(rs.getString("fullname"));
                user.setUsername(rs.getString("username"));
                user.setEmail(rs.getString("email"));
                user.setPhone(rs.getString("phone"));
                user.setStatus(rs.getString("status"));
                return user;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public boolean updatePassword(String username, String newPassword) {
        String sql = "UPDATE users SET password = ? WHERE username = ?";
        try (Connection conn = DBConnection.getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, hashPassword(newPassword));
            pstmt.setString(2, username);

            return pstmt.executeUpdate() > 0;

        } catch (SQLException e) {
            System.err.println("Error updating password (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error updating password (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }
}
