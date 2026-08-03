import 'package:flutter/material.dart';

/// The app's single navigator, wired to MaterialApp in main.dart.
///
/// Needed by anything that has to show a dialog or route from outside the
/// widget tree: a notification tap arriving while the app is closed, and
/// the update prompt, whose Firestore check outlives the widget that
/// started it (routing to the dashboard unmounts that widget, which is
/// exactly how the update prompt came to never appear at all).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
