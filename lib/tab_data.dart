import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'models.dart';
import 'l10n/app_localizations.dart'; // ★辞書のインポートを追加

class DataTab extends StatelessWidget {
  const DataTab({super.key});

  // 表示用の賢いフォーマッター（カテゴリ名への変換＆小数点の整理）
  String _formatDataList(List<double> vals, List<FeatureDef> defs) {
    List<String> results = [];
    for (int i = 0; i < vals.length; i++) {
      if (i < defs.length) {
        var def = defs[i];
        if (def.type == 1) {
          // 分類（ドロップダウン）の場合は、設定された文字（「晴れ」など）に変換する
          int idx = vals[i].toInt();
          if (idx >= 0 && idx < def.categories.length) {
            results.add(def.categories[idx]);
            continue;
          }
        }
      }
      // 数値の場合：小数点以下を最大2桁までにし、末尾の無駄な0や「.」を消してスッキリさせる
      String s = vals[i].toStringAsFixed(2);
      if (s.contains('.')) {
        s = s.replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
      }
      results.add(s);
    }
    return results.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProjectState>();
    final proj = state.proj;
    final double scale = ScaleUtil.scale(context);
    final l10n = AppLocalizations.of(context)!; // ★辞書を呼び出し

    Widget content;

    // ＝＝＝ 💬 生成AIモードの専用データ入力画面 ＝＝＝
    if (proj.mode == 1) {
      TextEditingController textCtrl = TextEditingController();

      // 言語に合わせてUIの案内文を切り替える
      String langName = proj.langMode == 1
          ? l10n.langEnglish
          : l10n.langHiragana;
      String hintExample = proj.langMode == 1
          ? "「Once upon a time...」"
          : "「むかしむかしあるところに...」";
      String warningText = proj.langMode == 1
          ? l10n.warningTextEnglish
          : l10n.warningTextHiragana;

      content = Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.0 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.readAiTextTitle(langName),
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8 * scale),
              Text(
                l10n.readAiTextDesc(hintExample),
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13 * scale,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 12 * scale),

              // 注意喚起の表示
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8 * scale),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.orangeAccent.withOpacity(0.5),
                  ),
                  borderRadius: BorderRadius.circular(4 * scale),
                  color: Colors.orange.withOpacity(0.1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orangeAccent,
                      size: 16 * scale,
                    ),
                    SizedBox(width: 8 * scale),
                    Expanded(
                      child: Text(
                        warningText,
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 8 * scale),

              TextField(
                controller: textCtrl,
                minLines: 15,
                maxLines: 15,
                maxLength: 10000,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(fontSize: 16 * scale),
                decoration: InputDecoration(
                  hintText: l10n.pasteTextHint,
                  hintStyle: TextStyle(fontSize: 16 * scale),
                  filled: true,
                  fillColor: Colors.black87,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8 * scale),
                  ),
                ),
              ),
              SizedBox(height: 16 * scale),
              Text(
                l10n.currentMemoryDataCount(proj.data.length),
                style: TextStyle(color: Colors.grey, fontSize: 14 * scale),
              ),
              SizedBox(height: 8 * scale),
              SizedBox(
                width: double.infinity,
                height: 60 * scale,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.auto_awesome, size: 24 * scale),
                  // ★ 修正：FittedBoxで囲んで、文字が長い場合は1行に収まるように自動縮小させる
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      l10n.btnAutoGenerateData,
                      style: TextStyle(fontSize: 16 * scale),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade800,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    String rawText = textCtrl.text;
                    if (rawText.trim().isEmpty) return;

                    if (proj.data.length + rawText.length > 15000) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(
                            l10n.dataLimitWarningTitle,
                            style: TextStyle(fontSize: 20 * scale),
                          ),
                          content: Text(
                            l10n.dataLimitWarningDesc,
                            style: TextStyle(fontSize: 16 * scale),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(
                                l10n.btnConfirm,
                                style: TextStyle(fontSize: 16 * scale),
                              ),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    // 無効な文字が含まれていないかチェック
                    List<String> invalidChars = [];
                    for (int i = 0; i < rawText.length; i++) {
                      if (!proj.currentChars.contains(rawText[i])) {
                        if (!invalidChars.contains(rawText[i])) {
                          invalidChars.add(rawText[i]);
                        }
                      }
                    }

                    // 無効な文字があった場合はエラーダイアログを出す
                    if (invalidChars.isNotEmpty) {
                      String errorDetail = proj.langMode == 1
                          ? l10n.errorDetailEnglish
                          : l10n.errorDetailHiragana;

                      String foundChars =
                          "${invalidChars.take(15).join(', ')}${invalidChars.length > 15 ? ' ...' : ''}";

                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(
                            l10n.errorUnsupportedCharsTitle,
                            style: TextStyle(fontSize: 18 * scale),
                          ),
                          content: Text(
                            l10n.errorUnsupportedCharsDesc(
                              errorDetail,
                              foundChars,
                            ),
                            style: TextStyle(fontSize: 14 * scale),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(
                                l10n.btnConfirm,
                                style: TextStyle(fontSize: 16 * scale),
                              ),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    // 抽出に必要な最低文字数のチェック
                    if (rawText.length <= proj.nGramCount) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.msgNotEnoughChars(proj.nGramCount + 1),
                            style: TextStyle(fontSize: 14 * scale),
                          ),
                        ),
                      );
                      return;
                    }

                    // データ追加処理
                    int beforeCount = proj.data.length;
                    state.appendDataFromText(rawText);
                    int added = proj.data.length - beforeCount;

                    textCtrl.clear();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.msgDataAddedFromText(added),
                          style: TextStyle(fontSize: 14 * scale),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 8 * scale),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  icon: Icon(
                    Icons.delete_sweep,
                    color: Colors.redAccent,
                    size: 24 * scale,
                  ),
                  label: Text(
                    l10n.btnClearAllMemory,
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16 * scale,
                    ),
                  ),
                  onPressed: () {
                    if (proj.data.isEmpty && textCtrl.text.isEmpty) return;
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(
                          l10n.warningTitle,
                          style: TextStyle(fontSize: 20 * scale),
                        ),
                        content: Text(
                          l10n.clearAllMemoryDesc,
                          style: TextStyle(fontSize: 16 * scale),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              l10n.btnCancel,
                              style: TextStyle(fontSize: 16 * scale),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              textCtrl.clear();
                              proj.rawText = null;
                              state.clearAllData();
                              Navigator.pop(ctx);
                            },
                            child: Text(
                              l10n.btnClear,
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
              ),
              SizedBox(height: 80 * scale),
            ],
          ),
        ),
      );
    }
    // ＝＝＝ 📊 通常モードの画面 ＝＝＝
    else {
      content = Scaffold(
        backgroundColor: Colors.transparent,
        body: ListView.builder(
          padding: EdgeInsets.only(bottom: 100 * scale),
          itemCount: proj.data.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildTopButtons(context, state, proj, scale, l10n);
            }

            final dataIndex = index - 1;
            final d = proj.data[dataIndex];
            return Card(
              margin: EdgeInsets.symmetric(
                horizontal: 8 * scale,
                vertical: 4 * scale,
              ),
              color: Colors.black87,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade800),
                borderRadius: BorderRadius.circular(8 * scale),
              ),
              child: ListTile(
                title: Text(
                  "${l10n.inputPrefix}${_formatDataList(d.inputs, proj.inputDefs)}",
                  style: TextStyle(
                    fontSize: 13 * scale,
                    color: Colors.greenAccent,
                  ),
                ),
                subtitle: Text(
                  "${l10n.outputPrefix}${_formatDataList(d.outputs, proj.outputDefs)}",
                  style: TextStyle(
                    fontSize: 13 * scale,
                    color: Colors.orangeAccent,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: Colors.blueAccent,
                        size: 24 * scale,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => _AddDataDialog(
                            state: state,
                            editIndex: dataIndex,
                            initialData: d,
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: Colors.redAccent,
                        size: 24 * scale,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(
                              l10n.confirmDataDeleteTitle,
                              style: TextStyle(fontSize: 20 * scale),
                            ),
                            content: Text(
                              l10n.confirmDataDeleteDesc,
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
                                  state.removeDataAt(dataIndex);
                                  Navigator.pop(ctx);
                                },
                                child: Text(
                                  l10n.btnDelete,
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
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => _AddDataDialog(state: state),
            );
          },
          icon: Icon(Icons.add, size: 24 * scale),
          label: Text(
            l10n.btnManualDataInput,
            style: TextStyle(fontSize: 16 * scale),
          ),
          backgroundColor: Colors.green.shade800,
          foregroundColor: Colors.white,
        ),
      );
    }

    return Stack(
      children: [
        AbsorbPointer(
          absorbing: state.isTraining,
          child: Opacity(opacity: state.isTraining ? 0.4 : 1.0, child: content),
        ),

        if (state.isTraining)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.redAccent.shade700,
              padding: EdgeInsets.symmetric(vertical: 8 * scale),
              child: Text(
                l10n.msgDataLockedDuringTraining,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12 * scale,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // 画面上部の入出力ボタン群
  Widget _buildTopButtons(
    BuildContext context,
    ProjectState state,
    NeuralProject proj,
    double scale,
    AppLocalizations l10n, // ★辞書を受け取る
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8.0 * scale,
        vertical: 12.0 * scale,
      ),
      margin: EdgeInsets.only(bottom: 8.0 * scale),
      color: Colors.grey.shade900,
      child: Column(
        children: [
          Text(
            l10n.batchDataManagement,
            style: TextStyle(fontSize: 12 * scale, color: Colors.grey),
          ),
          SizedBox(height: 8 * scale),
          Wrap(
            spacing: 8 * scale,
            runSpacing: 8 * scale,
            alignment: WrapAlignment.center,
            children: [
              // ▼ インポート系 ▼
              ElevatedButton.icon(
                icon: Icon(Icons.content_paste, size: 18 * scale),
                label: Text(
                  l10n.btnPaste,
                  style: TextStyle(fontSize: 14 * scale),
                ),
                onPressed: () => state.importFromClipboard(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.file_download, size: 18 * scale),
                label: Text(
                  l10n.btnReadCSV,
                  style: TextStyle(fontSize: 14 * scale),
                ),
                onPressed: () => state.importFromCSV(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                ),
              ),
              // ▼ エクスポート系 ▼
              if (proj.data.isNotEmpty)
                ElevatedButton.icon(
                  icon: Icon(Icons.copy, size: 18 * scale),
                  label: Text(
                    l10n.btnCopy,
                    style: TextStyle(fontSize: 14 * scale),
                  ),
                  onPressed: () => state.exportToClipboard(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              if (proj.data.isNotEmpty)
                ElevatedButton.icon(
                  icon: Icon(Icons.file_upload, size: 18 * scale),
                  label: Text(
                    l10n.btnSaveCSV,
                    style: TextStyle(fontSize: 14 * scale),
                  ),
                  onPressed: () => state.exportToCSV(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              // ▼ 削除系 ▼
              if (proj.data.isNotEmpty)
                ElevatedButton.icon(
                  icon: Icon(Icons.delete_sweep, size: 18 * scale),
                  label: Text(
                    l10n.btnDeleteAll,
                    style: TextStyle(fontSize: 14 * scale),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(
                          l10n.warningTitle,
                          style: TextStyle(fontSize: 20 * scale),
                        ),
                        content: Text(
                          l10n.deleteAllDataWarningDesc,
                          style: TextStyle(fontSize: 16 * scale),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              l10n.btnCancel,
                              style: TextStyle(fontSize: 16 * scale),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              state.clearAllData();
                              Navigator.pop(ctx);
                            },
                            child: Text(
                              l10n.btnClear,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
          if (proj.data.isEmpty) ...[
            SizedBox(height: 24 * scale),
            Text(
              l10n.noDataDesc,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                height: 1.5,
                fontSize: 14 * scale,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// === スマホでの手入力・編集用ダイアログ ===
class _AddDataDialog extends StatefulWidget {
  final ProjectState state;
  final int? editIndex;
  final TrainingData? initialData;

  const _AddDataDialog({required this.state, this.editIndex, this.initialData});

  @override
  State<_AddDataDialog> createState() => _AddDataDialogState();
}

class _AddDataDialogState extends State<_AddDataDialog> {
  late List<double> inVals;
  late List<double> outVals;

  @override
  void initState() {
    super.initState();
    final proj = widget.state.proj;

    if (widget.initialData != null) {
      inVals = List.from(widget.initialData!.inputs);
      outVals = List.from(widget.initialData!.outputs);
    } else {
      inVals = proj.inputDefs.map((d) => d.type == 1 ? 0.0 : d.min).toList();
      outVals = proj.outputDefs.map((d) => d.type == 1 ? 0.0 : d.min).toList();
    }
  }

  Widget _buildField(
    FeatureDef def,
    double currentVal,
    ValueChanged<double> onChanged,
    double scale,
  ) {
    if (def.type == 0) {
      return Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0 * scale),
              child: Slider(
                value: currentVal.clamp(def.min, def.max),
                min: def.min,
                max: def.max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 40 * scale,
            child: Text(
              currentVal.toStringAsFixed(1),
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14 * scale),
            ),
          ),
        ],
      );
    } else if (def.type == 1) {
      return DropdownButton<double>(
        isExpanded: true,
        value: currentVal,
        itemHeight: null,
        items: def.categories
            .asMap()
            .entries
            .map(
              (e) => DropdownMenuItem(
                value: e.key.toDouble(),
                child: Text(e.value, style: TextStyle(fontSize: 16 * scale)),
              ),
            )
            .toList(),
        onChanged: (v) => onChanged(v!),
      );
    } else {
      return TextFormField(
        initialValue: currentVal.toString(),
        style: TextStyle(fontSize: 16 * scale),
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        decoration: InputDecoration(
          hintText: "${def.min} ~ ${def.max}",
          hintStyle: TextStyle(fontSize: 16 * scale),
        ),
        onChanged: (v) {
          double? parsed = double.tryParse(v);
          if (parsed != null) onChanged(parsed);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final proj = widget.state.proj;
    final isEditing = widget.editIndex != null;
    final double scale = ScaleUtil.scale(context);
    final l10n = AppLocalizations.of(context)!; // ★辞書を呼び出し

    return AlertDialog(
      insetPadding: EdgeInsets.all(16 * scale),
      title: Text(
        isEditing ? l10n.editDataTitle : l10n.manualDataInputTitle,
        style: TextStyle(fontSize: 20 * scale),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 500 * scale),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.inputDataHeader,
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16 * scale,
                ),
              ),
              ...proj.inputDefs.asMap().entries.map((e) {
                int idx = e.key;
                FeatureDef def = e.value;
                return Padding(
                  padding: EdgeInsets.only(top: 8 * scale, bottom: 8 * scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        def.name,
                        style: TextStyle(
                          fontSize: 12 * scale,
                          color: Colors.grey,
                        ),
                      ),
                      _buildField(
                        def,
                        inVals[idx],
                        (v) => setState(() => inVals[idx] = v),
                        scale,
                      ),
                    ],
                  ),
                );
              }),
              Divider(height: 16 * scale),
              Text(
                l10n.outputDataHeader,
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16 * scale,
                ),
              ),
              ...proj.outputDefs.asMap().entries.map((e) {
                int idx = e.key;
                FeatureDef def = e.value;
                return Padding(
                  padding: EdgeInsets.only(top: 8 * scale, bottom: 8 * scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        def.name,
                        style: TextStyle(
                          fontSize: 12 * scale,
                          color: Colors.grey,
                        ),
                      ),
                      _buildField(
                        def,
                        outVals[idx],
                        (v) => setState(() => outVals[idx] = v),
                        scale,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            l10n.btnCancel,
            style: TextStyle(color: Colors.grey, fontSize: 16 * scale),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isEditing
                ? Colors.blue.shade800
                : Colors.green.shade800,
          ),
          onPressed: () {
            final newData = TrainingData(
              inputs: List.from(inVals),
              outputs: List.from(outVals),
            );

            if (isEditing) {
              proj.data[widget.editIndex!] = newData;
            } else {
              proj.data.add(newData);
            }

            widget.state.resetTraining();
            Navigator.pop(context);
          },
          child: Text(
            isEditing ? l10n.btnUpdate : l10n.btnAdd,
            style: TextStyle(fontSize: 16 * scale),
          ),
        ),
      ],
    );
  }
}
