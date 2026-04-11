import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'models.dart';
import 'nn_engine.dart';
import 'tab_data.dart';
import 'tab_train.dart';
import 'tab_predict.dart';
import 'tab_settings.dart';
import 'tab_manual.dart';
// ★VAE用タブのインポート（実ファイルは後で作る想定）
import 'tab_generate.dart';
import 'tab_data_vae.dart';
import 'sample_data.dart';

import 'share_manager.dart';
import 'screen_home.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

// ★★★ terminalLogs や サンプルデータ 用の言語判定プロパティ ★★★
bool get _isEn {
  return ui.PlatformDispatcher.instance.locale.languageCode != 'ja';
}

// ★★★ iPadレスポンシブ対応のためのグローバルスケール計算クラス ★★★
class ScaleUtil {
  static const double baseWidth = 390.0;
  static double scale(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth / baseWidth).clamp(0.8, 2.5);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Hive.initFlutter();
  Hive.registerAdapter(NeuralProjectAdapter());
  Hive.registerAdapter(TrainingDataAdapter());
  Hive.registerAdapter(FeatureDefAdapter());
  await Hive.openBox<NeuralProject>('projectsBox');

  runApp(
    ChangeNotifierProvider(create: (_) => AppState(), child: const MyApp()),
  );
}

// === 全体状態管理 ===
class AppState extends ChangeNotifier {
  final Box<NeuralProject> _box = Hive.box<NeuralProject>('projectsBox');
  List<NeuralProject> get projects => _box.values.toList();

  void addSamplePresets() {
    // ★★★ 追加：V3 VAEモード用のサンプルプロジェクト ★★★
    final pVAE = NeuralProject(
      id: (DateTime.now().millisecondsSinceEpoch - 1).toString(),
      name: _isEn ? "16x16 Image Generator (VAE)" : "16×16ドット絵生成AI (VAE)",
      inputDefs: [
        FeatureDef(
          name: _isEn ? "Color Pixels (RGB)" : "カラーピクセル(RGB)",
          type: 0,
          min: 0,
          max: 255,
        ),
      ],
      outputDefs: [
        FeatureDef(
          name: _isEn ? "Generated Pixels" : "生成ピクセル",
          type: 0,
          min: 0,
          max: 255,
        ),
      ],
      data: [], // データは後からプリセットなどを流し込む想定
      hiddenLayers: 2,
      hiddenNodesList: [64, 32], // エンコーダ側の隠れ層
      optimizer: 2, // Adam
      batchSize: 16,
      mode: 2, // ★VAEモード
      ecoWaitMs: 50,
      learningRate: 0.005,
      isRandomSplit: false,
      appVersion: ShareManager.currentAppVersion,
      latentDim: 4, // 潜在変数を4次元に設定
      klWeight: 1.0,
    );

    // 既存サンプル1
    final p1 = NeuralProject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _isEn ? "Arts vs Sciences AI" : "文系・理系判定AI",
      inputDefs: [
        FeatureDef(
          name: _isEn ? "Literature" : "国語",
          type: 0,
          min: 0,
          max: 100,
        ),
        FeatureDef(name: _isEn ? "Math" : "数学", type: 0, min: 0, max: 100),
        FeatureDef(name: _isEn ? "English" : "英語", type: 0, min: 0, max: 100),
      ],
      outputDefs: [
        FeatureDef(
          name: _isEn ? "Result" : "判定",
          type: 1,
          categories: _isEn ? ["Arts", "Sciences"] : ["文系", "理系"],
        ),
      ],
      data: [
        TrainingData(inputs: [80, 20, 90], outputs: [0]),
        TrainingData(inputs: [30, 90, 40], outputs: [1]),
        TrainingData(inputs: [90, 40, 80], outputs: [0]),
        TrainingData(inputs: [40, 85, 30], outputs: [1]),
        TrainingData(inputs: [85, 50, 70], outputs: [0]),
        TrainingData(inputs: [20, 95, 20], outputs: [1]),
      ],
      hiddenLayers: 1,
      hiddenNodes: 12,
      optimizer: 2,
      batchSize: 8,
      mode: 0,
      ecoWaitMs: 50,
      learningRate: 0.1,
      isRandomSplit: true,
      appVersion: ShareManager.currentAppVersion,
    );

    if (estateMagicWord_ja.isNotEmpty && estateMagicWord_en.isNotEmpty) {
      try {
        String estateMagicWord = "";
        if (_isEn) {
          estateMagicWord = estateMagicWord_en;
        } else {
          estateMagicWord = estateMagicWord_ja;
        }
        String jsonStr = utf8.decode(base64Decode(estateMagicWord));
        NeuralProject p2 = NeuralProject.fromJson(jsonDecode(jsonStr));
        p2.id = (DateTime.now().millisecondsSinceEpoch + 1).toString();
        p2.name = _isEn ? "West Coast Real Estate" : "西海岸不動産価格";
        p2.isRandomSplit = true;
        p2.appVersion = ShareManager.currentAppVersion;
        _box.put(p2.id, p2);
      } catch (e) {
        debugPrint("サンプルの読み込みエラー: $e");
      }
    }

    if (titanicMagicWord.isNotEmpty) {
      try {
        String jsonStr = utf8.decode(base64Decode(titanicMagicWord));
        NeuralProject p3 = NeuralProject.fromJson(jsonDecode(jsonStr));
        p3.id = (DateTime.now().millisecondsSinceEpoch + 2).toString();
        p3.name = _isEn ? "Shipwreck Survival AI" : "豪華客船からの生還";
        p3.isRandomSplit = true;
        p3.appVersion = ShareManager.currentAppVersion;
        _box.put(p3.id, p3);
      } catch (e) {
        debugPrint("サンプルの読み込みエラー: $e");
      }
    }

    if (momotaroMagicWord_ja.isNotEmpty && momotaroMagicWord_en.isNotEmpty) {
      try {
        String momotaroMagicWord = "";
        if (_isEn) {
          momotaroMagicWord = momotaroMagicWord_en;
        } else {
          momotaroMagicWord = momotaroMagicWord_ja;
        }
        String jsonStr = utf8.decode(base64Decode(momotaroMagicWord));
        NeuralProject p4 = NeuralProject.fromJson(jsonDecode(jsonStr));
        p4.id = (DateTime.now().millisecondsSinceEpoch + 3).toString();
        p4.name = _isEn ? "Fairytale Generator (Trained)" : "昔話ジェネレーター (学習済み)";
        p4.isRandomSplit = false;
        p4.appVersion = ShareManager.currentAppVersion;
        _box.put(p4.id, p4);
      } catch (e) {
        debugPrint("サンプルの読み込みエラー: $e");
      }
    }

    if (MagicWord_exampass.isNotEmpty) {
      try {
        String jsonStr = utf8.decode(base64Decode(MagicWord_exampass));
        NeuralProject p5 = NeuralProject.fromJson(jsonDecode(jsonStr));
        p5.id = (DateTime.now().millisecondsSinceEpoch + 5).toString();
        p5.name = _isEn ? "Student Exam Pass/Fail" : "Student Exam Pass/Fail";
        p5.isRandomSplit = true;
        p5.appVersion = ShareManager.currentAppVersion;
        _box.put(p5.id, p5);
      } catch (e) {
        debugPrint("サンプルの読み込みエラー: $e");
      }
    }
    if (MagicWord_RPG.isNotEmpty) {
      try {
        String jsonStr = utf8.decode(base64Decode(MagicWord_RPG));
        NeuralProject pp = NeuralProject.fromJson(jsonDecode(jsonStr));
        pp.id = (DateTime.now().millisecondsSinceEpoch + 6).toString();
        pp.name = _isEn ? "RPG Character Class" : "RPG Character Class";
        pp.isRandomSplit = true;
        pp.appVersion = ShareManager.currentAppVersion;
        _box.put(pp.id, pp);
      } catch (e) {
        debugPrint("サンプルの読み込みエラー: $e");
      }
    }
    if (MagicWord_Mushroom.isNotEmpty) {
      try {
        String jsonStr = utf8.decode(base64Decode(MagicWord_Mushroom));
        NeuralProject pp = NeuralProject.fromJson(jsonDecode(jsonStr));
        pp.id = (DateTime.now().millisecondsSinceEpoch + 7).toString();
        pp.name = _isEn ? "Poisonous Mushroom" : "Poisonous Mushroom";
        pp.isRandomSplit = true;
        pp.appVersion = ShareManager.currentAppVersion;
        _box.put(pp.id, pp);
      } catch (e) {
        debugPrint("サンプルの読み込みエラー: $e");
      }
    }
    if (MagicWord_Spam.isNotEmpty) {
      try {
        String jsonStr = utf8.decode(base64Decode(MagicWord_Spam));
        NeuralProject pp = NeuralProject.fromJson(jsonDecode(jsonStr));
        pp.id = (DateTime.now().millisecondsSinceEpoch + 8).toString();
        pp.name = _isEn ? "Spam Message Detection" : "Spam Message Detection";
        pp.isRandomSplit = true;
        pp.appVersion = ShareManager.currentAppVersion;
        _box.put(pp.id, pp);
      } catch (e) {
        debugPrint("サンプルの読み込みエラー: $e");
      }
    }
    if (MagicWord_WeatherActivity.isNotEmpty) {
      try {
        String jsonStr = utf8.decode(base64Decode(MagicWord_WeatherActivity));
        NeuralProject pp = NeuralProject.fromJson(jsonDecode(jsonStr));
        pp.id = (DateTime.now().millisecondsSinceEpoch + 9).toString();
        pp.name = _isEn ? "Weather & Activity" : "Weather & Activity";
        pp.isRandomSplit = true;
        pp.appVersion = ShareManager.currentAppVersion;
        _box.put(pp.id, pp);
      } catch (e) {
        debugPrint("サンプルの読み込みエラー: $e");
      }
    }
    if (MagicWord_TokyoApartmentRent.isNotEmpty) {
      try {
        String jsonStr = utf8.decode(
          base64Decode(MagicWord_TokyoApartmentRent),
        );
        NeuralProject pp = NeuralProject.fromJson(jsonDecode(jsonStr));
        pp.id = (DateTime.now().millisecondsSinceEpoch + 10).toString();
        pp.name = _isEn ? "Tokyo Apartment Rent" : "Tokyo Apartment Rent";
        pp.isRandomSplit = true;
        pp.appVersion = ShareManager.currentAppVersion;
        _box.put(pp.id, pp);
      } catch (e) {
        debugPrint("サンプルの読み込みエラー: $e");
      }
    }
    if (MagicWord_IceCream.isNotEmpty) {
      try {
        String jsonStr = utf8.decode(base64Decode(MagicWord_IceCream));
        NeuralProject pp = NeuralProject.fromJson(jsonDecode(jsonStr));
        pp.id = (DateTime.now().millisecondsSinceEpoch + 11).toString();
        pp.name = _isEn ? "Ice Cream Sales" : "Ice Cream Sales";
        pp.isRandomSplit = true;
        pp.appVersion = ShareManager.currentAppVersion;
        _box.put(pp.id, pp);
      } catch (e) {
        debugPrint("サンプルの読み込みエラー: $e");
      }
    }
    if (MagicWord_UsedCar.isNotEmpty) {
      try {
        String jsonStr = utf8.decode(base64Decode(MagicWord_UsedCar));
        NeuralProject pp = NeuralProject.fromJson(jsonDecode(jsonStr));
        pp.id = (DateTime.now().millisecondsSinceEpoch + 12).toString();
        pp.name = _isEn ? "Used Car Price" : "Used Car Price";
        pp.isRandomSplit = true;
        pp.appVersion = ShareManager.currentAppVersion;
        _box.put(pp.id, pp);
      } catch (e) {
        debugPrint("サンプルの読み込みエラー: $e");
      }
    }
    if (MagicWord_PlantGrowth.isNotEmpty) {
      try {
        String jsonStr = utf8.decode(base64Decode(MagicWord_PlantGrowth));
        NeuralProject pp = NeuralProject.fromJson(jsonDecode(jsonStr));
        pp.id = (DateTime.now().millisecondsSinceEpoch + 13).toString();
        pp.name = _isEn ? "Plant Growth" : "Plant Growth";
        pp.isRandomSplit = true;
        pp.appVersion = ShareManager.currentAppVersion;
        _box.put(pp.id, pp);
      } catch (e) {
        debugPrint("サンプルの読み込みエラー: $e");
      }
    }
    if (MagicWord_Movie.isNotEmpty) {
      try {
        String jsonStr = utf8.decode(base64Decode(MagicWord_Movie));
        NeuralProject pp = NeuralProject.fromJson(jsonDecode(jsonStr));
        pp.id = (DateTime.now().millisecondsSinceEpoch + 14).toString();
        pp.name = _isEn ? "Movie Box Office" : "Movie Box Office";
        pp.isRandomSplit = true;
        pp.appVersion = ShareManager.currentAppVersion;
        _box.put(pp.id, pp);
      } catch (e) {
        debugPrint("サンプルの読み込みエラー: $e");
      }
    }
    if (MagicWord_MagicWandGesture.isNotEmpty) {
      try {
        String jsonStr = utf8.decode(base64Decode(MagicWord_MagicWandGesture));
        NeuralProject pp = NeuralProject.fromJson(jsonDecode(jsonStr));
        pp.id = (DateTime.now().millisecondsSinceEpoch + 15).toString();
        pp.name = _isEn ? "Magic Wand Gesture" : "Magic Wand Gesture";
        pp.isRandomSplit = true;
        pp.appVersion = ShareManager.currentAppVersion;
        _box.put(pp.id, pp);
      } catch (e) {
        debugPrint("サンプルの読み込みエラー: $e");
      }
    }
    if (MagicWord_SmartAlarm.isNotEmpty) {
      try {
        String jsonStr = utf8.decode(base64Decode(MagicWord_SmartAlarm));
        NeuralProject pp = NeuralProject.fromJson(jsonDecode(jsonStr));
        pp.id = (DateTime.now().millisecondsSinceEpoch + 16).toString();
        pp.name = _isEn ? "Smart Fire/Hazard Alarm" : "Smart Fire/Hazard Alarm";
        pp.isRandomSplit = true;
        pp.appVersion = ShareManager.currentAppVersion;
        _box.put(pp.id, pp);
      } catch (e) {
        debugPrint("サンプルの読み込みエラー: $e");
      }
    }
    if (MagicWord_ColorSorterDevice.isNotEmpty) {
      try {
        String jsonStr = utf8.decode(base64Decode(MagicWord_ColorSorterDevice));
        NeuralProject pp = NeuralProject.fromJson(jsonDecode(jsonStr));
        pp.id = (DateTime.now().millisecondsSinceEpoch + 17).toString();
        pp.name = _isEn ? "Color Sorter Device" : "Color Sorter Device";
        pp.isRandomSplit = true;
        pp.appVersion = ShareManager.currentAppVersion;
        _box.put(pp.id, pp);
      } catch (e) {
        debugPrint("サンプルの読み込みエラー: $e");
      }
    }
    if (MagicWord_UltrasonicDistanceCalibrator.isNotEmpty) {
      try {
        String jsonStr = utf8.decode(
          base64Decode(MagicWord_UltrasonicDistanceCalibrator),
        );
        NeuralProject pp = NeuralProject.fromJson(jsonDecode(jsonStr));
        pp.id = (DateTime.now().millisecondsSinceEpoch + 18).toString();
        pp.name = _isEn
            ? "Ultrasonic Distance Calibrator"
            : "Ultrasonic Distance Calibrator";
        pp.isRandomSplit = true;
        pp.appVersion = ShareManager.currentAppVersion;
        _box.put(pp.id, pp);
      } catch (e) {
        debugPrint("サンプルの読み込みエラー: $e");
      }
    }
    if (MagicWord_ThermistorNon_linearConverter.isNotEmpty) {
      try {
        String jsonStr = utf8.decode(
          base64Decode(MagicWord_ThermistorNon_linearConverter),
        );
        NeuralProject pp = NeuralProject.fromJson(jsonDecode(jsonStr));
        pp.id = (DateTime.now().millisecondsSinceEpoch + 19).toString();
        pp.name = _isEn
            ? "Thermistor Non-linear Converter"
            : "Thermistor Non-linear Converter";
        pp.isRandomSplit = true;
        pp.appVersion = ShareManager.currentAppVersion;
        _box.put(pp.id, pp);
      } catch (e) {
        debugPrint("サンプルの読み込みエラー: $e");
      }
    }

    _box.put(p1.id, p1);
    _box.put(pVAE.id, pVAE); // VAEサンプルも保存
    notifyListeners();
  }

  void saveProject(NeuralProject proj) {
    _box.put(proj.id, proj);
    notifyListeners();
  }

  void deleteProject(String id) {
    _box.delete(id);
    notifyListeners();
  }

  void refreshProjects() {
    notifyListeners();
  }

  bool importProjectFromJsonString(String jsonStr, String suffixName) {
    try {
      NeuralProject newProj = NeuralProject.fromJson(jsonDecode(jsonStr));
      newProj.id = DateTime.now().millisecondsSinceEpoch.toString();
      newProj.name = "${newProj.name}($suffixName)";
      _box.put(newProj.id, newProj);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}

class ProjectState extends ChangeNotifier {
  final NeuralProject proj;
  NeuralNetwork? nn;
  RandomForest? rf;

  List<String> terminalLogs = [];
  List<double> trainLossHistory = [];
  List<double> valLossHistory = [];
  int currentEpochCount = 0;

  bool isTraining = false;
  bool stopRequested = false;
  int targetEpochs = 1000;
  ActivationType actType = ActivationType.relu;

  bool isHeatmapActive = false;

  List<TrainingData> validationData = [];
  List<bool> inputMask = [];

  int get ecoWaitMs => proj.ecoWaitMs;

  bool isScreenSaverActive = false;
  Timer? _idleTimer;
  final int _idleTimeoutSeconds = 600;
  Alignment saverAlignment = Alignment.center;
  Timer? _moveTimer;
  final Random _rnd = Random();

  ProjectState(this.proj) {
    if (proj.trainedModelJson != null) {
      try {
        if (proj.engineType == 0) {
          nn = NeuralNetwork.fromJson(jsonDecode(proj.trainedModelJson!));
          actType = nn!.hiddenActivation;

          // VAEモード(mode==2)と通常/テキストで入力サイズの計算を分ける
          int currentInputSize = 0;
          if (proj.mode == 2) {
            // VAEモード時は 16x16x3 = 768 を強制
            currentInputSize = 768;
          } else {
            currentInputSize = encodeData(
              List.filled(proj.inputDefs.length, 0),
              proj.inputDefs,
            ).length;
          }

          if (nn!.layerSizes[0] != currentInputSize) {
            nn = null;
            terminalLogs.add(
              _isEn
                  ? ">> Input configuration changed. Saved brain has been reset."
                  : ">> 入力構成が変更されているため、保存された脳をリセットしました。",
            );
          } else {
            terminalLogs.add(
              _isEn
                  ? ">> Successfully loaded past training data (AI brain)."
                  : ">> 過去の学習データ（AIの脳）を正常に読み込みました。",
            );
            terminalLogs.add(
              _isEn ? ">> You can now test it." : ">> このままテストできます。",
            );
          }
        } else {
          // ★RFの復元処理
          rf = RandomForest.fromJson(jsonDecode(proj.trainedModelJson!));
          int currentInputSize = encodeData(
            List.filled(proj.inputDefs.length, 0),
            proj.inputDefs,
          ).length;

          if (rf!.inputSize != currentInputSize) {
            rf = null;
            terminalLogs.add(
              _isEn
                  ? ">> Input configuration changed. Saved brain has been reset."
                  : ">> 入力構成が変更されているため、保存された脳をリセットしました。",
            );
          } else {
            terminalLogs.add(
              _isEn
                  ? ">> Successfully loaded past training data (Random Forest)."
                  : ">> 過去の学習データ（ランダムフォレスト）を正常に読み込みました。",
            );
            terminalLogs.add(
              _isEn
                  ? ">> You can now test it in the 'Predict' tab."
                  : ">> このまま「推論」タブでテストできます。",
            );
          }
        }
      } catch (e) {
        terminalLogs.add(
          _isEn
              ? ">> Failed to load past training data."
              : ">> 過去の学習データの読み込みに失敗しました。",
        );
        nn = null;
        rf = null;
      }
    }
    _startIdleTimer();
  }

  void updateInputMask(List<bool> newMask) {
    if (newMask.length != proj.inputDefs.length) return;
    inputMask = List.from(newMask);
    resetTraining();
  }

  void setHeatmapActive(bool isActive) {
    isHeatmapActive = isActive;
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _moveTimer?.cancel();
    super.dispose();
  }

  void resetIdleTimer() {
    if (isScreenSaverActive) {
      isScreenSaverActive = false;
      _moveTimer?.cancel();
      notifyListeners();
    }
    _startIdleTimer();
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(Duration(seconds: _idleTimeoutSeconds), () {
      if (isTraining) {
        isScreenSaverActive = true;
        _startMoveTimer();
        notifyListeners();
      }
    });
  }

  void _startMoveTimer() {
    _moveTimer?.cancel();
    saverAlignment = Alignment(
      (_rnd.nextDouble() * 1.6) - 0.8,
      (_rnd.nextDouble() * 1.6) - 0.8,
    );

    _moveTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      saverAlignment = Alignment(
        (_rnd.nextDouble() * 1.6) - 0.8,
        (_rnd.nextDouble() * 1.6) - 0.8,
      );
      notifyListeners();
    });
  }

  void setTargetEpochs(int value) {
    targetEpochs = value;
    notifyListeners();
  }

  void setActType(ActivationType type) {
    actType = type;
    notifyListeners();
  }

  void setEcoWait(int ms) {
    proj.ecoWaitMs = ms;
    Hive.box<NeuralProject>('projectsBox').put(proj.id, proj);
    notifyListeners();
  }

  void setLearningRate(double lr) {
    proj.learningRate = lr;
    if (nn != null) {
      nn!.learningRate = lr;
    }
    Hive.box<NeuralProject>('projectsBox').put(proj.id, proj);
    notifyListeners();
  }

  void setRandomSplit(bool isRandom) {
    proj.isRandomSplit = isRandom;
    resetTraining();
    Hive.box<NeuralProject>('projectsBox').put(proj.id, proj);
    notifyListeners();
  }

  void extractDataFromRawText(String rawText) {
    String targetText = rawText.trim().isNotEmpty
        ? rawText
        : (proj.rawText ?? "");

    if (targetText.trim().isEmpty && proj.data.isNotEmpty) {
      StringBuffer sb = StringBuffer();
      for (var d in proj.data) {
        if (d.inputs.isEmpty) continue;
        int idx = d.inputs[0].toInt();
        if (idx >= 0 && idx < proj.currentChars.length)
          sb.write(proj.currentChars[idx]);
      }
      var last = proj.data.last;
      if (last.inputs.length > 1) {
        for (int i = 1; i < last.inputs.length; i++) {
          int idx = last.inputs[i].toInt();
          if (idx >= 0 && idx < proj.currentChars.length)
            sb.write(proj.currentChars[idx]);
        }
      }
      if (last.outputs.isNotEmpty) {
        int outIdx = last.outputs[0].toInt();
        if (outIdx >= 0 && outIdx < proj.currentChars.length)
          sb.write(proj.currentChars[outIdx]);
      }
      targetText = sb.toString();
    }

    proj.rawText = targetText;
    proj.data.clear();
    inputMask.clear();

    List<String> charList = proj.currentChars.split('');
    List<FeatureDef> newInputs = [];

    for (int i = 1; i <= proj.nGramCount; i++) {
      String name = proj.langMode == 1 ? "Past char $i" : "過去文字$i";
      newInputs.add(FeatureDef(name: name, type: 1, categories: charList));
    }
    proj.inputDefs = newInputs;

    if (targetText.trim().isEmpty) {
      resetTraining();
      return;
    }

    String cleanText = targetText;
    int n = proj.nGramCount;
    if (cleanText.length <= n) {
      resetTraining();
      return;
    }

    for (int i = 0; i < cleanText.length - n; i++) {
      List<double> inVals = [];
      for (int j = 0; j < n; j++) {
        double idx = proj.currentChars.indexOf(cleanText[i + j]).toDouble();
        inVals.add(idx == -1.0 ? 0.0 : idx);
      }
      double outVal = proj.currentChars.indexOf(cleanText[i + n]).toDouble();
      outVal = outVal == -1.0 ? 0.0 : outVal;

      proj.data.add(TrainingData(inputs: inVals, outputs: [outVal]));
    }

    resetTraining();
  }

  void appendDataFromText(String newText) {
    if (newText.trim().isEmpty) return;
    String combinedText = (proj.rawText ?? "") + newText;
    extractDataFromRawText(combinedText);
  }

  void updateNetworkStructure(
    int layers,
    List<int> nodesList,
    int opt,
    int batch,
  ) {
    proj.hiddenLayers = layers;
    proj.hiddenNodesList = List.from(nodesList);
    if (nodesList.isNotEmpty) {
      proj.hiddenNodes = nodesList.first;
    }
    proj.optimizer = opt;
    proj.batchSize = batch;

    if (proj.mode == 1) {
      extractDataFromRawText(proj.rawText ?? "");
    } else {
      resetTraining();
    }

    Hive.box<NeuralProject>('projectsBox').put(proj.id, proj);
  }

  void removeDataAt(int index) {
    proj.data.removeAt(index);
    resetTraining();
  }

  void clearAllData() {
    proj.data.clear();
    proj.rawText = null;
    resetTraining();
  }

  Future<void> importDataFromText(String text, BuildContext context) async {
    try {
      List<String> lines = text.trim().split('\n');
      if (lines.isEmpty) return;

      bool truncated = false;
      if (lines.length > 10000) {
        lines = lines.sublist(0, 10000);
        truncated = true;
      }

      int inputCount = proj.inputDefs.length;
      int outputCount = proj.outputDefs.length;
      int expectedCols = inputCount + outputCount;
      List<TrainingData> newData = [];
      int successCount = 0;

      for (String line in lines) {
        if (line.trim().isEmpty) continue;
        String separator = line.contains('\t') ? '\t' : ',';
        List<String> cells = line.split(separator);

        if (cells.length >= expectedCols) {
          List<double> inVals = [];
          List<double> outVals = [];
          bool rowValid = true;

          for (int i = 0; i < expectedCols; i++) {
            String cellStr = cells[i].trim();

            FeatureDef def = (i < inputCount)
                ? proj.inputDefs[i]
                : proj.outputDefs[i - inputCount];

            double? val;

            if (def.type == 1) {
              int catIndex = def.categories.indexOf(cellStr);

              if (catIndex != -1) {
                val = catIndex.toDouble();
              } else {
                double? cellNum = double.tryParse(cellStr);
                if (cellNum != null) {
                  int fuzzyIndex = def.categories.indexWhere((cat) {
                    double? catNum = double.tryParse(cat);
                    return catNum != null && catNum == cellNum;
                  });
                  if (fuzzyIndex != -1) {
                    val = fuzzyIndex.toDouble();
                  }
                }
              }
            } else {
              val = double.tryParse(cellStr);
            }

            if (val == null) {
              rowValid = false;
              break;
            }

            if (i < inputCount)
              inVals.add(val);
            else
              outVals.add(val);
          }

          if (rowValid) {
            newData.add(TrainingData(inputs: inVals, outputs: outVals));
            successCount++;
          }
        }
      }

      if (successCount > 0) {
        proj.data.addAll(newData);
        if (proj.data.length > 10000)
          proj.data = proj.data.sublist(proj.data.length - 10000);
        resetTraining();

        if (context.mounted) {
          final l10n = AppLocalizations.of(context)!;
          String msg = l10n.msgImportSuccess(successCount);
          if (truncated) msg += "\n${l10n.msgImportTruncated}";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
      } else {
        if (context.mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.msgNoDataToImport)));
        }
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.msgImportError(e.toString()))),
        );
      }
    }
  }

  Future<void> importFromClipboard(BuildContext context) async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      await importDataFromText(data.text!, context);
    } else {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.msgNoTextInClipboard)));
      }
    }
  }

  Future<void> importFromCSV(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt', 'tsv'],
      );
      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        if (file.lengthSync() > 5 * 1024 * 1024) {
          if (context.mounted) {
            final l10n = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.msgFileTooLarge)));
          }
          return;
        }
        String text = await file.readAsString();
        await importDataFromText(text, context);
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.msgFileLoadFailed)));
      }
    }
  }

  String _generateExportText(bool isCsv) {
    String separator = isCsv ? ',' : '\t';
    List<String> lines = [];
    List<String> headers = [];
    headers.addAll(proj.inputDefs.map((e) => "IN:${e.name}"));
    headers.addAll(proj.outputDefs.map((e) => "OUT:${e.name}"));
    lines.add(headers.join(separator));

    int exportCount = proj.data.length > 5000 ? 5000 : proj.data.length;
    for (int i = 0; i < exportCount; i++) {
      var d = proj.data[i];
      List<String> row = [];
      for (int j = 0; j < d.inputs.length; j++) {
        var def = proj.inputDefs[j];
        if (def.type == 1) {
          int idx = d.inputs[j].toInt();
          row.add(
            (idx >= 0 && idx < def.categories.length)
                ? def.categories[idx]
                : idx.toString(),
          );
        } else {
          row.add(d.inputs[j].toString());
        }
      }
      for (int j = 0; j < d.outputs.length; j++) {
        var def = proj.outputDefs[j];
        if (def.type == 1) {
          int idx = d.outputs[j].toInt();
          row.add(
            (idx >= 0 && idx < def.categories.length)
                ? def.categories[idx]
                : idx.toString(),
          );
        } else {
          row.add(d.outputs[j].toString());
        }
      }
      lines.add(row.join(separator));
    }
    return lines.join('\n');
  }

  Future<void> exportToClipboard(BuildContext context) async {
    String text = _generateExportText(false);
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      String msg = l10n.msgDataCopiedToClipboard;
      if (proj.data.length > 5000) msg += "\n${l10n.msgExportTruncated5000}";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> exportToCSV(BuildContext context) async {
    try {
      String text = _generateExportText(true);

      final directory = await getTemporaryDirectory();
      String safeName = proj.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final filePath = '${directory.path}/${safeName}_data.csv';
      final file = File(filePath);
      await file.writeAsString(text);

      final RenderObject? renderObject = context.findRenderObject();
      Rect? shareRect;
      if (renderObject is RenderBox) {
        shareRect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
      } else {
        final size = MediaQuery.of(context).size;
        shareRect = Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: 50,
          height: 50,
        );
      }

      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        await Share.shareXFiles(
          [XFile(filePath)],
          text: l10n.msgShareCsvText(proj.name),
          subject: '${proj.name}_data.csv',
          sharePositionOrigin: shareRect,
        );

        String msg = l10n.msgCsvExported;
        if (proj.data.length > 5000) msg += "\n${l10n.msgExportTruncated5000}";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.msgCsvExportFailed(e.toString()))),
        );
      }
    }
  }

  List<double> encodeData(List<double> rawVals, List<FeatureDef> defs) {
    List<double> encoded = [];
    bool applyMask =
        (defs == proj.inputDefs &&
        inputMask.isNotEmpty &&
        inputMask.length == defs.length);

    for (int i = 0; i < defs.length; i++) {
      if (applyMask && !inputMask[i]) {
        continue;
      }
      if (defs[i].type == 0 || defs[i].type == 2) {
        double range = defs[i].max - defs[i].min;
        encoded.add(range == 0 ? 0 : (rawVals[i] - defs[i].min) / range);
      } else {
        for (int c = 0; c < defs[i].categories.length; c++)
          encoded.add(c == rawVals[i].toInt() ? 1.0 : 0.0);
      }
    }
    return encoded;
  }

  List<dynamic> decodePrediction(List<double> rawPred, List<FeatureDef> defs) {
    List<dynamic> results = [];
    int ptr = 0;
    for (var def in defs) {
      if (def.type == 0 || def.type == 2) {
        results.add(rawPred[ptr] * (def.max - def.min) + def.min);
        ptr++;
      } else {
        List<double> probs = [];
        for (int c = 0; c < def.categories.length; c++)
          probs.add(rawPred[ptr++]);
        results.add(probs);
      }
    }
    return results;
  }

  void resetTraining() {
    nn = null;
    rf = null;
    currentEpochCount = 0;
    trainLossHistory.clear();
    valLossHistory.clear();
    terminalLogs.clear();
    terminalLogs.add(
      _isEn
          ? ">> Training history and AI brain (weights/trees) fully reset."
          : ">> 学習履歴とAIの脳（重み・決定木）を完全にリセットしました。",
    );
    proj.trainedModelJson = null;
    proj.feature_importances = null;
    Hive.box<NeuralProject>('projectsBox').put(proj.id, proj);
    notifyListeners();
  }

  double _calculateRFLoss(
    RandomForest rfModel,
    List<List<double>> inputs,
    List<List<double>> expectedOutputs,
    int lossType,
  ) {
    if (inputs.isEmpty) return 0.0;
    double totalLoss = 0.0;
    for (int i = 0; i < inputs.length; i++) {
      List<double> o = rfModel.predict(inputs[i]).finalOutput;
      for (int j = 0; j < o.length; j++) {
        if (lossType == 1) {
          // CrossEntropy風
          totalLoss += -expectedOutputs[i][j] * log(o[j] + 1e-7);
        } else {
          // MSE
          totalLoss += pow(expectedOutputs[i][j] - o[j], 2);
        }
      }
    }
    return totalLoss / inputs.length;
  }

  Future<void> startTraining() async {
    if (proj.data.isEmpty) {
      terminalLogs.insert(
        0,
        _isEn
            ? ">> [Error] No training data. Please create a textbook in the Data tab!"
            : ">> 【エラー】学習データが0件です。データタブで教科書を作ってください！",
      );
      notifyListeners();
      return;
    }

    // フェイルセーフ：テキスト生成・VAEモードはRF非対応
    if ((proj.mode == 1 || proj.mode == 2) && proj.engineType == 1) {
      proj.engineType = 0; // 強制NN
      terminalLogs.insert(
        0,
        _isEn
            ? ">> [Warning] Text/Image Gen Mode only supports Neural Networks. Engine switched to NN automatically."
            : ">> 【フェイルセーフ】生成モードはNN専用です。強制的にエンジンをNNへ切り替えました。",
      );
      Hive.box<NeuralProject>('projectsBox').put(proj.id, proj);
    }

    isTraining = true;
    stopRequested = false;
    WakelockPlus.enable();

    validationData.clear();
    notifyListeners();

    int trueInputSize = 0;
    int trueOutputSize = 0;

    if (proj.mode == 2) {
      // VAEの入力と出力は画像のフラット化データ（16x16x3=768）
      trueInputSize = 768;
      trueOutputSize = 768;
    } else {
      trueInputSize = encodeData(
        List.filled(proj.inputDefs.length, 0),
        proj.inputDefs,
      ).length;
      trueOutputSize = encodeData(
        List.filled(proj.outputDefs.length, 0),
        proj.outputDefs,
      ).length;
    }

    // データ分割
    int dataCount = proj.data.length;
    List<int> allIndices = List.generate(dataCount, (i) => i);
    List<int> trainIndices = [];
    List<int> valIndices = [];

    // モードごとの学習方針
    if (proj.mode == 1 || proj.mode == 2) {
      // テキスト生成・VAE画像生成の場合は全データを使う
      trainIndices = List.from(allIndices);
      valIndices = List.from(allIndices);
    } else {
      int trainCount = dataCount >= 5 ? (dataCount * 0.8).floor() : dataCount;
      if (proj.isRandomSplit && dataCount >= 5) {
        allIndices.shuffle(Random(42));
        trainIndices = allIndices.sublist(0, trainCount);
        valIndices = allIndices.sublist(trainCount);
      } else {
        trainIndices = allIndices.sublist(0, trainCount);
        valIndices = allIndices.sublist(trainCount);
      }
    }

    for (int idx in valIndices) {
      validationData.add(proj.data[idx]);
    }

    List<List<double>> tInputs = [];
    List<List<double>> tOutputs = [];

    // データエンコード
    if (proj.mode == 2) {
      // VAE: データ側ですでに768次元化されていると仮定（またはここで変換処理を入れる）
      // 現在は仮置きとしてそのまま使う
      for (int idx in trainIndices) {
        tInputs.add(proj.data[idx].inputs);
        tOutputs.add(proj.data[idx].outputs);
      }
    } else {
      for (int idx in trainIndices) {
        tInputs.add(encodeData(proj.data[idx].inputs, proj.inputDefs));
        tOutputs.add(encodeData(proj.data[idx].outputs, proj.outputDefs));
      }
    }

    List<List<double>> vInputs = [];
    List<List<double>> vOutputs = [];

    if (proj.mode == 2) {
      for (int idx in valIndices) {
        vInputs.add(proj.data[idx].inputs);
        vOutputs.add(proj.data[idx].outputs);
      }
    } else {
      for (int idx in valIndices) {
        vInputs.add(encodeData(proj.data[idx].inputs, proj.inputDefs));
        vOutputs.add(encodeData(proj.data[idx].outputs, proj.outputDefs));
      }
    }

    final stopwatch = Stopwatch()..start();

    if (proj.engineType == 0) {
      // NNの学習
      if (nn == null) {
        List<int> layers = [trueInputSize];
        for (int i = 0; i < proj.hiddenLayers; i++) {
          int n = (i < proj.hiddenNodesList.length)
              ? proj.hiddenNodesList[i]
              : proj.hiddenNodes;
          layers.add(n);
        }
        layers.add(trueOutputSize);

        // ★ VAEモード時の特殊なレイヤー構成を後ほどnn_engine.dartで拡張対応します
        nn = NeuralNetwork(
          layerSizes: layers,
          learningRate: proj.learningRate,
          hiddenActivation: actType,
          optimizerType: OptimizerType.values[proj.optimizer],
          batchSize: proj.batchSize,
          lossType: proj.lossType,
          dropoutRate: proj.dropoutRate,
          l2Rate: proj.l2Rate,
          isVAE: proj.mode == 2, // ★NNにVAEかどうかを伝える
          latentDim: proj.latentDim, // ★
        );
      }

      final yieldTimer = Stopwatch()..start();

      for (int epoch = 1; epoch <= targetEpochs; epoch++) {
        if (stopRequested) {
          terminalLogs.insert(
            0,
            _isEn
                ? ">> Force Stopped (Epoch $currentEpochCount)"
                : ">> 強制停止 (Epoch $currentEpochCount)",
          );
          if (proj.mode == 1 || proj.mode == 2) {
            terminalLogs.insert(
              0,
              _isEn
                  ? ">> * In Gen mode, all data is used for training, so only TrainLoss is shown."
                  : ">> ※生成モードの場合には、全データを学習に使うので、trainの値しか表示されません。",
            );
          }
          break;
        }

        double tLoss = await nn!.trainEpoch(
          tInputs,
          tOutputs,
          ecoWaitMs,
          () => stopRequested,
          () async {
            if (isHeatmapActive) {
              notifyListeners();
              await Future.delayed(Duration.zero);
            }
          },
        );

        double vLoss = vInputs.isEmpty
            ? tLoss
            : nn!.calculateLoss(vInputs, vOutputs);

        currentEpochCount++;
        trainLossHistory.add(tLoss);
        valLossHistory.add(vLoss);

        if (yieldTimer.elapsedMilliseconds > 14 || epoch == targetEpochs) {
          if (proj.mode == 1 || proj.mode == 2) {
            terminalLogs.insert(
              0,
              "Epoch ${currentEpochCount.toString().padLeft(4)} ... TrainLoss: ${tLoss.toStringAsFixed(5)}",
            );
          } else {
            terminalLogs.insert(
              0,
              "Epoch ${currentEpochCount.toString().padLeft(4)} ... TrainLoss: ${tLoss.toStringAsFixed(5)} | ValLoss: ${vLoss.toStringAsFixed(5)}",
            );
          }
          notifyListeners();

          await Future.delayed(Duration.zero);
          yieldTimer.reset();
        }
      }
      stopwatch.stop();

      if (!stopRequested) {
        terminalLogs.insert(
          0,
          _isEn
              ? ">> Training Complete! (${stopwatch.elapsedMilliseconds}ms)"
              : ">> 学習完了！ (${stopwatch.elapsedMilliseconds}ms)",
        );
        if (proj.mode == 1 || proj.mode == 2) {
          terminalLogs.insert(
            0,
            _isEn
                ? ">> * In Gen mode, all data is used for training, so only TrainLoss is shown."
                : ">> ※生成モードの場合には、全データを学習に使うので、trainの値しか表示されません。",
          );
        }
      }

      proj.trainedModelJson = jsonEncode(nn!.toJson());
      Hive.box<NeuralProject>('projectsBox').put(proj.id, proj);
    } else {
      // RFの学習
      terminalLogs.insert(
        0,
        _isEn
            ? ">> Assembling Random Forest (Trees: ${proj.rf_trees}, Depth: ${proj.rf_depth})..."
            : ">> ランダムフォレストを構築中（木:${proj.rf_trees}本, 深さ:${proj.rf_depth}）...",
      );
      notifyListeners();

      rf = RandomForest(
        numTrees: proj.rf_trees,
        maxDepth: proj.rf_depth,
        lossType: proj.lossType,
        inputSize: trueInputSize,
        outputSize: trueOutputSize,
      );

      await rf!.train(tInputs, tOutputs, ecoWaitMs, () => stopRequested);
      stopwatch.stop();

      double tLoss = _calculateRFLoss(rf!, tInputs, tOutputs, proj.lossType);
      double vLoss = vInputs.isEmpty
          ? tLoss
          : _calculateRFLoss(rf!, vInputs, vOutputs, proj.lossType);

      currentEpochCount = 1;
      trainLossHistory.add(tLoss);
      valLossHistory.add(vLoss);

      terminalLogs.insert(
        0,
        "Result ... TrainLoss: ${tLoss.toStringAsFixed(5)} | ValLoss: ${vLoss.toStringAsFixed(5)}",
      );

      terminalLogs.insert(
        0,
        _isEn
            ? ">> RF Training Complete! (${stopwatch.elapsedMilliseconds}ms)"
            : ">> RF学習完了！ (${stopwatch.elapsedMilliseconds}ms)",
      );

      proj.feature_importances = List.from(rf!.featureImportances);
      proj.trainedModelJson = jsonEncode(rf!.toJson());
      Hive.box<NeuralProject>('projectsBox').put(proj.id, proj);
    }

    isTraining = false;
    isScreenSaverActive = false;
    _moveTimer?.cancel();
    WakelockPlus.disable();

    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('ja', '')],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale != null) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode) {
              return supportedLocale;
            }
          }
        }
        return supportedLocales.first;
      },
      debugShowCheckedModeBanner: false,
      title: '箱庭小AI',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.green,
          secondary: Colors.greenAccent,
        ),
      ),
      builder: (context, child) {
        final double scale = ScaleUtil.scale(context);

        return Theme(
          data: Theme.of(context).copyWith(
            appBarTheme: AppBarTheme(
              iconTheme: IconThemeData(size: 24.0 * scale),
            ),
            sliderTheme: SliderThemeData(
              showValueIndicator: ShowValueIndicator.always,
              trackHeight: 4.0 * scale,
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: 10.0 * scale,
              ),
              valueIndicatorTextStyle: TextStyle(
                fontSize: 14.0 * scale,
                color: Colors.white,
              ),
            ),
          ),
          child: child!,
        );
      },
      home: const HomeScreen(),
    );
  }
}

class ProjectDetailScreen extends StatelessWidget {
  const ProjectDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProjectState>();
    final proj = state.proj;
    final double scale = ScaleUtil.scale(context);
    final l10n = AppLocalizations.of(context)!;

    // ★ VAEモード時は「Predict」タブを「Generate」タブに差し替える
    final bool isVAE = proj.mode == 2;
    // データタブの切り替え
    final Widget dataTab = isVAE ? const DataVAETab() : const DataTab();
    final IconData actionIcon = isVAE ? Icons.image : Icons.science;
    final String actionText = isVAE
        ? (_isEn ? "Generate" : "生成")
        : l10n.tabPredict;
    final Widget actionTab = isVAE ? const GenerateTab() : const PredictTab();

    return Stack(
      children: [
        Listener(
          onPointerDown: (_) => state.resetIdleTimer(),
          onPointerMove: (_) => state.resetIdleTimer(),
          behavior: HitTestBehavior.translucent,
          child: PopScope(
            canPop: !state.isTraining,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.msgCannotPopDuringTraining,
                    style: TextStyle(fontSize: 14 * scale),
                  ),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            child: DefaultTabController(
              length: 5,
              child: GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                behavior: HitTestBehavior.opaque,
                child: Scaffold(
                  appBar: AppBar(
                    title: Text(
                      proj.name,
                      style: TextStyle(fontSize: 20 * scale),
                    ),
                  ),
                  body: TabBarView(
                    children: [
                      dataTab, // ★固定の const DataTab() から動的変数に変更
                      const TrainTab(),
                      actionTab, // ★動的切り替え
                      const SettingsTab(),
                      const ManualTab(),
                    ],
                  ),
                  bottomNavigationBar: Material(
                    color: Colors.black87,
                    child: SafeArea(
                      child: SizedBox(
                        height: 72 * scale,
                        child: TabBar(
                          isScrollable: false,
                          indicatorColor: Colors.greenAccent,
                          labelColor: Colors.greenAccent,
                          unselectedLabelColor: Colors.grey,
                          labelStyle: TextStyle(fontSize: 10 * scale),
                          tabs: [
                            Tab(
                              height: 72 * scale,
                              icon: Icon(Icons.edit, size: 22 * scale),
                              text: l10n.tabData,
                            ),
                            Tab(
                              height: 72 * scale,
                              icon: Icon(Icons.terminal, size: 22 * scale),
                              text: l10n.tabTrain,
                            ),
                            Tab(
                              height: 72 * scale,
                              icon: Icon(actionIcon, size: 22 * scale),
                              text: actionText,
                            ),
                            Tab(
                              height: 72 * scale,
                              icon: Icon(Icons.settings, size: 22 * scale),
                              text: l10n.tabSettings,
                            ),
                            Tab(
                              height: 72 * scale,
                              icon: Icon(Icons.menu_book, size: 22 * scale),
                              text: l10n.tabManual,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        IgnorePointer(
          ignoring: true,
          child: AnimatedOpacity(
            opacity: state.isScreenSaverActive ? 0.95 : 0.0,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            child: Container(
              color: Colors.black,
              child: AnimatedAlign(
                duration: const Duration(seconds: 3),
                curve: Curves.easeInOut,
                alignment: state.saverAlignment,
                child: state.isScreenSaverActive
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.nights_stay,
                            color: Colors.greenAccent,
                            size: 40 * scale,
                          ),
                          SizedBox(height: 16 * scale),
                          Text(
                            l10n.msgScreenSaver,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14 * scale,
                              letterSpacing: 2,
                              height: 1.5,
                              decoration: TextDecoration.none,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
