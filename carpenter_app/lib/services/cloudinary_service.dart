import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Uploads files to Cloudinary using an unsigned upload preset, so the
/// app never needs the account's API secret embedded in it. The
/// `auto/upload` endpoint accepts images, PDFs, and audio/video and
/// picks the right resource type automatically.
class CloudinaryService {
  CloudinaryService._();
  static final CloudinaryService instance = CloudinaryService._();

  static const String cloudName = 'dotfhm5de';
  static const String uploadPreset = 'carpenterhub_uploads';

  /// [resourceType] picks which Cloudinary delivery pipeline handles the
  /// file: 'auto' (images/PDFs), or 'raw' for audio -- 'video' is often
  /// blocked by unsigned upload presets that only allow images, while
  /// 'raw' just stores the bytes verbatim and is rarely restricted.
  Future<String?> uploadBytes(Uint8List bytes, String filename, {String resourceType = 'auto'}) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload');
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
