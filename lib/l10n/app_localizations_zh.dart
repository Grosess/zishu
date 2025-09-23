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
}
