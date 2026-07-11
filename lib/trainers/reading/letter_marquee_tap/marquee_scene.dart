import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_found_burst.dart';
import 'package:larnes_mobile/trainers/reading/letter_marquee_tap/marquee_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_marquee_tap/marquee_sizes.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

const _popCurve = Cubic(0.34, 1.2, 0.64, 1);
const _wrongRed = Color(0xFFDC2626);
const _letterInk = Color(marqueeLetterColor);

class ActiveMarqueeToken {
  ActiveMarqueeToken({
    required this.spec,
    required this.x,
    this.caughtBurst = false,
    this.wrongFlash = false,
  });

  final MarqueeTokenSpec spec;
  double x;
  bool caughtBurst;
  bool wrongFlash;
}

/// Web: `platform/src/trainers/reading/letter-marquee-tap/marquee-scene.tsx`
class MarqueeScene extends StatefulWidget {
  const MarqueeScene({
    super.key,
    required this.stream,
    required this.letterCase,
    required this.speed,
    required this.onCatch,
    this.onWrongCatch,
    this.disabled = false,
  });

  final List<MarqueeTokenSpec> stream;
  final String letterCase;
  final String speed;
  final VoidCallback onCatch;
  final VoidCallback? onWrongCatch;
  final bool disabled;

  @override
  State<MarqueeScene> createState() => _MarqueeSceneState();
}

class _MarqueeSceneState extends State<MarqueeScene> with TickerProviderStateMixin {
  Ticker? _ticker;
  Duration? _previousElapsed;
  Duration _lastSpawnAt = Duration.zero;
  int _streamIndex = 0;
  double _laneWidth = 320;
  final List<ActiveMarqueeToken> _activeTokens = [];

  @override
  void initState() {
    super.initState();
    _resetStreamState();
    _startTicker();
  }

  @override
  void didUpdateWidget(MarqueeScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      _resetStreamState();
    }
    if (oldWidget.disabled != widget.disabled) {
      if (widget.disabled) {
        _ticker?.stop();
      } else {
        _ticker?.start();
      }
    }
  }

  void _resetStreamState() {
    _streamIndex = 0;
    _lastSpawnAt = Duration.zero;
    _previousElapsed = null;
    _activeTokens.clear();
  }

  void _startTicker() {
    _ticker?.dispose();
    _ticker = createTicker(_onTick);
    if (!widget.disabled) {
      _ticker!.start();
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted || widget.disabled) {
      return;
    }

    final deltaMs = _previousElapsed == null
        ? 0.0
        : (elapsed - _previousElapsed!).inMicroseconds / 1000.0;
    _previousElapsed = elapsed;

    if (_lastSpawnAt == Duration.zero) {
      _lastSpawnAt = elapsed;
    }

    final motion = getMarqueeMotion(widget.speed);
    final chipSize = getMarqueeChipSizePx(MediaQuery.sizeOf(context).height);
    final shouldSpawn = _streamIndex < widget.stream.length &&
        elapsed.inMilliseconds - _lastSpawnAt.inMilliseconds >=
            motion.spawnIntervalMs;

    setState(() {
      final deltaX = motion.pixelsPerSecond * deltaMs / 1000;
      for (final token in _activeTokens) {
        if (!token.caughtBurst) {
          token.x -= deltaX;
        }
      }

      _activeTokens.removeWhere(
        (token) => !token.caughtBurst && token.x + chipSize <= -chipSize * 0.5,
      );

      if (shouldSpawn) {
        final spec = widget.stream[_streamIndex];
        _streamIndex += 1;
        _lastSpawnAt = elapsed;
        _activeTokens.add(
          ActiveMarqueeToken(
            spec: spec,
            x: _laneWidth,
          ),
        );
      }
    });
  }

  void _handleTokenTap(ActiveMarqueeToken token) {
    if (widget.disabled || token.caughtBurst) {
      return;
    }

    if (token.spec.isTarget) {
      setState(() => token.caughtBurst = true);
      widget.onCatch();

      Future<void>.delayed(
        const Duration(milliseconds: letterFoundBurstMs),
        () {
          if (!mounted) {
            return;
          }
          setState(() {
            _activeTokens.removeWhere((item) => item.spec.id == token.spec.id);
          });
        },
      );
      return;
    }

    setState(() => token.wrongFlash = true);
    widget.onWrongCatch?.call();

    Future<void>.delayed(
      const Duration(milliseconds: TrainerTimings.wrongFeedbackMs),
      () {
        if (!mounted) {
          return;
        }
        setState(() {
          if (_activeTokens.contains(token)) {
            token.wrongFlash = false;
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final chipSize = getMarqueeChipSizePx(viewportHeight);
    final fontSize = getMarqueeChipFontSizePx(chipSize);
    final laneHeight = getMarqueeLaneHeightPx(viewportHeight);

    return LayoutBuilder(
      builder: (context, constraints) {
        final laneWidth = constraints.maxWidth;
        if (laneWidth != _laneWidth) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && laneWidth != _laneWidth) {
              setState(() => _laneWidth = laneWidth);
            }
          });
        }

        return SizedBox(
          height: laneHeight,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: laneHeight * 0.2,
                child: const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(marqueeRailColor),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: laneHeight * 0.2,
                child: const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(marqueeRailColor),
                ),
              ),
              for (final token in _activeTokens)
                _MarqueeToken(
                  key: ValueKey(token.spec.id),
                  token: token,
                  chipSize: chipSize,
                  fontSize: fontSize,
                  letterCase: widget.letterCase,
                  laneHeight: laneHeight,
                  disabled: widget.disabled,
                  onTap: () => _handleTokenTap(token),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MarqueeToken extends StatefulWidget {
  const _MarqueeToken({
    super.key,
    required this.token,
    required this.chipSize,
    required this.fontSize,
    required this.letterCase,
    required this.laneHeight,
    required this.disabled,
    required this.onTap,
  });

  final ActiveMarqueeToken token;
  final double chipSize;
  final double fontSize;
  final String letterCase;
  final double laneHeight;
  final bool disabled;
  final VoidCallback onTap;

  @override
  State<_MarqueeToken> createState() => _MarqueeTokenState();
}

class _MarqueeTokenState extends State<_MarqueeToken> with TickerProviderStateMixin {
  late final AnimationController _enterController;
  late final Animation<double> _enterProgress;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeOffset;
  late final AnimationController _caughtController;
  late final Animation<double> _caughtOpacity;
  late final Animation<double> _caughtScale;

  ActiveMarqueeToken get _token => widget.token;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _enterProgress = CurvedAnimation(parent: _enterController, curve: _popCurve);
    _enterController.forward();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeOffset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));

    _caughtController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: letterFoundBurstMs),
    );
    _caughtOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _caughtController, curve: Curves.easeOut),
    );
    _caughtScale = Tween<double>(begin: 1, end: 1.12).animate(
      CurvedAnimation(parent: _caughtController, curve: _popCurve),
    );

    if (_token.wrongFlash) {
      _shakeController.forward(from: 0);
    }
    if (_token.caughtBurst) {
      _caughtController.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(_MarqueeToken oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.token.wrongFlash && widget.token.wrongFlash) {
      _shakeController.forward(from: 0);
    }
    if (!oldWidget.token.caughtBurst && widget.token.caughtBurst) {
      _caughtController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _enterController.dispose();
    _shakeController.dispose();
    _caughtController.dispose();
    super.dispose();
  }

  Color get _textColor {
    if (_token.wrongFlash) {
      return _wrongRed;
    }
    return _letterInk;
  }

  @override
  Widget build(BuildContext context) {
    final top = (widget.laneHeight - widget.chipSize) / 2;

    return Positioned(
      left: _token.x,
      top: top,
      width: widget.chipSize,
      height: widget.chipSize,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _enterProgress,
          _shakeController,
          _caughtController,
        ]),
        builder: (context, child) {
          final enterT = _enterProgress.value.clamp(0.0, 1.0);
          final opacity = _token.caughtBurst
              ? _caughtOpacity.value.clamp(0.0, 1.0)
              : 0.9 + 0.1 * enterT;
          final scale = _token.caughtBurst
              ? _caughtScale.value.clamp(1.0, 1.12)
              : 0.9 + 0.1 * enterT;

          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(_shakeOffset.value, 0),
              child: Transform.scale(
                scale: scale,
                child: child,
              ),
            ),
          );
        },
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (_token.caughtBurst)
              LetterFoundBurst(
                color: _letterInk,
                size: widget.chipSize,
              ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.disabled || _token.caughtBurst ? null : widget.onTap,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: widget.chipSize,
                  height: widget.chipSize,
                  child: Center(
                    child: Text(
                      getMarqueeDisplayLetter(
                        _token.spec.letter,
                        widget.letterCase,
                      ),
                      style: GoogleFonts.onest(
                        fontSize: widget.fontSize,
                        fontWeight: FontWeight.w700,
                        color: _textColor,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
