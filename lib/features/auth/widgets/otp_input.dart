import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  @override
  void initState() {
    super.initState();
    _nodes = List.generate(widget.length, (_) => FocusNode());
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

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        return SizedBox(
          width: 44,
          child: TextField(
            controller: _cells[index],
            focusNode: _nodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            decoration: const InputDecoration(counterText: ''),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) => _onChanged(index, value),
          ),
        );
      }),
    );
  }
}
