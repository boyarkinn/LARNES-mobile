import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/audio/speech_bank.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_chip_size.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_field_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_pair_connect/letter_pair_connect_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_pair_connect/audio.dart';
import 'package:larnes_mobile/trainers/reading/letter_pair_connect/connection_geometry.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/shared/instruction/load_trainer_instruction_duration.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_typewriter.dart';
import 'package:larnes_mobile/trainers/shared/match_connection/connection_lines_painter.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

class LetterPairConnectTrainer extends StatefulWidget {
  const LetterPairConnectTrainer({super.key, required this.params, this.onComplete});
  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<LetterPairConnectTrainer> createState() => _LetterPairConnectTrainerState();
}

class _LetterPairConnectTrainerState extends State<LetterPairConnectTrainer> {
  final _boardKey = GlobalKey();
  late final int _salt;
  late LetterPairRound _round;
  final _connections = <LetterConnection>[];
  final _wrongIds = <String>{};
  String? _selectedId;
  String? _dragId;
  Offset? _dragPoint;
  var _ready = false;
  var _instruction = true;
  var _instructionLength = 0;
  final _instructionTypewriter = TrainerInstructionTypewriter();
  Object _runToken = Object();
  var _completeCalled = false;
  Timer? _revealTimer;
  Timer? _instructionPauseTimer;
  Timer? _wrongTimer;
  Timer? _completeTimer;

  String _signature(Map<String, dynamic> params) =>
      '${params['practiceLetters'] ?? defaultPairLetters}|${params['letterCase'] ?? 'upper'}|${readTrainerSnapshotSeed('letter-pair-connect', params)}';

  @override
  void initState() {
    super.initState();
    _salt = createLayoutSalt();
    _reset();
  }

  @override
  void didUpdateWidget(covariant LetterPairConnectTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_signature(oldWidget.params) != _signature(widget.params)) _reset();
  }

  void _reset() {
    final runToken = Object();
    _runToken = runToken;
    _instructionTypewriter.cancel();
    _instructionPauseTimer?.cancel();
    _revealTimer?.cancel();
    _wrongTimer?.cancel();
    _completeTimer?.cancel();
    final letters = widget.params['practiceLetters'] as String? ?? defaultPairLetters;
    final letterCase = widget.params['letterCase'] as String? ?? 'upper';
    final seed = readTrainerSnapshotSeed('letter-pair-connect', widget.params) ??
        hashParamsSeed(['letter-pair-connect', letters, letterCase, _salt]);
    _round = buildLetterPairRound(
      practiceLetters: letters,
      letterCase: letterCase,
      rng: TrainerSnapshotRandom(seed).nextDouble,
    );
    _connections.clear();
    _wrongIds.clear();
    _selectedId = _dragId = null;
    _dragPoint = null;
    _ready = _completeCalled = false;
    _instruction = true;
    _instructionLength = 0;
    unawaited(_runInstruction(runToken));
  }

  Future<void> _runInstruction(Object runToken) async {
    await cancelLetterPairAudio();
    if (!mounted || !identical(_runToken, runToken)) return;
    final durationMs = await loadTrainerInstructionDurationMs(
      assetPath: '',
      playbackRate: 1,
      fallbackMs: letterPairInstructionFallbackMs,
      semanticKey: letterPairInstructionKey,
    );
    if (!mounted || !identical(_runToken, runToken)) return;
    _instructionTypewriter.start(
      speechKey: letterPairInstructionKey,
      text: letterPairInstructionText,
      durationMs: durationMs,
      isCurrent: () => mounted && identical(_runToken, runToken),
      onLength: (length) {
        if (mounted && identical(_runToken, runToken)) setState(() => _instructionLength = length);
      },
    );
    await playLetterPairInstruction();
    if (!mounted || !identical(_runToken, runToken)) return;
    _instructionTypewriter.cancel();
    setState(() => _instructionLength = publishedSpeechText(letterPairInstructionKey, letterPairInstructionText).length);
    _instructionPauseTimer = Timer(const Duration(milliseconds: letterPairInstructionPauseMs), () {
      if (!mounted || !identical(_runToken, runToken)) return;
      setState(() => _instruction = false);
      _scheduleReveal();
    });
  }

  void _scheduleReveal() {
    _revealTimer = Timer(Duration(milliseconds: getFruitRevealTotalMs(_round.letters.length)), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  bool get _complete => isLetterPairRoundComplete(_round.letters, _connections);
  bool _available(String id) => !_instruction && _ready && !_complete && !connectedLetterIds(_connections).contains(id);

  void _connect(String first, String second) {
    if (!_available(first) || !_available(second) || first == second) return;
    _wrongTimer?.cancel();
    setState(() {
      _selectedId = null;
      _wrongIds.clear();
      if (isMatchingLetterPair(_round.letters, first, second)) {
        _connections.add(LetterConnection(first, second));
      } else {
        _wrongIds.addAll([first, second]);
        _wrongTimer = Timer(const Duration(milliseconds: 550), () {
          if (mounted) setState(_wrongIds.clear);
        });
      }
    });
    if (_complete && !_completeCalled) {
      _completeCalled = true;
      _completeTimer = Timer(const Duration(milliseconds: 900), () {
        if (mounted) widget.onComplete?.call();
      });
    }
  }

  void _tap(String id) {
    if (!_available(id)) return;
    if (_selectedId == id) {
      setState(() => _selectedId = null);
    } else if (_selectedId != null) {
      _connect(_selectedId!, id);
    } else {
      setState(() => _selectedId = id);
    }
  }

  Offset _local(Offset global) => (_boardKey.currentContext!.findRenderObject()! as RenderBox).globalToLocal(global);

  void _startDrag(String id, Offset global) {
    if (!_available(id)) return;
    setState(() {
      _selectedId = null;
      _dragId = id;
      _dragPoint = _local(global);
    });
  }

  void _cancelDrag() => setState(() {
    _dragId = null;
    _dragPoint = null;
  });

  void _finishDrag(Size size, double chipSize) {
    final source = _dragId;
    final point = _dragPoint;
    if (source != null && point != null) {
      for (final letter in _round.letters) {
        final bounds = Rect.fromCenter(center: _anchor(letter.id, size), width: chipSize, height: chipSize);
        if (bounds.contains(point) && letter.id != source) {
          _connect(source, letter.id);
          break;
        }
      }
    }
    _cancelDrag();
  }

  Offset _anchor(String id, Size size) {
    final letter = _round.letters.firstWhere((letter) => letter.id == id);
    return Offset(letter.xPercent / 100 * size.width, letter.yPercent / 100 * size.height);
  }

  MatchConnectionLineSegment? _line(LetterConnection pair, Size size, double chipSize) {
    final first = _anchor(pair.firstId, size);
    final second = _anchor(pair.secondId, size);
    final geometry = buildPairCircleConnection(first, second, (chipSize - pairCircleBorderWidth(chipSize)) / 2);
    return geometry == null ? null : MatchConnectionLineSegment(from: geometry.from, to: geometry.to, stroke: pairConnectionColor, path: geometry.toPath());
  }

  MatchConnectionDraftSegment? _draft(Size size) {
    if (_dragId == null || _dragPoint == null) return null;
    final first = _anchor(_dragId!, size);
    final second = _dragPoint!;
    return MatchConnectionDraftSegment(from: first.dx <= second.dx ? first : second, to: first.dx <= second.dx ? second : first, stroke: const Color(0xFF64748B));
  }

  @override
  void dispose() {
    _runToken = Object();
    _instructionTypewriter.cancel();
    _instructionPauseTimer?.cancel();
    unawaited(cancelLetterPairAudio());
    _revealTimer?.cancel();
    _wrongTimer?.cancel();
    _completeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _instruction
      ? TrainerInstructionScene(length: _instructionLength, text: letterPairInstructionText, speechKey: letterPairInstructionKey)
      : TrainerScene(
    child: LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      final columns = _round.gridColumns;
      final baseSize = getLetterChipSizePx(MediaQuery.sizeOf(context).height);
      final chipSize = columns == null
          ? math.min(baseSize, math.min(size.width, size.height) * 0.15)
          : math.max(1.0, math.min(baseSize, math.min(size.width * 0.8 / columns * 0.76, size.height * 0.8 / (_round.letters.length / columns).ceil() * 0.76)));
      final matched = connectedLetterIds(_connections);
      return Semantics(
        label: 'Соединено пар: ${_connections.length} из ${_round.letters.length ~/ 2}',
        child: Stack(key: _boardKey, clipBehavior: Clip.none, children: [
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: MatchConnectionLinesPainter(
            circleCutouts: [for (final letter in _round.letters) if (matched.contains(letter.id)) MatchConnectionCircle(center: _anchor(letter.id, size), radius: math.max(0.0, chipSize / 2 - pairCircleBorderWidth(chipSize)))],
            draft: _draft(size),
            lockedLines: _connections.map((pair) => _line(pair, size, chipSize)).whereType<MatchConnectionLineSegment>().toList(),
            wrong: null,
          )))),
          for (var index = 0; index < _round.letters.length; index++)
            Positioned(
              left: _anchor(_round.letters[index].id, size).dx - chipSize / 2,
              top: _anchor(_round.letters[index].id, size).dy - chipSize / 2,
              child: _PairGlyph(
                key: ValueKey('pair-${_round.letters[index].id}'),
                letter: _round.letters[index], size: chipSize,
                wrong: _wrongIds.contains(_round.letters[index].id),
                selected: _selectedId == _round.letters[index].id || _dragId == _round.letters[index].id,
                matched: matched.contains(_round.letters[index].id),
                enabled: _available(_round.letters[index].id),
                enterDelayMs: getFruitRevealDelayMs(index, _round.letters.length),
                onTap: () => _tap(_round.letters[index].id),
                onPanStart: (details) => _startDrag(_round.letters[index].id, details.globalPosition),
                onPanUpdate: (details) { if (_dragId != null) setState(() => _dragPoint = _local(details.globalPosition)); },
                onPanEnd: (_) => _finishDrag(size, chipSize),
                onPanCancel: _cancelDrag,
              ),
            ),
        ]),
      );
    }),
  );
}

class _PairGlyph extends StatefulWidget {
  const _PairGlyph({super.key, required this.letter, required this.size, required this.wrong, required this.selected, required this.matched, required this.enabled, required this.enterDelayMs, required this.onTap, required this.onPanStart, required this.onPanUpdate, required this.onPanEnd, required this.onPanCancel});
  final PairLetter letter;
  final double size;
  final bool wrong, selected, matched, enabled;
  final int enterDelayMs;
  final VoidCallback onTap, onPanCancel;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;

  @override
  State<_PairGlyph> createState() => _PairGlyphState();
}

class _PairGlyphState extends State<_PairGlyph> with TickerProviderStateMixin {
  late final _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
  late final _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  Timer? _enterTimer;

  @override
  void initState() {
    super.initState();
    _enterTimer = Timer(Duration(milliseconds: widget.enterDelayMs), () { if (mounted) _enter.forward(); });
  }

  @override
  void didUpdateWidget(covariant _PairGlyph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.wrong && !oldWidget.wrong) _shake.forward(from: 0);
  }

  @override
  void dispose() {
    _enterTimer?.cancel();
    _enter.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true, enabled: widget.enabled, selected: widget.selected,
      label: 'Буква ${widget.letter.letter}, экземпляр ${widget.letter.id.endsWith('-0') ? 1 : 2}${widget.matched ? ', пара найдена' : ''}',
      onTap: widget.enabled ? widget.onTap : null,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) { widget.onTap(); return null; })},
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: widget.enabled ? widget.onTap : null,
          onPanStart: widget.enabled ? widget.onPanStart : null,
          onPanUpdate: widget.enabled ? widget.onPanUpdate : null,
          onPanEnd: widget.enabled ? widget.onPanEnd : null,
          onPanCancel: widget.enabled ? widget.onPanCancel : null,
          child: Stack(clipBehavior: Clip.none, children: [AnimatedBuilder(
            animation: Listenable.merge([_enter, _shake]),
            builder: (context, child) => Opacity(
              opacity: reduced ? 1 : _enter.value,
              child: Transform.translate(
                offset: Offset(reduced ? 0 : math.sin(_shake.value * math.pi * 6) * 7 * (1 - _shake.value), 0),
                child: Transform.scale(scale: (reduced ? 1 : 0.9 + 0.1 * _enter.value) * (widget.selected ? 1.08 : 1), child: child),
              ),
            ),
            child: Container(
              width: widget.size, height: widget.size,
              decoration: BoxDecoration(shape: BoxShape.circle, border: widget.selected ? Border.all(color: const Color(0x732F7D59), width: 2) : null),
              alignment: Alignment.center,
              child: ExcludeSemantics(child: Text(widget.letter.letter, style: TextStyle(fontSize: getLetterChipFontSizePx(widget.size), fontWeight: FontWeight.w700, color: widget.wrong ? const Color(0xFFDC2626) : letterDisplayColorFromHex(widget.letter.displayColor)))),
            ),
          ),
            if (widget.matched) Positioned.fill(child: IgnorePointer(child: DecoratedBox(
              key: ValueKey('pair-circle-${widget.letter.id}'),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: pairConnectionColor, width: pairCircleBorderWidth(widget.size))),
            ))),
          ]),
        ),
      ),
    );
  }
}
