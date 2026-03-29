import 'package:flutter/material.dart';

// ── Classic board ────────────────────────────────────────────────────────────
const Map<int, int> kSnakes = {
  16: 6, 47: 26, 49: 11, 56: 53,
  62: 19, 64: 60, 87: 24, 93: 73, 95: 75, 99: 78,
};

const Map<int, int> kLadders = {
  4: 14, 9: 31, 20: 38, 28: 84,
  40: 59, 51: 67, 63: 81, 71: 91,
};

// ── Advanced: Safe zones (these snake-head squares are neutralised) ───────────
const Set<int> kSafeZones = {16, 47, 95};

// ── Advanced: Special tile types ─────────────────────────────────────────────
enum SpecialTile {
  bonusRoll,        // 🎲 extra roll immediately
  skipTurn,         // 💤 lose next turn
  swapPosition,     // 🔄 swap with a chosen player
  shieldPowerUp,    // 🛡️ collect a shield
  extraRollPowerUp, // ⚡ collect an extra-roll token
  skipOpponentPowerUp, // 🚫 collect skip-opponent token
  trap,             // 🪤 go back 3 steps
  boost,            // 🚀 go forward 3 steps
  teleport,         // 🌀 random square 1–99
}

// Advanced tile positions (no overlap with snakes/ladders)
const Map<int, SpecialTile> kAdvancedTiles = {
  // Bonus tiles
  25: SpecialTile.bonusRoll,
  55: SpecialTile.bonusRoll,
  78: SpecialTile.bonusRoll,
  // Skip turn
  30: SpecialTile.skipTurn,
  65: SpecialTile.skipTurn,
  // Swap
  45: SpecialTile.swapPosition,
  80: SpecialTile.swapPosition,
  // Power-up: Shield
  15: SpecialTile.shieldPowerUp,
  42: SpecialTile.shieldPowerUp,
  68: SpecialTile.shieldPowerUp,
  // Power-up: Extra roll
  33: SpecialTile.extraRollPowerUp,
  72: SpecialTile.extraRollPowerUp,
  // Power-up: Skip opponent
  58: SpecialTile.skipOpponentPowerUp,
  85: SpecialTile.skipOpponentPowerUp,
  // Trap
  22: SpecialTile.trap,
  37: SpecialTile.trap,
  76: SpecialTile.trap,
  // Boost
  13: SpecialTile.boost,
  44: SpecialTile.boost,
  82: SpecialTile.boost,
  // Teleport
  27: SpecialTile.teleport,
  61: SpecialTile.teleport,
  88: SpecialTile.teleport,
};

// Tile display metadata
extension SpecialTileDisplay on SpecialTile {
  String get emoji {
    switch (this) {
      case SpecialTile.bonusRoll: return '🎲';
      case SpecialTile.skipTurn: return '💤';
      case SpecialTile.swapPosition: return '🔄';
      case SpecialTile.shieldPowerUp: return '🛡️';
      case SpecialTile.extraRollPowerUp: return '⚡';
      case SpecialTile.skipOpponentPowerUp: return '🚫';
      case SpecialTile.trap: return '🪤';
      case SpecialTile.boost: return '🚀';
      case SpecialTile.teleport: return '🌀';
    }
  }

  Color get tileColor {
    switch (this) {
      case SpecialTile.bonusRoll: return const Color(0xFFFFD600);
      case SpecialTile.skipTurn: return const Color(0xFF78909C);
      case SpecialTile.swapPosition: return const Color(0xFFAB47BC);
      case SpecialTile.shieldPowerUp: return const Color(0xFF0288D1);
      case SpecialTile.extraRollPowerUp: return const Color(0xFFFF8F00);
      case SpecialTile.skipOpponentPowerUp: return const Color(0xFFE53935);
      case SpecialTile.trap: return const Color(0xFF6D4C41);
      case SpecialTile.boost: return const Color(0xFF00BCD4);
      case SpecialTile.teleport: return const Color(0xFF7E57C2);
    }
  }
}

// ── Players ───────────────────────────────────────────────────────────────────
const List<String> kAvatarEmojis = ['🦊', '🐼', '🐸', '🦁', '🐯', '🐧'];

const List<Color> kPlayerColors = [
  Color(0xFFE53935),
  Color(0xFF1E88E5),
  Color(0xFF43A047),
  Color(0xFFFF8F00),
  Color(0xFF8E24AA),
  Color(0xFFE91E63),
];

// ── Power-up types ────────────────────────────────────────────────────────────
enum PowerUp { shield, extraRoll, skipOpponent }

extension PowerUpDisplay on PowerUp {
  String get emoji {
    switch (this) {
      case PowerUp.shield: return '🛡️';
      case PowerUp.extraRoll: return '⚡';
      case PowerUp.skipOpponent: return '🚫';
    }
  }

  String get label {
    switch (this) {
      case PowerUp.shield: return 'Shield';
      case PowerUp.extraRoll: return 'Extra Roll';
      case PowerUp.skipOpponent: return 'Skip Opp.';
    }
  }
}