import 'dart:async';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Pet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Digital Pet'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String petName = 'My Pet';
  int happiness = 50;
  int hunger = 50;
  bool gameOver = false;
  bool hasWon = false;
  bool isPaused = false;
  Timer? hungerTimer;
  Timer? highMoodTimer;
  Timer? _reactionTimer;
  double _reactionScale = 1.0;
  final TextEditingController nameController = TextEditingController();

  String get _moodLabel {
    if (happiness < 30) return 'Unhappy';
    if (happiness <= 70) return 'Neutral';
    return 'Happy';
  }

  Color get _moodColor {
    if (happiness < 30) return Colors.red;
    if (happiness <= 70) return Colors.yellow;
    return Colors.green;
  }

  String get _petMessage {
    if (gameOver) return 'I need a rest.';
    if (hasWon) return 'Best day ever!';
    if (hunger > 80) return 'I’m starving!';
    if (happiness <= 30) return 'Play with me?';
    return 'Hi, I’m $petName!';
  }

  void _reactToCare() {
    _reactionTimer?.cancel();
    if (MediaQuery.of(context).disableAnimations) {
      setState(() => _reactionScale = 1.0);
      return;
    }
    setState(() => _reactionScale = 1.08);
    _reactionTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _reactionScale = 1.0);
    });
  }

  @override
  void initState() {
    super.initState();
    _startHungerTimer();
  }

  int _clampMeter(int value) => value.clamp(0, 100);

  void _confirmName() {
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      petName = name;
    });
  }

  void _feedPet() {
    if (isPaused || gameOver || hasWon) return;
    _reactToCare();
    setState(() {
      hunger = _clampMeter(hunger - 10);
      if (hunger < 30) {
        happiness = _clampMeter(happiness - 20);
      } else {
        happiness = _clampMeter(happiness + 10);
      }
    });
    _checkOutcome();
  }

  void _playWithPet() {
    if (isPaused || gameOver || hasWon) return;
    _reactToCare();
    setState(() {
      happiness = _clampMeter(happiness + 10);
      hunger = _clampMeter(hunger + 5);
    });
    _checkOutcome();
  }

  void _startHungerTimer() {
    hungerTimer?.cancel();
    hungerTimer = null;
    if (isPaused || gameOver || hasWon) return;
    hungerTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted || gameOver || hasWon) {
        timer.cancel();
        hungerTimer = null;
        return;
      }
      if (isPaused) return;
      setState(() {
        // Reaching 100 is safe; only a later tick at 100 lowers happiness.
        if (hunger == 100) {
          happiness = _clampMeter(happiness - 20);
        } else {
          hunger = _clampMeter(hunger + 5);
        }
      });
      _checkOutcome();
    });
  }

  void _updateWinTimer() {
    if (happiness <= 80 || isPaused || gameOver || hasWon) {
      highMoodTimer?.cancel();
      highMoodTimer = null;
      return;
    }
    if (highMoodTimer?.isActive ?? false) return;
    highMoodTimer = Timer(const Duration(minutes: 3), () {
      highMoodTimer = null;
      if (!mounted || happiness <= 80 || gameOver || hasWon || isPaused) {
        return;
      }
      setState(() {
        hasWon = true;
      });
      hungerTimer?.cancel();
      hungerTimer = null;
    });
  }

  void _checkOutcome() {
    if (gameOver || hasWon) return;
    if (hunger == 100 && happiness <= 10) {
      highMoodTimer?.cancel();
      highMoodTimer = null;
      hungerTimer?.cancel();
      hungerTimer = null;
      setState(() {
        gameOver = true;
      });
      return;
    }
    _updateWinTimer();
  }

  void _togglePause() {
    if (gameOver || hasWon) return;
    setState(() {
      isPaused = !isPaused;
    });
    if (isPaused) {
      hungerTimer?.cancel();
      hungerTimer = null;
      highMoodTimer?.cancel();
      highMoodTimer = null;
    } else {
      _startHungerTimer();
      // Resume requires a fresh uninterrupted three minutes of high happiness.
      _checkOutcome();
    }
  }

  void _resetGame() {
    _reactionTimer?.cancel();
    hungerTimer?.cancel();
    hungerTimer = null;
    highMoodTimer?.cancel();
    highMoodTimer = null;
    setState(() {
      happiness = 50;
      _reactionScale = 1.0;
      hunger = 50;
      gameOver = false;
      hasWon = false;
      isPaused = false;
    });
    _startHungerTimer();
  }

  @override
  void dispose() {
    _reactionTimer?.cancel();
    hungerTimer?.cancel();
    highMoodTimer?.cancel();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final animationDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 250);
    final canCare = !isPaused && !gameOver && !hasWon;
    final status = gameOver
        ? 'GAME OVER'
        : hasWon
        ? 'YOU WIN!'
        : isPaused
        ? 'PAUSED'
        : 'Pet is active';

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Enter Pet Name'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _confirmName,
              child: const Text('Confirm Name'),
            ),
            const SizedBox(height: 16),
            Text('Pet: $petName'),
            const SizedBox(height: 12),
            Center(
              child: AnimatedScale(
                scale: reduceMotion ? 1.0 : _reactionScale,
                duration: animationDuration,
                curve: Curves.easeInOut,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(_moodColor, BlendMode.modulate),
                  child: Image.asset(
                    'assets/pet.png',
                    width: 96,
                    height: 96,
                    fit: BoxFit.contain,
                    semanticLabel: '$petName, feeling $_moodLabel',
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(
                          width: 96,
                          height: 96,
                          child: Center(child: Text('Pet image unavailable')),
                        ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _petMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Chip(
                backgroundColor: _moodColor,
                label: Text(
                  'Mood: $_moodLabel',
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Happiness: $happiness'),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: happiness / 100,
                end: happiness / 100,
              ),
              duration: animationDuration,
              builder: (context, value, child) => LinearProgressIndicator(
                value: value,
                semanticsLabel: 'Happiness',
                semanticsValue: '$happiness out of 100',
              ),
            ),
            const SizedBox(height: 16),
            Text('Hunger: $hunger'),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: hunger / 100, end: hunger / 100),
              duration: animationDuration,
              builder: (context, value, child) => LinearProgressIndicator(
                value: value,
                semanticsLabel: 'Hunger',
                semanticsValue: '$hunger out of 100',
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: canCare ? _feedPet : null,
                  child: const Text('Feed'),
                ),
                ElevatedButton(
                  onPressed: canCare ? _playWithPet : null,
                  child: const Text('Play'),
                ),
                ElevatedButton(
                  onPressed: gameOver || hasWon ? null : _togglePause,
                  child: Text(isPaused ? 'Resume' : 'Pause'),
                ),
                ElevatedButton(
                  onPressed: _resetGame,
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(status, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
