import 'package:flutter/material.dart';

extension BuildContextExt on BuildContext {
  // Theme shortcut
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;

  // MediaQuery shortcuts
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  // Snackbar helper
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? colorScheme.error : colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
