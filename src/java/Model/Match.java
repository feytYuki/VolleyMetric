package Model;

import java.sql.Timestamp;

public class Match {
    private int matchId;
    private int tournamentId;
    private String groupName;
    private int team1Id;
    private int team2Id;
    private Integer winnerId;
    
    // NEW FIELD ADDED
    private String matchType; // 'group' or 'bracket'

    private Integer team1Set1;
    private Integer team1Set2;
    private Integer team1Set3;
    private Integer team1Set4;
    private Integer team1Set5;
    private Integer team2Set1;
    private Integer team2Set2;
    private Integer team2Set3;
    private Integer team2Set4;
    private Integer team2Set5;
    private String status; // pending, completed
    private Timestamp createdAt;
    
    // Constructors
    public Match() {
    }
    
    public Match(int tournamentId, String groupName, int team1Id, int team2Id) {
        this.tournamentId = tournamentId;
        this.groupName = groupName;
        this.team1Id = team1Id;
        this.team2Id = team2Id;
        this.status = "pending";
        this.matchType = "group"; // Default to group
    }
    
    // Getters and Setters
    public int getMatchId() {
        return matchId;
    }
    
    public void setMatchId(int matchId) {
        this.matchId = matchId;
    }
    
    public int getTournamentId() {
        return tournamentId;
    }
    
    public void setTournamentId(int tournamentId) {
        this.tournamentId = tournamentId;
    }
    
    public String getGroupName() {
        return groupName;
    }
    
    public void setGroupName(String groupName) {
        this.groupName = groupName;
    }
    
    // NEW GETTER AND SETTER FOR MATCH TYPE
    public String getMatchType() {
        return matchType;
    }

    public void setMatchType(String matchType) {
        this.matchType = matchType;
    }

    public int getTeam1Id() {
        return team1Id;
    }
    
    public void setTeam1Id(int team1Id) {
        this.team1Id = team1Id;
    }
    
    public int getTeam2Id() {
        return team2Id;
    }
    
    public void setTeam2Id(int team2Id) {
        this.team2Id = team2Id;
    }
    
    public Integer getWinnerId() {
        return winnerId;
    }
    
    public void setWinnerId(Integer winnerId) {
        this.winnerId = winnerId;
    }
    
    public Integer getTeam1Set1() {
        return team1Set1;
    }
    
    public void setTeam1Set1(Integer team1Set1) {
        this.team1Set1 = team1Set1;
    }
    
    public Integer getTeam1Set2() {
        return team1Set2;
    }
    
    public void setTeam1Set2(Integer team1Set2) {
        this.team1Set2 = team1Set2;
    }
    
    public Integer getTeam1Set3() {
        return team1Set3;
    }
    
    public void setTeam1Set3(Integer team1Set3) {
        this.team1Set3 = team1Set3;
    }
    
    public Integer getTeam1Set4() {
        return team1Set4;
    }
    
    public void setTeam1Set4(Integer team1Set4) {
        this.team1Set4 = team1Set4;
    }
    
    public Integer getTeam1Set5() {
        return team1Set5;
    }
    
    public void setTeam1Set5(Integer team1Set5) {
        this.team1Set5 = team1Set5;
    }
    
    public Integer getTeam2Set1() {
        return team2Set1;
    }
    
    public void setTeam2Set1(Integer team2Set1) {
        this.team2Set1 = team2Set1;
    }
    
    public Integer getTeam2Set2() {
        return team2Set2;
    }
    
    public void setTeam2Set2(Integer team2Set2) {
        this.team2Set2 = team2Set2;
    }
    
    public Integer getTeam2Set3() {
        return team2Set3;
    }
    
    public void setTeam2Set3(Integer team2Set3) {
        this.team2Set3 = team2Set3;
    }
    
    public Integer getTeam2Set4() {
        return team2Set4;
    }
    
    public void setTeam2Set4(Integer team2Set4) {
        this.team2Set4 = team2Set4;
    }
    
    public Integer getTeam2Set5() {
        return team2Set5;
    }
    
    public void setTeam2Set5(Integer team2Set5) {
        this.team2Set5 = team2Set5;
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
    
    // Helper method to get set score
    public Integer getSetScore(int team, int setNumber) {
        if (team == 1) {
            switch (setNumber) {
                case 1: return team1Set1;
                case 2: return team1Set2;
                case 3: return team1Set3;
                case 4: return team1Set4;
                case 5: return team1Set5;
            }
        } else if (team == 2) {
            switch (setNumber) {
                case 1: return team2Set1;
                case 2: return team2Set2;
                case 3: return team2Set3;
                case 4: return team2Set4;
                case 5: return team2Set5;
            }
        }
        return null;
    }
}