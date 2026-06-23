package Model;

import java.sql.Timestamp;

/**
 * Team Registration Model Class
 * Represents a team registration for a tournament
 */
public class TeamRegistration {
    
    private int registrationId;
    private int tournamentId;
    private int userId;
    private String teamName;
    private String teamLeaderName;
    private String contactPhone;
    private String contactEmail;
    private int numberOfPlayers;
    private String status;  // pending, approved, rejected
    private Timestamp registeredAt;
    
    // Default Constructor
    public TeamRegistration() {
        this.status = "pending";
    }
    
    // Constructor for new registration
    public TeamRegistration(int tournamentId, int userId, String teamName, 
                           String teamLeaderName, String contactPhone, 
                           String contactEmail, int numberOfPlayers) {
        this.tournamentId = tournamentId;
        this.userId = userId;
        this.teamName = teamName;
        this.teamLeaderName = teamLeaderName;
        this.contactPhone = contactPhone;
        this.contactEmail = contactEmail;
        this.numberOfPlayers = numberOfPlayers;
        this.status = "pending";
    }
    
    // Getters and Setters
    public int getRegistrationId() {
        return registrationId;
    }
    
    public void setRegistrationId(int registrationId) {
        this.registrationId = registrationId;
    }
    
    public int getTournamentId() {
        return tournamentId;
    }
    
    public void setTournamentId(int tournamentId) {
        this.tournamentId = tournamentId;
    }
    
    public int getUserId() {
        return userId;
    }
    
    public void setUserId(int userId) {
        this.userId = userId;
    }
    
    public String getTeamName() {
        return teamName;
    }
    
    public void setTeamName(String teamName) {
        this.teamName = teamName;
    }
    
    public String getTeamLeaderName() {
        return teamLeaderName;
    }
    
    public void setTeamLeaderName(String teamLeaderName) {
        this.teamLeaderName = teamLeaderName;
    }
    
    public String getContactPhone() {
        return contactPhone;
    }
    
    public void setContactPhone(String contactPhone) {
        this.contactPhone = contactPhone;
    }
    
    public String getContactEmail() {
        return contactEmail;
    }
    
    public void setContactEmail(String contactEmail) {
        this.contactEmail = contactEmail;
    }
    
    public int getNumberOfPlayers() {
        return numberOfPlayers;
    }
    
    public void setNumberOfPlayers(int numberOfPlayers) {
        this.numberOfPlayers = numberOfPlayers;
    }
    
    public String getStatus() {
        return status;
    }
    
    public void setStatus(String status) {
        this.status = status;
    }
    
    public Timestamp getRegisteredAt() {
        return registeredAt;
    }
    
    public void setRegisteredAt(Timestamp registeredAt) {
        this.registeredAt = registeredAt;
    }
    
    // Utility methods
    public boolean isPending() {
        return "pending".equalsIgnoreCase(this.status);
    }
    
    public boolean isApproved() {
        return "approved".equalsIgnoreCase(this.status);
    }
    
    public boolean isRejected() {
        return "rejected".equalsIgnoreCase(this.status);
    }
    
    @Override
    public String toString() {
        return "TeamRegistration{" +
                "registrationId=" + registrationId +
                ", tournamentId=" + tournamentId +
                ", userId=" + userId +
                ", teamName='" + teamName + '\'' +
                ", teamLeaderName='" + teamLeaderName + '\'' +
                ", numberOfPlayers=" + numberOfPlayers +
                ", status='" + status + '\'' +
                '}';
    }
}