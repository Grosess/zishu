import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/folder_model.dart';

class FolderService {
  static final FolderService _instance = FolderService._internal();
  factory FolderService() => _instance;
  FolderService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  // Get all folders
  Future<List<SetFolder>> getFolders() async {
    await initialize();
    final foldersJson = _prefs.getStringList('set_folders') ?? [];
    return foldersJson.map((json) => SetFolder.fromJson(jsonDecode(json))).toList();
  }

  // Create a new folder
  Future<SetFolder> createFolder(String name) async {
    await initialize();
    final folders = await getFolders();
    
    final newFolder = SetFolder(
      id: 'folder_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
    );
    
    folders.add(newFolder);
    await _saveFolders(folders);
    
    return newFolder;
  }

  // Update folder
  Future<void> updateFolder(SetFolder folder) async {
    await initialize();
    final folders = await getFolders();
    
    final index = folders.indexWhere((f) => f.id == folder.id);
    if (index != -1) {
      folders[index] = folder;
      await _saveFolders(folders);
    }
  }

  // Delete folder
  Future<void> deleteFolder(String folderId) async {
    await initialize();
    final folders = await getFolders();
    
    folders.removeWhere((f) => f.id == folderId);
    await _saveFolders(folders);
  }

  // Add set to folder
  Future<void> addSetToFolder(String setId, String folderId) async {
    await initialize();
    final folders = await getFolders();
    
    final folder = folders.firstWhere((f) => f.id == folderId);
    if (!folder.setIds.contains(setId)) {
      final updatedFolder = folder.copyWith(
        setIds: [...folder.setIds, setId],
      );
      await updateFolder(updatedFolder);
    }
  }

  // Remove set from folder
  Future<void> removeSetFromFolder(String setId, String folderId) async {
    await initialize();
    final folders = await getFolders();
    
    final folder = folders.firstWhere((f) => f.id == folderId);
    final updatedFolder = folder.copyWith(
      setIds: folder.setIds.where((id) => id != setId).toList(),
    );
    await updateFolder(updatedFolder);
  }

  // Get folder for a set
  Future<SetFolder?> getFolderForSet(String setId) async {
    await initialize();
    final folders = await getFolders();
    
    try {
      return folders.firstWhere((f) => f.setIds.contains(setId));
    } catch (e) {
      return null;
    }
  }

  // Move set to another folder (or remove from folder)
  Future<void> moveSetToFolder(String setId, String? newFolderId) async {
    await initialize();
    
    // First remove from any existing folder
    final currentFolder = await getFolderForSet(setId);
    if (currentFolder != null) {
      await removeSetFromFolder(setId, currentFolder.id);
    }
    
    // Then add to new folder if specified
    if (newFolderId != null) {
      await addSetToFolder(setId, newFolderId);
    }
  }

  // Save folders to storage
  Future<void> _saveFolders(List<SetFolder> folders) async {
    final foldersJson = folders.map((f) => jsonEncode(f.toJson())).toList();
    await _prefs.setStringList('set_folders', foldersJson);
  }
}