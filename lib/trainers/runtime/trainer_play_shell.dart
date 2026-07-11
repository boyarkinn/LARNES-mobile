import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_play_theme.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_player_menu.dart';

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
  });

  final Widget child;
  final int currentStep;
  final int totalSteps;
  final String menuContinueLabel;
  final String menuExitLabel;
  final VoidCallback onExit;
  final TrainerPlayTheme theme;

  @override
  State<TrainerPlayShell> createState() => _TrainerPlayShellState();
}

class _TrainerPlayShellState extends State<TrainerPlayShell> {
  bool _menuOpen = false;

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
    final hudTop = trainerPlayHudTopInset(context);
    final sideInset = MediaQuery.paddingOf(context).horizontal / 2;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ParentParchmentBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  sideInset > 16 ? sideInset : 16,
                  hudTop,
                  sideInset > 16 ? sideInset : 16,
                  bottomInset > 16 ? bottomInset : 16,
                ),
                child: widget.child,
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
      ),
    );
  }
}
