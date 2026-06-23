package DAO;

import DB.DBConnection;
import Model.TeamMember;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Team Member Data Access Object
 * Handles all database operations related to Team Members
 */
public class TeamMemberDAO {
    
    /**
     * Add a team member
     * @param member TeamMember object
     * @return true if successful, false otherwise
     */
    public boolean addTeamMember(TeamMember member) {
        String sql = "INSERT INTO team_members (registration_id, member_name, position, jersey_number, is_captain) VALUES (?, ?, ?, ?, ?)";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, member.getRegistrationId());
            pstmt.setString(2, member.getMemberName());
            pstmt.setString(3, member.getPosition());
            pstmt.setInt(4, member.getJerseyNumber());
            pstmt.setBoolean(5, member.isCaptain());
            
            int rowsAffected = pstmt.executeUpdate();
            return rowsAffected > 0;
            
        } catch (SQLException e) {
            System.err.println("Error adding team member (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error adding team member (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return false;
    }
    
    /**
     * Get all members of a team registration
     * @param registrationId Registration ID
     * @return List of team members
     */
    public List<TeamMember> getMembersByRegistrationId(int registrationId) {
        List<TeamMember> members = new ArrayList<>();
        String sql = "SELECT * FROM team_members WHERE registration_id = ? ORDER BY is_captain DESC, member_id ASC";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, registrationId);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                TeamMember member = new TeamMember();
                member.setMemberId(rs.getInt("member_id"));
                member.setRegistrationId(rs.getInt("registration_id"));
                member.setMemberName(rs.getString("member_name"));
                member.setPosition(rs.getString("position"));
                member.setJerseyNumber(rs.getInt("jersey_number"));
                member.setIsCaptain(rs.getBoolean("is_captain"));
                members.add(member);
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting team members (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error getting team members (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return members;
    }
    
    /**
     * Delete all members of a registration
     * @param registrationId Registration ID
     * @return true if successful, false otherwise
     */
    public boolean deleteMembersByRegistrationId(int registrationId) {
        String sql = "DELETE FROM team_members WHERE registration_id = ?";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, registrationId);
            pstmt.executeUpdate();
            return true;
            
        } catch (SQLException e) {
            System.err.println("Error deleting team members (SQL): " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            System.err.println("Error deleting team members (Driver): " + e.getMessage());
            e.printStackTrace();
        }
        
        return false;
    }
}