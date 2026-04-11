import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// No description provided for @btnRoundtable.
  ///
  /// In ja, this message translates to:
  /// **'AI座談会'**
  String get btnRoundtable;

  /// No description provided for @btnNewProject.
  ///
  /// In ja, this message translates to:
  /// **'新規作成'**
  String get btnNewProject;

  /// No description provided for @msgCannotPopDuringTraining.
  ///
  /// In ja, this message translates to:
  /// **'⚠️ 学習中はホームに戻れません。先に「停止」を押してください。'**
  String get msgCannotPopDuringTraining;

  /// No description provided for @tabData.
  ///
  /// In ja, this message translates to:
  /// **'データ'**
  String get tabData;

  /// No description provided for @tabTrain.
  ///
  /// In ja, this message translates to:
  /// **'学習'**
  String get tabTrain;

  /// No description provided for @tabPredict.
  ///
  /// In ja, this message translates to:
  /// **'推論'**
  String get tabPredict;

  /// No description provided for @tabSettings.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get tabSettings;

  /// No description provided for @tabManual.
  ///
  /// In ja, this message translates to:
  /// **'説明書'**
  String get tabManual;

  /// No description provided for @msgScreenSaver.
  ///
  /// In ja, this message translates to:
  /// **'AIが学習中...\n画面をタップして復帰'**
  String get msgScreenSaver;

  /// No description provided for @projectCopyName.
  ///
  /// In ja, this message translates to:
  /// **'{name}のコピー'**
  String projectCopyName(String name);

  /// No description provided for @newProjectDefaultName.
  ///
  /// In ja, this message translates to:
  /// **'新規プロジェクト'**
  String get newProjectDefaultName;

  /// No description provided for @msgStructureChangedResetData.
  ///
  /// In ja, this message translates to:
  /// **'構成が変更されたため、引き継いだ学習データをリセットしました。'**
  String get msgStructureChangedResetData;

  /// No description provided for @addInputTitle.
  ///
  /// In ja, this message translates to:
  /// **'入力の追加'**
  String get addInputTitle;

  /// No description provided for @addOutputTitle.
  ///
  /// In ja, this message translates to:
  /// **'出力の追加'**
  String get addOutputTitle;

  /// No description provided for @itemNameLabel.
  ///
  /// In ja, this message translates to:
  /// **'項目名'**
  String get itemNameLabel;

  /// No description provided for @typeNumericSlider.
  ///
  /// In ja, this message translates to:
  /// **'数値 (スライダー)'**
  String get typeNumericSlider;

  /// No description provided for @typeCategoryDropdown.
  ///
  /// In ja, this message translates to:
  /// **'分類 (ドロップダウン)'**
  String get typeCategoryDropdown;

  /// No description provided for @typeNumericDirect.
  ///
  /// In ja, this message translates to:
  /// **'数値 (直接入力)'**
  String get typeNumericDirect;

  /// No description provided for @minValueLabel.
  ///
  /// In ja, this message translates to:
  /// **'最小値'**
  String get minValueLabel;

  /// No description provided for @maxValueLabel.
  ///
  /// In ja, this message translates to:
  /// **'最大値'**
  String get maxValueLabel;

  /// No description provided for @editCategoriesLabel.
  ///
  /// In ja, this message translates to:
  /// **'選択肢の編集'**
  String get editCategoriesLabel;

  /// No description provided for @newCategoryHint.
  ///
  /// In ja, this message translates to:
  /// **'新しい選択肢'**
  String get newCategoryHint;

  /// No description provided for @msgRequireOneCategory.
  ///
  /// In ja, this message translates to:
  /// **'※選択肢を1つ以上追加してください'**
  String get msgRequireOneCategory;

  /// No description provided for @btnCancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get btnCancel;

  /// No description provided for @btnAdd.
  ///
  /// In ja, this message translates to:
  /// **'追加'**
  String get btnAdd;

  /// No description provided for @unnamedItem.
  ///
  /// In ja, this message translates to:
  /// **'未設定'**
  String get unnamedItem;

  /// No description provided for @pastChar.
  ///
  /// In ja, this message translates to:
  /// **'過去文字{i}'**
  String pastChar(int i);

  /// No description provided for @nextOneChar.
  ///
  /// In ja, this message translates to:
  /// **'次の1文字'**
  String get nextOneChar;

  /// No description provided for @msgRequireInputOutput.
  ///
  /// In ja, this message translates to:
  /// **'入力と出力の項目を少なくとも1つずつ設定してください。'**
  String get msgRequireInputOutput;

  /// No description provided for @copyProjectTitle.
  ///
  /// In ja, this message translates to:
  /// **'プロジェクトのコピー'**
  String get copyProjectTitle;

  /// No description provided for @createNewProjectTitle.
  ///
  /// In ja, this message translates to:
  /// **'新規作成'**
  String get createNewProjectTitle;

  /// No description provided for @projectNameLabel.
  ///
  /// In ja, this message translates to:
  /// **'プロジェクト名'**
  String get projectNameLabel;

  /// No description provided for @aiTypeLabel.
  ///
  /// In ja, this message translates to:
  /// **'AIのタイプ'**
  String get aiTypeLabel;

  /// No description provided for @typeNumericPredict.
  ///
  /// In ja, this message translates to:
  /// **'数値予測 (通常)'**
  String get typeNumericPredict;

  /// No description provided for @typeTextGeneration.
  ///
  /// In ja, this message translates to:
  /// **'テキスト生成 (LLM)'**
  String get typeTextGeneration;

  /// No description provided for @inheritDataLabel.
  ///
  /// In ja, this message translates to:
  /// **'元の学習データも引き継ぐ'**
  String get inheritDataLabel;

  /// No description provided for @btnAddInput.
  ///
  /// In ja, this message translates to:
  /// **'＋ 入力を追加'**
  String get btnAddInput;

  /// No description provided for @categoryFormat.
  ///
  /// In ja, this message translates to:
  /// **'分類 ({categories})'**
  String categoryFormat(String categories);

  /// No description provided for @numericFormat.
  ///
  /// In ja, this message translates to:
  /// **'数値 ({min} ~ {max})'**
  String numericFormat(double min, double max);

  /// No description provided for @btnAddOutput.
  ///
  /// In ja, this message translates to:
  /// **'＋ 出力を追加'**
  String get btnAddOutput;

  /// No description provided for @learningLanguageLabel.
  ///
  /// In ja, this message translates to:
  /// **'学習言語'**
  String get learningLanguageLabel;

  /// No description provided for @langHiragana.
  ///
  /// In ja, this message translates to:
  /// **'ひらがな'**
  String get langHiragana;

  /// No description provided for @langEnglish.
  ///
  /// In ja, this message translates to:
  /// **'英語 (アルファベット等)'**
  String get langEnglish;

  /// No description provided for @descTextGenerationMode.
  ///
  /// In ja, this message translates to:
  /// **'【テキスト生成モード】\n選択した言語の文章を読み込ませることで、次に来る文字を予測して文章を自動生成する言語モデル（LLM）を作ります。\n\n※入力・出力の構成は自動で「直近の文字 → 次の1文字」に設定されます。'**
  String get descTextGenerationMode;

  /// No description provided for @btnCreateCopy.
  ///
  /// In ja, this message translates to:
  /// **'この内容でコピーを作成'**
  String get btnCreateCopy;

  /// No description provided for @btnCreateProject.
  ///
  /// In ja, this message translates to:
  /// **'この内容でプロジェクトを作成'**
  String get btnCreateProject;

  /// No description provided for @groupChatTitle.
  ///
  /// In ja, this message translates to:
  /// **'AI座談会'**
  String get groupChatTitle;

  /// No description provided for @tabCharSelect.
  ///
  /// In ja, this message translates to:
  /// **'キャラ選択'**
  String get tabCharSelect;

  /// No description provided for @tabCharSettings.
  ///
  /// In ja, this message translates to:
  /// **'キャラ設定'**
  String get tabCharSettings;

  /// No description provided for @tabChatRun.
  ///
  /// In ja, this message translates to:
  /// **'座談会実行'**
  String get tabChatRun;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In ja, this message translates to:
  /// **'削除の確認'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In ja, this message translates to:
  /// **'「{name}」を削除してもよろしいですか？\n※復元できません。'**
  String confirmDeleteMessage(String name);

  /// No description provided for @btnDelete.
  ///
  /// In ja, this message translates to:
  /// **'削除する'**
  String get btnDelete;

  /// No description provided for @editProjectNameTitle.
  ///
  /// In ja, this message translates to:
  /// **'プロジェクト名の変更'**
  String get editProjectNameTitle;

  /// No description provided for @editProjectNameHint.
  ///
  /// In ja, this message translates to:
  /// **'新しい名前を入力'**
  String get editProjectNameHint;

  /// No description provided for @btnChange.
  ///
  /// In ja, this message translates to:
  /// **'変更'**
  String get btnChange;

  /// No description provided for @appTitle.
  ///
  /// In ja, this message translates to:
  /// **'箱庭小AI'**
  String get appTitle;

  /// No description provided for @tooltipImport.
  ///
  /// In ja, this message translates to:
  /// **'プロジェクトを読み込む'**
  String get tooltipImport;

  /// No description provided for @tooltipEditName.
  ///
  /// In ja, this message translates to:
  /// **'名前を変更'**
  String get tooltipEditName;

  /// No description provided for @projectInfoSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'v{version} / データ: {dataCount}件 / 層:{layers} ユニット:[{nodesList}]'**
  String projectInfoSubtitle(
    String version,
    int dataCount,
    int layers,
    String nodesList,
  );

  /// No description provided for @tooltipExport.
  ///
  /// In ja, this message translates to:
  /// **'共有・出力'**
  String get tooltipExport;

  /// No description provided for @tooltipCopy.
  ///
  /// In ja, this message translates to:
  /// **'コピー'**
  String get tooltipCopy;

  /// No description provided for @tooltipDelete.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get tooltipDelete;

  /// No description provided for @welcomeTitle.
  ///
  /// In ja, this message translates to:
  /// **'AIを作って遊ぼう！'**
  String get welcomeTitle;

  /// No description provided for @welcomeDesc.
  ///
  /// In ja, this message translates to:
  /// **'箱庭小AIは、スマホの中でAI（人工知能）の頭脳を一から育てることができるシミュレーターです。'**
  String get welcomeDesc;

  /// No description provided for @welcomeStepTitle.
  ///
  /// In ja, this message translates to:
  /// **'💡 遊び方の３ステップ'**
  String get welcomeStepTitle;

  /// No description provided for @welcomeStepDesc.
  ///
  /// In ja, this message translates to:
  /// **'1. データ: 「国語と数学の点数」などの例題を登録\n2. 学習: ターミナルで誤差が減るのを見守る\n3. 推論: 未知の数値を入力してAIの予測を楽しむ'**
  String get welcomeStepDesc;

  /// No description provided for @btnStartWithSample.
  ///
  /// In ja, this message translates to:
  /// **'サンプルを作成して始める'**
  String get btnStartWithSample;

  /// No description provided for @exportDialogTitle.
  ///
  /// In ja, this message translates to:
  /// **'プロジェクトの出力'**
  String get exportDialogTitle;

  /// No description provided for @exportDialogDesc.
  ///
  /// In ja, this message translates to:
  /// **'「{name}」を共有・保存します。'**
  String exportDialogDesc(String name);

  /// No description provided for @estimatedDataSize.
  ///
  /// In ja, this message translates to:
  /// **'推定データサイズ: {size}'**
  String estimatedDataSize(String size);

  /// No description provided for @warningLargeSize.
  ///
  /// In ja, this message translates to:
  /// **'※データサイズが大きすぎるため、メールやメモ帳がフリーズするのを防ぐ目的で「呪文コピー」を制限しています。ファイル出力をご利用ください。'**
  String get warningLargeSize;

  /// No description provided for @btnSpellCopy.
  ///
  /// In ja, this message translates to:
  /// **'呪文コピー'**
  String get btnSpellCopy;

  /// No description provided for @btnFileOutput.
  ///
  /// In ja, this message translates to:
  /// **'ファイル出力'**
  String get btnFileOutput;

  /// No description provided for @msgSpellCopied.
  ///
  /// In ja, this message translates to:
  /// **'クリップボードに呪文をコピーしました！メール等に貼り付けてください。'**
  String get msgSpellCopied;

  /// No description provided for @errorDataGenerationFailed.
  ///
  /// In ja, this message translates to:
  /// **'圧縮データの生成に失敗しました'**
  String get errorDataGenerationFailed;

  /// No description provided for @errorSizeLimitExceeded.
  ///
  /// In ja, this message translates to:
  /// **'圧縮後もファイルサイズが5MBを超過しているため出力できません。'**
  String get errorSizeLimitExceeded;

  /// No description provided for @shareProjectText.
  ///
  /// In ja, this message translates to:
  /// **'箱庭小AIのプロジェクト「{name}」を共有します！'**
  String shareProjectText(String name);

  /// No description provided for @shareProjectSubject.
  ///
  /// In ja, this message translates to:
  /// **'{name} のデータ'**
  String shareProjectSubject(String name);

  /// No description provided for @msgFileExported.
  ///
  /// In ja, this message translates to:
  /// **'「{name}」のファイルを出力しました！'**
  String msgFileExported(String name);

  /// No description provided for @errorFileExport.
  ///
  /// In ja, this message translates to:
  /// **'ファイル出力エラー: {error}'**
  String errorFileExport(String error);

  /// No description provided for @versionOldTitle.
  ///
  /// In ja, this message translates to:
  /// **'バージョンが古いです'**
  String get versionOldTitle;

  /// No description provided for @versionOldDesc.
  ///
  /// In ja, this message translates to:
  /// **'このプロジェクトは新しいバージョンの「箱庭小AI (v{version})」で作られています。\n\n正常に召喚・動作させるために、アプリを最新版にアップデートしてから再度お試しください！'**
  String versionOldDesc(String version);

  /// No description provided for @btnConfirm.
  ///
  /// In ja, this message translates to:
  /// **'確認'**
  String get btnConfirm;

  /// No description provided for @importDialogTitle.
  ///
  /// In ja, this message translates to:
  /// **'プロジェクトの読み込み'**
  String get importDialogTitle;

  /// No description provided for @importDialogDesc.
  ///
  /// In ja, this message translates to:
  /// **'どちらの方法で読み込みますか？'**
  String get importDialogDesc;

  /// No description provided for @btnSpellPaste.
  ///
  /// In ja, this message translates to:
  /// **'呪文(貼り付け)'**
  String get btnSpellPaste;

  /// No description provided for @btnSelectFile.
  ///
  /// In ja, this message translates to:
  /// **'ファイルを選択'**
  String get btnSelectFile;

  /// No description provided for @castSpellTitle.
  ///
  /// In ja, this message translates to:
  /// **'呪文を唱える'**
  String get castSpellTitle;

  /// No description provided for @castSpellHint.
  ///
  /// In ja, this message translates to:
  /// **'ここに呪文(テキスト)をペースト...'**
  String get castSpellHint;

  /// No description provided for @btnSummon.
  ///
  /// In ja, this message translates to:
  /// **'召喚'**
  String get btnSummon;

  /// No description provided for @spellSummonSuffix.
  ///
  /// In ja, this message translates to:
  /// **'呪文召喚'**
  String get spellSummonSuffix;

  /// No description provided for @fileSummonSuffix.
  ///
  /// In ja, this message translates to:
  /// **'ファイル召喚'**
  String get fileSummonSuffix;

  /// No description provided for @errorNoDataInFile.
  ///
  /// In ja, this message translates to:
  /// **'ファイル内にプロジェクトデータが見つかりません'**
  String get errorNoDataInFile;

  /// No description provided for @msgSummonSuccess.
  ///
  /// In ja, this message translates to:
  /// **'見事な手際です！プロジェクトを召喚しました。'**
  String get msgSummonSuccess;

  /// No description provided for @msgSummonFailed.
  ///
  /// In ja, this message translates to:
  /// **'召喚に失敗しました。データが壊れているか、対応していない形式です。'**
  String get msgSummonFailed;

  /// No description provided for @readAiTextTitle.
  ///
  /// In ja, this message translates to:
  /// **'📚 AIに読ませる文章（{langName}）'**
  String readAiTextTitle(String langName);

  /// No description provided for @readAiTextDesc.
  ///
  /// In ja, this message translates to:
  /// **'ここに{hintExample}といった文章をペーストしてください。\n※AIは設定された文字数を見て「次の1文字」を予測するように自動で学習データを切り出します。'**
  String readAiTextDesc(String hintExample);

  /// No description provided for @warningTextEnglish.
  ///
  /// In ja, this message translates to:
  /// **'英語のアルファベットと基本的な記号（.,!?\'-）のみで入力願います。\n日本語や全角スペースなどは対象外です。'**
  String get warningTextEnglish;

  /// No description provided for @warningTextHiragana.
  ///
  /// In ja, this message translates to:
  /// **'ひらがなと句読点、ー！？のみで入力願います。\nかぎ括弧「」や漢字などは対象外です。'**
  String get warningTextHiragana;

  /// No description provided for @pasteTextHint.
  ///
  /// In ja, this message translates to:
  /// **'文章を入力またはペースト...'**
  String get pasteTextHint;

  /// No description provided for @currentMemoryDataCount.
  ///
  /// In ja, this message translates to:
  /// **'現在の記憶データ: {count}件'**
  String currentMemoryDataCount(int count);

  /// No description provided for @btnAutoGenerateData.
  ///
  /// In ja, this message translates to:
  /// **'文章から学習データを自動生成'**
  String get btnAutoGenerateData;

  /// No description provided for @dataLimitWarningTitle.
  ///
  /// In ja, this message translates to:
  /// **'データ上限の警告'**
  String get dataLimitWarningTitle;

  /// No description provided for @dataLimitWarningDesc.
  ///
  /// In ja, this message translates to:
  /// **'記憶できるデータの上限（約15,000件）を超えてしまいます。\n安全のため、先に「記憶を全消去」するか、短い文章にしてください。'**
  String get dataLimitWarningDesc;

  /// No description provided for @errorUnsupportedCharsTitle.
  ///
  /// In ja, this message translates to:
  /// **'エラー：未対応の文字が含まれています'**
  String get errorUnsupportedCharsTitle;

  /// No description provided for @errorDetailEnglish.
  ///
  /// In ja, this message translates to:
  /// **'AIの辞書は「アルファベットや基本的な記号」のみに対応しています。\n日本語や全角スペースなどが含まれていると学習できません。'**
  String get errorDetailEnglish;

  /// No description provided for @errorDetailHiragana.
  ///
  /// In ja, this message translates to:
  /// **'AIの辞書は「ひらがな」のみに対応しています。\n漢字やカタカナ、全角スペースなどが含まれていると学習できません。\nすべて「ひらがな」に変換してから入力してください。'**
  String get errorDetailHiragana;

  /// No description provided for @errorUnsupportedCharsDesc.
  ///
  /// In ja, this message translates to:
  /// **'{errorDetail}\n\n【見つかった未対応の文字】\n{foundChars}'**
  String errorUnsupportedCharsDesc(String errorDetail, String foundChars);

  /// No description provided for @msgNotEnoughChars.
  ///
  /// In ja, this message translates to:
  /// **'学習可能な文字が少なすぎます（最低 {requiredCount} 文字必要です）'**
  String msgNotEnoughChars(int requiredCount);

  /// No description provided for @msgDataAddedFromText.
  ///
  /// In ja, this message translates to:
  /// **'文章から {added} 件の学習データを追加しました！'**
  String msgDataAddedFromText(int added);

  /// No description provided for @btnClearAllMemory.
  ///
  /// In ja, this message translates to:
  /// **'記憶を全消去'**
  String get btnClearAllMemory;

  /// No description provided for @warningTitle.
  ///
  /// In ja, this message translates to:
  /// **'警告'**
  String get warningTitle;

  /// No description provided for @clearAllMemoryDesc.
  ///
  /// In ja, this message translates to:
  /// **'抽出したすべての記憶（データ）と入力文章を消去しますか？'**
  String get clearAllMemoryDesc;

  /// No description provided for @btnClear.
  ///
  /// In ja, this message translates to:
  /// **'消去'**
  String get btnClear;

  /// No description provided for @inputPrefix.
  ///
  /// In ja, this message translates to:
  /// **'入力: '**
  String get inputPrefix;

  /// No description provided for @outputPrefix.
  ///
  /// In ja, this message translates to:
  /// **'出力: '**
  String get outputPrefix;

  /// No description provided for @confirmDataDeleteTitle.
  ///
  /// In ja, this message translates to:
  /// **'削除の確認'**
  String get confirmDataDeleteTitle;

  /// No description provided for @confirmDataDeleteDesc.
  ///
  /// In ja, this message translates to:
  /// **'このデータを削除してもよろしいですか？'**
  String get confirmDataDeleteDesc;

  /// No description provided for @btnManualDataInput.
  ///
  /// In ja, this message translates to:
  /// **'データ手入力'**
  String get btnManualDataInput;

  /// No description provided for @msgDataLockedDuringTraining.
  ///
  /// In ja, this message translates to:
  /// **'⚠️ 学習中はデータの編集・追加がロックされます'**
  String get msgDataLockedDuringTraining;

  /// No description provided for @batchDataManagement.
  ///
  /// In ja, this message translates to:
  /// **'一括データ管理 (Excel等と連携)'**
  String get batchDataManagement;

  /// No description provided for @btnPaste.
  ///
  /// In ja, this message translates to:
  /// **'ペースト'**
  String get btnPaste;

  /// No description provided for @btnReadCSV.
  ///
  /// In ja, this message translates to:
  /// **'CSV読込'**
  String get btnReadCSV;

  /// No description provided for @btnCopy.
  ///
  /// In ja, this message translates to:
  /// **'コピー'**
  String get btnCopy;

  /// No description provided for @btnSaveCSV.
  ///
  /// In ja, this message translates to:
  /// **'CSV保存'**
  String get btnSaveCSV;

  /// No description provided for @btnDeleteAll.
  ///
  /// In ja, this message translates to:
  /// **'全消去'**
  String get btnDeleteAll;

  /// No description provided for @deleteAllDataWarningDesc.
  ///
  /// In ja, this message translates to:
  /// **'すべてのデータを消去しますか？'**
  String get deleteAllDataWarningDesc;

  /// No description provided for @noDataDesc.
  ///
  /// In ja, this message translates to:
  /// **'データがありません。\n右下のボタンから手入力するか、\nPCのExcel等からコピーしてペーストしてください。\n\n※列の順序:\n[入力1, 入力2... 出力1, 出力2...]'**
  String get noDataDesc;

  /// No description provided for @editDataTitle.
  ///
  /// In ja, this message translates to:
  /// **'データの編集'**
  String get editDataTitle;

  /// No description provided for @manualDataInputTitle.
  ///
  /// In ja, this message translates to:
  /// **'データの手入力'**
  String get manualDataInputTitle;

  /// No description provided for @inputDataHeader.
  ///
  /// In ja, this message translates to:
  /// **'▼ 入力データ'**
  String get inputDataHeader;

  /// No description provided for @outputDataHeader.
  ///
  /// In ja, this message translates to:
  /// **'▼ 出力データ (正解)'**
  String get outputDataHeader;

  /// No description provided for @btnUpdate.
  ///
  /// In ja, this message translates to:
  /// **'更新'**
  String get btnUpdate;

  /// No description provided for @systemName.
  ///
  /// In ja, this message translates to:
  /// **'システム'**
  String get systemName;

  /// No description provided for @welcomeRoundtable.
  ///
  /// In ja, this message translates to:
  /// **'座談会へようこそ！\n「進む」を押すとAIが順番に話し始めます。\n途中で「発言」から会話に割り込むこともできます。'**
  String get welcomeRoundtable;

  /// No description provided for @errorEmptyBrain.
  ///
  /// In ja, this message translates to:
  /// **'【エラー】{charName} の脳（学習データ）が空です。\n先に「学習」タブで学習を完了させてください。'**
  String errorEmptyBrain(String charName);

  /// No description provided for @errorBrainMismatch.
  ///
  /// In ja, this message translates to:
  /// **'【エラー】{charName} の脳の構造が一致しません。\n「設定」タブで脳をリセットしてください。'**
  String errorBrainMismatch(String charName);

  /// No description provided for @rescueWordsHiragana.
  ///
  /// In ja, this message translates to:
  /// **'えっと、,あのー、,んーっと、,そうですね、,それで、'**
  String get rescueWordsHiragana;

  /// No description provided for @rescueWordsEnglish.
  ///
  /// In ja, this message translates to:
  /// **'Well...,Umm...,Let me see...,So...,Ah,'**
  String get rescueWordsEnglish;

  /// No description provided for @msgInterventionOnlyLanguage.
  ///
  /// In ja, this message translates to:
  /// **'AIが理解できるように「{langName}」のみで入力してください。'**
  String msgInterventionOnlyLanguage(String langName);

  /// No description provided for @userName.
  ///
  /// In ja, this message translates to:
  /// **'あなた'**
  String get userName;

  /// No description provided for @msgNoAiInRoundtable.
  ///
  /// In ja, this message translates to:
  /// **'座談会に参加するAIがいません。\n「キャラ選択」タブでAIを追加してください。'**
  String get msgNoAiInRoundtable;

  /// No description provided for @hintInterveneMessage.
  ///
  /// In ja, this message translates to:
  /// **'メッセージを介入...'**
  String get hintInterveneMessage;

  /// No description provided for @btnNext.
  ///
  /// In ja, this message translates to:
  /// **'進む'**
  String get btnNext;

  /// No description provided for @msgMaxCharacters.
  ///
  /// In ja, this message translates to:
  /// **'参加できるキャラクターは最大4人までです。'**
  String get msgMaxCharacters;

  /// No description provided for @msgLanguageMismatchTitle.
  ///
  /// In ja, this message translates to:
  /// **'座談会の言語が合いません！'**
  String get msgLanguageMismatchTitle;

  /// No description provided for @msgLanguageMismatchDesc.
  ///
  /// In ja, this message translates to:
  /// **'現在は「{currentLang}」のAIが集まっています。「{newLang}」のAIは追加できません。'**
  String msgLanguageMismatchDesc(String currentLang, String newLang);

  /// No description provided for @participatingCharacters.
  ///
  /// In ja, this message translates to:
  /// **'参加キャラクター ({count} / 4人)'**
  String participatingCharacters(int count);

  /// No description provided for @msgEmptyCharacters.
  ///
  /// In ja, this message translates to:
  /// **'下のリストからAIを選んで追加してください。\n※1人目のAIの言語が座談会の公用語になります。'**
  String get msgEmptyCharacters;

  /// No description provided for @selectAiToInvite.
  ///
  /// In ja, this message translates to:
  /// **'▼ 座談会に呼ぶAIを選ぶ'**
  String get selectAiToInvite;

  /// No description provided for @msgNoLlmProjects.
  ///
  /// In ja, this message translates to:
  /// **'テキスト生成モードのAIがありません。\nホーム画面から作成してください。'**
  String get msgNoLlmProjects;

  /// No description provided for @memoryDataCount.
  ///
  /// In ja, this message translates to:
  /// **'記憶データ: {count}件'**
  String memoryDataCount(int count);

  /// No description provided for @freqQuiet.
  ///
  /// In ja, this message translates to:
  /// **'1 (無口 / 聞き手)'**
  String get freqQuiet;

  /// No description provided for @freqReserved.
  ///
  /// In ja, this message translates to:
  /// **'2 (控えめ)'**
  String get freqReserved;

  /// No description provided for @freqNormal.
  ///
  /// In ja, this message translates to:
  /// **'3 (普通)'**
  String get freqNormal;

  /// No description provided for @freqActive.
  ///
  /// In ja, this message translates to:
  /// **'4 (積極的)'**
  String get freqActive;

  /// No description provided for @freqChatty.
  ///
  /// In ja, this message translates to:
  /// **'5 (おしゃべり / 出たがり)'**
  String get freqChatty;

  /// No description provided for @characterNameLabel.
  ///
  /// In ja, this message translates to:
  /// **'キャラクター名'**
  String get characterNameLabel;

  /// No description provided for @nameless.
  ///
  /// In ja, this message translates to:
  /// **'名無し'**
  String get nameless;

  /// No description provided for @themeColor.
  ///
  /// In ja, this message translates to:
  /// **'🎨 テーマカラー'**
  String get themeColor;

  /// No description provided for @temperatureLabel.
  ///
  /// In ja, this message translates to:
  /// **'🧠 ゆらぎ (Temperature): {val}'**
  String temperatureLabel(String val);

  /// No description provided for @temperatureDesc.
  ///
  /// In ja, this message translates to:
  /// **'小さいほど無難な発言、大きいほど突拍子もないカオスな発言になります。'**
  String get temperatureDesc;

  /// No description provided for @frequencyLabel.
  ///
  /// In ja, this message translates to:
  /// **'🗣️ 発言頻度: {label}'**
  String frequencyLabel(String label);

  /// No description provided for @frequencyDesc.
  ///
  /// In ja, this message translates to:
  /// **'座談会が「進む」ときに、このキャラクターが発言権を獲得する確率です。'**
  String get frequencyDesc;

  /// No description provided for @maxLengthLabel.
  ///
  /// In ja, this message translates to:
  /// **'📏 最大発言文字数: {length} 文字'**
  String maxLengthLabel(int length);

  /// No description provided for @maxLengthDesc.
  ///
  /// In ja, this message translates to:
  /// **'1回のターンで話す最大の長さです。（文脈によってはこれより短く終わります）'**
  String get maxLengthDesc;

  /// No description provided for @lockMessage.
  ///
  /// In ja, this message translates to:
  /// **'学習中につき、脳の構造とアルゴリズムの変更はロックされています。（下部の動作設定は変更可能です）'**
  String get lockMessage;

  /// No description provided for @additionalEpochs.
  ///
  /// In ja, this message translates to:
  /// **'追加Epoch: '**
  String get additionalEpochs;

  /// No description provided for @btnResetBrain.
  ///
  /// In ja, this message translates to:
  /// **'脳のリセット'**
  String get btnResetBrain;

  /// No description provided for @btnAnalyzing.
  ///
  /// In ja, this message translates to:
  /// **'分析中...'**
  String get btnAnalyzing;

  /// No description provided for @btnForceStop.
  ///
  /// In ja, this message translates to:
  /// **'強制ストップ'**
  String get btnForceStop;

  /// No description provided for @btnResumeTraining.
  ///
  /// In ja, this message translates to:
  /// **'学習を再開'**
  String get btnResumeTraining;

  /// No description provided for @btnStartTraining.
  ///
  /// In ja, this message translates to:
  /// **'学習開始'**
  String get btnStartTraining;

  /// No description provided for @warnKeepScreen.
  ///
  /// In ja, this message translates to:
  /// **'※画面を維持してください。バックグラウンドにすると学習が止まります。'**
  String get warnKeepScreen;

  /// No description provided for @btnDetailedAnalysis.
  ///
  /// In ja, this message translates to:
  /// **'精度測定 & 詳細分析 (Val)'**
  String get btnDetailedAnalysis;

  /// No description provided for @btnAnalysisPending.
  ///
  /// In ja, this message translates to:
  /// **'学習完了後に測定できます'**
  String get btnAnalysisPending;

  /// No description provided for @accuracyResult.
  ///
  /// In ja, this message translates to:
  /// **'正答率: {rate} %'**
  String accuracyResult(String rate);

  /// No description provided for @analysisComplete.
  ///
  /// In ja, this message translates to:
  /// **'分析完了'**
  String get analysisComplete;

  /// No description provided for @tooltipShowDetailedChart.
  ///
  /// In ja, this message translates to:
  /// **'詳細グラフを表示'**
  String get tooltipShowDetailedChart;

  /// No description provided for @tooltipRemesure.
  ///
  /// In ja, this message translates to:
  /// **'再測定'**
  String get tooltipRemesure;

  /// No description provided for @legendTrainLoss.
  ///
  /// In ja, this message translates to:
  /// **'学習誤差(Train)'**
  String get legendTrainLoss;

  /// No description provided for @legendValLoss.
  ///
  /// In ja, this message translates to:
  /// **'検証誤差(Val)'**
  String get legendValLoss;

  /// No description provided for @terminalTitleHeatmap.
  ///
  /// In ja, this message translates to:
  /// **'Brain Map (Real-time)'**
  String get terminalTitleHeatmap;

  /// No description provided for @terminalTitleLog.
  ///
  /// In ja, this message translates to:
  /// **'Terminal Log'**
  String get terminalTitleLog;

  /// No description provided for @heatmapLegendSuppress.
  ///
  /// In ja, this message translates to:
  /// **'抑制 (-)'**
  String get heatmapLegendSuppress;

  /// No description provided for @heatmapLegendZero.
  ///
  /// In ja, this message translates to:
  /// **'0'**
  String get heatmapLegendZero;

  /// No description provided for @heatmapLegendExcite.
  ///
  /// In ja, this message translates to:
  /// **'興奮 (+)'**
  String get heatmapLegendExcite;

  /// No description provided for @heatmapLegendIntense.
  ///
  /// In ja, this message translates to:
  /// **'強烈'**
  String get heatmapLegendIntense;

  /// No description provided for @heatmapWarnSlow.
  ///
  /// In ja, this message translates to:
  /// **'※リアルタイム描画中は計算速度が低下します。'**
  String get heatmapWarnSlow;

  /// No description provided for @sensitivityTitle.
  ///
  /// In ja, this message translates to:
  /// **'AIの注目ポイント (簡易影響度)'**
  String get sensitivityTitle;

  /// No description provided for @btnRunDetailedAnalysis.
  ///
  /// In ja, this message translates to:
  /// **'詳細な感度分析を実行 (高負荷)'**
  String get btnRunDetailedAnalysis;

  /// No description provided for @sensitivityLlmNote.
  ///
  /// In ja, this message translates to:
  /// **'※「過去文字1」が最も古く、数字が大きいほど直前の文字を表します。'**
  String get sensitivityLlmNote;

  /// No description provided for @permutationImportanceTitle.
  ///
  /// In ja, this message translates to:
  /// **'詳細感度分析 (Permutation Importance)'**
  String get permutationImportanceTitle;

  /// No description provided for @permutationImportanceDesc.
  ///
  /// In ja, this message translates to:
  /// **'各データをランダムにシャッフルした時の「誤差の悪化量」を測定しました。数値が高いほど、AIがそのデータを頼りにしていたことを示します。'**
  String get permutationImportanceDesc;

  /// No description provided for @btnClose.
  ///
  /// In ja, this message translates to:
  /// **'閉じる'**
  String get btnClose;

  /// No description provided for @confusionMatrixTitle.
  ///
  /// In ja, this message translates to:
  /// **'AIの迷い (混同行列)'**
  String get confusionMatrixTitle;

  /// No description provided for @scatterPlotTitle.
  ///
  /// In ja, this message translates to:
  /// **'予測のズレ (散布図)'**
  String get scatterPlotTitle;

  /// No description provided for @confusionMatrixDesc.
  ///
  /// In ja, this message translates to:
  /// **'縦が「正解」、横が「AIの答え」です。\n対角線(左上〜右下)に数字が集まっていれば優秀です。'**
  String get confusionMatrixDesc;

  /// No description provided for @scatterPlotDesc.
  ///
  /// In ja, this message translates to:
  /// **'横が「正解」、縦が「AIの予測」です。\n点が斜めの線に近いほど正確です。'**
  String get scatterPlotDesc;

  /// No description provided for @tapToExpandHint.
  ///
  /// In ja, this message translates to:
  /// **'👇 グラフをタップすると全画面で拡大・操作できます'**
  String get tapToExpandHint;

  /// No description provided for @inputSelectionTitle.
  ///
  /// In ja, this message translates to:
  /// **'入力項目の選択 (実験室)'**
  String get inputSelectionTitle;

  /// No description provided for @inputSelectionDesc.
  ///
  /// In ja, this message translates to:
  /// **'※スイッチをオフにしたデータを「存在しないもの」として学習します。\n特定の項目の重要度を測る実験（アブレーション分析）に使えます。\n【重要】オフにした入力項目がある学習内容は、プロジェクト選択画面に戻るとリセットされます。アプリ再起動時やアップデート時も同様です。'**
  String get inputSelectionDesc;

  /// No description provided for @errorSelectAtLeastOne.
  ///
  /// In ja, this message translates to:
  /// **'少なくとも1つの項目を選択してください'**
  String get errorSelectAtLeastOne;

  /// No description provided for @applyChangesTitle.
  ///
  /// In ja, this message translates to:
  /// **'変更の適用'**
  String get applyChangesTitle;

  /// No description provided for @applyChangesDesc.
  ///
  /// In ja, this message translates to:
  /// **'入力項目の構成を変更し、現在の学習内容をリセットしますか？\n※この操作は元に戻せません。'**
  String get applyChangesDesc;

  /// No description provided for @btnResetAndApply.
  ///
  /// In ja, this message translates to:
  /// **'リセットして適用'**
  String get btnResetAndApply;

  /// No description provided for @msgStructureChanged.
  ///
  /// In ja, this message translates to:
  /// **'入力構成を変更しました。脳をリセットしました。'**
  String get msgStructureChanged;

  /// No description provided for @btnApplyStructureAndReset.
  ///
  /// In ja, this message translates to:
  /// **'設定を適用して脳をリセット'**
  String get btnApplyStructureAndReset;

  /// No description provided for @noBrainDataMessage.
  ///
  /// In ja, this message translates to:
  /// **'No Brain Data\n学習を開始すると脳が生成されます'**
  String get noBrainDataMessage;

  /// No description provided for @chartAxisTrue.
  ///
  /// In ja, this message translates to:
  /// **'縦:正解'**
  String get chartAxisTrue;

  /// No description provided for @chartAxisPred.
  ///
  /// In ja, this message translates to:
  /// **'横:予測'**
  String get chartAxisPred;

  /// No description provided for @detailedChartTitleMatrix.
  ///
  /// In ja, this message translates to:
  /// **'混同行列 (詳細)'**
  String get detailedChartTitleMatrix;

  /// No description provided for @detailedChartTitleScatter.
  ///
  /// In ja, this message translates to:
  /// **'予測散布図 (詳細)'**
  String get detailedChartTitleScatter;

  /// No description provided for @msgTrainFirst.
  ///
  /// In ja, this message translates to:
  /// **'※先に「学習」タブでAIを育ててください'**
  String get msgTrainFirst;

  /// No description provided for @writeAiContinuation.
  ///
  /// In ja, this message translates to:
  /// **'💬 AIに文章の続きを書かせる'**
  String get writeAiContinuation;

  /// No description provided for @hintSeedText.
  ///
  /// In ja, this message translates to:
  /// **'書き出しの文章 ({n}文字以上。例: {exampleText})'**
  String hintSeedText(int n, String exampleText);

  /// No description provided for @hintSeedTextPlaceholder.
  ///
  /// In ja, this message translates to:
  /// **'ここに入力した文章の続きをAIが考えます...'**
  String get hintSeedTextPlaceholder;

  /// No description provided for @temperatureLabelShort.
  ///
  /// In ja, this message translates to:
  /// **'ゆらぎ\n(ランダム性)'**
  String get temperatureLabelShort;

  /// No description provided for @temperatureNote.
  ///
  /// In ja, this message translates to:
  /// **'※ 0.0は無難でループしがち。数値を上げると意外な言葉を選びます。'**
  String get temperatureNote;

  /// No description provided for @btnStop.
  ///
  /// In ja, this message translates to:
  /// **'ストップ'**
  String get btnStop;

  /// No description provided for @btnAutoGenerate.
  ///
  /// In ja, this message translates to:
  /// **'自動生成'**
  String get btnAutoGenerate;

  /// No description provided for @btnStepForward.
  ///
  /// In ja, this message translates to:
  /// **'1文字進む (思考を見る)'**
  String get btnStepForward;

  /// No description provided for @aiThinkingTitle.
  ///
  /// In ja, this message translates to:
  /// **'🧠 AIの思考（入力: 「{input}」）'**
  String aiThinkingTitle(String input);

  /// No description provided for @aiDecision.
  ///
  /// In ja, this message translates to:
  /// **'【判断】'**
  String get aiDecision;

  /// No description provided for @step1Future.
  ///
  /// In ja, this message translates to:
  /// **'Step 1: 「{char}」のあと'**
  String step1Future(String char);

  /// No description provided for @step2Future.
  ///
  /// In ja, this message translates to:
  /// **'Step 2: さらに「{char}」のあと'**
  String step2Future(String char);

  /// No description provided for @generationResultTitle.
  ///
  /// In ja, this message translates to:
  /// **'📝 生成結果'**
  String get generationResultTitle;

  /// No description provided for @tooltipClearResult.
  ///
  /// In ja, this message translates to:
  /// **'結果をクリア'**
  String get tooltipClearResult;

  /// No description provided for @btnCopyAll.
  ///
  /// In ja, this message translates to:
  /// **'全文コピー'**
  String get btnCopyAll;

  /// No description provided for @msgTextCopied.
  ///
  /// In ja, this message translates to:
  /// **'生成されたテキストをコピーしました！'**
  String get msgTextCopied;

  /// No description provided for @msgRequireSeedLength.
  ///
  /// In ja, this message translates to:
  /// **'ヒントとして、{langName}を{n}文字以上入力してください！'**
  String msgRequireSeedLength(String langName, int n);

  /// No description provided for @msgRequireSeedLengthFirst.
  ///
  /// In ja, this message translates to:
  /// **'最初のヒントとして、{langName}を{n}文字以上入力してください！'**
  String msgRequireSeedLengthFirst(String langName, int n);

  /// No description provided for @msgPredictLockedDuringTraining.
  ///
  /// In ja, this message translates to:
  /// **'⚠️ 学習中は推論（テスト）操作がロックされます'**
  String get msgPredictLockedDuringTraining;

  /// No description provided for @btnPredictNormal.
  ///
  /// In ja, this message translates to:
  /// **'推論する (Predict)'**
  String get btnPredictNormal;

  /// No description provided for @predictionResult.
  ///
  /// In ja, this message translates to:
  /// **'{name} の予測値:  {val}'**
  String predictionResult(String name, String val);

  /// No description provided for @judgmentResult.
  ///
  /// In ja, this message translates to:
  /// **'【{name}】の判定:'**
  String judgmentResult(String name);

  /// No description provided for @settingsStructureTitle.
  ///
  /// In ja, this message translates to:
  /// **'🧠 脳の構造とアルゴリズム (変更時リセット)'**
  String get settingsStructureTitle;

  /// No description provided for @nGramCountLabel.
  ///
  /// In ja, this message translates to:
  /// **'推測文字数\n(文脈の長さ)'**
  String get nGramCountLabel;

  /// No description provided for @nGramChars.
  ///
  /// In ja, this message translates to:
  /// **'{count} 文字'**
  String nGramChars(int count);

  /// No description provided for @nGramDesc.
  ///
  /// In ja, this message translates to:
  /// **'※AIが次の文字を予測するために「直前の何文字」を見るかの設定です。増やすと文脈を捉えやすくなりますが、丸暗記（過学習）しやすくなります。\n※変更してリセットすると、保存されている元の文章から学習データを全自動で再抽出します。'**
  String get nGramDesc;

  /// No description provided for @hiddenLayersLabel.
  ///
  /// In ja, this message translates to:
  /// **'隠れ層の数'**
  String get hiddenLayersLabel;

  /// No description provided for @layersCount.
  ///
  /// In ja, this message translates to:
  /// **'{count} 層'**
  String layersCount(int count);

  /// No description provided for @hiddenLayersDesc.
  ///
  /// In ja, this message translates to:
  /// **'※層を深く(3以上)すると複雑な推論が可能になりますが、学習が難しくなります。'**
  String get hiddenLayersDesc;

  /// No description provided for @nodesPerLayerTitle.
  ///
  /// In ja, this message translates to:
  /// **'各層のユニット数 (ディープラーニング構造)'**
  String get nodesPerLayerTitle;

  /// No description provided for @layerLabel.
  ///
  /// In ja, this message translates to:
  /// **'第{index}層'**
  String layerLabel(int index);

  /// No description provided for @layerInputSide.
  ///
  /// In ja, this message translates to:
  /// **'\n(入力側)'**
  String get layerInputSide;

  /// No description provided for @layerOutputSide.
  ///
  /// In ja, this message translates to:
  /// **'\n(出力側)'**
  String get layerOutputSide;

  /// No description provided for @nodesCount.
  ///
  /// In ja, this message translates to:
  /// **'{count} 個'**
  String nodesCount(int count);

  /// No description provided for @warningHeavyStructure.
  ///
  /// In ja, this message translates to:
  /// **'【警告】スマホの限界を超える重い構造です！学習時に画面が完全にフリーズし、アプリが強制終了する危険があります。エコモードを50ms以上に設定することを強く推奨します。'**
  String get warningHeavyStructure;

  /// No description provided for @batchSizeLabel.
  ///
  /// In ja, this message translates to:
  /// **'バッチサイズ'**
  String get batchSizeLabel;

  /// No description provided for @batchSizeCount.
  ///
  /// In ja, this message translates to:
  /// **'{count} 件'**
  String batchSizeCount(int count);

  /// No description provided for @batchSizeDesc.
  ///
  /// In ja, this message translates to:
  /// **'※Adamの場合は少し大きめ(16〜32)にすると学習が安定します。'**
  String get batchSizeDesc;

  /// No description provided for @optimizerLabel.
  ///
  /// In ja, this message translates to:
  /// **'最適化手法'**
  String get optimizerLabel;

  /// No description provided for @optimizerDesc.
  ///
  /// In ja, this message translates to:
  /// **'※SGD(原始的) / Mini-Batch(安定) / Adam(現代の主流・おすすめ)'**
  String get optimizerDesc;

  /// No description provided for @lossFunctionLabel.
  ///
  /// In ja, this message translates to:
  /// **'損失関数'**
  String get lossFunctionLabel;

  /// No description provided for @lossMse.
  ///
  /// In ja, this message translates to:
  /// **'平均二乗誤差 (MSE)'**
  String get lossMse;

  /// No description provided for @lossCrossEntropy.
  ///
  /// In ja, this message translates to:
  /// **'交差エントロピー'**
  String get lossCrossEntropy;

  /// No description provided for @lossDesc.
  ///
  /// In ja, this message translates to:
  /// **'※MSE(数値予測向け・高速) / 交差エントロピー(分類やテキスト生成向け。自動でSoftmaxが適用されますが、計算処理が非常に重くなるためエコモード推奨)'**
  String get lossDesc;

  /// No description provided for @splitMethodTitle.
  ///
  /// In ja, this message translates to:
  /// **'🔀 テスト用データの抽出方法'**
  String get splitMethodTitle;

  /// No description provided for @splitMethodRandom.
  ///
  /// In ja, this message translates to:
  /// **'現在の設定：【ランダムに抽出する】\nデータ全体からランダムに20%を抜き出してテスト（Val）用として使います。一般的なAI開発でおすすめの設定です。\nなお、生成モードの場合には、この設定に関係なく常に100%学習に使います。'**
  String get splitMethodRandom;

  /// No description provided for @splitMethodTail.
  ///
  /// In ja, this message translates to:
  /// **'現在の設定：【末尾から抽出する】\n入力されたリストの後ろから20%をテスト（Val）用として使います。時系列データに有効です。\nなお、生成モードの場合には、この設定に関係なく常に100%学習に使います。'**
  String get splitMethodTail;

  /// No description provided for @confirmResetBrainTitle.
  ///
  /// In ja, this message translates to:
  /// **'脳のリセット確認'**
  String get confirmResetBrainTitle;

  /// No description provided for @confirmResetBrainDesc.
  ///
  /// In ja, this message translates to:
  /// **'構造とアルゴリズムの設定を適用し、AIの脳（重み）と学習履歴を完全にリセットしますか？\n※この操作は元に戻せません。'**
  String get confirmResetBrainDesc;

  /// No description provided for @btnReset.
  ///
  /// In ja, this message translates to:
  /// **'リセット'**
  String get btnReset;

  /// No description provided for @msgResetTextGen.
  ///
  /// In ja, this message translates to:
  /// **'AIの脳を再構築し、元の文章から学習用データを全自動で再抽出しました。'**
  String get msgResetTextGen;

  /// No description provided for @msgResetNormal.
  ///
  /// In ja, this message translates to:
  /// **'AIの脳を再構築し、学習履歴をリセットしました。'**
  String get msgResetNormal;

  /// No description provided for @settingsAppTitle.
  ///
  /// In ja, this message translates to:
  /// **'⚙️ アプリ動作設定 (学習中もいつでも変更可能)'**
  String get settingsAppTitle;

  /// No description provided for @learningRateLabel.
  ///
  /// In ja, this message translates to:
  /// **'学習率\n(歩幅)'**
  String get learningRateLabel;

  /// No description provided for @learningRateDesc.
  ///
  /// In ja, this message translates to:
  /// **'※AIが正解を通り過ぎてしまう（Lossが下がらない）時は小さく、学習が遅い時は大きくします。'**
  String get learningRateDesc;

  /// No description provided for @activationLabel.
  ///
  /// In ja, this message translates to:
  /// **'活性化関数'**
  String get activationLabel;

  /// No description provided for @activationDesc.
  ///
  /// In ja, this message translates to:
  /// **'※Sigmoid(0〜1滑らか) / ReLU(現代主流) / Tanh(-1〜1メリハリ)'**
  String get activationDesc;

  /// No description provided for @ecoModeLabel.
  ///
  /// In ja, this message translates to:
  /// **'エコモード\n(待機時間)'**
  String get ecoModeLabel;

  /// No description provided for @ecoModeDesc.
  ///
  /// In ja, this message translates to:
  /// **'※最小値の『20ms』に近づけるほど高速で学習しますが、スマホが発熱しやすくなります。ご使用の端末に合わせて数値を調整してください。'**
  String get ecoModeDesc;

  /// No description provided for @manualTitle.
  ///
  /// In ja, this message translates to:
  /// **'箱庭小AI 説明書'**
  String get manualTitle;

  /// No description provided for @manualTapHint.
  ///
  /// In ja, this message translates to:
  /// **'緑色の下線がある単語をタップすると、解説が表示されます！'**
  String get manualTapHint;

  /// No description provided for @termEpoch.
  ///
  /// In ja, this message translates to:
  /// **'エポック'**
  String get termEpoch;

  /// No description provided for @termEpochDesc.
  ///
  /// In ja, this message translates to:
  /// **'学習の回数。教科書（全データ）を最初から最後まで1回読み終わることを「1エポック」と呼びます。'**
  String get termEpochDesc;

  /// No description provided for @termLoss.
  ///
  /// In ja, this message translates to:
  /// **'Loss'**
  String get termLoss;

  /// No description provided for @termLossDesc.
  ///
  /// In ja, this message translates to:
  /// **'AIの答えと正解とのズレ（誤差）。これが0に近いほど優秀ですが、0.000にする必要はありません。'**
  String get termLossDesc;

  /// No description provided for @termOverfitting.
  ///
  /// In ja, this message translates to:
  /// **'過学習'**
  String get termOverfitting;

  /// No description provided for @termOverfittingDesc.
  ///
  /// In ja, this message translates to:
  /// **'練習問題を丸暗記してしまい、応用力がなくなった「ガリ勉」状態のこと。'**
  String get termOverfittingDesc;

  /// No description provided for @termOneHot.
  ///
  /// In ja, this message translates to:
  /// **'One-Hot'**
  String get termOneHot;

  /// No description provided for @termOneHotDesc.
  ///
  /// In ja, this message translates to:
  /// **'文字やカテゴリを「0」と「1」のスイッチの並びに変換する手法。'**
  String get termOneHotDesc;

  /// No description provided for @termVanishingGradient.
  ///
  /// In ja, this message translates to:
  /// **'勾配消失'**
  String get termVanishingGradient;

  /// No description provided for @termVanishingGradientDesc.
  ///
  /// In ja, this message translates to:
  /// **'層を深くしすぎると、奥の方まで「反省（修正命令）」が届かなくなる現象。'**
  String get termVanishingGradientDesc;

  /// No description provided for @termRelu.
  ///
  /// In ja, this message translates to:
  /// **'ReLU'**
  String get termRelu;

  /// No description provided for @termReluDesc.
  ///
  /// In ja, this message translates to:
  /// **'マイナスの入力を0にし、プラスはそのまま通す活性化関数。計算が速く学習しやすい。'**
  String get termReluDesc;

  /// No description provided for @termAdam.
  ///
  /// In ja, this message translates to:
  /// **'Adam'**
  String get termAdam;

  /// No description provided for @termAdamDesc.
  ///
  /// In ja, this message translates to:
  /// **'学習率を自動調整してくれる賢い最適化手法。迷ったらコレ。'**
  String get termAdamDesc;

  /// No description provided for @termNGram.
  ///
  /// In ja, this message translates to:
  /// **'Nグラム'**
  String get termNGram;

  /// No description provided for @termNGramDesc.
  ///
  /// In ja, this message translates to:
  /// **'「直前の何文字を見るか」という設定。文脈の長さを決めます。'**
  String get termNGramDesc;

  /// No description provided for @termTemperature.
  ///
  /// In ja, this message translates to:
  /// **'ゆらぎ'**
  String get termTemperature;

  /// No description provided for @termTemperatureDesc.
  ///
  /// In ja, this message translates to:
  /// **'Temperature。AIが次の文字を選ぶ時の「冒険心（ランダム性）」の強さ。'**
  String get termTemperatureDesc;

  /// No description provided for @termWeight.
  ///
  /// In ja, this message translates to:
  /// **'重み'**
  String get termWeight;

  /// No description provided for @termWeightDesc.
  ///
  /// In ja, this message translates to:
  /// **'Weight。入力情報の重要度。AIの記憶そのもの。'**
  String get termWeightDesc;

  /// No description provided for @termBias.
  ///
  /// In ja, this message translates to:
  /// **'バイアス'**
  String get termBias;

  /// No description provided for @termBiasDesc.
  ///
  /// In ja, this message translates to:
  /// **'Bias。ニューロンの発火しやすさ（下駄）。性格のようなもの。'**
  String get termBiasDesc;

  /// No description provided for @termFuturePrediction.
  ///
  /// In ja, this message translates to:
  /// **'未来予知'**
  String get termFuturePrediction;

  /// No description provided for @termFuturePredictionDesc.
  ///
  /// In ja, this message translates to:
  /// **'AIが選んだ文字の、さらにその先を予測する機能。'**
  String get termFuturePredictionDesc;

  /// No description provided for @termSensitivityAnalysis.
  ///
  /// In ja, this message translates to:
  /// **'感度分析'**
  String get termSensitivityAnalysis;

  /// No description provided for @termSensitivityAnalysisDesc.
  ///
  /// In ja, this message translates to:
  /// **'特定の入力情報を遮断して、AIの反応を見る実験手法。アブレーションとも呼ばれます。'**
  String get termSensitivityAnalysisDesc;

  /// No description provided for @termBatchSize.
  ///
  /// In ja, this message translates to:
  /// **'バッチサイズ'**
  String get termBatchSize;

  /// No description provided for @termBatchSizeDesc.
  ///
  /// In ja, this message translates to:
  /// **'まとめて学習するデータの数。1だと毎回反省し、大きいと平均をとってから反省します。'**
  String get termBatchSizeDesc;

  /// No description provided for @ch1Title.
  ///
  /// In ja, this message translates to:
  /// **'遊び方の基本'**
  String get ch1Title;

  /// No description provided for @ch1Intro.
  ///
  /// In ja, this message translates to:
  /// **'このアプリは、スマホの中でAI（人工知能）の頭脳を一から育てることができるシミュレーターです。'**
  String get ch1Intro;

  /// No description provided for @ch1Sec1Title.
  ///
  /// In ja, this message translates to:
  /// **'1. データタブ（教科書づくり）'**
  String get ch1Sec1Title;

  /// No description provided for @ch1Sec1Desc.
  ///
  /// In ja, this message translates to:
  /// **'AIに覚えさせるためのデータを作ります。数値をいじって「この入力の時はこの結果になる」という例題をリストに追加します。'**
  String get ch1Sec1Desc;

  /// No description provided for @ch1Sec2Title.
  ///
  /// In ja, this message translates to:
  /// **'2. 学習タブ（AIの勉強）'**
  String get ch1Sec2Title;

  /// No description provided for @ch1Sec2Desc.
  ///
  /// In ja, this message translates to:
  /// **'「学習開始」を押してAIに勉強させます。エポック数は教科書を何周繰り返し読むかを表します。'**
  String get ch1Sec2Desc;

  /// No description provided for @ch1Sec3Title.
  ///
  /// In ja, this message translates to:
  /// **'3. 推論タブ（テスト）'**
  String get ch1Sec3Title;

  /// No description provided for @ch1Sec3Desc.
  ///
  /// In ja, this message translates to:
  /// **'学習済みのAIのテストを行います。未知の数値を入力し、AIがどんな予測を弾き出すか実験してみましょう。'**
  String get ch1Sec3Desc;

  /// No description provided for @ch1Tip.
  ///
  /// In ja, this message translates to:
  /// **'💡 コツ：数値予測モードでは数十件のデータでも十分ですが、テキスト生成モードでは数百〜数千文字のデータが必要です。AIの成長には時間がかかるので、気長に見守ってあげてください。'**
  String get ch1Tip;

  /// No description provided for @ch2Title.
  ///
  /// In ja, this message translates to:
  /// **'生成AIモードの仕組み'**
  String get ch2Title;

  /// No description provided for @ch2Intro.
  ///
  /// In ja, this message translates to:
  /// **'テキスト生成モードを選ぶと、ChatGPTのような「文章を生み出すAI」の赤ちゃんを作ることができます。'**
  String get ch2Intro;

  /// No description provided for @ch2Sec1Title.
  ///
  /// In ja, this message translates to:
  /// **'予測マシーンとしてのAI'**
  String get ch2Sec1Title;

  /// No description provided for @ch2Sec1Desc.
  ///
  /// In ja, this message translates to:
  /// **'生成AIは、裏側で「『む』『か』『し』と来たら、次は『む』が来る確率が高い」という予測をひたすら繰り返しているだけです。'**
  String get ch2Sec1Desc;

  /// No description provided for @ch2Sec2Title.
  ///
  /// In ja, this message translates to:
  /// **'⚠️ 会話はできません'**
  String get ch2Sec2Title;

  /// No description provided for @ch2Sec2Desc.
  ///
  /// In ja, this message translates to:
  /// **'このAIは「直前の数文字（Nグラム）」しか記憶できない超・健忘症です。意味を理解して会話することはできません。'**
  String get ch2Sec2Desc;

  /// No description provided for @ch2ColumnTitle.
  ///
  /// In ja, this message translates to:
  /// **'【コラム】現代のAIはどれくらい凄いの？'**
  String get ch2ColumnTitle;

  /// No description provided for @ch2ColumnDesc.
  ///
  /// In ja, this message translates to:
  /// **'箱庭小AIのテキスト生成モードは、「数百個のスイッチ（One-Hot）」をカチカチ切り替えて言葉を紡いでいます。\n対して、ChatGPTのような巨大なAIは、このスイッチの数が「数千億〜数兆個」という、想像を絶する規模で構成されています。\n\nスイッチの数が桁違いに多いからこそ、長い文脈を記憶し、人間のような会話ができるのです。しかし、根本的な仕組みは同じです。みなさんのスマホの中で数百個のスイッチが懸命に動く姿は、巨大AIが誕生するまでの「最初の一歩」を再現しているのです。'**
  String get ch2ColumnDesc;

  /// No description provided for @ch2Sec3Title.
  ///
  /// In ja, this message translates to:
  /// **'📉 Lossが1.0から減らない？'**
  String get ch2Sec3Title;

  /// No description provided for @ch2Sec3Desc.
  ///
  /// In ja, this message translates to:
  /// **'バグではありません！最初は超難問に挑んでいるため、Lossはしばらく1.0付近で停滞します。数千エポック以上、気長に待つと突然「覚醒」して下がり始めます。'**
  String get ch2Sec3Desc;

  /// No description provided for @ch3Title.
  ///
  /// In ja, this message translates to:
  /// **'AIの思考を透視する'**
  String get ch3Title;

  /// No description provided for @ch3Intro.
  ///
  /// In ja, this message translates to:
  /// **'Ver 1.3.0では、今までブラックボックスだった「AIの頭の中」を数値とグラフで可視化する、強力な分析機能が搭載されました。'**
  String get ch3Intro;

  /// No description provided for @ch3Sec1Title.
  ///
  /// In ja, this message translates to:
  /// **'🔮 2手先までの未来予知（連鎖）'**
  String get ch3Sec1Title;

  /// No description provided for @ch3Sec1Desc.
  ///
  /// In ja, this message translates to:
  /// **'テキスト生成モードで「1文字進む」ボタンを押すと、AIが次に選ぶ文字だけでなく、「その文字を選んだら、さらに次はどうなるか？」という2手先までの未来予知が表示されます。\n「あ、この文字を選ぶとループしそうだぞ」といったAIの思考の連鎖が手に取るように分かります。'**
  String get ch3Sec1Desc;

  /// No description provided for @ch3Sec2Title.
  ///
  /// In ja, this message translates to:
  /// **'💯 正答率と混同行列（分類のみ）'**
  String get ch3Sec2Title;

  /// No description provided for @ch3Sec2Desc.
  ///
  /// In ja, this message translates to:
  /// **'「文系・理系」のような分類問題では、学習結果の「正答率」が表示されます。\nさらに詳細な「混同行列（Confusion Matrix）」ボタンを押すと、「文系を理系と間違えた回数」などが表形式で分かります。「AIがどのパターンを苦手としているか」を一目で特定できます。'**
  String get ch3Sec2Desc;

  /// No description provided for @ch3Sec3Title.
  ///
  /// In ja, this message translates to:
  /// **'📉 予測のズレ散布図（数値のみ）'**
  String get ch3Sec3Title;

  /// No description provided for @ch3Sec3Desc.
  ///
  /// In ja, this message translates to:
  /// **'「価格・気温」のような数値予測では、AIの予測値と正解データのズレを「散布図」で表示します。\n点が斜めの線上に集まっているほど優秀なAIです。大きく外れている点は、AIにとって「想定外のデータ」だったことを意味します。'**
  String get ch3Sec3Desc;

  /// No description provided for @ch3Sec4Title.
  ///
  /// In ja, this message translates to:
  /// **'📊 重要度分析（Permutation Importance）'**
  String get ch3Sec4Title;

  /// No description provided for @ch3Sec4Desc.
  ///
  /// In ja, this message translates to:
  /// **'AIが「どの入力データを一番頼りにしているか」をランキング形式で表示します。\n入力データを項目ごとにわざとシャッフルしてAIを混乱させ、その時にどれくらい予測精度が落ちるかを測定します。「シャッフルして精度がガタ落ちした＝AIが最も重要視していたデータ」と逆算する、データサイエンスの現場で使われる高度な分析手法です。'**
  String get ch3Sec4Desc;

  /// No description provided for @ch3Sec5Title.
  ///
  /// In ja, this message translates to:
  /// **'🎛️ 感度分析（アブレーション実験）'**
  String get ch3Sec5Title;

  /// No description provided for @ch3Sec5Desc.
  ///
  /// In ja, this message translates to:
  /// **'推論タブや学習画面に「入力スイッチ」が追加されました。\nこれは「ある情報を完全に遮断（OFF）したら、AIはどう判断するか？」をテストする機能です。\n例えば「広さ」のスイッチをOFFにしても家賃予測が変わらなければ、AIは「広さなんて見ていない（無視している）」ことがバレてしまいます。'**
  String get ch3Sec5Desc;

  /// No description provided for @ch4Title.
  ///
  /// In ja, this message translates to:
  /// **'設定全項目リファレンス (上級者向け)'**
  String get ch4Title;

  /// No description provided for @ch4Intro.
  ///
  /// In ja, this message translates to:
  /// **'設定画面にあるすべての項目についての解説です。意味が分からなくなった時の辞書としてお使いください。\n'**
  String get ch4Intro;

  /// No description provided for @ch4Sub1.
  ///
  /// In ja, this message translates to:
  /// **'【AIの構造（脳の形）】'**
  String get ch4Sub1;

  /// No description provided for @ch4Layers.
  ///
  /// In ja, this message translates to:
  /// **'隠れ層の数 (Layers)'**
  String get ch4Layers;

  /// No description provided for @ch4LayersDesc.
  ///
  /// In ja, this message translates to:
  /// **'脳みその会議の回数。多いほど複雑な法則を見つけられますが、学習が難しくなります。'**
  String get ch4LayersDesc;

  /// No description provided for @ch4LayersRec.
  ///
  /// In ja, this message translates to:
  /// **'1〜2層（通常）、2〜3層（生成AI）'**
  String get ch4LayersRec;

  /// No description provided for @ch4Units.
  ///
  /// In ja, this message translates to:
  /// **'ユニット数 (Units)'**
  String get ch4Units;

  /// No description provided for @ch4UnitsDesc.
  ///
  /// In ja, this message translates to:
  /// **'1回の会議に参加するニューロンの数。多いほど細かいニュアンスを表現できます。'**
  String get ch4UnitsDesc;

  /// No description provided for @ch4UnitsRec.
  ///
  /// In ja, this message translates to:
  /// **'10〜20個（通常）、50〜100個（生成AI）'**
  String get ch4UnitsRec;

  /// No description provided for @ch4Activation.
  ///
  /// In ja, this message translates to:
  /// **'活性化関数 (Activation)'**
  String get ch4Activation;

  /// No description provided for @ch4ActivationDesc.
  ///
  /// In ja, this message translates to:
  /// **'ニューロンの情報の伝え方（性格）です。\n・Sigmoid: 0〜1に収める。層が深いと学習しなくなる。\n・ReLU: マイナスは無視、プラスはそのまま。計算が速く優秀。（※本アプリでは「Dying ReLU問題」を防ぎ学習を安定させるため、裏側ではマイナス側にも微小な傾きを持たせた『Leaky ReLU』を採用しています）\n・Tanh: -1〜1に収める。Sigmoidよりメリハリがある。'**
  String get ch4ActivationDesc;

  /// No description provided for @ch4ActivationRec.
  ///
  /// In ja, this message translates to:
  /// **'ReLU（迷ったらコレ）'**
  String get ch4ActivationRec;

  /// No description provided for @ch4Sub2.
  ///
  /// In ja, this message translates to:
  /// **'【学習の方法（勉強法）】'**
  String get ch4Sub2;

  /// No description provided for @ch4Optimizer.
  ///
  /// In ja, this message translates to:
  /// **'最適化手法 (Optimizer)'**
  String get ch4Optimizer;

  /// No description provided for @ch4OptimizerDesc.
  ///
  /// In ja, this message translates to:
  /// **'反省のタイミングと計算方法です。\n・SGD: 一問一答で即反省。グラフが暴れやすい。\n・Mini-batch: 数問まとめてから平均をとって反省。SGDより安定して学習できる。\n・Adam: 過去の傾向を記憶して学習率を自動調整する天才。迷ったらコレ。'**
  String get ch4OptimizerDesc;

  /// No description provided for @ch4OptimizerRec.
  ///
  /// In ja, this message translates to:
  /// **'Adam'**
  String get ch4OptimizerRec;

  /// No description provided for @ch4LR.
  ///
  /// In ja, this message translates to:
  /// **'学習率 (Learning Rate)'**
  String get ch4LR;

  /// No description provided for @ch4LRDesc.
  ///
  /// In ja, this message translates to:
  /// **'1回の失敗からどれくらい大きく考え方を変えるか（歩幅）。\n大きすぎると正解を通り過ぎて発散し、小さすぎるといつまでも終わらない。'**
  String get ch4LRDesc;

  /// No description provided for @ch4LRRec.
  ///
  /// In ja, this message translates to:
  /// **'0.01 〜 0.001（Adamなら自動調整されるので気にしなくてOK）'**
  String get ch4LRRec;

  /// No description provided for @ch4BatchSize.
  ///
  /// In ja, this message translates to:
  /// **'バッチサイズ (Batch Size)'**
  String get ch4BatchSize;

  /// No description provided for @ch4BatchSizeDesc.
  ///
  /// In ja, this message translates to:
  /// **'何問解くごとに反省会を開くか。\n・1: 毎回反省。正確だが遅い。\n・10〜32: まとめて平均をとって反省。計算が速く、安定する。'**
  String get ch4BatchSizeDesc;

  /// No description provided for @ch4BatchSizeRec.
  ///
  /// In ja, this message translates to:
  /// **'データ数の10分の1程度（生成AIなら32〜64）'**
  String get ch4BatchSizeRec;

  /// No description provided for @ch4LossFunc.
  ///
  /// In ja, this message translates to:
  /// **'損失関数 (Loss Function)'**
  String get ch4LossFunc;

  /// No description provided for @ch4LossFuncDesc.
  ///
  /// In ja, this message translates to:
  /// **'間違いの採点方法です。\n・MSE (平均二乗誤差): 数値予測向き。\n・Cross Entropy (交差エントロピー): 分類・生成AI向き。計算は重いが、正解への近道を知っている。'**
  String get ch4LossFuncDesc;

  /// No description provided for @ch4LossFuncRec.
  ///
  /// In ja, this message translates to:
  /// **'数値予測ならMSE、生成AIならCross Entropy'**
  String get ch4LossFuncRec;

  /// No description provided for @ch4Sub3.
  ///
  /// In ja, this message translates to:
  /// **'【データの扱い】'**
  String get ch4Sub3;

  /// No description provided for @ch4ValRatio.
  ///
  /// In ja, this message translates to:
  /// **'テストデータ比率 (Val Ratio)'**
  String get ch4ValRatio;

  /// No description provided for @ch4ValRatioDesc.
  ///
  /// In ja, this message translates to:
  /// **'全データのうち、カンニング防止（テスト用）に隠しておく割合。\n20%に設定すると、残り80%だけで勉強します。'**
  String get ch4ValRatioDesc;

  /// No description provided for @ch4ValRatioRec.
  ///
  /// In ja, this message translates to:
  /// **'20%(このアプリでは固定)'**
  String get ch4ValRatioRec;

  /// No description provided for @ch4SplitMode.
  ///
  /// In ja, this message translates to:
  /// **'抽出モード'**
  String get ch4SplitMode;

  /// No description provided for @ch4SplitModeDesc.
  ///
  /// In ja, this message translates to:
  /// **'テスト用データをどこから選ぶか。\n・ランダム: 全体からバラバラに選ぶ。偏りを防ぐ。\n・末尾抽出: データの最後の方をテストにする。時系列データ（株価や文章の続き）用。'**
  String get ch4SplitModeDesc;

  /// No description provided for @ch4SplitModeRec.
  ///
  /// In ja, this message translates to:
  /// **'基本はランダム、生成AIは末尾'**
  String get ch4SplitModeRec;

  /// No description provided for @ch4EcoMode.
  ///
  /// In ja, this message translates to:
  /// **'エコモード (Eco Mode)'**
  String get ch4EcoMode;

  /// No description provided for @ch4EcoModeDesc.
  ///
  /// In ja, this message translates to:
  /// **'1エポックごとの休憩時間（ミリ秒）。\nスマホの発熱を抑えるためにCPUを休ませます。数値を上げると学習は遅くなりますが、電池持ちが良くなります。'**
  String get ch4EcoModeDesc;

  /// No description provided for @ch4RecommendPrefix.
  ///
  /// In ja, this message translates to:
  /// **'💡 推奨: {text}'**
  String ch4RecommendPrefix(String text);

  /// No description provided for @ch5Title.
  ///
  /// In ja, this message translates to:
  /// **'学習の仕組みと裏側'**
  String get ch5Title;

  /// No description provided for @ch5Sec1Title.
  ///
  /// In ja, this message translates to:
  /// **'📊 TrainとVal（カンニング防止）'**
  String get ch5Sec1Title;

  /// No description provided for @ch5Sec1Desc.
  ///
  /// In ja, this message translates to:
  /// **'青線(Train)が下がっているのにオレンジ線(Val)が上がったら、それは過学習（丸暗記）のサインです。'**
  String get ch5Sec1Desc;

  /// No description provided for @ch5Sec2Title.
  ///
  /// In ja, this message translates to:
  /// **'🎯 Lossは0.000を目指さなくていい'**
  String get ch5Sec2Title;

  /// No description provided for @ch5Sec2Desc.
  ///
  /// In ja, this message translates to:
  /// **'Lossを無理に0にしようとすると「過学習」になります。0.1〜0.05あたりで十分賢い状態です。「腹八分目」がAI育成の鉄則です。'**
  String get ch5Sec2Desc;

  /// No description provided for @ch5Sec3Title.
  ///
  /// In ja, this message translates to:
  /// **'🤔 なぜ答えは「◯◯%」なの？'**
  String get ch5Sec3Title;

  /// No description provided for @ch5Sec3Desc.
  ///
  /// In ja, this message translates to:
  /// **'AIは物事を白黒つけるのが苦手です。「晴れっぽさ0.8、雨っぽさ0.2」という確率（グラデーション）で世界を見ています。'**
  String get ch5Sec3Desc;

  /// No description provided for @ch5Sec4Title.
  ///
  /// In ja, this message translates to:
  /// **'🎲 重み・バイアスと「リセット」'**
  String get ch5Sec4Title;

  /// No description provided for @ch5Sec4Desc.
  ///
  /// In ja, this message translates to:
  /// **'AIの脳内で行われている『脳内会議』を想像してみてください。そこには膨大な数の『計算ボタン（参加者）』がいて、それぞれが個性的な性格を持っています。\n\n【重み（Weight）：情報のえこひいき】\nこれは『誰の意見をどれくらい信用するか』という度合いです。「Aさんの意見は2倍の大きさで聞くけど、Bさんの意見は半分しか聞かない（無視する）」といった具合に、情報に優先順位をつける役割です。\n\n【バイアス（Bias）：元々のノリ】\nこれは、その参加者が『そもそも賛成しやすいか、反対しやすいか』という元々の性格（ゲタ）です。「まだ何も聞いてないのに、最初からなんとなく賛成気味」という楽天家もいれば、頑固な否定派もいます。\n\n━━━━━━━━━━━━━━━━━━━━\n  💡 ここが超重要！\n  学習とは、すべてのボタンの\n  「信頼度（重み）」と「性格（バイアス）」の両方を\n  正解に合わせて、少しずつ微調整していく\n  地道な作業のことを指します。\n━━━━━━━━━━━━━━━━━━━━\n\n【リセットの秘密：運命のダイス】\nリセットボタンを押すと、これら全ての性格がサイコロでランダムに振り直されます。\n実はAIにも「生まれつきの才能（運）」があります。何度勉強してもLossが下がらない時は、たまたま性格の相性が悪かっただけかもしれません。\nそんな時は迷わずリセットして、新しい才能を持ったAIに生まれ変わらせてあげてください！'**
  String get ch5Sec4Desc;

  /// No description provided for @ch5Sec5Title.
  ///
  /// In ja, this message translates to:
  /// **'🔄 One-Hotエンコーディング'**
  String get ch5Sec5Title;

  /// No description provided for @ch5Sec5Desc.
  ///
  /// In ja, this message translates to:
  /// **'AIは計算機なので、文字をそのまま読むことはできません。そこで裏側では、文字を「スイッチの並び」に変換しています。\n\n【名前の由来：1つだけが熱い！】\n例えば「あ・い・う」の3種類がある場合、[1, 0, 0]のように「1つだけを1（ON）にし、他はすべて0（OFF）にする」というルールで表現します。この『1つ（One）だけがON（Hot）』という状態が、名前の由来です。\n\n【脳の入り口が自動で増える！】\nこのアプリで「分類（ドロップダウン）」を選択すると、裏側では選択肢の数だけAIの脳の入り口（神経細胞）が自動的に増設されます。天気予報で『晴れ・曇り・雨』の3つを選んだら、AIの脳には専用の入り口が3つ用意され、該当する場所だけがカチッとONになる仕組みです。'**
  String get ch5Sec5Desc;

  /// No description provided for @ch6Title.
  ///
  /// In ja, this message translates to:
  /// **'アプリの仕様とQ&A'**
  String get ch6Title;

  /// No description provided for @ch6Q1Title.
  ///
  /// In ja, this message translates to:
  /// **'Q. テキスト生成モードでは、なぜデータの100%を学習に使い、検証用のデータを用意しないのですか？'**
  String get ch6Q1Title;

  /// No description provided for @ch6Q1Desc.
  ///
  /// In ja, this message translates to:
  /// **'A. とても小規模なモデルであり、数文字の並びから続きを予測するには、データを「丸暗記」するくらいがちょうど良いためです。\nもし検証用にデータを分けてしまうと、そこに含まれる言葉はAIが学習できず、「教えたはずの言葉をいつまでも話してくれない」ということが起きてしまいます。\nあなたが入力した文章の癖や言い回しを余すことなく吸収させるため、教科書（データ）を隅から隅まで100%使用して学習させています。\n'**
  String get ch6Q1Desc;

  /// No description provided for @ch6Q2Title.
  ///
  /// In ja, this message translates to:
  /// **'Q. データを変えるとリセットされる？'**
  String get ch6Q2Title;

  /// No description provided for @ch6Q2Desc.
  ///
  /// In ja, this message translates to:
  /// **'A. はい。古い知識が邪魔をしないよう、データ構造が変わると脳は初期化されます。'**
  String get ch6Q2Desc;

  /// No description provided for @ch6Q3Title.
  ///
  /// In ja, this message translates to:
  /// **'Q. Excelからの貼り付けやCSVファイルからの読み込みでの見出し行は？'**
  String get ch6Q3Title;

  /// No description provided for @ch6Q3Desc.
  ///
  /// In ja, this message translates to:
  /// **'A. 見出し行があってもなくても大丈夫です。文字だけの行や空欄行は自動で無視されます。'**
  String get ch6Q3Desc;

  /// No description provided for @ch6Q4Title.
  ///
  /// In ja, this message translates to:
  /// **'Q. 読み込まれた件数が、元のデータより少ない気がする'**
  String get ch6Q4Title;

  /// No description provided for @ch6Q4Desc.
  ///
  /// In ja, this message translates to:
  /// **'A. データの途中に「空欄（欠損値）」があったり、「全角数字（１２３）」「カンマ付きの数字（1,000）」「単位（円など）」が含まれている行は、AIが計算エラーを起こすのを防ぐため、自動的にスキップ（無視）される安全設計になっています。数値はすべて半角数字で入力されているか確認してください。\n（※ただし、分類項目に設定している列については、「男性」「女性」といった文字はもちろん、「1」「2」のような数字のカテゴリであっても、数値としてではなく正しく「分類」として認識して読み込みます！）'**
  String get ch6Q4Desc;

  /// No description provided for @ch6Q5Title.
  ///
  /// In ja, this message translates to:
  /// **'Q. 桁が大きい数字はそのまま入力して良いの？'**
  String get ch6Q5Title;

  /// No description provided for @ch6Q5Desc.
  ///
  /// In ja, this message translates to:
  /// **'A. 年収（500万）や年齢（20）のような数字も、あなたが設定した最小値と最大値をもとに内部で自動的に0〜1の範囲に変換（正規化）されるので、そのまま入力してOKです。'**
  String get ch6Q5Desc;

  /// No description provided for @ch6Q6Title.
  ///
  /// In ja, this message translates to:
  /// **'Q. Transformerじゃないの？'**
  String get ch6Q6Title;

  /// No description provided for @ch6Q6Desc.
  ///
  /// In ja, this message translates to:
  /// **'A. 作者の技術力不足です！これは原始的な多層パーセプトロン（MLP）による力技の実装です。'**
  String get ch6Q6Desc;

  /// No description provided for @footerTermsTitle.
  ///
  /// In ja, this message translates to:
  /// **'🎓 ご利用にあたって'**
  String get footerTermsTitle;

  /// No description provided for @footerTermsDesc.
  ///
  /// In ja, this message translates to:
  /// **'このアプリは、どなたでもご自由にお使いいただきたいと考えています。\n学校の授業での活用や、YouTube等での紹介・配信についても、事前の連絡や許可は一切不要です。\n「AIって意外とシンプルで面白いな」と感じてくれる人が一人でも増えれば、作者としてこれほど嬉しいことはありません。'**
  String get footerTermsDesc;

  /// No description provided for @footerPrivacyTitle.
  ///
  /// In ja, this message translates to:
  /// **'🔒 プライバシーポリシー'**
  String get footerPrivacyTitle;

  /// No description provided for @footerPrivacyDesc.
  ///
  /// In ja, this message translates to:
  /// **'Shin Tomura（以下、「開発者」といいます）は、スマートフォン向けアプリ「箱庭小AI」（以下、「本アプリ」といいます）における、ユーザーの個人情報およびプライバシー情報の取り扱いについて、以下の通りプライバシーポリシーを定めます。\n\n1. 個人情報の収集および利用について\n本アプリは完全オフライン（デバイス内完結型）で動作するように設計されています。ユーザーが入力した学習データ、AIの構造、学習結果などのすべてのデータは、ユーザーのスマートフォン端末内にのみ保存されます。\n開発者がこれらの個人情報や入力データを収集、取得、または外部サーバーへ送信することは一切ありません。\n\n2. デバイス機能へのアクセスについて\n本アプリでは、以下の機能を利用するためにデバイスの一部の機能にアクセスしますが、これらのデータが外部に送信されることはありません。\n・クリップボード: データのインポート、および「呪文」のコピー・ペーストを行うために利用します。\n・ファイルアクセス: 学習データのCSVインポート・エクスポート機能を利用する際に、端末内のファイルシステムにアクセスします。\n・写真ライブラリおよび画像ファイル: 画像生成（VAE）モードの学習データとして端末内の画像を選択・読み込むため、および生成した画像を端末に保存・共有するためにアクセスします。読み込まれた画像や生成されたデータはデバイス内でのみ処理され、外部サーバーへ送信されることは一切ありません。\n\n3. 第三者への情報提供\n本アプリはユーザーの個人情報および入力データを一切収集していないため、第三者に対して情報を提供することはありません。また、外部のアナリティクスツールや第三者の広告モジュールは組み込まれていません。\n\n4. 免責事項\n本アプリを利用したことにより生じた、いかなるトラブルや損害についても、開発者は一切の責任を負わないものとします。データのバックアップやアプリの利用は、ユーザーご自身の責任において行ってください。\n\n5. プライバシーポリシーの変更\n開発者は、必要に応じて本ポリシーを変更することがあります。変更後のプライバシーポリシーは、本ページに掲載された時点から効力を生じるものとします。\n\n6. お問い合わせ窓口\n開発者: Shin Tomura\n連絡先: [hakoniwa@ymail.plala.or.jp]\n\n（制定日：2026年3月22日）'**
  String get footerPrivacyDesc;

  /// No description provided for @msgImportSuccess.
  ///
  /// In ja, this message translates to:
  /// **'{count}件のデータをインポートしました！'**
  String msgImportSuccess(int count);

  /// No description provided for @msgImportTruncated.
  ///
  /// In ja, this message translates to:
  /// **'※安全のため10,000件で打ち切りました。'**
  String get msgImportTruncated;

  /// No description provided for @msgNoDataToImport.
  ///
  /// In ja, this message translates to:
  /// **'インポートできるデータが見つかりませんでした。'**
  String get msgNoDataToImport;

  /// No description provided for @msgImportError.
  ///
  /// In ja, this message translates to:
  /// **'エラーが発生しました: {error}'**
  String msgImportError(String error);

  /// No description provided for @msgNoTextInClipboard.
  ///
  /// In ja, this message translates to:
  /// **'クリップボードにテキストがありません。'**
  String get msgNoTextInClipboard;

  /// No description provided for @msgFileTooLarge.
  ///
  /// In ja, this message translates to:
  /// **'ファイルサイズが大きすぎます(上限5MB)。スマホ保護のため中止しました。'**
  String get msgFileTooLarge;

  /// No description provided for @msgFileLoadFailed.
  ///
  /// In ja, this message translates to:
  /// **'ファイルの読み込みに失敗しました。'**
  String get msgFileLoadFailed;

  /// No description provided for @msgDataCopiedToClipboard.
  ///
  /// In ja, this message translates to:
  /// **'データをクリップボードにコピーしました。Excel等に貼り付けられます。'**
  String get msgDataCopiedToClipboard;

  /// No description provided for @msgExportTruncated5000.
  ///
  /// In ja, this message translates to:
  /// **'※安全のため最初の5,000件のみ出力しました。'**
  String get msgExportTruncated5000;

  /// No description provided for @msgCsvExported.
  ///
  /// In ja, this message translates to:
  /// **'CSVファイルを出力しました！'**
  String get msgCsvExported;

  /// No description provided for @msgCsvExportFailed.
  ///
  /// In ja, this message translates to:
  /// **'CSV保存に失敗しました: {error}'**
  String msgCsvExportFailed(String error);

  /// No description provided for @msgShareCsvText.
  ///
  /// In ja, this message translates to:
  /// **'「{name}」の学習データ(CSV)'**
  String msgShareCsvText(String name);

  /// No description provided for @editProjectAndItemNameTitle.
  ///
  /// In ja, this message translates to:
  /// **'プロジェクト・項目名の変更'**
  String get editProjectAndItemNameTitle;

  /// No description provided for @projectNameHeader.
  ///
  /// In ja, this message translates to:
  /// **'プロジェクト名'**
  String get projectNameHeader;

  /// No description provided for @inputItemNamesHeader.
  ///
  /// In ja, this message translates to:
  /// **'▼ 入力項目の名前'**
  String get inputItemNamesHeader;

  /// No description provided for @outputItemNamesHeader.
  ///
  /// In ja, this message translates to:
  /// **'▼ 出力項目の名前'**
  String get outputItemNamesHeader;

  /// No description provided for @inputItemLabelNum.
  ///
  /// In ja, this message translates to:
  /// **'入力 {num}'**
  String inputItemLabelNum(int num);

  /// No description provided for @outputItemLabelNum.
  ///
  /// In ja, this message translates to:
  /// **'出力 {num}'**
  String outputItemLabelNum(int num);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
