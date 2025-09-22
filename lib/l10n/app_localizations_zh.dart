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
  String get practice => '练习';

  @override
  String get sets => '字集';

  @override
  String get statistics => '统计';

  @override
  String get settings => '设置';

  @override
  String get importFromPhoto => '从照片导入';

  @override
  String get scanVocabulary => '扫描词汇';

  @override
  String get selectPhotos => '选择照片';

  @override
  String get fromCamera => '相机拍摄';

  @override
  String get fromGallery => '从相册选择';

  @override
  String get practiceGroupSize => '练习组大小';

  @override
  String get practiceGroupDescription => '每次学习中一起练习的词汇数量';

  @override
  String get practiceGroupExample => '例如：10 = 一次练习10个单词';

  @override
  String get chinese => '中文';

  @override
  String get pinyin => '拼音';

  @override
  String get english => '英文';

  @override
  String get saveSet => '保存字集';

  @override
  String get characterSetName => '字集名称';

  @override
  String get language => '语言';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get englishLanguage => 'English';

  @override
  String get chineseLanguage => '中文';

  @override
  String get welcomeTitle => '欢迎使用字书';

  @override
  String get welcomeMessage => '请选择您的首选语言：';

  @override
  String get processing => '处理中...';

  @override
  String get ocrProcessing => '正在处理图片 OCR...';

  @override
  String get downloadingModel => '正在下载语言模型... 可能需要一些时间。';
}
