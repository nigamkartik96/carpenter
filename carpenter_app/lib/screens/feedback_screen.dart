import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../services/cloudinary_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/speaker_button.dart';

/// Lets a carpenter report a problem to the admin by typing, recording a
/// voice note, taking a photo, or any combination. The three inputs are
/// deliberately equal-weight rather than "text with attachments": a
/// carpenter who can't read or write comfortably should be able to send
/// something useful without touching the keyboard at all.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _text = TextEditingController();
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  bool recording = false;
  bool playing = false;
  bool uploadingAudio = false;
  bool uploadingImage = false;
  bool submitting = false;
  String? localAudioPath;
  String? audioUrl;
  String? imageUrl;
  String? error;

  bool get _busy => uploadingAudio || uploadingImage || submitting || recording;
  bool get _hasContent => _text.text.trim().isNotEmpty || audioUrl != null || imageUrl != null;

  @override
  void dispose() {
    _text.dispose();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final app = context.read<AppState>();
    try {
      if (!await _recorder.hasPermission()) {
        setState(() => error = app.tr('Microphone permission denied'));
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/feedback_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      setState(() {
        recording = true;
        localAudioPath = null;
        audioUrl = null;
        error = null;
      });
    } catch (e) {
      setState(() => error = '${app.tr('Could not start recording')}: $e');
    }
  }

  Future<void> _stopRecording() async {
    final app = context.read<AppState>();
    try {
      final path = await _recorder.stop();
      setState(() {
        recording = false;
        localAudioPath = path;
      });
      if (path == null) return;
      setState(() => uploadingAudio = true);
      final bytes = await File(path).readAsBytes();
      final url = await CloudinaryService.instance.uploadBytes(bytes, 'feedback.m4a', resourceType: 'raw');
      setState(() => audioUrl = url);
    } catch (e) {
      setState(() {
        recording = false;
        error = '${app.tr('Upload failed')}: $e';
      });
    } finally {
      if (mounted) setState(() => uploadingAudio = false);
    }
  }

  Future<void> _togglePlay() async {
    if (localAudioPath == null) return;
    if (playing) {
      await _player.stop();
      setState(() => playing = false);
      return;
    }
    await _player.play(DeviceFileSource(localAudioPath!));
    setState(() => playing = true);
    _player.onPlayerComplete.first.then((_) {
      if (mounted) setState(() => playing = false);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final app = context.read<AppState>();
    try {
      final picked = await ImagePicker().pickImage(source: source, maxWidth: 1080, imageQuality: 70);
      if (picked == null) return;
      setState(() {
        uploadingImage = true;
        error = null;
      });
      final bytes = await picked.readAsBytes();
      final url = await CloudinaryService.instance.uploadBytes(bytes, picked.name);
      setState(() => imageUrl = url);
    } catch (e) {
      setState(() => error = '${app.tr('Upload failed')}: $e');
    } finally {
      if (mounted) setState(() => uploadingImage = false);
    }
  }

  Future<void> _submit() async {
    final app = context.read<AppState>();
    if (!_hasContent) {
      setState(() => error = app.tr('Please write, record or attach something first'));
      return;
    }
    setState(() {
      submitting = true;
      error = null;
    });
    try {
      await app.submitFeedback(text: _text.text.trim(), audioUrl: audioUrl, imageUrl: imageUrl);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(app.tr('Sent to admin. Thank you!'))));
      Navigator.pop(context);
    } catch (e) {
      setState(() => error = '${app.tr('Could not send')}: $e');
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text(app.tr('Feedback')),
        actions: [
          SpeakerButton(
            text: app.tr(
              'Tell the admin about any problem you are facing. You can type it, record your voice, or send a photo.',
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(app.tr('Tell the admin about any problem you are facing.'), style: TextStyle(color: kMuted, fontSize: 13)),
          const SizedBox(height: 16),

          Text(app.tr('Write'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _text,
            maxLines: 4,
            decoration: InputDecoration(hintText: app.tr('Describe the problem...')),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),

          Text(app.tr('Voice note'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: uploadingAudio ? null : (recording ? _stopRecording : _startRecording),
                    icon: Icon(recording ? Icons.stop : Icons.mic, size: 18),
                    label: Text(recording ? app.tr('Stop recording') : app.tr('Record voice note')),
                  ),
                ),
                if (uploadingAudio)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(app.tr('Uploading...'), style: TextStyle(color: kMuted, fontSize: 12)),
                  ),
                if (audioUrl != null && !uploadingAudio) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: kSuccess, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(app.tr('Voice note ready'), style: const TextStyle(fontSize: 12))),
                      TextButton.icon(
                        onPressed: _togglePlay,
                        icon: Icon(playing ? Icons.stop : Icons.play_arrow, size: 16),
                        label: Text(playing ? app.tr('Stop') : app.tr('Play')),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(app.tr('Photo'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: uploadingImage ? null : () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined, size: 16),
                        label: Text(app.tr('Camera')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: uploadingImage ? null : () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_outlined, size: 16),
                        label: Text(app.tr('Gallery')),
                      ),
                    ),
                  ],
                ),
                if (uploadingImage)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(app.tr('Uploading...'), style: TextStyle(color: kMuted, fontSize: 12)),
                  ),
                if (imageUrl != null && !uploadingImage) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedImg(imageUrl!, height: 140, width: double.infinity),
                  ),
                ],
              ],
            ),
          ),

          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(error!, style: const TextStyle(color: kDanger, fontSize: 12)),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _busy ? null : _submit,
            child: Text(submitting ? app.tr('Sending...') : app.tr('Send to admin')),
          ),
        ],
      ),
    );
  }
}
