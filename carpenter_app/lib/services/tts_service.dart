import 'package:flutter_tts/flutter_tts.dart';

/// On-device text-to-speech for the audio-guidance feature (Section 4).
///
/// The spec asks for "pre-recorded Hindi audio" -- this app has no way to
/// produce real human voice recordings, so synthesized on-device TTS is
/// used instead: free, no audio assets to manage, and works for any
/// string already in [hiStrings] without needing a matching recording.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _configured = false;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    _configured = true;
    await _tts.setSpeechRate(0.42); // slower than default -- easier to follow for a first-time listener
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> speak(String text, {required bool isHindi}) async {
    await _ensureConfigured();
    await _tts.setLanguage(isHindi ? 'hi-IN' : 'en-IN');
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}
