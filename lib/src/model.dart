// lib/src/model.dart
class ComplexityIssue {
  final String filePath; 
  final int startLine;
  final String functionName;
  final int complexity;
  final String severity; 
  final String message;

  ComplexityIssue({
    required this.filePath,
    required this.startLine,
    required this.functionName,
    required this.complexity,
    required this.severity,
    required this.message,
  });

  
  Map<String, dynamic> toJsonSonar() {
    return {
      "engineId": "DartComplexityAnalyzer",
      "ruleId": "HIGH_CYCLOMATIC_COMPLEXITY",
      "severity": severity,
      "type": "CODE_SMELL",
      "primaryLocation": {
        "message": message,
        "filePath": filePath,
        "textRange": {"startLine": startLine}
      }
    };
  }
}

class AnalysisResult {
  final String filePath;
  final List<ComplexityIssue> issues; 
  final Map<String, int> allFunctionComplexities;

  AnalysisResult({
    required this.filePath,
    required this.issues,
    required this.allFunctionComplexities,
  });
}