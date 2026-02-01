class SetFolder {
  final String id;
  final String name;
  final List<String> setIds;
  final List<String> folderIds; // Child folder IDs
  final String? parentFolderId; // Parent folder ID (null for root folders)
  final DateTime createdAt;

  SetFolder({
    required this.id,
    required this.name,
    List<String>? setIds,
    List<String>? folderIds,
    this.parentFolderId,
    DateTime? createdAt,
  }) :
    setIds = setIds ?? [],
    folderIds = folderIds ?? [],
    createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'setIds': setIds,
      'folderIds': folderIds,
      'parentFolderId': parentFolderId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SetFolder.fromJson(Map<String, dynamic> json) {
    return SetFolder(
      id: json['id'],
      name: json['name'],
      setIds: List<String>.from(json['setIds'] ?? []),
      folderIds: List<String>.from(json['folderIds'] ?? []),
      parentFolderId: json['parentFolderId'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  SetFolder copyWith({
    String? name,
    List<String>? setIds,
    List<String>? folderIds,
    String? Function()? parentFolderId, // Use function to allow null assignment
  }) {
    return SetFolder(
      id: id,
      name: name ?? this.name,
      setIds: setIds ?? this.setIds,
      folderIds: folderIds ?? this.folderIds,
      parentFolderId: parentFolderId != null ? parentFolderId() : this.parentFolderId,
      createdAt: createdAt,
    );
  }

  // Check if this is a root folder (no parent)
  bool get isRoot => parentFolderId == null;

  // Get folder depth (0 for root, 1 for first level, etc.)
  int getDepth(List<SetFolder> allFolders) {
    if (isRoot) return 0;
    final parent = allFolders.firstWhere((f) => f.id == parentFolderId);
    return 1 + parent.getDepth(allFolders);
  }
}