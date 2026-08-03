import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'navigation.dart';

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
    } catch (e) {
      // Logged out, this reads config/appVersion without being signed in
      // and Firestore rules reject it. Logged out is also the one case
      // where nothing needs updating yet, so returning null is right --
      // but log it, because a silent null here is indistinguishable from
      // "already up to date".
      debugPrint('update check failed: $e');
      return null;
    }
  }

  // The prompt is offered once per app launch. Both AuthGate (resumed
  // session) and HomeShell (fresh login) ask, since neither covers the
  // other's path, and without this guard a resumed session would show
  // the dialog twice.
  static bool _prompted = false;

  /// Shows the update dialog through the app-wide navigator rather than a
  /// widget's own context. The check is asynchronous and routing to the
  /// dashboard unmounts whatever started it, so a `mounted` guard on the
  /// caller silently swallowed the prompt for every logged-in carpenter.
  static Future<void> promptIfAvailable() async {
    if (_prompted) return;
    final update = await instance.checkForUpdate();
    if (update == null) return;
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) return;
    _prompted = true;
    await showUpdateDialog(ctx, update);
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
