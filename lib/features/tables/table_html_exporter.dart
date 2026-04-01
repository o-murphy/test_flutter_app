import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:eballistica/features/tables/details_table_mv.dart';
import 'package:eballistica/features/tables/trajectory_tables_vm.dart';
import 'package:eballistica/shared/models/formatted_row.dart';

// ─── HTML Exporter ────────────────────────────────────────────────────────────

class TableHtmlExporter {
  const TableHtmlExporter._();

  static Future<void> share({
    required DetailsTableData? details,
    required TrajectoryTablesUiReady tables,
  }) async {
    final html = _buildHtml(details: details, tables: tables);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/trajectory_table.html');
    await file.writeAsString(html, flush: true);

    if (Platform.isAndroid || Platform.isIOS) {
      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType: 'text/html',
            name: 'trajectory_table.html',
          ),
        ],
        subject: details != null
            ? '${details.rifleName} — Trajectory'
            : 'Trajectory',
      );
    } else {
      // Desktop: open HTML in the default browser
      await launchUrl(
        Uri.file(file.path),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  // ── Top-level builder ──────────────────────────────────────────────────────

  static String _buildHtml({
    required DetailsTableData? details,
    required TrajectoryTablesUiReady tables,
  }) {
    final title = details != null
        ? '${_esc(details.rifleName)} — Trajectory'
        : 'Trajectory';
    final sb = StringBuffer()
      ..writeln('<!DOCTYPE html>')
      ..writeln('<html lang="en">')
      ..writeln('<head>')
      ..writeln('<meta charset="utf-8">')
      ..writeln(
        '<meta name="viewport" content="width=device-width, initial-scale=1">',
      )
      ..writeln('<title>$title</title>')
      ..writeln('<style>')
      ..writeln(_css)
      ..writeln('</style>')
      ..writeln('<script>')
      ..writeln(_js)
      ..writeln('</script>')
      ..writeln('</head>')
      ..writeln('<body>')
      ..writeln('<div class="toolbar" id="toolbar">')
      ..writeln('  <span class="toolbar-title">${_esc(title)}</span>')
      ..writeln('  <div class="toolbar-actions">')
      ..writeln('    <button onclick="saveHtml()">Save</button>')
      ..writeln('    <button onclick="window.print()">Print</button>')
      ..writeln('  </div>')
      ..writeln('</div>');

    if (details != null) sb.write(_buildDetails(details));

    final zeros = tables.zeroCrossings;
    if (zeros != null && zeros.distanceHeaders.isNotEmpty) {
      sb.write(_buildTable(zeros, title: 'Zero Crossings'));
    }
    sb.write(_buildTable(tables.mainTable, title: 'Trajectory'));

    sb.writeln('</body>');
    sb.writeln('</html>');
    return sb.toString();
  }

  // ── Details section ────────────────────────────────────────────────────────

  static String _buildDetails(DetailsTableData d) {
    final sb = StringBuffer()
      ..writeln('<section class="details">')
      ..writeln('<h1>${_esc(d.rifleName)}</h1>');

    // Rifle
    sb.writeln('<div class="card">');
    sb.writeln('<h2>Rifle</h2><table class="info">');
    sb.write(_row('Name', d.rifleName));
    if (d.caliber != null) sb.write(_row('Caliber', d.caliber!));
    if (d.twist != null) sb.write(_row('Twist', d.twist!));
    if (d.zeroDist != null) sb.write(_row('Zero distance', d.zeroDist!));
    sb.writeln('</table></div>');

    // Cartridge
    if (d.zeroMv != null || d.currentMv != null) {
      sb.writeln('<div class="card">');
      sb.writeln('<h2>Cartridge</h2><table class="info">');
      if (d.zeroMv != null) sb.write(_row('Zero MV', d.zeroMv!));
      if (d.currentMv != null) sb.write(_row('Current MV', d.currentMv!));
      sb.writeln('</table></div>');
    }

    // Projectile
    final hasProj =
        d.dragModel != null ||
        d.bc != null ||
        d.bulletLen != null ||
        d.bulletDiam != null ||
        d.bulletWeight != null ||
        d.formFactor != null ||
        d.sectionalDensity != null ||
        d.gyroStability != null;
    if (hasProj) {
      sb.writeln('<div class="card">');
      sb.writeln('<h2>Projectile</h2><table class="info">');
      if (d.dragModel != null) sb.write(_row('Drag model', d.dragModel!));
      if (d.bc != null) sb.write(_row('BC', d.bc!));
      if (d.bulletLen != null) sb.write(_row('Length', d.bulletLen!));
      if (d.bulletDiam != null) sb.write(_row('Diameter', d.bulletDiam!));
      if (d.bulletWeight != null) sb.write(_row('Weight', d.bulletWeight!));
      if (d.formFactor != null) sb.write(_row('Form factor', d.formFactor!));
      if (d.sectionalDensity != null) {
        sb.write(_row('Sectional density', d.sectionalDensity!));
      }
      if (d.gyroStability != null) {
        sb.write(_row('Gyrostability (Sg)', d.gyroStability!));
      }
      sb.writeln('</table></div>');
    }

    // Conditions
    final hasCond =
        d.temperature != null ||
        d.humidity != null ||
        d.pressure != null ||
        d.windSpeed != null ||
        d.windDir != null;
    if (hasCond) {
      sb.writeln('<div class="card">');
      sb.writeln('<h2>Conditions</h2><table class="info">');
      if (d.temperature != null) sb.write(_row('Temperature', d.temperature!));
      if (d.humidity != null) sb.write(_row('Humidity', d.humidity!));
      if (d.pressure != null) sb.write(_row('Pressure', d.pressure!));
      if (d.windSpeed != null) sb.write(_row('Wind speed', d.windSpeed!));
      if (d.windDir != null) sb.write(_row('Wind direction', d.windDir!));
      sb.writeln('</table></div>');
    }

    sb.writeln('</section>');
    return sb.toString();
  }

  static String _row(String label, String value) =>
      '<tr><td class="lbl">${_esc(label)}</td>'
      '<td class="val">${_esc(value)}</td></tr>\n';

  // ── Trajectory table section ───────────────────────────────────────────────

  static String _buildTable(FormattedTableData t, {required String title}) {
    if (t.distanceHeaders.isEmpty || t.rows.isEmpty) return '';
    final sb = StringBuffer()
      ..writeln('<section class="traj">')
      ..writeln('<h2>$title</h2>')
      ..writeln('<div class="scroll">')
      ..writeln('<table class="traj-tbl">')
      ..writeln('<thead><tr>');

    sb.writeln(
      '<th>Range<br><span class="unit">${_esc(t.distanceUnit)}</span></th>',
    );
    for (final r in t.rows) {
      final unit = r.unitSymbol.isNotEmpty
          ? '<br><span class="unit">${_esc(r.unitSymbol)}</span>'
          : '';
      sb.writeln('<th>${_esc(r.label)}$unit</th>');
    }
    sb.writeln('</tr></thead><tbody>');

    for (var pi = 0; pi < t.distanceHeaders.length; pi++) {
      final first = t.rows.isNotEmpty ? t.rows[0].cells[pi] : null;
      final cls = (first?.isZeroCrossing ?? false)
          ? ' class="zero"'
          : (first?.isSubsonic ?? false)
          ? ' class="subsonic"'
          : (first?.isTargetColumn ?? false)
          ? ' class="target"'
          : '';
      sb.writeln('<tr$cls>');
      sb.writeln('<td class="rng">${_esc(t.distanceHeaders[pi])}</td>');
      for (final r in t.rows) {
        final v = pi < r.cells.length ? r.cells[pi].value : '—';
        sb.writeln('<td>${_esc(v)}</td>');
      }
      sb.writeln('</tr>');
    }

    sb.writeln('</tbody></table></div></section>');
    return sb.toString();
  }

  // ── HTML escape ────────────────────────────────────────────────────────────

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  // ── CSS ───────────────────────────────────────────────────────────────────

  static const _css = r'''
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      font-size: 13px; line-height: 1.5; color: #1c1c1e; background: #f2f2f7;
      padding: 16px; padding-top: 60px;
    }
    .toolbar {
      position: fixed; top: 0; left: 0; right: 0; height: 44px; z-index: 100;
      background: rgba(242,242,247,.85); backdrop-filter: blur(12px);
      border-bottom: 1px solid #e5e5ea;
      display: flex; align-items: center; justify-content: space-between;
      padding: 0 16px; gap: 12px;
    }
    .toolbar-title { font-weight: 600; font-size: 14px; overflow: hidden;
                     text-overflow: ellipsis; white-space: nowrap; }
    .toolbar-actions { display: flex; gap: 8px; flex-shrink: 0; }
    .toolbar button {
      font-size: 13px; font-family: inherit; cursor: pointer;
      padding: 0; border: none; background: none;
      color: #0071e3; font-weight: 500; text-decoration: underline;
    }
    .toolbar button:hover { color: #0077ed; }
    @media print {
      .toolbar { display: none; }
      body { padding-top: 16px; background: #fff; }
    }
    h1 { font-size: 18px; font-weight: 700; margin-bottom: 12px; }
    h2 {
      font-size: 11px; font-weight: 700; text-transform: uppercase;
      letter-spacing: 0.7px; color: #636366; margin-bottom: 6px;
    }
    section { margin-bottom: 20px; }

    /* Details cards */
    .details { display: flex; flex-wrap: wrap; gap: 12px; }
    .details h1 { flex: 0 0 100%; }
    .card {
      background: #fff; border-radius: 10px; padding: 12px 14px;
      flex: 1 1 180px; box-shadow: 0 1px 3px rgba(0,0,0,.07);
    }
    table.info { width: 100%; border-collapse: collapse; }
    table.info td { padding: 3px 0; vertical-align: top; }
    td.lbl { color: #636366; padding-right: 12px; white-space: nowrap; }
    td.val { font-weight: 500; font-variant-numeric: tabular-nums; }

    /* Trajectory table */
    .traj { background: #fff; border-radius: 10px; padding: 12px 14px;
            box-shadow: 0 1px 3px rgba(0,0,0,.07); }
    .scroll { overflow-x: auto; }
    table.traj-tbl {
      border-collapse: collapse; font-size: 12px;
      font-variant-numeric: tabular-nums; white-space: nowrap;
      width: 100%; min-width: max-content;
    }
    table.traj-tbl th, table.traj-tbl td {
      border: 1px solid #e5e5ea; padding: 4px 10px; text-align: right;
    }
    table.traj-tbl th {
      background: #f2f2f7; font-size: 11px; font-weight: 600;
      text-align: center; position: sticky; top: 0;
    }
    .unit { font-weight: 400; color: #8e8e93; }
    td.rng { text-align: center; font-weight: 600; background: #f2f2f7; }
    tr:nth-child(even) td { background: #fafafa; }
    tr.zero    td { background: #fff0f0 !important; color: #c0392b; font-weight: 600; }
    tr.subsonic td { background: #f0eeff !important; color: #5856d6; font-weight: 600; }
    tr.target  td { background: #e8f4ff !important; color: #0071e3; font-weight: 600; }
  ''';

  // ── JS ────────────────────────────────────────────────────────────────────

  static const _js = r'''
    function saveHtml() {
      const html = document.documentElement.outerHTML;
      const blob = new Blob([html], { type: 'text/html' });
      const a = document.createElement('a');
      a.href = URL.createObjectURL(blob);
      a.download = 'trajectory_table.html';
      a.click();
      URL.revokeObjectURL(a.href);
    }
  ''';
}
