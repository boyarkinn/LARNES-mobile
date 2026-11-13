import 'dart:async';
import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_pause_scope.dart';

/// Automatic 3–2–1 preparation; menu/background pauses restart the countdown.
class TrainerReadyCountdown extends StatefulWidget {
  const TrainerReadyCountdown({super.key, required this.onComplete});
  final VoidCallback onComplete;
  @override
  State<TrainerReadyCountdown> createState() => _TrainerReadyCountdownState();
}

class _TrainerReadyCountdownState extends State<TrainerReadyCountdown>
    with WidgetsBindingObserver {
  Timer? _timer;
  int _index = 0;
  bool _menuPaused = false, _appPaused = false, _completed = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _menuPaused = TrainerPauseScope.isPaused(context);
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appPaused = state != AppLifecycleState.resumed;
    _sync();
  }

  void _sync() {
    if (_menuPaused || _appPaused) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    if (_timer != null || _completed) return;
    _index = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_index == 2) {
        timer.cancel();
        _timer = null;
        _completed = true;
        widget.onComplete();
      } else {
        setState(() => _index++);
      }
    });
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      liveRegion: true,
      child: Text(
        '${3 - _index}',
        style: const TextStyle(
          fontSize: 100,
          fontWeight: FontWeight.bold,
          color: Color(0xFFCA8A04),
          shadows: [Shadow(color: Color(0x1F854D0E), offset: Offset(0, 3))],
        ),
      ),
    ),
  );
}
