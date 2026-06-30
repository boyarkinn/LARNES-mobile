import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/shared/dot_group.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';

class TripleScene extends StatefulWidget {
  const TripleScene({
    super.key,
    required this.totalRods,
    required this.value,
  });

  final int totalRods;
  final int value;

  @override
  State<TripleScene> createState() => _TripleSceneState();
}

class _TripleSceneState extends State<TripleScene>
    with SingleTickerProviderStateMixin {
  static const _stagger = Duration(milliseconds: 450);
  static const _itemDuration = Duration(milliseconds: 400);

  late final AnimationController _controller;
  late List<RodState> _abacusRods;
  Timer? _abacusTimer;

  @override
  void initState() {
    super.initState();
    _abacusRods = emptyRods(widget.totalRods);
    _controller = AnimationController(
      vsync: this,
      duration: _stagger * 4 + _itemDuration,
    )..forward();
    _scheduleAbacusReveal();
  }

  @override
  void didUpdateWidget(TripleScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value &&
        oldWidget.totalRods == widget.totalRods) {
      return;
    }

    _abacusTimer?.cancel();
    setState(() => _abacusRods = emptyRods(widget.totalRods));
    _controller
      ..reset()
      ..forward();
    _scheduleAbacusReveal();
  }

  void _scheduleAbacusReveal() {
    _abacusTimer = Timer(_stagger * 4, () {
      if (!mounted) {
        return;
      }
      setState(
        () => _abacusRods = numberToAbacus(widget.value, widget.totalRods),
      );
    });
  }

  @override
  void dispose() {
    _abacusTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  double _itemProgress(int index) {
    final start = index * _stagger.inMilliseconds / _controller.duration!.inMilliseconds;
    final end = start + _itemDuration.inMilliseconds / _controller.duration!.inMilliseconds;
    final t = ((_controller.value - start) / (end - start)).clamp(0.0, 1.0);
    return Curves.easeOutBack.transform(t).clamp(0.0, 1.0);
  }

  Widget _staggeredItem(int index, Widget child) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = _itemProgress(index);
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - progress)),
            child: Transform.scale(
              scale: 0.92 + 0.08 * progress,
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 16,
      children: [
        _staggeredItem(0, DotGroup(count: widget.value)),
        _staggeredItem(
          1,
          const Text(
            '=',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFB923C),
            ),
          ),
        ),
        _staggeredItem(
          2,
          Container(
            constraints: const BoxConstraints(minWidth: 64),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFED7AA), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              '${widget.value}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: Color(0xFFEA580C),
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        _staggeredItem(
          3,
          const Text(
            '=',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFB923C),
            ),
          ),
        ),
        _staggeredItem(
          4,
          Container(
            constraints: const BoxConstraints(minHeight: 140, minWidth: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF7ED), Colors.white],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFEDD5)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: AbacusWidget(
              rods: _abacusRods,
              totalRods: widget.totalRods,
            ),
          ),
        ),
      ],
    );
  }
}
