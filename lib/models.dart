import 'dart:convert'; // ★追加: レシピの安全な保存に使用
import 'package:hive/hive.dart';
import 'share_manager.dart';

// ★★★ 追加：アプリ全体で使う辞書のマスターデータ ★★★
const String hiraganaChars =
    "あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをんぁぃぅぇぉっゃゅょがぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽー、。！？ \n";

// 英語版の辞書（アルファベット、数字、記号、改行）
const String englishChars =
    " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!?'\"-\n";

// ★★★ 追加：カスタム特徴量のレシピクラス ★★★
class CustomFeatureRecipe {
  String name;
  List<String> tokens;

  CustomFeatureRecipe(this.name, this.tokens);

  CustomFeatureRecipe clone() => CustomFeatureRecipe(name, List.from(tokens));

  Map<String, dynamic> toJson() => {'name': name, 'tokens': tokens};

  factory CustomFeatureRecipe.fromJson(Map<String, dynamic> json) =>
      CustomFeatureRecipe(
        json['name'],
        List<String>.from(json['tokens'] ?? []),
      );
}

class FeatureDef {
  String name;
  int type;
  double min;
  double max;
  List<String> categories;

  int missingStrategy;
  double? fallbackNumeric;
  String? fallbackCategory;

  FeatureDef({
    required this.name,
    required this.type,
    this.min = 0,
    this.max = 100,
    this.categories = const [],
    this.missingStrategy = 0,
    this.fallbackNumeric,
    this.fallbackCategory,
  });

  FeatureDef clone() => FeatureDef(
    name: name,
    type: type,
    min: min,
    max: max,
    categories: List.from(categories),
    missingStrategy: missingStrategy,
    fallbackNumeric: fallbackNumeric,
    fallbackCategory: fallbackCategory,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'min': min,
    'max': max,
    'categories': categories,
    'missingStrategy': missingStrategy,
    'fallbackNumeric': fallbackNumeric,
    'fallbackCategory': fallbackCategory,
  };

  factory FeatureDef.fromJson(Map<String, dynamic> json) => FeatureDef(
    name: json['name'],
    type: json['type'],
    min: (json['min'] as num).toDouble(),
    max: (json['max'] as num).toDouble(),
    categories: List<String>.from(json['categories'] ?? []),
    missingStrategy: json['missingStrategy'] ?? 0,
    fallbackNumeric: json['fallbackNumeric'] != null
        ? (json['fallbackNumeric'] as num).toDouble()
        : null,
    fallbackCategory: json['fallbackCategory'],
  );
}

class TrainingData {
  List<double> inputs;
  List<double> outputs;
  TrainingData({required this.inputs, required this.outputs});
  TrainingData clone() =>
      TrainingData(inputs: List.from(inputs), outputs: List.from(outputs));
  Map<String, dynamic> toJson() => {'inputs': inputs, 'outputs': outputs};
  factory TrainingData.fromJson(Map<String, dynamic> json) => TrainingData(
    inputs: List<double>.from(json['inputs'].map((x) => (x as num).toDouble())),
    outputs: List<double>.from(
      json['outputs'].map((x) => (x as num).toDouble()),
    ),
  );
}

class NeuralProject {
  String id;
  String name;
  List<FeatureDef> inputDefs;
  List<FeatureDef> outputDefs;
  List<TrainingData> data;

  int hiddenLayers;
  int hiddenNodes;
  int optimizer;
  int batchSize;
  String? trainedModelJson;
  int mode;
  int ecoWaitMs;
  double learningRate;
  bool isRandomSplit;
  int lossType;
  List<int> hiddenNodesList;

  int nGramCount;
  String? rawText;
  String appVersion;

  int langMode;

  int engineType;
  double dropoutRate;
  double l2Rate;
  int rf_trees;
  int rf_depth;
  List<double>? feature_importances;

  int latentDim;
  double klWeight;

  // ★追加：カスタム特徴量のレシピリスト
  List<CustomFeatureRecipe> customRecipes;

  String get currentChars => langMode == 1 ? englishChars : hiraganaChars;

  NeuralProject({
    required this.id,
    required this.name,
    required this.inputDefs,
    required this.outputDefs,
    required this.data,
    this.hiddenLayers = 1,
    this.hiddenNodes = 12,
    this.optimizer = 2,
    this.batchSize = 8,
    this.trainedModelJson,
    this.mode = 0,
    this.ecoWaitMs = 50,
    this.learningRate = 0.01,
    this.isRandomSplit = true,
    this.lossType = 0,
    List<int>? hiddenNodesList,
    this.nGramCount = 3,
    this.rawText,
    this.appVersion = ShareManager.currentAppVersion,
    this.langMode = 0,
    this.engineType = 0,
    this.dropoutRate = 0.0,
    this.l2Rate = 0.0,
    this.rf_trees = 5,
    this.rf_depth = 3,
    this.feature_importances,
    this.latentDim = 4,
    this.klWeight = 1.0,
    List<CustomFeatureRecipe>? customRecipes, // ★追加
  }) : hiddenNodesList =
           hiddenNodesList ??
           List.filled(hiddenLayers, hiddenNodes, growable: true),
       customRecipes = customRecipes ?? []; // ★追加

  NeuralProject clone({required String newId, required String newName}) {
    return NeuralProject(
      id: newId,
      name: newName,
      inputDefs: inputDefs.map((e) => e.clone()).toList(),
      outputDefs: outputDefs.map((e) => e.clone()).toList(),
      data: data.map((e) => e.clone()).toList(),
      hiddenLayers: hiddenLayers,
      hiddenNodes: hiddenNodes,
      optimizer: optimizer,
      batchSize: batchSize,
      trainedModelJson: trainedModelJson,
      mode: mode,
      ecoWaitMs: ecoWaitMs,
      learningRate: learningRate,
      isRandomSplit: isRandomSplit,
      lossType: lossType,
      hiddenNodesList: List.from(hiddenNodesList),
      nGramCount: nGramCount,
      rawText: rawText,
      appVersion: appVersion,
      langMode: langMode,
      engineType: engineType,
      dropoutRate: dropoutRate,
      l2Rate: l2Rate,
      rf_trees: rf_trees,
      rf_depth: rf_depth,
      feature_importances: feature_importances != null
          ? List.from(feature_importances!)
          : null,
      latentDim: latentDim,
      klWeight: klWeight,
      customRecipes: customRecipes.map((e) => e.clone()).toList(), // ★追加
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'inputDefs': inputDefs.map((e) => e.toJson()).toList(),
    'outputDefs': outputDefs.map((e) => e.toJson()).toList(),
    'data': mode == 1 ? [] : data.map((e) => e.toJson()).toList(),
    'hiddenLayers': hiddenLayers,
    'hiddenNodes': hiddenNodes,
    'optimizer': optimizer,
    'batchSize': batchSize,
    'trainedModelJson': trainedModelJson,
    'mode': mode,
    'ecoWaitMs': ecoWaitMs,
    'learningRate': learningRate,
    'isRandomSplit': isRandomSplit,
    'lossType': lossType,
    'hiddenNodesList': hiddenNodesList,
    'nGramCount': nGramCount,
    'rawText': rawText,
    'appVersion': appVersion,
    'langMode': langMode,
    'engineType': engineType,
    'dropoutRate': dropoutRate,
    'l2Rate': l2Rate,
    'rf_trees': rf_trees,
    'rf_depth': rf_depth,
    'feature_importances': feature_importances,
    'latentDim': latentDim,
    'klWeight': klWeight,
    'customRecipes': customRecipes.map((e) => e.toJson()).toList(), // ★追加
  };

  factory NeuralProject.fromJson(Map<String, dynamic> json) {
    int loadedMode = json['mode'] ?? 0;
    List<TrainingData> loadedData = [];
    String? loadedRawText = json['rawText'];
    int loadedNGramCount = json['nGramCount'] ?? 3;

    int loadedLangMode = json['langMode'] ?? 0;
    String targetChars = loadedLangMode == 1 ? englishChars : hiraganaChars;

    if (json['data'] != null) {
      loadedData = List<TrainingData>.from(
        json['data'].map((x) => TrainingData.fromJson(x)),
      );
    }

    if (loadedMode == 1) {
      if ((loadedRawText == null || loadedRawText.trim().isEmpty) &&
          loadedData.isNotEmpty) {
        StringBuffer sb = StringBuffer();
        for (var d in loadedData) {
          if (d.inputs.isEmpty) continue;
          int idx = d.inputs[0].toInt();
          if (idx >= 0 && idx < targetChars.length) sb.write(targetChars[idx]);
        }
        var last = loadedData.last;
        if (last.inputs.length > 1) {
          for (int i = 1; i < last.inputs.length; i++) {
            int idx = last.inputs[i].toInt();
            if (idx >= 0 && idx < targetChars.length)
              sb.write(targetChars[idx]);
          }
        }
        if (last.outputs.isNotEmpty) {
          int outIdx = last.outputs[0].toInt();
          if (outIdx >= 0 && outIdx < targetChars.length)
            sb.write(targetChars[outIdx]);
        }
        loadedRawText = sb.toString();
      }

      if (loadedRawText != null && loadedRawText.trim().isNotEmpty) {
        loadedData.clear();
        String cleanText = loadedRawText;
        int n = loadedNGramCount;

        if (cleanText.length > n) {
          for (int i = 0; i < cleanText.length - n; i++) {
            List<double> inVals = [];
            for (int j = 0; j < n; j++) {
              double idx = targetChars.indexOf(cleanText[i + j]).toDouble();
              inVals.add(idx == -1.0 ? 0.0 : idx);
            }
            double outVal = targetChars.indexOf(cleanText[i + n]).toDouble();
            outVal = outVal == -1.0 ? 0.0 : outVal;
            loadedData.add(TrainingData(inputs: inVals, outputs: [outVal]));
          }
        }
      }
    }

    return NeuralProject(
      id: json['id'],
      name: json['name'],
      inputDefs: List<FeatureDef>.from(
        json['inputDefs'].map((x) => FeatureDef.fromJson(x)),
      ),
      outputDefs: List<FeatureDef>.from(
        json['outputDefs'].map((x) => FeatureDef.fromJson(x)),
      ),
      data: loadedData,
      hiddenLayers: json['hiddenLayers'] ?? 1,
      hiddenNodes: json['hiddenNodes'] ?? 12,
      optimizer: json['optimizer'] ?? 2,
      batchSize: json['batchSize'] ?? 8,
      trainedModelJson: json['trainedModelJson'],
      mode: loadedMode,
      ecoWaitMs: json['ecoWaitMs'] ?? 50,
      learningRate: json['learningRate']?.toDouble() ?? 0.01,
      isRandomSplit: json['isRandomSplit'] ?? true,
      lossType: json['lossType'] ?? 0,
      hiddenNodesList: json['hiddenNodesList'] != null
          ? List<int>.from(json['hiddenNodesList'])
          : null,
      nGramCount: loadedNGramCount,
      rawText: loadedRawText,
      appVersion: json['appVersion'] ?? "1.1.0",
      langMode: loadedLangMode,
      engineType: json['engineType'] ?? 0,
      dropoutRate: json['dropoutRate']?.toDouble() ?? 0.0,
      l2Rate: json['l2Rate']?.toDouble() ?? 0.0,
      rf_trees: json['rf_trees'] ?? 5,
      rf_depth: json['rf_depth'] ?? 3,
      feature_importances: json['feature_importances'] != null
          ? List<double>.from(
              json['feature_importances'].map((x) => (x as num).toDouble()),
            )
          : null,
      latentDim: json['latentDim'] ?? 4,
      klWeight: json['klWeight']?.toDouble() ?? 1.0,
      // ★追加：JSONからの復元
      customRecipes: json['customRecipes'] != null
          ? List<CustomFeatureRecipe>.from(
              json['customRecipes'].map((x) => CustomFeatureRecipe.fromJson(x)),
            )
          : [],
    );
  }
}

class ChatCharacter {
  String projectId;
  String characterName;
  int colorValue;
  double temperature;
  int frequency;
  int maxLength;

  ChatCharacter({
    required this.projectId,
    required this.characterName,
    required this.colorValue,
    this.temperature = 1.0,
    this.frequency = 3,
    this.maxLength = 30,
  });
}

// --- Hiveアダプター ---

// ★修正点1: FeatureDefのバイナリ構造は「絶対に」元の5項目から変えない（ポインタのズレ防止）
class FeatureDefAdapter extends TypeAdapter<FeatureDef> {
  @override
  final int typeId = 2;

  @override
  FeatureDef read(BinaryReader reader) {
    return FeatureDef(
      name: reader.readString(),
      type: reader.readInt(),
      min: reader.readDouble(),
      max: reader.readDouble(),
      categories: reader.readList().cast<String>(),
      // 新規フィールドはここでは読まず、デフォルト値のままにしておく
    );
  }

  @override
  void write(BinaryWriter writer, FeatureDef obj) {
    writer.writeString(obj.name);
    writer.writeInt(obj.type);
    writer.writeDouble(obj.min);
    writer.writeDouble(obj.max);
    writer.writeList(obj.categories);
    // 新規フィールドはここでは書き込まない
  }
}

class TrainingDataAdapter extends TypeAdapter<TrainingData> {
  @override
  final int typeId = 1;
  @override
  TrainingData read(BinaryReader reader) => TrainingData(
    inputs: reader.readList().cast<double>(),
    outputs: reader.readList().cast<double>(),
  );
  @override
  void write(BinaryWriter writer, TrainingData obj) {
    writer.writeList(obj.inputs);
    writer.writeList(obj.outputs);
  }
}

class NeuralProjectAdapter extends TypeAdapter<NeuralProject> {
  @override
  final int typeId = 0;
  @override
  NeuralProject read(BinaryReader reader) {
    String id = reader.readString();
    String name = reader.readString();
    List<FeatureDef> inputDefs = reader.readList().cast<FeatureDef>();
    List<FeatureDef> outputDefs = reader.readList().cast<FeatureDef>();
    List<TrainingData> data = reader.readList().cast<TrainingData>();
    int hiddenLayers = reader.readInt();
    int hiddenNodes = reader.readInt();
    int optimizer = 0;
    int batchSize = 8;
    String? trainedModelJson;
    int mode = 0;
    int ecoWaitMs = 50;
    double learningRate = 0.01;
    bool isRandomSplit = true;
    int lossType = 0;
    List<int> hiddenNodesList = [];
    int nGramCount = 3;
    String? rawText;
    String appVersion = "1.1.0";
    int langMode = 0;

    int engineType = 0;
    double dropoutRate = 0.0;
    double l2Rate = 0.0;
    int rf_trees = 5;
    int rf_depth = 3;
    List<double>? feature_importances;

    int latentDim = 4;
    double klWeight = 1.0;

    // 互換性維持読み込み
    try {
      optimizer = reader.readInt();
    } catch (e) {}
    try {
      batchSize = reader.readInt();
    } catch (e) {}
    try {
      String readStr = reader.readString();
      if (readStr.isNotEmpty) trainedModelJson = readStr;
    } catch (e) {}
    try {
      mode = reader.readInt();
    } catch (e) {}
    try {
      ecoWaitMs = reader.readInt();
    } catch (e) {}
    try {
      learningRate = reader.readDouble();
    } catch (e) {}
    try {
      isRandomSplit = reader.readBool();
    } catch (e) {}
    try {
      lossType = reader.readInt();
    } catch (e) {}
    try {
      hiddenNodesList = reader.readList().cast<int>();
    } catch (e) {}
    try {
      nGramCount = reader.readInt();
    } catch (e) {}
    try {
      String readStr = reader.readString();
      if (readStr.isNotEmpty) rawText = readStr;
    } catch (e) {}
    try {
      String readStr = reader.readString();
      if (readStr.isNotEmpty) appVersion = readStr;
    } catch (e) {}
    try {
      langMode = reader.readInt();
    } catch (e) {}
    try {
      engineType = reader.readInt();
    } catch (e) {}
    try {
      dropoutRate = reader.readDouble();
    } catch (e) {}
    try {
      l2Rate = reader.readDouble();
    } catch (e) {}
    try {
      rf_trees = reader.readInt();
    } catch (e) {}
    try {
      rf_depth = reader.readInt();
    } catch (e) {}
    try {
      feature_importances = reader.readList().cast<double>();
    } catch (e) {}
    try {
      latentDim = reader.readInt();
    } catch (e) {}
    try {
      klWeight = reader.readDouble();
    } catch (e) {}

    // ★修正点2: FeatureDefの拡張プロパティは、トップレベルから安全に読み取って注入する
    List<int>? inMiss, outMiss;
    List<double>? inFallN, outFallN;
    List<String>? inFallC, outFallC;

    try {
      inMiss = reader.readList().cast<int>();
    } catch (e) {}
    try {
      inFallN = reader.readList().cast<double>();
    } catch (e) {}
    try {
      inFallC = reader.readList().cast<String>();
    } catch (e) {}
    try {
      outMiss = reader.readList().cast<int>();
    } catch (e) {}
    try {
      outFallN = reader.readList().cast<double>();
    } catch (e) {}
    try {
      outFallC = reader.readList().cast<String>();
    } catch (e) {}

    if (inMiss != null && inMiss.length == inputDefs.length) {
      for (int i = 0; i < inputDefs.length; i++) {
        inputDefs[i].missingStrategy = inMiss[i];
        double fn = inFallN![i];
        inputDefs[i].fallbackNumeric = fn.isNaN ? null : fn;
        String fc = inFallC![i];
        inputDefs[i].fallbackCategory = fc.isEmpty ? null : fc;
      }
    }
    if (outMiss != null && outMiss.length == outputDefs.length) {
      for (int i = 0; i < outputDefs.length; i++) {
        outputDefs[i].missingStrategy = outMiss[i];
        double fn = outFallN![i];
        outputDefs[i].fallbackNumeric = fn.isNaN ? null : fn;
        String fc = outFallC![i];
        outputDefs[i].fallbackCategory = fc.isEmpty ? null : fc;
      }
    }

    // ★★★ 追加: カスタム特徴量レシピの安全な読み込み ★★★
    // JSON文字列のリストとして読み込み、デコードする。無い場合は空リスト。
    List<CustomFeatureRecipe> loadedRecipes = [];
    try {
      List<String> recipesJson = reader.readList().cast<String>();
      loadedRecipes = recipesJson
          .map((e) => CustomFeatureRecipe.fromJson(jsonDecode(e)))
          .toList();
    } catch (e) {}

    String targetChars = langMode == 1 ? englishChars : hiraganaChars;

    if (mode == 1) {
      if ((rawText == null || rawText.trim().isEmpty) && data.isNotEmpty) {
        StringBuffer sb = StringBuffer();
        for (var d in data) {
          if (d.inputs.isEmpty) continue;
          int idx = d.inputs[0].toInt();
          if (idx >= 0 && idx < targetChars.length) sb.write(targetChars[idx]);
        }
        var last = data.last;
        if (last.inputs.length > 1) {
          for (int i = 1; i < last.inputs.length; i++) {
            int idx = last.inputs[i].toInt();
            if (idx >= 0 && idx < targetChars.length)
              sb.write(targetChars[idx]);
          }
        }
        if (last.outputs.isNotEmpty) {
          int outIdx = last.outputs[0].toInt();
          if (outIdx >= 0 && outIdx < targetChars.length)
            sb.write(targetChars[outIdx]);
        }
        rawText = sb.toString();
      }

      if (rawText != null && rawText.trim().isNotEmpty) {
        data.clear();
        String cleanText = rawText;
        int n = nGramCount;

        if (cleanText.length > n) {
          for (int i = 0; i < cleanText.length - n; i++) {
            List<double> inVals = [];
            for (int j = 0; j < n; j++) {
              double idx = targetChars.indexOf(cleanText[i + j]).toDouble();
              inVals.add(idx == -1.0 ? 0.0 : idx);
            }
            double outVal = targetChars.indexOf(cleanText[i + n]).toDouble();
            outVal = outVal == -1.0 ? 0.0 : outVal;
            data.add(TrainingData(inputs: inVals, outputs: [outVal]));
          }
        }
      }
    }

    return NeuralProject(
      id: id,
      name: name,
      inputDefs: inputDefs,
      outputDefs: outputDefs,
      data: data,
      hiddenLayers: hiddenLayers,
      hiddenNodes: hiddenNodes,
      optimizer: optimizer,
      batchSize: batchSize,
      trainedModelJson: trainedModelJson,
      mode: mode,
      ecoWaitMs: ecoWaitMs,
      learningRate: learningRate,
      isRandomSplit: isRandomSplit,
      lossType: lossType,
      hiddenNodesList: hiddenNodesList.isNotEmpty ? hiddenNodesList : null,
      nGramCount: nGramCount,
      rawText: rawText,
      appVersion: appVersion,
      langMode: langMode,
      engineType: engineType,
      dropoutRate: dropoutRate,
      l2Rate: l2Rate,
      rf_trees: rf_trees,
      rf_depth: rf_depth,
      feature_importances: feature_importances,
      latentDim: latentDim,
      klWeight: klWeight,
      customRecipes: loadedRecipes, // ★追加
    );
  }

  @override
  void write(BinaryWriter writer, NeuralProject obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeList(obj.inputDefs);
    writer.writeList(obj.outputDefs);
    writer.writeList(obj.mode == 1 ? [] : obj.data);
    writer.writeInt(obj.hiddenLayers);
    writer.writeInt(obj.hiddenNodes);
    writer.writeInt(obj.optimizer);
    writer.writeInt(obj.batchSize);
    writer.writeString(obj.trainedModelJson ?? "");
    writer.writeInt(obj.mode);
    writer.writeInt(obj.ecoWaitMs);
    writer.writeDouble(obj.learningRate);
    writer.writeBool(obj.isRandomSplit);
    writer.writeInt(obj.lossType);
    writer.writeList(obj.hiddenNodesList);
    writer.writeInt(obj.nGramCount);
    writer.writeString(obj.rawText ?? "");
    writer.writeString(obj.appVersion);
    writer.writeInt(obj.langMode);
    writer.writeInt(obj.engineType);
    writer.writeDouble(obj.dropoutRate);
    writer.writeDouble(obj.l2Rate);
    writer.writeInt(obj.rf_trees);
    writer.writeInt(obj.rf_depth);
    writer.writeList(obj.feature_importances ?? []);
    writer.writeInt(obj.latentDim);
    writer.writeDouble(obj.klWeight);

    // ★修正点3: FeatureDefの拡張プロパティは、トップレベルの最後にリストとして保存する
    writer.writeList(obj.inputDefs.map((e) => e.missingStrategy).toList());
    writer.writeList(
      obj.inputDefs.map((e) => e.fallbackNumeric ?? double.nan).toList(),
    );
    writer.writeList(
      obj.inputDefs.map((e) => e.fallbackCategory ?? "").toList(),
    );

    writer.writeList(obj.outputDefs.map((e) => e.missingStrategy).toList());
    writer.writeList(
      obj.outputDefs.map((e) => e.fallbackNumeric ?? double.nan).toList(),
    );
    writer.writeList(
      obj.outputDefs.map((e) => e.fallbackCategory ?? "").toList(),
    );

    // ★★★ 追加: カスタム特徴量レシピの保存 ★★★
    // TypeAdapter未登録のクラスでも安全に保存できるよう、JSON文字列のリストに変換して書き込む
    writer.writeList(
      obj.customRecipes.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}
