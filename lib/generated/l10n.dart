// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class S {
  S(this._locale);

  static S of(BuildContext context) {
    return Localizations.of(context, S) ?? S(const Locale('en'));
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  final Locale _locale;

  // All localized strings
  String get appTitle => _getMessage('appTitle');
  String get practice => _getMessage('practice');
  String get sets => _getMessage('sets');
  String get statistics => _getMessage('statistics');
  String get settings => _getMessage('settings');
  String get importFromPhoto => _getMessage('importFromPhoto');
  String get scanVocabulary => _getMessage('scanVocabulary');
  String get selectPhotos => _getMessage('selectPhotos');
  String get fromCamera => _getMessage('fromCamera');
  String get fromGallery => _getMessage('fromGallery');
  String get practiceGroupSize => _getMessage('practiceGroupSize');
  String get practiceGroupDescription => _getMessage('practiceGroupDescription');
  String get practiceGroupExample => _getMessage('practiceGroupExample');
  String get chinese => _getMessage('chinese');
  String get pinyin => _getMessage('pinyin');
  String get english => _getMessage('english');
  String get saveSet => _getMessage('saveSet');
  String get characterSetName => _getMessage('characterSetName');
  String get language => _getMessage('language');
  String get selectLanguage => _getMessage('selectLanguage');
  String get englishLanguage => _getMessage('englishLanguage');
  String get chineseLanguage => _getMessage('chineseLanguage');
  String get welcomeTitle => _getMessage('welcomeTitle');
  String get welcomeMessage => _getMessage('welcomeMessage');
  String get processing => _getMessage('processing');
  String get ocrProcessing => _getMessage('ocrProcessing');
  String get downloadingModel => _getMessage('downloadingModel');
  String get home => _getMessage('home');
  String get progress => _getMessage('progress');
  String get addPhotos => _getMessage('addPhotos');
  String get importFromPhotoBeta => _getMessage('importFromPhotoBeta');
  String get scanVocabularyBeta => _getMessage('scanVocabularyBeta');
  String get clear => _getMessage('clear');
  String get noImagesSelected => _getMessage('noImagesSelected');
  String get tapToAddPhotos => _getMessage('tapToAddPhotos');
  String get termsPerGroup => _getMessage('termsPerGroup');
  String get reviewAndEdit => _getMessage('reviewAndEdit');
  String get failedToProcessImages => _getMessage('failedToProcessImages');
  String get noVocabularyFound => _getMessage('noVocabularyFound');
  String get removeAll => _getMessage('removeAll');
  String get beta => _getMessage('beta');
  String get takePhoto => _getMessage('takePhoto');
  String get selectFromGallery => _getMessage('selectFromGallery');
  String get processingImages => _getMessage('processingImages');
  String get extractingCharacters => _getMessage('extractingCharacters');
  String get mayTakeMoment => _getMessage('mayTakeMoment');

  String _getMessage(String key) {
    final messages = _locale.languageCode == 'zh' ? _zhMessages : _enMessages;
    return messages[key] ?? _enMessages[key] ?? key;
  }

  static const Map<String, String> _enMessages = {
    'appTitle': 'Zishu',
    'practice': 'Practice',
    'sets': 'Sets',
    'statistics': 'Statistics',
    'settings': 'Settings',
    'importFromPhoto': 'Import from Photo',
    'scanVocabulary': 'Scan Vocabulary',
    'selectPhotos': 'Select Photos',
    'fromCamera': 'From Camera',
    'fromGallery': 'From Gallery',
    'practiceGroupSize': 'Practice Group Size',
    'practiceGroupDescription': 'How many vocabulary terms will be practiced together in each study session',
    'practiceGroupExample': 'Example: 10 = practice 10 words at a time',
    'chinese': 'Chinese',
    'pinyin': 'Pinyin',
    'english': 'English',
    'saveSet': 'Save Set',
    'characterSetName': 'Character Set Name',
    'language': 'Language',
    'selectLanguage': 'Select Language',
    'englishLanguage': 'English',
    'chineseLanguage': '中文',
    'welcomeTitle': 'Welcome to Zishu',
    'welcomeMessage': 'Please select your preferred language:',
    'processing': 'Processing...',
    'ocrProcessing': 'Processing image with OCR...',
    'downloadingModel': 'Downloading language model... This may take a moment.',
    'home': 'Home',
    'progress': 'Progress',
    'addPhotos': 'Add Photos',
    'importFromPhotoBeta': 'Import from Photo (Beta)',
    'scanVocabularyBeta': 'Scan Vocabulary (Beta)',
    'clear': 'Clear',
    'noImagesSelected': 'No images selected',
    'tapToAddPhotos': 'Tap the buttons below to add photos',
    'termsPerGroup': 'Terms per group',
    'reviewAndEdit': 'Review and edit the vocabulary before saving',
    'failedToProcessImages': 'Failed to process images',
    'noVocabularyFound': 'No vocabulary items found in the images',
    'removeAll': 'Remove All',
    'beta': 'Beta',
    'takePhoto': 'Take Photo',
    'selectFromGallery': 'Select from Gallery',
    'processingImages': 'Processing images...',
    'extractingCharacters': 'Extracting Chinese characters and definitions',
    'mayTakeMoment': 'This may take a moment for multiple images',
  };

  static const Map<String, String> _zhMessages = {
    'appTitle': '字书',
    'practice': '练习',
    'sets': '字集',
    'statistics': '统计',
    'settings': '设置',
    'importFromPhoto': '从照片导入',
    'scanVocabulary': '扫描词汇',
    'selectPhotos': '选择照片',
    'fromCamera': '相机拍摄',
    'fromGallery': '从相册选择',
    'practiceGroupSize': '练习组大小',
    'practiceGroupDescription': '每次学习中一起练习的词汇数量',
    'practiceGroupExample': '例如：10 = 一次练习10个单词',
    'chinese': '中文',
    'pinyin': '拼音',
    'english': '英文',
    'saveSet': '保存字集',
    'characterSetName': '字集名称',
    'language': '语言',
    'selectLanguage': '选择语言',
    'englishLanguage': 'English',
    'chineseLanguage': '中文',
    'welcomeTitle': '欢迎使用字书',
    'welcomeMessage': '请选择您的首选语言：',
    'processing': '处理中...',
    'ocrProcessing': '正在处理图片 OCR...',
    'downloadingModel': '正在下载语言模型... 可能需要一些时间。',
    'home': '主页',
    'progress': '进度',
    'addPhotos': '添加照片',
    'importFromPhotoBeta': '从照片导入 (测试版)',
    'scanVocabularyBeta': '扫描词汇 (测试版)',
    'clear': '清除',
    'noImagesSelected': '未选择图片',
    'tapToAddPhotos': '点击下方按钮添加照片',
    'termsPerGroup': '每组词汇数',
    'reviewAndEdit': '保存前请检查和编辑词汇',
    'failedToProcessImages': '处理图片失败',
    'noVocabularyFound': '图片中未发现词汇项目',
    'removeAll': '全部移除',
    'beta': '测试版',
    'takePhoto': '拍摄照片',
    'selectFromGallery': '从相册选择',
    'processingImages': '处理图片中...',
    'extractingCharacters': '提取中文字符和定义',
    'mayTakeMoment': '处理多张图片可能需要一些时间',
  };
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<S> load(Locale locale) async {
    return S(locale);
  }

  @override
  bool shouldReload(_SDelegate old) => false;
}