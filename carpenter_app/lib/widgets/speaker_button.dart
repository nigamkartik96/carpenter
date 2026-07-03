import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tts_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// Persistent speaker icon that reads [text] aloud in the carpenter's
/// selected language (Section 4). Kept as a small icon button, consistent
/// in icon and position wherever it appears, so it's discoverable without
/// being in the way of someone who doesn't need it.
///
/// [text] should already be the *translated* string (i.e. pass
/// `app.tr('...')`, not the raw key) so what's spoken matches what's onscreen.
class SpeakerButton extends StatefulWidget {
  const SpeakerButton({super.key, required this.text, this.size = 22});
  final String text;
  final double size;

  @override
  State<SpeakerButton> createState() => _SpeakerButtonState();
}

class _SpeakerButtonState extends State<SpeakerButton> {
  bool _speaking = false;

  Future<void> _toggle(bool isHindi) async {
    if (_speaking) {
      await TtsService.instance.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }
    setState(() => _speaking = true);
    await TtsService.instance.speak(widget.text, isHindi: isHindi);
    if (mounted) setState(() => _speaking = false);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return IconButton(
      tooltip: app.tr('Play instructions'),
      icon: Icon(_speaking ? Icons.volume_up : Icons.volume_up_outlined, color: _speaking ? kPrimary : kMuted, size: widget.size),
      onPressed: () => _toggle(app.locale.isHindi),
    );
  }
}
