import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../models/move_record.dart';
import '../colors/constants/board_data.dart';
import '../services/audio_service.dart';
import '../services/stats_service.dart';
import 'hotspot_multiplayer_provider.dart';

enum GameMode {
  classic,
  advanced,
  multiplayer,
}
enum GamePhase { setup, playing, pendingSwap, pendingSkipOpponent, finished }
enum GameEvent { none, snakeBite, ladderClimb, safeZone, shieldBlocked, trap, boost, teleport, bonusRoll }

class GameProvider extends ChangeNotifier {
  // ── Config ────────────────────────────────────────────────────
  List<Player> players = [];
  GameMode gameMode = GameMode.classic;
  bool doubleDiceMode = false; // advanced only: always roll 2 dice

  // ── Game state ────────────────────────────────────────────────
  int currentPlayerIndex = 0;
  int dice1 = 1;
  int dice2 = 1;
  bool useDoubleDice = false; // current roll toggle
  bool isRolling = false;
  bool isMoving = false;
  bool canRoll = true;
  int timerSeconds = 30;
  GamePhase phase = GamePhase.setup;
  Player? winner;
  String message = '';

  bool isHost = false;
  HotspotMultiplayerProvider? hotspotProvider;

  // ── Cutscene ──────────────────────────────────────────────────
  GameEvent currentEvent = GameEvent.none;

  // ── Dice history (last 5 rolls) ───────────────────────────────
  final List<Map<String, dynamic>> diceHistory = []; // {player, rolls, total}

  // ── Move history ──────────────────────────────────────────────
  final List<MoveRecord> moveHistory = [];

  // ── Pending UI interactions ───────────────────────────────────
  List<int> swapTargetIndices = []; // indices available to swap with
  int? pendingSwapForIndex;         // index of player who triggered swap
  int? pendingSkipForIndex;         // index of player who used skip

  // ── Internals ─────────────────────────────────────────────────
  Timer? _countdownTimer;
  Timer? _rollTimer;
  final Random _rnd = Random();
  final AudioService _audio = AudioService();
  final StatsService stats = StatsService();
  bool _cancelled = false;
  bool _disposed = false;

  Player get currentPlayer => players[currentPlayerIndex];

  // ── Init ──────────────────────────────────────────────────────
  GameProvider() { stats.load(); }

  void setGameMode(GameMode m) { gameMode = m; notifyListeners(); }
  void setDoubleDiceMode(bool v) { doubleDiceMode = v; notifyListeners(); }

  void setupHotspotHost(int playerCount, int turnTime, List<int> bonusTiles) {
    isHost = true;
    hotspotProvider = HotspotMultiplayerProvider(
      isHost: true,
      roomConfig: RoomConfig(
        maxPlayers: playerCount,
        turnTime: turnTime,
        bonusTiles: bonusTiles,
      ),
    );
    hotspotProvider!.startHosting();
  }

  void joinHotspot(String hostName) {
    isHost = false;
    hotspotProvider = HotspotMultiplayerProvider(isHost: false);
    hotspotProvider!.joinRoom(hostName);
    hotspotProvider!.onGameUpdate = _handleRemoteUpdate;
  }

  void _handleRemoteUpdate(GameStateUpdate update) {
    // Sync remote moves into your local game state
    diceValue = update.diceValue;
    currentPlayerIndex = update.currentPlayerIndex;
    playerPositions = update.playerPositions;
    notifyListeners();
  }

  void initPlayers(int count) {
    players = List.generate(count, (i) => Player(
      name: 'Player ${i + 1}',
      avatar: kAvatarEmojis[i],
      color: kPlayerColors[i],
    ));
    notifyListeners();
  }

  void updatePlayer(int i, {String? name, String? avatar, Color? color}) {
    if (i >= players.length) return;
    if (name != null) players[i].name = name;
    if (avatar != null) players[i].avatar = avatar;
    if (color != null) players[i].color = color;
    notifyListeners();
  }

  // ── Game flow ─────────────────────────────────────────────────
  void startGame() {
    _cancelled = false;
    currentPlayerIndex = 0;
    winner = null;
    message = "${players[0].name}'s turn — Roll!";
    phase = GamePhase.playing;
    canRoll = true;
    useDoubleDice = doubleDiceMode;
    diceHistory.clear();
    moveHistory.clear();
    _audio.playBGM();
    _startCountdown();
    notifyListeners();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    timerSeconds = 30;
    notifyListeners();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_disposed) { t.cancel(); return; }
      timerSeconds--;
      if (timerSeconds <= 0) { t.cancel(); _timeOut(); }
      notifyListeners();
    });
  }

  void _timeOut() {
    if (!canRoll) return;
    message = '⏰ ${currentPlayer.name} timed out!';
    canRoll = false;
    notifyListeners();
    _delayThen(2000, _nextTurn);
  }

  // ── Toggle double dice for current roll ───────────────────────
  void toggleDoubleDiceThisRoll() {
    if (!canRoll || isRolling || gameMode != GameMode.advanced) return;
    useDoubleDice = !useDoubleDice;
    notifyListeners();
  }

  // ── Roll ──────────────────────────────────────────────────────
  void rollDice() {
    if (!canRoll || isRolling || isMoving || phase != GamePhase.playing) return;
    _countdownTimer?.cancel();
    isRolling = true;
    canRoll = false;
    message = '🎲 Rolling…';
    _audio.playDiceRoll();
    notifyListeners();

    int tick = 0;
    const total = 16;
    _rollTimer = Timer.periodic(const Duration(milliseconds: 75), (t) {
      if (_disposed) { t.cancel(); return; }
      dice1 = _rnd.nextInt(6) + 1;
      if (useDoubleDice) dice2 = _rnd.nextInt(6) + 1;
      tick++;
      if (tick >= total) {
        t.cancel();
        isRolling = false;
        _processRoll();

        // Sync to clients if host
        if (isHost && hotspotProvider != null) {
          hotspotProvider!.sendUpdate(GameStateUpdate(
            diceValue: useDoubleDice ? dice1 + dice2 : dice1,
            currentPlayerIndex: currentPlayerIndex,
            playerPositions: players.map((p) => p.position).toList(),
          ));
        }
      }
      notifyListeners();
    });
  }
  void _processRoll() {
    final rolls = useDoubleDice ? [dice1, dice2] : [dice1];
    final total = rolls.fold(0, (a, b) => a + b);

    // Record in history
    diceHistory.insert(0, {
      'player': currentPlayer.name,
      'avatar': currentPlayer.avatar,
      'color': currentPlayer.color,
      'rolls': rolls,
      'total': total,
    });
    if (diceHistory.length > 5) diceHistory.removeLast();

    // Reset double dice flag for next turn
    useDoubleDice = doubleDiceMode;

    // Update move count
    currentPlayer.totalMoves++;

    final fromPos = currentPlayer.position;

    // Overshoot check
    if (fromPos + total > 100) {
      message = '🎯 ${currentPlayer.name} needs ${100 - fromPos} to win!';
      moveHistory.insert(0, MoveRecord(
        playerName: currentPlayer.name,
        playerAvatar: currentPlayer.avatar,
        playerColor: currentPlayer.color,
        diceRolls: rolls,
        fromPosition: fromPos,
        toPosition: fromPos,
        event: 'overshoot',
      ));
      notifyListeners();
      _delayThen(2000, _nextTurn);
      return;
    }

    notifyListeners();
    _animateStepByStep(fromPos, fromPos + total, rolls);
  }

  // ── Tile-by-tile animation ────────────────────────────────────
  Future<void> _animateStepByStep(int from, int to, List<int> rolls) async {
    isMoving = true;
    notifyListeners();
    final player = players[currentPlayerIndex];

    for (int pos = from + 1; pos <= to; pos++) {
      if (_cancelled || _disposed) return;
      player.position = pos;
      _audio.playMove();
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 250));
    }

    isMoving = false;
    if (_cancelled || _disposed) return;

    _checkLanding(from, to, rolls);
  }

  // ── Landing logic ─────────────────────────────────────────────
  void _checkLanding(int from, int to, List<int> rolls) {
    if (_cancelled || _disposed) return;
    final player = players[currentPlayerIndex];

    // Win condition
    if (to == 100) {
      _win(player, from, to, rolls);
      return;
    }

    // Snake check
    if (kSnakes.containsKey(to)) {
      // Safe zone in advanced mode neutralises this snake
      if (gameMode == GameMode.advanced && kSafeZones.contains(to)) {
        currentEvent = GameEvent.safeZone;
        message = '🛡️ Safe Zone! ${player.name} is protected!';
        _recordMove(from, to, rolls, 'safe_zone');
        notifyListeners();
        _delayThen(2000, () {
          currentEvent = GameEvent.none;
          notifyListeners();
          _nextTurn();
        });
        return;
      }

      // Shield power-up check
      if (player.powerUps.contains(PowerUp.shield)) {
        player.usePowerUp(PowerUp.shield);
        currentEvent = GameEvent.shieldBlocked;
        message = '🛡️ Shield saved ${player.name} from the snake!';
        _recordMove(from, to, rolls, 'shield_blocked');
        notifyListeners();
        _delayThen(2000, () {
          currentEvent = GameEvent.none;
          notifyListeners();
          _nextTurn();
        });
        return;
      }

      // Snake bites
      final snakeTo = kSnakes[to]!;
      currentEvent = GameEvent.snakeBite;
      message = '🐍 ${player.name} got bitten! $to → $snakeTo';
      player.snakesHit++;
      notifyListeners();
      _audio.playSnake();

      _delayThen(1200, () {
        if (_cancelled || _disposed) return;
        player.position = snakeTo;
        _recordMove(from, snakeTo, rolls, 'snake');
        notifyListeners();
        _delayThen(1500, () {
          currentEvent = GameEvent.none;
          notifyListeners();
          _nextTurn();
        });
      });
      return;
    }

    // Ladder check
    if (kLadders.containsKey(to)) {
      final ladderTo = kLadders[to]!;
      currentEvent = GameEvent.ladderClimb;
      message = '🪜 ${player.name} climbed! $to → $ladderTo';
      player.laddersClimbed++;
      notifyListeners();
      _audio.playLadder();

      _delayThen(1200, () {
        if (_cancelled || _disposed) return;
        player.position = ladderTo;
        _recordMove(from, ladderTo, rolls, 'ladder');
        notifyListeners();
        _delayThen(1500, () {
          currentEvent = GameEvent.none;
          notifyListeners();
          _nextTurn();
        });
      });
      return;
    }

    // Advanced: special tiles
    if (gameMode == GameMode.advanced) {
      final tile = kAdvancedTiles[to];
      if (tile != null) {
        _applySpecialTile(from, to, rolls, tile);
        return;
      }
    }

    // Normal square
    _recordMove(from, to, rolls, null);
    message = '${player.name} moved to $to';
    notifyListeners();
    _delayThen(1500, _nextTurn);
  }

  // ── Special tile effects ──────────────────────────────────────
  void _applySpecialTile(int from, int to, List<int> rolls, SpecialTile tile) {
    final player = players[currentPlayerIndex];
    _audio.playSpecial();

    switch (tile) {
      case SpecialTile.bonusRoll:
        currentEvent = GameEvent.bonusRoll;
        message = '🎲 ${player.name} gets a BONUS ROLL!';
        _recordMove(from, to, rolls, 'bonus_roll');
        notifyListeners();
        _delayThen(1500, () {
          if (_cancelled || _disposed) return;
          currentEvent = GameEvent.none;
          canRoll = true; // stay on current player, allow re-roll
          message = '🎲 ${player.name} — Roll again!';
          _startCountdown();
          notifyListeners();
        });
        break;

      case SpecialTile.skipTurn:
        player.skipNextTurn = true;
        message = '💤 ${player.name} loses their next turn!';
        _recordMove(from, to, rolls, 'skip_turn');
        notifyListeners();
        _delayThen(2000, _nextTurn);
        break;

      case SpecialTile.swapPosition:
        if (players.length < 2) {
          _recordMove(from, to, rolls, null);
          _delayThen(1500, _nextTurn);
          return;
        }
        pendingSwapForIndex = currentPlayerIndex;
        swapTargetIndices = [
          for (int i = 0; i < players.length; i++)
            if (i != currentPlayerIndex) i
        ];
        _recordMove(from, to, rolls, 'swap');
        message = '🔄 ${player.name} — Choose a player to SWAP with!';
        phase = GamePhase.pendingSwap;
        notifyListeners();
        break;

      case SpecialTile.shieldPowerUp:
        _grantPowerUp(from, to, rolls, PowerUp.shield, '🛡️ ${player.name} found a Shield!');
        break;
      case SpecialTile.extraRollPowerUp:
        _grantPowerUp(from, to, rolls, PowerUp.extraRoll, '⚡ ${player.name} found an Extra Roll!');
        break;
      case SpecialTile.skipOpponentPowerUp:
        _grantPowerUp(from, to, rolls, PowerUp.skipOpponent, '🚫 ${player.name} found Skip Opponent!');
        break;

      case SpecialTile.trap:
        currentEvent = GameEvent.trap;
        final trapTo = (to - 3).clamp(1, 99);
        message = '🪤 Trap! ${player.name} goes back 3 steps!';
        notifyListeners();
        _delayThen(800, () async {
          if (_cancelled || _disposed) return;
          // Animate stepping back
          for (int p = to - 1; p >= trapTo; p--) {
            if (_cancelled || _disposed) return;
            player.position = p;
            notifyListeners();
            await Future.delayed(const Duration(milliseconds: 200));
          }
          _recordMove(from, trapTo, rolls, 'trap');
          currentEvent = GameEvent.none;
          notifyListeners();
          _delayThen(1500, _nextTurn);
        });
        break;

      case SpecialTile.boost:
        currentEvent = GameEvent.boost;
        final boostSteps = _rnd.nextInt(4) + 2; // 2-5
        final boostTo = (to + boostSteps).clamp(1, 100);
        message = '🚀 Boost! ${player.name} zooms +$boostSteps steps!';
        notifyListeners();
        _delayThen(800, () async {
          if (_cancelled || _disposed) return;
          for (int p = to + 1; p <= boostTo; p++) {
            if (_cancelled || _disposed) return;
            player.position = p;
            notifyListeners();
            await Future.delayed(const Duration(milliseconds: 200));
          }
          _recordMove(from, boostTo, rolls, 'boost');
          currentEvent = GameEvent.none;
          notifyListeners();
          if (boostTo == 100) { _win(player, from, 100, rolls); return; }
          _delayThen(1500, _nextTurn);
        });
        break;

      case SpecialTile.teleport:
        currentEvent = GameEvent.teleport;
        final teleportTo = _rnd.nextInt(99) + 1;
        message = '🌀 TELEPORT! ${player.name} jumps to $teleportTo!';
        _delayThen(800, () {
          if (_cancelled || _disposed) return;
          player.position = teleportTo;
          _recordMove(from, teleportTo, rolls, 'teleport');
          currentEvent = GameEvent.none;
          notifyListeners();
          _delayThen(1500, _nextTurn);
        });
        notifyListeners();
        break;
    }
  }

  void _grantPowerUp(int from, int to, List<int> rolls, PowerUp p, String msg) {
    final player = players[currentPlayerIndex];
    player.addPowerUp(p);
    _audio.playPowerUp();
    message = msg;
    _recordMove(from, to, rolls, 'powerup_${p.name}');
    notifyListeners();
    _delayThen(2000, _nextTurn);
  }

  // ── Swap resolution (called from UI) ─────────────────────────
  void resolveSwap(int targetIndex) {
    if (phase != GamePhase.pendingSwap) return;
    final a = players[pendingSwapForIndex!];
    final b = players[targetIndex];
    final tmp = a.position;
    a.position = b.position;
    b.position = tmp;
    message = '🔄 ${a.name} ⇄ ${b.name} swapped!';
    pendingSwapForIndex = null;
    swapTargetIndices = [];
    phase = GamePhase.playing;
    notifyListeners();
    _delayThen(2000, _nextTurn);
  }

  // ── Use power-up (called from UI) ─────────────────────────────
  void useExtraRoll() {
    final player = players[currentPlayerIndex];
    if (!player.usePowerUp(PowerUp.extraRoll)) return;
    // Extra roll is used: allow another roll without advancing turn
    message = '⚡ ${player.name} uses Extra Roll!';
    canRoll = true;
    _startCountdown();
    notifyListeners();
  }

  void initiateSkipOpponent() {
    final player = players[currentPlayerIndex];
    if (!player.powerUps.contains(PowerUp.skipOpponent)) return;
    pendingSkipForIndex = currentPlayerIndex;
    swapTargetIndices = [
      for (int i = 0; i < players.length; i++)
        if (i != currentPlayerIndex) i
    ];
    phase = GamePhase.pendingSkipOpponent;
    message = '🚫 ${player.name} — Choose a player to SKIP!';
    notifyListeners();
  }

  void resolveSkipOpponent(int targetIndex) {
    if (phase != GamePhase.pendingSkipOpponent) return;
    final user = players[pendingSkipForIndex!];
    user.usePowerUp(PowerUp.skipOpponent);
    players[targetIndex].skipNextTurn = true;
    message = '🚫 ${players[targetIndex].name} will skip their next turn!';
    pendingSkipForIndex = null;
    swapTargetIndices = [];
    phase = GamePhase.playing;
    notifyListeners();
    _delayThen(1500, _nextTurn);
  }

  void cancelPending() {
    pendingSwapForIndex = null;
    pendingSkipForIndex = null;
    swapTargetIndices = [];
    phase = GamePhase.playing;
    notifyListeners();
    _delayThen(500, _nextTurn);
  }

  // ── Win ───────────────────────────────────────────────────────
  void _win(Player player, int from, int to, List<int> rolls) {
    _countdownTimer?.cancel();
    winner = player;
    phase = GamePhase.finished;
    currentEvent = GameEvent.none;
    message = '🎉 ${player.name} wins the game!';
    _recordMove(from, to, rolls, 'win');
    _audio.playWin();
    notifyListeners();

    // Persist stats
    for (final p in players) {
      stats.recordGame(
        name: p.name,
        avatar: p.avatar,
        won: p == player,
        totalMoves: p.totalMoves,
        snakesHit: p.snakesHit,
        laddersClimbed: p.laddersClimbed,
      );
    }
  }

  // ── Next turn ─────────────────────────────────────────────────
  void _nextTurn() {
    if (_cancelled || _disposed || phase == GamePhase.finished) return;
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;

    // Skip if marked
    if (currentPlayer.skipNextTurn) {
      currentPlayer.skipNextTurn = false;
      message = '💤 ${currentPlayer.name} skips their turn!';
      notifyListeners();
      _delayThen(1500, _nextTurn);
      return;
    }

    canRoll = true;
    useDoubleDice = doubleDiceMode;
    message = "${currentPlayer.name}'s turn — Roll!";
    _startCountdown();
    notifyListeners();
  }

  // ── Record move ───────────────────────────────────────────────
  void _recordMove(int from, int to, List<int> rolls, String? event) {
    moveHistory.insert(0, MoveRecord(
      playerName: currentPlayer.name,
      playerAvatar: currentPlayer.avatar,
      playerColor: currentPlayer.color,
      diceRolls: rolls,
      fromPosition: from,
      toPosition: to,
      event: event,
    ));
    if (moveHistory.length > 50) moveHistory.removeLast();
  }

  // ── Sound toggles ─────────────────────────────────────────────
  bool get musicEnabled => _audio.musicEnabled;
  bool get sfxEnabled => _audio.sfxEnabled;
  void toggleMusic() { _audio.toggleMusic(); notifyListeners(); }
  void toggleSFX() { _audio.toggleSFX(); notifyListeners(); }

  // ── Reset ─────────────────────────────────────────────────────
  void resetGame() {
    _cancelled = true;
    _countdownTimer?.cancel();
    _rollTimer?.cancel();
    _audio.stopBGM();
    for (final p in players) p.resetForNewGame();
    phase = GamePhase.setup;
    winner = null;
    message = '';
    canRoll = true;
    isRolling = false;
    isMoving = false;
    timerSeconds = 30;
    currentEvent = GameEvent.none;
    diceHistory.clear();
    moveHistory.clear();
    pendingSwapForIndex = null;
    pendingSkipForIndex = null;
    swapTargetIndices = [];
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────
  void _delayThen(int ms, VoidCallback fn) {
    Future.delayed(Duration(milliseconds: ms), () {
      if (!_cancelled && !_disposed) fn();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelled = true;
    _countdownTimer?.cancel();
    _rollTimer?.cancel();
    _audio.dispose();
    super.dispose();
  }
}