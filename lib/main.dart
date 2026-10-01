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
  final TextEditingController nameController = TextEditingController();

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
    hungerTimer?.cancel();
    hungerTimer = null;
    highMoodTimer?.cancel();
    highMoodTimer = null;
    setState(() {
      happiness = 50;
      hunger = 50;
      gameOver = false;
      hasWon = false;
      isPaused = false;
    });
    _startHungerTimer();
  }

  @override
  void dispose() {
    hungerTimer?.cancel();
    highMoodTimer?.cancel();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 16),
            Text('Happiness: $happiness'),
            LinearProgressIndicator(value: happiness / 100),
            const SizedBox(height: 16),
            Text('Hunger: $hunger'),
            LinearProgressIndicator(value: hunger / 100),
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
