import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Collapsible thinking block for DeepSeek/Gemma 4 reasoning display.
class ThinkingBlock extends StatefulWidget {
  final String thinkingText;
  final bool isComplete;

  const ThinkingBlock({
    super.key,
    required this.thinkingText,
    this.isComplete = true,
  });

  @override
  State<ThinkingBlock> createState() => _ThinkingBlockState();
}

class _ThinkingBlockState extends State<ThinkingBlock>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _iconController;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _iconController.forward();
      } else {
        _iconController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Ambient colors matching the theme
    final baseColor = isDark ? const Color(0xFF2A273D) : const Color(0xFFF1F3F5);
    final borderColor = isDark ? const Color(0xFF383552) : const Color(0xFFE2E8F0);
    final accentColor = isDark ? const Color(0xFF9E77F1) : const Color(0xFF6366F1);
    final textColor = isDark ? const Color(0xFFA7A9BE) : const Color(0xFF475569);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (tappable)
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology_rounded,
                    size: 18,
                    color: accentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isComplete ? 'Thinking Process' : 'Thinking...',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (!widget.isComplete) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accentColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                  const Spacer(),
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5)
                        .animate(_iconController),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content (collapsible)
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(
                widget.thinkingText,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  height: 1.5,
                  color: textColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
