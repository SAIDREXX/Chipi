import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class SpeechRecognitionService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  Future<void> startListening(
      List<String> phrases, List<String> responses) async {
    bool available = await _speech.initialize();
    if (available) {
      _speech.listen(onResult: (result) {
        String recognizedText = result.recognizedWords;
        for (int i = 0; i < phrases.length; i++) {
          if (recognizedText.contains(phrases[i])) {
            speak(responses[i]);
            break;
          }
        }
      });
    } else {}
  }

  Future<void> speak(String text) async {
    await _tts.setLanguage("es-MX");
    await _tts.setPitch(1.0);
    await _tts.speak(text);
  }

  void stopListening() {
    _speech.stop();
  }
}
