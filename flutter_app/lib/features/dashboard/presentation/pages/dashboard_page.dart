import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:code_card_ai/core/utils/responsive.dart';
import 'package:code_card_ai/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:code_card_ai/features/dashboard/presentation/widgets/activity_item.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isMobile = Responsive.isMobile(context);
    int gridCount = isMobile ? 2 : 4;
    double aspectRatio = isMobile ? 1.3 : 1.4;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: ListView(
          padding: EdgeInsets.all(isMobile ? 24.0 : 36.0),
          children: [
            // Welcome Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: GoogleFonts.outfit(
                        fontSize: isMobile ? 28 : 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Welcome to ColdGuard AI',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Color(0xFF0F172A)),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 24 : 32),

            // Quick Stats Cards Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: gridCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: aspectRatio,
              children: const [
                StatCard(
                  title: 'Active Cards',
                  value: '12',
                  icon: Icons.credit_card_rounded,
                  iconColor: Color(0xFF0F52FF),
                  bgColor: Color(0xFFEFF6FF),
                ),
                StatCard(
                  title: 'Integrations',
                  value: '5',
                  icon: Icons.integration_instructions_outlined,
                  iconColor: Color(0xFF0D9488),
                  bgColor: Color(0xFFF0FDFA),
                ),
                StatCard(
                  title: 'Alerts',
                  value: '2',
                  icon: Icons.notifications_active_outlined,
                  iconColor: Color(0xFFEF4444),
                  bgColor: Color(0xFFFEF2F2),
                ),
                StatCard(
                  title: 'Sync Status',
                  value: 'Healthy',
                  icon: Icons.cloud_done_outlined,
                  iconColor: Color(0xFF10B981),
                  bgColor: Color(0xFFECFDF5),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 24 : 32),

            // Recent Activity Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activity',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const ActivityItem(
                    title: 'Sensor connection restored',
                    time: '10 mins ago',
                    icon: Icons.wifi_rounded,
                    iconColor: Color(0xFF10B981),
                    bgColor: Color(0xFFECFDF5),
                  ),
                  Divider(height: 24, color: Color(0xFFF1F5F9)),
                  const ActivityItem(
                    title: 'Card sync completed',
                    time: '1 hour ago',
                    icon: Icons.sync_rounded,
                    iconColor: Color(0xFF0F52FF),
                    bgColor: Color(0xFFEFF6FF),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
