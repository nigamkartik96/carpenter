import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Design tokens. Every screen should pull colors/spacing from here rather
// than hardcoding one-off values, so the whole app reads as one product.
// ---------------------------------------------------------------------------

// Cool neutral gray, not the previous warm beige -- the beige+black-opacity
// combination was reading as dated/institutional ("hospital walls") rather
// than a modern product. This scale mirrors the neutral grays common across
// current SaaS admin tools (Linear, Vercel, etc.).
const kBgApp = Color(0xFFF7F8FA);
const kBgSurface = Colors.white;
const kBgSidebar = Color(0xFF14161A);

const kTextPrimary = Color(0xFF111827);
const kTextSecondary = Color(0xFF6B7280);
const kTextMuted = Color(0xFF9CA3AF);
const kBorderSubtle = Color(0xFFE5E7EB); // solid cool gray, not black-opacity -- crisper on both white and kBgApp

const kAccentPrimary = Color(0xFF4F46E5);
const kAccentPrimaryDark = Color(0xFF4338CA);

// Status-system colors (solid, used with white text for guaranteed AA
// contrast -- see StatusBadge below). Each is a standard "600"-weight shade
// from a widely-used design scale, chosen specifically because that weight
// is already tuned to clear AA contrast against white text.
const kStatusNeutral = Color(0xFF6B7280); // Submitted/New/Pending: muted gray, not yellow
const kStatusInfo = Color(0xFF2563EB); // In progress
const kStatusAttention = Color(0xFFD97706); // Needs action
const kStatusSuccess = Color(0xFF16A34A); // Complete
const kStatusClosed = Color(0xFFB91C1C); // Rejected/withdrawn/closed -- muted red, distinct from a live error state

// Audience tags (Gold/Silver/All on Notifications) use a distinct palette
// from status, so the two kinds of pill are never visually confusable.
const kAudienceColor = Color(0xFF7C3AED);

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

const double kCardRadius = 12;
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
      decoration: BoxDecoration(color: neutral ? const Color(0xFFE7E5E1) : c, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
        style: TextStyle(color: neutral ? kTextSecondary : Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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
