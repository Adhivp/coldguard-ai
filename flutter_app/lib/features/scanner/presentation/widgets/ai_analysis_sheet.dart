import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:code_card_ai/core/di/injection_container.dart';
import 'package:code_card_ai/features/chat/data/services/model_service.dart';
import 'package:code_card_ai/features/chat/data/models/model_info.dart';
import 'package:code_card_ai/features/scanner/data/models/scan_result_model.dart';

/// A premium bottom sheet that provides AI-powered cold chain analysis
/// using the on-device Gemma 4 E2B model.
class AIAnalysisSheet extends StatefulWidget {
  final ScanResultModel scanResult;

  const AIAnalysisSheet({super.key, required this.scanResult});

  @override
  State<AIAnalysisSheet> createState() => _AIAnalysisSheetState();
}

class _AIAnalysisSheetState extends State<AIAnalysisSheet> {
  static const Color _accent = Color(0xFF00ACC1);

  final Map<int, String> _results = {};
  final Map<int, bool> _loading = {};
  InferenceChat? _analysisChat;
  bool _initializing = false;

  final List<_AnalysisFeature> _features = const [
    _AnalysisFeature(
      title: 'Cold Chain Compliance',
      icon: Icons.verified_rounded,
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
      description: 'AI-generated compliance verdict with detailed reasoning',
    ),
    _AnalysisFeature(
      title: 'Risk Assessment',
      icon: Icons.shield_rounded,
      gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
      description: 'Risk level scoring with contributing factors',
    ),
    _AnalysisFeature(
      title: 'Predictive Shelf Life',
      icon: Icons.timeline_rounded,
      gradient: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      description: 'Estimated remaining usable shelf life',
    ),
    _AnalysisFeature(
      title: 'Recommended Actions',
      icon: Icons.checklist_rounded,
      gradient: [Color(0xFF3B82F6), Color(0xFF2563EB)],
      description: 'Actionable recommendations for your logistics team',
    ),
    _AnalysisFeature(
      title: 'Executive Summary',
      icon: Icons.summarize_rounded,
      gradient: [Color(0xFF00ACC1), Color(0xFF00838F)],
      description: 'Export-ready overview of cold chain status',
    ),
  ];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _features.length; i++) {
      _loading[i] = false;
      _results[i] = '';
    }
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    setState(() => _initializing = true);
    try {
      final modelService = sl<ModelService>();
      if (!modelService.isModelActive) {
        setState(() => _initializing = false);
        return;
      }
      final model = ModelCatalog.allModels.first;
      _analysisChat = await modelService.createAnalysisChat(model);
    } catch (e) {
      debugPrint('[AIAnalysis] Failed to initialize analysis chat: $e');
    }
    setState(() => _initializing = false);
  }

  String _buildPrompt(int featureIndex) {
    final product = widget.scanResult.product;
    final current = widget.scanResult.current;
    final life = widget.scanResult.life;

    final context = "Product: ${product.name} (${product.productId})\n"
        "Category: ${product.category}\n"
        "Manufacturer: ${product.manufacturer}\n"
        "Storage Requirement: ${product.storageRequirement}\n"
        "Current Temperature: ${current.temperature}°C\n"
        "Humidity: ${current.humidity}%\n"
        "Condition Status: ${current.status}\n"
        "Health Score: ${life.healthScore}%\n"
        "Total Excursions: ${life.totalExcursions}\n"
        "Days Remaining: ${life.daysRemaining}\n"
        "Adjusted Days Remaining: ${life.adjustedDaysRemaining}\n"
        "Life Status: ${life.status}\n";

    switch (featureIndex) {
      case 0:
        return "You are a cold chain compliance auditor. Based on the following product data, generate a compliance report. "
            "State the verdict (PASS, FAIL, or WARNING), then briefly explain your reasoning in under 3-4 sentences. "
            "Be concise and make sure to finish your response properly.\n\n$context";
      case 1:
        return "You are a cold chain risk analyst. Based on the following product data, assess the risk level as LOW, MEDIUM, HIGH, or CRITICAL. "
            "Briefly explain contributing factors in under 3 sentences. Be concise and make sure to finish your response properly.\n\n$context";
      case 2:
        return "You are a food/pharma shelf life scientist. Based on the following product data, estimate the remaining usable shelf life. "
            "Briefly explain the impact of temperature excursions in under 3 sentences. Be concise and make sure to finish your response properly.\n\n$context";
      case 3:
        return "You are a cold chain logistics advisor. Based on the following product data, provide 2-3 specific, actionable recommendations "
            "for the logistics team. Keep them short, concise, and complete.\n\n$context";
      case 4:
        return "You are a cold chain operations manager. Write a concise executive summary (1 short paragraph, under 4 sentences) of this product's cold chain status. "
            "Include key metrics, current condition, and risk factors. Be concise and make sure to finish your response properly.\n\n$context";
      default:
        return context;
    }
  }

  Future<void> _generateAnalysis(int index) async {
    if (_analysisChat == null || _loading[index] == true) return;

    setState(() {
      _loading[index] = true;
      _results[index] = '';
    });

    try {
      final prompt = _buildPrompt(index);
      await _analysisChat!.addQuery(
        Message.text(text: prompt, isUser: true),
      );

      final buffer = StringBuffer();
      await for (final chunk in _analysisChat!.generateChatResponseAsync()) {
        String text = '';
        if (chunk is TextResponse) {
          text = chunk.token ?? '';
        } else if (chunk is ThinkingResponse) {
          // Skip thinking content for analysis display
          continue;
        }
        text = text.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '');
        if (text.isNotEmpty) {
          buffer.write(text);
          setState(() => _results[index] = buffer.toString());
        }
      }
    } catch (e) {
      setState(() => _results[index] = '⚠️ Analysis failed: $e');
    }

    setState(() => _loading[index] = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F0E17) : const Color(0xFFF8FAFC),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF383552) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00ACC1), Color(0xFF00838F)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Product Analysis',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Powered by on-device Gemma 4 E2B',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? const Color(0xFFA7A9BE) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_initializing)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
                      ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(color: Color(0xFFE2E8F0)),
              ),

              // Content
              Expanded(
                child: _buildContent(isDark, scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(bool isDark, ScrollController scrollController) {
    final modelService = sl<ModelService>();

    if (!modelService.isModelActive) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology_alt_rounded, size: 48, color: _accent),
              ),
              const SizedBox(height: 20),
              Text(
                'AI Model Not Active',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please activate the Gemma 4 E2B model from the AI Assistant screen to enable product analysis.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      itemCount: _features.length,
      itemBuilder: (context, index) => _buildFeatureCard(index, isDark),
    );
  }

  Widget _buildFeatureCard(int index, bool isDark) {
    final feature = _features[index];
    final isLoading = _loading[index] == true;
    final hasResult = _results[index]?.isNotEmpty == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1C2A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF383552) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: feature.gradient[0].withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  feature.gradient[0].withOpacity(isDark ? 0.15 : 0.08),
                  feature.gradient[1].withOpacity(isDark ? 0.05 : 0.02),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: feature.gradient),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(feature.icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.title,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        feature.description,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark ? const Color(0xFFA7A9BE) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                // Generate / Regenerate button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: isLoading ? null : () => _generateAnalysis(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: isLoading
                            ? null
                            : LinearGradient(colors: feature.gradient),
                        color: isLoading
                            ? (isDark ? const Color(0xFF383552) : const Color(0xFFE2E8F0))
                            : null,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLoading)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            Icon(
                              hasResult ? Icons.refresh_rounded : Icons.auto_awesome,
                              color: Colors.white,
                              size: 14,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            isLoading
                                ? 'Analyzing...'
                                : (hasResult ? 'Regenerate' : 'Generate'),
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
                ),
              ],
            ),
          ),

          // Content area
          if (isLoading && !hasResult)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildShimmer(isDark),
            )
          else if (hasResult)
            Padding(
              padding: const EdgeInsets.all(16),
              child: MarkdownBody(
                data: _results[index]!,
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: GoogleFonts.inter(
                    color: isDark ? const Color(0xFFFFFFFE) : const Color(0xFF334155),
                    fontSize: 13,
                    height: 1.6,
                  ),
                  strong: GoogleFonts.inter(
                    color: isDark ? const Color(0xFFFFFFFE) : const Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  listBullet: GoogleFonts.inter(
                    color: isDark ? const Color(0xFFFFFFFE) : const Color(0xFF334155),
                    fontSize: 13,
                  ),
                  h1: GoogleFonts.outfit(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  h2: GoogleFonts.outfit(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  h3: GoogleFonts.outfit(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  blockquoteDecoration: BoxDecoration(
                    color: _accent.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(color: _accent, width: 3),
                    ),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                'Tap "Generate" to run AI analysis on this product.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? const Color(0xFFA7A9BE) : const Color(0xFF94A3B8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        4,
        (i) => Padding(
          padding: EdgeInsets.only(bottom: i < 3 ? 10 : 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            height: 14,
            width: i == 3 ? 120 : double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF383552).withOpacity(0.5)
                  : const Color(0xFFE2E8F0).withOpacity(0.7),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalysisFeature {
  final String title;
  final IconData icon;
  final List<Color> gradient;
  final String description;

  const _AnalysisFeature({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.description,
  });
}
