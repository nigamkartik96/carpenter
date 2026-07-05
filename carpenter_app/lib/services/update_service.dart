import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  final String version;
  final int buildNumber;
  final String downloadUrl;
  final String releaseNotes;
  final bool forceUpdate;

  UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.forceUpdate,
  });
}

class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('appVersion')
          .get();
      if (!doc.exists) return null;
      final d = doc.data()!;
      final remoteVersion = d['version'] as String? ?? '';
      final remoteBuild = (d['buildNumber'] is int)
          ? d['buildNumber'] as int
          : int.tryParse('${d['buildNumber']}') ?? 0;
      final downloadUrl = d['downloadUrl'] as String? ?? '';
      if (remoteVersion.isEmpty || downloadUrl.isEmpty) return null;

      final info = await PackageInfo.fromPlatform();
      final localBuild = int.tryParse(info.buildNumber) ?? 0;

      if (remoteBuild > localBuild) {
        return UpdateInfo(
          version: remoteVersion,
          buildNumber: remoteBuild,
          downloadUrl: downloadUrl,
          releaseNotes: d['releaseNotes'] as String? ?? '',
          forceUpdate: d['forceUpdate'] == true,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> launchDownload(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> showUpdateDialog(
      BuildContext context, UpdateInfo update) {
    return showDialog(
      context: context,
      barrierDismissible: !update.forceUpdate,
      builder: (ctx) => PopScope(
        canPop: !update.forceUpdate,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.system_update, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('Update available'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Version ${update.version} is available.'),
              if (update.releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(update.releaseNotes,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
              if (update.forceUpdate) ...[
                const SizedBox(height: 12),
                const Text('This update is required to continue using the app.',
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: Colors.red)),
              ],
            ],
          ),
          actions: [
            if (!update.forceUpdate)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Later'),
              ),
            FilledButton.icon(
              onPressed: () {
                UpdateService.instance.launchDownload(update.downloadUrl);
                if (!update.forceUpdate) Navigator.pop(ctx);
              },
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Update now'),
            ),
          ],
        ),
      ),
    );
  }
}
