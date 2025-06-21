import 'dart:convert';
import 'package:flutter/services.dart';
import 'decomposition_service.dart';

class RadicalInfo {
  final String radical;
  final String meaning;
  final String pinyin;
  final int strokeCount;

  RadicalInfo({
    required this.radical,
    required this.meaning,
    required this.pinyin,
    required this.strokeCount,
  });
}

class CharacterRadicalAnalysis {
  final String character;
  final List<RadicalInfo> radicals;
  final String? semanticHint;
  final String? phoneticHint;

  CharacterRadicalAnalysis({
    required this.character,
    required this.radicals,
    this.semanticHint,
    this.phoneticHint,
  });
}

class RadicalService {
  static final RadicalService _instance = RadicalService._internal();
  factory RadicalService() => _instance;
  RadicalService._internal();

  bool _isInitialized = false;
  Map<String, RadicalInfo> _radicalDatabase = {};
  Map<String, CharacterRadicalAnalysis> _cache = {};
  final DecompositionService _decompositionService = DecompositionService();

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize radical service
    try {
      // Load radical database
      await _loadRadicalDatabase();
      // Production: removed debug print
      // Initialize decomposition service
      await _decompositionService.initialize();
      // Production: removed debug print
      _isInitialized = true;
      // Production: removed debug print
    } catch (e) {
      // Production: removed debug print
    }
  }

  Future<void> _loadRadicalDatabase() async {
    // Common radicals with their meanings
    // This is a subset - you could expand this with a full radical database
    _radicalDatabase = {
      '人': RadicalInfo(radical: '人', meaning: 'person', pinyin: 'rén', strokeCount: 2),
      '亻': RadicalInfo(radical: '亻', meaning: 'person (left)', pinyin: 'rén', strokeCount: 2),
      '口': RadicalInfo(radical: '口', meaning: 'mouth', pinyin: 'kǒu', strokeCount: 3),
      '土': RadicalInfo(radical: '土', meaning: 'earth', pinyin: 'tǔ', strokeCount: 3),
      '女': RadicalInfo(radical: '女', meaning: 'woman', pinyin: 'nǚ', strokeCount: 3),
      '子': RadicalInfo(radical: '子', meaning: 'child', pinyin: 'zǐ', strokeCount: 3),
      '心': RadicalInfo(radical: '心', meaning: 'heart', pinyin: 'xīn', strokeCount: 4),
      '忄': RadicalInfo(radical: '忄', meaning: 'heart (left)', pinyin: 'xīn', strokeCount: 3),
      '手': RadicalInfo(radical: '手', meaning: 'hand', pinyin: 'shǒu', strokeCount: 4),
      '扌': RadicalInfo(radical: '扌', meaning: 'hand (left)', pinyin: 'shǒu', strokeCount: 3),
      '日': RadicalInfo(radical: '日', meaning: 'sun/day', pinyin: 'rì', strokeCount: 4),
      '月': RadicalInfo(radical: '月', meaning: 'moon/month', pinyin: 'yuè', strokeCount: 4),
      '木': RadicalInfo(radical: '木', meaning: 'tree/wood', pinyin: 'mù', strokeCount: 4),
      '水': RadicalInfo(radical: '水', meaning: 'water', pinyin: 'shuǐ', strokeCount: 4),
      '氵': RadicalInfo(radical: '氵', meaning: 'water (left)', pinyin: 'shuǐ', strokeCount: 3),
      '火': RadicalInfo(radical: '火', meaning: 'fire', pinyin: 'huǒ', strokeCount: 4),
      '灬': RadicalInfo(radical: '灬', meaning: 'fire (bottom)', pinyin: 'huǒ', strokeCount: 4),
      '金': RadicalInfo(radical: '金', meaning: 'metal/gold', pinyin: 'jīn', strokeCount: 8),
      '钅': RadicalInfo(radical: '钅', meaning: 'metal (left)', pinyin: 'jīn', strokeCount: 5),
      '言': RadicalInfo(radical: '言', meaning: 'speech', pinyin: 'yán', strokeCount: 7),
      '讠': RadicalInfo(radical: '讠', meaning: 'speech (left)', pinyin: 'yán', strokeCount: 2),
      '辶': RadicalInfo(radical: '辶', meaning: 'walk', pinyin: 'chuò', strokeCount: 3),
      '艹': RadicalInfo(radical: '艹', meaning: 'grass', pinyin: 'cǎo', strokeCount: 3),
      '宀': RadicalInfo(radical: '宀', meaning: 'roof', pinyin: 'mián', strokeCount: 3),
      '贝': RadicalInfo(radical: '贝', meaning: 'shell/money', pinyin: 'bèi', strokeCount: 4),
      '见': RadicalInfo(radical: '见', meaning: 'see', pinyin: 'jiàn', strokeCount: 4),
      '门': RadicalInfo(radical: '门', meaning: 'door', pinyin: 'mén', strokeCount: 3),
      '马': RadicalInfo(radical: '马', meaning: 'horse', pinyin: 'mǎ', strokeCount: 3),
      '鸟': RadicalInfo(radical: '鸟', meaning: 'bird', pinyin: 'niǎo', strokeCount: 5),
      '鱼': RadicalInfo(radical: '鱼', meaning: 'fish', pinyin: 'yú', strokeCount: 8),
      '虫': RadicalInfo(radical: '虫', meaning: 'insect', pinyin: 'chóng', strokeCount: 6),
      '目': RadicalInfo(radical: '目', meaning: 'eye', pinyin: 'mù', strokeCount: 5),
      '耳': RadicalInfo(radical: '耳', meaning: 'ear', pinyin: 'ěr', strokeCount: 6),
      '舌': RadicalInfo(radical: '舌', meaning: 'tongue', pinyin: 'shé', strokeCount: 6),
      '竹': RadicalInfo(radical: '竹', meaning: 'bamboo', pinyin: 'zhú', strokeCount: 6),
      '米': RadicalInfo(radical: '米', meaning: 'rice', pinyin: 'mǐ', strokeCount: 6),
      '糸': RadicalInfo(radical: '糸', meaning: 'silk', pinyin: 'sī', strokeCount: 6),
      '纟': RadicalInfo(radical: '纟', meaning: 'silk (left)', pinyin: 'sī', strokeCount: 3),
      '石': RadicalInfo(radical: '石', meaning: 'stone', pinyin: 'shí', strokeCount: 5),
      '山': RadicalInfo(radical: '山', meaning: 'mountain', pinyin: 'shān', strokeCount: 3),
      '田': RadicalInfo(radical: '田', meaning: 'field', pinyin: 'tián', strokeCount: 5),
      '刀': RadicalInfo(radical: '刀', meaning: 'knife', pinyin: 'dāo', strokeCount: 2),
      '刂': RadicalInfo(radical: '刂', meaning: 'knife (right)', pinyin: 'dāo', strokeCount: 2),
      '力': RadicalInfo(radical: '力', meaning: 'power', pinyin: 'lì', strokeCount: 2),
      '又': RadicalInfo(radical: '又', meaning: 'again/hand', pinyin: 'yòu', strokeCount: 2),
      '犬': RadicalInfo(radical: '犬', meaning: 'dog', pinyin: 'quǎn', strokeCount: 4),
      '犭': RadicalInfo(radical: '犭', meaning: 'dog (left)', pinyin: 'quǎn', strokeCount: 3),
      '禾': RadicalInfo(radical: '禾', meaning: 'grain', pinyin: 'hé', strokeCount: 5),
      '穴': RadicalInfo(radical: '穴', meaning: 'cave', pinyin: 'xué', strokeCount: 5),
      '立': RadicalInfo(radical: '立', meaning: 'stand', pinyin: 'lì', strokeCount: 5),
      '走': RadicalInfo(radical: '走', meaning: 'walk/run', pinyin: 'zǒu', strokeCount: 7),
      '足': RadicalInfo(radical: '足', meaning: 'foot', pinyin: 'zú', strokeCount: 7),
      '⻊': RadicalInfo(radical: '⻊', meaning: 'foot (left)', pinyin: 'zú', strokeCount: 7),
      '雨': RadicalInfo(radical: '雨', meaning: 'rain', pinyin: 'yǔ', strokeCount: 8),
      '食': RadicalInfo(radical: '食', meaning: 'food', pinyin: 'shí', strokeCount: 9),
      '饣': RadicalInfo(radical: '饣', meaning: 'food (left)', pinyin: 'shí', strokeCount: 3),
      '丶': RadicalInfo(radical: '丶', meaning: 'dot', pinyin: 'zhǔ', strokeCount: 1),
      '一': RadicalInfo(radical: '一', meaning: 'one/horizontal', pinyin: 'yī', strokeCount: 1),
      '廿': RadicalInfo(radical: '廿', meaning: 'twenty', pinyin: 'niàn', strokeCount: 4),
      '属': RadicalInfo(radical: '属', meaning: 'belong', pinyin: 'shǔ', strokeCount: 12),
      '乍': RadicalInfo(radical: '乍', meaning: 'suddenly', pinyin: 'zhà', strokeCount: 5),
      '主': RadicalInfo(radical: '主', meaning: 'master/main', pinyin: 'zhǔ', strokeCount: 5),
      '本': RadicalInfo(radical: '本', meaning: 'root/origin', pinyin: 'běn', strokeCount: 5),
      '旦': RadicalInfo(radical: '旦', meaning: 'dawn', pinyin: 'dàn', strokeCount: 5),
      '氐': RadicalInfo(radical: '氐', meaning: 'low', pinyin: 'dī', strokeCount: 5),
      '可': RadicalInfo(radical: '可', meaning: 'can/may', pinyin: 'kě', strokeCount: 5),
      '弗': RadicalInfo(radical: '弗', meaning: 'not', pinyin: 'fú', strokeCount: 5),
      '吏': RadicalInfo(radical: '吏', meaning: 'official', pinyin: 'lì', strokeCount: 6),
      '列': RadicalInfo(radical: '列', meaning: 'arrange', pinyin: 'liè', strokeCount: 6),
      '共': RadicalInfo(radical: '共', meaning: 'together', pinyin: 'gòng', strokeCount: 6),
      '两': RadicalInfo(radical: '两', meaning: 'two/both', pinyin: 'liǎng', strokeCount: 7),
      '咅': RadicalInfo(radical: '咅', meaning: 'spit', pinyin: 'pǒu', strokeCount: 8),
      '侯': RadicalInfo(radical: '侯', meaning: 'marquis', pinyin: 'hóu', strokeCount: 9),
      '昔': RadicalInfo(radical: '昔', meaning: 'past', pinyin: 'xī', strokeCount: 8),
      '直': RadicalInfo(radical: '直', meaning: 'straight', pinyin: 'zhí', strokeCount: 8),
      '叚': RadicalInfo(radical: '叚', meaning: 'false', pinyin: 'jiǎ', strokeCount: 9),
      '禺': RadicalInfo(radical: '禺', meaning: 'monkey', pinyin: 'yú', strokeCount: 9),
      '象': RadicalInfo(radical: '象', meaning: 'elephant', pinyin: 'xiàng', strokeCount: 12),
      '分': RadicalInfo(radical: '分', meaning: 'divide', pinyin: 'fēn', strokeCount: 4),
      '半': RadicalInfo(radical: '半', meaning: 'half', pinyin: 'bàn', strokeCount: 5),
      '古': RadicalInfo(radical: '古', meaning: 'ancient', pinyin: 'gǔ', strokeCount: 5),
      '专': RadicalInfo(radical: '专', meaning: 'special', pinyin: 'zhuān', strokeCount: 4),
      '介': RadicalInfo(radical: '介', meaning: 'between', pinyin: 'jiè', strokeCount: 4),
      '牛': RadicalInfo(radical: '牛', meaning: 'cow', pinyin: 'niú', strokeCount: 4),
      '壬': RadicalInfo(radical: '壬', meaning: 'ninth', pinyin: 'rén', strokeCount: 4),
      '尤': RadicalInfo(radical: '尤', meaning: 'especially', pinyin: 'yóu', strokeCount: 4),
      '云': RadicalInfo(radical: '云', meaning: 'cloud', pinyin: 'yún', strokeCount: 4),
      '王': RadicalInfo(radical: '王', meaning: 'king', pinyin: 'wáng', strokeCount: 4),
      '厶': RadicalInfo(radical: '厶', meaning: 'private', pinyin: 'sī', strokeCount: 2),
      '丘': RadicalInfo(radical: '丘', meaning: 'hill', pinyin: 'qiū', strokeCount: 5),
      '甘': RadicalInfo(radical: '甘', meaning: 'sweet', pinyin: 'gān', strokeCount: 5),
      '曲': RadicalInfo(radical: '曲', meaning: 'bent', pinyin: 'qū', strokeCount: 6),
      '天': RadicalInfo(radical: '天', meaning: 'sky', pinyin: 'tiān', strokeCount: 4),
      '夂': RadicalInfo(radical: '夂', meaning: 'go', pinyin: 'zhǐ', strokeCount: 3),
      '冖': RadicalInfo(radical: '冖', meaning: 'cover', pinyin: 'mì', strokeCount: 2),
      '与': RadicalInfo(radical: '与', meaning: 'give', pinyin: 'yǔ', strokeCount: 3),
      '车': RadicalInfo(radical: '车', meaning: 'vehicle', pinyin: 'chē', strokeCount: 4),
      '辰': RadicalInfo(radical: '辰', meaning: 'morning', pinyin: 'chén', strokeCount: 7),
      '令': RadicalInfo(radical: '令', meaning: 'order', pinyin: 'lìng', strokeCount: 5),
      '中': RadicalInfo(radical: '中', meaning: 'middle', pinyin: 'zhōng', strokeCount: 4),
      '夬': RadicalInfo(radical: '夬', meaning: 'decide', pinyin: 'guài', strokeCount: 4),
      '兄': RadicalInfo(radical: '兄', meaning: 'elder brother', pinyin: 'xiōng', strokeCount: 5),
      '隹': RadicalInfo(radical: '隹', meaning: 'bird', pinyin: 'zhuī', strokeCount: 8),
      '京': RadicalInfo(radical: '京', meaning: 'capital', pinyin: 'jīng', strokeCount: 8),
      '咸': RadicalInfo(radical: '咸', meaning: 'salty', pinyin: 'xián', strokeCount: 9),
      '疑': RadicalInfo(radical: '疑', meaning: 'doubt', pinyin: 'yí', strokeCount: 14),
      '几': RadicalInfo(radical: '几', meaning: 'table', pinyin: 'jī', strokeCount: 2),
      '风': RadicalInfo(radical: '风', meaning: 'wind', pinyin: 'fēng', strokeCount: 4),
      '岂': RadicalInfo(radical: '岂', meaning: 'how', pinyin: 'qǐ', strokeCount: 6),
      '凵': RadicalInfo(radical: '凵', meaning: 'receptacle', pinyin: 'kǎn', strokeCount: 2),
      '乂': RadicalInfo(radical: '乂', meaning: 'regulate', pinyin: 'yì', strokeCount: 2),
      '丩': RadicalInfo(radical: '丩', meaning: 'connect', pinyin: 'jiū', strokeCount: 2),
      '匕': RadicalInfo(radical: '匕', meaning: 'spoon', pinyin: 'bǐ', strokeCount: 2),
      '丂': RadicalInfo(radical: '丂', meaning: 'obstruction', pinyin: 'kǎo', strokeCount: 2),
      '于': RadicalInfo(radical: '于', meaning: 'at/in', pinyin: 'yú', strokeCount: 3),
      '乞': RadicalInfo(radical: '乞', meaning: 'beg', pinyin: 'qǐ', strokeCount: 3),
      '幺': RadicalInfo(radical: '幺', meaning: 'tiny', pinyin: 'yāo', strokeCount: 3),
      '士': RadicalInfo(radical: '士', meaning: 'scholar', pinyin: 'shì', strokeCount: 3),
      '巾': RadicalInfo(radical: '巾', meaning: 'towel', pinyin: 'jīn', strokeCount: 3),
      '冂': RadicalInfo(radical: '冂', meaning: 'border', pinyin: 'jiōng', strokeCount: 2),
      '夕': RadicalInfo(radical: '夕', meaning: 'evening', pinyin: 'xī', strokeCount: 3),
      '尹': RadicalInfo(radical: '尹', meaning: 'govern', pinyin: 'yǐn', strokeCount: 4),
      '文': RadicalInfo(radical: '文', meaning: 'literature', pinyin: 'wén', strokeCount: 4),
      '今': RadicalInfo(radical: '今', meaning: 'now', pinyin: 'jīn', strokeCount: 4),
      '丿': RadicalInfo(radical: '丿', meaning: 'slash', pinyin: 'piě', strokeCount: 1),
      '乀': RadicalInfo(radical: '乀', meaning: 'dot', pinyin: 'fú', strokeCount: 1),
      '丁': RadicalInfo(radical: '丁', meaning: 'nail', pinyin: 'dīng', strokeCount: 2),
      '七': RadicalInfo(radical: '七', meaning: 'seven', pinyin: 'qī', strokeCount: 2),
      '九': RadicalInfo(radical: '九', meaning: 'nine', pinyin: 'jiǔ', strokeCount: 2),
      '八': RadicalInfo(radical: '八', meaning: 'eight', pinyin: 'bā', strokeCount: 2),
      '十': RadicalInfo(radical: '十', meaning: 'ten', pinyin: 'shí', strokeCount: 2),
      '厂': RadicalInfo(radical: '厂', meaning: 'cliff', pinyin: 'chǎng', strokeCount: 2),
      '卜': RadicalInfo(radical: '卜', meaning: 'divination', pinyin: 'bǔ', strokeCount: 2),
      '卩': RadicalInfo(radical: '卩', meaning: 'seal', pinyin: 'jié', strokeCount: 2),
      '勹': RadicalInfo(radical: '勹', meaning: 'wrap', pinyin: 'bāo', strokeCount: 2),
      '匚': RadicalInfo(radical: '匚', meaning: 'box', pinyin: 'fāng', strokeCount: 2),
      '冫': RadicalInfo(radical: '冫', meaning: 'ice', pinyin: 'bīng', strokeCount: 2),
      '丬': RadicalInfo(radical: '丬', meaning: 'split', pinyin: 'pán', strokeCount: 3),
      '彡': RadicalInfo(radical: '彡', meaning: 'hair', pinyin: 'shān', strokeCount: 3),
      '巳': RadicalInfo(radical: '巳', meaning: 'snake', pinyin: 'sì', strokeCount: 3),
      '干': RadicalInfo(radical: '干', meaning: 'dry', pinyin: 'gān', strokeCount: 3),
      '戈': RadicalInfo(radical: '戈', meaning: 'halberd', pinyin: 'gē', strokeCount: 4),
      '歹': RadicalInfo(radical: '歹', meaning: 'bad', pinyin: 'dǎi', strokeCount: 4),
      '贝': RadicalInfo(radical: '贝', meaning: 'shell', pinyin: 'bèi', strokeCount: 4),
      '冈': RadicalInfo(radical: '冈', meaning: 'ridge', pinyin: 'gāng', strokeCount: 4),
      '仓': RadicalInfo(radical: '仓', meaning: 'warehouse', pinyin: 'cāng', strokeCount: 4),
      '衤': RadicalInfo(radical: '衤', meaning: 'clothes', pinyin: 'yī', strokeCount: 5),
      '未': RadicalInfo(radical: '未', meaning: 'not yet', pinyin: 'wèi', strokeCount: 5),
      '尸': RadicalInfo(radical: '尸', meaning: 'corpse', pinyin: 'shī', strokeCount: 3),
      '朿': RadicalInfo(radical: '朿', meaning: 'thorn', pinyin: 'cì', strokeCount: 6),
      '亥': RadicalInfo(radical: '亥', meaning: 'pig', pinyin: 'hài', strokeCount: 6),
      '齐': RadicalInfo(radical: '齐', meaning: 'even', pinyin: 'qí', strokeCount: 6),
      '弟': RadicalInfo(radical: '弟', meaning: 'younger brother', pinyin: 'dì', strokeCount: 7),
      '肖': RadicalInfo(radical: '肖', meaning: 'resemble', pinyin: 'xiào', strokeCount: 7),
      '佥': RadicalInfo(radical: '佥', meaning: 'all', pinyin: 'qiān', strokeCount: 7),
      '居': RadicalInfo(radical: '居', meaning: 'reside', pinyin: 'jū', strokeCount: 8),
      '乘': RadicalInfo(radical: '乘', meaning: 'ride', pinyin: 'chéng', strokeCount: 10),
      '畐': RadicalInfo(radical: '畐', meaning: 'full', pinyin: 'fú', strokeCount: 9),
      '害': RadicalInfo(radical: '害', meaning: 'harm', pinyin: 'hài', strokeCount: 10),
      '工': RadicalInfo(radical: '工', meaning: 'work', pinyin: 'gōng', strokeCount: 3),
      '且': RadicalInfo(radical: '且', meaning: 'moreover', pinyin: 'qiě', strokeCount: 5),
      '奴': RadicalInfo(radical: '奴', meaning: 'slave', pinyin: 'nú', strokeCount: 5),
      '去': RadicalInfo(radical: '去', meaning: 'go', pinyin: 'qù', strokeCount: 5),
      '厉': RadicalInfo(radical: '厉', meaning: 'severe', pinyin: 'lì', strokeCount: 5),
      '经': RadicalInfo(radical: '经', meaning: 'pass through', pinyin: 'jīng', strokeCount: 8),
      '执': RadicalInfo(radical: '执', meaning: 'hold', pinyin: 'zhí', strokeCount: 6),
      '甬': RadicalInfo(radical: '甬', meaning: 'path', pinyin: 'yǒng', strokeCount: 7),
      '免': RadicalInfo(radical: '免', meaning: 'avoid', pinyin: 'miǎn', strokeCount: 7),
      '革': RadicalInfo(radical: '革', meaning: 'leather', pinyin: 'gé', strokeCount: 9),
      '堇': RadicalInfo(radical: '堇', meaning: 'violet', pinyin: 'jǐn', strokeCount: 11),
      '是': RadicalInfo(radical: '是', meaning: 'is/yes', pinyin: 'shì', strokeCount: 9),
      '斤': RadicalInfo(radical: '斤', meaning: 'axe', pinyin: 'jīn', strokeCount: 4),
      '甲': RadicalInfo(radical: '甲', meaning: 'armor', pinyin: 'jiǎ', strokeCount: 5),
      '非': RadicalInfo(radical: '非', meaning: 'not', pinyin: 'fēi', strokeCount: 8),
      '儿': RadicalInfo(radical: '儿', meaning: 'legs', pinyin: 'ér', strokeCount: 2),
      '矢': RadicalInfo(radical: '矢', meaning: 'arrow', pinyin: 'shǐ', strokeCount: 5),
      '扁': RadicalInfo(radical: '扁', meaning: 'flat', pinyin: 'biǎn', strokeCount: 9),
      '若': RadicalInfo(radical: '若', meaning: 'if', pinyin: 'ruò', strokeCount: 8),
      '千': RadicalInfo(radical: '千', meaning: 'thousand', pinyin: 'qiān', strokeCount: 3),
      '廾': RadicalInfo(radical: '廾', meaning: 'two hands', pinyin: 'gǒng', strokeCount: 3),
      '化': RadicalInfo(radical: '化', meaning: 'change', pinyin: 'huà', strokeCount: 4),
      '办': RadicalInfo(radical: '办', meaning: 'handle', pinyin: 'bàn', strokeCount: 4),
      '白': RadicalInfo(radical: '白', meaning: 'white', pinyin: 'bái', strokeCount: 5),
      '占': RadicalInfo(radical: '占', meaning: 'occupy', pinyin: 'zhàn', strokeCount: 5),
      '尃': RadicalInfo(radical: '尃', meaning: 'spread', pinyin: 'fū', strokeCount: 12),
      '上': RadicalInfo(radical: '上', meaning: 'up', pinyin: 'shàng', strokeCount: 3),
      '下': RadicalInfo(radical: '下', meaning: 'down', pinyin: 'xià', strokeCount: 3),
      '圭': RadicalInfo(radical: '圭', meaning: 'jade', pinyin: 'guī', strokeCount: 6),
      '臣': RadicalInfo(radical: '臣', meaning: 'minister', pinyin: 'chén', strokeCount: 6),
      '韦': RadicalInfo(radical: '韦', meaning: 'tanned leather', pinyin: 'wéi', strokeCount: 4),
      '卯': RadicalInfo(radical: '卯', meaning: 'rabbit', pinyin: 'mǎo', strokeCount: 5),
      '皀': RadicalInfo(radical: '皀', meaning: 'grain', pinyin: 'bī', strokeCount: 7),
      '龹': RadicalInfo(radical: '龹', meaning: 'roll', pinyin: 'quǎn', strokeCount: 16),
      '厄': RadicalInfo(radical: '厄', meaning: 'disaster', pinyin: 'è', strokeCount: 4),
      '乙': RadicalInfo(radical: '乙', meaning: 'second', pinyin: 'yǐ', strokeCount: 1),
      '万': RadicalInfo(radical: '万', meaning: 'ten thousand', pinyin: 'wàn', strokeCount: 3),
      '里': RadicalInfo(radical: '里', meaning: 'inside', pinyin: 'lǐ', strokeCount: 7),
      '相': RadicalInfo(radical: '相', meaning: 'mutual', pinyin: 'xiāng', strokeCount: 9),
      '夏': RadicalInfo(radical: '夏', meaning: 'summer', pinyin: 'xià', strokeCount: 10),
      '豆': RadicalInfo(radical: '豆', meaning: 'bean', pinyin: 'dòu', strokeCount: 7),
      '寸': RadicalInfo(radical: '寸', meaning: 'inch', pinyin: 'cùn', strokeCount: 3),
      '既': RadicalInfo(radical: '既', meaning: 'already', pinyin: 'jì', strokeCount: 9),
      '斯': RadicalInfo(radical: '斯', meaning: 'this', pinyin: 'sī', strokeCount: 12),
      '三': RadicalInfo(radical: '三', meaning: 'three', pinyin: 'sān', strokeCount: 3),
      '大': RadicalInfo(radical: '大', meaning: 'big', pinyin: 'dà', strokeCount: 3),
      '尗': RadicalInfo(radical: '尗', meaning: 'uncle', pinyin: 'shú', strokeCount: 6),
      '耳': RadicalInfo(radical: '耳', meaning: 'ear', pinyin: 'ěr', strokeCount: 6),
      '爫': RadicalInfo(radical: '爫', meaning: 'claw', pinyin: 'zhǎo', strokeCount: 4),
      '亦': RadicalInfo(radical: '亦', meaning: 'also', pinyin: 'yì', strokeCount: 6),
      '余': RadicalInfo(radical: '余', meaning: 'surplus', pinyin: 'yú', strokeCount: 7),
      '叒': RadicalInfo(radical: '叒', meaning: 'obedient', pinyin: 'ruò', strokeCount: 6),
      '宜': RadicalInfo(radical: '宜', meaning: 'suitable', pinyin: 'yí', strokeCount: 8),
      '史': RadicalInfo(radical: '史', meaning: 'history', pinyin: 'shǐ', strokeCount: 5),
      '小': RadicalInfo(radical: '小', meaning: 'small', pinyin: 'xiǎo', strokeCount: 3),
      '少': RadicalInfo(radical: '少', meaning: 'few', pinyin: 'shǎo', strokeCount: 4),
      '尧': RadicalInfo(radical: '尧', meaning: 'high', pinyin: 'yáo', strokeCount: 6),
      '考': RadicalInfo(radical: '考', meaning: 'examine', pinyin: 'kǎo', strokeCount: 6),
      '昭': RadicalInfo(radical: '昭', meaning: 'bright', pinyin: 'zhāo', strokeCount: 9),
      '肉': RadicalInfo(radical: '肉', meaning: 'meat', pinyin: 'ròu', strokeCount: 6),
      '者': RadicalInfo(radical: '者', meaning: 'person', pinyin: 'zhě', strokeCount: 8),
      '孰': RadicalInfo(radical: '孰', meaning: 'who', pinyin: 'shú', strokeCount: 11),
      '故': RadicalInfo(radical: '故', meaning: 'reason', pinyin: 'gù', strokeCount: 9),
      '任': RadicalInfo(radical: '任', meaning: 'duty', pinyin: 'rèn', strokeCount: 6),
      'X': RadicalInfo(radical: 'X', meaning: 'cross', pinyin: '', strokeCount: 2),
      'E': RadicalInfo(radical: 'E', meaning: 'seal form', pinyin: '', strokeCount: 3),
      '兴': RadicalInfo(radical: '兴', meaning: 'prosper/rise', pinyin: 'xīng', strokeCount: 6),
      '扌': RadicalInfo(radical: '扌', meaning: 'hand', pinyin: 'shǒu', strokeCount: 3),
      '呆': RadicalInfo(radical: '呆', meaning: 'dull/stupid', pinyin: 'dāi', strokeCount: 7),
      '舉': RadicalInfo(radical: '舉', meaning: 'raise (traditional)', pinyin: 'jǔ', strokeCount: 16),
    };
  }

  CharacterRadicalAnalysis? getRadicalAnalysis(String character) {
    // Production: removed debug print
    
    // Check cache first
    if (_cache.containsKey(character)) {
      // Production: removed debug print
      return _cache[character];
    }

    // Get decomposition from service
    final decomposition = _decompositionService.getDecomposition(character);
    // Production: removed debug print
    if (decomposition == null || decomposition.components.isEmpty) {
      // Production: removed debug print
      return null;
    }
    // Production: removed debug print

    // Get radical info for each component
    final radicals = <RadicalInfo>[];
    for (final component in decomposition.components) {
      final info = _radicalDatabase[component];
      if (info != null) {
        radicals.add(info);
      } else {
        // Create a basic entry for components not in our database
        radicals.add(RadicalInfo(
          radical: component,
          meaning: 'component',
          pinyin: '',
          strokeCount: 0,
        ));
      }
    }

    if (radicals.isEmpty) {
      return null;
    }

    // Generate hints based on etymology if available
    String? semanticHint;
    String? phoneticHint;
    
    final etymology = decomposition.etymology;
    if (etymology != null) {
      final type = etymology['type'] as String?;
      if (type == 'pictophonetic') {
        final semantic = etymology['semantic'] as String?;
        final phonetic = etymology['phonetic'] as String?;
        
        if (semantic != null) {
          final semanticInfo = _radicalDatabase[semantic];
          if (semanticInfo != null) {
            semanticHint = 'The ${semanticInfo.meaning} radical indicates the meaning';
          }
        }
        
        if (phonetic != null) {
          phoneticHint = 'The $phonetic component hints at the pronunciation';
        }
      } else if (type == 'ideographic' && etymology['hint'] != null) {
        semanticHint = etymology['hint'] as String;
      }
    }

    final analysis = CharacterRadicalAnalysis(
      character: character,
      radicals: radicals,
      semanticHint: semanticHint,
      phoneticHint: phoneticHint,
    );

    // Cache the result
    _cache[character] = analysis;
    return analysis;
  }

  bool get isInitialized => _isInitialized;
}