import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/parent/models/parent_live_lesson_room.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_play_theme.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_player_menu.dart';

class LiveLessonWaitingView extends StatefulWidget {
  const LiveLessonWaitingView({
    super.key,
    required this.waiting,
    required this.untitledLabel,
    required this.continueLabel,
    required this.exitLabel,
    required this.waitingLabel,
    required this.onLeave,
  });

  final ParentLiveLessonWaiting waiting;
  final String untitledLabel;
  final String continueLabel;
  final String exitLabel;
  final String waitingLabel;
  final VoidCallback onLeave;

  @override
  State<LiveLessonWaitingView> createState() => _LiveLessonWaitingViewState();
}

class _LiveLessonWaitingViewState extends State<LiveLessonWaitingView> {
  bool _menuOpen = false;

  void _closeMenu() {
    if (_menuOpen) {
      setState(() => _menuOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.waiting.lessonTitle.isNotEmpty
        ? widget.waiting.lessonTitle
        : widget.untitledLabel;
    final meta = [title, widget.waiting.timeLabel].whereType<String>().join(' · ');
    final nameStyle = GoogleFonts.fredoka(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1,
      letterSpacing: -0.025 * 32,
      color: ParentColors.shell,
    );
    final metaStyle = GoogleFonts.fredoka(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      height: 1,
      letterSpacing: -0.025 * 17,
      color: ParentColors.shell,
    );

    return ParentParchmentBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Semantics(
              label: widget.waitingLabel,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 88, 24, 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.waiting.childName.isNotEmpty)
                      Text(
                        widget.waiting.childName,
                        textAlign: TextAlign.center,
                        style: nameStyle,
                      ),
                    if (meta.isNotEmpty) ...[
                      if (widget.waiting.childName.isNotEmpty) const SizedBox(height: 6),
                      Text(
                        meta,
                        textAlign: TextAlign.center,
                        style: metaStyle,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topLeft,
                child: TrainerPlayerMenuButton(
                  isOpen: _menuOpen,
                  theme: TrainerPlayTheme.parent,
                  onPressed: () {
                    setState(() => _menuOpen = !_menuOpen);
                  },
                ),
              ),
            ),
            if (_menuOpen)
              TrainerPlayerMenuModal(
                continueLabel: widget.continueLabel,
                exitLabel: widget.exitLabel,
                theme: TrainerPlayTheme.parent,
                onContinue: _closeMenu,
                onExit: () {
                  _closeMenu();
                  widget.onLeave();
                },
              ),
          ],
        ),
      ),
    );
  }
}
