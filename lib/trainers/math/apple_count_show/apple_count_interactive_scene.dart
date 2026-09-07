import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_show_audio.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_show_model.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_glyph.dart';

/// Web: `platform/src/trainers/math/apple-count-show/apple-count-interactive-scene.tsx`
class AppleCountInteractiveScene extends StatefulWidget {
  const AppleCountInteractiveScene({
    super.key,
    required this.targetCount,
    required this.totalApples,
    required this.targetDisplay,
    this.disabled = false,
    required this.onComplete,
  });

  final int targetCount;
  final int totalApples;
  final String targetDisplay;
  final bool disabled;
  final VoidCallback onComplete;

  @override
  State<AppleCountInteractiveScene> createState() => _AppleCountInteractiveSceneState();
}

class _AppleCountInteractiveSceneState extends State<AppleCountInteractiveScene>
    with SingleTickerProviderStateMixin {
  static const _appleSize = 52.0;
  static const _basketAppleSize = 46.0;

  late List<AppleEntity> _apples;
  var _shuffleGeneration = 0;
  var _hasErrorFlash = false;
  var _isSuccess = false;

  Timer? _errorFlashTimer;
  Object _audioToken = Object();
  late final AnimationController _shakeController;
  late final Animation<double> _shakeOffset;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeOffset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
    _restartScene();
  }

  @override
  void didUpdateWidget(AppleCountInteractiveScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetCount != widget.targetCount ||
        oldWidget.totalApples != widget.totalApples ||
        oldWidget.targetDisplay != widget.targetDisplay) {
      _restartScene();
    }
  }

  @override
  void dispose() {
    _errorFlashTimer?.cancel();
    _shakeController.dispose();
    unawaited(cancelAppleCountShowAudio());
    super.dispose();
  }

  void _restartScene() {
    final audioToken = Object();
    _audioToken = audioToken;
    _errorFlashTimer?.cancel();
    unawaited(cancelAppleCountShowAudio());

    setState(() {
      _apples = buildInitialApples(
        widget.totalApples,
        widget.targetCount,
        widget.targetDisplay,
      );
      _shuffleGeneration = 0;
      _hasErrorFlash = false;
      _isSuccess = false;
    });

    unawaited(_playTargetAudio(audioToken));
  }

  Future<void> _playTargetAudio(Object audioToken) async {
    try {
      await playAppleTargetCountAudio(widget.targetCount);
    } catch (_) {
      // fallback без mp3
    }
    if (!mounted || !identical(audioToken, _audioToken)) {
      return;
    }
  }

  bool get _isLocked => widget.disabled || _isSuccess;

  bool get _showTargetDigit => widget.targetDisplay == targetDisplayWithDigit;

  int get _basketCount => countApplesInBasket(_apples);

  List<AppleEntity> get _basketApples {
    return _apples
        .where((apple) => apple.zone == AppleEntity.zoneBasket)
        .toList()
      ..sort((left, right) => (left.basketSlot ?? 0).compareTo(right.basketSlot ?? 0));
  }

  List<AppleEntity> get _fieldApples {
    return _apples.where((apple) => apple.zone == AppleEntity.zoneField).toList();
  }

  void _flashError() {
    _errorFlashTimer?.cancel();
    setState(() => _hasErrorFlash = true);
    _shakeController.forward(from: 0);
    _errorFlashTimer = Timer(const Duration(milliseconds: 550), () {
      if (mounted) {
        setState(() => _hasErrorFlash = false);
      }
    });
  }

  void _placeAppleInBasket(String appleId) {
    setState(() {
      _apples = moveAppleToBasket(_apples, appleId);
      _hasErrorFlash = false;
    });
  }

  void _returnAppleToField(String appleId) {
    final nextGeneration = _shuffleGeneration + 1;
    final positions = buildInitialApples(
      widget.totalApples,
      widget.targetCount,
      widget.targetDisplay,
      nextGeneration,
    );
    final index = _apples.indexWhere((apple) => apple.id == appleId);
    if (index < 0 || index >= positions.length) {
      return;
    }

    setState(() {
      _shuffleGeneration = nextGeneration;
      _apples = moveAppleToField(
        _apples,
        appleId,
        ScatterPosition(
          xPercent: positions[index].xPercent,
          yPercent: positions[index].yPercent,
        ),
      );
      _hasErrorFlash = false;
    });
  }

  void _handleReady() {
    if (_isLocked || _basketCount == 0) {
      return;
    }

    if (isCorrectBasketCount(_basketCount, widget.targetCount)) {
      setState(() {
        _hasErrorFlash = false;
        _isSuccess = true;
      });
      widget.onComplete();
      return;
    }

    _flashError();
    final nextGeneration = _shuffleGeneration + 1;
    setState(() {
      _shuffleGeneration = nextGeneration;
      _apples = reshuffleAllApplesToField(
        _apples,
        widget.totalApples,
        widget.targetCount,
        widget.targetDisplay,
        nextGeneration,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _isSuccess
        ? const Color(0xCC4ADE80)
        : _hasErrorFlash
            ? const Color(0xCCFB7185)
            : const Color(0xB3FCD34D);
    final backgroundColor = _isSuccess
        ? const Color(0x59ECFDF5)
        : _hasErrorFlash
            ? const Color(0x59FFE4E6)
            : Colors.transparent;

    return Column(
      children: [
        if (_showTargetDigit)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${widget.targetCount}',
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w700,
                color: Color(0xFFDC2626),
                height: 1,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final apple in _fieldApples)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOutBack,
                      left: constraints.maxWidth * apple.xPercent / 100 - _appleSize / 2,
                      top: constraints.maxHeight * apple.yPercent / 100 - _appleSize / 2,
                      child: _AppleDraggable(
                        appleId: apple.id,
                        disabled: _isLocked,
                        size: _appleSize,
                        onDragEndedOutsideBasket: null,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shakeOffset.value, 0),
                child: child,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Column(
                children: [
                  const BasketGlyph(height: 100),
                  const SizedBox(height: 8),
                  DragTarget<String>(
                    onWillAcceptWithDetails: (_) => !_isLocked,
                    onAcceptWithDetails: (details) => _placeAppleInBasket(details.data),
                    builder: (context, candidate, rejected) {
                      final highlighted = candidate.isNotEmpty;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: highlighted
                            ? BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x334F46E5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              )
                            : null,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final apple in _basketApples)
                              _AppleDraggable(
                                appleId: apple.id,
                                disabled: _isLocked,
                                size: _basketAppleSize,
                                onDragEndedOutsideBasket: _returnAppleToField,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLocked || _basketCount == 0 ? null : _handleReady,
              child: const Text('ГОТОВО'),
            ),
          ),
        ),
      ],
    );
  }
}

class _AppleDraggable extends StatelessWidget {
  const _AppleDraggable({
    required this.appleId,
    required this.disabled,
    required this.size,
    this.onDragEndedOutsideBasket,
  });

  final String appleId;
  final bool disabled;
  final double size;
  final ValueChanged<String>? onDragEndedOutsideBasket;

  @override
  Widget build(BuildContext context) {
    if (disabled) {
      return AppleGlyph(size: size);
    }

    return Draggable<String>(
      data: appleId,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(opacity: 0.92, child: AppleGlyph(size: size + 6)),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: AppleGlyph(size: size)),
      onDragEnd: (details) {
        if (details.wasAccepted) {
          return;
        }
        onDragEndedOutsideBasket?.call(appleId);
      },
      child: AppleGlyph(size: size),
    );
  }
}
