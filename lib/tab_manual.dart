import 'package:flutter/material.dart';
import 'main.dart'; // ScaleUtilをインポート
import 'share_manager.dart'; // バージョン情報取得用
import 'l10n/app_localizations.dart';

class ManualTab extends StatelessWidget {
  const ManualTab({super.key});

  @override
  Widget build(BuildContext context) {
    final double scale = ScaleUtil.scale(context);
    final l10n = AppLocalizations.of(context)!;

    // ★言語設定が日本語（ja）じゃなければ、すべて英語（isEn = true）として扱う
    final bool isEn = Localizations.localeOf(context).languageCode != 'ja';

    // 専門用語の解説データを定義（バイリンガル対応）
    final Map<String, String> termDictionary = {
      l10n.termEpoch: l10n.termEpochDesc,
      l10n.termLoss: l10n.termLossDesc,
      l10n.termOverfitting: l10n.termOverfittingDesc,
      l10n.termOneHot: l10n.termOneHotDesc,
      l10n.termVanishingGradient: l10n.termVanishingGradientDesc,
      l10n.termRelu: l10n.termReluDesc,
      l10n.termAdam: l10n.termAdamDesc,
      l10n.termNGram: l10n.termNGramDesc,
      l10n.termTemperature: l10n.termTemperatureDesc,
      l10n.termWeight: l10n.termWeightDesc,
      l10n.termBias: l10n.termBiasDesc,
      l10n.termFuturePrediction: l10n.termFuturePredictionDesc,
      l10n.termSensitivityAnalysis: l10n.termSensitivityAnalysisDesc,
      l10n.termBatchSize: l10n.termBatchSizeDesc,

      // ★新規追加：RF・決定木関連の用語（言語で出し分け）
      isEn ? "Random Forest" : "ランダムフォレスト": isEn
          ? "An ensemble learning method that constructs multiple decision trees during training and outputs the mode or mean prediction."
          : "訓練中に複数の決定木を構築し、多数決や平均で予測を出力するアンサンブル学習手法です。",
      isEn ? "Decision Tree" : "決定木": isEn
          ? "A flowchart-like structure where each internal node represents a test on a feature, and each leaf node represents a class label or continuous value."
          : "条件分岐（YES/NO）を繰り返してデータを分類・予測する、フローチャートのようなモデルです。",
      "Dropout": isEn
          ? "A regularization technique where randomly selected neurons are ignored during training to prevent overfitting."
          : "過学習を防ぐため、学習時にランダムな割合でニューロンを無効化（ドロップ）する技術です。",
      "L2 Regularization": isEn
          ? "Adds a penalty to the loss function based on the squared magnitude of weights to keep the model simple."
          : "重みが大きくなりすぎるのを防ぐため、損失関数にペナルティを加える手法です。モデルをシンプルに保ちます。",
      isEn ? "Gini Impurity" : "Gini不純度": isEn
          ? "A metric used in classification trees to measure how often a randomly chosen element would be incorrectly labeled."
          : "データの中に異なるクラス（不純物）がどれくらい混ざっているかを示す指標。分類問題の決定木で使われます。",
      "MSE": isEn
          ? "Mean Squared Error. Evaluates the difference between predicted and actual values, used in regression tasks."
          : "平均二乗誤差（Mean Squared Error）。予測値と正解のズレを評価する指標で、数値予測（回帰問題）で使われます。",
    };

    // 用語解説付きのテキストを作るヘルパー
    Widget _buildRichText(String text, {Color? color}) {
      List<InlineSpan> spans = [];
      String remainingText = text;
      Color baseColor = color ?? Colors.white;

      while (remainingText.isNotEmpty) {
        int earliestIndex = -1;
        String? foundTerm;

        for (var term in termDictionary.keys) {
          int index = remainingText.indexOf(term);
          if (index != -1) {
            if (earliestIndex == -1 || index < earliestIndex) {
              earliestIndex = index;
              foundTerm = term;
            }
          }
        }

        if (earliestIndex != -1 && foundTerm != null) {
          if (earliestIndex > 0) {
            spans.add(
              TextSpan(
                text: remainingText.substring(0, earliestIndex),
                style: TextStyle(fontSize: 16 * scale, color: baseColor),
              ),
            );
          }
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Tooltip(
                message: termDictionary[foundTerm]!,
                triggerMode: TooltipTriggerMode.tap,
                showDuration: const Duration(seconds: 5),
                padding: EdgeInsets.all(12 * scale),
                margin: EdgeInsets.symmetric(horizontal: 20 * scale),
                textStyle: TextStyle(fontSize: 16 * scale, color: Colors.black),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8 * scale),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4 * scale,
                    vertical: 2 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4 * scale),
                    border: Border.all(
                      color: Colors.greenAccent.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        foundTerm,
                        style: TextStyle(
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.greenAccent,
                        ),
                      ),
                      SizedBox(width: 4 * scale),
                      Icon(
                        Icons.help_outline,
                        size: 12 * scale,
                        color: Colors.greenAccent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          remainingText = remainingText.substring(
            earliestIndex + foundTerm.length,
          );
        } else {
          spans.add(
            TextSpan(
              text: remainingText,
              style: TextStyle(fontSize: 16 * scale, color: baseColor),
            ),
          );
          remainingText = "";
        }
      }
      return RichText(text: TextSpan(children: spans));
    }

    // 見出し付きセクション作成ヘルパー
    Widget _buildSection(
      String title,
      String content, {
      Color color = Colors.greenAccent,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16 * scale),
          Text(
            title,
            style: TextStyle(
              fontSize: 16 * scale,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 8 * scale),
          _buildRichText(content),
        ],
      );
    }

    // 設定項目用のリストアイテム作成ヘルパー
    Widget _buildSettingItem(String name, String desc, {String? recommend}) {
      return Padding(
        padding: EdgeInsets.only(bottom: 16 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "■ $name",
              style: TextStyle(
                fontSize: 15 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.lightGreenAccent,
              ),
            ),
            SizedBox(height: 4 * scale),
            _buildRichText(desc),
            if (recommend != null) ...[
              SizedBox(height: 4 * scale),
              Text(
                recommend.startsWith("Recommend:")
                    ? recommend
                    : l10n.ch4RecommendPrefix(recommend),
                style: TextStyle(
                  fontSize: 13 * scale,
                  color: Colors.orangeAccent,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            Divider(color: Colors.white24),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.all(16 * scale),
      children: [
        // ヘッダー
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                l10n.manualTitle,
                style: TextStyle(
                  fontSize: 22 * scale,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            SizedBox(width: 8 * scale),
            Text(
              ShareManager.currentAppVersion,
              style: TextStyle(
                fontSize: 14 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        Divider(color: Colors.green, thickness: 2 * scale),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0 * scale),
          child: Text(
            l10n.manualTapHint,
            style: TextStyle(fontSize: 12 * scale, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),

        // ==========================================
        // 🔰 初心者向け：基本とAIの仕組み
        // ==========================================
        Padding(
          padding: EdgeInsets.only(top: 16 * scale, bottom: 8 * scale),
          child: Row(
            children: [
              Icon(Icons.school, color: Colors.greenAccent, size: 24 * scale),
              SizedBox(width: 8 * scale),
              // ★修正ポイント：テキストをExpandedで囲み、画面外へのオーバーフローを防ぐ
              Expanded(
                child: Text(
                  isEn ? "🔰 Beginner's Guide" : "🔰 初心者向けガイド",
                  style: TextStyle(
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ＝＝＝ 第1章：遊び方の基本 ＝＝＝
        ExpansionTile(
          initiallyExpanded: false,
          title: Text(
            isEn ? "Chapter 1: ${l10n.ch1Title}" : "第1章：${l10n.ch1Title}",
            style: TextStyle(
              fontSize: 18 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
            ),
          ),
          childrenPadding: EdgeInsets.all(16 * scale),
          children: [
            _buildRichText(l10n.ch1Intro),
            _buildSection(l10n.ch1Sec1Title, l10n.ch1Sec1Desc),
            _buildSection(l10n.ch1Sec2Title, l10n.ch1Sec2Desc),
            _buildSection(l10n.ch1Sec3Title, l10n.ch1Sec3Desc),
            SizedBox(height: 16 * scale),
            Container(
              padding: EdgeInsets.all(12 * scale),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8 * scale),
                border: Border.all(color: Colors.green),
              ),
              child: _buildRichText(l10n.ch1Tip),
            ),
          ],
        ),

        // ＝＝＝ 第2章：ランダムフォレスト(RF)とは？ ＝＝＝
        ExpansionTile(
          initiallyExpanded: false,
          title: Text(
            isEn
                ? "Chapter 2: [New AI] What is Random Forest (RF)?"
                : "第2章：【新AI】ランダムフォレスト(RF)とは？",
            style: TextStyle(
              fontSize: 18 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.cyanAccent,
            ),
          ),
          childrenPadding: EdgeInsets.all(16 * scale),
          children: [
            _buildRichText(
              isEn
                  ? "In addition to NN (Neural Network), this app now features a new AI engine called 'Random Forest (RF)'."
                  : "このアプリには、NN（ニューラルネットワーク）に加えて、新たに「ランダムフォレスト（RF）」というAIエンジンが搭載されました。",
            ),
            _buildSection(
              isEn ? "1. What is Random Forest?" : "1. ランダムフォレストって何？",
              isEn
                  ? "It's an AI that creates many flowchart-like 'Decision Trees' (branching with YES/NO) and outputs the final answer by majority vote. Think of it as 'asking 100 experts for their opinion'. It's extremely strong with tabular data (like Excel) and computes incredibly fast."
                  : "YES/NOで分岐するフローチャートのような「決定木」をたくさん作り、全員で多数決をとって最終的な答えを出すAIです。「100人の専門家に意見を聞いて決める」ようなイメージです。エクセルなどの表データに非常に強く、計算が超高速で終わるのが特徴です。",
              color: Colors.cyanAccent,
            ),
            _buildSection(
              isEn
                  ? "2. Difference from Neural Network (NN)"
                  : "2. ニューラルネットワーク(NN)との違い",
              isEn
                  ? "NN mimics the human brain and excels at text generation and complex image recognition, but can be computationally heavy. On the other hand, RF is a collection of conditional branches, so it runs blazingly fast even on low-power devices like microcontrollers. Try switching engines in the 'Advanced Settings' based on your needs!"
                  : "NNは人間の脳を模倣したもので、テキスト生成や複雑な画像認識が得意ですが、計算が重くなりがちです。一方、RFは条件分岐の集合体なので、マイコンなどの非力なデバイスでも爆速で動作します。「詳細設定」から用途に合わせてエンジンを切り替えてみましょう！",
              color: Colors.cyanAccent,
            ),
            SizedBox(height: 16 * scale),
            // ★Gini選択時の警告コラム
            Container(
              padding: EdgeInsets.all(12 * scale),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8 * scale),
                border: Border.all(color: Colors.redAccent),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orangeAccent,
                      ),
                      SizedBox(width: 8 * scale),
                      Expanded(
                        child: Text(
                          isEn
                              ? "⚠️ [Important] About choosing Gini for Numerical Prediction"
                              : "⚠️【重要】数値予測時のGini選択について",
                          style: TextStyle(
                            fontSize: 15 * scale,
                            fontWeight: FontWeight.bold,
                            color: Colors.orangeAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8 * scale),
                  _buildRichText(
                    isEn
                        ? "In this app's RF engine, if you mistakenly select the classification loss function 'Gini Impurity' when you want to 'predict numbers (regression)' like sales or age, the calculation logic will break and keep outputting completely wrong (or identical) answers.\n\nWhen you want to predict numbers, always select 'MSE (Mean Squared Error)'. Conversely, when you want to perform 'classification' like survive/die, select 'Gini Impurity'. It's also a good learning experience to intentionally make a mistake and observe how the AI breaks!"
                        : "このアプリのRFエンジンでは、売上や年齢などの「数値を予測（回帰）」したい時に、誤って分類用の損失関数である「Gini不純度」を選ぶと、計算ロジックが崩壊して全く見当違いな答え（または同じ答え）を出し続けてしまいます。\n\n数値を予測させたい場合は、必ず「MSE（平均二乗誤差）」を選択してください。逆に、生存/死亡などの「分類」を行いたい場合は「Gini不純度」を選択します。あえて間違えてみて、AIがどう壊れるか観察するのも勉強になります！",
                  ),
                ],
              ),
            ),
          ],
        ),

        // ＝＝＝ 第3章：生成AIモードの仕組み ＝＝＝
        ExpansionTile(
          initiallyExpanded: false,
          title: Text(
            isEn ? "Chapter 3: ${l10n.ch2Title}" : "第3章：${l10n.ch2Title}",
            style: TextStyle(
              fontSize: 18 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          childrenPadding: EdgeInsets.all(16 * scale),
          children: [
            _buildRichText(l10n.ch2Intro),
            _buildSection(
              l10n.ch2Sec1Title,
              l10n.ch2Sec1Desc,
              color: Colors.blueAccent,
            ),
            _buildSection(
              l10n.ch2Sec2Title,
              l10n.ch2Sec2Desc,
              color: Colors.orangeAccent,
            ),

            SizedBox(height: 16 * scale),
            Container(
              padding: EdgeInsets.all(12 * scale),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8 * scale),
                border: Border.all(color: Colors.blueGrey),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.ch2ColumnTitle,
                    style: TextStyle(
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                    ),
                  ),
                  SizedBox(height: 8 * scale),
                  _buildRichText(l10n.ch2ColumnDesc, color: Colors.white),
                ],
              ),
            ),
            _buildSection(
              l10n.ch2Sec3Title,
              l10n.ch2Sec3Desc,
              color: Colors.redAccent,
            ),
          ],
        ),

        // ＝＝＝ 第4章：AIの思考を透視する ＝＝＝
        ExpansionTile(
          initiallyExpanded: false,
          title: Text(
            isEn ? "Chapter 4: ${l10n.ch3Title}" : "第4章：${l10n.ch3Title}",
            style: TextStyle(
              fontSize: 18 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.purpleAccent,
            ),
          ),
          childrenPadding: EdgeInsets.all(16 * scale),
          children: [
            _buildRichText(l10n.ch3Intro),
            _buildSection(
              l10n.ch3Sec1Title,
              l10n.ch3Sec1Desc,
              color: Colors.purpleAccent,
            ),
            _buildSection(
              l10n.ch3Sec2Title,
              l10n.ch3Sec2Desc,
              color: Colors.purpleAccent,
            ),
            _buildSection(
              l10n.ch3Sec3Title,
              l10n.ch3Sec3Desc,
              color: Colors.purpleAccent,
            ),
            _buildSection(
              l10n.ch3Sec4Title,
              l10n.ch3Sec4Desc,
              color: Colors.purpleAccent,
            ),
            _buildSection(
              l10n.ch3Sec5Title,
              l10n.ch3Sec5Desc,
              color: Colors.purpleAccent,
            ),
          ],
        ),

        // ==========================================
        // ⚙️ 技術者・上級者向け：詳細設定と書き出し
        // ==========================================
        Padding(
          padding: EdgeInsets.only(top: 32 * scale, bottom: 8 * scale),
          child: Row(
            children: [
              Icon(
                Icons.engineering,
                color: Colors.orangeAccent,
                size: 24 * scale,
              ),
              SizedBox(width: 8 * scale),
              // ★修正ポイント：テキストをExpandedで囲み、画面外へのオーバーフローを防ぐ
              Expanded(
                child: Text(
                  isEn ? "⚙️ For Engineers & Advanced Users" : "⚙️ 技術者・上級者向け",
                  style: TextStyle(
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ＝＝＝ 第5章：詳細設定の全項目リファレンス ＝＝＝
        ExpansionTile(
          initiallyExpanded: false,
          title: Text(
            isEn ? "Chapter 5: ${l10n.ch4Title}" : "第5章：${l10n.ch4Title}",
            style: TextStyle(
              fontSize: 18 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.lightGreenAccent,
            ),
          ),
          childrenPadding: EdgeInsets.all(16 * scale),
          children: [
            Text(
              l10n.ch4Intro,
              style: TextStyle(fontSize: 14 * scale, color: Colors.grey),
            ),

            // --- AI Engine Configuration ---
            SizedBox(height: 16 * scale),
            Text(
              isEn ? "■ AI Engine Configuration (New)" : "■ AIエンジン設定（NEW）",
              style: TextStyle(
                fontSize: 16 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.lightBlueAccent,
              ),
            ),
            Divider(color: Colors.lightBlueAccent),
            _buildSettingItem(
              isEn ? "AI Engine Selection" : "AIエンジンの選択",
              isEn
                  ? "Choose between Neural Network (deep learning, great for complex patterns and text generation) and Random Forest (ensemble of decision trees, extremely fast and lightweight)."
                  : "ニューラルネットワーク（深層学習。複雑なパターンやテキスト生成が得意）と、ランダムフォレスト（決定木のアンサンブル。非常に高速で軽量）から選択します。",
              recommend: isEn
                  ? "Recommend: Use NN for text/complex logic, RF for simple classification/regression on MCUs."
                  : "おすすめ：テキストや複雑な論理はNN、表データやマイコンでの分類・予測はRFを使用してください。",
            ),
            _buildSettingItem(
              isEn ? "RF: Trees & Max Depth" : "RF: 木の本数 ＆ 最大の深さ",
              isEn
                  ? "Controls the size of the Random Forest. 'Trees' is the number of Decision Tree instances. 'Max Depth' limits how many splits each tree can make."
                  : "ランダムフォレストの規模を制御します。「木の本数」は決定木の数、「最大の深さ」は各木が何回まで条件分岐できるかの上限です。",
              recommend: isEn
                  ? "Recommend: Keep these small (e.g., Trees: 3-5, Depth: 3-5) if exporting to bare-metal microcontrollers."
                  : "おすすめ：Arduino等の非力なマイコンに書き出す場合は、小さめ（例：木3本、深さ3）に設定してください。",
            ),
            _buildSettingItem(
              isEn ? "NN: Dropout & L2 Regularization" : "NN: ドロップアウト ＆ L2正則化",
              isEn
                  ? "Advanced techniques to prevent overfitting. Dropout randomly disables neurons, while L2 Regularization penalizes excessively large weights."
                  : "過学習を防ぐための高度なテクニックです。ドロップアウトはランダムにニューロンを無効化し、L2正則化は重みが大きくなりすぎるのを防ぎます。",
              recommend: isEn
                  ? "Recommend: Increase these slightly if your Validation Loss is much worse than Training Loss."
                  : "おすすめ：検証誤差（Val Loss）が訓練誤差より極端に悪い場合に、少しだけ数値を上げてみてください。",
            ),

            SizedBox(height: 16 * scale),

            // --- AIの構造 ---
            Text(
              l10n.ch4Sub1,
              style: TextStyle(
                fontSize: 16 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Divider(color: Colors.green),
            _buildSettingItem(
              l10n.ch4Layers,
              l10n.ch4LayersDesc,
              recommend: l10n.ch4LayersRec,
            ),
            _buildSettingItem(
              l10n.ch4Units,
              l10n.ch4UnitsDesc,
              recommend: l10n.ch4UnitsRec,
            ),
            _buildSettingItem(
              l10n.ch4Activation,
              l10n.ch4ActivationDesc,
              recommend: l10n.ch4ActivationRec,
            ),

            SizedBox(height: 16 * scale),

            // --- 学習アルゴリズム ---
            Text(
              l10n.ch4Sub2,
              style: TextStyle(
                fontSize: 16 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Divider(color: Colors.green),
            _buildSettingItem(
              l10n.ch4Optimizer,
              l10n.ch4OptimizerDesc,
              recommend: l10n.ch4OptimizerRec,
            ),
            _buildSettingItem(
              l10n.ch4LR,
              l10n.ch4LRDesc,
              recommend: l10n.ch4LRRec,
            ),
            _buildSettingItem(
              l10n.ch4BatchSize,
              l10n.ch4BatchSizeDesc,
              recommend: l10n.ch4BatchSizeRec,
            ),
            _buildSettingItem(
              l10n.ch4LossFunc,
              l10n.ch4LossFuncDesc,
              recommend: l10n.ch4LossFuncRec,
            ),

            SizedBox(height: 16 * scale),

            // --- データ処理 ---
            Text(
              l10n.ch4Sub3,
              style: TextStyle(
                fontSize: 16 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Divider(color: Colors.green),
            _buildSettingItem(
              l10n.ch4ValRatio,
              l10n.ch4ValRatioDesc,
              recommend: l10n.ch4ValRatioRec,
            ),
            _buildSettingItem(
              l10n.ch4SplitMode,
              l10n.ch4SplitModeDesc,
              recommend: l10n.ch4SplitModeRec,
            ),
            _buildSettingItem(l10n.ch4EcoMode, l10n.ch4EcoModeDesc),
          ],
        ),

        // ＝＝＝ 第6章：上級機能 ＝＝＝
        ExpansionTile(
          initiallyExpanded: false,
          title: Text(
            isEn
                ? "Chapter 6: Advanced Features & Export"
                : "第6章：高度な機能とコード書き出し",
            style: TextStyle(
              fontSize: 18 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.yellowAccent,
            ),
          ),
          childrenPadding: EdgeInsets.all(16 * scale),
          children: [
            _buildSection(
              isEn ? "1. Decision Tree Explorer" : "1. 決定木エクスプローラー",
              isEn
                  ? "When using the Random Forest engine, you can visually explore how the AI makes decisions in the Predict Tab. It shows the exact logic conditions (e.g., Feature A <= 0.5) and the path taken for the current input data. This makes the AI 100% explainable."
                  : "RFエンジンを使用している場合、予測タブでAIがどのように判断を下したかを視覚的に確認できます。現在の入力データがどの条件（例：特徴量A <= 0.5）を通って結果に至ったかが一目でわかり、AIの思考プロセスが100%説明可能になります。",
              color: Colors.yellowAccent,
            ),
            _buildSection(
              isEn ? "2. Export to Native Code" : "2. ネイティブコードへの書き出し",
              isEn
                  ? "You can export your trained AI brain (both NN and RF) directly into standalone source code from the Predict Tab. Supported languages include Dart, Python, C++, and Rust. The generated code has zero external dependencies."
                  : "学習済みのAIの脳（NNおよびRF）を、予測タブから直接ソースコードとして書き出すことができます。対応言語はDart, Python, C++, Rustです。生成されたコードは外部ライブラリに一切依存せず、単体で動作します。",
              color: Colors.yellowAccent,
            ),
            _buildSection(
              isEn ? "3. Microcontroller Support (C++)" : "3. マイコン向けサポート (C++)",
              isEn
                  ? "The C++ exports include specific versions for IoT devices. 'Bare-Metal' generates extremely minimal code suitable for classic Arduino (AVR). 'Rich' utilizes modern C++ features better suited for 32-bit MCUs like the ESP32."
                  : "C++の書き出しには、IoTデバイス向けの専用バージョンが含まれます。「Bare-Metal」は従来のArduino(AVR)に適した極小コードを生成します。「Rich」はESP32のような32ビットマイコンに適したモダンなC++機能を使用します。",
              color: Colors.yellowAccent,
            ),
          ],
        ),

        // ＝＝＝ 第7章：学習の仕組みと裏側 ＝＝＝
        ExpansionTile(
          initiallyExpanded: false,
          title: Text(
            isEn ? "Chapter 7: ${l10n.ch5Title}" : "第7章：${l10n.ch5Title}",
            style: TextStyle(
              fontSize: 18 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
            ),
          ),
          childrenPadding: EdgeInsets.all(16 * scale),
          children: [
            _buildSection(l10n.ch5Sec1Title, l10n.ch5Sec1Desc),
            _buildSection(l10n.ch5Sec2Title, l10n.ch5Sec2Desc),
            _buildSection(l10n.ch5Sec3Title, l10n.ch5Sec3Desc),
            _buildSection(
              l10n.ch5Sec4Title,
              l10n.ch5Sec4Desc,
              color: Colors.orangeAccent,
            ),
            _buildSection(l10n.ch5Sec5Title, l10n.ch5Sec5Desc),
          ],
        ),

        // ＝＝＝ 第8章：アプリの仕様とQ&A ＝＝＝
        ExpansionTile(
          initiallyExpanded: false,
          title: Text(
            isEn ? "Chapter 8: ${l10n.ch6Title}" : "第8章：${l10n.ch6Title}",
            style: TextStyle(
              fontSize: 18 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
            ),
          ),
          childrenPadding: EdgeInsets.all(16 * scale),
          children: [
            _buildSection(l10n.ch6Q1Title, l10n.ch6Q1Desc),
            _buildSection(l10n.ch6Q2Title, l10n.ch6Q2Desc),
            _buildSection(l10n.ch6Q3Title, l10n.ch6Q3Desc),
            _buildSection(l10n.ch6Q4Title, l10n.ch6Q4Desc),
            _buildSection(l10n.ch6Q5Title, l10n.ch6Q5Desc),
            _buildSection(l10n.ch6Q6Title, l10n.ch6Q6Desc, color: Colors.grey),
          ],
        ),

        SizedBox(height: 32 * scale),
        Divider(thickness: 1 * scale),
        Text(
          l10n.footerTermsTitle,
          style: TextStyle(
            fontSize: 18 * scale,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 8 * scale),
        _buildRichText(l10n.footerTermsDesc),
        SizedBox(height: 16 * scale),

        // プライバシーポリシー
        ExpansionTile(
          initiallyExpanded: false,
          title: Text(
            l10n.footerPrivacyTitle,
            style: TextStyle(
              fontSize: 16 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          childrenPadding: EdgeInsets.all(16 * scale),
          children: [
            Container(
              padding: EdgeInsets.all(12 * scale),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8 * scale),
              ),
              child: Text(
                l10n.footerPrivacyDesc,
                style: TextStyle(
                  fontSize: 12 * scale,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),

        // オープンソースライセンス
        ExpansionTile(
          initiallyExpanded: false,
          title: Text(
            'Open Source Licenses',
            style: TextStyle(
              fontSize: 16 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          childrenPadding: EdgeInsets.all(16 * scale),
          children: [
            TextButton(
              onPressed: () {
                showLicensePage(
                  context: context,
                  applicationName: 'hakoniwa_neuralnet',
                  applicationVersion: ShareManager.currentAppVersion,
                );
              },
              child: Text(
                isEn ? 'View all third-party licenses' : 'サードパーティライセンスを表示',
                style: TextStyle(
                  fontSize: 14 * scale,
                  color: Colors.blueAccent,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 40 * scale),
      ],
    );
  }
}
