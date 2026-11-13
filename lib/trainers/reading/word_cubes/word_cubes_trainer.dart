import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/audio/spoken_cues.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_typewriter.dart';
import 'package:larnes_mobile/trainers/shared/instruction/load_trainer_instruction_duration.dart';
import 'package:larnes_mobile/trainers/audio/speech_bank.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'model.dart';
import 'cube_projection.dart';

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
  late List<CubeRound> _rounds;
  var _roundIndex = 0;
  var _faces = <int>[];
  var _phase = 'instruction';
  var _instructionLength = 0;
  final _typewriter = TrainerInstructionTypewriter();
  Object _run = Object();
  Timer? _timer;
  String _signature(Map<String, dynamic> params) =>
      params['__runtimeSnapshot'].toString();
  CubeRound get _round => _rounds[_roundIndex];
  bool get _complete => isCubeRoundComplete(_round, _faces);

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(covariant WordCubesTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_signature(oldWidget.params) != _signature(widget.params)) _reset();
  }

  void _reset() {
    _timer?.cancel();
    _typewriter.cancel();
    final run = Object();
    _run = run;
    _rounds = cubeRoundsFromPayload(
      readTrainerRuntimeSnapshot('word-cubes', widget.params),
    );
    if (_rounds.isEmpty) {
      _phase = 'unavailable';
      return;
    }
    _roundIndex = 0;
    _faces = _round.cubes.map((cube) => cube.initialFace).toList();
    _phase = 'instruction';
    _instructionLength = 0;
    unawaited(_instruction(run));
  }

  Future<void> _instruction(Object run) async {
    await getSharedClipPlayer().cancel();
    if (!mounted || !identical(_run, run)) return;
    final duration = await loadTrainerInstructionDurationMs(
      assetPath: '',
      playbackRate: 1,
      fallbackMs: 3000,
      semanticKey: wordCubesInstructionKey,
    );
    if (!mounted || !identical(_run, run)) return;
    _typewriter.start(
      speechKey: wordCubesInstructionKey,
      text: wordCubesInstruction,
      durationMs: duration,
      isCurrent: () => mounted && identical(_run, run),
      onLength: (length) {
        if (mounted && identical(_run, run))
          setState(() => _instructionLength = length);
      },
    );
    await playSpokenCue(semanticKey: wordCubesInstructionKey, fallbackMs: 3000);
    if (!mounted || !identical(_run, run)) return;
    _typewriter.cancel();
    setState(
      () => _instructionLength = publishedSpeechText(
        wordCubesInstructionKey,
        wordCubesInstruction,
      ).length,
    );
    _timer = Timer(const Duration(seconds: 1), () {
      if (mounted && identical(_run, run)) setState(() => _phase = 'play');
    });
  }

  void _turn(int index) {
    if (_phase != 'play' || _complete) return;
    setState(
      () =>
          _faces[index] = nextCubeFace(_round.cubes[index].cube, _faces[index]),
    );
    if (!_complete) return;
    _timer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_roundIndex + 1 < _rounds.length) {
        setState(() {
          _roundIndex++;
          _faces = _round.cubes.map((cube) => cube.initialFace).toList();
        });
      } else {
        setState(() => _phase = 'done');
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _run = Object();
    _timer?.cancel();
    _typewriter.cancel();
    unawaited(getSharedClipPlayer().cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == 'unavailable')
      return const TrainerScene(
        child: Text('Материалы упражнения не подготовлены.'),
      );
    if (_phase == 'instruction')
      return TrainerInstructionScene(
        length: _instructionLength,
        text: wordCubesInstruction,
        speechKey: wordCubesInstructionKey,
      );
    return TrainerScene(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(768.0, constraints.maxWidth - 32);
          final baseSize = math.min(
            math.min(170.0, width / (_round.cubes.length + 0.6)),
            math.max(44.0, constraints.maxHeight * 0.35),
          );
          final gap = math.min(70.0, constraints.maxHeight * 0.11);
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    label: _round.word.word,
                    child: ExcludeSemantics(
                      child: Text(
                        _round.word.parts.map((part) => part.target).join('|'),
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: math.min(
                            math.min(88.0, width * 0.16),
                            constraints.maxHeight * 0.20,
                          ),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF14232B),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: gap),
                  SizedBox(
                    width: width,
                    height: baseSize,
                    child: Row(
                      textDirection: TextDirection.ltr,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < _round.cubes.length; i++)
                          _CubeButton(
                            key: ValueKey('$_roundIndex:$i'),
                            cube: _round.cubes[i].cube,
                            text: _round.cubes[i].cube.faces[_faces[i]],
                            index: i,
                            size:
                                baseSize *
                                (_round.cubes[i].cube.small ? 0.78 : 1),
                            solved: _complete,
                            enabled: _phase == 'play' && !_complete,
                            onTap: () => _turn(i),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: gap),
                  SizedBox(
                    height: 28,
                    child: Text(
                      _complete ? 'Верно!' : '',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xFF16803D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CubeButton extends StatefulWidget {
  const _CubeButton({
    super.key,
    required this.cube,
    required this.text,
    required this.index,
    required this.size,
    required this.solved,
    required this.enabled,
    required this.onTap,
  });
  final WarehouseCube cube;
  final String text;
  final int index;
  final double size;
  final bool solved, enabled;
  final VoidCallback onTap;
  @override
  State<_CubeButton> createState() => _CubeButtonState();
}

class _CubeButtonState extends State<_CubeButton>
    with SingleTickerProviderStateMixin {
  late final _roll = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: wordCubeTurnMs),
  );
  late final _progress = CurvedAnimation(
    parent: _roll,
    curve: Curves.easeInOut,
  );
  var _completedTurns = 0;
  var _rolling = false;

  void _activate() {
    if (!widget.enabled || _rolling) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      widget.onTap();
      return;
    }
    setState(() => _rolling = true);
    unawaited(
      _roll.forward(from: 0).then((_) {
        if (!mounted) return;
        setState(() {
          _completedTurns++;
          _rolling = false;
          _roll.reset();
        });
        widget.onTap();
      }),
    );
  }

  @override
  void dispose() {
    _progress.dispose();
    _roll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final enabled = widget.enabled && !_rolling;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: reduced ? 1.0 : 0.0, end: 1.0),
      duration: Duration(milliseconds: reduced ? 0 : 550 + widget.index * 100),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(
          (widget.index.isEven ? -40 : 40) * (1 - value),
          -85 * (1 - value),
        ),
        child: Transform.scale(scale: 0.6 + 0.4 * value, child: child),
      ),
      child: Semantics(
        button: true,
        enabled: enabled,
        label:
            'Кубик ${widget.index + 1}, склад ${widget.text}. Нажми, чтобы изменить склад',
        onTap: enabled ? _activate : null,
        child: FocusableActionDetector(
          enabled: enabled,
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                _activate();
                return null;
              },
            ),
          },
          child: GestureDetector(
            excludeFromSemantics: true,
            onTap: enabled ? _activate : null,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: AnimatedBuilder(
                animation: _progress,
                builder: (context, _) => CustomPaint(
                  painter: _CubePainter(
                    widget.cube,
                    widget.text,
                    widget.solved,
                    _completedTurns + _progress.value,
                    _completedTurns,
                    _rolling,
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
  const _CubePainter(
    this.cube,
    this.text,
    this.solved,
    this.rotation,
    this.completedTurns,
    this.turning,
  );
  final WarehouseCube cube;
  final String text;
  final bool solved, turning;
  final double rotation;
  final int completedTurns;
  @override
  void paint(Canvas canvas, Size size) {
    final List<int> colors = cube.kind == 'vowel'
        ? [0xFFE36B70, 0xFFF29297, 0xFFB84A53]
        : cube.small
        ? cube.kind == 'voiced'
              ? [0xFF59A878, 0xFF89C89A, 0xFF397C55]
              : [0xFFA4CE91, 0xFFC4E2B5, 0xFF7DA86B]
        : cube.kind == 'voiced'
        ? [0xFF407EBE, 0xFF78A6D8, 0xFF285A92]
        : [0xFF83B8EC, 0xFFB0D3F4, 0xFF5D92C9];
    final projected = projectWordCube(rotation);
    canvas.save();
    canvas.scale(size.width / 112, size.height / 112);
    canvas.drawOval(
      const Rect.fromLTRB(19, 103, 93, 109),
      Paint()
        ..color = const Color(0x24244A43)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.save();
    canvas.clipPath(projected.outline);
    for (final surface in projected.surfaces) {
      final top = surface.id == 4;
      final first = top
          ? Color(colors[1])
          : Color.lerp(Color(colors[2]), Color(colors[1]), surface.light)!;
      final last = top
          ? Color(colors[0])
          : Color.lerp(Color(colors[2]), Color(colors[0]), surface.light)!;
      final path = cubePolygonPath(surface.points);
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: const Alignment(-0.3, 1),
            colors: [first, last],
          ).createShader(path.getBounds()),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0x42FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeJoin = StrokeJoin.round,
      );
      final label = cubeSideText(
        cube.faces,
        text,
        surface.id,
        completedTurns,
        turning,
      );
      if (label.isEmpty) continue;
      final m = surface.textMatrix;
      canvas.save();
      canvas.transform(
        Float64List.fromList([
          m[0],
          m[1],
          0,
          0,
          m[2],
          m[3],
          0,
          0,
          0,
          0,
          1,
          0,
          m[4],
          m[5],
          0,
          1,
        ]),
      );
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: label.length == 1 ? 60 : 48,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF152B30),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(50 - painter.width / 2, 55 - painter.height / 2),
      );
      painter.dispose();
      canvas.restore();
    }
    canvas.restore();
    canvas.drawPath(
      projected.outline,
      Paint()
        ..color = Color(solved ? 0xFF16803D : 0x1F24413D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (solved ? 2.5 : 1)
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CubePainter oldDelegate) =>
      oldDelegate.cube != cube ||
      oldDelegate.text != text ||
      oldDelegate.solved != solved ||
      oldDelegate.rotation != rotation ||
      oldDelegate.completedTurns != completedTurns ||
      oldDelegate.turning != turning;
}
