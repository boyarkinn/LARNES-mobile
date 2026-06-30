import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/number_composition/number_composition_model.dart';
import 'package:larnes_mobile/trainers/shared/dot_group.dart';

class EquationScene extends StatelessWidget {
  const EquationScene({
    super.key,
    required this.equation,
    required this.mode,
  });

  final CompositionEquation equation;
  final CompositionPhase mode;

  @override
  Widget build(BuildContext context) {
    final showFullEquation = mode == 'demo-digits' || mode == 'demo-dots';
    final showDigits = mode == 'demo-digits' || mode == 'practice-digits';

    if (showDigits) {
      return Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          _EquationPart(
            key: ValueKey('$mode-known-${equation.knownPart}'),
            delayMs: 0,
            child: Text(
              '${equation.knownPart}',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4F46E5),
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (showFullEquation) ...[
            const _OperatorText('+'),
            _EquationPart(
              key: ValueKey('$mode-missing-${equation.missingPart}'),
              delayMs: 150,
              child: Text(
                '${equation.missingPart}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4F46E5),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const _OperatorText('='),
            _EquationPart(
              key: ValueKey('$mode-whole-${equation.whole}'),
              delayMs: 300,
              child: Text(
                '${equation.whole}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF059669),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        _EquationPart(
          key: ValueKey('$mode-known-dots-${equation.knownPart}'),
          delayMs: 0,
          child: DotGroup(
            count: equation.knownPart,
            size: DotGroupSize.lg,
            tone: DotGroupTone.indigo,
          ),
        ),
        if (showFullEquation) ...[
          const _OperatorText('+'),
          _EquationPart(
            key: ValueKey('$mode-missing-dots-${equation.missingPart}'),
            delayMs: 150,
            child: DotGroup(
              count: equation.missingPart,
              size: DotGroupSize.lg,
              tone: DotGroupTone.indigo,
            ),
          ),
          const _OperatorText('='),
          _EquationPart(
            key: ValueKey('$mode-whole-dots-${equation.whole}'),
            delayMs: 300,
            child: DotGroup(
              count: equation.whole,
              size: DotGroupSize.lg,
              tone: DotGroupTone.indigo,
            ),
          ),
        ],
      ],
    );
  }
}

class _OperatorText extends StatelessWidget {
  const _OperatorText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: Color(0xFF94A3B8),
      ),
    );
  }
}

class _EquationPart extends StatefulWidget {
  const _EquationPart({
    super.key,
    required this.delayMs,
    required this.child,
  });

  final int delayMs;
  final Widget child;

  @override
  State<_EquationPart> createState() => _EquationPartState();
}

class _EquationPartState extends State<_EquationPart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
