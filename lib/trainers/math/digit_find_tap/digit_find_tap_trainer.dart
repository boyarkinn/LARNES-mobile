import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_field_scene.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_find_tap_layout.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_find_tap_model.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

/// Web v2: `platform/src/trainers/math/digit-find-tap/component.tsx`
class DigitFindTapTrainer extends StatefulWidget {
  const DigitFindTapTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<DigitFindTapTrainer> createState() => _DigitFindTapTrainerState();
}

class _DigitFindTapTrainerState extends State<DigitFindTapTrainer> {
  late final int _layoutSalt;
  late final List<PlacedDigit> _digits;

  final Set<String> _foundIds = {};
  String? _wrongId;
  var _isCompleted = false;
  var _isRevealComplete = false;
  var _completeCalled = false;
  Timer? _revealTimer;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _layoutSalt = createLayoutSalt();
    _digits = _buildDigits();
    _scheduleReveal();
  }

  List<PlacedDigit> _buildDigits() {
    final targetDigit = normalizeTargetDigit(widget.params['digit'] as num? ?? 0);
    final targetCount = widget.params['targetCount'] as int? ?? 1;
    final distractorCount = widget.params['distractorCount'] as int? ?? 0;

    final seed = hashParamsSeed([
      targetDigit,
      targetCount,
      distractorCount,
      _layoutSalt,
    ]);
    final rng = createSeededRng(seed);
    final tokens = buildDigitTokens(
      BuildDigitFieldInput(
        distractorCount: distractorCount,
        rng: rng,
        targetCount: targetCount,
        targetDigit: targetDigit,
      ),
    );

    return placeDigitTokens(tokens, rng);
  }

  void _scheduleReveal() {
    _revealTimer?.cancel();

    if (_digits.isEmpty) {
      setState(() => _isRevealComplete = true);
      return;
    }

    setState(() => _isRevealComplete = false);

    _revealTimer = Timer(
      Duration(milliseconds: getFruitRevealTotalMs(_digits.length)),
      () {
        if (!mounted) {
          return;
        }
        setState(() => _isRevealComplete = true);
      },
    );
  }

  void _handleTap(String id) {
    if (_isCompleted || !_isRevealComplete || _foundIds.contains(id)) {
      return;
    }

    final tokenIndex = _digits.indexWhere((digit) => digit.id == id);
    if (tokenIndex < 0) {
      return;
    }
    final token = _digits[tokenIndex];

    if (!token.isTarget) {
      setState(() => _wrongId = id);
      Future<void>.delayed(
        const Duration(milliseconds: TrainerTimings.wrongFeedbackMs),
        () {
          if (!mounted) {
            return;
          }
          setState(() {
            if (_wrongId == id) {
              _wrongId = null;
            }
          });
        },
      );
      return;
    }

    setState(() => _foundIds.add(id));

    if (allTargetsFound(_foundIds, _digits)) {
      setState(() => _isCompleted = true);
      _scheduleComplete();
    }
  }

  void _scheduleComplete() {
    if (_completeCalled || widget.onComplete == null) {
      return;
    }

    _completeCalled = true;
    _completeTimer = Timer(
      const Duration(milliseconds: TrainerTimings.completeAfterBurstMs),
      () {
        if (mounted) {
          widget.onComplete?.call();
        }
      },
    );
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _completeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TrainerScene(
      child: DigitFieldScene(
        digits: _digits,
        disabled: _isCompleted || !_isRevealComplete,
        foundIds: _foundIds,
        onTap: _handleTap,
        wrongId: _wrongId,
      ),
    );
  }
}
