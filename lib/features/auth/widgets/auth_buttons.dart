import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/auth/theme/auth_theme.dart';

class AuthPrimaryButton extends StatefulWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.useWebAuthStyle = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool useWebAuthStyle;

  @override
  State<AuthPrimaryButton> createState() => _AuthPrimaryButtonState();
}

class _AuthPrimaryButtonState extends State<AuthPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;

    if (widget.useWebAuthStyle) {
      return GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: AuthMotion.tapDuration,
          curve: AuthMotion.curve,
          width: double.infinity,
          transform: Matrix4.translationValues(0, _pressed ? 1 : 0, 0),
          decoration: BoxDecoration(
            color: enabled ? AuthColors.cobalt : AuthColors.line,
            borderRadius: BorderRadius.circular(AuthRadii.button),
            border: Border.all(
              color: enabled ? AuthColors.cobalt : AuthColors.line,
            ),
            boxShadow: enabled && !_pressed
                ? const [
                    BoxShadow(
                      color: AuthColors.cobaltDeep,
                      offset: Offset(0, 3),
                    ),
                  ]
                : enabled && _pressed
                    ? const [
                        BoxShadow(
                          color: AuthColors.cobaltDeep,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
          ),
          height: AuthMetrics.buttonMinHeight,
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      );
    }

    final child = DecoratedBox(
      decoration: BoxDecoration(
        color: enabled ? ParentColors.shell : ParentColors.line,
        borderRadius: BorderRadius.circular(ParentRadii.card),
        boxShadow: enabled
            ? const [
                BoxShadow(
                  color: ParentColors.shadow,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  widget.label,
                  style: GoogleFonts.onest(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );

    if (!enabled) {
      return Opacity(opacity: 0.72, child: child);
    }

    return ParentScaleTap(onTap: widget.onPressed!, child: child);
  }
}

class AuthTextLink extends StatelessWidget {
  const AuthTextLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.align = Alignment.center,
    this.useWebAuthStyle = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Alignment align;
  final bool useWebAuthStyle;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      textAlign: align == Alignment.center ? TextAlign.center : TextAlign.start,
      style: useWebAuthStyle
          ? GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: onPressed != null ? AuthColors.cobaltDeep : AuthColors.muted,
            )
          : GoogleFonts.onest(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: onPressed != null ? ParentColors.shell : ParentColors.inkMuted,
            ),
    );

    if (onPressed == null) {
      return Align(alignment: align, child: text);
    }

    if (useWebAuthStyle) {
      return Align(
        alignment: align,
        child: GestureDetector(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: text,
          ),
        ),
      );
    }

    return Align(
      alignment: align,
      child: ParentScaleTap(
        onTap: onPressed!,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: text,
        ),
      ),
    );
  }
}

class AuthSecondaryButton extends StatefulWidget {
  const AuthSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<AuthSecondaryButton> createState() => _AuthSecondaryButtonState();
}

class _AuthSecondaryButtonState extends State<AuthSecondaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: AuthMotion.tapDuration,
        curve: AuthMotion.curve,
        child: AnimatedContainer(
          duration: AuthMotion.tapDuration,
          curve: AuthMotion.curve,
          width: double.infinity,
          height: AuthMetrics.buttonMinHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AuthColors.surfaceStrong,
            borderRadius: BorderRadius.circular(AuthRadii.button),
            border: Border.all(color: const Color.fromRGBO(26, 29, 46, 0.17)),
          ),
          child: widget.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: enabled ? AuthColors.ink : AuthColors.muted,
                  ),
                ),
        ),
      ),
    );
  }
}

class AuthSegmentToggle<T extends Object> extends StatelessWidget {
  const AuthSegmentToggle({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<AuthSegmentOption<T>> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < options.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: _AuthSegmentOptionTile(
              label: options[index].label,
              selected: options[index].value == value,
              onTap: () => onChanged(options[index].value),
            ),
          ),
        ],
      ],
    );
  }
}

class AuthSegmentOption<T extends Object> {
  const AuthSegmentOption({required this.value, required this.label});

  final T value;
  final String label;
}

class _AuthSegmentOptionTile extends StatelessWidget {
  const _AuthSegmentOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ParentScaleTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: ParentMotion.duration,
        curve: ParentMotion.curve,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? ParentColors.shellSoft : ParentColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? ParentColors.shell : ParentColors.line,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.onest(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? ParentColors.shellDeep : ParentColors.inkMuted,
          ),
        ),
      ),
    );
  }
}
