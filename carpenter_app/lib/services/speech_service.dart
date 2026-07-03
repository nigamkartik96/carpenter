import 'package:speech_to_text/speech_to_text.dart';

/// Thin wrapper around `speech_to_text` for the voice-input mic buttons
/// scattered across forms (Section 2 of the accessibility redesign). Reuses
/// the RECORD_AUDIO permission the app already has for voice-note orders --
/// no separate permission needed.
///
/// One instance is shared app-wide (see [SpeechService.instance]) because
/// `speech_to_text` only supports a single active recognition session at a
/// time; a fresh `SpeechToText()` per field would just fail to initialize
/// while another field's session is still live.
class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  final SpeechToText _stt = SpeechToText();
  bool _available = false;
  bool _initTried = false;

  Future<bool> _ensureInit() async {
    if (_initTried) return _available;
    _initTried = true;
    try {
      _available = await _stt.initialize(onError: (_) {}, onStatus: (_) {});
    } catch (_) {
      _available = false;
    }
    return _available;
  }

  bool get isListening => _stt.isListening;

  /// Starts listening and streams partial/final results to [onResult] as
  /// they arrive. [localeId] follows BCP-47 (e.g. `hi_IN`, `en_IN`).
  /// Returns false immediately (without calling [onResult]) if speech
  /// recognition isn't available on this device.
  Future<bool> listen({
    required void Function(String text, bool isFinal) onResult,
    required String localeId,
  }) async {
    if (!await _ensureInit()) return false;
    await _stt.listen(
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      listenOptions: SpeechListenOptions(partialResults: true, cancelOnError: true, localeId: localeId),
    );
    return true;
  }

  Future<void> stop() => _stt.stop();
  Future<void> cancel() => _stt.cancel();
}
