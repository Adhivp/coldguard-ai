import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:code_card_ai/core/di/injection_container.dart';
import 'package:code_card_ai/features/scanner/data/models/scan_result_model.dart';
import 'package:code_card_ai/features/scanner/data/models/telemetry_graph_model.dart';
import 'package:code_card_ai/features/scanner/data/datasources/scan_remote_datasource.dart';
import 'package:code_card_ai/features/scanner/presentation/widgets/ai_analysis_sheet.dart';
import 'package:code_card_ai/features/chat/data/services/model_service.dart';

class ScanResultPage extends StatefulWidget {
  final ScanResultModel result;

  const ScanResultPage({super.key, required this.result});

  @override
  State<ScanResultPage> createState() => _ScanResultPageState();
}

class _ScanResultPageState extends State<ScanResultPage> {
  TelemetryGraphModel? _graphData;
  bool _isLoadingGraph = false;
  String _errorMessage = '';
  String _zoom = 'day'; // 'day', 'hour', 'minute', 'second'
  String _selectedDate = '2026-07-12';
  int _selectedHour = 14;
  int _selectedMinute = 30;
  int _currentPage = 1;
  bool _showTemperature = true;

  @override
  void initState() {
    super.initState();
    // Initialize date from last reading if available, else use today's date
    if (widget.result.current.lastUpdated.isNotEmpty) {
      try {
        final dt = DateTime.parse(widget.result.current.lastUpdated);
        _selectedDate =
            "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
        _selectedHour = dt.hour;
        _selectedMinute = dt.minute;
      } catch (_) {
        _selectedDate = '2026-07-12';
      }
    } else {
      _selectedDate = '2026-07-12';
    }
    _fetchGraphData();
  }

  Future<void> _fetchGraphData() async {
    setState(() {
      _isLoadingGraph = true;
      _errorMessage = '';
    });
    try {
      final remoteDataSource = sl<ScanRemoteDataSource>();
      final data = await remoteDataSource.getProductGraphData(
        productId: widget.result.product.productId,
        zoom: _zoom,
        date: _zoom == 'day' ? null : _selectedDate,
        hour: _zoom == 'minute' || _zoom == 'second' ? _selectedHour : null,
        minute: _zoom == 'second' ? _selectedMinute : null,
        page: _currentPage,
        pageSize: 30,
      );
      setState(() {
        _graphData = data;
        _isLoadingGraph = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingGraph = false;
      });
    }
  }

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
    final product = widget.result.product;
    final current = widget.result.current;
    final life = widget.result.life;

    final bool isOk = current.status == 'OK';
    final Color statusColor = isOk
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    final Color statusBg = isOk
        ? const Color(0xFFECFDF5)
        : const Color(0xFFFEF2F2);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: _buildAIFab(context),
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

                        // AI Quick Badge
                        _buildAIQuickBadge(current, life),

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

                  // Smart Alert Banner (conditional)
                  if (!isOk || life.totalExcursions > 0)
                    _buildSmartAlertBanner(current, life, product),

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

                  // Telemetry History Graph
                  _buildGraphCard(),
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

  Widget _buildGraphCard() {
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
          // Section Title
          // Section Title
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSectionTitle('Environmental Telemetry'),

              // Temp / Humidity Toggle
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMetricToggleBtn(true, 'Temp'),
                    _buildMetricToggleBtn(false, 'Humidity'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Interactive Hint Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.touch_app_rounded,
                  color: Color(0xFF1D4ED8),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Interactive: Tap chart points to drill down from Day ➔ Hour ➔ Minute ➔ Second.',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Zoom Level Indicators & Breadcrumbs
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              // Zoom Level Title
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_zoom != 'day') ...[
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_zoom == 'second') {
                            _zoom = 'minute';
                          } else if (_zoom == 'minute') {
                            _zoom = 'hour';
                          } else if (_zoom == 'hour') {
                            _zoom = 'day';
                          }
                          _currentPage = 1;
                          _fetchGraphData();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _accentLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          size: 14,
                          color: _accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    _zoom == 'day'
                        ? 'Daily Telemetry'
                        : _zoom == 'hour'
                        ? 'Hourly'
                        : _zoom == 'minute'
                        ? 'Minutely'
                        : 'Raw Data',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),

              // Breadcrumbs Drill-Down Selection
              _buildBreadcrumbs(),
            ],
          ),
          const SizedBox(height: 20),

          // Main Chart View area
          SizedBox(
            height: 220,
            child: _isLoadingGraph
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_accent),
                    ),
                  )
                : _errorMessage.isNotEmpty
                ? _errorMessage.contains('404')
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.cloud_off_rounded,
                                  color: Color(0xFF94A3B8),
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No Telemetry Data Found (404)',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                ),
                                child: Text(
                                  'The server returned no telemetry points for this selection.',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Center(
                          child: Text(
                            'Error loading graph: $_errorMessage',
                            style: GoogleFonts.inter(color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          ),
                        )
                : _graphData == null || _graphData!.points.isEmpty
                ? Center(
                    child: Text(
                      'No telemetry points recorded.',
                      style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: _buildLineChart(),
                  ),
          ),
          const SizedBox(height: 16),

          // Summary Stats Row (Avg, Min, Max, Excursions)
          if (_graphData != null) _buildSummaryRow(),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    final List<Widget> items = [];

    // All Days (Root)
    final bool isDayActive = _zoom == 'day';
    items.add(
      _buildBreadcrumbItem(
        label: 'All Days',
        isActive: isDayActive,
        onTap: isDayActive
            ? null
            : () {
                setState(() {
                  _zoom = 'day';
                  _currentPage = 1;
                  _fetchGraphData();
                });
              },
      ),
    );

    // Date
    if (_zoom == 'hour' || _zoom == 'minute' || _zoom == 'second') {
      items.add(_buildBreadcrumbSeparator());
      final bool isHourActive = _zoom == 'hour';
      items.add(
        _buildBreadcrumbItem(
          label: _selectedDate,
          isActive: isHourActive,
          onTap: isHourActive
              ? null
              : () {
                  setState(() {
                    _zoom = 'hour';
                    _currentPage = 1;
                    _fetchGraphData();
                  });
                },
        ),
      );
    }

    // Hour
    if (_zoom == 'minute' || _zoom == 'second') {
      items.add(_buildBreadcrumbSeparator());
      final bool isMinuteActive = _zoom == 'minute';
      items.add(
        _buildBreadcrumbItem(
          label: '${_selectedHour.toString().padLeft(2, '0')}:00',
          isActive: isMinuteActive,
          onTap: isMinuteActive
              ? null
              : () {
                  setState(() {
                    _zoom = 'minute';
                    _currentPage = 1;
                    _fetchGraphData();
                  });
                },
        ),
      );
    }

    // Minute
    if (_zoom == 'second') {
      items.add(_buildBreadcrumbSeparator());
      items.add(
        _buildBreadcrumbItem(
          label: '${_selectedMinute.toString().padLeft(2, '0')}m',
          isActive: true,
          onTap: null,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: items,
        ),
      ),
    );
  }

  Widget _buildBreadcrumbItem({
    required String label,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            color: isActive ? _accent : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumbSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: Icon(
        Icons.chevron_right_rounded,
        size: 14,
        color: Color(0xFF94A3B8),
      ),
    );
  }

  Widget _buildMetricToggleBtn(bool isTemp, String label) {
    final isSelected = _showTemperature == isTemp;
    return GestureDetector(
      onTap: () {
        setState(() {
          _showTemperature = isTemp;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? _accent : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    final points = _graphData!.points;

    // Sort points chronologically to draw the line correctly
    final sortedPoints = List<TelemetryPoint>.from(points)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final List<FlSpot> spots = [];
    for (int i = 0; i < sortedPoints.length; i++) {
      final p = sortedPoints[i];
      final val = _showTemperature ? p.temperature : p.humidity;
      spots.add(FlSpot(i.toDouble(), val));
    }

    // Determine min and max Y for better spacing
    double minY = _showTemperature ? 0.0 : 0.0;
    double maxY = _showTemperature ? 40.0 : 100.0;
    if (spots.isNotEmpty) {
      final values = spots.map((s) => s.y).toList();
      final actualMin = values.reduce((a, b) => a < b ? a : b);
      final actualMax = values.reduce((a, b) => a > b ? a : b);
      minY = (actualMin - 2.0).clamp(_showTemperature ? -40.0 : 0.0, 100.0);
      maxY = (actualMax + 2.0).clamp(_showTemperature ? -40.0 : 0.0, 100.0);
    }

    final chartColor = _showTemperature ? _accent : const Color(0xFF0F52FF);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: ((maxY - minY) / 4).clamp(1.0, 50.0),
          getDrawingHorizontalLine: (value) =>
              FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                return Text(
                  "${value.toStringAsFixed(0)}${_showTemperature ? '°C' : '%'}",
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: (sortedPoints.length / 4).clamp(1.0, 100.0),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < sortedPoints.length) {
                  final t = sortedPoints[idx].timestamp;
                  String label = "";
                  if (_zoom == 'day') {
                    label = "${t.day}/${t.month}";
                  } else if (_zoom == 'hour') {
                    label = "${t.hour}:00";
                  } else if (_zoom == 'minute') {
                    label = "${t.hour}:${t.minute.toString().padLeft(2, '0')}";
                  } else {
                    label =
                        "${t.minute}:${t.second.toString().padLeft(2, '0')}";
                  }
                  return Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          getTouchedSpotIndicator:
              (LineChartBarData barData, List<int> spotIndexes) {
                return spotIndexes.map((spotIndex) {
                  return TouchedSpotIndicatorData(
                    FlLine(
                      color: chartColor.withOpacity(0.3),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                    ),
                    FlDotData(
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 6,
                          color: chartColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  );
                }).toList();
              },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF0F172A).withOpacity(0.9),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                final idx = touchedSpot.x.toInt();
                if (idx >= 0 && idx < sortedPoints.length) {
                  final p = sortedPoints[idx];
                  final timeStr =
                      "${p.timestamp.hour.toString().padLeft(2, '0')}:${p.timestamp.minute.toString().padLeft(2, '0')}:${p.timestamp.second.toString().padLeft(2, '0')}";
                  final statusStr = p.continuityOk ? "🟢 OK" : "🔴 EXCURSION";
                  final actionStr = _zoom == 'second'
                      ? ""
                      : "\n👉 Tap point to zoom in";
                  return LineTooltipItem(
                    "${_showTemperature ? 'Temp' : 'Hum'}: ${touchedSpot.y.toStringAsFixed(1)}${_showTemperature ? '°C' : '%'}\nTime: $timeStr\n$statusStr$actionStr",
                    GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
            if (event is FlTapUpEvent &&
                response != null &&
                response.lineBarSpots != null) {
              final spot = response.lineBarSpots!.first;
              final idx = spot.x.toInt();
              if (idx >= 0 && idx < sortedPoints.length) {
                final point = sortedPoints[idx];
                _handleDrillIn(point);
              }
            }
          },
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: chartColor,
            barWidth: 3,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  chartColor.withOpacity(0.15),
                  chartColor.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final p = sortedPoints[index];
                if (!p.continuityOk) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: const Color(0xFFEF4444),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                }
                return FlDotCirclePainter(
                  radius: 3,
                  color: chartColor,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleDrillIn(TelemetryPoint point) {
    if (_zoom == 'day') {
      setState(() {
        _zoom = 'hour';
        _selectedDate =
            "${point.timestamp.year}-${point.timestamp.month.toString().padLeft(2, '0')}-${point.timestamp.day.toString().padLeft(2, '0')}";
        _currentPage = 1;
        _fetchGraphData();
      });
    } else if (_zoom == 'hour') {
      setState(() {
        _zoom = 'minute';
        _selectedHour = point.timestamp.hour;
        _currentPage = 1;
        _fetchGraphData();
      });
    } else if (_zoom == 'minute') {
      setState(() {
        _zoom = 'second';
        _selectedMinute = point.timestamp.minute;
        _currentPage = 1;
        _fetchGraphData();
      });
    }
  }

  Widget _buildSummaryRow() {
    final meta = _graphData!.meta;
    return Column(
      children: [
        const Divider(color: Color(0xFFF1F5F9)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryMetric(
              'Avg Temp',
              "${meta.avgTemperature.toStringAsFixed(1)}°C",
            ),
            _buildSummaryMetric(
              'Min Temp',
              "${meta.minTemperature.toStringAsFixed(1)}°C",
            ),
            _buildSummaryMetric(
              'Max Temp',
              "${meta.maxTemperature.toStringAsFixed(1)}°C",
            ),
            _buildSummaryMetric(
              'Excursions',
              "${meta.excursionCount}",
              valueColor: meta.excursionCount > 0
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryMetric(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // ─── AI Analysis FAB ──────────────────────────────────────────

  Widget _buildAIFab(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF00ACC1), Color(0xFF00838F)],
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        heroTag: 'ai_analysis_fab',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AIAnalysisSheet(scanResult: widget.result),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
        label: Text(
          'AI Analysis',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ─── AI Quick Badge ───────────────────────────────────────────

  Widget _buildAIQuickBadge(CurrentConditionModel current, LifeModel life) {
    final bool isSafe =
        current.status == 'OK' &&
        life.totalExcursions == 0 &&
        life.healthScore >= 80;
    final modelService = sl<ModelService>();
    final bool aiReady = modelService.isModelActive;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSafe ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSafe
                ? const Color(0xFF10B981).withOpacity(0.3)
                : const Color(0xFFEF4444).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              aiReady ? Icons.auto_awesome : Icons.smart_toy_outlined,
              size: 16,
              color: isSafe ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                aiReady
                    ? (isSafe
                          ? '✅ AI Verdict: Safe to Ship'
                          : '⚠️ AI Verdict: Hold for Review')
                    : (isSafe ? '✅ Safe to Ship' : '⚠️ Hold for Review'),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSafe
                      ? const Color(0xFF059669)
                      : const Color(0xFFDC2626),
                ),
              ),
            ),
            if (aiReady)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'AI',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: _accent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Smart Alert Banner ───────────────────────────────────────

  Widget _buildSmartAlertBanner(
    CurrentConditionModel current,
    LifeModel life,
    ProductModel product,
  ) {
    final bool hasExcursions = life.totalExcursions > 0;
    final bool tempOutOfRange = current.status != 'OK';

    String alertTitle = 'Cold Chain Anomaly Detected';
    String alertBody = '';

    if (tempOutOfRange && hasExcursions) {
      alertBody =
          '${product.name} is currently at ${current.temperature}°C (required: ${product.storageRequirement}) '
          'with ${life.totalExcursions} recorded excursion(s). '
          'Immediate review is recommended to prevent product degradation.';
    } else if (tempOutOfRange) {
      alertBody =
          'Current temperature of ${current.temperature}°C is outside the required range '
          '(${product.storageRequirement}). Monitor closely and take corrective action.';
    } else if (hasExcursions) {
      alertTitle = 'Excursion History Alert';
      alertBody =
          '${life.totalExcursions} temperature excursion(s) have been recorded for this product. '
          'Health score is ${life.healthScore}%. Adjusted shelf life: ${life.adjustedDaysRemaining} days.';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFEF2F2),
              const Color(0xFFFFF7ED).withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFEF4444),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alertTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFB91C1C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alertBody,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF991B1B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) =>
                            AIAnalysisSheet(scanResult: widget.result),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00ACC1), Color(0xFF00838F)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Run AI Analysis',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
