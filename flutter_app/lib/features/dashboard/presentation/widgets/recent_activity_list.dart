import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RecentActivityList extends StatelessWidget {
  const RecentActivityList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    'View all',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00ACC1),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Timeline list
            _buildTimelineItem(
              context,
              title: 'Sensor connection restored',
              desc: 'All sensors are back online and reporting data.',
              time: '10 min ago',
              icon: Icons.wifi_rounded,
              iconColor: const Color(0xFF10B981),
              iconBg: const Color(0xFFECFDF5),
              dotColor: const Color(0xFF10B981),
              isLast: false,
            ),
            _buildTimelineItem(
              context,
              title: 'Product scanned',
              desc: 'Chicken Breast • Batch #CB25071101',
              time: '30 min ago',
              icon: Icons.inventory_2_outlined,
              iconColor: const Color(0xFF00ACC1),
              iconBg: const Color(0xFFE0F7FA),
              dotColor: const Color(0xFF00ACC1),
              isLast: false,
            ),
            _buildTimelineItem(
              context,
              title: 'Temperature alert resolved',
              desc: 'Temperature back to normal range.',
              time: '3 hours ago',
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFF59E0B),
              iconBg: const Color(0xFFFEF3C7),
              dotColor: const Color(0xFFF59E0B),
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context, {
    required String title,
    required String desc,
    required String time,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color dotColor,
    required bool isLast,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left node and line
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content middle
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: isDark ? const Color(0xFFA7A9BE) : const Color(0xFF64748B),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Time + Indicator dot right
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    color: isDark ? const Color(0xFFA7A9BE) : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
