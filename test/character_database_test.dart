import 'package:flutter_test/flutter_test.dart';
import 'package:zishu/services/character_database.dart';
import 'package:zishu/services/character_stroke_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('CharacterDatabase', () {
    test('should load characters 三 and 上 from full database', () async {
      final database = CharacterDatabase();
      final strokeService = CharacterStrokeService();
      
      // Initialize database
      await database.initialize();
      
      // Load specific characters
      await database.loadCharacters(['三', '上']);
      
      // Check if characters are available in stroke service
      final san = strokeService.getCharacterStroke('三');
      final shang = strokeService.getCharacterStroke('上');
      
      expect(san, isNotNull, reason: 'Character 三 should be loaded');
      expect(shang, isNotNull, reason: 'Character 上 should be loaded');
      
      if (san != null) {
        expect(san.strokes.length, 3, reason: '三 should have 3 strokes');
      }
      
      if (shang != null) {
        expect(shang.strokes.length, 3, reason: '上 should have 3 strokes');
      }
    });
  });
}