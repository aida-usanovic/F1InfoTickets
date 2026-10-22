import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/cart_state.dart';
import '../../state/notification_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_logo.dart';
import 'cart_screen.dart';
import 'drivers_tab.dart';
import 'home_tab.dart';
import 'profile_screen.dart';
import 'races_tab.dart';
import 'teams_tab.dart';
import 'tickets_tab.dart';

/// Mobile layout from the mockups: logo, cart and profile in the app bar, five sections in the bottom bar.
class MobileShell extends StatefulWidget {
  const MobileShell({super.key});

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell> with WidgetsBindingObserver {
  int _index = 0;
  late final NotificationState _notifications = context.read<NotificationState>();

  static const _tabs = [
    (title: 'Home', icon: Icons.home_outlined, selected: Icons.home),
    (title: 'Drivers', icon: Icons.sports_motorsports_outlined, selected: Icons.sports_motorsports),
    (title: 'Tickets', icon: Icons.confirmation_number_outlined, selected: Icons.confirmation_number),
    (title: 'Teams', icon: Icons.groups_outlined, selected: Icons.groups),
    (title: 'Races', icon: Icons.flag_outlined, selected: Icons.flag),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartState>().load().catchError((_) {});
      // Polls for new notifications every 30 seconds while the customer app is open.
      _notifications.start();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifications.stop();
    super.dispose();
  }

  /// Checks right away when the app comes back from the background instead of waiting for the next poll.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _notifications.refresh();
  }

  void _openTab(int index) => setState(() => _index = index);

  Future<void> _openCart() => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));

  Future<void> _openProfile() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartState>().count;
    final unread = context.watch<NotificationState>().unread;
    return Scaffold(
      appBar: AppBar(
        title: const BrandLogo(size: 20),
        actions: [
          IconButton(
            tooltip: 'Cart',
            onPressed: _openCart,
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              backgroundColor: AppColors.red,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: _openProfile,
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              backgroundColor: AppColors.red,
              child: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          HomeTab(onOpenTab: _openTab),
          const DriversTab(),
          const TicketsTab(),
          const TeamsTab(),
          const RacesTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _openTab,
        destinations: [
          for (final tab in _tabs) NavigationDestination(icon: Icon(tab.icon), selectedIcon: Icon(tab.selected), label: tab.title),
        ],
      ),
    );
  }
}
