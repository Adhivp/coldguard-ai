import 'package:flutter/material.dart';
import 'package:code_card_ai/core/utils/responsive.dart';
import 'package:code_card_ai/features/home/presentation/widgets/custom_floating_navbar.dart';
import 'package:code_card_ai/features/home/presentation/widgets/custom_sidebar.dart';
import 'package:code_card_ai/features/home/presentation/widgets/custom_nav_rail.dart';
import 'package:code_card_ai/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:code_card_ai/features/monitoring/presentation/pages/monitoring_page.dart';
import 'package:code_card_ai/features/history/presentation/pages/history_page.dart';
import 'package:code_card_ai/features/settings/presentation/pages/settings_page.dart';
import 'package:code_card_ai/features/chat/presentation/pages/chat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _navItems = [
    {'label': 'Dashboard', 'icon': Icons.home_rounded},
    {'label': 'Products', 'icon': Icons.inventory_2_rounded},
    {'label': 'History', 'icon': Icons.access_time_rounded},
    {'label': 'About Us', 'icon': Icons.info_outline_rounded},
    {'label': 'AI Assistant', 'icon': Icons.psychology_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Widget> screens = [
      const DashboardScreen(),
      const MonitoringScreen(),
      const HistoryScreen(),
      const SafeArea(bottom: false, child: SettingsScreen()),
      const SafeArea(bottom: false, child: ChatPage()),
    ];

    bool isMobile = Responsive.isMobile(context);
    bool isTablet = Responsive.isTablet(context);
    bool isDesktop = Responsive.isDesktop(context);

    Widget contentBody = IndexedStack(index: _currentIndex, children: screens);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0E17)
          : const Color(0xFFF8FAFC),
      body: Row(
        children: [
          if (isDesktop)
            CustomSidebar(
              currentIndex: _currentIndex,
              items: _navItems,
              onTap: (index) => setState(() => _currentIndex = index),
            ),
          if (isTablet)
            CustomNavRail(
              currentIndex: _currentIndex,
              items: _navItems,
              onTap: (index) => setState(() => _currentIndex = index),
            ),
          if (!isMobile)
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Color(0xFFE2E8F0),
            ),
          Expanded(child: contentBody),
        ],
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF00ACC1),
              shape: const CircleBorder(),
              elevation: 4,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatPage()),
                );
              },
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white,
              ),
            )
          : null,
      bottomNavigationBar: isMobile
          ? CustomFloatingNavbar(
              currentIndex: _currentIndex,
              items: _navItems.take(4).toList(),
              onTap: (index) => setState(() => _currentIndex = index),
            )
          : null,
    );
  }
}
