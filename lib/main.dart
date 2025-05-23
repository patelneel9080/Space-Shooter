import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const SpaceShooterApp());
}

class SpaceShooterApp extends StatelessWidget {
  const SpaceShooterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Space Shooter',
      theme: ThemeData.dark(),
      home: const SpaceShooterGame(),
    );
  }
}

class SpaceShooterGame extends StatefulWidget {
  const SpaceShooterGame({Key? key}) : super(key: key);

  @override
  State<SpaceShooterGame> createState() => _SpaceShooterGameState();
}

class _SpaceShooterGameState extends State<SpaceShooterGame> with SingleTickerProviderStateMixin {
  static const double playerSize = 40;
  static const double asteroidSize = 30;
  static const double bulletSize = 8;
  static const double moveStep = 5;
  static const double bulletSpeed = 10;
  static const double asteroidSpeed = 3;
  static const int gameTickMs = 16;
  static const int spawnIntervalMs = 1000;
  static const int shootCooldownMs = 300;

  double playerX = 0.0;
  double playerY = 0.0;
  double playerVelocityX = 0.0;
  double playerVelocityY = 0.0;
  List<Offset> asteroids = [];
  List<Offset> bullets = [];
  int score = 0;
  bool isGameOver = false;
  Timer? gameTimer;
  Timer? spawnTimer;
  Timer? shootCooldown;
  bool canShoot = true;
  late double screenWidth;
  late double screenHeight;
  final Random rand = Random();
  final Set<LogicalKeyboardKey> pressedKeys = {};
  late AnimationController _controller;
  DateTime lastFireTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_update);
    _controller.repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => startGame());
  }

  void startGame() {
    setState(() {
      isGameOver = false;
      score = 0;
      asteroids.clear();
      bullets.clear();
      final size = MediaQuery.of(context).size;
      screenWidth = size.width;
      screenHeight = size.height;
      playerX = screenWidth / 2;
      playerY = screenHeight - playerSize - 16;
    });
    gameTimer?.cancel();
    spawnTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: gameTickMs), (_) => gameTick());
    spawnTimer = Timer.periodic(const Duration(milliseconds: spawnIntervalMs), (_) => spawnAsteroid());
  }

  void endGame() {
    gameTimer?.cancel();
    spawnTimer?.cancel();
    setState(() {
      isGameOver = true;
    });
  }

  void gameTick() {
    if (isGameOver) return;
    setState(() {
      // Reset velocity
      playerVelocityX = 0;
      playerVelocityY = 0;

      // Handle keyboard input for movement
      if (pressedKeys.contains(LogicalKeyboardKey.arrowLeft) || 
          pressedKeys.contains(LogicalKeyboardKey.keyA)) {
        playerVelocityX = -moveStep;
      }
      if (pressedKeys.contains(LogicalKeyboardKey.arrowRight) || 
          pressedKeys.contains(LogicalKeyboardKey.keyD)) {
        playerVelocityX = moveStep;
      }
      if (pressedKeys.contains(LogicalKeyboardKey.arrowUp) || 
          pressedKeys.contains(LogicalKeyboardKey.keyW)) {
        playerVelocityY = -moveStep;
      }
      if (pressedKeys.contains(LogicalKeyboardKey.arrowDown) || 
          pressedKeys.contains(LogicalKeyboardKey.keyS)) {
        playerVelocityY = moveStep;
      }

      // Apply diagonal movement normalization
      if (playerVelocityX != 0 && playerVelocityY != 0) {
        final factor = 1 / sqrt(2);
        playerVelocityX *= factor;
        playerVelocityY *= factor;
      }

      // Update player position
      playerX = (playerX + playerVelocityX).clamp(playerSize, screenWidth - playerSize);
      playerY = (playerY + playerVelocityY).clamp(playerSize, screenHeight - playerSize);

      // Move bullets
      for (int i = bullets.length - 1; i >= 0; i--) {
        bullets[i] = Offset(bullets[i].dx, bullets[i].dy - bulletSpeed);
        if (bullets[i].dy < -bulletSize) {
          bullets.removeAt(i);
        }
      }

      // Move asteroids
      for (int i = asteroids.length - 1; i >= 0; i--) {
        asteroids[i] = Offset(asteroids[i].dx, asteroids[i].dy + asteroidSpeed);
        if (asteroids[i].dy > screenHeight + asteroidSize) {
          asteroids.removeAt(i);
          continue;
        }

        // Check bullet collisions
        for (int j = bullets.length - 1; j >= 0; j--) {
          if ((asteroids[i] - bullets[j]).distance < asteroidSize + bulletSize) {
            asteroids.removeAt(i);
            bullets.removeAt(j);
            score += 10;
            break;
          }
        }

        // Check player collision
        if (i < asteroids.length && (asteroids[i] - Offset(playerX, playerY)).distance < playerSize + asteroidSize) {
          endGame();
          return;
        }
      }
    });
  }

  void spawnAsteroid() {
    if (isGameOver) return;
    setState(() {
      double x = rand.nextDouble() * (screenWidth - 2 * asteroidSize) + asteroidSize;
      asteroids.add(Offset(x, -asteroidSize));
    });
  }

  void shoot() {
    if (!canShoot) return;
    setState(() {
      bullets.add(Offset(playerX, playerY - playerSize));
      canShoot = false;
      shootCooldown?.cancel();
      shootCooldown = Timer(const Duration(milliseconds: shootCooldownMs), () {
        canShoot = true;
      });
    });
  }

  void _update() {
    if (isGameOver) return;

    setState(() {
      // Reset velocity
      playerVelocityX = 0;
      playerVelocityY = 0;

      // Handle keyboard input for movement
      if (pressedKeys.contains(LogicalKeyboardKey.arrowLeft) || 
          pressedKeys.contains(LogicalKeyboardKey.keyA)) {
        playerVelocityX = -moveStep;
      }
      if (pressedKeys.contains(LogicalKeyboardKey.arrowRight) || 
          pressedKeys.contains(LogicalKeyboardKey.keyD)) {
        playerVelocityX = moveStep;
      }
      if (pressedKeys.contains(LogicalKeyboardKey.arrowUp) || 
          pressedKeys.contains(LogicalKeyboardKey.keyW)) {
        playerVelocityY = -moveStep;
      }
      if (pressedKeys.contains(LogicalKeyboardKey.arrowDown) || 
          pressedKeys.contains(LogicalKeyboardKey.keyS)) {
        playerVelocityY = moveStep;
      }

      // Apply diagonal movement normalization
      if (playerVelocityX != 0 && playerVelocityY != 0) {
        final factor = 1 / sqrt(2);
        playerVelocityX *= factor;
        playerVelocityY *= factor;
      }

      // Update player position
      playerX = (playerX + playerVelocityX).clamp(playerSize, screenWidth - playerSize);
      playerY = (playerY + playerVelocityY).clamp(playerSize, screenHeight - playerSize);

      // Fire bullets
      if (pressedKeys.contains(LogicalKeyboardKey.space)) {
        final now = DateTime.now();
        if (now.difference(lastFireTime) > const Duration(milliseconds: 250)) {
          bullets.add(Offset(playerX, playerY - playerSize));
          lastFireTime = now;
        }
      }

      // Update bullets
      bullets.removeWhere((bullet) {
        bullet = Offset(bullet.dx, bullet.dy - bulletSpeed);
        return bullet.dy < -bulletSize;
      });

      // Update asteroids
      asteroids.removeWhere((asteroid) {
        asteroid = Offset(asteroid.dx, asteroid.dy + asteroidSpeed);
        
        // Check collision with player
        if ((asteroid.dx - playerX).abs() < asteroidSize && (asteroid.dy - playerY).abs() < asteroidSize) {
          endGame();
          return true;
        }

        // Check collision with bullets
        for (int j = bullets.length - 1; j >= 0; j--) {
          if ((asteroid - bullets[j]).distance < asteroidSize + bulletSize) {
            bullets.removeAt(j);
            score += 10;
            return true;
          }
        }

        return asteroid.dy > screenHeight + asteroidSize;
      });
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    spawnTimer?.cancel();
    shootCooldown?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (event) {
        if (event is RawKeyDownEvent) {
          setState(() {
            pressedKeys.add(event.logicalKey);
          });
        } else if (event is RawKeyUpEvent) {
          setState(() {
            pressedKeys.remove(event.logicalKey);
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _GamePainter(
                player: Offset(playerX, playerY),
                playerSize: playerSize,
                asteroids: asteroids,
                asteroidSize: asteroidSize,
                bullets: bullets,
                bulletSize: bulletSize,
                score: score,
                isGameOver: isGameOver,
              ),
            ),
            if (isGameOver)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Game Over', style: TextStyle(fontSize: 36, color: Colors.red)),
                      const SizedBox(height: 16),
                      Text('Score: $score', style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: startGame,
                        child: const Text('Restart'),
                      ),
                    ],
                  ),
                ),
              ),
            if (!isGameOver)
              Positioned(
                top: 16,
                left: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score: $score',
                      style: const TextStyle(fontSize: 24, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Controls: WASD or Arrow Keys to move\nSpace to shoot',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GamePainter extends CustomPainter {
  final Offset player;
  final double playerSize;
  final List<Offset> asteroids;
  final double asteroidSize;
  final List<Offset> bullets;
  final double bulletSize;
  final int score;
  final bool isGameOver;

  _GamePainter({
    required this.player,
    required this.playerSize,
    required this.asteroids,
    required this.asteroidSize,
    required this.bullets,
    required this.bulletSize,
    required this.score,
    required this.isGameOver,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw player (spaceship)
    final playerPaint = Paint()..color = Colors.blue;
    final path = Path()
      ..moveTo(player.dx, player.dy - playerSize)
      ..lineTo(player.dx - playerSize / 2, player.dy)
      ..lineTo(player.dx + playerSize / 2, player.dy)
      ..close();
    canvas.drawPath(path, playerPaint);

    // Draw asteroids
    final asteroidPaint = Paint()..color = Colors.red;
    for (final asteroid in asteroids) {
      canvas.drawCircle(asteroid, asteroidSize, asteroidPaint);
    }

    // Draw bullets
    final bulletPaint = Paint()..color = Colors.yellow;
    for (final bullet in bullets) {
      canvas.drawCircle(bullet, bulletSize, bulletPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
