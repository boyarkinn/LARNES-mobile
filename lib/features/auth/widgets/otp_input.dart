import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';

class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.controller,
    this.length = 6,
  });

  final TextEditingController controller;
  final int length;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final List<FocusNode> _nodes;
  late final List<TextEditingController> _cells;

  static const _cellHeight = 56.0;
  static const _cellRadius = 10.0;

  @override
  void initState() {
    super.initState();
    _nodes = List.generate(widget.length, (index) {
      final node = FocusNode();
      node.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
      return node;
    });
    _cells = List.generate(widget.length, (_) => TextEditingController());
    _syncFromParent(widget.controller.text);
    widget.controller.addListener(_onParentChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onParentChanged);
    for (final node in _nodes) {
      node.dispose();
    }
    for (final cell in _cells) {
      cell.dispose();
    }
    super.dispose();
  }

  void _onParentChanged() => _syncFromParent(widget.controller.text);

  void _syncFromParent(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '').split('');
    for (var i = 0; i < widget.length; i++) {
      final digit = i < digits.length ? digits[i] : '';
      if (_cells[i].text != digit) {
        _cells[i].text = digit;
      }
    }
  }

  void _emit() {
    final code = _cells.map((c) => c.text).join();
    if (widget.controller.text != code) {
      widget.controller.text = code;
    }
  }

  void _onChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      _cells[index].text = '';
      _emit();
      return;
    }
    _cells[index].text = digits.substring(digits.length - 1);
    if (index < widget.length - 1) {
      _nodes[index + 1].requestFocus();
    }
    _emit();
  }

  void _backspaceFrom(int index) {
    if (index <= 0) {
      return;
    }
    _cells[index - 1].text = '';
    _nodes[index - 1].requestFocus();
    _emit();
  }

  KeyEventResult _onCellKeyEvent(int index, KeyEvent event) {
    if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }

    if (_cells[index].text.isEmpty && index > 0) {
      _backspaceFrom(index);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  BoxDecoration _cellBoxDecoration(bool isFocused) {
    return BoxDecoration(
      color: ParentColors.surface,
      borderRadius: BorderRadius.circular(_cellRadius),
      border: Border.all(
        color: isFocused ? ParentColors.shell : ParentColors.line,
        width: isFocused ? 1.5 : 1,
      ),
      boxShadow: isFocused
          ? const [
              BoxShadow(
                color: ParentColors.focusRing,
                blurRadius: 0,
                spreadRadius: 3,
              ),
            ]
          : null,
    );
  }

  static const _hiddenFieldDecoration = InputDecoration(
    counterText: '',
    isCollapsed: true,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    contentPadding: EdgeInsets.zero,
  );

  TextStyle get _digitStyle => GoogleFonts.onest(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1,
        color: ParentColors.ink,
      );

  Widget _buildCell(int index) {
    final isFocused = _nodes[index].hasFocus;

    return Expanded(
      child: SizedBox(
        height: _cellHeight,
        child: DecoratedBox(
          decoration: _cellBoxDecoration(isFocused),
          child: Center(
            child: Focus(
              onKeyEvent: (node, event) => _onCellKeyEvent(index, event),
              child: TextField(
              controller: _cells[index],
              focusNode: _nodes[index],
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              style: _digitStyle,
              keyboardType: TextInputType.number,
              maxLength: 1,
              decoration: _hiddenFieldDecoration,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _OtpCellFormatter(onBackspaceWhenEmpty: () => _backspaceFrom(index)),
              ],
                onChanged: (value) => _onChanged(index, value),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < widget.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          _buildCell(index),
        ],
      ],
    );
  }
}

class _OtpCellFormatter extends TextInputFormatter {
  const _OtpCellFormatter({required this.onBackspaceWhenEmpty});

  final VoidCallback onBackspaceWhenEmpty;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (oldValue.text.isEmpty && newValue.text.isEmpty) {
      onBackspaceWhenEmpty();
    }

    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    return TextEditingValue(
      text: digits[digits.length - 1],
      selection: const TextSelection.collapsed(offset: 1),
    );
  }
}
