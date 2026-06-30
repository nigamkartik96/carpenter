import 'package:flutter/material.dart';

const kPrimary = Color(0xFF378ADD);
const kPrimaryDark = Color(0xFF185FA5);
const kBg = Color(0xFFF4F1EC);
const kSuccess = Color(0xFF0F6E56);
const kWarning = Color(0xFF854F0B);
const kDanger = Color(0xFFA32D2D);
const kMuted = Color(0xFF5F5E5A);

ThemeData buildAdminTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: kBg,
    colorScheme: ColorScheme.fromSeed(seedColor: kPrimary),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      isDense: true,
    ),
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
    case 'On store':
    case 'In store':
    case 'Dispatched':
      return kPrimaryDark;
    case 'Pending':
    case 'New':
    case 'Ordered':
    case 'Submitted':
      return kWarning;
    case 'Rejected':
      return kDanger;
    default:
      return kMuted;
  }
}

class Heading extends StatelessWidget {
  const Heading(this.text, {super.key, this.subtitle});
  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: const TextStyle(color: kMuted, fontSize: 13)),
        ],
      ],
    );
  }
}

class SubHeading extends StatelessWidget {
  const SubHeading(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14));
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = statusColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class Kpi extends StatelessWidget {
  const Kpi({super.key, required this.label, required this.value, required this.icon, this.onTap});
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // No self-wrapping Expanded/Flexible here -- callers decide how to
    // size this (Expanded in a Row on wide screens, SizedBox in a Wrap
    // on narrow ones), since Expanded only works as a direct Flex child.
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text(label, style: TextStyle(color: kMuted, fontSize: 12)), Icon(icon, size: 16, color: kMuted)],
              ),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.black.withOpacity(0.08))),
      child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(14), child: child)),
    );
  }
}

class StatusDropdown extends StatelessWidget {
  const StatusDropdown({super.key, required this.value, required this.options, required this.onChanged});
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    // DropdownButton throws a hard assertion error (crashing the whole
    // screen) if `value` isn't exactly one of `items`. Guard against any
    // status string that drifts from the expected list (e.g. a status a
    // different app version wrote) by including it as an extra option
    // instead of crashing.
    final safeOptions = options.contains(value) ? options : [value, ...options];
    return DropdownButton<String>(
      value: value,
      underline: const SizedBox(),
      items: safeOptions.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
