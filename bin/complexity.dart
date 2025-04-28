// bin/complexity.dart
import 'dart:io';
import 'package:args/args.dart'; // Package สำหรับ parse arguments
import 'package:path/path.dart' as p; // Package สำหรับจัดการ path
// Import โค้ดจาก lib ของเราเอง (ใช้ชื่อ package ที่ตั้งใน pubspec.yaml)
import 'package:complexity_analyzer/src/analyzer.dart';
import 'package:complexity_analyzer/src/reporter.dart';
import 'package:complexity_analyzer/src/model.dart';

// ค่า Default ต่างๆ
const String defaultOutputDirName = 'complexity'; // ชื่อโฟลเดอร์ output
const String defaultJsonName = 'sonar-report.json';
const String defaultHtmlName = 'report.html';
const int defaultThreshold = 10;
const List<String> defaultPaths = ['lib']; // Default path ที่จะ scan

void main(List<String> arguments) async {
  // --- ตั้งค่า Argument Parser ---
  final parser = ArgParser()
    ..addCommand('generate', _buildGenerateCommandParser()); // สร้าง subcommand 'generate'

  ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
    if (argResults.command == null) {
      if (arguments.isEmpty || arguments.first == '--help' || arguments.first == '-h') {
         _printUsage(parser);
         exit(0);
      } else {
          print('Invalid command. Please use "generate".');
          _printUsage(parser);
          exit(64);
      }
    }
  } catch (e) {
    print('Error parsing arguments: $e');
    _printUsage(parser);
    exit(64); // Exit code for command line usage error
  }

  // --- ทำงานตาม Subcommand ---
  if (argResults.command?.name == 'generate') {
    await _handleGenerateCommand(argResults.command!);
  } else {
    // Should not happen if parsing is correct and command is required
    _printUsage(parser);
    exit(64);
  }
}

// สร้าง Parser สำหรับ subcommand 'generate' โดยเฉพาะ
ArgParser _buildGenerateCommandParser() {
  return ArgParser()
    ..addOption('threshold',
        abbr: 't',
        help: 'Cyclomatic Complexity threshold score.',
        defaultsTo: defaultThreshold.toString())
    ..addOption('output-dir',
        abbr: 'o',
        help: 'Directory to save report files.',
        defaultsTo: defaultOutputDirName)
    ..addMultiOption('paths',
        abbr: 'p',
        help: 'List of files or directories to analyze.',
        defaultsTo: defaultPaths)
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help for the generate command.');
}

// Function หลักสำหรับจัดการคำสั่ง 'generate'
Future<void> _handleGenerateCommand(ArgResults generateArgs) async {
  if (generateArgs['help'] as bool) {
    print('Generates complexity analysis reports (JSON and HTML).\n');
    print('Usage: dart run complexity_analyzer:generate [options]\n');
    print(_buildGenerateCommandParser().usage);
    exit(0);
  }

  final int threshold = int.tryParse(generateArgs['threshold'] as String) ?? defaultThreshold;
  final String outputDir = generateArgs['output-dir'] as String;
  final List<String> inputPaths = generateArgs['paths'] as List<String>;

  print('🚀 Starting Complexity Analysis...');
  print('   Threshold: $threshold');
  print('   Output Directory: $outputDir');
  print('   Paths to Analyze: ${inputPaths.join(', ')}');

  final analyzer = ComplexityAnalyzer(); // สร้าง instance จาก library
  final reporter = ComplexityReporter(); // สร้าง instance จาก library
  final List<String> filesToAnalyze = await _findDartFiles(inputPaths);

  if (filesToAnalyze.isEmpty) {
    print('❌ No Dart files found in the specified paths.');
    exit(0);
  }

  print('🔍 Analyzing ${filesToAnalyze.length} files...');

  // --- วิเคราะห์ไฟล์ ---
  final List<AnalysisResult> analysisResults = [];
  final Stopwatch stopwatch = Stopwatch()..start();

  for (final filePath in filesToAnalyze) {
    // ทำให้เป็น relative path สำหรับ report
    String relativePath = p.relative(filePath, from: Directory.current.path);
    try {
      AnalysisResult? result = await analyzer.analyzeFile(filePath, threshold, relativePath);
      if (result != null) {
        analysisResults.add(result);
      }
    } catch (e, s) {
      print('⚠️ Error analyzing file $relativePath: $e');
      // print(s); // Uncomment for stack trace
    }
  }
  stopwatch.stop();
  print('✅ Analysis completed in ${stopwatch.elapsedMilliseconds}ms.');

  // --- รวบรวมผลลัพธ์ ---
  final List<ComplexityIssue> allIssues = analysisResults.expand((r) => r.issues).toList();
  // (Optional: Sort issues)
  allIssues.sort((a, b) {
      int severityCompare = _severityValue(a.severity).compareTo(_severityValue(b.severity));
      if (severityCompare != 0) return severityCompare; // Major first
      return b.complexity.compareTo(a.complexity); // Higher complexity first
  });


  // --- สร้างรายงาน ---
  print('📄 Generating reports...');
  try {
    // สร้าง Directory ปลายทาง (ถ้ายังไม่มี)
    final Directory dir = Directory(outputDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      print('   Created output directory: $outputDir');
    }

    // 1. สร้าง JSON Report
    final String jsonContent = reporter.generateJsonReport(allIssues);
    final String jsonPath = p.join(outputDir, defaultJsonName);
    await File(jsonPath).writeAsString(jsonContent);
    print('   💾 JSON report saved to: $jsonPath');

    // 2. สร้าง HTML Report
    final String htmlContent = reporter.generateHtmlReport(allIssues); // อาจจะส่ง analysisResults ทั้งหมดไปถ้าต้องการข้อมูลเพิ่ม
    final String htmlPath = p.join(outputDir, defaultHtmlName);
    await File(htmlPath).writeAsString(htmlContent);
    print('   💾 HTML report saved to: $htmlPath');

    print('✨ Done!');

  } catch (e, s) {
    print('❌ Error generating or saving reports: $e');
    // print(s); // Uncomment for stack trace
    exit(1);
  }
}

// Helper function แปลง Severity เป็นค่าตัวเลขเพื่อเรียงลำดับ
int _severityValue(String severity) {
    switch (severity.toUpperCase()) {
        case 'MAJOR': return 0;
        case 'MINOR': return 1;
        default: return 2;
    }
}


// Helper function ค้นหาไฟล์ .dart ใน paths ที่กำหนด
Future<List<String>> _findDartFiles(List<String> paths) async {
  final List<String> dartFiles = [];
  for (final path in paths) {
    if (await Directory(path).exists()) {
      final dir = Directory(path);
      await dir.list(recursive: true, followLinks: false).forEach((entity) {
        if (entity is File && entity.path.endsWith('.dart')) {
          // กรองไฟล์ generated ออก (ตัวอย่าง)
          if (!entity.path.endsWith('.g.dart') && !entity.path.endsWith('.freezed.dart')) {
            dartFiles.add(entity.path);
          }
        }
      });
    } else if (await File(path).exists()) {
      if (path.endsWith('.dart')) {
        dartFiles.add(path);
      }
    } else {
      print('⚠️ Warning: Path not found or is not a file/directory: $path');
    }
  }
  return dartFiles;
}

// Helper function แสดงวิธีใช้
void _printUsage(ArgParser parser) {
  print('Dart Complexity Analyzer\n');
  print('Usage: dart run complexity_analyzer:<command> [options]\n');
  print('Available commands:');
  parser.commands.forEach((name, commandParser) {
    print('  generate:   Generates complexity analysis reports (JSON and HTML).');
    // เพิ่ม command อื่นๆ ถ้ามี
  });
  print('\nRun "dart run complexity_analyzer:<command> --help" for more information on a command.');
}

// --- อย่าลืมสร้าง class/method ที่จำเป็นใน lib/src/analyzer.dart และ lib/src/reporter.dart ---
// ตัวอย่างคร่าวๆ ของ Analyzer และ Reporter (ต้อง implement รายละเอียดเอง)

// --- In lib/src/analyzer.dart ---
// class ComplexityAnalyzer {
//   Future<AnalysisResult?> analyzeFile(String filePath, int threshold, String relativePath) async {
//     // 1. Read file content using filePath
//     // 2. Preprocess (remove comments/strings)
//     // 3. Find functions (with start lines using original content, names, bodies using cleaned content)
//     // 4. Calculate complexity for each function body
//     // 5. Create ComplexityIssue objects for those > threshold (using relativePath)
//     // 6. Create map of all function complexities
//     // 7. Return AnalysisResult
//     // ... Implementation details ...
//      return AnalysisResult(filePath: relativePath, issues: [], allFunctionComplexities: {}); // Placeholder
//   }
//   // ... other helper methods ...
// }

// --- In lib/src/reporter.dart ---
// import 'dart:convert';
// import 'model.dart';
// import 'package:path/path.dart' as p; // If needed here

// class ComplexityReporter {
//   String generateJsonReport(List<ComplexityIssue> allIssues) {
//     final reportData = {"issues": allIssues.map((issue) => issue.toJsonSonar()).toList()};
//     return JsonEncoder.withIndent('  ').convert(reportData);
//   }

//   String generateHtmlReport(List<ComplexityIssue> allIssues) {
//      // ... Use StringBuffer to build the HTML string ...
//      // ... Similar to the previous generate_html_report.dart logic ...
//      StringBuffer html = StringBuffer();
//      // ... Build HTML structure ...
//      // ... Loop through allIssues and add rows to table ...
//      return html.toString(); // Placeholder
//   }
// }