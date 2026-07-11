import 'package:flutter/material.dart';
import 'package:code_card_ai/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:code_card_ai/features/dashboard/presentation/widgets/scan_hero_card.dart';
import 'package:code_card_ai/features/dashboard/presentation/widgets/navigation_grid.dart';
import 'package:code_card_ai/features/dashboard/presentation/widgets/stats_row.dart';
import 'package:code_card_ai/features/dashboard/presentation/widgets/active_shipment_card.dart';
import 'package:code_card_ai/features/dashboard/presentation/widgets/recent_activity_list.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0E17) : const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            DashboardHeader(),
            SizedBox(height: 16),
            ScanHeroCard(),
            SizedBox(height: 16),
            NavigationGrid(),
            SizedBox(height: 16),
            StatsRow(),
            SizedBox(height: 20),
            ActiveShipmentCard(),
            SizedBox(height: 16),
            RecentActivityList(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
