class HanziCharacter {
  final String character;
  final String pinyin;
  final List<String> meanings;
  final int strokeCount;
  final List<String> strokeOrder;
  final String? svgPath;
  final String? radical;
  final int frequency;

  HanziCharacter({
    required this.character,
    required this.pinyin,
    required this.meanings,
    required this.strokeCount,
    required this.strokeOrder,
    this.svgPath,
    this.radical,
    this.frequency = 0,
  });

  factory HanziCharacter.fromJson(Map<String, dynamic> json) {
    return HanziCharacter(
      character: json['character'],
      pinyin: json['pinyin'],
      meanings: List<String>.from(json['meanings'] ?? []),
      strokeCount: json['strokeCount'] ?? 0,
      strokeOrder: List<String>.from(json['strokeOrder'] ?? []),
      svgPath: json['svgPath'],
      radical: json['radical'],
      frequency: json['frequency'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'character': character,
      'pinyin': pinyin,
      'meanings': meanings,
      'strokeCount': strokeCount,
      'strokeOrder': strokeOrder,
      'svgPath': svgPath,
      'radical': radical,
      'frequency': frequency,
    };
  }
}

class CharacterSet {
  final String id;
  final String name;
  final String description;
  final List<String> characters;
  final String level; // HSK1, HSK2, etc.

  CharacterSet({
    required this.id,
    required this.name,
    required this.description,
    required this.characters,
    required this.level,
  });

  factory CharacterSet.fromJson(Map<String, dynamic> json) {
    return CharacterSet(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      characters: List<String>.from(json['characters']),
      level: json['level'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'characters': characters,
      'level': level,
    };
  }
}