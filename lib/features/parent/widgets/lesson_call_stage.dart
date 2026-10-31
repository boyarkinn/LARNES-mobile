import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/audio/trainer_error_reporter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/kiosk_api.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/config/app_config.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/lesson_call_pass.dart';
import 'package:larnes_mobile/features/parent/models/lesson_child_board.dart';
import 'package:larnes_mobile/features/parent/models/lesson_device_media.dart';
import 'package:larnes_mobile/features/parent/widgets/lesson_device_media_controller.dart';
import 'package:larnes_mobile/features/parent/widgets/board_image_bridge.dart';
import 'package:larnes_mobile/features/messenger/messenger_panel.dart';
import 'package:larnes_mobile/features/messenger/messenger_api.dart';
import 'package:larnes_mobile/features/messenger/messenger_room.dart';
import 'package:larnes_mobile/features/messenger/messenger_scope.dart';
import 'package:larnes_mobile/features/messenger/message_sound.dart';
import 'package:larnes_mobile/features/parent/widgets/lesson_call_dock.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
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
    this.leaveLesson,
    required this.trainerOpen,
    this.inviteToken,
    this.fetchPass,
    this.fetchBoard,
    this.sendBoard,
    this.requestBoard,
    this.claimRoster,
    this.handle,
    this.captureOnJoin = true,
    this.mediaEnabled = true,
    this.workspaceFormat = 'board',
    this.lessonSessionId,
    this.fetchMedia,
    this.sendMedia,
    this.messenger,
  });

  final Widget? body;
  final String childId;
  final VoidCallback onLeave;
  final Future<bool> Function()? leaveLesson;
  final bool trainerOpen;
  final String? inviteToken;
  final LessonCallStageHandle? handle;
  final bool captureOnJoin;
  final bool mediaEnabled;
  final String workspaceFormat;
  final String? lessonSessionId;
  final Future<LessonDeviceMedia?> Function()? fetchMedia;
  final Future<LessonDeviceMedia?> Function(Map<String, dynamic>)? sendMedia;
  final MessengerScope? messenger;
  final Future<LessonCallPassOutcome> Function(
    String locale, {
    String? assignment,
  })?
  fetchPass;
  final Future<LessonChildBoard?> Function({String? link})? fetchBoard;
  final Future<bool> Function(Map<String, dynamic> body)? sendBoard;
  final Future<Map<String, dynamic>?> Function(Map<String, dynamic> body)?
  requestBoard;
  final Future<LessonCallTeachers> Function({
    required String endpointId,
    required String locale,
    String? assignment,
  })?
  claimRoster;

  @override
  State<LessonCallStage> createState() => _LessonCallStageState();
}

class _LessonCallStageState extends State<LessonCallStage>
    with WidgetsBindingObserver {
  Map<String, Object?> _clientVersion = const {};
  InAppWebViewController? _web;
  LessonCallPass? _pass;
  String? _html;
  bool _loading = true;
  bool _joined = false;
  bool _inRoom = false;
  bool _boardWidgets = false;
  String _boardAudioReady = '';
  bool _cameraOn = false;
  bool _micOn = false;
  bool _cameraLive = false;
  bool _micLive = false;
  bool _hearBlocked = false;
  bool _starting = false;
  bool _awaitingPage = false;
  bool _claiming = false;
  bool _renewing = false;
  int _callGen = 0;
  int _pageGen = 0;
  int _cameraSeq = 0;
  int _micSeq = 0;
  String? _cameraNote;
  String? _micNote;
  String? _endpointId;
  Timer? _roster;
  Timer? _chromeTimer;
  bool _chromeOpen = false;
  String _mode = 'grid';
  Completer<void>? _left;
  Future<void>? _ending;
  bool _ended = false;
  bool _leavingDesk = false;
  bool _leaveFailed = false;
  _LessonCallLink _link = _LessonCallLink.none;
  String _movingDomain = '';
  bool _holding = false;
  Timer? _soundTimer;
  bool _following = false;
  Timer? _boardTimer;
  bool _boardBusy = false;
  int _boardGen = 1;
  String _boardKey = '';
  MessengerRoom? _messenger;
  bool _messengerOpen = false;
  final _workspaceMessengerApi = MessengerApi();
  int _messengerBridgeEpoch = 0;
  String get _messengerBridgeIdentity =>
      '${widget.messenger?.sessionKey ?? ''}:$_messengerBridgeEpoch:$_pageGen';
  LessonChildBoard? _board;
  late final String _boardLink;
  LessonDeviceMediaController? _desk;
  bool _pageReady = false;
  bool _deskStarting = false;
  bool _applyingDesk = false;
  int _deskAttempt = -1;
  String _deskAssignment = '';
  bool get _mediaWanted => _desk?.needed ?? widget.mediaEnabled;

  bool get _boardWorkspace => true;

  /// Урок открыт входом родителя, а не гостевой ссылкой или экраном класса.
  bool get _parentSession =>
      widget.inviteToken == null &&
      widget.fetchPass == null &&
      widget.claimRoster == null;

  @override
  void initState() {
    super.initState();
    unawaited(
      nativeTrainerVersionMetadata().then((version) {
        _clientVersion = version;
      }),
    );
    _boardLink =
        '${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}${identityHashCode(this).toRadixString(16)}';
    widget.handle?.attach(endCall);
    WidgetsBinding.instance.addObserver(this);
    _attachMessenger();
    unawaited(NativeMessageSound.load());
    NativeMessageSound.enabled.addListener(_onMessenger);
    if (widget.fetchMedia != null &&
        widget.sendMedia != null &&
        widget.lessonSessionId != null) {
      _desk = LessonDeviceMediaController(
        childId: widget.childId,
        lessonSessionId: widget.lessonSessionId!,
        fetch: widget.fetchMedia!,
        send: widget.sendMedia!,
      )..addListener(_onDeskMedia);
    }
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _messenger?.resume();
    } else {
      _messenger?.pause();
    }
    if (!_ended) {
      unawaited(_setAppVisibility(state == AppLifecycleState.resumed));
    }
    if (state != AppLifecycleState.resumed || _ended) {
      return;
    }
    unawaited(_followRoom());
    unawaited(_pullBoard());
  }

  Future<void> _setAppVisibility(bool visible) async {
    try {
      await _web?.evaluateJavascript(
        source:
            'if (typeof setLessonAppVisible === "function") setLessonAppVisible($visible)',
      );
    } catch (_) {
      // The WebView may already be gone or still installing the lesson page.
    }
  }

  Future<void> _load() async {
    final html = await rootBundle.loadString(
      'assets/call/lesson_call_stage.html',
    );
    if (!mounted || _ended) {
      return;
    }

    _html = html;
    _desk?.start();
    if (_boardWorkspace) {
      _watchBoard();
      _tryStart();
    }
    if (!widget.mediaEnabled) {
      setState(() => _loading = false);
      if (_boardWorkspace) _watchBoard();
      _tryStart();
      return;
    }
    await _openPass();
  }

  void _onDeskMedia() {
    final desk = _desk;
    if (!mounted || _ended || desk == null) return;
    unawaited(_syncLessonChrome());
    final media = desk.media;
    final changed = media != null && _deskAssignment != media.assignment;
    if (changed) {
      if (widget.messenger != null)
        _workspaceMessengerApi.cancelScope(widget.messenger!);
      _deskAssignment = media.assignment;
      _deskAttempt = -1;
      _messengerBridgeEpoch++;
    }
    if (!_mediaWanted || changed) {
      final hadMedia = _pass != null || _joined || _inRoom || _deskStarting;
      setState(() {
        _retireCall();
        _joined = false;
        _pass = null;
        _holding = false;
        _link = desk.failed || media?.error != null
            ? _LessonCallLink.failed
            : _LessonCallLink.none;
      });
      _roster?.cancel();
      _roster = null;
      _soundTimer?.cancel();
      _soundTimer = null;
      if (hadMedia) unawaited(_stopSession());
      if (!_mediaWanted) return;
    } else {
      setState(() {});
    }
    if (_inRoom) {
      // A mute must cancel its own pending permission immediately, even while
      // the other capture device keeps this conference connected.
      for (final device in ['video', 'audio']) {
        final wanted =
            desk.requested(device) &&
            (device == 'video' ? media?.video == true : media?.audio == true);
        final actual = device == 'video' ? _cameraOn : _micOn;
        if (!wanted && actual) {
          if (device == 'video') {
            _cameraSeq++;
            _cameraOn = false;
            _cameraLive = false;
          } else {
            _micSeq++;
            _micOn = false;
            _micLive = false;
          }
          unawaited(
            _web?.evaluateJavascript(
              source: 'setDevice(${jsonEncode(device)}, true)',
            ),
          );
        }
      }
      unawaited(_applyDeskDevices());
      return;
    }
    if (!_pageReady ||
        _deskStarting ||
        media == null ||
        _deskAttempt == media.revision)
      return;
    _deskAttempt = media.revision;
    _deskStarting = true;
    unawaited(
      _openPass().whenComplete(() {
        _deskStarting = false;
        if (mounted &&
            !_ended &&
            _mediaWanted &&
            !_inRoom &&
            _deskAttempt != _desk?.media?.revision)
          _onDeskMedia();
      }),
    );
  }

  Future<void> _applyDeskDevices() async {
    if (_applyingDesk || _desk == null || !_inRoom) return;
    _applyingDesk = true;
    try {
      for (final device in ['video', 'audio']) {
        if (!mounted || !_inRoom || !_mediaWanted) return;
        final on =
            _desk!.requested(device) &&
            (device == 'audio'
                ? _desk!.media?.audio == true
                : _desk!.media?.video == true);
        final actual = device == 'video' ? _cameraOn : _micOn;
        if (on != actual) await _setDeviceWish(device, !on);
      }
    } finally {
      _applyingDesk = false;
    }
  }

  Future<LessonCallPassOutcome> _fetchPass() async {
    final locale = LocaleScope.read(context).localeCode;
    final injected = widget.fetchPass;
    if (injected != null) {
      return injected(locale, assignment: _desk?.media?.assignment);
    }
    final invite = widget.inviteToken;
    if (invite == null) {
      return AuthScope.of(
        context,
      ).parentApi.fetchLessonCallPass(childId: widget.childId, locale: locale);
    }
    return AuthScope.of(
      context,
    ).lessonInviteGuestApi.fetchLessonCallPass(token: invite, locale: locale);
  }

  Future<void> _openPass() async {
    final gen = _callGen;
    try {
      final outcome = await _fetchPass();
      if (!mounted ||
          _ended ||
          gen != _callGen ||
          (_desk != null && !_mediaWanted)) {
        return;
      }
      if (outcome.moving) {
        setState(() {
          _holding = true;
          _loading = false;
          _movingDomain = outcome.domain;
        });
        _watchSound();
        _watchBoard();
        _tryStart();
        return;
      }
      final pass = outcome.pass;
      setState(() {
        _pass = pass;
        _loading = false;
        _link = pass == null ? _LessonCallLink.failed : _LessonCallLink.none;
      });
      if (pass?.workspaceFormat == 'board') {
        _watchSound();
        _watchBoard();
      }
      if (_boardWorkspace && _pageReady) {
        await _join();
      } else {
        _tryStart();
      }
    } on ParentApiException catch (error) {
      if (gen == _callGen && !_ended && (_desk == null || _mediaWanted))
        _failOpen(error.code);
    } on KioskApiException catch (error) {
      if (gen == _callGen && !_ended && (_desk == null || _mediaWanted))
        _failOpen(error.code);
    } catch (_) {
      if (gen == _callGen && !_ended && (_desk == null || _mediaWanted))
        _failOpen(null);
    }
  }

  void _failOpen(String? code) {
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
      _link = code == 'inactive' && !_boardWorkspace
          ? _LessonCallLink.closed
          : _LessonCallLink.failed;
    });
    if (_desk != null)
      unawaited(_desk!.report(failedDevice: 'call', error: 'failed'));
  }

  Future<void> _renewPass() async {
    if (!_mediaWanted || _renewing || _link == _LessonCallLink.closed) {
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
      final outcome = await _fetchPass();
      if (!_renewStill(callGen)) {
        return;
      }
      if (outcome.moving) {
        setState(() {
          _holding = true;
          _movingDomain = outcome.domain.isEmpty
              ? _movingDomain
              : outcome.domain;
        });
        await _web?.evaluateJavascript(source: 'holdRoom()');
        return;
      }
      final pass = outcome.pass;
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
      await web.evaluateJavascript(
        source: 'acceptPass(${jsonEncode(pass.toStageJson())})',
      );
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
    final closed = code == 'inactive' && !_boardWorkspace;
    setState(
      () => _link = closed ? _LessonCallLink.closed : _LessonCallLink.failed,
    );
    await _web?.evaluateJavascript(
      source: 'renewFailed(${jsonEncode(closed ? "inactive" : "failed")})',
    );
  }

  void _stopRoster(String? code) {
    if (code == 'inactive' || code == 'forbidden') {
      _roster?.cancel();
      _roster = null;
      if (!_boardWorkspace) {
        _boardTimer?.cancel();
        _boardTimer = null;
      }
    }
    if ((code == 'inactive' || code == 'forbidden') && mounted) {
      setState(() {
        _retireCall();
        _link = _boardWorkspace
            ? _LessonCallLink.failed
            : _LessonCallLink.closed;
      });
      unawaited(_stopSession());
    }
  }

  bool _renewStill(int callGen) {
    return mounted && callGen == _callGen && _link != _LessonCallLink.closed;
  }

  void _watchSound() {
    if (_soundTimer != null) return;
    _soundTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      unawaited(_followRoom());
    });
  }

  Future<void> _followRoom() async {
    if (!_mediaWanted ||
        _following ||
        _ended ||
        _link == _LessonCallLink.closed)
      return;
    _following = true;
    try {
      final outcome = await _fetchPass();
      if (!mounted || _ended) return;
      if (outcome.moving) {
        setState(() {
          _holding = true;
          _movingDomain = outcome.domain.isEmpty
              ? _movingDomain
              : outcome.domain;
        });
        await _web?.evaluateJavascript(source: 'holdRoom()');
        return;
      }
      final pass = outcome.pass;
      if (pass == null || pass.workspaceFormat != 'board') return;
      final previous = _pass?.room;
      setState(() {
        _holding = false;
        _pass = pass;
      });
      if (previous == pass.room && _inRoom) return;
      await _web?.evaluateJavascript(
        source: 'switchRoom(${jsonEncode(pass.toStageJson())})',
      );
    } catch (_) {
      // A failed refresh does not put the child back into the shared call.
    } finally {
      _following = false;
    }
  }

  void _watchBoard() {
    if (_boardTimer != null) return;
    _boardTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      unawaited(_pullBoard());
    });
    unawaited(_pullBoard());
  }

  Future<LessonChildBoard?> _fetchBoard() {
    final injected = widget.fetchBoard;
    if (injected != null) return injected(link: _boardLink);
    final invite = widget.inviteToken;
    if (invite != null) {
      return AuthScope.of(
        context,
      ).lessonInviteGuestApi.fetchBoard(token: invite, link: _boardLink);
    }
    return AuthScope.of(
      context,
    ).parentApi.fetchChildBoard(childId: widget.childId, link: _boardLink);
  }

  Future<bool> _sendBoard(Map<String, dynamic> body) {
    final injected = widget.sendBoard;
    if (injected != null) return injected(body);
    final invite = widget.inviteToken;
    if (invite != null) {
      return AuthScope.of(
        context,
      ).lessonInviteGuestApi.sendBoard(token: invite, body: body);
    }
    return AuthScope.of(
      context,
    ).parentApi.sendChildBoard(childId: widget.childId, body: body);
  }

  Future<void> _pullBoard() async {
    if (_boardBusy || _ended || !mounted) return;
    if (!_boardWorkspace && !_holding) return;
    _boardBusy = true;
    try {
      final board = await _fetchBoard();
      if (!mounted || board == null || _ended) return;
      if (widget.lessonSessionId != null &&
          board.lessonSessionId != widget.lessonSessionId)
        return;
      final key =
          '${board.focusRoomId}|${board.roomEpoch}|${board.sceneGeneration}|${board.instanceKey}';
      if (key != _boardKey) {
        _boardKey = key;
        _boardGen += 1;
      }
      _board = board;
      await _web?.evaluateJavascript(
        source: 'noteLessonClock(${board.serverNow})',
      );
      if (!mounted || _ended) return;
      await _web?.evaluateJavascript(
        source:
            'setChildRoom(${jsonEncode({..._clientVersion, 'childId': widget.childId, 'drawMode': board.drawMode, 'exercises': board.exercises, 'personalRuns': board.personalRuns, 'link': _boardLink, 'epoch': board.roomEpoch, 'focus': board.focusRoomId, 'lessonSessionId': board.lessonSessionId, 'presence': board.presence, 'participants': board.participants, 'rulerScale': board.rulerScale, 'navigation': board.navigation, 'gen': _boardGen, 'revision': board.sceneRevision, 'scene': board.scene, 'sceneGeneration': board.sceneGeneration, 'serverNow': board.serverNow, 'sound': board.sound, 'conversation': board.conversation, 'title': board.title})})',
      );
      await _syncLessonChrome();
    } catch (_) {
      // A missed snapshot does not end the lesson or the call.
    } finally {
      _boardBusy = false;
    }
  }

  Future<void> _sceneRoom(String detail) async {
    final board = _board;
    if (board == null) return;
    try {
      final body = jsonDecode(detail);
      if (body is! Map) return;
      final gen = body['gen'];
      final elements = body['elements'];
      final roomId = body['roomId'];
      final epoch = body['epoch'];
      if (gen is! int || gen != _boardGen || elements is! List) return;
      if (roomId is! String ||
          epoch is! int ||
          roomId != board.focusRoomId ||
          epoch != board.roomEpoch)
        return;
      await _sendBoard({
        'elements': elements,
        'kind': 'scene',
        'roomEpoch': epoch,
        'roomId': roomId,
        'sceneGeneration': board.sceneGeneration,
      });
    } catch (_) {
      // A stroke from the previous room is not written.
    }
  }

  void _tryStart() {
    if (_ended || !mounted) return;
    final web = _web;
    final pass = _pass;
    final html = _html;
    final domain = pass?.domain ?? _movingDomain;
    if (web == null ||
        (widget.mediaEnabled && !_boardWorkspace && domain.isEmpty) ||
        html == null ||
        _starting) {
      return;
    }

    _starting = true;
    _awaitingPage = true;
    _pageGen += 1;
    web.loadData(
      data: html,
      mimeType: 'text/html',
      encoding: 'utf-8',
      baseUrl: WebUri(
        _boardWorkspace || !widget.mediaEnabled
            ? AppConfig.apiBaseUrl
            : 'https://$domain/',
      ),
    );
  }

  Future<void> _installBoard() async {
    final web = _web;
    final pageGen = _pageGen;
    if (web == null) {
      return;
    }
    final source = await rootBundle.loadString('assets/call/larnes-board.js');
    if (!mounted || _web != web || _pageGen != pageGen) {
      return;
    }
    const size = 240000;
    var start = 0;
    while (start < source.length) {
      if (!mounted || _web != web || _pageGen != pageGen) {
        return;
      }
      var end = start + size < source.length ? start + size : source.length;
      if (end < source.length &&
          source.codeUnitAt(end - 1) >= 0xD800 &&
          source.codeUnitAt(end - 1) <= 0xDBFF) {
        end -= 1;
      }
      final last = end == source.length;
      final part = jsonEncode(source.substring(start, end));
      await web.evaluateJavascript(
        source: 'installBoard($part,${last ? 'true' : 'false'})',
      );
      start = end;
    }
  }

  Future<void> _join() async {
    final web = _web;
    final pass = _pass;
    if (_ended ||
        !_mediaWanted ||
        web == null ||
        pass == null ||
        _joined ||
        (_boardWorkspace && !_pageReady)) {
      return;
    }

    _joined = true;
    await _syncPage();
    await web.evaluateJavascript(
      source: 'join(${jsonEncode(pass.toStageJson())})',
    );
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
      'board': {
        'presenceTeacher': l10n.parentLiveLessonBoardPresenceTeacher,
        'presenceParticipant': l10n.parentLiveLessonBoardPresenceParticipant,
      },
      // Pictures load from the site; only the parent's own sign-in may upload one.
      'boardImages': {
        'base': boardImageBase(),
        'upload': _boardWorkspace ? widget.messenger != null : _parentSession,
        'private': _boardWorkspace,
      },
    });
    await web.evaluateJavascript(source: 'setLabels($labels)');
    await web.evaluateJavascript(source: 'setBand(${widget.trainerOpen})');
    await _syncLessonChrome();
  }

  Future<Map<String, String>> _lessonImage(
    List<dynamic> args,
    bool upload,
  ) async {
    final scope = widget.messenger, board = _board;
    if (scope == null ||
        board == null ||
        args.isEmpty ||
        args.first is! Map ||
        !mounted ||
        _ended)
      return {'code': 'forbidden'};
    final input = args.first as Map, gen = _boardGen;
    if (input['gen'] != gen ||
        input['roomId'] != board.focusRoomId ||
        input['roomEpoch'] != board.roomEpoch ||
        scope.lessonSessionId != board.lessonSessionId)
      return {'code': 'forbidden'};
    final headers = await scope.authorization();
    if (!mounted ||
        _ended ||
        gen != _boardGen ||
        widget.messenger?.sessionKey != scope.sessionKey)
      return {'code': 'forbidden'};
    final frozen = MessengerScope(
      authorization: () async => headers,
      credential: scope.credential,
      intent: scope.intent,
      lessonSessionId: scope.lessonSessionId,
      ownerKey: scope.ownerKey,
      admissionId: scope.admissionId,
      childId: scope.childId,
    );
    final result = await lessonBoardImageFromPage(
      scope: frozen,
      roomId: board.focusRoomId,
      input: input,
      upload: upload,
    );
    if (!mounted ||
        _ended ||
        gen != _boardGen ||
        widget.messenger?.sessionKey != scope.sessionKey)
      return {'code': 'forbidden'};
    return result;
  }

  Future<void> _syncLessonChrome() async {
    final web = _web;
    if (web == null || !_boardWorkspace || !mounted || _ended) return;
    final l10n = context.l10n;
    String? deviceNote(String? note, bool video) => note == null
        ? null
        : video
        ? note == 'denied'
              ? l10n.parentLiveLessonCameraDenied
              : note == 'missing'
              ? l10n.parentLiveLessonCameraMissing
              : l10n.parentLiveLessonCameraAskAgain
        : note == 'denied'
        ? l10n.parentLiveLessonMicDenied
        : note == 'missing'
        ? l10n.parentLiveLessonMicMissing
        : l10n.parentLiveLessonMicAskAgain;
    final state = {
      'callReady': _desk != null ? _desk!.media != null : widget.mediaEnabled,
      'videoOn': _desk?.requested('video') ?? _cameraOn,
      'audioOn': _desk?.requested('audio') ?? _micOn,
      'connected': _inRoom,
      'chat': widget.messenger != null,
      'chatLabel': l10n.messengerOpen,
      'messengerOpen': _messengerOpen,
      'messageSoundEnabled': NativeMessageSound.enabled.value,
      'messenger': widget.messenger == null
          ? null
          : {
              'identity': _messengerBridgeIdentity,
              'lessonSessionId': widget.messenger!.lessonSessionId,
              'childId': widget.messenger!.childId ?? widget.childId,
              'credential': widget.messenger!.credential.name,
              'intent': widget.messenger!.intent.name,
            },
      'unread': _messengerOpen ? 0 : _messenger?.unread ?? 0,
      'noticeInbox': _messenger?.gateway is MessengerApi
          ? (_messenger!.gateway as MessengerApi).noticeInbox(_messenger!.scope)
          : null,
      'retry': _link == _LessonCallLink.lost || _link == _LessonCallLink.failed,
      'hearBlocked': _hearBlocked,
      'retryLabel': _hearBlocked
          ? l10n.parentLiveLessonHear
          : l10n.parentLiveLessonLinkRetry,
      'note': [
        if (_link == _LessonCallLink.failed) l10n.parentLiveLessonCallFailed,
        if (_link == _LessonCallLink.lost) l10n.parentLiveLessonLinkLost,
        if (_link == _LessonCallLink.reconnecting)
          l10n.parentLiveLessonLinkReconnecting,
        deviceNote(_cameraNote, true),
        deviceNote(_micNote, false),
      ].whereType<String>().join(' '),
    };
    try {
      await web.evaluateJavascript(
        source:
            'if(window.LarnesBoard?.setChrome)window.LarnesBoard.setChrome(${jsonEncode(state)})',
      );
    } catch (_) {
      /* Page may be closing. */
    }
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
    final callGen = _callGen;
    if (endpointId == null ||
        endpointId.isEmpty ||
        web == null ||
        _claiming ||
        !mounted) {
      return;
    }

    _claiming = true;
    final locale = Localizations.localeOf(context).languageCode;
    final claim = widget.claimRoster;
    try {
      final teachers = claim != null
          ? await claim(
              endpointId: endpointId,
              locale: locale,
              assignment: _desk?.media?.assignment,
            )
          : widget.inviteToken == null
          ? await AuthScope.of(context).parentApi.claimLessonCallRoster(
              childId: widget.childId,
              endpointId: endpointId,
              locale: locale,
            )
          : await AuthScope.of(
              context,
            ).lessonInviteGuestApi.claimLessonCallRoster(
              token: widget.inviteToken!,
              endpointId: endpointId,
              locale: locale,
            );
      if (!mounted ||
          _web != web ||
          _endpointId != endpointId ||
          _callGen != callGen) {
        return;
      }
      await web.evaluateJavascript(
        source:
            'setTeachers(${jsonEncode(teachers.ids)}, ${jsonEncode(teachers.primary)})',
      );
      if (!mounted ||
          _web != web ||
          _endpointId != endpointId ||
          _callGen != callGen) {
        return;
      }
      await web.evaluateJavascript(
        source:
            'setBoardRoster(${jsonEncode(teachers.toBoardJson())}, ${jsonEncode(endpointId)})',
      );
    } on ParentApiException catch (error) {
      if (!mounted ||
          _web != web ||
          _endpointId != endpointId ||
          _callGen != callGen) {
        return;
      }
      await web.evaluateJavascript(
        source: 'setBoardRoster(null, ${jsonEncode(endpointId)})',
      );
      _stopRoster(error.code);
    } on KioskApiException catch (error) {
      if (!mounted ||
          _web != web ||
          _endpointId != endpointId ||
          _callGen != callGen) {
        return;
      }
      await web.evaluateJavascript(
        source: 'setBoardRoster(null, ${jsonEncode(endpointId)})',
      );
      _stopRoster(error.code);
    } finally {
      _claiming = false;
    }
  }

  void _retireCall() {
    _callGen += 1;
    _endpointId = null;
    _cameraSeq += 1;
    _micSeq += 1;
    _inRoom = false;
    _cameraOn = false;
    _micOn = false;
    _cameraLive = false;
    _micLive = false;
  }

  Future<void> _stopSession() async {
    try {
      await _web?.evaluateJavascript(
        source: _boardWorkspace ? 'pauseMedia()' : 'dropSession()',
      );
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
    if (!_mediaWanted) return;
    final video = device == 'video';
    final seq = video ? ++_cameraSeq : ++_micSeq;
    final callGen = _callGen;
    final expectedMedia = _desk?.media;
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
      final permission = video ? Permission.camera : Permission.microphone;
      final granted = (await permission.request()).isGranted;
      if (!_deviceWishCurrent(video, seq, callGen)) {
        return;
      }
      final cameraGranted = video ? granted : await Permission.camera.isGranted;
      final micGranted = video
          ? await Permission.microphone.isGranted
          : granted;
      await _web?.evaluateJavascript(
        source: 'allowDevices($cameraGranted, $micGranted)',
      );
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
        if (_desk != null)
          unawaited(
            _desk!.report(
              failedDevice: device,
              error: 'denied',
              expected: expectedMedia,
            ),
          );
        if (!_deviceWishCurrent(video, seq, callGen)) {
          return;
        }
        await _web?.evaluateJavascript(
          source: 'setDevice(${jsonEncode(device)}, true)',
        );
        return;
      }
    }
    if (!_deviceWishCurrent(video, seq, callGen)) {
      return;
    }
    await _web?.evaluateJavascript(
      source: 'setDevice(${jsonEncode(device)}, $muted)',
    );
  }

  Future<void> _applyTeacherMedia(String device, bool muted) async {
    if ((device != 'video' && device != 'audio') || !_inRoom) {
      return;
    }
    await _setDeviceWish(device, muted);
  }

  Future<void> _toggleCamera() async {
    if (_desk != null) {
      await _desk!.change('video', !_desk!.requested('video'));
      return;
    }
    if (!_inRoom) {
      return;
    }
    await _setDeviceWish('video', _cameraOn);
  }

  Future<void> _toggleMic() async {
    if (_desk != null) {
      await _desk!.change('audio', !_desk!.requested('audio'));
      return;
    }
    if (!_inRoom) {
      return;
    }
    await _setDeviceWish('audio', _micOn);
  }

  Future<void> _resumeHear() async {
    await _web?.evaluateJavascript(source: 'resumeHear()');
  }

  Future<void> _rejoin() async {
    if (_desk != null) {
      await _desk!.refresh();
      _deskAttempt = -1;
      _onDeskMedia();
      return;
    }
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
    _retireCall();
    _boardGen++;
    _pageGen++;
    _roster?.cancel();
    _soundTimer?.cancel();
    _boardTimer?.cancel();
    _chromeTimer?.cancel();
    _desk?.removeListener(_onDeskMedia);
    _desk?.dispose();
    _desk = null;
    _messenger?.pause();
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

  Future<Map<String, dynamic>> _requestBoardExercise(List<dynamic> args) async {
    final board = _board;
    if (!mounted ||
        _ended ||
        board == null ||
        args.isEmpty ||
        args.first is! Map)
      return {'accepted': false};
    final request = Map<String, dynamic>.from(args.first as Map);
    if (request['gen'] != _boardGen ||
        request['roomId'] != board.focusRoomId ||
        request['body'] is! Map)
      return {'accepted': false};
    final body = Map<String, dynamic>.from(request['body'] as Map);
    if (!{
      'audio',
      'field',
      'command',
      'preview',
      'presence',
      'ready',
      'scene',
      'personal',
    }.contains(body['kind']))
      return {'accepted': false};
    if (body['kind'] == 'scene' &&
        (body['roomId'] != board.focusRoomId ||
            body['roomEpoch'] != board.roomEpoch ||
            body['lessonSessionId'] != board.lessonSessionId))
      return {'accepted': false};
    if (body['kind'] == 'presence' &&
        (body['roomId'] != board.focusRoomId ||
            body['roomEpoch'] != board.roomEpoch))
      return {'accepted': false};
    if (body['kind'] == 'ready') body['link'] = _boardLink;
    if (body['kind'] == 'personal') body['writer'] = _boardLink;
    final injected = widget.requestBoard;
    if (injected != null) return await injected(body) ?? {'accepted': false};
    // Never fall through from a kiosk identity to the parent's credentials.
    if (widget.fetchBoard != null) return {'accepted': false};
    final invite = widget.inviteToken;
    final auth = AuthScope.of(context);
    final result = invite != null
        ? await auth.lessonInviteGuestApi.requestBoard(
            token: invite,
            body: body,
          )
        : await auth.parentApi.requestChildBoard(
            childId: widget.childId,
            body: body,
          );
    return result ?? {'accepted': false};
  }

  Future<Map<String, dynamic>> _lessonMessenger(List<dynamic> args) async {
    final scope = widget.messenger;
    if (scope == null ||
        !mounted ||
        _ended ||
        args.isEmpty ||
        args.first is! Map)
      return {'error': 'forbidden'};
    final input = Map<String, dynamic>.from(args.first as Map),
        identity = _messengerBridgeIdentity;
    if (input['identity'] != identity) return {'error': 'forbidden'};
    if (input['operation'] == 'sound' && input['enabled'] is bool) {
      NativeMessageSound.setEnabled(input['enabled'] as bool);
      return {'ok': true};
    }
    final headers = await scope.authorization();
    if (!mounted || _ended || identity != _messengerBridgeIdentity)
      return {'error': 'forbidden'};
    final frozen = MessengerScope(
      authorization: () async => headers,
      credential: scope.credential,
      intent: scope.intent,
      lessonSessionId: scope.lessonSessionId,
      ownerKey: scope.ownerKey,
      admissionId: scope.admissionId,
      childId: scope.childId,
    );
    if (input['operation'] == 'open-file') {
      final id = input['id'];
      if (id is! String || !RegExp(r'^[a-zA-Z0-9-]{8,80}$').hasMatch(id))
        return {'error': 'file'};
      await _messenger?.openFile(id);
      return {'ok': true};
    }
    final result = await _workspaceMessengerApi.webview(frozen, input);
    if (!mounted || _ended || identity != _messengerBridgeIdentity)
      return {'error': 'forbidden'};
    return result;
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
    if (!mounted || _ended) {
      return;
    }
    final detail = message['detail'];
    if (kind == 'workspace-action') {
      switch (detail) {
        case 'video':
          _toggleCamera();
        case 'audio':
          _toggleMic();
        case 'chat':
          _toggleChat();
        case 'leave':
          unawaited(_leaveFromDock());
        case 'restore':
          if (_hearBlocked) {
            _resumeHear();
          } else {
            _rejoin();
          }
      }
      unawaited(_syncLessonChrome());
      return;
    }
    if (kind == 'room-scene' && detail is String) {
      unawaited(_sceneRoom(detail));
      return;
    }
    final block = detail is String && detail.isNotEmpty ? detail : 'failed';
    var stopSession = false;
    var openDevices = false;
    setState(() {
      switch (kind) {
        case 'board-widgets':
          _boardWidgets = true;
          _boardAudioReady = detail is String && detail.isNotEmpty
              ? detail
              : 'not-started';
        case 'joined':
          _inRoom = true;
          _link = _LessonCallLink.none;
          openDevices = widget.captureOnJoin;
          if (_desk != null) {
            unawaited(_applyDeskDevices());
          }
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
          _cameraLive = true;
          _cameraNote = null;
        case 'camera-off':
          _cameraOn = false;
          _cameraLive = false;
        case 'camera-failed':
          _cameraOn = false;
          _cameraLive = false;
          _cameraNote = block;
          if (_desk != null)
            unawaited(_desk!.report(failedDevice: 'video', error: block));
        case 'mic-on':
          _micOn = true;
          _micLive = true;
          _micNote = null;
        case 'mic-off':
          _micOn = false;
          _micLive = false;
        case 'mic-failed':
          _micOn = false;
          _micLive = false;
          _micNote = block;
          if (_desk != null)
            unawaited(_desk!.report(failedDevice: 'audio', error: block));
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
          _link = _boardWorkspace
              ? _LessonCallLink.failed
              : _LessonCallLink.closed;
          stopSession = true;
        case 'mode':
          if (detail == 'grid' || detail == 'talk' || detail == 'workflow') {
            _mode = detail;
            if (_mode != 'workflow') {
              _chromeOpen = false;
              _chromeTimer?.cancel();
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
          if (_desk != null)
            unawaited(_desk!.report(failedDevice: 'call', error: 'failed'));
      }
    });
    if (stopSession) {
      unawaited(_stopSession());
    }
    unawaited(_syncLessonChrome());
    if (_desk != null &&
        _inRoom &&
        (kind == 'camera-on' ||
            kind == 'mic-on' ||
            kind == 'camera-off' ||
            kind == 'mic-off')) {
      unawaited(
        _desk!.report(
          joined:
              (!_desk!.requested('video') || _cameraLive) &&
              (!_desk!.requested('audio') || _micLive),
        ),
      );
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
    if (oldWidget.messenger?.sessionKey != widget.messenger?.sessionKey) {
      _messengerBridgeEpoch++;
      if (oldWidget.messenger != null)
        _workspaceMessengerApi.cancelScope(oldWidget.messenger!);
      _attachMessenger();
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
    NativeMessageSound.enabled.removeListener(_onMessenger);
    if (widget.messenger != null)
      _workspaceMessengerApi.cancelScope(widget.messenger!);
    _callGen += 1;
    _pageGen += 1;
    _cameraSeq += 1;
    _micSeq += 1;
    WidgetsBinding.instance.removeObserver(this);
    _roster?.cancel();
    _soundTimer?.cancel();
    _boardTimer?.cancel();
    _chromeTimer?.cancel();
    _desk?.removeListener(_onDeskMedia);
    _desk?.dispose();
    widget.handle?.detach(endCall);
    _messenger?.removeListener(_onMessenger);
    _messenger?.pause();
    if (!_ended) {
      _web?.evaluateJavascript(source: 'leave()');
    }
    super.dispose();
  }

  Widget _callSurface() {
    if (widget.mediaEnabled && !_boardWorkspace && _pass == null && !_holding) {
      return ColoredBox(
        color: const Color(0xFF111111),
        child: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : const SizedBox.shrink(),
        ),
      );
    }

    return InAppWebView(
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        iframeAllow: 'camera; microphone',
        supportZoom: false,
      ),
      onWebViewCreated: (controller) {
        _web = controller;
        controller.addJavaScriptHandler(
          handlerName: 'lessonMessenger',
          callback: _lessonMessenger,
        );
        controller.addJavaScriptHandler(
          handlerName: 'lessonCall',
          callback: _onBridge,
        );
        controller.addJavaScriptHandler(
          handlerName: 'boardExercise',
          callback: _requestBoardExercise,
        );
        controller.addJavaScriptHandler(
          handlerName: 'boardImage',
          callback: (args) => _boardWorkspace
              ? _lessonImage(args, true)
              : _parentSession
              ? uploadBoardImageFromPage(AuthScope.of(context).parentApi, args)
              : Future.value(const {'code': 'forbidden'}),
        );
        controller.addJavaScriptHandler(
          handlerName: 'boardImageData',
          callback: (args) => _lessonImage(args, false),
        );
        _tryStart();
      },
      onLoadStop: (controller, url) async {
        if (_ended || !_awaitingPage || _joined) {
          return;
        }
        _awaitingPage = false;
        try {
          await _installBoard();
        } catch (_) {
          // Доска не встала. Звонок всё равно открывается.
        }
        if (!mounted || _ended) {
          return;
        }
        if (_boardWorkspace || !widget.mediaEnabled) {
          await _syncPage();
          await controller.evaluateJavascript(
            source:
                'openWorkspace(${jsonEncode({'workspaceFormat': _boardWorkspace ? 'board' : widget.workspaceFormat})})',
          );
          await _pullBoard();
          _pageReady = true;
          _onDeskMedia();
          if (widget.mediaEnabled) await _join();
          return;
        }
        if (_holding && _pass == null) {
          await controller.evaluateJavascript(source: 'holdRoom()');
          return;
        }
        await _join();
      },
      onPermissionRequest: (controller, request) async {
        final resources = request.resources;
        final capture = {
          PermissionResourceType.CAMERA,
          PermissionResourceType.MICROPHONE,
          PermissionResourceType.CAMERA_AND_MICROPHONE,
        };
        if (resources.isEmpty ||
            !_mediaWanted ||
            resources.any((type) => !capture.contains(type))) {
          return PermissionResponse(
            resources: resources,
            action: PermissionResponseAction.DENY,
          );
        }
        final desk = _desk;
        if (desk != null) {
          final camera = desk.requested('video') && desk.media?.video == true;
          final mic = desk.requested('audio') && desk.media?.audio == true;
          if (resources.any(
            (type) =>
                (type == PermissionResourceType.CAMERA && !camera) ||
                (type == PermissionResourceType.MICROPHONE && !mic) ||
                (type == PermissionResourceType.CAMERA_AND_MICROPHONE &&
                    (!camera || !mic)),
          )) {
            return PermissionResponse(
              resources: resources,
              action: PermissionResponseAction.DENY,
            );
          }
        }
        return PermissionResponse(
          resources: resources,
          action: PermissionResponseAction.GRANT,
        );
      },
    );
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
    if (_leavingDesk || _ended) return;
    final confirm = widget.leaveLesson;
    if (confirm != null) {
      setState(() {
        _leavingDesk = true;
        _leaveFailed = false;
      });
      bool released;
      try {
        released = await confirm();
      } catch (_) {
        released = false;
      }
      if (!mounted) return;
      if (!released) {
        setState(() {
          _leavingDesk = false;
          _leaveFailed = true;
        });
        return;
      }
    }
    await endCall();
    if (!mounted) {
      return;
    }
    widget.onLeave();
  }

  void _attachMessenger() {
    _messengerOpen = false;
    _messenger?.removeListener(_onMessenger);
    _messenger?.pause();
    final scope = widget.messenger;
    if (scope == null || !scope.canOpen) {
      _messenger = null;
      _messengerOpen = false;
      return;
    }
    _messenger = MessengerRooms.retain(scope);
    _messenger!.addListener(_onMessenger);
    _messenger!.setVisible(_messengerOpen);
  }

  void _onMessenger() {
    if (mounted) setState(() {});
    unawaited(_syncLessonChrome());
  }

  void _toggleChat() {
    final room = _messenger;
    if (room == null) return;
    setState(() => _messengerOpen = !_messengerOpen);
    room.setVisible(_messengerOpen);
    if (_boardWorkspace) room.setVisible(false);
    unawaited(_syncLessonChrome());
  }

  Widget _chatButton() {
    final room = _messenger;
    final unread = _messengerOpen ? 0 : room?.unread ?? 0;
    final label = context.l10n.messengerOpen;
    return _ChatButton(label: label, unread: unread, onPressed: _toggleChat);
  }

  Widget _dock({required bool showChat}) {
    return LessonCallDock(
      audioOn: _desk?.requested('audio') ?? _micOn,
      callReady: _desk != null ? _desk!.media != null : _inRoom,
      cameraNote: _cameraNote,
      canRetry: _link != _LessonCallLink.closed,
      closed: _link == _LessonCallLink.closed,
      connectFailed: _link == _LessonCallLink.failed,
      hearBlocked: _hearBlocked,
      lost: _link == _LessonCallLink.lost,
      reconnecting: _link == _LessonCallLink.reconnecting,
      micNote: _micNote,
      videoOn: _desk?.requested('video') ?? _cameraOn,
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
      onChat: showChat ? _toggleChat : null,
      unread: _messengerOpen ? 0 : _messenger?.unread ?? 0,
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
            side: BorderSide(
              color: hear ? const Color(0xFFDC2626) : ParentColors.line,
            ),
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
    final boardFormat = _boardWorkspace;
    final board = boardFormat || (_mode == 'workflow' && !trainer);
    final handle = !boardFormat && (board || trainer);

    return Column(
      children: [
        if (_leaveFailed)
          Text(
            context.l10n.parentLiveLessonLeaveFailed,
            style: const TextStyle(color: Colors.red),
          ),
        Flexible(
          child: Stack(
            children: [
              Positioned.fill(
                child: MetaData(
                  metaData: _boardWidgets ? _boardAudioReady : '',
                  child: _callSurface(),
                ),
              ),
              if (trainer) Positioned.fill(child: widget.body!),
              if (handle)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Column(
                    crossAxisAlignment: trainer
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_chromeOpen && !_hearBlocked) _dock(showChat: false),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          12,
                          0,
                          12,
                          8 + MediaQuery.paddingOf(context).bottom,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.messenger != null) ...[
                              _chatButton(),
                              const SizedBox(width: 8),
                            ],
                            _linkButton(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (_messengerOpen &&
                  _messenger != null &&
                  (!boardFormat || !_boardWidgets))
                Positioned.fill(
                  child: MessengerPanel(
                    room: _messenger!,
                    onClose: _toggleChat,
                  ),
                ),
            ],
          ),
        ),
        if (!handle && (!boardFormat || !_boardWidgets))
          _dock(showChat: widget.messenger != null),
      ],
    );
  }
}

class _ChatButton extends StatelessWidget {
  const _ChatButton({
    required this.label,
    required this.onPressed,
    required this.unread,
  });

  final String label;
  final VoidCallback onPressed;
  final int unread;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: ParentColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: ParentColors.line),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onPressed,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.chat_bubble_outline, size: 24),
              ),
            ),
          ),
          if (unread > 0)
            Positioned(
              right: -2,
              top: -2,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0xFFB42318),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    '${unread > 99 ? 99 : unread}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
