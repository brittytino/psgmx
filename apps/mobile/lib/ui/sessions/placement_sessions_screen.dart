import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/user_provider.dart';
import 'tabs/my_attendance_tab.dart';
import 'tabs/my_team_tab.dart';
import 'tabs/schedule_tab.dart';
import 'tabs/overall_tab.dart';

class PlacementSessionsScreen extends StatelessWidget {
  const PlacementSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    // Determine effective role (considering simulation mode)
    final isActualPlacementRep = userProvider.isActualPlacementRep;
    final isPlacementRep = userProvider.isPlacementRep;
    final isCoordinator = userProvider.isCoordinator;
    final isTeamLeader = userProvider.isTeamLeader;
    final isSimulating = isActualPlacementRep && !isPlacementRep;

    List<Widget> tabs = [];
    List<Widget> tabViews = [];

    // 1. My attendance (Everyone)
    tabs.add(const Tab(text: 'My attendance'));
    tabViews.add(const MyAttendanceTab());

    // 2. My Team (Team Leaders, Coordinators, Placement Rep)
    if (isTeamLeader || isCoordinator || (isPlacementRep && !isSimulating)) {
      tabs.add(const Tab(text: 'My Team'));
      tabViews.add(const MyTeamTab());
    }

    // 3. Schedule (Coordinators, Placement Rep)
    if (isCoordinator || (isActualPlacementRep && !isSimulating)) {
      tabs.add(const Tab(text: 'Schedule'));
      tabViews.add(const ScheduleTab());
    }

    // 4. Overall (Only Actual Placement Rep)
    if (isActualPlacementRep && !isSimulating) {
      tabs.add(const Tab(text: 'Overall'));
      tabViews.add(const OverallTab());
    }

    final TabAlignment tabAlignment;
    final bool isScrollable;
    if (tabs.length <= 2) {
      tabAlignment = TabAlignment.center;
      isScrollable = false;
    } else if (tabs.length <= 4) {
      tabAlignment = TabAlignment.fill;
      isScrollable = false;
    } else {
      tabAlignment = TabAlignment.start;
      isScrollable = true;
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF8F5), // Light warm background
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              backgroundColor: const Color(0xFFFAF8F5),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Placement Sessions',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFF2D3142),
                    ),
                  ),
                  Text(
                    'Consistency today, opportunities tomorrow. ✨',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF9094A6),
                    ),
                  ),
                ],
              ),
              pinned: true,
              floating: true,
              forceElevated: innerBoxIsScrolled,
              expandedHeight: 120, // Enough room for title and subtitle
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFF0F0F0)),
                  ),
                  child: TabBar(
                    isScrollable: isScrollable,
                    tabAlignment: tabAlignment,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF9094A6),
                    labelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    unselectedLabelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: const Color(0xFFFF6B4A), // Coral accent
                      borderRadius: BorderRadius.circular(30),
                    ),
                    dividerColor: Colors.transparent,
                    padding: const EdgeInsets.all(4),
                    tabs: tabs,
                  ),
                ),
              ),
            ),
          ],
          body: TabBarView(children: tabViews),
        ),
      ),
    );
  }
}
