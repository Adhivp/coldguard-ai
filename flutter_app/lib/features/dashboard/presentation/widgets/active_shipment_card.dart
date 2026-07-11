import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:code_card_ai/features/scanner/data/models/scan_result_model.dart';
import 'package:code_card_ai/features/scanner/presentation/pages/scan_result_page.dart';

class ShipmentData {
  final String title;
  final String batch;
  final String imageAsset;
  final IconData fallbackIcon;
  final String temp;
  final String humidity;
  final String location;
  final String status;
  final double progress;
  final Color tempColor;
  final Color tempBgColor;

  const ShipmentData({
    required this.title,
    required this.batch,
    required this.imageAsset,
    required this.fallbackIcon,
    required this.temp,
    required this.humidity,
    required this.location,
    required this.status,
    required this.progress,
    required this.tempColor,
    required this.tempBgColor,
  });
}

class ActiveShipmentCard extends StatelessWidget {
  const ActiveShipmentCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<ShipmentData> shipments = [
      const ShipmentData(
        title: 'Chicken Breast',
        batch: 'CB25071101',
        imageAsset: 'assets/chicken_breast.png',
        fallbackIcon: Icons.restaurant_rounded,
        temp: '4.2°C',
        humidity: '62%',
        location: 'Mumbai, India',
        status: 'In Transit',
        progress: 0.65,
        tempColor: Color(0xFFD81B60),
        tempBgColor: Color(0xFFFCE4EC),
      ),
      const ShipmentData(
        title: 'Fresh Salmon',
        batch: 'FS25071202',
        imageAsset: 'assets/salmon.jpg',
        fallbackIcon: Icons.set_meal_rounded,
        temp: '1.8°C',
        humidity: '78%',
        location: 'Goa, India',
        status: 'In Transit',
        progress: 0.40,
        tempColor: Color(0xFF10B981),
        tempBgColor: Color(0xFFECFDF5),
      ),
      const ShipmentData(
        title: 'Covid-19 Vaccine',
        batch: 'CV25071203',
        imageAsset: 'assets/vaccine.jpg',
        fallbackIcon: Icons.vaccines_rounded,
        temp: '-18.5°C',
        humidity: '25%',
        location: 'Delhi, India',
        status: 'In Transit',
        progress: 0.85,
        tempColor: Color(0xFF0F52FF),
        tempBgColor: Color(0xFFEFF6FF),
      ),
      const ShipmentData(
        title: 'Organic Milk',
        batch: 'OM25071204',
        imageAsset: 'assets/organic_milk.jpg',
        fallbackIcon: Icons.local_drink_rounded,
        temp: '3.5°C',
        humidity: '52%',
        location: 'Bangalore, India',
        status: 'Delivered',
        progress: 1.0,
        tempColor: Color(0xFF10B981),
        tempBgColor: Color(0xFFECFDF5),
      ),
    ];

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
                'Active Shipments',
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
          // Shipment list
          ...shipments.map(
            (shipment) => _buildShipmentItem(context, shipment, isDark, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentItem(
    BuildContext context,
    ShipmentData shipment,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Image Stack
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  shipment.imageAsset,
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
                        shipment.fallbackIcon,
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
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    children: [
                      TextSpan(text: shipment.title),
                      TextSpan(
                        text: '  •  Batch #${shipment.batch}',
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
                      label: shipment.temp,
                      color: shipment.tempColor,
                      bgColor: shipment.tempBgColor,
                    ),
                    _buildTag(
                      context,
                      icon: Icons.water_drop_rounded,
                      label: shipment.humidity,
                      color: const Color(0xFF0F52FF),
                      bgColor: const Color(0xFFEFF6FF),
                    ),
                    _buildTag(
                      context,
                      icon: Icons.location_on_rounded,
                      label: shipment.location,
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
                          decoration: BoxDecoration(
                            color: shipment.status == 'Delivered'
                                ? const Color(0xFF10B981)
                                : const Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          shipment.status,
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
                        child: LinearProgressIndicator(
                          value: shipment.progress,
                          minHeight: 4,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF00ACC1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // View Details link
                    GestureDetector(
                      onTap: () {
                        // Create matching ScanResultModel for the shipment
                        final scanResult = ScanResultModel(
                          product: ProductModel(
                            productId: shipment.batch.startsWith('CB')
                                ? 'PROD-CB01'
                                : (shipment.batch.startsWith('FS')
                                      ? 'PROD-FS02'
                                      : (shipment.batch.startsWith('CV')
                                            ? 'PROD-CV03'
                                            : 'PROD-OM04')),
                            name: shipment.title,
                            batchNumber: shipment.batch,
                            manufacturer: shipment.title == 'Chicken Breast'
                                ? 'MeatCare Foods Ltd'
                                : (shipment.title == 'Fresh Salmon'
                                      ? 'OceanHarvest Inc'
                                      : (shipment.title == 'Covid-19 Vaccine'
                                            ? 'BioVax Labs'
                                            : 'GreenValley Dairies')),
                            category: shipment.title == 'Chicken Breast'
                                ? 'Meat'
                                : (shipment.title == 'Fresh Salmon'
                                      ? 'Seafood'
                                      : (shipment.title == 'Covid-19 Vaccine'
                                            ? 'Pharmaceuticals'
                                            : 'Dairy')),
                            storageRequirement:
                                shipment.title == 'Chicken Breast'
                                ? '2°C to 6°C'
                                : (shipment.title == 'Fresh Salmon'
                                      ? '0°C to 4°C'
                                      : (shipment.title == 'Covid-19 Vaccine'
                                            ? '-25°C to -15°C'
                                            : '2°C to 6°C')),
                            manufacturedAt: '2026-07-10T12:00:00Z',
                            expiresAt: '2026-07-25T12:00:00Z',
                            currentLocation: shipment.location,
                          ),
                          current: CurrentConditionModel(
                            temperature:
                                double.tryParse(
                                  shipment.temp.replaceAll('°C', ''),
                                ) ??
                                0.0,
                            humidity:
                                double.tryParse(
                                  shipment.humidity.replaceAll('%', ''),
                                ) ??
                                0.0,
                            status: 'OK',
                            lastUpdated: DateTime.now().toIso8601String(),
                          ),
                          life: LifeModel(
                            daysRemaining: shipment.title == 'Covid-19 Vaccine'
                                ? 85
                                : 8,
                            healthScore: shipment.title == 'Chicken Breast'
                                ? 94
                                : (shipment.title == 'Fresh Salmon'
                                      ? 97
                                      : (shipment.title == 'Covid-19 Vaccine'
                                            ? 99
                                            : 92)),
                            estimatedExpiry: '2026-07-25T12:00:00Z',
                            adjustedDaysRemaining:
                                shipment.title == 'Covid-19 Vaccine' ? 85 : 7,
                            status: 'HEALTHY',
                            totalExcursions: shipment.title == 'Chicken Breast'
                                ? 1
                                : 0,
                          ),
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ScanResultPage(result: scanResult),
                          ),
                        );
                      },
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
