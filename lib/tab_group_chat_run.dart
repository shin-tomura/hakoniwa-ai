import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models.dart';
import 'nn_engine.dart';
import 'main.dart';
import 'l10n/app_localizations.dart'; // ★辞書のインポートを追加

// タイムラインに表示する1つの吹き出し（メッセージ）のデータ
class ChatMessage {
  final String senderName;
  final String text;
  final Color color;
  final bool isUser; // ユーザーの介入発言かどうか

  ChatMessage({
    required this.senderName,
    required this.text,
    required this.color,
    this.isUser = false,
  });
}

class GroupChatRunTab extends StatefulWidget {
  final List<ChatCharacter> selectedCharacters;

  const GroupChatRunTab({super.key, required this.selectedCharacters});

  @override
  State<GroupChatRunTab> createState() => _GroupChatRunTabState();
}

class _GroupChatRunTabState extends State<GroupChatRunTab> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  // AIが考え中（テキスト生成中）かどうか
  bool _isGenerating = false;

  // 直前に発言したAIの名前を記憶（連続発言防止用）
  String? _lastSpeakerName;

  // メモリ上にロードしたAIの脳（NeuralNetwork）とプロジェクト情報をキャッシュするマップ
  // key: projectId
  final Map<String, NeuralNetwork> _loadedNetworks = {};
  final Map<String, NeuralProject> _loadedProjects = {};

  bool _isInitMessageSet = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitMessageSet) {
      final l10n = AppLocalizations.of(context)!;
      // 最初の案内メッセージ
      _messages.add(
        ChatMessage(
          senderName: l10n.systemName,
          text: l10n.welcomeRoundtable,
          color: Colors.grey,
        ),
      );
      _isInitMessageSet = true;
    }
  }

  // --- 発言頻度に応じたルーレット（くじ引き） ---
  ChatCharacter _chooseNextSpeaker() {
    if (widget.selectedCharacters.length <= 1) {
      return widget.selectedCharacters.first;
    }

    List<ChatCharacter> candidates = widget.selectedCharacters;

    if (_lastSpeakerName != null) {
      candidates = widget.selectedCharacters
          .where((c) => c.characterName != _lastSpeakerName)
          .toList();

      if (candidates.isEmpty) {
        candidates = widget.selectedCharacters;
      }
    }

    int totalWeight = candidates.fold(0, (sum, c) => sum + c.frequency);

    if (totalWeight == 0) {
      return candidates[Random().nextInt(candidates.length)];
    }

    int r = Random().nextInt(totalWeight);
    int current = 0;
    for (var c in candidates) {
      current += c.frequency;
      if (r < current) return c;
    }
    return candidates.last;
  }

  // --- ゆらぎ（Temperature）を適用して次の1文字を確率的に選ぶ ---
  int _sampleWithTemperature(List<double> probabilities, double temperature) {
    if (temperature <= 0.0) {
      double maxP = -1.0;
      int maxIdx = 0;
      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxP) {
          maxP = probabilities[i];
          maxIdx = i;
        }
      }
      return maxIdx;
    }

    List<double> logits = [];
    double maxLogit = -double.maxFinite;
    for (double p in probabilities) {
      double logit = log(p + 1e-10);
      logits.add(logit);
      if (logit > maxLogit) maxLogit = logit;
    }

    double sumExp = 0.0;
    List<double> expVals = [];
    for (double logit in logits) {
      double e = exp((logit - maxLogit) / temperature);
      expVals.add(e);
      sumExp += e;
    }

    List<double> softmaxProps = expVals.map((e) => e / sumExp).toList();

    double rand = Random().nextDouble();
    double cumulative = 0.0;
    for (int i = 0; i < softmaxProps.length; i++) {
      cumulative += softmaxProps[i];
      if (rand <= cumulative) {
        return i;
      }
    }
    return softmaxProps.length - 1;
  }

  // --- シード（直近のN文字）を取得する ---
  String _getSeedText(int requiredLength, String currentChars) {
    String fullText = _messages.map((m) => m.text).join("");

    String cleanText = "";
    for (int i = 0; i < fullText.length; i++) {
      if (currentChars.contains(fullText[i])) {
        cleanText += fullText[i];
      }
    }

    // 必要な文字数に満たない場合は、その言語の辞書の先頭文字でパディング
    if (cleanText.length < requiredLength) {
      String pad = currentChars.substring(0, requiredLength);
      cleanText = (pad + cleanText);
    }

    return cleanText.substring(cleanText.length - requiredLength);
  }

  // --- AIに発言させる処理（「進む」ボタン用） ---
  Future<void> _onNextPressed() async {
    if (widget.selectedCharacters.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isGenerating = true);

    ChatCharacter speaker = _chooseNextSpeaker();

    if (!_loadedNetworks.containsKey(speaker.projectId)) {
      final appState = context.read<AppState>();
      final proj = appState.projects.firstWhere(
        (p) => p.id == speaker.projectId,
        orElse: () => throw Exception("プロジェクトが見つかりません"),
      );

      if (proj.trainedModelJson == null) {
        setState(() {
          _messages.add(
            ChatMessage(
              senderName: l10n.systemName,
              text: l10n.errorEmptyBrain(speaker.characterName),
              color: Colors.redAccent,
            ),
          );
          _isGenerating = false;
        });
        _scrollToBottom();
        return;
      }

      _loadedNetworks[speaker.projectId] = NeuralNetwork.fromJson(
        jsonDecode(proj.trainedModelJson!),
      );
      _loadedProjects[speaker.projectId] = proj;
    }

    NeuralNetwork nn = _loadedNetworks[speaker.projectId]!;
    NeuralProject proj = _loadedProjects[speaker.projectId]!;
    int n = proj.nGramCount;

    String seed = _getSeedText(n, proj.currentChars);
    String generatedText = "";

    int maxLength = speaker.maxLength;
    int validCharCount = 0;

    for (int step = 0; step < maxLength; step++) {
      if (!mounted) break;

      List<double> inputVals = [];
      for (int i = 0; i < n; i++) {
        double idx = proj.currentChars.indexOf(seed[i]).toDouble();
        inputVals.add(idx == -1.0 ? 0.0 : idx);
      }

      List<double> encodedInputs = [];
      for (int i = 0; i < n; i++) {
        for (int c = 0; c < proj.currentChars.length; c++) {
          encodedInputs.add(c == inputVals[i].toInt() ? 1.0 : 0.0);
        }
      }

      if (encodedInputs.length != nn.layerSizes.first) {
        setState(() {
          _messages.add(
            ChatMessage(
              senderName: l10n.systemName,
              text: l10n.errorBrainMismatch(speaker.characterName),
              color: Colors.redAccent,
            ),
          );
          _isGenerating = false;
        });
        _scrollToBottom();
        return;
      }

      List<double> rawPred = nn.predict(encodedInputs);
      int nextCharIdx = _sampleWithTemperature(rawPred, speaker.temperature);
      String nextChar = proj.currentChars[nextCharIdx];

      generatedText += nextChar;

      bool isBreakChar = false;
      bool isValidChar = true;

      if (proj.langMode == 1) {
        // 英語モード
        if (nextChar == " " ||
            nextChar == "," ||
            nextChar == "." ||
            nextChar == "!" ||
            nextChar == "?" ||
            nextChar == "\n") {
          isValidChar = false;
        }
        if (nextChar == "." ||
            nextChar == "!" ||
            nextChar == "?" ||
            nextChar == "\n") {
          isBreakChar = true;
        }
      } else {
        // ひらがなモード
        if (nextChar == " " ||
            nextChar == "、" ||
            nextChar == "。" ||
            nextChar == "！" ||
            nextChar == "？" ||
            nextChar == "\n") {
          isValidChar = false;
        }
        if (nextChar == "。" ||
            nextChar == "！" ||
            nextChar == "？" ||
            nextChar == "\n") {
          isBreakChar = true;
        }
      }

      if (isValidChar) {
        validCharCount++;
      }

      // 意味のある文字を出力した上で区切り文字が来たらストップ
      if (isBreakChar && validCharCount > 0) {
        break;
      }

      seed = seed.substring(1) + nextChar;
      await Future.delayed(const Duration(milliseconds: 10));
    }

    String finalMsg = generatedText.trim();
    if (finalMsg.isEmpty) {
      // AIが言葉に詰まった時のレスキューワードも言語ごとに切り替える
      List<String> rescues = proj.langMode == 1
          ? l10n.rescueWordsEnglish.split(',')
          : l10n.rescueWordsHiragana.split(',');
      finalMsg = rescues[Random().nextInt(rescues.length)];
    }

    setState(() {
      _messages.add(
        ChatMessage(
          senderName: speaker.characterName,
          text: finalMsg,
          color: Color(speaker.colorValue),
        ),
      );
      _isGenerating = false;
      _lastSpeakerName = speaker.characterName;
    });

    _scrollToBottom();
  }

  // --- ユーザーが介入発言する処理 ---
  void _onUserSpeak() {
    String text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    final appState = context.read<AppState>();
    final l10n = AppLocalizations.of(context)!;
    String validChars = hiraganaChars; // デフォルト
    String langName = l10n.langHiragana;

    if (widget.selectedCharacters.isNotEmpty) {
      try {
        final proj = appState.projects.firstWhere(
          (p) => p.id == widget.selectedCharacters.first.projectId,
        );
        validChars = proj.currentChars;
        langName = proj.langMode == 1 ? l10n.langEnglish : l10n.langHiragana;
      } catch (e) {}
    }

    bool hasInvalid = false;
    for (int i = 0; i < text.length; i++) {
      if (!validChars.contains(text[i])) {
        hasInvalid = true;
        break;
      }
    }

    if (hasInvalid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.msgInterventionOnlyLanguage(langName),
            style: TextStyle(fontSize: 14 * ScaleUtil.scale(context)),
          ),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    setState(() {
      _messages.add(
        ChatMessage(
          senderName: l10n.userName,
          text: text,
          color: Colors.greenAccent,
          isUser: true,
        ),
      );
      _textCtrl.clear();
    });

    FocusManager.instance.primaryFocus?.unfocus();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double scale = ScaleUtil.scale(context);
    final l10n = AppLocalizations.of(context)!;

    if (widget.selectedCharacters.isEmpty) {
      return Center(
        child: Text(
          l10n.msgNoAiInRoundtable,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16 * scale),
        ),
      );
    }

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          // ＝＝＝ 上部：タイムライン（チャット履歴） ＝＝＝
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: EdgeInsets.all(16 * scale),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];

                if (msg.senderName == l10n.systemName) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 16 * scale),
                    child: Center(
                      child: Text(
                        msg.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: msg.color,
                          fontSize: 12 * scale,
                        ),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: EdgeInsets.only(bottom: 16 * scale),
                  child: Row(
                    mainAxisAlignment: msg.isUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!msg.isUser)
                        CircleAvatar(
                          backgroundColor: msg.color,
                          radius: 16 * scale,
                          child: Text(
                            msg.senderName.substring(0, 1),
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14 * scale,
                            ),
                          ),
                        ),
                      SizedBox(width: 8 * scale),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: msg.isUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.senderName,
                              style: TextStyle(
                                color: msg.isUser ? msg.color : Colors.grey,
                                fontSize: 12 * scale,
                              ),
                            ),
                            SizedBox(height: 4 * scale),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16 * scale,
                                vertical: 12 * scale,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                border: Border.all(
                                  color: msg.color.withOpacity(0.8),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16 * scale),
                                  topRight: Radius.circular(16 * scale),
                                  bottomLeft: msg.isUser
                                      ? Radius.circular(16 * scale)
                                      : Radius.zero,
                                  bottomRight: msg.isUser
                                      ? Radius.zero
                                      : Radius.circular(16 * scale),
                                ),
                              ),
                              child: Text(
                                msg.text,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16 * scale,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8 * scale),
                      if (msg.isUser)
                        CircleAvatar(
                          backgroundColor: msg.color,
                          radius: 16 * scale,
                          child: Icon(
                            Icons.person,
                            color: Colors.black,
                            size: 20 * scale,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ＝＝＝ 下部：コントロールパネル ＝＝＝
          Container(
            padding: EdgeInsets.all(12 * scale),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              boxShadow: [
                BoxShadow(
                  color: Colors.black54,
                  offset: Offset(0, -2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      style: TextStyle(fontSize: 16 * scale),
                      decoration: InputDecoration(
                        hintText: l10n.hintInterveneMessage,
                        hintStyle: TextStyle(fontSize: 14 * scale),
                        filled: true,
                        fillColor: Colors.black,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16 * scale,
                          vertical: 8 * scale,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24 * scale),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _onUserSpeak(),
                    ),
                  ),
                  SizedBox(width: 8 * scale),

                  IconButton(
                    icon: Icon(
                      Icons.send,
                      color: Colors.greenAccent,
                      size: 28 * scale,
                    ),
                    onPressed: _onUserSpeak,
                  ),

                  SizedBox(width: 8 * scale),
                  Container(
                    width: 1,
                    height: 30 * scale,
                    color: Colors.grey.shade700,
                  ),
                  SizedBox(width: 12 * scale),

                  ElevatedButton.icon(
                    icon: _isGenerating
                        ? SizedBox(
                            width: 20 * scale,
                            height: 20 * scale,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.play_arrow, size: 24 * scale),
                    label: Text(
                      l10n.btnNext,
                      style: TextStyle(
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16 * scale,
                        vertical: 12 * scale,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24 * scale),
                      ),
                    ),
                    onPressed: _isGenerating ? null : _onNextPressed,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
