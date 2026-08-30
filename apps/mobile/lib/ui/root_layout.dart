import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/navigation_provider.dart';
import '../core/utils/responsive_helper.dart';
import 'today/today_screen.dart';
import 'train/train_hub_screen.dart';
import 'progress/progress_screen.dart';
import 'community/community_screen.dart';
import 'profile/profile_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'widgets/shared_bottom_navigation_bar.dart';

class RootLayout extends StatefulWidget {
  const RootLayout({super.key});

  @override
  State<RootLayout> createState() => _RootLayoutState();
}

class _RootLayoutState extends State<RootLayout> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final navProvider = Provider.of<NavigationProvider>(context);
    final user = userProvider.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // The companion journey is stable across batches. The content inside each
    // destination adapts to junior/senior status instead of moving navigation.
    final screens = <Widget>[
      const TodayScreen(),
      const TrainHubScreen(),
      const ProgressScreen(),
      const CommunityScreen(),
      const ProfileScreen(),
    ];

    // Stable companion navigation for the authenticated user.
    final navItems = <NavigationDestination>[
      NavigationDestination(
          icon: const Icon(LucideIcons.home),
          selectedIcon: Icon(LucideIcons.home,
              color: Theme.of(context).colorScheme.primary),
          label: 'Today'),
      NavigationDestination(
          icon: const Icon(LucideIcons.target),
          selectedIcon: Icon(LucideIcons.target,
              color: Theme.of(context).colorScheme.primary),
          label: 'Train'),
      NavigationDestination(
          icon: const Icon(LucideIcons.chartNoAxesCombined),
          selectedIcon: Icon(LucideIcons.chartNoAxesCombined,
              color: Theme.of(context).colorScheme.primary),
          label: 'Progress'),
      NavigationDestination(
          icon: const Icon(LucideIcons.users),
          selectedIcon: Icon(LucideIcons.users,
              color: Theme.of(context).colorScheme.primary),
          label: 'Community'),
      NavigationDestination(
          icon: const Icon(LucideIcons.user),
          selectedIcon: Icon(LucideIcons.user,
              color: Theme.of(context).colorScheme.primary),
          label: 'You'),
    ];

    // Safety check for index
    var currentIndex = navProvider.currentIndex;
    if (currentIndex >= screens.length) {
      currentIndex = 0;
      // Schedule a fix for the provider as well
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navProvider.setIndex(0);
      });
    }

    // Use NavigationRail for desktop/tablet web, BottomNavigationBar for mobile
    final useRail = ResponsiveHelper.isDesktop(context) ||
        (ResponsiveHelper.isWeb && ResponsiveHelper.isTablet(context));

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: (idx) => navProvider.setIndex(idx),
              labelType: NavigationRailLabelType.all,
              destinations: navItems
                  .map((item) => NavigationRailDestination(
                        icon: item.icon,
                        selectedIcon: item.selectedIcon,
                        label: Text(item.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: screens[currentIndex]),
          ],
        ),
      );
    }

    // Mobile layout with bottom navigation
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: const SharedBottomNavigationBar(),
    );
  }
}
