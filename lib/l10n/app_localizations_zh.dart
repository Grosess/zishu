// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '字书';

  @override
  String get home => '主页';

  @override
  String get sets => '字集';

  @override
  String get progress => '进度';

  @override
  String get settings => '设置';

  @override
  String get characterSets => '字符集';

  @override
  String get builtIn => '内置';

  @override
  String get custom => '自定义';

  @override
  String get learn => '学习';

  @override
  String get practice => '练习';

  @override
  String get viewAll => '查看全部';

  @override
  String get add => '添加';

  @override
  String get remove => '移除';

  @override
  String get delete => '删除';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get edit => '编辑';

  @override
  String get rename => '重命名';

  @override
  String get select => '选择';

  @override
  String get editSet => '编辑字集';

  @override
  String get deleteSet => '删除字集';

  @override
  String get renameSet => '重命名字集';

  @override
  String get saveChanges => '保存更改';

  @override
  String get discardChanges => '放弃更改？';

  @override
  String get discardChangesMessage => '您有未保存的更改。要放弃它们吗？';

  @override
  String get discard => '放弃';

  @override
  String get markAllAsLearned => '全部标记为已学';

  @override
  String markAllAsLearnedConfirm(int count, String type, String name) {
    return '您真的要将 \"$name\" 中的所有 $count 个$type标记为已学吗？\n\n此操作无法撤销。';
  }

  @override
  String get words => '词语';

  @override
  String get characters => '字符';

  @override
  String get items => '项目';

  @override
  String get totalItems => '总项目';

  @override
  String get cards => '卡片';

  @override
  String get selected => '已选';

  @override
  String get selectAll => '全选';

  @override
  String get deselectAll => '取消全选';

  @override
  String get addItems => '添加项目';

  @override
  String get enterItems => '输入项目，用逗号、空格或换行分隔';

  @override
  String get exampleItems => '例如：你好，世界，中国';

  @override
  String get setName => '字集名称';

  @override
  String get enterNewName => '输入新名称';

  @override
  String createdFrom(String source) {
    return '创建自：$source';
  }

  @override
  String progressLabel(int percent) {
    return '进度：$percent%';
  }

  @override
  String get noItemsInSet => '此字集中没有项目';

  @override
  String get cannotSaveEmptySet => '不能保存空字集';

  @override
  String deleteSetConfirm(String name) {
    return '删除 \"$name\"？此操作无法撤销。';
  }

  @override
  String get createNewSet => '创建新字集';

  @override
  String get enterCharacters => '输入字符或词语';

  @override
  String get importFromText => '从文本导入';

  @override
  String get theme => '主题';

  @override
  String get duotone => '双色';

  @override
  String get classicFixed => '经典（固定）';

  @override
  String get chooseStrokeType => '选择笔画类型';

  @override
  String get language => '语言';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get englishLanguage => 'English';

  @override
  String get chineseLanguage => '中文';

  @override
  String get accentColor => '主题色';

  @override
  String get backgroundColor => '背景色';

  @override
  String get duotoneMode => '双色模式';

  @override
  String get green => '绿色';

  @override
  String get red => '红色';

  @override
  String get blue => '蓝色';

  @override
  String get purple => '紫色';

  @override
  String get orange => '橙色';

  @override
  String get pink => '粉色';

  @override
  String get gold => '金色';

  @override
  String get black => '黑色';

  @override
  String get white => '白色';

  @override
  String get gridView => '网格视图';

  @override
  String get listView => '列表视图';

  @override
  String get allItemsLearned => '此字集中的所有项目都已学习！';

  @override
  String get featureComingSoon => '功能即将推出';

  @override
  String get searchSets => '搜索字集...';

  @override
  String get noSetsFound => '未找到字集';

  @override
  String get searchAdditionalSets => '搜索要添加的其他字集...';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get developer => '开发者';

  @override
  String get welcomeTitle => '欢迎使用字书';

  @override
  String get welcomeMessage => '请选择您的首选语言：';

  @override
  String markedItemsAsLearned(int count) {
    return '已将 $count 个项目标记为已学';
  }

  @override
  String deletedSet(String name) {
    return '已删除 \"$name\"';
  }

  @override
  String get changeColor => '更改颜色';

  @override
  String get moveToFolder => '移至文件夹';

  @override
  String get mergeWithAnotherSet => '与另一字集合并';

  @override
  String countSelected(int count) {
    return '$count 个已选';
  }

  @override
  String countItems(int count) {
    return '$count 个项目';
  }

  @override
  String get charactersBy => '个字符截止';

  @override
  String perDay(int count) {
    return '每天 $count 个';
  }

  @override
  String get there => '进度';

  @override
  String get ahead => '领先';

  @override
  String get behind => '落后';

  @override
  String countAhead(int count) {
    return '领先 $count 个';
  }

  @override
  String countBehind(int count) {
    return '落后 $count 个';
  }

  @override
  String get endlessPractice => '无尽练习';

  @override
  String practiceAllLearned(int count) {
    return '练习全部 $count 个已学项目';
  }

  @override
  String get searchCharacters => '搜索字符';

  @override
  String get findByPinyin => '通过拼音、中文或英文查找';

  @override
  String get recentSets => '最近字集';

  @override
  String get noRecentSets => '没有最近练习的字集。';

  @override
  String get startPracticingSets => '从字集标签页开始练习！';

  @override
  String get sessionSummary => '练习总结';

  @override
  String get practiceIncorrect => '练习错误项';

  @override
  String get createSet => '创建字集';

  @override
  String get done => '完成';

  @override
  String get nameYourPracticeSet => '为练习集命名';

  @override
  String get noLearnedItemsFound => '未找到已学项目。请先学习一些字符！';

  @override
  String get couldNotOpenFeedback => '无法打开反馈表单';

  @override
  String get noValidCharactersFound => '未找到有效字符进行练习';

  @override
  String get showGroups => '显示分组';

  @override
  String get todaysLearn => '今日学习';

  @override
  String get todaysReview => '今日复习';

  @override
  String get totalTime => '总时间';

  @override
  String get todaysProgress => '今日进度';

  @override
  String get cardsStudied => '已学卡片';

  @override
  String get timeToday => '今日时间';

  @override
  String get dailyStreak => '连续天数';

  @override
  String get currentStreak => '当前连续';

  @override
  String get bestStreak => '最佳连续';

  @override
  String get verbs => '动词';

  @override
  String get dailyActivities => '日常活动';

  @override
  String get places => '地点';

  @override
  String get moreComingSoon => '更多即将推出...';

  @override
  String andMoreCount(int count) {
    return '... 还有 $count 个';
  }

  @override
  String get noCustomSets => '没有自定义字集';

  @override
  String get createCustomSet => '创建自定义字集';

  @override
  String get removeFromBuiltin => '从内置中移除';

  @override
  String get deleteCustomSet => '删除自定义字集';

  @override
  String get createFolder => '创建文件夹';

  @override
  String get renameFolder => '重命名文件夹';

  @override
  String get deleteFolder => '删除文件夹';

  @override
  String get chooseColor => '选择颜色';

  @override
  String get mergeSets => '合并字集';

  @override
  String get confirmMerge => '确认合并';

  @override
  String get noFolder => '无文件夹';

  @override
  String get allItemsLearnedMessage => '此字集中的所有项目都已学习！';

  @override
  String get noLearnedItemsMessage => '此字集中还没有已学项目。请先使用\"学习\"！';

  @override
  String get continueButton => '继续';

  @override
  String get someItemsUnavailable => '部分项目不可用';

  @override
  String ofGoal(Object goal) {
    return '目标 $goal 个';
  }

  @override
  String get setGoalButton => '设置目标';

  @override
  String get totalCharactersLearned => '已学字符总数';

  @override
  String get totalStudyTime => '总学习时间';

  @override
  String minutesShort(Object count) {
    return '$count分钟';
  }

  @override
  String hoursShort(Object count) {
    return '$count小时';
  }

  @override
  String daysShort(Object count) {
    return '$count天';
  }

  @override
  String setsCount(Object count) {
    return '$count 个字集';
  }

  @override
  String setCount(Object count) {
    return '$count 个字集';
  }

  @override
  String get searchCharactersHint => '搜索字符...';

  @override
  String get endless => '无尽';

  @override
  String get teal => '青色';

  @override
  String get lightPink => '浅粉色';

  @override
  String get hotPink => '亮粉色';

  @override
  String get blueGreen => '蓝绿色';

  @override
  String get themeColor => '主题颜色';

  @override
  String get practiceSettings => '练习设置';

  @override
  String get handwritingMode => '手写模式';

  @override
  String get handwritingModeDesc => '自由绘制无笔画引导，然后自我评估';

  @override
  String get showGrid => '显示网格';

  @override
  String get showGridDesc => '在练习区域显示网格线';

  @override
  String get showGuideByDefault => '默认显示引导';

  @override
  String get showGuideDesc => '在学习模式中显示字符轮廓';

  @override
  String get strokeWidth => '笔画宽度';

  @override
  String get strokeColor => '笔画颜色';

  @override
  String get strokeType => '笔画类型';

  @override
  String get strokeAppearance => '笔画外观';

  @override
  String get autoPronounce => '自动朗读中文';

  @override
  String get autoPronounceDesc => '自动朗读字符和词语';

  @override
  String get cardsPerGroup => '每组卡片数';

  @override
  String cardsPerGroupDesc(int count) {
    return '每组$count个字符';
  }

  @override
  String get attributions => '归属';

  @override
  String get attributionsDesc => '第三方许可和致谢';

  @override
  String get swapColors => '交换颜色';

  @override
  String get swapColorsDesc => '交换背景色和主题色';

  @override
  String get hintColor => '提示颜色';

  @override
  String get dailyGoal => '每日目标';

  @override
  String get charactersPerDay => '个字符/天';

  @override
  String get dataRecoveryTitle => '数据恢复通知';

  @override
  String dataRecoverySuccess(int count) {
    return '成功从备份恢复了$count个集合';
  }

  @override
  String get dataLoadError => '加载集合时出错';

  @override
  String dataLoadErrorMessage(int recovered, int total) {
    return '由于数据损坏，某些集合无法加载。已恢复$recovered/$total个集合。';
  }

  @override
  String get dataParseError => '无法加载自定义集合。数据可能已损坏。正在尝试从备份恢复...';

  @override
  String dataRecoveryFromBackup(int count) {
    return '已从备份恢复数据！恢复了$count个集合。';
  }

  @override
  String get noBackupAvailable => '没有可用的备份。如果丢失数据，请报告此问题。';

  @override
  String get dataSaveWarning => '警告：无法保存更改。请重试，如果问题持续存在，请联系支持。';

  @override
  String get ok => '确定';

  @override
  String get viewDetails => '查看详情';

  @override
  String goodEvening(String name) {
    return '晚上好，$name';
  }

  @override
  String goodMorning(String name) {
    return '早上好，$name';
  }

  @override
  String goodAfternoon(String name) {
    return '下午好，$name';
  }

  @override
  String goodNight(String name) {
    return '晚安，$name';
  }

  @override
  String get keepUpTheGreatWork => '继续加油！';

  @override
  String get writingMode => '书写模式';

  @override
  String get writingModeNormal => '笔画顺序';

  @override
  String get writingModeNormalDesc => '跟随笔画顺序指导';

  @override
  String get writingModeFree => '自由书写';

  @override
  String get writingModeFreeDesc => '无笔画指导自由绘制';

  @override
  String get showStrokeAnimation => '显示笔画动画';

  @override
  String get showStrokeAnimationDesc => '动画显示正确的笔画路径';

  @override
  String get showRadicalAnalysis => '显示部首分析';

  @override
  String get showRadicalAnalysisDesc => '显示字符部首分解';

  @override
  String get beta => '测试版';

  @override
  String get hapticFeedback => '触觉反馈';

  @override
  String get hapticFeedbackDesc => '交互时振动';

  @override
  String get strokeLeniency => '笔画宽松度';

  @override
  String get strokeLeniencyDesc => '笔画验证的严格程度';

  @override
  String get mostMissed => '最易出错';

  @override
  String get errorRate => '错误率';

  @override
  String get wrong => '错误';

  @override
  String get right => '正确';

  @override
  String get attempts => '尝试次数';

  @override
  String get dataAndProgress => '数据与进度';

  @override
  String get dataBackup => '数据备份';

  @override
  String get practiceHistory => '练习历史';

  @override
  String get markAsLearned => '标记为已学习';

  @override
  String get giveFeedback => '提供反馈';

  @override
  String get profile => '个人资料';

  @override
  String get saveProfile => '保存个人资料';

  @override
  String get howToUseZishu => '如何使用紫书';

  @override
  String get howToUseZishuTutorial => '紫书使用教程';

  @override
  String get enterFolderName => '输入文件夹名称';

  @override
  String get folderName => '文件夹名称';

  @override
  String get hours => '小时';

  @override
  String get minutes => '分钟';

  @override
  String get seconds => '秒';

  @override
  String get hour => '小时';

  @override
  String get minute => '分钟';

  @override
  String get second => '秒';

  @override
  String get usingDuotoneForeground => '使用双色前景色';

  @override
  String get pixels => '像素';

  @override
  String get auto => '自动';

  @override
  String get strokesConvertToFont => '绘制后笔画转换为字体';

  @override
  String get exportData => '导出数据';

  @override
  String get saveProgressToShare => '保存进度以便与其他设备共享';

  @override
  String get exportDataButton => '导出数据';

  @override
  String get importData => '导入数据';

  @override
  String get restoreProgress => '从另一设备恢复进度';

  @override
  String get pasteExportedData => '在此粘贴导出的数据';

  @override
  String get importDataButton => '导入数据';

  @override
  String get howItWorks => '工作原理：';

  @override
  String get exportDataStep1 => '1. 在一个设备上导出数据';

  @override
  String get exportDataStep2 => '2. 复制导出的文本';

  @override
  String get exportDataStep3 => '3. 发送到另一设备（邮件、消息等）';

  @override
  String get exportDataStep4 => '4. 在另一设备上粘贴并导入';

  @override
  String get backupNote => '注意：这是一个简单的备份方案。数据仅保存在您的设备上。';

  @override
  String get noPracticeSessions => '暂无练习记录';

  @override
  String get startPracticingToSeeHistory => '开始练习以查看历史记录';

  @override
  String get importKnownCharacters => '导入已知字符';

  @override
  String get import => '导入';

  @override
  String get characterMarkedAsLearned => '已标记1个字符为已学习';

  @override
  String charactersMarkedAsLearned(Object count) {
    return '已标记$count个字符为已学习';
  }

  @override
  String get searchByPinyin => '通过拼音、中文或英文搜索...';

  @override
  String get showLearnedOnly => '仅显示已学习';

  @override
  String get enterPinyinToSearch => '输入拼音进行搜索';

  @override
  String get examples => '示例：';

  @override
  String get pinyinExample => '拼音：\"shang\" → 上、伤、尚';

  @override
  String get chineseExample => '中文：\"上\" → 在上面/在...上';

  @override
  String get englishExample => '英文：\"water\" → 水、江、河';

  @override
  String get writingModeAutoDesc => '绘制后笔画转换为字体';

  @override
  String get writingModeHandwritingDesc => '手写并自动检查准确性';

  @override
  String get writingModeTrueHandwritingDesc => '自由绘制并自我评估，最适合记忆';

  @override
  String get handwriting => '手写';

  @override
  String get trueHandwriting => '真实手写';

  @override
  String get name => '名称';

  @override
  String get enterYourName => '输入您的名字';

  @override
  String get targetCharacters => '目标字符数';

  @override
  String exampleNumber(String number) {
    return '例如：$number';
  }

  @override
  String get dailyReviewTarget => '每日复习目标';

  @override
  String get characterSetName => '字符集名称';

  @override
  String get enterNameForSet => '为字集输入名称';

  @override
  String get chineseText => '中文文本';

  @override
  String get pasteOrTypeChineseText => '在此粘贴或输入中文文本...';

  @override
  String get enterDefinition => '输入定义...';

  @override
  String get exampleMyPracticeSet => '例如：我的练习集';

  @override
  String get exampleCharactersOrWords => '例如：我，你，他 或 你好世界';

  @override
  String get exampleMyVocabulary => '例如：我的词汇';

  @override
  String get optional => '可选';

  @override
  String get newFolder => '新文件夹';

  @override
  String get pleaseEnterFolderName => '请输入文件夹名称';

  @override
  String get coverCharacter => '封面字符';

  @override
  String get selectCoverCharacter => '选择一个字符来代表此字集';

  @override
  String get charactersOrWords => '字符/词语';

  @override
  String get useCommasForWords => '用逗号分隔词语。';

  @override
  String get allChineseCharactersExtracted => '将提取所有中文字符';

  @override
  String characterCount(int count) {
    return '$count 个字符';
  }

  @override
  String get enterAllCharactersYouKnow => '输入您已知的所有字符：';

  @override
  String get exampleChineseCharacters => '你好世界学习中文...';

  @override
  String get january => '一月';

  @override
  String get february => '二月';

  @override
  String get march => '三月';

  @override
  String get april => '四月';

  @override
  String get may => '五月';

  @override
  String get june => '六月';

  @override
  String get july => '七月';

  @override
  String get august => '八月';

  @override
  String get september => '九月';

  @override
  String get october => '十月';

  @override
  String get november => '十一月';

  @override
  String get december => '十二月';

  @override
  String get settingsHeader => '设置';

  @override
  String get supportHeader => '支持';

  @override
  String get tapToEditProfile => '点击编辑个人资料';

  @override
  String get user => '用户';

  @override
  String get system => '系统';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get chooseTheme => '选择主题';

  @override
  String get swap => '交换';

  @override
  String pixelsValue(String value) {
    return '$value 像素';
  }

  @override
  String get strokeOrderData => '笔画顺序数据和字符分解';

  @override
  String get dictionaryData => '中英文词典数据';

  @override
  String get characterInfoData => '字符信息和部首数据';

  @override
  String get viewOnGitHub => '在GitHub上查看';

  @override
  String get visitMDBG => '访问MDBG';

  @override
  String get learnMore => '了解更多';

  @override
  String get openSource => '开源';

  @override
  String get openSourceDescription =>
      '字书使用Flutter构建，并使用各种开源库。我们感谢所有使这些资源可用的贡献者。';

  @override
  String get copyrightShaunak => '版权所有 (c) 2016 Shaunak Kishore';

  @override
  String get licensedLGPL => '采用LGPL-3.0许可证';

  @override
  String get copyrightMDBG => '版权所有 (c) 2024 MDBG';

  @override
  String get licensedCCBY => '采用CC BY-SA 4.0许可证';

  @override
  String get copyrightUnicode => '版权所有 (c) 1991-2024 Unicode, Inc.';

  @override
  String get licensedUnicode => '采用Unicode许可协议';

  @override
  String get takePhoto => '拍照';

  @override
  String get selectFromGallery => '从相册选择';

  @override
  String get addPhotos => '添加照片';

  @override
  String get importFromPhoto => '从照片导入';

  @override
  String get removeAll => '全部移除';

  @override
  String get scanVocabulary => '扫描词汇表';

  @override
  String get processingImages => '处理图像中';

  @override
  String get extractingCharacters => '提取字符中';

  @override
  String get mayTakeMoment => '可能需要一些时间';

  @override
  String get ocrProcessing => 'OCR处理中';

  @override
  String get downloadingModel => '下载模型中';

  @override
  String get importText => '导入文本';

  @override
  String get pasteCharactersYouKnow => '粘贴您已知的字符';

  @override
  String get importFromCSV => '从CSV/TSV导入';

  @override
  String get uploadCSVFile => '上传 .csv 或 .tsv 文件';

  @override
  String get importFromCSVOrText => '从CSV或文本文件导入';

  @override
  String get importCSVDescription => '从CSV或TSV文件导入中文字符。';

  @override
  String get fileFormat => '文件格式：';

  @override
  String get firstColumnChineseChars => '• 第一列应包含中文字符';

  @override
  String get canIncludeWordsOrChars => '• 可以包含词语或单个字符';

  @override
  String get otherColumnsIgnored => '• 其他列将被忽略';

  @override
  String get supportedFormatsCSV => '支持的格式：.csv，.tsv';

  @override
  String get selectFile => '选择文件';

  @override
  String get tipPasteFromOtherSources => '提示：您可以从其他来源粘贴字符。';

  @override
  String get setDailyReviewGoal => '设置每日复习目标';

  @override
  String get setDailyReviewDescription => '设置您每天想要复习/练习的字符数量。';

  @override
  String get appearance => '外观';

  @override
  String get dataExportedSuccessfully => '数据导出成功';

  @override
  String get pleasePasteDataToImport => '请粘贴要导入的数据';

  @override
  String get dangerZone => '危险区域';

  @override
  String get permanentlyDeleteAllData => '永久删除所有数据';

  @override
  String get deleteAllDataWarning => '这将删除您所有已学习的字符、练习历史、自定义字集和所有其他数据。此操作无法撤销！';

  @override
  String get resetAllData => '重置所有数据';

  @override
  String get streakSettings => '连续天数设置';

  @override
  String learnCharsToMaintainStreak(int goal) {
    return '今天学习 $goal 个新字符以保持连续';
  }

  @override
  String get basedOnProgressGoal => '基于您的进度目标';

  @override
  String get close => '关闭';

  @override
  String get noStatisticsYet => '暂无统计数据';

  @override
  String get practiceToSeeErrorRates => '练习字符以查看您的错误率';

  @override
  String get days => '天';

  @override
  String get exportedDataTapToCopy => '导出的数据（点击复制）：';

  @override
  String get confirmImport => '确认导入';

  @override
  String foundCharactersToImport(int count) {
    return '找到 $count 个唯一字符要导入。是否继续？';
  }

  @override
  String get groups => '分组';

  @override
  String hskLevelVocabulary(String level) {
    return 'HSK $level 级词汇';
  }

  @override
  String groupNumber(int number) {
    return '第 $number 组';
  }

  @override
  String itemsCount(int count) {
    return '（$count 项）';
  }

  @override
  String setGroups(String setName) {
    return '$setName - 分组';
  }

  @override
  String supergroupNumber(int number) {
    return '超级分组 $number';
  }

  @override
  String get backToSupergroups => '← 返回超级分组';

  @override
  String get hideGroups => '隐藏分组';

  @override
  String get hideSupergroups => '隐藏超级分组';

  @override
  String get showSupergroups => '显示超级分组';

  @override
  String get learningMode => '学习模式';

  @override
  String get practiceAll => '全部练习';

  @override
  String get setLearned => '字集已学习！';

  @override
  String get noGroupsNeeded => '无需分组';

  @override
  String setGroupNumber(String setName, int number) {
    return '$setName - 第 $number 组';
  }

  @override
  String get changeProfilePicture => '更改头像';

  @override
  String get loading => '加载中...';

  @override
  String get chooseFromFiles => '从文件选择';

  @override
  String get enterNameToUseInitials => '输入名字以使用首字母';

  @override
  String useInitials(String initial) {
    return '使用首字母 ($initial)';
  }

  @override
  String get imageSelected => '已选择图片';

  @override
  String get noImageSelected => '未选择图片';

  @override
  String get submit => '提交';

  @override
  String get dataImportedSuccessfully => '数据导入成功';

  @override
  String get invalidDataFormat => '数据格式无效';

  @override
  String get failedToImportData => '导入数据失败';

  @override
  String get copiedToClipboard => '已复制到剪贴板';

  @override
  String get confirmReset => '确认重置';

  @override
  String get confirmResetQuestion => '您确定要重置所有数据吗？';

  @override
  String get thisWillPermanentlyDelete => '这将永久删除：';

  @override
  String get allLearnedCharactersAndWords => '• 所有已学习的字符和词语';

  @override
  String get allPracticeHistoryAndStats => '• 所有练习历史和统计数据';

  @override
  String get allCustomCharacterSets => '• 所有自定义字符集';

  @override
  String get allFoldersAndOrganization => '• 所有文件夹和组织';

  @override
  String get allSettingsAndPreferences => '• 所有设置和偏好';

  @override
  String get thisActionCannotBeUndone => '此操作无法撤销！';

  @override
  String get yesDeleteEverything => '是的，删除所有内容';

  @override
  String get allDataHasBeenReset => '所有数据已被重置';

  @override
  String get showGroupsButton => '显示分组';

  @override
  String get groupsButton => '分组';

  @override
  String get chooseHintColor => '选择提示颜色';

  @override
  String get hskLevel1Description => 'HSK 1 级词汇';

  @override
  String get hskLevel2Description => 'HSK 2 级词汇（仅新词）';

  @override
  String get hskLevel3Description => 'HSK 3 级词汇（仅新词）';

  @override
  String get hskLevel4Description => 'HSK 4 级词汇（仅新词）';

  @override
  String get hskLevel5Description => 'HSK 5 级词汇（仅新词）';

  @override
  String get hskLevel6Description => 'HSK 6 级词汇（仅新词）';

  @override
  String get erase => '擦除';

  @override
  String get showCharacter => '显示字符';

  @override
  String get hideCharacter => '隐藏字符';

  @override
  String get nextStep => '下一步';

  @override
  String get showAll => '全部显示';

  @override
  String get hide => '隐藏';

  @override
  String get createYourOwnPracticeSets => '创建您自己的练习集，包含特定的汉字或词语';

  @override
  String get createYourFirstSet => '创建您的第一个字集';
}
