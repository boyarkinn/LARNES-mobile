import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_homework.dart';
import 'package:larnes_mobile/features/parent/widgets/board_image_bridge.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_step_chrome.dart';

const homeworkBoardKey = 'board';

/// Рисунок педагога из снимка задания или null, если снимок не доски.
List<dynamic>? homeworkBoardBase(Map<String, dynamic>? snapshot) {
  if (snapshot == null ||
      snapshot['trainerKey'] != homeworkBoardKey ||
      snapshot['mode'] != 'materialized') {
    return null;
  }
  final payload = snapshot['payload'];
  if (payload is! Map) {
    return null;
  }
  final elements = payload['elements'];
  return elements is List ? elements : null;
}

enum _BoardSave { idle, saving, saved, failed, closed }

/// Шаг ДЗ «Доска»: общий файл доски в WebView, рисунок педагога закреплён.
class HomeworkBoardStep extends StatefulWidget {
  const HomeworkBoardStep({
    super.key,
    required this.childId,
    required this.assignmentId,
    required this.step,
    required this.chrome,
  });

  final String childId;
  final String assignmentId;
  final ParentHomeworkPlayStep step;

  /// `onAdvance` вызывается, только когда рисунок сохранён.
  final TrainerStepChrome chrome;

  @override
  State<HomeworkBoardStep> createState() => _HomeworkBoardStepState();
}

class _HomeworkBoardStepState extends State<HomeworkBoardStep> {
  static const _chunk = 240000;

  InAppWebViewController? _web;
  String? _html;
  bool _installing = false;
  bool _mounted = false;
  bool _failed = false;
  _BoardSave _save = _BoardSave.idle;
  late String _savedJson = jsonEncode(widget.step.boardWork ?? const []);
  Future<_BoardSave>? _running;
  List<dynamic>? _pending;

  @override
  void initState() {
    super.initState();
    if (homeworkBoardBase(widget.step.runtimeSnapshot) == null) {
      _failed = true;
      return;
    }
    rootBundle.loadString('assets/call/homework_board.html').then((html) {
      if (mounted) setState(() => _html = html);
    });
  }

  Future<void> _send(String function, String source) async {
    final web = _web;
    if (web == null) return;
    var start = 0;
    while (start < source.length) {
      if (!mounted || _web != web) return;
      var end = start + _chunk < source.length ? start + _chunk : source.length;
      if (end < source.length &&
          source.codeUnitAt(end - 1) >= 0xD800 &&
          source.codeUnitAt(end - 1) <= 0xDBFF) {
        end -= 1;
      }
      final last = end == source.length;
      await web.evaluateJavascript(
        source: '$function(${jsonEncode(source.substring(start, end))},$last)',
      );
      start = end;
    }
  }

  Future<void> _install() async {
    if (_installing) return;
    _installing = true;
    try {
      await _send(
        'installBoard',
        await rootBundle.loadString('assets/call/larnes-board.js'),
      );
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _mountScene() async {
    final locale = LocaleScope.read(context).localeCode;
    final scene = jsonEncode({
      'base': homeworkBoardBase(widget.step.runtimeSnapshot) ?? const [],
      'imageBase': boardImageBase(),
      'locale': locale,
      'work': widget.step.boardWork ?? const [],
    });
    try {
      await _send('appendScene', scene);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  dynamic _onBridge(List<dynamic> args) {
    final message = args.isNotEmpty && args.first is Map ? args.first as Map : null;
    switch (message?['kind']) {
      case 'installed':
        unawaited(_mountScene());
      case 'mounted':
        if (mounted) setState(() => _mounted = true);
      case 'failed':
        if (mounted) setState(() => _failed = true);
      case 'work':
        final work = message?['detail'];
        if (work is List) unawaited(_store(work));
    }
    return null;
  }

  /// One write at a time; a newer drawing replaces a waiting one.
  Future<_BoardSave> _store(List<dynamic> work) async {
    _pending = work;
    while (_running != null) {
      await _running;
    }
    final next = _pending;
    _pending = null;
    if (next == null) return _save;
    final json = jsonEncode(next);
    if (json == _savedJson) return _BoardSave.saved;
    final run = _write(next, json);
    _running = run;
    try {
      return await run;
    } finally {
      _running = null;
    }
  }

  Future<_BoardSave> _write(List<dynamic> work, String json) async {
    if (mounted) setState(() => _save = _BoardSave.saving);
    var result = _BoardSave.saved;
    try {
      await AuthScope.of(context).parentApi.saveHomeworkBoardWork(
            childId: widget.childId,
            assignmentId: widget.assignmentId,
            itemId: widget.step.id,
            elements: work,
            locale: LocaleScope.read(context).localeCode,
          );
      _savedJson = json;
    } on ParentApiException catch (error) {
      result = error.code == 'closed' ? _BoardSave.closed : _BoardSave.failed;
    } catch (_) {
      result = _BoardSave.failed;
    }
    if (mounted) setState(() => _save = result);
    return result;
  }

  Future<void> _advance() async {
    var result = _BoardSave.saved;
    final web = _web;
    if (_mounted && web != null) {
      try {
        final raw = await web.evaluateJavascript(source: 'currentWork()');
        final work = raw is String ? jsonDecode(raw) : null;
        if (work is List) result = await _store(work);
      } catch (_) {
        result = _BoardSave.failed;
        if (mounted) setState(() => _save = result);
      }
    }
    // A closed homework still advances: the server then explains why it is closed.
    if (mounted && result != _BoardSave.failed) widget.chrome.onAdvance?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chrome = widget.chrome;
    final error = _failed
        ? l10n.homeworkBoardUnavailable
        : _save == _BoardSave.failed
            ? l10n.homeworkBoardSaveFailed
            : _save == _BoardSave.closed
                ? l10n.homeworkBoardClosed
                : chrome.errorMessage;
    final html = _html;

    // White sheet edge to edge; the shell's progress and menu lie on top, as on other trainers.
    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
              child: _failed
                  ? const SizedBox.expand()
                  : html == null
                      ? const Center(child: CircularProgressIndicator())
                      : Stack(
                          children: [
                            InAppWebView(
                              initialData: InAppWebViewInitialData(
                                data: html,
                                baseUrl: WebUri('https://larnes.app/'),
                              ),
                              initialSettings: InAppWebViewSettings(
                                javaScriptEnabled: true,
                                supportZoom: false,
                                transparentBackground: false,
                              ),
                              onWebViewCreated: (controller) {
                                _web = controller;
                                controller.addJavaScriptHandler(
                                  handlerName: 'homeworkBoard',
                                  callback: _onBridge,
                                );
                                controller.addJavaScriptHandler(
                                  handlerName: 'boardImage',
                                  callback: (args) => uploadBoardImageFromPage(
                                    AuthScope.of(context).parentApi,
                                    args,
                                  ),
                                );
                              },
                              onLoadStop: (controller, url) => _install(),
                            ),
                            if (!_mounted)
                              const ColoredBox(
                                color: Colors.white,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
                        ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: TrainerStepChromeBar(
              chrome: TrainerStepChrome(
                errorMessage: error,
                finishLabel: chrome.finishLabel,
                isInteractive: false,
                isLast: chrome.isLast,
                isPending: chrome.isPending || _save == _BoardSave.saving,
                nextLabel: chrome.nextLabel,
                onAdvance: chrome.isPending || _save == _BoardSave.saving
                    ? null
                    : () => unawaited(_advance()),
                theme: chrome.theme,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
