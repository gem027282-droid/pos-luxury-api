import 'package:flutter/material.dart';

/// 2027 Neo-Glassmorphism Luxury Palette
class LuxuryColors {
  // Deep Obsidian Dark Space
  static const Color obsidianBackground = Color(0xFF08090E);
  static const Color obsidianSurface = Color(0xFF0F111A);
  static const Color obsidianCard = Color(0xFF141724);
  static const Color acrylicGlass = Color(0xFF141A29);

  // Radiant & Metallic Golds
  static const Color radiantGold = Color(0xFFE5B869);
  static const Color champagneGold = Color(0xFFF3D59B);
  static const Color darkGold = Color(0xFFB0893E);
  static const Color goldGlow = Color(0x33E5B869);

  // Luxury Royal Accents
  static const Color imperialCrimson = Color(0xFFC02638);
  static const Color emeraldCash = Color(0xFF10B981);
  static const Color sapphireCredit = Color(0xFF3B82F6);
  static const Color amethystSplit = Color(0xFF8B5CF6);

  // Typography & Content
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textGold = Color(0xFFE5B869);

  // Glassmorphic Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF7DEAB), Color(0xFFE5B869), Color(0xFFC29749)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient specularBorder = LinearGradient(
    colors: [
      Color(0x66FFFFFF),
      Color(0x1AFFFFFF),
      Color(0x05FFFFFF),
      Color(0x33E5B869),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.4, 0.8, 1.0],
  );

  static const LinearGradient glassFillGradient = LinearGradient(
    colors: [
      Color(0x8C141A29),
      Color(0x660F111A),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
