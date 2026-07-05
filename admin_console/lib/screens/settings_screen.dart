import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state.dart';
import '../widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AdminState>();
    return ListView(
      children: [
        const Heading('Settings', subtitle: 'Platform-wide rules used by both apps'),
        const SizedBox(height: 20),
        const SubHeading('Order points rule'),
        const SizedBox(height: 8),
        Text('How many points a carpenter earns per rupee spent, and the minimum points balance needed to redeem.', style: const TextStyle(color: kMuted, fontSize: 12)),
        const SizedBox(height: 10),
        _PointsRuleForm(app: app),
        const SizedBox(height: 24),
        const SubHeading('Lead points rule'),
        const SizedBox(height: 8),
        const Text('How many points a carpenter earns when a lead they submitted reaches each stage.', style: TextStyle(color: kMuted, fontSize: 12)),
        const SizedBox(height: 10),
        _LeadPointsRuleForm(app: app),
        const SizedBox(height: 24),
        const SubHeading('App version (OTA update)'),
        const SizedBox(height: 8),
        const Text('Set the latest APK version info. Carpenters will see an update prompt when their installed build is older.', style: TextStyle(color: kMuted, fontSize: 12)),
        const SizedBox(height: 10),
        _AppVersionForm(app: app),
      ],
    );
  }
}

class _PointsRuleForm extends StatefulWidget {
  const _PointsRuleForm({required this.app});
  final AdminState app;

  @override
  State<_PointsRuleForm> createState() => _PointsRuleFormState();
}

class _PointsRuleFormState extends State<_PointsRuleForm> {
  late final amount = TextEditingController(text: '${widget.app.pointRuleAmount}');
  late final points = TextEditingController(text: '${widget.app.pointRulePoints}');
  late final minRedeem = TextEditingController(text: '${widget.app.minRedeemPoints}');
  bool _edited = false;

  @override
  void didUpdateWidget(_PointsRuleForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_edited) {
      amount.text = '${widget.app.pointRuleAmount}';
      points.text = '${widget.app.pointRulePoints}';
      minRedeem.text = '${widget.app.minRedeemPoints}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          SizedBox(width: 120, child: TextField(controller: points, onChanged: (_) => _edited = true, decoration: const InputDecoration(labelText: 'Points'))),
          const Text('per ₹'),
          SizedBox(width: 120, child: TextField(controller: amount, onChanged: (_) => _edited = true, decoration: const InputDecoration(labelText: 'Amount spent'))),
          SizedBox(width: 160, child: TextField(controller: minRedeem, onChanged: (_) => _edited = true, decoration: const InputDecoration(labelText: 'Min points to redeem'))),
          ElevatedButton(
            onPressed: () async {
              final confirmed = await confirmDialog(
                context,
                title: 'Save points rule?',
                message: 'Carpenters will earn ${points.text} point(s) per ₹${amount.text} spent, and need ${minRedeem.text} points minimum to redeem. This applies immediately.',
              );
              if (!confirmed) return;
              _edited = false;
              await widget.app.setPointRule(int.tryParse(amount.text) ?? 100, int.tryParse(points.text) ?? 1, int.tryParse(minRedeem.text) ?? 500);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Points rule saved')));
            },
            child: const Text('Save rule'),
          ),
        ],
      ),
    );
  }
}

class _LeadPointsRuleForm extends StatefulWidget {
  const _LeadPointsRuleForm({required this.app});
  final AdminState app;

  @override
  State<_LeadPointsRuleForm> createState() => _LeadPointsRuleFormState();
}

class _LeadPointsRuleFormState extends State<_LeadPointsRuleForm> {
  // leadPointsQualified/Converted load asynchronously from Firestore, so
  // this widget can build before they arrive. Initializing the controllers
  // just once at first build risked showing a stale "0" and admins
  // re-saving that over a real rule -- so keep them in sync until the
  // admin actually starts typing.
  late final qualified = TextEditingController(text: '${widget.app.leadPointsQualified}');
  late final converted = TextEditingController(text: '${widget.app.leadPointsConverted}');
  bool _edited = false;

  @override
  void didUpdateWidget(_LeadPointsRuleForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_edited) {
      qualified.text = '${widget.app.leadPointsQualified}';
      converted.text = '${widget.app.leadPointsConverted}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          const Text('Award on:', style: TextStyle(fontSize: 13)),
          SizedBox(
            width: 140,
            child: TextField(
              controller: qualified,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => _edited = true,
              decoration: const InputDecoration(labelText: 'Qualified -> pts'),
            ),
          ),
          SizedBox(
            width: 140,
            child: TextField(
              controller: converted,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => _edited = true,
              decoration: const InputDecoration(labelText: 'Converted -> pts'),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final confirmed = await confirmDialog(
                context,
                title: 'Save lead points rule?',
                message: 'Leads reaching Qualified will earn ${qualified.text} pts, and Converted will earn ${converted.text} pts.',
              );
              if (!confirmed) return;
              _edited = false;
              await widget.app.setLeadPointsRule(qualifiedPoints: int.tryParse(qualified.text) ?? 0, convertedPoints: int.tryParse(converted.text) ?? 0);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lead points rule saved')));
            },
            child: const Text('Save rule'),
          ),
        ],
      ),
    );
  }
}

class _AppVersionForm extends StatefulWidget {
  const _AppVersionForm({required this.app});
  final AdminState app;

  @override
  State<_AppVersionForm> createState() => _AppVersionFormState();
}

class _AppVersionFormState extends State<_AppVersionForm> {
  late final version = TextEditingController(text: widget.app.appVersion);
  late final buildNumber = TextEditingController(text: '${widget.app.appBuildNumber}');
  late final downloadUrl = TextEditingController(text: widget.app.appDownloadUrl);
  late final releaseNotes = TextEditingController(text: widget.app.appReleaseNotes);
  late bool forceUpdate = widget.app.appForceUpdate;
  bool _edited = false;

  @override
  void didUpdateWidget(_AppVersionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_edited) {
      version.text = widget.app.appVersion;
      buildNumber.text = '${widget.app.appBuildNumber}';
      downloadUrl.text = widget.app.appDownloadUrl;
      releaseNotes.text = widget.app.appReleaseNotes;
      forceUpdate = widget.app.appForceUpdate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(width: 140, child: TextField(controller: version, onChanged: (_) => _edited = true, decoration: const InputDecoration(labelText: 'Version (e.g. 1.1.0)'))),
              SizedBox(width: 120, child: TextField(controller: buildNumber, onChanged: (_) => _edited = true, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Build number'))),
            ],
          ),
          const SizedBox(height: 10),
          TextField(controller: downloadUrl, onChanged: (_) => _edited = true, decoration: const InputDecoration(labelText: 'APK download URL (Firebase Storage or any public link)')),
          const SizedBox(height: 10),
          TextField(controller: releaseNotes, onChanged: (_) => _edited = true, maxLines: 2, decoration: const InputDecoration(labelText: 'Release notes (optional)')),
          const SizedBox(height: 10),
          Row(
            children: [
              Checkbox(
                value: forceUpdate,
                onChanged: (v) => setState(() { forceUpdate = v ?? false; _edited = true; }),
              ),
              const Text('Force update (users cannot skip)'),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              final v = version.text.trim();
              final b = int.tryParse(buildNumber.text) ?? 0;
              final url = downloadUrl.text.trim();
              if (v.isEmpty || b == 0 || url.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Version, build number, and download URL are required')));
                return;
              }
              final confirmed = await confirmDialog(
                context,
                title: 'Publish app version?',
                message: 'Carpenters with build < $b will be prompted to update to v$v.${forceUpdate ? ' This is a FORCED update — they cannot dismiss.' : ''}',
              );
              if (!confirmed) return;
              _edited = false;
              await widget.app.saveAppVersion(
                version: v,
                buildNumber: b,
                downloadUrl: url,
                releaseNotes: releaseNotes.text.trim(),
                forceUpdate: forceUpdate,
              );
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('App version published')));
            },
            child: const Text('Publish version'),
          ),
        ],
      ),
    );
  }
}
