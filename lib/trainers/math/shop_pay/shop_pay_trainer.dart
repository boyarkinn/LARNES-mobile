import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/shop_pay/shop_pay_model.dart';
import 'package:larnes_mobile/trainers/math/shop_pay/shop_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

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
  var _isComplete = false;
  var _completeCalled = false;
  Timer? _completeTimer;

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
  void dispose() {
    _completeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = normalizeShopItemSlug(widget.params['item'] as String? ?? 'candy');
    final price = widget.params['price'] as int? ?? 1;
    final coinCount = widget.params['coinCount'] as int? ?? price;

    return TrainerScene(
      child: ShopScene(
        coinCount: coinCount,
        disabled: _isComplete,
        item: item,
        onPaymentSuccess: _handlePaymentSuccess,
        price: price,
      ),
    );
  }
}
