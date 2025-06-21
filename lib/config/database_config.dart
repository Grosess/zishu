/// Configuration for the character database
class DatabaseConfig {
  /// Whether to use the full MakeMeAHanzi database or the sample
  /// Force rebuild by changing comment
  static const bool USE_FULL_DATABASE = true;
  
  /// Path to the sample database (40 characters)
  static const String SAMPLE_DATABASE_PATH = 'database-sample/makemeahanzi-master/makemeahanzi-master/graphics.txt';
  
  /// Path to the full database (19k+ characters)
  /// Update this path when you have the full database
  static const String FULL_DATABASE_PATH = 'database/makemeahanzi-master/makemeahanzi-master/graphics.txt';
  
  /// Maximum characters to load at once for performance
  static const int MAX_BATCH_SIZE = 100;
  
  /// Whether to preload common characters on startup
  static const bool PRELOAD_COMMON_CHARACTERS = true;
  
  /// Common characters to preload
  static const List<String> COMMON_CHARACTERS = [
    // Most common 100 Chinese characters
    '的', '一', '是', '不', '了', '在', '人', '有', '我', '他',
    '这', '个', '们', '中', '来', '上', '大', '为', '和', '国',
    '地', '到', '以', '说', '时', '要', '就', '出', '会', '可',
    '也', '你', '对', '生', '能', '而', '子', '那', '得', '于',
    '着', '下', '自', '之', '年', '过', '发', '后', '作', '里',
    '用', '道', '行', '所', '然', '家', '种', '事', '成', '方',
    '多', '经', '么', '去', '法', '学', '如', '都', '同', '现',
    '当', '没', '动', '面', '起', '看', '定', '天', '分', '还',
    '进', '好', '小', '部', '其', '些', '主', '样', '理', '心',
    '她', '本', '前', '开', '但', '因', '只', '从', '想', '实',
  ];
  
  /// Get the current database path based on configuration
  static String get databasePath => 
    USE_FULL_DATABASE ? FULL_DATABASE_PATH : SAMPLE_DATABASE_PATH;
}