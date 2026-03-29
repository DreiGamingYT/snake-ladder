import 'package:flutter/material.dart';
import '../colors/constants/board_data.dart';

class Player {
  String name;
  String avatar;
  Color color;
  int position;

  // Power-ups (max 2 held at once)
  List<PowerUp> powerUps;

  // In-game state
  bool skipNextTurn;
  bool shieldActive; // auto-consumed when hitting snake

  // Session stats
  int totalMoves;
  int snakesHit;
  int laddersClimbed;
  int powerUpsUsed;

  Player({
    required this.name,
    required this.avatar,
    required this.color,
    this.position = 0,
    this.skipNextTurn = false,
    this.shieldActive = false,
    List<PowerUp>? powerUps,
    this.totalMoves = 0,
    this.snakesHit = 0,
    this.laddersClimbed = 0,
    this.powerUpsUsed = 0,
  }) : powerUps = powerUps ?? [];

  bool get hasPowerUp => powerUps.isNotEmpty;

  void addPowerUp(PowerUp p) {
    if (powerUps.length < 2) powerUps.add(p);
  }

  bool usePowerUp(PowerUp p) {
    if (powerUps.remove(p)) {
      powerUpsUsed++;
      return true;
    }
    return false;
  }

  void resetForNewGame() {
    position = 0;
    skipNextTurn = false;
    shieldActive = false;
    powerUps.clear();
    totalMoves = 0;
    snakesHit = 0;
    laddersClimbed = 0;
    powerUpsUsed = 0;
  }
}