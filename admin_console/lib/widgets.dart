import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'models.dart';

// ---------------------------------------------------------------------------
// Design tokens. Every screen should pull colors/spacing from here rather
// than hardcoding one-off values, so the whole app reads as one product.
// ---------------------------------------------------------------------------

// The console is a multi-tenant product: it ships to businesses other than
// CarpenterHub, whose own apps each have their own look (carpenter_app is
// deliberately warm/orange -- do NOT mirror it here). So the surface system
// is chromatically silent and the only brand colour lives in the accent
// pair below. Re-theming for a new tenant means changing those two
// constants and nothing else.
//
// The neutrals carry a faint green cast picked up from the petrol accent,
// rather than the blue-gray every SaaS admin defaults to -- enough to feel
// chosen at full-page scale, not enough to read as a colour.
const kBgApp = Color(0xFFF4F6F5);
const kBgSurface = Colors.white;
const kBgSidebar = Color(0xFF10201F); // near-black, same petrol family

const kTextPrimary = Color(0xFF16201F);
const kTextSecondary = Color(0xFF5B6866); // 5.8:1 on white, 5.4:1 on kBgApp -- body-safe
const kTextMuted = Color(0xFF8A9694); // 3.1:1 -- decorative/large only, never body text
const kBorderSubtle = Color(0xFFDFE4E2);

// ---- Tenant accent -------------------------------------------------------
// The one place brand colour is allowed. Deep petrol: distinct from the
// blue/indigo default, and dark enough to carry white text at AA.
const kAccentPrimary = Color(0xFF0F4C51);
const kAccentPrimaryDark = Color(0xFF0A383C);

// Status fills, used with white text. Every value here is measured at >=4.5:1
// against white, so a solid pill is AA at any size.
//
// The previous green (#16A34A) and amber (#D97706) were "600"-weight shades
// assumed to be safe, but measured only 3.30:1 and 3.19:1 with white text --
// both failing AA despite the comment here claiming otherwise. They are now
// one step darker.
const kStatusNeutral = Color(0xFF5B6866); // Submitted/New/Pending -- rendered as a light pill, see StatusBadge
const kStatusInfo = Color(0xFF2563EB); // In progress -- 5.17:1
const kStatusAttention = Color(0xFFB45309); // Needs action -- 5.02:1
const kStatusSuccess = Color(0xFF15803D); // Complete -- 5.02:1
const kStatusClosed = Color(0xFFB91C1C); // Rejected/withdrawn/closed -- 6.47:1

// Audience tags (Gold/Silver/All on Notifications) use a distinct palette
// from status, so the two kinds of pill are never visually confusable.
const kAudienceColor = Color(0xFF6D28D9); // 7.10:1

// ---- Tints -------------------------------------------------------------
// Pale category backgrounds with a matching ink dark enough to read on them
// (each pair measured >=6.7:1). Screens were mixing seven ad-hoc pastels for
// this; these are the only ones.
const kTintSuccess = Color(0xFFE8F5EC);
const kTintAttention = Color(0xFFFDF3E3);
const kTintAudience = Color(0xFFF1EAFA);
const kTintAccent = Color(0xFFE7EEEE);

const kInkSuccess = Color(0xFF14532D);
const kInkAttention = Color(0xFF7C4A03);
const kInkAudience = Color(0xFF5B21B6);

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

// Two radii, not the seven that had accumulated (3/6/8/10/12/14/20).
// Containers get one value, controls inside them get the tighter one, and
// pills stay fully round.
const double kRadiusCard = 10;
const double kRadiusControl = 6;
const double kRadiusPill = 999;
const double kCardRadius = kRadiusCard; // legacy alias -- lots of call sites
const kCardBorder = BorderSide(color: kBorderSubtle);

// ---------------------------------------------------------------------------
// Type. IBM Plex across three roles: Sans for interface, Mono for every
// figure, Sans Devanagari as the fallback that carries Hindi content.
//
// The ramp is deliberately six steps with real distance between them. What
// was here before had nine sizes clustered between 10 and 15 -- 12px and
// 13px alone accounted for most of the interface, which is why nothing read
// as more important than anything else. 13 is gone; if something sat at 13
// it belongs at either 14 (content) or 12 (metadata).
// ---------------------------------------------------------------------------
const kFontSans = 'IBMPlexSans';
const kFontMono = 'IBMPlexMono';
const kFontFallback = ['IBMPlexSansDevanagari', 'Noto Sans Devanagari'];

/// Page titles. One per screen, and nothing else competes with it.
const kTypeDisplay = TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.15, letterSpacing: -0.5, color: kTextPrimary);

/// Card and dialog titles.
const kTypeTitle = TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: -0.2, color: kTextPrimary);

/// Section labels within a page.
const kTypeSection = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.3, color: kTextPrimary);

/// Default reading size for content.
const kTypeBody = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.45, color: kTextPrimary);

/// Supporting text: helper lines, timestamps, table metadata.
const kTypeMeta = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4, color: kTextSecondary);

/// Pills, eyebrows, column headers. Uppercase tracking is applied at the
/// call site where the label is genuinely a category rather than a word.
const kTypeMicro = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.3, letterSpacing: 0.2, color: kTextSecondary);

/// Every figure in the console -- money, points, counts, dates. Tabular so a
/// column of numbers lines up digit-for-digit when scanned vertically, which
/// on screens that are mostly numbers is the difference between a table and
/// a list of strings.
const kTypeFigure = TextStyle(fontFamily: kFontMono, fontSize: 14, fontWeight: FontWeight.w400, height: 1.4, color: kTextPrimary, fontFeatures: [FontFeature.tabularFigures()]);

/// The headline figure on a stat card.
const kTypeFigureLarge = TextStyle(fontFamily: kFontMono, fontSize: 24, fontWeight: FontWeight.w600, height: 1.2, letterSpacing: -0.5, color: kTextPrimary, fontFeatures: [FontFeature.tabularFigures()]);

/// Date + time, for things where "when exactly" matters -- a recorded party
/// payment has to be reconcilable against a cash book, and several can land
/// on the same day, so the date alone doesn't tell them apart.
String fmtDateTime(DateTime d) {
  final date = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  final time = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  return '$date · $time';
}

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
    // Use the dialog's own builder context (not the outer `context`
    // parameter) for the pop calls below. showDialog pushes onto the
    // root Navigator, but go_router's ShellRoute gives routed pages
    // their own nested Navigator -- popping with the outer context
    // resolved to that nested one instead, closing the underlying page
    // rather than the dialog.
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(cancelLabel)),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: danger ? TextButton.styleFrom(foregroundColor: kStatusClosed) : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result == true;
}

/// Single-button acknowledgement dialog (no cancel). Used to announce an
/// outcome the admin only needs to read, e.g. "order completed". Uses the
/// dialog's own builder context for the pop, for the same nested-Navigator
/// reason documented on [confirmDialog].
Future<void> infoDialog(
  BuildContext context, {
  required String title,
  required String message,
  String buttonLabel = 'OK',
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(buttonLabel)),
      ],
    ),
  );
}

void showPaymentDetailsDialog(BuildContext context, Carpenter c) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('${c.name} — Payment details'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _payRow(Icons.phone_outlined, 'Phone', c.mobile),
            if (c.upiId.isNotEmpty) _payRow(Icons.account_balance_wallet_outlined, 'UPI ID', c.upiId),
            if (c.bankName.isNotEmpty) _payRow(Icons.account_balance_outlined, 'Bank', c.bankName),
            if (c.qrUrl != null) ...[
              const SizedBox(height: 12),
              const Text('QR Code', style: TextStyle(fontSize: 12, color: kTextSecondary)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  c.qrUrl!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const SizedBox(width: 200, height: 200, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  errorBuilder: (_, __, ___) => Container(
                    width: 200,
                    height: 200,
                    alignment: Alignment.center,
                    color: kBgApp,
                    child: const Text('Could not load QR', style: TextStyle(color: kTextMuted, fontSize: 12)),
                  ),
                ),
              ),
            ],
            if (!c.hasPaymentInfo) const Text('No payment details added yet.', style: TextStyle(color: kTextMuted, fontSize: 13)),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
    ),
  );
}

Widget _payRow(IconData icon, String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 6),
  child: Row(
    children: [
      Icon(icon, size: 18, color: kTextSecondary),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: kTextSecondary)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    ],
  ),
);

ThemeData buildAdminTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: kBgApp,
    colorScheme: ColorScheme.fromSeed(seedColor: kAccentPrimary),
    fontFamily: kFontSans,
    // Hindi (offer titles and other carpenter-entered content) falls through
    // to Plex Sans Devanagari, so mixed Hindi/English lines render in one
    // designed family rather than showing tofu or dropping to a system face
    // mid-sentence.
    fontFamilyFallback: kFontFallback,
    textTheme: const TextTheme(
      bodyLarge: kTypeBody,
      bodyMedium: kTypeBody,
      bodySmall: kTypeMeta,
      titleLarge: kTypeTitle,
      titleMedium: kTypeSection,
      labelSmall: kTypeMicro,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kAccentPrimary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: kBorderSubtle,
        disabledForegroundColor: kTextMuted,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: spaceLg, vertical: 14),
        textStyle: const TextStyle(fontFamily: kFontSans, fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusControl)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kTextPrimary,
        side: const BorderSide(color: kBorderSubtle),
        padding: const EdgeInsets.symmetric(horizontal: spaceLg, vertical: 14),
        textStyle: const TextStyle(fontFamily: kFontSans, fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusControl)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kAccentPrimary,
        textStyle: const TextStyle(fontFamily: kFontSans, fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kBgSurface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: spaceMd, vertical: spaceMd),
      hintStyle: const TextStyle(color: kTextMuted, fontSize: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusControl), borderSide: const BorderSide(color: kBorderSubtle)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusControl), borderSide: const BorderSide(color: kBorderSubtle)),
      // A focused field is the one thing on screen accepting input; the
      // accent earns its keep here more than anywhere else.
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusControl), borderSide: const BorderSide(color: kAccentPrimary, width: 2)),
      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusControl), borderSide: const BorderSide(color: kBorderSubtle)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: kBgSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusCard), side: kCardBorder),
    ),
    dividerTheme: const DividerThemeData(color: kBorderSubtle, thickness: 1, space: 1),
    appBarTheme: const AppBarTheme(
      backgroundColor: kBgSurface,
      foregroundColor: kTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: kTypeTitle,
    ),
  );
}

/// Single source of truth for what color a status string maps to. Every
/// status pill in the app (orders, leads, carpenters, offers, gifts,
/// redemptions) routes through this -- no page should compute its own
/// status color.
Color statusColor(String status) {
  switch (status) {
    case 'Approved':
    case 'Delivered':
    case 'Converted':
    case 'Live':
      return kStatusSuccess;
    // Fulfilled is "ready, awaiting final delivery" -- distinct from both
    // Processing (in progress) and Delivered (done), so it gets its own
    // color rather than reusing the success green.
    case 'Fulfilled':
      return kStatusAttention;
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

/// Whether [status] is in the low-emphasis "neutral/pending" category --
/// used by StatusBadge to render those as a light pill instead of a solid
/// dark one, since a solid neutral-gray badge reads as "near-black" next
/// to the more saturated info/success/attention colors.
bool _isNeutralStatus(String status) => statusColor(status) == kStatusNeutral;

class Heading extends StatelessWidget {
  const Heading(this.text, {super.key, this.subtitle});
  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: kTypeDisplay),
        if (subtitle != null) ...[
          const SizedBox(height: spaceXs),
          Text(subtitle!, style: kTypeBody.copyWith(color: kTextSecondary)),
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
    return Text(text, style: kTypeSection);
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
      borderRadius: BorderRadius.circular(kRadiusControl),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: spaceXs, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_back, size: 16, color: kAccentPrimary),
            const SizedBox(width: spaceSm),
            Text(label, style: kTypeBody.copyWith(color: kAccentPrimary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Solid-background pill with white text -- guarantees AA contrast
/// regardless of which status color is picked, unlike the previous
/// low-contrast pastel-background + colored-text treatment. The neutral
/// category (Submitted/Pending/New) is the exception: a solid dark-gray
/// pill there reads as "near-black" next to the more saturated colors on
/// other statuses, so it gets a light-gray pill with dark text instead --
/// still meets contrast, just doesn't carry the same visual weight as an
/// active/colored status.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = statusColor(label);
    final neutral = _isNeutralStatus(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: neutral ? kBgApp : c, borderRadius: BorderRadius.circular(kRadiusPill), border: neutral ? Border.all(color: kBorderSubtle) : null),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
        style: kTypeMicro.copyWith(color: neutral ? kTextSecondary : Colors.white),
      ),
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
      decoration: BoxDecoration(color: kAudienceColor, borderRadius: BorderRadius.circular(kRadiusPill)),
      child: Text(label, style: kTypeMicro.copyWith(color: Colors.white)),
    );
  }
}

/// Carpenter tier (Bronze/Silver/Gold/Platinum) as a neutral outline pill.
///
/// Tiers used to render through [AudienceBadge], which painted all four the
/// same violet -- so the colour told you nothing the word wasn't already
/// saying, and it clashed with the audience tags on Notifications that use
/// that violet to mean something else. In this system colour is reserved
/// for state that needs attention; a tier is a standing attribute, so it
/// stays quiet and lets the status pill beside it carry the emphasis.
class TierBadge extends StatelessWidget {
  const TierBadge(this.tier, {super.key});
  final String tier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: kBgSurface,
        borderRadius: BorderRadius.circular(kRadiusPill),
        border: Border.all(color: kBorderSubtle),
      ),
      child: Text(tier, style: kTypeMicro),
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
                padding: const EdgeInsets.all(spaceSm),
                decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(kRadiusControl)),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Uppercase micro label above the figure: the number is
                    // the content, the label is just its key. Secondary, not
                    // muted -- muted is 3.06:1, and this label is the only
                    // thing telling you what the number counts.
                    Text(label.toUpperCase(), style: kTypeMicro.copyWith(letterSpacing: 0.6)),
                    const SizedBox(height: spaceXs),
                    Text(value, style: kTypeFigureLarge),
                    if (trend != null) ...[
                      const SizedBox(height: 2),
                      Text(trend!, style: kTypeMicro.copyWith(color: kTextMuted)),
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

/// Filter chip in the console's own vocabulary rather than Material's.
/// Selected reads as a filled accent pill; unselected as a plain outline --
/// the stock FilterChip's selected state was a faint tint with a checkmark,
/// which at a row of six was hard to pick out at a glance.
class StatusFilterChip extends StatelessWidget {
  const StatusFilterChip({super.key, required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? kAccentPrimary : kBgSurface,
      borderRadius: BorderRadius.circular(kRadiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadiusPill),
        // No `alignment` and no fixed height here: a Container with an
        // alignment expands to fill the loose constraints a Wrap hands it,
        // which turned a row of chips into full-width stacked bars.
        // Padding alone lets each chip hug its label.
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadiusPill),
            border: Border.all(color: selected ? kAccentPrimary : kBorderSubtle),
          ),
          child: Text(label, style: kTypeMeta.copyWith(color: selected ? Colors.white : kTextSecondary, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
        ),
      ),
    );
  }
}

/// A bordered dropdown for filter bars. Filters that are a single choice
/// from a list (date range, sort order) belong here rather than as a row of
/// chips: chips imply multi-select and, at four or five per group, turn the
/// bar into a wall of pills where nothing reads as the active state.
/// Chips are kept only for status, where seeing every option at a glance is
/// the point.
class FilterSelect<T> extends StatelessWidget {
  const FilterSelect({super.key, required this.value, required this.options, required this.onChanged, this.icon});
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: kBgSurface,
        borderRadius: BorderRadius.circular(kRadiusControl),
        border: Border.all(color: kBorderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          borderRadius: BorderRadius.circular(kRadiusControl),
          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: kTextSecondary),
          style: kTypeMeta.copyWith(color: kTextPrimary),
          items: [
            for (final (v, label) in options)
              DropdownMenuItem(
                value: v,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[Icon(icon, size: 14, color: kTextSecondary), const SizedBox(width: 6)],
                    Text(label, style: kTypeMeta.copyWith(color: kTextPrimary)),
                  ],
                ),
              ),
          ],
          onChanged: (v) => v == null ? null : onChanged(v),
        ),
      ),
    );
  }
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

/// Shared modal shell for "New X" creation forms (offers, gifts, ...) --
/// header (icon/title/optional subtitle/close), a scrollable body, and an
/// action bar, separated by whitespace alone rather than hard rules, so the
/// dialog reads as one soft floating card instead of stacked boxes.
/// Previously each of these dialogs built its own plain `Dialog` + `Padding`
/// from scratch with hardcoded spacing, which is why they didn't read as
/// part of the same product as the rest of the admin console.
class FormDialog extends StatelessWidget {
  const FormDialog({
    super.key,
    required this.title,
    required this.icon,
    required this.onClose,
    required this.children,
    required this.actions,
    this.subtitle,
    this.maxWidth = 520,
    this.maxHeight = 640,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onClose;
  final List<Widget> children;
  final List<Widget> actions;
  final double maxWidth;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      elevation: 12,
      shadowColor: Colors.black.withOpacity(0.25),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(spaceXl, spaceXl, spaceMd, spaceLg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: kAccentPrimary.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, size: 20, color: kAccentPrimary),
                  ),
                  const SizedBox(width: spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: kTextPrimary)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(subtitle!, style: const TextStyle(fontSize: 13, color: kTextSecondary)),
                        ],
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, size: 20), onPressed: onClose, splashRadius: 20),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(spaceXl, 0, spaceXl, spaceLg),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(spaceXl, spaceMd, spaceXl, spaceLg),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tap-to-upload image box -- shared visual treatment for every "add an
/// image" spot (gift photo, offer banner) so they read as the same kind of
/// control instead of each screen inventing its own flat gray box. Uses a
/// dashed border (the near-universal "drop zone" signal -- Notion, Figma,
/// GitHub avatar upload, etc. all use it) and brightens on hover so it
/// reads as interactive on desktop web, not just a static placeholder.
class ImagePickerBox extends StatefulWidget {
  const ImagePickerBox({
    super.key,
    required this.imageUrl,
    required this.uploading,
    required this.onTap,
    this.hint = 'Click to upload an image',
    this.height = 160,
  });

  final String? imageUrl;
  final bool uploading;
  final VoidCallback onTap;
  final String hint;
  final double height;

  @override
  State<ImagePickerBox> createState() => _ImagePickerBoxState();
}

class _ImagePickerBoxState extends State<ImagePickerBox> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.imageUrl != null;
    final active = _hovering && !widget.uploading;
    return MouseRegion(
      cursor: widget.uploading ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.uploading ? null : widget.onTap,
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: CustomPaint(
            // kBorderSubtle is too close in value to the box's own fill to
            // read as a border at rest -- needs a darker gray than the flat
            // 1px card borders used elsewhere, since this one has to work
            // as the *only* visual cue that the box is a drop zone.
            painter: hasImage ? null : _DashedBorderPainter(color: active ? kAccentPrimary : const Color(0xFFB0B5BD), radius: kCardRadius, strokeWidth: 1.75),
            child: Container(
              decoration: BoxDecoration(
                color: active ? kAccentPrimary.withOpacity(0.04) : kBgApp,
                borderRadius: BorderRadius.circular(kCardRadius),
                border: hasImage ? Border.all(color: kBorderSubtle) : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.uploading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                  : hasImage
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(widget.imageUrl!, fit: BoxFit.cover),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Material(
                                color: Colors.black54,
                                shape: const CircleBorder(),
                                child: IconButton(icon: const Icon(Icons.edit, color: Colors.white, size: 16), onPressed: widget.onTap),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: kAccentPrimary.withOpacity(0.10), shape: BoxShape.circle),
                                child: Icon(Icons.cloud_upload_outlined, color: kAccentPrimary, size: 24),
                              ),
                              const SizedBox(height: spaceSm),
                              Text(widget.hint, style: const TextStyle(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Even, evenly-spaced dashed rounded-rect border -- Flutter has no built-in
/// dashed border, and this is the near-universal signal for "drop a file
/// here" that a plain solid border doesn't communicate as clearly.
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius, this.dashWidth = 6, this.gapWidth = 4, this.strokeWidth = 1.5});
  final Color color;
  final double radius;
  final double dashWidth;
  final double gapWidth;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => oldDelegate.color != color || oldDelegate.radius != radius;
}

// ---------------------------------------------------------------------------
// Pagination
// ---------------------------------------------------------------------------

const _defaultPageSizes = [10, 25, 50, 100];

/// Controls for a paginated list: "Showing X–Y of Z", a page-size dropdown
/// and prev/next buttons. Stateless -- the owning screen holds page + perPage.
class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.total,
    required this.page,
    required this.perPage,
    required this.onPageChanged,
    required this.onPerPageChanged,
    this.pageSizes = _defaultPageSizes,
  });

  final int total;
  final int page;
  final int perPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPerPageChanged;
  final List<int> pageSizes;

  int get _totalPages => (total / perPage).ceil().clamp(1, 999999);

  @override
  Widget build(BuildContext context) {
    final start = total == 0 ? 0 : page * perPage + 1;
    final end = ((page + 1) * perPage).clamp(0, total);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: spaceSm),
      child: Row(
        children: [
          Text('Showing $start–$end of $total', style: const TextStyle(fontSize: 12, color: kTextSecondary)),
          const Spacer(),
          const Text('Per page ', style: TextStyle(fontSize: 12, color: kTextSecondary)),
          DropdownButton<int>(
            value: perPage,
            underline: const SizedBox(),
            isDense: true,
            items: pageSizes.map((n) => DropdownMenuItem(value: n, child: Text('$n', style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) {
              if (v != null) onPerPageChanged(v);
            },
          ),
          const SizedBox(width: spaceMd),
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: page > 0 ? () => onPageChanged(page - 1) : null,
            visualDensity: VisualDensity.compact,
            tooltip: 'Previous page',
          ),
          Text('${page + 1} / $_totalPages', style: const TextStyle(fontSize: 12, color: kTextSecondary)),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: page < _totalPages - 1 ? () => onPageChanged(page + 1) : null,
            visualDensity: VisualDensity.compact,
            tooltip: 'Next page',
          ),
        ],
      ),
    );
  }
}

/// Returns a page-slice of [items]. Clamps to the last valid page if [page]
/// overshoots (can happen when a filter shrinks the list while paged forward).
List<T> pageSlice<T>(List<T> items, int page, int perPage) {
  if (items.isEmpty) return [];
  final maxPage = ((items.length / perPage).ceil() - 1).clamp(0, 999999);
  final safePage = page.clamp(0, maxPage);
  final start = safePage * perPage;
  return items.sublist(start, (start + perPage).clamp(0, items.length));
}

// ---------------------------------------------------------------------------
// DataListView — consistent table component for all list screens
// ---------------------------------------------------------------------------

class DataListRow {
  final List<Widget> cells;
  final VoidCallback? onTap;
  const DataListRow({required this.cells, this.onTap});
}

class DataListView extends StatelessWidget {
  const DataListView({super.key, required this.columns, required this.rows});
  final List<(String label, {bool expanded})> columns;
  final List<DataListRow> rows;

  @override
  Widget build(BuildContext context) {
    Widget headerCell(String label, {bool expanded = false}) {
      final text = Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextSecondary));
      return expanded ? Expanded(child: text) : Padding(padding: const EdgeInsets.only(right: 16), child: text);
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: kBgSurface,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: kBorderSubtle),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kBorderSubtle))),
            child: Row(
              children: [
                for (final (label, :expanded) in columns) headerCell(label, expanded: expanded),
              ],
            ),
          ),
          for (var i = 0; i < rows.length; i++)
            InkWell(
              onTap: rows[i].onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: i < rows.length - 1 ? const BoxDecoration(border: Border(bottom: BorderSide(color: kBorderSubtle, width: 0.5))) : null,
                child: Row(children: rows[i].cells),
              ),
            ),
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
    // Same pill/box silhouette either way -- so the Update column never
    // changes shape row-to-row -- but the disabled state doesn't repeat
    // the status word (already shown in the adjacent Status column,
    // which made it read as a broken/empty dropdown) and uses a flat
    // fill instead of a border, so it visibly recedes next to the real
    // controls above/below it.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: enabled ? kBgSurface : const Color(0xFFEFEDE9),
        borderRadius: BorderRadius.circular(8),
        border: enabled ? Border.all(color: kBorderSubtle) : null,
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
          : const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 13, color: kTextMuted),
                SizedBox(width: 5),
                Text('Locked', style: TextStyle(fontSize: 12, color: kTextMuted)),
              ],
            ),
    );
  }
}
