import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_play_theme.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_player_menu.dart';
import 'trainer_pause_scope.dart';
import 'trainer_time_progress.dart';

/// Game-style trainer shell (web `TrainerPlayShell` / mock trainer-game-v1).
class TrainerPlayShell extends StatefulWidget {
  const TrainerPlayShell({
    super.key,
    required this.child,
    required this.currentStep,
    required this.totalSteps,
    required this.menuContinueLabel,
    required this.menuExitLabel,
    required this.onExit,
    this.theme = TrainerPlayTheme.parent,
    this.edgeToEdge = false,
  });

  final Widget child;
  final int currentStep;
  final int totalSteps;
  final String menuContinueLabel;
  final String menuExitLabel;
  final VoidCallback onExit;
  final TrainerPlayTheme theme;

  /// Kiosk / program play: full-bleed stage padding (safe area only), same parchment as homework.
  final bool edgeToEdge;

  @override
  State<TrainerPlayShell> createState() => _TrainerPlayShellState();
}

class _TrainerPlayShellState extends State<TrainerPlayShell> {
  bool _menuOpen = false;
  final _timeProgress = TrainerTimeProgressController();
  @override
  void dispose() {
    _timeProgress.dispose();
    super.dispose();
  }

  void _closeMenu() {
    if (_menuOpen) {
      setState(() => _menuOpen = false);
    }
  }

  void _toggleMenu() {
    setState(() => _menuOpen = !_menuOpen);
  }

  @override
  Widget build(BuildContext context) {
    final progressMax = widget.totalSteps < 1 ? 1 : widget.totalSteps;
    final progressValue = widget.currentStep.clamp(0, progressMax);
    final progressPercent = progressValue / progressMax;
    final stagePadding = trainerPlayStagePadding(context);

    final scaffold = Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Padding(
              padding: stagePadding,
              child: TrainerTimeProgressScope(
                controller: _timeProgress,
                child: TrainerPauseScope(
                  paused: _menuOpen,
                  child: widget.child,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Semantics(
                      label: 'Шаг $progressValue из $progressMax',
                      value: '$progressValue',
                      child: SizedBox(
                        height: 7,
                        child: ColoredBox(
                          color: widget.theme.progressTrack,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: AnimatedFractionallySizedBox(
                              duration: const Duration(milliseconds: 280),
                              curve: ParentMotion.curve,
                              widthFactor: progressPercent,
                              child: ColoredBox(color: widget.theme.accent),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ListenableBuilder(
                    listenable: _timeProgress,
                    builder: (context, child) => _timeProgress.value == null
                        ? const SizedBox.shrink()
                        : TrainerTimeProgressBar(value: _timeProgress.value!),
                  ),
                  TrainerPlayerMenuButton(
                    isOpen: _menuOpen,
                    onPressed: _toggleMenu,
                    theme: widget.theme,
                  ),
                ],
              ),
            ),
          ),
          if (_menuOpen)
            TrainerPlayerMenuModal(
              continueLabel: widget.menuContinueLabel,
              exitLabel: widget.menuExitLabel,
              theme: widget.theme,
              onContinue: _closeMenu,
              onExit: () {
                _closeMenu();
                widget.onExit();
              },
            ),
        ],
      ),
    );

    return ParentParchmentBackground(child: scaffold);
  }
}
