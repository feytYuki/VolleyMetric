package Model;

import java.sql.Date;
import java.sql.Time;
import java.sql.Timestamp;

/**
 * Tournament Model Class
 * Represents a tournament entity in the VolleyMetric system
 */
public class Tournament {
    
    // Private fields matching database columns
    private int tournamentId;
    private int organizerId;
    private String tournamentName;
    private Date tournamentDate;
    private Time startTime;
    private String location;
    private String category;        // men, women, mixed
    private String tournamentType;  // indoor, beach
    private int maxTeams;
    private int currentTeams;
    private String description;
    private String status;          // upcoming, ongoing, completed, cancelled
    private Timestamp createdAt;
    private Timestamp updatedAt;
    
    // Default Constructor
    public Tournament() {
        this.currentTeams = 0;
        this.status = "upcoming";
    }
    
    // Constructor for creating new tournament
    public Tournament(int organizerId, String tournamentName, Date tournamentDate, 
                     Time startTime, String location, String category, 
                     String tournamentType, int maxTeams, String description) {
        this.organizerId = organizerId;
        this.tournamentName = tournamentName;
        this.tournamentDate = tournamentDate;
        this.startTime = startTime;
        this.location = location;
        this.category = category;
        this.tournamentType = tournamentType;
        this.maxTeams = maxTeams;
        this.description = description;
        this.currentTeams = 0;
        this.status = "upcoming";
    }
    
    // Getters and Setters
    public int getTournamentId() {
        return tournamentId;
    }
    
    public void setTournamentId(int tournamentId) {
        this.tournamentId = tournamentId;
    }
    
    public int getOrganizerId() {
        return organizerId;
    }
    
    public void setOrganizerId(int organizerId) {
        this.organizerId = organizerId;
    }
    
    public String getTournamentName() {
        return tournamentName;
    }
    
    public void setTournamentName(String tournamentName) {
        this.tournamentName = tournamentName;
    }
    
    public Date getTournamentDate() {
        return tournamentDate;
    }
    
    public void setTournamentDate(Date tournamentDate) {
        this.tournamentDate = tournamentDate;
    }
    
    public Time getStartTime() {
        return startTime;
    }
    
    public void setStartTime(Time startTime) {
        this.startTime = startTime;
    }
    
    public String getLocation() {
        return location;
    }
    
    public void setLocation(String location) {
        this.location = location;
    }
    
    public String getCategory() {
        return category;
    }
    
    public void setCategory(String category) {
        this.category = category;
    }
    
    public String getTournamentType() {
        return tournamentType;
    }
    
    public void setTournamentType(String tournamentType) {
        this.tournamentType = tournamentType;
    }
    
    public int getMaxTeams() {
        return maxTeams;
    }
    
    public void setMaxTeams(int maxTeams) {
        this.maxTeams = maxTeams;
    }
    
    public int getCurrentTeams() {
        return currentTeams;
    }
    
    public void setCurrentTeams(int currentTeams) {
        this.currentTeams = currentTeams;
    }
    
    public String getDescription() {
        return description;
    }
    
    public void setDescription(String description) {
        this.description = description;
    }
    
    public String getStatus() {
        return status;
    }
    
    public void setStatus(String status) {
        this.status = status;
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
    
    // Utility methods
    public boolean isFull() {
        return currentTeams >= maxTeams;
    }
    
    public int getAvailableSlots() {
        return maxTeams - currentTeams;
    }
    
    public boolean isUpcoming() {
        return "upcoming".equalsIgnoreCase(this.status);
    }
    
    public boolean isOngoing() {
        return "ongoing".equalsIgnoreCase(this.status);
    }
    
    public boolean isCompleted() {
        return "completed".equalsIgnoreCase(this.status);
    }
    
    @Override
    public String toString() {
        return "Tournament{" +
                "tournamentId=" + tournamentId +
                ", organizerId=" + organizerId +
                ", tournamentName='" + tournamentName + '\'' +
                ", tournamentDate=" + tournamentDate +
                ", startTime=" + startTime +
                ", location='" + location + '\'' +
                ", category='" + category + '\'' +
                ", tournamentType='" + tournamentType + '\'' +
                ", maxTeams=" + maxTeams +
                ", currentTeams=" + currentTeams +
                ", status='" + status + '\'' +
                '}';
    }
}