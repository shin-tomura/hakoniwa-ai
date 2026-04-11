import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import 'main.dart'; // ProjectState, ScaleUtilを使用
import 'models.dart'; // TrainingDataを使用
import 'l10n/app_localizations.dart';

// 共通の言語判定
bool get _isEn {
  return ui.PlatformDispatcher.instance.locale.languageCode != 'ja';
}

class DataVAETab extends StatefulWidget {
  const DataVAETab({super.key});

  @override
  State<DataVAETab> createState() => _DataVAETabState();
}

class _DataVAETabState extends State<DataVAETab> {
  // true: クロップ（中央切り抜き）, false: ストレッチ（引き伸ばし）
  bool _isCrop = true;
  // 画像処理中かどうかのフラグ
  bool _isProcessing = false;

  // ギャラリーから画像を選択し、16x16の配列に変換してHive(ProjectState)に保存する
  Future<void> _pickAndProcessImages(ProjectState state) async {
    try {
      // 複数画像選択を許可してファイルピッカーを起動
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result == null || result.paths.isEmpty) return;

      // ★ フェイルセーフ1: 一度に処理できる枚数を制限（最大50枚）
      const int maxSelection = 50;
      List<String?> selectedPaths = result.paths;
      bool isLimited = false;

      if (selectedPaths.length > maxSelection) {
        selectedPaths = selectedPaths.sublist(0, maxSelection);
        isLimited = true;
      }

      setState(() {
        _isProcessing = true;
      });

      // 制限にかかった場合はスナックバーで通知
      if (isLimited && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEn
                  ? "Selected too many images. Processing the first $maxSelection."
                  : "選択枚数が多すぎます。安全のため最初の${maxSelection}枚のみ処理します。",
            ),
            backgroundColor: Colors.orangeAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      int successCount = 0;

      for (String? path in selectedPaths) {
        if (path == null) continue;
        File file = File(path);

        // 1. 画像ファイルを読み込み
        final Uint8List bytes = await file.readAsBytes();
        final ui.Codec codec = await ui.instantiateImageCodec(bytes);
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        final ui.Image rawImage = frameInfo.image;

        // 2. 16x16 のキャンバスを準備して、そこに画像を描画する（ここでリサイズ処理）
        final ui.PictureRecorder recorder = ui.PictureRecorder();
        final Canvas canvas = Canvas(recorder);
        final Rect destRect = const Rect.fromLTWH(0, 0, 16, 16);
        final Paint paint = Paint()..filterQuality = FilterQuality.high;

        if (_isCrop) {
          // 短い辺に合わせて正方形を作り、中央を切り抜く
          double minDim = min(
            rawImage.width.toDouble(),
            rawImage.height.toDouble(),
          );
          double srcX = (rawImage.width - minDim) / 2.0;
          double srcY = (rawImage.height - minDim) / 2.0;
          Rect srcRect = Rect.fromLTWH(srcX, srcY, minDim, minDim);
          canvas.drawImageRect(rawImage, srcRect, destRect, paint);
        } else {
          // アスペクト比を無視して 16x16 にギュッと押し込む
          Rect srcRect = Rect.fromLTWH(
            0,
            0,
            rawImage.width.toDouble(),
            rawImage.height.toDouble(),
          );
          canvas.drawImageRect(rawImage, srcRect, destRect, paint);
        }

        // 3. キャンバスに描画した 16x16 の画像を抽出
        final ui.Picture picture = recorder.endRecording();
        final ui.Image resizedImage = await picture.toImage(16, 16);
        final ByteData? byteData = await resizedImage.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );

        if (byteData != null) {
          List<double> pixels = [];
          // 4. RGBAデータからRGBだけを取り出し、0.0〜1.0に正規化してフラットな配列にする
          for (int i = 0; i < byteData.lengthInBytes; i += 4) {
            double r = byteData.getUint8(i) / 255.0;
            double g = byteData.getUint8(i + 1) / 255.0;
            double b = byteData.getUint8(i + 2) / 255.0;
            pixels.addAll([r, g, b]);
          }

          // 5. VAEは入力と出力が同じ（自己符号化）なので、両方に同じデータを入れる
          state.proj.data.add(TrainingData(inputs: pixels, outputs: pixels));
          successCount++;
        }

        // ★ フェイルセーフ2: 大量のメモリを消費するネイティブ画像オブジェクトを明示的に解放
        rawImage.dispose();
        resizedImage.dispose();

        // ★ フェイルセーフ3: ガベージコレクションを促し、UIフリーズを防ぐための息継ぎ
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // 学習データが変更されたので、既存のAIの脳をリセット
      state.resetTraining();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEn
                  ? "$successCount images added to the album."
                  : "$successCount 枚の画像をアルバムに追加しました。",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEn ? "Error processing images: $e" : "画像処理エラー: $e",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // 全削除の確認ダイアログ
  Future<void> _confirmClearAll(
    BuildContext context,
    ProjectState state,
    double scale,
  ) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          _isEn ? "Clear Album" : "アルバムを空にする",
          style: TextStyle(fontSize: 20 * scale),
        ),
        content: Text(
          _isEn
              ? "Are you sure you want to delete all images?"
              : "すべての画像を削除してもよろしいですか？",
          style: TextStyle(fontSize: 16 * scale),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              _isEn ? "Cancel" : "キャンセル",
              style: TextStyle(color: Colors.grey, fontSize: 16 * scale),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              _isEn ? "Delete" : "削除",
              style: TextStyle(color: Colors.red, fontSize: 16 * scale),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      state.clearAllData();
    }
  }

  // 個別削除の確認ダイアログ
  Future<void> _confirmDeleteSingle(
    BuildContext context,
    ProjectState state,
    int index,
    double scale,
  ) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          _isEn ? "Delete Image" : "画像を削除",
          style: TextStyle(fontSize: 20 * scale),
        ),
        content: Text(
          _isEn
              ? "Are you sure you want to delete this image?"
              : "この画像を削除してもよろしいですか？",
          style: TextStyle(fontSize: 16 * scale),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              _isEn ? "Cancel" : "キャンセル",
              style: TextStyle(color: Colors.grey, fontSize: 16 * scale),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              _isEn ? "Delete" : "削除",
              style: TextStyle(color: Colors.red, fontSize: 16 * scale),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      state.removeDataAt(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProjectState>();
    final double scale = ScaleUtil.scale(context);
    final dataList = state.proj.data;

    return Column(
      children: [
        // === 上部：コントロールパネル（画像追加＆設定） ===
        Container(
          padding: EdgeInsets.all(12 * scale),
          color: Colors.black87,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // クロップかストレッチかの切り替えトグルと説明
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _isEn ? "Resize Mode:" : "リサイズ設定:",
                              style: TextStyle(
                                fontSize: 14 * scale,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(width: 8 * scale),
                            ToggleButtons(
                              constraints: BoxConstraints(
                                minHeight: 32 * scale,
                                minWidth: 60 * scale,
                              ),
                              isSelected: [_isCrop, !_isCrop],
                              onPressed: (index) {
                                setState(() {
                                  _isCrop = index == 0;
                                });
                              },
                              borderRadius: BorderRadius.circular(8 * scale),
                              selectedColor: Colors.white,
                              fillColor: Colors.green.shade800,
                              color: Colors.grey,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8 * scale,
                                  ),
                                  child: Text(
                                    _isEn ? "Crop" : "切り抜き",
                                    style: TextStyle(fontSize: 12 * scale),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8 * scale,
                                  ),
                                  child: Text(
                                    _isEn ? "Stretch" : "伸縮",
                                    style: TextStyle(fontSize: 12 * scale),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 8 * scale),
                        // リサイズ手法の英語解説
                        Text(
                          "* Crop: Cuts the center to make a perfect square.\n* Stretch: Squeezes the whole image into a square.",
                          style: TextStyle(
                            fontSize: 11 * scale,
                            color: Colors.white60,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 全削除ボタン
                  if (dataList.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.delete_sweep,
                        color: Colors.redAccent,
                        size: 28 * scale,
                      ),
                      onPressed: () => _confirmClearAll(context, state, scale),
                      tooltip: _isEn ? "Clear Album" : "アルバムを空にする",
                    ),
                ],
              ),
              SizedBox(height: 16 * scale),

              // 画像追加ボタン
              SizedBox(
                width: double.infinity,
                height: 48 * scale,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12 * scale),
                    ),
                  ),
                  onPressed: _isProcessing
                      ? null
                      : () => _pickAndProcessImages(state),
                  icon: _isProcessing
                      ? SizedBox(
                          width: 20 * scale,
                          height: 20 * scale,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(Icons.add_photo_alternate, size: 24 * scale),
                  label: Text(
                    _isProcessing
                        ? (_isEn ? "Processing Images..." : "画像を処理中...")
                        : (_isEn ? "Add Images to Album" : "アルバムに画像を追加"),
                    style: TextStyle(
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        Divider(color: Colors.grey.shade800, height: 1),

        // === 下部：学習データのアルバム（GridView） ===
        Expanded(
          child: dataList.isEmpty
              ? Center(
                  child: Text(
                    _isEn
                        ? "Album is empty.\nAdd photos to teach the AI."
                        : "アルバムが空です。\nAIに教えたい写真を追加してください。",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16 * scale),
                  ),
                )
              : GridView.builder(
                  padding: EdgeInsets.all(
                    12 * scale,
                  ).copyWith(bottom: 80 * scale),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // 1行に4枚表示
                    crossAxisSpacing: 8 * scale,
                    mainAxisSpacing: 8 * scale,
                  ),
                  itemCount: dataList.length,
                  itemBuilder: (context, index) {
                    final data = dataList[index];
                    return Stack(
                      children: [
                        // 画像描画
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade800),
                            borderRadius: BorderRadius.circular(4 * scale),
                            color: Colors.black,
                          ),
                          clipBehavior: Clip.antiAlias,
                          // ★ パフォーマンス最適化：描画結果をキャッシュしてスクロール時のカクつきを防ぐ
                          child: RepaintBoundary(
                            child: CustomPaint(
                              size: Size.infinite,
                              painter: VaePreviewPainter(rgbData: data.inputs),
                            ),
                          ),
                        ),
                        // 削除ボタン（右上に小さく配置）
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _confirmDeleteSingle(
                              context,
                              state,
                              index,
                              scale,
                            ),
                            child: Container(
                              padding: EdgeInsets.all(2 * scale),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(8 * scale),
                                ),
                              ),
                              child: Icon(
                                Icons.close,
                                size: 16 * scale,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// 768次元のRGBデータを16x16のグリッドに描画するカスタムペインター
class VaePreviewPainter extends CustomPainter {
  final List<double> rgbData;
  final int gridSize = 16;

  VaePreviewPainter({required this.rgbData});

  @override
  void paint(Canvas canvas, Size size) {
    if (rgbData.length < 768) return;

    double cellWidth = size.width / gridSize;
    double cellHeight = size.height / gridSize;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 256; i++) {
      int x = i % gridSize;
      int y = i ~/ gridSize; // 整数除算

      // 0.0〜1.0 のデータを 0〜255 の色データに変換
      int r = (rgbData[i * 3 + 0] * 255).clamp(0, 255).toInt();
      int g = (rgbData[i * 3 + 1] * 255).clamp(0, 255).toInt();
      int b = (rgbData[i * 3 + 2] * 255).clamp(0, 255).toInt();

      paint.color = Color.fromARGB(255, r, g, b);
      canvas.drawRect(
        Rect.fromLTWH(x * cellWidth, y * cellHeight, cellWidth, cellHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant VaePreviewPainter oldDelegate) {
    // データが変わらない限り再描画の必要なし
    return false;
  }
}
