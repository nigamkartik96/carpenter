import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

const _imageExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.bmp', '.gif'};
const _pdfExtensions = {'.pdf'};
const _maxDimension = 1080;
const _jpegQuality = 70;

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
    final ext = filename.contains('.') ? filename.substring(filename.lastIndexOf('.')).toLowerCase() : '';
    final isImage = _imageExtensions.contains(ext);

    Uint8List uploadData = bytes;
    String uploadName = filename;

    if (isImage) {
      final compressed = _compressImage(bytes);
      if (compressed != null) {
        uploadData = compressed;
        final base = filename.contains('.') ? filename.substring(0, filename.lastIndexOf('.')) : filename;
        uploadName = '$base.jpg';
      }
    }

    final isPdf = _pdfExtensions.contains(ext);

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/auto/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(http.MultipartFile.fromBytes('file', uploadData, filename: uploadName));

    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode != 200) {
      throw Exception('Cloudinary upload failed (${response.statusCode}): $body');
    }
    final json = jsonDecode(body) as Map<String, dynamic>;
    final url = json['secure_url'] as String?;

    if (isPdf && url != null) {
      return _withPdfCompression(url);
    }
    return url;
  }

  /// Inserts Cloudinary's on-the-fly PDF optimization into the URL.
  /// `q_auto` recompresses embedded images at optimal quality,
  /// `fl_lossy` allows lossy compression on those images.
  /// Text and vectors stay untouched — only raster images inside
  /// the PDF are recompressed (same as Ghostscript /prepress).
  ///
  /// Example:
  ///   .../upload/v123/file.pdf  →  .../upload/q_auto,fl_lossy/v123/file.pdf
  static String _withPdfCompression(String url) {
    const marker = '/upload/';
    final i = url.indexOf(marker);
    if (i == -1) return url;
    final insertAt = i + marker.length;
    return '${url.substring(0, insertAt)}q_auto,fl_lossy/${url.substring(insertAt)}';
  }

  static Uint8List? _compressImage(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      var image = decoded;
      if (image.width > _maxDimension || image.height > _maxDimension) {
        if (image.width >= image.height) {
          image = img.copyResize(image, width: _maxDimension);
        } else {
          image = img.copyResize(image, height: _maxDimension);
        }
      }
      return Uint8List.fromList(img.encodeJpg(image, quality: _jpegQuality));
    } catch (_) {
      return null;
    }
  }
}
