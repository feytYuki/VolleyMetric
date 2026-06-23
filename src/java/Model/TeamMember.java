package Model;

/**
 * Team Member Model Class
 * Represents a member of a registered team
 */
public class TeamMember {
    
    private int memberId;
    private int registrationId;
    private String memberName;
    private String position;
    private int jerseyNumber;
    private boolean isCaptain;
    
    // Default Constructor
    public TeamMember() {
        this.isCaptain = false;
    }
    
    // Constructor
    public TeamMember(int registrationId, String memberName, String position, 
                     int jerseyNumber, boolean isCaptain) {
        this.registrationId = registrationId;
        this.memberName = memberName;
        this.position = position;
        this.jerseyNumber = jerseyNumber;
        this.isCaptain = isCaptain;
    }
    
    // Getters and Setters
    public int getMemberId() {
        return memberId;
    }
    
    public void setMemberId(int memberId) {
        this.memberId = memberId;
    }
    
    public int getRegistrationId() {
        return registrationId;
    }
    
    public void setRegistrationId(int registrationId) {
        this.registrationId = registrationId;
    }
    
    public String getMemberName() {
        return memberName;
    }
    
    public void setMemberName(String memberName) {
        this.memberName = memberName;
    }
    
    public String getPosition() {
        return position;
    }
    
    public void setPosition(String position) {
        this.position = position;
    }
    
    public int getJerseyNumber() {
        return jerseyNumber;
    }
    
    public void setJerseyNumber(int jerseyNumber) {
        this.jerseyNumber = jerseyNumber;
    }
    
    public boolean isCaptain() {
        return isCaptain;
    }
    
    public void setIsCaptain(boolean isCaptain) {
        this.isCaptain = isCaptain;
    }
    
    @Override
    public String toString() {
        return "TeamMember{" +
                "memberId=" + memberId +
                ", memberName='" + memberName + '\'' +
                ", position='" + position + '\'' +
                ", jerseyNumber=" + jerseyNumber +
                ", isCaptain=" + isCaptain +
                '}';
    }
}