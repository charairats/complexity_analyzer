// lib/src/analyzer.dart
import 'dart:io';
import 'package:path/path.dart' as p; // ใช้สำหรับจัดการ path

// Import model ที่เราสร้างขึ้น
import 'model.dart';

class ComplexityAnalyzer {
  // Keywords และ Operators ที่ใช้ในการคำนวณ (เหมือนเดิม)
  static const List<String> _decisionKeywords = [
    'if',
    'while',
    'for',
    'case',
    'catch'
  ];
  static const List<String> _decisionOperators = ['&&', '||', '?'];

  /// วิเคราะห์ไฟล์ Dart หนึ่งไฟล์เพื่อหา Cyclomatic Complexity
  ///
  /// - [filePath]: Path เต็มของไฟล์ที่ต้องการวิเคราะห์ (สำหรับอ่านไฟล์)
  /// - [threshold]: ค่า CC สูงสุดที่ยอมรับได้
  /// - [relativePath]: Path ของไฟล์ที่สัมพันธ์กับ root project (สำหรับใส่ใน report)
  ///
  /// คืนค่า [AnalysisResult] หรือ null ถ้าเกิดข้อผิดพลาดในการอ่านไฟล์
  Future<AnalysisResult?> analyzeFile(
      String filePath, int threshold, String relativePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('⚠️ Warning: File not found: $filePath');
        return null;
      }
      final originalCode = await file.readAsString();

      // 1. ประมวลผลเบื้องต้น (ลบ comment, string)
      final processedCode = _preprocessCode(originalCode);

      // 2. ค้นหาฟังก์ชันและคำนวณ Complexity
      final functions = _findFunctions(originalCode, processedCode);

      final List<ComplexityIssue> issues = [];
      final Map<String, int> allComplexities = {}; // <FunctionName, Score>

      for (var funcInfo in functions) {
        final complexity = _calculateBlockComplexity(funcInfo.body);
        allComplexities[funcInfo.name] = complexity; // เก็บ complexity ทั้งหมด

        // 3. ตรวจสอบ Threshold และสร้าง Issue object
        if (complexity > threshold) {
          String severity = complexity > (threshold * 1.5) ? "MAJOR" : "MINOR";
          String message =
              "Cyclomatic Complexity of '${funcInfo.name}' is $complexity (threshold is $threshold). Consider refactoring.";

          issues.add(ComplexityIssue(
            filePath: relativePath, // ใช้ relative path ใน report
            startLine: funcInfo.startLine,
            functionName: funcInfo.name,
            complexity: complexity,
            severity: severity,
            message: message,
          ));
        }
      }

      return AnalysisResult(
        filePath: relativePath,
        issues: issues,
        allFunctionComplexities: allComplexities,
      );
    } catch (e, s) {
      print('❌ Error analyzing file $relativePath: $e');
      // print(s); // Uncomment for stack trace details
      return null;
    }
  }

  /// ประมวลผลโค้ดเบื้องต้น: ลบ comments และ string literals
  String _preprocessCode(String code) {
    // ลบ single line comments
    String noSingleComments =
        code.replaceAll(RegExp(r'//.*', multiLine: false), '');
    // ลบ multi-line comments
    String noMultiComments = noSingleComments.replaceAll(
        RegExp(r'/\*.*?\*/', multiLine: true, dotAll: true), '');
    // ลบ strings (แบบง่ายๆ อาจไม่สมบูรณ์ 100%)
    String noStrings =
        noMultiComments.replaceAll(RegExp(r"'[^'\\]*(?:\\.[^'\\]*)*'"), "''");
    noStrings = noStrings.replaceAll(RegExp(r'"[^"\\]*(?:\\.[^"\\]*)*"'), '""');
    noStrings = noStrings.replaceAll(RegExp(r'"""(?:.|\n)*?"""'), '""""""');
    noStrings = noStrings.replaceAll(RegExp(r"'''(?:.|\n)*?'''"), "''''''");
    return noStrings;
  }

  /// ค้นหาฟังก์ชัน/เมธอดในโค้ดที่ผ่านการประมวลผลแล้ว
  List<_FunctionInfo> _findFunctions(
      String originalCode, String processedCode) {
    final List<_FunctionInfo> functions = [];
    // RegExp เดิมที่ใช้หา function/method/constructor/getter/setter
    // (อาจต้องปรับปรุงเพิ่มเติมสำหรับ edge cases)
    RegExp functionPattern = RegExp(
        r'^\s*(?:[\w<>?,\[\]]+\s+)?(\w+)\s*\([^)]*\)\s*(\{)|' +
            r'^\s*(?:static\s+)?(get|set)\s+(\w+)\s*(?:\([^)]*\))?\s*(\{)|' +
            r'^\s*(\w+)\s*\([^)]*\)\s*(?:[:]\s*super\(.*?\))?\s*(\{)',
        multiLine: true);

    Iterable<RegExpMatch> matches = functionPattern.allMatches(processedCode);

    for (var match in matches) {
      String functionName;
      int bodyStartIndex = -1;
      int definitionStartIndex =
          match.start; // ตำแหน่งเริ่ม definition ใน processedCode

      if (match.group(1) != null && match.group(2) == '{') {
        // Normal function or Constructor
        functionName = match.group(1)!;
        bodyStartIndex = processedCode.indexOf('{', definitionStartIndex);
      } else if (match.group(3) != null &&
          match.group(4) != null &&
          match.group(5) == '{') {
        // Getter or Setter
        functionName = "${match.group(3)} ${match.group(4)}";
        bodyStartIndex = processedCode.indexOf('{', definitionStartIndex);
      } else {
        continue;
      }

      if (bodyStartIndex != -1) {
        int bodyEndIndex = _findMatchingBrace(processedCode, bodyStartIndex);
        if (bodyEndIndex != -1) {
          String functionBody =
              processedCode.substring(bodyStartIndex + 1, bodyEndIndex);
          // **สำคัญ:** หา start line จาก originalCode โดยใช้ definitionStartIndex
          // (การหา index ใน original code อาจคลาดเคลื่อนถ้า comment/string ที่ลบไปมีหลายบรรทัด
          // อาจต้องใช้วิธีเทียบตำแหน่งที่ซับซ้อนกว่านี้ถ้าต้องการความแม่นยำสูง)
          // วิธีอย่างง่ายคือหาจาก originalCode โดยใช้ index จาก processedCode
          // ซึ่งอาจไม่แม่นยำ 100% แต่เป็นจุดเริ่มต้นที่ดี
          int startLine = _getLineNumber(originalCode, definitionStartIndex);

          functions.add(_FunctionInfo(
            name: functionName,
            startLine: startLine,
            body: functionBody,
          ));
        }
      }
    }
    return functions;
  }

  /// คำนวณ Cyclomatic Complexity สำหรับโค้ดบล็อก (body ของฟังก์ชัน)
  int _calculateBlockComplexity(String body) {
    int complexity = 1; // Base complexity
    // นับ Keywords
    for (String keyword in _decisionKeywords) {
      RegExp keywordRegex = RegExp(r'\b' + keyword + r'\b');
      complexity += keywordRegex.allMatches(body).length;
    }
    // นับ Operators
    for (String op in _decisionOperators) {
      String escapedOp = RegExp.escape(op);
      RegExp operatorRegex = RegExp(escapedOp);
      complexity += operatorRegex.allMatches(body).length;
    }
    return complexity;
  }

  /// หาตำแหน่ง '}' ที่คู่กัน (เหมือนเดิม)
  int _findMatchingBrace(String code, int startIndex) {
    if (startIndex < 0 || startIndex >= code.length || code[startIndex] != '{')
      return -1;
    int braceLevel = 1;
    for (int i = startIndex + 1; i < code.length; i++) {
      if (code[i] == '{')
        braceLevel++;
      else if (code[i] == '}') {
        braceLevel--;
        if (braceLevel == 0) return i;
      }
    }
    return -1; // Not found
  }

  /// คำนวณหมายเลขบรรทัดจาก index (เหมือนเดิม)
  int _getLineNumber(String code, int index) {
    if (index < 0) return 1; // Handle edge case
    // ตรวจสอบ index ไม่ให้เกินความยาว string
    int effectiveIndex = index >= code.length ? code.length - 1 : index;
    // +1 เพราะบรรทัดเริ่มนับที่ 1
    return code.substring(0, effectiveIndex).split('\n').length;
  }
}

/// Class ช่วยเก็บข้อมูลฟังก์ชันที่หาเจอภายใน
class _FunctionInfo {
  final String name;
  final int startLine;
  final String body;

  _FunctionInfo(
      {required this.name, required this.startLine, required this.body});
}
