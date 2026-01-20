import 'package:flutter/material.dart';

class CustomDrawerTheme {
  final Color backgroundColor;
  final Color selectedItemColor;
  final Color unselectedItemColor;
  final Color selectedBackgroundColor;
  final Color dividerColor;
  final Color headerBackgroundColor;
  final Color headerTextColor;
  final Color sectionTitleColor;
  final double itemBorderRadius;
  final EdgeInsets itemPadding;
  final EdgeInsets sectionPadding;

  const CustomDrawerTheme({
    this.backgroundColor = const Color(0xFF1E1E2E),
    this.selectedItemColor = const Color(0xFFE91E63), // Pink color from image
    this.unselectedItemColor = const Color(0xFFE5E7EB),
    this.selectedBackgroundColor = const Color(
      0xFFE91E63,
    ), // Pink color from image
    this.dividerColor = const Color(0xFF2A2A3E),
    this.headerBackgroundColor = const Color(0xFF1E1E2E),
    this.headerTextColor = Colors.white,
    this.sectionTitleColor = const Color(0xFF6B7280),
    this.itemBorderRadius = 8.0,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    this.sectionPadding = const EdgeInsets.symmetric(vertical: 8),
  });

  static const CustomDrawerTheme dark = CustomDrawerTheme();

  static const CustomDrawerTheme light = CustomDrawerTheme(
    backgroundColor: Colors.white,
    selectedItemColor: Color(0xFFE91E63), // Pink color from image
    unselectedItemColor: Color(0xFF374151),
    selectedBackgroundColor: Color(0xFFE91E63), // Pink color from image
    dividerColor: Color(0xFFE5E7EB),
    headerBackgroundColor: Colors.white,
    headerTextColor: Color(0xFF111827),
    sectionTitleColor: Color(0xFF6B7280),
  );
}
