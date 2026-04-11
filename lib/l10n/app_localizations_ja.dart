// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get btnRoundtable => 'AI座談会';

  @override
  String get btnNewProject => '新規作成';

  @override
  String get msgCannotPopDuringTraining => '⚠️ 学習中はホームに戻れません。先に「停止」を押してください。';

  @override
  String get tabData => 'データ';

  @override
  String get tabTrain => '学習';

  @override
  String get tabPredict => '推論';

  @override
  String get tabSettings => '設定';

  @override
  String get tabManual => '説明書';

  @override
  String get msgScreenSaver => 'AIが学習中...\n画面をタップして復帰';

  @override
  String projectCopyName(String name) {
    return '$nameのコピー';
  }

  @override
  String get newProjectDefaultName => '新規プロジェクト';

  @override
  String get msgStructureChangedResetData => '構成が変更されたため、引き継いだ学習データをリセットしました。';

  @override
  String get addInputTitle => '入力の追加';

  @override
  String get addOutputTitle => '出力の追加';

  @override
  String get itemNameLabel => '項目名';

  @override
  String get typeNumericSlider => '数値 (スライダー)';

  @override
  String get typeCategoryDropdown => '分類 (ドロップダウン)';

  @override
  String get typeNumericDirect => '数値 (直接入力)';

  @override
  String get minValueLabel => '最小値';

  @override
  String get maxValueLabel => '最大値';

  @override
  String get editCategoriesLabel => '選択肢の編集';

  @override
  String get newCategoryHint => '新しい選択肢';

  @override
  String get msgRequireOneCategory => '※選択肢を1つ以上追加してください';

  @override
  String get btnCancel => 'キャンセル';

  @override
  String get btnAdd => '追加';

  @override
  String get unnamedItem => '未設定';

  @override
  String pastChar(int i) {
    return '過去文字$i';
  }

  @override
  String get nextOneChar => '次の1文字';

  @override
  String get msgRequireInputOutput => '入力と出力の項目を少なくとも1つずつ設定してください。';

  @override
  String get copyProjectTitle => 'プロジェクトのコピー';

  @override
  String get createNewProjectTitle => '新規作成';

  @override
  String get projectNameLabel => 'プロジェクト名';

  @override
  String get aiTypeLabel => 'AIのタイプ';

  @override
  String get typeNumericPredict => '数値予測 (通常)';

  @override
  String get typeTextGeneration => 'テキスト生成 (LLM)';

  @override
  String get inheritDataLabel => '元の学習データも引き継ぐ';

  @override
  String get btnAddInput => '＋ 入力を追加';

  @override
  String categoryFormat(String categories) {
    return '分類 ($categories)';
  }

  @override
  String numericFormat(double min, double max) {
    return '数値 ($min ~ $max)';
  }

  @override
  String get btnAddOutput => '＋ 出力を追加';

  @override
  String get learningLanguageLabel => '学習言語';

  @override
  String get langHiragana => 'ひらがな';

  @override
  String get langEnglish => '英語 (アルファベット等)';

  @override
  String get descTextGenerationMode =>
      '【テキスト生成モード】\n選択した言語の文章を読み込ませることで、次に来る文字を予測して文章を自動生成する言語モデル（LLM）を作ります。\n\n※入力・出力の構成は自動で「直近の文字 → 次の1文字」に設定されます。';

  @override
  String get btnCreateCopy => 'この内容でコピーを作成';

  @override
  String get btnCreateProject => 'この内容でプロジェクトを作成';

  @override
  String get groupChatTitle => 'AI座談会';

  @override
  String get tabCharSelect => 'キャラ選択';

  @override
  String get tabCharSettings => 'キャラ設定';

  @override
  String get tabChatRun => '座談会実行';

  @override
  String get confirmDeleteTitle => '削除の確認';

  @override
  String confirmDeleteMessage(String name) {
    return '「$name」を削除してもよろしいですか？\n※復元できません。';
  }

  @override
  String get btnDelete => '削除する';

  @override
  String get editProjectNameTitle => 'プロジェクト名の変更';

  @override
  String get editProjectNameHint => '新しい名前を入力';

  @override
  String get btnChange => '変更';

  @override
  String get appTitle => '箱庭小AI';

  @override
  String get tooltipImport => 'プロジェクトを読み込む';

  @override
  String get tooltipEditName => '名前を変更';

  @override
  String projectInfoSubtitle(
    String version,
    int dataCount,
    int layers,
    String nodesList,
  ) {
    return 'v$version / データ: $dataCount件 / 層:$layers ユニット:[$nodesList]';
  }

  @override
  String get tooltipExport => '共有・出力';

  @override
  String get tooltipCopy => 'コピー';

  @override
  String get tooltipDelete => '削除';

  @override
  String get welcomeTitle => 'AIを作って遊ぼう！';

  @override
  String get welcomeDesc => '箱庭小AIは、スマホの中でAI（人工知能）の頭脳を一から育てることができるシミュレーターです。';

  @override
  String get welcomeStepTitle => '💡 遊び方の３ステップ';

  @override
  String get welcomeStepDesc =>
      '1. データ: 「国語と数学の点数」などの例題を登録\n2. 学習: ターミナルで誤差が減るのを見守る\n3. 推論: 未知の数値を入力してAIの予測を楽しむ';

  @override
  String get btnStartWithSample => 'サンプルを作成して始める';

  @override
  String get exportDialogTitle => 'プロジェクトの出力';

  @override
  String exportDialogDesc(String name) {
    return '「$name」を共有・保存します。';
  }

  @override
  String estimatedDataSize(String size) {
    return '推定データサイズ: $size';
  }

  @override
  String get warningLargeSize =>
      '※データサイズが大きすぎるため、メールやメモ帳がフリーズするのを防ぐ目的で「呪文コピー」を制限しています。ファイル出力をご利用ください。';

  @override
  String get btnSpellCopy => '呪文コピー';

  @override
  String get btnFileOutput => 'ファイル出力';

  @override
  String get msgSpellCopied => 'クリップボードに呪文をコピーしました！メール等に貼り付けてください。';

  @override
  String get errorDataGenerationFailed => '圧縮データの生成に失敗しました';

  @override
  String get errorSizeLimitExceeded => '圧縮後もファイルサイズが5MBを超過しているため出力できません。';

  @override
  String shareProjectText(String name) {
    return '箱庭小AIのプロジェクト「$name」を共有します！';
  }

  @override
  String shareProjectSubject(String name) {
    return '$name のデータ';
  }

  @override
  String msgFileExported(String name) {
    return '「$name」のファイルを出力しました！';
  }

  @override
  String errorFileExport(String error) {
    return 'ファイル出力エラー: $error';
  }

  @override
  String get versionOldTitle => 'バージョンが古いです';

  @override
  String versionOldDesc(String version) {
    return 'このプロジェクトは新しいバージョンの「箱庭小AI (v$version)」で作られています。\n\n正常に召喚・動作させるために、アプリを最新版にアップデートしてから再度お試しください！';
  }

  @override
  String get btnConfirm => '確認';

  @override
  String get importDialogTitle => 'プロジェクトの読み込み';

  @override
  String get importDialogDesc => 'どちらの方法で読み込みますか？';

  @override
  String get btnSpellPaste => '呪文(貼り付け)';

  @override
  String get btnSelectFile => 'ファイルを選択';

  @override
  String get castSpellTitle => '呪文を唱える';

  @override
  String get castSpellHint => 'ここに呪文(テキスト)をペースト...';

  @override
  String get btnSummon => '召喚';

  @override
  String get spellSummonSuffix => '呪文召喚';

  @override
  String get fileSummonSuffix => 'ファイル召喚';

  @override
  String get errorNoDataInFile => 'ファイル内にプロジェクトデータが見つかりません';

  @override
  String get msgSummonSuccess => '見事な手際です！プロジェクトを召喚しました。';

  @override
  String get msgSummonFailed => '召喚に失敗しました。データが壊れているか、対応していない形式です。';

  @override
  String readAiTextTitle(String langName) {
    return '📚 AIに読ませる文章（$langName）';
  }

  @override
  String readAiTextDesc(String hintExample) {
    return 'ここに$hintExampleといった文章をペーストしてください。\n※AIは設定された文字数を見て「次の1文字」を予測するように自動で学習データを切り出します。';
  }

  @override
  String get warningTextEnglish =>
      '英語のアルファベットと基本的な記号（.,!?\'-）のみで入力願います。\n日本語や全角スペースなどは対象外です。';

  @override
  String get warningTextHiragana =>
      'ひらがなと句読点、ー！？のみで入力願います。\nかぎ括弧「」や漢字などは対象外です。';

  @override
  String get pasteTextHint => '文章を入力またはペースト...';

  @override
  String currentMemoryDataCount(int count) {
    return '現在の記憶データ: $count件';
  }

  @override
  String get btnAutoGenerateData => '文章から学習データを自動生成';

  @override
  String get dataLimitWarningTitle => 'データ上限の警告';

  @override
  String get dataLimitWarningDesc =>
      '記憶できるデータの上限（約15,000件）を超えてしまいます。\n安全のため、先に「記憶を全消去」するか、短い文章にしてください。';

  @override
  String get errorUnsupportedCharsTitle => 'エラー：未対応の文字が含まれています';

  @override
  String get errorDetailEnglish =>
      'AIの辞書は「アルファベットや基本的な記号」のみに対応しています。\n日本語や全角スペースなどが含まれていると学習できません。';

  @override
  String get errorDetailHiragana =>
      'AIの辞書は「ひらがな」のみに対応しています。\n漢字やカタカナ、全角スペースなどが含まれていると学習できません。\nすべて「ひらがな」に変換してから入力してください。';

  @override
  String errorUnsupportedCharsDesc(String errorDetail, String foundChars) {
    return '$errorDetail\n\n【見つかった未対応の文字】\n$foundChars';
  }

  @override
  String msgNotEnoughChars(int requiredCount) {
    return '学習可能な文字が少なすぎます（最低 $requiredCount 文字必要です）';
  }

  @override
  String msgDataAddedFromText(int added) {
    return '文章から $added 件の学習データを追加しました！';
  }

  @override
  String get btnClearAllMemory => '記憶を全消去';

  @override
  String get warningTitle => '警告';

  @override
  String get clearAllMemoryDesc => '抽出したすべての記憶（データ）と入力文章を消去しますか？';

  @override
  String get btnClear => '消去';

  @override
  String get inputPrefix => '入力: ';

  @override
  String get outputPrefix => '出力: ';

  @override
  String get confirmDataDeleteTitle => '削除の確認';

  @override
  String get confirmDataDeleteDesc => 'このデータを削除してもよろしいですか？';

  @override
  String get btnManualDataInput => 'データ手入力';

  @override
  String get msgDataLockedDuringTraining => '⚠️ 学習中はデータの編集・追加がロックされます';

  @override
  String get batchDataManagement => '一括データ管理 (Excel等と連携)';

  @override
  String get btnPaste => 'ペースト';

  @override
  String get btnReadCSV => 'CSV読込';

  @override
  String get btnCopy => 'コピー';

  @override
  String get btnSaveCSV => 'CSV保存';

  @override
  String get btnDeleteAll => '全消去';

  @override
  String get deleteAllDataWarningDesc => 'すべてのデータを消去しますか？';

  @override
  String get noDataDesc =>
      'データがありません。\n右下のボタンから手入力するか、\nPCのExcel等からコピーしてペーストしてください。\n\n※列の順序:\n[入力1, 入力2... 出力1, 出力2...]';

  @override
  String get editDataTitle => 'データの編集';

  @override
  String get manualDataInputTitle => 'データの手入力';

  @override
  String get inputDataHeader => '▼ 入力データ';

  @override
  String get outputDataHeader => '▼ 出力データ (正解)';

  @override
  String get btnUpdate => '更新';

  @override
  String get systemName => 'システム';

  @override
  String get welcomeRoundtable =>
      '座談会へようこそ！\n「進む」を押すとAIが順番に話し始めます。\n途中で「発言」から会話に割り込むこともできます。';

  @override
  String errorEmptyBrain(String charName) {
    return '【エラー】$charName の脳（学習データ）が空です。\n先に「学習」タブで学習を完了させてください。';
  }

  @override
  String errorBrainMismatch(String charName) {
    return '【エラー】$charName の脳の構造が一致しません。\n「設定」タブで脳をリセットしてください。';
  }

  @override
  String get rescueWordsHiragana => 'えっと、,あのー、,んーっと、,そうですね、,それで、';

  @override
  String get rescueWordsEnglish => 'Well...,Umm...,Let me see...,So...,Ah,';

  @override
  String msgInterventionOnlyLanguage(String langName) {
    return 'AIが理解できるように「$langName」のみで入力してください。';
  }

  @override
  String get userName => 'あなた';

  @override
  String get msgNoAiInRoundtable => '座談会に参加するAIがいません。\n「キャラ選択」タブでAIを追加してください。';

  @override
  String get hintInterveneMessage => 'メッセージを介入...';

  @override
  String get btnNext => '進む';

  @override
  String get msgMaxCharacters => '参加できるキャラクターは最大4人までです。';

  @override
  String get msgLanguageMismatchTitle => '座談会の言語が合いません！';

  @override
  String msgLanguageMismatchDesc(String currentLang, String newLang) {
    return '現在は「$currentLang」のAIが集まっています。「$newLang」のAIは追加できません。';
  }

  @override
  String participatingCharacters(int count) {
    return '参加キャラクター ($count / 4人)';
  }

  @override
  String get msgEmptyCharacters =>
      '下のリストからAIを選んで追加してください。\n※1人目のAIの言語が座談会の公用語になります。';

  @override
  String get selectAiToInvite => '▼ 座談会に呼ぶAIを選ぶ';

  @override
  String get msgNoLlmProjects => 'テキスト生成モードのAIがありません。\nホーム画面から作成してください。';

  @override
  String memoryDataCount(int count) {
    return '記憶データ: $count件';
  }

  @override
  String get freqQuiet => '1 (無口 / 聞き手)';

  @override
  String get freqReserved => '2 (控えめ)';

  @override
  String get freqNormal => '3 (普通)';

  @override
  String get freqActive => '4 (積極的)';

  @override
  String get freqChatty => '5 (おしゃべり / 出たがり)';

  @override
  String get characterNameLabel => 'キャラクター名';

  @override
  String get nameless => '名無し';

  @override
  String get themeColor => '🎨 テーマカラー';

  @override
  String temperatureLabel(String val) {
    return '🧠 ゆらぎ (Temperature): $val';
  }

  @override
  String get temperatureDesc => '小さいほど無難な発言、大きいほど突拍子もないカオスな発言になります。';

  @override
  String frequencyLabel(String label) {
    return '🗣️ 発言頻度: $label';
  }

  @override
  String get frequencyDesc => '座談会が「進む」ときに、このキャラクターが発言権を獲得する確率です。';

  @override
  String maxLengthLabel(int length) {
    return '📏 最大発言文字数: $length 文字';
  }

  @override
  String get maxLengthDesc => '1回のターンで話す最大の長さです。（文脈によってはこれより短く終わります）';

  @override
  String get lockMessage => '学習中につき、脳の構造とアルゴリズムの変更はロックされています。（下部の動作設定は変更可能です）';

  @override
  String get additionalEpochs => '追加Epoch: ';

  @override
  String get btnResetBrain => '脳のリセット';

  @override
  String get btnAnalyzing => '分析中...';

  @override
  String get btnForceStop => '強制ストップ';

  @override
  String get btnResumeTraining => '学習を再開';

  @override
  String get btnStartTraining => '学習開始';

  @override
  String get warnKeepScreen => '※画面を維持してください。バックグラウンドにすると学習が止まります。';

  @override
  String get btnDetailedAnalysis => '精度測定 & 詳細分析 (Val)';

  @override
  String get btnAnalysisPending => '学習完了後に測定できます';

  @override
  String accuracyResult(String rate) {
    return '正答率: $rate %';
  }

  @override
  String get analysisComplete => '分析完了';

  @override
  String get tooltipShowDetailedChart => '詳細グラフを表示';

  @override
  String get tooltipRemesure => '再測定';

  @override
  String get legendTrainLoss => '学習誤差(Train)';

  @override
  String get legendValLoss => '検証誤差(Val)';

  @override
  String get terminalTitleHeatmap => 'Brain Map (Real-time)';

  @override
  String get terminalTitleLog => 'Terminal Log';

  @override
  String get heatmapLegendSuppress => '抑制 (-)';

  @override
  String get heatmapLegendZero => '0';

  @override
  String get heatmapLegendExcite => '興奮 (+)';

  @override
  String get heatmapLegendIntense => '強烈';

  @override
  String get heatmapWarnSlow => '※リアルタイム描画中は計算速度が低下します。';

  @override
  String get sensitivityTitle => 'AIの注目ポイント (簡易影響度)';

  @override
  String get btnRunDetailedAnalysis => '詳細な感度分析を実行 (高負荷)';

  @override
  String get sensitivityLlmNote => '※「過去文字1」が最も古く、数字が大きいほど直前の文字を表します。';

  @override
  String get permutationImportanceTitle => '詳細感度分析 (Permutation Importance)';

  @override
  String get permutationImportanceDesc =>
      '各データをランダムにシャッフルした時の「誤差の悪化量」を測定しました。数値が高いほど、AIがそのデータを頼りにしていたことを示します。';

  @override
  String get btnClose => '閉じる';

  @override
  String get confusionMatrixTitle => 'AIの迷い (混同行列)';

  @override
  String get scatterPlotTitle => '予測のズレ (散布図)';

  @override
  String get confusionMatrixDesc =>
      '縦が「正解」、横が「AIの答え」です。\n対角線(左上〜右下)に数字が集まっていれば優秀です。';

  @override
  String get scatterPlotDesc => '横が「正解」、縦が「AIの予測」です。\n点が斜めの線に近いほど正確です。';

  @override
  String get tapToExpandHint => '👇 グラフをタップすると全画面で拡大・操作できます';

  @override
  String get inputSelectionTitle => '入力項目の選択 (実験室)';

  @override
  String get inputSelectionDesc =>
      '※スイッチをオフにしたデータを「存在しないもの」として学習します。\n特定の項目の重要度を測る実験（アブレーション分析）に使えます。\n【重要】オフにした入力項目がある学習内容は、プロジェクト選択画面に戻るとリセットされます。アプリ再起動時やアップデート時も同様です。';

  @override
  String get errorSelectAtLeastOne => '少なくとも1つの項目を選択してください';

  @override
  String get applyChangesTitle => '変更の適用';

  @override
  String get applyChangesDesc =>
      '入力項目の構成を変更し、現在の学習内容をリセットしますか？\n※この操作は元に戻せません。';

  @override
  String get btnResetAndApply => 'リセットして適用';

  @override
  String get msgStructureChanged => '入力構成を変更しました。脳をリセットしました。';

  @override
  String get btnApplyStructureAndReset => '設定を適用して脳をリセット';

  @override
  String get noBrainDataMessage => 'No Brain Data\n学習を開始すると脳が生成されます';

  @override
  String get chartAxisTrue => '縦:正解';

  @override
  String get chartAxisPred => '横:予測';

  @override
  String get detailedChartTitleMatrix => '混同行列 (詳細)';

  @override
  String get detailedChartTitleScatter => '予測散布図 (詳細)';

  @override
  String get msgTrainFirst => '※先に「学習」タブでAIを育ててください';

  @override
  String get writeAiContinuation => '💬 AIに文章の続きを書かせる';

  @override
  String hintSeedText(int n, String exampleText) {
    return '書き出しの文章 ($n文字以上。例: $exampleText)';
  }

  @override
  String get hintSeedTextPlaceholder => 'ここに入力した文章の続きをAIが考えます...';

  @override
  String get temperatureLabelShort => 'ゆらぎ\n(ランダム性)';

  @override
  String get temperatureNote => '※ 0.0は無難でループしがち。数値を上げると意外な言葉を選びます。';

  @override
  String get btnStop => 'ストップ';

  @override
  String get btnAutoGenerate => '自動生成';

  @override
  String get btnStepForward => '1文字進む (思考を見る)';

  @override
  String aiThinkingTitle(String input) {
    return '🧠 AIの思考（入力: 「$input」）';
  }

  @override
  String get aiDecision => '【判断】';

  @override
  String step1Future(String char) {
    return 'Step 1: 「$char」のあと';
  }

  @override
  String step2Future(String char) {
    return 'Step 2: さらに「$char」のあと';
  }

  @override
  String get generationResultTitle => '📝 生成結果';

  @override
  String get tooltipClearResult => '結果をクリア';

  @override
  String get btnCopyAll => '全文コピー';

  @override
  String get msgTextCopied => '生成されたテキストをコピーしました！';

  @override
  String msgRequireSeedLength(String langName, int n) {
    return 'ヒントとして、$langNameを$n文字以上入力してください！';
  }

  @override
  String msgRequireSeedLengthFirst(String langName, int n) {
    return '最初のヒントとして、$langNameを$n文字以上入力してください！';
  }

  @override
  String get msgPredictLockedDuringTraining => '⚠️ 学習中は推論（テスト）操作がロックされます';

  @override
  String get btnPredictNormal => '推論する (Predict)';

  @override
  String predictionResult(String name, String val) {
    return '$name の予測値:  $val';
  }

  @override
  String judgmentResult(String name) {
    return '【$name】の判定:';
  }

  @override
  String get settingsStructureTitle => '🧠 脳の構造とアルゴリズム (変更時リセット)';

  @override
  String get nGramCountLabel => '推測文字数\n(文脈の長さ)';

  @override
  String nGramChars(int count) {
    return '$count 文字';
  }

  @override
  String get nGramDesc =>
      '※AIが次の文字を予測するために「直前の何文字」を見るかの設定です。増やすと文脈を捉えやすくなりますが、丸暗記（過学習）しやすくなります。\n※変更してリセットすると、保存されている元の文章から学習データを全自動で再抽出します。';

  @override
  String get hiddenLayersLabel => '隠れ層の数';

  @override
  String layersCount(int count) {
    return '$count 層';
  }

  @override
  String get hiddenLayersDesc => '※層を深く(3以上)すると複雑な推論が可能になりますが、学習が難しくなります。';

  @override
  String get nodesPerLayerTitle => '各層のユニット数 (ディープラーニング構造)';

  @override
  String layerLabel(int index) {
    return '第$index層';
  }

  @override
  String get layerInputSide => '\n(入力側)';

  @override
  String get layerOutputSide => '\n(出力側)';

  @override
  String nodesCount(int count) {
    return '$count 個';
  }

  @override
  String get warningHeavyStructure =>
      '【警告】スマホの限界を超える重い構造です！学習時に画面が完全にフリーズし、アプリが強制終了する危険があります。エコモードを50ms以上に設定することを強く推奨します。';

  @override
  String get batchSizeLabel => 'バッチサイズ';

  @override
  String batchSizeCount(int count) {
    return '$count 件';
  }

  @override
  String get batchSizeDesc => '※Adamの場合は少し大きめ(16〜32)にすると学習が安定します。';

  @override
  String get optimizerLabel => '最適化手法';

  @override
  String get optimizerDesc => '※SGD(原始的) / Mini-Batch(安定) / Adam(現代の主流・おすすめ)';

  @override
  String get lossFunctionLabel => '損失関数';

  @override
  String get lossMse => '平均二乗誤差 (MSE)';

  @override
  String get lossCrossEntropy => '交差エントロピー';

  @override
  String get lossDesc =>
      '※MSE(数値予測向け・高速) / 交差エントロピー(分類やテキスト生成向け。自動でSoftmaxが適用されますが、計算処理が非常に重くなるためエコモード推奨)';

  @override
  String get splitMethodTitle => '🔀 テスト用データの抽出方法';

  @override
  String get splitMethodRandom =>
      '現在の設定：【ランダムに抽出する】\nデータ全体からランダムに20%を抜き出してテスト（Val）用として使います。一般的なAI開発でおすすめの設定です。\nなお、生成モードの場合には、この設定に関係なく常に100%学習に使います。';

  @override
  String get splitMethodTail =>
      '現在の設定：【末尾から抽出する】\n入力されたリストの後ろから20%をテスト（Val）用として使います。時系列データに有効です。\nなお、生成モードの場合には、この設定に関係なく常に100%学習に使います。';

  @override
  String get confirmResetBrainTitle => '脳のリセット確認';

  @override
  String get confirmResetBrainDesc =>
      '構造とアルゴリズムの設定を適用し、AIの脳（重み）と学習履歴を完全にリセットしますか？\n※この操作は元に戻せません。';

  @override
  String get btnReset => 'リセット';

  @override
  String get msgResetTextGen => 'AIの脳を再構築し、元の文章から学習用データを全自動で再抽出しました。';

  @override
  String get msgResetNormal => 'AIの脳を再構築し、学習履歴をリセットしました。';

  @override
  String get settingsAppTitle => '⚙️ アプリ動作設定 (学習中もいつでも変更可能)';

  @override
  String get learningRateLabel => '学習率\n(歩幅)';

  @override
  String get learningRateDesc =>
      '※AIが正解を通り過ぎてしまう（Lossが下がらない）時は小さく、学習が遅い時は大きくします。';

  @override
  String get activationLabel => '活性化関数';

  @override
  String get activationDesc => '※Sigmoid(0〜1滑らか) / ReLU(現代主流) / Tanh(-1〜1メリハリ)';

  @override
  String get ecoModeLabel => 'エコモード\n(待機時間)';

  @override
  String get ecoModeDesc =>
      '※最小値の『20ms』に近づけるほど高速で学習しますが、スマホが発熱しやすくなります。ご使用の端末に合わせて数値を調整してください。';

  @override
  String get manualTitle => '箱庭小AI 説明書';

  @override
  String get manualTapHint => '緑色の下線がある単語をタップすると、解説が表示されます！';

  @override
  String get termEpoch => 'エポック';

  @override
  String get termEpochDesc => '学習の回数。教科書（全データ）を最初から最後まで1回読み終わることを「1エポック」と呼びます。';

  @override
  String get termLoss => 'Loss';

  @override
  String get termLossDesc =>
      'AIの答えと正解とのズレ（誤差）。これが0に近いほど優秀ですが、0.000にする必要はありません。';

  @override
  String get termOverfitting => '過学習';

  @override
  String get termOverfittingDesc => '練習問題を丸暗記してしまい、応用力がなくなった「ガリ勉」状態のこと。';

  @override
  String get termOneHot => 'One-Hot';

  @override
  String get termOneHotDesc => '文字やカテゴリを「0」と「1」のスイッチの並びに変換する手法。';

  @override
  String get termVanishingGradient => '勾配消失';

  @override
  String get termVanishingGradientDesc => '層を深くしすぎると、奥の方まで「反省（修正命令）」が届かなくなる現象。';

  @override
  String get termRelu => 'ReLU';

  @override
  String get termReluDesc => 'マイナスの入力を0にし、プラスはそのまま通す活性化関数。計算が速く学習しやすい。';

  @override
  String get termAdam => 'Adam';

  @override
  String get termAdamDesc => '学習率を自動調整してくれる賢い最適化手法。迷ったらコレ。';

  @override
  String get termNGram => 'Nグラム';

  @override
  String get termNGramDesc => '「直前の何文字を見るか」という設定。文脈の長さを決めます。';

  @override
  String get termTemperature => 'ゆらぎ';

  @override
  String get termTemperatureDesc => 'Temperature。AIが次の文字を選ぶ時の「冒険心（ランダム性）」の強さ。';

  @override
  String get termWeight => '重み';

  @override
  String get termWeightDesc => 'Weight。入力情報の重要度。AIの記憶そのもの。';

  @override
  String get termBias => 'バイアス';

  @override
  String get termBiasDesc => 'Bias。ニューロンの発火しやすさ（下駄）。性格のようなもの。';

  @override
  String get termFuturePrediction => '未来予知';

  @override
  String get termFuturePredictionDesc => 'AIが選んだ文字の、さらにその先を予測する機能。';

  @override
  String get termSensitivityAnalysis => '感度分析';

  @override
  String get termSensitivityAnalysisDesc =>
      '特定の入力情報を遮断して、AIの反応を見る実験手法。アブレーションとも呼ばれます。';

  @override
  String get termBatchSize => 'バッチサイズ';

  @override
  String get termBatchSizeDesc => 'まとめて学習するデータの数。1だと毎回反省し、大きいと平均をとってから反省します。';

  @override
  String get ch1Title => '遊び方の基本';

  @override
  String get ch1Intro => 'このアプリは、スマホの中でAI（人工知能）の頭脳を一から育てることができるシミュレーターです。';

  @override
  String get ch1Sec1Title => '1. データタブ（教科書づくり）';

  @override
  String get ch1Sec1Desc =>
      'AIに覚えさせるためのデータを作ります。数値をいじって「この入力の時はこの結果になる」という例題をリストに追加します。';

  @override
  String get ch1Sec2Title => '2. 学習タブ（AIの勉強）';

  @override
  String get ch1Sec2Desc => '「学習開始」を押してAIに勉強させます。エポック数は教科書を何周繰り返し読むかを表します。';

  @override
  String get ch1Sec3Title => '3. 推論タブ（テスト）';

  @override
  String get ch1Sec3Desc =>
      '学習済みのAIのテストを行います。未知の数値を入力し、AIがどんな予測を弾き出すか実験してみましょう。';

  @override
  String get ch1Tip =>
      '💡 コツ：数値予測モードでは数十件のデータでも十分ですが、テキスト生成モードでは数百〜数千文字のデータが必要です。AIの成長には時間がかかるので、気長に見守ってあげてください。';

  @override
  String get ch2Title => '生成AIモードの仕組み';

  @override
  String get ch2Intro => 'テキスト生成モードを選ぶと、ChatGPTのような「文章を生み出すAI」の赤ちゃんを作ることができます。';

  @override
  String get ch2Sec1Title => '予測マシーンとしてのAI';

  @override
  String get ch2Sec1Desc =>
      '生成AIは、裏側で「『む』『か』『し』と来たら、次は『む』が来る確率が高い」という予測をひたすら繰り返しているだけです。';

  @override
  String get ch2Sec2Title => '⚠️ 会話はできません';

  @override
  String get ch2Sec2Desc =>
      'このAIは「直前の数文字（Nグラム）」しか記憶できない超・健忘症です。意味を理解して会話することはできません。';

  @override
  String get ch2ColumnTitle => '【コラム】現代のAIはどれくらい凄いの？';

  @override
  String get ch2ColumnDesc =>
      '箱庭小AIのテキスト生成モードは、「数百個のスイッチ（One-Hot）」をカチカチ切り替えて言葉を紡いでいます。\n対して、ChatGPTのような巨大なAIは、このスイッチの数が「数千億〜数兆個」という、想像を絶する規模で構成されています。\n\nスイッチの数が桁違いに多いからこそ、長い文脈を記憶し、人間のような会話ができるのです。しかし、根本的な仕組みは同じです。みなさんのスマホの中で数百個のスイッチが懸命に動く姿は、巨大AIが誕生するまでの「最初の一歩」を再現しているのです。';

  @override
  String get ch2Sec3Title => '📉 Lossが1.0から減らない？';

  @override
  String get ch2Sec3Desc =>
      'バグではありません！最初は超難問に挑んでいるため、Lossはしばらく1.0付近で停滞します。数千エポック以上、気長に待つと突然「覚醒」して下がり始めます。';

  @override
  String get ch3Title => 'AIの思考を透視する';

  @override
  String get ch3Intro =>
      'Ver 1.3.0では、今までブラックボックスだった「AIの頭の中」を数値とグラフで可視化する、強力な分析機能が搭載されました。';

  @override
  String get ch3Sec1Title => '🔮 2手先までの未来予知（連鎖）';

  @override
  String get ch3Sec1Desc =>
      'テキスト生成モードで「1文字進む」ボタンを押すと、AIが次に選ぶ文字だけでなく、「その文字を選んだら、さらに次はどうなるか？」という2手先までの未来予知が表示されます。\n「あ、この文字を選ぶとループしそうだぞ」といったAIの思考の連鎖が手に取るように分かります。';

  @override
  String get ch3Sec2Title => '💯 正答率と混同行列（分類のみ）';

  @override
  String get ch3Sec2Desc =>
      '「文系・理系」のような分類問題では、学習結果の「正答率」が表示されます。\nさらに詳細な「混同行列（Confusion Matrix）」ボタンを押すと、「文系を理系と間違えた回数」などが表形式で分かります。「AIがどのパターンを苦手としているか」を一目で特定できます。';

  @override
  String get ch3Sec3Title => '📉 予測のズレ散布図（数値のみ）';

  @override
  String get ch3Sec3Desc =>
      '「価格・気温」のような数値予測では、AIの予測値と正解データのズレを「散布図」で表示します。\n点が斜めの線上に集まっているほど優秀なAIです。大きく外れている点は、AIにとって「想定外のデータ」だったことを意味します。';

  @override
  String get ch3Sec4Title => '📊 重要度分析（Permutation Importance）';

  @override
  String get ch3Sec4Desc =>
      'AIが「どの入力データを一番頼りにしているか」をランキング形式で表示します。\n入力データを項目ごとにわざとシャッフルしてAIを混乱させ、その時にどれくらい予測精度が落ちるかを測定します。「シャッフルして精度がガタ落ちした＝AIが最も重要視していたデータ」と逆算する、データサイエンスの現場で使われる高度な分析手法です。';

  @override
  String get ch3Sec5Title => '🎛️ 感度分析（アブレーション実験）';

  @override
  String get ch3Sec5Desc =>
      '推論タブや学習画面に「入力スイッチ」が追加されました。\nこれは「ある情報を完全に遮断（OFF）したら、AIはどう判断するか？」をテストする機能です。\n例えば「広さ」のスイッチをOFFにしても家賃予測が変わらなければ、AIは「広さなんて見ていない（無視している）」ことがバレてしまいます。';

  @override
  String get ch4Title => '設定全項目リファレンス (上級者向け)';

  @override
  String get ch4Intro => '設定画面にあるすべての項目についての解説です。意味が分からなくなった時の辞書としてお使いください。\n';

  @override
  String get ch4Sub1 => '【AIの構造（脳の形）】';

  @override
  String get ch4Layers => '隠れ層の数 (Layers)';

  @override
  String get ch4LayersDesc => '脳みその会議の回数。多いほど複雑な法則を見つけられますが、学習が難しくなります。';

  @override
  String get ch4LayersRec => '1〜2層（通常）、2〜3層（生成AI）';

  @override
  String get ch4Units => 'ユニット数 (Units)';

  @override
  String get ch4UnitsDesc => '1回の会議に参加するニューロンの数。多いほど細かいニュアンスを表現できます。';

  @override
  String get ch4UnitsRec => '10〜20個（通常）、50〜100個（生成AI）';

  @override
  String get ch4Activation => '活性化関数 (Activation)';

  @override
  String get ch4ActivationDesc =>
      'ニューロンの情報の伝え方（性格）です。\n・Sigmoid: 0〜1に収める。層が深いと学習しなくなる。\n・ReLU: マイナスは無視、プラスはそのまま。計算が速く優秀。（※本アプリでは「Dying ReLU問題」を防ぎ学習を安定させるため、裏側ではマイナス側にも微小な傾きを持たせた『Leaky ReLU』を採用しています）\n・Tanh: -1〜1に収める。Sigmoidよりメリハリがある。';

  @override
  String get ch4ActivationRec => 'ReLU（迷ったらコレ）';

  @override
  String get ch4Sub2 => '【学習の方法（勉強法）】';

  @override
  String get ch4Optimizer => '最適化手法 (Optimizer)';

  @override
  String get ch4OptimizerDesc =>
      '反省のタイミングと計算方法です。\n・SGD: 一問一答で即反省。グラフが暴れやすい。\n・Mini-batch: 数問まとめてから平均をとって反省。SGDより安定して学習できる。\n・Adam: 過去の傾向を記憶して学習率を自動調整する天才。迷ったらコレ。';

  @override
  String get ch4OptimizerRec => 'Adam';

  @override
  String get ch4LR => '学習率 (Learning Rate)';

  @override
  String get ch4LRDesc =>
      '1回の失敗からどれくらい大きく考え方を変えるか（歩幅）。\n大きすぎると正解を通り過ぎて発散し、小さすぎるといつまでも終わらない。';

  @override
  String get ch4LRRec => '0.01 〜 0.001（Adamなら自動調整されるので気にしなくてOK）';

  @override
  String get ch4BatchSize => 'バッチサイズ (Batch Size)';

  @override
  String get ch4BatchSizeDesc =>
      '何問解くごとに反省会を開くか。\n・1: 毎回反省。正確だが遅い。\n・10〜32: まとめて平均をとって反省。計算が速く、安定する。';

  @override
  String get ch4BatchSizeRec => 'データ数の10分の1程度（生成AIなら32〜64）';

  @override
  String get ch4LossFunc => '損失関数 (Loss Function)';

  @override
  String get ch4LossFuncDesc =>
      '間違いの採点方法です。\n・MSE (平均二乗誤差): 数値予測向き。\n・Cross Entropy (交差エントロピー): 分類・生成AI向き。計算は重いが、正解への近道を知っている。';

  @override
  String get ch4LossFuncRec => '数値予測ならMSE、生成AIならCross Entropy';

  @override
  String get ch4Sub3 => '【データの扱い】';

  @override
  String get ch4ValRatio => 'テストデータ比率 (Val Ratio)';

  @override
  String get ch4ValRatioDesc =>
      '全データのうち、カンニング防止（テスト用）に隠しておく割合。\n20%に設定すると、残り80%だけで勉強します。';

  @override
  String get ch4ValRatioRec => '20%(このアプリでは固定)';

  @override
  String get ch4SplitMode => '抽出モード';

  @override
  String get ch4SplitModeDesc =>
      'テスト用データをどこから選ぶか。\n・ランダム: 全体からバラバラに選ぶ。偏りを防ぐ。\n・末尾抽出: データの最後の方をテストにする。時系列データ（株価や文章の続き）用。';

  @override
  String get ch4SplitModeRec => '基本はランダム、生成AIは末尾';

  @override
  String get ch4EcoMode => 'エコモード (Eco Mode)';

  @override
  String get ch4EcoModeDesc =>
      '1エポックごとの休憩時間（ミリ秒）。\nスマホの発熱を抑えるためにCPUを休ませます。数値を上げると学習は遅くなりますが、電池持ちが良くなります。';

  @override
  String ch4RecommendPrefix(String text) {
    return '💡 推奨: $text';
  }

  @override
  String get ch5Title => '学習の仕組みと裏側';

  @override
  String get ch5Sec1Title => '📊 TrainとVal（カンニング防止）';

  @override
  String get ch5Sec1Desc =>
      '青線(Train)が下がっているのにオレンジ線(Val)が上がったら、それは過学習（丸暗記）のサインです。';

  @override
  String get ch5Sec2Title => '🎯 Lossは0.000を目指さなくていい';

  @override
  String get ch5Sec2Desc =>
      'Lossを無理に0にしようとすると「過学習」になります。0.1〜0.05あたりで十分賢い状態です。「腹八分目」がAI育成の鉄則です。';

  @override
  String get ch5Sec3Title => '🤔 なぜ答えは「◯◯%」なの？';

  @override
  String get ch5Sec3Desc =>
      'AIは物事を白黒つけるのが苦手です。「晴れっぽさ0.8、雨っぽさ0.2」という確率（グラデーション）で世界を見ています。';

  @override
  String get ch5Sec4Title => '🎲 重み・バイアスと「リセット」';

  @override
  String get ch5Sec4Desc =>
      'AIの脳内で行われている『脳内会議』を想像してみてください。そこには膨大な数の『計算ボタン（参加者）』がいて、それぞれが個性的な性格を持っています。\n\n【重み（Weight）：情報のえこひいき】\nこれは『誰の意見をどれくらい信用するか』という度合いです。「Aさんの意見は2倍の大きさで聞くけど、Bさんの意見は半分しか聞かない（無視する）」といった具合に、情報に優先順位をつける役割です。\n\n【バイアス（Bias）：元々のノリ】\nこれは、その参加者が『そもそも賛成しやすいか、反対しやすいか』という元々の性格（ゲタ）です。「まだ何も聞いてないのに、最初からなんとなく賛成気味」という楽天家もいれば、頑固な否定派もいます。\n\n━━━━━━━━━━━━━━━━━━━━\n  💡 ここが超重要！\n  学習とは、すべてのボタンの\n  「信頼度（重み）」と「性格（バイアス）」の両方を\n  正解に合わせて、少しずつ微調整していく\n  地道な作業のことを指します。\n━━━━━━━━━━━━━━━━━━━━\n\n【リセットの秘密：運命のダイス】\nリセットボタンを押すと、これら全ての性格がサイコロでランダムに振り直されます。\n実はAIにも「生まれつきの才能（運）」があります。何度勉強してもLossが下がらない時は、たまたま性格の相性が悪かっただけかもしれません。\nそんな時は迷わずリセットして、新しい才能を持ったAIに生まれ変わらせてあげてください！';

  @override
  String get ch5Sec5Title => '🔄 One-Hotエンコーディング';

  @override
  String get ch5Sec5Desc =>
      'AIは計算機なので、文字をそのまま読むことはできません。そこで裏側では、文字を「スイッチの並び」に変換しています。\n\n【名前の由来：1つだけが熱い！】\n例えば「あ・い・う」の3種類がある場合、[1, 0, 0]のように「1つだけを1（ON）にし、他はすべて0（OFF）にする」というルールで表現します。この『1つ（One）だけがON（Hot）』という状態が、名前の由来です。\n\n【脳の入り口が自動で増える！】\nこのアプリで「分類（ドロップダウン）」を選択すると、裏側では選択肢の数だけAIの脳の入り口（神経細胞）が自動的に増設されます。天気予報で『晴れ・曇り・雨』の3つを選んだら、AIの脳には専用の入り口が3つ用意され、該当する場所だけがカチッとONになる仕組みです。';

  @override
  String get ch6Title => 'アプリの仕様とQ&A';

  @override
  String get ch6Q1Title => 'Q. テキスト生成モードでは、なぜデータの100%を学習に使い、検証用のデータを用意しないのですか？';

  @override
  String get ch6Q1Desc =>
      'A. とても小規模なモデルであり、数文字の並びから続きを予測するには、データを「丸暗記」するくらいがちょうど良いためです。\nもし検証用にデータを分けてしまうと、そこに含まれる言葉はAIが学習できず、「教えたはずの言葉をいつまでも話してくれない」ということが起きてしまいます。\nあなたが入力した文章の癖や言い回しを余すことなく吸収させるため、教科書（データ）を隅から隅まで100%使用して学習させています。\n';

  @override
  String get ch6Q2Title => 'Q. データを変えるとリセットされる？';

  @override
  String get ch6Q2Desc => 'A. はい。古い知識が邪魔をしないよう、データ構造が変わると脳は初期化されます。';

  @override
  String get ch6Q3Title => 'Q. Excelからの貼り付けやCSVファイルからの読み込みでの見出し行は？';

  @override
  String get ch6Q3Desc => 'A. 見出し行があってもなくても大丈夫です。文字だけの行や空欄行は自動で無視されます。';

  @override
  String get ch6Q4Title => 'Q. 読み込まれた件数が、元のデータより少ない気がする';

  @override
  String get ch6Q4Desc =>
      'A. データの途中に「空欄（欠損値）」があったり、「全角数字（１２３）」「カンマ付きの数字（1,000）」「単位（円など）」が含まれている行は、AIが計算エラーを起こすのを防ぐため、自動的にスキップ（無視）される安全設計になっています。数値はすべて半角数字で入力されているか確認してください。\n（※ただし、分類項目に設定している列については、「男性」「女性」といった文字はもちろん、「1」「2」のような数字のカテゴリであっても、数値としてではなく正しく「分類」として認識して読み込みます！）';

  @override
  String get ch6Q5Title => 'Q. 桁が大きい数字はそのまま入力して良いの？';

  @override
  String get ch6Q5Desc =>
      'A. 年収（500万）や年齢（20）のような数字も、あなたが設定した最小値と最大値をもとに内部で自動的に0〜1の範囲に変換（正規化）されるので、そのまま入力してOKです。';

  @override
  String get ch6Q6Title => 'Q. Transformerじゃないの？';

  @override
  String get ch6Q6Desc => 'A. 作者の技術力不足です！これは原始的な多層パーセプトロン（MLP）による力技の実装です。';

  @override
  String get footerTermsTitle => '🎓 ご利用にあたって';

  @override
  String get footerTermsDesc =>
      'このアプリは、どなたでもご自由にお使いいただきたいと考えています。\n学校の授業での活用や、YouTube等での紹介・配信についても、事前の連絡や許可は一切不要です。\n「AIって意外とシンプルで面白いな」と感じてくれる人が一人でも増えれば、作者としてこれほど嬉しいことはありません。';

  @override
  String get footerPrivacyTitle => '🔒 プライバシーポリシー';

  @override
  String get footerPrivacyDesc =>
      'Shin Tomura（以下、「開発者」といいます）は、スマートフォン向けアプリ「箱庭小AI」（以下、「本アプリ」といいます）における、ユーザーの個人情報およびプライバシー情報の取り扱いについて、以下の通りプライバシーポリシーを定めます。\n\n1. 個人情報の収集および利用について\n本アプリは完全オフライン（デバイス内完結型）で動作するように設計されています。ユーザーが入力した学習データ、AIの構造、学習結果などのすべてのデータは、ユーザーのスマートフォン端末内にのみ保存されます。\n開発者がこれらの個人情報や入力データを収集、取得、または外部サーバーへ送信することは一切ありません。\n\n2. デバイス機能へのアクセスについて\n本アプリでは、以下の機能を利用するためにデバイスの一部の機能にアクセスしますが、これらのデータが外部に送信されることはありません。\n・クリップボード: データのインポート、および「呪文」のコピー・ペーストを行うために利用します。\n・ファイルアクセス: 学習データのCSVインポート・エクスポート機能を利用する際に、端末内のファイルシステムにアクセスします。\n・写真ライブラリおよび画像ファイル: 画像生成（VAE）モードの学習データとして端末内の画像を選択・読み込むため、および生成した画像を端末に保存・共有するためにアクセスします。読み込まれた画像や生成されたデータはデバイス内でのみ処理され、外部サーバーへ送信されることは一切ありません。\n\n3. 第三者への情報提供\n本アプリはユーザーの個人情報および入力データを一切収集していないため、第三者に対して情報を提供することはありません。また、外部のアナリティクスツールや第三者の広告モジュールは組み込まれていません。\n\n4. 免責事項\n本アプリを利用したことにより生じた、いかなるトラブルや損害についても、開発者は一切の責任を負わないものとします。データのバックアップやアプリの利用は、ユーザーご自身の責任において行ってください。\n\n5. プライバシーポリシーの変更\n開発者は、必要に応じて本ポリシーを変更することがあります。変更後のプライバシーポリシーは、本ページに掲載された時点から効力を生じるものとします。\n\n6. お問い合わせ窓口\n開発者: Shin Tomura\n連絡先: [hakoniwa@ymail.plala.or.jp]\n\n（制定日：2026年3月22日）';

  @override
  String msgImportSuccess(int count) {
    return '$count件のデータをインポートしました！';
  }

  @override
  String get msgImportTruncated => '※安全のため10,000件で打ち切りました。';

  @override
  String get msgNoDataToImport => 'インポートできるデータが見つかりませんでした。';

  @override
  String msgImportError(String error) {
    return 'エラーが発生しました: $error';
  }

  @override
  String get msgNoTextInClipboard => 'クリップボードにテキストがありません。';

  @override
  String get msgFileTooLarge => 'ファイルサイズが大きすぎます(上限5MB)。スマホ保護のため中止しました。';

  @override
  String get msgFileLoadFailed => 'ファイルの読み込みに失敗しました。';

  @override
  String get msgDataCopiedToClipboard => 'データをクリップボードにコピーしました。Excel等に貼り付けられます。';

  @override
  String get msgExportTruncated5000 => '※安全のため最初の5,000件のみ出力しました。';

  @override
  String get msgCsvExported => 'CSVファイルを出力しました！';

  @override
  String msgCsvExportFailed(String error) {
    return 'CSV保存に失敗しました: $error';
  }

  @override
  String msgShareCsvText(String name) {
    return '「$name」の学習データ(CSV)';
  }

  @override
  String get editProjectAndItemNameTitle => 'プロジェクト・項目名の変更';

  @override
  String get projectNameHeader => 'プロジェクト名';

  @override
  String get inputItemNamesHeader => '▼ 入力項目の名前';

  @override
  String get outputItemNamesHeader => '▼ 出力項目の名前';

  @override
  String inputItemLabelNum(int num) {
    return '入力 $num';
  }

  @override
  String outputItemLabelNum(int num) {
    return '出力 $num';
  }
}
