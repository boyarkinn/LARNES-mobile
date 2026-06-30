import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/shop_pay/ruble_coin.dart';
import 'package:larnes_mobile/trainers/math/shop_pay/shop_item_icon.dart';
import 'package:larnes_mobile/trainers/math/shop_pay/shop_pay_model.dart';

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
  String? _errorMessage;
  var _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _coins = createCoins(widget.coinCount);
  }

  int get _paidAmount => countCoinsInRegister(_coins);

  List<ShopCoin> get _trayCoins =>
      _coins.where((coin) => coin.zone == coinZoneTray).toList();

  List<ShopCoin> get _registerCoins =>
      _coins.where((coin) => coin.zone == coinZoneRegister).toList();

  void _moveCoin(String coinId, String zone) {
    setState(() {
      _coins = moveCoinToZone(_coins, coinId, zone);
      _errorMessage = null;
    });
  }

  void _toggleCoinZone(ShopCoin coin) {
    if (widget.disabled || _isSuccess) {
      return;
    }

    final nextZone =
        coin.zone == coinZoneTray ? coinZoneRegister : coinZoneTray;
    _moveCoin(coin.id, nextZone);
  }

  void _handlePay() {
    if (widget.disabled || _isSuccess) {
      return;
    }

    final result = validatePayment(widget.price, _paidAmount);

    if (result.ok) {
      setState(() {
        _errorMessage = null;
        _isSuccess = true;
      });
      widget.onPaymentSuccess();
      return;
    }

    setState(() {
      _errorMessage = result.message;
      _coins = resetCoinsToTray(_coins);
    });
  }

  Widget _coinDraggable({
    required ShopCoin coin,
    required double size,
  }) {
    if (widget.disabled || _isSuccess) {
      return RubleCoin(size: size);
    }

    return Draggable<String>(
      data: coin.id,
      feedback: Material(
        color: Colors.transparent,
        child: RubleCoin(size: size + 4),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: RubleCoin(size: size),
      ),
      onDragEnd: (details) {
        if (!details.wasAccepted) {
          _moveCoin(coin.id, coinZoneTray);
        }
      },
      child: RubleCoin(size: size),
    );
  }

  Widget _dropZone({
    required Widget child,
    required String targetZone,
  }) {
    if (widget.disabled || _isSuccess) {
      return child;
    }

    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => _moveCoin(details.data, targetZone),
      builder: (context, candidate, rejected) {
        final highlighted = candidate.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: highlighted
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF818CF8),
                    width: 2,
                  ),
                )
              : null,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = shopItemLabels[widget.item] ?? widget.item;
    final registerBorderColor = _isSuccess
        ? const Color(0xFF86EFAC)
        : _errorMessage != null
            ? const Color(0xFFFECACA)
            : const Color(0xFFC7D2FE);
    final registerBackground = _isSuccess
        ? const Color(0xFFF0FDF4)
        : _errorMessage != null
            ? const Color(0xFFFFF1F2)
            : const Color(0xFFEEF2FF);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFBEB), Colors.white],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A), width: 2),
          ),
          child: Column(
            children: [
              const Text(
                'ВИТРИНА',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: Color(0xFFB45309),
                ),
              ),
              const SizedBox(height: 12),
              ShopItemIcon(item: widget.item, size: 80),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.price} ₽',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4F46E5),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _dropZone(
          targetZone: coinZoneRegister,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 112),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: registerBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: registerBorderColor,
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'КАССА · $_paidAmount ₽',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: Color(0xFF4338CA),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: _registerCoins.isEmpty
                      ? [
                          const Text(
                            'Перетащи сюда монетки',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ]
                      : _registerCoins.map((coin) {
                          return GestureDetector(
                            onTap: () => _toggleCoinZone(coin),
                            child: _coinDraggable(
                              coin: coin,
                              size: 48,
                            ),
                          );
                        }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _dropZone(
          targetZone: coinZoneTray,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                const Text(
                  'МОНЕТКИ ПО 1 ₽',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: _trayCoins.map((coin) {
                    return GestureDetector(
                      onTap: () => _toggleCoinZone(coin),
                      child: _coinDraggable(
                        coin: coin,
                        size: 52,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: widget.disabled || _isSuccess || _paidAmount == 0
              ? null
              : _handlePay,
          child: const Text('Заплатить'),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFFE11D48),
            ),
          ),
        ],
        if (_isSuccess) ...[
          const SizedBox(height: 8),
          const Text(
            'Молодец! Правильно!',
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
