// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get btnRoundtable => 'AI Roundtable';

  @override
  String get btnNewProject => 'New Project';

  @override
  String get msgCannotPopDuringTraining =>
      '⚠️ Cannot return home during training. Please stop first.';

  @override
  String get tabData => 'Data';

  @override
  String get tabTrain => 'Train';

  @override
  String get tabPredict => 'Predict';

  @override
  String get tabSettings => 'Settings';

  @override
  String get tabManual => 'Manual';

  @override
  String get msgScreenSaver => 'AI is training...\nTap to wake up';

  @override
  String projectCopyName(String name) {
    return '$name Copy';
  }

  @override
  String get newProjectDefaultName => 'New Project';

  @override
  String get msgStructureChangedResetData =>
      'Structure changed, inherited training data has been reset.';

  @override
  String get addInputTitle => 'Add Input';

  @override
  String get addOutputTitle => 'Add Output';

  @override
  String get itemNameLabel => 'Item Name';

  @override
  String get typeNumericSlider => 'Numeric (Slider)';

  @override
  String get typeCategoryDropdown => 'Category (Dropdown)';

  @override
  String get typeNumericDirect => 'Numeric (Direct)';

  @override
  String get minValueLabel => 'Min Value';

  @override
  String get maxValueLabel => 'Max Value';

  @override
  String get editCategoriesLabel => 'Edit Categories';

  @override
  String get newCategoryHint => 'New Category';

  @override
  String get msgRequireOneCategory => '* Please add at least one category.';

  @override
  String get btnCancel => 'Cancel';

  @override
  String get btnAdd => 'Add';

  @override
  String get unnamedItem => 'Unnamed';

  @override
  String pastChar(int i) {
    return 'Past char $i';
  }

  @override
  String get nextOneChar => 'Next char';

  @override
  String get msgRequireInputOutput =>
      'Please set at least one input and one output item.';

  @override
  String get copyProjectTitle => 'Copy Project';

  @override
  String get createNewProjectTitle => 'Create New';

  @override
  String get projectNameLabel => 'Project Name';

  @override
  String get aiTypeLabel => 'AI Type';

  @override
  String get typeNumericPredict => 'Numeric Predict (Normal)';

  @override
  String get typeTextGeneration => 'Text Generation (LLM)';

  @override
  String get inheritDataLabel => 'Inherit original training data';

  @override
  String get btnAddInput => '+ Add Input';

  @override
  String categoryFormat(String categories) {
    return 'Category ($categories)';
  }

  @override
  String numericFormat(double min, double max) {
    return 'Numeric ($min ~ $max)';
  }

  @override
  String get btnAddOutput => '+ Add Output';

  @override
  String get learningLanguageLabel => 'Learning Language';

  @override
  String get langHiragana => 'Hiragana';

  @override
  String get langEnglish => 'English (Alphabets etc.)';

  @override
  String get descTextGenerationMode =>
      '[Text Generation Mode]\nCreates a Language Model (LLM) that predicts the next character to automatically generate text by reading sentences in the selected language.\n\n* Input/Output configuration is automatically set to \'Recent chars -> Next 1 char\'.';

  @override
  String get btnCreateCopy => 'Create Copy';

  @override
  String get btnCreateProject => 'Create Project';

  @override
  String get groupChatTitle => 'AI Roundtable';

  @override
  String get tabCharSelect => 'Select AI';

  @override
  String get tabCharSettings => 'AI Settings';

  @override
  String get tabChatRun => 'Run Chat';

  @override
  String get confirmDeleteTitle => 'Confirm Deletion';

  @override
  String confirmDeleteMessage(String name) {
    return 'Are you sure you want to delete \'$name\'?\n* This cannot be undone.';
  }

  @override
  String get btnDelete => 'Delete';

  @override
  String get editProjectNameTitle => 'Edit Project Name';

  @override
  String get editProjectNameHint => 'Enter new name';

  @override
  String get btnChange => 'Change';

  @override
  String get appTitle => 'Hakoniwa AI';

  @override
  String get tooltipImport => 'Import Project';

  @override
  String get tooltipEditName => 'Edit Name';

  @override
  String projectInfoSubtitle(
    String version,
    int dataCount,
    int layers,
    String nodesList,
  ) {
    return 'v$version / Data: $dataCount / Layers: $layers Units: [$nodesList]';
  }

  @override
  String get tooltipExport => 'Export / Share';

  @override
  String get tooltipCopy => 'Copy';

  @override
  String get tooltipDelete => 'Delete';

  @override
  String get welcomeTitle => 'Let\'s build an AI!';

  @override
  String get welcomeDesc =>
      'Hakoniwa AI is a simulator that allows you to train an AI brain from scratch right on your smartphone.';

  @override
  String get welcomeStepTitle => '💡 3 Steps to Play';

  @override
  String get welcomeStepDesc =>
      '1. Data: Register examples like \'Math and English scores\'.\n2. Train: Watch the error decrease in the terminal.\n3. Predict: Input unknown numbers and enjoy the AI\'s prediction.';

  @override
  String get btnStartWithSample => 'Start with Samples';

  @override
  String get exportDialogTitle => 'Export Project';

  @override
  String exportDialogDesc(String name) {
    return 'Sharing and saving \'$name\'.';
  }

  @override
  String estimatedDataSize(String size) {
    return 'Estimated Size: $size';
  }

  @override
  String get warningLargeSize =>
      '* \'Spell Copy\' is disabled to prevent your mail or note app from freezing due to large data size. Please use \'Export File\'.';

  @override
  String get btnSpellCopy => 'Copy Spell';

  @override
  String get btnFileOutput => 'Export File';

  @override
  String get msgSpellCopied =>
      'Spell copied to clipboard! Paste it into an email or note.';

  @override
  String get errorDataGenerationFailed => 'Failed to generate compressed data.';

  @override
  String get errorSizeLimitExceeded =>
      'Cannot export because the compressed file size exceeds 5MB.';

  @override
  String shareProjectText(String name) {
    return 'Sharing Hakoniwa AI project \'$name\'!';
  }

  @override
  String shareProjectSubject(String name) {
    return 'Data of $name';
  }

  @override
  String msgFileExported(String name) {
    return 'File for \'$name\' has been exported!';
  }

  @override
  String errorFileExport(String error) {
    return 'File export error: $error';
  }

  @override
  String get versionOldTitle => 'App Version is Old';

  @override
  String versionOldDesc(String version) {
    return 'This project was created with a newer version of Hakoniwa AI (v$version).\n\nPlease update the app to the latest version to summon and run it properly!';
  }

  @override
  String get btnConfirm => 'OK';

  @override
  String get importDialogTitle => 'Import Project';

  @override
  String get importDialogDesc => 'How would you like to import?';

  @override
  String get btnSpellPaste => 'Spell (Paste)';

  @override
  String get btnSelectFile => 'Select File';

  @override
  String get castSpellTitle => 'Cast a Spell';

  @override
  String get castSpellHint => 'Paste the spell (text) here...';

  @override
  String get btnSummon => 'Summon';

  @override
  String get spellSummonSuffix => 'Spell Summon';

  @override
  String get fileSummonSuffix => 'File Summon';

  @override
  String get errorNoDataInFile => 'Project data not found in the file.';

  @override
  String get msgSummonSuccess =>
      'Excellent execution! The project has been summoned.';

  @override
  String get msgSummonFailed =>
      'Summoning failed. The data is corrupted or in an unsupported format.';

  @override
  String readAiTextTitle(String langName) {
    return '📚 Text for AI to read ($langName)';
  }

  @override
  String readAiTextDesc(String hintExample) {
    return 'Paste a sentence like $hintExample here.\n* The AI will automatically extract training data to predict the \'next 1 character\' based on the set number of characters.';
  }

  @override
  String get warningTextEnglish =>
      'Please enter only English alphabets and basic symbols (.,!?\'-).\nJapanese characters and full-width spaces are not supported.';

  @override
  String get warningTextHiragana =>
      'Please enter only Hiragana and punctuation (ー！？).\nBrackets and Kanji are not supported.';

  @override
  String get pasteTextHint => 'Type or paste text...';

  @override
  String currentMemoryDataCount(int count) {
    return 'Current memory data: $count';
  }

  @override
  String get btnAutoGenerateData => 'Auto-generate data from text';

  @override
  String get dataLimitWarningTitle => 'Data Limit Warning';

  @override
  String get dataLimitWarningDesc =>
      'This will exceed the maximum data limit (approx. 15,000 items).\nFor safety, please \'Clear All Memory\' first, or use shorter text.';

  @override
  String get errorUnsupportedCharsTitle =>
      'Error: Unsupported characters included';

  @override
  String get errorDetailEnglish =>
      'The AI dictionary only supports \'Alphabets and basic symbols\'.\nIt cannot learn if Japanese characters or full-width spaces are included.';

  @override
  String get errorDetailHiragana =>
      'The AI dictionary only supports \'Hiragana\'.\nIt cannot learn if Kanji, Katakana, or full-width spaces are included.\nPlease convert everything to \'Hiragana\' before inputting.';

  @override
  String errorUnsupportedCharsDesc(String errorDetail, String foundChars) {
    return '$errorDetail\n\n[Unsupported characters found]\n$foundChars';
  }

  @override
  String msgNotEnoughChars(int requiredCount) {
    return 'Too few characters available for learning (minimum $requiredCount characters required).';
  }

  @override
  String msgDataAddedFromText(int added) {
    return 'Added $added training data items from the text!';
  }

  @override
  String get btnClearAllMemory => 'Clear All Memory';

  @override
  String get warningTitle => 'Warning';

  @override
  String get clearAllMemoryDesc =>
      'Are you sure you want to delete all extracted memory (data) and input text?';

  @override
  String get btnClear => 'Clear';

  @override
  String get inputPrefix => 'IN: ';

  @override
  String get outputPrefix => 'OUT: ';

  @override
  String get confirmDataDeleteTitle => 'Confirm Deletion';

  @override
  String get confirmDataDeleteDesc =>
      'Are you sure you want to delete this data?';

  @override
  String get btnManualDataInput => 'Manual Input';

  @override
  String get msgDataLockedDuringTraining =>
      '⚠️ Data editing/adding is locked during training.';

  @override
  String get batchDataManagement => 'Batch Data Management (Link with Excel)';

  @override
  String get btnPaste => 'Paste';

  @override
  String get btnReadCSV => 'Read CSV';

  @override
  String get btnCopy => 'Copy';

  @override
  String get btnSaveCSV => 'Save CSV';

  @override
  String get btnDeleteAll => 'Delete All';

  @override
  String get deleteAllDataWarningDesc =>
      'Are you sure you want to delete ALL data?';

  @override
  String get noDataDesc =>
      'No data available.\nPlease input manually using the button on the bottom right, or copy and paste from Excel/etc. on your PC.\n\n* Column order:\n[Input 1, Input 2... Output 1, Output 2...]';

  @override
  String get editDataTitle => 'Edit Data';

  @override
  String get manualDataInputTitle => 'Manual Data Input';

  @override
  String get inputDataHeader => '▼ Input Data';

  @override
  String get outputDataHeader => '▼ Output Data (Answer)';

  @override
  String get btnUpdate => 'Update';

  @override
  String get systemName => 'System';

  @override
  String get welcomeRoundtable =>
      'Welcome to the AI Roundtable!\nPress \'Next\' to make the AIs speak in turn.\nYou can also intervene in the conversation by sending a message.';

  @override
  String errorEmptyBrain(String charName) {
    return '[Error] $charName\'s brain (training data) is empty.\nPlease complete training in the \'Train\' tab first.';
  }

  @override
  String errorBrainMismatch(String charName) {
    return '[Error] $charName\'s brain structure does not match.\nPlease reset the brain in the \'Settings\' tab.';
  }

  @override
  String get rescueWordsHiragana => 'Erm...,Um...,Let\'s see...,Well...,So...,';

  @override
  String get rescueWordsEnglish => 'Well...,Umm...,Let me see...,So...,Ah,';

  @override
  String msgInterventionOnlyLanguage(String langName) {
    return 'Please enter only in \'$langName\' so the AI can understand.';
  }

  @override
  String get userName => 'You';

  @override
  String get msgNoAiInRoundtable =>
      'No AI participating in the roundtable.\nPlease add AI from the \'Select AI\' tab.';

  @override
  String get hintInterveneMessage => 'Intervene with a message...';

  @override
  String get btnNext => 'Next';

  @override
  String get msgMaxCharacters => 'A maximum of 4 characters can participate.';

  @override
  String get msgLanguageMismatchTitle => 'Language mismatch!';

  @override
  String msgLanguageMismatchDesc(String currentLang, String newLang) {
    return 'Currently, \'$currentLang\' AIs are gathered. You cannot add a \'$newLang\' AI.';
  }

  @override
  String participatingCharacters(int count) {
    return 'Participants ($count / 4)';
  }

  @override
  String get msgEmptyCharacters =>
      'Select an AI from the list below to add.\n* The first AI\'s language will be the official language of the roundtable.';

  @override
  String get selectAiToInvite => '▼ Select AI to invite';

  @override
  String get msgNoLlmProjects =>
      'No Text Generation AI available.\nPlease create one from the Home screen.';

  @override
  String memoryDataCount(int count) {
    return 'Memory Data: $count';
  }

  @override
  String get freqQuiet => '1 (Quiet / Listener)';

  @override
  String get freqReserved => '2 (Reserved)';

  @override
  String get freqNormal => '3 (Normal)';

  @override
  String get freqActive => '4 (Active)';

  @override
  String get freqChatty => '5 (Chatty / Talkative)';

  @override
  String get characterNameLabel => 'Character Name';

  @override
  String get nameless => 'Nameless';

  @override
  String get themeColor => '🎨 Theme Color';

  @override
  String temperatureLabel(String val) {
    return '🧠 Temperature: $val';
  }

  @override
  String get temperatureDesc =>
      'Lower values make safer responses, higher values make more chaotic and unpredictable ones.';

  @override
  String frequencyLabel(String label) {
    return '🗣️ Frequency: $label';
  }

  @override
  String get frequencyDesc =>
      'The probability of this character getting the right to speak when advancing the roundtable.';

  @override
  String maxLengthLabel(int length) {
    return '📏 Max Length: $length chars';
  }

  @override
  String get maxLengthDesc =>
      'The maximum length of a single utterance. (May end shorter depending on context)';

  @override
  String get lockMessage =>
      'Training in progress. Structural and algorithmic changes are locked. (Settings below can still be changed.)';

  @override
  String get additionalEpochs => 'Add Epochs: ';

  @override
  String get btnResetBrain => 'Reset Brain';

  @override
  String get btnAnalyzing => 'Analyzing...';

  @override
  String get btnForceStop => 'Force Stop';

  @override
  String get btnResumeTraining => 'Resume Training';

  @override
  String get btnStartTraining => 'Start Training';

  @override
  String get warnKeepScreen =>
      '* Please keep the screen active. Training will pause in the background.';

  @override
  String get btnDetailedAnalysis => 'Measure Accuracy & Analyze (Val)';

  @override
  String get btnAnalysisPending => 'Available after training';

  @override
  String accuracyResult(String rate) {
    return 'Accuracy: $rate %';
  }

  @override
  String get analysisComplete => 'Analysis Complete';

  @override
  String get tooltipShowDetailedChart => 'Show detailed chart';

  @override
  String get tooltipRemesure => 'Re-measure';

  @override
  String get legendTrainLoss => 'Train Loss';

  @override
  String get legendValLoss => 'Val Loss';

  @override
  String get terminalTitleHeatmap => 'Brain Map (Real-time)';

  @override
  String get terminalTitleLog => 'Terminal Log';

  @override
  String get heatmapLegendSuppress => 'Suppress (-)';

  @override
  String get heatmapLegendZero => '0';

  @override
  String get heatmapLegendExcite => 'Excite (+)';

  @override
  String get heatmapLegendIntense => 'Intense';

  @override
  String get heatmapWarnSlow =>
      '* Real-time rendering slows down calculation speed.';

  @override
  String get sensitivityTitle => 'AI Focus Points (Simple Impact)';

  @override
  String get btnRunDetailedAnalysis =>
      'Run Detailed Sensitivity Analysis (Heavy)';

  @override
  String get sensitivityLlmNote =>
      '* \'Past char 1\' is the oldest, larger numbers mean more recent characters.';

  @override
  String get permutationImportanceTitle =>
      'Detailed Sensitivity (Permutation Importance)';

  @override
  String get permutationImportanceDesc =>
      'Measured \'error deterioration\' when each data column is randomly shuffled. Higher values mean the AI relied heavily on that data.';

  @override
  String get btnClose => 'Close';

  @override
  String get confusionMatrixTitle => 'AI Confusion (Matrix)';

  @override
  String get scatterPlotTitle => 'Prediction Deviation (Scatter)';

  @override
  String get confusionMatrixDesc =>
      'Vertical is \'True\', Horizontal is \'Predicted\'.\nIt is excellent if numbers gather on the diagonal (top-left to bottom-right).';

  @override
  String get scatterPlotDesc =>
      'Horizontal is \'True\', Vertical is \'Predicted\'.\nThe closer the dots are to the diagonal line, the more accurate.';

  @override
  String get tapToExpandHint =>
      '👇 Tap the chart to expand and interact in full screen.';

  @override
  String get inputSelectionTitle => 'Input Selection (Lab)';

  @override
  String get inputSelectionDesc =>
      '* Data with switch turned off will be learned as \'non-existent\'.\nUse for ablation studies to measure the importance of specific features.\n[IMPORTANT] Training progress with disabled inputs will be reset when returning to the Home screen, restarting, or updating the app.';

  @override
  String get errorSelectAtLeastOne => 'Please select at least one item.';

  @override
  String get applyChangesTitle => 'Apply Changes';

  @override
  String get applyChangesDesc =>
      'Change the input configuration and reset the current training data?\n* This cannot be undone.';

  @override
  String get btnResetAndApply => 'Reset and Apply';

  @override
  String get msgStructureChanged =>
      'Input configuration changed. Brain has been reset.';

  @override
  String get btnApplyStructureAndReset => 'Apply settings and reset brain';

  @override
  String get noBrainDataMessage =>
      'No Brain Data\nBrain will be generated when training starts.';

  @override
  String get chartAxisTrue => 'V: True';

  @override
  String get chartAxisPred => 'H: Pred';

  @override
  String get detailedChartTitleMatrix => 'Confusion Matrix (Details)';

  @override
  String get detailedChartTitleScatter => 'Scatter Plot (Details)';

  @override
  String get msgTrainFirst =>
      '* Please train the AI in the \'Train\' tab first.';

  @override
  String get writeAiContinuation => '💬 Let AI write the continuation';

  @override
  String hintSeedText(int n, String exampleText) {
    return 'Starting text (At least $n chars. e.g., $exampleText)';
  }

  @override
  String get hintSeedTextPlaceholder =>
      'The AI will think of the continuation of the text entered here...';

  @override
  String get temperatureLabelShort => 'Temp\n(Randomness)';

  @override
  String get temperatureNote =>
      '* 0.0 is safe but prone to loops. Higher values choose unexpected words.';

  @override
  String get btnStop => 'Stop';

  @override
  String get btnAutoGenerate => 'Auto Generate';

  @override
  String get btnStepForward => 'Step 1 Char (See thoughts)';

  @override
  String aiThinkingTitle(String input) {
    return '🧠 AI\'s Thoughts (Input: \'$input\')';
  }

  @override
  String get aiDecision => '[Decision]';

  @override
  String step1Future(String char) {
    return 'Step 1: After \'$char\'';
  }

  @override
  String step2Future(String char) {
    return 'Step 2: Then after \'$char\'';
  }

  @override
  String get generationResultTitle => '📝 Generated Result';

  @override
  String get tooltipClearResult => 'Clear result';

  @override
  String get btnCopyAll => 'Copy All';

  @override
  String get msgTextCopied => 'Generated text copied to clipboard!';

  @override
  String msgRequireSeedLength(String langName, int n) {
    return 'Please enter at least $n chars in \'$langName\' as a hint!';
  }

  @override
  String msgRequireSeedLengthFirst(String langName, int n) {
    return 'Please enter at least $n chars in \'$langName\' as the first hint!';
  }

  @override
  String get msgPredictLockedDuringTraining =>
      '⚠️ Prediction (Test) operations are locked during training.';

  @override
  String get btnPredictNormal => 'Predict';

  @override
  String predictionResult(String name, String val) {
    return 'Prediction for $name: $val';
  }

  @override
  String judgmentResult(String name) {
    return 'Judgment for [$name]:';
  }

  @override
  String get settingsStructureTitle =>
      '🧠 Structure & Algorithm (Requires Reset)';

  @override
  String get nGramCountLabel => 'N-Gram\n(Context Len)';

  @override
  String nGramChars(int count) {
    return '$count chars';
  }

  @override
  String get nGramDesc =>
      '* Determines how many \'past characters\' the AI looks at to predict the next one. A larger value captures more context but increases the risk of rote memorization (overfitting).\n* If you apply and reset, training data will be automatically re-extracted from the saved text.';

  @override
  String get hiddenLayersLabel => 'Hidden Layers';

  @override
  String layersCount(int count) {
    return '$count layers';
  }

  @override
  String get hiddenLayersDesc =>
      '* Deeper layers (3+) enable complex reasoning but make training more difficult.';

  @override
  String get nodesPerLayerTitle => 'Units per Layer (Deep Learning Structure)';

  @override
  String layerLabel(int index) {
    return 'Layer $index';
  }

  @override
  String get layerInputSide => '\n(Input Side)';

  @override
  String get layerOutputSide => '\n(Output Side)';

  @override
  String nodesCount(int count) {
    return '$count units';
  }

  @override
  String get warningHeavyStructure =>
      '[WARNING] Heavy structure exceeding smartphone limits! The app may freeze or crash during training. It is strongly recommended to set Eco Mode to 50ms or higher.';

  @override
  String get batchSizeLabel => 'Batch Size';

  @override
  String batchSizeCount(int count) {
    return '$count items';
  }

  @override
  String get batchSizeDesc =>
      '* When using Adam, a slightly larger value (16-32) stabilizes training.';

  @override
  String get optimizerLabel => 'Optimizer';

  @override
  String get optimizerDesc =>
      '* SGD (Primitive) / Mini-Batch (Stable) / Adam (Modern standard, Recommended)';

  @override
  String get lossFunctionLabel => 'Loss Function';

  @override
  String get lossMse => 'Mean Squared Error (MSE)';

  @override
  String get lossCrossEntropy => 'Cross Entropy';

  @override
  String get lossDesc =>
      '* MSE (For numeric prediction, Fast) / Cross Entropy (For classification/text generation. Softmax is applied automatically, but it requires heavy calculation. Eco Mode recommended).';

  @override
  String get splitMethodTitle => '🔀 Validation Data Extraction';

  @override
  String get splitMethodRandom =>
      'Current: [Extract Randomly]\nRandomly extracts 20% of all data for validation (Val). Recommended for general AI development.\nNote: In Generation mode, 100% of data is always used for training regardless of this setting.';

  @override
  String get splitMethodTail =>
      'Current: [Extract from Tail]\nUses the last 20% of the inputted list for validation (Val). Effective for time-series data.\nNote: In Generation mode, 100% of data is always used for training regardless of this setting.';

  @override
  String get confirmResetBrainTitle => 'Confirm Brain Reset';

  @override
  String get confirmResetBrainDesc =>
      'Apply structure and algorithm settings, and completely reset the AI\'s brain (weights) and training history?\n* This action cannot be undone.';

  @override
  String get btnReset => 'Reset';

  @override
  String get msgResetTextGen =>
      'Rebuilt AI brain and automatically re-extracted training data from the original text.';

  @override
  String get msgResetNormal => 'Rebuilt AI brain and reset training history.';

  @override
  String get settingsAppTitle => '⚙️ App Operation Settings (Change anytime)';

  @override
  String get learningRateLabel => 'Learning Rate\n(Step Size)';

  @override
  String get learningRateDesc =>
      '* Decrease if AI overshoots the answer (Loss doesn\'t drop), increase if learning is too slow.';

  @override
  String get activationLabel => 'Activation';

  @override
  String get activationDesc =>
      '* Sigmoid (0 to 1 smooth) / ReLU (Modern standard) / Tanh (-1 to 1 sharp)';

  @override
  String get ecoModeLabel => 'Eco Mode\n(Wait Time)';

  @override
  String get ecoModeDesc =>
      '* Closer to the minimum \'20ms\' trains faster but makes the phone heat up easily. Adjust according to your device.';

  @override
  String get manualTitle => 'Hakoniwa AI Manual';

  @override
  String get manualTapHint =>
      'Tap words with green underlines to see explanations!';

  @override
  String get termEpoch => 'Epoch';

  @override
  String get termEpochDesc =>
      'The number of training cycles. Reading the textbook (all data) from start to finish once is called \'1 Epoch\'.';

  @override
  String get termLoss => 'Loss';

  @override
  String get termLossDesc =>
      'The deviation (error) between the AI\'s answer and the correct answer. Closer to 0 is better, but it doesn\'t need to be 0.000.';

  @override
  String get termOverfitting => 'Overfitting';

  @override
  String get termOverfittingDesc =>
      'A state where the AI has memorized the practice problems but lost the ability to apply it to new ones.';

  @override
  String get termOneHot => 'One-Hot';

  @override
  String get termOneHotDesc =>
      'A technique to convert characters or categories into an array of \'0\' and \'1\' switches.';

  @override
  String get termVanishingGradient => 'Vanishing Gradient';

  @override
  String get termVanishingGradientDesc =>
      'A phenomenon where \'reflection (correction commands)\' fail to reach the deeper layers when there are too many layers.';

  @override
  String get termRelu => 'ReLU';

  @override
  String get termReluDesc =>
      'An activation function that turns negative inputs to 0 and passes positives as is. Fast and easy to train.';

  @override
  String get termAdam => 'Adam';

  @override
  String get termAdamDesc =>
      'A smart optimization method that automatically adjusts the learning rate. When in doubt, choose this.';

  @override
  String get termNGram => 'N-Gram';

  @override
  String get termNGramDesc =>
      'A setting for \'how many previous characters to look at\'. Determines context length.';

  @override
  String get termTemperature => 'Temperature';

  @override
  String get termTemperatureDesc =>
      'Temperature. The strength of the AI\'s \'adventurousness (randomness)\' when choosing the next character.';

  @override
  String get termWeight => 'Weight';

  @override
  String get termWeightDesc =>
      'Weight. The importance of input information. The AI\'s memory itself.';

  @override
  String get termBias => 'Bias';

  @override
  String get termBiasDesc =>
      'Bias. How easily a neuron fires. Like a personality trait.';

  @override
  String get termFuturePrediction => 'Future Prediction';

  @override
  String get termFuturePredictionDesc =>
      'A feature that predicts what comes after the character the AI has chosen.';

  @override
  String get termSensitivityAnalysis => 'Sensitivity Analysis';

  @override
  String get termSensitivityAnalysisDesc =>
      'An experimental method that blocks specific input information to see the AI\'s reaction. Also known as ablation.';

  @override
  String get termBatchSize => 'Batch Size';

  @override
  String get termBatchSizeDesc =>
      'The number of data items trained together. 1 reflects every time, larger sizes take the average before reflecting.';

  @override
  String get ch1Title => ' Basic Ways to Play';

  @override
  String get ch1Intro =>
      'This app is a simulator that lets you train an AI (Artificial Intelligence) brain from scratch on your smartphone.';

  @override
  String get ch1Sec1Title => '1. Data Tab (Making Textbooks)';

  @override
  String get ch1Sec1Desc =>
      'Create data for the AI to learn. Adjust values and add examples like \'this input gives this result\' to the list.';

  @override
  String get ch1Sec2Title => '2. Train Tab (AI Studying)';

  @override
  String get ch1Sec2Desc =>
      'Press \'Start Training\' to make the AI study. Epochs represent how many times it reads through the textbook.';

  @override
  String get ch1Sec3Title => '3. Predict Tab (Testing)';

  @override
  String get ch1Sec3Desc =>
      'Test the trained AI. Input unknown values and experiment to see what prediction the AI outputs.';

  @override
  String get ch1Tip =>
      '💡 Tip: Tens of data points are enough for numeric prediction, but Text Generation needs hundreds to thousands of characters. AI growth takes time, so please watch over it patiently.';

  @override
  String get ch2Title => ' Text Generation Mode';

  @override
  String get ch2Intro =>
      'By selecting Text Generation Mode, you can create a baby \'Text Generating AI\' similar to ChatGPT.';

  @override
  String get ch2Sec1Title => 'AI as a Prediction Machine';

  @override
  String get ch2Sec1Desc =>
      'Behind the scenes, generative AI simply repeats predictions like \'If it\'s [O][n][c], the next letter is likely [e]\'.';

  @override
  String get ch2Sec2Title => '⚠️ Cannot Converse';

  @override
  String get ch2Sec2Desc =>
      'This AI is extremely forgetful and only remembers the \'previous few characters (N-Gram)\'. It cannot understand meaning or hold a conversation.';

  @override
  String get ch2ColumnTitle => '[Column] How amazing are modern AIs?';

  @override
  String get ch2ColumnDesc =>
      'Hakoniwa AI\'s text generation mode spins words by switching a few hundred \'One-Hot\' switches.\nIn contrast, massive AIs like ChatGPT consist of \'hundreds of billions to trillions\' of switches.\n\nBecause the number of switches is magnitudes larger, they can remember long contexts and converse like humans. However, the fundamental mechanism is the same. The sight of hundreds of switches working hard inside your phone recreates the \'first steps\' towards the birth of massive AIs.';

  @override
  String get ch2Sec3Title => '📉 Loss stuck at 1.0?';

  @override
  String get ch2Sec3Desc =>
      'It\'s not a bug! Since it\'s tackling an extremely difficult problem initially, the Loss will stall around 1.0 for a while. If you wait patiently for thousands of Epochs, it will suddenly \'awaken\' and start dropping.';

  @override
  String get ch3Title => ' X-Raying AI\'s Thoughts';

  @override
  String get ch3Intro =>
      'In Ver 1.3.0, powerful analysis features have been added to visualize the \'AI\'s brain\', which was previously a black box, using numbers and graphs.';

  @override
  String get ch3Sec1Title => '🔮 Future Prediction up to 2 steps (Chain)';

  @override
  String get ch3Sec1Desc =>
      'Pressing \'Step 1 Char\' in Text Generation Mode shows not only the next character the AI picks, but also Future Predictions up to 2 steps ahead: \'What happens next if it picks this?\'.\nYou can clearly see the AI\'s thought chain, like \'Ah, picking this char might cause a loop\'.';

  @override
  String get ch3Sec2Title =>
      '💯 Accuracy & Confusion Matrix (Classification only)';

  @override
  String get ch3Sec2Desc =>
      'For classification problems like \'Humanities/Sciences\', \'Accuracy\' is displayed.\nClicking the detailed \'Confusion Matrix\' button shows a table of things like \'how many times Humanities was mistaken for Sciences\'. You can identify which patterns the AI struggles with at a glance.';

  @override
  String get ch3Sec3Title =>
      '📉 Prediction Deviation Scatter Plot (Numeric only)';

  @override
  String get ch3Sec3Desc =>
      'For numeric predictions like \'Price/Temp\', a \'Scatter Plot\' shows the deviation between AI predictions and correct data.\nThe closer dots gather on the diagonal line, the better the AI. Points far off mean it was \'unexpected data\' for the AI.';

  @override
  String get ch3Sec4Title => '📊 Permutation Importance';

  @override
  String get ch3Sec4Desc =>
      'Shows a ranking of \'which input data the AI relies on most\'.\nIt intentionally shuffles input data by column to confuse the AI and measures how much accuracy drops. \'Accuracy dropped drastically when shuffled = highly valued data by AI\'. A highly advanced method used in data science.';

  @override
  String get ch3Sec5Title => '🎛️ Sensitivity Analysis (Ablation)';

  @override
  String get ch3Sec5Desc =>
      'An \'Input Switch\' was added to the Predict and Train tabs.\nThis tests \'How does the AI judge if certain info is completely blocked (OFF)?\'.\nFor example, if turning OFF the \'Area\' switch doesn\'t change rent prediction, it proves the AI \'wasn\'t even looking at the area (ignoring it)\'.';

  @override
  String get ch4Title => ' Settings Reference (Advanced)';

  @override
  String get ch4Intro =>
      'Explanations for all items on the Settings screen. Use this as a dictionary when you don\'t understand something.\n';

  @override
  String get ch4Sub1 => '[AI Structure (Brain Shape)]';

  @override
  String get ch4Layers => 'Hidden Layers';

  @override
  String get ch4LayersDesc =>
      'Number of brain conferences. More layers find complex rules but make training harder.';

  @override
  String get ch4LayersRec => '1-2 layers (Normal), 2-3 layers (Text Gen)';

  @override
  String get ch4Units => 'Units';

  @override
  String get ch4UnitsDesc =>
      'Number of neurons in a conference. More units can express finer nuances.';

  @override
  String get ch4UnitsRec => '10-20 units (Normal), 50-100 units (Text Gen)';

  @override
  String get ch4Activation => 'Activation Function';

  @override
  String get ch4ActivationDesc =>
      'How neurons transmit info (personality).\n- Sigmoid: Bounds to 0~1. Fails to learn in deep layers.\n- ReLU: Ignores negatives, passes positives. Fast and excellent.(Note: Under the hood, this app implements \'Leaky ReLU\' with a small negative slope to prevent the \'Dying ReLU\' problem and ensure stable training in a sandbox environment.)\n- Tanh: Bounds to -1~1. Sharper than Sigmoid.';

  @override
  String get ch4ActivationRec => 'ReLU (When in doubt)';

  @override
  String get ch4Sub2 => '[Learning Method]';

  @override
  String get ch4Optimizer => 'Optimizer';

  @override
  String get ch4OptimizerDesc =>
      'Timing and method of reflection.\n- SGD: Reflects immediately per question. Graph is volatile.\n- Mini-batch: Averages a few questions before reflecting. More stable.\n- Adam: A genius that remembers past trends and auto-adjusts learning rate. Recommended.';

  @override
  String get ch4OptimizerRec => 'Adam';

  @override
  String get ch4LR => 'Learning Rate';

  @override
  String get ch4LRDesc =>
      'How much to change thinking from one failure (step size).\nToo large overshoots the answer, too small never finishes.';

  @override
  String get ch4LRRec =>
      '0.01 - 0.001 (Adam auto-adjusts, so don\'t worry much)';

  @override
  String get ch4BatchSize => 'Batch Size';

  @override
  String get ch4BatchSizeDesc =>
      'How many questions to solve before holding a reflection meeting.\n- 1: Reflect every time. Accurate but slow.\n- 10~32: Average and reflect. Fast and stable.';

  @override
  String get ch4BatchSizeRec => 'About 1/10 of data count (32-64 for Text Gen)';

  @override
  String get ch4LossFunc => 'Loss Function';

  @override
  String get ch4LossFuncDesc =>
      'How mistakes are scored.\n- MSE: For numeric prediction.\n- Cross Entropy: For classification/Text Gen. Heavy computation, but knows the shortcut to the answer.';

  @override
  String get ch4LossFuncRec => 'MSE for numeric, Cross Entropy for Text Gen';

  @override
  String get ch4Sub3 => '[Data Handling]';

  @override
  String get ch4ValRatio => 'Val Ratio';

  @override
  String get ch4ValRatioDesc =>
      'Percentage of data hidden for anti-cheat testing.\nSet to 20%, it only studies with the remaining 80%.';

  @override
  String get ch4ValRatioRec => '20% (Fixed in this app)';

  @override
  String get ch4SplitMode => 'Split Mode';

  @override
  String get ch4SplitModeDesc =>
      'Where to pick test data from.\n- Random: Pick scattered from all data. Prevents bias.\n- Tail: Use the end of the data. For time-series (stocks, text continuation).';

  @override
  String get ch4SplitModeRec => 'Basically Random, Tail for Text Gen';

  @override
  String get ch4EcoMode => 'Eco Mode';

  @override
  String get ch4EcoModeDesc =>
      'Rest time per epoch (ms).\nRests the CPU to reduce phone heating. Higher values slow down training but save battery.';

  @override
  String ch4RecommendPrefix(String text) {
    return '💡 Recommended: $text';
  }

  @override
  String get ch5Title => ' How Training Works';

  @override
  String get ch5Sec1Title => '📊 Train & Val (Anti-Cheat)';

  @override
  String get ch5Sec1Desc =>
      'If the blue line (Train) goes down but the orange line (Val) goes up, it\'s a sign of Overfitting (rote memorization).';

  @override
  String get ch5Sec2Title => '🎯 Loss doesn\'t need to be 0.000';

  @override
  String get ch5Sec2Desc =>
      'Forcing Loss to 0 leads to \'Overfitting\'. Around 0.1-0.05 is smart enough. \'Stopping at 80% full\' is the golden rule of AI training.';

  @override
  String get ch5Sec3Title => '🤔 Why are answers \'XX%\'?';

  @override
  String get ch5Sec3Desc =>
      'AI is bad at black-and-white decisions. It sees the world in probabilities (gradients) like \'80% Sunny, 20% Rainy\'.';

  @override
  String get ch5Sec4Title => '🎲 Weights, Biases & \'Reset\'';

  @override
  String get ch5Sec4Desc =>
      'Imagine an \'inner brain conference\' in the AI. There are massive numbers of \'calculators (participants)\' with unique personalities.\n\n[Weight: Information Favoritism]\nThis is \'how much to trust whose opinion\'. It prioritizes info like \'listen to A twice as much, but ignore B by half\'.\n\n[Bias: Default Vibe]\nThis is whether the participant \'tends to agree or disagree by default\'. Some are optimists \'leaning towards agree before hearing anything\', while others are stubborn deniers.\n\n━━━━━━━━━━━━━━━━━━━━\n  💡 VERY IMPORTANT!\n  \'Training\' is the steady process\n  of finely adjusting both the\n  \'Trust (Weight)\' and \'Personality (Bias)\'\n  of all buttons to match the correct answer.\n━━━━━━━━━━━━━━━━━━━━\n\n[Secret of Reset: Dice of Fate]\nPressing Reset rerolls all these personalities randomly with dice.\nActually, AI has \'innate talent (luck)\'. If Loss won\'t drop after many studies, their personalities might just be incompatible.\nIn such cases, don\'t hesitate to reset and reincarnate the AI with new talent!';

  @override
  String get ch5Sec5Title => '🔄 One-Hot Encoding';

  @override
  String get ch5Sec5Desc =>
      'Since AI is a calculator, it can\'t read letters directly. So behind the scenes, letters are converted into \'an array of switches\'.\n\n[Origin of Name: Only One is Hot!]\nFor example, with 3 types \'A, B, C\', it\'s expressed as [1, 0, 0] where \'only one is 1 (ON), rest are 0 (OFF)\'. \'Only One is Hot (ON)\' is where the name comes from.\n\n[Brain Entrances Auto-Expand!]\nIf you select \'Category\' in this app, entrances (neurons) to the AI brain are automatically added for each option. Pick \'Sunny, Cloudy, Rainy\', and 3 entrances are created, with only the relevant one clicking ON.';

  @override
  String get ch6Title => ' App Specs & Q&A';

  @override
  String get ch6Q1Title =>
      'Q. In Text Gen mode, why use 100% of data for training and none for validation?';

  @override
  String get ch6Q1Desc =>
      'A. It\'s a very small model, and to predict continuations from a few characters, \'rote memorization\' is just about right.\nIf validation data is separated, the AI can\'t learn words within it, causing it to \'never speak words you thought you taught\'.\nTo absorb your text\'s quirks completely, it uses 100% of the textbook (data) from corner to corner for training.\n';

  @override
  String get ch6Q2Title => 'Q. Does changing data reset everything?';

  @override
  String get ch6Q2Desc =>
      'A. Yes. To prevent old knowledge from interfering, the brain resets when data structure changes.';

  @override
  String get ch6Q3Title =>
      'Q. What about header rows when pasting from Excel or reading CSV?';

  @override
  String get ch6Q3Desc =>
      'A. It\'s fine with or without header rows. Text-only rows or empty rows are automatically ignored.';

  @override
  String get ch6Q4Title =>
      'Q. The imported count seems less than the original data';

  @override
  String get ch6Q4Desc =>
      'A. For safety, rows with \'blanks\', \'full-width numbers\', \'comma-separated numbers (1,000)\', or \'units (\$)\' are automatically skipped to prevent calculation errors. Ensure all numbers are half-width.\n(* However, for columns set as \'Category\', both text like \'Male\'/\'Female\' and numeric categories like \'1\'/\'2\' are correctly read as \'categories\', not numbers!)';

  @override
  String get ch6Q5Title => 'Q. Can I input large numbers as is?';

  @override
  String get ch6Q5Desc =>
      'A. Yes. Numbers like Income (50k) or Age (20) are automatically converted (normalized) to a 0-1 range internally based on the Min/Max values you set, so just input them as is.';

  @override
  String get ch6Q6Title => 'Q. Isn\'t this a Transformer?';

  @override
  String get ch6Q6Desc =>
      'A. Lack of developer skill! This is a brute-force implementation using a primitive Multi-Layer Perceptron (MLP).';

  @override
  String get footerTermsTitle => '🎓 Terms of Use';

  @override
  String get footerTermsDesc =>
      'We want anyone to feel free to use this app.\nNo prior contact or permission is required for use in school classes, or introductions/streaming on YouTube, etc.\nNothing would make the developer happier than if even one more person feels \'AI is surprisingly simple and fun\'.';

  @override
  String get footerPrivacyTitle => '🔒 Privacy Policy';

  @override
  String get footerPrivacyDesc =>
      'Shin Tomura (hereinafter \'Developer\') establishes the following privacy policy regarding the handling of users\' personal and privacy information in the smartphone app \'Hakoniwa AI\' (hereinafter \'App\').\n\n1. Collection and Use of Personal Information\nThis App is designed to operate completely offline (on-device). All data inputted by the user, such as training data, AI structures, and learning results, are saved ONLY within the user\'s smartphone device.\nThe Developer will never collect, acquire, or transmit any of this personal information or input data to external servers.\n\n2. Access to Device Features\nThis App accesses some device features to provide the following functions, but this data is not sent externally.\n- Clipboard: Used for importing data and copy-pasting \'Spells\'.\n- File Access: Accesses the local file system when using the CSV import/export feature for training data.\n- Photo Library and Image Files: Accesses the device\'s photo library or image files to select and load training data for the Image Generation (VAE) mode, as well as to save or share the generated images. All loaded and generated data is processed entirely on-device and is never transmitted to external servers under any circumstances.\n\n3. Provision of Information to Third Parties\nSince this App collects absolutely no personal information or input data from users, no information will be provided to third parties. Furthermore, no external analytics tools or third-party ad modules are integrated.\n\n4. Disclaimer\nThe Developer assumes no responsibility for any trouble or damage caused by using this App. Please back up your data and use the App at your own risk.\n\n5. Changes to Privacy Policy\nThe Developer may change this policy as necessary. The updated privacy policy becomes effective from the moment it is posted on this page.\n\n6. Contact\nDeveloper: Shin Tomura\nContact: [hakoniwa@ymail.plala.or.jp]\n\n(Established: March 22, 2026)';

  @override
  String msgImportSuccess(int count) {
    return 'Imported $count data items!';
  }

  @override
  String get msgImportTruncated => '* Truncated at 10,000 items for safety.';

  @override
  String get msgNoDataToImport => 'No data found to import.';

  @override
  String msgImportError(String error) {
    return 'Error occurred: $error';
  }

  @override
  String get msgNoTextInClipboard => 'No text in clipboard.';

  @override
  String get msgFileTooLarge =>
      'File too large (Max 5MB). Aborted to protect device.';

  @override
  String get msgFileLoadFailed => 'Failed to load file.';

  @override
  String get msgDataCopiedToClipboard =>
      'Data copied to clipboard. You can paste it into Excel, etc.';

  @override
  String get msgExportTruncated5000 =>
      '* Exported only the first 5,000 items for safety.';

  @override
  String get msgCsvExported => 'CSV file exported!';

  @override
  String msgCsvExportFailed(String error) {
    return 'Failed to save CSV: $error';
  }

  @override
  String msgShareCsvText(String name) {
    return 'Training data (CSV) for \'$name\'';
  }

  @override
  String get editProjectAndItemNameTitle => 'Edit Project & Items';

  @override
  String get projectNameHeader => 'Project Name';

  @override
  String get inputItemNamesHeader => '▼ Input Names';

  @override
  String get outputItemNamesHeader => '▼ Output Names';

  @override
  String inputItemLabelNum(int num) {
    return 'Input $num';
  }

  @override
  String outputItemLabelNum(int num) {
    return 'Output $num';
  }
}
