import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/audio/spoken_cues.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_field_scene.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_typewriter.dart';
import 'package:larnes_mobile/trainers/shared/instruction/load_trainer_instruction_duration.dart';
import 'package:larnes_mobile/trainers/audio/speech_bank.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'model.dart';

const wordCubesInstruction = 'Нажимай на кубики и собери слово';
const wordCubesInstructionKey = 'instruction:word-cubes';

class WordCubesTrainer extends StatefulWidget {
  const WordCubesTrainer({super.key, required this.params, this.onComplete});
  final Map<String, dynamic> params;
  final VoidCallback? onComplete;
  @override
  State<WordCubesTrainer> createState() => _WordCubesTrainerState();
}

class _WordCubesTrainerState extends State<WordCubesTrainer> {
  late final int _salt = createLayoutSalt();
  late List<CubeRound> _rounds;
  var _roundIndex = 0;
  var _faces = <int>[];
  var _phase = 'instruction';
  var _instructionLength = 0;
  final _typewriter = TrainerInstructionTypewriter();
  Object _run = Object();
  Timer? _timer;
  String _signature(Map<String, dynamic> params) => '${params['wordSlug'] ?? 'all'}|${readTrainerSnapshotSeed('word-cubes', params)}';
  CubeRound get _round => _rounds[_roundIndex];
  bool get _complete => isCubeRoundComplete(_round, _faces);

  @override
  void initState() { super.initState(); _reset(); }
  @override
  void didUpdateWidget(covariant WordCubesTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_signature(oldWidget.params) != _signature(widget.params)) _reset();
  }
  void _reset() {
    _timer?.cancel(); _typewriter.cancel();
    final run = Object(); _run = run;
    final slug = widget.params['wordSlug'] as String? ?? 'all';
    final seed = readTrainerSnapshotSeed('word-cubes', widget.params) ?? hashParamsSeed(['word-cubes', slug, _salt]);
    _rounds = buildCubeRounds(slug, TrainerSnapshotRandom(seed).nextDouble);
    _roundIndex = 0; _faces = _round.cubes.map((cube) => cube.initialFace).toList();
    _phase = 'instruction'; _instructionLength = 0;
    unawaited(_instruction(run));
  }
  Future<void> _instruction(Object run) async {
    await getSharedClipPlayer().cancel();
    if (!mounted || !identical(_run, run)) return;
    final duration = await loadTrainerInstructionDurationMs(assetPath: '', playbackRate: 1, fallbackMs: 3000, semanticKey: wordCubesInstructionKey);
    if (!mounted || !identical(_run, run)) return;
    _typewriter.start(speechKey: wordCubesInstructionKey, text: wordCubesInstruction, durationMs: duration,
      isCurrent: () => mounted && identical(_run, run),
      onLength: (length) { if (mounted && identical(_run, run)) setState(() => _instructionLength = length); });
    await playSpokenCue(semanticKey: wordCubesInstructionKey, fallbackMs: 3000);
    if (!mounted || !identical(_run, run)) return;
    _typewriter.cancel();
    setState(() => _instructionLength = publishedSpeechText(wordCubesInstructionKey, wordCubesInstruction).length);
    _timer = Timer(const Duration(seconds: 1), () { if (mounted && identical(_run, run)) setState(() => _phase = 'play'); });
  }
  void _turn(int index) {
    if (_phase != 'play' || _complete) return;
    setState(() => _faces[index] = nextCubeFace(_round.cubes[index].cube, _faces[index]));
    if (!_complete) return;
    _timer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_roundIndex + 1 < _rounds.length) {
        setState(() { _roundIndex++; _faces = _round.cubes.map((cube) => cube.initialFace).toList(); });
      } else {
        setState(() => _phase = 'done');
        widget.onComplete?.call();
      }
    });
  }
  @override
  void dispose() {
    _run = Object(); _timer?.cancel(); _typewriter.cancel();
    unawaited(getSharedClipPlayer().cancel()); super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    if (_phase == 'instruction') return TrainerInstructionScene(length: _instructionLength, text: wordCubesInstruction, speechKey: wordCubesInstructionKey);
    return TrainerScene(child: LayoutBuilder(builder: (context, constraints) {
      final width = math.min(768.0, constraints.maxWidth - 32);
      final baseSize = math.min(math.min(170.0, width / (_round.cubes.length + 0.6)), math.max(44.0, constraints.maxHeight * 0.35));
      final gap = math.min(70.0, constraints.maxHeight * 0.11);
      return Center(child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Semantics(label: _round.word.word, child: ExcludeSemantics(child: Text(_round.word.parts.map((part) => part.target).join('|'), textDirection: TextDirection.ltr, style: TextStyle(fontSize: math.min(math.min(88.0, width * 0.16), constraints.maxHeight * 0.20), fontWeight: FontWeight.w700, color: const Color(0xFF14232B))))),
        SizedBox(height: gap),
        SizedBox(width: width, height: baseSize, child: Row(textDirection: TextDirection.ltr, mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (var i = 0; i < _round.cubes.length; i++) _CubeButton(key: ValueKey('$_roundIndex:$i'), cube: _round.cubes[i].cube, text: _round.cubes[i].cube.faces[_faces[i]], index: i, size: baseSize * (_round.cubes[i].cube.small ? 0.78 : 1), solved: _complete, enabled: _phase == 'play' && !_complete, onTap: () => _turn(i)),
        ])),
        SizedBox(height: gap),
        SizedBox(height: 28, child: Text(_complete ? 'Верно!' : '', style: const TextStyle(fontSize: 20, color: Color(0xFF16803D), fontWeight: FontWeight.w600))),
      ])));
    }));
  }
}

class _CubeButton extends StatefulWidget {
  const _CubeButton({super.key, required this.cube, required this.text, required this.index, required this.size, required this.solved, required this.enabled, required this.onTap});
  final WarehouseCube cube;
  final String text;
  final int index;
  final double size;
  final bool solved, enabled;
  final VoidCallback onTap;
  @override
  State<_CubeButton> createState() => _CubeButtonState();
}

class _CubeButtonState extends State<_CubeButton> with SingleTickerProviderStateMixin {
  late final _press = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
  late final _pressScale = TweenSequence<double>([
    TweenSequenceItem<double>(tween: Tween<double>(begin: 1.0, end: 0.94).chain(CurveTween(curve: Curves.easeOut)), weight: 45),
    TweenSequenceItem<double>(tween: Tween<double>(begin: 0.94, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 55),
  ]).animate(_press);

  void _activate() {
    if (!widget.enabled) return;
    if (!MediaQuery.disableAnimationsOf(context)) _press.forward(from: 0);
    widget.onTap();
  }

  @override
  void dispose() { _press.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: reduced ? 1.0 : 0.0, end: 1.0),
      duration: Duration(milliseconds: reduced ? 0 : 550 + widget.index * 100),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.translate(
        offset: Offset((widget.index.isEven ? -40 : 40) * (1 - value), -85 * (1 - value)),
        child: Transform.scale(scale: 0.6 + 0.4 * value, child: child),
      ),
      child: Semantics(
        button: true,
        enabled: widget.enabled,
        label: 'Кубик ${widget.index + 1}, склад ${widget.text}. Нажми, чтобы изменить склад',
        onTap: widget.enabled ? _activate : null,
        child: FocusableActionDetector(
          enabled: widget.enabled,
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
              _activate();
              return null;
            }),
          },
          child: GestureDetector(
            excludeFromSemantics: true,
            onTap: widget.enabled ? _activate : null,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: ScaleTransition(
                scale: reduced ? const AlwaysStoppedAnimation(1.0) : _pressScale,
                child: CustomPaint(
                  painter: _CubePainter(widget.cube, widget.solved),
                  child: Padding(
                    padding: EdgeInsets.only(left: widget.size * 0.07, right: widget.size * 0.20, top: widget.size * 0.20, bottom: widget.size * 0.07),
                    child: Center(
                      child: Text(widget.text, style: TextStyle(
                        fontSize: widget.size * (widget.text.length == 1 ? 0.446 : 0.366),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF152B30),
                      )),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CubePainter extends CustomPainter {
  const _CubePainter(this.cube, this.solved);
  final WarehouseCube cube;
  final bool solved;
  @override
  void paint(Canvas canvas, Size size) {
    final List<int> colors = cube.kind == 'vowel' ? [0xFFE36B70, 0xFFF29297, 0xFFB84A53]
      : cube.small ? cube.kind == 'voiced' ? [0xFF59A878, 0xFF89C89A, 0xFF397C55] : [0xFFA4CE91, 0xFFC4E2B5, 0xFF7DA86B]
      : cube.kind == 'voiced' ? [0xFF407EBE, 0xFF78A6D8, 0xFF285A92] : [0xFF83B8EC, 0xFFB0D3F4, 0xFF5D92C9];
    canvas.save();
    canvas.scale(size.width / 112, size.height / 112);
    final outline = Path()
      ..moveTo(31, 6)..lineTo(96, 6)..quadraticBezierTo(106, 6, 106, 16)
      ..lineTo(106, 82)..quadraticBezierTo(106, 88, 102, 92)..lineTo(94, 100)
      ..quadraticBezierTo(90, 104, 84, 104)..lineTo(20, 104)
      ..quadraticBezierTo(8, 104, 8, 92)..lineTo(8, 34)
      ..quadraticBezierTo(8, 26, 14, 20)..lineTo(22, 10)
      ..quadraticBezierTo(25, 6, 31, 6)..close();
    const frontBounds = Rect.fromLTRB(8, 22, 90, 104);
    final front = RRect.fromRectAndRadius(frontBounds, const Radius.circular(12));
    final frontPaint = Paint()..shader = LinearGradient(
      begin: Alignment.topLeft, end: const Alignment(-0.3, 1),
      colors: [Color(colors[1]), Color(colors[0])],
    ).createShader(frontBounds);
    canvas.drawOval(const Rect.fromLTRB(17, 103, 97, 109), Paint()
      ..color = const Color(0x24244A43)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    canvas.save();
    canvas.clipPath(outline);
    canvas.drawPath(outline, frontPaint);
    final top = Path()..moveTo(8, 22)..lineTo(24, 6)..lineTo(106, 6)..lineTo(90, 26)..lineTo(8, 26)..close();
    canvas.drawPath(top, Paint()..shader = LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomCenter,
      colors: [Color(colors[1]), Color(colors[0])],
    ).createShader(const Rect.fromLTRB(8, 6, 106, 26)));
    final side = Path()..moveTo(88, 26)..lineTo(106, 6)..lineTo(106, 88)..lineTo(88, 106)..close();
    canvas.drawPath(side, Paint()..shader = LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(colors[0]), Color(colors[2])],
    ).createShader(const Rect.fromLTRB(88, 6, 106, 106)));
    canvas.drawRRect(front, frontPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(8.6, 22.6, 89.4, 103.4), const Radius.circular(11.4)), Paint()
      ..color = const Color(0x5CFFFFFF)
      ..style = PaintingStyle.stroke..strokeWidth = 1.2);
    canvas.drawPath(Path()..moveTo(21, 28)..lineTo(75, 28)..quadraticBezierTo(83, 28, 83, 36), Paint()
      ..color = const Color(0x47FFFFFF)..style = PaintingStyle.stroke..strokeWidth = 1.5..strokeCap = StrokeCap.round);
    canvas.restore();
    canvas.drawPath(outline, Paint()
      ..color = Color(solved ? 0xFF16803D : 0x1F24413D)
      ..style = PaintingStyle.stroke..strokeWidth = (solved ? 2.5 : 1)..strokeJoin = StrokeJoin.round);
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant _CubePainter oldDelegate) => oldDelegate.cube != cube || oldDelegate.solved != solved;
}
