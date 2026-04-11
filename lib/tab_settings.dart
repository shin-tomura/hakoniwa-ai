import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui; // 言語判定用の追加
import 'main.dart';
import 'nn_engine.dart';
import 'models.dart';
import 'l10n/app_localizations.dart'; // 辞書のインポートを追加
import 'package:hive/hive.dart'; // ★追加：Hiveのファイルサイズ取得用

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  // --- 既存のパラメータ ---
  late int layers;
  late List<int> nodesList;
  late int opt;
  late int batch;
  late int lossType;
  late int nGramCount;

  late TextEditingController _lrCtrl;

  // --- 新エンジン用の構造パラメータ（リセットが必要なもの） ---
  late int engineType;
  late int rfTrees;
  late int rfDepth;

  // ★ 追加：VAE用の潜在変数次元数スライダー用変数
  late int latentDim;

  // ▼▼▼ 追加：メモリ占有量取得関数 ▼▼▼
  String _getMemoryStats() {
    double ramMB = 0.0;
    double hiveMB = 0.0;

    try {
      // 物理メモリ(RSS)の取得
      ramMB = ProcessInfo.currentRss / (1024 * 1024);
    } catch (_) {}

    try {
      // Hiveのファイルサイズの取得（※Box名が'projects'であることを前提としています）
      if (Hive.isBoxOpen('projectsBox')) {
        // ★ 'projectsBox' ではなく実際のBox名に合わせる
        final box = Hive.box<NeuralProject>('projectsBox');
        if (box.path != null) {
          final file = File(box.path!);
          hiveMB = file.lengthSync() / (1024 * 1024);
        }
      }
    } catch (e) {
      debugPrint('Hive size error: $e');
    }

    return "App RAM: ${ramMB.toStringAsFixed(1)} MB | Hive DB: ${hiveMB.toStringAsFixed(1)} MB";
  }

  @override
  void initState() {
    super.initState();
    final proj = context.read<ProjectState>().proj;
    layers = proj.hiddenLayers;
    nodesList = List.from(proj.hiddenNodesList);
    opt = proj.optimizer;
    batch = proj.batchSize;
    lossType = proj.lossType;
    nGramCount = proj.nGramCount;

    // 新パラメータの初期化
    engineType = proj.engineType;
    rfTrees = proj.rf_trees;
    rfDepth = proj.rf_depth;

    // ★ VAEの初期化
    latentDim = proj.latentDim;

    _lrCtrl = TextEditingController(text: proj.learningRate.toStringAsFixed(4));
  }

  @override
  void dispose() {
    _lrCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProjectState>();
    final double scale = ScaleUtil.scale(context);
    final l10n = AppLocalizations.of(context)!; // 辞書を呼び出し
    final bool isEn =
        ui.PlatformDispatcher.instance.locale.languageCode != 'ja'; // 英語環境判定

    return ListView(
      padding: EdgeInsets.all(16 * scale),
      children: [
        Container(
          margin: EdgeInsets.only(bottom: 16 * scale),
          padding: EdgeInsets.symmetric(
            vertical: 8 * scale,
            horizontal: 12 * scale,
          ),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8 * scale),
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: Text(
            _getMemoryStats(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.amberAccent,
              fontSize: 12 * scale,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
        if (state.isTraining)
          Container(
            margin: EdgeInsets.only(bottom: 16 * scale),
            padding: EdgeInsets.all(12 * scale),
            decoration: BoxDecoration(
              color: Colors.redAccent.shade700,
              borderRadius: BorderRadius.circular(8 * scale),
            ),
            child: Row(
              children: [
                Icon(Icons.lock, color: Colors.white, size: 20 * scale),
                SizedBox(width: 8 * scale),
                Expanded(
                  child: Text(
                    l10n.lockMessage, // 辞書を使用
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12 * scale,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ==========================================
        // 🧠 リセットが必要な構造設定（上半分）
        // ==========================================
        AbsorbPointer(
          absorbing: state.isTraining,
          child: Opacity(
            opacity: state.isTraining ? 0.3 : 1.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.settingsStructureTitle, // 辞書を使用
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16 * scale),

                // --- AIエンジン選択 ---
                Row(
                  children: [
                    SizedBox(
                      width: 80 * scale,
                      child: Text(
                        isEn ? "AI Engine" : "AIエンジン",
                        style: TextStyle(fontSize: 14 * scale),
                      ),
                    ),
                    Expanded(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: engineType,
                        dropdownColor: Colors.grey.shade900,
                        items: [
                          DropdownMenuItem(
                            value: 0,
                            child: Text(
                              "Neural Network (NN)",
                              style: TextStyle(fontSize: 16 * scale),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 1,
                            child: Text(
                              "Random Forest (RF)",
                              style: TextStyle(
                                fontSize: 16 * scale,
                                color: Colors.lightGreenAccent,
                              ),
                            ),
                          ),
                        ],
                        onChanged:
                            (state.proj.mode == 1 || state.proj.mode == 2)
                            ? null // テキスト生成・VAEモード時は変更不可
                            : (v) => setState(() => engineType = v!),
                      ),
                    ),
                  ],
                ),
                if (state.proj.mode == 1 || state.proj.mode == 2)
                  Text(
                    isEn
                        ? "* Gen mode only supports Neural Network."
                        : "※ 生成モードは Neural Network 専用です。",
                    style: TextStyle(
                      fontSize: 11 * scale,
                      color: Colors.orangeAccent,
                    ),
                  ),
                SizedBox(height: 16 * scale),

                if (state.proj.mode == 1) ...[
                  Row(
                    children: [
                      SizedBox(
                        width: 80 * scale,
                        child: Text(
                          l10n.nGramCountLabel, // 辞書を使用
                          style: TextStyle(fontSize: 14 * scale),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0 * scale),
                          child: Slider(
                            value: nGramCount.toDouble(),
                            min: 1,
                            max: 5,
                            divisions: 4,
                            label: "$nGramCount",
                            activeColor: Colors.cyanAccent,
                            onChanged: (v) =>
                                setState(() => nGramCount = v.toInt()),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40 * scale,
                        child: Text(
                          l10n.nGramChars(nGramCount), // 辞書を使用
                          style: TextStyle(fontSize: 14 * scale),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    l10n.nGramDesc, // 辞書を使用
                    style: TextStyle(
                      fontSize: 11 * scale,
                      color: Colors.orangeAccent,
                    ),
                  ),
                  SizedBox(height: 24 * scale),
                ],

                // --- 分岐：エンジンによって表示する詳細設定を切り替える ---
                if (engineType == 0) ...[
                  // ＝＝＝ NN (Neural Network) 用の設定 ＝＝＝
                  Row(
                    children: [
                      SizedBox(
                        width: 80 * scale,
                        child: Text(
                          l10n.hiddenLayersLabel, // 辞書を使用
                          style: TextStyle(fontSize: 14 * scale),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0 * scale),
                          child: Slider(
                            value: layers.toDouble(),
                            min: 0,
                            max: 5,
                            divisions: 5,
                            label: "$layers",
                            activeColor: Colors.cyanAccent,
                            onChanged: (v) {
                              setState(() {
                                int newLayers = v.toInt();
                                if (newLayers > layers) {
                                  int lastNodes = nodesList.isNotEmpty
                                      ? nodesList.last
                                      : 12;
                                  for (int i = layers; i < newLayers; i++) {
                                    nodesList.add(lastNodes);
                                  }
                                } else if (newLayers < layers) {
                                  nodesList.removeRange(newLayers, layers);
                                }
                                layers = newLayers;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40 * scale,
                        child: Text(
                          l10n.layersCount(layers), // 辞書を使用
                          style: TextStyle(fontSize: 14 * scale),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    l10n.hiddenLayersDesc, // 辞書を使用
                    style: TextStyle(fontSize: 11 * scale, color: Colors.grey),
                  ),
                  SizedBox(height: 16 * scale),

                  Container(
                    padding: EdgeInsets.all(12 * scale),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(8 * scale),
                      border: Border.all(color: Colors.grey.shade800),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.nodesPerLayerTitle, // 辞書を使用
                          style: TextStyle(
                            fontSize: 12 * scale,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        ...List.generate(layers, (index) {
                          String label = l10n.layerLabel(index + 1); // 辞書を使用
                          if (index == 0)
                            label += l10n.layerInputSide;
                          else if (index == layers - 1)
                            label += l10n.layerOutputSide;

                          return Row(
                            children: [
                              SizedBox(
                                width: 80 * scale,
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 13 * scale,
                                    color: index == 0
                                        ? Colors.cyanAccent
                                        : (index == layers - 1
                                              ? Colors.orangeAccent
                                              : Colors.white),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 4.0 * scale,
                                  ),
                                  child: Slider(
                                    value: nodesList[index].toDouble(),
                                    min: 4,
                                    max: 128,
                                    divisions: 31,
                                    label: "${nodesList[index]}",
                                    activeColor: Colors.cyanAccent,
                                    onChanged: (v) {
                                      setState(() {
                                        nodesList[index] = v.toInt();
                                      });
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 50 * scale,
                                child: Text(
                                  l10n.nodesCount(nodesList[index]), // 辞書を使用
                                  style: TextStyle(fontSize: 14 * scale),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  SizedBox(height: 16 * scale),

                  if (layers >= 4 && nodesList.any((n) => n >= 64))
                    Container(
                      margin: EdgeInsets.only(bottom: 16 * scale),
                      padding: EdgeInsets.all(12 * scale),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8 * scale),
                        border: Border.all(color: Colors.redAccent),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning,
                            color: Colors.redAccent,
                            size: 24 * scale,
                          ),
                          SizedBox(width: 8 * scale),
                          Expanded(
                            child: Text(
                              l10n.warningHeavyStructure, // 辞書を使用
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12 * scale,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ★★★ 追加：VAE(画像生成)モードの時だけ出現する「潜在変数 (Z)」スライダー ★★★
                  if (state.proj.mode == 2) ...[
                    Container(
                      margin: EdgeInsets.only(bottom: 16 * scale),
                      padding: EdgeInsets.all(12 * scale),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8 * scale),
                        border: Border.all(
                          color: Colors.orangeAccent.withOpacity(0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 80 * scale,
                                child: Text(
                                  isEn ? "Latent Dim (Z)" : "潜在変数 (Z)",
                                  style: TextStyle(
                                    fontSize: 12 * scale,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orangeAccent,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 4.0 * scale,
                                  ),
                                  child: Slider(
                                    value: latentDim.toDouble(),
                                    min: 2,
                                    max: 16,
                                    divisions: 14, // 2から16まで1刻み
                                    label: "$latentDim",
                                    activeColor: Colors.orangeAccent,
                                    inactiveColor: Colors.orangeAccent
                                        .withOpacity(0.3),
                                    onChanged: (v) =>
                                        setState(() => latentDim = v.toInt()),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 40 * scale,
                                child: Text(
                                  "$latentDim",
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 14 * scale,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orangeAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            isEn
                                ? "Number of Z sliders. Fewer sliders create clearer morphing effects, more sliders memorize details better."
                                : "スライダーの数です。少ないと形が混ざりやすくなり、多いと元の画像を正確に記憶します。",
                            style: TextStyle(
                              fontSize: 11 * scale,
                              color: Colors.orangeAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  Row(
                    children: [
                      SizedBox(
                        width: 80 * scale,
                        child: Text(
                          l10n.batchSizeLabel, // 辞書を使用
                          style: TextStyle(fontSize: 14 * scale),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0 * scale),
                          child: Slider(
                            value: batch.toDouble(),
                            min: 1,
                            max: 64,
                            divisions: 63,
                            label: "$batch",
                            activeColor: Colors.cyanAccent,
                            onChanged: (v) => setState(() => batch = v.toInt()),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40 * scale,
                        child: Text(
                          l10n.batchSizeCount(batch), // 辞書を使用
                          style: TextStyle(fontSize: 14 * scale),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    l10n.batchSizeDesc, // 辞書を使用
                    style: TextStyle(fontSize: 11 * scale, color: Colors.grey),
                  ),
                  SizedBox(height: 16 * scale),

                  Row(
                    children: [
                      SizedBox(
                        width: 80 * scale,
                        child: Text(
                          l10n.optimizerLabel, // 辞書を使用
                          style: TextStyle(fontSize: 14 * scale),
                        ),
                      ),
                      Expanded(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: opt,
                          itemHeight: null,
                          dropdownColor: Colors.grey.shade900,
                          items: [
                            DropdownMenuItem(
                              value: 0,
                              child: Text(
                                "SGD",
                                style: TextStyle(fontSize: 16 * scale),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 1,
                              child: Text(
                                "Mini-Batch",
                                style: TextStyle(fontSize: 16 * scale),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 2,
                              child: Text(
                                "Adam",
                                style: TextStyle(fontSize: 16 * scale),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => opt = v!),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    l10n.optimizerDesc, // 辞書を使用
                    style: TextStyle(fontSize: 11 * scale, color: Colors.grey),
                  ),
                  SizedBox(height: 16 * scale),
                ] else ...[
                  // ＝＝＝ RF (Random Forest) 用の設定 ＝＝＝
                  Row(
                    children: [
                      SizedBox(
                        width: 80 * scale,
                        child: Text(
                          isEn ? "Trees" : "決定木の数\n(Trees)",
                          style: TextStyle(fontSize: 12 * scale),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0 * scale),
                          child: Slider(
                            value: rfTrees.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            label: "$rfTrees",
                            activeColor: Colors.lightGreenAccent,
                            onChanged: (v) =>
                                setState(() => rfTrees = v.toInt()),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40 * scale,
                        child: Text(
                          "$rfTrees",
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 14 * scale),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    isEn
                        ? "Number of decision trees in the forest. (Max 10 for MCU limits)"
                        : "森を作る決定木の数です。（マイコンのメモリ制限のため最大10）",
                    style: TextStyle(fontSize: 11 * scale, color: Colors.grey),
                  ),
                  SizedBox(height: 16 * scale),

                  Row(
                    children: [
                      SizedBox(
                        width: 80 * scale,
                        child: Text(
                          isEn ? "Max Depth" : "木の深さ\n(Depth)",
                          style: TextStyle(fontSize: 12 * scale),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0 * scale),
                          child: Slider(
                            value: rfDepth.toDouble(),
                            min: 1,
                            max: 5,
                            divisions: 4,
                            label: "$rfDepth",
                            activeColor: Colors.lightGreenAccent,
                            onChanged: (v) =>
                                setState(() => rfDepth = v.toInt()),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40 * scale,
                        child: Text(
                          "$rfDepth",
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 14 * scale),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    isEn
                        ? "Maximum depth of each tree. (Max 5)"
                        : "それぞれの木が分岐する最大の深さです。（最大5）",
                    style: TextStyle(fontSize: 11 * scale, color: Colors.grey),
                  ),
                  SizedBox(height: 16 * scale),
                ],

                // --- 損失関数 / 分岐基準（エンジンに応じて動的変更） ---
                Row(
                  children: [
                    SizedBox(
                      width: 80 * scale,
                      child: Text(
                        engineType == 0
                            ? l10n.lossFunctionLabel
                            : (isEn ? "Split Criterion" : "分岐基準"),
                        style: TextStyle(
                          fontSize: engineType == 0 ? 14 * scale : 13 * scale,
                        ),
                      ),
                    ),
                    Expanded(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        // 変更：VAEモード(2)の時は強制的に「1 (BCE+KL)」の表示に固定する
                        value: state.proj.mode == 2 ? 1 : lossType,
                        itemHeight: null,
                        dropdownColor: Colors.grey.shade900,
                        items: [
                          DropdownMenuItem(
                            value: 0,
                            child: Text(
                              engineType == 0 ? l10n.lossMse : "MSE",
                              style: TextStyle(fontSize: 16 * scale),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 1,
                            child: Text(
                              // 変更：VAEモードの時は特別な表示にする
                              state.proj.mode == 2
                                  ? "BCE + KL Loss"
                                  : (engineType == 0
                                        ? l10n.lossCrossEntropy
                                        : "Gini Impurity"),
                              style: TextStyle(
                                fontSize: 16 * scale,
                                color: Colors.orangeAccent,
                              ),
                            ),
                          ),
                        ],
                        // 変更：VAEモードの時は null を渡してグレーアウト（操作不能）にする
                        onChanged: state.proj.mode == 2
                            ? null
                            : (v) => setState(() => lossType = v!),
                      ),
                    ),
                  ],
                ),
                // 変更：説明文もVAE専用のものを出し、注意を引く色にする
                Text(
                  state.proj.mode == 2
                      ? (isEn
                            ? "* Image Gen (VAE) forces BCE + KL Divergence loss to balance reconstruction and latent space."
                            : "※画像生成(VAE)では、復元と潜在空間のバランスをとるため BCE + KL損失 が強制適用されます。")
                      : (engineType == 0
                            ? l10n.lossDesc
                            : "Criterion used to evaluate the quality of a split. Use MSE for regression and Gini for classification."),
                  style: TextStyle(
                    fontSize: 11 * scale,
                    color: state.proj.mode == 2
                        ? Colors.orangeAccent
                        : Colors.grey,
                  ),
                ),
                SizedBox(height: 16 * scale),

                // --- 分割手法（共通） ---
                Container(
                  padding: EdgeInsets.all(12 * scale),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(8 * scale),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              l10n.splitMethodTitle, // 辞書を使用
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14 * scale,
                              ),
                            ),
                          ),
                          Switch(
                            value: state.proj.isRandomSplit,
                            activeColor: Colors.greenAccent,
                            onChanged: (v) => state.setRandomSplit(v),
                          ),
                        ],
                      ),
                      Text(
                        state.proj.isRandomSplit
                            ? l10n
                                  .splitMethodRandom // 辞書を使用
                            : l10n.splitMethodTail, // 辞書を使用
                        style: TextStyle(
                          fontSize: 12 * scale,
                          color: state.proj.isRandomSplit
                              ? Colors.greenAccent
                              : Colors.orangeAccent,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24 * scale),

                ElevatedButton.icon(
                  icon: Icon(Icons.save, size: 24 * scale),
                  label: Text(
                    l10n.btnApplyStructureAndReset, // 既存の辞書を再利用
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16 * scale,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16 * scale),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(
                          l10n.confirmResetBrainTitle, // 辞書を使用
                          style: TextStyle(fontSize: 20 * scale),
                        ),
                        content: Text(
                          l10n.confirmResetBrainDesc, // 辞書を使用
                          style: TextStyle(fontSize: 16 * scale),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              l10n.btnCancel,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16 * scale,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // 新規パラメータの適用
                              state.proj.engineType = engineType;
                              state.proj.rf_trees = rfTrees;
                              state.proj.rf_depth = rfDepth;

                              state.proj.lossType = lossType;
                              state.proj.nGramCount = nGramCount;

                              // ★ 追加：VAE用の潜在変数次元数を保存
                              if (state.proj.mode == 2) {
                                state.proj.latentDim = latentDim;
                              }

                              if (state.proj.mode == 1) {
                                List<String> charList = state.proj.currentChars
                                    .split('');

                                state.proj.inputDefs.clear();
                                for (int i = 1; i <= nGramCount; i++) {
                                  state.proj.inputDefs.add(
                                    FeatureDef(
                                      name: l10n.pastChar(i), // 既存辞書を再利用
                                      type: 1,
                                      categories: charList,
                                    ),
                                  );
                                }
                                state.proj.outputDefs = [
                                  FeatureDef(
                                    name: l10n.nextOneChar, // 既存辞書を再利用
                                    type: 1,
                                    categories: charList,
                                  ),
                                ];
                              }

                              state.updateNetworkStructure(
                                layers,
                                nodesList,
                                opt,
                                batch,
                              );
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    state.proj.mode == 1
                                        ? l10n
                                              .msgResetTextGen // 辞書を使用
                                        : l10n.msgResetNormal, // 辞書を使用
                                    style: TextStyle(fontSize: 14 * scale),
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              l10n.btnReset, // 辞書を使用
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16 * scale,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 40 * scale),
        Divider(color: Colors.green, thickness: 1 * scale),
        SizedBox(height: 16 * scale),

        // ==========================================
        // ⚙️ 学習中もいつでも変更できる設定（下半分）
        // ==========================================
        Text(
          l10n.settingsAppTitle, // 辞書を使用
          style: TextStyle(
            color: Colors.greenAccent,
            fontSize: 16 * scale,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16 * scale),

        // NNエンジンの場合のみ、学習率・活性化関数・ドロップアウト・L2正則化を表示する
        if (state.proj.engineType == 0) ...[
          Row(
            children: [
              SizedBox(
                width: 80 * scale,
                child: Text(
                  l10n.learningRateLabel,
                  style: TextStyle(fontSize: 14 * scale),
                ), // 辞書を使用
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0 * scale),
                  child: Slider(
                    value: state.proj.learningRate.clamp(0.001, 0.5),
                    min: 0.001,
                    max: 0.5,
                    divisions: 499,
                    activeColor: Colors.cyanAccent,
                    label: state.proj.learningRate.toStringAsFixed(4),
                    onChanged: (v) {
                      state.setLearningRate(v);
                      _lrCtrl.text = v.toStringAsFixed(4);
                    },
                  ),
                ),
              ),
              SizedBox(
                width: 70 * scale,
                child: TextField(
                  controller: _lrCtrl,
                  style: TextStyle(fontSize: 14 * scale),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8 * scale,
                      horizontal: 4 * scale,
                    ),
                  ),
                  onChanged: (v) {
                    double? parsed = double.tryParse(v);
                    if (parsed != null && parsed > 0) {
                      double safeValue = parsed > 1.0 ? 1.0 : parsed;
                      state.setLearningRate(safeValue);
                    }
                  },
                ),
              ),
            ],
          ),
          Text(
            l10n.learningRateDesc, // 辞書を使用
            style: TextStyle(fontSize: 11 * scale, color: Colors.grey),
          ),
          SizedBox(height: 16 * scale),

          Row(
            children: [
              SizedBox(
                width: 80 * scale,
                child: Text(
                  l10n.activationLabel,
                  style: TextStyle(fontSize: 14 * scale),
                ), // 辞書を使用
              ),
              Expanded(
                child: DropdownButton<ActivationType>(
                  isExpanded: true,
                  value: state.actType,
                  itemHeight: null,
                  dropdownColor: Colors.grey.shade900,
                  items: [
                    DropdownMenuItem(
                      value: ActivationType.sigmoid,
                      child: Text(
                        "Sigmoid",
                        style: TextStyle(fontSize: 16 * scale),
                      ),
                    ),
                    DropdownMenuItem(
                      value: ActivationType.relu,
                      child: Text(
                        "ReLU",
                        style: TextStyle(fontSize: 16 * scale),
                      ),
                    ),
                    DropdownMenuItem(
                      value: ActivationType.tanh,
                      child: Text(
                        "Tanh",
                        style: TextStyle(fontSize: 16 * scale),
                      ),
                    ),
                  ],
                  onChanged: (v) => state.setActType(v!),
                ),
              ),
            ],
          ),
          Text(
            l10n.activationDesc, // 辞書を使用
            style: TextStyle(fontSize: 11 * scale, color: Colors.grey),
          ),
          SizedBox(height: 16 * scale),

          // --- Dropout（リセット不要で即反映） ---
          Row(
            children: [
              SizedBox(
                width: 80 * scale,
                child: Text(
                  isEn ? "Dropout" : "ﾄﾞﾛｯﾌﾟｱｳﾄ",
                  style: TextStyle(fontSize: 14 * scale),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0 * scale),
                  child: Slider(
                    value: state.proj.dropoutRate.clamp(0.0, 0.5),
                    min: 0.0,
                    max: 0.5,
                    divisions: 10,
                    label: state.proj.dropoutRate.toStringAsFixed(2),
                    activeColor: Colors.cyanAccent,
                    onChanged: (v) {
                      setState(() {
                        state.proj.dropoutRate = v;
                        // 即座に保存（リセット不要）
                        context.read<AppState>().saveProject(state.proj);
                      });
                    },
                  ),
                ),
              ),
              SizedBox(
                width: 40 * scale,
                child: Text(
                  state.proj.dropoutRate.toStringAsFixed(2),
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 14 * scale),
                ),
              ),
            ],
          ),
          Text(
            isEn
                ? "Helps prevent overfitting by randomly disabling neurons."
                : "過学習を防ぐためにニューロンをランダムに無効化します。",
            style: TextStyle(fontSize: 11 * scale, color: Colors.grey),
          ),
          SizedBox(height: 16 * scale),

          // --- L2 Reg（5段階・対数スケール） ---
          Row(
            children: [
              SizedBox(
                width: 80 * scale,
                child: Text(
                  isEn ? "L2 Reg" : "L2正則化",
                  style: TextStyle(fontSize: 14 * scale),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0 * scale),
                  child: Builder(
                    builder: (context) {
                      // 1. 現在の l2Rate を 0〜4 の「レベル」に逆変換
                      int currentLevel = 0;
                      if (state.proj.l2Rate >= 0.1)
                        currentLevel = 4;
                      else if (state.proj.l2Rate >= 0.01)
                        currentLevel = 3;
                      else if (state.proj.l2Rate >= 0.001)
                        currentLevel = 2;
                      else if (state.proj.l2Rate >= 0.0001)
                        currentLevel = 1;

                      // 2. レベルに応じたラベルテキストの作成
                      List<String> labelsEn = [
                        "OFF",
                        "Minimal",
                        "Weak",
                        "Medium",
                        "Strong",
                      ];
                      List<String> labelsJa = ["OFF", "極小", "弱", "中", "強"];
                      String labelName = isEn
                          ? labelsEn[currentLevel]
                          : labelsJa[currentLevel];
                      String labelValue = currentLevel == 0
                          ? "0"
                          : state.proj.l2Rate.toStringAsFixed(4);

                      return Slider(
                        value: currentLevel.toDouble(),
                        min: 0,
                        max: 4,
                        divisions: 4,
                        label: "$labelName ($labelValue)", // スライダー操作中のポップアップ
                        activeColor: Colors.cyanAccent,
                        onChanged: (v) {
                          setState(() {
                            // 3. レベル(0〜4)から実数の l2Rate へ変換
                            int level = v.toInt();
                            if (level == 0)
                              state.proj.l2Rate = 0.0;
                            else if (level == 1)
                              state.proj.l2Rate = 0.0001;
                            else if (level == 2)
                              state.proj.l2Rate = 0.001;
                            else if (level == 3)
                              state.proj.l2Rate = 0.01;
                            else if (level == 4)
                              state.proj.l2Rate = 0.1;

                            // 即座に保存（リセット不要）
                            context.read<AppState>().saveProject(state.proj);
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
              SizedBox(
                width: 60 * scale,
                child: Builder(
                  builder: (context) {
                    // 横の数値表示用（OFF, 1e-4, 1e-3, 1e-2, 1e-1 などでも可ですが、直感的な段階名＋数値を表示）
                    int lvl = 0;
                    if (state.proj.l2Rate >= 0.1)
                      lvl = 4;
                    else if (state.proj.l2Rate >= 0.01)
                      lvl = 3;
                    else if (state.proj.l2Rate >= 0.001)
                      lvl = 2;
                    else if (state.proj.l2Rate >= 0.0001)
                      lvl = 1;

                    List<String> lbls = isEn
                        ? ["OFF", "Min", "Weak", "Med", "Strong"]
                        : ["OFF", "極小", "弱", "中", "強"];
                    return Text(
                      lvl == 0 ? "OFF" : "${lbls[lvl]}\n${state.proj.l2Rate}",
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 12 * scale),
                    );
                  },
                ),
              ),
            ],
          ),
          Text(
            isEn
                ? "Adds a penalty to large weights. Select from 5 levels (0 to 0.1)."
                : "重みが大きくなりすぎないようにペナルティを与えます。5段階から選択します。",
            style: TextStyle(fontSize: 11 * scale, color: Colors.grey),
          ),
          SizedBox(height: 16 * scale),
        ],

        // --- Eco Mode (共通) ---
        Row(
          children: [
            SizedBox(
              width: 80 * scale,
              child: Text(
                l10n.ecoModeLabel, // 辞書を使用
                style: TextStyle(fontSize: 14 * scale),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0 * scale),
                child: Slider(
                  value: state.ecoWaitMs.toDouble(),
                  min: 20,
                  max: 500,
                  divisions: 48,
                  activeColor: state.ecoWaitMs == 0 ? Colors.redAccent : null,
                  label: "${state.ecoWaitMs} ms",
                  onChanged: (v) => state.setEcoWait(v.toInt()),
                ),
              ),
            ),
            SizedBox(
              width: 50 * scale,
              child: Text(
                "${state.ecoWaitMs} ms",
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14 * scale,
                  color: state.ecoWaitMs == 0 ? Colors.redAccent : null,
                  fontWeight: state.ecoWaitMs == 0
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        Text(
          l10n.ecoModeDesc, // 辞書を使用
          style: TextStyle(fontSize: 11 * scale, color: Colors.grey),
        ),
        SizedBox(height: 40 * scale),
      ],
    );
  }
}
