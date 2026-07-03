import 'package:flutter/material.dart';
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
    
    return NavigationBar(
      selectedIndex: navProvider.currentIndex,
      onDestinationSelected: (idx) {
        navProvider.setIndex(idx);
        // Navigate back to root layout if we are not already there
        if (GoRouterState.of(context).uri.toString() != '/') {
           context.go('/');
        }
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(LucideIcons.home), 
          selectedIcon: Icon(LucideIcons.home, color: theme.colorScheme.primary), 
          label: 'Home'
        ),
        NavigationDestination(
          icon: const Icon(LucideIcons.calendarCheck), 
          selectedIcon: Icon(LucideIcons.calendarCheck, color: theme.colorScheme.primary), 
          label: 'Quests'
        ),
        NavigationDestination(
          icon: const Icon(LucideIcons.calendar), 
          selectedIcon: Icon(LucideIcons.calendar, color: theme.colorScheme.primary), 
          label: 'Sessions'
        ),
        NavigationDestination(
          icon: const Icon(LucideIcons.graduationCap),
          selectedIcon: Icon(LucideIcons.graduationCap, color: theme.colorScheme.primary),
          label: 'Campus'
        ),
        NavigationDestination(
          icon: const Icon(LucideIcons.user), 
          selectedIcon: Icon(LucideIcons.user, color: theme.colorScheme.primary), 
          label: 'You'
        ),
      ],
    );
  }
}
