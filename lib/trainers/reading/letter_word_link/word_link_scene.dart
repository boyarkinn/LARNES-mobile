import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/match_hit_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_word_link/word_link_card.dart';
import 'package:larnes_mobile/trainers/reading/letter_word_link/word_link_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_word_link/word_link_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_word_link/word_link_size.dart';
import 'package:larnes_mobile/trainers/reading/reading_word_catalogs.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

class _DrawLine {
  const _DrawLine({required this.from, required this.to});

  final Offset from;
  final Offset to;
}

class _ActiveDraw {
  const _ActiveDraw({required this.from, required this.to});

  final Offset from;
  final Offset to;
}

class _WrongFlash {
  const _WrongFlash({required this.from, required this.to});

  final Offset from;
  final Offset to;
}

/// Web: `platform/src/trainers/reading/letter-word-link/word-link-scene.tsx`
class WordLinkScene extends StatefulWidget {
  const WordLinkScene({
    super.key,
    required this.round,
    required this.connections,
    required this.letterColor,
    required this.onConnect,
    required this.onPlayWord,
    this.disabled = false,
  });

  final WordLinkRound round;
  final List<WordLinkConnection> connections;
  final Color letterColor;
  final ValueChanged<WordLinkConnection> onConnect;
  final ValueChanged<WordLinkItem> onPlayWord;
  final bool disabled;

  @override
  State<WordLinkScene> createState() => _WordLinkSceneState();
}

class _WordLinkSceneState extends State<WordLinkScene> {
  final _boardKey = GlobalKey();
  final _letterKey = GlobalKey();
  final _wordKeys = <String, GlobalKey>{};

  _ActiveDraw? _activeDraw;
  _WrongFlash? _wrongFlash;
  String? _wrongFlashRightId;
  Timer? _wrongFlashTimer;
  Timer? _interactionTimer;
  var _isInteractionReady = false;
  var _layoutVersion = 0;

  @override
  void initState() {
    super.initState();
    _ensureKeys();
    _scheduleInteractionReady();
  }

  @override
  void didUpdateWidget(WordLinkScene oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.round, widget.round)) {
      _ensureKeys();
      _isInteractionReady = false;
      _scheduleInteractionReady();
    }

    if (oldWidget.connections != widget.connections) {
      _scheduleLineRelayout();
    }
  }

  void _ensureKeys() {
    for (final item in widget.round.wordItems) {
      _wordKeys.putIfAbsent(item.id, GlobalKey.new);
    }
  }

  void _scheduleInteractionReady() {
    _interactionTimer?.cancel();
    _interactionTimer = Timer(
      Duration(
        milliseconds: getWordLinkInteractionReadyMs(
          widget.round.wordItems.length,
        ),
      ),
      () {
        if (mounted) {
          setState(() => _isInteractionReady = true);
        }
      },
    );
  }

  void _scheduleLineRelayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _layoutVersion++);
      }
    });
  }

  @override
  void dispose() {
    _wrongFlashTimer?.cancel();
    _interactionTimer?.cancel();
    super.dispose();
  }

  bool get _isLocked => widget.disabled || !_isInteractionReady;

  Set<String> get _connectedRightIds =>
      widget.connections.map((connection) => connection.rightId).toSet();

  RenderBox? get _boardBox =>
      _boardKey.currentContext?.findRenderObject() as RenderBox?;

  RenderBox? _itemBox(GlobalKey key) =>
      key.currentContext?.findRenderObject() as RenderBox?;

  Offset? _getAnchor(GlobalKey key, {required bool rightSide}) {
    final boardBox = _boardBox;
    final itemBox = _itemBox(key);

    if (boardBox == null || itemBox == null) {
      return null;
    }

    return boardPointToOffset(
      getElementAnchorPoint(
        itemBox,
        boardBox,
        rightSide: rightSide,
      ),
    );
  }

  Offset? _relativePoint(Offset globalPosition) {
    final boardBox = _boardBox;

    if (boardBox == null) {
      return null;
    }

    return globalPosition - boardBox.localToGlobal(Offset.zero);
  }

  List<_DrawLine> _lockedLines() {
    final lines = <_DrawLine>[];

    for (final connection in widget.connections) {
      final wordKey = _wordKeys[connection.rightId];

      if (wordKey == null) {
        continue;
      }

      final from = _getAnchor(_letterKey, rightSide: true);
      final to = _getAnchor(wordKey, rightSide: false);

      if (from != null && to != null) {
        lines.add(_DrawLine(from: from, to: to));
      }
    }

    return lines;
  }

  WordLinkItem? _findWordTarget(List<Offset> points) {
    final boardBox = _boardBox;
    if (boardBox == null) {
      return null;
    }

    return pickTargetAtPoints<WordLinkItem>(
      board: boardBox,
      elements: widget.round.wordItems,
      getElement: (item) {
        final key = _wordKeys[item.id];
        return key == null ? null : _itemBox(key);
      },
      isAvailable: (item) => !_connectedRightIds.contains(item.id),
      points: points.map(offsetToBoardPoint).toList(),
      padding: 20,
    );
  }

  void _handleLetterPointerDown(PointerDownEvent event) {
    if (_isLocked) {
      return;
    }

    final from = _getAnchor(_letterKey, rightSide: true);
    final to = _relativePoint(event.position);

    if (from == null || to == null) {
      return;
    }

    setState(() {
      _activeDraw = _ActiveDraw(from: from, to: to);
    });
  }

  void _handleLetterPointerEnd(PointerEvent event) {
    if (_activeDraw == null) {
      return;
    }

    final point = _relativePoint(event.position);
    if (point != null) {
      _finishDraw(point);
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_activeDraw == null || _isLocked) {
      return;
    }

    final to = _relativePoint(event.position);
    if (to == null) {
      return;
    }

    setState(() {
      _activeDraw = _ActiveDraw(from: _activeDraw!.from, to: to);
    });
  }

  void _handlePointerEnd(PointerEvent event) {
    if (_activeDraw == null) {
      return;
    }

    final point = _relativePoint(event.position);
    if (point != null) {
      _finishDraw(point);
    }
  }

  void _finishDraw(Offset releasePoint) {
    final activeDraw = _activeDraw;
    if (activeDraw == null) {
      return;
    }

    setState(() => _activeDraw = null);

    final wordItem = _findWordTarget([releasePoint, activeDraw.to]);
    if (wordItem == null) {
      return;
    }

    if (isCorrectWordLink(wordItem, widget.round.letter)) {
      widget.onConnect(
        WordLinkConnection(rightId: wordItem.id, slug: wordItem.slug),
      );
      return;
    }

    final wordKey = _wordKeys[wordItem.id];
    final wrongTo =
        wordKey == null ? null : _getAnchor(wordKey, rightSide: false);

    if (wrongTo != null) {
      _wrongFlashTimer?.cancel();
      setState(() {
        _wrongFlash = _WrongFlash(from: activeDraw.from, to: wrongTo);
        _wrongFlashRightId = wordItem.id;
      });
      _wrongFlashTimer = Timer(
        const Duration(milliseconds: TrainerTimings.wrongConnectionFlashMs),
        () {
          if (mounted) {
            setState(() {
              _wrongFlash = null;
              _wrongFlashRightId = null;
            });
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockedLines = _lockedLines();
    final missingAnchors = widget.connections.isNotEmpty &&
        lockedLines.length < widget.connections.length;

    if (missingAnchors) {
      _scheduleLineRelayout();
    }

    // Touch [_layoutVersion] so lines repaint after resize/connection updates.
    // ignore: unnecessary_statements
    _layoutVersion;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportHeight = constraints.maxHeight;
        final viewportWidth = constraints.maxWidth;
        final letterBoxSize = getWordLinkLetterBoxSize(
          viewportHeight,
          viewportWidth,
        );
        final letterFontSize = getWordLinkLetterFontSize(letterBoxSize);
        final cardCount = widget.round.wordItems.length;

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerMove: _isLocked ? null : _handlePointerMove,
          onPointerUp: _isLocked ? null : _handlePointerEnd,
          onPointerCancel: _isLocked ? null : _handlePointerEnd,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 768),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: SizedBox(
                  key: _boardKey,
                  width: constraints.maxWidth.clamp(0, 768),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 20),
                            child: KeyedSubtree(
                              key: _letterKey,
                              child: LetterWordLinkAnchorCard(
                                boxSize: letterBoxSize,
                                disabled: _isLocked,
                                displayLetter: widget.round.displayLetter,
                                fontSize: letterFontSize,
                                letterColor: widget.letterColor,
                                onPointerDown: _handleLetterPointerDown,
                                onPointerEnd: _handleLetterPointerEnd,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (var index = 0; index < cardCount; index++) ...[
                                  if (index > 0) const SizedBox(height: 12),
                                  KeyedSubtree(
                                    key: _wordKeys[widget.round.wordItems[index].id],
                                    child: WordLinkCard(
                                      connected: _connectedRightIds.contains(
                                        widget.round.wordItems[index].id,
                                      ),
                                      displayLabel:
                                          widget.round.wordItems[index].displayLabel,
                                      imageSrc: getWordLinkImageSrc(
                                        widget.round.wordItems[index].slug,
                                      ),
                                      onPlaySound: () => widget.onPlayWord(
                                        widget.round.wordItems[index],
                                      ),
                                      revealDelayMs: getWordLinkCardRevealDelayMs(
                                        index,
                                        cardCount,
                                      ),
                                      wrongFlash:
                                          _wrongFlashRightId ==
                                          widget.round.wordItems[index].id,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _WordLinkLinesPainter(
                              activeDraw: _activeDraw,
                              lockedLines: lockedLines,
                              wrongFlash: _wrongFlash,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WordLinkLinesPainter extends CustomPainter {
  _WordLinkLinesPainter({
    required this.lockedLines,
    required this.activeDraw,
    required this.wrongFlash,
  });

  final List<_DrawLine> lockedLines;
  final _ActiveDraw? activeDraw;
  final _WrongFlash? wrongFlash;

  @override
  void paint(Canvas canvas, Size size) {
    final lockedPaint = Paint()
      ..color = wordLinkLineLockedColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (final line in lockedLines) {
      canvas.drawLine(line.from, line.to, lockedPaint);
    }

    if (activeDraw != null) {
      _drawDashedLine(
        canvas,
        activeDraw!.from,
        activeDraw!.to,
        Paint()
          ..color = wordLinkLineDraftColor
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }

    if (wrongFlash != null) {
      canvas.drawLine(
        wrongFlash!.from,
        wrongFlash!.to,
        Paint()
          ..color = wordLinkLineWrongColor
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(to.dx, to.dy);

    const dashWidth = 8.0;
    const dashSpace = 6.0;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WordLinkLinesPainter oldDelegate) {
    return oldDelegate.lockedLines != lockedLines ||
        oldDelegate.activeDraw != activeDraw ||
        oldDelegate.wrongFlash != wrongFlash;
  }
}
