import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NavigationGrid extends StatelessWidget {
  const NavigationGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildNavCard(
              context,
              title: 'Live Monitor',
              desc: 'Real-time temperature and environment',
              accentColor: const Color(0xFF00ACC1),
              onTap: () {},
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildNavCard(
              context,
              title: 'Analytics',
              desc: 'Insights, reports and trends',
              accentColor: const Color(0xFF00ACC1),
              onTap: () {},
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildNavCard(
              context,
              title: 'My Shipments',
              desc: 'Track and manage active shipments',
              accentColor: const Color(0xFF00ACC1),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavCard(
    BuildContext context, {
    required String title,
    required String desc,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        height: 110,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Accent bar
            Container(
              width: 28,
              height: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            // Description
            Text(
              desc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isDark ? const Color(0xFFA7A9BE) : const Color(0xFF64748B),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
