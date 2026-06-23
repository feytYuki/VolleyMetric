package Model;

import java.sql.Timestamp;

/**
 * User Model Class
 * Represents a user entity in the VolleyMetric system
 */
public class User {
    
    // Private fields matching database columns
    private int userId;
    private String fullname;
    private String username;
    private String email;
    private String phone;
    private String password;
    private Timestamp createdAt;
    private Timestamp updatedAt;
    private String status;
    
    // Default Constructor
    public User() {
    }
    
    // Constructor for registration (without ID and timestamps)
    public User(String fullname, String username, String email, String phone, String password) {
        this.fullname = fullname;
        this.username = username;
        this.email = email;
        this.phone = phone;
        this.password = password;
        this.status = "active";
    }
    
    // Constructor with all fields
    public User(int userId, String fullname, String username, String email, 
                String phone, String password, Timestamp createdAt, 
                Timestamp updatedAt, String status) {
        this.userId = userId;
        this.fullname = fullname;
        this.username = username;
        this.email = email;
        this.phone = phone;
        this.password = password;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
        this.status = status;
    }
    
    // Getters and Setters
    public int getUserId() {
        return userId;
    }
    
    public void setUserId(int userId) {
        this.userId = userId;
    }
    
    public String getFullname() {
        return fullname;
    }
    
    public void setFullname(String fullname) {
        this.fullname = fullname;
    }
    
    public String getUsername() {
        return username;
    }
    
    public void setUsername(String username) {
        this.username = username;
    }
    
    public String getEmail() {
        return email;
    }
    
    public void setEmail(String email) {
        this.email = email;
    }
    
    public String getPhone() {
        return phone;
    }
    
    public void setPhone(String phone) {
        this.phone = phone;
    }
    
    public String getPassword() {
        return password;
    }
    
    public void setPassword(String password) {
        this.password = password;
    }
    
    public Timestamp getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
    
    public Timestamp getUpdatedAt() {
        return updatedAt;
    }
    
    public void setUpdatedAt(Timestamp updatedAt) {
        this.updatedAt = updatedAt;
    }
    
    public String getStatus() {
        return status;
    }
    
    public void setStatus(String status) {
        this.status = status;
    }
    
    // toString method for debugging
    @Override
    public String toString() {
        return "User{" +
                "userId=" + userId +
                ", fullname='" + fullname + '\'' +
                ", username='" + username + '\'' +
                ", email='" + email + '\'' +
                ", phone='" + phone + '\'' +
                ", status='" + status + '\'' +
                ", createdAt=" + createdAt +
                '}';
    }
    
    // Utility method to check if user is active
    public boolean isActive() {
        return "active".equalsIgnoreCase(this.status);
    }
}
