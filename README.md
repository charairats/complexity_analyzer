# Dart Complexity Analyzer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A tool to analyze the Cyclomatic Complexity (CC) of Dart code and generate summary reports. Helps in measuring and managing code complexity within your projects.

## ✨ Features

- **Cyclomatic Complexity Analysis:** Calculates the CC score for each function/method in the specified Dart files.
- **JSON Report:** Generates a JSON report file adhering to the [SonarQube Generic Issue Data](https://docs.sonarsource.com/sonarqube-cloud/enriching/generic-issue-data/) format, suitable for import into SonarQube or other tools.
- **HTML Report:** Creates a user-friendly HTML report listing functions/methods that exceed the defined complexity threshold, along with details.
- **Command-Line Interface:** Easy to use via command-line commands.
- **Configurable:** Allows customization of the complexity threshold, analysis paths, and output directory.

## ⚙️ Installation

Add `complexity_analyzer` to your `dev_dependencies` in your project's `pubspec.yaml` file, referencing it from its Git repository:

```yaml
dev_dependencies:
  complexity_analyzer:
    git:
      url: https://github.com/charairats/complexity_analyzer.git
      ref: main
```

Then, run the command:

```bash
dart pub get
```

## 🚀 Usage

Use the `dart run complexity_analyzer:complexity` command followed by the `generate` subcommand to initiate the analysis and report generation.

Command Structure:

```bash
dart run complexity_analyzer:complexity generate [options]
```

Examples:

1. Run with defaults:
   - Analyzes files only within the `lib/` directory.
   - Uses the default threshold (10).
   - Generates reports in the complexity/ directory at the project root.
   ```bash
   dart run complexity_analyzer:complexity generate
   ```
2. Set a custom threshold:

   - Set the maximum acceptable CC score to 15.

   ```bash
   dart run complexity_analyzer:complexity generate --threshold 15
   ```

3. Specify analysis paths:
   - Analyze specific files and directories (e.g., `lib/` and `test/`).
   ```bash
   dart run complexity_analyzer:complexity generate --threshold 15
   ```
4. Change the output directory:

   - Save the reports to the build/reports/complexity directory instead.

   ```bash
   dart run complexity_analyzer:complexity generate --output-dir build/reports/complexity
   ```

5. Combine options:

   ```bash
   dart run complexity_analyzer:complexity generate --threshold 12 --paths lib/my_code.dart --output-dir reports
   ```

6. View all options:
   ```bash
   dart run complexity_analyzer:complexity generate --help
   ```

## 📊 Output

Upon successful execution of the `generate` command, report files will be created in the specified output directory (default is `complexity/`):

- `sonar-report.json`: A JSON file formatted according to the SonarQube Generic Issue Data specification. Use this file to import issues (functions exceeding the complexity threshold) into SonarQube.
- `report.html`: An HTML file displaying a user-friendly table of functions/methods that exceed the complexity threshold. This file can be opened directly in a web browser.

* **On Windows:**
    ```bash
    start complexity\report.html
    # Or use the path specified with --output-dir
    start your-output-dir\report.html
    ```
* **On macOS:**
    ```bash
    open complexity/report.html
    # Or use the path specified with --output-dir
    open your-output-dir/report.html
    ```

## 🔧 Options for `generate` Command

- `--threshold` `(-t)`: (Numeric) The maximum acceptable Cyclomatic Complexity score. Defaults to 10.
- `--output-dir` `(-o)`: (String) The directory path where report files will be saved. Defaults to complexity.
- `--paths` `(-p)`: (List&lt;String>) A list of files or directories to analyze. Can be specified multiple times. Defaults to ['lib'].
- `--help` `(-h)`: (Flag) Displays help information for the generate command.

## 📜 License

This project is licensed under the **MIT License**. See the https://www.google.com/search?q=LICENSE file for details.

---

_Generated with assistance from Google Gemini 2.5 Pro ✨_
