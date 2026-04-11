import 'package:flutter/material.dart';
import 'main.dart';
import 'models.dart';
import 'tab_group_chat_select.dart';
import 'tab_group_chat_settings.dart';
import 'tab_group_chat_run.dart';
import 'l10n/app_localizations.dart'; // ★辞書のインポートを追加

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({super.key});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  // 座談会に参加するキャラクターのリスト
  List<ChatCharacter> selectedCharacters = [];

  @override
  Widget build(BuildContext context) {
    final double scale = ScaleUtil.scale(context);
    final l10n = AppLocalizations.of(context)!; // ★辞書を呼び出し

    // ご要望の3つのタブ（キャラ選択、キャラ設定、座談会実行）を構成
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.groupChatTitle,
            style: TextStyle(fontSize: 20 * scale),
          ), // ★辞書を使用
        ),
        body: TabBarView(
          children: [
            GroupChatSelectTab(
              selectedCharacters: selectedCharacters,
              onSelectionChanged: () {
                setState(() {});
              },
            ),
            GroupChatSettingsTab(
              selectedCharacters: selectedCharacters,
              onSettingsChanged: () {
                setState(() {});
              },
            ),
            GroupChatRunTab(selectedCharacters: selectedCharacters),
          ],
        ),
        bottomNavigationBar: Material(
          color: Colors.black87,
          child: SafeArea(
            child: TabBar(
              indicatorColor: Colors.purpleAccent,
              labelColor: Colors.purpleAccent,
              unselectedLabelColor: Colors.grey,
              labelStyle: TextStyle(fontSize: 12 * scale),
              tabs: [
                Tab(
                  height: 84 * scale,
                  icon: Icon(Icons.person_add, size: 24 * scale),
                  text: l10n.tabCharSelect, // ★辞書を使用
                ),
                Tab(
                  height: 84 * scale,
                  icon: Icon(Icons.tune, size: 24 * scale),
                  text: l10n.tabCharSettings, // ★辞書を使用
                ),
                Tab(
                  height: 84 * scale,
                  icon: Icon(Icons.forum, size: 24 * scale),
                  text: l10n.tabChatRun, // ★辞書を使用
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
