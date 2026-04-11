import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models.dart';
import 'main.dart'; // AppStateやScaleUtilを読み込むため
import 'l10n/app_localizations.dart'; // ★辞書のインポートを追加

class GroupChatSelectTab extends StatefulWidget {
  final List<ChatCharacter> selectedCharacters;
  final VoidCallback onSelectionChanged;

  const GroupChatSelectTab({
    super.key,
    required this.selectedCharacters,
    required this.onSelectionChanged,
  });

  @override
  State<GroupChatSelectTab> createState() => _GroupChatSelectTabState();
}

class _GroupChatSelectTabState extends State<GroupChatSelectTab> {
  final List<Color> _colorPalette = [
    Colors.blueAccent,
    Colors.redAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
  ];

  void _addCharacter(NeuralProject proj) {
    final l10n = AppLocalizations.of(context)!; // ★辞書を呼び出し

    if (widget.selectedCharacters.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.msgMaxCharacters, // ★辞書を使用
            style: TextStyle(fontSize: 14 * ScaleUtil.scale(context)),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (widget.selectedCharacters.isNotEmpty) {
      final appState = context.read<AppState>();
      String firstCharProjectId = widget.selectedCharacters.first.projectId;

      try {
        final firstProj = appState.projects.firstWhere(
          (p) => p.id == firstCharProjectId,
        );

        if (firstProj.langMode != proj.langMode) {
          String currentLang = firstProj.langMode == 1
              ? l10n.langEnglish
              : l10n.langHiragana;
          String newLang = proj.langMode == 1
              ? l10n.langEnglish
              : l10n.langHiragana;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "${l10n.msgLanguageMismatchTitle}\n${l10n.msgLanguageMismatchDesc(currentLang, newLang)}", // ★辞書を使用
                style: TextStyle(
                  fontSize: 14 * ScaleUtil.scale(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.orange.shade800,
            ),
          );
          return;
        }
      } catch (e) {}
    }

    String baseName = proj.name;
    int count = widget.selectedCharacters
        .where((c) => c.projectId == proj.id)
        .length;
    String charName = count == 0 ? baseName : "$baseName(${count + 1})";

    List<int> usedColors = widget.selectedCharacters
        .map((c) => c.colorValue)
        .toList();

    Color charColor = _colorPalette.first;
    for (Color color in _colorPalette) {
      if (!usedColors.contains(color.value)) {
        charColor = color;
        break;
      }
    }

    setState(() {
      widget.selectedCharacters.add(
        ChatCharacter(
          projectId: proj.id,
          characterName: charName,
          colorValue: charColor.value,
        ),
      );
    });

    widget.onSelectionChanged();
  }

  void _removeCharacter(int index) {
    setState(() {
      widget.selectedCharacters.removeAt(index);
    });
    widget.onSelectionChanged();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final double scale = ScaleUtil.scale(context);
    final l10n = AppLocalizations.of(context)!; // ★辞書を呼び出し

    final llmProjects = appState.projects.where((p) => p.mode == 1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16 * scale),
          color: Colors.grey.shade900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.participatingCharacters(
                  widget.selectedCharacters.length,
                ), // ★辞書を使用
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16 * scale,
                ),
              ),
              SizedBox(height: 12 * scale),
              if (widget.selectedCharacters.isEmpty)
                Text(
                  l10n.msgEmptyCharacters, // ★辞書を使用
                  style: TextStyle(color: Colors.grey, fontSize: 13 * scale),
                )
              else
                Wrap(
                  spacing: 12 * scale,
                  runSpacing: 12 * scale,
                  children: widget.selectedCharacters.asMap().entries.map((
                    entry,
                  ) {
                    int idx = entry.key;
                    ChatCharacter char = entry.value;
                    Color cColor = Color(char.colorValue);

                    return Chip(
                      avatar: CircleAvatar(
                        backgroundColor: cColor,
                        child: Text(
                          char.characterName.substring(0, 1),
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12 * scale,
                          ),
                        ),
                      ),
                      label: Text(
                        char.characterName,
                        style: TextStyle(fontSize: 14 * scale),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20 * scale),
                        side: BorderSide(color: cColor, width: 2),
                      ),
                      backgroundColor: Colors.black87,
                      deleteIcon: Icon(
                        Icons.cancel,
                        size: 20 * scale,
                        color: Colors.grey,
                      ),
                      onDeleted: () => _removeCharacter(idx),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),

        Padding(
          padding: EdgeInsets.all(16 * scale),
          child: Text(
            l10n.selectAiToInvite, // ★辞書を使用
            style: TextStyle(
              color: Colors.purpleAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16 * scale,
            ),
          ),
        ),

        Expanded(
          child: llmProjects.isEmpty
              ? Center(
                  child: Text(
                    l10n.msgNoLlmProjects, // ★辞書を使用
                    style: TextStyle(color: Colors.grey, fontSize: 14 * scale),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: llmProjects.length,
                  itemBuilder: (context, index) {
                    final proj = llmProjects[index];

                    String langText = proj.langMode == 1
                        ? l10n.langEnglish
                        : l10n.langHiragana; // ★辞書を使用
                    Color langColor = proj.langMode == 1
                        ? Colors.blueAccent
                        : Colors.greenAccent;

                    return Card(
                      margin: EdgeInsets.symmetric(
                        horizontal: 16 * scale,
                        vertical: 6 * scale,
                      ),
                      color: Colors.black87,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade800),
                        borderRadius: BorderRadius.circular(8 * scale),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.chat,
                          color: Colors.purpleAccent,
                          size: 28 * scale,
                        ),
                        title: Text(
                          proj.name,
                          style: TextStyle(
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.memoryDataCount(proj.data.length), // ★辞書を使用
                              style: TextStyle(
                                fontSize: 12 * scale,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 4 * scale),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6 * scale,
                                vertical: 2 * scale,
                              ),
                              decoration: BoxDecoration(
                                color: langColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4 * scale),
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
                          ],
                        ),
                        trailing: ElevatedButton.icon(
                          icon: Icon(Icons.person_add, size: 18 * scale),
                          label: Text(
                            l10n.btnAdd, // ★既存辞書を再利用
                            style: TextStyle(fontSize: 14 * scale),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade800,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _addCharacter(proj),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
