package Controller;

import Model.*;
import DAO.*;

import javax.servlet.ServletException;
//import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.*;
import java.text.SimpleDateFormat;
import java.util.*;

// iText 7 imports — requires kernel, layout, io, commons, bcprov JARs in WEB-INF/lib/
import com.itextpdf.kernel.colors.ColorConstants;
import com.itextpdf.kernel.colors.DeviceRgb;
import com.itextpdf.kernel.geom.PageSize;
import com.itextpdf.kernel.pdf.PdfDocument;
import com.itextpdf.kernel.pdf.PdfWriter;
import com.itextpdf.layout.Document;
import com.itextpdf.layout.element.Cell;
import com.itextpdf.layout.element.Paragraph;
import com.itextpdf.layout.element.Table;
import com.itextpdf.layout.properties.TextAlignment;
import com.itextpdf.layout.properties.UnitValue;

//@WebServlet("/GenerateReportServlet")
public class GenerateReportServlet extends HttpServlet {

    // ── Brand colours ──────────────────────────────────────────────────────
    private static final DeviceRgb HEADER_BG   = new DeviceRgb(0x76, 0x4b, 0xa2);
    private static final DeviceRgb HEADER_TEXT = new DeviceRgb(0xFF, 0xFF, 0xFF);
    private static final DeviceRgb ROW_ALT     = new DeviceRgb(0xF8, 0xF9, 0xFA);
    private static final DeviceRgb TITLE_COLOR = new DeviceRgb(0x1a, 0x1a, 0x2e);

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // ── Session guard ──────────────────────────────────────────────────
        HttpSession session   = request.getSession(false);
        String organizerUser  = (session != null) ? (String)  session.getAttribute("organizerUsername") : null;
        Integer organizerId   = (session != null) ? (Integer) session.getAttribute("organizerId")       : null;
        String organizerName  = (session != null) ? (String)  session.getAttribute("organizerFullname") : organizerUser;

        if (organizerUser == null || organizerId == null) {
            response.sendRedirect("OrganizerLogin.jsp");
            return;
        }

        // ── Request parameters ─────────────────────────────────────────────
        String reportType   = request.getParameter("reportType");
        String format       = request.getParameter("format");
        String filterTourId = request.getParameter("tournamentId");
        String filterFrom   = request.getParameter("fromDate");
        String filterTo     = request.getParameter("toDate");

        if (reportType == null) reportType = "tournament_summary";
        if (format     == null) format     = "csv";

        // FIX 1: Use java.text.SimpleDateFormat with java.util.Date consistently.
        // Tournament.getTournamentDate() returns java.sql.Date which extends java.util.Date,
        // so before()/after() comparisons are valid once we parse filterFrom/filterTo as java.util.Date.
        SimpleDateFormat displayFmt = new SimpleDateFormat("dd MMM yyyy");
        SimpleDateFormat parseFmt   = new SimpleDateFormat("yyyy-MM-dd");

        // ── Load and filter tournaments ────────────────────────────────────
        TournamentDAO tournamentDAO = new TournamentDAO();
        List<Tournament> completed  = tournamentDAO.getTournamentsByStatus("completed");
        List<Tournament> filtered   = new ArrayList<>();

        for (Tournament t : completed) {
            // FIX 2: organizerId is Integer, t.getOrganizerId() is int — use .equals() not == to avoid
            // autoboxing comparison issues with Integer objects above value 127.
            if (!organizerId.equals(t.getOrganizerId())) continue;

            if (filterTourId != null && !filterTourId.isEmpty() && !filterTourId.equals("all")) {
                if (t.getTournamentId() != Integer.parseInt(filterTourId)) continue;
            }
            try {
                if (filterFrom != null && !filterFrom.isEmpty()) {
                    java.util.Date from = parseFmt.parse(filterFrom);
                    // FIX 3: getTournamentDate() returns java.sql.Date.
                    // before()/after() accept java.util.Date — this is fine — but we must
                    // call compareTo via java.util.Date, which java.sql.Date inherits correctly.
                    if (t.getTournamentDate().before(from)) continue;
                }
                if (filterTo != null && !filterTo.isEmpty()) {
                    java.util.Date to = parseFmt.parse(filterTo);
                    if (t.getTournamentDate().after(to)) continue;
                }
            } catch (Exception ignored) {}

            filtered.add(t);
        }

        // ── Build data rows ────────────────────────────────────────────────
        MatchDAO            matchDAO  = new MatchDAO();
        TeamRegistrationDAO regDAO    = new TeamRegistrationDAO();
        TeamMemberDAO       memberDAO = new TeamMemberDAO();

        String[] headers;
        List<String[]> rows = new ArrayList<>();

        // FIX 4: switch-on-String requires Java 7+, which is fine for a Java EE project,
        // but the original had no explicit default assignment for headers before the switch,
        // causing a "variable headers might not have been initialised" compile error.
        // Fixed by assigning before the switch and using if/else if instead.
        if ("team_standings".equals(reportType)) {
            headers = new String[]{"Tournament", "Rank", "Team", "W", "L",
                                   "Sets Won", "Sets Lost", "Pts For", "Pts Against", "Avg Pts/Match"};
            buildStandingsRows(filtered, matchDAO, regDAO, rows);

        } else if ("player_statistics".equals(reportType)) {
            headers = new String[]{"Tournament", "Team", "Player Name", "Position", "Jersey No."};
            buildPlayerRows(filtered, regDAO, memberDAO, rows);

        } else {
            // default: tournament_summary
            reportType = "tournament_summary";
            headers = new String[]{"#", "Tournament Name", "Date", "Location",
                                   "Category", "Type", "Teams", "Champion"};
            buildSummaryRows(filtered, matchDAO, regDAO, displayFmt, rows);
        }

        // ── Dispatch to formatter ──────────────────────────────────────────
        String timestamp = new SimpleDateFormat("yyyyMMdd_HHmm").format(new java.util.Date());
        String filename  = "VolleyMetric_" + reportType + "_" + timestamp;

        if ("pdf".equalsIgnoreCase(format)) {
            exportPdf(response, filename, reportType, organizerName, headers, rows, filtered);
        } else {
            exportCsv(response, filename, headers, rows);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  Data builders
    // ═══════════════════════════════════════════════════════════════════════

    private void buildSummaryRows(List<Tournament> tournaments, MatchDAO matchDAO,
                                   TeamRegistrationDAO regDAO, SimpleDateFormat fmt,
                                   List<String[]> out) {
        int i = 1;
        for (Tournament t : tournaments) {
            List<Match> bracket = matchDAO.getMatchesByTournamentAndType(t.getTournamentId(), "bracket");
            String champion = "-";
            for (Match m : bracket) {
                if ("Final".equals(m.getGroupName()) && m.getWinnerId() != null) {
                    TeamRegistration champ = regDAO.getRegistrationById(m.getWinnerId());
                    if (champ != null) champion = champ.getTeamName();
                }
            }
            // FIX 5: Tournament.getTournamentDate() returns java.sql.Date.
            // SimpleDateFormat.format() accepts java.util.Date — java.sql.Date is a subclass so this works,
            // but must not be cast to java.util.Date explicitly (it already is one).
            out.add(new String[]{
                String.valueOf(i++),
                t.getTournamentName(),
                fmt.format(t.getTournamentDate()),
                t.getLocation(),
                capitalise(t.getCategory()),
                capitalise(t.getTournamentType()),
                String.valueOf(t.getCurrentTeams()),
                champion
            });
        }
    }

    private void buildStandingsRows(List<Tournament> tournaments, MatchDAO matchDAO,
                                     TeamRegistrationDAO regDAO, List<String[]> out) {
        for (Tournament t : tournaments) {
            List<Match> allMatches = matchDAO.getMatchesByTournament(t.getTournamentId());
            List<TeamRegistration> teams = regDAO.getApprovedTeamsByTournament(t.getTournamentId());

            final Map<Integer, Integer> wins   = new HashMap<>();
            final Map<Integer, Integer> losses = new HashMap<>();
            final Map<Integer, Integer> sw     = new HashMap<>();
            final Map<Integer, Integer> sl     = new HashMap<>();
            final Map<Integer, Integer> pf     = new HashMap<>();
            final Map<Integer, Integer> pa     = new HashMap<>();

            for (Match m : allMatches) {
                if (m.getWinnerId() == null) continue;
                int t1 = m.getTeam1Id(), t2 = m.getTeam2Id();
                int w  = m.getWinnerId();
                // FIX 6: m.getWinnerId() returns Integer; comparing with == to int t1 works due to
                // unboxing, but can throw NullPointerException if winnerId is null.
                // The null check above guards this, so unboxing is safe here.
                int l  = (w == t1) ? t2 : t1;

                wins.merge(w,  1, Integer::sum);
                losses.merge(l, 1, Integer::sum);

                int s1 = 0, s2 = 0, p1 = 0, p2 = 0;
                for (int i = 1; i <= 5; i++) {
                    Integer sc1 = m.getSetScore(1, i);
                    Integer sc2 = m.getSetScore(2, i);
                    if (sc1 != null && sc2 != null) {
                        p1 += sc1; p2 += sc2;
                        if (sc1 > sc2) s1++; else if (sc2 > sc1) s2++;
                    }
                }
                sw.merge(t1, s1, Integer::sum); sw.merge(t2, s2, Integer::sum);
                sl.merge(t1, s2, Integer::sum); sl.merge(t2, s1, Integer::sum);
                pf.merge(t1, p1, Integer::sum); pf.merge(t2, p2, Integer::sum);
                pa.merge(t1, p2, Integer::sum); pa.merge(t2, p1, Integer::sum);
            }

            // FIX 7: Lambda captures of local variables must be effectively final.
            // The original declared wins/sw/pf inside the loop without final, which caused
            // "local variable referenced from lambda must be effectively final" in some compilers.
            // Fixed by declaring all maps as final above.
            teams.sort((a, b) -> {
                int diff = Integer.compare(
                    wins.getOrDefault(b.getRegistrationId(), 0),
                    wins.getOrDefault(a.getRegistrationId(), 0));
                if (diff != 0) return diff;
                diff = Integer.compare(
                    sw.getOrDefault(b.getRegistrationId(), 0),
                    sw.getOrDefault(a.getRegistrationId(), 0));
                if (diff != 0) return diff;
                return Integer.compare(
                    pf.getOrDefault(b.getRegistrationId(), 0),
                    pf.getOrDefault(a.getRegistrationId(), 0));
            });

            int rank = 1;
            for (TeamRegistration team : teams) {
                int rid = team.getRegistrationId();
                int gp  = wins.getOrDefault(rid, 0) + losses.getOrDefault(rid, 0);
                double avg = gp > 0 ? (double) pf.getOrDefault(rid, 0) / gp : 0.0;
                out.add(new String[]{
                    t.getTournamentName(),
                    String.valueOf(rank++),
                    team.getTeamName(),
                    String.valueOf(wins.getOrDefault(rid, 0)),
                    String.valueOf(losses.getOrDefault(rid, 0)),
                    String.valueOf(sw.getOrDefault(rid, 0)),
                    String.valueOf(sl.getOrDefault(rid, 0)),
                    String.valueOf(pf.getOrDefault(rid, 0)),
                    String.valueOf(pa.getOrDefault(rid, 0)),
                    String.format("%.1f", avg)
                });
            }
        }
    }

    private void buildPlayerRows(List<Tournament> tournaments, TeamRegistrationDAO regDAO,
                                  TeamMemberDAO memberDAO, List<String[]> out) {
        for (Tournament t : tournaments) {
            for (TeamRegistration team : regDAO.getApprovedTeamsByTournament(t.getTournamentId())) {
                for (TeamMember member : memberDAO.getMembersByRegistrationId(team.getRegistrationId())) {
                    // FIX 8: member.getPosition() can be null if DB value is NULL — guard it.
                    String pos = member.getPosition();
                    String posDisplay = (pos != null) ? capitalise(pos.replace("_", " ")) : "";
                    out.add(new String[]{
                        t.getTournamentName(),
                        team.getTeamName(),
                        member.getMemberName(),
                        posDisplay,
                        String.valueOf(member.getJerseyNumber())
                    });
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  CSV Export
    // ═══════════════════════════════════════════════════════════════════════

    private void exportCsv(HttpServletResponse response, String filename,
                            String[] headers, List<String[]> rows) throws IOException {
        response.setContentType("text/csv; charset=UTF-8");
        response.setHeader("Content-Disposition", "attachment; filename=\"" + filename + ".csv\"");

        PrintWriter pw = response.getWriter();
        pw.println(String.join(",", csvEscape(headers)));
        for (String[] row : rows) {
            pw.println(String.join(",", csvEscape(row)));
        }
        pw.flush();
    }

    private String[] csvEscape(String[] cols) {
        String[] escaped = new String[cols.length];
        for (int i = 0; i < cols.length; i++) {
            String val = (cols[i] == null) ? "" : cols[i];
            if (val.contains(",") || val.contains("\"") || val.contains("\n")) {
                val = "\"" + val.replace("\"", "\"\"") + "\"";
            }
            escaped[i] = val;
        }
        return escaped;
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  PDF Export  (iText 7)
    // ═══════════════════════════════════════════════════════════════════════

    private void exportPdf(HttpServletResponse response, String filename,
                            String reportType, String organizerName,
                            String[] headers, List<String[]> rows,
                            List<Tournament> filtered) throws IOException {

        response.setContentType("application/pdf");
        response.setHeader("Content-Disposition", "attachment; filename=\"" + filename + ".pdf\"");

        ByteArrayOutputStream baos = new ByteArrayOutputStream();

        // FIX 9: PdfWriter(OutputStream) constructor — pass baos directly.
        // The original was correct, but make sure the Document is closed BEFORE writing to
        // the response stream, otherwise the PDF trailer is never flushed and the file is corrupt.
        PdfWriter   writer   = new PdfWriter(baos);
        PdfDocument pdfDoc   = new PdfDocument(writer);
        Document    document = new Document(pdfDoc, PageSize.A4.rotate());
        document.setMargins(30, 30, 30, 30);

        // Title
        Paragraph title = new Paragraph("VolleyMetric — " + reportTypeLabel(reportType) + " Report")
            .setFontSize(20).setBold().setFontColor(TITLE_COLOR)
            .setTextAlignment(TextAlignment.LEFT).setMarginBottom(4);
        document.add(title);

        String meta = "Generated: " + new SimpleDateFormat("dd MMM yyyy, HH:mm").format(new java.util.Date())
            + "   |   Organizer: " + (organizerName != null ? organizerName : "")
            + "   |   Tournaments: " + filtered.size();
        document.add(new Paragraph(meta)
            .setFontSize(9).setFontColor(ColorConstants.GRAY).setMarginBottom(14));

        // Divider rule
        Table rule = new Table(UnitValue.createPercentArray(new float[]{1})).useAllAvailableWidth();
        // FIX 10: new Cell() with no-arg is correct. setBorder(null) sets all borders to null on iText 7.
        // The original called setBorder(null) which is valid in iText 7 — no change needed here.
        Cell ruleLine = new Cell().setHeight(3).setBackgroundColor(HEADER_BG).setBorder(null);
        rule.addCell(ruleLine);
        document.add(rule);
        document.add(new Paragraph(" ").setFontSize(4).setMarginBottom(0));

        // Data table
        float[] colWidths = evenWidths(headers.length);
        Table table = new Table(UnitValue.createPercentArray(colWidths)).useAllAvailableWidth();

        for (String h : headers) {
            Cell cell = new Cell()
                .add(new Paragraph(h).setFontSize(9).setBold().setFontColor(HEADER_TEXT))
                .setBackgroundColor(HEADER_BG)
                .setBorder(null)
                .setPadding(6);
            table.addHeaderCell(cell);
        }

        boolean alt = false;
        for (String[] row : rows) {
            DeviceRgb rowBg = alt ? ROW_ALT : new DeviceRgb(255, 255, 255);
            for (String val : row) {
                Cell cell = new Cell()
                    .add(new Paragraph(val != null ? val : "").setFontSize(8))
                    .setBackgroundColor(rowBg)
                    .setBorder(null)
                    .setPadding(5);
                table.addCell(cell);
            }
            alt = !alt;
        }

        document.add(table);

        document.add(new Paragraph(" ").setFontSize(4));
        // FIX 11: new java.util.Date().getYear() is deprecated — use Calendar instead.
        int year = Calendar.getInstance().get(Calendar.YEAR);
        document.add(new Paragraph(
            "\u00A9 " + year + " VolleyMetric  |  21030 Kuala Nerus, Terengganu  |  info@volleymetric.com")
            .setFontSize(8).setFontColor(ColorConstants.GRAY)
            .setTextAlignment(TextAlignment.CENTER));

        // FIX 12: document.close() must be called before writing baos to the response.
        // Otherwise iText has not written the PDF cross-reference table and the file is invalid.
        document.close();

        response.getOutputStream().write(baos.toByteArray());
        response.getOutputStream().flush();
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  Helpers
    // ═══════════════════════════════════════════════════════════════════════

    private float[] evenWidths(int count) {
        float[] w = new float[count];
        Arrays.fill(w, 1f);
        return w;
    }

    private String reportTypeLabel(String type) {
        if ("team_standings".equals(type))    return "Team Standings";
        if ("player_statistics".equals(type)) return "Player Statistics";
        return "Tournament Summary";
    }

    private String capitalise(String s) {
        if (s == null || s.isEmpty()) return (s == null) ? "" : s;
        return Character.toUpperCase(s.charAt(0)) + s.substring(1);
    }
}