import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Design tokens. Every screen should pull colors/spacing from here rather
// than hardcoding one-off values, so the whole app reads as one product.
// ---------------------------------------------------------------------------

const kBgApp = Color(0xFFF4F1EC);
const kBgSurface = Colors.white;
const kBgSidebar = Color(0xFF1F1A16);

const kTextPrimary = Color(0xFF211C16);
const kTextSecondary = Color(0xFF5F5E5A);
const kTextMuted = Color(0xFF8A8782);
const kBorderSubtle = Color(0x1F000000); // black, 12% -- same as before

const kAccentPrimary = Color(0xFF378ADD);
const kAccentPrimaryDark = Color(0xFF185FA5);

// Status-system colors (solid, used with white text for guaranteed AA
// contrast -- see StatusBadge below).
const kStatusNeutral = Color(0xFF6B6862); // Submitted/New/Pending: muted gray, not yellow
const kStatusInfo = Color(0xFF2F6FED); // In progress
const kStatusAttention = Color(0xFFB4690E); // Needs action
const kStatusSuccess = Color(0xFF1A8754); // Complete
const kStatusClosed = Color(0xFF8A3A3A); // Rejected/withdrawn/closed -- muted red

// Audience tags (Gold/Silver/All on Notifications) use a distinct palette
// from status, so the two kinds of pill are never visually confusable.
const kAudienceColor = Color(0xFF6D4FC4);

// Backward-compatible aliases -- lots of existing screens reference these
// short names directly; keep them pointing at the token system above
// rather than rewriting every call site.
const kPrimary = kAccentPrimary;
const kPrimaryDark = kAccentPrimaryDark;
const kBg = kBgApp;
const kSuccess = kStatusSuccess;
const kWarning = kStatusAttention;
const kDanger = kStatusClosed;
const kMuted = kTextSecondary;

const double spaceXs = 4;
const double spaceSm = 8;
const double spaceMd = 12;
const double spaceLg = 16;
const double spaceXl = 24;
const double space2xl = 32;

const double kCardRadius = 10;
const kCardBorder = BorderSide(color: kBorderSubtle);

/// Shared yes/no confirmation dialog so every destructive or
/// hard-to-undo action (withdraw, status change, settings save, ...)
/// looks and behaves the same. Returns true only if the admin confirmed.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(cancelLabel)),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: danger ? TextButton.styleFrom(foregroundColor: kStatusClosed) : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result == true;
}

ThemeData buildAdminTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: kBgApp,
    colorScheme: ColorScheme.fromSeed(seedColor: kAccentPrimary),
    // Devanagari (Hindi offer titles etc.) needs a fallback that has those
    // glyphs -- Noto Sans is bundled with Flutter's default font set and
    // covers it, so mixed Hindi/English text renders cleanly side by side
    // instead of showing tofu boxes for the Hindi portion.
    fontFamilyFallback: const ['Noto Sans', 'Noto Sans Devanagari'],
    textTheme: const TextTheme(bodyMedium: TextStyle(color: kTextPrimary)),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kAccentPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kBgSurface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      isDense: true,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: kBgSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCardRadius), side: kCardBorder),
    ),
  );
}

/// Single source of truth for what color a status string maps to. Every
/// status pill in the app (orders, leads, carpenters, offers, gifts,
/// redemptions) routes through this -- no page should compute its own
/// status color.
Color statusColor(String status) {
  switch (status) {
    case 'Fulfilled':
    case 'Approved':
    case 'Delivered':
    case 'Converted':
    case 'Live':
      return kStatusSuccess;
    case 'Processing':
    case 'Contacted':
    case 'On store':
    case 'In store':
    case 'Dispatched':
    case 'Ordered':
    case 'Qualified':
      return kStatusInfo;
    case 'Submitted':
    case 'Pending':
    case 'New':
      return kStatusNeutral;
    case 'Rejected':
    case 'Withdrawn':
    case 'Closed':
      return kStatusClosed;
    default:
      return kStatusNeutral;
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
        Text(text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kTextPrimary)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: const TextStyle(color: kTextSecondary, fontSize: 13)),
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
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kTextPrimary));
  }
}

/// A "← Back to X" label for detail pages, used instead of relying on the
/// AppBar's bare back arrow so it's always clear where Back goes.
class BackLink extends StatelessWidget {
  const BackLink({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_back, size: 16, color: kAccentPrimary),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: kAccentPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Solid-background pill with white text -- guarantees AA contrast
/// regardless of which status color is picked, unlike the previous
/// low-contrast pastel-background + colored-text treatment.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = statusColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// Same pill shape as StatusBadge but a distinct color family, for
/// audience/tier tags (Gold/Silver/All) so they're never confused with a
/// status meaning even when they sit in the same row.
class AudienceBadge extends StatelessWidget {
  const AudienceBadge(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: kAudienceColor, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// Carpenter/admin avatar with a guaranteed fallback: CircleAvatar's plain
/// `backgroundImage` silently shows a broken-image glyph on a load error
/// with no way to react to it. This builds the image manually so a failed
/// load (404, bad URL, offline) falls back to initials-on-color instead.
class Avatar extends StatelessWidget {
  const Avatar({super.key, this.photoUrl, required this.name, this.radius = 24});
  final String? photoUrl;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: kAccentPrimary.withOpacity(0.12),
      child: Text(initials, style: TextStyle(color: kAccentPrimary, fontWeight: FontWeight.w700, fontSize: radius * 0.7)),
    );
    if (photoUrl == null || photoUrl!.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        photoUrl!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (context, child, progress) => progress == null ? child : fallback,
      ),
    );
  }
}

/// Icon-in-colored-chip + value + label, for Dashboard stat cards -- gives
/// stats more visual weight than plain text. [trend] is an optional small
/// secondary line (e.g. "+12% vs last week") reserved for when comparison
/// data is available; leaving it null renders identically to before.
class StatChip extends StatelessWidget {
  const StatChip({super.key, required this.label, required this.value, required this.icon, this.color = kAccentPrimary, this.trend, this.onTap});
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kBgSurface,
      borderRadius: BorderRadius.circular(kCardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kCardRadius),
        child: Container(
          padding: const EdgeInsets.all(spaceLg),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(kCardRadius), border: Border.all(color: kBorderSubtle)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kTextPrimary)),
                    if (trend != null) ...[
                      const SizedBox(height: 2),
                      Text(trend!, style: const TextStyle(color: kTextMuted, fontSize: 11)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Backward-compatible name for [StatChip] -- kept so existing call sites
/// (`Kpi(...)`) don't all need renaming.
class Kpi extends StatChip {
  const Kpi({super.key, required super.label, required super.value, required super.icon, super.onTap});
}

/// Compact icon + label tile for "Quick links"-style navigation grids --
/// unlike [Kpi], it carries no value/number, just a destination.
class LinkTile extends StatelessWidget {
  const LinkTile({super.key, required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kBgSurface,
      borderRadius: BorderRadius.circular(kCardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kCardRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(kCardRadius), border: Border.all(color: kBorderSubtle)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: kAccentPrimary),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextPrimary)),
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
      margin: const EdgeInsets.only(bottom: spaceSm),
      child: InkWell(borderRadius: BorderRadius.circular(kCardRadius), onTap: onTap, child: Padding(padding: const EdgeInsets.all(14), child: child)),
    );
  }
}

/// Grouped form container with a title -- used for the gift/offer dialogs,
/// settings cards, and the notification composer, so every form on the
/// site reads as the same kind of object.
class FormCard extends StatelessWidget {
  const FormCard({super.key, this.title, required this.children});
  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(spaceLg),
      decoration: BoxDecoration(color: kBgSurface, borderRadius: BorderRadius.circular(kCardRadius), border: Border.all(color: kBorderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[SubHeading(title!), const SizedBox(height: spaceMd)],
          ...children,
        ],
      ),
    );
  }
}

/// Label-above-field wrapper -- a persistent label reads more clearly as
/// "this is what goes here" than a Material floating label alone,
/// especially once a field already has a value.
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child, this.error});
  final String label;
  final Widget child;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextSecondary)),
        const SizedBox(height: 6),
        child,
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(error!, style: const TextStyle(fontSize: 11, color: kStatusClosed)),
        ],
      ],
    );
  }
}

/// Consistent "nothing here yet" treatment -- replaces the various bare
/// muted-text-only empty states scattered across screens.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: spaceXl),
      decoration: BoxDecoration(color: kBgSurface, borderRadius: BorderRadius.circular(kCardRadius), border: Border.all(color: kBorderSubtle)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: kTextMuted),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: kTextSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class StatusDropdown extends StatelessWidget {
  const StatusDropdown({super.key, required this.value, required this.options, required this.onChanged, this.enabled = true});
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  // When false, renders the same select-trigger shape but inert and
  // visibly grayed out -- so a column of these doesn't change shape
  // depending on whether a row has further actions available.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // DropdownButton throws a hard assertion error (crashing the whole
    // screen) if `value` isn't exactly one of `items`. Guard against any
    // status string that drifts from the expected list (e.g. a status a
    // different app version wrote) by including it as an extra option
    // instead of crashing.
    final safeOptions = options.contains(value) ? options : [value, ...options];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: enabled ? kBgSurface : const Color(0xFFF0EEE9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderSubtle),
      ),
      child: enabled
          ? DropdownButton<String>(
              value: value,
              underline: const SizedBox(),
              items: safeOptions.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: const TextStyle(fontSize: 13, color: kTextMuted)),
                const SizedBox(width: 4),
                const Icon(Icons.lock_outline, size: 14, color: kTextMuted),
              ],
            ),
    );
  }
}
