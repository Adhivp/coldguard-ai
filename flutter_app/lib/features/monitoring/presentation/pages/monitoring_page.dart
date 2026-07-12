import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:code_card_ai/core/di/injection_container.dart';
import 'package:code_card_ai/core/utils/responsive.dart';
import 'package:code_card_ai/features/scanner/data/models/product_summary_model.dart';
import 'package:code_card_ai/features/scanner/data/datasources/scan_remote_datasource.dart';
import 'package:code_card_ai/features/scanner/presentation/pages/scan_result_page.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  late Future<List<ProductSummaryModel>> _productsFuture;
  bool _isFetchingDetails = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'normal', 'excursion'

  @override
  void initState() {
    super.initState();
    _refreshProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshProducts() {
    setState(() {
      _productsFuture = sl<ScanRemoteDataSource>().getAllProducts();
    });
  }

  List<ProductSummaryModel> _getFilteredProducts(
    List<ProductSummaryModel> list,
  ) {
    return list.where((item) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch =
          item.productId.toLowerCase().contains(query) ||
          item.deviceId.toLowerCase().contains(query) ||
          item.name.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);

      final bool hasExcursion = !item.isWithinRange;

      bool matchesStatus = true;
      if (_filterStatus == 'normal') {
        matchesStatus = !hasExcursion;
      } else if (_filterStatus == 'excursion') {
        matchesStatus = hasExcursion;
      }

      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> _handleProductTap(String productId) async {
    if (_isFetchingDetails) return;

    setState(() {
      _isFetchingDetails = true;
    });

    try {
      final scanResult = await sl<ScanRemoteDataSource>().scanProduct(
        productId,
      );
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanResultPage(result: scanResult),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Failed to load details for product "$productId".';
        if (e.toString().contains('404')) {
          msg = 'Product details not found (404).';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    msg,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingDetails = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = Responsive.isMobile(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F0E17) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark
        ? const Color(0xFFA7A9BE)
        : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0E17)
          : const Color(0xFFF8FAFC),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF0E7490).withOpacity(0.35),
                    const Color(0xFF0F0E17),
                  ]
                : [const Color(0xFF0E7490), const Color(0xFFF8FAFC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.45],
          ),
        ),
        child: Stack(
          children: [
            // Content
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: RefreshIndicator(
                    onRefresh: () async {
                      _refreshProducts();
                      await _productsFuture.catchError(
                        (_) => <ProductSummaryModel>[],
                      );
                    },
                    color: const Color(0xFF00ACC1),
                    child: FutureBuilder<List<ProductSummaryModel>>(
                      future: _productsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF00ACC1),
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          final errStr = snapshot.error.toString();
                          final is404 = errStr.contains('404');
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.25,
                              ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: is404
                                            ? const Color(0xFFF1F5F9)
                                            : const Color(0xFFFEF2F2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        is404
                                            ? Icons.search_off_rounded
                                            : Icons.wifi_off_rounded,
                                        color: is404
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFFEF4444),
                                        size: 40,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      is404
                                          ? 'No Products Found (404)'
                                          : 'Failed to Load Products',
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32.0,
                                      ),
                                      child: Text(
                                        is404
                                            ? 'The server did not return any tracking products.'
                                            : 'Make sure you are connected to the network and try again. Error: $errStr',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: subTextColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton.icon(
                                      onPressed: _refreshProducts,
                                      icon: const Icon(
                                        Icons.refresh_rounded,
                                        size: 18,
                                      ),
                                      label: const Text('Retry'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF00ACC1,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }

                        final allProducts = snapshot.data ?? [];
                        final filteredProducts = _getFilteredProducts(
                          allProducts,
                        );

                        if (allProducts.isEmpty) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.25,
                              ),
                              Center(
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE0F7FA),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.inventory_2_outlined,
                                        color: Color(0xFF00ACC1),
                                        size: 40,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No Active Products',
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'There are no products currently active in the cold chain.',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: subTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }

                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16.0 : 24.0,
                            vertical: 20.0,
                          ),
                          children: [
                            // Page Titles
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Products',
                                      style: GoogleFonts.outfit(
                                        fontSize: isMobile ? 24 : 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'Active tracking nodes inside the supply chain',
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        color: Colors.white.withOpacity(0.85),
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    color: Colors.white,
                                  ),
                                  onPressed: _refreshProducts,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // KPI summary row
                            _buildKPISection(allProducts, isDark),

                            // Search and Filters
                            _buildSearchFilterRow(isDark),
                            const SizedBox(height: 20),

                            // Product List
                            filteredProducts.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 40.0,
                                      ),
                                      child: Text(
                                        'No products match search or filter rules.',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: subTextColor,
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: filteredProducts.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final item = filteredProducts[index];
                                      final bool hasExcursion =
                                          !item.isWithinRange;

                                      final statusColor = hasExcursion
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF10B981);
                                      final statusBg = hasExcursion
                                          ? const Color(0xFFFEF2F2)
                                          : const Color(0xFFECFDF5);

                                      return Card(
                                        elevation: 0,
                                        color: isDark
                                            ? const Color(0xFF1E293B)
                                            : Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          side: BorderSide(
                                            color: isDark
                                                ? const Color(0xFF334155)
                                                : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: InkWell(
                                          onTap: () =>
                                              _handleProductTap(item.productId),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(14.0),
                                            child: Row(
                                              children: [
                                                // Details
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // Product name
                                                      Text(
                                                        item.name.isNotEmpty
                                                            ? item.name
                                                            : item.productId,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style:
                                                            GoogleFonts.outfit(
                                                              fontSize: 15.5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: textColor,
                                                            ),
                                                      ),
                                                      const SizedBox(height: 3),
                                                      // Product ID + Category
                                                      Row(
                                                        children: [
                                                          Text(
                                                            item.productId,
                                                            style: GoogleFonts.inter(
                                                              fontSize: 11,
                                                              color:
                                                                  subTextColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                          if (item
                                                              .category
                                                              .isNotEmpty) ...[
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        6,
                                                                  ),
                                                              child: Text(
                                                                '•',
                                                                style: GoogleFonts.inter(
                                                                  fontSize: 11,
                                                                  color:
                                                                      subTextColor,
                                                                ),
                                                              ),
                                                            ),
                                                            Flexible(
                                                              child: Text(
                                                                item.category,
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: GoogleFonts.inter(
                                                                  fontSize: 11,
                                                                  color:
                                                                      subTextColor,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),

                                                      // Metrics badges row
                                                      Row(
                                                        children: [
                                                          _buildBadge(
                                                            icon: Icons
                                                                .thermostat_rounded,
                                                            label:
                                                                '${item.latestTemperature.toStringAsFixed(1)}°C',
                                                            color: statusColor,
                                                            bgColor: statusBg,
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          _buildBadge(
                                                            icon: Icons
                                                                .bar_chart_rounded,
                                                            label:
                                                                '${item.totalReadings} pnts',
                                                            color: const Color(
                                                              0xFF00ACC1,
                                                            ),
                                                            bgColor:
                                                                const Color(
                                                                  0xFFE0F7FA,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),

                                                      // Last sync time
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons.wifi_rounded,
                                                            size: 11,
                                                            color: isDark
                                                                ? const Color(
                                                                    0xFF10B981,
                                                                  ).withOpacity(
                                                                    0.8,
                                                                  )
                                                                : const Color(
                                                                    0xFF10B981,
                                                                  ),
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              'Last Sync: ${_formatReadingTime(item.latestReadingTs)}',
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: GoogleFonts.inter(
                                                                fontSize: 10,
                                                                color:
                                                                    subTextColor,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // Interactive Arrow Button Container
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? const Color(
                                                            0xFF2D3748,
                                                          )
                                                        : const Color(
                                                            0xFFF1F5F9,
                                                          ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.arrow_forward_rounded,
                                                    color: Color(0xFF00ACC1),
                                                    size: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Loading overlay when fetching details
            if (_isFetchingDetails)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF00ACC1),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Syncing cold chain record...',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPISection(List<ProductSummaryModel> products, bool isDark) {
    final total = products.length;
    final normal = products.where((e) => e.isWithinRange).length;
    final alerts = total - normal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildKPICard(
              title: 'Total Items',
              value: '$total',
              color: const Color(0xFF00ACC1),
              icon: Icons.inventory_2_rounded,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildKPICard(
              title: 'In Range',
              value: '$normal',
              color: const Color(0xFF10B981),
              icon: Icons.gpp_good_rounded,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildKPICard(
              title: 'Excursions',
              value: '$alerts',
              color: const Color(0xFFEF4444),
              icon: Icons.error_outline_rounded,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFFA7A9BE)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilterRow(bool isDark) {
    return Column(
      children: [
        // Search Input
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search product ID or device...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: const Color(0xFF94A3B8),
                    ),

                    fillColor: Colors.white,
                  ),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF64748B),
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Status Tabs/Chips
        Row(
          children: [
            _buildFilterChip('all', 'All Nodes', isDark),
            const SizedBox(width: 8),
            _buildFilterChip('normal', 'Secure Only', isDark),
            const SizedBox(width: 8),
            _buildFilterChip('excursion', 'Excursions', isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String status, String label, bool isDark) {
    final isSelected = _filterStatus == status;
    Color activeColor = const Color(0xFF00ACC1);
    if (status == 'normal') activeColor = const Color(0xFF10B981);
    if (status == 'excursion') activeColor = const Color(0xFFEF4444);

    return GestureDetector(
      onTap: () {
        setState(() {
          _filterStatus = status;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.12)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? activeColor
                : (isDark ? const Color(0xFFA7A9BE) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(double temp, bool hasExcursion, bool isDark) {
    final startColor = hasExcursion
        ? const Color(0xFFEF4444)
        : const Color(0xFF00ACC1);
    final endColor = hasExcursion
        ? const Color(0xFFFF5252)
        : const Color(0xFF0F52FF);

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: startColor.withOpacity(0.24),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
            ),
            child: Icon(
              hasExcursion
                  ? Icons.warning_amber_rounded
                  : Icons.gpp_good_rounded,
              color: startColor,
              size: 22,
            ),
          ),
          if (hasExcursion)
            // Small pulsing beacon
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEF4444),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatReadingTime(DateTime dt) {
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
    final year = dt.year;
    final month = monthNames[dt.month - 1];
    final day = dt.day;
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$month $day, $year $hour:$min';
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
