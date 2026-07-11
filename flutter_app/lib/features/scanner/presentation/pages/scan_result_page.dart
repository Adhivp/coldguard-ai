import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:code_card_ai/features/scanner/data/models/scan_result_model.dart';

class ScanResultPage extends StatelessWidget {
  final ScanResultModel result;

  const ScanResultPage({super.key, required this.result});

  // App accent color
  static const Color _accent = Color(0xFF00ACC1);
  static const Color _accentLight = Color(0xFFE0F7FA);

  String _getProductAsset(String name) {
    final lowercaseName = name.toLowerCase();
    if (lowercaseName.contains('chicken')) {
      return 'assets/chicken_breast.png';
    } else if (lowercaseName.contains('salmon')) {
      return 'assets/salmon.jpg';
    } else if (lowercaseName.contains('vaccine')) {
      return 'assets/vaccine.jpg';
    } else if (lowercaseName.contains('milk')) {
      return 'assets/organic_milk.jpg';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final product = result.product;
    final current = result.current;
    final life = result.life;

    final bool isOk = current.status == 'OK';
    final Color statusColor = isOk
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    final Color statusBg = isOk
        ? const Color(0xFFECFDF5)
        : const Color(0xFFFEF2F2);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Gradient App Bar
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: _accent,
            title: Text(
              'Scan Details',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Colors.white70),
                onPressed: () {},
              ),
            ],
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF26C6DA), Color(0xFF00838F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    top: -20,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 40,
                    bottom: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.04),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Hero Product Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _accentLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                product.category.toUpperCase(),
                                style: GoogleFonts.inter(
                                  color: _accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    current.status,
                                    style: GoogleFonts.inter(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          product.name,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 8),

                        _buildDetailRow('ID', product.productId),
                        _buildDetailRow('Batch', product.batchNumber),
                        _buildDetailRow('Manufacturer', product.manufacturer),
                        _buildDetailRow('Storage', product.storageRequirement),
                        _buildDetailRow('Location', product.currentLocation),

                        // Local product hero image
                        (() {
                          final imagePath = _getProductAsset(product.name);
                          if (imagePath.isNotEmpty) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                                const Divider(color: Color(0xFFF1F5F9)),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    imagePath,
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 100,
                                        color: const Color(0xFFF1F5F9),
                                        child: const Center(
                                          child: Icon(
                                            Icons.broken_image_rounded,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        })(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Live Conditions
                  _buildSectionTitle('Live Conditions'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildLiveMetricCard(
                          title: 'Temperature',
                          value: '${current.temperature.toStringAsFixed(1)} °C',
                          status:
                              current.temperature >= 2 &&
                                  current.temperature <= 8
                              ? 'Normal'
                              : 'Excursion',
                          icon: Icons.thermostat_rounded,
                          color:
                              current.temperature >= 2 &&
                                  current.temperature <= 8
                              ? _accent
                              : const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildLiveMetricCard(
                          title: 'Humidity',
                          value: '${current.humidity.toStringAsFixed(1)} %',
                          status: 'Optimal',
                          icon: Icons.water_drop_rounded,
                          color: _accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. Cold Chain Analytics
                  _buildSectionTitle('Cold Chain Analytics'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Health score gauge
                        Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: CircularProgressIndicator(
                                    value: life.healthScore / 100,
                                    strokeWidth: 8,
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      life.healthScore > 80
                                          ? _accent
                                          : const Color(0xFFF59E0B),
                                    ),
                                  ),
                                ),
                                Text(
                                  '${life.healthScore}%',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Product Health Score',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Life status: ${life.status}',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 12),

                        _buildAnalyticsRow(
                          'Total Excursions',
                          '${life.totalExcursions} times',
                          icon: Icons.warning_amber_rounded,
                          color: const Color(0xFFEF4444),
                        ),
                        _buildAnalyticsRow(
                          'Remaining Shelf Life',
                          '${life.daysRemaining} Days',
                          icon: Icons.timelapse_rounded,
                          color: _accent,
                        ),
                        _buildAnalyticsRow(
                          'Adjusted Life',
                          '${life.adjustedDaysRemaining} Days',
                          icon: Icons.history_toggle_off_rounded,
                          color: const Color(0xFF8B5CF6),
                        ),
                        _buildAnalyticsRow(
                          'Estimated Expiry',
                          _formatDate(life.estimatedExpiry),
                          icon: Icons.event_busy_rounded,
                          color: const Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. Shipment Transit Timeline
                  _buildSectionTitle('Shipment Transit Timeline'),
                  const SizedBox(height: 12),
                  _buildTimelineCard(
                    context,
                    product.name,
                    product.currentLocation,
                    current.temperature,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(
    BuildContext context,
    String productName,
    String currentLocation,
    double currentTemp,
  ) {
    final waypoints = _getWaypoints(productName, currentLocation, currentTemp);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Disclaimer Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB), // Light amber/yellow
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFEF3C7)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DEMO MODE • SIMULATED DATA',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFB45309),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'This transit timeline displays simulated telemetry values for evaluation purposes. Active real-time sensor integration is currently not implemented.',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF78350F),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Waypoint list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: waypoints.length,
            itemBuilder: (context, index) {
              final wp = waypoints[index];
              return _buildTimelineItem(
                location: wp['location'] as String,
                temp: wp['temp'] as String,
                time: wp['time'] as String,
                status: wp['status'] as String,
                isLast: index == waypoints.length - 1,
                accentColor: _accent,
              );
            },
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getWaypoints(
    String productName,
    String currentLocation,
    double currentTemp,
  ) {
    if (productName.contains('Salmon')) {
      return [
        {
          'location': 'In Transit: Near Goa Highway',
          'temp': '$currentTemp °C',
          'time': 'July 12, 02:45 AM',
          'status': 'Optimal',
        },
        {
          'location': 'Goa Port Terminal cold Hub',
          'temp': '2.0 °C',
          'time': 'July 11, 08:30 PM',
          'status': 'Optimal',
        },
        {
          'location': 'Origin: OceanHarvest Factory, Goa',
          'temp': '1.5 °C',
          'time': 'July 11, 10:00 AM',
          'status': 'Optimal',
        },
      ];
    } else if (productName.contains('Vaccine')) {
      return [
        {
          'location': 'In Transit: Near Delhi Airport',
          'temp': '$currentTemp °C',
          'time': 'July 12, 02:15 AM',
          'status': 'Optimal',
        },
        {
          'location': 'Delhi Pharma Depot Unit 4',
          'temp': '-19.0 °C',
          'time': 'July 11, 04:00 PM',
          'status': 'Optimal',
        },
        {
          'location': 'Origin: BioVax Labs Manufacturing',
          'temp': '-18.0 °C',
          'time': 'July 11, 07:00 AM',
          'status': 'Optimal',
        },
      ];
    } else if (productName.contains('Milk')) {
      return [
        {
          'location': 'Delivered: Bangalore Retail Center',
          'temp': '$currentTemp °C',
          'time': 'July 12, 03:00 AM',
          'status': 'Optimal',
        },
        {
          'location': 'Bangalore City Cold Store',
          'temp': '3.2 °C',
          'time': 'July 11, 09:15 PM',
          'status': 'Optimal',
        },
        {
          'location': 'Origin: GreenValley Farms Dairy, Bangalore',
          'temp': '3.6 °C',
          'time': 'July 11, 01:00 PM',
          'status': 'Optimal',
        },
      ];
    } else {
      return [
        {
          'location': 'In Transit: Near Mumbai Hub',
          'temp': '$currentTemp °C',
          'time': 'July 12, 02:30 AM',
          'status': 'Optimal',
        },
        {
          'location': 'Mumbai Cargo Port Hub',
          'temp': '4.5 °C',
          'time': 'July 11, 06:15 PM',
          'status': 'Optimal',
        },
        {
          'location': 'Origin: MeatCare Facility, Mumbai',
          'temp': '3.9 °C',
          'time': 'July 11, 09:00 AM',
          'status': 'Optimal',
        },
      ];
    }
  }

  Widget _buildTimelineItem({
    required String location,
    required String temp,
    required String time,
    required String status,
    required bool isLast,
    required Color accentColor,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left timeline graphics column
          SizedBox(
            width: 24,
            child: Column(
              children: [
                // Circle dot
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor, width: 3),
                  ),
                ),
                // Vertical Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2.5,
                      color: accentColor.withOpacity(0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right content details column
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          location,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          temp,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF334155),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMetricCard({
    required String title,
    required String value,
    required String status,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsRow(
    String label,
    String value, {
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF475569),
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }
}
