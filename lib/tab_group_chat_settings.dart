import 'package:flutter/material.dart';

import 'models.dart';
import 'main.dart'; // ScaleUtilを読み込むため
import 'l10n/app_localizations.dart'; // ★辞書のインポートを追加

class GroupChatSettingsTab extends StatefulWidget {
  final List<ChatCharacter> selectedCharacters;
  final VoidCallback onSettingsChanged;

  const GroupChatSettingsTab({
    super.key,
    required this.selectedCharacters,
    required this.onSettingsChanged,
  });

  @override
  State<GroupChatSettingsTab> createState() => _GroupChatSettingsTabState();
}

class _GroupChatSettingsTabState extends State<GroupChatSettingsTab> {
  // ★ 修正：pinkAccent を外し、はっきり見分けがつく tealAccent(青緑) などに変更
  final List<Color> _availableColors = [
    Colors.blueAccent,
    Colors.redAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.yellowAccent,
    Colors.cyanAccent,
    Colors.amberAccent, // ← ここを変更
  ];

  // ★ 修正：辞書を使うために BuildContext を引数に追加
  String _getFrequencyLabel(BuildContext context, int freq) {
    final l10n = AppLocalizations.of(context)!;
    switch (freq) {
      case 1:
        return l10n.freqQuiet;
      case 2:
        return l10n.freqReserved;
      case 3:
        return l10n.freqNormal;
      case 4:
        return l10n.freqActive;
      case 5:
        return l10n.freqChatty;
      default:
        return "$freq";
    }
  }

  @override
  Widget build(BuildContext context) {
    final double scale = ScaleUtil.scale(context);
    final l10n = AppLocalizations.of(context)!; // ★辞書を呼び出し

    // ★ 追加：画面全体をGestureDetectorで包み、どこをタップしてもキーボードが閉じるようにする
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque, // 余白タップにも反応させるための設定
      child: widget.selectedCharacters.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.tune,
                    size: 60 * scale,
                    color: Colors.grey.shade700,
                  ),
                  SizedBox(height: 16 * scale),
                  Text(
                    l10n.msgNoAiInRoundtable, // ★既存の辞書を再利用
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16 * scale),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16 * scale),
              itemCount: widget.selectedCharacters.length,
              itemBuilder: (context, index) {
                final char = widget.selectedCharacters[index];
                final Color charColor = Color(char.colorValue);

                return Card(
                  margin: EdgeInsets.only(bottom: 24 * scale),
                  color: Colors.black87,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: charColor.withOpacity(0.6),
                      width: 2 * scale,
                    ),
                    borderRadius: BorderRadius.circular(12 * scale),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16 * scale),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ＝＝＝ ✏️ キャラクター名の編集欄 ＝＝＝
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: charColor,
                              radius: 18 * scale,
                              child: Text(
                                char.characterName.isNotEmpty
                                    ? char.characterName.substring(0, 1)
                                    : "?",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16 * scale,
                                ),
                              ),
                            ),
                            SizedBox(width: 12 * scale),
                            Expanded(
                              child: TextFormField(
                                initialValue: char.characterName, // 初期値はプロジェクト名
                                style: TextStyle(
                                  color: charColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18 * scale,
                                ),
                                textInputAction: TextInputAction
                                    .done, // ★ 追加：キーボードのボタンを「完了」にする
                                onFieldSubmitted: (_) {
                                  // ★ 追加：完了ボタンを押した時も明示的にキーボードを閉じる
                                  FocusManager.instance.primaryFocus?.unfocus();
                                },
                                decoration: InputDecoration(
                                  labelText: l10n.characterNameLabel, // ★辞書を使用
                                  labelStyle: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12 * scale,
                                  ),
                                  isDense: true,
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: charColor),
                                  ),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    // 空欄にされた場合は「名無し」にする
                                    char.characterName = val.trim().isEmpty
                                        ? l10n
                                              .nameless // ★辞書を使用
                                        : val;
                                  });
                                  // 変更を親に伝えて、他のタブにもリアルタイム反映させる
                                  widget.onSettingsChanged();
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16 * scale),

                        // ＝＝＝ 🎨 カラーパレット（テーマカラー選択） ＝＝＝
                        Text(
                          l10n.themeColor, // ★辞書を使用
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14 * scale,
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        Wrap(
                          spacing: 12 * scale,
                          runSpacing: 8 * scale,
                          children: _availableColors.map((color) {
                            bool isSelected = char.colorValue == color.value;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  char.colorValue = color.value; // 色を更新
                                });
                                widget.onSettingsChanged(); // 親にも通知
                              },
                              child: Container(
                                width: 32 * scale,
                                height: 32 * scale,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: isSelected ? 3 * scale : 0,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: color.withOpacity(0.8),
                                            blurRadius: 8 * scale,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 16 * scale),
                        Divider(
                          color: Colors.grey.shade800,
                          height: 16 * scale,
                        ),

                        // ＝＝＝ ① ゆらぎ (Temperature) 設定 ＝＝＝
                        Text(
                          l10n.temperatureLabel(
                            char.temperature.toStringAsFixed(1),
                          ), // ★辞書を使用
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14 * scale,
                          ),
                        ),
                        Text(
                          l10n.temperatureDesc, // ★辞書を使用
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12 * scale,
                          ),
                        ),
                        Slider(
                          value: char.temperature,
                          min: 0.1,
                          max: 2.0,
                          divisions: 19,
                          activeColor: charColor,
                          onChanged: (val) {
                            setState(() => char.temperature = val);
                            widget.onSettingsChanged();
                          },
                        ),
                        SizedBox(height: 16 * scale),

                        // ＝＝＝ ② 発言頻度 (Frequency) 設定 ＝＝＝
                        Text(
                          l10n.frequencyLabel(
                            _getFrequencyLabel(context, char.frequency),
                          ), // ★辞書を使用
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14 * scale,
                          ),
                        ),
                        Text(
                          l10n.frequencyDesc, // ★辞書を使用
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12 * scale,
                          ),
                        ),
                        Slider(
                          value: char.frequency.toDouble(),
                          min: 1,
                          max: 5,
                          divisions: 4,
                          activeColor: charColor,
                          onChanged: (val) {
                            setState(() => char.frequency = val.toInt());
                            widget.onSettingsChanged();
                          },
                        ),
                        SizedBox(height: 16 * scale),

                        // ＝＝＝ ③ 最大発言文字数設定 ＝＝＝
                        Text(
                          l10n.maxLengthLabel(char.maxLength), // ★辞書を使用
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14 * scale,
                          ),
                        ),
                        Text(
                          l10n.maxLengthDesc, // ★辞書を使用
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12 * scale,
                          ),
                        ),
                        Slider(
                          value: char.maxLength.toDouble(),
                          min: 5,
                          max: 100,
                          divisions: 95,
                          activeColor: charColor,
                          onChanged: (val) {
                            setState(() => char.maxLength = val.toInt());
                            widget.onSettingsChanged();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
