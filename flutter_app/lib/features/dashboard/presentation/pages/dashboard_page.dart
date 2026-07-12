import 'package:flutter/material.dart';
import 'package:code_card_ai/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:code_card_ai/features/dashboard/presentation/widgets/scan_hero_card.dart';
import 'package:code_card_ai/features/dashboard/presentation/widgets/stats_row.dart';
import 'package:code_card_ai/features/dashboard/presentation/widgets/active_shipment_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0E17)
          : const Color(0xFFF8FAFC),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF0E7490).withOpacity(0.35),
                    const Color(0xFF0F0E17),
                  ]
                : [
                    const Color(0xFF0E7490),
                    const Color(0xFFF8FAFC),
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.45],
          ),
        ),
        child: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardHeader(),
              SizedBox(height: 16),
              ScanHeroCard(),
              SizedBox(height: 16),
              StatsRow(),
              SizedBox(height: 20),
              ActiveShipmentCard(),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
