import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:larnes_mobile/app/theme/larnes_theme.dart';

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

  static const _cellHeight = 60.0;
  static const _digitStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1,
    color: LarnesColors.textPrimary,
  );

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

  BoxDecoration _cellBoxDecoration(bool isFocused) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: isFocused ? LarnesColors.indigo : LarnesColors.border,
        width: isFocused ? 1.5 : 1,
      ),
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

  Widget _buildCell(int index) {
    final isFocused = _nodes[index].hasFocus;

    return Expanded(
      child: SizedBox(
        height: _cellHeight,
        child: DecoratedBox(
          decoration: _cellBoxDecoration(isFocused),
          child: Center(
            child: TextField(
              controller: _cells[index],
              focusNode: _nodes[index],
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              style: _digitStyle,
              keyboardType: TextInputType.number,
              maxLength: 1,
              decoration: _hiddenFieldDecoration,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) => _onChanged(index, value),
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
