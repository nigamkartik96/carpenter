import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';

String hashPin(String pin) => sha256.convert(utf8.encode(pin)).toString();

class _PinDots extends StatelessWidget {
  const _PinDots({required this.filled});
  final int filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) => Container(
        width: 18,
        height: 18,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: i < filled ? kPrimary : Colors.transparent,
          border: Border.all(color: i < filled ? kPrimary : kBorder, width: 2),
        ),
      )),
    );
  }
}

class _PinKeypad extends StatelessWidget {
  const _PinKeypad({required this.onDigit, required this.onDelete});
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    Widget key(String label, {VoidCallback? onTap, Widget? child}) => Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 56,
              alignment: Alignment.center,
              child: child ?? Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: kText)),
            ),
          ),
        ),
      ),
    );

    return Column(
      children: [
        for (final row in [['1','2','3'], ['4','5','6'], ['7','8','9']])
          Row(children: row.map((d) => key(d, onTap: () => onDigit(d))).toList()),
        Row(children: [
          key('', onTap: null),
          key('0', onTap: () => onDigit('0')),
          key('', onTap: onDelete, child: const Icon(Icons.backspace_outlined, color: kMuted)),
        ]),
      ],
    );
  }
}

/// Full-screen PIN entry used by SetupPinScreen and ChangePinScreen.
class _PinEntryPage extends StatefulWidget {
  const _PinEntryPage({required this.title, required this.subtitle, this.onCompleted});
  final String title;
  final String subtitle;
  final ValueChanged<String>? onCompleted;

  @override
  State<_PinEntryPage> createState() => _PinEntryPageState();
}

class _PinEntryPageState extends State<_PinEntryPage> {
  String _pin = '';
  String? _error;

  void _addDigit(String d) {
    if (_pin.length >= 4) return;
    setState(() { _pin += d; _error = null; });
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), () {
        widget.onCompleted?.call(_pin);
      });
    }
  }

  void _delete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void reset([String? error]) {
    setState(() { _pin = ''; _error = error; });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 2),
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: kPrimary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_outline, color: kPrimary, size: 28),
        ),
        const SizedBox(height: 16),
        Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kText)),
        const SizedBox(height: 6),
        Text(widget.subtitle, style: const TextStyle(color: kMuted, fontSize: 13), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        _PinDots(filled: _pin.length),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, style: const TextStyle(color: kDanger, fontSize: 12)),
          ),
        const Spacer(flex: 1),
        _PinKeypad(onDigit: _addDigit, onDelete: _delete),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Initial PIN setup screen (used for first-time setup and after admin reset).
/// When [canSkip] is true, the user can dismiss without setting a PIN.
class SetupPinScreen extends StatefulWidget {
  const SetupPinScreen({super.key, this.canSkip = true, this.onDone});
  final bool canSkip;
  final VoidCallback? onDone;

  @override
  State<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends State<SetupPinScreen> {
  String? _firstPin;
  bool _saving = false;
  final _enterKey = GlobalKey<_PinEntryPageState>();
  final _confirmKey = GlobalKey<_PinEntryPageState>();

  void _onFirstPinEntered(String pin) {
    setState(() => _firstPin = pin);
  }

  Future<void> _onConfirmPinEntered(String pin) async {
    if (pin != _firstPin) {
      _confirmKey.currentState?.reset(context.read<AppState>().tr('PINs do not match. Try again.'));
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AppState>().setPin(pin);
      if (mounted) {
        widget.onDone?.call();
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _confirmKey.currentState?.reset(context.read<AppState>().tr('Could not save PIN. Try again.'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return PopScope(
      canPop: widget.canSkip,
      child: Scaffold(
        appBar: AppBar(
          title: Text(app.tr('Set up PIN')),
          automaticallyImplyLeading: widget.canSkip,
          actions: [
            if (widget.canSkip)
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(app.tr('Skip')),
              ),
          ],
        ),
        body: _saving
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _firstPin == null
                    ? _PinEntryPage(
                        key: _enterKey,
                        title: app.tr('Create a 4-digit PIN'),
                        subtitle: app.tr('This PIN will be used to quickly access your account'),
                        onCompleted: _onFirstPinEntered,
                      )
                    : _PinEntryPage(
                        key: _confirmKey,
                        title: app.tr('Confirm your PIN'),
                        subtitle: app.tr('Enter the same PIN again to confirm'),
                        onCompleted: _onConfirmPinEntered,
                      ),
              ),
      ),
    );
  }
}

/// Change PIN screen — verifies current PIN first, then sets a new one.
class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

enum _ChangePinStep { verifyCurrent, enterNew, confirmNew }

class _ChangePinScreenState extends State<ChangePinScreen> {
  _ChangePinStep _step = _ChangePinStep.verifyCurrent;
  String? _newPin;
  bool _saving = false;
  final _verifyKey = GlobalKey<_PinEntryPageState>();
  final _newKey = GlobalKey<_PinEntryPageState>();
  final _confirmKey = GlobalKey<_PinEntryPageState>();

  void _onVerify(String pin) {
    final app = context.read<AppState>();
    if (hashPin(pin) != app.pinHash) {
      _verifyKey.currentState?.reset(app.tr('Incorrect PIN'));
      return;
    }
    setState(() => _step = _ChangePinStep.enterNew);
  }

  void _onNewPin(String pin) {
    setState(() { _newPin = pin; _step = _ChangePinStep.confirmNew; });
  }

  Future<void> _onConfirm(String pin) async {
    final app = context.read<AppState>();
    if (pin != _newPin) {
      _confirmKey.currentState?.reset(app.tr('PINs do not match. Try again.'));
      return;
    }
    setState(() => _saving = true);
    try {
      await app.setPin(pin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(app.tr('PIN changed successfully'))));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _confirmKey.currentState?.reset(app.tr('Could not save PIN. Try again.'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(app.tr('Change PIN'))),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: switch (_step) {
                _ChangePinStep.verifyCurrent => _PinEntryPage(
                  key: _verifyKey,
                  title: app.tr('Enter current PIN'),
                  subtitle: app.tr('Verify your identity before changing PIN'),
                  onCompleted: _onVerify,
                ),
                _ChangePinStep.enterNew => _PinEntryPage(
                  key: _newKey,
                  title: app.tr('Create a new PIN'),
                  subtitle: app.tr('Enter a new 4-digit PIN'),
                  onCompleted: _onNewPin,
                ),
                _ChangePinStep.confirmNew => _PinEntryPage(
                  key: _confirmKey,
                  title: app.tr('Confirm your PIN'),
                  subtitle: app.tr('Enter the same PIN again to confirm'),
                  onCompleted: _onConfirm,
                ),
              },
            ),
    );
  }
}

/// Unskippable screen shown when the admin has triggered a PIN or password
/// reset. The user cannot proceed until they complete the required setup.
class ForceResetScreen extends StatefulWidget {
  const ForceResetScreen({super.key, required this.resetPin, required this.resetPassword});
  final bool resetPin;
  final bool resetPassword;

  @override
  State<ForceResetScreen> createState() => _ForceResetScreenState();
}

class _ForceResetScreenState extends State<ForceResetScreen> {
  late bool _needsPin;
  late bool _needsPassword;

  @override
  void initState() {
    super.initState();
    _needsPin = widget.resetPin;
    _needsPassword = widget.resetPassword;
  }

  bool get _allDone => !_needsPin && !_needsPassword;

  void _checkDone() {
    if (_allDone && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: kWarning.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.security, color: kWarning, size: 34),
                ),
                const SizedBox(height: 18),
                Text(app.tr('Security update required'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  app.tr('The admin has requested you to update your security settings. Please complete the following to continue.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kMuted, fontSize: 13),
                ),
                const SizedBox(height: 24),
                if (_needsPassword) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _resetPassword(context, app),
                      icon: const Icon(Icons.password),
                      label: Text(app.tr('Set new password')),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_needsPin) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(builder: (_) => const SetupPinScreen(canSkip: false)),
                        );
                        if (result == true && mounted) {
                          setState(() => _needsPin = false);
                          _checkDone();
                        }
                      },
                      icon: const Icon(Icons.pin),
                      label: Text(app.tr('Set up PIN')),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (!_needsPin && !_needsPassword)
                  const Icon(Icons.check_circle, color: kSuccess, size: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resetPassword(BuildContext context, AppState app) async {
    final controller = TextEditingController();
    final confirmController = TextEditingController();
    String? error;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(app.tr('Set new password')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                obscureText: true,
                decoration: InputDecoration(labelText: app.tr('New password')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: InputDecoration(labelText: app.tr('Confirm password')),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!, style: const TextStyle(color: kDanger, fontSize: 12)),
                ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isEmpty || controller.text.length < 6) {
                  setDialogState(() => error = app.tr('Password must be at least 6 characters'));
                  return;
                }
                if (controller.text != confirmController.text) {
                  setDialogState(() => error = app.tr('Passwords do not match'));
                  return;
                }
                try {
                  await app.resetPasswordTo(controller.text);
                  if (ctx.mounted) Navigator.of(ctx).pop(true);
                } catch (e) {
                  setDialogState(() => error = app.tr('Could not update password. Try again.'));
                }
              },
              child: Text(app.tr('Save')),
            ),
          ],
        ),
      ),
    );
    if (result == true && mounted) {
      setState(() => _needsPassword = false);
      _checkDone();
    }
  }
}
