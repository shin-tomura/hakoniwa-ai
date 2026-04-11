import 'dart:io';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart'; // ★追加：Hiveのファイルサイズ取得用
import 'main.dart';
import 'models.dart';
import 'share_manager.dart';
import 'screen_create_project.dart';
import 'screen_group_chat.dart';
import 'l10n/app_localizations.dart';
import 'screen_csv_import.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // ★追加：アプリのRAM使用量とHiveのファイルサイズを取得するギーク向けメーター関数
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

  void _confirmDelete(BuildContext context, String id, String name) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.confirmDeleteTitle,
          style: TextStyle(fontSize: 20 * ScaleUtil.scale(ctx)),
        ),
        content: Text(
          l10n.confirmDeleteMessage(name),
          style: TextStyle(fontSize: 16 * ScaleUtil.scale(ctx)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.btnCancel,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16 * ScaleUtil.scale(ctx),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<AppState>().deleteProject(id);
              Navigator.pop(ctx);
            },
            child: Text(
              l10n.btnDelete,
              style: TextStyle(
                color: Colors.red,
                fontSize: 16 * ScaleUtil.scale(ctx),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, NeuralProject proj) {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController nameCtrl = TextEditingController(
      text: proj.name,
    );

    List<TextEditingController> inCtrls = [];
    List<TextEditingController> outCtrls = [];

    // モード0（数値推論）の場合のみ、入出力項目の名前を編集可能にする
    bool canEditItems = proj.mode == 0;

    if (canEditItems) {
      inCtrls = proj.inputDefs
          .map((d) => TextEditingController(text: d.name))
          .toList();
      outCtrls = proj.outputDefs
          .map((d) => TextEditingController(text: d.name))
          .toList();
    }

    showDialog(
      context: context,
      builder: (ctx) => GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: AlertDialog(
          title: Text(
            !canEditItems
                ? l10n.editProjectNameTitle
                : l10n.editProjectAndItemNameTitle,
            style: TextStyle(fontSize: 20 * ScaleUtil.scale(ctx)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.projectNameHeader,
                  style: TextStyle(
                    fontSize: 12 * ScaleUtil.scale(ctx),
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 4 * ScaleUtil.scale(ctx)),
                TextField(
                  controller: nameCtrl,
                  autofocus: !canEditItems,
                  style: TextStyle(fontSize: 16 * ScaleUtil.scale(ctx)),
                  decoration: InputDecoration(
                    hintText: l10n.editProjectNameHint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                if (canEditItems) ...[
                  SizedBox(height: 16 * ScaleUtil.scale(ctx)),
                  Text(
                    l10n.inputItemNamesHeader,
                    style: TextStyle(
                      fontSize: 14 * ScaleUtil.scale(ctx),
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8 * ScaleUtil.scale(ctx)),
                  ...List.generate(inCtrls.length, (i) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: 8 * ScaleUtil.scale(ctx),
                      ),
                      child: TextField(
                        controller: inCtrls[i],
                        style: TextStyle(fontSize: 14 * ScaleUtil.scale(ctx)),
                        decoration: InputDecoration(
                          labelText: l10n.inputItemLabelNum(i + 1),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 8 * ScaleUtil.scale(ctx)),
                  Text(
                    l10n.outputItemNamesHeader,
                    style: TextStyle(
                      fontSize: 14 * ScaleUtil.scale(ctx),
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8 * ScaleUtil.scale(ctx)),
                  ...List.generate(outCtrls.length, (i) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: 8 * ScaleUtil.scale(ctx),
                      ),
                      child: TextField(
                        controller: outCtrls[i],
                        style: TextStyle(fontSize: 14 * ScaleUtil.scale(ctx)),
                        decoration: InputDecoration(
                          labelText: l10n.outputItemLabelNum(i + 1),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                l10n.btnCancel,
                style: TextStyle(fontSize: 16 * ScaleUtil.scale(ctx)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade800,
              ),
              onPressed: () {
                // プロジェクト名の保存
                String newName = nameCtrl.text.trim();
                if (newName.isNotEmpty) {
                  proj.name = newName;
                }

                // 項目名の保存（数値推論モードのみ）
                if (canEditItems) {
                  for (int i = 0; i < proj.inputDefs.length; i++) {
                    String newInName = inCtrls[i].text.trim();
                    if (newInName.isNotEmpty) {
                      proj.inputDefs[i].name = newInName;
                    }
                  }
                  for (int i = 0; i < proj.outputDefs.length; i++) {
                    String newOutName = outCtrls[i].text.trim();
                    if (newOutName.isNotEmpty) {
                      proj.outputDefs[i].name = newOutName;
                    }
                  }
                }

                context.read<AppState>().saveProject(proj);
                Navigator.pop(ctx);
              },
              child: Text(
                l10n.btnChange,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16 * ScaleUtil.scale(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final double scale = ScaleUtil.scale(context);
    final l10n = AppLocalizations.of(context)!;

    // テキスト生成モードのプロジェクトが1つでもあるかチェック（座談会解放の条件）
    final hasLlmProject = appState.projects.any((p) => p.mode == 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle, style: TextStyle(fontSize: 20 * scale)),
        actions: [
          IconButton(
            tooltip: l10n.tooltipImport,
            icon: Icon(Icons.download, size: 24 * scale),
            onPressed: () => ShareManager.showImportDialog(context),
          ),
        ],
      ),
      // ★改良：ボディ全体をColumnで包み、一番上にメーターを固定配置
      body: Column(
        children: [
          //
          Container(
            width: double.infinity,
            color: Colors.black87,
            padding: EdgeInsets.symmetric(
              vertical: 4 * scale,
              horizontal: 8 * scale,
            ),
            child: Text(
              _getMemoryStats(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.amberAccent, // 警告っぽさを出すカラー
                fontSize: 11 * scale,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace', // ギーク感を出す等幅フォント
              ),
            ),
          ),
          // 【既存のメインコンテンツ（Expandedで残りの画面を埋める）】
          // 【既存のメインコンテンツ（Expandedで残りの画面を埋める）】
          Expanded(
            child: appState.projects.isEmpty
                ? ListView(
                    // プロジェクトが0個の場合は、ボタンとWelcome画面をスクロールリストで並べる
                    children: [
                      _buildKaggleImportButton(context, scale),
                      _buildWelcomeScreen(context, appState, scale, l10n),
                    ],
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(bottom: 88 * scale),
                    // プロジェクト数 + ボタン1個分のカウントにする
                    itemCount: appState.projects.length + 1,
                    itemBuilder: (context, index) {
                      // インデックス0（一番上）にKaggleインポートボタンを配置
                      if (index == 0) {
                        return _buildKaggleImportButton(context, scale);
                      }

                      // インデックス1以降は、既存のプロジェクトタイルを描画 (-1してズレを補正)
                      final proj = appState.projects[index - 1];

                      // ===== 以下、既存の ListTile を返す処理をそのまま配置 =====

                      final bool isLlm = proj.mode == 1;
                      final bool isVAE = proj.mode == 2;
                      final bool isRF =
                          proj.engineType == 1 && !isLlm && !isVAE;

                      IconData leadingIcon = Icons.edit;
                      Color leadingColor = Colors.greenAccent;
                      if (isLlm) {
                        leadingColor = Colors.purpleAccent;
                      } else if (isVAE) {
                        leadingIcon = Icons.image;
                        leadingColor = Colors.pinkAccent;
                      }

                      String langText = proj.langMode == 1
                          ? l10n.langEnglish
                          : l10n.langHiragana;
                      Color langColor = proj.langMode == 1
                          ? Colors.blueAccent
                          : Colors.greenAccent;

                      return ListTile(
                        leading: IconButton(
                          tooltip: l10n.tooltipEditName,
                          icon: Icon(
                            leadingIcon,
                            color: leadingColor,
                            size: 26 * scale,
                          ),
                          onPressed: () => _showEditNameDialog(context, proj),
                        ),
                        title: Text(
                          proj.name,
                          style: TextStyle(fontSize: 16 * scale),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isRF
                                  ? "v${proj.appVersion} | Data: ${proj.data.length} | Trees: ${proj.rf_trees} | Depth: ${proj.rf_depth}"
                                  : l10n.projectInfoSubtitle(
                                      proj.appVersion,
                                      proj.data.length,
                                      proj.hiddenLayers,
                                      proj.hiddenNodesList.join('-'),
                                    ),
                              style: TextStyle(fontSize: 14 * scale),
                            ),
                            SizedBox(height: 4 * scale),
                            if (isLlm) ...[
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6 * scale,
                                  vertical: 2 * scale,
                                ),
                                decoration: BoxDecoration(
                                  color: langColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(
                                    4 * scale,
                                  ),
                                  border: Border.all(
                                    color: langColor.withOpacity(0.5),
                                  ),
                                ),
                                child: Text(
                                  langText,
                                  style: TextStyle(
                                    fontSize: 10 * scale,
                                    color: langColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ] else if (isVAE) ...[
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6 * scale,
                                  vertical: 2 * scale,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.pink.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(
                                    4 * scale,
                                  ),
                                  border: Border.all(
                                    color: Colors.pink.withOpacity(0.5),
                                  ),
                                ),
                                child: Text(
                                  "Image Gen (VAE)",
                                  style: TextStyle(
                                    fontSize: 10 * scale,
                                    color: Colors.pinkAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ] else ...[
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6 * scale,
                                  vertical: 2 * scale,
                                ),
                                decoration: BoxDecoration(
                                  color: isRF
                                      ? Colors.orange.withOpacity(0.15)
                                      : Colors.blue.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(
                                    4 * scale,
                                  ),
                                  border: Border.all(
                                    color: isRF
                                        ? Colors.orange.withOpacity(0.5)
                                        : Colors.blue.withOpacity(0.5),
                                  ),
                                ),
                                child: Text(
                                  isRF ? "Random Forest" : "Neural Network",
                                  style: TextStyle(
                                    fontSize: 10 * scale,
                                    color: isRF
                                        ? Colors.orangeAccent
                                        : Colors.blueAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: l10n.tooltipExport,
                              icon: Icon(
                                Icons.ios_share,
                                color: Colors.orangeAccent,
                                size: 24 * scale,
                              ),
                              onPressed: () =>
                                  ShareManager.showExportDialog(context, proj),
                            ),
                            IconButton(
                              tooltip: l10n.tooltipCopy,
                              icon: Icon(
                                Icons.copy,
                                color: Colors.blue,
                                size: 24 * scale,
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CreateProjectScreen(sourceProject: proj),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: l10n.tooltipDelete,
                              icon: Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 24 * scale,
                              ),
                              onPressed: () =>
                                  _confirmDelete(context, proj.id, proj.name),
                            ),
                          ],
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider(
                                create: (_) => ProjectState(proj),
                                child: const ProjectDetailScreen(),
                              ),
                            ),
                          );
                          if (context.mounted) {
                            context.read<AppState>().refreshProjects();
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: appState.projects.isEmpty
          ? null
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0 * scale),
              child: Row(
                children: [
                  if (hasLlmProject) ...[
                    Expanded(
                      child: FloatingActionButton.extended(
                        heroTag: "btn_group_chat",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GroupChatScreen(),
                            ),
                          );
                        },
                        icon: Icon(Icons.forum, size: 22 * scale),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            l10n.btnRoundtable,
                            style: TextStyle(fontSize: 15 * scale),
                          ),
                        ),
                        backgroundColor: Colors.purple.shade800,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12 * scale),
                  ] else
                    const Spacer(),
                  Expanded(
                    child: FloatingActionButton.extended(
                      heroTag: "btn_new_project",
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateProjectScreen(),
                        ),
                      ),
                      icon: Icon(Icons.add, size: 22 * scale),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          l10n.btnNewProject,
                          style: TextStyle(fontSize: 15 * scale),
                        ),
                      ),
                      backgroundColor: Colors.green.shade800,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeScreen(
    BuildContext context,
    AppState appState,
    double scale,
    AppLocalizations l10n,
  ) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.0 * scale),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, size: 80 * scale, color: Colors.green),
              SizedBox(height: 16 * scale),
              Text(
                l10n.welcomeTitle,
                style: TextStyle(
                  fontSize: 24 * scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16 * scale),
              Text(
                l10n.welcomeDesc,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16 * scale),
              ),
              SizedBox(height: 24 * scale),
              Container(
                padding: EdgeInsets.all(16 * scale),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12 * scale),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.welcomeStepTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                        fontSize: 16 * scale,
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    Text(
                      l10n.welcomeStepDesc,
                      style: TextStyle(fontSize: 15 * scale),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32 * scale),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24 * scale,
                    vertical: 12 * scale,
                  ),
                  backgroundColor: Colors.green.shade800,
                  foregroundColor: Colors.white,
                ),
                icon: Icon(Icons.play_arrow, size: 24 * scale),
                label: Text(
                  l10n.btnStartWithSample,
                  style: TextStyle(fontSize: 16 * scale),
                ),
                onPressed: () => appState.addSamplePresets(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ★ Kaggle CSVインポートボタンのウィジェット
  Widget _buildKaggleImportButton(BuildContext context, double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16.0 * scale,
        vertical: 8.0 * scale,
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16 * scale),
          backgroundColor: Colors.teal.shade800,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12 * scale),
          ),
        ),
        icon: Icon(Icons.table_chart, size: 28 * scale),
        label: Text(
          "Kaggle CSV Import (Beta)",
          style: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          // ★ 新しく作成するCSVインポート画面へ遷移
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CsvImportConfigScreen()),
          );
        },
      ),
    );
  }
}
