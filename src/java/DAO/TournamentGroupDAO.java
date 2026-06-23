package DAO;

import Model.TournamentGroup;
import Model.TeamRegistration;
import DB.DBConnection;
import java.sql.*;
import java.util.*;

public class TournamentGroupDAO {
    
    public boolean createGroup(TournamentGroup group) {
        String sql = "INSERT INTO tournament_groups (tournament_id, group_name, registration_id) VALUES (?, ?, ?)";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, group.getTournamentId());
            pstmt.setString(2, group.getGroupName());
            pstmt.setInt(3, group.getRegistrationId());
            
            int rowsAffected = pstmt.executeUpdate();
            if (rowsAffected > 0) {
                return true;
            }
        } catch (SQLException | ClassNotFoundException e) {
            System.err.println("Error creating tournament group: " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }
    
    public Map<String, List<TeamRegistration>> getGroupsWithTeams(int tournamentId) {
        Map<String, List<TeamRegistration>> groups = new LinkedHashMap<>();
        String sql = "SELECT tg.group_name, tr.* " +
                     "FROM tournament_groups tg " +
                     "JOIN team_registrations tr ON tg.registration_id = tr.registration_id " +
                     "WHERE tg.tournament_id = ? " +
                     "ORDER BY tg.group_name, tr.team_name";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, tournamentId);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                String groupName = rs.getString("group_name");
                TeamRegistration team = mapRowToTeam(rs);
                groups.computeIfAbsent(groupName, k -> new ArrayList<>()).add(team);
            }
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
        return groups;
    }
    
    public boolean groupsExistForTournament(int tournamentId) {
        String sql = "SELECT COUNT(*) FROM tournament_groups WHERE tournament_id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, tournamentId);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
        return false;
    }
    
    public boolean deleteGroupsByTournament(int tournamentId) {
        String sql = "DELETE FROM tournament_groups WHERE tournament_id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, tournamentId);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
        return false;
    }

    public Map<String, List<TeamRegistration>> getRankedTeamsByGroup(int tournamentId) {
        Map<String, List<TeamRegistration>> rankedGroups = new LinkedHashMap<>();
        
        // Step 1: Get all distinct groups for this tournament
        List<String> groupNames = new ArrayList<>();
        String groupSql = "SELECT DISTINCT group_name FROM tournament_groups WHERE tournament_id = ? ORDER BY group_name";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(groupSql)) {
            
            ps.setInt(1, tournamentId);
            ResultSet rs = ps.executeQuery();
            
            while (rs.next()) {
                String groupName = rs.getString("group_name");
                groupNames.add(groupName);
                System.out.println("Found group: " + groupName); // Debug log
            }
            
            if (groupNames.isEmpty()) {
                System.err.println("ERROR: No groups found for tournament " + tournamentId);
                return rankedGroups;
            }
            
        } catch (SQLException | ClassNotFoundException e) {
            System.err.println("Error getting group names: " + e.getMessage());
            e.printStackTrace();
            return rankedGroups;
        }

        // Step 2: For each group, get teams ranked by wins
        String teamSql = "SELECT tr.*, " +
                        "COALESCE((SELECT COUNT(*) FROM matches m " +
                        "WHERE m.winner_id = tr.registration_id " +
                        "AND m.tournament_id = ? " +
                        "AND m.group_name = ?), 0) as win_count " +
                        "FROM team_registrations tr " +
                        "JOIN tournament_groups tg ON tr.registration_id = tg.registration_id " +
                        "WHERE tg.tournament_id = ? AND tg.group_name = ? " +
                        "ORDER BY win_count DESC, tr.team_name ASC";

        try (Connection conn = DBConnection.getConnection()) {
            
            for (String groupName : groupNames) {
                try (PreparedStatement ps = conn.prepareStatement(teamSql)) {
                    
                    ps.setInt(1, tournamentId);
                    ps.setString(2, groupName);
                    ps.setInt(3, tournamentId);
                    ps.setString(4, groupName);
                    
                    ResultSet rs = ps.executeQuery();
                    List<TeamRegistration> teams = new ArrayList<>();
                    
                    while (rs.next()) {
                        TeamRegistration team = mapRowToTeam(rs);
                        int wins = rs.getInt("win_count");
                        teams.add(team);
                        System.out.println("Group " + groupName + ": " + team.getTeamName() + " - " + wins + " wins");
                    }
                    
                    rankedGroups.put(groupName, teams);
                }
            }
            
        } catch (SQLException | ClassNotFoundException e) {
            System.err.println("Error calculating ranked teams: " + e.getMessage());
            e.printStackTrace();
        }
        
        return rankedGroups;
    }

    private TeamRegistration mapRowToTeam(ResultSet rs) throws SQLException {
        TeamRegistration team = new TeamRegistration();
        team.setRegistrationId(rs.getInt("registration_id"));
        team.setTournamentId(rs.getInt("tournament_id"));
        team.setUserId(rs.getInt("user_id"));
        team.setTeamName(rs.getString("team_name"));
        team.setTeamLeaderName(rs.getString("team_leader_name"));
        team.setContactPhone(rs.getString("contact_phone"));
        team.setContactEmail(rs.getString("contact_email"));
        team.setNumberOfPlayers(rs.getInt("number_of_players"));
        team.setStatus(rs.getString("status"));
        team.setRegisteredAt(rs.getTimestamp("registered_at"));
        return team;
    }
}