import 'dart:math';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import 'main.dart'; // AppState, ScaleUtilを使用するため
import 'models.dart'; // NeuralProjectを使用するため
import 'l10n/app_localizations.dart'; // ★辞書のインポートを追加

class ShareManager {
  //
  static const String currentAppVersion = "3.1.7";

  // ======================================================================
  // 1. 出力（エクスポート）機能
  // ======================================================================
  static Future<void> showExportDialog(
    BuildContext context,
    NeuralProject proj,
  ) async {
    final double scale = ScaleUtil.scale(context);
    final l10n = AppLocalizations.of(context)!; // ★辞書を呼び出し

    // データサイズの事前計測（文字数ではなくバイト数で計算）
    final String jsonStr = jsonEncode(proj.toJson());
    final List<int> rawBytes = utf8.encode(jsonStr);
    final double kbSize = rawBytes.length / 1024;
    final String sizeText = kbSize > 1024
        ? '${(kbSize / 1024).toStringAsFixed(2)} MB'
        : '${kbSize.toStringAsFixed(2)} KB';

    // クリップボードの許容上限を定義（例: 200KBを超えるとクリップボード出力を無効化）
    // ※ VAEモードではネットワーク規模が大きくなるため、この安全装置が役立ちます
    final bool canClipboard = kbSize <= 200;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.exportDialogTitle,
          style: TextStyle(fontSize: 20 * scale),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.exportDialogDesc(proj.name),
              style: TextStyle(fontSize: 16 * scale),
            ),
            SizedBox(height: 12 * scale),
            Text(
              l10n.estimatedDataSize(sizeText),
              style: TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16 * scale,
              ),
            ),
            SizedBox(height: 16 * scale),
            if (!canClipboard)
              Container(
                padding: EdgeInsets.all(8 * scale),
                color: Colors.red.shade900.withOpacity(0.5),
                child: Text(
                  l10n.warningLargeSize,
                  style: TextStyle(color: Colors.white, fontSize: 12 * scale),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.btnCancel,
              style: TextStyle(color: Colors.grey, fontSize: 16 * scale),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: canClipboard
                  ? Colors.blue.shade800
                  : Colors.grey.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: canClipboard
                ? () {
                    Navigator.pop(ctx);
                    _exportToClipboard(context, rawBytes, l10n);
                  }
                : null,
            icon: Icon(Icons.copy, size: 20 * scale),
            label: Text(
              l10n.btnSpellCopy,
              style: TextStyle(fontSize: 14 * scale),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx); // ダイアログを閉じる
              await _exportToFile(context, proj, jsonStr, l10n);
            },
            icon: Icon(Icons.share, size: 20 * scale),
            label: Text(
              l10n.btnFileOutput,
              style: TextStyle(fontSize: 14 * scale),
            ),
          ),
        ],
      ),
    );
  }

  static void _exportToClipboard(
    BuildContext context,
    List<int> rawBytes,
    AppLocalizations l10n,
  ) {
    String magicWord = base64Encode(rawBytes);
    Clipboard.setData(ClipboardData(text: magicWord));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.msgSpellCopied)));
  }

  static Future<void> _exportToFile(
    BuildContext context,
    NeuralProject proj,
    String jsonStr,
    AppLocalizations l10n,
  ) async {
    try {
      // 圧縮処理: JSON -> Archive(Tar) -> GZip
      final bytes = utf8.encode(jsonStr);
      final archive = Archive();
      archive.addFile(ArchiveFile('project.json', bytes.length, bytes));
      final tarData = TarEncoder().encode(archive);
      final gzipData = GZipEncoder().encode(tarData);

      if (gzipData == null) throw Exception(l10n.errorDataGenerationFailed);

      // サイズ制限チェック (5MB上限)
      if (gzipData.length > 5 * 1024 * 1024) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.errorSizeLimitExceeded)));
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      // ファイル名に使えない文字をサニタイズ
      String safeName = proj.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final now = DateTime.now();
      final timeStamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

      // 独自の拡張子を設定
      final filePath = '${tempDir.path}/${safeName}_$timeStamp.hakoai';
      final file = File(filePath);
      await file.writeAsBytes(gzipData);

      // iPadクラッシュ対策 & iPhoneエラー回避: 安全な基準位置の取得
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

      // シェアシートの起動
      await Share.shareXFiles(
        [XFile(filePath)],
        text: l10n.shareProjectText(safeName),
        subject: l10n.shareProjectSubject(proj.name),
        sharePositionOrigin: shareRect,
      );

      // シェア処理完了後のスナックバー表示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.msgFileExported(proj.name)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorFileExport(e.toString()))),
        );
        debugPrint("$e");
      }
    }
  }

  // ======================================================================
  // 2. 入力（インポート）機能
  // ======================================================================

  // ★★★ バージョンチェック機能 ★★★

  // バージョン文字列("1.2.0"や"1.10.0")を数字の配列に分解して正確に大小比較するメソッド
  // 呪文のバージョン > 現在のアプリ ならプラスの数値を返す
  static int _compareVersions(String v1, String v2) {
    List<int> parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    int length = max(parts1.length, parts2.length);
    for (int i = 0; i < length; i++) {
      int p1 = i < parts1.length ? parts1[i] : 0;
      int p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 != p2) {
        return p1.compareTo(p2); // 単純な算数の大小比較
      }
    }
    return 0; // 完全に一致
  }

  // jsonデータの中のappVersionを覗き見て、現在のアプリより新しければ警告を出す
  static bool _checkVersionCompatibility(BuildContext context, String jsonStr) {
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonStr);
      final String dataVersion = jsonMap['appVersion'] ?? "1.1.0";
      final l10n = AppLocalizations.of(context)!; // ★辞書を呼び出し

      if (_compareVersions(dataVersion, currentAppVersion) > 0) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              l10n.versionOldTitle,
              style: TextStyle(fontSize: 20 * ScaleUtil.scale(ctx)),
            ),
            content: Text(
              l10n.versionOldDesc(dataVersion),
              style: TextStyle(fontSize: 16 * ScaleUtil.scale(ctx)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  l10n.btnConfirm,
                  style: TextStyle(fontSize: 16 * ScaleUtil.scale(ctx)),
                ),
              ),
            ],
          ),
        );
        return false; // 新しすぎる場合はNG
      }
      return true; // OK
    } catch (e) {
      // JSONが壊れているなどの場合は一旦通して、後続の読み込みエラーに任せる
      return true;
    }
  }

  static Future<void> showImportDialog(BuildContext context) async {
    final double scale = ScaleUtil.scale(context);
    final l10n = AppLocalizations.of(context)!; // ★辞書を呼び出し

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.importDialogTitle,
          style: TextStyle(fontSize: 20 * scale),
        ),
        content: Text(
          l10n.importDialogDesc,
          style: TextStyle(fontSize: 16 * scale),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.btnCancel,
              style: TextStyle(color: Colors.grey, fontSize: 16 * scale),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _showClipboardImportDialog(context);
            },
            icon: Icon(Icons.paste, size: 20 * scale),
            label: Text(
              l10n.btnSpellPaste,
              style: TextStyle(fontSize: 14 * scale),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _importFromFile(context);
            },
            icon: Icon(Icons.folder_open, size: 20 * scale),
            label: Text(
              l10n.btnSelectFile,
              style: TextStyle(fontSize: 14 * scale),
            ),
          ),
        ],
      ),
    );
  }

  static void _showClipboardImportDialog(BuildContext context) {
    final double scale = ScaleUtil.scale(context);
    final l10n = AppLocalizations.of(context)!; // ★辞書を呼び出し
    String magicWord = "";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.castSpellTitle,
          style: TextStyle(fontSize: 20 * scale),
        ),
        content: TextField(
          maxLines: 4,
          style: TextStyle(fontSize: 16 * scale),
          decoration: InputDecoration(
            hintText: l10n.castSpellHint,
            hintStyle: TextStyle(fontSize: 16 * scale),
          ),
          onChanged: (v) => magicWord = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.btnCancel, style: TextStyle(fontSize: 16 * scale)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade900,
            ),
            onPressed: () {
              try {
                String jsonStr = utf8.decode(base64Decode(magicWord));
                Navigator.pop(ctx); // ダイアログを閉じる

                if (_checkVersionCompatibility(context, jsonStr)) {
                  bool success = context
                      .read<AppState>()
                      .importProjectFromJsonString(
                        jsonStr,
                        l10n.spellSummonSuffix,
                      );
                  _showImportResult(context, success, l10n);
                }
              } catch (e) {
                Navigator.pop(ctx);
                _showImportResult(context, false, l10n);
              }
            },
            child: Text(l10n.btnSummon, style: TextStyle(fontSize: 16 * scale)),
          ),
        ],
      ),
    );
  }

  static Future<void> _importFromFile(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!; // ★辞書を呼び出し
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();

      // 解凍処理: GZip -> TarDecoder -> JSON
      final archive = TarDecoder().decodeBytes(
        GZipDecoder().decodeBytes(bytes),
      );

      String? jsonStr;
      for (var f in archive) {
        if (f.isFile && f.name.endsWith('.json')) {
          jsonStr = utf8.decode(f.content as List<int>);
          break;
        }
      }

      if (jsonStr != null && context.mounted) {
        if (_checkVersionCompatibility(context, jsonStr)) {
          bool success = context.read<AppState>().importProjectFromJsonString(
            jsonStr,
            l10n.fileSummonSuffix,
          );
          _showImportResult(context, success, l10n);
        }
      } else {
        throw Exception(l10n.errorNoDataInFile);
      }
    } catch (e) {
      debugPrint("Import File Error: $e");
      if (context.mounted) _showImportResult(context, false, l10n);
    }
  }

  static void _showImportResult(
    BuildContext context,
    bool success,
    AppLocalizations l10n,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? l10n.msgSummonSuccess : l10n.msgSummonFailed),
      ),
    );
  }
}
