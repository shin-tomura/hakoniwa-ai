import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:io';
import 'dart:convert'; // ★追加：CSVストリームデコード用
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart'; // ★追加：CSVファイル選択用
import 'main.dart';
import 'nn_engine.dart';
import 'models.dart';
import 'l10n/app_localizations.dart';
import 'code_generators.dart';

class PredictTab extends StatefulWidget {
  const PredictTab({super.key});
  @override
  State<PredictTab> createState() => _PredictTabState();
}

class _PredictTabState extends State<PredictTab> {
  // --- 通常モード用変数 ---
  late List<double> curIn;
  late List<TextEditingController> inCtrls;
  List<dynamic>? results;

  // --- CSVバッチ推論用変数 ---
  bool _isBatchPredicting = false;
  int _batchProcessedRows = 0;

  // --- RF用推論パス追跡 ---
  RFPrediction? _rfLastPred;
  int _rfSelectedTreeIndex = 0;

  // --- 生成AIモード用変数 ---
  final TextEditingController _seedCtrl = TextEditingController();
  String _generatedText = "";
  bool _isGenerating = false;

  List<Map<String, dynamic>>? _stepProbabilities;
  List<Map<String, dynamic>>? _futureProbabilitiesStep1;
  List<Map<String, dynamic>>? _futureProbabilitiesStep2;

  String? _lastInputForStep;
  String? _lastSelectedChar;
  String? _predictedCharStep1;

  double _temperature = 0.5;

  @override
  void initState() {
    super.initState();
    final proj = context.read<ProjectState>().proj;

    if (proj.inputDefs.isNotEmpty) {
      curIn = proj.inputDefs.map((d) => d.type == 1 ? 0.0 : d.min).toList();
      inCtrls = proj.inputDefs
          .map((d) => TextEditingController(text: d.min.toString()))
          .toList();
    } else {
      curIn = [];
      inCtrls = [];
    }
  }

  // ＝＝＝ 👨‍💻 コードエクスポートダイアログ表示 ＝＝＝
  Future<void> _showCodeExportDialog(
    ProjectState state,
    double scale, {
    required String exportLang,
  }) async {
    String code;
    String title;
    String langName;
    Color mainColor;
    String fileName;

    if (exportLang == 'python') {
      code = CodeGenerators.buildPythonCode(state);
      title = "</> Export Python Code";
      langName = "Pure Python";
      mainColor = Colors.yellowAccent;
      fileName = "hakoniwa_model.py";
    } else if (exportLang == 'cpp_legacy') {
      code = CodeGenerators.buildCppLegacyCode(state);
      title = "</> Export C++ Code (Legacy)";
      langName = "Pure C++11 (Legacy)";
      mainColor = Colors.blueAccent;
      fileName = "HakoniwaModel.hpp";
    } else if (exportLang == 'cpp_rich') {
      code = CodeGenerators.buildCppRichCode(state);
      title = "</> Export C++ Code (Rich / ESP32)";
      langName = "Pure C++11 (Rich Mode)";
      mainColor = Colors.blueAccent;
      fileName = "HakoniwaModelRich.hpp";
    } else if (exportLang == 'cpp_baremetal') {
      code = CodeGenerators.buildBareMetalCppCode(state);
      title = "</> Export C++ Code (Bare-Metal)";
      langName = "Pure C++ (Extreme Bare-Metal)";
      mainColor = Colors.blueAccent;
      fileName = "hakoniwa_baremetal.ino";
    } else if (exportLang == 'rust') {
      code = CodeGenerators.buildRustCode(state);
      title = "</> Export Rust Code";
      langName = "Pure Rust";
      mainColor = Colors.orangeAccent;
      fileName = "main.rs";
    } else {
      code = CodeGenerators.buildDartCode(state);
      title = "</> Export Dart Code";
      langName = "Pure Dart";
      mainColor = Colors.cyanAccent;
      fileName = "hakoniwa_model.dart";
    }

    final bool isTooLarge = code.length > 150000;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Text(
            title,
            style: TextStyle(
              color: mainColor,
              fontWeight: FontWeight.bold,
              fontSize: 20 * scale,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "This will export the trained AI inference logic as a $langName code.\nYou can easily run it in your own environment.",
                  style: TextStyle(color: Colors.white70, fontSize: 14 * scale),
                ),
                SizedBox(height: 12 * scale),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(8 * scale),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: mainColor.withOpacity(0.5)),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        code.length > 10000
                            ? "${code.substring(0, 10000)}\n\n... (Preview truncated due to large size) ..."
                            : code,
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 12 * scale,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isTooLarge)
                  Padding(
                    padding: EdgeInsets.only(top: 8 * scale),
                    child: Text(
                      "* The code is too long for the clipboard. Please use 'Save File' to export it as a file.",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13 * scale,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.grey, fontSize: 15 * scale),
              ),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.copy, size: 18 * scale),
              label: Text("Copy", style: TextStyle(fontSize: 15 * scale)),
              onPressed: isTooLarge
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(text: code));
                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Copied to clipboard!")),
                      );
                    },
            ),
            Builder(
              builder: (btnContext) => ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor.withOpacity(0.8),
                  foregroundColor: Colors.white,
                ),
                icon: Icon(Icons.download, size: 18 * scale),
                label: Text(
                  "Save File",
                  style: TextStyle(fontSize: 15 * scale),
                ),
                onPressed: () async {
                  try {
                    final dir = await getTemporaryDirectory();
                    final file = File('${dir.path}/$fileName');
                    await file.writeAsString(code);

                    final box = btnContext.findRenderObject() as RenderBox?;
                    final rect = box != null
                        ? box.localToGlobal(Offset.zero) & box.size
                        : null;

                    await Share.shareXFiles(
                      [XFile(file.path)],
                      text: 'Hakoniwa AI Model Code',
                      sharePositionOrigin: rect,
                    );
                  } catch (e) {
                    debugPrint("Export failed: $e");
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // --- 予測メソッド ---
  List<Map<String, dynamic>> _predictNextCharDistribution(
    ProjectState state,
    String contextText,
  ) {
    int n = state.proj.nGramCount;
    if (contextText.length < n) return [];

    List<double> inputIndices = [];
    for (int i = 0; i < n; i++) {
      double idx = state.proj.currentChars.indexOf(contextText[i]).toDouble();
      inputIndices.add(idx == -1.0 ? 0.0 : idx);
    }

    List<double> encodedInput = state.encodeData(
      inputIndices,
      state.proj.inputDefs,
    );

    List<double> rawPred;
    if (state.proj.engineType == 0) {
      if (encodedInput.length != state.nn!.layerSizes.first) return [];
      rawPred = state.nn!.predict(encodedInput);
    } else {
      if (state.rf == null) return [];
      rawPred = state.rf!.predict(encodedInput).finalOutput;
    }

    List<Map<String, dynamic>> probs = [];
    for (int i = 0; i < rawPred.length; i++) {
      if (i < state.proj.currentChars.length) {
        probs.add({'char': state.proj.currentChars[i], 'prob': rawPred[i]});
      }
    }
    probs.sort((a, b) => (b['prob'] as double).compareTo(a['prob'] as double));
    return probs;
  }

  Future<void> _generateOneChar(ProjectState state, double scale) async {
    String currentText = _seedCtrl.text;
    int n = state.proj.nGramCount;
    final l10n = AppLocalizations.of(context)!;

    String langName = state.proj.langMode == 1
        ? l10n.langEnglish
        : l10n.langHiragana;

    String cleanText = currentText
        .split('')
        .where((c) => state.proj.currentChars.contains(c))
        .join('');

    if (cleanText.length < n) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.msgRequireSeedLength(langName, n),
            style: TextStyle(fontSize: 14 * scale),
          ),
        ),
      );
      return;
    }

    String contextStr = cleanText.substring(cleanText.length - n);
    List<double> inputIndices = [];
    for (int i = 0; i < n; i++) {
      double idx = state.proj.currentChars.indexOf(contextStr[i]).toDouble();
      inputIndices.add(idx == -1.0 ? 0.0 : idx);
    }
    List<double> encodedInput = state.encodeData(
      inputIndices,
      state.proj.inputDefs,
    );

    bool isSizeValid = state.proj.engineType == 0
        ? encodedInput.length == state.nn!.layerSizes.first
        : encodedInput.length == state.rf!.inputSize;

    if (!isSizeValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.errorBrainMismatch(""),
            style: TextStyle(fontSize: 14 * scale),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    List<Map<String, dynamic>> currentProbs = _predictNextCharDistribution(
      state,
      contextStr,
    );

    String selectedChar = "";

    if (_temperature <= 0.05) {
      selectedChar = currentProbs[0]['char'];
    } else {
      final random = Random();
      double weightSum = 0.0;
      List<double> weights = [];

      for (var p in currentProbs) {
        double prob = (p['prob'] as double) <= 0 ? 1e-7 : (p['prob'] as double);
        double w = pow(prob, 1.0 / _temperature).toDouble();
        weights.add(w);
        weightSum += w;
      }

      double r = random.nextDouble() * weightSum;
      for (int i = 0; i < weights.length; i++) {
        r -= weights[i];
        if (r <= 0) {
          selectedChar = currentProbs[i]['char'];
          break;
        }
      }
      if (selectedChar == "") selectedChar = currentProbs.last['char'];
    }

    String textForStep1 = cleanText + selectedChar;
    String nextContext1 = textForStep1;
    if (nextContext1.length > n) {
      nextContext1 = nextContext1.substring(nextContext1.length - n);
    }

    List<Map<String, dynamic>> futureStep1 = _predictNextCharDistribution(
      state,
      nextContext1,
    );

    List<Map<String, dynamic>>? futureStep2;
    String? step1TopChar;

    if (futureStep1.isNotEmpty) {
      step1TopChar = futureStep1[0]['char'];
      String textForStep2 = textForStep1 + step1TopChar!;
      String nextContext2 = textForStep2;
      if (nextContext2.length > n) {
        nextContext2 = nextContext2.substring(nextContext2.length - n);
      }
      futureStep2 = _predictNextCharDistribution(state, nextContext2);
    }

    setState(() {
      _seedCtrl.text = currentText + selectedChar;
      _generatedText = _seedCtrl.text;

      _stepProbabilities = currentProbs.take(5).toList();
      _futureProbabilitiesStep1 = futureStep1.take(3).toList();
      _futureProbabilitiesStep2 = futureStep2?.take(3).toList();

      _lastInputForStep = contextStr;
      _lastSelectedChar = selectedChar;
      _predictedCharStep1 = step1TopChar;

      _seedCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _seedCtrl.text.length),
      );
    });
  }

  Future<void> _generateText(ProjectState state, double scale) async {
    String currentText = _seedCtrl.text;
    int n = state.proj.nGramCount;
    final l10n = AppLocalizations.of(context)!;

    String langName = state.proj.langMode == 1
        ? l10n.langEnglish
        : l10n.langHiragana;

    currentText = currentText
        .split('')
        .where((c) => state.proj.currentChars.contains(c))
        .join('');

    if (currentText.length < n) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.msgRequireSeedLengthFirst(langName, n),
            style: TextStyle(fontSize: 14 * scale),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedText = currentText;
      _stepProbabilities = null;
      _futureProbabilitiesStep1 = null;
      _futureProbabilitiesStep2 = null;
      _lastSelectedChar = null;
    });

    final random = Random();

    for (int step = 0; step < 50; step++) {
      if (!mounted || !_isGenerating) break;

      String contextStr = _generatedText.substring(_generatedText.length - n);
      List<double> inputIndices = [];
      for (int i = 0; i < n; i++) {
        double idx = state.proj.currentChars.indexOf(contextStr[i]).toDouble();
        inputIndices.add(idx == -1.0 ? 0.0 : idx);
      }

      List<double> encodedInput = state.encodeData(
        inputIndices,
        state.proj.inputDefs,
      );

      bool isSizeValid = state.proj.engineType == 0
          ? encodedInput.length == state.nn!.layerSizes.first
          : encodedInput.length == state.rf!.inputSize;

      if (!isSizeValid) {
        setState(() => _isGenerating = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.errorBrainMismatch(""),
                style: TextStyle(fontSize: 14 * scale),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      List<double> rawPred = state.proj.engineType == 0
          ? state.nn!.predict(encodedInput)
          : state.rf!.predict(encodedInput).finalOutput;

      int bestIdx = 0;

      if (_temperature <= 0.05) {
        double maxProb = -1;
        for (int i = 0; i < rawPred.length; i++) {
          if (rawPred[i] > maxProb) {
            maxProb = rawPred[i];
            bestIdx = i;
          }
        }
      } else {
        List<double> weights = [];
        double weightSum = 0.0;
        for (int i = 0; i < rawPred.length; i++) {
          double prob = rawPred[i] <= 0 ? 1e-7 : rawPred[i];
          double w = pow(prob, 1.0 / _temperature).toDouble();
          weights.add(w);
          weightSum += w;
        }
        double r = random.nextDouble() * weightSum;
        for (int i = 0; i < weights.length; i++) {
          r -= weights[i];
          if (r <= 0) {
            bestIdx = i;
            break;
          }
        }
      }

      _generatedText += state.proj.currentChars[bestIdx];

      setState(() {});
      await Future.delayed(const Duration(milliseconds: 50));
    }
    setState(() {
      _isGenerating = false;
    });
  }

  // ＝＝＝ 🚀 追加：出力設定ダイアログ ＝＝＝
  Future<void> _showBatchPredictSettings(
    ProjectState state,
    double scale,
  ) async {
    // Get all output variables
    final allOutputs = state.proj.outputDefs.asMap().entries.toList();

    if (allOutputs.isEmpty) {
      await _batchPredictCSV(state, scale, {}, {});
      return;
    }

    // Set of indices for selected output columns (default: all selected)
    Set<int> selectedOutputs = allOutputs.map((e) => e.key).toSet();

    // Map to hold the output mode for each categorical variable
    // (index -> categoryIndex / null: String output)
    Map<int, int?> outputSettings = {};
    for (var e in allOutputs.where((e) => e.value.type == 1)) {
      outputSettings[e.key] = null;
    }

    bool? proceed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              "CSV Output Settings (Kaggle)",
              style: TextStyle(
                fontSize: 20 * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select columns to include in the output. For categorical variables, you can also specify the output format.",
                    style: TextStyle(fontSize: 16 * scale),
                  ),
                  SizedBox(height: 16 * scale),
                  ...allOutputs.map((entry) {
                    int outIdx = entry.key;
                    FeatureDef def = entry.value;
                    bool isSelected = selectedOutputs.contains(outIdx);
                    bool isCategory = def.type == 1;

                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0 * scale),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Transform.scale(
                                scale: scale, // 🚀 ここで scale 倍に拡大・縮小
                                child: Checkbox(
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    setDialogState(() {
                                      if (value == true) {
                                        selectedOutputs.add(outIdx);
                                      } else {
                                        selectedOutputs.remove(outIdx);
                                      }
                                    });
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 8.0 * scale,
                              ), // 🚀 文字との間隔も scale に合わせる（任意）
                              Expanded(
                                child: Text(
                                  "Variable: ${def.name}${isCategory ? ' (Categorical)' : ' (Numerical)'}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16 * scale,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Only show dropdown if the column is selected AND is a categorical variable
                          if (isSelected && isCategory)
                            Padding(
                              padding: EdgeInsets.only(left: 48.0 * scale),
                              child: DropdownButton<int?>(
                                isExpanded: true,
                                itemHeight: 60.0 * scale,
                                value: outputSettings[outIdx],
                                items: [
                                  DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text(
                                      "String Output (Max Probability)",
                                      style: TextStyle(fontSize: 16 * scale),
                                    ),
                                  ),
                                  ...def.categories.asMap().entries.map((
                                    catEntry,
                                  ) {
                                    return DropdownMenuItem<int?>(
                                      value: catEntry.key,
                                      child: Text(
                                        "Probability Output: ${catEntry.value}",
                                        style: TextStyle(fontSize: 16 * scale),
                                      ),
                                    );
                                  }),
                                ],
                                onChanged: (val) {
                                  setDialogState(() {
                                    outputSettings[outIdx] = val;
                                  });
                                },
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel", style: TextStyle(fontSize: 16 * scale)),
              ),
              ElevatedButton(
                // Disable button if no columns are selected
                onPressed: selectedOutputs.isEmpty
                    ? null
                    : () => Navigator.pop(context, true),
                child: Text(
                  "Start Prediction",
                  style: TextStyle(fontSize: 16 * scale),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (proceed == true) {
      await _batchPredictCSV(state, scale, selectedOutputs, outputSettings);
    }
  }

  // ＝＝＝ 🚀 CSV一括推論処理（Kaggle提出用対応・特徴量レシピ動的展開版） ＝＝＝
  Future<void> _batchPredictCSV(
    ProjectState state,
    double scale,
    Set<int> selectedOutputs, // Selected output column indices
    Map<int, int?> outputSettings,
  ) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result == null) return;
      String inputPath = result.files.single.path!;

      setState(() {
        _isBatchPredicting = true;
        _batchProcessedRows = 0;
      });

      Directory dir = await getTemporaryDirectory();
      String outputPath = '${dir.path}/submission.csv';
      File outFile = File(outputPath);
      var sink = outFile.openWrite();

      Stopwatch coolDownTimer = Stopwatch()..start();
      Stopwatch yieldTimer = Stopwatch()..start();
      int ecoWaitMs = state.proj.ecoWaitMs;

      File inFile = File(inputPath);
      Stream<String> lines = inFile
          .openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      List<String> parseCsvLine(String line) {
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

      // --- 特徴量レシピ評価用のローカル関数 ---
      bool isOperator(String token) => [
        '+',
        '-',
        '*',
        '/',
        '_',
        'log',
        'exp',
        'sqrt',
        'abs',
      ].contains(token);

      int precedence(String op) {
        if (['log', 'exp', 'sqrt', 'abs'].contains(op)) return 4;
        if (op == '*' || op == '/') return 3;
        if (op == '+' || op == '-') return 2;
        if (op == '_') return 1;
        return 0;
      }

      List<String> toPostfix(List<String> infix) {
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
          } else if (isOperator(t)) {
            while (ops.isNotEmpty && precedence(ops.last) >= precedence(t)) {
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

      dynamic resolveToken(String t, List<String> row, List<String> headers) {
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

      dynamic calculate(dynamic left, dynamic right, String op) {
        if (op == '_') return "${left.toString()}_${right.toString()}";
        if (left is! double || right is! double) {
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
            return r == 0 ? 0.0 : l / r;
        }
        return 0.0;
      }

      dynamic calculateUnary(dynamic val, String op) {
        if (val is! double) return 0.0;
        double v = val;
        switch (op) {
          case 'log':
            return log(v.abs() + 1.0);
          case 'exp':
            return exp(v.clamp(-100.0, 100.0));
          case 'sqrt':
            return sqrt(v.abs());
          case 'abs':
            return v.abs();
        }
        return 0.0;
      }

      String evaluateRecipe(
        List<String> tokens,
        List<String> row,
        List<String> headers,
      ) {
        try {
          List<String> postfix = toPostfix(tokens);
          List<dynamic> stack = [];
          for (String t in postfix) {
            if (isOperator(t)) {
              if (['log', 'exp', 'sqrt', 'abs'].contains(t)) {
                // 単項演算子の処理
                if (stack.isEmpty) return "0.0";
                var val = stack.removeLast();
                stack.add(calculateUnary(val, t));
              } else {
                // 二項演算子の処理
                if (stack.length < 2) return "0.0";
                var right = stack.removeLast();
                var left = stack.removeLast();
                stack.add(calculate(left, right, t));
              }
            } else {
              stack.add(resolveToken(t, row, headers));
            }
          }
          return stack.isNotEmpty ? stack.last.toString() : "0.0";
        } catch (e) {
          return "0.0";
        }
      }
      // ----------------------------------------

      bool isFirstLine = true;
      Map<int, FeatureDef> colToInputDef = {};
      int? idColumnIndex;
      String idColumnName = "id";
      List<String> baseHeaders = [];

      await for (String line in lines) {
        if (!_isBatchPredicting) break;

        List<String> tokens = parseCsvLine(line);

        if (isFirstLine) {
          baseHeaders = List.from(tokens);
          List<String> currentHeaders = List.from(baseHeaders);

          for (var recipe in state.proj.customRecipes) {
            currentHeaders.add(recipe.name);
          }

          for (int i = 0; i < currentHeaders.length; i++) {
            String colName = currentHeaders[i];
            bool matched = false;
            for (var def in state.proj.inputDefs) {
              if (def.name.trim().toLowerCase() == colName.toLowerCase()) {
                colToInputDef[i] = def;
                matched = true;
                break;
              }
            }
            if (!matched && idColumnIndex == null) {
              idColumnIndex = i;
              idColumnName = colName;
            }
          }

          if (colToInputDef.isEmpty) {
            idColumnIndex = 0;
            idColumnName = currentHeaders.isNotEmpty ? currentHeaders[0] : "id";
            int inputDefIdx = 0;
            for (int i = 1; i < currentHeaders.length; i++) {
              if (inputDefIdx < state.proj.inputDefs.length) {
                colToInputDef[i] = state.proj.inputDefs[inputDefIdx];
                inputDefIdx++;
              }
            }
          }

          // Build header based on selected outputs
          String outHeader = "";
          if (idColumnIndex != null) outHeader += "$idColumnName,";

          List<String> outputHeaderNames = [];
          for (int i = 0; i < state.proj.outputDefs.length; i++) {
            if (selectedOutputs.contains(i)) {
              outputHeaderNames.add(state.proj.outputDefs[i].name);
            }
          }
          outHeader += outputHeaderNames.join(',');
          sink.writeln(outHeader);

          isFirstLine = false;
          continue;
        }

        // --- データ行の動的展開（特徴量エンジニアリング） ---
        List<String> expandedRow = List.from(tokens);
        List<String> runningHeaders = List.from(baseHeaders);

        for (var recipe in state.proj.customRecipes) {
          String newVal = evaluateRecipe(
            recipe.tokens,
            expandedRow,
            runningHeaders,
          );
          expandedRow.add(newVal);
          runningHeaders.add(recipe.name);
        }
        // ----------------------------------------

        String outLine = "";
        if (idColumnIndex != null && expandedRow.length > idColumnIndex) {
          outLine += "${expandedRow[idColumnIndex]},";
        }

        List<double> currentInputs = List.filled(
          state.proj.inputDefs.length,
          0.0,
        );

        for (int i = 0; i < state.proj.inputDefs.length; i++) {
          FeatureDef def = state.proj.inputDefs[i];
          int csvColIdx = -1;
          colToInputDef.forEach((key, value) {
            if (value == def) csvColIdx = key;
          });

          String valStr = (csvColIdx != -1 && csvColIdx < expandedRow.length)
              ? expandedRow[csvColIdx]
              : "";
          bool isMissing = valStr.isEmpty || valStr.toLowerCase() == 'nan';

          if (def.type == 0 || def.type == 2) {
            double fallback = def.fallbackNumeric ?? def.min;
            currentInputs[i] = isMissing
                ? fallback
                : (double.tryParse(valStr) ?? fallback);
          } else if (def.type == 1) {
            String fallback =
                def.fallbackCategory ??
                (def.categories.isNotEmpty ? def.categories.first : "");
            String targetVal = isMissing ? fallback : valStr;
            int catIdx = def.categories.indexOf(targetVal);
            if (catIdx == -1) {
              catIdx = def.categories.indexOf(fallback);
              if (catIdx == -1 && def.categories.contains("Unknown")) {
                catIdx = def.categories.indexOf("Unknown");
              }
            }
            currentInputs[i] = catIdx >= 0 ? catIdx.toDouble() : 0.0;
          }
        }

        List<double> encodedInput = state.encodeData(
          currentInputs,
          state.proj.inputDefs,
        );
        List<double> rawOut;
        if (state.proj.engineType == 0) {
          rawOut = state.nn!.predict(encodedInput);
        } else {
          rawOut = state.rf!.predict(encodedInput).finalOutput;
        }

        List<dynamic> results = state.decodePrediction(
          rawOut,
          state.proj.outputDefs,
        );
        List<String> outValues = [];

        // Build output line based on selected outputs
        for (int j = 0; j < state.proj.outputDefs.length; j++) {
          if (!selectedOutputs.contains(j)) continue; // Skip unselected columns

          FeatureDef def = state.proj.outputDefs[j];
          if (def.type == 0 || def.type == 2) {
            double val = (results[j] is double)
                ? results[j]
                : (results[j][0] as double);
            outValues.add(val.toStringAsFixed(4));
          } else if (def.type == 1) {
            List<double> probs = results[j] as List<double>;

            int? targetCatIdx = outputSettings[j];

            if (targetCatIdx == null) {
              int maxIdx = 0;
              for (int k = 1; k < probs.length; k++) {
                if (probs[k] > probs[maxIdx]) maxIdx = k;
              }
              if (maxIdx < def.categories.length) {
                outValues.add(def.categories[maxIdx]);
              } else {
                outValues.add(def.categories.first);
              }
            } else {
              double prob = (targetCatIdx < probs.length)
                  ? probs[targetCatIdx]
                  : 0.0;
              outValues.add(prob.toStringAsFixed(4));
            }
          }
        }

        outLine += outValues.join(',');
        sink.writeln(outLine);

        _batchProcessedRows++;

        if (coolDownTimer.elapsedMilliseconds > 500) {
          if (ecoWaitMs > 0) {
            await Future.delayed(Duration(milliseconds: ecoWaitMs));
          } else {
            await Future.delayed(Duration.zero);
          }
          coolDownTimer.reset();
          yieldTimer.reset();
          setState(() {});
        } else if (yieldTimer.elapsedMilliseconds > 14) {
          await Future.delayed(Duration.zero);
          yieldTimer.reset();
        }
      }

      await sink.flush();
      await sink.close();
      setState(() => _isBatchPredicting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Completed: $_batchProcessedRows rows predicted."),
            backgroundColor: Colors.green,
          ),
        );
        final size = MediaQuery.of(context).size;
        await Share.shareXFiles(
          [XFile(outFile.path)],
          text: 'submission.csv',
          subject: 'Kaggle Submission File',
          sharePositionOrigin: Rect.fromLTWH(
            size.width / 2,
            size.height / 2,
            1,
            1,
          ),
        );
      }
    } catch (e) {
      setState(() => _isBatchPredicting = false);
      print("Batch Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Batch Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProjectState>();
    final proj = state.proj;
    final double scale = ScaleUtil.scale(context);
    final l10n = AppLocalizations.of(context)!;

    if (state.nn == null && state.rf == null) {
      return Center(
        child: Text(
          l10n.msgTrainFirst,
          style: TextStyle(color: Colors.redAccent, fontSize: 16 * scale),
        ),
      );
    }

    Widget content;

    // ＝＝＝ 💬 生成AIモードのUI ＝＝＝
    if (proj.mode == 1) {
      int n = proj.nGramCount;
      String exampleText = proj.langMode == 1
          ? "Once upon a time"
          : "むかしむかしあるところに";

      content = SingleChildScrollView(
        padding: EdgeInsets.all(16.0 * scale),
        child: Column(
          children: [
            Text(
              l10n.writeAiContinuation,
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 16 * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16 * scale),

            TextField(
              controller: _seedCtrl,
              minLines: 1,
              maxLines: 5,
              maxLength: 1000,
              keyboardType: TextInputType.multiline,
              style: TextStyle(fontSize: 16 * scale),
              decoration: InputDecoration(
                labelText: l10n.hintSeedText(n, exampleText),
                labelStyle: TextStyle(fontSize: 14 * scale),
                hintText: l10n.hintSeedTextPlaceholder,
                hintStyle: TextStyle(fontSize: 14 * scale),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _seedCtrl.clear();
                    if (_stepProbabilities != null) {
                      setState(() {
                        _stepProbabilities = null;
                        _futureProbabilitiesStep1 = null;
                        _futureProbabilitiesStep2 = null;
                        _lastSelectedChar = null;
                      });
                    }
                  },
                ),
              ),
              onChanged: (_) {
                if (_stepProbabilities != null) {
                  setState(() {
                    _stepProbabilities = null;
                    _futureProbabilitiesStep1 = null;
                    _futureProbabilitiesStep2 = null;
                    _lastSelectedChar = null;
                  });
                }
              },
            ),
            SizedBox(height: 16 * scale),

            Row(
              children: [
                Text(
                  l10n.temperatureLabelShort,
                  style: TextStyle(fontSize: 12 * scale),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0 * scale),
                    child: Slider(
                      value: _temperature,
                      min: 0.0,
                      max: 2.0,
                      divisions: 20,
                      label: _temperature.toStringAsFixed(1),
                      onChanged: _isGenerating
                          ? null
                          : (v) => setState(() => _temperature = v),
                    ),
                  ),
                ),
                SizedBox(
                  width: 32 * scale,
                  child: Text(
                    _temperature.toStringAsFixed(1),
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 14 * scale),
                  ),
                ),
              ],
            ),
            Text(
              l10n.temperatureNote,
              style: TextStyle(fontSize: 11 * scale, color: Colors.grey),
            ),
            SizedBox(height: 16 * scale),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isGenerating
                          ? Colors.red
                          : Colors.green.shade800,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: 16 * scale,
                        horizontal: 4 * scale,
                      ),
                    ),
                    onPressed: () {
                      if (_isGenerating) {
                        setState(() => _isGenerating = false);
                      } else {
                        _generateText(state, scale);
                      }
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isGenerating ? Icons.stop : Icons.auto_awesome,
                            size: 20 * scale,
                          ),
                          SizedBox(width: 8 * scale),
                          Text(
                            _isGenerating ? l10n.btnStop : l10n.btnAutoGenerate,
                            style: TextStyle(fontSize: 14 * scale),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8 * scale),
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey.shade800,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: 16 * scale,
                        horizontal: 4 * scale,
                      ),
                      side: BorderSide(
                        color: Colors.cyanAccent.withOpacity(0.5),
                      ),
                    ),
                    onPressed: _isGenerating
                        ? null
                        : () => _generateOneChar(state, scale),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.skip_next, size: 20 * scale),
                          SizedBox(width: 8 * scale),
                          Text(
                            l10n.btnStepForward,
                            style: TextStyle(fontSize: 14 * scale),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16 * scale),

            if (_stepProbabilities != null) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12 * scale),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(8 * scale),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.aiThinkingTitle(_lastInputForStep ?? ""),
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14 * scale,
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.aiDecision,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12 * scale,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              SizedBox(height: 4 * scale),
                              ...List.generate(_stepProbabilities!.length, (
                                index,
                              ) {
                                final item = _stepProbabilities![index];
                                final double prob = item['prob'] as double;
                                final String char = item['char'] as String;
                                final bool isSelected =
                                    char == _lastSelectedChar;

                                return Padding(
                                  padding: EdgeInsets.only(bottom: 3.0 * scale),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 15 * scale,
                                        child: Text(
                                          "${index + 1}.",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 11 * scale,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 20 * scale,
                                        alignment: Alignment.center,
                                        child: Text(
                                          char,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14 * scale,
                                            color: isSelected
                                                ? Colors.cyanAccent
                                                : Colors.white,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: LinearProgressIndicator(
                                          value: prob.clamp(0.0, 1.0),
                                          backgroundColor: Colors.black,
                                          color: isSelected
                                              ? Colors.cyanAccent
                                              : Colors.blueGrey,
                                          minHeight: 6 * scale,
                                        ),
                                      ),
                                      SizedBox(width: 4 * scale),
                                      SizedBox(
                                        width: 35 * scale,
                                        child: Text(
                                          "${(prob * 100).toStringAsFixed(0)}%",
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontSize: 10 * scale,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 120 * scale,
                          color: Colors.grey.shade800,
                          margin: EdgeInsets.symmetric(horizontal: 8 * scale),
                        ),
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.step1Future(_lastSelectedChar ?? ""),
                                style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 11 * scale,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2 * scale),
                              if (_futureProbabilitiesStep1 != null)
                                ..._futureProbabilitiesStep1!.map(
                                  (item) => _buildMiniProbRow(
                                    item,
                                    scale,
                                    Colors.cyanAccent,
                                  ),
                                ),
                              SizedBox(height: 4 * scale),
                              Center(
                                child: Icon(
                                  Icons.arrow_downward,
                                  size: 16 * scale,
                                  color: Colors.white30,
                                ),
                              ),
                              SizedBox(height: 4 * scale),
                              Text(
                                l10n.step2Future(_predictedCharStep1 ?? ""),
                                style: TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 11 * scale,
                                ),
                              ),
                              SizedBox(height: 2 * scale),
                              if (_futureProbabilitiesStep2 != null)
                                ..._futureProbabilitiesStep2!.map(
                                  (item) => _buildMiniProbRow(
                                    item,
                                    scale,
                                    Colors.orangeAccent,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16 * scale),
            ],

            SizedBox(height: 16 * scale),

            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      l10n.generationResultTitle,
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16 * scale,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20 * scale,
                    color: Colors.grey,
                  ),
                  tooltip: l10n.tooltipClearResult,
                  onPressed: () {
                    setState(() {
                      _generatedText = "";
                    });
                  },
                ),
                TextButton.icon(
                  icon: Icon(Icons.copy, size: 18 * scale),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      l10n.btnCopyAll,
                      style: TextStyle(fontSize: 14 * scale),
                    ),
                  ),
                  onPressed: _generatedText.isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(
                            ClipboardData(text: _generatedText),
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.msgTextCopied,
                                style: TextStyle(fontSize: 14 * scale),
                              ),
                            ),
                          );
                        },
                ),
              ],
            ),
            SizedBox(height: 8 * scale),

            Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: 150 * scale),
              padding: EdgeInsets.all(16 * scale),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8 * scale),
                border: Border.all(
                  color: Colors.green.shade900,
                  width: 2 * scale,
                ),
              ),
              child: SelectableText(
                _generatedText,
                style: TextStyle(
                  fontSize: 18 * scale,
                  height: 1.8,
                  letterSpacing: 1.2 * scale,
                ),
              ),
            ),
            SizedBox(height: 32 * scale),

            // ★ 開発者向け機能：コードエクスポートボタン
            Divider(color: Colors.cyan.withOpacity(0.5), thickness: 1),
            SizedBox(height: 8 * scale),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.cyanAccent,
                  side: BorderSide(color: Colors.cyan.shade800),
                  padding: EdgeInsets.symmetric(vertical: 16 * scale),
                ),
                label: Text(
                  "Export Dart Code",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16 * scale,
                  ),
                ),
                onPressed: () =>
                    _showCodeExportDialog(state, scale, exportLang: "dart"),
              ),
            ),
            SizedBox(height: 16 * scale),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.yellowAccent,
                  side: BorderSide(color: Colors.yellow.shade800),
                  padding: EdgeInsets.symmetric(vertical: 16 * scale),
                ),
                label: Text(
                  "Export Python Code",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16 * scale,
                  ),
                ),
                onPressed: () =>
                    _showCodeExportDialog(state, scale, exportLang: "python"),
              ),
            ),
            SizedBox(height: 16 * scale),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blueAccent,
                  side: BorderSide(color: Colors.blue.shade800),
                  padding: EdgeInsets.symmetric(vertical: 16 * scale),
                ),
                label: Text(
                  "Export C++ (General / PC)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16 * scale,
                  ),
                ),
                onPressed: () => _showCodeExportDialog(
                  state,
                  scale,
                  exportLang: "cpp_legacy",
                ),
              ),
            ),
            SizedBox(height: 16 * scale),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blueAccent,
                  side: BorderSide(color: Colors.blue.shade800),
                  padding: EdgeInsets.symmetric(vertical: 16 * scale),
                ),
                label: Text(
                  "Export C++ (ESP32 / Rich)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16 * scale,
                  ),
                ),
                onPressed: () =>
                    _showCodeExportDialog(state, scale, exportLang: "cpp_rich"),
              ),
            ),
            SizedBox(height: 16 * scale),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blueAccent,
                  side: BorderSide(color: Colors.blue.shade800),
                  padding: EdgeInsets.symmetric(vertical: 16 * scale),
                ),
                label: Text(
                  "Export C++ (Arduino / Bare-Metal)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16 * scale,
                  ),
                ),
                onPressed: () => _showCodeExportDialog(
                  state,
                  scale,
                  exportLang: "cpp_baremetal",
                ),
              ),
            ),
            SizedBox(height: 16 * scale),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orangeAccent,
                  side: BorderSide(color: Colors.orange.shade800),
                  padding: EdgeInsets.symmetric(vertical: 16 * scale),
                ),
                label: Text(
                  "Export Rust Code",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16 * scale,
                  ),
                ),
                onPressed: () =>
                    _showCodeExportDialog(state, scale, exportLang: "rust"),
              ),
            ),
            SizedBox(height: 40 * scale),
          ],
        ),
      );
    }
    // ＝＝＝ 📊 通常モードのUI ＝＝＝
    else {
      content = ListView(
        padding: EdgeInsets.all(16 * scale),
        children: [
          ...List.generate(proj.inputDefs.length, (i) {
            final def = proj.inputDefs[i];
            if (def.type == 0) {
              return Row(
                children: [
                  SizedBox(
                    width: 80 * scale,
                    child: Text(
                      def.name,
                      style: TextStyle(fontSize: 14 * scale),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0 * scale),
                      child: Slider(
                        value: curIn[i],
                        min: def.min,
                        max: def.max,
                        onChanged: (v) => setState(() => curIn[i] = v),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40 * scale,
                    child: Text(
                      curIn[i].toStringAsFixed(1),
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 14 * scale),
                    ),
                  ),
                ],
              );
            } else if (def.type == 1) {
              return Row(
                children: [
                  SizedBox(
                    width: 80 * scale,
                    child: Text(
                      def.name,
                      style: TextStyle(fontSize: 14 * scale),
                    ),
                  ),
                  Expanded(
                    child: DropdownButton<double>(
                      isExpanded: true,
                      value: curIn[i],
                      itemHeight: null,
                      items: List.generate(
                        def.categories.length,
                        (c) => DropdownMenuItem(
                          value: c.toDouble(),
                          child: Text(
                            def.categories[c],
                            style: TextStyle(fontSize: 16 * scale),
                          ),
                        ),
                      ),
                      onChanged: (v) => setState(() => curIn[i] = v!),
                    ),
                  ),
                ],
              );
            } else {
              return Row(
                children: [
                  SizedBox(
                    width: 80 * scale,
                    child: Text(
                      def.name,
                      style: TextStyle(fontSize: 14 * scale),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: inCtrls[i],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      style: TextStyle(fontSize: 16 * scale),
                      onChanged: (v) =>
                          curIn[i] = double.tryParse(v) ?? def.min,
                    ),
                  ),
                ],
              );
            }
          }),
          SizedBox(height: 16 * scale),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade800,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16 * scale),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8 * scale),
              ),
            ),
            onPressed: () {
              List<double> encodedInput = state.encodeData(
                curIn,
                proj.inputDefs,
              );

              List<double> rawOut;
              if (proj.engineType == 0) {
                rawOut = state.nn!.predict(encodedInput);
                _rfLastPred = null;
              } else {
                _rfLastPred = state.rf!.predict(encodedInput);
                rawOut = _rfLastPred!.finalOutput;
                _rfSelectedTreeIndex = 0;
              }

              setState(
                () => results = state.decodePrediction(rawOut, proj.outputDefs),
              );
            },
            child: Text(
              l10n.btnPredictNormal,
              style: TextStyle(
                fontSize: 16 * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // ★追加：CSV一括推論UI（Kaggle提出ファイル出力）
          SizedBox(height: 16 * scale),
          if (_isBatchPredicting) ...[
            Container(
              padding: EdgeInsets.all(16 * scale),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade900,
                borderRadius: BorderRadius.circular(8 * scale),
                border: Border.all(color: Colors.cyanAccent),
              ),
              child: Column(
                children: [
                  Text(
                    "Processing CSV... $_batchProcessedRows rows",
                    style: TextStyle(color: Colors.white, fontSize: 16 * scale),
                  ),
                  SizedBox(height: 16 * scale),
                  const LinearProgressIndicator(color: Colors.cyanAccent),
                  SizedBox(height: 16 * scale),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => setState(() => _isBatchPredicting = false),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            /*Container(
              padding: EdgeInsets.all(12 * scale),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8 * scale),
                border: Border.all(color: Colors.blueGrey),
              ),
              child: Text(
                "[Kaggle Submission Format]\n"
                "Ensure the first (leftmost) column of your test CSV contains an identifier, such as 'id'.\n"
                "The exported submission.csv will be generated in the 'id, prediction' format.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13 * scale,
                  height: 1.4,
                ),
              ),
            ),
            SizedBox(height: 12 * scale),*/
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade800,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16 * scale),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
                side: BorderSide(color: Colors.cyanAccent.withOpacity(0.5)),
              ),
              onPressed: () => _showBatchPredictSettings(state, scale),
              icon: Icon(Icons.file_upload, size: 24 * scale),
              label: Text(
                "Batch Predict (CSV to Submission)",
                style: TextStyle(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],

          Divider(color: Colors.green, thickness: 2 * scale),

          if (results != null)
            ...List.generate(proj.outputDefs.length, (i) {
              final def = proj.outputDefs[i];
              if (def.type == 0 || def.type == 2) {
                return Padding(
                  padding: EdgeInsets.all(8 * scale),
                  child: Text(
                    l10n.predictionResult(
                      def.name,
                      results![i].toStringAsFixed(2),
                    ),
                    style: TextStyle(
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              } else {
                List<double> probs = results![i] as List<double>;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.judgmentResult(def.name),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16 * scale,
                      ),
                    ),
                    ...List.generate(
                      def.categories.length,
                      (c) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 4 * scale),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80 * scale,
                              child: Text(
                                def.categories[c],
                                style: TextStyle(fontSize: 14 * scale),
                              ),
                            ),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: probs[c],
                                backgroundColor: Colors.grey.shade800,
                                color: Colors.green,
                                minHeight: 12 * scale,
                              ),
                            ),
                            SizedBox(width: 8 * scale),
                            SizedBox(
                              width: 50 * scale,
                              child: Text(
                                "${(probs[c] * 100).toStringAsFixed(1)}%",
                                textAlign: TextAlign.right,
                                style: TextStyle(fontSize: 14 * scale),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16 * scale),
                  ],
                );
              }
            }),

          // ランダムフォレスト「決定木の解剖図」への遷移UI
          if (proj.engineType == 1 &&
              state.rf != null &&
              _rfLastPred != null) ...[
            Divider(color: Colors.lightGreenAccent, thickness: 1 * scale),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8 * scale),
              child: Row(
                children: [
                  Icon(
                    Icons.park,
                    color: Colors.lightGreenAccent,
                    size: 20 * scale,
                  ),
                  SizedBox(width: 8 * scale),
                  Expanded(
                    child: Text(
                      "Decision Tree Explorer",
                      style: TextStyle(
                        color: Colors.lightGreenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16 * scale,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              ui.PlatformDispatcher.instance.locale.languageCode != 'ja'
                  ? "Tap the button below to expand and explore how the AI decided."
                  : "下のボタンをタップすると、AIがどのように判断を下したかを拡大して確認できます。",
              style: TextStyle(color: Colors.white70, fontSize: 12 * scale),
            ),
            SizedBox(height: 12 * scale),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreen.shade900,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12 * scale),
                side: BorderSide(
                  color: Colors.lightGreenAccent.withOpacity(0.5),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RFTreeExplorerScreen(
                      rf: state.rf!,
                      prediction: _rfLastPred!,
                      inputDefs: proj.inputDefs,
                      outputDefs: proj.outputDefs,
                      inputMask: state.inputMask,
                    ),
                  ),
                );
              },
              icon: Icon(Icons.zoom_out_map, size: 20 * scale),
              label: Text(
                "Open Tree Explorer",
                style: TextStyle(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 32 * scale),
          ],

          // ★ 開発者向け機能：コードエクスポートボタン
          Divider(color: Colors.cyan.withOpacity(0.5), thickness: 1),
          SizedBox(height: 8 * scale),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.cyanAccent,
                side: BorderSide(color: Colors.cyan.shade800),
                padding: EdgeInsets.symmetric(vertical: 16 * scale),
              ),
              label: Text(
                "Export Dart Code",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16 * scale,
                ),
              ),
              onPressed: () =>
                  _showCodeExportDialog(state, scale, exportLang: "dart"),
            ),
          ),
          SizedBox(height: 16 * scale),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.yellowAccent,
                side: BorderSide(color: Colors.yellow.shade800),
                padding: EdgeInsets.symmetric(vertical: 16 * scale),
              ),
              label: Text(
                "Export Python Code",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16 * scale,
                ),
              ),
              onPressed: () =>
                  _showCodeExportDialog(state, scale, exportLang: "python"),
            ),
          ),
          SizedBox(height: 16 * scale),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blueAccent,
                side: BorderSide(color: Colors.blue.shade800),
                padding: EdgeInsets.symmetric(vertical: 16 * scale),
              ),
              label: Text(
                "Export C++ (General / PC)",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16 * scale,
                ),
              ),
              onPressed: () =>
                  _showCodeExportDialog(state, scale, exportLang: "cpp_legacy"),
            ),
          ),
          SizedBox(height: 16 * scale),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blueAccent,
                side: BorderSide(color: Colors.blue.shade800),
                padding: EdgeInsets.symmetric(vertical: 16 * scale),
              ),
              label: Text(
                "Export C++ (ESP32 / Rich)",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16 * scale,
                ),
              ),
              onPressed: () =>
                  _showCodeExportDialog(state, scale, exportLang: "cpp_rich"),
            ),
          ),
          SizedBox(height: 16 * scale),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blueAccent,
                side: BorderSide(color: Colors.blue.shade800),
                padding: EdgeInsets.symmetric(vertical: 16 * scale),
              ),
              label: Text(
                "Export C++ (Arduino / Bare-Metal)",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16 * scale,
                ),
              ),
              onPressed: () => _showCodeExportDialog(
                state,
                scale,
                exportLang: "cpp_baremetal",
              ),
            ),
          ),
          SizedBox(height: 16 * scale),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orangeAccent,
                side: BorderSide(color: Colors.orange.shade800),
                padding: EdgeInsets.symmetric(vertical: 16 * scale),
              ),
              label: Text(
                "Export Rust Code",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16 * scale,
                ),
              ),
              onPressed: () =>
                  _showCodeExportDialog(state, scale, exportLang: "rust"),
            ),
          ),
          SizedBox(height: 40 * scale),
        ],
      );
    }

    return Stack(
      children: [
        AbsorbPointer(
          absorbing: state.isTraining,
          child: Opacity(opacity: state.isTraining ? 0.3 : 1.0, child: content),
        ),
        if (state.isTraining)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.redAccent.shade700,
              padding: EdgeInsets.symmetric(vertical: 8 * scale),
              child: Text(
                l10n.msgPredictLockedDuringTraining,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12 * scale,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMiniProbRow(
    Map<String, dynamic> item,
    double scale,
    Color barColor,
  ) {
    final double prob = item['prob'] as double;
    final String char = item['char'] as String;
    return Padding(
      padding: EdgeInsets.only(bottom: 2.0 * scale),
      child: Row(
        children: [
          SizedBox(
            width: 16 * scale,
            child: Text(
              char,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12 * scale,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: prob.clamp(0.0, 1.0),
              backgroundColor: Colors.black,
              color: barColor.withOpacity(0.8),
              minHeight: 4 * scale,
            ),
          ),
          SizedBox(width: 4 * scale),
          SizedBox(
            width: 30 * scale,
            child: Text(
              "${(prob * 100).toStringAsFixed(0)}%",
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 9 * scale, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

// ＝＝＝ ランダムフォレスト「決定木の解剖図」用の独立画面 ＝＝＝
class RFTreeExplorerScreen extends StatefulWidget {
  final RandomForest rf;
  final RFPrediction prediction;
  final List<FeatureDef> inputDefs;
  final List<FeatureDef> outputDefs;
  final List<bool> inputMask;

  const RFTreeExplorerScreen({
    super.key,
    required this.rf,
    required this.prediction,
    required this.inputDefs,
    required this.outputDefs,
    required this.inputMask,
  });

  @override
  State<RFTreeExplorerScreen> createState() => _RFTreeExplorerScreenState();
}

class _RFTreeExplorerScreenState extends State<RFTreeExplorerScreen> {
  int _selectedTreeIndex = 0;

  @override
  Widget build(BuildContext context) {
    final double scale = ScaleUtil.scale(context);

    // 木の深さに応じてキャンバスサイズを動的に計算（最小値も設定して見切れを防止）
    double canvasWidth = max(
      pow(2, widget.rf.maxDepth) * 60.0 * scale,
      MediaQuery.of(context).size.width,
    );
    double canvasHeight = max(
      (widget.rf.maxDepth + 2) * 90.0 * scale,
      MediaQuery.of(context).size.height,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white, size: 24 * scale),
        title: Text(
          "Decision Tree Explorer",
          style: TextStyle(color: Colors.white, fontSize: 18 * scale),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50 * scale),
          child: Container(
            color: Colors.grey.shade900,
            padding: EdgeInsets.symmetric(
              horizontal: 16 * scale,
              vertical: 8 * scale,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  widget.rf.trees.length,
                  (index) => Padding(
                    padding: EdgeInsets.only(right: 8 * scale),
                    child: ChoiceChip(
                      label: Text("Tree ${index + 1}"),
                      selected: _selectedTreeIndex == index,
                      selectedColor: Colors.lightGreen.shade800,
                      backgroundColor: Colors.black,
                      labelStyle: TextStyle(
                        color: _selectedTreeIndex == index
                            ? Colors.white
                            : Colors.grey,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedTreeIndex = index);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(double.infinity),
            minScale: 0.1,
            maxScale: 3.0,
            constrained: false, // 自由にスクロール可能
            child: Container(
              width: canvasWidth,
              height: canvasHeight,
              color: Colors.black,
              child: CustomPaint(
                painter: RFTreePainter(
                  tree: widget.rf.trees[_selectedTreeIndex],
                  path: widget.prediction.treePaths[_selectedTreeIndex],
                  inputDefs: widget.inputDefs,
                  outputDefs: widget.outputDefs,
                  scale: scale,
                  inputMask: widget.inputMask,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16 * scale,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16 * scale,
                  vertical: 8 * scale,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20 * scale),
                  border: Border.all(
                    color: Colors.lightGreenAccent.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  "Pinch to zoom / Drag to pan",
                  style: TextStyle(
                    color: Colors.lightGreenAccent,
                    fontSize: 12 * scale,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ＝＝＝ カスタムペインター ＝＝＝
class RFTreePainter extends CustomPainter {
  final DecisionTree tree;
  final TreePath path;
  final List<FeatureDef> inputDefs;
  final List<FeatureDef> outputDefs;
  final double scale;
  final List<bool> inputMask;

  RFTreePainter({
    required this.tree,
    required this.path,
    required this.inputDefs,
    required this.outputDefs,
    required this.scale,
    required this.inputMask,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (tree.root == null) return;

    Map<TreeNode, Offset> positions = {};
    int leafCount = 0;

    // 深さ優先探索でX,Y座標を計算
    void assignX(TreeNode node, int depth) {
      if (node.left != null) assignX(node.left!, depth + 1);
      if (node.left == null && node.right == null) {
        positions[node] = Offset(
          leafCount * 140.0 * scale + 70 * scale,
          depth * 90.0 * scale + 40 * scale,
        );
        leafCount++;
      } else {
        if (node.right != null) assignX(node.right!, depth + 1);
        double lx = positions[node.left!]!.dx;
        double rx = positions[node.right!]!.dx;
        positions[node] = Offset(
          (lx + rx) / 2,
          depth * 90.0 * scale + 40 * scale,
        );
      }
    }

    assignX(tree.root!, 0);

    // 推論時に通ったルート（アクティブノード・エッジ）を追跡
    Set<TreeNode> activeNodes = {tree.root!};
    Set<TreeNode> activeLeft = {};
    Set<TreeNode> activeRight = {};

    TreeNode? curr = tree.root;
    for (int dir in path.route) {
      if (dir == 0 && curr!.left != null) {
        activeLeft.add(curr);
        curr = curr.left;
        activeNodes.add(curr!);
      } else if (dir == 1 && curr!.right != null) {
        activeRight.add(curr);
        curr = curr.right;
        activeNodes.add(curr!);
      }
    }

    final edgePaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 2.0 * scale;
    final activeEdgePaint = Paint()
      ..color = Colors.lightGreenAccent
      ..strokeWidth = 4.0 * scale;

    // エッジの描画
    void drawEdges(TreeNode node) {
      Offset p1 = positions[node]!;
      if (node.left != null) {
        Offset p2 = positions[node.left!]!;
        canvas.drawLine(
          p1,
          p2,
          activeLeft.contains(node) ? activeEdgePaint : edgePaint,
        );
        drawEdges(node.left!);
      }
      if (node.right != null) {
        Offset p2 = positions[node.right!]!;
        canvas.drawLine(
          p1,
          p2,
          activeRight.contains(node) ? activeEdgePaint : edgePaint,
        );
        drawEdges(node.right!);
      }
    }

    drawEdges(tree.root!);

    // ノードの描画
    void drawNodes(TreeNode node) {
      Offset pos = positions[node]!;
      bool isActive = activeNodes.contains(node);

      Rect rect = Rect.fromCenter(
        center: pos,
        width: 120 * scale,
        height: 50 * scale,
      );
      RRect rrect = RRect.fromRectAndRadius(rect, Radius.circular(8 * scale));

      canvas.drawRRect(
        rrect,
        Paint()
          ..color = isActive
              ? Colors.lightGreen.shade900
              : Colors.grey.shade800,
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = isActive ? Colors.lightGreenAccent : Colors.grey
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * scale,
      );

      String text = "";
      if (node.value != null) {
        // 葉ノード（結論）
        if (tree.lossType == 1) {
          // 分類
          int maxIdx = 0;
          for (int i = 1; i < node.value!.length; i++) {
            if (node.value![i] > node.value![maxIdx]) maxIdx = i;
          }
          String cat =
              outputDefs.isNotEmpty && outputDefs[0].categories.length > maxIdx
              ? outputDefs[0].categories[maxIdx]
              : maxIdx.toString();
          text =
              "Class: $cat\n(${(node.value![maxIdx] * 100).toStringAsFixed(1)}%)";
        } else {
          // 数値予測
          double denormVal = node.value![0];
          if (outputDefs.isNotEmpty &&
              (outputDefs[0].type == 0 || outputDefs[0].type == 2)) {
            denormVal =
                node.value![0] * (outputDefs[0].max - outputDefs[0].min) +
                outputDefs[0].min;
          }
          text = "Val: ${denormVal.toStringAsFixed(2)}";
        }
      } else {
        // 分岐ノード（条件）
        int encodedIndex = node.featureIndex!;
        String fName = "F$encodedIndex";
        double displayThreshold = node.threshold!;
        bool isCategory = false;

        int currentFilteredIdx = 0;

        for (int i = 0; i < inputDefs.length; i++) {
          var def = inputDefs[i];

          bool isMasked =
              inputMask.isNotEmpty &&
              inputMask.length == inputDefs.length &&
              !inputMask[i];

          if (!isMasked) {
            if (def.type == 1) {
              int catLen = def.categories.length;
              if (encodedIndex >= currentFilteredIdx &&
                  encodedIndex < currentFilteredIdx + catLen) {
                int cIdx = encodedIndex - currentFilteredIdx;
                fName = "${def.name}[${def.categories[cIdx]}]";
                isCategory = true;
                break;
              }
              currentFilteredIdx += catLen;
            } else {
              if (encodedIndex == currentFilteredIdx) {
                fName = def.name;
                displayThreshold =
                    node.threshold! * (def.max - def.min) + def.min;
                break;
              }
              currentFilteredIdx += 1;
            }
          }
        }
        if (fName.length > 10) fName = fName.substring(0, 10) + "..";

        if (isCategory) {
          text = "$fName\nNO      YES";
        } else {
          text =
              "$fName\n<= ${displayThreshold.toStringAsFixed(2)}\nYES      NO";
        }
      }

      TextPainter tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade400,
            fontSize: 10 * scale,
            height: 1.2,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 110 * scale);
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));

      if (node.left != null) drawNodes(node.left!);
      if (node.right != null) drawNodes(node.right!);
    }

    drawNodes(tree.root!);
  }

  @override
  bool shouldRepaint(covariant RFTreePainter oldDelegate) => true;
}
