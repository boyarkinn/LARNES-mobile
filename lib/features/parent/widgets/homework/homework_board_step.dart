import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:larnes_mobile/core/api/native_homework_api.dart';
import 'package:path_provider/path_provider.dart';
import 'native_homework_outbox.dart';
import 'native_homework_writer.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_homework.dart';
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
  NativeHomeworkWriter? _writer;
  Map<String, dynamic>? _native;
  List<dynamic>? _restoredWork;
  bool _booted = false;
  NativeHomeworkTarget get _target =>
      NativeHomeworkTarget(widget.childId, widget.assignmentId, widget.step.id);
  NativeHomeworkApi get _api => AuthScope.of(context).parentApi.nativeHomework;

  @override
  void initState() {
    super.initState();
    if (homeworkBoardBase(widget.step.runtimeSnapshot) == null) {
      _failed = true;
      return;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_booted && !_failed) {
      _booted = true;
      unawaited(_boot());
    }
  }

  Future<void> _boot() async {
    try {
      final api = _api, target = _target, state = await api.open(target);
      if (!mounted) return;
      final outbox =
          NativeHomeworkOutbox(await getApplicationSupportDirectory(), [
            state['actorUserId'] as String,
            widget.childId,
            widget.assignmentId,
            widget.step.id,
          ]);
      final writer = NativeHomeworkWriter(
        outbox: outbox,
        retryable: (error) =>
            error is! NativeHomeworkError ||
            ![
              'conflict',
              'operation_conflict',
              'forbidden',
              'closed',
              'invalid',
              'size',
            ].contains(error.code),
        generation: state['generation'] as int,
        versionId: state['versionId'] as String?,
        cloudVersionId: state['cloudVersionId'] as String?,
        save: (command) => api.save(
          target,
          command,
          actorUserId: state['actorUserId'] as String,
          sessionVersion: state['sessionVersion'] as int,
        ),
        waitCloud: (id) => api.waitCloud(target, id),
        changed: (saving, error) {
          if (mounted) {
            setState(
              () => _save = saving
                  ? _BoardSave.saving
                  : error == null
                  ? _BoardSave.saved
                  : error is NativeHomeworkError && error.code == 'closed'
                  ? _BoardSave.closed
                  : _BoardSave.failed,
            );
          }
        },
      );
      _writer = writer;
      _native = state;
      await writer.restore();
      _restoredWork = writer.recoveredWork;
      _savedJson = jsonEncode(_restoredWork ?? _nativeWork());
      final html = await rootBundle.loadString(
        'assets/call/homework_board.html',
      );
      if (mounted) {
        setState(() => _html = html);
      } else {
        writer.dispose();
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _writer?.dispose();
    super.dispose();
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

  List<dynamic> _nativeWork() {
    final document = _native?['document'] as Map?;
    return [
      ...?((document?['scene'] as Map?)?['elements'] as List?),
      ...?(document?['tombstones'] as List?),
    ];
  }

  Future<void> _mountScene() async {
    final locale = LocaleScope.read(context).localeCode;
    final scene = jsonEncode({
      'base': (_native?['document'] as Map?)?['base']?['elements'] ?? const [],
      'canEdit': _native?['canEdit'] == true,
      'protocol': 2,
      'locale': locale,
      'work': _restoredWork ?? _nativeWork(),
    });
    try {
      await _send('appendScene', scene);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  dynamic _onBridge(List<dynamic> args) {
    final message = args.isNotEmpty && args.first is Map
        ? args.first as Map
        : null;
    switch (message?['kind']) {
      case 'installed':
        unawaited(_mountScene());
      case 'mounted':
        if (mounted) setState(() => _mounted = true);
      case 'failed':
        if (mounted) setState(() => _failed = true);
      case 'work':
        final work = message?['detail'];
        if (work is List && _native?['canEdit'] == true) {
          unawaited(_store(work));
        }
    }
    return null;
  }

  Future<_BoardSave> _store(List<dynamic> work) async {
    final json = jsonEncode(work);
    if (json == _savedJson || _native?['canEdit'] != true) return _save;
    try {
      await _writer!.enqueue(work);
      _savedJson = json;
      return _BoardSave.saving;
    } catch (_) {
      if (mounted) setState(() => _save = _BoardSave.failed);
      return _BoardSave.failed;
    }
  }

  Future<Map<String, String>> _uploadImage(List<dynamic> args) async {
    try {
      final input = args.first as Map;
      final id = await _api.upload(
        _target,
        base64Decode(input['data'] as String),
        input['mimeType'] as String,
        actorUserId: _native!['actorUserId'] as String,
        sessionVersion: _native!['sessionVersion'] as int,
      );
      return {'fileId': id};
    } catch (_) {
      return {'code': 'failed'};
    }
  }

  Future<Map<String, String>> _readImage(List<dynamic> args) async {
    try {
      return {
        'dataURL': await _api.image(
          _target,
          (args.first as Map)['imageId'] as String,
        ),
      };
    } catch (_) {
      return {'code': 'failed'};
    }
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
    if (result != _BoardSave.closed &&
        _native?['canEdit'] == true &&
        !await _writer!.flush()) {
      result = _BoardSave.failed;
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
                              callback: _uploadImage,
                            );
                            controller.addJavaScriptHandler(
                              handlerName: 'homeworkImage',
                              callback: _readImage,
                            );
                          },
                          onLoadStop: (controller, url) => _install(),
                        ),
                        if (!_mounted)
                          const ColoredBox(
                            color: Colors.white,
                            child: Center(child: CircularProgressIndicator()),
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
