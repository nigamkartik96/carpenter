import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';

// Dark "GitHub Dark"-style palette with a burnt-orange/amber accent,
// matching the CarpenterHub reference design.
const kBg = Color(0xFF0D1117);
const kCard = Color(0xFF161B22);
const kCard2 = Color(0xFF1C2128);
const kBorder = Color(0x33636E7B);
const kText = Color(0xFFE6EDF3);
const kMuted = Color(0xFF768390);
const kPrimary = Color(0xFFE8780C);
const kPrimaryLight = Color(0xFFF0A030);
const kPrimaryDark = Color(0xFFCC6B2C);
const kSuccess = Color(0xFF57AB5A);
const kWarning = Color(0xFFF0A030);
const kDanger = Color(0xFFE5534B);
const kInfo = Color(0xFF4493F8);
const kPurple = Color(0xFFA371F7);

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kBg,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(seedColor: kPrimary, brightness: Brightness.dark).copyWith(
      surface: kBg,
      primary: kPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kBg,
      foregroundColor: kText,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: kText, fontSize: 15, fontWeight: FontWeight.w600),
      iconTheme: IconThemeData(color: kText),
    ),
    textTheme: ThemeData.dark().textTheme.apply(bodyColor: kText, displayColor: kText),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: kCard2,
        disabledForegroundColor: kMuted,
        minimumSize: const Size.fromHeight(48),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kText,
        side: const BorderSide(color: kBorder),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: kPrimaryLight)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kCard,
      labelStyle: const TextStyle(color: kMuted, fontSize: 12),
      hintStyle: const TextStyle(color: kMuted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPrimaryDark)),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: kCard2, surfaceTintColor: Colors.transparent),
    cardTheme: const CardThemeData(color: kCard, surfaceTintColor: Colors.transparent),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: kCard.withOpacity(0.95),
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontSize: 10,
            color: states.contains(WidgetState.selected) ? kPrimaryLight : kMuted,
          )),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? kPrimaryLight : kMuted,
          )),
    ),
    snackBarTheme: const SnackBarThemeData(backgroundColor: kCard2, contentTextStyle: TextStyle(color: kText)),
    dividerTheme: const DividerThemeData(color: kBorder),
  );
}

Color statusColor(String status) {
  switch (status) {
    case 'Fulfilled':
    case 'Approved':
    case 'Delivered':
    case 'Converted':
      return kSuccess;
    case 'Processing':
    case 'Contacted':
    case 'Qualified':
    case 'On store':
    case 'In store':
      return kWarning;
    case 'Submitted':
    case 'Pending':
    case 'New':
    case 'Ordered':
      return kInfo;
    case 'Cancelled':
    case 'Rejected':
    case 'Closed':
      return kDanger;
    default:
      return kMuted;
  }
}

/// Icon shown alongside every status word so status is never conveyed by
/// color or text alone (target users may not read the word, or may not
/// distinguish the colors reliably).
IconData statusIcon(String status) {
  switch (status) {
    case 'Submitted':
    case 'Pending':
    case 'Ordered':
      return Icons.schedule;
    case 'Processing':
    case 'Contacted':
    case 'On store':
    case 'In store':
      return Icons.settings_outlined;
    case 'Fulfilled':
    case 'Approved':
      return Icons.inventory_2_outlined;
    case 'Delivered':
      return Icons.check_circle;
    case 'New':
      return Icons.auto_awesome;
    case 'Qualified':
      return Icons.thumb_up_outlined;
    case 'Converted':
      return Icons.check_circle;
    case 'Closed':
    case 'Cancelled':
    case 'Rejected':
      return Icons.cancel_outlined;
    default:
      return Icons.circle_outlined;
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final c = statusColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon(label), color: c, size: 13),
          const SizedBox(width: 4),
          Text(app.tr(label), style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: kCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: kBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(padding: const EdgeInsets.all(14), child: child),
      ),
    );
  }
}

class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = kPrimary,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kText)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: kMuted)),
        ],
      ),
    );
  }
}
