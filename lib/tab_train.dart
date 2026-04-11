import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:ui' as ui; // 画像変換と言語判定用
import 'dart:typed_data'; // 画像変換用
import 'main.dart'; // ScaleUtil, ProjectState, NeuralNetwork等へのアクセス
import 'nn_engine.dart';
import 'models.dart'; // FeatureDef用
import 'l10n/app_localizations.dart';
import 'pdf_report_generator.dart'; // PDF出力ロジック
//import 'dart:typed_data';
//import 'tab_predict.dart';

class TrainTab extends StatefulWidget {
  const TrainTab({super.key});

  @override
  State<TrainTab> createState() => _TrainTabState();
}

class _TrainTabState extends State<TrainTab> {
  bool _showHeatmap = false;

  bool _isAnalyzing = false;
  Map<String, double>? _sensitivityResults;
  double _progress = 0.0;

  double? _currentAccuracy;
  bool _isCalcingAcc = false;

  // 分析指標
  double? _fScore; // 分類用：F値
  double? _r2Score; // 回帰用：決定係数

  List<List<int>>? _confusionMatrix;
  List<String> _matrixLabels = [];
  List<Offset>? _scatterPoints;

  List<bool> _tempInputMask = [];

  late TextEditingController _epochCtrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectState>().setHeatmapActive(_showHeatmap);
    });

    final projState = context.read<ProjectState>();
    _epochCtrl = TextEditingController(text: projState.targetEpochs.toString());
  }

  @override
  void dispose() {
    _epochCtrl.dispose();
    super.dispose();
  }

  Future<Uint8List> _capturePainter(
    CustomPainter painter,
    Size size, {
    bool whiteBg = false,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    final bgPaint = ui.Paint()
      ..color = whiteBg
          ? const ui.Color(0xFFFFFFFF)
          : const ui.Color(0xFF1A1A1A);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    painter.paint(canvas, size);
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _exportPdfReport(ProjectState state, double scale) async {
    if (state.nn == null && state.rf == null) return;

    final stopwatch = Stopwatch()..start();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text("Preparing Analysis Report PDF..."),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.teal.shade700,
      ),
    );

    // NNの場合のみ感度分析を実行
    if (state.nn != null &&
        _sensitivityResults == null &&
        state.proj.data.isNotEmpty) {
      await _runSensitivityAnalysis(state);
    }

    // 詳細評価
    if (_confusionMatrix == null &&
        _scatterPoints == null &&
        state.proj.data.isNotEmpty &&
        state.proj.mode < 1) {
      await _runDetailedEvaluation(state);
    }

    final lossPainter = LossChartPainter(
      state.trainLossHistory,
      state.valLossHistory,
      2.0,
    );
    final lossBytes = await _capturePainter(
      lossPainter,
      const Size(600, 200),
      whiteBg: true,
    );

    Uint8List? scatterBytes;
    if (_scatterPoints != null) {
      final scatterPainter = ScatterPlotPainter(_scatterPoints!, 2.0);
      scatterBytes = await _capturePainter(
        scatterPainter,
        const Size(400, 400),
        whiteBg: true,
      );
    }

    List<String> topMistakes = [];
    if (_confusionMatrix != null) {
      List<int> trueTotals = List.filled(_confusionMatrix!.length, 0);
      for (int r = 0; r < _confusionMatrix!.length; r++) {
        for (int c = 0; c < _confusionMatrix![r].length; c++) {
          trueTotals[r] += _confusionMatrix![r][c];
        }
      }

      List<Map<String, dynamic>> mistakesList = [];
      for (int r = 0; r < _confusionMatrix!.length; r++) {
        for (int c = 0; c < _confusionMatrix![r].length; c++) {
          if (r != c && _confusionMatrix![r][c] > 0) {
            mistakesList.add({
              'true': _matrixLabels.length > r
                  ? _matrixLabels[r]
                  : r.toString(),
              'pred': _matrixLabels.length > c
                  ? _matrixLabels[c]
                  : c.toString(),
              'count': _confusionMatrix![r][c],
              'total': trueTotals[r],
            });
          }
        }
      }
      mistakesList.sort(
        (a, b) => (b['count'] as int).compareTo(a['count'] as int),
      );
      for (int i = 0; i < mistakesList.length && i < 3; i++) {
        topMistakes.add(
          "Predicted '${mistakesList[i]['pred']}' but true is '${mistakesList[i]['true']}' (${mistakesList[i]['count']} errors / Total ${mistakesList[i]['total']})",
        );
      }
    }
    String modeName = state.proj.mode == 0
        ? "Numeric Prediction"
        : "Classification";
    if (_confusionMatrix != null) modeName = "Classification";

    String finalScoreLabel = "Status";
    String finalScoreVal = "Trained";
    if (_fScore != null) {
      finalScoreLabel = "Validation F-score";
      finalScoreVal = "${(_fScore! * 100).toStringAsFixed(1)}%";
    } else if (_r2Score != null) {
      finalScoreLabel = "Validation R² Score";
      finalScoreVal = _r2Score!.toStringAsFixed(3);
    } else if (_currentAccuracy != null) {
      finalScoreLabel = "Validation Accuracy";
      finalScoreVal = "${(_currentAccuracy! * 100).toStringAsFixed(1)}%";
    }

    List<String> inFeatures = state.proj.inputDefs.map((e) => e.name).toList();
    List<String> outFeatures = state.proj.outputDefs
        .map((e) => e.name)
        .toList();

    String optimizerInfo = state.proj.engineType == 0
        ? (state.nn?.optimizerType.name.toUpperCase() ?? "SGD")
        : "Random Forest";
    String lossFuncInfo = state.proj.lossType == 0
        ? "MSE"
        : (state.proj.engineType == 0 ? "Cross Entropy" : "Gini Impurity");
    String actInfo = state.proj.engineType == 0
        ? (state.nn?.hiddenActivation.name.toUpperCase() ?? "RELU")
        : "Decision Trees";
    int bSize = state.proj.engineType == 0
        ? (state.nn?.batchSize ?? 8)
        : state.proj.rf_trees;

    String tLossFinal = state.trainLossHistory.isNotEmpty
        ? state.trainLossHistory.last.toStringAsFixed(4)
        : "-";
    String vLossFinal = state.valLossHistory.isNotEmpty
        ? state.valLossHistory.last.toStringAsFixed(4)
        : "-";

    // =========================================================
    // ★修正：NNとRFでFeature Importanceの取得元を分ける
    // =========================================================
    Map<String, double> importanceMap = {};

    if (state.proj.engineType == 0 && _sensitivityResults != null) {
      // 【NNの場合】直前で実行した感度分析の結果をそのまま使う
      importanceMap = Map<String, double>.from(_sensitivityResults!);
    } else if (state.proj.engineType == 1 &&
        state.proj.feature_importances != null) {
      // 【RFの場合】配列をカテゴリ変数ごとに合算して使う
      int ptr = 0;
      for (int i = 0; i < state.proj.inputDefs.length; i++) {
        var def = state.proj.inputDefs[i];

        bool isMasked =
            state.inputMask.isNotEmpty &&
            state.inputMask.length == state.proj.inputDefs.length &&
            !state.inputMask[i];

        double combinedImportance = 0.0;

        // ★変更：マスクされていない場合のみ配列から読み取る
        if (!isMasked) {
          if (def.type == 1) {
            for (int c = 0; c < def.categories.length; c++) {
              if (ptr < state.proj.feature_importances!.length) {
                combinedImportance += state.proj.feature_importances![ptr];
              }
              ptr++;
            }
          } else {
            if (ptr < state.proj.feature_importances!.length) {
              combinedImportance += state.proj.feature_importances![ptr];
            }
            ptr++;
          }
          importanceMap[def.name] = combinedImportance;
        }
      }
    }

    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed < 2000) {
      await Future.delayed(Duration(milliseconds: 2000 - elapsed));
    }

    // ★変更：PDF生成前に、RFなら【全て】の決定木の画像データを作成する
    List<Uint8List>? rfTreeImages;
    if (state.proj.engineType == 1) {
      rfTreeImages = await _generateAllTreeImageBytes(state);
    }

    await PdfReportGenerator.generateAndShowPdf(
      engineType: state.proj.engineType,
      projectModeName: modeName,
      layerSizes: state.nn?.layerSizes.join(' -> ') ?? "",
      targetEpochs: state.proj.engineType == 0 ? state.targetEpochs : 1,
      dataCount: state.proj.data.length,
      inputFeatures: inFeatures,
      outputFeatures: outFeatures,
      optimizerType: optimizerInfo,
      learningRate: state.proj.engineType == 0
          ? (state.nn?.learningRate ?? 0.0)
          : 0.0,
      lossFunction: lossFuncInfo,
      hiddenActivation: actInfo,
      batchSize: bSize,
      rfTrees: state.proj.rf_trees,
      rfDepth: state.proj.rf_depth,
      finalTrainLoss: tLossFinal,
      finalValLoss: vLossFinal,
      finalScoreLabel: finalScoreLabel,
      finalScoreValue: finalScoreVal,
      lossImageBytes: lossBytes,
      scatterImageBytes: scatterBytes,
      treeImagesBytes: rfTreeImages, // ★変更：複数形(s付き)にし、リストを渡す
      topMistakes: topMistakes,
      featureImportance: importanceMap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProjectState>();
    final double scale = ScaleUtil.scale(context);
    final l10n = AppLocalizations.of(context)!;

    if (_tempInputMask.length != state.proj.inputDefs.length) {
      if (state.inputMask.isNotEmpty &&
          state.inputMask.length == state.proj.inputDefs.length) {
        _tempInputMask = List.from(state.inputMask);
      } else {
        _tempInputMask = List.filled(state.proj.inputDefs.length, true);
      }
    }

    return ListView(
      padding: EdgeInsets.symmetric(vertical: 8.0 * scale),
      children: [
        // === 1. 設定エリア（スライダー・リセット） ===
        AbsorbPointer(
          absorbing: state.isTraining || _isAnalyzing,
          child: Opacity(
            opacity: (state.isTraining || _isAnalyzing) ? 0.3 : 1.0,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0 * scale),
              child: Column(
                children: [
                  if (state.proj.engineType == 0)
                    Row(
                      children: [
                        Text(
                          l10n.additionalEpochs,
                          style: TextStyle(fontSize: 14 * scale),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 18.0 * scale,
                            ),
                            child: Slider(
                              value: state.targetEpochs.toDouble().clamp(
                                1.0,
                                5000.0,
                              ),
                              min: 1,
                              max: 5000,
                              onChanged: (v) {
                                state.setTargetEpochs(v.toInt());
                                _epochCtrl.text = v.toInt().toString();
                              },
                              activeColor: Colors.cyanAccent,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 60 * scale,
                          child: TextField(
                            controller: _epochCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 14 * scale),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 8 * scale,
                                horizontal: 4 * scale,
                              ),
                            ),
                            onChanged: (v) {
                              int? val = int.tryParse(v);
                              if (val != null && val > 0) {
                                state.setTargetEpochs(val);
                              }
                            },
                          ),
                        ),
                      ],
                    )
                  else
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 18.0 * scale),
                      child: Row(
                        children: [
                          Icon(
                            Icons.park,
                            color: Colors.lightGreenAccent,
                            size: 18 * scale,
                          ),
                          SizedBox(width: 8 * scale),
                          Expanded(
                            child: Text(
                              ui
                                          .PlatformDispatcher
                                          .instance
                                          .locale
                                          .languageCode !=
                                      'ja'
                                  ? "Random Forest trains all at once (1 Epoch)."
                                  : "ランダムフォレストは一括で学習します（1 Epoch）。",
                              style: TextStyle(
                                color: Colors.lightGreenAccent,
                                fontSize: 12 * scale,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16 * scale,
                          vertical: 8 * scale,
                        ),
                      ),
                      onPressed: (state.nn == null && state.rf == null)
                          ? null
                          : () {
                              _showResetDialog(context, state, scale, l10n);
                            },
                      icon: Icon(
                        Icons.delete_forever,
                        color: Colors.redAccent,
                        size: 16 * scale,
                      ),
                      label: Text(
                        l10n.btnResetBrain,
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12 * scale,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        SizedBox(height: 12 * scale),

        // === 2. 開始・停止ボタン ===
        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: state.isTraining
                  ? Colors.red
                  : Colors.green.shade900,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 40 * scale,
                vertical: 16 * scale,
              ),
              elevation: 8,
              shadowColor: Colors.greenAccent.withOpacity(0.4),
            ),
            onPressed:
                (state.proj.data.isEmpty ||
                    _isAnalyzing ||
                    (state.proj.engineType == 1 && state.rf != null))
                ? null
                : () {
                    if (state.isTraining) {
                      state.stopRequested = true;
                    } else {
                      setState(() {
                        _sensitivityResults = null;
                        _currentAccuracy = null;
                        _fScore = null;
                        _r2Score = null;
                        _confusionMatrix = null;
                        _scatterPoints = null;
                      });
                      state.startTraining();
                    }
                  },
            child: Text(
              _isAnalyzing
                  ? l10n.btnAnalyzing
                  : (state.isTraining
                        ? l10n.btnForceStop
                        : ((state.proj.engineType == 0 && state.nn != null)
                              ? l10n.btnResumeTraining
                              : l10n.btnStartTraining)),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16 * scale,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),

        // === 3. 警告文 ===
        if (state.isTraining)
          Padding(
            padding: EdgeInsets.all(8.0 * scale),
            child: Center(
              child: Text(
                l10n.warnKeepScreen,
                style: TextStyle(color: Colors.orange, fontSize: 10 * scale),
              ),
            ),
          ),

        SizedBox(height: 12 * scale),

        // === 4. 誤差グラフ & 精度評価エリア ===
        if (state.trainLossHistory.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0 * scale),
            child: Column(
              children: [
                if (state.proj.mode < 1)
                  Container(
                    margin: EdgeInsets.only(bottom: 8.0 * scale),
                    child: _currentAccuracy == null && _scatterPoints == null
                        ? ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey.shade900,
                              foregroundColor: Colors.greenAccent,
                              side: BorderSide(
                                color: Colors.greenAccent.withOpacity(0.5),
                              ),
                            ),
                            onPressed: (state.isTraining || _isCalcingAcc)
                                ? null
                                : () => _runDetailedEvaluation(state),
                            icon: _isCalcingAcc
                                ? SizedBox(
                                    width: 16 * scale,
                                    height: 16 * scale,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.greenAccent,
                                    ),
                                  )
                                : Icon(Icons.assessment, size: 18 * scale),
                            label: Text(
                              state.isTraining
                                  ? l10n.btnAnalysisPending
                                  : l10n.btnDetailedAnalysis,
                              style: TextStyle(fontSize: 12 * scale),
                            ),
                          )
                        : Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 6 * scale,
                              horizontal: 12 * scale,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              border: Border.all(color: Colors.greenAccent),
                              borderRadius: BorderRadius.circular(20 * scale),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.greenAccent,
                                  size: 18 * scale,
                                ),
                                SizedBox(width: 8 * scale),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _fScore != null
                                          ? "F-score: ${(_fScore! * 100).toStringAsFixed(1)}%"
                                          : _r2Score != null
                                          ? "R² Score: ${_r2Score!.toStringAsFixed(3)}"
                                          : _scatterPoints != null
                                          ? l10n.analysisComplete
                                          : l10n.accuracyResult(
                                              (_currentAccuracy! * 100)
                                                  .toStringAsFixed(1),
                                            ),
                                      style: TextStyle(
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15 * scale,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8 * scale),
                                IconButton(
                                  constraints: BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  tooltip: l10n.tooltipShowDetailedChart,
                                  icon: Icon(
                                    Icons.bar_chart,
                                    color:
                                        (_confusionMatrix == null &&
                                            _scatterPoints == null)
                                        ? Colors.white
                                        : Colors.white30,
                                    size: 20 * scale,
                                  ),
                                  onPressed: (state.isTraining || _isCalcingAcc)
                                      ? null
                                      : () => _runDetailedEvaluation(state),
                                ),
                                SizedBox(width: 8 * scale),
                                IconButton(
                                  constraints: BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  tooltip: l10n.tooltipRemesure,
                                  icon: Icon(
                                    Icons.refresh,
                                    color: Colors.white54,
                                    size: 18 * scale,
                                  ),
                                  onPressed: (state.isTraining || _isCalcingAcc)
                                      ? null
                                      : () => _runDetailedEvaluation(state),
                                ),
                              ],
                            ),
                          ),
                  ),
                if (state.proj.engineType == 0)
                  Container(
                    height: 140 * scale,
                    padding: EdgeInsets.all(8 * scale),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.grey.shade800),
                      borderRadius: BorderRadius.circular(8 * scale),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _legendItem(
                              Colors.blue,
                              l10n.legendTrainLoss,
                              scale,
                            ),
                            SizedBox(width: 16 * scale),
                            if (state.proj.mode < 1)
                              _legendItem(
                                Colors.orange,
                                l10n.legendValLoss,
                                scale,
                              ),
                          ],
                        ),
                        Expanded(
                          child: CustomPaint(
                            size: const Size(double.infinity, double.infinity),
                            painter: LossChartPainter(
                              state.trainLossHistory,
                              state.proj.mode == 0
                                  ? state.valLossHistory
                                  : state.trainLossHistory,
                              scale,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 16 * scale),

          // === 混同行列 or 散布図の表示エリア ===
          if (_confusionMatrix != null || _scatterPoints != null)
            _buildDetailedAnalysisView(scale, l10n),
        ],

        // === 5. モニターエリア ===
        if (state.proj.engineType == 0)
          Container(
            height: _showHeatmap ? 380 * scale : 200 * scale,
            margin: EdgeInsets.symmetric(horizontal: 32.0 * scale),
            decoration: BoxDecoration(
              color: Colors.black87,
              border: Border.all(
                color: _showHeatmap ? Colors.greenAccent : Colors.grey.shade800,
                width: _showHeatmap ? 2.0 : 1.0,
              ),
              borderRadius: BorderRadius.circular(8 * scale),
              boxShadow: _showHeatmap
                  ? [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12 * scale,
                    vertical: 4 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(6 * scale),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _showHeatmap ? Icons.grid_4x4 : Icons.terminal,
                        color: _showHeatmap ? Colors.greenAccent : Colors.grey,
                        size: 16 * scale,
                      ),
                      SizedBox(width: 8 * scale),
                      Expanded(
                        child: Text(
                          _showHeatmap
                              ? l10n.terminalTitleHeatmap
                              : l10n.terminalTitleLog,
                          style: TextStyle(
                            color: _showHeatmap
                                ? Colors.greenAccent
                                : Colors.grey,
                            fontSize: 12 * scale,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      // ★ 修正：右側の情報部分を Flexible で包み、はみ出しを防ぐ
                      if (state.proj.engineType == 0 && state.nn != null)
                        Flexible(
                          child: Padding(
                            padding: EdgeInsets.only(left: 8.0 * scale),
                            child: Text(
                              state.nn!.layerSizes.join('-'),
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11 * scale,
                                fontFamily: 'monospace',
                              ),
                              textAlign: TextAlign.right, // 右寄せにして見栄えを良くする
                              overflow:
                                  TextOverflow.ellipsis, // はみ出した場合は '...' にする
                              maxLines: 1, // 1行に収める
                            ),
                          ),
                        )
                      else if (state.proj.engineType == 1 && state.rf != null)
                        Flexible(
                          child: Padding(
                            padding: EdgeInsets.only(left: 8.0 * scale),
                            child: Text(
                              "RF (T:${state.proj.rf_trees} D:${state.proj.rf_depth})",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11 * scale,
                                fontFamily: 'monospace',
                              ),
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.black,
                    width: double.infinity,
                    child: _showHeatmap
                        ? _buildHeatmapView(state, scale, l10n)
                        : _buildLogView(state, scale),
                  ),
                ),
                if (_showHeatmap)
                  Container(
                    padding: EdgeInsets.all(8 * scale),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey.shade800,
                          width: 1.0,
                        ),
                      ),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(6 * scale),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildColorLegend(
                              Colors.blue,
                              l10n.heatmapLegendSuppress,
                              scale,
                            ),
                            _buildColorLegend(
                              Colors.black,
                              l10n.heatmapLegendZero,
                              scale,
                            ),
                            _buildColorLegend(
                              Colors.red,
                              l10n.heatmapLegendExcite,
                              scale,
                            ),
                            _buildColorLegend(
                              Colors.yellow,
                              l10n.heatmapLegendIntense,
                              scale,
                            ),
                          ],
                        ),
                        SizedBox(height: 6 * scale),
                        Text(
                          l10n.heatmapWarnSlow,
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 9 * scale,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

        // === ★ NN感度分析 or RF特徴量重要度の表示 ===
        if (state.proj.engineType == 0 &&
            state.nn != null &&
            state.proj.mode < 2) ...[
          SizedBox(height: 16 * scale),
          _buildSensitivityAnalysisUI(state, scale, l10n),
        ] else if (state.proj.engineType == 1 &&
            state.proj.feature_importances != null) ...[
          SizedBox(height: 16 * scale),
          _buildFeatureImportanceUI(state, scale, l10n),
        ],

        // === アブレーション分析用入力セレクタ ===
        if (!state.isTraining &&
            state.proj.data.isNotEmpty &&
            state.proj.mode < 1) ...[
          SizedBox(height: 16 * scale),
          _buildInputSelector(state, scale, l10n),
        ],

        // === PDF出力ボタン ===
        if ((state.nn != null || state.rf != null) && state.proj.mode < 1) ...[
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16.0 * scale,
              vertical: 8.0 * scale,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 80 * scale,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12 * scale),
                  ),
                ),
                // ★修正のキモ：
                // 1. 学習中や計算中なら押せない
                // 2. 詳細評価が終わっていない（メモリにF値などがない）なら押せない
                onPressed:
                    (state.isTraining ||
                        _isCalcingAcc ||
                        _isAnalyzing ||
                        (_currentAccuracy == null && _scatterPoints == null))
                    ? null
                    : () => _exportPdfReport(state, scale),
                icon: Icon(Icons.picture_as_pdf, size: 24 * scale),
                label: Text(
                  // 💡 もし可能なら、グレーアウトしている理由をテキストで伝えるのも親切です
                  (_currentAccuracy == null && _scatterPoints == null)
                      ? "Run Analysis to Export PDF" // 分析を実行してからエクスポートしてね
                      : "Export Analysis Report (PDF)",
                  style: TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 40 * scale),
        ],
      ],
    );
  }

  Widget _buildDetailedAnalysisView(double scale, AppLocalizations l10n) {
    bool isClassification = _confusionMatrix != null;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0 * scale),
      child: Container(
        margin: EdgeInsets.only(bottom: 16 * scale),
        padding: EdgeInsets.all(12 * scale),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(8 * scale),
          border: Border.all(
            color: isClassification ? Colors.cyanAccent : Colors.amberAccent,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Wrap(
              children: [
                Icon(
                  isClassification ? Icons.grid_view : Icons.scatter_plot,
                  color: isClassification
                      ? Colors.cyanAccent
                      : Colors.amberAccent,
                  size: 20 * scale,
                ),
                SizedBox(width: 8 * scale),
                Text(
                  isClassification
                      ? l10n.confusionMatrixTitle
                      : l10n.scatterPlotTitle,
                  style: TextStyle(
                    color: isClassification
                        ? Colors.cyanAccent
                        : Colors.amberAccent,
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8 * scale),

            // F値またはR2スコアの強調表示
            if (isClassification && _fScore != null)
              Container(
                margin: EdgeInsets.symmetric(vertical: 8 * scale),
                padding: EdgeInsets.symmetric(
                  vertical: 8 * scale,
                  horizontal: 16 * scale,
                ),
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
                child: Column(
                  children: [
                    Text(
                      "F-score (Macro Avg)",
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 11 * scale,
                      ),
                    ),
                    Text(
                      "${(_fScore! * 100).toStringAsFixed(2)}%",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24 * scale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else if (!isClassification && _r2Score != null)
              Container(
                margin: EdgeInsets.symmetric(vertical: 8 * scale),
                padding: EdgeInsets.symmetric(
                  vertical: 8 * scale,
                  horizontal: 16 * scale,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
                child: Column(
                  children: [
                    Text(
                      "R² Score (Coefficient of Determination)",
                      style: TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 11 * scale,
                      ),
                    ),
                    Text(
                      _r2Score!.toStringAsFixed(4),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24 * scale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            Text(
              isClassification
                  ? l10n.confusionMatrixDesc
                  : l10n.scatterPlotDesc,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12 * scale,
                height: 1.4,
              ),
            ),
            SizedBox(height: 8 * scale),

            Text(
              l10n.tapToExpandHint,
              style: TextStyle(color: Colors.cyanAccent, fontSize: 11 * scale),
            ),
            SizedBox(height: 12 * scale),

            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DetailedChartScreen(
                      confusionMatrix: _confusionMatrix,
                      matrixLabels: _matrixLabels,
                      scatterPoints: _scatterPoints,
                    ),
                  ),
                );
              },
              child: Container(
                color: Colors.transparent,
                child: IgnorePointer(
                  child: isClassification
                      ? _buildConfusionMatrixWidget(scale, l10n)
                      : _buildScatterPlotWidget(scale),
                ),
              ),
            ),

            SizedBox(height: 8 * scale),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _confusionMatrix = null;
                    _scatterPoints = null;
                  });
                },
                child: Text(
                  l10n.btnClose,
                  style: TextStyle(color: Colors.grey, fontSize: 12 * scale),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfusionMatrixWidget(double scale, AppLocalizations l10n) {
    if (_confusionMatrix == null) return SizedBox();

    final double cellSize = 40.0 * scale;
    final int size = _confusionMatrix!.length;
    final double labelWidth = 60.0 * scale;
    final double labelHeight = 30.0 * scale;
    final double totalWidth = labelWidth + (size * cellSize);
    final double totalHeight = labelHeight + (size * cellSize);

    return Container(
      height: 300 * scale,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.white24),
      ),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: totalWidth,
          minHeight: totalHeight,
          maxWidth: totalWidth,
          maxHeight: totalHeight,
          child: CustomPaint(
            painter: ConfusionMatrixPainter(
              _confusionMatrix!,
              _matrixLabels,
              cellSize,
              labelWidth,
              labelHeight,
              scale,
              l10n,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScatterPlotWidget(double scale) {
    return Container(
      height: 200 * scale,
      width: double.infinity,
      color: Colors.black,
      child: CustomPaint(painter: ScatterPlotPainter(_scatterPoints!, scale)),
    );
  }

  Widget _buildInputSelector(
    ProjectState state,
    double scale,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.0 * scale),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border.all(color: Colors.grey.shade800),
        borderRadius: BorderRadius.circular(8 * scale),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(Icons.tune, color: Colors.cyanAccent, size: 20 * scale),
            SizedBox(width: 8 * scale),
            Text(
              l10n.inputSelectionTitle,
              style: TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
                fontSize: 14 * scale,
              ),
            ),
          ],
        ),
        initiallyExpanded: false,
        collapsedIconColor: Colors.grey,
        iconColor: Colors.cyanAccent,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16.0 * scale,
              vertical: 8.0 * scale,
            ),
            child: Text(
              l10n.inputSelectionDesc,
              style: TextStyle(color: Colors.white, fontSize: 12 * scale),
            ),
          ),
          for (int i = 0; i < state.proj.inputDefs.length; i++)
            SwitchListTile(
              dense: true,
              activeColor: Colors.cyanAccent,
              title: Text(
                state.proj.inputDefs[i].name,
                style: TextStyle(fontSize: 13 * scale, color: Colors.white),
              ),
              value: _tempInputMask.length > i ? _tempInputMask[i] : true,
              onChanged: (val) {
                setState(() {
                  if (_tempInputMask.length > i) {
                    _tempInputMask[i] = val;
                  }
                });
              },
            ),
          SizedBox(height: 8 * scale),
          Padding(
            padding: EdgeInsets.only(
              bottom: 12.0 * scale,
              left: 16 * scale,
              right: 16 * scale,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan.shade900,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12 * scale),
                  side: BorderSide(color: Colors.cyanAccent.withOpacity(0.5)),
                ),
                onPressed: () {
                  if (!_tempInputMask.contains(true)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.errorSelectAtLeastOne)),
                    );
                    return;
                  }

                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(
                        l10n.applyChangesTitle,
                        style: TextStyle(fontSize: 18 * scale),
                      ),
                      content: Text(
                        l10n.applyChangesDesc,
                        style: TextStyle(fontSize: 14 * scale),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            l10n.btnCancel,
                            style: TextStyle(
                              fontSize: 16 * scale,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            state.updateInputMask(_tempInputMask);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.msgStructureChanged),
                                backgroundColor: Colors.cyan.shade800,
                              ),
                            );
                          },
                          child: Text(
                            l10n.btnResetAndApply,
                            style: TextStyle(
                              fontSize: 16 * scale,
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                icon: Icon(Icons.refresh, size: 18 * scale),
                label: Text(
                  l10n.btnApplyStructureAndReset,
                  style: TextStyle(fontSize: 14 * scale),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runDetailedEvaluation(ProjectState state) async {
    if (_isCalcingAcc || (state.nn == null && state.rf == null)) return;

    setState(() {
      _isCalcingAcc = true;
      _confusionMatrix = null;
      _scatterPoints = null;
      _fScore = null;
      _r2Score = null;
    });

    await Future.delayed(const Duration(milliseconds: 50));

    try {
      List<TrainingData> targetData = state.validationData;

      if (targetData.isEmpty) {
        final data = state.proj.data;
        if (data.isEmpty) {
          setState(() => _isCalcingAcc = false);
          return;
        }
        int valSize = (data.length * 0.2).ceil();
        targetData = data.sublist(data.length - valSize);
      }

      // NNの200件上限を撤廃し、検証用データを全件使用する
      List<TrainingData> calcData = List.from(targetData);

      int classOutputIndex = state.proj.outputDefs.indexWhere(
        (d) => d.type == 1,
      );
      bool isClassification = classOutputIndex != -1 || state.proj.mode == 1;

      int correctCount = 0;
      int totalCount = 0;

      List<List<int>>? tempMatrix;
      if (isClassification) {
        List<String> categories = [];
        if (state.proj.mode == 1) {
          categories = state.proj.currentChars.split('');
        } else {
          categories = state.proj.outputDefs[classOutputIndex].categories;
        }
        _matrixLabels = categories;
        int catSize = categories.length;
        if (catSize > 0) {
          tempMatrix = List.generate(catSize, (_) => List.filled(catSize, 0));
        }
      }

      List<Offset> tempPoints = [];

      // --- フリーズ・発熱対策用の変数 ---
      final coolDownTimer = Stopwatch()..start();
      final yieldTimer = Stopwatch()..start();
      const int ecoWaitMs = 50; // 発熱対策の休止時間(ms)

      for (var d in calcData) {
        List<double> x = state.encodeData(d.inputs, state.proj.inputDefs);
        List<double> yEncoded = state.encodeData(
          d.outputs,
          state.proj.outputDefs,
        );

        List<double> pred;
        if (state.proj.engineType == 0 && state.nn != null) {
          pred = state.nn!.predict(x);
        } else if (state.proj.engineType == 1 && state.rf != null) {
          pred = state.rf!.predict(x).finalOutput;
        } else {
          continue;
        }

        if (pred.isEmpty || yEncoded.isEmpty) continue;

        if (isClassification && tempMatrix != null) {
          int catLen = _matrixLabels.length;
          int startIdx = 0;
          if (state.proj.mode < 1) {
            for (int i = 0; i < classOutputIndex; i++) {
              var def = state.proj.outputDefs[i];
              startIdx += (def.type == 1) ? def.categories.length : 1;
            }
          }

          if (startIdx + catLen <= pred.length &&
              startIdx + catLen <= yEncoded.length) {
            int predIdx = 0;
            double maxP = -999.0;
            for (int k = 0; k < catLen; k++) {
              if (pred[startIdx + k] > maxP) {
                maxP = pred[startIdx + k];
                predIdx = k;
              }
            }

            int trueIdx = 0;
            double maxT = -999.0;
            for (int k = 0; k < catLen; k++) {
              if (yEncoded[startIdx + k] > maxT) {
                maxT = yEncoded[startIdx + k];
                trueIdx = k;
              }
            }

            tempMatrix[trueIdx][predIdx]++;
            if (trueIdx == predIdx) correctCount++;
          }
          totalCount++;
        } else {
          double truth = yEncoded[0];
          double prediction = pred[0];
          tempPoints.add(Offset(truth, prediction));
        }

        // --- フリーズ回避 ＆ 発熱対策の息継ぎ ---
        if (coolDownTimer.elapsedMilliseconds > 500) {
          await Future.delayed(const Duration(milliseconds: ecoWaitMs));
          coolDownTimer.reset();
          yieldTimer.reset();
        } else if (yieldTimer.elapsedMilliseconds > 14) {
          await Future.delayed(Duration.zero);
          yieldTimer.reset();
        }
      }

      // 分析指標の算出（F値、R2）
      double? calcFScore;
      double? calcR2;

      if (isClassification && tempMatrix != null) {
        int nClass = tempMatrix.length;
        double sumF = 0.0;
        int validClasses = 0;

        for (int i = 0; i < nClass; i++) {
          int tp = tempMatrix[i][i];
          int fp = 0;
          int fn = 0;
          for (int j = 0; j < nClass; j++) {
            if (i != j) {
              fp += tempMatrix[j][i];
              fn += tempMatrix[i][j];
            }
          }
          if (tp + fp + fn > 0) {
            double precision = (tp + fp) == 0 ? 0 : tp / (tp + fp);
            double recall = (tp + fn) == 0 ? 0 : tp / (tp + fn);
            if (precision + recall > 0) {
              sumF += 2 * (precision * recall) / (precision + recall);
            }
            validClasses++;
          }
        }
        if (validClasses > 0) calcFScore = sumF / validClasses;
      } else if (!isClassification && tempPoints.isNotEmpty) {
        double yMean =
            tempPoints.map((p) => p.dx).reduce((a, b) => a + b) /
            tempPoints.length;
        double ssTot = 0.0;
        double ssRes = 0.0;
        for (var p in tempPoints) {
          ssTot += pow(p.dx - yMean, 2);
          ssRes += pow(p.dx - p.dy, 2);
        }
        calcR2 = ssTot == 0 ? 0.0 : 1.0 - (ssRes / ssTot);
      }

      if (mounted) {
        setState(() {
          if (isClassification) {
            _currentAccuracy = totalCount > 0 ? correctCount / totalCount : 0.0;
            _fScore = calcFScore;
            _confusionMatrix = tempMatrix;
          } else {
            _currentAccuracy = null;
            _r2Score = calcR2;
            _scatterPoints = tempPoints;
          }
        });
      }
    } catch (e) {
      debugPrint("Evaluation Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isCalcingAcc = false);
      }
    }
  }

  // ★NN専用の感度分析UI
  Widget _buildSensitivityAnalysisUI(
    ProjectState state,
    double scale,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: Colors.orangeAccent,
                size: 16 * scale,
              ),
              SizedBox(width: 6 * scale),
              Expanded(
                child: Text(
                  l10n.permutationImportanceTitle,
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * scale),
          Container(
            padding: EdgeInsets.all(12 * scale),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(8 * scale),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: _isAnalyzing
                ? Column(
                    children: [
                      CircularProgressIndicator(
                        color: Colors.orangeAccent,
                        value: _progress > 0 ? _progress : null,
                      ),
                      SizedBox(height: 8 * scale),
                      const Text(
                        "Analyzing... Please do not close the screen.",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  )
                : (_sensitivityResults == null)
                ? SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade800,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12 * scale),
                      ),
                      onPressed: () => _runSensitivityAnalysis(state),
                      icon: Icon(Icons.analytics, size: 20 * scale),
                      label: Text(
                        l10n.btnRunDetailedAnalysis,
                        style: TextStyle(fontSize: 14 * scale),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Text(
                        l10n.permutationImportanceDesc,
                        style: TextStyle(
                          fontSize: 11 * scale,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 12 * scale),
                      _buildSensitivityGraph(state, scale),
                      SizedBox(height: 12 * scale),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade800,
                            padding: EdgeInsets.symmetric(vertical: 12 * scale),
                          ),
                          onPressed: () {
                            setState(() {
                              _sensitivityResults = null;
                            });
                          },
                          child: Text(
                            l10n.btnClose,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14 * scale,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ★追加：RF専用の特徴量重要度UI
  Widget _buildFeatureImportanceUI(
    ProjectState state,
    double scale,
    AppLocalizations l10n,
  ) {
    if (state.proj.feature_importances == null) return const SizedBox.shrink();

    // グラフ描画用にデータを構築
    List<MapEntry<String, double>> entries = [];
    int ptr = 0;

    for (int i = 0; i < state.proj.inputDefs.length; i++) {
      var def = state.proj.inputDefs[i];

      // ★追加：変数がマスクされているかチェック
      bool isMasked =
          state.inputMask.isNotEmpty &&
          state.inputMask.length == state.proj.inputDefs.length &&
          !state.inputMask[i];

      double combinedImportance = 0.0;

      // ★変更：マスクされていない（有効な）変数のみ、RFの配列から値を取り出す
      if (!isMasked) {
        if (def.type == 1) {
          for (int c = 0; c < def.categories.length; c++) {
            if (ptr < state.proj.feature_importances!.length) {
              combinedImportance += state.proj.feature_importances![ptr];
            }
            ptr++; // 有効な場合のみポインタを進める
          }
        } else {
          if (ptr < state.proj.feature_importances!.length) {
            combinedImportance += state.proj.feature_importances![ptr];
          }
          ptr++; // 有効な場合のみポインタを進める
        }

        // グラフのエントリに追加
        entries.add(MapEntry(def.name, combinedImportance));
      }
    }
    entries.sort((a, b) => b.value.compareTo(a.value));

    double maxVal = 0.0;
    for (var e in entries) if (e.value > maxVal) maxVal = e.value;
    if (maxVal == 0) maxVal = 1.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.park,
                color: Colors.lightGreenAccent,
                size: 16 * scale,
              ),
              SizedBox(width: 6 * scale),
              Expanded(
                child: Text(
                  "RF Feature Importance",
                  style: TextStyle(
                    color: Colors.lightGreenAccent,
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * scale),
          Container(
            padding: EdgeInsets.all(12 * scale),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(8 * scale),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: Column(
              children: [
                Text(
                  "Gini Importance (Which features were most useful for splits)",
                  style: TextStyle(fontSize: 11 * scale, color: Colors.grey),
                ),
                SizedBox(height: 12 * scale),
                Column(
                  children: [
                    for (var entry in entries)
                      _buildBarRow(
                        entry.key,
                        entry.value,
                        maxVal,
                        scale,
                        Colors.lightGreenAccent,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runSensitivityAnalysis(ProjectState state) async {
    if (state.nn == null || state.proj.data.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _progress = 0.0;
    });

    await Future.delayed(Duration(milliseconds: 100));

    try {
      final data = state.proj.data;
      final inputDefs = state.proj.inputDefs;

      int sampleSize = data.length > 500 ? 500 : data.length;
      List<int> sampleIndices = List.generate(sampleSize, (i) => i);
      if (data.length > 500) sampleIndices.shuffle();

      List<TrainingData> sampleData = [];
      for (int i = 0; i < sampleSize; i++) {
        sampleData.add(
          data[sampleIndices[i] < data.length ? sampleIndices[i] : i],
        );
      }

      double baselineLoss = await _calculateLossAsync(state, sampleData);
      Map<String, double> importanceMap = {};

      for (int i = 0; i < inputDefs.length; i++) {
        setState(() {
          _progress = (i / inputDefs.length);
        });
        await Future.delayed(Duration(milliseconds: 10));

        if (state.inputMask.isNotEmpty &&
            state.inputMask.length == inputDefs.length &&
            !state.inputMask[i]) {
          continue;
        }

        FeatureDef targetDef = inputDefs[i];
        List<TrainingData> shuffledData = [];
        List<double> columnValues = sampleData.map((d) => d.inputs[i]).toList();
        columnValues.shuffle(Random());

        for (int j = 0; j < sampleSize; j++) {
          List<double> newInputs = List.from(sampleData[j].inputs);
          newInputs[i] = columnValues[j];
          shuffledData.add(
            TrainingData(inputs: newInputs, outputs: sampleData[j].outputs),
          );
        }

        double shuffledLoss = await _calculateLossAsync(state, shuffledData);
        double importance = shuffledLoss - baselineLoss;
        if (importance < 0) importance = 0;

        importanceMap[targetDef.name] = importance;
      }

      setState(() {
        _sensitivityResults = importanceMap;
        _isAnalyzing = false;
        _progress = 1.0;
      });
    } catch (e) {
      debugPrint("分析エラー: $e");
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<double> _calculateLossAsync(
    ProjectState state,
    List<TrainingData> data,
  ) async {
    final nn = state.nn!;
    double totalLoss = 0.0;
    int chunkSize = 50;

    for (int i = 0; i < data.length; i += chunkSize) {
      int end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      for (int j = i; j < end; j++) {
        List<double> x = state.encodeData(data[j].inputs, state.proj.inputDefs);
        List<double> y = state.encodeData(
          data[j].outputs,
          state.proj.outputDefs,
        );
        List<double> pred = nn.predict(x);
        for (int k = 0; k < pred.length; k++) {
          if (nn.lossType == 1) {
            totalLoss += -y[k] * log(pred[k] + 1e-7);
          } else {
            totalLoss += pow(y[k] - pred[k], 2);
          }
        }
      }
      await Future.delayed(Duration.zero);
    }
    return totalLoss / data.length;
  }

  Widget _buildSensitivityGraph(ProjectState state, double scale) {
    if (_sensitivityResults == null) return const SizedBox.shrink();
    var entries = _sensitivityResults!.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    double maxVal = 0.0;
    for (var e in entries) if (e.value > maxVal) maxVal = e.value;
    if (maxVal == 0) maxVal = 1.0;

    return Column(
      children: [
        for (var entry in entries)
          _buildBarRow(
            entry.key,
            entry.value,
            maxVal,
            scale,
            Colors.orangeAccent,
          ),
      ],
    );
  }

  Widget _buildBarRow(
    String label,
    double value,
    double maxVal,
    double scale,
    Color barColor,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0 * scale),
      child: Row(
        children: [
          SizedBox(
            width: 140 * scale,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: TextStyle(fontSize: 11 * scale, color: Colors.white70),
              ),
            ),
          ),
          SizedBox(width: 8 * scale),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 8 * scale,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(4 * scale),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: (value / maxVal).clamp(0.0, 1.0),
                  child: Container(
                    height: 8 * scale,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        barColor.withOpacity(0.5),
                        barColor,
                        (value / maxVal),
                      ),
                      borderRadius: BorderRadius.circular(4 * scale),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8 * scale),
          SizedBox(
            width: 30 * scale,
            child: Text(
              (value / maxVal * 100).toStringAsFixed(0),
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 10 * scale, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorLegend(Color color, String label, double scale) {
    return Row(
      children: [
        Container(
          width: 12 * scale,
          height: 12 * scale,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey.shade700, width: 0.5),
          ),
        ),
        SizedBox(width: 4 * scale),
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 10 * scale),
        ),
      ],
    );
  }

  Widget _buildHeatmapView(
    ProjectState state,
    double scale,
    AppLocalizations l10n,
  ) {
    if (state.nn == null) {
      return Center(
        child: Text(
          l10n.noBrainDataMessage,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12 * scale),
        ),
      );
    }
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: BrainHeatmapPainter(state.nn!, scale),
      ),
    );
  }

  Widget _buildLogView(ProjectState state, double scale) {
    return Scrollbar(
      child: ListView.builder(
        padding: EdgeInsets.all(8 * scale),
        itemCount: state.terminalLogs.length,
        itemBuilder: (context, index) => Text(
          state.terminalLogs[index],
          style: TextStyle(
            color: Colors.greenAccent,
            fontFamily: 'monospace',
            fontSize: 12 * scale,
          ),
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String text, double scale) {
    return Row(
      children: [
        Container(width: 10 * scale, height: 10 * scale, color: color),
        SizedBox(width: 4 * scale),
        Text(
          text,
          style: TextStyle(fontSize: 10 * scale, color: Colors.grey),
        ),
      ],
    );
  }

  void _showResetDialog(
    BuildContext context,
    ProjectState state,
    double scale,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.warningTitle, style: TextStyle(fontSize: 18 * scale)),
        content: Text(
          l10n.applyChangesDesc,
          style: TextStyle(fontSize: 14 * scale),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.btnCancel, style: TextStyle(fontSize: 16 * scale)),
          ),
          TextButton(
            onPressed: () {
              state.resetTraining();
              Navigator.pop(ctx);
            },
            child: Text(
              l10n.btnResetBrain,
              style: TextStyle(color: Colors.red, fontSize: 16 * scale),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // ★変更：全ての木を画像化し、リストで返すように修正（UIフリーズ防止付き）
  // ============================================================================
  Future<List<Uint8List>> _generateAllTreeImageBytes(ProjectState state) async {
    if (state.rf == null || state.rf!.trees.isEmpty) return [];

    List<Uint8List> images = [];
    final double scale = 2.0;
    double canvasWidth = 2400;
    double canvasHeight = 1600;

    for (int i = 0; i < state.rf!.trees.length; i++) {
      final tree = state.rf!.trees[i];

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
      );

      canvas.drawRect(
        Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
        Paint()..color = Colors.white,
      );

      final painter = PdfRFTreePainter(
        tree: tree,
        inputDefs: state.proj.inputDefs,
        outputDefs: state.proj.outputDefs,
        scale: scale,
        inputMask: state.inputMask,
      );

      painter.paint(canvas, Size(canvasWidth, canvasHeight));

      final picture = recorder.endRecording();
      final img = await picture.toImage(
        canvasWidth.toInt(),
        canvasHeight.toInt(),
      );
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        images.add(byteData.buffer.asUint8List());
      }

      // ★UIフリーズ防止の要：1本描画するごとに10ミリ秒だけFlutterの描画スレッドに処理を譲る
      await Future.delayed(const Duration(milliseconds: 10));
    }

    return images;
  }
}

class PdfRFTreePainter extends CustomPainter {
  final DecisionTree tree;
  final List<FeatureDef> inputDefs;
  final List<FeatureDef> outputDefs;
  final double scale;
  final List<bool> inputMask;

  PdfRFTreePainter({
    required this.tree,
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
    int maxDepth = 0;

    // ★全体がはみ出さないように、まず木の幅（葉の数）と深さを測定する
    void measure(TreeNode node, int depth) {
      if (depth > maxDepth) maxDepth = depth;
      if (node.left == null && node.right == null) {
        leafCount++;
      } else {
        if (node.left != null) measure(node.left!, depth + 1);
        if (node.right != null) measure(node.right!, depth + 1);
      }
    }

    measure(tree.root!, 0);
    if (leafCount == 0) leafCount = 1;

    // 木の「論理的な」サイズを計算
    double logicalWidth = leafCount * 140.0 * scale;
    double logicalHeight = (maxDepth + 1) * 90.0 * scale + 50 * scale;

    // キャンバスサイズに全体がピタリと収まるように縮小率を計算（オートフィット）
    double scaleX = size.width / logicalWidth;
    double scaleY = size.height / logicalHeight;
    double fitScale = min(scaleX, scaleY) * 0.95; // 余白を5%持たせる

    // 中央寄せのためのオフセット
    double offsetX = (size.width - logicalWidth * fitScale) / 2;
    double offsetY = (size.height - logicalHeight * fitScale) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(fitScale, fitScale);

    leafCount = 0; // 描画用にリセット

    // 深さ優先探索でX,Y座標を割り当て
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

    final edgePaint = Paint()
      ..color = Colors
          .black87 // ★エッジも黒に
      ..strokeWidth = 2.0 * scale;

    // エッジの描画
    void drawEdges(TreeNode node) {
      Offset p1 = positions[node]!;
      if (node.left != null) {
        Offset p2 = positions[node.left!]!;
        canvas.drawLine(p1, p2, edgePaint);
        drawEdges(node.left!);
      }
      if (node.right != null) {
        Offset p2 = positions[node.right!]!;
        canvas.drawLine(p1, p2, edgePaint);
        drawEdges(node.right!);
      }
    }

    drawEdges(tree.root!);

    // ノードの描画
    void drawNodes(TreeNode node) {
      Offset pos = positions[node]!;

      Rect rect = Rect.fromCenter(
        center: pos,
        width: 120 * scale,
        height: 50 * scale,
      );
      RRect rrect = RRect.fromRectAndRadius(rect, Radius.circular(8 * scale));

      // ★ノードの中身を白、枠線を黒にする
      canvas.drawRRect(rrect, Paint()..color = Colors.white);
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = Colors.black87
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * scale,
      );

      String text = "";
      if (node.value != null) {
        if (tree.lossType == 1) {
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
        int encodedIndex = node.featureIndex!;
        String fName = "F$encodedIndex";
        double displayThreshold = node.threshold!;
        bool isCategory = false;

        // ★修正：有効な（マスクされていない）列のみをカウントして、正しい名前を特定する
        int currentFilteredIdx = 0; // マスク適用後のAIが認識しているインデックス

        for (int i = 0; i < inputDefs.length; i++) {
          var def = inputDefs[i];

          // ★追加：この変数がマスク（除外）されているか判定
          bool isMasked =
              inputMask.isNotEmpty &&
              inputMask.length == inputDefs.length &&
              !inputMask[i];

          if (!isMasked) {
            // 有効な変数の場合のみ、AIのインデックス（encodedIndex）と比較する
            if (def.type == 1) {
              int catLen = def.categories.length;
              if (encodedIndex >= currentFilteredIdx &&
                  encodedIndex < currentFilteredIdx + catLen) {
                int cIdx = encodedIndex - currentFilteredIdx;
                fName = "${def.name}[${def.categories[cIdx]}]";
                isCategory = true;
                break;
              }
              currentFilteredIdx += catLen; // 有効な列数分だけカウントを進める
            } else {
              if (encodedIndex == currentFilteredIdx) {
                fName = def.name;
                displayThreshold =
                    node.threshold! * (def.max - def.min) + def.min;
                break;
              }
              currentFilteredIdx += 1; // 有効な1列分カウントを進める
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
            color: Colors.black87, // ★文字も黒
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
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PdfRFTreePainter oldDelegate) => true;
}

class BrainHeatmapPainter extends CustomPainter {
  final NeuralNetwork nn;
  final double scale;
  BrainHeatmapPainter(this.nn, this.scale);
  @override
  void paint(Canvas canvas, Size size) {
    final layers = nn.layers;
    if (layers.isEmpty) return;
    double layerWidth = size.width / layers.length;
    double padding = 2.0 * scale;
    final Paint cellPaint = Paint();
    final Paint linePaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.0;
    for (int i = 0; i < layers.length; i++) {
      final layer = layers[i];
      final weights = layer.weights;
      if (weights.isEmpty) continue;
      int neuronCount = weights.length;
      int inputCount = weights[0].length;
      double maxAbsWeight = 0.0001;
      for (var row in weights) {
        for (var w in row) {
          if (w.abs() > maxAbsWeight) maxAbsWeight = w.abs();
        }
      }
      double startX = i * layerWidth;
      double drawW = layerWidth - padding;
      double cellH = size.height / neuronCount;
      double cellW = drawW / inputCount;
      for (int n = 0; n < neuronCount; n++) {
        for (int inp = 0; inp < inputCount; inp++) {
          double wVal = weights[n][inp];
          double norm = wVal / maxAbsWeight;
          Color cellColor;
          if (norm < 0) {
            double intensity = norm.abs();
            cellColor =
                Color.lerp(Colors.black, Colors.cyanAccent, intensity) ??
                Colors.black;
            cellColor = cellColor.withOpacity(0.3 + 0.7 * intensity);
          } else {
            if (norm < 0.5) {
              double localT = norm * 2.0;
              cellColor =
                  Color.lerp(Colors.black, Colors.redAccent, localT) ??
                  Colors.black;
            } else {
              double localT = (norm - 0.5) * 2.0;
              cellColor =
                  Color.lerp(Colors.redAccent, Colors.yellowAccent, localT) ??
                  Colors.redAccent;
            }
            cellColor = cellColor.withOpacity(0.3 + 0.7 * norm);
          }
          cellPaint.color = cellColor;
          canvas.drawRect(
            Rect.fromLTWH(
              startX + (inp * cellW),
              n * cellH,
              cellW + 0.5,
              cellH + 0.5,
            ),
            cellPaint,
          );
        }
      }
      if (i > 0)
        canvas.drawLine(
          Offset(startX, 0),
          Offset(startX, size.height),
          linePaint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant BrainHeatmapPainter oldDelegate) => true;
}

class LossChartPainter extends CustomPainter {
  final List<double> trainLoss;
  final List<double> valLoss;
  final double scale;

  LossChartPainter(this.trainLoss, this.valLoss, this.scale);
  @override
  void paint(Canvas canvas, Size size) {
    if (trainLoss.isEmpty) return;
    final axisPaint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    final gridPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5 * scale;
    final trainPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    final valPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    double actualMax = 0.001;
    for (var l in trainLoss) if (l > actualMax) actualMax = l;
    for (var l in valLoss) if (l > actualMax) actualMax = l;
    double visualMaxLoss = actualMax > 1.0 ? 1.0 : actualMax;
    double xPadding = 30.0 * scale;
    double yPadding = 4.0 * scale;
    double drawWidth = size.width - xPadding;
    double drawHeight = size.height - yPadding * 2;
    double originY = yPadding + drawHeight;
    canvas.drawLine(
      Offset(xPadding, originY),
      Offset(size.width, originY),
      axisPaint,
    );
    canvas.drawLine(
      Offset(xPadding, originY),
      Offset(xPadding, yPadding),
      axisPaint,
    );
    canvas.drawLine(
      Offset(xPadding, yPadding),
      Offset(size.width, yPadding),
      gridPaint,
    );
    final textStyle = TextStyle(
      color: Colors.grey.shade500,
      fontSize: 9 * scale,
    );
    final tpMax = TextPainter(
      text: TextSpan(text: visualMaxLoss.toStringAsFixed(1), style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tpMax.paint(canvas, Offset(0, yPadding - 5));
    final tpMin = TextPainter(
      text: TextSpan(text: "0", style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tpMin.paint(canvas, Offset(12 * scale, originY - 5));
    Path trainPath = Path();
    Path valPath = Path();
    double stepX =
        drawWidth / (trainLoss.length > 1 ? trainLoss.length - 1 : 1);
    for (int i = 0; i < trainLoss.length; i++) {
      double x = xPadding + (i * stepX);
      double tLoss = trainLoss[i] > 1.0 ? 1.0 : trainLoss[i];
      double yT =
          yPadding + drawHeight - ((tLoss / visualMaxLoss) * drawHeight);
      double vLoss = valLoss.length > i ? valLoss[i] : trainLoss[i];
      vLoss = vLoss > 1.0 ? 1.0 : vLoss;
      double yV =
          yPadding + drawHeight - ((vLoss / visualMaxLoss) * drawHeight);
      if (i == 0) {
        trainPath.moveTo(x, yT);
        valPath.moveTo(x, yV);
      } else {
        trainPath.lineTo(x, yT);
        valPath.lineTo(x, yV);
      }
    }
    canvas.drawPath(valPath, valPaint);
    canvas.drawPath(trainPath, trainPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ConfusionMatrixPainter extends CustomPainter {
  final List<List<int>> matrix;
  final List<String> labels;
  final double cellSize;
  final double labelWidth;
  final double labelHeight;
  final double scale;
  final AppLocalizations l10n;

  ConfusionMatrixPainter(
    this.matrix,
    this.labels,
    this.cellSize,
    this.labelWidth,
    this.labelHeight,
    this.scale,
    this.l10n,
  );

  @override
  void paint(Canvas canvas, Size size) {
    int count = matrix.length;
    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    List<int> rowTotals = [];
    for (var row in matrix) {
      int total = row.reduce((a, b) => a + b);
      rowTotals.add(total);
    }

    final textStyle = TextStyle(color: Colors.grey, fontSize: 10 * scale);
    final numStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 12 * scale,
    );

    for (int i = 0; i < count; i++) {
      String label = labels.length > i ? labels[i] : "$i";

      _drawTextCentered(
        canvas,
        label,
        Offset(labelWidth + i * cellSize + cellSize / 2, labelHeight / 2),
        textStyle,
      );

      _drawTextCentered(
        canvas,
        label,
        Offset(labelWidth / 2, labelHeight + i * cellSize + cellSize / 2),
        textStyle,
      );
    }

    for (int r = 0; r < count; r++) {
      int total = rowTotals[r];
      for (int c = 0; c < count; c++) {
        int val = matrix[r][c];
        double ratio = total > 0 ? val / total : 0.0;

        Color cellColor;
        if (val == 0) {
          cellColor = Colors.black;
        } else if (r == c) {
          cellColor = Colors.green.withOpacity(0.2 + 0.8 * ratio);
        } else {
          cellColor = Colors.red.withOpacity(0.2 + 0.8 * ratio);
        }

        double left = labelWidth + c * cellSize;
        double top = labelHeight + r * cellSize;
        Rect rect = Rect.fromLTWH(left, top, cellSize, cellSize);

        paint.color = cellColor;
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, borderPaint);

        if (val > 0) {
          _drawTextCentered(
            canvas,
            val.toString(),
            Offset(left + cellSize / 2, top + cellSize / 2),
            numStyle,
          );
        }
      }
    }

    _drawTextCentered(
      canvas,
      l10n.chartAxisTrue,
      Offset(labelWidth / 2, labelHeight / 2 - 6 * scale),
      TextStyle(color: Colors.cyanAccent, fontSize: 8 * scale),
    );
    _drawTextCentered(
      canvas,
      l10n.chartAxisPred,
      Offset(labelWidth / 2, labelHeight / 2 + 6 * scale),
      TextStyle(color: Colors.cyanAccent, fontSize: 8 * scale),
    );
  }

  void _drawTextCentered(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle style,
  ) {
    final span = TextSpan(text: text, style: style);
    final tp = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '..',
    );
    tp.layout(maxWidth: cellSize - 2);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ScatterPlotPainter extends CustomPainter {
  final List<Offset> points;
  final double scale;

  ScatterPlotPainter(this.points, this.scale);

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 20.0 * scale;
    final w = size.width - padding * 2;
    final h = size.height - padding * 2;

    final borderPaint = Paint()
      ..color = Colors.grey.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(Rect.fromLTWH(padding, padding, w, h), borderPaint);

    final idealLinePaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(padding, padding + h),
      Offset(padding + w, padding),
      idealLinePaint,
    );

    final pointPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    for (var p in points) {
      double px = padding + p.dx * w;
      double py = padding + h - (p.dy * h);

      if (px < padding) px = padding;
      if (px > padding + w) px = padding + w;
      if (py < padding) py = padding;
      if (py > padding + h) py = padding + h;

      canvas.drawCircle(Offset(px, py), 3 * scale, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DetailedChartScreen extends StatelessWidget {
  final List<List<int>>? confusionMatrix;
  final List<String> matrixLabels;
  final List<Offset>? scatterPoints;

  const DetailedChartScreen({
    super.key,
    this.confusionMatrix,
    this.matrixLabels = const [],
    this.scatterPoints,
  });

  @override
  Widget build(BuildContext context) {
    final double scale = ScaleUtil.scale(context);
    final l10n = AppLocalizations.of(context)!;
    bool isClassification = confusionMatrix != null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white, size: 24 * scale),
        title: Text(
          isClassification
              ? l10n.detailedChartTitleMatrix
              : l10n.detailedChartTitleScatter,
          style: TextStyle(color: Colors.white, fontSize: 18 * scale),
        ),
      ),
      body: InteractiveViewer(
        boundaryMargin: EdgeInsets.all(double.infinity),
        minScale: 0.1,
        maxScale: 5.0,
        constrained: false,
        child: isClassification
            ? _buildMatrixContent(scale, l10n)
            : _buildScatterContent(context, scale),
      ),
    );
  }

  Widget _buildMatrixContent(double scale, AppLocalizations l10n) {
    if (confusionMatrix == null) return SizedBox();
    final double cellSize = 40.0 * scale;
    final int size = confusionMatrix!.length;
    final double labelWidth = 60.0 * scale;
    final double labelHeight = 30.0 * scale;
    final double totalWidth = labelWidth + (size * cellSize);
    final double totalHeight = labelHeight + (size * cellSize);

    return SizedBox(
      width: totalWidth,
      height: totalHeight,
      child: CustomPaint(
        painter: ConfusionMatrixPainter(
          confusionMatrix!,
          matrixLabels,
          cellSize,
          labelWidth,
          labelHeight,
          scale,
          l10n,
        ),
      ),
    );
  }

  Widget _buildScatterContent(BuildContext context, double scale) {
    if (scatterPoints == null) return SizedBox();
    final Size screenSize = MediaQuery.of(context).size;
    final double size = screenSize.width > screenSize.height
        ? screenSize.height * 0.8
        : screenSize.width * 0.9;

    return Container(
      width: size,
      height: size,
      color: Colors.black,
      child: CustomPaint(painter: ScatterPlotPainter(scatterPoints!, scale)),
    );
  }
}
