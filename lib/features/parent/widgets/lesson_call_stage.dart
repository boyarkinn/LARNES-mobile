import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/kiosk_api.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/lesson_call_pass.dart';
import 'package:larnes_mobile/features/parent/widgets/lesson_call_dock.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
import 'package:larnes_mobile/trainers/board/lesson_board_canvas.dart';
import 'package:larnes_mobile/trainers/board/lesson_board_scene.dart';
import 'package:permission_handler/permission_handler.dart';

enum _LessonCallLink { none, reconnecting, lost, closed, failed }

class LessonCallStageHandle {
  Future<void> Function()? _end;

  void attach(Future<void> Function() end) {
    _end = end;
  }

  void detach(Future<void> Function() end) {
    if (_end == end) {
      _end = null;
    }
  }

  Future<void> end() {
    final end = _end;
    if (end == null) {
      return Future<void>.value();
    }
    return end();
  }
}

class LessonCallStage extends StatefulWidget {
  const LessonCallStage({
    super.key,
    required this.body,
    required this.childId,
    required this.onLeave,
    required this.trainerOpen,
    this.inviteToken,
    this.fetchPass,
    this.claimRoster,
    this.handle,
    this.captureOnJoin = true,
  });

  final Widget? body;
  final String childId;
  final VoidCallback onLeave;
  final bool trainerOpen;
  final String? inviteToken;
  final LessonCallStageHandle? handle;
  final bool captureOnJoin;
  final Future<LessonCallPass?> Function(String locale)? fetchPass;
  final Future<LessonCallTeachers> Function({
    required String endpointId,
    required String locale,
  })? claimRoster;

  @override
  State<LessonCallStage> createState() => _LessonCallStageState();
}

class _LessonCallStageState extends State<LessonCallStage> {
  InAppWebViewController? _web;
  LessonCallPass? _pass;
  String? _html;
  bool _loading = true;
  bool _joined = false;
  bool _inRoom = false;
  bool _cameraOn = false;
  bool _micOn = false;
  bool _hearBlocked = false;
  bool _starting = false;
  bool _awaitingPage = false;
  bool _claiming = false;
  bool _renewing = false;
  int _callGen = 0;
  int _cameraSeq = 0;
  int _micSeq = 0;
  String? _cameraNote;
  String? _micNote;
  String? _endpointId;
  Timer? _roster;
  Timer? _chromeTimer;
  bool _chromeOpen = false;
  String _mode = 'grid';
  String _boardDraw = 'teacher';
  int _boardSentAt = 0;
  List<Map<String, dynamic>> _elements = const [];
  bool _eraser = false;
  Color _ink = const Color(0xFF1E1E1E);
  String _inkHex = '#1e1e1e';
  Timer? _boardSend;
  Completer<void>? _left;
  Future<void>? _ending;
  bool _ended = false;
  _LessonCallLink _link = _LessonCallLink.none;

  @override
  void initState() {
    super.initState();
    widget.handle?.attach(endCall);
    _load();
  }

  Future<void> _load() async {
    final html = await rootBundle.loadString('assets/call/lesson_call_stage.html');
    if (!mounted) {
      return;
    }

    _html = html;
    await _openPass();
  }

  Future<LessonCallPass?> _fetchPass() async {
    final locale = LocaleScope.read(context).localeCode;
    final injected = widget.fetchPass;
    if (injected != null) {
      return injected(locale);
    }
    final invite = widget.inviteToken;
    if (invite == null) {
      return AuthScope.of(context).parentApi.fetchLessonCallPass(
        childId: widget.childId,
        locale: locale,
      );
    }
    return AuthScope.of(context).lessonInviteGuestApi.fetchLessonCallPass(
      token: invite,
      locale: locale,
    );
  }

  Future<void> _openPass() async {
    try {
      final pass = await _fetchPass();
      if (!mounted) {
        return;
      }
      setState(() {
        _pass = pass;
        _loading = false;
        _link = pass == null ? _LessonCallLink.failed : _LessonCallLink.none;
      });
      _tryStart();
    } on ParentApiException catch (error) {
      _failOpen(error.code);
    } on KioskApiException catch (error) {
      _failOpen(error.code);
    }
  }

  void _failOpen(String? code) {
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
      _link = code == 'inactive' ? _LessonCallLink.closed : _LessonCallLink.failed;
    });
  }

  Future<void> _renewPass() async {
    if (_renewing || _link == _LessonCallLink.closed) {
      return;
    }
    _renewing = true;
    var callGen = _callGen;
    try {
      setState(() {
        _retireCall();
        _link = _LessonCallLink.reconnecting;
      });
      callGen = _callGen;
      await _stopSession();
      if (!_renewStill(callGen)) {
        return;
      }
      final pass = await _fetchPass();
      if (!_renewStill(callGen)) {
        return;
      }
      if (pass == null) {
        setState(() => _link = _LessonCallLink.failed);
        await _web?.evaluateJavascript(source: 'renewFailed("failed")');
        return;
      }
      setState(() => _pass = pass);
      if (!_renewStill(callGen)) {
        return;
      }
      final web = _web;
      if (web == null || _html == null || !_starting) {
        _tryStart();
        return;
      }
      await web.evaluateJavascript(source: 'acceptPass(${jsonEncode(pass.toStageJson())})');
    } on ParentApiException catch (error) {
      await _failRenew(error.code, callGen);
    } on KioskApiException catch (error) {
      await _failRenew(error.code, callGen);
    } finally {
      _renewing = false;
    }
  }

  Future<void> _failRenew(String? code, int callGen) async {
    if (!_renewStill(callGen)) {
      return;
    }
    final closed = code == 'inactive';
    setState(() => _link = closed ? _LessonCallLink.closed : _LessonCallLink.failed);
    await _web?.evaluateJavascript(source: 'renewFailed(${jsonEncode(closed ? "inactive" : "failed")})');
  }

  void _stopRoster(String? code) {
    if (code == 'inactive' || code == 'forbidden') {
      _roster?.cancel();
      _roster = null;
    }
    if (code == 'inactive' && mounted) {
      setState(() {
        _retireCall();
        _link = _LessonCallLink.closed;
      });
      unawaited(_stopSession());
    }
  }

  bool _renewStill(int callGen) {
    return mounted && callGen == _callGen && _link != _LessonCallLink.closed;
  }

  void _tryStart() {
    final web = _web;
    final pass = _pass;
    final html = _html;
    if (web == null || pass == null || html == null || _starting) {
      return;
    }

    _starting = true;
    _awaitingPage = true;
    web.loadData(
      data: html,
      mimeType: 'text/html',
      encoding: 'utf-8',
      baseUrl: WebUri('https://${pass.domain}/'),
    );
  }

  Future<void> _join() async {
    final web = _web;
    final pass = _pass;
    if (web == null || pass == null || _joined) {
      return;
    }

    _joined = true;
    await _syncPage();
    await web.evaluateJavascript(source: 'join(${jsonEncode(pass.toStageJson())})');
  }

  Future<void> _syncPage() async {
    final web = _web;
    if (web == null || !mounted) {
      return;
    }
    final l10n = context.l10n;
    final labels = jsonEncode({
      'cameraOff': l10n.parentLiveLessonCameraOffCaption,
      'locale': Localizations.localeOf(context).languageCode,
      'online': l10n.parentLiveLessonOnline,
      'you': l10n.parentLiveLessonYou,
    });
    await web.evaluateJavascript(source: 'setLabels($labels)');
    await web.evaluateJavascript(source: 'setBand(${widget.trainerOpen})');
  }

  void _watchRoster(String endpointId) {
    if (endpointId.isEmpty) {
      return;
    }
    _endpointId = endpointId;
    _roster ??= Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_claimRoster());
    });
    unawaited(_claimRoster());
  }

  Future<void> _claimRoster() async {
    final endpointId = _endpointId;
    final web = _web;
    if (endpointId == null || endpointId.isEmpty || web == null || _claiming || !mounted) {
      return;
    }

    _claiming = true;
    final locale = Localizations.localeOf(context).languageCode;
    final claim = widget.claimRoster;
    try {
      final teachers = claim != null
          ? await claim(endpointId: endpointId, locale: locale)
          : widget.inviteToken == null
          ? await AuthScope.of(context).parentApi.claimLessonCallRoster(
              childId: widget.childId,
              endpointId: endpointId,
              locale: locale,
            )
          : await AuthScope.of(context).lessonInviteGuestApi.claimLessonCallRoster(
              token: widget.inviteToken!,
              endpointId: endpointId,
              locale: locale,
            );
      if (!mounted) {
        return;
      }
      await web.evaluateJavascript(
        source: 'setTeachers(${jsonEncode(teachers.ids)}, ${jsonEncode(teachers.primary)})',
      );
    } on ParentApiException catch (error) {
      _stopRoster(error.code);
    } on KioskApiException catch (error) {
      _stopRoster(error.code);
    } finally {
      _claiming = false;
    }
  }

  void _retireCall() {
    _callGen += 1;
    _cameraSeq += 1;
    _micSeq += 1;
    _inRoom = false;
    _cameraOn = false;
    _micOn = false;
  }

  Future<void> _stopSession() async {
    try {
      await _web?.evaluateJavascript(source: 'dropSession()');
    } catch (_) {}
  }

  bool _deviceWishCurrent(bool video, int seq, int callGen) {
    return mounted &&
        seq == (video ? _cameraSeq : _micSeq) &&
        callGen == _callGen &&
        _inRoom &&
        _link != _LessonCallLink.closed;
  }

  Future<void> _setDeviceWish(String device, bool muted) async {
    final video = device == 'video';
    final seq = video ? ++_cameraSeq : ++_micSeq;
    final callGen = _callGen;
    setState(() {
      if (video) {
        _cameraNote = null;
        _cameraOn = !muted;
      } else {
        _micNote = null;
        _micOn = !muted;
      }
    });
    if (!muted) {
      final statuses = await [Permission.camera, Permission.microphone].request();
      if (!_deviceWishCurrent(video, seq, callGen)) {
        return;
      }
      final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
      final micGranted = statuses[Permission.microphone]?.isGranted ?? false;
      await _web?.evaluateJavascript(source: 'allowDevices($cameraGranted, $micGranted)');
      final granted = video ? cameraGranted : micGranted;
      if (!granted) {
        setState(() {
          if (video) {
            _cameraOn = false;
            _cameraNote = 'denied';
          } else {
            _micOn = false;
            _micNote = 'denied';
          }
        });
        if (!_deviceWishCurrent(video, seq, callGen)) {
          return;
        }
        await _web?.evaluateJavascript(source: 'setDevice(${jsonEncode(device)}, true)');
        return;
      }
    }
    if (!_deviceWishCurrent(video, seq, callGen)) {
      return;
    }
    await _web?.evaluateJavascript(source: 'setDevice(${jsonEncode(device)}, $muted)');
  }

  Future<void> _applyTeacherMedia(String device, bool muted) async {
    if ((device != 'video' && device != 'audio') || !_inRoom) {
      return;
    }
    await _setDeviceWish(device, muted);
  }

  Future<void> _toggleCamera() async {
    if (!_inRoom) {
      return;
    }
    await _setDeviceWish('video', _cameraOn);
  }

  Future<void> _toggleMic() async {
    if (!_inRoom) {
      return;
    }
    await _setDeviceWish('audio', _micOn);
  }

  Future<void> _resumeHear() async {
    await _web?.evaluateJavascript(source: 'resumeHear()');
  }

  Future<void> _rejoin() async {
    if (_link == _LessonCallLink.closed) {
      return;
    }
    setState(() => _link = _LessonCallLink.reconnecting);
    await _renewPass();
  }

  Future<void> endCall() {
    return _ending ??= _endCall();
  }

  Future<void> _endCall() async {
    if (_ended) {
      return;
    }
    _ended = true;
    final web = _web;
    if (web == null) {
      return;
    }
    final left = Completer<void>();
    _left = left;
    try {
      await web.evaluateJavascript(source: 'leave()');
    } catch (_) {
      if (!left.isCompleted) {
        left.complete();
      }
      return;
    }
    try {
      await left.future.timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  void _onBridge(List<dynamic> args) {
    if (args.isEmpty || args.first is! Map) {
      return;
    }

    final message = Map<String, dynamic>.from(args.first as Map);
    final kind = message['kind'];
    if (kind == 'left') {
      final left = _left;
      if (left != null && !left.isCompleted) {
        left.complete();
      }
    }
    if (!mounted) {
      return;
    }
    final detail = message['detail'];
    final block = detail is String && detail.isNotEmpty ? detail : 'failed';
    var stopSession = false;
    var openDevices = false;
    setState(() {
      switch (kind) {
        case 'joined':
          _inRoom = true;
          _link = _LessonCallLink.none;
          openDevices = widget.captureOnJoin;
        case 'endpoint':
          if (detail is String) {
            _watchRoster(detail);
          }
        case 'teacher-media':
          if (detail is String) {
            final parts = detail.split(':');
            if (parts.length == 2) {
              unawaited(_applyTeacherMedia(parts[0], parts[1] == '1'));
            }
          }
        case 'camera-on':
          _cameraOn = true;
          _cameraNote = null;
        case 'camera-off':
          _cameraOn = false;
        case 'camera-failed':
          _cameraOn = false;
          _cameraNote = block;
        case 'mic-on':
          _micOn = true;
          _micNote = null;
        case 'mic-off':
          _micOn = false;
        case 'mic-failed':
          _micOn = false;
          _micNote = block;
        case 'hear-blocked':
          _hearBlocked = true;
        case 'hear-on':
          _hearBlocked = false;
        case 'renew':
          if (_link != _LessonCallLink.closed) {
            unawaited(_renewPass());
          }
        case 'closed':
          _retireCall();
          _link = _LessonCallLink.closed;
          stopSession = true;
        case 'mode':
          if (detail == 'grid' || detail == 'talk' || detail == 'workflow') {
            _mode = detail;
            if (_mode != 'workflow') {
              _chromeOpen = false;
              _chromeTimer?.cancel();
            }
          }
        case 'board-draw':
          if (detail == 'teacher' || detail == 'all') {
            _boardDraw = detail;
            if (detail != 'all') {
              _boardSend?.cancel();
            }
          }
        case 'board':
          final scene = message['scene'];
          if (scene is Map) {
            final incoming = readBoardElements(scene['elements']);
            if (_drawAll) {
              _elements = mergeBoardElements(_elements, incoming);
            } else {
              final sentAt = scene['sentAt'];
              final at = sentAt is num ? sentAt.toInt() : 0;
              if (at > _boardSentAt) {
                _boardSentAt = at;
                _elements = incoming;
              }
            }
          }
        case 'link':
          if (_link == _LessonCallLink.closed) {
            break;
          }
          if (detail == 'reconnecting') {
            _link = _LessonCallLink.reconnecting;
          } else if (detail == 'lost') {
            _inRoom = false;
            _link = _LessonCallLink.lost;
          } else if (detail == 'room') {
            _link = _LessonCallLink.none;
          }
        case 'lost':
          _inRoom = false;
          _link = _LessonCallLink.lost;
        case 'failed':
          _inRoom = false;
          _link = _LessonCallLink.failed;
      }
    });
    if (stopSession) {
      unawaited(_stopSession());
    }
    if (openDevices) {
      unawaited(_setDeviceWish('video', false));
      unawaited(_setDeviceWish('audio', false));
    }
  }

  @override
  void didUpdateWidget(covariant LessonCallStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.handle != widget.handle) {
      oldWidget.handle?.detach(endCall);
      widget.handle?.attach(endCall);
    }
    if (oldWidget.trainerOpen == widget.trainerOpen) {
      return;
    }
    if (widget.trainerOpen || _mode != 'workflow') {
      _chromeTimer?.cancel();
      _chromeOpen = false;
    }
    unawaited(_syncPage());
  }

  @override
  void dispose() {
    _callGen += 1;
    _cameraSeq += 1;
    _micSeq += 1;
    _roster?.cancel();
    _chromeTimer?.cancel();
    _boardSend?.cancel();
    widget.handle?.detach(endCall);
    if (!_ended) {
      _web?.evaluateJavascript(source: 'leave()');
    }
    super.dispose();
  }

  Widget _callSurface() {
    if (_pass == null) {
      return ColoredBox(
        color: const Color(0xFF111111),
        child: Center(
          child: _loading ? const CircularProgressIndicator() : const SizedBox.shrink(),
        ),
      );
    }

    return InAppWebView(
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        iframeAllow: 'camera; microphone',
      ),
      onWebViewCreated: (controller) {
        _web = controller;
        controller.addJavaScriptHandler(
          handlerName: 'lessonCall',
          callback: _onBridge,
        );
        _tryStart();
      },
      onLoadStop: (controller, url) {
        if (!_awaitingPage || _joined) {
          return;
        }
        _awaitingPage = false;
        _join();
      },
      onPermissionRequest: (controller, request) async {
        final resources = request.resources;
        final capture = {
          PermissionResourceType.CAMERA,
          PermissionResourceType.MICROPHONE,
          PermissionResourceType.CAMERA_AND_MICROPHONE,
        };
        if (resources.isEmpty || resources.any((type) => !capture.contains(type))) {
          return PermissionResponse(
            resources: resources,
            action: PermissionResponseAction.DENY,
          );
        }
        return PermissionResponse(
          resources: resources,
          action: PermissionResponseAction.GRANT,
        );
      },
    );
  }

  bool get _drawAll => _boardDraw == 'all';

  void _rememberElements(List<Map<String, dynamic>> next) {
    setState(() => _elements = next);
    _scheduleBoardSend();
  }

  void _scheduleBoardSend() {
    if (!_drawAll || !_inRoom) {
      return;
    }
    _boardSend?.cancel();
    _boardSend = Timer(const Duration(milliseconds: 300), () {
      final body = jsonEncode(_elements);
      unawaited(_web?.evaluateJavascript(source: 'sendBoard(${jsonEncode(body)})'));
    });
  }

  void _addStroke(List<BoardPoint> points) {
    if (points.isEmpty || !_drawAll) {
      return;
    }
    _rememberElements([..._elements, freedrawElement(points, _inkHex)]);
  }

  void _eraseAt(BoardPoint at, double radius) {
    if (!_drawAll) {
      return;
    }
    final next = eraseBoardElements(_elements, at, radius);
    if (next == null) {
      return;
    }
    _rememberElements(next);
  }

  void _keepChrome() {
    if (_mode != 'workflow' || !_chromeOpen) {
      return;
    }
    _chromeTimer?.cancel();
    _chromeTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _chromeOpen = false);
      }
    });
  }

  void _toggleChrome() {
    if (_hearBlocked) {
      unawaited(_resumeHear());
      return;
    }
    if (_chromeOpen) {
      _chromeTimer?.cancel();
      setState(() => _chromeOpen = false);
      return;
    }
    setState(() => _chromeOpen = true);
    _keepChrome();
  }

  Future<void> _leaveFromDock() async {
    await endCall();
    if (!mounted) {
      return;
    }
    widget.onLeave();
  }

  Widget _dock() {
    return LessonCallDock(
      audioOn: _micOn,
      callReady: _inRoom,
      cameraNote: _cameraNote,
      canRetry: _link != _LessonCallLink.closed,
      closed: _link == _LessonCallLink.closed,
      connectFailed: _link == _LessonCallLink.failed,
      hearBlocked: _hearBlocked,
      lost: _link == _LessonCallLink.lost,
      reconnecting: _link == _LessonCallLink.reconnecting,
      micNote: _micNote,
      videoOn: _cameraOn,
      onHear: () {
        _keepChrome();
        _resumeHear();
      },
      onLeave: () {
        unawaited(_leaveFromDock());
      },
      onRetry: () {
        _keepChrome();
        _rejoin();
      },
      onToggleAudio: () {
        _keepChrome();
        _toggleMic();
      },
      onToggleVideo: () {
        _keepChrome();
        _toggleCamera();
      },
    );
  }

  Widget _boardTools() {
    final l10n = context.l10n;
    const inks = <(Color, String)>[
      (Color(0xFF1E1E1E), '#1e1e1e'),
      (Color(0xFFE03131), '#e03131'),
      (Color(0xFF1971C2), '#1971c2'),
      (Color(0xFF2F9E44), '#2f9e44'),
    ];
    return Material(
      color: ParentColors.surface,
      elevation: 2,
      shadowColor: ParentColors.shadow,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _boardTool(
              selected: !_eraser,
              label: l10n.parentLiveLessonBoardPen,
              icon: Icons.edit,
              onTap: () => setState(() => _eraser = false),
            ),
            _boardTool(
              selected: _eraser,
              label: l10n.parentLiveLessonBoardEraser,
              icon: Icons.auto_fix_off,
              onTap: () => setState(() => _eraser = true),
            ),
            for (final ink in inks)
              _boardColor(
                color: ink.$1,
                selected: !_eraser && _inkHex == ink.$2,
                onTap: () => setState(() {
                  _eraser = false;
                  _ink = ink.$1;
                  _inkHex = ink.$2;
                }),
              ),
          ],
        ),
      ),
    );
  }

  Widget _boardTool({
    required bool selected,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: selected ? ParentColors.shellSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: ParentColors.ink),
          ),
        ),
      ),
    );
  }

  Widget _boardColor({
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: context.l10n.parentLiveLessonBoardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: selected ? ParentColors.shell : ParentColors.line, width: selected ? 2 : 1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _linkButton() {
    final l10n = context.l10n;
    final hear = _hearBlocked;
    final label = hear
        ? l10n.parentLiveLessonHear
        : _chromeOpen
            ? l10n.parentLiveLessonCallHide
            : l10n.parentLiveLessonCallShow;
    return Tooltip(
      message: l10n.parentLiveLessonCall,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: hear ? const Color(0xFFDC2626) : ParentColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: hear ? const Color(0xFFDC2626) : ParentColors.line),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _toggleChrome,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                hear ? Icons.volume_off : Icons.call,
                color: hear ? Colors.white : ParentColors.ink,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trainer = widget.trainerOpen && widget.body != null;
    final board = _mode == 'workflow' && !trainer;
    final handle = board || trainer;

    return Column(
      children: [
        Flexible(
          child: Stack(
            children: [
              Positioned.fill(child: _callSurface()),
              if (board)
                Positioned.fill(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: LessonBoardCanvas(
                          canDraw: _drawAll,
                          color: _ink,
                          elements: _elements,
                          eraser: _eraser,
                          onErase: _eraseAt,
                          onStroke: _addStroke,
                        ),
                      ),
                      if (_drawAll)
                        Positioned(
                          top: 8,
                          left: 8,
                          right: 8,
                          child: _boardTools(),
                        ),
                    ],
                  ),
                ),
              if (trainer) Positioned.fill(child: widget.body!),
              if (handle)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Column(
                    crossAxisAlignment: trainer ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_chromeOpen && !_hearBlocked) _dock(),
                      Padding(
                        padding: EdgeInsets.fromLTRB(12, 0, 12, 8 + MediaQuery.paddingOf(context).bottom),
                        child: _linkButton(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (!handle) _dock(),
      ],
    );
  }
}
