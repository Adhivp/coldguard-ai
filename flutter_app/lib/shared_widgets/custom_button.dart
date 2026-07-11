import 'package:flutter/material.dart';
import 'package:code_card_ai/core/theme/app_colors.dart';
import 'package:code_card_ai/core/theme/app_text_styles.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double height;
  final List<Color>? gradientColors;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 56.0,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final activeGradient = gradientColors ?? (isDark 
        ? [AppColors.darkPrimary, const Color(0xFFC084FC)] 
        : [AppColors.lightPrimary, const Color(0xFF818CF8)]);

    final isDisabled = onPressed == null || isLoading;

    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: isDisabled
            ? null
            : LinearGradient(
                colors: activeGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isDisabled ? (isDark ? Colors.grey[800] : Colors.grey[300]) : null,
        boxShadow: isDisabled
            ? []
            : [
                BoxShadow(
                  color: activeGradient.first.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: EdgeInsets.zero,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: AppTextStyles.button.copyWith(
                  color: isDisabled 
                      ? (isDark ? Colors.white38 : Colors.black38) 
                      : Colors.white,
                ),
              ),
      ),
    );
  }
}
