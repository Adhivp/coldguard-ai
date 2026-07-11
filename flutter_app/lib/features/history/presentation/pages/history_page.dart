import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:code_card_ai/core/di/injection_container.dart';
import 'package:code_card_ai/core/utils/responsive.dart';
import 'package:code_card_ai/features/scanner/data/datasources/scan_local_datasource.dart';
import 'package:code_card_ai/features/scanner/data/models/scan_result_model.dart';
import 'package:code_card_ai/features/scanner/presentation/pages/scan_result_page.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    bool isMobile = Responsive.isMobile(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0E17)
          : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16.0 : 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'History Logs',
                              style: GoogleFonts.outfit(
                                fontSize: isMobile ? 26 : 30,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Historical scan activity',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark
                                    ? const Color(0xFFA7A9BE)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_sweep_rounded,
                          color: Colors.redAccent,
                          size: 26,
                        ),
                        tooltip: 'Clear Scan History',
                        onPressed: _clearHistoryDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tab Content (Only Scan History now)
                  Expanded(child: _buildScanHistoryView(isDark)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanHistoryView(bool isDark) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: sl<ScanLocalDataSource>().getScanHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00ACC1)),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading history: ${snapshot.error}',
              style: GoogleFonts.inter(color: Colors.redAccent),
            ),
          );
        }
        final history = snapshot.data ?? [];
        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE0F7FA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 56,
                    color: Color(0xFF00ACC1),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Scans Yet',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'Scan a product cold-chain card to save its parameters and monitor status updates locally.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark
                          ? const Color(0xFFA7A9BE)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: history.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final entry = history[index];
            final result = ScanResultModel.fromJson(
              entry['result'] as Map<String, dynamic>,
            );
            final scannedAt = DateTime.parse(entry['scanned_at'] as String);

            final product = result.product;
            final current = result.current;
            final isOk = current.status == 'OK';

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScanResultPage(result: result),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.01),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Status Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isOk
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFEF2F2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isOk
                            ? Icons.check_circle_outline_rounded
                            : Icons.warning_amber_rounded,
                        color: isOk
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Batch #${product.batchNumber}  •  ${product.category}',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: isDark
                                  ? const Color(0xFFA7A9BE)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              _buildMiniBadge(
                                icon: Icons.thermostat_rounded,
                                label:
                                    '${current.temperature.toStringAsFixed(1)}°C',
                                color:
                                    current.temperature >= 2 &&
                                        current.temperature <= 8
                                    ? const Color(0xFF00ACC1)
                                    : const Color(0xFFEF4444),
                                isDark: isDark,
                              ),
                              const SizedBox(width: 6),
                              _buildMiniBadge(
                                icon: Icons.water_drop_rounded,
                                label:
                                    '${current.humidity.toStringAsFixed(1)}%',
                                color: const Color(0xFF0F52FF),
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Time and Chevron
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatScannedAt(scannedAt),
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFFA7A9BE)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF00ACC1),
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMiniBadge({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D3748) : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
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

  String _formatScannedAt(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 30) {
      return 'Just now';
    } else if (diff.inMinutes < 1) {
      return '1m ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24 && dt.day == now.day) {
      final minutes = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      return 'Today, $hour:$minutes $ampm';
    } else {
      final monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final day = dt.day;
      final month = monthNames[dt.month - 1];
      final minutes = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      return '$month $day, $hour:$minutes $ampm';
    }
  }

  Future<void> _clearHistoryDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear Scan History?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will delete all scanned product logs permanently.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Clear All',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await sl<ScanLocalDataSource>().clearScanHistory();
      setState(() {});
    }
  }
}
