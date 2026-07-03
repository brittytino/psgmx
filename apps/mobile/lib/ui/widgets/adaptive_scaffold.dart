import 'package:flutter/material.dart';
import '../../core/theme/layout_tokens.dart';

class AdaptiveNavigationScaffold extends StatelessWidget {
  final String title;
  final Widget? action;
  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final AppUserDisplay? userProfile;

  const AdaptiveNavigationScaffold({
    super.key,
    required this.title,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.action,
    this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppSpacing.tabletBreakpoint) {
          // Mobile: Bottom Navigation
          return Scaffold(
            appBar: AppBar(
              title: Text(title),
              actions: [
                if (action != null) action!,
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
            body: body,
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: destinations,
            ),
          );
        } else {
          // Tablet/Desktop: Navigation Rail
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  leading: userProfile != null ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: CircleAvatar(child: Text(userProfile!.initials)),
                  ) : null,
                  trailing: action != null ? Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: action,
                      ),
                    ),
                  ) : null,
                  destinations: destinations.map((d) {
                    return NavigationRailDestination(
                      icon: d.icon, 
                      selectedIcon: d.selectedIcon, 
                      label: Text(d.label),
                    );
                  }).toList(),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: Column(
                    children: [
                      // On large screens, sometimes we want a header or just content
                      AppBar(title: Text(title), elevation: 0),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                            child: body,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

class AppUserDisplay {
  final String name;
  final String initials;
  AppUserDisplay({required this.name, required this.initials});
}
