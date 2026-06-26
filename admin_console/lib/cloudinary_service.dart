import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Uploads files to Cloudinary using an unsigned upload preset, so the
/// admin console never needs the account's API secret embedded in it.
/// The `auto/upload` endpoint accepts images, PDFs, and audio/video and
/// picks the right resource type automatically.
class CloudinaryService {
  CloudinaryService._();
  static final CloudinaryService instance = CloudinaryService._();

  static const String cloudName = 'dotfhm5de';
  static const String uploadPreset = 'carpenterhub_uploads';

  Future<String?> uploadBytes(Uint8List bytes, String filename) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/auto/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode != 200) {
      throw Exception('Cloudinary upload failed (${response.statusCode}): $body');
    }
    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['secure_url'] as String?;
  }
}
