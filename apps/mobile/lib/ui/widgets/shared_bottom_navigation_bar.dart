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
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: navProvider.currentIndex,
        onDestinationSelected: (idx) {
          navProvider.setIndex(idx);
          if (GoRouterState.of(context).uri.toString() != '/') {
             context.go('/');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.home), 
            label: 'Home'
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.calendarCheck), 
            label: 'Quests'
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.calendar), 
            label: 'Sessions'
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.graduationCap),
            label: 'Campus'
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.user), 
            label: 'You'
          ),
        ],
      ),
    );
  }
}
