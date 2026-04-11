import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfReportGenerator {
  static Future<void> generateAndShowPdf({
    required int engineType, // ★追加: 0=NN, 1=RF
    required String projectModeName,
    required String layerSizes,
    required int targetEpochs,
    required int dataCount,
    required List<String> inputFeatures,
    required List<String> outputFeatures,
    required String optimizerType,
    required double learningRate,
    required String lossFunction,
    required String hiddenActivation,
    required int batchSize,
    required int rfTrees, // ★追加: RFの木の本数
    required int rfDepth, // ★追加: RFの最大深度
    required String finalTrainLoss,
    required String finalValLoss,
    required String? finalScoreLabel,
    required String? finalScoreValue,
    required Uint8List lossImageBytes,
    required Uint8List? scatterImageBytes,
    required List<Uint8List>? treeImagesBytes, // ★追加: RF用の代表決定木画像
    required List<String> topMistakes,
    required Map<String, double> featureImportance,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- Header ---
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Hakoniwa AI - Analysis Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal900,
                      ),
                    ),
                    pw.Text(
                      'Generated: ${DateTime.now().toString().split('.')[0]}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // --- Main Content (3 Columns) ---
              pw.Expanded(
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // ==========================================
                    // COLUMN 1: Model & Dataset Specs
                    // ==========================================
                    pw.Expanded(
                      flex: 3,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(8),
                          ),
                          border: pw.Border.all(color: PdfColors.grey300),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Experiment Setup',
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blueGrey800,
                              ),
                            ),
                            pw.Divider(color: PdfColors.grey400),
                            pw.SizedBox(height: 4),

                            pw.Text(
                              'Hyperparameters',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            _infoRow('Task Type:', projectModeName),

                            // ★エンジンによって表示項目を切り替え
                            if (engineType == 0) ...[
                              _infoRow('Engine:', 'Neural Network'),
                              _infoRow('Network Arch:', layerSizes),
                              _infoRow('Activation:', hiddenActivation),
                              _infoRow('Optimizer:', optimizerType),
                              _infoRow(
                                'Learning Rate:',
                                learningRate.toString(),
                              ),
                              _infoRow('Batch Size:', '$batchSize'),
                              _infoRow('Loss Function:', lossFunction),
                              _infoRow('Epochs Trained:', '$targetEpochs'),
                            ] else ...[
                              _infoRow('Engine:', 'Random Forest'),
                              _infoRow('Num of Trees:', '$rfTrees'),
                              _infoRow('Max Depth:', '$rfDepth'),
                              _infoRow('Split Criterion:', lossFunction),
                            ],

                            _infoRow('Dataset Size:', '$dataCount samples'),

                            pw.SizedBox(height: 12),
                            pw.Text(
                              'Variables Definition',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Input Features (X):',
                              style: const pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.grey700,
                              ),
                            ),
                            for (
                              int i = 0;
                              i < inputFeatures.length && i < 5;
                              i++
                            )
                              pw.Text(
                                ' - ${inputFeatures[i]}',
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            if (inputFeatures.length > 5)
                              pw.Text(
                                '   ...and ${inputFeatures.length - 5} more',
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.grey600,
                                ),
                              ),

                            pw.SizedBox(height: 6),
                            pw.Text(
                              'Target Variable (y):',
                              style: const pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.grey700,
                              ),
                            ),
                            for (
                              int i = 0;
                              i < outputFeatures.length && i < 3;
                              i++
                            )
                              pw.Text(
                                ' - ${outputFeatures[i]}',
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            if (outputFeatures.length > 3)
                              pw.Text(
                                '   ...and ${outputFeatures.length - 3} more',
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.grey600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    pw.SizedBox(width: 16),

                    // ==========================================
                    // COLUMN 2: Training Process & Score
                    // ==========================================
                    pw.Expanded(
                      flex: 4,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Top: Score
                          pw.Container(
                            width: double.infinity,
                            padding: const pw.EdgeInsets.all(12),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.green50,
                              borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(8),
                              ),
                              border: pw.Border.all(color: PdfColors.green300),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                pw.Text(
                                  'Final Model Performance',
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.green900,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  finalScoreLabel ?? 'Status',
                                  style: const pw.TextStyle(
                                    fontSize: 10,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                                pw.Text(
                                  finalScoreValue ?? 'Unknown',
                                  style: pw.TextStyle(
                                    fontSize: 28,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.green700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 16),

                          // Final Loss Evaluation
                          // ★変更：NNの場合のみ評価指標を表示し、RFの場合はスペースを節約
                          if (engineType == 0) ...[
                            pw.Text(
                              'Final Loss Evaluation',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Container(
                              padding: const pw.EdgeInsets.all(8),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.grey50,
                                borderRadius: const pw.BorderRadius.all(
                                  pw.Radius.circular(4),
                                ),
                                border: pw.Border.all(color: PdfColors.grey300),
                              ),
                              child: pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceAround,
                                children: [
                                  pw.Column(
                                    children: [
                                      pw.Text(
                                        'Train Loss',
                                        style: const pw.TextStyle(
                                          fontSize: 9,
                                          color: PdfColors.blue700,
                                        ),
                                      ),
                                      pw.Text(
                                        finalTrainLoss,
                                        style: pw.TextStyle(
                                          fontSize: 14,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  pw.Container(
                                    width: 1,
                                    height: 20,
                                    color: PdfColors.grey300,
                                  ),
                                  pw.Column(
                                    children: [
                                      pw.Text(
                                        'Validation Loss',
                                        style: const pw.TextStyle(
                                          fontSize: 9,
                                          color: PdfColors.orange700,
                                        ),
                                      ),
                                      pw.Text(
                                        finalValLoss,
                                        style: pw.TextStyle(
                                          fontSize: 14,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            pw.SizedBox(height: 16),
                          ],

                          // ★変更: NNならロス履歴、RFなら代表ツリー画像を「拡大(Expanded)」して表示
                          if (engineType == 0) ...[
                            pw.Text(
                              'Training History (Loss Convergence)',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Expanded(
                              // NNのグラフも少し広げる
                              child: pw.Container(
                                width: double.infinity,
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(
                                    color: PdfColors.grey400,
                                  ),
                                ),
                                child: pw.Image(
                                  pw.MemoryImage(lossImageBytes),
                                  fit: pw.BoxFit.fill,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Container(
                                  width: 8,
                                  height: 8,
                                  color: PdfColors.blue,
                                ),
                                pw.SizedBox(width: 4),
                                pw.Text(
                                  'Train Loss',
                                  style: const pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColors.grey800,
                                  ),
                                ),
                                pw.SizedBox(width: 12),
                                if (finalScoreLabel != 'Status') ...[
                                  pw.Container(
                                    width: 8,
                                    height: 8,
                                    color: PdfColors.orange,
                                  ),
                                  pw.SizedBox(width: 4),
                                  pw.Text(
                                    'Validation Loss',
                                    style: const pw.TextStyle(
                                      fontSize: 8,
                                      color: PdfColors.grey800,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ] else ...[
                            pw.Text(
                              'Representative Decision Tree (Sample)',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            if (treeImagesBytes != null &&
                                treeImagesBytes.isNotEmpty)
                              pw.Expanded(
                                child: pw.Container(
                                  width: double.infinity,
                                  decoration: pw.BoxDecoration(
                                    color: PdfColors.white,
                                    border: pw.Border.all(
                                      color: PdfColors.grey400,
                                    ),
                                  ),
                                  child: pw.Image(
                                    pw.MemoryImage(
                                      treeImagesBytes[0],
                                    ), // ★リストの[0]番目を指定
                                    fit: pw.BoxFit.contain,
                                  ),
                                ),
                              )
                            else
                              pw.Expanded(
                                child: pw.Container(
                                  width: double.infinity,
                                  alignment: pw.Alignment.center,
                                  decoration: pw.BoxDecoration(
                                    color: PdfColors.grey100,
                                    border: pw.Border.all(
                                      color: PdfColors.grey400,
                                    ),
                                  ),
                                  child: pw.Text(
                                    'No Tree Image Available.',
                                    style: const pw.TextStyle(
                                      color: PdfColors.grey500,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 16),

                    // ==========================================
                    // COLUMN 3: Analysis & Feature Importance
                    // ==========================================
                    pw.Expanded(
                      flex: 4,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Top: Task Specific Result (Scatter or Confusion)
                          if (scatterImageBytes != null) ...[
                            pw.Text(
                              'Prediction Accuracy (Scatter Plot)',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Container(
                              height: 160,
                              width: double.infinity,
                              alignment: pw.Alignment.center,
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.grey800),
                              ),
                              child: pw.Image(
                                pw.MemoryImage(scatterImageBytes),
                                fit: pw.BoxFit.contain,
                              ),
                            ),
                          ] else ...[
                            pw.Text(
                              'Classification Analysis',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Container(
                              height: 160,
                              width: double.infinity,
                              padding: const pw.EdgeInsets.all(8),
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.grey300),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Top Misclassifications (Errors):',
                                    style: const pw.TextStyle(
                                      fontSize: 10,
                                      color: PdfColors.red700,
                                    ),
                                  ),
                                  pw.SizedBox(height: 6),
                                  if (topMistakes.isEmpty)
                                    pw.Text(
                                      'No significant errors detected.',
                                      style: const pw.TextStyle(fontSize: 10),
                                    )
                                  else
                                    for (var mistake in topMistakes)
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        child: pw.Text(
                                          '- $mistake',
                                          style: const pw.TextStyle(
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                            ),
                          ],

                          pw.SizedBox(height: 16),

                          // Bottom: Feature Importance (汎用的な名前に変更)
                          pw.Text(
                            'Feature Importance (Impact on Prediction)',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          if (featureImportance.isEmpty)
                            pw.Text(
                              'No importance data available.',
                              style: const pw.TextStyle(fontSize: 10),
                            )
                          else
                            pw.Expanded(
                              child: pw.Container(
                                padding: const pw.EdgeInsets.all(12),
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(
                                    color: PdfColors.grey300,
                                  ),
                                  borderRadius: const pw.BorderRadius.all(
                                    pw.Radius.circular(4),
                                  ),
                                ),
                                child: pw.Column(
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.spaceEvenly,
                                  children: _buildFeatureBars(
                                    featureImportance,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey300),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Powered by Hakoniwa AI - 100% Local Processing',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // ============================================================================
    // ★新規追加：全決定木を1ページずつ横向きで追加する（Appendix）
    // ============================================================================
    if (engineType == 1 && treeImagesBytes != null) {
      for (int i = 0; i < treeImagesBytes.length; i++) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: const pw.EdgeInsets.all(32),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Header(
                    level: 0,
                    child: pw.Text(
                      'Appendix: Decision Tree ${i + 1} / ${treeImagesBytes.length}',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal900,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Container(
                      width: double.infinity,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                      ),
                      child: pw.Image(
                        pw.MemoryImage(treeImagesBytes[i]),
                        fit: pw.BoxFit.contain, // 枠内に全体をピッタリ収める
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'HakoniwaAI_Analysis_Report.pdf',
      format: PdfPageFormat.a4.landscape,
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildFeatureBars(Map<String, double> importance) {
    var entries = importance.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));

    // Top 5まで表示
    int displayCount = entries.length > 5 ? 5 : entries.length;
    double maxVal = entries.isEmpty ? 1.0 : entries.first.value;
    if (maxVal == 0) maxVal = 1.0;

    List<pw.Widget> rows = [];
    for (int i = 0; i < displayCount; i++) {
      double ratio = (entries[i].value / maxVal).clamp(0.0, 1.0);

      int flexFilled = (ratio * 100).round();
      int flexEmpty = 100 - flexFilled;
      if (flexFilled == 0) flexFilled = 1;

      rows.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: 70, // カラム幅に合わせて少し縮小
                child: pw.Text(
                  entries[i].key,
                  style: const pw.TextStyle(fontSize: 9),
                  maxLines: 1,
                ),
              ),
              pw.Expanded(
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: flexFilled,
                      child: pw.Container(
                        height: 8,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.orange400,
                        ),
                      ),
                    ),
                    if (flexEmpty > 0)
                      pw.Expanded(
                        flex: flexEmpty,
                        child: pw.Container(
                          height: 8,
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.grey200,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 8),
              pw.SizedBox(
                width: 30,
                child: pw.Text(
                  '${(ratio * 100).toStringAsFixed(0)}%',
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }
}
