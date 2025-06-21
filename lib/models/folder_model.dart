class SetFolder {
  final String id;
  final String name;
  final List<String> setIds;
  final DateTime createdAt;
  
  SetFolder({
    required this.id,
    required this.name,
    List<String>? setIds,
    DateTime? createdAt,
  }) : 
    setIds = setIds ?? [],
    createdAt = createdAt ?? DateTime.now();
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'setIds': setIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  factory SetFolder.fromJson(Map<String, dynamic> json) {
    return SetFolder(
      id: json['id'],
      name: json['name'],
      setIds: List<String>.from(json['setIds'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
  
  SetFolder copyWith({
    String? name,
    List<String>? setIds,
  }) {
    return SetFolder(
      id: id,
      name: name ?? this.name,
      setIds: setIds ?? this.setIds,
      createdAt: createdAt,
    );
  }
}