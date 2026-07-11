import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:code_card_ai/core/utils/responsive.dart';
import 'package:code_card_ai/features/scanner/presentation/pages/scanner_page.dart';
import 'dart:math';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Subtle clean background
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16.0 : 28.0,
              vertical: 20.0,
            ),
            children: [
              // ============================
              // 1. Premium Glassmorphic Header Card
              // ============================
              _buildHeader(context, isMobile),
              const SizedBox(height: 20),

              // ============================
              // 2. Scan Product Hero Card
              // ============================
              _buildScanHeroCard(context, isMobile),
              const SizedBox(height: 20),

              // ============================
              // 3. Live Monitoring Card (Dark Blue Card with bg.svg)
              // ============================
              _buildLiveMonitoringCard(context, isMobile),
              const SizedBox(height: 20),

              // ============================
              // 4. Metrics Grid
              // ============================
              _buildMetricsGrid(context, isMobile),
              const SizedBox(height: 20),

              // ============================
              // 5. Temperature Analytics Chart
              // ============================
              _buildAnalyticsChartCard(context, isMobile),
              const SizedBox(height: 20),

              // ============================
              // 6. AI Insights Card
              // ============================
              _buildAIInsightsCard(context, isMobile),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // ============================
  // Header Widget Builder
  // ============================
  Widget _buildHeader(BuildContext context, bool isMobile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
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
      child: Row(
        children: [
          // 3D hardware icon wrapper
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.view_in_ar_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Text block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Monitor',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'SKU-9923  •  Electronics',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildHeaderStatusChip(
                      label: 'Online',
                      color: const Color(0xFF10B981),
                      bgColor: const Color(0xFFECFDF5),
                    ),
                    const SizedBox(width: 8),
                    _buildHeaderStatusChip(
                      label: 'Monitoring Active',
                      color: const Color(0xFF0F52FF),
                      bgColor: const Color(0xFFEFF6FF),
                    ),
                  ],
                )
              ],
            ),
          ),
          // Action Buttons
          Row(
            children: [
              _buildHeaderIconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_outlined, color: Color(0xFF475569)),
                    Positioned(
                      right: 1,
                      top: 1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F52FF),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  ],
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 10),
              _buildHeaderIconButton(
                icon: const Icon(Icons.settings_outlined, color: Color(0xFF475569)),
                onPressed: () {},
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHeaderStatusChip({
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required Widget icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: icon,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }

  // ============================
  // Scan Hero Card Widget Builder
  // ============================
  Widget _buildScanHeroCard(BuildContext context, bool isMobile) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scan Product',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Instantly monitor product condition and temperature',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildScanChip(
                        icon: Icons.qr_code_rounded,
                        label: 'QR Code',
                      ),
                      const SizedBox(width: 8),
                      _buildScanChip(
                        icon: Icons.view_column_rounded,
                        label: 'Barcode',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ScannerPage()),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                    label: Text(
                      'Start Scan',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F52FF),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: const Color(0xFF0F52FF).withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 26),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.asset(
                  'assets/Qrbox.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF475569)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  // ============================
  // Live Monitoring Card Widget Builder
  // ============================
  Widget _buildLiveMonitoringCard(BuildContext context, bool isMobile) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF051138), // Dark indigo base
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF051138).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background SVG picture
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/bg.svg',
                fit: BoxFit.cover,
              ),
            ),
            // Background gradient mask for readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF051138).withOpacity(0.55),
                      const Color(0xFF0A226E).withOpacity(0.75),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            // Card Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // LIVE MONITORING dot
                      Row(
                        children: [
                          _BlinkingLiveDot(),
                          const SizedBox(width: 8),
                          Text(
                            'LIVE MONITORING',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      // SAFE pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'SAFE',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Center temperature ring and text
                  Expanded(
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Circular Temperature Ring
                          SizedBox(
                            width: 110,
                            height: 110,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: const Size(110, 110),
                                  painter: TemperatureGaugePainter(value: 0.65),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'INTERNAL TEMP',
                                      style: GoogleFonts.inter(
                                        fontSize: 7,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white54,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '24.5°C',
                                      style: GoogleFonts.outfit(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    SizedBox(
                                      width: 45,
                                      height: 14,
                                      child: CustomPaint(
                                        painter: HeartbeatWavePainter(),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Bottom Updated Row
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Last Updated • 2 sec ago',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // ============================
  // Metrics Grid Widget Builder
  // ============================
  Widget _buildMetricsGrid(BuildContext context, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Compute columns based on available width
        final double cardWidth = (constraints.maxWidth - (isMobile ? 12 : 24)) / 2;
        
        return Wrap(
          spacing: isMobile ? 12 : 16,
          runSpacing: isMobile ? 12 : 16,
          children: [
            _buildMetricCard(
              width: cardWidth,
              title: 'Current Temp',
              value: '24.5 °C',
              subtitle: 'Stable',
              isGreen: true,
              arrowDown: true,
              icon: Icons.thermostat_rounded,
              iconColor: const Color(0xFF0F52FF),
              iconBgColor: const Color(0xFFEFF6FF),
            ),
            _buildMetricCard(
              width: cardWidth,
              title: 'Average Temp',
              value: '23.8 °C',
              subtitle: '-0.4°C',
              isGreen: false,
              arrowDown: true,
              icon: Icons.trending_down_rounded,
              iconColor: const Color(0xFF0F52FF),
              iconBgColor: const Color(0xFFEFF6FF),
            ),
            _buildMetricCard(
              width: cardWidth,
              title: 'Maximum Temp',
              value: '26.1 °C',
              subtitle: '14:20',
              isGreen: null,
              arrowDown: false,
              icon: Icons.trending_up_rounded,
              iconColor: const Color(0xFFEF4444),
              iconBgColor: const Color(0xFFFEE2E2),
            ),
            _buildMetricCard(
              width: cardWidth,
              title: 'System Status',
              value: 'Active',
              subtitle: '99% Uptime',
              isGreen: true,
              arrowDown: false,
              icon: Icons.verified_user_rounded,
              iconColor: const Color(0xFF10B981),
              iconBgColor: const Color(0xFFECFDF5),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required bool? isGreen,
    required bool arrowDown,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Icon Circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          // Metric Values
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (isGreen != null) ...[
                      Icon(
                        arrowDown ? Icons.arrow_downward_rounded : Icons.check_circle_outline_rounded,
                        size: 11,
                        color: isGreen ? const Color(0xFF10B981) : const Color(0xFF0F52FF),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isGreen == null
                            ? const Color(0xFF64748B)
                            : (isGreen ? const Color(0xFF10B981) : const Color(0xFF0F52FF)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // ============================
  // Line Chart Card Widget Builder
  // ============================
  Widget _buildAnalyticsChartCard(BuildContext context, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          // Chart Header with filters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.analytics_outlined, color: Color(0xFF0F52FF), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Temperature Analytics',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Last 24 Hours',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Buttons
              Row(
                children: [
                  _buildTimeFilterButton('24H', isActive: true),
                  const SizedBox(width: 4),
                  _buildTimeFilterButton('7D', isActive: false),
                  const SizedBox(width: 4),
                  _buildTimeFilterButton('30D', isActive: false),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          // Chart Display
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: const Color(0xFFE2E8F0),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        if (value % 2 == 0) {
                          return Text(
                            '${value.toInt()}°C',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 4,
                      getTitlesWidget: (value, meta) {
                        final hours = ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00', '24:00'];
                        final index = (value / 4).toInt();
                        if (index >= 0 && index < hours.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              hours[index],
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 24,
                minY: 18,
                maxY: 28,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF0F172A),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y}°C\n12:00 PM',
                          GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 22.8),
                      FlSpot(4, 23.2),
                      FlSpot(8, 22.5),
                      FlSpot(12, 24.5),
                      FlSpot(16, 23.8),
                      FlSpot(20, 22.0),
                      FlSpot(24, 23.5),
                    ],
                    isCurved: true,
                    color: const Color(0xFF0F52FF),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        if (spot.x == 12) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: const Color(0xFF0F52FF),
                            strokeColor: Colors.white,
                            strokeWidth: 3,
                          );
                        }
                        return FlDotCirclePainter(radius: 0, color: Colors.transparent);
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0F52FF).withOpacity(0.2),
                          const Color(0xFF0F52FF).withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTimeFilterButton(String label, {required bool isActive}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF0F52FF) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.white : const Color(0xFF475569),
        ),
      ),
    );
  }

  // ============================
  // AI Insights Card Widget Builder
  // ============================
  Widget _buildAIInsightsCard(BuildContext context, bool isMobile) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEFF6FF),
            const Color(0xFFE0ECFF).withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBFDBFE).withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Text(
                      'AI Insights',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.sparkles, color: Color(0xFF0F52FF), size: 15),
                  ],
                ),
                const SizedBox(height: 14),
                // Checklist
                _buildInsightCheckItem('Temperature Stable'),
                const SizedBox(height: 8),
                _buildInsightCheckItem('No abnormal fluctuations detected'),
                const SizedBox(height: 8),
                _buildInsightCheckItem('Product operating within safe range'),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Glowing Holographic Brain Icon/Image
          Expanded(
            flex: 3,
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Holographic glow ring background
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F52FF).withOpacity(0.15),
                          blurRadius: 20,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  // Glowing Brain
                  const Icon(
                    Icons.psychology_rounded,
                    color: Color(0xFF0F52FF),
                    size: 54,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCheckItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF334155),
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// Blinking Live Dot Animation Widget
// ==========================================
class _BlinkingLiveDot extends StatefulWidget {
  @override
  State<_BlinkingLiveDot> createState() => _BlinkingLiveDotState();
}

class _BlinkingLiveDotState extends State<_BlinkingLiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF10B981),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ==========================================
// Custom Painters for Gauge & Pulse wave
// ==========================================
class TemperatureGaugePainter extends CustomPainter {
  final double value;

  TemperatureGaugePainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8;

    // Track arc
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final startAngle = -1.25 * pi;
    final sweepAngle = 1.5 * pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Active track arc with gradient
    final activePaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFF10B981), // Green
          Color(0xFF0F52FF), // Blue
          Color(0xFF3B82F6), // Light Blue
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * value,
      false,
      activePaint,
    );

    // Handle indicator knob offset
    final currentAngle = startAngle + (sweepAngle * value);
    final knobOffset = Offset(
      center.dx + radius * cos(currentAngle),
      center.dy + radius * sin(currentAngle),
    );

    final knobPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawCircle(knobOffset, 7, shadowPaint);
    canvas.drawCircle(knobOffset, 5, knobPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class HeartbeatWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height / 2);
    path.lineTo(size.width * 0.25, size.height / 2);
    path.lineTo(size.width * 0.32, size.height / 2 - 6);
    path.lineTo(size.width * 0.40, size.height / 2 + 10);
    path.lineTo(size.width * 0.48, size.height / 2 - 12);
    path.lineTo(size.width * 0.56, size.height / 2 + 8);
    path.lineTo(size.width * 0.64, size.height / 2);
    path.lineTo(size.width, size.height / 2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
