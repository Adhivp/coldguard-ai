import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryLogItem extends StatelessWidget {
  final String title;
  final String desc;
  final String time;
  final String type;

  const HistoryLogItem({
    super.key,
    required this.title,
    required this.desc,
    required this.time,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    Color accentColor;
    Color bgColor;
    IconData icon;

    switch (type) {
      case 'warning':
        accentColor = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        icon = Icons.warning_amber_rounded;
        break;
      case 'error':
        accentColor = const Color(0xFFEF4444);
        bgColor = const Color(0xFFFEF2F2);
        icon = Icons.error_outline_rounded;
        break;
      case 'success':
        accentColor = const Color(0xFF10B981);
        bgColor = const Color(0xFFECFDF5);
        icon = Icons.check_circle_outline_rounded;
        break;
      default:
        accentColor = const Color(0xFF0F52FF);
        bgColor = const Color(0xFFEFF6FF);
        icon = Icons.info_outline_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
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
