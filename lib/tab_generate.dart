import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'main.dart'; // ProjectState, ScaleUtilを使用
import 'l10n/app_localizations.dart'; // 共通辞書

// ★ 新機能用のローカル言語判定
bool get _isEn {
  return ui.PlatformDispatcher.instance.locale.languageCode != 'ja';
}

class GenerateTab extends StatefulWidget {
  const GenerateTab({super.key});

  @override
  State<GenerateTab> createState() => _GenerateTabState();
}

class _GenerateTabState extends State<GenerateTab> {
  List<double>? _zValues;
  List<Color>? _pixels;
  final Random _rand = Random();
  bool _isExporting = false; // 保存処理中のフラグ

  @override
  void initState() {
    super.initState();
  }

  // 潜在変数Zの初期化
  void _initZ(int latentDim) {
    _zValues = List.filled(latentDim, 0.0);
    _pixels = List.filled(256, Colors.black);
  }

  // ニューラルネットワークのデコーダを使って画像を生成
  void _generateImage(ProjectState state) {
    if (state.nn == null || !state.nn!.isVAE || _zValues == null) return;

    // 潜在変数Zから画像を復元 (出力は 16 * 16 * 3 = 768 次元)
    List<double> output = state.nn!.decodeFromZ(_zValues!);

    if (output.length >= 768) {
      List<Color> newPixels = List.filled(256, Colors.black);
      for (int i = 0; i < 256; i++) {
        int r = (output[i * 3 + 0] * 255).clamp(0, 255).toInt();
        int g = (output[i * 3 + 1] * 255).clamp(0, 255).toInt();
        int b = (output[i * 3 + 2] * 255).clamp(0, 255).toInt();
        newPixels[i] = Color.fromARGB(255, r, g, b);
      }
      setState(() {
        _pixels = newPixels;
      });
    }
  }

  // Box-Muller変換で標準正規分布からランダム生成
  void _randomizeZ(ProjectState state) {
    if (_zValues == null) return;
    for (int i = 0; i < _zValues!.length; i++) {
      double u1 = 1.0 - _rand.nextDouble();
      double u2 = 1.0 - _rand.nextDouble();
      double z = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
      _zValues![i] = z.clamp(-3.0, 3.0);
    }
    _generateImage(state);
  }

  // スライダーをすべて0（平均顔）にリセット
  void _resetZ(ProjectState state) {
    if (_zValues == null) return;
    for (int i = 0; i < _zValues!.length; i++) {
      _zValues![i] = 0.0;
    }
    _generateImage(state);
  }

  // 生成したドット絵を高画質(512x512)のPNGに変換して保存/シェアする機能
  Future<void> _exportImage(BuildContext context) async {
    if (_pixels == null) return;
    setState(() {
      _isExporting = true;
    });

    try {
      // 保存用のサイズ（SNS等で見栄えが良いように 512x512 に拡大）
      const int exportSize = 512;
      const int gridSize = 16;
      const double cellSize = exportSize / gridSize;

      // バックグラウンドでキャンバスに描画
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      final Paint paint = Paint()..style = PaintingStyle.fill;

      for (int i = 0; i < _pixels!.length; i++) {
        int x = i % gridSize;
        int y = i ~/ gridSize;
        paint.color = _pixels![i];
        canvas.drawRect(
          Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
          paint,
        );
      }

      // 画像化してPNGバイトデータに変換
      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(exportSize, exportSize);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();

        // テンポラリディレクトリに一時保存
        final Directory tempDir = await getTemporaryDirectory();
        final File file = File(
          '${tempDir.path}/ai_pixel_art_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(pngBytes);

        // ★ 修正：iPad対策として、画面の「ど真ん中」をシェアパネルの出現位置に強制指定する
        Rect? shareRect;
        if (context.mounted) {
          final size = MediaQuery.of(context).size;
          shareRect = Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: 50,
            height: 50,
          );
        }

        // Shareシートの起動と結果の受け取り
        final ShareResult shareResult = await Share.shareXFiles(
          [XFile(file.path)],
          text: _isEn ? '#HakoniwaAI #PixelArt' : '#箱庭小AI #ドット絵',
          sharePositionOrigin: shareRect,
        );

        // ★結果のステータスを判定
        if (shareResult.status == ShareResultStatus.success) {
          // ユーザーが保存や共有を完了した時だけスナックバーを出す
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isEn
                      ? 'Image saved/shared successfully!'
                      : '画像の保存・共有が完了しました！',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else if (shareResult.status == ShareResultStatus.dismissed) {
          // ユーザーがシェアシートをスワイプして閉じた（キャンセルした）場合は何もしない
          debugPrint("Share dismissed.");
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEn ? 'Failed to save image: $e' : '画像の保存に失敗しました: $e',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProjectState>();
    final double scale = ScaleUtil.scale(context);

    // AIの脳がない、または学習中の場合の表示
    if (state.isTraining) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.greenAccent),
            SizedBox(height: 16 * scale),
            Text(
              _isEn ? "AI is currently learning..." : "AIが学習中です…",
              style: TextStyle(fontSize: 16 * scale, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (state.nn == null || !state.nn!.isVAE) {
      return Center(
        child: Text(
          _isEn
              ? "No VAE Brain found. Please train the model in the Train tab."
              : "VAEの脳がありません。\n「学習」タブでAIを訓練してください。",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16 * scale, color: Colors.grey),
        ),
      );
    }

    // 学習済みモデルが存在し、_zValuesが未初期化なら初期化して最初の画像を生成
    if (_zValues == null || _zValues!.length != state.nn!.latentDim) {
      _initZ(state.nn!.latentDim);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateImage(state);
      });
    }

    return Column(
      children: [
        // === 上部：生成された画像（キャンバス） ===
        Container(
          padding: EdgeInsets.all(16 * scale),
          color: Colors.black54,
          child: Center(
            child: Container(
              width: 160 * scale,
              height: 160 * scale,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.greenAccent.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CustomPaint(
                painter: PixelArtPainter(
                  pixels: _pixels ?? List.filled(256, Colors.black),
                ),
              ),
            ),
          ),
        ),

        // === 中段：コントロールボタン ===
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16 * scale,
            vertical: 8 * scale,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.grey),
                  padding: EdgeInsets.symmetric(horizontal: 12 * scale),
                ),
                onPressed: () => _resetZ(state),
                icon: Icon(Icons.refresh, size: 18 * scale),
                label: Text(
                  _isEn ? "Zero" : "ゼロ",
                  style: TextStyle(fontSize: 14 * scale),
                ),
              ),
              SizedBox(width: 8 * scale),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade800,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12 * scale),
                  ),
                  onPressed: () => _randomizeZ(state),
                  icon: Icon(Icons.casino, size: 18 * scale),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _isEn ? "Randomize" : "ランダム生成",
                      style: TextStyle(fontSize: 14 * scale),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8 * scale),
              // 保存（シェア）ボタン
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade800,
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
                child: IconButton(
                  tooltip: _isEn ? "Share / Save Image" : "画像をシェア・保存",
                  icon: _isExporting
                      ? SizedBox(
                          width: 20 * scale,
                          height: 20 * scale,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          Icons.ios_share,
                          color: Colors.white,
                          size: 22 * scale,
                        ),
                  onPressed: _isExporting ? null : () => _exportImage(context),
                ),
              ),
            ],
          ),
        ),

        Divider(color: Colors.grey.shade800, height: 1),

        // === 下部：潜在空間(Z)操作スライダー群 ===
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(bottom: 80 * scale),
            itemCount: state.nn!.latentDim,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16 * scale,
                  vertical: 4 * scale,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40 * scale,
                      child: Text(
                        "Z${index + 1}",
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14 * scale,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2.0 * scale,
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius: 8.0 * scale,
                          ),
                          overlayShape: RoundSliderOverlayShape(
                            overlayRadius: 16.0 * scale,
                          ),
                          activeTrackColor: Colors.greenAccent,
                          inactiveTrackColor: Colors.grey.shade800,
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          min: -3.0,
                          max: 3.0,
                          value: _zValues![index],
                          onChanged: (value) {
                            setState(() {
                              _zValues![index] = value;
                            });
                            _generateImage(state);
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 48 * scale,
                      child: Text(
                        _zValues![index].toStringAsFixed(2),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12 * scale,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// 16x16のピクセルアートを高速に描画するためのカスタムペインター
class PixelArtPainter extends CustomPainter {
  final List<Color> pixels;
  final int gridSize = 16;

  PixelArtPainter({required this.pixels});

  @override
  void paint(Canvas canvas, Size size) {
    double cellWidth = size.width / gridSize;
    double cellHeight = size.height / gridSize;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < pixels.length; i++) {
      int x = i % gridSize;
      int y = i ~/ gridSize;

      paint.color = pixels[i];
      canvas.drawRect(
        Rect.fromLTWH(x * cellWidth, y * cellHeight, cellWidth, cellHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PixelArtPainter oldDelegate) {
    return true;
  }
}
