import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:code_card_ai/core/utils/responsive.dart';
import 'package:code_card_ai/features/history/presentation/widgets/history_log_item.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isMobile = Responsive.isMobile(context);

    final List<Map<String, dynamic>> logs = [
      {
        'title': 'Temperature threshold exceeded',
        'desc': 'Sensor 2 recorded a peak of 8.4°C (Limit: 6.0°C).',
        'time': 'Today, 10:24 AM',
        'type': 'warning',
      },
      {
        'title': 'Weekly report generated',
        'desc': 'The PDF report for Cold Chain integrity is ready for export.',
        'time': 'Today, 07:30 AM',
        'type': 'success',
      },
      {
        'title': 'Sensor calibration success',
        'desc': 'Temperature sensors calibrated with a confidence of 99.8%.',
        'time': 'Yesterday, 04:12 PM',
        'type': 'success',
      },
      {
        'title': 'Device disconnected',
        'desc': 'ColdGuard gateway experienced a temporary network loss.',
        'time': 'Yesterday, 11:05 AM',
        'type': 'error',
      },
      {
        'title': 'Firmware updated',
        'desc': 'Successfully updated to v2.4.1. Core stability improved.',
        'time': 'July 9, 09:15 AM',
        'type': 'info',
      },
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: EdgeInsets.all(isMobile ? 24.0 : 36.0),
          children: [
            Text(
              'History Logs',
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 28 : 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              'Historical security and system event records',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final log = logs[index];
                return HistoryLogItem(
                  title: log['title'] as String,
                  desc: log['desc'] as String,
                  time: log['time'] as String,
                  type: log['type'] as String,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
