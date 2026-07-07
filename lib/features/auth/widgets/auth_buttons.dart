import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  static const _minHeight = 52.0;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
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
        height: _minHeight,
        width: double.infinity,
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
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

    return ParentScaleTap(onTap: onPressed!, child: child);
  }
}

class AuthTextLink extends StatelessWidget {
  const AuthTextLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.align = Alignment.center,
  });

  final String label;
  final VoidCallback? onPressed;
  final Alignment align;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      textAlign: align == Alignment.center ? TextAlign.center : TextAlign.start,
      style: GoogleFonts.onest(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onPressed != null ? ParentColors.shell : ParentColors.inkMuted,
      ),
    );

    if (onPressed == null) {
      return Align(alignment: align, child: text);
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
