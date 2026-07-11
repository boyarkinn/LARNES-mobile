import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/math/shop_pay/ruble_coin.dart';
import 'package:larnes_mobile/trainers/math/shop_pay/shop_item_icon.dart';
import 'package:larnes_mobile/trainers/math/shop_pay/shop_pay_model.dart';
import 'package:larnes_mobile/trainers/math/shop_pay/shop_reveal.dart';
import 'package:larnes_mobile/trainers/math/shop_pay/shop_scene_layout.dart';

/// Web v2: `platform/src/trainers/math/shop-pay/shop-scene.tsx`
class ShopScene extends StatefulWidget {
  const ShopScene({
    super.key,
    required this.coinCount,
    required this.item,
    required this.price,
    this.disabled = false,
    required this.onPaymentSuccess,
  });

  final int coinCount;
  final ShopItemSlug item;
  final int price;
  final bool disabled;
  final VoidCallback onPaymentSuccess;

  @override
  State<ShopScene> createState() => _ShopSceneState();
}

class _ShopSceneState extends State<ShopScene> {
  late List<ShopCoin> _coins;
  var _hasErrorFlash = false;
  var _isSuccess = false;
  var _isInteractionReady = false;
  var _isPayVisible = false;
  Timer? _payRevealTimer;
  Timer? _interactionReadyTimer;
  Timer? _errorFlashTimer;

  @override
  void initState() {
    super.initState();
    _resetScene();
  }

  @override
  void didUpdateWidget(ShopScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coinCount != widget.coinCount ||
        oldWidget.item != widget.item ||
        oldWidget.price != widget.price) {
      setState(_resetScene);
    }
  }

  void _resetScene() {
    _payRevealTimer?.cancel();
    _interactionReadyTimer?.cancel();
    _errorFlashTimer?.cancel();

    _coins = createCoins(widget.coinCount);
    _hasErrorFlash = false;
    _isSuccess = false;
    _isInteractionReady = false;
    _isPayVisible = false;

    _payRevealTimer = Timer(
      Duration(milliseconds: getShopPayRevealStartMs(widget.coinCount)),
      () {
        if (mounted) {
          setState(() => _isPayVisible = true);
        }
      },
    );

    _interactionReadyTimer = Timer(
      Duration(milliseconds: getShopInteractionReadyMs(widget.coinCount)),
      () {
        if (mounted) {
          setState(() => _isInteractionReady = true);
        }
      },
    );
  }

  int get _paidAmount => countCoinsInRegister(_coins);

  bool get _isLocked =>
      widget.disabled || _isSuccess || !_isInteractionReady;

  List<ShopCoin> get _trayCoins =>
      _coins.where((coin) => coin.zone == coinZoneTray).toList();

  List<ShopCoin> get _registerCoins =>
      _coins.where((coin) => coin.zone == coinZoneRegister).toList();

  void _moveCoin(String coinId, String zone) {
    setState(() {
      _coins = moveCoinToZone(_coins, coinId, zone);
      _hasErrorFlash = false;
    });
  }

  void _toggleCoinZone(ShopCoin coin) {
    if (_isLocked) {
      return;
    }

    final nextZone =
        coin.zone == coinZoneTray ? coinZoneRegister : coinZoneTray;
    _moveCoin(coin.id, nextZone);
  }

  void _flashError() {
    _errorFlashTimer?.cancel();
    setState(() => _hasErrorFlash = true);
    _errorFlashTimer = Timer(const Duration(milliseconds: 550), () {
      if (mounted) {
        setState(() => _hasErrorFlash = false);
      }
    });
  }

  void _handlePay() {
    if (_isLocked || _paidAmount == 0) {
      return;
    }

    final result = validatePayment(widget.price, _paidAmount);

    if (result.ok) {
      setState(() {
        _hasErrorFlash = false;
        _isSuccess = true;
      });
      widget.onPaymentSuccess();
      return;
    }

    _flashError();
    setState(() => _coins = resetCoinsToTray(_coins));
  }

  @override
  void dispose() {
    _payRevealTimer?.cancel();
    _interactionReadyTimer?.cancel();
    _errorFlashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportHeight = constraints.maxHeight;
        final layout = computeShopSceneLayout(
          viewportWidth: constraints.maxWidth,
          viewportHeight: viewportHeight,
        );
        final itemSize = layout.itemSize;
        final trayCoinSize = layout.trayCoinSize;
        final registerCoinSize = layout.registerCoinSize;
        final dragCoinSize = layout.dragCoinSize;
        final priceFontSize = layout.priceFontSize;
        final paidFontSize = layout.paidFontSize;

        final registerBorderColor = _isSuccess
            ? const Color(0xCC4ADE80)
            : _hasErrorFlash
                ? const Color(0xCCFB7185)
                : const Color(0xB3818CF8);
        final registerBackground = _isSuccess
            ? const Color(0x66DCFCE7)
            : _hasErrorFlash
                ? const Color(0x59FFE4E6)
                : Colors.transparent;

        return Column(
          children: [
            Expanded(
              flex: 110,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _ShopRevealBlock(
                      delayMs: shopShowcaseRevealDelayMs,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ShopItemIcon(item: widget.item, size: itemSize),
                          const SizedBox(height: 12),
                          Text(
                            '${widget.price} ₽',
                            style: TextStyle(
                              fontSize: priceFontSize,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF4F46E5),
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 135,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _ShopRevealBlock(
                  delayMs: shopRegisterRevealDelayMs,
                  child: _RegisterZone(
                    backgroundColor: registerBackground,
                    borderColor: registerBorderColor,
                    isShaking: _hasErrorFlash,
                    onAcceptCoin: _isLocked ? null : _moveCoin,
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: _registerCoins
                                  .map(
                                    (coin) => _RegisterCoinButton(
                                      coin: coin,
                                      disabled: _isLocked,
                                      size: registerCoinSize,
                                      onTap: () => _toggleCoinZone(coin),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '$_paidAmount ₽',
                              style: TextStyle(
                                fontSize: paidFontSize,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF4338CA),
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 100,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var index = 0; index < _trayCoins.length; index++)
                          _TrayCoinButton(
                            coin: _trayCoins[index],
                            delayMs: getShopCoinRevealDelayMs(
                              index,
                              widget.coinCount,
                            ),
                            disabled: _isLocked,
                            dragSize: dragCoinSize,
                            size: trayCoinSize,
                            onSelect: () => _toggleCoinZone(_trayCoins[index]),
                            onDropped: (zone) =>
                                _moveCoin(_trayCoins[index].id, zone),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _isPayVisible
                  ? _ShopRevealBlock(
                      delayMs: 0,
                      child: _ShopPayButton(
                        disabled: _isLocked || _paidAmount == 0,
                        onPressed: _handlePay,
                      ),
                    )
                  : const SizedBox(height: 48),
            ),
          ],
        );
      },
    );
  }
}

class _ShopRevealBlock extends StatefulWidget {
  const _ShopRevealBlock({
    required this.delayMs,
    required this.child,
  });

  final int delayMs;
  final Widget child;

  @override
  State<_ShopRevealBlock> createState() => _ShopRevealBlockState();
}

class _ShopRevealBlockState extends State<_ShopRevealBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  Timer? _enterTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: kFruitPopDurationMs),
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    if (widget.delayMs <= 0) {
      _controller.value = 1;
      return;
    }

    _enterTimer = Timer(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _enterTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final t = _progress.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: 0.92 + 0.08 * t,
            child: Transform.translate(
              offset: Offset(0, 8 * (1 - t)),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _RegisterZone extends StatefulWidget {
  const _RegisterZone({
    required this.backgroundColor,
    required this.borderColor,
    required this.isShaking,
    required this.child,
    this.onAcceptCoin,
  });

  final Color backgroundColor;
  final Color borderColor;
  final bool isShaking;
  final Widget child;
  final void Function(String coinId, String zone)? onAcceptCoin;

  @override
  State<_RegisterZone> createState() => _RegisterZoneState();
}

class _RegisterZoneState extends State<_RegisterZone>
    with SingleTickerProviderStateMixin {
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

    if (widget.isShaking) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(_RegisterZone oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isShaking && widget.isShaking) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeOffset.value, 0),
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: widget.borderColor,
            radius: 16,
            strokeWidth: 2,
          ),
          child: widget.child,
        ),
      ),
    );

    final onAccept = widget.onAcceptCoin;
    if (onAccept == null) {
      return content;
    }

    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onAccept(details.data, coinZoneRegister),
      builder: (context, candidate, rejected) {
        final highlighted = candidate.isNotEmpty;
        if (!highlighted) {
          return content;
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x334F46E5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: content,
        );
      },
    );
  }
}

class _RegisterCoinButton extends StatelessWidget {
  const _RegisterCoinButton({
    required this.coin,
    required this.disabled,
    required this.size,
    required this.onTap,
  });

  final ShopCoin coin;
  final bool disabled;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        customBorder: const CircleBorder(),
        child: RubleCoin(size: size),
      ),
    );
  }
}

class _TrayCoinButton extends StatefulWidget {
  const _TrayCoinButton({
    required this.coin,
    required this.delayMs,
    required this.disabled,
    required this.size,
    required this.dragSize,
    required this.onSelect,
    required this.onDropped,
  });

  final ShopCoin coin;
  final int delayMs;
  final bool disabled;
  final double size;
  final double dragSize;
  final VoidCallback onSelect;
  final ValueChanged<String> onDropped;

  @override
  State<_TrayCoinButton> createState() => _TrayCoinButtonState();
}

class _TrayCoinButtonState extends State<_TrayCoinButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  Timer? _enterTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: kFruitPopDurationMs),
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    if (widget.delayMs <= 0) {
      _controller.value = 1;
      return;
    }

    _enterTimer = Timer(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _enterTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget coin = RubleCoin(size: widget.size);

    if (!widget.disabled) {
      coin = Draggable<String>(
        data: widget.coin.id,
        maxSimultaneousDrags: 1,
        feedback: Material(
          color: Colors.transparent,
          child: RubleCoin(size: widget.dragSize),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: RubleCoin(size: widget.size),
        ),
        onDragEnd: (details) {
          if (!details.wasAccepted) {
            widget.onDropped(coinZoneTray);
          }
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onSelect,
            customBorder: const CircleBorder(),
            child: RubleCoin(size: widget.size),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final t = _progress.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: 0.88 + 0.12 * t,
            child: child,
          ),
        );
      },
      child: coin,
    );
  }
}

class _ShopPayButton extends StatefulWidget {
  const _ShopPayButton({
    required this.disabled,
    required this.onPressed,
  });

  final bool disabled;
  final VoidCallback onPressed;

  @override
  State<_ShopPayButton> createState() => _ShopPayButtonState();
}

class _ShopPayButtonState extends State<_ShopPayButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.disabled;
    final background =
        _pressed && enabled ? ParentColors.shellDeep : ParentColors.shell;
    final shadowDy = _pressed && enabled ? 2.0 : 3.0;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.55,
        duration: ParentMotion.tapDuration,
        child: AnimatedContainer(
          duration: ParentMotion.tapDuration,
          curve: ParentMotion.curve,
          constraints: const BoxConstraints(minWidth: 160, minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: ParentColors.shellDeep,
                      offset: Offset(0, shadowDy),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              'Заплатить',
              style: GoogleFonts.fredoka(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.2,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dashLength = 8.0;
      const gapLength = 6.0;
      while (distance < metric.length) {
        final end = distance + dashLength;
        canvas.drawPath(
          metric.extractPath(distance, end.clamp(0, metric.length)),
          paint,
        );
        distance = end + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
