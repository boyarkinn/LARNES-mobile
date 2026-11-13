import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_result_scope.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_play_button.dart';
import 'package:larnes_mobile/trainers/shared/shuffled_cycle.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/reading/shared/reading_instruction.dart';
import 'model.dart';

class ReadingWordColumnsTrainer extends StatefulWidget {
  const ReadingWordColumnsTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });
  final Map<String, dynamic> params;
  final VoidCallback? onComplete;
  @override
  State<ReadingWordColumnsTrainer> createState() => _ReadingWordColumnsState();
}

class _ReadingWordColumnsState extends State<ReadingWordColumnsTrainer> {
  List<String> _words = [];
  ShuffledCycle? _sequence;
  String _phase = 'instruction', _instruction = '';
  int _length = 0;
  bool _loaded = false, _loading = false, _saving = false, _failed = false;
  TrainerResultScope? _scope;
  void Function()? _cancel;
  Future<void> _writes = Future.value();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded || _loading) return;
    _scope = TrainerResultScope.maybeOf(context);
    _loading = true;
    final payload = readTrainerRuntimeSnapshot(
      'reading-word-columns',
      widget.params,
    );
    _words = (payload?['words'] as List? ?? []).whereType<String>().toList();
    if (_words.isNotEmpty) {
      _sequence = ShuffledCycle.create(
        _words.length,
        Random().nextInt(0x100000000),
      );
    }
    unawaited(_restore());
  }

  Future<void> _restore() async {
    try {
      final key = _scope?.storageKey;
      final saved = key == null
          ? null
          : (await SharedPreferences.getInstance()).getString(key);
      if (saved != null && mounted) {
        final raw = jsonDecode(saved);
        final sequence = ShuffledCycle.restore(raw['sequence'], _words.length);
        if (sequence != null &&
            [
              'instruction',
              'ready',
              'reading',
              'finished',
            ].contains(raw['phase'])) {
          _sequence = sequence;
          _phase = raw['phase'];
          _failed = _phase == 'finished';
        }
      }
    } catch (_) {
      /* Optional resume cache. */
    }
    if (!mounted) return;
    setState(() => _loaded = true);
    if (_phase == 'instruction') _startInstruction();
  }

  void _persist() {
    final key = _scope?.storageKey;
    if (key == null || _sequence == null) return;
    final value = jsonEncode({
      'phase': _phase,
      'sequence': _sequence!.toJson(),
    });
    _writes = _writes.catchError((Object _) {}).then((_) async {
      await (await SharedPreferences.getInstance()).setString(key, value);
    });
  }

  void _startInstruction() {
    _cancel = startReadingInstruction(
      trainerKey: 'reading-word-columns',
      fallbackText: wordColumnsInstructionText,
      fallbackMs: wordColumnsInstructionMs,
      reduceMotion: MediaQuery.disableAnimationsOf(context),
      isMounted: () => mounted,
      onFrame: (text, length) {
        if (mounted) {
          setState(() {
            _instruction = text;
            _length = length;
          });
        }
      },
      onFinished: () {
        if (mounted) {
          setState(() => _phase = 'ready');
          _persist();
        }
      },
    );
  }

  Future<void> _finish() async {
    if (_saving || _sequence == null) return;
    setState(() {
      _saving = true;
      _failed = false;
      _phase = 'finished';
    });
    _persist();
    try {
      await _writes.catchError((Object _) {});
      if (!mounted) return;
      await _scope?.save(context, {
        'kind': 'word-count',
        'wordsRead': _sequence!.consumed,
      });
      if (mounted) widget.onComplete?.call();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _cancel?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    String label(String ru, String en, String ar) => lang == 'ar'
        ? ar
        : lang == 'en'
        ? en
        : ru;
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    if (_sequence == null) {
      return Center(
        child: Text(
          label(
            'В выбранной подтеме нет русских слов.',
            'There are no Russian words in this subtopic.',
            'لا توجد كلمات روسية في هذا الموضوع الفرعي.',
          ),
        ),
      );
    }
    if (_phase == 'instruction') {
      return TrainerInstructionScene(length: _length, text: _instruction);
    }
    Widget button(String text, VoidCallback callback, {bool danger = false}) =>
        TrainerPlayButton(
          onPressed: callback,
          danger: danger,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(text),
        );
    return LayoutBuilder(
      builder: (context, box) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_phase == 'ready')
                TrainerPlayButton(
                  width: 144,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  onPressed: () {
                    setState(() => _phase = 'reading');
                    _persist();
                  },
                  child: Text(label('Начать', 'Start', 'ابدأ')),
                )
              else if (_phase == 'finished') ...[
                Text(
                  '${_sequence!.consumed}',
                  style: const TextStyle(fontSize: 48),
                ),
                if (_saving) const CircularProgressIndicator(),
                if (_failed) ...[
                  Text(
                    label(
                      'Не удалось сохранить результат.',
                      'Could not save the result.',
                      'تعذّر حفظ النتيجة.',
                    ),
                  ),
                  button(
                    label(
                      'Повторить сохранение',
                      'Retry saving',
                      'أعد محاولة الحفظ',
                    ),
                    () => unawaited(_finish()),
                  ),
                ],
              ] else ...[
                SizedBox(
                  width: box.maxWidth,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _words[_sequence!.order[_sequence!.position]],
                      textDirection: TextDirection.ltr,
                      locale: const Locale('ru'),
                      style: TextStyle(
                        fontSize: (box.maxWidth * 0.09)
                            .clamp(32, 80)
                            .toDouble(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 384),
                    child: Row(
                      children: [
                        Expanded(
                          child: button(
                            label('Завершить', 'Finish', 'إنهاء'),
                            () => unawaited(_finish()),
                            danger: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: button(label('Далее', 'Next', 'التالي'), () {
                            setState(() => _sequence = _sequence!.advance());
                            _persist();
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
