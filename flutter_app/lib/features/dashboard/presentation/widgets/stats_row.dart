import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:code_card_ai/core/di/injection_container.dart';
import 'package:code_card_ai/features/scanner/data/datasources/scan_local_datasource.dart';

class StatsRow extends StatelessWidget {
  const StatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: sl<ScanLocalDataSource>().getScanHistory(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.length : 0;
        final countStr = snapshot.connectionState == ConnectionState.waiting
            ? '...'
            : '$count';

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    value: countStr,
                    title: 'Total Scans',
                    status: 'Stored locally',
                    statusColor: const Color(0xFF00ACC1),
                    icon: Icons.qr_code_scanner_rounded,
                    iconColor: const Color(0xFF00ACC1),
                    iconBg: const Color(0xFFE0F7FA),
                  ),
                ),
                _buildDivider(isDark),
                Expanded(
                  child: _buildStatItem(
                    context,
                    value: '2',
                    title: 'Active Alerts',
                    status: 'View all',
                    statusColor: const Color(0xFFF59E0B),
                    icon: Icons.thermostat_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    iconBg: const Color(0xFFFEF3C7),
                  ),
                ),
                _buildDivider(isDark),
                Expanded(
                  child: _buildStatItem(
                    context,
                    value: '4',
                    title: 'Active Shipments',
                    status: 'In Transit',
                    statusColor: const Color(0xFF0F52FF),
                    icon: Icons.local_shipping_rounded,
                    iconColor: const Color(0xFF0F52FF),
                    iconBg: const Color(0xFFEFF6FF),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String value,
    required String title,
    required String status,
    required Color statusColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 6),
          // Value
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          // Title
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: isDark ? const Color(0xFFA7A9BE) : const Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          // Status
          Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 1,
      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
    );
  }
}
