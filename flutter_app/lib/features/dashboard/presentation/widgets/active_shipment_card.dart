import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActiveShipmentCard extends StatelessWidget {
  const ActiveShipmentCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Shipment',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: isDark
                      ? const Color(0xFFA7A9BE)
                      : const Color(0xFF64748B),
                ),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Shipment Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Image Stack
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/chicken_breast.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback container in case of error
                          return Container(
                            width: 72,
                            height: 72,
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFF1F5F9),
                            child: Icon(
                              Icons.restaurant_rounded,
                              color: theme.primaryColor,
                              size: 32,
                            ),
                          );
                        },
                      ),
                    ),
                    // Small snowflake icon badge at bottom right
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00ACC1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.ac_unit_rounded,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Right Details Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Batch
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                          children: [
                            const TextSpan(text: 'Chicken Breast'),
                            TextSpan(
                              text: '  •  Batch #CB25071101',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.normal,
                                color: isDark
                                    ? const Color(0xFFA7A9BE)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Mini status tags (Wrap to prevent layout overflow)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          _buildTag(
                            context,
                            icon: Icons.thermostat_rounded,
                            label: '4.2°C',
                            color: const Color(0xFFD81B60),
                            bgColor: const Color(0xFFFCE4EC),
                          ),
                          _buildTag(
                            context,
                            icon: Icons.water_drop_rounded,
                            label: '62%',
                            color: const Color(0xFF0F52FF),
                            bgColor: const Color(0xFFEFF6FF),
                          ),
                          _buildTag(
                            context,
                            icon: Icons.location_on_rounded,
                            label: 'Mumbai, India',
                            color: const Color(0xFF475569),
                            bgColor: const Color(0xFFF1F5F9),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Progress / Status indicator Row
                      Row(
                        children: [
                          // In Transit dot and text
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'In Transit',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          // Progress Bar
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: const LinearProgressIndicator(
                                value: 0.65, // 65% progress
                                minHeight: 4,
                                backgroundColor: Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF00ACC1),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // View Details link
                          GestureDetector(
                            onTap: () {},
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'View Details',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF00ACC1),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFF00ACC1),
                                  size: 12,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D3748) : bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: isDark ? Colors.white70 : color),
          const SizedBox(width: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : color,
            ),
          ),
        ],
      ),
    );
  }
}
