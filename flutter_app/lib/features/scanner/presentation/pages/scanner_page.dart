import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:code_card_ai/core/di/injection_container.dart';
import 'package:code_card_ai/features/scanner/data/datasources/scan_remote_datasource.dart';
import 'package:code_card_ai/features/scanner/data/datasources/scan_local_datasource.dart';
import 'package:code_card_ai/features/scanner/presentation/pages/scan_result_page.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with SingleTickerProviderStateMixin {
  late MobileScannerController _scannerController;
  bool _isFlashOn = false;
  bool _isQrMode = true; // true = QR Code, false = Barcode
  bool _isLoading = false;
  
  late AnimationController _lineAnimationController;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
    
    // Animation for the scanning line
    _lineAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _lineAnimationController.dispose();
    super.dispose();
  }

  Future<void> _handleScan(String code) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // Stop camera feed temporarily
    await _scannerController.stop();

    try {
      final remoteDataSource = sl<ScanRemoteDataSource>();
      
      String targetId = code.trim();
      if (targetId.isEmpty) {
        throw Exception('Scanned code is empty');
      }

      final scanResult = await remoteDataSource.scanProduct(targetId);
      
      // Save scan to local history
      await sl<ScanLocalDataSource>().saveScanResult(scanResult);
      
      if (mounted) {
        // Navigate to result screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ScanResultPage(result: scanResult),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Scan failed: Unable to fetch data for "$code".';
        if (e.toString().contains('404')) {
          msg = 'Product not found (404): "$code" is invalid.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    msg,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
        // Resume scanning
        setState(() {
          _isLoading = false;
        });
        _scannerController.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanAreaSize = _isQrMode ? 240.0 : 160.0;
    final scanAreaWidth = _isQrMode ? 240.0 : 280.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Mobile Scanner View
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? code = barcode.rawValue;
                if (code != null) {
                  _handleScan(code);
                  break;
                }
              }
            },
          ),

          // 2. Dark semi-transparent overlay surrounding the scan area
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: scanAreaWidth,
                    height: scanAreaSize,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Scanner Border/Notch frame
          Align(
            alignment: Alignment.center,
            child: Container(
              width: scanAreaWidth,
              height: scanAreaSize,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF0F52FF),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  // Animated Scanning Horizontal Line
                  AnimatedBuilder(
                    animation: _lineAnimationController,
                    builder: (context, child) {
                      final offset = _lineAnimationController.value * (scanAreaSize - 6);
                      return Positioned(
                        top: offset,
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withOpacity(0.8),
                                blurRadius: 8,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 4. Instructions and mode selector (top and bottom)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                // Heading
                Text(
                  _isQrMode ? 'QR Scanner' : 'Barcode Scanner',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Flashlight toggle
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      color: _isFlashOn ? Colors.yellow : Colors.white,
                    ),
                    onPressed: () async {
                      await _scannerController.toggleTorch();
                      setState(() {
                        _isFlashOn = !_isFlashOn;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Lower Controls
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Instruction Text
                Text(
                  _isQrMode
                      ? 'Align QR Code inside the frame'
                      : 'Align Barcode inside the frame',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),

                // Mode Toggle Button (QR vs Barcode)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildModeButton(
                      label: 'QR Code',
                      icon: Icons.qr_code_2_rounded,
                      isActive: _isQrMode,
                      onTap: () => setState(() => _isQrMode = true),
                    ),
                    const SizedBox(width: 16),
                    _buildModeButton(
                      label: 'Barcode',
                      icon: Icons.view_column_rounded,
                      isActive: !_isQrMode,
                      onTap: () => setState(() => _isQrMode = false),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.75),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F52FF)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Fetching product details...',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0F52FF) : Colors.black54,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isActive ? const Color(0xFF0F52FF) : Colors.white24,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
