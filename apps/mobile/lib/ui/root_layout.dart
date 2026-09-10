import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/navigation_provider.dart';
import '../core/theme/app_dimens.dart';
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

    final currentIndex = navProvider.currentIndex;

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
            Expanded(
              child: _AnimatedTabBody(
                index: currentIndex,
                screens: screens,
              ),
            ),
          ],
        ),
      );
    }

    // Mobile layout with bottom navigation
    return Scaffold(
      body: _AnimatedTabBody(index: currentIndex, screens: screens),
      bottomNavigationBar: const SharedBottomNavigationBar(),
    );
  }
}

/// Keeps already-visited tabs alive (so scroll position and fetched data are
/// retained) while applying one short, GPU-friendly transition on tab change.
class _AnimatedTabBody extends StatefulWidget {
  final int index;
  final List<Widget> screens;

  const _AnimatedTabBody({required this.index, required this.screens});

  @override
  State<_AnimatedTabBody> createState() => _AnimatedTabBodyState();
}

class _AnimatedTabBodyState extends State<_AnimatedTabBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Set<int> _visitedIndexes;
  double _direction = 1;

  @override
  void initState() {
    super.initState();
    _visitedIndexes = {widget.index};
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.medium,
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant _AnimatedTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _direction = widget.index > oldWidget.index ? 1 : -1;
      _visitedIndexes.add(widget.index);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stack = IndexedStack(
      index: widget.index,
      children: List<Widget>.generate(widget.screens.length, (index) {
        if (!_visitedIndexes.contains(index)) return const SizedBox.shrink();
        return TickerMode(
          enabled: index == widget.index,
          child: widget.screens[index],
        );
      }),
    );

    if (MediaQuery.disableAnimationsOf(context)) return stack;

    return AnimatedBuilder(
      animation: _controller,
      child: stack,
      builder: (context, child) {
        final value = Curves.easeOutCubic.transform(_controller.value);
        return Opacity(
          opacity: 0.88 + (0.12 * value),
          child: Transform.translate(
            offset: Offset((1 - value) * 12 * _direction, 0),
            child: child,
          ),
        );
      },
    );
  }
}
