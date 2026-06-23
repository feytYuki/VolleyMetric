package Model;

public class TournamentGroup {
    private int groupId;
    private int tournamentId;
    private String groupName; // A, B, C, D
    private int registrationId;
    
    // Constructors
    public TournamentGroup() {
    }
    
    public TournamentGroup(int tournamentId, String groupName, int registrationId) {
        this.tournamentId = tournamentId;
        this.groupName = groupName;
        this.registrationId = registrationId;
    }
    
    // Getters and Setters
    public int getGroupId() {
        return groupId;
    }
    
    public void setGroupId(int groupId) {
        this.groupId = groupId;
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
    
    public int getRegistrationId() {
        return registrationId;
    }
    
    public void setRegistrationId(int registrationId) {
        this.registrationId = registrationId;
    }
}