package DAO;

import Model.Match;
import DB.DBConnection;
import java.sql.*;
import java.util.*;

public class MatchDAO {

    public boolean createMatch(Match match) {
        String sql = "INSERT INTO matches (tournament_id, group_name, team1_id, team2_id, status) " +
                     "VALUES (?, ?, ?, ?, ?)";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, match.getTournamentId());
            pstmt.setString(2, match.getGroupName());
            pstmt.setInt(3, match.getTeam1Id());
            pstmt.setInt(4, match.getTeam2Id());
            pstmt.setString(5, "pending");
            return pstmt.executeUpdate() > 0;
        } catch (SQLException | ClassNotFoundException e) {
            System.err.println("Error creating match: " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }

    public List<Match> getMatchesByTournament(int tournamentId) {
        List<Match> matches = new ArrayList<>();
        String sql = "SELECT * FROM matches WHERE tournament_id = ? ORDER BY group_name, match_id";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, tournamentId);
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) matches.add(mapResultSetToMatch(rs));
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
        return matches;
    }

    public boolean updateMatchResult(Match match) {
        String sql = "UPDATE matches SET winner_id = ?, " +
                     "team1_set1=?, team1_set2=?, team1_set3=?, team1_set4=?, team1_set5=?, " +
                     "team2_set1=?, team2_set2=?, team2_set3=?, team2_set4=?, team2_set5=?, " +
                     "status='completed' WHERE match_id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setObject(1, match.getWinnerId());
            pstmt.setObject(2, match.getTeam1Set1());
            pstmt.setObject(3, match.getTeam1Set2());
            pstmt.setObject(4, match.getTeam1Set3());
            pstmt.setObject(5, match.getTeam1Set4());
            pstmt.setObject(6, match.getTeam1Set5());
            pstmt.setObject(7, match.getTeam2Set1());
            pstmt.setObject(8, match.getTeam2Set2());
            pstmt.setObject(9, match.getTeam2Set3());
            pstmt.setObject(10, match.getTeam2Set4());
            pstmt.setObject(11, match.getTeam2Set5());
            pstmt.setInt(12, match.getMatchId());
            return pstmt.executeUpdate() > 0;
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
        return false;
    }

    public Match getMatchById(int matchId) {
        String sql = "SELECT * FROM matches WHERE match_id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, matchId);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) return mapResultSetToMatch(rs);
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
        return null;
    }

    public boolean deleteMatchesByTournament(int tournamentId) {
        String sql = "DELETE FROM matches WHERE tournament_id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, tournamentId);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
        return false;
    }

    /**
     * Deletes matches for a tournament matching any of the given stage names.
     * Used to clean up stale empty bracket placeholders before regenerating.
     */
    public void deleteMatchesByTournamentAndStages(int tournamentId, String[] stages) {
        if (stages == null || stages.length == 0) return;
        StringBuilder placeholders = new StringBuilder();
        for (int i = 0; i < stages.length; i++) {
            placeholders.append(i == 0 ? "?" : ",?");
        }
        String sql = "DELETE FROM matches WHERE tournament_id=? AND group_name IN (" + placeholders + ")";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, tournamentId);
            for (int i = 0; i < stages.length; i++) {
                ps.setString(i + 2, stages[i]);
            }
            int deleted = ps.executeUpdate();
            System.out.println("Deleted " + deleted + " stale bracket match(es) for tournament " + tournamentId);
        } catch (SQLException | ClassNotFoundException e) {
            System.err.println("Error deleting stale bracket matches: " + e.getMessage());
            e.printStackTrace();
        }
    }

    public boolean createBracketMatch(int tournamentId, int team1Id, int team2Id, String stageName) {
        String sql = "INSERT INTO matches (tournament_id, team1_id, team2_id, group_name, status) " +
                     "VALUES (?, ?, ?, ?, 'pending')";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, tournamentId);
            // Use NULL for placeholder slots (0 violates the FK constraint on team_registrations)
            if (team1Id > 0) ps.setInt(2, team1Id); else ps.setNull(2, java.sql.Types.INTEGER);
            if (team2Id > 0) ps.setInt(3, team2Id); else ps.setNull(3, java.sql.Types.INTEGER);
            ps.setString(4, stageName);
            int rows = ps.executeUpdate();
            System.out.println("Created bracket match: " + stageName +
                               " (T1:" + team1Id + " T2:" + team2Id + ") rows=" + rows);
            return rows > 0;
        } catch (SQLException | ClassNotFoundException e) {
            System.err.println("Error creating bracket match '" + stageName + "': " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    public boolean updateFutureMatchTeam(int tournamentId, String stageName, int teamSlot, int teamId) {
        String colName = (teamSlot == 1) ? "team1_id" : "team2_id";
        String sql = "UPDATE matches SET " + colName + "=? WHERE tournament_id=? AND group_name=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, teamId);
            ps.setInt(2, tournamentId);
            ps.setString(3, stageName);
            int rows = ps.executeUpdate();
            System.out.println("Updated " + stageName + " " + colName + " -> team " + teamId + " rows=" + rows);
            return rows > 0;
        } catch (SQLException | ClassNotFoundException e) {
            System.err.println("Error updating future match team: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    /**
     * Returns bracket-stage matches (QF/SF/Final) or group-stage matches depending on type.
     */
    public List<Match> getMatchesByTournamentAndType(int tournamentId, String type) {
        List<Match> matches = new ArrayList<>();
        String sql;
        if ("bracket".equals(type)) {
            sql = "SELECT * FROM matches WHERE tournament_id=? " +
                  "AND group_name IN ('QF1','QF2','QF3','QF4','SF1','SF2','Final') " +
                  "ORDER BY match_id ASC";
        } else {
            sql = "SELECT * FROM matches WHERE tournament_id=? " +
                  "AND group_name NOT IN ('QF1','QF2','QF3','QF4','SF1','SF2','Final') " +
                  "ORDER BY group_name, match_id ASC";
        }
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, tournamentId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) matches.add(mapResultSetToMatch(rs));
            System.out.println("Found " + matches.size() + " matches of type '" + type + "' for tournament " + tournamentId);
        } catch (SQLException | ClassNotFoundException e) {
            System.err.println("Error getting matches by type: " + e.getMessage());
            e.printStackTrace();
        }
        return matches;
    }

    /**
     * Removes duplicate RR matches, keeping only the 3 unique pairings.
     * Called on page load to self-heal if the bracket servlet was called multiple times.
     */
    public void cleanDuplicateRRMatches(int tournamentId) {
        String sql = "DELETE FROM matches WHERE tournament_id=? AND group_name='RR' " +
                     "AND match_id NOT IN (" +
                     "  SELECT match_id FROM (SELECT match_id FROM matches " +
                     "  WHERE tournament_id=? AND group_name='RR' ORDER BY match_id ASC LIMIT 3) AS keep" +
                     ")";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, tournamentId);
            ps.setInt(2, tournamentId);
            int deleted = ps.executeUpdate();
            if (deleted > 0) System.out.println("Cleaned " + deleted + " duplicate RR matches for tournament " + tournamentId);
        } catch (SQLException | ClassNotFoundException e) {
            System.err.println("Error cleaning RR matches: " + e.getMessage());
        }
    }

    public List<Match> getRRMatches(int tournamentId) {
        List<Match> matches = new ArrayList<>();
        String sql = "SELECT * FROM matches WHERE tournament_id=? AND group_name='RR' ORDER BY match_id ASC";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, tournamentId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) matches.add(mapResultSetToMatch(rs));
        } catch (SQLException | ClassNotFoundException e) {
            System.err.println("Error getting RR matches: " + e.getMessage());
            e.printStackTrace();
        }
        return matches;
    }

    /**
     * Seeds the Final bracket match DIRECTLY using real team IDs (no NULL placeholder step).
     * Called when all RR matches are already completed and no Final row exists yet.
     */
    public boolean tryResolveRRFinalDirect(int tournamentId, List<Match> rrMatches) {
        if (rrMatches == null || rrMatches.size() != 3) return false;
        for (Match m : rrMatches) {
            if (m.getWinnerId() == null) return false;
        }

        System.out.println("Seeding Final directly from completed RR matches...");

        Set<Integer> teamSet = new LinkedHashSet<>();
        for (Match m : rrMatches) {
            teamSet.add(m.getTeam1Id());
            teamSet.add(m.getTeam2Id());
        }
        List<Integer> teams = new ArrayList<>(teamSet);

        Map<Integer, Integer> wins   = new HashMap<>();
        Map<Integer, Integer> ptDiff = new HashMap<>();
        for (int t : teams) { wins.put(t, 0); ptDiff.put(t, 0); }

        for (Match m : rrMatches) {
            int t1 = m.getTeam1Id(), t2 = m.getTeam2Id();
            int winner = m.getWinnerId();
            wins.put(winner, wins.get(winner) + 1);
            int diff = 0;
            for (int s = 1; s <= 5; s++) {
                Integer s1 = m.getSetScore(1, s);
                Integer s2 = m.getSetScore(2, s);
                if (s1 != null && s2 != null) diff += (s1 - s2);
            }
            ptDiff.put(t1, ptDiff.get(t1) + diff);
            ptDiff.put(t2, ptDiff.get(t2) - diff);
        }

        teams.sort((a, b) -> {
            int wDiff = wins.get(b) - wins.get(a);
            if (wDiff != 0) return wDiff;
            return ptDiff.get(b) - ptDiff.get(a);
        });

        int first  = teams.get(0);
        int second = teams.get(1);
        System.out.println("RR standings: 1st=" + first + " 2nd=" + second + " 3rd=" + teams.get(2));

        return createBracketMatch(tournamentId, first, second, "Final");
    }

    /**
     * Checks if all 3 RR matches are completed. If so, ranks the 3 teams and
     * fills the Final bracket match with team1=1st place, team2=2nd place.
     * Returns true if the Final was successfully seeded.
     */
    public boolean tryResolveRRFinal(int tournamentId) {
        List<Match> rrMatches = getRRMatches(tournamentId);

        if (rrMatches.size() != 3) return false;
        for (Match m : rrMatches) {
            if (m.getWinnerId() == null) return false;
        }

        System.out.println("All 3 RR matches done — seeding Final...");

        Set<Integer> teamSet = new LinkedHashSet<>();
        for (Match m : rrMatches) {
            teamSet.add(m.getTeam1Id());
            teamSet.add(m.getTeam2Id());
        }
        List<Integer> teams = new ArrayList<>(teamSet);

        Map<Integer, Integer> wins   = new HashMap<>();
        Map<Integer, Integer> ptDiff = new HashMap<>();
        for (int t : teams) { wins.put(t, 0); ptDiff.put(t, 0); }

        for (Match m : rrMatches) {
            int t1 = m.getTeam1Id(), t2 = m.getTeam2Id();
            int winner = m.getWinnerId();

            wins.put(winner, wins.get(winner) + 1);

            int diff = 0;
            for (int s = 1; s <= 5; s++) {
                Integer s1 = m.getSetScore(1, s);
                Integer s2 = m.getSetScore(2, s);
                if (s1 != null && s2 != null) {
                    diff += (s1 - s2);
                }
            }
            ptDiff.put(t1, ptDiff.get(t1) + diff);
            ptDiff.put(t2, ptDiff.get(t2) - diff);
        }

        teams.sort((a, b) -> {
            int wDiff = wins.get(b) - wins.get(a);
            if (wDiff != 0) return wDiff;
            return ptDiff.get(b) - ptDiff.get(a);
        });

        int first  = teams.get(0);
        int second = teams.get(1);
        System.out.println("RR standings: 1st=" + first + " 2nd=" + second + " 3rd=" + teams.get(2));

        boolean ok = updateFutureMatchTeam(tournamentId, "Final", 1, first)
                   & updateFutureMatchTeam(tournamentId, "Final", 2, second);

        System.out.println("Final seeded: " + ok);
        return ok;
    }

    public boolean updateBracketResult(int matchId,
            int t1s1, int t2s1, int t1s2, int t2s2,
            int t1s3, int t2s3, int t1s4, int t2s4,
            int t1s5, int t2s5, int winnerId) {
        String sql = "UPDATE matches SET " +
                     "team1_set1=?,team2_set1=?,team1_set2=?,team2_set2=?," +
                     "team1_set3=?,team2_set3=?,team1_set4=?,team2_set4=?," +
                     "team1_set5=?,team2_set5=?,winner_id=?,status='completed' " +
                     "WHERE match_id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setObject(1,  t1s1 == 0 ? null : t1s1);
            ps.setObject(2,  t2s1 == 0 ? null : t2s1);
            ps.setObject(3,  t1s2 == 0 ? null : t1s2);
            ps.setObject(4,  t2s2 == 0 ? null : t2s2);
            ps.setObject(5,  t1s3 == 0 ? null : t1s3);
            ps.setObject(6,  t2s3 == 0 ? null : t2s3);
            ps.setObject(7,  t1s4 == 0 ? null : t1s4);
            ps.setObject(8,  t2s4 == 0 ? null : t2s4);
            ps.setObject(9,  t1s5 == 0 ? null : t1s5);
            ps.setObject(10, t2s5 == 0 ? null : t2s5);
            ps.setInt(11, winnerId);
            ps.setInt(12, matchId);
            int rows = ps.executeUpdate();
            System.out.println("Updated bracket match " + matchId + " winner=" + winnerId + " rows=" + rows);
            return rows > 0;
        } catch (SQLException | ClassNotFoundException e) {
            System.err.println("Error updating bracket result: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    /**
     * Maps a ResultSet row to a Match object.
     * NOTE: match_type is intentionally NOT read here — it does not exist in
     * the DB schema. The servlet uses group_name (QF1/SF1/Final etc.) to
     * determine bracket logic instead.
     */
    private Match mapResultSetToMatch(ResultSet rs) throws SQLException {
        Match match = new Match();
        match.setMatchId(rs.getInt("match_id"));
        match.setTournamentId(rs.getInt("tournament_id"));
        match.setGroupName(rs.getString("group_name"));
        // Use getObject to distinguish NULL from 0
        Integer _t1 = (Integer) rs.getObject("team1_id");
        Integer _t2 = (Integer) rs.getObject("team2_id");
        match.setTeam1Id(_t1 != null ? _t1 : 0);
        match.setTeam2Id(_t2 != null ? _t2 : 0);
        match.setWinnerId((Integer) rs.getObject("winner_id"));
        match.setTeam1Set1((Integer) rs.getObject("team1_set1"));
        match.setTeam1Set2((Integer) rs.getObject("team1_set2"));
        match.setTeam1Set3((Integer) rs.getObject("team1_set3"));
        match.setTeam1Set4((Integer) rs.getObject("team1_set4"));
        match.setTeam1Set5((Integer) rs.getObject("team1_set5"));
        match.setTeam2Set1((Integer) rs.getObject("team2_set1"));
        match.setTeam2Set2((Integer) rs.getObject("team2_set2"));
        match.setTeam2Set3((Integer) rs.getObject("team2_set3"));
        match.setTeam2Set4((Integer) rs.getObject("team2_set4"));
        match.setTeam2Set5((Integer) rs.getObject("team2_set5"));
        match.setStatus(rs.getString("status"));
        match.setCreatedAt(rs.getTimestamp("created_at"));
        return match;
    }

    /**
     * Ensures a Final bracket row exists for the tournament.
     * If it already exists, does nothing. If missing, creates an empty placeholder.
     * This guarantees updateFutureMatchTeam("Final", ...) will always find a row to UPDATE.
     */
    public void ensureFinalExists(int tournamentId) {
        String check = "SELECT COUNT(*) FROM matches WHERE tournament_id=? AND group_name='Final'";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(check)) {
            ps.setInt(1, tournamentId);
            ResultSet rs = ps.executeQuery();
            if (rs.next() && rs.getInt(1) == 0) {
                System.out.println("Final row missing — creating placeholder for tournament " + tournamentId);
                createBracketMatch(tournamentId, 0, 0, "Final");
            }
        } catch (SQLException | ClassNotFoundException e) {
            System.err.println("Error in ensureFinalExists: " + e.getMessage());
            e.printStackTrace();
        }
    }

}