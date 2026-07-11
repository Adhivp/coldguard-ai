import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:code_card_ai/core/utils/responsive.dart';
import 'package:code_card_ai/features/monitoring/presentation/widgets/metric_tile.dart';
import 'package:code_card_ai/features/monitoring/presentation/widgets/ecg_painter.dart';

class MonitoringScreen extends StatelessWidget {
  final Animation<double> animation;

  const MonitoringScreen({
    super.key,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    bool isMobile = Responsive.isMobile(context);

    Widget gridSection() {
      if (isMobile) {
        return Column(
          children: const [
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    label: 'Temperature',
                    value: '4.2°C',
                    subText: 'Normal Range',
                    icon: Icons.thermostat_rounded,
                    color: Color(0xFF0D9488),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: MetricTile(
                    label: 'Humidity',
                    value: '64%',
                    subText: 'Optimal',
                    icon: Icons.water_drop_rounded,
                    color: Color(0xFF0F52FF),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    label: 'Battery',
                    value: '94%',
                    subText: '8h 24m left',
                    icon: Icons.battery_charging_full_rounded,
                    color: Color(0xFF10B981),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: MetricTile(
                    label: 'Signal',
                    value: '-68 dBm',
                    subText: 'Excellent',
                    icon: Icons.wifi_tethering_rounded,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
          ],
        );
      } else {
        return Row(
          children: const [
            Expanded(
              child: MetricTile(
                label: 'Temperature',
                value: '4.2°C',
                subText: 'Normal Range',
                icon: Icons.thermostat_rounded,
                color: Color(0xFF0D9488),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: MetricTile(
                label: 'Humidity',
                value: '64%',
                subText: 'Optimal',
                icon: Icons.water_drop_rounded,
                color: Color(0xFF0F52FF),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: MetricTile(
                label: 'Battery',
                value: '94%',
                subText: '8h 24m left',
                icon: Icons.battery_charging_full_rounded,
                color: Color(0xFF10B981),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: MetricTile(
                label: 'Signal',
                value: '-68 dBm',
                subText: 'Excellent',
                icon: Icons.wifi_tethering_rounded,
                color: Color(0xFF8B5CF6),
              ),
            ),
          ],
        );
      }
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: ListView(
          padding: EdgeInsets.all(isMobile ? 24.0 : 36.0),
          children: [
            Text(
              'Live Monitoring',
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 28 : 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              'Real-time temperature and status signals',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),

            // Live ECG Waveform Card
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Live Pulse Waveform',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '72 BPM',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: EcgPainter(phase: animation.value),
                          child: Container(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Metrics Section
            gridSection(),
          ],
        ),
      ),
    );
  }
}
