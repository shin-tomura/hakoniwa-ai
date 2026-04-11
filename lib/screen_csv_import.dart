import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'main.dart';

// --- 各列のプロファイリング状態を保持するクラス ---
class ColumnProfile {
  String name;
  int role; // 0: Ignore, 1: Input, 2: Output
  int type; // 0: Numeric, 1: Category
  int missingStrategy; // 0: Mean/Mode, 1: Median, 2: Zero/Unknown, 3: Drop Row

  int missingCount = 0;
  Set<String> uniqueValues = {};
  double minVal = double.infinity;
  double maxVal = double.negativeInfinity;
  double sumVal = 0;
  int numericCount = 0;

  ColumnProfile(this.name) : role = 1, type = 0, missingStrategy = 0;
}

class CsvImportConfigScreen extends StatefulWidget {
  const CsvImportConfigScreen({super.key});

  @override
  State<CsvImportConfigScreen> createState() => _CsvImportConfigScreenState();
}

class _CsvImportConfigScreenState extends State<CsvImportConfigScreen> {
  bool _isLoading = false;
  String _statusText = "Please select a CSV file...";

  List<String> _baseHeaders = []; // ★ 元のCSVヘッダーを保持
  List<ColumnProfile> _profiles = [];
  List<List<String>> _sampledData = [];
  String? _csvFilePath;

  int _totalRowCount = 0;
  double _cardinalityThreshold = 0.8;
  final double _missingThreshold = 0.5;

  bool _useEqualSampling = false;

  // --- カスタム特徴量ビルダー用ステート (Formula) ---
  final TextEditingController _featureNameController = TextEditingController();
  List<String> _currentRecipeTokens = [];
  String? _selectedBuilderColumn;
  final List<CustomFeatureRecipe> _customRecipes = [];

  final List<String> _operatorTokens = [
    '+',
    '-',
    '*',
    '/',
    '_',
    'log',
    'exp',
    'sqrt',
    'abs',
  ];
  final List<String> _constantTokens = [
    '1',
    '-1',
    '10',
    '100',
    '0.1',
    '0',
    '(',
    ')',
  ];

  // --- 新機能: データ変換用ステート (Map / Bin) ---
  int _transformMode = 0; // 0: Map, 1: Bin

  // Map(カテゴリ→数値)用
  String? _selectedMapColumn;
  final Map<String, double> _mapBindings = {};
  final TextEditingController _mapFeatureNameController =
      TextEditingController();

  // Bin(数値→カテゴリ)用
  String? _selectedBinColumn;
  final List<Map<String, dynamic>> _binRules = [];
  final TextEditingController _binThreshController = TextEditingController();
  final TextEditingController _binLabelController = TextEditingController();
  final TextEditingController _binDefaultLabelController =
      TextEditingController(text: "Other");
  final TextEditingController _binFeatureNameController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickAndProcessCsv();
    });
  }

  @override
  void dispose() {
    _featureNameController.dispose();
    _mapFeatureNameController.dispose();
    _binThreshController.dispose();
    _binLabelController.dispose();
    _binDefaultLabelController.dispose();
    _binFeatureNameController.dispose();
    super.dispose();
  }

  // --- 堅牢なCSVパーサー ---
  List<String> _parseCsvLine(String line) {
    List<String> result = [];
    StringBuffer buffer = StringBuffer();
    bool insideQuotes = false;

    for (int i = 0; i < line.length; i++) {
      String c = line[i];
      if (c == '"') {
        insideQuotes = !insideQuotes;
      } else if (c == ',' && !insideQuotes) {
        result.add(buffer.toString().trim().replaceAll('"', ''));
        buffer.clear();
      } else {
        buffer.write(c);
      }
    }
    result.add(buffer.toString().trim().replaceAll('"', ''));
    return result;
  }

  // --- 数式評価エンジン (Shunting Yard algorithm) ---
  int _precedence(String op) {
    if (['log', 'exp', 'sqrt', 'abs'].contains(op)) return 4;
    if (op == '*' || op == '/') return 3;
    if (op == '+' || op == '-') return 2;
    if (op == '_') return 1;
    return 0;
  }

  bool _isOperator(String token) {
    return _operatorTokens.contains(token);
  }

  List<String> _toPostfix(List<String> infix) {
    List<String> output = [];
    List<String> ops = [];
    for (String t in infix) {
      if (t == '(') {
        ops.add(t);
      } else if (t == ')') {
        while (ops.isNotEmpty && ops.last != '(') {
          output.add(ops.removeLast());
        }
        if (ops.isNotEmpty) ops.removeLast();
      } else if (_isOperator(t)) {
        while (ops.isNotEmpty && _precedence(ops.last) >= _precedence(t)) {
          output.add(ops.removeLast());
        }
        ops.add(t);
      } else {
        output.add(t);
      }
    }
    while (ops.isNotEmpty) output.add(ops.removeLast());
    return output;
  }

  dynamic _resolveToken(String t, List<String> row, List<String> headers) {
    if (headers.contains(t)) {
      int idx = headers.indexOf(t);
      String val = idx < row.length ? row[idx] : "";
      double? numVal = double.tryParse(val);
      return numVal ?? val;
    }
    double? numTok = double.tryParse(t);
    if (numTok != null) return numTok;
    return t;
  }

  dynamic _calculate(dynamic left, dynamic right, String op) {
    if (op == '_') return "${left.toString()}_${right.toString()}";

    if (left is! double || right is! double) {
      // 型混在時は安全のために強制的に文字列結合 (カテゴリ化)
      return "${left.toString()}_${right.toString()}";
    }

    double l = left;
    double r = right;
    switch (op) {
      case '+':
        return l + r;
      case '-':
        return l - r;
      case '*':
        return l * r;
      case '/':
        return r == 0 ? 0.0 : l / r; // ゼロ除算回避
    }
    return 0.0;
  }

  // 単項演算子（関数）用の計算処理とフェイルセーフ機構
  dynamic _calculateUnary(dynamic val, String op) {
    if (val is! double) return 0.0;

    double v = val;
    switch (op) {
      case 'log':
        // フェイルセーフ: 0以下によるエラーを回避するため、絶対値を取って+1する
        return log(v.abs() + 1.0);
      case 'exp':
        // フェイルセーフ: Infinityやオーバーフロー回避のため、入力を-100〜100の範囲にクランプ
        return exp(v.clamp(-100.0, 100.0));
      case 'sqrt':
        // フェイルセーフ: 負の数によるNaNを回避するため、絶対値の平方根を取る
        return sqrt(v.abs());
      case 'abs':
        return v.abs();
    }
    return 0.0;
  }

  String _evaluateRecipe(
    List<String> tokens,
    List<String> row,
    List<String> headers,
  ) {
    if (tokens.isEmpty) return "0.0";

    // --- 特別な変換ルールの評価 (Map / Bin) ---
    if (tokens.first == '__MAP__') {
      String colName = tokens[1];
      int idx = headers.indexOf(colName);
      String val = idx != -1 && idx < row.length ? row[idx] : "";
      for (int i = 2; i < tokens.length; i += 2) {
        if (tokens[i] == val) return tokens[i + 1];
      }
      return "0.0"; // デフォルト
    }

    if (tokens.first == '__BIN__') {
      String colName = tokens[1];
      int idx = headers.indexOf(colName);
      String val = idx != -1 && idx < row.length ? row[idx] : "";
      double? numVal = double.tryParse(val);
      if (numVal == null) return tokens.last; // パース不可ならデフォルトラベル

      for (int i = 2; i < tokens.length - 1; i += 2) {
        double? thresh = double.tryParse(tokens[i]);
        if (thresh != null && numVal <= thresh) {
          return tokens[i + 1];
        }
      }
      return tokens.last; // どの閾値にも当てはまらない場合
    }

    // --- 通常の数式評価 ---
    // --- 通常の数式評価 ---
    try {
      List<String> postfix = _toPostfix(tokens);
      List<dynamic> stack = [];
      for (String t in postfix) {
        if (_isOperator(t)) {
          if (['log', 'exp', 'sqrt', 'abs'].contains(t)) {
            // 単項演算子（関数）の処理: 1つだけポップする
            if (stack.isEmpty) return "0.0";
            var val = stack.removeLast();
            stack.add(_calculateUnary(val, t));
          } else {
            // 二項演算子の処理: 2つポップする
            if (stack.length < 2) return "0.0";
            var right = stack.removeLast();
            var left = stack.removeLast();
            stack.add(_calculate(left, right, t));
          }
        } else {
          stack.add(_resolveToken(t, row, headers));
        }
      }
      return stack.isNotEmpty ? stack.last.toString() : "0.0";
    } catch (e) {
      return "0.0";
    }
  }

  // ベース行に対して全てのカスタム特徴量を動的に適用する
  List<String> _expandRowWithRecipes(List<String> baseRow) {
    if (_customRecipes.isEmpty) return baseRow;
    List<String> expanded = List.from(baseRow);
    List<String> currentHeaders = List.from(_baseHeaders);
    for (var recipe in _customRecipes) {
      String val = _evaluateRecipe(recipe.tokens, expanded, currentHeaders);
      expanded.add(val);
      currentHeaders.add(recipe.name);
    }
    return expanded;
  }

  // --- CSV初期読み込み ---
  Future<void> _pickAndProcessCsv() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.single.path == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      _csvFilePath = result.files.single.path!;

      setState(() {
        _isLoading = true;
        _statusText =
            "Streaming CSV data...\n(Cool-down & Freeze prevention active)";
      });

      final file = File(_csvFilePath!);
      final lines = file
          .openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      int rowCount = 0;
      List<String> rawSampledLines = [];
      List<String> headers = [];

      Stopwatch coolDownTimer = Stopwatch()..start();
      Stopwatch yieldTimer = Stopwatch()..start();
      int ecoWaitMs = 50;

      await for (var line in lines) {
        if (rowCount == 0) {
          headers = _parseCsvLine(line);
          _baseHeaders = List.from(headers);
          rowCount++;
          continue;
        }

        if (rawSampledLines.length < 10000) {
          rawSampledLines.add(line);
        } else {
          int r = Random().nextInt(rowCount);
          if (r < 10000) {
            rawSampledLines[r] = line;
          }
        }
        rowCount++;

        if (coolDownTimer.elapsedMilliseconds > 500) {
          await Future.delayed(Duration(milliseconds: ecoWaitMs));
          coolDownTimer.reset();
          yieldTimer.reset();
        } else if (yieldTimer.elapsedMilliseconds > 14) {
          await Future.delayed(Duration.zero);
          yieldTimer.reset();
        }
      }

      _totalRowCount = rowCount > 0 ? rowCount - 1 : 0;

      setState(() {
        _statusText =
            "Profiling data...\n(Sampled rows: ${rawSampledLines.length})";
      });

      _profiles = _baseHeaders.map((h) => ColumnProfile(h)).toList();
      _sampledData = [];

      for (var line in rawSampledLines) {
        List<String> row = _parseCsvLine(line);
        _sampledData.add(row);

        for (int i = 0; i < row.length && i < _profiles.length; i++) {
          String val = row[i];
          ColumnProfile p = _profiles[i];

          if (val.isEmpty || val.toLowerCase() == 'nan') {
            p.missingCount++;
            continue;
          }

          p.uniqueValues.add(val);

          double? numVal = double.tryParse(val);
          if (numVal != null) {
            p.sumVal += numVal;
            p.numericCount++;
            if (numVal < p.minVal) p.minVal = numVal;
            if (numVal > p.maxVal) p.maxVal = numVal;
          } else {
            p.type = 1;
          }
        }

        if (coolDownTimer.elapsedMilliseconds > 500) {
          await Future.delayed(Duration(milliseconds: ecoWaitMs));
          coolDownTimer.reset();
          yieldTimer.reset();
        } else if (yieldTimer.elapsedMilliseconds > 14) {
          await Future.delayed(Duration.zero);
          yieldTimer.reset();
        }
      }

      _applyCardinalityFilter();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        _isLoading = false;
        _statusText = "An error occurred: $e";
      });
    }
  }

  void _applyCardinalityFilter() {
    int sampleSize = _sampledData.length;
    if (sampleSize == 0) return;

    for (var p in _profiles) {
      double missingRate = p.missingCount / sampleSize;
      double cardRate = p.uniqueValues.length / sampleSize;

      if (missingRate >= _missingThreshold ||
          cardRate >= _cardinalityThreshold ||
          p.uniqueValues.length <= 1) {
        p.role = 0;
      } else {
        p.role = 1;
      }
    }
  }

  // --- 特徴量追加の共通処理 ---
  void _commitNewFeature(String newName, List<String> tokens) {
    final double scale = ScaleUtil.scale(context);
    List<String> currentHeaders = _profiles.map((p) => p.name).toList();

    _customRecipes.add(CustomFeatureRecipe(newName, List.from(tokens)));
    ColumnProfile newProfile = ColumnProfile(newName);

    for (int i = 0; i < _sampledData.length; i++) {
      String val = _evaluateRecipe(tokens, _sampledData[i], currentHeaders);
      _sampledData[i].add(val);

      if (val.isEmpty || val.toLowerCase() == 'nan') {
        newProfile.missingCount++;
      } else {
        newProfile.uniqueValues.add(val);
        double? numVal = double.tryParse(val);
        if (numVal != null) {
          newProfile.sumVal += numVal;
          newProfile.numericCount++;
          if (numVal < newProfile.minVal) newProfile.minVal = numVal;
          if (numVal > newProfile.maxVal) newProfile.maxVal = numVal;
        } else {
          newProfile.type = 1; // Category
        }
      }
    }

    _profiles.add(newProfile);
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16 * scale),
        content: Text(
          "Feature '$newName' added successfully!",
          style: TextStyle(fontSize: 14 * scale),
        ),
      ),
    );
  }

  void _addFormulaFeature() {
    String newName = _featureNameController.text.trim();
    if (newName.isEmpty || _currentRecipeTokens.isEmpty) return;
    _commitNewFeature(newName, _currentRecipeTokens);
    _currentRecipeTokens.clear();
    _featureNameController.clear();
  }

  // Mapルールの適用
  void _applyMapFeature() {
    String newName = _mapFeatureNameController.text.trim();
    if (newName.isEmpty || _selectedMapColumn == null) return;

    List<String> tokens = ['__MAP__', _selectedMapColumn!];
    _mapBindings.forEach((k, v) {
      tokens.add(k);
      tokens.add(v.toString());
    });

    _commitNewFeature(newName, tokens);
    _mapFeatureNameController.clear();
    // 状態リセット
    _mapBindings.clear();
    _selectedMapColumn = null;
  }

  // Binルールの適用
  void _applyBinFeature() {
    String newName = _binFeatureNameController.text.trim();
    if (newName.isEmpty || _selectedBinColumn == null || _binRules.isEmpty)
      return;

    List<String> tokens = ['__BIN__', _selectedBinColumn!];

    // 閾値でソート (昇順)
    _binRules.sort(
      (a, b) => (a['thresh'] as double).compareTo(b['thresh'] as double),
    );

    for (var rule in _binRules) {
      tokens.add(rule['thresh'].toString());
      tokens.add(rule['label']);
    }
    tokens.add(
      _binDefaultLabelController.text.isNotEmpty
          ? _binDefaultLabelController.text
          : 'Other',
    );

    _commitNewFeature(newName, tokens);

    _binFeatureNameController.clear();
    _binRules.clear();
    _selectedBinColumn = null;
  }

  // Map(カテゴリ→数値)対象カラム選択時の処理
  void _onMapColumnSelected(String? colName) {
    setState(() {
      _selectedMapColumn = colName;
      _mapBindings.clear();
      if (colName != null) {
        var p = _profiles.firstWhere((p) => p.name == colName);
        double counter = 0.0;
        for (var val in p.uniqueValues) {
          _mapBindings[val] = counter;
          counter += 1.0;
        }
      }
    });
  }

  void _showPreviewDialog() {
    final double scale = ScaleUtil.scale(context);
    List<String> currentHeaders = _profiles.map((p) => p.name).toList();
    List<String> results = [];
    int previewCount = min(10, _sampledData.length);
    for (int i = 0; i < previewCount; i++) {
      String res = _evaluateRecipe(
        _currentRecipeTokens,
        _sampledData[i],
        currentHeaders,
      );
      results.add("Row ${i + 1}: $res");
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        insetPadding: EdgeInsets.all(16 * scale),
        title: Text(
          "Formula Preview (First 10 rows)",
          style: TextStyle(color: Colors.white, fontSize: 18 * scale),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: results
                  .map(
                    (r) => Text(
                      r,
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontFamily: 'monospace',
                        fontSize: 14 * scale,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Close", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  // --- モデルビルド＆書き出し ---
  Future<void> _buildAndExportProject() async {
    setState(() {
      _isLoading = true;
      _statusText = "Reconstructing data...\nInitializing model synthesis";
    });

    await Future.delayed(const Duration(milliseconds: 100));

    int ecoWaitMs = 50;
    Stopwatch yieldTimer = Stopwatch()..start();
    Stopwatch coolDownTimer = Stopwatch()..start();

    List<double> precomputedMedians = List.filled(_profiles.length, 0.0);
    List<String> precomputedModes = List.filled(_profiles.length, "");

    for (int c = 0; c < _profiles.length; c++) {
      var p = _profiles[c];
      if (p.role == 0) continue;

      if (p.type == 0) {
        if (p.missingStrategy == 0) {
          double mean = p.numericCount > 0 ? (p.sumVal / p.numericCount) : 0.0;
          precomputedMedians[c] = mean;
        } else if (p.missingStrategy == 1) {
          List<double> nums = [];
          for (var row in _sampledData) {
            if (c < row.length) {
              double? n = double.tryParse(row[c]);
              if (n != null) nums.add(n);
            }
          }
          if (nums.isNotEmpty) {
            nums.sort();
            precomputedMedians[c] = nums[nums.length ~/ 2];
          }
        } else {
          precomputedMedians[c] = 0.0;
        }
      } else {
        if (p.missingStrategy == 0 && p.uniqueValues.isNotEmpty) {
          precomputedModes[c] = p.uniqueValues.first;
        } else {
          precomputedModes[c] = "Unknown";
        }
      }
    }

    bool isEqualSamplingActive = _useEqualSampling && _totalRowCount > 10000;
    int targetOutputColIndex = -1;

    if (isEqualSamplingActive) {
      for (int i = 0; i < _profiles.length; i++) {
        if (_profiles[i].role == 2 && _profiles[i].type == 1) {
          targetOutputColIndex = i;
          break;
        }
      }
      if (targetOutputColIndex == -1) isEqualSamplingActive = false;
    }

    if (isEqualSamplingActive && _csvFilePath != null) {
      setState(() {
        _statusText =
            "Equalizing categories (Pass 1/2)...\nScanning row distributions";
      });
      await Future.delayed(const Duration(milliseconds: 100));

      Map<String, List<int>> categoryRowIndices = {};
      final file = File(_csvFilePath!);
      final lines = file
          .openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      int rowIndex = 0;
      yieldTimer.reset();
      coolDownTimer.reset();

      await for (var line in lines) {
        if (rowIndex == 0) {
          rowIndex++;
          continue;
        }

        // カスタム特徴量を適用して行を展開
        List<String> row = _expandRowWithRecipes(_parseCsvLine(line));

        if (targetOutputColIndex < row.length) {
          String cat = row[targetOutputColIndex];
          if (cat.isEmpty || cat.toLowerCase() == 'nan') {
            cat = precomputedModes[targetOutputColIndex];
          }
          categoryRowIndices.putIfAbsent(cat, () => []).add(rowIndex);
        }
        rowIndex++;

        if (coolDownTimer.elapsedMilliseconds > 500) {
          await Future.delayed(Duration(milliseconds: ecoWaitMs));
          coolDownTimer.reset();
          yieldTimer.reset();
        } else if (yieldTimer.elapsedMilliseconds > 14) {
          await Future.delayed(Duration.zero);
          yieldTimer.reset();
        }
      }

      setState(() {
        _statusText =
            "Equalizing categories (Pass 2/2)...\nExtracting balanced data";
      });
      await Future.delayed(const Duration(milliseconds: 100));

      List<String> categories = categoryRowIndices.keys.toList();
      categories.sort(
        (a, b) => categoryRowIndices[a]!.length.compareTo(
          categoryRowIndices[b]!.length,
        ),
      );

      Set<int> selectedRowIndices = {};
      int remainingQuota = 10000;
      int remainingCategories = categories.length;
      final random = Random();

      for (String cat in categories) {
        int targetCount = remainingQuota ~/ remainingCategories;
        List<int> indices = categoryRowIndices[cat]!;

        if (indices.length <= targetCount) {
          selectedRowIndices.addAll(indices);
          remainingQuota -= indices.length;
        } else {
          indices.shuffle(random);
          selectedRowIndices.addAll(indices.take(targetCount));
          remainingQuota -= targetCount;
        }
        remainingCategories--;
      }

      rowIndex = 0;
      List<List<String>> newSampledData = [];
      final lines2 = file
          .openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      yieldTimer.reset();
      coolDownTimer.reset();

      await for (var line in lines2) {
        if (rowIndex == 0) {
          rowIndex++;
          continue;
        }

        if (selectedRowIndices.contains(rowIndex)) {
          // パス2でも展開する
          newSampledData.add(_expandRowWithRecipes(_parseCsvLine(line)));
        }
        rowIndex++;

        if (coolDownTimer.elapsedMilliseconds > 500) {
          await Future.delayed(Duration(milliseconds: ecoWaitMs));
          coolDownTimer.reset();
          yieldTimer.reset();
        } else if (yieldTimer.elapsedMilliseconds > 14) {
          await Future.delayed(Duration.zero);
          yieldTimer.reset();
        }
      }

      _sampledData = newSampledData;

      for (var row in _sampledData) {
        for (int c = 0; c < _profiles.length; c++) {
          var p = _profiles[c];
          if (p.role == 0) continue;

          String val = c < row.length ? row[c] : "";
          if (val.isEmpty || val.toLowerCase() == 'nan') continue;
          p.uniqueValues.add(val);
        }
      }
    }

    setState(() {
      _statusText = "Building Neural Project...";
    });

    List<FeatureDef> inputDefs = [];
    List<FeatureDef> outputDefs = [];
    List<TrainingData> trainingData = [];

    for (var row in _sampledData) {
      bool shouldDropRow = false;

      for (int c = 0; c < _profiles.length; c++) {
        var p = _profiles[c];
        if (p.role == 0) continue;
        String val = c < row.length ? row[c] : "";
        if ((val.isEmpty || val.toLowerCase() == 'nan') &&
            p.missingStrategy == 3) {
          shouldDropRow = true;
          break;
        }
      }

      if (shouldDropRow) continue;

      List<double> inVals = [];
      List<double> outVals = [];

      for (int c = 0; c < _profiles.length; c++) {
        var p = _profiles[c];
        if (p.role == 0) continue;

        String val = c < row.length ? row[c] : "";
        bool isMissing = val.isEmpty || val.toLowerCase() == 'nan';
        double finalVal = 0.0;

        if (p.type == 0) {
          if (isMissing) {
            finalVal = precomputedMedians[c];
          } else {
            finalVal = double.tryParse(val) ?? precomputedMedians[c];
          }
        } else {
          if (isMissing) {
            val = precomputedModes[c];
          }
          List<String> catList = p.uniqueValues.toList();
          if (p.missingStrategy == 2 && !catList.contains("Unknown")) {
            catList.add("Unknown");
          }

          double idx = catList.indexOf(val).toDouble();
          finalVal = idx == -1.0 ? 0.0 : idx;
        }

        if (p.role == 1) inVals.add(finalVal);
        if (p.role == 2) outVals.add(finalVal);
      }

      if (inVals.isNotEmpty && outVals.isNotEmpty) {
        trainingData.add(TrainingData(inputs: inVals, outputs: outVals));
      }

      if (coolDownTimer.elapsedMilliseconds > 500) {
        await Future.delayed(Duration(milliseconds: ecoWaitMs));
        coolDownTimer.reset();
        yieldTimer.reset();
      } else if (yieldTimer.elapsedMilliseconds > 14) {
        await Future.delayed(Duration.zero);
        yieldTimer.reset();
      }
    }

    for (int c = 0; c < _profiles.length; c++) {
      var p = _profiles[c];
      if (p.role == 0) continue;

      List<String> cats = p.uniqueValues.toList();
      if (p.type == 1 && p.missingStrategy == 2 && !cats.contains("Unknown")) {
        cats.add("Unknown");
      }

      FeatureDef def = FeatureDef(
        name: p.name,
        type: p.type,
        min: p.minVal == double.infinity ? 0 : p.minVal,
        max: p.maxVal == double.negativeInfinity ? 100 : p.maxVal,
        categories: cats,
        missingStrategy: p.missingStrategy,
        fallbackNumeric: p.type == 0 ? precomputedMedians[c] : null,
        fallbackCategory: p.type == 1 ? precomputedModes[c] : null,
      );

      if (p.role == 1) inputDefs.add(def);
      if (p.role == 2) outputDefs.add(def);
    }

    NeuralProject importedProj = NeuralProject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: "Kaggle Dataset",
      inputDefs: inputDefs,
      outputDefs: outputDefs,
      data: trainingData,
      mode: 0,
      engineType: 0,
      customRecipes: _customRecipes,
    );

    if (mounted) {
      context.read<AppState>().saveProject(importedProj);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double scale = ScaleUtil.scale(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black87,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.greenAccent),
              SizedBox(height: 24 * scale),
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16 * scale),
              ),
            ],
          ),
        ),
      );
    }

    int sampleSize = _sampledData.length;

    // リアルタイムミニプレビュー（組み立て中のライブ表示用）
    List<String> miniPreview = [];
    if (_currentRecipeTokens.isNotEmpty && _sampledData.isNotEmpty) {
      List<String> currentHeaders = _profiles.map((p) => p.name).toList();
      int maxP = min(2, _sampledData.length);
      for (int i = 0; i < maxP; i++) {
        miniPreview.add(
          _evaluateRecipe(
            _currentRecipeTokens,
            _sampledData[i],
            currentHeaders,
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Data Preprocessing (Kaggle)",
          style: TextStyle(fontSize: 18 * scale),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.only(bottom: 88 * scale),
        itemCount:
            _profiles.length +
            3, // 0: Config, 1: Formula, 2: Transform, 3+: Profiles
        itemBuilder: (context, index) {
          // --- インデックス0: 全体設定 ---
          if (index == 0) {
            return Container(
              padding: EdgeInsets.all(16 * scale),
              color: Colors.grey.shade900,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_totalRowCount > 10000)
                    Container(
                      margin: EdgeInsets.only(bottom: 12 * scale),
                      padding: EdgeInsets.all(8 * scale),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade900.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4 * scale),
                        border: Border.all(
                          color: Colors.blueAccent.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blueAccent,
                            size: 18 * scale,
                          ),
                          SizedBox(width: 8 * scale),
                          Expanded(
                            child: Text(
                              "Large dataset detected (Total: $_totalRowCount rows).\nProfiling is based on a random sample of 10,000 rows to save memory.",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11 * scale,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Auto-Drop Threshold (Cardinality)",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                            fontSize: 14 * scale,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8 * scale),
                      Text(
                        "${(_cardinalityThreshold * 100).toInt()}%",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14 * scale,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _cardinalityThreshold,
                    min: 0.1,
                    max: 1.0,
                    divisions: 18,
                    activeColor: Colors.greenAccent,
                    onChanged: (val) {
                      setState(() {
                        _cardinalityThreshold = val;
                        _applyCardinalityFilter();
                      });
                    },
                  ),
                  Text(
                    "* Automatically drops columns with too many unique values (e.g., IDs, Tickets).",
                    style: TextStyle(fontSize: 12 * scale, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // --- インデックス1: カスタム特徴量ビルダー (数式) ---
          if (index == 1) {
            return Card(
              margin: EdgeInsets.symmetric(
                horizontal: 12 * scale,
                vertical: 8 * scale,
              ),
              color: Colors.grey.shade900,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.purpleAccent.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(8 * scale),
              ),
              child: Padding(
                padding: EdgeInsets.all(12 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.science,
                          color: Colors.purpleAccent,
                          size: 20 * scale,
                        ),
                        SizedBox(width: 8 * scale),
                        Expanded(
                          // 親のRowなどの残り幅に合わせるために必要
                          child: Text(
                            "Custom Feature Builder (Formula)",
                            style: TextStyle(
                              color: Colors.purpleAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16 * scale,
                            ),
                            overflow: TextOverflow.ellipsis, // はみ出した分を「...」にする
                            maxLines: 1, // 1行に制限する
                            softWrap: false,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8 * scale),

                    // 数式トークンの表示エリア
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(minHeight: 40 * scale),
                      padding: EdgeInsets.all(8 * scale),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: _currentRecipeTokens.isEmpty
                            ? [
                                Text(
                                  "Build formula here...",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12 * scale,
                                  ),
                                ),
                              ]
                            : _currentRecipeTokens.asMap().entries.map((entry) {
                                return Chip(
                                  label: Text(
                                    entry.value,
                                    style: TextStyle(
                                      fontSize: 12 * scale,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: _isOperator(entry.value)
                                      ? Colors.blue.shade900
                                      : Colors.blueGrey.shade800,
                                  deleteIcon: Icon(
                                    Icons.close,
                                    size: 14 * scale,
                                    color: Colors.white70,
                                  ),
                                  onDeleted: () {
                                    setState(() {
                                      _currentRecipeTokens.removeAt(entry.key);
                                    });
                                  },
                                );
                              }).toList(),
                      ),
                    ),
                    SizedBox(height: 8 * scale),

                    Text(
                      "1. Append Column",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12 * scale,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            dropdownColor: Colors.grey.shade800,
                            hint: Text(
                              "Select existing column",
                              style: TextStyle(fontSize: 12 * scale),
                            ),
                            value: _selectedBuilderColumn,
                            items: _profiles
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p.name,
                                    child: Text(
                                      p.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12 * scale),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedBuilderColumn = val;
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.add_circle,
                            color: Colors.greenAccent,
                            size: 28 * scale,
                          ),
                          onPressed: () {
                            if (_selectedBuilderColumn != null) {
                              setState(() {
                                _currentRecipeTokens.add(
                                  _selectedBuilderColumn!,
                                );
                              });
                            }
                          },
                        ),
                      ],
                    ),

                    Text(
                      "2. Append Operator ( _ = concat)",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12 * scale,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: _operatorTokens
                          .map(
                            (op) => ActionChip(
                              label: Text(
                                op,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onPressed: () =>
                                  setState(() => _currentRecipeTokens.add(op)),
                              backgroundColor: Colors.blue.shade800,
                              padding: EdgeInsets.zero,
                            ),
                          )
                          .toList(),
                    ),
                    SizedBox(height: 8 * scale),

                    Text(
                      "3. Append Constant / Symbol",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12 * scale,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _constantTokens
                          .map(
                            (c) => ActionChip(
                              label: Text(c),
                              onPressed: () =>
                                  setState(() => _currentRecipeTokens.add(c)),
                              backgroundColor: Colors.orange.shade800,
                              padding: EdgeInsets.zero,
                            ),
                          )
                          .toList(),
                    ),
                    Divider(color: Colors.grey.shade700, height: 24 * scale),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _featureNameController,
                            decoration: const InputDecoration(
                              hintText: "New Feature Name",
                              filled: true,
                              fillColor: Colors.black54,
                              isDense: true,
                            ),
                            style: TextStyle(fontSize: 14 * scale),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8 * scale),

                    if (miniPreview.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: 8 * scale),
                        child: Text(
                          "Live Preview: ${miniPreview.join(', ')} ...",
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 12 * scale,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton.icon(
                          icon: Icon(Icons.remove_red_eye, size: 16 * scale),
                          label: Text(
                            "Preview 10 Rows",
                            style: TextStyle(fontSize: 12 * scale),
                          ),
                          onPressed: _currentRecipeTokens.isEmpty
                              ? null
                              : _showPreviewDialog,
                        ),
                        ElevatedButton.icon(
                          icon: Icon(Icons.add_task, size: 16 * scale),
                          label: Text(
                            "Add Formula",
                            style: TextStyle(
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade700,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _currentRecipeTokens.isEmpty
                              ? null
                              : _addFormulaFeature,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          // --- インデックス2: データ変換 (Map / Bin) ---
          if (index == 2) {
            return Card(
              margin: EdgeInsets.symmetric(
                horizontal: 12 * scale,
                vertical: 8 * scale,
              ),
              color: Colors.grey.shade900,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.orangeAccent.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(8 * scale),
              ),
              child: Padding(
                padding: EdgeInsets.all(12 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.transform,
                          color: Colors.orangeAccent,
                          size: 20 * scale,
                        ),
                        SizedBox(width: 8 * scale),
                        Expanded(
                          // 親のRowなどの残り幅に合わせるために必要
                          child: Text(
                            "Data Transformation (Map / Bin)",
                            style: TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16 * scale,
                            ),
                            overflow: TextOverflow.ellipsis, // はみ出した分を「...」にする
                            maxLines: 1, // 1行に制限する
                            softWrap: false,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12 * scale),

                    Center(
                      child: SegmentedButton<int>(
                        segments: [
                          ButtonSegment(
                            value: 0,
                            label: Text(
                              "Map (Cat➔Num)",
                              style: TextStyle(fontSize: 12 * scale),
                            ),
                            icon: const Icon(Icons.format_list_numbered),
                          ),
                          ButtonSegment(
                            value: 1,
                            label: Text(
                              "Bin (Num➔Cat)",
                              style: TextStyle(fontSize: 12 * scale),
                            ),
                            icon: const Icon(Icons.filter_alt),
                          ),
                        ],
                        selected: {_transformMode},
                        onSelectionChanged: (val) {
                          setState(() {
                            _transformMode = val.first;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 12 * scale),

                    // --- モード0: Map (カテゴリ → 数値) ---
                    if (_transformMode == 0) ...[
                      Text(
                        "Select Category Column:",
                        style: TextStyle(
                          fontSize: 12 * scale,
                          color: Colors.white70,
                        ),
                      ),
                      DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: Colors.grey.shade800,
                        hint: Text(
                          "Select column to map",
                          style: TextStyle(fontSize: 12 * scale),
                        ),
                        value: _selectedMapColumn,
                        items: _profiles.where((p) => p.type == 1).map((p) {
                          return DropdownMenuItem(
                            value: p.name,
                            child: Text(
                              p.name,
                              style: TextStyle(fontSize: 12 * scale),
                            ),
                          );
                        }).toList(),
                        onChanged: _onMapColumnSelected,
                      ),

                      if (_mapBindings.isNotEmpty) ...[
                        SizedBox(height: 8 * scale),
                        Text(
                          "Assign numerical values:",
                          style: TextStyle(
                            fontSize: 12 * scale,
                            color: Colors.white70,
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(
                            top: 4 * scale,
                            bottom: 8 * scale,
                          ),
                          padding: EdgeInsets.all(8 * scale),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4 * scale),
                          ),
                          child: Column(
                            children: _mapBindings.keys.map((key) {
                              return Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 4 * scale,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        key,
                                        style: TextStyle(
                                          fontSize: 14 * scale,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _mapBindings[key] =
                                              (_mapBindings[key] ?? 0.0) - 1;
                                        });
                                      },
                                    ),
                                    Text(
                                      _mapBindings[key]!.toStringAsFixed(0),
                                      style: TextStyle(
                                        fontSize: 16 * scale,
                                        color: Colors.greenAccent,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        color: Colors.blueAccent,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _mapBindings[key] =
                                              (_mapBindings[key] ?? 0.0) + 1;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],

                      Divider(color: Colors.grey.shade700, height: 24 * scale),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _mapFeatureNameController,
                              decoration: const InputDecoration(
                                hintText: "New Mapped Column Name",
                                filled: true,
                                fillColor: Colors.black54,
                                isDense: true,
                              ),
                              style: TextStyle(fontSize: 14 * scale),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12 * scale),
                      Center(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.add_task, size: 16 * scale),
                          label: Text(
                            "Apply Map Transform",
                            style: TextStyle(
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade800,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _selectedMapColumn != null
                              ? _applyMapFeature
                              : null,
                        ),
                      ),
                    ],

                    // --- モード1: Bin (数値 → カテゴリ) ---
                    if (_transformMode == 1) ...[
                      Text(
                        "Select Numeric Column:",
                        style: TextStyle(
                          fontSize: 12 * scale,
                          color: Colors.white70,
                        ),
                      ),
                      DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: Colors.grey.shade800,
                        hint: Text(
                          "Select column to bin",
                          style: TextStyle(fontSize: 12 * scale),
                        ),
                        value: _selectedBinColumn,
                        items: _profiles.where((p) => p.type == 0).map((p) {
                          return DropdownMenuItem(
                            value: p.name,
                            child: Text(
                              p.name,
                              style: TextStyle(fontSize: 12 * scale),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedBinColumn = val;
                          });
                        },
                      ),

                      if (_binRules.isNotEmpty) ...[
                        SizedBox(height: 8 * scale),
                        Text(
                          "Current Rules (Evaluated sequentially):",
                          style: TextStyle(
                            fontSize: 12 * scale,
                            color: Colors.white70,
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(
                            top: 4 * scale,
                            bottom: 8 * scale,
                          ),
                          padding: EdgeInsets.all(8 * scale),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4 * scale),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ..._binRules.asMap().entries.map((entry) {
                                int idx = entry.key;
                                var rule = entry.value;
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 2 * scale,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        "If <= ${rule['thresh']}",
                                        style: TextStyle(
                                          color: Colors.blueAccent,
                                          fontSize: 13 * scale,
                                        ),
                                      ),
                                      Text(
                                        " ➔ ",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13 * scale,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          "'${rule['label']}'",
                                          style: TextStyle(
                                            color: Colors.greenAccent,
                                            fontSize: 13 * scale,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          size: 16 * scale,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _binRules.removeAt(idx);
                                          });
                                        },
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              Padding(
                                padding: EdgeInsets.only(top: 4 * scale),
                                child: Text(
                                  "Else ➔ '${_binDefaultLabelController.text}'",
                                  style: TextStyle(
                                    color: Colors.orangeAccent,
                                    fontSize: 13 * scale,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: 8 * scale),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _binThreshController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                              decoration: InputDecoration(
                                hintText: "Max Threshold (<=)",
                                hintStyle: TextStyle(fontSize: 12 * scale),
                                filled: true,
                                fillColor: Colors.black54,
                                isDense: true,
                              ),
                              style: TextStyle(fontSize: 14 * scale),
                            ),
                          ),
                          SizedBox(width: 8 * scale),
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _binLabelController,
                              decoration: InputDecoration(
                                hintText: "Target Label",
                                hintStyle: TextStyle(fontSize: 12 * scale),
                                filled: true,
                                fillColor: Colors.black54,
                                isDense: true,
                              ),
                              style: TextStyle(fontSize: 14 * scale),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: Colors.greenAccent,
                            ),
                            onPressed: () {
                              double? t = double.tryParse(
                                _binThreshController.text,
                              );
                              if (t != null &&
                                  _binLabelController.text.isNotEmpty) {
                                setState(() {
                                  _binRules.add({
                                    'thresh': t,
                                    'label': _binLabelController.text,
                                  });
                                  // 視覚的な整列のためにここで一旦ソートしておく
                                  _binRules.sort(
                                    (a, b) => (a['thresh'] as double).compareTo(
                                      b['thresh'] as double,
                                    ),
                                  );
                                  _binThreshController.clear();
                                  _binLabelController.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),

                      SizedBox(height: 8 * scale),
                      Row(
                        children: [
                          Text(
                            "Default Label (Else):",
                            style: TextStyle(
                              fontSize: 12 * scale,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(width: 8 * scale),
                          Expanded(
                            child: TextField(
                              controller: _binDefaultLabelController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.black54,
                                isDense: true,
                                hintText: "e.g., Other",
                                hintStyle: TextStyle(fontSize: 12 * scale),
                              ),
                              style: TextStyle(fontSize: 14 * scale),
                              onChanged: (v) => setState(() {}),
                            ),
                          ),
                        ],
                      ),

                      Divider(color: Colors.grey.shade700, height: 24 * scale),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _binFeatureNameController,
                              decoration: const InputDecoration(
                                hintText: "New Binned Column Name",
                                filled: true,
                                fillColor: Colors.black54,
                                isDense: true,
                              ),
                              style: TextStyle(fontSize: 14 * scale),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12 * scale),
                      Center(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.add_task, size: 16 * scale),
                          label: Text(
                            "Apply Bin Transform",
                            style: TextStyle(
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade800,
                            foregroundColor: Colors.white,
                          ),
                          onPressed:
                              _selectedBinColumn != null && _binRules.isNotEmpty
                              ? _applyBinFeature
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          // --- インデックス3以降: 各列のプロファイルカード ---
          var p = _profiles[index - 3];
          double missingRate =
              p.missingCount / (sampleSize > 0 ? sampleSize : 1);

          return Card(
            margin: EdgeInsets.symmetric(
              horizontal: 12 * scale,
              vertical: 6 * scale,
            ),
            color: p.role == 0 ? Colors.grey.shade800 : Colors.grey.shade900,
            child: Padding(
              padding: EdgeInsets.all(12 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          style: TextStyle(
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.bold,
                            color: p.role == 0 ? Colors.grey : Colors.white,
                            decoration: p.role == 0
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        "Missing: ${(missingRate * 100).toStringAsFixed(1)}% | Unique: ${p.uniqueValues.length}",
                        style: TextStyle(
                          fontSize: 12 * scale,
                          color: missingRate > 0.4
                              ? Colors.redAccent
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4 * scale),
                  Builder(
                    builder: (context) {
                      List<String> examples = p.uniqueValues.take(3).toList();
                      String exampleText = examples.join(', ');
                      if (p.uniqueValues.length > 3) exampleText += ', ...';
                      if (examples.isEmpty) exampleText = "N/A";
                      return Text(
                        "e.g., $exampleText",
                        style: TextStyle(
                          fontSize: 12 * scale,
                          color: Colors.grey.shade400,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                  SizedBox(height: 12 * scale),
                  Opacity(
                    opacity: p.role == 0 ? 0.5 : 1.0,
                    child: Wrap(
                      spacing: 8 * scale,
                      runSpacing: 8 * scale,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SegmentedButton<int>(
                          segments: [
                            ButtonSegment(
                              value: 0,
                              label: Text(
                                "Ignore",
                                style: TextStyle(fontSize: 12 * scale),
                              ),
                            ),
                            ButtonSegment(
                              value: 1,
                              label: Text(
                                "Input",
                                style: TextStyle(fontSize: 12 * scale),
                              ),
                            ),
                            ButtonSegment(
                              value: 2,
                              label: Text(
                                "Output",
                                style: TextStyle(fontSize: 12 * scale),
                              ),
                            ),
                          ],
                          selected: {p.role},
                          onSelectionChanged: (val) {
                            setState(() {
                              p.role = val.first;
                            });
                          },
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        SegmentedButton<int>(
                          segments: [
                            ButtonSegment(
                              value: 0,
                              label: Text(
                                "Numeric",
                                style: TextStyle(fontSize: 12 * scale),
                              ),
                            ),
                            ButtonSegment(
                              value: 1,
                              label: Text(
                                "Category",
                                style: TextStyle(fontSize: 12 * scale),
                              ),
                            ),
                          ],
                          selected: {p.type},
                          onSelectionChanged: (val) {
                            setState(() {
                              p.type = val.first;
                              if (p.type == 1 && p.missingStrategy == 1) {
                                p.missingStrategy = 0;
                              }
                            });
                          },
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        DropdownButton<int>(
                          value: p.missingStrategy,
                          dropdownColor: Colors.grey.shade800,
                          items: [
                            DropdownMenuItem(
                              value: 0,
                              child: Text(
                                p.type == 0
                                    ? "Fill with Mean"
                                    : "Fill with Mode",
                                style: TextStyle(fontSize: 12 * scale),
                              ),
                            ),
                            if (p.type == 0)
                              DropdownMenuItem(
                                value: 1,
                                child: Text(
                                  "Fill with Median",
                                  style: TextStyle(fontSize: 12 * scale),
                                ),
                              ),
                            DropdownMenuItem(
                              value: 2,
                              child: Text(
                                p.type == 0
                                    ? "Fill with Zero (0)"
                                    : "Treat as 'Unknown'",
                                style: TextStyle(fontSize: 12 * scale),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 3,
                              child: Text(
                                "Drop Row",
                                style: TextStyle(
                                  fontSize: 12 * scale,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                p.missingStrategy = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        icon: Icon(Icons.check_circle, size: 24 * scale),
        label: Text(
          "Confirm & Save",
          style: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          bool hasInput = _profiles.any((p) => p.role == 1);
          bool hasOutput = _profiles.any((p) => p.role == 2);
          if (!hasInput || !hasOutput) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Please set at least one Input and one Output column.",
                  style: TextStyle(fontSize: 14 * scale),
                ),
              ),
            );
            return;
          }

          bool hasCategoryOutput = _profiles.any(
            (p) => p.role == 2 && p.type == 1,
          );
          if (_totalRowCount > 10000 && hasCategoryOutput) {
            bool? doEqualize = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: Colors.grey.shade900,
                  title: Text(
                    "Equalized Sampling",
                    style: TextStyle(color: Colors.white, fontSize: 18 * scale),
                  ),
                  content: Text(
                    "This dataset has over 10,000 rows.\nWould you like to enable equalized sampling to balance the number of data points for each category in the Output column?",
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 14 * scale,
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14 * scale,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(null),
                    ),
                    TextButton(
                      child: Text(
                        "No",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14 * scale,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    TextButton(
                      child: Text(
                        "Yes",
                        style: TextStyle(
                          color: Colors.purpleAccent,
                          fontSize: 14 * scale,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                );
              },
            );

            if (doEqualize == null) return;
            setState(() {
              _useEqualSampling = doEqualize;
            });
          } else {
            setState(() {
              _useEqualSampling = false;
            });
          }

          _buildAndExportProject();
        },
      ),
    );
  }
}
