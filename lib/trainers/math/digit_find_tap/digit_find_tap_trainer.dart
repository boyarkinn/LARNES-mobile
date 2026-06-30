import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_field_scene.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_find_tap_layout.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_find_tap_model.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

const _wrongFeedbackMs = 550;
const _completeDelayMs = 900;

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
  late final List<PlacedDigit> _digits;
  final Set<String> _foundIds = {};
  String? _wrongId;
  bool _isCompleted = false;
  bool _completeCalled = false;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _digits = _buildDigits();
  }

  List<PlacedDigit> _buildDigits() {
    final targetDigit = normalizeTargetDigit(widget.params['digit'] as num? ?? 0);
    final targetCount = widget.params['targetCount'] as int? ?? 1;
    final distractorCount = widget.params['distractorCount'] as int? ?? 0;

    final seed = hashParamsSeed([targetDigit, targetCount, distractorCount]);
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

  int get _targetsTotal => _digits.where((digit) => digit.isTarget).length;

  int get _targetDigit =>
      normalizeTargetDigit(widget.params['digit'] as num? ?? 0);

  void _handleTap(String id) {
    if (_isCompleted || _foundIds.contains(id)) {
      return;
    }

    final tokenIndex = _digits.indexWhere((digit) => digit.id == id);
    if (tokenIndex < 0) {
      return;
    }
    final token = _digits[tokenIndex];

    if (!token.isTarget) {
      setState(() => _wrongId = id);
      Future<void>.delayed(const Duration(milliseconds: _wrongFeedbackMs), () {
        if (!mounted) {
          return;
        }
        setState(() {
          if (_wrongId == id) {
            _wrongId = null;
          }
        });
      });
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
      const Duration(milliseconds: _completeDelayMs),
      () {
        if (mounted) {
          widget.onComplete?.call();
        }
      },
    );
  }

  @override
  void dispose() {
    _completeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4B5563),
            ),
            children: [
              const TextSpan(text: 'Найди все цифры '),
              TextSpan(
                text: '$_targetDigit',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7C3AED),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const TextSpan(
                text: ' · ',
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
              TextSpan(
                text: '${_foundIds.length}/$_targetsTotal',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        DigitFieldScene(
          digits: _digits,
          disabled: _isCompleted,
          foundIds: _foundIds,
          onTap: _handleTap,
          wrongId: _wrongId,
        ),
        if (_isCompleted) ...[
          const SizedBox(height: 12),
          const Text(
            'Молодец!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF16A34A),
            ),
          ),
        ],
      ],
    );
  }
}
