import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/game_data.dart';
import '../models/ball_type.dart';
import '../models/floating_text.dart';
import '../models/game_mode.dart';
import '../models/power_type.dart';
import '../models/spawned_power.dart';
import '../models/unlockable_background.dart';
import '../models/unlockable_skin.dart';
import '../widgets/game_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/glowing_ball.dart';
import '../widgets/power_icon.dart';
import '../widgets/shop_card.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final Random _random = Random();
  final AudioPlayer _tapPlayer = AudioPlayer(playerId: 'tap_player');
  final AudioPlayer _sfxPlayer = AudioPlayer(playerId: 'sfx_player');

  static const double hudHeight = 150;
  static const double hudTopPadding = 12;

  bool playing = false;
  bool freeze = false;
  bool doublePoints = false;
  bool doubleBall = false;
  bool magnet = false;
  bool slowmo = false;

  int timeLeft = 20;
  int score = 0;
  int bestScore = 0;
  int level = 1;
  int combo = 0;
  int bestCombo = 0;
  int coins = 0;
  int sessionCoins = 0;

  GameMode selectedMode = GameMode.classic;
  String selectedSkinKey = 'default';
  String selectedBackgroundKey = 'stars';
  Set<String> unlockedSkins = {'default'};
  Set<String> unlockedBackgrounds = {'stars'};

  double x = 120;
  double y = 220;
  double x2 = 200;
  double y2 = 300;

  BallType currentBallType = BallType.normal;
  BallType currentBallType2 = BallType.normal;

  double ballSize = 72;

  final List<SpawnedPower> powers = [];
  final List<FloatingText> floatingTexts = [];
  int powerId = 0;
  int floatingTextId = 0;

  Timer? secondTimer;
  Timer? worldTimer;
  Timer? freezeTimer;
  Timer? doublePointsTimer;
  Timer? doubleBallTimer;
  Timer? magnetTimer;
  Timer? slowmoTimer;

  bool disposed = false;
  DateTime? lastTapAt;
  int rapidTapStreak = 0;
  int _moveGeneration = 0;
  bool _movementScheduled = false;

  UnlockableSkin get currentSkin {
    return GameData.skins.firstWhere(
      (e) => e.key == selectedSkinKey,
      orElse: () => GameData.skins.first,
    );
  }

  UnlockableBackground get currentBackground {
    return GameData.backgrounds.firstWhere(
      (e) => e.key == selectedBackgroundKey,
      orElse: () => GameData.backgrounds.first,
    );
  }

  @override
  void initState() {
    super.initState();
    _tapPlayer.setReleaseMode(ReleaseMode.stop);
    _sfxPlayer.setReleaseMode(ReleaseMode.stop);
    loadSaveData();
    startWorldLoop();
  }

  Future<void> loadSaveData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      bestScore = prefs.getInt('best_score') ?? 0;
      bestCombo = prefs.getInt('best_combo') ?? 0;
      coins = prefs.getInt('coins') ?? 0;
      selectedSkinKey = prefs.getString('selected_skin') ?? 'default';
      selectedBackgroundKey = prefs.getString('selected_background') ?? 'stars';
      unlockedSkins = (prefs.getStringList('unlocked_skins') ?? ['default']).toSet();
      unlockedBackgrounds =
          (prefs.getStringList('unlocked_backgrounds') ?? ['stars']).toSet();
    });
  }

  Future<void> saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('best_score', bestScore);
    await prefs.setInt('best_combo', bestCombo);
    await prefs.setInt('coins', coins);
    await prefs.setString('selected_skin', selectedSkinKey);
    await prefs.setString('selected_background', selectedBackgroundKey);
    await prefs.setStringList('unlocked_skins', unlockedSkins.toList());
    await prefs.setStringList('unlocked_backgrounds', unlockedBackgrounds.toList());
  }

  void startWorldLoop() {
    worldTimer?.cancel();

    worldTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || disposed) return;
      if (floatingTexts.isEmpty && powers.isEmpty) return;

      bool changed = false;

      for (int i = floatingTexts.length - 1; i >= 0; i--) {
        final t = floatingTexts[i];
        t.position = Offset(t.position.dx, t.position.dy - 1.6);
        t.life -= 0.05;
        if (t.life <= 0) {
          floatingTexts.removeAt(i);
        }
        changed = true;
      }

      for (int i = powers.length - 1; i >= 0; i--) {
        final p = powers[i];
        p.life -= 0.05;
        if (p.life <= 0) {
          powers.removeAt(i);
        }
        changed = true;
      }

      if (changed) {
        setState(() {});
      }
    });
  }

  Future<void> playSimpleSfx(String path) async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource(path));
    } catch (_) {}
  }

  Future<void> playTapWithPitch(double rate) async {
    try {
      await _tapPlayer.stop();
      await _tapPlayer.play(AssetSource('audio/tap.mp3'));
      await _tapPlayer.setPlaybackRate(rate);
    } catch (_) {}
  }

  void cancelEffectTimers() {
    freezeTimer?.cancel();
    doublePointsTimer?.cancel();
    doubleBallTimer?.cancel();
    magnetTimer?.cancel();
    slowmoTimer?.cancel();
  }

  Future<void> startGame() async {
    cancelEffectTimers();

    setState(() {
      playing = true;
      freeze = false;
      doublePoints = false;
      doubleBall = false;
      magnet = false;
      slowmo = false;
      score = 0;
      combo = 0;
      level = 1;
      sessionCoins = 0;
      powers.clear();
      floatingTexts.clear();

      switch (selectedMode) {
        case GameMode.classic:
          timeLeft = 20;
          ballSize = 72;
          break;
        case GameMode.survival:
          timeLeft = 12;
          ballSize = 72;
          break;
        case GameMode.precision:
          timeLeft = 25;
          ballSize = 52;
          break;
        case GameMode.chaos:
          timeLeft = 20;
          ballSize = 68;
          break;
        case GameMode.performance:
          timeLeft = 18;
          ballSize = 72;
          break;
      }
    });

    await playSimpleSfx('audio/start.mp3');
    startRoundTimers();
    _moveGeneration++;
    _movementScheduled = false;
    moveBallLoop();
    spawnPowerLoop();
  }

  void startRoundTimers() {
    secondTimer?.cancel();
    secondTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!playing) {
        timer.cancel();
        return;
      }

      setState(() {
        timeLeft--;
      });

      if (timeLeft <= 0) {
        timer.cancel();
        endGame();
      }
    });
  }

  Rect playAreaBounds(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const paddingLeft = 8.0;
    const paddingRight = 8.0;
    const paddingBottom = 30.0;

    final safeTop = MediaQuery.of(context).padding.top;
    final topReserved = safeTop + hudHeight + hudTopPadding + 18;

    final width = max(10.0, size.width - ballSize - paddingLeft - paddingRight);
    final height = max(10.0, size.height - ballSize - topReserved - paddingBottom);

    return Rect.fromLTWH(paddingLeft, topReserved, width, height);
  }

  int movementDelay() {
    int base;
    switch (selectedMode) {
      case GameMode.classic:
        base = 980;
        break;
      case GameMode.survival:
        base = 1040;
        break;
      case GameMode.precision:
        base = 1120;
        break;
      case GameMode.chaos:
        base = 900;
        break;
      case GameMode.performance:
        base = 760;
        break;
    }

    final reduction = ((level - 1) * 10).clamp(0, 280);
    int result = base - reduction;
    if (slowmo) result += 280;

    return result.clamp(430, 1400);
  }

  int movementAnimationDuration() {
    final d = (movementDelay() * 0.82).round();
    return d.clamp(260, 900);
  }

  Offset randomPointInBounds(Rect bounds) {
    return Offset(
      _random.nextDouble() * bounds.width + bounds.left,
      _random.nextDouble() * bounds.height + bounds.top,
    );
  }

  Offset randomPointFarFrom({
    required Rect bounds,
    required Offset from,
    required double minDistance,
  }) {
    Offset candidate = randomPointInBounds(bounds);
    for (int i = 0; i < 8; i++) {
      if ((candidate - from).distance >= minDistance) return candidate;
      candidate = randomPointInBounds(bounds);
    }
    return candidate;
  }

  BallType randomBallType() {
    final r = _random.nextDouble();
    if (selectedMode == GameMode.chaos && r < 0.16) return BallType.danger;
    if (r < 0.58) return BallType.normal;
    if (r < 0.79) return BallType.fast;
    if (r < 0.92) return BallType.golden;
    return BallType.danger;
  }

  void moveBallLoop() {
    if (!playing || disposed) return;
    final int generation = ++_moveGeneration;
    _movementScheduled = true;

    void tick() {
      if (!playing || disposed) {
        _movementScheduled = false;
        return;
      }

      if (generation != _moveGeneration) {
        _movementScheduled = false;
        return;
      }

      if (freeze) {
        Future.delayed(const Duration(milliseconds: 140), tick);
        return;
      }

      final duration = movementDelay();
      final bounds = playAreaBounds(context);
      final minTravel = min(bounds.shortestSide * 0.48, 220.0);

      final target1 = randomPointFarFrom(
        bounds: bounds,
        from: Offset(x, y),
        minDistance: minTravel,
      );

      Offset? target2;
      if (doubleBall || selectedMode == GameMode.chaos) {
        target2 = randomPointFarFrom(
          bounds: bounds,
          from: Offset(x2, y2),
          minDistance: minTravel,
        );
      }

      if (!mounted) return;

      setState(() {
        x = target1.dx;
        y = target1.dy;
        currentBallType = randomBallType();

        if (doubleBall || selectedMode == GameMode.chaos) {
          x2 = target2!.dx;
          y2 = target2.dy;
          currentBallType2 = randomBallType();
        }
      });

      Future.delayed(Duration(milliseconds: duration), () {
        if (generation == _moveGeneration) {
          tick();
        }
      });
    }

    tick();
  }

  void spawnPowerLoop() {
    if (!playing || disposed) return;

    int delay;
    switch (selectedMode) {
      case GameMode.classic:
        delay = 2600;
        break;
      case GameMode.survival:
        delay = 1900;
        break;
      case GameMode.precision:
        delay = 3000;
        break;
      case GameMode.chaos:
        delay = 1500;
        break;
      case GameMode.performance:
        delay = 3400;
        break;
    }

    Future.delayed(Duration(milliseconds: delay), () {
      if (!playing || disposed) return;

        final count = selectedMode == GameMode.performance
          ? 1
          : selectedMode == GameMode.chaos
            ? 2 + _random.nextInt(2)
            : (_random.nextDouble() < 0.30 ? 2 : 1);

      for (int i = 0; i < count; i++) {
        spawnSinglePower();
      }

      spawnPowerLoop();
    });
  }

  void spawnSinglePower() {
    final bounds = playAreaBounds(context);

    powers.add(
      SpawnedPower(
        id: powerId++,
        type: weightedRandomPower(),
        x: _random.nextDouble() * bounds.width + bounds.left,
        y: _random.nextDouble() * bounds.height + bounds.top,
        life: 4.2,
      ),
    );
    setState(() {});
  }

  PowerType weightedRandomPower() {
    final r = _random.nextDouble();
    if (r < 0.38) return PowerType.time;
    if (r < 0.53) return PowerType.x2;
    if (r < 0.65) return PowerType.freeze;
    if (r < 0.77) return PowerType.doubleBall;
    if (r < 0.89) return PowerType.magnet;
    return PowerType.slowmo;
  }

  Color ballPrimary(BallType type) {
    switch (type) {
      case BallType.normal:
        return currentSkin.colors.first;
      case BallType.fast:
        return Colors.deepPurpleAccent;
      case BallType.golden:
        return Colors.amberAccent;
      case BallType.danger:
        return Colors.redAccent;
    }
  }

  Color ballSecondary(BallType type) {
    switch (type) {
      case BallType.normal:
        return currentSkin.colors.last;
      case BallType.fast:
        return Colors.purple;
      case BallType.golden:
        return Colors.orange;
      case BallType.danger:
        return Colors.red.shade900;
    }
  }

  void addFloatingText({
    required Offset position,
    required String text,
    required Color color,
  }) {
    floatingTexts.add(
      FloatingText(
        id: floatingTextId++,
        position: position,
        text: text,
        color: color,
        life: 0.75,
      ),
    );
  }

  Future<void> tapBall({required bool secondBall}) async {
    if (!playing) return;

    final type = secondBall ? currentBallType2 : currentBallType;
    final center = Offset(
      (secondBall ? x2 : x) + ballSize / 2,
      (secondBall ? y2 : y) + ballSize / 2,
    );

    final now = DateTime.now();
    if (lastTapAt != null && now.difference(lastTapAt!).inMilliseconds < 420) {
      rapidTapStreak++;
    } else {
      rapidTapStreak = 0;
    }
    lastTapAt = now;

    double pitch = 1.0 + (rapidTapStreak * 0.16);
    pitch = pitch.clamp(1.0, 2.2);
    await playTapWithPitch(pitch);

    int gainedPoints = 1;

    switch (type) {
      case BallType.normal:
        gainedPoints = 1;
        combo++;
        break;
      case BallType.fast:
        gainedPoints = 2;
        combo++;
        break;
      case BallType.golden:
        gainedPoints = 4;
        combo++;
        if (selectedMode == GameMode.survival) timeLeft += 1;
        break;
      case BallType.danger:
        gainedPoints = 0;
        combo = 0;
        timeLeft = max(0, timeLeft - 2);
        addFloatingText(
          position: center,
          text: '-2s',
          color: Colors.redAccent,
        );
        setState(() {});
        if (timeLeft <= 0) endGame();
        return;
    }

    if (doublePoints) gainedPoints *= 2;

    final comboBonus = combo >= 20
        ? 3
        : combo >= 12
            ? 2
            : combo >= 6
                ? 1
                : 0;

    gainedPoints += comboBonus;

    if (selectedMode == GameMode.survival) {
      timeLeft += 1;
    }

    sessionCoins += max(1, gainedPoints ~/ 2);

    addFloatingText(
      position: center,
      text: '+$gainedPoints',
      color: type == BallType.golden ? Colors.amberAccent : Colors.white,
    );

    setState(() {
      score += gainedPoints;
      level = (score ~/ 25) + 1;
      if (combo > bestCombo) bestCombo = combo;
    });
  }

  Future<void> tapNearBall(Offset tapPosition) async {
    if (!playing) return;

    // No castigar si tocó cerca de una bola.
    final center1 = Offset(x + ballSize / 2, y + ballSize / 2);
    if ((tapPosition - center1).distance < ballSize * 0.65) {
      return;
    }

    if (doubleBall || selectedMode == GameMode.chaos) {
      final center2 = Offset(x2 + ballSize / 2, y2 + ballSize / 2);
      if ((tapPosition - center2).distance < ballSize * 0.60) {
        return;
      }
    }

    // No castigar si tocó un boost.
    for (final power in powers) {
      final powerCenter = Offset(power.x + 23, power.y + 23);
      if ((tapPosition - powerCenter).distance < 28) {
        return;
      }
    }

    // Castigo por fallo.
    timeLeft = max(0, timeLeft - 1);
    combo = 0;

    addFloatingText(
      position: tapPosition,
      text: '-1s',
      color: Colors.redAccent,
    );

    setState(() {});

    if (timeLeft <= 0) {
      endGame();
      return;
    }

    // Magnet sigue ayudando si tocó "cerca", pero no exacto.
    if (!magnet) return;

    if ((tapPosition - center1).distance < 92) {
      await tapBall(secondBall: false);
      return;
    }

    if (doubleBall || selectedMode == GameMode.chaos) {
      final center2 = Offset(x2 + ballSize / 2, y2 + ballSize / 2);
      if ((tapPosition - center2).distance < 92) {
        await tapBall(secondBall: true);
      }
    }
  }

  Future<void> activatePower(SpawnedPower power) async {
    if (!playing) return;

    powers.removeWhere((p) => p.id == power.id);

    final center = Offset(power.x + 22, power.y + 22);
    await playSimpleSfx('audio/power.mp3');

    switch (power.type) {
      case PowerType.time:
        setState(() => timeLeft += selectedMode == GameMode.survival ? 6 : 5);
        addFloatingText(
          position: center,
          text: '+5s',
          color: Colors.greenAccent,
        );
        break;
      case PowerType.freeze:
        freeze = true;
        freezeTimer?.cancel();
        freezeTimer = Timer(const Duration(seconds: 3), () {
          freeze = false;
          if (playing && !_movementScheduled) {
            moveBallLoop();
          }
          setState(() {});
        });
        break;
      case PowerType.doubleBall:
        doubleBall = true;
        doubleBallTimer?.cancel();
        doubleBallTimer = Timer(const Duration(seconds: 7), () {
          doubleBall = false;
          setState(() {});
        });
        break;
      case PowerType.x2:
        doublePoints = true;
        doublePointsTimer?.cancel();
        doublePointsTimer = Timer(const Duration(seconds: 7), () {
          doublePoints = false;
          setState(() {});
        });
        break;
      case PowerType.magnet:
        magnet = true;
        magnetTimer?.cancel();
        magnetTimer = Timer(const Duration(seconds: 6), () {
          magnet = false;
          setState(() {});
        });
        break;
      case PowerType.slowmo:
        slowmo = true;
        slowmoTimer?.cancel();
        slowmoTimer = Timer(const Duration(seconds: 6), () {
          slowmo = false;
          setState(() {});
        });
        break;
    }

    setState(() {});
  }

  Future<void> endGame() async {
    if (!playing) return;

    playing = false;
    _moveGeneration++;
    _movementScheduled = false;
    secondTimer?.cancel();
    cancelEffectTimers();

    if (score > bestScore) bestScore = score;
    coins += sessionCoins;
    await saveProgress();
    await playSimpleSfx('audio/gameover.mp3');

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('🔥 Fin del juego'),
        content: Text(
          'Puntaje: $score\n'
          'Récord: $bestScore\n'
          'Combo máximo: $bestCombo\n'
          'Monedas ganadas: $sessionCoins\n'
          'Monedas totales: $coins',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  void buyOrSelectSkin(UnlockableSkin skin) async {
    if (unlockedSkins.contains(skin.key)) {
      setState(() => selectedSkinKey = skin.key);
      await saveProgress();
      return;
    }

    if (coins >= skin.price) {
      setState(() {
        coins -= skin.price;
        unlockedSkins.add(skin.key);
        selectedSkinKey = skin.key;
      });
      await saveProgress();
    }
  }

  void buyOrSelectBackground(UnlockableBackground bg) async {
    if (unlockedBackgrounds.contains(bg.key)) {
      setState(() => selectedBackgroundKey = bg.key);
      await saveProgress();
      return;
    }

    if (coins >= bg.price) {
      setState(() {
        coins -= bg.price;
        unlockedBackgrounds.add(bg.key);
        selectedBackgroundKey = bg.key;
      });
      await saveProgress();
    }
  }

  String modeLabel(GameMode mode) {
    switch (mode) {
      case GameMode.classic:
        return 'Clásico';
      case GameMode.survival:
        return 'Supervivencia';
      case GameMode.precision:
        return 'Precisión';
      case GameMode.chaos:
        return 'Caos';
      case GameMode.performance:
        return 'Rendimiento';
    }
  }

  String modeDescription(GameMode mode) {
    switch (mode) {
      case GameMode.classic:
        return '20 segundos, balanceado y directo.';
      case GameMode.survival:
        return 'Empiezas con poco tiempo y ganas tiempo al acertar.';
      case GameMode.precision:
        return 'Bolita más pequeña, más precisión.';
      case GameMode.chaos:
        return 'Más boosts, más bolas y más locura.';
      case GameMode.performance:
        return 'Menos carga visual y movimiento más fluido.';
    }
  }

  IconData modeIcon(GameMode mode) {
    switch (mode) {
      case GameMode.classic:
        return Icons.bolt;
      case GameMode.survival:
        return Icons.favorite;
      case GameMode.precision:
        return Icons.gps_fixed;
      case GameMode.chaos:
        return Icons.auto_awesome;
      case GameMode.performance:
        return Icons.speed;
    }
  }

  @override
  void dispose() {
    disposed = true;
    worldTimer?.cancel();
    secondTimer?.cancel();
    cancelEffectTimers();
    _tapPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: playing ? buildGame() : buildMenu(),
    );
  }

  Widget buildMenu() {
    return Stack(
      children: [
        GameBackground(background: currentBackground),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF67F7FF), Color(0xFFFF6AF3)],
                  ).createShader(bounds),
                  child: const Text(
                    'HYPERTAP\nLEGENDS',
                    style: TextStyle(
                      fontSize: 34,
                      height: 0.95,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      statChip('Récord', '$bestScore'),
                      statChip('Combo', '$bestCombo'),
                      statChip('Monedas', '$coins'),
                      statChip('Skin', currentSkin.name),
                      statChip('Fondo', currentBackground.name),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Modos de juego',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Column(
                  children: GameMode.values.map((mode) {
                    final selected = selectedMode == mode;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => selectedMode = mode),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected ? Colors.cyanAccent : Colors.white12,
                              width: 1.4,
                            ),
                            color: selected
                                ? Colors.cyanAccent.withOpacity(0.10)
                                : Colors.white.withOpacity(0.04),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                modeIcon(mode),
                                color: selected ? Colors.cyanAccent : Colors.white70,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      modeLabel(mode),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      modeDescription(mode),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.72),
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'START GAME',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Tienda de skins',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: GameData.skins.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final skin = GameData.skins[i];
                      final unlocked = unlockedSkins.contains(skin.key);
                      final selected = selectedSkinKey == skin.key;

                      return ShopCard(
                        title: skin.name,
                        subtitle: unlocked
                            ? (selected ? 'Equipada' : 'Desbloqueada')
                            : '${skin.price} monedas',
                        unlocked: unlocked,
                        selected: selected,
                        onTap: () => buyOrSelectSkin(skin),
                        preview: Image.asset(
                          skin.assetPath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.95),
                                    skin.colors.first,
                                    skin.colors.last,
                                  ],
                                  stops: const [0.06, 0.42, 1.0],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Tienda de fondos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: GameData.backgrounds.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final bg = GameData.backgrounds[i];
                      final unlocked = unlockedBackgrounds.contains(bg.key);
                      final selected = selectedBackgroundKey == bg.key;

                      return ShopCard(
                        title: bg.name,
                        subtitle: unlocked
                            ? (selected ? 'Equipado' : 'Desbloqueado')
                            : '${bg.price} monedas',
                        unlocked: unlocked,
                        selected: selected,
                        onTap: () => buyOrSelectBackground(bg),
                        preview: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            bg.assetPath,
                            width: 86,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return Container(
                                width: 86,
                                height: 52,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    colors: bg.fallbackColors,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildGame() {
    final animMs = movementAnimationDuration();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => tapNearBall(details.localPosition),
      child: Stack(
        children: [
          const RepaintBoundary(
            child: SizedBox.expand(),
          ),
          GameBackground(background: currentBackground),

          RepaintBoundary(
            child: Stack(
              children: [
                ...floatingTexts.map((t) {
                  final opacity = (t.life / t.maxLife).clamp(0.0, 1.0);
                  return Positioned(
                    left: t.position.dx,
                    top: t.position.dy,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: opacity,
                        child: Text(
                          t.text,
                          style: TextStyle(
                            color: t.color,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          AnimatedPositioned(
            duration: Duration(milliseconds: animMs),
            curve: Curves.fastOutSlowIn,
            left: x,
            top: y,
            child: RepaintBoundary(
              child: GlowingBall(
                size: ballSize,
                primary: ballPrimary(currentBallType),
                secondary: ballSecondary(currentBallType),
                skinAssetPath: currentSkin.assetPath,
                onTap: () => tapBall(secondBall: false),
              ),
            ),
          ),

          if (doubleBall || selectedMode == GameMode.chaos)
            AnimatedPositioned(
              duration: Duration(milliseconds: animMs),
              curve: Curves.fastOutSlowIn,
              left: x2,
              top: y2,
              child: RepaintBoundary(
                child: GlowingBall(
                  size: ballSize * 0.92,
                  primary: ballPrimary(currentBallType2),
                  secondary: ballSecondary(currentBallType2),
                  skinAssetPath: currentSkin.assetPath,
                  onTap: () => tapBall(secondBall: true),
                ),
              ),
            ),

          ...powers.map((power) {
            final opacity = (power.life / power.maxLife).clamp(0.0, 1.0);
            return Positioned(
              left: power.x,
              top: power.y,
              child: GestureDetector(
                onTap: () => activatePower(power),
                child: RepaintBoundary(
                  child: PowerIcon(
                    type: power.type,
                    opacity: opacity,
                  ),
                ),
              ),
            );
          }),

          SafeArea(
            child: RepaintBoundary(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, hudTopPadding, 16, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        topPill('Score', '$score'),
                        const SizedBox(width: 8),
                        topPill('Time', '$timeLeft'),
                        const SizedBox(width: 8),
                        topPill('Lvl', '$level'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        topPill('Combo', 'x$combo'),
                        const SizedBox(width: 8),
                        topPill('Modo', modeLabel(selectedMode)),
                        const SizedBox(width: 8),
                        topPill('Coins', '$sessionCoins'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (freeze) statusChip('Freeze', Colors.lightBlueAccent),
                        if (doublePoints) statusChip('x2', Colors.orangeAccent),
                        if (doubleBall || selectedMode == GameMode.chaos)
                          statusChip('Double', Colors.purpleAccent),
                        if (magnet) statusChip('Magnet', Colors.cyanAccent),
                        if (slowmo) statusChip('Slow', Colors.greenAccent),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 42,
            right: 12,
            child: IconButton(
              onPressed: endGame,
              icon: const Icon(Icons.close, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget topPill(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.28),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.65))),
            const SizedBox(height: 3),
            Text(value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget statusChip(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget statChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ],
      ),
    );
  }
}