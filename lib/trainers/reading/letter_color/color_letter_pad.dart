import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/letter_color/color_letter_actions.dart';
import 'package:larnes_mobile/trainers/reading/letter_color/color_letter_canvas.dart';
import 'package:larnes_mobile/trainers/reading/letter_color/color_pad_size.dart';
import 'package:larnes_mobile/trainers/reading/letter_color/color_palette.dart';
import 'package:larnes_mobile/trainers/reading/letter_color/letter_color_model.dart';

/// Web v2: `platform/src/trainers/reading/letter-color/color-letter-pad.tsx`
class ColorLetterPad extends StatefulWidget {
  const ColorLetterPad({
    super.key,
    required this.displayLetter,
    this.disabled = false,
    required this.onDone,
  });

  final String displayLetter;
  final bool disabled;
  final VoidCallback onDone;

  @override
  State<ColorLetterPad> createState() => _ColorLetterPadState();
}

class _ColorLetterPadState extends State<ColorLetterPad> {
  final _canvasController = ColorLetterCanvasController();
  var _selectedColor = drawColors.first;
  var _hasInk = false;

  void _handleClear() {
    if (widget.disabled) {
      return;
    }

    _canvasController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padSize = colorPadSize(constraints.maxHeight, constraints.maxWidth);

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ColorPalette(
              disabled: widget.disabled,
              onSelect: (color) => setState(() => _selectedColor = color),
              selectedColor: _selectedColor,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: Center(
                child: SizedBox(
                  width: padSize,
                  height: padSize,
                  child: ColorLetterCanvas(
                    controller: _canvasController,
                    disabled: widget.disabled,
                    displayLetter: widget.displayLetter,
                    fontSize: colorLetterFontSize,
                    onInkChange: (hasInk) {
                      if (_hasInk != hasInk) {
                        setState(() => _hasInk = hasInk);
                      }
                    },
                    selectedColor: _selectedColor,
                    semanticsLabel: 'Разукрась букву ${widget.displayLetter}',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ColorLetterActionRow(
              clearDisabled: widget.disabled || !_hasInk,
              doneDisabled: widget.disabled,
              onClear: _handleClear,
              onDone: widget.onDone,
            ),
          ],
        );
      },
    );
  }
}
