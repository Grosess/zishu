/// Dictionary service for character definitions and pinyin
class CharacterDictionary {
  static final CharacterDictionary _instance = CharacterDictionary._internal();
  factory CharacterDictionary() => _instance;
  CharacterDictionary._internal();

  // Basic dictionary data - in production, load from a proper dictionary file
  final Map<String, CharacterInfo> _dictionary = {
    // Numbers - keeping these as basic fallback
    '一': CharacterInfo(
      character: '一',
      pinyin: 'yī',
      definition: 'one',
      tone: 1,
    ),
    '二': CharacterInfo(
      character: '二',
      pinyin: 'èr',
      definition: 'two',
      tone: 4,
    ),
    '三': CharacterInfo(
      character: '三',
      pinyin: 'sān',
      definition: 'three',
      tone: 1,
    ),
    '四': CharacterInfo(
      character: '四',
      pinyin: 'sì',
      definition: 'four',
      tone: 4,
    ),
    '五': CharacterInfo(
      character: '五',
      pinyin: 'wǔ',
      definition: 'five',
      tone: 3,
    ),
    '六': CharacterInfo(
      character: '六',
      pinyin: 'liù',
      definition: 'six',
      tone: 4,
    ),
    '七': CharacterInfo(
      character: '七',
      pinyin: 'qī',
      definition: 'seven',
      tone: 1,
    ),
    '八': CharacterInfo(
      character: '八',
      pinyin: 'bā',
      definition: 'eight',
      tone: 1,
    ),
    '九': CharacterInfo(
      character: '九',
      pinyin: 'jiǔ',
      definition: 'nine',
      tone: 3,
    ),
    '十': CharacterInfo(
      character: '十',
      pinyin: 'shí',
      definition: 'ten',
      tone: 2,
    ),
    '零': CharacterInfo(
      character: '零',
      pinyin: 'líng',
      definition: 'zero',
      tone: 2,
    ),
    '我': CharacterInfo(
      character: '我',
      pinyin: 'wǒ',
      definition: 'I, me',
      tone: 3,
    ),
    '你': CharacterInfo(
      character: '你',
      pinyin: 'nǐ',
      definition: 'you',
      tone: 3,
    ),
    '的': CharacterInfo(
      character: '的',
      pinyin: 'de',
      definition: 'possessive particle',
      tone: 0, // neutral tone
    ),
    '好': CharacterInfo(
      character: '好',
      pinyin: 'hǎo',
      definition: 'good, well',
      tone: 3,
    ),
    '生': CharacterInfo(
      character: '生',
      pinyin: 'shēng',
      definition: 'birth, life, raw',
      tone: 1,
    ),
    '日': CharacterInfo(
      character: '日',
      pinyin: 'rì',
      definition: 'sun, day',
      tone: 4,
    ),
    '人': CharacterInfo(
      character: '人',
      pinyin: 'rén',
      definition: 'person, people',
      tone: 2,
    ),
    '上': CharacterInfo(
      character: '上',
      pinyin: 'shàng',
      definition: 'up, above, on',
      tone: 4,
    ),
    '下': CharacterInfo(
      character: '下',
      pinyin: 'xià',
      definition: 'down, below, under',
      tone: 4,
    ),
    '不': CharacterInfo(
      character: '不',
      pinyin: 'bù',
      definition: 'not, no',
      tone: 4,
    ),
    '个': CharacterInfo(
      character: '个',
      pinyin: 'gè',
      definition: 'measure word',
      tone: 4,
    ),
    '们': CharacterInfo(
      character: '们',
      pinyin: 'men',
      definition: 'plural marker',
      tone: 0,
    ),
    '会': CharacterInfo(
      character: '会',
      pinyin: 'huì',
      definition: 'can, will, to meet',
      tone: 4,
    ),
    '住': CharacterInfo(
      character: '住',
      pinyin: 'zhù',
      definition: 'to live, to stay',
      tone: 4,
    ),
    '做': CharacterInfo(
      character: '做',
      pinyin: 'zuò',
      definition: 'to do, to make',
      tone: 4,
    ),
    '先': CharacterInfo(
      character: '先',
      pinyin: 'xiān',
      definition: 'first, before',
      tone: 1,
    ),
    '再': CharacterInfo(
      character: '再',
      pinyin: 'zài',
      definition: 'again, more',
      tone: 4,
    ),
    '写': CharacterInfo(
      character: '写',
      pinyin: 'xiě',
      definition: 'to write',
      tone: 3,
    ),
    '冷': CharacterInfo(
      character: '冷',
      pinyin: 'lěng',
      definition: 'cold',
      tone: 3,
    ),
    '几': CharacterInfo(
      character: '几',
      pinyin: 'jǐ',
      definition: 'how many, several',
      tone: 3,
    ),
    '出': CharacterInfo(
      character: '出',
      pinyin: 'chū',
      definition: 'to go out, to exit',
      tone: 1,
    ),
    '分': CharacterInfo(
      character: '分',
      pinyin: 'fēn',
      definition: 'minute, to divide',
      tone: 1,
    ),
    '前': CharacterInfo(
      character: '前',
      pinyin: 'qián',
      definition: 'front, before',
      tone: 2,
    ),
    '去': CharacterInfo(
      character: '去',
      pinyin: 'qù',
      definition: 'to go',
      tone: 4,
    ),
    '叫': CharacterInfo(
      character: '叫',
      pinyin: 'jiào',
      definition: 'to call, to be called',
      tone: 4,
    ),
    '吃': CharacterInfo(
      character: '吃',
      pinyin: 'chī',
      definition: 'to eat',
      tone: 1,
    ),
    '同': CharacterInfo(
      character: '同',
      pinyin: 'tóng',
      definition: 'same, together',
      tone: 2,
    ),
    '后': CharacterInfo(
      character: '后',
      pinyin: 'hòu',
      definition: 'back, after',
      tone: 4,
    ),
    '吗': CharacterInfo(
      character: '吗',
      pinyin: 'ma',
      definition: 'question particle',
      tone: 0,
    ),
    '听': CharacterInfo(
      character: '听',
      pinyin: 'tīng',
      definition: 'to listen, to hear',
      tone: 1,
    ),
    '呢': CharacterInfo(
      character: '呢',
      pinyin: 'ne',
      definition: 'question particle',
      tone: 0,
    ),
    '和': CharacterInfo(
      character: '和',
      pinyin: 'hé',
      definition: 'and, with',
      tone: 2,
    ),
    '哪': CharacterInfo(
      character: '哪',
      pinyin: 'nǎ',
      definition: 'which, where',
      tone: 3,
    ),
    '喂': CharacterInfo(
      character: '喂',
      pinyin: 'wèi',
      definition: 'hello (phone)',
      tone: 4,
    ),
    '喝': CharacterInfo(
      character: '喝',
      pinyin: 'hē',
      definition: 'to drink',
      tone: 1,
    ),
    '回': CharacterInfo(
      character: '回',
      pinyin: 'huí',
      definition: 'to return',
      tone: 2,
    ),
    '在': CharacterInfo(
      character: '在',
      pinyin: 'zài',
      definition: 'at, in, on',
      tone: 4,
    ),
    '坐': CharacterInfo(
      character: '坐',
      pinyin: 'zuò',
      definition: 'to sit',
      tone: 4,
    ),
    '块': CharacterInfo(
      character: '块',
      pinyin: 'kuài',
      definition: 'piece, yuan',
      tone: 4,
    ),
    '多': CharacterInfo(
      character: '多',
      pinyin: 'duō',
      definition: 'many, much',
      tone: 1,
    ),
    '大': CharacterInfo(
      character: '大',
      pinyin: 'dà',
      definition: 'big, large',
      tone: 4,
    ),
    '小': CharacterInfo(
      character: '小',
      pinyin: 'xiǎo',
      definition: 'small, little',
      tone: 3,
    ),
    '中': CharacterInfo(
      character: '中',
      pinyin: 'zhōng',
      definition: 'middle, center',
      tone: 1,
    ),
    '国': CharacterInfo(
      character: '国',
      pinyin: 'guó',
      definition: 'country, nation',
      tone: 2,
    ),
    '家': CharacterInfo(
      character: '家',
      pinyin: 'jiā',
      definition: 'home, family',
      tone: 1,
    ),
    '年': CharacterInfo(
      character: '年',
      pinyin: 'nián',
      definition: 'year',
      tone: 2,
    ),
    '月': CharacterInfo(
      character: '月',
      pinyin: 'yuè',
      definition: 'moon, month',
      tone: 4,
    ),
    '今': CharacterInfo(
      character: '今',
      pinyin: 'jīn',
      definition: 'today, now',
      tone: 1,
    ),
    '天': CharacterInfo(
      character: '天',
      pinyin: 'tiān',
      definition: 'sky, day, heaven',
      tone: 1,
    ),
    '快': CharacterInfo(
      character: '快',
      pinyin: 'kuài',
      definition: 'fast, quick, happy',
      tone: 4,
    ),
    '乐': CharacterInfo(
      character: '乐',
      pinyin: 'lè',
      definition: 'happy, joy',
      tone: 4,
    ),
    '出': CharacterInfo(
      character: '出',
      pinyin: 'chū',
      definition: 'go out, exit',
      tone: 1,
    ),
    '们': CharacterInfo(
      character: '们',
      pinyin: 'men',
      definition: 'plural marker',
      tone: 0,
    ),
    '租': CharacterInfo(
      character: '租',
      pinyin: 'zū',
      definition: 'rent, lease',
      tone: 1,
    ),
    '车': CharacterInfo(
      character: '车',
      pinyin: 'chē',
      definition: 'vehicle, car',
      tone: 1,
    ),
    '这': CharacterInfo(
      character: '这',
      pinyin: 'zhè',
      definition: 'this',
      tone: 4,
    ),
    '党': CharacterInfo(
      character: '党',
      pinyin: 'dǎng',
      definition: 'party, association',
      tone: 3,
    ),
    '共': CharacterInfo(
      character: '共',
      pinyin: 'gòng',
      definition: 'together, common',
      tone: 4,
    ),
    '和': CharacterInfo(
      character: '和',
      pinyin: 'hé',
      definition: 'and, with',
      tone: 2,
    ),
    '是': CharacterInfo(
      character: '是',
      pinyin: 'shì',
      definition: 'is, are, am',
      tone: 4,
    ),
    '有': CharacterInfo(
      character: '有',
      pinyin: 'yǒu',
      definition: 'have, has',
      tone: 3,
    ),
    '不': CharacterInfo(
      character: '不',
      pinyin: 'bù',
      definition: 'not, no',
      tone: 4,
    ),
    '在': CharacterInfo(
      character: '在',
      pinyin: 'zài',
      definition: 'at, in, on',
      tone: 4,
    ),
    '他': CharacterInfo(
      character: '他',
      pinyin: 'tā',
      definition: 'he, him',
      tone: 1,
    ),
    '她': CharacterInfo(
      character: '她',
      pinyin: 'tā',
      definition: 'she, her',
      tone: 1,
    ),
    '那': CharacterInfo(
      character: '那',
      pinyin: 'nà',
      definition: 'that',
      tone: 4,
    ),
    '个': CharacterInfo(
      character: '个',
      pinyin: 'gè',
      definition: 'individual, measure word',
      tone: 4,
    ),
    '上': CharacterInfo(
      character: '上',
      pinyin: 'shàng',
      definition: 'up, on, above',
      tone: 4,
    ),
    '下': CharacterInfo(
      character: '下',
      pinyin: 'xià',
      definition: 'down, below, under',
      tone: 4,
    ),
    '来': CharacterInfo(
      character: '来',
      pinyin: 'lái',
      definition: 'come',
      tone: 2,
    ),
    '去': CharacterInfo(
      character: '去',
      pinyin: 'qù',
      definition: 'go',
      tone: 4,
    ),
    '说': CharacterInfo(
      character: '说',
      pinyin: 'shuō',
      definition: 'say, speak',
      tone: 1,
    ),
    '会': CharacterInfo(
      character: '会',
      pinyin: 'huì',
      definition: 'can, will, meeting',
      tone: 4,
    ),
    '也': CharacterInfo(
      character: '也',
      pinyin: 'yě',
      definition: 'also, too',
      tone: 3,
    ),
    '很': CharacterInfo(
      character: '很',
      pinyin: 'hěn',
      definition: 'very',
      tone: 3,
    ),
    '都': CharacterInfo(
      character: '都',
      pinyin: 'dōu',
      definition: 'all, both',
      tone: 1,
    ),
    '吗': CharacterInfo(
      character: '吗',
      pinyin: 'ma',
      definition: 'question particle',
      tone: 0,
    ),
    '呢': CharacterInfo(
      character: '呢',
      pinyin: 'ne',
      definition: 'particle',
      tone: 0,
    ),
    '就': CharacterInfo(
      character: '就',
      pinyin: 'jiù',
      definition: 'then, just, immediately',
      tone: 4,
    ),
    '开': CharacterInfo(
      character: '开',
      pinyin: 'kāi',
      definition: 'open, start, begin',
      tone: 1,
    ),
    '始': CharacterInfo(
      character: '始',
      pinyin: 'shǐ',
      definition: 'begin, start',
      tone: 3,
    ),
    '作': CharacterInfo(
      character: '作',
      pinyin: 'zuò',
      definition: 'do, make, work',
      tone: 4,
    ),
    '业': CharacterInfo(
      character: '业',
      pinyin: 'yè',
      definition: 'business, occupation',
      tone: 4,
    ),
    '想': CharacterInfo(
      character: '想',
      pinyin: 'xiǎng',
      definition: 'think, want, miss',
      tone: 3,
    ),
    '要': CharacterInfo(
      character: '要',
      pinyin: 'yào',
      definition: 'want, need, will',
      tone: 4,
    ),
    '能': CharacterInfo(
      character: '能',
      pinyin: 'néng',
      definition: 'can, able to',
      tone: 2,
    ),
    '知': CharacterInfo(
      character: '知',
      pinyin: 'zhī',
      definition: 'know, knowledge',
      tone: 1,
    ),
    '道': CharacterInfo(
      character: '道',
      pinyin: 'dào',
      definition: 'way, path, say',
      tone: 4,
    ),
    '看': CharacterInfo(
      character: '看',
      pinyin: 'kàn',
      definition: 'look, see, watch',
      tone: 4,
    ),
    '时': CharacterInfo(
      character: '时',
      pinyin: 'shí',
      definition: 'time, hour',
      tone: 2,
    ),
    '间': CharacterInfo(
      character: '间',
      pinyin: 'jiān',
      definition: 'between, room',
      tone: 1,
    ),
    '让': CharacterInfo(
      character: '让',
      pinyin: 'ràng',
      definition: 'let, allow, yield',
      tone: 4,
    ),
    '给': CharacterInfo(
      character: '给',
      pinyin: 'gěi',
      definition: 'give, for, to',
      tone: 3,
    ),
    '学': CharacterInfo(
      character: '学',
      pinyin: 'xué',
      definition: 'study, learn',
      tone: 2,
    ),
    '习': CharacterInfo(
      character: '习',
      pinyin: 'xí',
      definition: 'practice, habit',
      tone: 2,
    ),
  };

  // Word definitions
  final Map<String, WordInfo> _words = {
    '生日': WordInfo(
      word: '生日',
      pinyin: 'shēng rì',
      definition: 'birthday',
      characters: ['生', '日'],
    ),
    '中国': WordInfo(
      word: '中国',
      pinyin: 'zhōng guó',
      definition: 'China',
      characters: ['中', '国'],
    ),
    '今天': WordInfo(
      word: '今天',
      pinyin: 'jīn tiān',
      definition: 'today',
      characters: ['今', '天'],
    ),
    '你好': WordInfo(
      word: '你好',
      pinyin: 'nǐ hǎo',
      definition: 'hello',
      characters: ['你', '好'],
    ),
    '大家': WordInfo(
      word: '大家',
      pinyin: 'dà jiā',
      definition: 'everyone',
      characters: ['大', '家'],
    ),
    '小人': WordInfo(
      word: '小人',
      pinyin: 'xiǎo rén',
      definition: 'petty person, villain',
      characters: ['小', '人'],
    ),
    '快乐': WordInfo(
      word: '快乐',
      pinyin: 'kuài lè',
      definition: 'happy, joyful',
      characters: ['快', '乐'],
    ),
    '生日快乐': WordInfo(
      word: '生日快乐',
      pinyin: 'shēng rì kuài lè',
      definition: 'happy birthday',
      characters: ['生', '日', '快', '乐'],
    ),
    '出生': WordInfo(
      word: '出生',
      pinyin: 'chū shēng',
      definition: 'be born, birth',
      characters: ['出', '生'],
    ),
    '出租车': WordInfo(
      word: '出租车',
      pinyin: 'chū zū chē',
      definition: 'taxi',
      characters: ['出', '租', '车'],
    ),
    '我们': WordInfo(
      word: '我们',
      pinyin: 'wǒ men',
      definition: 'we, us',
      characters: ['我', '们'],
    ),
    '开始': WordInfo(
      word: '开始',
      pinyin: 'kāi shǐ',
      definition: 'begin, start',
      characters: ['开', '始'],
    ),
    '作业': WordInfo(
      word: '作业',
      pinyin: 'zuò yè',
      definition: 'homework, assignment',
      characters: ['作', '业'],
    ),
    '知道': WordInfo(
      word: '知道',
      pinyin: 'zhī dào',
      definition: 'know, understand',
      characters: ['知', '道'],
    ),
    '时间': WordInfo(
      word: '时间',
      pinyin: 'shí jiān',
      definition: 'time, period',
      characters: ['时', '间'],
    ),
    '学习': WordInfo(
      word: '学习',
      pinyin: 'xué xí',
      definition: 'study, learn',
      characters: ['学', '习'],
    ),
  };

  CharacterInfo? getCharacterInfo(String character) {
    final info = _dictionary[character];
    if (info != null && _shouldFilterDefinition(info.definition)) {
      return null;
    }
    return info;
  }
  
  /// Check if a definition should be filtered out
  bool _shouldFilterDefinition(String definition) {
    final lowerDef = definition.toLowerCase();
    return lowerDef.contains('variant of') || 
           lowerDef.contains('used in') ||
           lowerDef.contains('see also') ||
           lowerDef.contains('same as');
  }

  WordInfo? getWordInfo(String word) {
    return _words[word];
  }

  bool isWord(String text) {
    return _words.containsKey(text);
  }

  List<String> splitIntoCharacters(String text) {
    // Check if it's a known word first
    if (_words.containsKey(text)) {
      return _words[text]!.characters;
    }
    // Otherwise split into individual characters
    return text.split('');
  }
  
  // Determine if an item is a single character or a word
  bool isMultiCharacterItem(String item) {
    return item.length > 1;
  }
}

class CharacterInfo {
  final String character;
  final String pinyin;
  final String definition;
  final int tone;

  CharacterInfo({
    required this.character,
    required this.pinyin,
    required this.definition,
    required this.tone,
  });
}

class WordInfo {
  final String word;
  final String pinyin;
  final String definition;
  final List<String> characters;

  WordInfo({
    required this.word,
    required this.pinyin,
    required this.definition,
    required this.characters,
  });
}