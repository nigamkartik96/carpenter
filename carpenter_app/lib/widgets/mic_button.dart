import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/speech_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// A mic icon that fills [controller] with speech-to-text results in the
/// carpenter's selected app language. Meant to sit as an [InputDecoration]
/// suffixIcon on any free-text field (Section 2: every text field should
/// offer voice input as an equally prominent alternative to typing).
///
/// Appends to whatever the user already typed rather than replacing it, so
/// switching between typing and speaking mid-entry doesn't lose text.
class MicButton extends StatefulWidget {
  const MicButton({super.key, required this.controller, this.onFinalResult});
  final TextEditingController controller;
  final ValueChanged<String>? onFinalResult;

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> {
  bool _listening = false;
  String _baseText = '';

  Future<void> _toggle(AppState app) async {
    if (_listening) {
      await SpeechService.instance.stop();
      setState(() => _listening = false);
      return;
    }
    _baseText = widget.controller.text;
    final started = await SpeechService.instance.listen(
      localeId: app.locale.isHindi ? 'hi_IN' : 'en_IN',
      onResult: (text, isFinal) {
        if (!mounted) return;
        final combined = _baseText.isEmpty ? text : '$_baseText $text';
        widget.controller.text = combined;
        widget.controller.selection = TextSelection.collapsed(offset: combined.length);
        if (isFinal) {
          setState(() => _listening = false);
          widget.onFinalResult?.call(combined);
        }
      },
    );
    if (!started) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(app.tr('Speech input not available on this device'))),
        );
      }
      return;
    }
    setState(() => _listening = true);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return IconButton(
      tooltip: app.tr(_listening ? 'Listening...' : 'Speak now'),
      icon: Icon(_listening ? Icons.mic : Icons.mic_none, color: _listening ? kDanger : kMuted),
      onPressed: () => _toggle(app),
    );
  }
}
