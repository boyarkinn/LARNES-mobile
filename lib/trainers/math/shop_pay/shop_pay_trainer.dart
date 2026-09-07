import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/shop_pay/shop_pay_audio.dart';
import 'package:larnes_mobile/trainers/math/shop_pay/shop_pay_model.dart';
import 'package:larnes_mobile/trainers/math/shop_pay/shop_scene.dart';
import 'package:larnes_mobile/trainers/shared/instruction/load_trainer_instruction_duration.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_typewriter.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

enum ShopPayPhase { instruction, countdown, play }

/// Web v2: `platform/src/trainers/math/shop-pay/component.tsx`
class ShopPayTrainer extends StatefulWidget {
  const ShopPayTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<ShopPayTrainer> createState() => _ShopPayTrainerState();
}

class _ShopPayTrainerState extends State<ShopPayTrainer> {
  static const _instructionText = 'Купи товар';
  static const _countdownLabels = ['3', '2', '1', 'СТАРТ'];
  static const _countdownStepMs = 750;
  static const _countdownColor = Color(0xFFDC2626);

  var _phase = ShopPayPhase.instruction;
  var _countdownLabel = _countdownLabels.first;
  var _instructionLength = 0;
  var _isComplete = false;
  var _completeCalled = false;
  Object _runToken = Object();

  final _instructionTypewriter = TrainerInstructionTypewriter();
  Timer? _countdownTimer;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  @override
  void didUpdateWidget(ShopPayTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params != widget.params) {
      _startSession();
    }
  }

  @override
  void dispose() {
    _instructionTypewriter.cancel();
    _countdownTimer?.cancel();
    _completeTimer?.cancel();
    unawaited(cancelShopPayAudio());
    super.dispose();
  }

  void _startSession() {
    final runToken = Object();
    _runToken = runToken;
    _instructionTypewriter.cancel();
    _countdownTimer?.cancel();
    _completeTimer?.cancel();
    unawaited(cancelShopPayAudio());

    setState(() {
      _phase = ShopPayPhase.instruction;
      _instructionLength = 0;
      _countdownLabel = _countdownLabels.first;
      _isComplete = false;
      _completeCalled = false;
    });

    unawaited(_runInstruction(runToken));
  }

  Future<void> _runInstruction(Object runToken) async {
    final durationMs = await loadTrainerInstructionDurationMs(
      assetPath: getShopPayInstructionAudioAsset(),
      playbackRate: kShopPayInstructionPlaybackRate,
      fallbackMs: kShopPayInstructionDurationFallbackMs,
    );
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _instructionTypewriter.start(
      text: _instructionText,
      durationMs: durationMs,
      isCurrent: () => mounted && identical(runToken, _runToken),
      onLength: (length) {
        if (!mounted || !identical(runToken, _runToken)) {
          return;
        }
        setState(() => _instructionLength = length);
      },
    );

    await playShopPayInstruction();
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _instructionTypewriter.cancel();
    setState(() {
      _instructionLength = _instructionText.length;
      _phase = ShopPayPhase.countdown;
    });
    _runCountdown(runToken);
  }

  void _runCountdown(Object runToken) {
    _countdownTimer?.cancel();
    var index = 0;

    void showNext() {
      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }

      if (index >= _countdownLabels.length) {
        setState(() => _phase = ShopPayPhase.play);
        return;
      }

      setState(() => _countdownLabel = _countdownLabels[index]);
      index += 1;
      _countdownTimer = Timer(
        const Duration(milliseconds: _countdownStepMs),
        showNext,
      );
    }

    showNext();
  }

  void _handlePaymentSuccess() {
    setState(() => _isComplete = true);
    _scheduleComplete();
  }

  void _scheduleComplete() {
    if (_completeCalled || widget.onComplete == null) {
      return;
    }

    _completeCalled = true;
    _completeTimer = Timer(
      const Duration(milliseconds: TrainerTimings.completeDelayMs),
      () {
        if (mounted) {
          widget.onComplete?.call();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = normalizeShopItemSlug(widget.params['item'] as String? ?? 'candy');
    final price = widget.params['price'] as int? ?? 1;
    final coinCount = widget.params['coinCount'] as int? ?? price;

    return TrainerScene(
      child: switch (_phase) {
        ShopPayPhase.instruction => TrainerInstructionScene(
          length: _instructionLength,
          text: _instructionText,
        ),
        ShopPayPhase.countdown => Center(
          child: Text(
            _countdownLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: MediaQuery.sizeOf(context).shortestSide * 0.26,
              height: 1,
              color: _countdownColor,
            ),
          ),
        ),
        ShopPayPhase.play => ShopScene(
          coinCount: coinCount,
          disabled: _isComplete,
          item: item,
          onPaymentSuccess: _handlePaymentSuccess,
          price: price,
        ),
      },
    );
  }
}
