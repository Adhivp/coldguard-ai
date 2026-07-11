import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    String greetingPrefix;
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greetingPrefix = 'Good morning';
    } else if (hour < 17) {
      greetingPrefix = 'Good afternoon';
    } else {
      greetingPrefix = 'Good evening';
    }

    return Stack(
      children: [
        // Background image
        Positioned.fill(
          child: Image.asset('assets/header_bg.png', fit: BoxFit.cover),
        ),

        // Content
        Padding(
          padding: EdgeInsets.fromLTRB(16.0, topPadding + 12.0, 16.0, 14.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left text section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '👋 $greetingPrefix!',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ColdGuard AI',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Live intelligence for every shipment',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right side (Notification bell)
              Stack(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {},
                    ),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5252), // Red badge dot
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
