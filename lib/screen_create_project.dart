import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'models.dart';
import 'share_manager.dart';
import 'l10n/app_localizations.dart'; // ★辞書のインポートを追加

class CreateProjectScreen extends StatefulWidget {
  final NeuralProject? sourceProject;
  const CreateProjectScreen({super.key, this.sourceProject});
  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  late TextEditingController _nameCtrl;
  late List<FeatureDef> inputs;
  late List<FeatureDef> outputs;
  late List<TrainingData> trainingData;
  bool _inheritData = true;
  int _selectedMode = 0;
  int _selectedLangMode = 0;

  bool _isInitTextSet = false; // ★初期名がセットされたかどうかのフラグ

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(); // ★ここで一旦空で初期化

    if (widget.sourceProject != null) {
      inputs = widget.sourceProject!.inputDefs.map((e) => e.clone()).toList();
      outputs = widget.sourceProject!.outputDefs.map((e) => e.clone()).toList();
      trainingData = widget.sourceProject!.data.map((e) => e.clone()).toList();
      _selectedMode = widget.sourceProject!.mode;
      _selectedLangMode = widget.sourceProject!.langMode;
    } else {
      inputs = [];
      outputs = [];
      trainingData = [];
      _selectedLangMode = 0;
    }
  }

  // ★initStateではcontextが使えないため、ここで辞書を使って初期名を入れる
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitTextSet) {
      final l10n = AppLocalizations.of(context)!;
      if (widget.sourceProject != null) {
        _nameCtrl.text = l10n.projectCopyName(widget.sourceProject!.name);
      } else {
        _nameCtrl.text = l10n.newProjectDefaultName;
      }
      _isInitTextSet = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _onStructureChanged() {
    if (trainingData.isNotEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.msgStructureChangedResetData,
            style: TextStyle(fontSize: 14 * ScaleUtil.scale(context)),
          ),
        ),
      );
      setState(() {
        trainingData.clear();
        _inheritData = false;
      });
    }
  }

  void _showAddDialog(bool isInput) {
    final l10n = AppLocalizations.of(context)!; // ★辞書
    String fName = "";
    int fType = 0;
    double fMin = 0, fMax = 100;
    List<String> categories = ["A", "B"];
    TextEditingController catCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text(
            isInput ? l10n.addInputTitle : l10n.addOutputTitle,
            style: TextStyle(fontSize: 20 * ScaleUtil.scale(ctx)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  style: TextStyle(fontSize: 16 * ScaleUtil.scale(ctx)),
                  decoration: InputDecoration(
                    labelText: l10n.itemNameLabel,
                    labelStyle: TextStyle(fontSize: 16 * ScaleUtil.scale(ctx)),
                  ),
                  onChanged: (v) => fName = v,
                ),
                DropdownButton<int>(
                  isExpanded: true,
                  value: fType,
                  itemHeight: null,
                  items: [
                    DropdownMenuItem(
                      value: 0,
                      child: Text(
                        l10n.typeNumericSlider,
                        style: TextStyle(fontSize: 16 * ScaleUtil.scale(ctx)),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 1,
                      child: Text(
                        l10n.typeCategoryDropdown,
                        style: TextStyle(fontSize: 16 * ScaleUtil.scale(ctx)),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 2,
                      child: Text(
                        l10n.typeNumericDirect,
                        style: TextStyle(fontSize: 16 * ScaleUtil.scale(ctx)),
                      ),
                    ),
                  ],
                  onChanged: (v) => setStateDialog(() => fType = v!),
                ),
                if (fType == 0 || fType == 2) ...[
                  TextField(
                    style: TextStyle(fontSize: 16 * ScaleUtil.scale(ctx)),
                    decoration: InputDecoration(
                      labelText: l10n.minValueLabel,
                      labelStyle: TextStyle(
                        fontSize: 16 * ScaleUtil.scale(ctx),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => fMin = double.tryParse(v) ?? 0,
                  ),
                  TextField(
                    style: TextStyle(fontSize: 16 * ScaleUtil.scale(ctx)),
                    decoration: InputDecoration(
                      labelText: l10n.maxValueLabel,
                      labelStyle: TextStyle(
                        fontSize: 16 * ScaleUtil.scale(ctx),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => fMax = double.tryParse(v) ?? 100,
                  ),
                ] else ...[
                  SizedBox(height: 16 * ScaleUtil.scale(ctx)),
                  Text(
                    l10n.editCategoriesLabel,
                    style: TextStyle(
                      fontSize: 12 * ScaleUtil.scale(ctx),
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8 * ScaleUtil.scale(ctx)),
                  Wrap(
                    spacing: 8 * ScaleUtil.scale(ctx),
                    runSpacing: 4 * ScaleUtil.scale(ctx),
                    children: categories.asMap().entries.map((e) {
                      int idx = e.key;
                      String cat = e.value;
                      return Chip(
                        label: Text(
                          cat,
                          style: TextStyle(fontSize: 14 * ScaleUtil.scale(ctx)),
                        ),
                        deleteIcon: Icon(
                          Icons.cancel,
                          size: 18 * ScaleUtil.scale(ctx),
                        ),
                        onDeleted: () {
                          setStateDialog(() {
                            categories.removeAt(idx);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: TextStyle(fontSize: 16 * ScaleUtil.scale(ctx)),
                          controller: catCtrl,
                          decoration: InputDecoration(
                            hintText: l10n.newCategoryHint,
                            hintStyle: TextStyle(
                              fontSize: 16 * ScaleUtil.scale(ctx),
                            ),
                          ),
                          onSubmitted: (v) {
                            if (v.trim().isNotEmpty) {
                              setStateDialog(() {
                                categories.add(v.trim());
                                catCtrl.clear();
                              });
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.add_circle,
                          color: Colors.green,
                          size: 24 * ScaleUtil.scale(ctx),
                        ),
                        onPressed: () {
                          if (catCtrl.text.trim().isNotEmpty) {
                            setStateDialog(() {
                              categories.add(catCtrl.text.trim());
                              catCtrl.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  if (categories.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 8.0 * ScaleUtil.scale(ctx)),
                      child: Text(
                        l10n.msgRequireOneCategory,
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12 * ScaleUtil.scale(ctx),
                        ),
                      ),
                    ),
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
              onPressed: (fType == 1 && categories.isEmpty)
                  ? null
                  : () {
                      final def = FeatureDef(
                        name: fName.isEmpty ? l10n.unnamedItem : fName,
                        type: fType,
                        min: fMin,
                        max: fMax,
                        categories: List.from(categories),
                      );
                      setState(() {
                        isInput ? inputs.add(def) : outputs.add(def);
                        _onStructureChanged();
                      });
                      Navigator.pop(ctx);
                    },
              child: Text(
                l10n.btnAdd,
                style: TextStyle(fontSize: 16 * ScaleUtil.scale(ctx)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveProject() {
    final l10n = AppLocalizations.of(context)!;

    // テキスト生成モードの自動定義
    if (_selectedMode == 1 && inputs.isEmpty) {
      String targetChars = _selectedLangMode == 1
          ? englishChars
          : hiraganaChars;
      List<String> charList = targetChars.split('');

      inputs = [];
      for (int i = 1; i <= 3; i++) {
        inputs.add(
          FeatureDef(name: l10n.pastChar(i), type: 1, categories: charList),
        );
      }
      outputs = [
        FeatureDef(name: l10n.nextOneChar, type: 1, categories: charList),
      ];
    }

    // ★ VAE画像生成モードの自動定義
    if (_selectedMode == 2 && inputs.isEmpty) {
      inputs = [
        FeatureDef(name: "Color Pixels (RGB)", type: 0, min: 0, max: 255),
      ];
      outputs = [
        FeatureDef(name: "Generated Pixels", type: 0, min: 0, max: 255),
      ];
    }

    if (inputs.isEmpty || outputs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.msgRequireInputOutput,
            style: TextStyle(fontSize: 14 * ScaleUtil.scale(context)),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 各モードのデフォルトパラメータを決定
    int defaultLayers = 1;
    int defaultNodes = 12;
    List<int>? defaultNodesList;
    double defaultLr = 0.1;
    bool defaultRandomSplit = true;
    int defaultLossType = 0;

    if (_selectedMode == 1) {
      // テキスト生成
      defaultLayers = 2;
      defaultNodes = 64;
      defaultLr = 0.01;
      defaultRandomSplit = false;
      defaultLossType = 1;
    } else if (_selectedMode == 2) {
      // VAE画像生成
      defaultLayers = 2;
      defaultNodes = 64;
      defaultNodesList = [64, 32];
      defaultLr = 0.005;
      defaultRandomSplit = false;
      defaultLossType = 0; // VAEは内部的にBCEやMSEを計算するのでベースは0でOK
    }

    final proj = NeuralProject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text,
      inputDefs: inputs,
      outputDefs: outputs,
      data: _inheritData ? trainingData : [],
      hiddenLayers: widget.sourceProject?.hiddenLayers ?? defaultLayers,
      hiddenNodes: widget.sourceProject?.hiddenNodes ?? defaultNodes,
      hiddenNodesList: widget.sourceProject != null
          ? List.from(widget.sourceProject!.hiddenNodesList)
          : defaultNodesList,
      optimizer: widget.sourceProject?.optimizer ?? 2,
      batchSize:
          widget.sourceProject?.batchSize ?? (_selectedMode == 2 ? 16 : 8),
      trainedModelJson: _inheritData
          ? widget.sourceProject?.trainedModelJson
          : null,
      mode: _selectedMode,
      ecoWaitMs:
          widget.sourceProject?.ecoWaitMs ?? (_selectedMode == 2 ? 50 : 50),
      learningRate: widget.sourceProject?.learningRate ?? defaultLr,
      isRandomSplit: widget.sourceProject?.isRandomSplit ?? defaultRandomSplit,
      lossType: widget.sourceProject?.lossType ?? defaultLossType,
      nGramCount: widget.sourceProject?.nGramCount ?? 3,
      rawText: _inheritData ? widget.sourceProject?.rawText : null,
      appVersion: ShareManager.currentAppVersion,
      langMode: _selectedLangMode,
      latentDim: widget.sourceProject?.latentDim ?? 4,
      klWeight: widget.sourceProject?.klWeight ?? 1.0,
      engineType: widget.sourceProject?.engineType ?? 0, // NN強制
    );
    context.read<AppState>().saveProject(proj);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final double scale = ScaleUtil.scale(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.sourceProject != null
              ? l10n.copyProjectTitle
              : l10n.createNewProjectTitle,
          style: TextStyle(fontSize: 20 * scale),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check, size: 24 * scale),
            onPressed: _saveProject,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16 * scale),
        children: [
          TextField(
            controller: _nameCtrl,
            style: TextStyle(fontSize: 16 * scale),
            decoration: InputDecoration(
              labelText: l10n.projectNameLabel,
              labelStyle: TextStyle(fontSize: 16 * scale),
            ),
          ),
          SizedBox(height: 16 * scale),
          Text(
            l10n.aiTypeLabel,
            style: TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16 * scale,
            ),
          ),
          SizedBox(height: 8 * scale),

          // ★ VAEモードを追加し、文字はみ出しを防ぐために縦並びのカードリストに変更
          Column(
            children: [
              // --- モード0：数値推論 ---
              InkWell(
                onTap: () {
                  if (_selectedMode != 0) {
                    setState(() {
                      _selectedMode = 0;
                      inputs.clear();
                      outputs.clear();
                      _onStructureChanged();
                    });
                  }
                },
                borderRadius: BorderRadius.circular(8 * scale),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 12 * scale,
                    horizontal: 16 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedMode == 0
                        ? Colors.green.shade900.withOpacity(0.4)
                        : Colors.transparent,
                    border: Border.all(
                      color: _selectedMode == 0
                          ? Colors.greenAccent
                          : Colors.grey.shade800,
                      width: _selectedMode == 0 ? 2.0 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8 * scale),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calculate,
                        size: 24 * scale,
                        color: _selectedMode == 0
                            ? Colors.greenAccent
                            : Colors.grey,
                      ),
                      SizedBox(width: 16 * scale),
                      Expanded(
                        child: Text(
                          l10n.typeNumericPredict,
                          style: TextStyle(
                            fontSize: 15 * scale,
                            color: _selectedMode == 0
                                ? Colors.white
                                : Colors.grey.shade400,
                            fontWeight: _selectedMode == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (_selectedMode == 0)
                        Icon(
                          Icons.check_circle,
                          color: Colors.greenAccent,
                          size: 20 * scale,
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8 * scale),

              // --- モード1：テキスト生成 ---
              InkWell(
                onTap: () {
                  if (_selectedMode != 1) {
                    setState(() {
                      _selectedMode = 1;
                      inputs.clear();
                      outputs.clear();
                      _onStructureChanged();
                    });
                  }
                },
                borderRadius: BorderRadius.circular(8 * scale),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 12 * scale,
                    horizontal: 16 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedMode == 1
                        ? Colors.green.shade900.withOpacity(0.4)
                        : Colors.transparent,
                    border: Border.all(
                      color: _selectedMode == 1
                          ? Colors.greenAccent
                          : Colors.grey.shade800,
                      width: _selectedMode == 1 ? 2.0 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8 * scale),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat,
                        size: 24 * scale,
                        color: _selectedMode == 1
                            ? Colors.greenAccent
                            : Colors.grey,
                      ),
                      SizedBox(width: 16 * scale),
                      Expanded(
                        child: Text(
                          l10n.typeTextGeneration,
                          style: TextStyle(
                            fontSize: 15 * scale,
                            color: _selectedMode == 1
                                ? Colors.white
                                : Colors.grey.shade400,
                            fontWeight: _selectedMode == 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (_selectedMode == 1)
                        Icon(
                          Icons.check_circle,
                          color: Colors.greenAccent,
                          size: 20 * scale,
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8 * scale),

              // --- モード2：画像生成 (VAE) ---
              InkWell(
                onTap: () {
                  if (_selectedMode != 2) {
                    setState(() {
                      _selectedMode = 2;
                      inputs.clear();
                      outputs.clear();
                      _onStructureChanged();
                    });
                  }
                },
                borderRadius: BorderRadius.circular(8 * scale),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 12 * scale,
                    horizontal: 16 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedMode == 2
                        ? Colors.green.shade900.withOpacity(0.4)
                        : Colors.transparent,
                    border: Border.all(
                      color: _selectedMode == 2
                          ? Colors.greenAccent
                          : Colors.grey.shade800,
                      width: _selectedMode == 2 ? 2.0 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8 * scale),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.image,
                        size: 24 * scale,
                        color: _selectedMode == 2
                            ? Colors.greenAccent
                            : Colors.grey,
                      ),
                      SizedBox(width: 16 * scale),
                      Expanded(
                        child: Text(
                          "Image Gen (VAE)", // ★ ハードコーディング
                          style: TextStyle(
                            fontSize: 15 * scale,
                            color: _selectedMode == 2
                                ? Colors.white
                                : Colors.grey.shade400,
                            fontWeight: _selectedMode == 2
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (_selectedMode == 2)
                        Icon(
                          Icons.check_circle,
                          color: Colors.greenAccent,
                          size: 20 * scale,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16 * scale),

          if (_selectedMode == 0) ...[
            if (widget.sourceProject != null)
              CheckboxListTile(
                title: Text(
                  l10n.inheritDataLabel,
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 16 * scale,
                  ),
                ),
                value: _inheritData,
                onChanged: (v) => setState(() => _inheritData = v!),
              ),
            SizedBox(height: 20 * scale),
            ElevatedButton(
              onPressed: () => _showAddDialog(true),
              child: Text(
                l10n.btnAddInput,
                style: TextStyle(fontSize: 16 * scale),
              ),
            ),
            ...inputs.asMap().entries.map(
              (entry) => ListTile(
                title: Text(
                  entry.value.name,
                  style: TextStyle(fontSize: 16 * scale),
                ),
                subtitle: Text(
                  entry.value.type == 1
                      ? l10n.categoryFormat(entry.value.categories.join(','))
                      : l10n.numericFormat(entry.value.min, entry.value.max),
                  style: TextStyle(fontSize: 14 * scale),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                    size: 24 * scale,
                  ),
                  onPressed: () => setState(() {
                    inputs.removeAt(entry.key);
                    _onStructureChanged();
                  }),
                ),
              ),
            ),
            Divider(),
            ElevatedButton(
              onPressed: () => _showAddDialog(false),
              child: Text(
                l10n.btnAddOutput,
                style: TextStyle(fontSize: 16 * scale),
              ),
            ),
            ...outputs.asMap().entries.map(
              (entry) => ListTile(
                title: Text(
                  entry.value.name,
                  style: TextStyle(fontSize: 16 * scale),
                ),
                subtitle: Text(
                  entry.value.type == 1
                      ? l10n.categoryFormat(entry.value.categories.join(','))
                      : l10n.numericFormat(entry.value.min, entry.value.max),
                  style: TextStyle(fontSize: 14 * scale),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                    size: 24 * scale,
                  ),
                  onPressed: () => setState(() {
                    outputs.removeAt(entry.key);
                    _onStructureChanged();
                  }),
                ),
              ),
            ),
          ] else if (_selectedMode == 1) ...[
            Text(
              l10n.learningLanguageLabel,
              style: TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16 * scale,
              ),
            ),
            SizedBox(height: 8 * scale),
            SegmentedButton<int>(
              segments: [
                ButtonSegment(
                  value: 0,
                  label: Text(
                    l10n.langHiragana,
                    style: TextStyle(fontSize: 14 * scale),
                  ),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text(
                    l10n.langEnglish,
                    style: TextStyle(fontSize: 14 * scale),
                  ),
                ),
              ],
              selected: {_selectedLangMode},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() {
                  _selectedLangMode = newSelection.first;
                  inputs.clear();
                  outputs.clear();
                  _onStructureChanged();
                });
              },
            ),
            SizedBox(height: 16 * scale),

            Container(
              padding: EdgeInsets.all(12 * scale),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8 * scale),
              ),
              child: Text(
                l10n.descTextGenerationMode,
                style: TextStyle(
                  color: Colors.white70,
                  height: 1.5,
                  fontSize: 14 * scale,
                ),
              ),
            ),
          ] else if (_selectedMode == 2) ...[
            // ★ VAEモード時の説明文（英語ハードコーディング）
            Container(
              padding: EdgeInsets.all(12 * scale),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8 * scale),
              ),
              child: Text(
                "Image Generation Mode (VAE):\n\n"
                "Train an AI to generate 16x16 pixel art. Upload images in the Data tab to build a visual scrapbook for the AI. "
                "The neural network will learn the underlying patterns and allow you to dynamically generate new pixel art via the latent space sliders.\n\n"
                "* Input/Output layers and latent dimensions (Z-space) are configured automatically.",
                style: TextStyle(
                  color: Colors.white70,
                  height: 1.5,
                  fontSize: 14 * scale,
                ),
              ),
            ),
          ],

          SizedBox(height: 32 * scale),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16 * scale),
              backgroundColor: Colors.green.shade800,
              foregroundColor: Colors.white,
            ),
            icon: Icon(Icons.check_circle, size: 28 * scale),
            label: Text(
              widget.sourceProject != null
                  ? l10n.btnCreateCopy
                  : l10n.btnCreateProject,
              style: TextStyle(
                fontSize: 16 * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: _saveProject,
          ),
          SizedBox(height: 40 * scale),
        ],
      ),
    );
  }
}
