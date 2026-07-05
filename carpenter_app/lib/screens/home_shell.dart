import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/speaker_button.dart';
import 'order_screens.dart';
import 'rewards_screens.dart';
import 'profile_screens.dart';

/// Bottom-nav shell: Home, Orders, Gifts, Profile.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pages = [
      const DashboardScreen(),
      const OrderHistoryScreen(embedded: true),
      const GiftStoreScreen(embedded: true),
      const ProfileScreen(embedded: true),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (app.lastError != null)
              Container(
                width: double.infinity,
                color: kDanger.withOpacity(0.15),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: kDanger, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(app.lastError!, style: const TextStyle(color: kDanger, fontSize: 11))),
                    GestureDetector(onTap: app.clearError, child: const Icon(Icons.close, size: 14, color: kDanger)),
                  ],
                ),
              ),
            Expanded(child: pages[_index]),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: app.tr('Home')),
          NavigationDestination(icon: const Icon(Icons.list_alt_outlined), selectedIcon: const Icon(Icons.list_alt), label: app.tr('Orders')),
          NavigationDestination(icon: const Icon(Icons.card_giftcard_outlined), selectedIcon: const Icon(Icons.card_giftcard), label: app.tr('Gifts')),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: app.tr('Profile')),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 21,
              // Neutral fixed background, not a translucent orange tint --
              // opacity-composited-over-unknown-background makes contrast
              // impossible to guarantee, and orange is reserved for CTAs.
              backgroundColor: kCard2,
              child: app.photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        app.photoUrl!,
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Text(app.initials, style: const TextStyle(color: kPrimaryDark, fontWeight: FontWeight.w600)),
                      ),
                    )
                  : Text(app.initials, style: const TextStyle(color: kPrimaryDark, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.tr('Welcome back'), style: const TextStyle(fontSize: 11, color: kMuted, fontFamily: 'monospace')),
                  Text(app.carpenterName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kText)),
                ],
              ),
            ),
            SpeakerButton(
              text: app.tr(
                'This is your home screen. You can see your points here. To place a new order, press the "Create order" button below.',
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () => Navigator.pushNamed(context, '/notifications'),
                  icon: const Icon(Icons.notifications_outlined, color: kText),
                ),
                if (app.unreadCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                      child: Text(
                        app.unreadCount > 9 ? '9+' : '${app.unreadCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: kOnPrimary, fontSize: 9, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          // Was a full orange gradient -- orange is reserved for "the
          // button to press" now, not decorative card fills, so this is a
          // neutral surface with the brand color kept only as a small
          // accent on the trophy icon.
          decoration: BoxDecoration(
            color: kCard,
            border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app.tr('Redeemable Points'), style: const TextStyle(fontSize: 11, color: kMuted, fontFamily: 'monospace')),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('${app.points}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: kText)),
                            const SizedBox(width: 6),
                            Text(app.tr('pts'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.emoji_events_outlined, color: kPrimaryDark, size: 32),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app.tr('Total Points'), style: const TextStyle(fontSize: 10, color: kMuted, fontFamily: 'monospace')),
                        Text('${app.totalPoints} ${app.tr('pts')}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kText)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pushNamed(context, '/points'),
                      child: Text(app.tr('Activity')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/redeem'),
                      child: Text(app.tr('Redeem')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (app.notifications.isNotEmpty)
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/notifications'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
              child: Row(
                children: [
                  Icon(Icons.notifications_outlined, size: 18, color: app.unreadCount > 0 ? kPrimary : kMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app.tr('Latest update'), style: const TextStyle(fontSize: 10, color: kMuted, fontFamily: 'monospace')),
                        Text(app.trDyn(app.notifications.first.title), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kText), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(app.trDyn(app.notifications.first.body), style: const TextStyle(fontSize: 11, color: kMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: kMuted),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
            child: Row(
              children: [
                const Icon(Icons.notifications_outlined, size: 18, color: kMuted),
                const SizedBox(width: 10),
                Text(app.tr('No notifications yet'), style: const TextStyle(fontSize: 12, color: kMuted)),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.emoji_events_outlined, size: 16, color: kMuted),
            const SizedBox(width: 6),
            Text(app.tr('Top carpenters'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kText)),
          ],
        ),
        const SizedBox(height: 8),
        if (app.leaderboard.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(app.tr('No leaderboard activity yet'), style: const TextStyle(color: kMuted, fontSize: 12)),
          )
        else
          SizedBox(
          height: 88 * app.fontScale,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: app.leaderboard.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final e = app.leaderboard[i];
              final you = e.name == app.carpenterName;
              return SizedBox(
                width: 62,
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 23,
                          backgroundColor: (you ? kPrimary : kCard2),
                          child: e.photoUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    e.photoUrl!,
                                    width: 46,
                                    height: 46,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Text(e.initials, style: TextStyle(color: you ? kOnPrimary : kText, fontWeight: FontWeight.w600)),
                                  ),
                                )
                              : Text(e.initials, style: TextStyle(color: you ? kOnPrimary : kText, fontWeight: FontWeight.w600)),
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: CircleAvatar(
                            radius: 9,
                            backgroundColor: you ? kSuccess : kPrimaryDark,
                            child: Text('${i + 1}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(you ? app.tr('You') : e.name, style: const TextStyle(fontSize: 11, color: kText), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${e.points}', style: const TextStyle(fontSize: 11, color: kMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // Extra spacing vs. other grids in the app -- these are the primary
          // navigation actions on the screen users land on most, and matter
          // more for users unfamiliar with precise touchscreen interaction.
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.15 / app.fontScale,
          children: [
            ActionTile(icon: Icons.local_offer_outlined, title: app.tr('Offers'), subtitle: app.tr('Today & weekly'), color: const Color(0xFFFF8C42), onTap: () => Navigator.pushNamed(context, '/offers')),
            ActionTile(icon: Icons.add_box_outlined, title: app.tr('Create order'), subtitle: app.tr('Image, manual or voice'), color: kSuccess, onTap: () => Navigator.pushNamed(context, '/createOrder')),
            ActionTile(icon: Icons.card_giftcard_outlined, title: app.tr('Redeem points'), subtitle: app.tr('Gifts & cash'), color: kPrimaryLight, onTap: () => Navigator.pushNamed(context, '/gifts')),
            ActionTile(icon: Icons.lightbulb_outline, title: app.tr('Suggestions'), subtitle: app.tr('Share a lead'), color: const Color(0xFF39C5CF), onTap: () => Navigator.pushNamed(context, '/leads')),
            ActionTile(icon: Icons.history, title: app.tr('Order history'), subtitle: app.tr('Track past orders'), color: kPurple, onTap: () => Navigator.pushNamed(context, '/orderHistory')),
            ActionTile(icon: Icons.account_balance_wallet_outlined, title: app.tr('My account'), subtitle: app.tr('Bank, UPI & profile'), color: kInfo, onTap: () => Navigator.pushNamed(context, '/account')),
          ],
        ),
      ],
    );
  }
}
