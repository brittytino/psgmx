import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/navigation_provider.dart';

class SharedBottomNavigationBar extends StatelessWidget {
  const SharedBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.8),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: navProvider.currentIndex,
          onDestinationSelected: (idx) {
            if (idx != navProvider.currentIndex) {
              HapticFeedback.selectionClick();
              navProvider.setIndex(idx);
            }
            if (GoRouterState.of(context).uri.toString() != '/') {
              context.go('/');
            }
          },
          destinations: const [
            NavigationDestination(icon: Icon(LucideIcons.home), label: 'Today'),
            NavigationDestination(
                icon: Icon(LucideIcons.target), label: 'Train'),
            NavigationDestination(
                icon: Icon(LucideIcons.chartNoAxesCombined), label: 'Progress'),
            NavigationDestination(
                icon: Icon(LucideIcons.users), label: 'Community'),
            NavigationDestination(icon: Icon(LucideIcons.user), label: 'You'),
          ],
        ),
      ),
    );
  }
}
