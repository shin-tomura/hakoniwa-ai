import 'dart:convert';
import 'models.dart';
import 'nn_engine.dart';
import 'main.dart';

class CodeGenerators {
  // 🌲 RFの木構造を再帰的にコード化する共通ヘルパー
  static void _genTreeLogic(
    StringBuffer sb,
    TreeNode? node,
    int depth,
    String lang,
    int outSize,
  ) {
    if (node == null) return;
    String ind = "    " * depth;
    String inVar = (lang == 'cpp_baremetal') ? 'input' : 'input_data';
    String outVar = (lang == 'cpp_baremetal') ? 'output' : 'out_buf';

    if (node.value != null) {
      for (int i = 0; i < outSize; i++) {
        if (lang == 'python') {
          sb.writeln("$ind$outVar[$i] += ${node.value![i]}");
        } else if (lang == 'cpp_baremetal' || lang == 'cpp_rich') {
          sb.writeln("$ind$outVar[$i] += ${node.value![i]}f;");
        } else if (lang == 'rust') {
          sb.writeln("$ind$outVar[$i] += ${node.value![i]}_f64;");
        } else {
          sb.writeln("$ind$outVar[$i] += ${node.value![i]};"); // Dart
        }
      }
    } else {
      if (lang == 'python') {
        sb.writeln(
          "${ind}if $inVar[${node.featureIndex}] <= ${node.threshold}:",
        );
        _genTreeLogic(sb, node.left, depth + 1, lang, outSize);
        sb.writeln("${ind}else:");
        _genTreeLogic(sb, node.right, depth + 1, lang, outSize);
      } else if (lang == 'cpp_baremetal' || lang == 'cpp_rich') {
        sb.writeln(
          "${ind}if ($inVar[${node.featureIndex}] <= ${node.threshold}f) {",
        );
        _genTreeLogic(sb, node.left, depth + 1, lang, outSize);
        sb.writeln("$ind} else {");
        _genTreeLogic(sb, node.right, depth + 1, lang, outSize);
        sb.writeln("$ind}");
      } else if (lang == 'rust') {
        sb.writeln(
          "${ind}if $inVar[${node.featureIndex}] <= ${node.threshold}_f64 {",
        );
        _genTreeLogic(sb, node.left, depth + 1, lang, outSize);
        sb.writeln("$ind} else {");
        _genTreeLogic(sb, node.right, depth + 1, lang, outSize);
        sb.writeln("$ind}");
      } else {
        // dart
        sb.writeln(
          "${ind}if ($inVar[${node.featureIndex}] <= ${node.threshold}) {",
        );
        _genTreeLogic(sb, node.left, depth + 1, lang, outSize);
        sb.writeln("$ind} else {");
        _genTreeLogic(sb, node.right, depth + 1, lang, outSize);
        sb.writeln("$ind}");
      }
    }
  }

  // ＝＝＝ 👨‍💻 Dartコード生成ロジック ＝＝＝
  static String buildDartCode(ProjectState state) {
    final proj = state.proj;
    final sb = StringBuffer();

    sb.writeln("import 'dart:math';");
    if (proj.mode == 1) {
      // 💡 修正箇所：絵文字や特殊文字を安全に処理するためのパッケージをインポート
      sb.writeln(
        "import 'package:characters/characters.dart'; // 📦 For safe Unicode/Emoji handling",
      );
    }
    sb.writeln("");
    sb.writeln("/// Auto-generated Hakoniwa AI Inference Model");
    sb.writeln("/// ");
    sb.writeln(
      "/// DISCLAIMER: This auto-generated code is for educational and experimental purposes.",
    );
    sb.writeln(
      "/// It is provided \"AS IS\" without warranty of any kind. The author shall not be liable",
    );
    sb.writeln(
      "/// for any claim, damages or other liability arising from the use of this code.",
    );
    sb.writeln("/// ");
    sb.writeln("/// Project: ${proj.name}");
    sb.writeln("/// ");
    sb.writeln("/// [Usage Example]");
    if (proj.mode == 1) {
      // 🇯🇵 日本語判定を入れてサンプルテキストを切り替える
      bool isJapanese = RegExp(r'[ぁ-んァ-ン一-龥]').hasMatch(proj.currentChars);
      String sampleText = isJapanese ? 'むかしむかし' : 'Once';
      sb.writeln("/// ```dart");
      sb.writeln("/// final ai = HakoniwaModel();");
      sb.writeln("/// final random = Random();");
      sb.writeln(
        "/// String text = '$sampleText'; // Note: Length must be >= nGramCount",
      );
      // 💡 修正箇所：Temperatureの設定を追加
      sb.writeln(
        "/// double temperature = 0.5; // Set to 0.0 for greedy, >0.0 for creative",
      );
      sb.writeln("/// ");
      sb.writeln("/// print('Initial text: \$text');");
      sb.writeln(
        "/// print('Generating next 50 characters (Temperature: \$temperature)...');",
      );
      sb.writeln("/// ");
      sb.writeln("/// // Generate the next 50 characters:");
      sb.writeln("/// for (int i = 0; i < 50; i++) {");
      sb.writeln("///   var probs = ai.predictNextChar(text);");
      sb.writeln("///   if (probs.isEmpty) break;");
      sb.writeln("///   ");
      sb.writeln("///   String nextChar = probs.first['char'];");
      sb.writeln("///   ");
      // 💡 修正箇所：Temperatureを用いたサンプリングロジックに変更
      sb.writeln("///   if (temperature > 0.05) {");
      sb.writeln("///     List<double> weights = [];");
      sb.writeln("///     double weightSum = 0.0;");
      sb.writeln("///     for (var p in probs) {");
      sb.writeln(
        "///       double prob = (p['prob'] as double) > 0 ? p['prob'] : 1e-7;",
      );
      sb.writeln(
        "///       double w = pow(prob, 1.0 / temperature).toDouble();",
      );
      sb.writeln("///       weights.add(w);");
      sb.writeln("///       weightSum += w;");
      sb.writeln("///     }");
      sb.writeln("///     ");
      sb.writeln("///     double r = random.nextDouble() * weightSum;");
      sb.writeln("///     for (int j = 0; j < weights.length; j++) {");
      sb.writeln("///       r -= weights[j];");
      sb.writeln("///       if (r <= 0.0) {");
      sb.writeln("///         nextChar = probs[j]['char'];");
      sb.writeln("///         break;");
      sb.writeln("///       }");
      sb.writeln("///     }");
      sb.writeln("///   }");
      sb.writeln("///   ");
      sb.writeln("///   text += nextChar;");
      sb.writeln("/// }");
      sb.writeln("/// print('\\nResult:\\n\$text');");
      sb.writeln("/// ```");
    } else {
      sb.writeln("/// ```dart");
      sb.writeln("/// final ai = HakoniwaModel();");
      sb.writeln("/// ");
      sb.writeln(
        "/// // [Input] Provide raw values matching the Input Definitions.",
      );
      sb.writeln("/// // - For Numeric: Pass the actual value (e.g., 25.5)");
      sb.writeln(
        "/// // - For Category: Pass the category index as a double (e.g., 1.0)",
      );
      sb.writeln(
        "/// // Note: Scaling and One-Hot encoding are handled automatically.",
      );

      List<String> exampleInputs = [];
      for (int i = 0; i < proj.inputDefs.length; i++) {
        if (state.inputMask.isNotEmpty && !state.inputMask[i]) continue;
        var d = proj.inputDefs[i];
        if (d.type == 1) {
          exampleInputs.add("0.0");
        } else {
          double midVal = (d.min + d.max) / 2.0;
          exampleInputs.add(midVal.toStringAsFixed(1));
        }
      }

      sb.writeln(
        "/// List<double> rawInputs = [ ${exampleInputs.join(', ')} ];",
      );
      sb.writeln("/// ");
      sb.writeln("/// // [Predict]");
      sb.writeln("/// List<dynamic> results = ai.predict(rawInputs);");
      sb.writeln("/// ");
      sb.writeln(
        "/// // [Output] Interpret the results based on Output Definitions.",
      );
      sb.writeln(
        "/// // --- Example 1: If Output 0 is a Category (Classification) ---",
      );
      sb.writeln("/// List<double> probs = results[0];");
      sb.writeln("/// print('Probabilities for each class: \$probs');");
      sb.writeln("/// ");
      sb.writeln("/// // Find the most likely class index:");
      sb.writeln("/// int bestClass = 0;");
      sb.writeln("/// double maxProb = probs[0];");
      sb.writeln("/// for (int i = 1; i < probs.length; i++) {");
      sb.writeln("///   if (probs[i] > maxProb) {");
      sb.writeln("///     maxProb = probs[i];");
      sb.writeln("///     bestClass = i;");
      sb.writeln("///   }");
      sb.writeln("/// }");
      sb.writeln(
        "/// print('Predicted Class Index: \$bestClass (Confidence: \${(maxProb * 100).toStringAsFixed(1)}%)');",
      );
      sb.writeln("/// ");
      sb.writeln(
        "/// // --- Example 2: If Output 1 is Numeric (Regression) ---",
      );
      sb.writeln("/// // double predictedValue = results[1];");
      sb.writeln("/// // print('Predicted Value: \$predictedValue');");
      sb.writeln("/// ```");
      sb.writeln("/// ");

      sb.writeln("/// [Input Definitions]");
      for (int i = 0; i < proj.inputDefs.length; i++) {
        if (state.inputMask.isNotEmpty && !state.inputMask[i]) continue;
        var d = proj.inputDefs[i];
        if (d.type == 1) {
          List<String> catStrs = [];
          for (int c = 0; c < d.categories.length; c++) {
            catStrs.add("${c.toDouble()}=${d.categories[c]}");
          }
          sb.writeln("/// Input $i (Category): ${catStrs.join(', ')}");
        } else {
          sb.writeln("/// Input $i (Numeric): Range (${d.min} - ${d.max})");
        }
      }
      sb.writeln("/// ");
      sb.writeln("/// [Output Definitions]");
      for (int i = 0; i < proj.outputDefs.length; i++) {
        var d = proj.outputDefs[i];
        if (d.type == 1) {
          List<String> catStrs = [];
          for (int c = 0; c < d.categories.length; c++) {
            catStrs.add("Index $c=${d.categories[c]}");
          }
          sb.writeln("/// Output $i (Category): ${catStrs.join(', ')}");
        } else {
          sb.writeln("/// Output $i (Numeric): Range (${d.min} - ${d.max})");
        }
      }
    }
    sb.writeln("/// ");
    sb.writeln("class HakoniwaModel {");

    if (proj.engineType == 0) {
      final nn = state.nn!;
      sb.writeln("  final List<int> layerSizes = ${nn.layerSizes};");
      sb.writeln(
        "  final int hiddenActivation = ${nn.hiddenActivation.index}; // 0:Sigmoid, 1:ReLU, 2:Tanh",
      );
      sb.writeln(
        "  final int lossType = ${nn.lossType}; // 0:MSE(Sigmoid), 1:CrossEntropy(Softmax)",
      );
      sb.writeln("");

      sb.writeln("  // --- 🧠 Trained Parameters ---");
      sb.writeln("  final List<List<List<double>>> weights = ${nn.weights};");
      sb.writeln("  final List<List<double>> biases = ${nn.biases};");
      sb.writeln("");

      sb.writeln(r"""
  // --- Inference Core Logic ---
  List<double> _predictRaw(List<double> input_data) {
    List<double> current = List.from(input_data);
    for (int i = 0; i < weights.length; i++) {
      List<double> next = List.filled(layerSizes[i + 1], 0.0);
      for (int j = 0; j < layerSizes[i + 1]; j++) {
        double sum = biases[i][j];
        for (int k = 0; k < layerSizes[i]; k++) {
          sum += current[k] * weights[i][k][j];
        }
        
        // Apply activation function (hidden layers only)
        if (i < weights.length - 1) {
          if (hiddenActivation == 0) { // Sigmoid
            next[j] = 1.0 / (1.0 + exp(-sum));
          } else if (hiddenActivation == 1) { // ReLU
            next[j] = sum > 0 ? sum : 0.01 * sum;
          } else if (hiddenActivation == 2) { // Tanh
            next[j] = (exp(sum) - exp(-sum)) / (exp(sum) + exp(-sum));
          }
        } else {
          next[j] = sum;
        }
      }
      current = next;
    }
    
    // Output layer activation (based on lossType)
    if (lossType == 1) { // Softmax
      double maxVal = current.reduce(max);
      double sumExp = 0.0;
      for (int j = 0; j < current.length; j++) {
        current[j] = exp(current[j] - maxVal);
        sumExp += current[j];
      }
      for (int j = 0; j < current.length; j++) current[j] /= sumExp;
    } else { // Sigmoid
      for (int j = 0; j < current.length; j++) {
        current[j] = 1.0 / (1.0 + exp(-current[j]));
      }
    }
    return current;
  }
""");
    } else {
      final rf = state.rf!;
      int outSize = rf.outputSize;
      sb.writeln("  // --- 🌲 Random Forest Hardcoded Logic ---");
      sb.writeln("  List<double> _predictRaw(List<double> input_data) {");
      sb.writeln("    List<double> out_buf = List.filled($outSize, 0.0);");
      for (int i = 0; i < rf.trees.length; i++) {
        sb.writeln("    // Tree $i");
        _genTreeLogic(sb, rf.trees[i].root, 1, 'dart', outSize);
      }
      sb.writeln(
        "    for(int i=0; i<$outSize; i++) out_buf[i] /= ${rf.trees.length}.0;",
      );
      sb.writeln("    return out_buf;");
      sb.writeln("  }");
      sb.writeln("");
    }

    if (proj.mode == 1) {
      sb.writeln("  final int nGramCount = ${proj.nGramCount};");

      // 💡 修正箇所：生成元の currentChars がサロゲートペアを含んでいても割れないように runes を使用
      String dartVocab = proj.currentChars.runes
          .map((r) => jsonEncode(String.fromCharCode(r)))
          .join(', ');
      sb.writeln("  final List<String> vocab = [$dartVocab];");

      sb.writeln(r"""
  /// Predicts the probability distribution of the next character based on the preceding context.
  List<Map<String, dynamic>> predictNextChar(String contextText) {
    // 💡 修正箇所：characters を使って絵文字や特殊文字を「見た目通りの1文字」として安全にカウント
    var chars = contextText.characters;
    if (chars.length < nGramCount) return [];
    
    // 後ろから nGramCount 文字分を安全に取得し、リスト化
    List<String> ctx = chars.takeLast(nGramCount).toList();
    
    // Vectorize characters (One-Hot Encoding)
    List<double> input = [];
    for (int i = 0; i < nGramCount; i++) {
      int idx = vocab.indexOf(ctx[i]);
      for (int v = 0; v < vocab.length; v++) {
        input.add(v == idx ? 1.0 : 0.0);
      }
    }
    
    List<double> rawPred = _predictRaw(input);
    
    List<Map<String, dynamic>> probs = [];
    for (int i = 0; i < vocab.length && i < rawPred.length; i++) {
      probs.add({'char': vocab[i], 'prob': rawPred[i]});
    }
    probs.sort((a, b) => (b['prob'] as double).compareTo(a['prob'] as double));
    return probs;
  }
""");
    } else {
      sb.writeln("  // --- Normalization Data ---");
      sb.writeln("  final List<Map<String, dynamic>> inputDefs = [");
      for (int i = 0; i < proj.inputDefs.length; i++) {
        // ★書き換え
        if (state.inputMask.isNotEmpty && !state.inputMask[i]) continue; // ★追加
        var d = proj.inputDefs[i];
        sb.writeln(
          "    {'type': ${d.type}, 'min': ${d.min}, 'max': ${d.max}, 'catLen': ${d.categories.length}},",
        );
      }
      sb.writeln("  ];");

      sb.writeln("  final List<Map<String, dynamic>> outputDefs = [");
      for (var d in proj.outputDefs) {
        sb.writeln(
          "    {'type': ${d.type}, 'min': ${d.min}, 'max': ${d.max}, 'catLen': ${d.categories.length}},",
        );
      }
      sb.writeln("  ];");

      sb.writeln(r"""
  /// Pass raw input values (List of double) to get the prediction result.
  /// Scaling and One-Hot encoding are handled automatically internally.
  List<dynamic> predict(List<double> rawInputs) {
    // 1. Normalize input data (Encode)
    List<double> encodedInputs = [];
    for (int i = 0; i < inputDefs.length; i++) {
      var def = inputDefs[i];
      double val = rawInputs[i];
      if (def['type'] == 1) { 
        for (int c = 0; c < def['catLen']; c++) {
          encodedInputs.add((c.toDouble() - val).abs() < 0.001 ? 1.0 : 0.0);
        }
      } else { 
        double minV = def['min'];
        double maxV = def['max'];
        encodedInputs.add(maxV == minV ? 0.0 : ((val - minV) / (maxV - minV)).clamp(0.0, 1.0));
      }
    }

    // 2. Run inference
    List<double> rawOut = _predictRaw(encodedInputs);

    // 3. Denormalize output data (Decode)
    List<dynamic> results = [];
    int outIdx = 0;
    for (int i = 0; i < outputDefs.length; i++) {
      var def = outputDefs[i];
      if (def['type'] == 1) { // Classification
        int catLen = def['catLen'];
        results.add(rawOut.sublist(outIdx, outIdx + catLen));
        outIdx += catLen;
      } else { // Regression (Numeric)
        double minV = def['min'];
        double maxV = def['max'];
        results.add(rawOut[outIdx] * (maxV - minV) + minV);
        outIdx += 1;
      }
    }
    return results;
  }
""");
    }

    sb.writeln("}");
    return sb.toString();
  }

  // ＝＝＝ 👨‍💻 Pythonコード生成ロジック（DX究極進化 ＆ フェイルセーフ完全版） ＝＝＝
  static String buildPythonCode(ProjectState state) {
    final proj = state.proj;
    final sb = StringBuffer();

    sb.writeln("import math");
    sb.writeln("import random");
    sb.writeln("import json");
    sb.writeln("");
    sb.writeln("# Auto-generated Hakoniwa AI Inference Model (Pure Python)");
    sb.writeln("# ");
    sb.writeln(
      "# DISCLAIMER: This auto-generated code is for educational and experimental purposes.",
    );
    sb.writeln(
      "# It is provided \"AS IS\" without warranty of any kind. The author shall not be liable",
    );
    sb.writeln(
      "# for any claim, damages or other liability arising from the use of this code.",
    );
    sb.writeln("# ");
    sb.writeln("# Project: ${proj.name}");
    sb.writeln("# Note: No external libraries like NumPy are required.");
    sb.writeln("");

    // ＝＝＝ 👇 仕様書（Model Specification）の動的生成 👇 ＝＝＝
    sb.writeln(
      "# ======================================================================",
    );
    sb.writeln("# [Model Specification]");
    if (proj.mode == 1) {
      sb.writeln("# Task: Text Generation (Next Character Prediction)");
      sb.writeln("# Context Length (n-gram): ${proj.nGramCount} characters");
      sb.writeln(
        "# Vocabulary Size: ${proj.currentChars.length} unique characters",
      );
      sb.writeln(
        "# Note: Feed at least ${proj.nGramCount} characters to the predict_next_char() method.",
      );
    } else {
      sb.writeln("# Task: Tabular Data Prediction");
      sb.writeln("# ");
      sb.writeln("# --- Inputs ---");
      for (int i = 0; i < proj.inputDefs.length; i++) {
        if (state.inputMask.isNotEmpty && !state.inputMask[i]) continue;
        var d = proj.inputDefs[i];
        if (d.type == 1) {
          String cats = d.categories.map((c) => "'$c'").join(", ");
          sb.writeln("# ${i + 1}. ${d.name} (Category): $cats");
        } else {
          sb.writeln(
            "# ${i + 1}. ${d.name} (Numeric): Range ${d.min} ~ ${d.max}",
          );
        }
      }
      sb.writeln("# ");
      sb.writeln("# --- Outputs ---");
      for (int i = 0; i < proj.outputDefs.length; i++) {
        var d = proj.outputDefs[i];
        if (d.type == 1) {
          String cats = d.categories.map((c) => "'$c'").join(", ");
          sb.writeln("# ${i + 1}. ${d.name} (Category): $cats");
        } else {
          sb.writeln(
            "# ${i + 1}. ${d.name} (Numeric): Range ${d.min} ~ ${d.max}",
          );
        }
      }
    }
    sb.writeln(
      "# ======================================================================",
    );
    sb.writeln("");

    // ＝＝＝ 👇 Usage Example 👇 ＝＝＝
    sb.writeln("# [Usage Example]");
    sb.writeln(
      "# You can test this model instantly using Google Colab or any online Python compiler.",
    );
    sb.writeln("# ");
    sb.writeln("# --- Method A: Paste & Run (For small models) ---");
    sb.writeln(
      "# 1. Copy all this code and paste it into your Python environment.",
    );
    sb.writeln(
      "# 2. Add the execution code below to the very bottom of the file.",
    );
    sb.writeln("# ");
    sb.writeln("# --- Method B: Import & Run (For large models / files) ---");
    sb.writeln("# 1. Save this code as a file named 'hakoniwa_model.py'.");
    sb.writeln(
      "# 2. Put it in your project folder (or upload it to Google Colab).",
    );
    sb.writeln("# 3. Create a new Python file and run the following code:");
    sb.writeln("# ");

    if (proj.mode == 1) {
      // 🇯🇵 日本語が含まれているかを判定（ひらがな、カタカナ、漢字）
      bool isJapanese = RegExp(r'[ぁ-んァ-ン一-龥]').hasMatch(proj.currentChars);
      String sampleText = isJapanese ? 'むかしむかし' : 'Once';

      sb.writeln("# ```python");
      sb.writeln(
        "# # For Method B only (If using Method A, skip the line below):",
      );
      sb.writeln("# from hakoniwa_model import HakoniwaModel");
      sb.writeln("# ");
      sb.writeln("# ai = HakoniwaModel()");
      sb.writeln(
        "# text = '$sampleText' # Note: Length must be >= n_gram_count",
      );
      sb.writeln(
        "# temperature = 0.5 # Set to 0.0 for greedy, >0.0 for creative",
      );
      sb.writeln("# ");
      sb.writeln("# print(f'Initial text: {text}')");
      sb.writeln(
        "# print(f'Generating next 50 characters (Temperature: {temperature})...')",
      );
      sb.writeln("# ");
      sb.writeln("# for _ in range(50):");
      sb.writeln("#     probs = ai.predict_next_char(text)");
      sb.writeln("#     if not probs: break");
      sb.writeln("#     ");
      sb.writeln("#     next_char = probs[0]['char']");
      sb.writeln("#     if temperature > 0.05:");
      sb.writeln("#         weights = []");
      sb.writeln("#         for p in probs:");
      sb.writeln("#             prob = p['prob'] if p['prob'] > 0 else 1e-7");
      sb.writeln("#             weights.append(prob ** (1.0 / temperature))");
      sb.writeln("#         weight_sum = sum(weights)");
      sb.writeln("#         r = random.random() * weight_sum");
      sb.writeln("#         for i, w in enumerate(weights):");
      sb.writeln("#             r -= w");
      sb.writeln("#             if r <= 0:");
      sb.writeln("#                 next_char = probs[i]['char']");
      sb.writeln("#                 break");
      sb.writeln("#     ");
      sb.writeln("#     text += next_char");
      sb.writeln("# ");
      sb.writeln("# print(f'\\nResult:\\n{text}')");
      sb.writeln("# ```");
    } else {
      List<String> exampleInputs = [];
      for (int i = 0; i < proj.inputDefs.length; i++) {
        if (state.inputMask.isNotEmpty && !state.inputMask[i]) continue;
        var d = proj.inputDefs[i];
        if (d.type == 1 && d.categories.isNotEmpty) {
          exampleInputs.add(jsonEncode(d.categories[0])); // 例: "male"
        } else if (d.type == 1) {
          exampleInputs.add("0.0");
        } else {
          double midVal = (d.min + d.max) / 2.0;
          exampleInputs.add(midVal.toStringAsFixed(1)); // 例: 50.0
        }
      }

      sb.writeln("# ```python");
      sb.writeln(
        "# # For Method B only (If using Method A, skip the line below):",
      );
      sb.writeln("# from hakoniwa_model import HakoniwaModel");
      sb.writeln("# ");
      sb.writeln("# ai = HakoniwaModel()");
      sb.writeln("# raw_inputs = [${exampleInputs.join(', ')}]");
      sb.writeln("# results = ai.predict(raw_inputs)");
      sb.writeln("# ");
      sb.writeln("# print(f'Input values: {raw_inputs}')");
      sb.writeln("# print(json.dumps(results, indent=2, ensure_ascii=False))");
      sb.writeln("# ```");
    }
    sb.writeln(
      "# ======================================================================",
    );
    sb.writeln("");

    // ＝＝＝ 👇 クラス定義 👇 ＝＝＝
    sb.writeln("class HakoniwaModel:");

    // ★修正ポイント：__init__ の中で全ての変数を定義しきるように順序を変更
    sb.writeln("    def __init__(self):");

    if (proj.engineType == 0) {
      final nn = state.nn!;
      sb.writeln("        self.layer_sizes = ${nn.layerSizes}");
      sb.writeln(
        "        self.hidden_activation = ${nn.hiddenActivation.index} # 0:Sigmoid, 1:ReLU, 2:Tanh",
      );
      sb.writeln(
        "        self.loss_type = ${nn.lossType} # 0:MSE(Sigmoid), 1:CrossEntropy(Softmax)",
      );
      sb.writeln("");
      sb.writeln("        # --- 🧠 Trained Parameters ---");
      sb.writeln("        self.weights = ${nn.weights}");
      sb.writeln("        self.biases = ${nn.biases}");
      sb.writeln("");
    } else {
      sb.writeln(
        "        # RF uses hardcoded logic in _predict_raw for performance",
      );
    }

    if (proj.mode == 1) {
      sb.writeln("        self.n_gram_count = ${proj.nGramCount}");
      sb.writeln(
        "        self.vocab = [${proj.currentChars.split('').map((e) => jsonEncode(e)).join(", ")}]",
      );
      sb.writeln("");
    } else {
      sb.writeln("        # --- Model Metadata (Names & Categories) ---");
      sb.writeln("        self.input_defs = [");
      for (int i = 0; i < proj.inputDefs.length; i++) {
        // ★書き換え
        if (state.inputMask.isNotEmpty && !state.inputMask[i]) continue; // ★追加
        var d = proj.inputDefs[i];
        String cats = d.categories.map((c) => jsonEncode(c)).join(', ');
        sb.writeln(
          "            {'name': ${jsonEncode(d.name)}, 'type': ${d.type}, 'min': ${d.min}, 'max': ${d.max}, 'catLen': ${d.categories.length}, 'categories': [$cats]},",
        );
      }
      sb.writeln("        ]");
      sb.writeln("        self.output_defs = [");
      for (var d in proj.outputDefs) {
        String cats = d.categories.map((c) => jsonEncode(c)).join(', ');
        sb.writeln(
          "            {'name': ${jsonEncode(d.name)}, 'type': ${d.type}, 'min': ${d.min}, 'max': ${d.max}, 'catLen': ${d.categories.length}, 'categories': [$cats]},",
        );
      }
      sb.writeln("        ]");
      sb.writeln("");
    }

    // ★修正ポイント：__init__ が終わった後に、メソッド群を定義する
    if (proj.engineType == 0) {
      sb.writeln(r"""
    def _predict_raw(self, input_data):
        current = list(input_data)
        for i in range(len(self.weights)):
            next_layer = [0.0] * self.layer_sizes[i + 1]
            for j in range(self.layer_sizes[i + 1]):
                total = self.biases[i][j]
                for k in range(self.layer_sizes[i]):
                    total += current[k] * self.weights[i][k][j]
                
                # Apply activation function (hidden layers only)
                if i < len(self.weights) - 1:
                    if self.hidden_activation == 0: # Sigmoid
                        next_layer[j] = 0.0 if total < -700 else 1.0 / (1.0 + math.exp(-total))
                    elif self.hidden_activation == 1: # ReLU
                        next_layer[j] = total if total > 0 else 0.01 * total
                    elif self.hidden_activation == 2: # Tanh
                        next_layer[j] = math.tanh(total)
                else:
                    next_layer[j] = total
            current = next_layer
        
        # Output layer activation
        if self.loss_type == 1: # Softmax
            max_val = max(current)
            sum_exp = 0.0
            for j in range(len(current)):
                current[j] = math.exp(current[j] - max_val)
                sum_exp += current[j]
            for j in range(len(current)):
                current[j] /= sum_exp
        else: # Sigmoid
            for j in range(len(current)):
                current[j] = 0.0 if current[j] < -700 else 1.0 / (1.0 + math.exp(-current[j]))
                
        return current
""");
    } else {
      final rf = state.rf!;
      int outSize = rf.outputSize;
      sb.writeln("    def _predict_raw(self, input_data):");
      sb.writeln("        out_buf = [0.0] * $outSize");
      for (int i = 0; i < rf.trees.length; i++) {
        sb.writeln("        # Tree $i");
        _genTreeLogic(sb, rf.trees[i].root, 2, 'python', outSize);
      }
      sb.writeln(
        "        for i in range(len(out_buf)): out_buf[i] /= ${rf.trees.length}.0",
      );
      sb.writeln("        return out_buf");
      sb.writeln("");
    }

    if (proj.mode == 1) {
      sb.writeln(r"""
    def predict_next_char(self, context_text):
        if len(context_text) < self.n_gram_count:
            return []
        ctx = context_text[-self.n_gram_count:]
        
        # Vectorize characters (One-Hot Encoding)
        input_data = []
        for char in ctx:
            idx = self.vocab.index(char) if char in self.vocab else -1
            for v in range(len(self.vocab)):
                input_data.append(1.0 if v == idx else 0.0)
                
        raw_pred = self._predict_raw(input_data)
        
        probs = []
        for i in range(min(len(self.vocab), len(raw_pred))):
            probs.append({'char': self.vocab[i], 'prob': raw_pred[i]})
            
        probs.sort(key=lambda x: x['prob'], reverse=True)
        return probs
""");
    } else {
      sb.writeln(r"""
    def predict(self, raw_inputs):
        if len(raw_inputs) != len(self.input_defs):
            raise ValueError(f"Expected {len(self.input_defs)} inputs, but got {len(raw_inputs)}.")

        # 1. Normalize input data (Encode strings/numbers to floats)
        encoded_inputs = []
        for i in range(len(self.input_defs)):
            definition = self.input_defs[i]
            val = raw_inputs[i]
            
            if definition['type'] == 1: # Category
                idx = -1
                if isinstance(val, str) and val in definition['categories']:
                    idx = definition['categories'].index(val)
                else:
                    try:
                        parsed_idx = int(float(val))
                        if 0 <= parsed_idx < definition['catLen']:
                            idx = parsed_idx
                    except (ValueError, TypeError):
                        pass
                
                # Fail-safe: Return a clear error if the value is invalid.
                if idx == -1:
                    valid_cats = definition['categories']
                    raise ValueError(
                        f"Invalid value '{val}' for input '{definition['name']}'. "
                        f"Expected one of {valid_cats} or a valid index (0 to {definition['catLen']-1})."
                    )
                
                for c in range(definition['catLen']):
                    encoded_inputs.append(1.0 if c == idx else 0.0)
            else: # Numeric
                try:
                    val_f = float(val)
                except (ValueError, TypeError):
                    raise ValueError(f"Invalid numeric value '{val}' for input '{definition['name']}'.")
                    
                min_v = definition['min']
                max_v = definition['max']
                if max_v == min_v:
                    encoded_inputs.append(0.0)
                else:
                    clamped = max(0.0, min(1.0, (val_f - min_v) / (max_v - min_v)))
                    encoded_inputs.append(clamped)
                    
        # 2. Run inference
        raw_out = self._predict_raw(encoded_inputs)
        
        # 3. Denormalize output data (Decode into readable dictionaries)
        results = []
        out_idx = 0
        for i in range(len(self.output_defs)):
            definition = self.output_defs[i]
            result_dict = {'name': definition['name']}
            
            if definition['type'] == 1: # Classification
                cat_len = definition['catLen']
                probs = raw_out[out_idx : out_idx + cat_len]
                cats = definition['categories']
                
                best_idx = probs.index(max(probs))
                best_class = cats[best_idx] if cats else str(best_idx)
                
                result_dict['prediction'] = best_class
                result_dict['confidence'] = max(probs)
                result_dict['probabilities'] = {cats[c]: probs[c] for c in range(cat_len)} if cats else {str(c): probs[c] for c in range(cat_len)}
                
                out_idx += cat_len
            else: # Regression
                min_v = definition['min']
                max_v = definition['max']
                pred_val = raw_out[out_idx] * (max_v - min_v) + min_v
                
                result_dict['prediction'] = pred_val
                
                out_idx += 1
                
            results.append(result_dict)
            
        return results
""");
    }

    // ＝＝＝ 👇 一番下部に付加する実行ブロック（スイッチ制御版） 👇 ＝＝＝
    sb.writeln(
      "# ======================================================================",
    );
    sb.writeln("# [Execution Block]");
    sb.writeln(
      "# Change 'RUN_TEST = False' to 'True' to instantly test the model.",
    );
    sb.writeln(
      "# ======================================================================",
    );
    sb.writeln("RUN_TEST = False");
    sb.writeln("");
    sb.writeln("if __name__ == '__main__' and RUN_TEST:");
    sb.writeln("    print('--- Hakoniwa AI Model Test ---')");
    sb.writeln("    ai = HakoniwaModel()");
    sb.writeln("    ");

    if (proj.mode == 1) {
      bool isJapanese = RegExp(r'[ぁ-んァ-ン一-龥]').hasMatch(proj.currentChars);
      String sampleText = isJapanese ? 'むかしむかし' : 'Once';

      sb.writeln(
        "    text = '$sampleText' # Note: Length must be >= n_gram_count",
      );
      sb.writeln(
        "    temperature = 0.5 # Set to 0.0 for greedy, >0.0 for creative",
      );
      sb.writeln("    print(f'Initial text: {text}')");
      sb.writeln(
        "    print(f'Generating next 50 characters (Temperature: {temperature})...')",
      );
      sb.writeln("    ");
      sb.writeln("    for _ in range(50):");
      sb.writeln("        probs = ai.predict_next_char(text)");
      sb.writeln("        if not probs: break");
      sb.writeln("        ");
      sb.writeln("        next_char = probs[0]['char']");
      sb.writeln("        if temperature > 0.05:");
      sb.writeln("            weights = []");
      sb.writeln("            for p in probs:");
      sb.writeln("                prob = p['prob'] if p['prob'] > 0 else 1e-7");
      sb.writeln("                weights.append(prob ** (1.0 / temperature))");
      sb.writeln("            weight_sum = sum(weights)");
      sb.writeln("            r = random.random() * weight_sum");
      sb.writeln("            for i, w in enumerate(weights):");
      sb.writeln("                r -= w");
      sb.writeln("                if r <= 0:");
      sb.writeln("                    next_char = probs[i]['char']");
      sb.writeln("                    break");
      sb.writeln("        ");
      sb.writeln("        text += next_char");
      sb.writeln("    ");
      sb.writeln("    print(f'\\nResult:\\n{text}')");
    } else {
      List<String> exampleInputs = [];
      for (int i = 0; i < proj.inputDefs.length; i++) {
        if (state.inputMask.isNotEmpty && !state.inputMask[i]) continue;
        var d = proj.inputDefs[i];
        if (d.type == 1 && d.categories.isNotEmpty) {
          exampleInputs.add(jsonEncode(d.categories[0]));
        } else if (d.type == 1) {
          exampleInputs.add("0.0");
        } else {
          double midVal = (d.min + d.max) / 2.0;
          exampleInputs.add(midVal.toStringAsFixed(1));
        }
      }

      sb.writeln("    raw_inputs = [${exampleInputs.join(', ')}]");
      sb.writeln("    results = ai.predict(raw_inputs)");
      sb.writeln("    print(f'Input values: {raw_inputs}')");
      sb.writeln(
        "    print(json.dumps(results, indent=2, ensure_ascii=False))",
      );
    }

    return sb.toString();
  }

  // ＝＝＝ 👨‍💻 C++コード生成ロジック（Makers & IoTエンジニア向け） ＝＝＝
  static String buildCppLegacyCode(ProjectState state) {
    final proj = state.proj;
    final sb = StringBuffer();

    // Dartの配列文字列 "[1, 2]" を C++の初期化リスト "{1, 2}" に変換
    String toCppList(dynamic list) {
      return list.toString().replaceAll('[', '{').replaceAll(']', '}');
    }

    sb.writeln("/*");
    sb.writeln(" * Auto-generated Hakoniwa AI Inference Model (Pure C++11)");
    sb.writeln(" * ");
    sb.writeln(
      " * DISCLAIMER: This auto-generated code is for educational and experimental purposes.",
    );
    sb.writeln(
      " * It is provided \"AS IS\" without warranty of any kind. The author shall not be liable",
    );
    sb.writeln(
      " * for any claim, damages or other liability arising from the use of this code.",
    );
    sb.writeln(" * ");
    sb.writeln(" * Project: ${proj.name}");
    sb.writeln(
      " * Note: Single header-only library. No external dependencies.",
    );
    sb.writeln(" */");
    sb.writeln("");
    sb.writeln("#ifndef HAKONIWA_MODEL_HPP");
    sb.writeln("#define HAKONIWA_MODEL_HPP");
    sb.writeln("");
    sb.writeln("#include <iostream>");
    sb.writeln("#include <vector>");
    sb.writeln("#include <string>");
    sb.writeln("#include <cmath>");
    sb.writeln("#include <map>");
    sb.writeln("#include <algorithm>");
    // stdexcept は例外用なので不要になりましたが、他の標準関数用に残しても無害です
    sb.writeln("#include <stdexcept>");
    sb.writeln("#include <cstdlib>"); // 💡 strtol, strtod, 乱数生成用
    sb.writeln("#include <ctime>"); // 💡 乱数シード用
    sb.writeln("");

    // ＝＝＝ 👇 クラス定義 👇 ＝＝＝
    sb.writeln("class HakoniwaModel {");
    sb.writeln("private:");

    if (proj.engineType == 0) {
      final nn = state.nn!;
      sb.writeln(
        "    std::vector<int> layer_sizes = ${toCppList(nn.layerSizes)};",
      );
      sb.writeln(
        "    int hidden_activation = ${nn.hiddenActivation.index}; // 0:Sigmoid, 1:ReLU, 2:Tanh",
      );
      sb.writeln(
        "    int loss_type = ${nn.lossType}; // 0:MSE(Sigmoid), 1:CrossEntropy(Softmax)",
      );
      sb.writeln("");
      sb.writeln("    // --- 🧠 Trained Parameters ---");
      sb.writeln(
        "    std::vector<std::vector<std::vector<double>>> weights = ${toCppList(nn.weights)};",
      );
      sb.writeln(
        "    std::vector<std::vector<double>> biases = ${toCppList(nn.biases)};",
      );
      sb.writeln("");
    }

    if (proj.mode == 1) {
      sb.writeln("    int n_gram_count = ${proj.nGramCount};");
      // 💡 jsonEncodeを使用して安全にエスケープ
      String cppVocab =
          '{' +
          proj.currentChars.split('').map((e) => jsonEncode(e)).join(', ') +
          '}';
      sb.writeln("    std::vector<std::string> vocab = $cppVocab;");
      sb.writeln("");
    } else {
      sb.writeln("    struct Def {");
      sb.writeln("        std::string name;");
      sb.writeln("        int type;");
      sb.writeln("        double min_val;");
      sb.writeln("        double max_val;");
      sb.writeln("        int catLen;");
      sb.writeln("        std::vector<std::string> categories;");
      sb.writeln("    };");
      sb.writeln("    std::vector<Def> input_defs;");
      sb.writeln("    std::vector<Def> output_defs;");
      sb.writeln("");
    }

    if (proj.engineType == 0) {
      sb.writeln(
        "    std::vector<double> _predict_raw(const std::vector<double>& input_data) {",
      );
      sb.writeln("        std::vector<double> current = input_data;");
      sb.writeln("        for (size_t i = 0; i < weights.size(); i++) {");
      sb.writeln(
        "            std::vector<double> next_layer(layer_sizes[i + 1], 0.0);",
      );
      sb.writeln(
        "            for (size_t j = 0; j < layer_sizes[i + 1]; j++) {",
      );
      sb.writeln("                double total = biases[i][j];");
      sb.writeln(
        "                for (size_t k = 0; k < layer_sizes[i]; k++) {",
      );
      sb.writeln("                    total += current[k] * weights[i][k][j];");
      sb.writeln("                }");
      sb.writeln("                if (i < weights.size() - 1) {");
      sb.writeln(
        "                    if (hidden_activation == 0) { // Sigmoid",
      );
      sb.writeln(
        "                        next_layer[j] = (total < -700) ? 0.0 : 1.0 / (1.0 + std::exp(-total));",
      );
      sb.writeln(
        "                    } else if (hidden_activation == 1) { // ReLU",
      );
      sb.writeln(
        "                        next_layer[j] = (total > 0) ? total : 0.01 * total;",
      );
      sb.writeln(
        "                    } else if (hidden_activation == 2) { // Tanh",
      );
      sb.writeln("                        next_layer[j] = std::tanh(total);");
      sb.writeln("                    }");
      sb.writeln("                } else {");
      sb.writeln("                    next_layer[j] = total;");
      sb.writeln("                }");
      sb.writeln("            }");
      sb.writeln("            current = next_layer;");
      sb.writeln("        }");
      sb.writeln("        if (loss_type == 1) { // Softmax");
      sb.writeln(
        "            double max_val = *std::max_element(current.begin(), current.end());",
      );
      sb.writeln("            double sum_exp = 0.0;");
      sb.writeln("            for (double& val : current) {");
      sb.writeln("                val = std::exp(val - max_val);");
      sb.writeln("                sum_exp += val;");
      sb.writeln("            }");
      sb.writeln("            for (double& val : current) val /= sum_exp;");
      sb.writeln("        } else { // Sigmoid");
      sb.writeln("            for (double& val : current) {");
      sb.writeln(
        "                val = (val < -700) ? 0.0 : 1.0 / (1.0 + std::exp(-val));",
      );
      sb.writeln("            }");
      sb.writeln("        }");
      sb.writeln("        return current;");
      sb.writeln("    }");
    } else {
      final rf = state.rf!;
      int outSize = rf.outputSize;
      sb.writeln(
        "    std::vector<double> _predict_raw(const std::vector<double>& input_data) {",
      );
      sb.writeln("        std::vector<double> out_buf($outSize, 0.0);");
      for (int i = 0; i < rf.trees.length; i++) {
        sb.writeln("        // Tree $i");
        _genTreeLogic(sb, rf.trees[i].root, 2, 'cpp_rich', outSize);
      }
      sb.writeln(
        "        for(int i=0; i<$outSize; i++) out_buf[i] /= ${rf.trees.length}.0;",
      );
      sb.writeln("        return out_buf;");
      sb.writeln("    }");
    }

    sb.writeln("public:");
    sb.writeln("    HakoniwaModel() {");
    if (proj.mode == 0) {
      for (int i = 0; i < proj.inputDefs.length; i++) {
        // ★書き換え
        if (state.inputMask.isNotEmpty && !state.inputMask[i]) continue; // ★追加
        var d = proj.inputDefs[i];
        String cats =
            '{' + d.categories.map((c) => jsonEncode(c)).join(', ') + '}';
        sb.writeln(
          "        input_defs.push_back({${jsonEncode(d.name)}, ${d.type}, ${d.min}, ${d.max}, ${d.categories.length}, $cats});",
        );
      }
      for (var d in proj.outputDefs) {
        String cats =
            '{' + d.categories.map((c) => jsonEncode(c)).join(', ') + '}';
        sb.writeln(
          "        output_defs.push_back({${jsonEncode(d.name)}, ${d.type}, ${d.min}, ${d.max}, ${d.categories.length}, $cats});",
        );
      }
    }
    sb.writeln("    }");
    sb.writeln("");

    if (proj.mode == 1) {
      sb.writeln(r"""    // Predict next character with native UTF-8 support
    std::vector<std::pair<std::string, double>> predict_next_char(const std::string& context_text) {
        std::vector<std::string> chars;
        // UTF-8 byte parsing to handle both English and Japanese characters cleanly
        for (size_t i = 0; i < context_text.length(); ) {
            int cbytes = 1;
            unsigned char c = context_text[i];
            if ((c & 0xE0) == 0xC0) cbytes = 2;
            else if ((c & 0xF0) == 0xE0) cbytes = 3;
            else if ((c & 0xF8) == 0xF0) cbytes = 4;
            
            // 安全対策：不正なUTF-8（途中で途切れている等）によるクラッシュ防止
            if (i + cbytes > context_text.length()) {
                cbytes = 1; // 範囲外の場合は1バイトとして処理して進める
            }

            chars.push_back(context_text.substr(i, cbytes));
            i += cbytes;
        }
        
        if (chars.size() < n_gram_count) return {};
        
        std::vector<std::string> ctx(chars.end() - n_gram_count, chars.end());
        std::vector<double> input_data;
        for (const std::string& ch : ctx) {
            int idx = -1;
            auto it = std::find(vocab.begin(), vocab.end(), ch);
            if (it != vocab.end()) idx = std::distance(vocab.begin(), it);
            
            for (size_t v = 0; v < vocab.size(); v++) {
                input_data.push_back((v == idx) ? 1.0 : 0.0);
            }
        }
        
        std::vector<double> raw_pred = _predict_raw(input_data);
        std::vector<std::pair<std::string, double>> probs;
        for (size_t i = 0; i < std::min(vocab.size(), raw_pred.size()); i++) {
            probs.push_back({vocab[i], raw_pred[i]});
        }
        
        std::sort(probs.begin(), probs.end(), [](const std::pair<std::string, double>& a, const std::pair<std::string, double>& b) {
            return a.second > b.second;
        });
        return probs;
    }
""");
    } else {
      sb.writeln(r"""    // Returns a beautiful JSON-formatted string natively
    std::string predict(const std::vector<std::string>& raw_inputs) {
        if (raw_inputs.size() != input_defs.size()) {
            return "{\"error\": \"Input size mismatch\"}";
        }
        std::vector<double> encoded_inputs;
        for (size_t i = 0; i < input_defs.size(); i++) {
            const auto& def = input_defs[i];
            std::string val = raw_inputs[i];
            
            if (def.type == 1) { // Category
                int idx = -1;
                auto it = std::find(def.categories.begin(), def.categories.end(), val);
                if (it != def.categories.end()) {
                    idx = std::distance(def.categories.begin(), it);
                } else {
                    // 💡 修正箇所：try-catch を使わず std::strtol で安全にパース
                    char* end;
                    idx = static_cast<int>(std::strtol(val.c_str(), &end, 10));
                }
                if (idx < 0 || idx >= def.catLen) idx = 0; // Fallback
                for (int c = 0; c < def.catLen; c++) {
                    encoded_inputs.push_back((c == idx) ? 1.0 : 0.0);
                }
            } else { // Numeric
                // 💡 修正箇所：try-catch を使わず std::strtod で安全にパース
                char* end;
                double val_f = std::strtod(val.c_str(), &end);
                
                if (def.max_val == def.min_val) {
                    encoded_inputs.push_back(0.0);
                } else {
                    double clamped = std::max(0.0, std::min(1.0, (val_f - def.min_val) / (def.max_val - def.min_val)));
                    encoded_inputs.push_back(clamped);
                }
            }
        }
        
        std::vector<double> raw_out = _predict_raw(encoded_inputs);
        
        std::string json = "[\n";
        int out_idx = 0;
        for (size_t i = 0; i < output_defs.size(); i++) {
            const auto& def = output_defs[i];
            json += "  {\n";
            json += "    \"name\": \"" + def.name + "\",\n";
            
            if (def.type == 1) { // Classification
                int cat_len = def.catLen;
                double max_prob = -1.0;
                int best_idx = 0;
                for (int c = 0; c < cat_len; c++) {
                    if (raw_out[out_idx + c] > max_prob) {
                        max_prob = raw_out[out_idx + c];
                        best_idx = c;
                    }
                }
                std::string best_class = def.categories.empty() ? std::to_string(best_idx) : def.categories[best_idx];
                
                json += "    \"prediction\": \"" + best_class + "\",\n";
                json += "    \"confidence\": " + std::to_string(max_prob) + ",\n";
                json += "    \"probabilities\": {\n";
                for (int c = 0; c < cat_len; c++) {
                    std::string c_name = def.categories.empty() ? std::to_string(c) : def.categories[c];
                    json += "      \"" + c_name + "\": " + std::to_string(raw_out[out_idx + c]) + (c < cat_len - 1 ? ",\n" : "\n");
                }
                json += "    }\n";
                out_idx += cat_len;
            } else { // Regression
                double pred_val = raw_out[out_idx] * (def.max_val - def.min_val) + def.min_val;
                json += "    \"prediction\": " + std::to_string(pred_val) + "\n";
                out_idx += 1;
            }
            
            let block_comma = if (i < output_defs.size() - 1) "," else "";
            json += "  }" + std::string(block_comma) + "\n";
        }
        
        json += "]";
        return json;
    }
""");
    }
    sb.writeln("};");
    sb.writeln("");
    sb.writeln("#endif // HAKONIWA_MODEL_HPP");
    sb.writeln("");

    // ＝＝＝ 👇 C++版 実行ブロック (Arduino / PC両対応) 👇 ＝＝＝
    sb.writeln(
      "// ======================================================================",
    );
    sb.writeln("// [Execution Block]");
    sb.writeln(
      "// Change '#define RUN_TEST 0' to '#define RUN_TEST 1' to enable the test main() function.",
    );
    sb.writeln(
      "// ======================================================================",
    );
    sb.writeln("#define RUN_TEST 0");
    sb.writeln("");
    sb.writeln("#if RUN_TEST");
    sb.writeln("int main() {");
    sb.writeln("    std::cout << \"--- Hakoniwa AI Model Test (C++) ---\\n\";");
    sb.writeln("    HakoniwaModel ai;");
    sb.writeln("");

    if (proj.mode == 0) {
      // 📊 テーブルデータ予測モード
      List<String> exampleInputs = [];
      for (int i = 0; i < proj.inputDefs.length; i++) {
        // ★書き換え
        if (state.inputMask.isNotEmpty && !state.inputMask[i]) continue; // ★追加
        var d = proj.inputDefs[i];
        if (d.type == 1 && d.categories.isNotEmpty) {
          exampleInputs.add(jsonEncode(d.categories[0]));
        } else if (d.type == 1) {
          exampleInputs.add('"0"');
        } else {
          double midVal = (d.min + d.max) / 2.0;
          exampleInputs.add(jsonEncode(midVal.toStringAsFixed(1)));
        }
      }
      sb.writeln(
        "    std::vector<std::string> raw_inputs = {${exampleInputs.join(', ')}};",
      );
      sb.writeln("    std::string result_json = ai.predict(raw_inputs);");
      sb.writeln("    ");
      sb.writeln("    std::cout << \"Input values: [ \";");
      sb.writeln(
        "    for(const auto& val : raw_inputs) std::cout << val << \" \";",
      );
      sb.writeln("    std::cout << \"]\\n\\n\";");
      sb.writeln("    std::cout << result_json << std::endl;");
    } else {
      // 📝 テキスト生成モード（アルファベット・ひらがな両対応 ＆ ゆらぎ対応）
      bool isJapanese = RegExp(r'[ぁ-んァ-ン一-龥]').hasMatch(proj.currentChars);
      String sampleText = isJapanese ? 'むかしむかし' : 'Once';

      sb.writeln("    std::string text = ${jsonEncode(sampleText)};");
      sb.writeln(
        "    double temperature = 0.5; // Set to 0.0 for greedy, >0.0 for creative",
      );
      sb.writeln("    std::cout << \"Initial text: \" << text << \"\\n\";");
      sb.writeln(
        "    std::cout << \"Generating next 50 characters (Temperature: \" << temperature << \")...\\n\\n\";",
      );
      sb.writeln("    ");
      sb.writeln(
        "    std::srand(static_cast<unsigned int>(std::time(nullptr)));",
      );
      sb.writeln("    for (int i = 0; i < 50; i++) {");
      sb.writeln("        auto probs = ai.predict_next_char(text);");
      sb.writeln("        if (probs.empty()) break;");
      sb.writeln("        ");
      sb.writeln("        std::string next_char = probs[0].first;");
      sb.writeln("        if (temperature > 0.05) {");
      sb.writeln("            std::vector<double> weights;");
      sb.writeln("            double weight_sum = 0.0;");
      sb.writeln("            for (const auto& p : probs) {");
      sb.writeln(
        "                double prob = (p.second <= 0.0) ? 1e-7 : p.second;",
      );
      sb.writeln(
        "                double w = std::pow(prob, 1.0 / temperature);",
      );
      sb.writeln("                weights.push_back(w);");
      sb.writeln("                weight_sum += w;");
      sb.writeln("            }");
      sb.writeln(
        "            double r = (static_cast<double>(std::rand()) / RAND_MAX) * weight_sum;",
      );
      sb.writeln("            for (size_t j = 0; j < weights.size(); j++) {");
      sb.writeln("                r -= weights[j];");
      sb.writeln("                if (r <= 0.0) {");
      sb.writeln("                    next_char = probs[j].first;");
      sb.writeln("                    break;");
      sb.writeln("                }");
      sb.writeln("            }");
      sb.writeln("        }");
      sb.writeln("        text += next_char;");
      sb.writeln("    }");
      sb.writeln("    ");
      sb.writeln("    std::cout << \"Result:\\n\" << text << std::endl;");
    }

    sb.writeln("    return 0;");
    sb.writeln("}");
    sb.writeln("#endif");

    return sb.toString();
  }

  // ============================================================================
  // 1. Rich & Convenient Mode (For ESP32, Raspberry Pi, PC)
  // ============================================================================
  static String buildCppRichCode(ProjectState state) {
    final proj = state.proj;
    final sb = StringBuffer();

    // Convert Dart list "[1, 2]" to C++ initializer list "{1, 2}"
    String toCppList(dynamic list) {
      return list.toString().replaceAll('[', '{').replaceAll(']', '}');
    }

    sb.writeln("/*");
    sb.writeln(" * Auto-generated Hakoniwa AI Inference Model (Rich C++ Mode)");
    sb.writeln(
      " * Engine: ${proj.engineType == 1 ? 'Random Forest' : 'Neural Network'}",
    );
    sb.writeln(" * ");
    sb.writeln(
      " * DISCLAIMER: This auto-generated code is for educational and experimental purposes.",
    );
    sb.writeln(
      " * It is provided \"AS IS\" without warranty of any kind. The author shall not be liable",
    );
    sb.writeln(
      " * for any claim, damages or other liability arising from the use of this code.",
    );
    sb.writeln(" * ");
    sb.writeln(" * Project: ${proj.name}");
    sb.writeln(
      " * Note: Single header-only library. No external dependencies.",
    );
    sb.writeln(
      " * Suitable for ESP32, Raspberry Pi, PC, and devices with sufficient RAM.",
    );
    sb.writeln(" */");
    sb.writeln("");
    sb.writeln("#ifndef HAKONIWA_MODEL_RICH_HPP");
    sb.writeln("#define HAKONIWA_MODEL_RICH_HPP");
    sb.writeln("");
    sb.writeln("#include <iostream>");
    sb.writeln("#include <vector>");
    sb.writeln("#include <string>");
    sb.writeln("#include <cmath>");
    sb.writeln("#include <map>");
    sb.writeln("#include <algorithm>");
    sb.writeln("#include <stdexcept>");
    sb.writeln("#include <cstdlib>"); // For strtol, strtod, random generation
    sb.writeln("#include <ctime>"); // For random seed
    sb.writeln("");

    // === 👇 Class Definition 👇 ===
    sb.writeln("class HakoniwaModel {");
    sb.writeln("private:");
    if (proj.engineType == 0) {
      final nn = state.nn!;
      sb.writeln(
        "    std::vector<int> layer_sizes = ${toCppList(nn.layerSizes)};",
      );
      sb.writeln(
        "    int hidden_activation = ${nn.hiddenActivation.index}; // 0:Sigmoid, 1:ReLU, 2:Tanh",
      );
      sb.writeln(
        "    int loss_type = ${nn.lossType}; // 0:MSE(Sigmoid), 1:CrossEntropy(Softmax)",
      );
      sb.writeln("");
      sb.writeln("    // --- 🧠 Trained Parameters ---");
      sb.writeln(
        "    std::vector<std::vector<std::vector<double>>> weights = ${toCppList(nn.weights)};",
      );
      sb.writeln(
        "    std::vector<std::vector<double>> biases = ${toCppList(nn.biases)};",
      );
      sb.writeln("");
    }

    if (proj.mode == 1) {
      sb.writeln("    int n_gram_count = ${proj.nGramCount};");
      String cppVocab =
          '{' +
          proj.currentChars.split('').map((e) => jsonEncode(e)).join(', ') +
          '}';
      sb.writeln("    std::vector<std::string> vocab = $cppVocab;");
      sb.writeln("");
    } else {
      sb.writeln("    struct Def {");
      sb.writeln("        std::string name;");
      sb.writeln("        int type;");
      sb.writeln("        double min_val;");
      sb.writeln("        double max_val;");
      sb.writeln("        int catLen;");
      sb.writeln("        std::vector<std::string> categories;");
      sb.writeln("    };");
      sb.writeln("    std::vector<Def> input_defs;");
      sb.writeln("    std::vector<Def> output_defs;");
      sb.writeln("");
    }

    if (proj.engineType == 0) {
      sb.writeln(
        "    std::vector<double> _predict_raw(const std::vector<double>& input_data) {",
      );
      sb.writeln("        std::vector<double> current = input_data;");
      sb.writeln("        for (size_t i = 0; i < weights.size(); i++) {");
      sb.writeln(
        "            std::vector<double> next_layer(layer_sizes[i + 1], 0.0);",
      );
      sb.writeln(
        "            for (size_t j = 0; j < layer_sizes[i + 1]; j++) {",
      );
      sb.writeln("                double total = biases[i][j];");
      sb.writeln(
        "                for (size_t k = 0; k < layer_sizes[i]; k++) {",
      );
      sb.writeln("                    total += current[k] * weights[i][k][j];");
      sb.writeln("                }");
      sb.writeln("                if (i < weights.size() - 1) {");
      sb.writeln(
        "                    if (hidden_activation == 0) { // Sigmoid",
      );
      sb.writeln(
        "                        next_layer[j] = (total < -700) ? 0.0 : 1.0 / (1.0 + std::exp(-total));",
      );
      sb.writeln(
        "                    } else if (hidden_activation == 1) { // ReLU",
      );
      sb.writeln(
        "                        next_layer[j] = (total > 0) ? total : 0.01 * total;",
      );
      sb.writeln(
        "                    } else if (hidden_activation == 2) { // Tanh",
      );
      sb.writeln("                        next_layer[j] = std::tanh(total);");
      sb.writeln("                    }");
      sb.writeln("                } else {");
      sb.writeln("                    next_layer[j] = total;");
      sb.writeln("                }");
      sb.writeln("            }");
      sb.writeln("            current = next_layer;");
      sb.writeln("        }");
      sb.writeln("        if (loss_type == 1) { // Softmax");
      sb.writeln(
        "            double max_val = *std::max_element(current.begin(), current.end());",
      );
      sb.writeln("            double sum_exp = 0.0;");
      sb.writeln("            for (double& val : current) {");
      sb.writeln("                val = std::exp(val - max_val);");
      sb.writeln("                sum_exp += val;");
      sb.writeln("            }");
      sb.writeln("            for (double& val : current) val /= sum_exp;");
      sb.writeln("        } else { // Sigmoid");
      sb.writeln("            for (double& val : current) {");
      sb.writeln(
        "                val = (val < -700) ? 0.0 : 1.0 / (1.0 + std::exp(-val));",
      );
      sb.writeln("            }");
      sb.writeln("        }");
      sb.writeln("        return current;");
      sb.writeln("    }");
    } else {
      final rf = state.rf!;
      int outSize = rf.outputSize;
      sb.writeln(
        "    std::vector<double> _predict_raw(const std::vector<double>& input_data) {",
      );
      sb.writeln("        std::vector<double> out_buf($outSize, 0.0);");
      for (int i = 0; i < rf.trees.length; i++) {
        sb.writeln("        // Tree $i");
        _genTreeLogic(sb, rf.trees[i].root, 2, 'cpp_rich', outSize);
      }
      sb.writeln(
        "        for(int i=0; i<$outSize; i++) out_buf[i] /= ${rf.trees.length}.0;",
      );
      sb.writeln("        return out_buf;");
      sb.writeln("    }");
    }

    sb.writeln("public:");
    sb.writeln("    HakoniwaModel() {");
    if (proj.mode == 0) {
      for (int i = 0; i < proj.inputDefs.length; i++) {
        // ★書き換え
        if (state.inputMask.isNotEmpty && !state.inputMask[i]) continue; // ★追加
        var d = proj.inputDefs[i];
        String cats =
            '{' + d.categories.map((c) => jsonEncode(c)).join(', ') + '}';
        sb.writeln(
          "        input_defs.push_back({${jsonEncode(d.name)}, ${d.type}, ${d.min}, ${d.max}, ${d.categories.length}, $cats});",
        );
      }
      for (var d in proj.outputDefs) {
        String cats =
            '{' + d.categories.map((c) => jsonEncode(c)).join(', ') + '}';
        sb.writeln(
          "        output_defs.push_back({${jsonEncode(d.name)}, ${d.type}, ${d.min}, ${d.max}, ${d.categories.length}, $cats});",
        );
      }
    }
    sb.writeln("    }");
    sb.writeln("");

    if (proj.mode == 1) {
      sb.writeln(r"""    // Predict next character with native UTF-8 support
    std::vector<std::pair<std::string, double>> predict_next_char(const std::string& context_text) {
        std::vector<std::string> chars;
        // UTF-8 byte parsing to handle both English and Japanese characters cleanly
        for (size_t i = 0; i < context_text.length(); ) {
            int cbytes = 1;
            unsigned char c = context_text[i];
            if ((c & 0xE0) == 0xC0) cbytes = 2;
            else if ((c & 0xF0) == 0xE0) cbytes = 3;
            else if ((c & 0xF8) == 0xF0) cbytes = 4;
            
            // Safety fallback: Prevent crash on invalid/incomplete UTF-8
            if (i + cbytes > context_text.length()) {
                cbytes = 1; // Treat as 1 byte if out of bounds
            }
            chars.push_back(context_text.substr(i, cbytes));
            i += cbytes;
        }
        
        if (chars.size() < n_gram_count) return {};
        
        std::vector<std::string> ctx(chars.end() - n_gram_count, chars.end());
        std::vector<double> input_data;
        for (const std::string& ch : ctx) {
            int idx = -1;
            auto it = std::find(vocab.begin(), vocab.end(), ch);
            if (it != vocab.end()) idx = std::distance(vocab.begin(), it);
            
            for (size_t v = 0; v < vocab.size(); v++) {
                input_data.push_back((v == idx) ? 1.0 : 0.0);
            }
        }
        
        std::vector<double> raw_pred = _predict_raw(input_data);
        std::vector<std::pair<std::string, double>> probs;
        for (size_t i = 0; i < std::min(vocab.size(), raw_pred.size()); i++) {
            probs.push_back({vocab[i], raw_pred[i]});
        }
        
        std::sort(probs.begin(), probs.end(), [](const std::pair<std::string, double>& a, const std::pair<std::string, double>& b) {
            return a.second > b.second;
        });
        return probs;
    }
""");
    } else {
      sb.writeln(r"""    // Returns a beautiful JSON-formatted string natively
    std::string predict(const std::vector<std::string>& raw_inputs) {
        if (raw_inputs.size() != input_defs.size()) {
            return "{\"error\": \"Input size mismatch\"}";
        }
        std::vector<double> encoded_inputs;
        for (size_t i = 0; i < input_defs.size(); i++) {
            const auto& def = input_defs[i];
            std::string val = raw_inputs[i];
            
            if (def.type == 1) { // Category
                int idx = -1;
                auto it = std::find(def.categories.begin(), def.categories.end(), val);
                if (it != def.categories.end()) {
                    idx = std::distance(def.categories.begin(), it);
                } else {
                    // Safe parsing without try-catch using std::strtol
                    char* end;
                    idx = static_cast<int>(std::strtol(val.c_str(), &end, 10));
                }
                if (idx < 0 || idx >= def.catLen) idx = 0; // Fallback
                for (int c = 0; c < def.catLen; c++) {
                    encoded_inputs.push_back((c == idx) ? 1.0 : 0.0);
                }
            } else { // Numeric
                // Safe parsing without try-catch using std::strtod
                char* end;
                double val_f = std::strtod(val.c_str(), &end);
                
                if (def.max_val == def.min_val) {
                    encoded_inputs.push_back(0.0);
                } else {
                    double clamped = std::max(0.0, std::min(1.0, (val_f - def.min_val) / (def.max_val - def.min_val)));
                    encoded_inputs.push_back(clamped);
                }
            }
        }
        
        std::vector<double> raw_out = _predict_raw(encoded_inputs);
        
        std::string json = "[\n";
        int out_idx = 0;
        for (size_t i = 0; i < output_defs.size(); i++) {
            const auto& def = output_defs[i];
            json += "  {\n";
            json += "    \"name\": \"" + def.name + "\",\n";
            
            if (def.type == 1) { // Classification
                int cat_len = def.catLen;
                double max_prob = -1.0;
                int best_idx = 0;
                for (int c = 0; c < cat_len; c++) {
                    if (raw_out[out_idx + c] > max_prob) {
                        max_prob = raw_out[out_idx + c];
                        best_idx = c;
                    }
                }
                std::string best_class = def.categories.empty() ? std::to_string(best_idx) : def.categories[best_idx];
                
                json += "    \"prediction\": \"" + best_class + "\",\n";
                json += "    \"confidence\": " + std::to_string(max_prob) + ",\n";
                json += "    \"probabilities\": {\n";
                for (int c = 0; c < cat_len; c++) {
                    std::string c_name = def.categories.empty() ? std::to_string(c) : def.categories[c];
                    json += "      \"" + c_name + "\": " + std::to_string(raw_out[out_idx + c]) + (c < cat_len - 1 ? ",\n" : "\n");
                }
                json += "    }\n";
                out_idx += cat_len;
            } else { // Regression
                double pred_val = raw_out[out_idx] * (def.max_val - def.min_val) + def.min_val;
                json += "    \"prediction\": " + std::to_string(pred_val) + "\n";
                out_idx += 1;
            }
            
            std::string block_comma = (i < output_defs.size() - 1) ? "," : "";
            json += "  }" + block_comma + "\n";
        }
        
        json += "]";
        return json;
    }
""");
    }
    sb.writeln("};");
    sb.writeln("");
    sb.writeln("#endif // HAKONIWA_MODEL_RICH_HPP");
    sb.writeln("");

    // === 👇 Execution Block (Supports both Arduino(ESP32) and PC) 👇 ===
    sb.writeln(
      "// ======================================================================",
    );
    sb.writeln("// [Execution Block]");
    sb.writeln(
      "// Paste into Wokwi (ESP32) or compile on PC to test immediately.",
    );
    sb.writeln(
      "// ======================================================================",
    );
    sb.writeln("#if defined(ARDUINO)");
    sb.writeln("void setup() {");
    sb.writeln("    Serial.begin(115200);");
    sb.writeln(
      "    Serial.println(\"--- Hakoniwa AI Rich Mode Test (ESP32) ---\");",
    );
    sb.writeln("    HakoniwaModel ai;");
    sb.writeln("");

    if (proj.mode == 0) {
      List<String> exampleInputs = [];
      for (int i = 0; i < proj.inputDefs.length; i++) {
        // ★書き換え
        if (state.inputMask.isNotEmpty && !state.inputMask[i]) continue; // ★追加
        var d = proj.inputDefs[i];
        if (d.type == 1 && d.categories.isNotEmpty) {
          exampleInputs.add(jsonEncode(d.categories[0]));
        } else if (d.type == 1) {
          exampleInputs.add('"0"');
        } else {
          double midVal = (d.min + d.max) / 2.0;
          exampleInputs.add(jsonEncode(midVal.toStringAsFixed(1)));
        }
      }
      sb.writeln(
        "    std::vector<std::string> raw_inputs = {${exampleInputs.join(', ')}};",
      );
      sb.writeln("    std::string result_json = ai.predict(raw_inputs);");
      sb.writeln("    ");
      sb.writeln("    Serial.print(\"Input values: [ \");");
      sb.writeln(
        "    for(const auto& val : raw_inputs) { Serial.print(val.c_str()); Serial.print(\" \"); }",
      );
      sb.writeln("    Serial.println(\"]\");");
      sb.writeln("    Serial.println(result_json.c_str());");
    } else {
      bool isJapanese = RegExp(r'[ぁ-んァ-ン一-龥]').hasMatch(proj.currentChars);
      String sampleText = isJapanese ? 'むかしむかし' : 'Once';
      sb.writeln("    std::string text = ${jsonEncode(sampleText)};");
      sb.writeln(
        "    double temperature = 0.5; // Set to 0.0 for greedy, >0.0 for creative",
      );
      sb.writeln(
        "    Serial.print(\"Initial text: \"); Serial.println(text.c_str());",
      );
      sb.writeln("    Serial.println(\"Generating next 50 characters...\");");
      sb.writeln("    ");
      sb.writeln(
        "    std::srand(static_cast<unsigned int>(std::time(nullptr)));",
      );
      sb.writeln("    for (int i = 0; i < 50; i++) {");
      sb.writeln("        auto probs = ai.predict_next_char(text);");
      sb.writeln("        if (probs.empty()) break;");
      sb.writeln("        ");
      sb.writeln("        std::string next_char = probs[0].first;");
      sb.writeln("        if (temperature > 0.05) {");
      sb.writeln("            std::vector<double> weights;");
      sb.writeln("            double weight_sum = 0.0;");
      sb.writeln("            for (const auto& p : probs) {");
      sb.writeln(
        "                double prob = (p.second <= 0.0) ? 1e-7 : p.second;",
      );
      sb.writeln(
        "                double w = std::pow(prob, 1.0 / temperature);",
      );
      sb.writeln("                weights.push_back(w);");
      sb.writeln("                weight_sum += w;");
      sb.writeln("            }");
      sb.writeln(
        "            double r = (static_cast<double>(std::rand()) / RAND_MAX) * weight_sum;",
      );
      sb.writeln("            for (size_t j = 0; j < weights.size(); j++) {");
      sb.writeln("                r -= weights[j];");
      sb.writeln("                if (r <= 0.0) {");
      sb.writeln("                    next_char = probs[j].first;");
      sb.writeln("                    break;");
      sb.writeln("                }");
      sb.writeln("            }");
      sb.writeln("        }");
      sb.writeln("        text += next_char;");
      sb.writeln("    }");
      sb.writeln("    ");
      sb.writeln("    Serial.println(\"Result:\");");
      sb.writeln("    Serial.println(text.c_str());");
    }
    sb.writeln("}");
    sb.writeln("void loop() {}");

    // For PC Compilation
    sb.writeln("#else // PC Test Main");
    sb.writeln("int main() {");
    sb.writeln(
      "    std::cout << \"--- Hakoniwa AI Rich Mode Test (PC) ---\\n\";",
    );
    sb.writeln("    HakoniwaModel ai;");
    sb.writeln("");
    if (proj.mode == 0) {
      List<String> exampleInputs = [];
      for (int i = 0; i < proj.inputDefs.length; i++) {
        // ★書き換え
        if (state.inputMask.isNotEmpty && !state.inputMask[i]) continue; // ★追加
        var d = proj.inputDefs[i];
        if (d.type == 1 && d.categories.isNotEmpty) {
          exampleInputs.add(jsonEncode(d.categories[0]));
        } else if (d.type == 1) {
          exampleInputs.add('"0"');
        } else {
          double midVal = (d.min + d.max) / 2.0;
          exampleInputs.add(jsonEncode(midVal.toStringAsFixed(1)));
        }
      }
      sb.writeln(
        "    std::vector<std::string> raw_inputs = {${exampleInputs.join(', ')}};",
      );
      sb.writeln("    std::string result_json = ai.predict(raw_inputs);");
      sb.writeln("    ");
      sb.writeln("    std::cout << \"Input values: [ \";");
      sb.writeln(
        "    for(const auto& val : raw_inputs) std::cout << val << \" \";",
      );
      sb.writeln("    std::cout << \"]\\n\\n\";");
      sb.writeln("    std::cout << result_json << std::endl;");
    } else {
      bool isJapanese = RegExp(r'[ぁ-んァ-ン一-龥]').hasMatch(proj.currentChars);
      String sampleText = isJapanese ? 'むかしむかし' : 'Once';
      sb.writeln("    std::string text = ${jsonEncode(sampleText)};");
      sb.writeln("    double temperature = 0.5;");
      sb.writeln("    std::cout << \"Initial text: \" << text << \"\\n\";");
      sb.writeln(
        "    std::cout << \"Generating next 50 characters...\\n\\n\";",
      );
      sb.writeln("    ");
      sb.writeln(
        "    std::srand(static_cast<unsigned int>(std::time(nullptr)));",
      );
      sb.writeln("    for (int i = 0; i < 50; i++) {");
      sb.writeln("        auto probs = ai.predict_next_char(text);");
      sb.writeln("        if (probs.empty()) break;");
      sb.writeln("        ");
      sb.writeln("        std::string next_char = probs[0].first;");
      sb.writeln("        if (temperature > 0.05) {");
      sb.writeln("            std::vector<double> weights;");
      sb.writeln("            double weight_sum = 0.0;");
      sb.writeln("            for (const auto& p : probs) {");
      sb.writeln(
        "                double prob = (p.second <= 0.0) ? 1e-7 : p.second;",
      );
      sb.writeln(
        "                double w = std::pow(prob, 1.0 / temperature);",
      );
      sb.writeln("                weights.push_back(w);");
      sb.writeln("                weight_sum += w;");
      sb.writeln("            }");
      sb.writeln(
        "            double r = (static_cast<double>(std::rand()) / RAND_MAX) * weight_sum;",
      );
      sb.writeln("            for (size_t j = 0; j < weights.size(); j++) {");
      sb.writeln("                r -= weights[j];");
      sb.writeln("                if (r <= 0.0) {");
      sb.writeln("                    next_char = probs[j].first;");
      sb.writeln("                    break;");
      sb.writeln("                }");
      sb.writeln("            }");
      sb.writeln("        }");
      sb.writeln("        text += next_char;");
      sb.writeln("    }");
      sb.writeln("    ");
      sb.writeln("    std::cout << \"Result:\\n\" << text << std::endl;");
    }
    sb.writeln("    return 0;");
    sb.writeln("}");
    sb.writeln("#endif");

    return sb.toString();
  }

  // ============================================================================
  // 2. Extreme Bare-Metal Mode (For Arduino Uno, AVR, low-RAM devices)
  // ============================================================================
  static String buildBareMetalCppCode(ProjectState state) {
    final proj = state.proj;
    final sb = StringBuffer();

    // 📝 Helper to write nested array as C++ float constants with 'f' suffix
    String toBareMetalArray(dynamic list) {
      if (list is List) {
        return '{' + list.map((e) => toBareMetalArray(e)).join(', ') + '}';
      } else {
        return list.toString() + 'f';
      }
    }

    int inNodes = 0;
    int outNodes = 0;
    int maxNodes = 0;

    if (proj.engineType == 0) {
      final nn = state.nn!;
      inNodes = nn.layerSizes.first;
      outNodes = nn.layerSizes.last;
      for (int s in nn.layerSizes) {
        if (s > maxNodes) maxNodes = s;
      }
    } else {
      final rf = state.rf!;
      inNodes = rf.inputSize;
      outNodes = rf.outputSize;
    }

    sb.writeln("/*");
    sb.writeln(
      " * Auto-generated Hakoniwa AI Inference Model (Extreme Bare-Metal C++)",
    );
    sb.writeln(
      " * Engine: ${proj.engineType == 1 ? 'Random Forest' : 'Neural Network'}",
    );
    sb.writeln(" * ");
    sb.writeln(
      " * DISCLAIMER: This auto-generated code is for educational and experimental purposes.",
    );
    sb.writeln(
      " * It is provided \"AS IS\" without warranty of any kind. The author shall not be liable",
    );
    sb.writeln(
      " * for any claim, damages or other liability arising from the use of this code.",
    );
    sb.writeln(" * ");
    sb.writeln(" * Project: ${proj.name}");
    sb.writeln(" * [! WARNING: PURE C/C++ MODE !]");
    sb.writeln(
      " * - No dynamic memory allocation (No std::vector, std::string).",
    );
    sb.writeln(
      " * - Uses <math.h> only. Weights are stored in 'const' arrays (Flash Memory).",
    );
    sb.writeln(
      " * - Ultra-low RAM footprint. Perfect for Arduino Uno (ATmega328P) and similar MCU.",
    );
    sb.writeln(" */");
    sb.writeln("");
    sb.writeln("#include <math.h>");
    sb.writeln("");

    if (proj.engineType == 0) {
      final nn = state.nn!;
      sb.writeln(
        "// --- 🧠 Trained Parameters (Stored in Flash memory to save RAM) ---",
      );
      for (int i = 0; i < nn.weights.length; i++) {
        int inSize = nn.layerSizes[i];
        int outSize = nn.layerSizes[i + 1];
        sb.writeln(
          "// Layer $i -> ${i + 1} (Input: $inSize, Output: $outSize)",
        );
        sb.writeln(
          "const float weights_layer${i}[${inSize}][${outSize}] = ${toBareMetalArray(nn.weights[i])};",
        );
        sb.writeln(
          "const float biases_layer${i}[${outSize}] = ${toBareMetalArray(nn.biases[i])};",
        );
        sb.writeln("");
      }
    }

    sb.writeln("// --- 🚀 Core Inference Engine ---");
    if (proj.mode == 1) {
      sb.writeln("// [! ADVANCED MODE: Text Generation !]");
      sb.writeln(
        "// Note: Dynamic string handling is intentionally avoided in this mode.",
      );
      sb.writeln(
        "// You must implement your own character ring-buffer and window logic.",
      );
    }
    sb.writeln(
      "// input[$inNodes]: Raw normalized/one-hot encoded float array",
    );
    sb.writeln("// output[$outNodes]: Result array passed by reference");
    sb.writeln(
      "void predict(const float input[$inNodes], float output[$outNodes]) {",
    );

    if (proj.engineType == 0) {
      final nn = state.nn!;
      if (nn.weights.length > 1) {
        sb.writeln("    float buf_a[$maxNodes] = {0};");
        sb.writeln("    float buf_b[$maxNodes] = {0};");
        sb.writeln("    const float* current = input;");
        sb.writeln("    float* next = buf_a;");
      } else {
        sb.writeln("    const float* current = input;");
        sb.writeln("    float* next = output;");
      }
      sb.writeln("");

      for (int i = 0; i < nn.weights.length; i++) {
        int inSize = nn.layerSizes[i];
        int outSize = nn.layerSizes[i + 1];

        sb.writeln("    // --- Layer $i Computation ---");
        sb.writeln("    for (int j = 0; j < $outSize; j++) {");
        sb.writeln("        float total = biases_layer${i}[j];");
        sb.writeln("        for (int k = 0; k < $inSize; k++) {");
        sb.writeln(
          "            total += current[k] * weights_layer${i}[k][j];",
        );
        sb.writeln("        }");

        if (i < nn.weights.length - 1) {
          // If it's a hidden layer
          sb.writeln("        // Activation");
          // 💡 真の原因を修正： Enum の `.index` を使って正しく判定させる
          if (nn.hiddenActivation.index == 0) {
            // Sigmoid
            sb.writeln(
              "        next[j] = (total < -700.0f) ? 0.0f : 1.0f / (1.0f + exp(-total));",
            );
          } else if (nn.hiddenActivation.index == 1) {
            // ReLU
            sb.writeln(
              "        next[j] = (total > 0.0f) ? total : 0.01f * total;",
            );
          } else if (nn.hiddenActivation.index == 2) {
            // Tanh
            sb.writeln("        next[j] = tanh(total);");
          } else {
            sb.writeln("        next[j] = total;"); // フォールバック（安全対策）
          }
        } else {
          // Output layer (no activation yet)
          sb.writeln("        next[j] = total;");
        }
        sb.writeln("    }");

        // Buffer switching logic
        if (i < nn.weights.length - 1) {
          if (nn.weights.length > 1) {
            if (i == nn.weights.length - 2) {
              sb.writeln("    current = next;");
              sb.writeln("    next = output;");
            } else {
              sb.writeln("    current = next;");
              sb.writeln("    next = (next == buf_a) ? buf_b : buf_a;");
            }
          }
        }
        sb.writeln("");
      }

      sb.writeln("    // --- Output Activation ---");
      if (nn.lossType == 1) {
        // Softmax
        sb.writeln("    float max_val = output[0];");
        sb.writeln("    for (int i = 1; i < $outNodes; i++) {");
        sb.writeln("        if (output[i] > max_val) max_val = output[i];");
        sb.writeln("    }");
        sb.writeln("    float sum_exp = 0.0f;");
        sb.writeln("    for (int i = 0; i < $outNodes; i++) {");
        sb.writeln("        output[i] = exp(output[i] - max_val);");
        sb.writeln("        sum_exp += output[i];");
        sb.writeln("    }");
        sb.writeln("    for (int i = 0; i < $outNodes; i++) {");
        sb.writeln("        output[i] /= sum_exp;");
        sb.writeln("    }");
      } else {
        // Sigmoid
        sb.writeln("    for (int i = 0; i < $outNodes; i++) {");
        sb.writeln(
          "        output[i] = (output[i] < -700.0f) ? 0.0f : 1.0f / (1.0f + exp(-output[i]));",
        );
        sb.writeln("    }");
      }
    } else {
      final rf = state.rf!;
      sb.writeln("    for(int i=0; i<$outNodes; i++) output[i] = 0.0f;");
      for (int i = 0; i < rf.trees.length; i++) {
        sb.writeln("    // Tree $i");
        _genTreeLogic(sb, rf.trees[i].root, 1, 'cpp_baremetal', outNodes);
      }
      sb.writeln(
        "    for(int i=0; i<$outNodes; i++) output[i] /= ${rf.trees.length}.0f;",
      );
    }
    sb.writeln("}");
    sb.writeln("");

    // === 👇 Arduino Uno Execution Block 👇 ===
    sb.writeln(
      "// ======================================================================",
    );
    sb.writeln("// [Execution Block for Arduino / Wokwi Emulator]");
    sb.writeln("// Paste into Wokwi (Arduino Uno) to test immediately.");
    sb.writeln(
      "// ======================================================================",
    );
    sb.writeln("#if defined(ARDUINO)");
    sb.writeln("void setup() {");
    sb.writeln("    Serial.begin(115200);");
    sb.writeln("    Serial.println(\"--- Hakoniwa AI Bare-Metal Test ---\");");
    sb.writeln("");

    if (proj.mode == 0) {
      List<String> floatVals = [];
      List<String> displayVals = [];
      List<String> comments = [];

      for (int i = 0; i < proj.inputDefs.length; i++) {
        // ★書き換え
        if (state.inputMask.isNotEmpty && !state.inputMask[i]) continue; // ★追加
        var d = proj.inputDefs[i];
        if (d.type == 1 && d.categories.isNotEmpty) {
          displayVals.add('\\"${d.categories.first}\\"');
          comments.add(
            "    // Input '${d.name}' (Category: ${d.categories.first}) -> One-hot encoded",
          );
          for (int c = 0; c < d.categories.length; c++) {
            floatVals.add(c == 0 ? "1.0f" : "0.0f");
          }
        } else {
          double midVal = (d.min + d.max) / 2.0;
          double normalized = 0.0;
          if (d.max != d.min) {
            normalized = (midVal - d.min) / (d.max - d.min);
          }

          displayVals.add('\\"${midVal.toStringAsFixed(1)}\\"');
          floatVals.add("${normalized}f");
          comments.add(
            "    // Input '${d.name}' (Value: ${midVal.toStringAsFixed(1)}, Min: ${d.min}, Max: ${d.max}) -> Normalized to ${normalized}f",
          );
        }
      }

      sb.writeln(
        "    // Manual Data Preparation for {${displayVals.join(', ')}}",
      );
      for (String comment in comments) {
        sb.writeln(comment);
      }
      sb.writeln("    float test_input[$inNodes] = {${floatVals.join(', ')}};");
      sb.writeln("    float result_output[$outNodes] = {0};");
      sb.writeln("");
      sb.writeln("    unsigned long start_time = micros();");
      sb.writeln("    predict(test_input, result_output);");
      sb.writeln("    unsigned long end_time = micros();");
      sb.writeln("");
      sb.writeln("    Serial.println(\"Predictions:\");");

      int outIdx = 0;
      for (var d in proj.outputDefs) {
        if (d.type == 1) {
          for (int c = 0; c < d.categories.length; c++) {
            String catName = d.categories[c];
            sb.writeln("    Serial.print(\"  ${d.name} '${catName}': \");");
            sb.writeln("    Serial.print(result_output[${outIdx + c}] * 100);");
            sb.writeln("    Serial.println(\" %\");");
          }
          outIdx += d.categories.length;
        } else {
          sb.writeln("    Serial.print(\"  ${d.name} (Value): \");");
          sb.writeln(
            "    Serial.println(result_output[$outIdx] * (${d.max}f - ${d.min}f) + ${d.min}f);",
          );
          outIdx += 1;
        }
      }
      sb.writeln("");
      sb.writeln("    Serial.print(\"Inference Time: \");");
      sb.writeln("    Serial.print(end_time - start_time);");
      sb.writeln("    Serial.println(\" microseconds\");");
    } else {
      sb.writeln("    // Dummy input for Text Generation model testing");
      sb.writeln("    float test_input[$inNodes] = {0};");
      sb.writeln("    float result_output[$outNodes] = {0};");
      sb.writeln("");
      sb.writeln("    unsigned long start_time = micros();");
      sb.writeln("    predict(test_input, result_output);");
      sb.writeln("    unsigned long end_time = micros();");
      sb.writeln("");
      sb.writeln(
        "    Serial.println(\"Text generation 1-step test complete.\");",
      );
      sb.writeln("    Serial.print(\"Inference Time: \");");
      sb.writeln("    Serial.print(end_time - start_time);");
      sb.writeln("    Serial.println(\" microseconds\");");
    }
    sb.writeln("}");
    sb.writeln("void loop() {}");
    sb.writeln("#endif");

    return sb.toString();
  }

  // ＝＝＝ 👨‍💻 Rustコード生成ロジック（WASM / バックエンドエンジニア向け） ＝＝＝
  static String buildRustCode(ProjectState state) {
    final proj = state.proj;
    final sb = StringBuffer();

    // Dartの配列文字列 "[1, 2]" を Rustの配列マクロ "vec![1, 2]" に変換
    String toRustVec(dynamic list) {
      return list.toString().replaceAll('[', 'vec![').replaceAll(']', ']');
    }

    sb.writeln("/*");
    sb.writeln(" * Auto-generated Hakoniwa AI Inference Model (Pure Rust)");
    sb.writeln(
      " * Engine: ${proj.engineType == 1 ? 'Random Forest' : 'Neural Network'}",
    );
    sb.writeln(" * ");
    sb.writeln(
      " * DISCLAIMER: This auto-generated code is for educational and experimental purposes.",
    );
    sb.writeln(
      " * It is provided \"AS IS\" without warranty of any kind. The author shall not be liable",
    );
    sb.writeln(
      " * for any claim, damages or other liability arising from the use of this code.",
    );
    sb.writeln(" * ");
    sb.writeln(" * Project: ${proj.name}");
    sb.writeln(
      " * Note: Zero external dependencies. Works out of the box with `cargo run`.",
    );
    sb.writeln(
      " * Suitable for WebAssembly (WASM) or high-performance backend microservices.",
    );
    sb.writeln(" */");
    sb.writeln("");
    sb.writeln("use std::f64::consts::E;");
    sb.writeln("use std::cmp::Ordering;");
    sb.writeln("");

    if (proj.mode == 0) {
      sb.writeln("pub struct FeatureDef {");
      sb.writeln("    pub name: String,");
      sb.writeln("    pub feature_type: i32, // 0: Numeric, 1: Category");
      sb.writeln("    pub min_val: f64,");
      sb.writeln("    pub max_val: f64,");
      sb.writeln("    pub cat_len: usize,");
      sb.writeln("    pub categories: Vec<String>,");
      sb.writeln("}");
      sb.writeln("");
    }

    // ＝＝＝ 👇 構造体定義 👇 ＝＝＝
    sb.writeln("pub struct HakoniwaModel {");
    if (proj.engineType == 0) {
      final nn = state.nn!;
      sb.writeln("    layer_sizes: Vec<usize>,");
      sb.writeln("    hidden_activation: i32, // 0:Sigmoid, 1:ReLU, 2:Tanh");
      sb.writeln(
        "    loss_type: i32, // 0:MSE(Sigmoid), 1:CrossEntropy(Softmax)",
      );
      sb.writeln("    weights: Vec<Vec<Vec<f64>>>,");
      sb.writeln("    biases: Vec<Vec<f64>>,");
    }
    if (proj.mode == 1) {
      sb.writeln("    n_gram_count: usize,");
      sb.writeln("    vocab: Vec<String>,");
    } else {
      sb.writeln("    input_defs: Vec<FeatureDef>,");
      sb.writeln("    output_defs: Vec<FeatureDef>,");
    }
    sb.writeln("}");
    sb.writeln("");

    sb.writeln("impl HakoniwaModel {");
    sb.writeln("    pub fn new() -> Self {");
    sb.writeln("        Self {");
    if (proj.engineType == 0) {
      final nn = state.nn!;
      sb.writeln("            layer_sizes: ${toRustVec(nn.layerSizes)},");
      sb.writeln(
        "            hidden_activation: ${nn.hiddenActivation.index},",
      );
      sb.writeln("            loss_type: ${nn.lossType},");
      sb.writeln("            weights: ${toRustVec(nn.weights)},");
      sb.writeln("            biases: ${toRustVec(nn.biases)},");
    }

    if (proj.mode == 1) {
      sb.writeln("            n_gram_count: ${proj.nGramCount},");
      String rustVocab =
          "vec![" +
          proj.currentChars
              .split('')
              .map((e) => '${jsonEncode(e)}.to_string()')
              .join(', ') +
          "]";
      sb.writeln("            vocab: $rustVocab,");
    } else {
      sb.writeln("            input_defs: vec![");
      for (int i = 0; i < proj.inputDefs.length; i++) {
        // ★書き換え
        if (state.inputMask.isNotEmpty && !state.inputMask[i]) continue; // ★追加
        var d = proj.inputDefs[i];
        String cats =
            "vec![" +
            d.categories.map((c) => '${jsonEncode(c)}.to_string()').join(', ') +
            "]";
        sb.writeln(
          "                FeatureDef { name: ${jsonEncode(d.name)}.to_string(), feature_type: ${d.type}, min_val: ${d.min}_f64, max_val: ${d.max}_f64, cat_len: ${d.categories.length}, categories: $cats },",
        );
      }
      sb.writeln("            ],");
      sb.writeln("            output_defs: vec![");
      for (var d in proj.outputDefs) {
        String cats =
            "vec![" +
            d.categories.map((c) => '${jsonEncode(c)}.to_string()').join(', ') +
            "]";
        sb.writeln(
          "                FeatureDef { name: ${jsonEncode(d.name)}.to_string(), feature_type: ${d.type}, min_val: ${d.min}_f64, max_val: ${d.max}_f64, cat_len: ${d.categories.length}, categories: $cats },",
        );
      }
      sb.writeln("            ],");
    }
    sb.writeln("        }");
    sb.writeln("    }");
    sb.writeln("");

    if (proj.engineType == 0) {
      sb.writeln(r"""    fn predict_raw(&self, input_data: &[f64]) -> Vec<f64> {
        let mut current = input_data.to_vec();
        
        for i in 0..self.weights.len() {
            let mut next_layer = vec![0.0; self.layer_sizes[i + 1]];
            for j in 0..self.layer_sizes[i + 1] {
                let mut total = self.biases[i][j];
                for k in 0..self.layer_sizes[i] {
                    total += current[k] * self.weights[i][k][j];
                }
                
                if i < self.weights.len() - 1 {
                    if self.hidden_activation == 0 { // Sigmoid
                        next_layer[j] = if total < -700.0 { 0.0 } else { 1.0 / (1.0 + E.powf(-total)) };
                    } else if self.hidden_activation == 1 { // ReLU
                        next_layer[j] = if total > 0.0 { total } else { 0.01 * total };
                    } else if self.hidden_activation == 2 { // Tanh
                        next_layer[j] = total.tanh();
                    }
                } else {
                    next_layer[j] = total;
                }
            }
            current = next_layer;
        }
        
        if self.loss_type == 1 { // Softmax
            let max_val = current.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
            let mut sum_exp = 0.0;
            for val in &mut current {
                *val = E.powf(*val - max_val);
                sum_exp += *val;
            }
            for val in &mut current {
                *val /= sum_exp;
            }
        } else { // Sigmoid
            for val in &mut current {
                *val = if *val < -700.0 { 0.0 } else { 1.0 / (1.0 + E.powf(-*val)) };
            }
        }
        
        current
    }
""");
    } else {
      final rf = state.rf!;
      int outSize = rf.outputSize;
      sb.writeln("    fn predict_raw(&self, input_data: &[f64]) -> Vec<f64> {");
      sb.writeln("        let mut out_buf = vec![0.0; $outSize];");
      for (int i = 0; i < rf.trees.length; i++) {
        sb.writeln("        // Tree $i");
        _genTreeLogic(sb, rf.trees[i].root, 2, 'rust', outSize);
      }
      sb.writeln(
        "        for i in 0..$outSize { out_buf[i] /= ${rf.trees.length}.0; }",
      );
      sb.writeln("        out_buf");
      sb.writeln("    }");
    }

    if (proj.mode == 1) {
      sb.writeln(
        r"""    pub fn predict_next_char(&self, context_text: &str) -> Vec<(String, f64)> {
        // Rust natively handles UTF-8 chars beautifully
        let chars: Vec<char> = context_text.chars().collect();
        if chars.len() < self.n_gram_count {
            return vec![];
        }
        
        let ctx = &chars[chars.len() - self.n_gram_count..];
        let mut input_data = vec![];
        
        for &ch in ctx {
            let ch_str = ch.to_string();
            let idx = self.vocab.iter().position(|v| v == &ch_str).unwrap_or(usize::MAX);
            for v in 0..self.vocab.len() {
                input_data.push(if v == idx { 1.0 } else { 0.0 });
            }
        }
        
        let raw_pred = self.predict_raw(&input_data);
        
        let mut probs: Vec<(String, f64)> = self.vocab.iter().zip(raw_pred.iter())
            .map(|(k, v)| (k.clone(), *v))
            .collect();
            
        probs.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(Ordering::Equal));
        probs
    }
""",
      );
    } else {
      sb.writeln(r"""    // Returns a JSON-formatted String directly
    pub fn predict(&self, raw_inputs: &[&str]) -> String {
        if raw_inputs.len() != self.input_defs.len() {
            return r#"{"error": "Input size mismatch"}"#.to_string();
        }
        
        let mut encoded_inputs = vec![];
        
        for (i, def) in self.input_defs.iter().enumerate() {
            let val = raw_inputs[i];
            if def.feature_type == 1 { // Category
                let mut idx = def.categories.iter().position(|c| c == val).unwrap_or(usize::MAX);
                if idx == usize::MAX {
                    idx = val.parse::<usize>().unwrap_or(0);
                }
                if idx >= def.cat_len { idx = 0; } // Fallback
                
                for c in 0..def.cat_len {
                    encoded_inputs.push(if c == idx { 1.0 } else { 0.0 });
                }
            } else { // Numeric
                let val_f: f64 = val.parse().unwrap_or(0.0);
                if def.max_val == def.min_val {
                    encoded_inputs.push(0.0);
                } else {
                    let clamped = ((val_f - def.min_val) / (def.max_val - def.min_val)).clamp(0.0, 1.0);
                    encoded_inputs.push(clamped);
                }
            }
        }
        
        let raw_out = self.predict_raw(&encoded_inputs);
        
        let mut json = String::from("[\n");
        let mut out_idx = 0;
        
        for (i, def) in self.output_defs.iter().enumerate() {
            json.push_str("  {\n");
            json.push_str(&format!("    \"name\": \"{}\",\n", def.name));
            
            if def.feature_type == 1 { // Classification
                let cat_len = def.cat_len;
                let probs = &raw_out[out_idx..out_idx + cat_len];
                
                let mut max_prob = -1.0;
                let mut best_idx = 0;
                for c in 0..cat_len {
                    if probs[c] > max_prob {
                        max_prob = probs[c];
                        best_idx = c;
                    }
                }
                
                let best_class = if def.categories.is_empty() { best_idx.to_string() } else { def.categories[best_idx].clone() };
                
                json.push_str(&format!("    \"prediction\": \"{}\",\n", best_class));
                json.push_str(&format!("    \"confidence\": {:.6},\n", max_prob));
                json.push_str("    \"probabilities\": {\n");
                
                for c in 0..cat_len {
                    let c_name = if def.categories.is_empty() { c.to_string() } else { def.categories[c].clone() };
                    let comma = if c < cat_len - 1 { "," } else { "" };
                    json.push_str(&format!("      \"{}\": {:.6}{}\n", c_name, probs[c], comma));
                }
                json.push_str("    }\n");
                out_idx += cat_len;
            } else { // Regression
                let pred_val = raw_out[out_idx] * (def.max_val - def.min_val) + def.min_val;
                json.push_str(&format!("    \"prediction\": {:.6}\n", pred_val));
                out_idx += 1;
            }
            
            let block_comma = if i < self.output_defs.len() - 1 { "," } else { "" };
            json.push_str(&format!("  }}{}\n", block_comma));
        }
        
        json.push(']');
        json
    }
""");
    }
    sb.writeln("}");
    sb.writeln("");

    // ＝＝＝ 👇 Rust版 実行ブロック 👇 ＝＝＝
    sb.writeln(
      "// ======================================================================",
    );
    sb.writeln("// [Execution Block]");
    sb.writeln(
      "// You can run this file directly using `cargo run` if you set up a new project.",
    );
    sb.writeln(
      "// ======================================================================",
    );
    sb.writeln("fn main() {");
    sb.writeln("    println!(\"--- Hakoniwa AI Model Test (Rust) ---\");");
    sb.writeln("    let ai = HakoniwaModel::new();");
    sb.writeln("");

    if (proj.mode == 0) {
      List<String> exampleInputs = [];
      for (int i = 0; i < proj.inputDefs.length; i++) {
        // ★書き換え
        if (state.inputMask.isNotEmpty && !state.inputMask[i]) continue; // ★追加
        var d = proj.inputDefs[i];
        if (d.type == 1 && d.categories.isNotEmpty) {
          exampleInputs.add(jsonEncode(d.categories[0]));
        } else if (d.type == 1) {
          exampleInputs.add('"0"');
        } else {
          double midVal = (d.min + d.max) / 2.0;
          exampleInputs.add(jsonEncode(midVal.toStringAsFixed(1)));
        }
      }
      sb.writeln("    let raw_inputs = vec![${exampleInputs.join(', ')}];");
      sb.writeln("    let result_json = ai.predict(&raw_inputs);");
      sb.writeln("    ");
      sb.writeln("    println!(\"Input values: {:?}\", raw_inputs);");
      sb.writeln("    println!(\"{}\", result_json);");
    } else {
      // 📝 テキスト生成モード（アルファベット・ひらがな両対応 ＆ ゆらぎ対応）
      bool isJapanese = RegExp(r'[ぁ-んァ-ン一-龥]').hasMatch(proj.currentChars);
      String sampleText = isJapanese ? 'むかしむかし' : 'Once';

      sb.writeln("    let mut text = String::from(${jsonEncode(sampleText)});");
      sb.writeln(
        "    let temperature = 0.5; // Set to 0.0 for greedy, >0.0 for creative",
      );
      sb.writeln(
        "    println!(\"Initial text: {}\\nGenerating next 50 characters (Temperature: {})...\\n\", text, temperature);",
      );
      sb.writeln("    ");
      // 💡 追加: 外部クレート不要の自作軽量擬似乱数ジェネレーター（LCG）
      sb.writeln(
        "    // Simple PRNG state for demo purposes (No external crates required)",
      );
      sb.writeln(
        "    let mut seed = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap().subsec_nanos() as u64;",
      );
      sb.writeln("    ");
      sb.writeln("    for _ in 0..50 {");
      sb.writeln("        let probs = ai.predict_next_char(&text);");
      sb.writeln("        if probs.is_empty() { break; }");
      sb.writeln("        ");
      sb.writeln("        let mut next_char = probs[0].0.clone();");
      // 💡 追加: 温度パラメータによるサンプリング処理
      sb.writeln("        if temperature > 0.05 {");
      sb.writeln("            let mut weights = vec![];");
      sb.writeln("            let mut weight_sum = 0.0;");
      sb.writeln("            for p in &probs {");
      sb.writeln(
        "                let prob = if p.1 <= 0.0 { 1e-7 } else { p.1 };",
      );
      sb.writeln("                let w = prob.powf(1.0 / temperature);");
      sb.writeln("                weights.push(w);");
      sb.writeln("                weight_sum += w;");
      sb.writeln("            }");
      sb.writeln(
        "            seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1);",
      );
      sb.writeln(
        "            let r_float = (seed >> 11) as f64 / (1u64 << 53) as f64;",
      );
      sb.writeln("            let mut r = r_float * weight_sum;");
      sb.writeln("            for (j, w) in weights.iter().enumerate() {");
      sb.writeln("                r -= *w;");
      sb.writeln("                if r <= 0.0 {");
      sb.writeln("                    next_char = probs[j].0.clone();");
      sb.writeln("                    break;");
      sb.writeln("                }");
      sb.writeln("            }");
      sb.writeln("        }");
      sb.writeln("        text.push_str(&next_char);");
      sb.writeln("    }");
      sb.writeln("    ");
      sb.writeln("    println!(\"Result:\\n{}\", text);");
    }

    sb.writeln("}");

    return sb.toString();
  }
}
