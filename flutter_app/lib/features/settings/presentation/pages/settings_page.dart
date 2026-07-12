import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:code_card_ai/core/utils/responsive.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F0E17) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark
        ? const Color(0xFFA7A9BE)
        : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: EdgeInsets.all(isMobile ? 20.0 : 36.0),
            children: [
              // Header Segment
              Text(
                'About the App',
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 26 : 30,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                'Learn more about ColdGuard AI technology & mission',
                style: GoogleFonts.inter(fontSize: 13, color: subTextColor),
              ),
              const SizedBox(height: 24),

              // Brand Icon Card
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Glowing logo badge
                    Container(
                      width: 80,
                      height: 80,

                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Image.asset(
                            'assets/cg..png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ColdGuard AI',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 1.0.0',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00ACC1),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: borderColor),
                    const SizedBox(height: 12),
                    Text(
                      'ColdGuard AI is an intelligent telemetry analysis platform designed to safeguard temperature-sensitive shipments across global supply chains. By combining raw IoT sensor tracking, interactive data visualization, and LLM-powered telemetry audits, we ensure complete environmental security from farm to fork.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: subTextColor,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Footer Support
              Center(
                child: Column(
                  children: [
                    Text(
                      '© 2026 ColdGuard AI Technologies. All rights reserved.',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: subTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Support: support@coldguard.ai',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00ACC1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
