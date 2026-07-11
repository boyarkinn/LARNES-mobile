import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/letter_color/color_letter_actions.dart';
import 'package:larnes_mobile/trainers/reading/letter_color/color_letter_canvas.dart';
import 'package:larnes_mobile/trainers/reading/letter_color/color_palette.dart';
import 'package:larnes_mobile/trainers/reading/letter_color/letter_color_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_case_color/case_color_pad_size.dart';
import 'package:larnes_mobile/trainers/reading/letter_case_color/letter_case_color_model.dart';

/// Web v2: `platform/src/trainers/reading/letter-case-color/case-color-scene.tsx`
class CaseColorScene extends StatefulWidget {
  const CaseColorScene({
    super.key,
    required this.lowerLetter,
    required this.upperLetter,
    this.disabled = false,
    required this.onDone,
  });

  final String lowerLetter;
  final String upperLetter;
  final bool disabled;
  final VoidCallback onDone;

  @override
  State<CaseColorScene> createState() => _CaseColorSceneState();
}

class _CaseColorSceneState extends State<CaseColorScene> {
  final _upperCanvasController = ColorLetterCanvasController();
  final _lowerCanvasController = ColorLetterCanvasController();
  var _selectedColor = drawColors.first;
  var _upperHasInk = false;
  var _lowerHasInk = false;

  bool get _canClear => _upperHasInk || _lowerHasInk;

  void _handleClear() {
    if (widget.disabled) {
      return;
    }

    _upperCanvasController.clear();
    _lowerCanvasController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padSize = caseColorPadSize(
          constraints.maxHeight,
          constraints.maxWidth,
        );
        final gridMaxWidth = caseColorGridMaxWidth(constraints.maxWidth);

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
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: gridMaxWidth),
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: SizedBox(
                            width: padSize,
                            height: padSize,
                            child: ColorLetterCanvas(
                              controller: _upperCanvasController,
                              disabled: widget.disabled,
                              displayLetter: widget.upperLetter,
                              fontSize: caseColorFontSizeLarge,
                              onInkChange: (hasInk) {
                                if (_upperHasInk != hasInk) {
                                  setState(() => _upperHasInk = hasInk);
                                }
                              },
                              selectedColor: _selectedColor,
                              semanticsLabel:
                                  'Разукрась большую букву ${widget.upperLetter}',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Center(
                          child: SizedBox(
                            width: padSize,
                            height: padSize,
                            child: ColorLetterCanvas(
                              controller: _lowerCanvasController,
                              disabled: widget.disabled,
                              displayLetter: widget.lowerLetter,
                              fontSize: caseColorFontSizeSmall,
                              onInkChange: (hasInk) {
                                if (_lowerHasInk != hasInk) {
                                  setState(() => _lowerHasInk = hasInk);
                                }
                              },
                              revealDelayMs: caseColorLowerRevealDelayMs,
                              selectedColor: _selectedColor,
                              semanticsLabel:
                                  'Разукрась маленькую букву ${widget.lowerLetter}',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ColorLetterActionRow(
              clearDisabled: widget.disabled || !_canClear,
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
