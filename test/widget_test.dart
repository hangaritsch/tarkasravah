import 'package:test/test.dart';
import 'package:tarkasravah/models/sutra.dart';

void main() {
  group('Sutra Model Tests', () {
    test('Sutra.fromJson parses JSON correctly', () {
      final jsonMap = {
        'id': 1,
        'sutra_number': '१',
        'title': 'Test Sutra',
        'sanskrit': 'निधाय हृदि विश्वेशं',
        'english_meaning': 'Having placed the Lord in the heart',
        'kannada_meaning': 'ವಿಶ್ವೇಶ್ವರನನ್ನು ಹೃದಯದಲ್ಲಿ ನೆನೆದು',
        'audio': 'audio_0.mp3'
      };

      final sutra = Sutra.fromJson(jsonMap);

      expect(sutra.id, 1);
      expect(sutra.sutraNumber, '१');
      expect(sutra.title, 'Test Sutra');
      expect(sutra.sanskrit, 'निधाय हृदि विश्वेशं');
      expect(sutra.englishMeaning, 'Having placed the Lord in the heart');
      expect(sutra.kannadaMeaning, 'ವಿಶ್ವೇಶ್ವರನನ್ನು ಹೃದಯದಲ್ಲಿ ನೆನೆದು');
      expect(sutra.audio, 'audio_0.mp3');
    });

    test('Sutra.toJson returns correct Map representation', () {
      final sutra = Sutra(
        id: 2,
        sutraNumber: '२',
        title: 'Another Sutra',
        sanskrit: 'सप्त पदार्थाः',
        englishMeaning: 'seven categories',
        kannadaMeaning: 'ಏಳು ಪದಾರ್ಥಗಳು',
        audio: 'audio_1.mp3',
      );

      final jsonMap = sutra.toJson();

      expect(jsonMap['id'], 2);
      expect(jsonMap['sutra_number'], '२');
      expect(jsonMap['title'], 'Another Sutra');
      expect(jsonMap['sanskrit'], 'सप्त पदार्थाः');
      expect(jsonMap['english_meaning'], 'seven categories');
      expect(jsonMap['kannada_meaning'], 'ಏಳು ಪದಾರ್ಥಗಳು');
      expect(jsonMap['audio'], 'audio_1.mp3');
    });
  });
}
