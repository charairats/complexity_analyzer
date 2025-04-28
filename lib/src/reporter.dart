// lib/src/reporter.dart
import 'dart:convert'; // สำหรับ JSON
import 'model.dart'; // Import model ของเรา

class ComplexityReporter {
  /// สร้างเนื้อหา JSON report ตาม format SonarQube Generic Issue Data
  String generateJsonReport(List<ComplexityIssue> allIssues) {
    final reportData = {
      "issues": allIssues
          .map((issue) => issue.toJsonSonar()) // ใช้ method ใน model
          .toList()
    };
    // ใช้ JsonEncoder เพื่อให้ JSON สวยงาม อ่านง่าย
    return JsonEncoder.withIndent('  ').convert(reportData);
  }

  /// สร้างเนื้อหา HTML report แบบง่าย
  String generateHtmlReport(List<ComplexityIssue> allIssues) {
    final StringBuffer html = StringBuffer();

    // --- HTML Boilerplate and CSS ---
    html.writeln('<!DOCTYPE html>');
    html.writeln('<html lang="th">');
    html.writeln('<head>');
    html.writeln('  <meta charset="UTF-8">');
    html.writeln(
        '  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    html.writeln('  <title>รายงาน Cyclomatic Complexity</title>');
    html.writeln('  <style>');
    html.writeln(
        '    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen, Ubuntu, Cantarell, "Open Sans", "Helvetica Neue", sans-serif; margin: 20px; background-color: #f8f9fa; color: #212529; }');
    html.writeln(
        '    h1 { color: #343a40; border-bottom: 2px solid #dee2e6; padding-bottom: 10px; margin-bottom: 20px;}');
    html.writeln(
        '    table { width: 100%; border-collapse: collapse; margin-top: 20px; background-color: #fff; box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075); }');
    html.writeln(
        '    th, td { border: 1px solid #dee2e6; padding: 0.75rem; text-align: left; vertical-align: top; }');
    html.writeln('    th { background-color: #e9ecef; font-weight: 600; }');
    html.writeln('    tr:nth-child(even) { background-color: #f8f9fa; }');
    html.writeln(
        '    .severity-MAJOR { color: #dc3545; font-weight: bold; }'); // Bootstrap danger color
    html.writeln(
        '    .severity-MINOR { color: #fd7e14; }'); // Bootstrap orange color
    html.writeln(
        '    .filepath { font-family: SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace; color: #0d6efd; word-break: break-all; }'); // Bootstrap primary color
    html.writeln(
        '    .line { text-align: right; font-family: SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;}');
    html.writeln(
        '    .complexity { text-align: right; font-weight: bold; font-family: SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;}');
    html.writeln(
        '    .summary { margin: 20px 0; padding: 1rem; background-color: #cfe2ff; border-left: 5px solid #0d6efd; color: #052c65;}'); // Bootstrap primary alert colors
    html.writeln(
        '    .footer { margin-top: 30px; font-size: 0.85em; color: #6c757d; text-align: center; }'); // Bootstrap secondary color
    html.writeln('  </style>');
    html.writeln('</head>');
    html.writeln('<body>');

    html.writeln('  <h1>รายงาน Cyclomatic Complexity</h1>');
    html.writeln(
        '  <div class="summary">พบฟังก์ชันที่ซับซ้อนเกินเกณฑ์ทั้งหมด: <strong>${allIssues.length}</strong> รายการ</div>');

    // --- สร้างตารางแสดงผล ---
    if (allIssues.isNotEmpty) {
      html.writeln('  <table>');
      html.writeln('    <thead>');
      html.writeln('      <tr>');
      html.writeln('        <th>Severity</th>');
      html.writeln('        <th>File Path</th>');
      html.writeln('        <th>Line</th>');
      html.writeln('        <th>Function</th>');
      html.writeln('        <th>Complexity</th>');
      html.writeln('        <th>Message</th>');
      html.writeln('      </tr>');
      html.writeln('    </thead>');
      html.writeln('    <tbody>');

      for (final issue in allIssues) {
        html.writeln('      <tr>');
        html.writeln(
            '        <td class="severity-${issue.severity.toUpperCase()}">${_escapeHtml(issue.severity)}</td>');
        html.writeln(
            '        <td class="filepath">${_escapeHtml(issue.filePath)}</td>');
        html.writeln('        <td class="line">${issue.startLine}</td>');
        html.writeln('        <td>${_escapeHtml(issue.functionName)}</td>');
        html.writeln('        <td class="complexity">${issue.complexity}</td>');
        html.writeln('        <td>${_escapeHtml(issue.message)}</td>');
        html.writeln('      </tr>');
      }

      html.writeln('    </tbody>');
      html.writeln('  </table>');
    } else {
      html.writeln(
          '  <p>✅ ไม่พบฟังก์ชันที่มี Cyclomatic Complexity เกินเกณฑ์ที่กำหนด</p>');
    }

    // --- ส่วนท้าย ---
    html.writeln('  <div class="footer">');
    html.writeln(
        '    Report generated on: ${DateTime.now().toUtc().toIso8601String()} UTC');
    html.writeln('  </div>');

    html.writeln('</body>');
    html.writeln('</html>');

    return html.toString();
  }

  /// Helper function สำหรับ escape HTML entities
  String _escapeHtml(String? text) {
    if (text == null) return '';
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
