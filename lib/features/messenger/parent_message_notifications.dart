import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/auth/token_storage.dart';
import 'package:larnes_mobile/core/config/app_config.dart';
import 'package:larnes_mobile/features/messenger/message_inbox.dart';
import 'package:larnes_mobile/features/messenger/message_sound.dart';
import 'package:larnes_mobile/features/messenger/message_bubble.dart';
import 'package:larnes_mobile/features/messenger/messenger_room.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

final parentMessageUnread = ValueNotifier<int>(0);
final parentChildUnread = ValueNotifier<Map<String, int>>({});
final parentLessonUnread = ValueNotifier<Map<String, int>>({});

/// One foreground inbox for all parent pages. Lessons use the shared WebView UI.
class ParentMessageNotifications extends StatefulWidget {
  const ParentMessageNotifications({
    super.key,
    required this.router,
    required this.accountId,
    required this.child,
  });
  final GoRouter router;
  final String? accountId;
  final Widget child;
  @override
  State<ParentMessageNotifications> createState() =>
      _ParentMessageNotificationsState();
}

class _ParentMessageNotificationsState extends State<ParentMessageNotifications>
    with WidgetsBindingObserver {
  final _tracker = MessageInboxTracker(), _tokens = TokenStorage();
  final _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      validateStatus: (status) => status != null && status < 600,
    ),
  );
  Timer? _timer, _hide;
  CancelToken? _request;
  MessagePreview? _preview;
  int _generation = 0;
  bool _foreground = true, _busy = false;
  String get _path =>
      widget.router.routerDelegate.currentConfiguration.uri.path;
  bool get _eligible =>
      widget.accountId != null &&
      _foreground &&
      _path.startsWith('/parent') &&
      !_path.endsWith('/lesson');
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.router.routerDelegate.addListener(_route);
    unawaited(NativeMessageSound.load());
    unawaited(NativeMessageSound.prepare());
    _schedule();
  }

  @override
  void didUpdateWidget(covariant ParentMessageNotifications old) {
    super.didUpdateWidget(old);
    if (old.accountId != widget.accountId) {
      _generation++;
      _request?.cancel();
      _tracker.clear();
      parentMessageUnread.value = 0;
      parentChildUnread.value = {};
      parentLessonUnread.value = {};
      _preview = null;
      _hide?.cancel();
      NativeMessageSound.stop();
      _schedule();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _generation++;
      _request?.cancel();
      _hide?.cancel();
      setState(() => _preview = null);
    }
    _schedule();
  }

  void _route() {
    if (!_eligible) {
      _generation++;
      _request?.cancel();
      _hide?.cancel();
      if (mounted && _preview != null) setState(() => _preview = null);
    }
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (_eligible) _timer = Timer(const Duration(milliseconds: 300), _poll);
  }

  Future<void> _poll() async {
    if (!mounted || !_eligible) return;
    if (_busy) {
      _timer = Timer(const Duration(seconds: 1), _poll);
      return;
    }
    _busy = true;
    final generation = _generation;
    final cancel = CancelToken();
    _request = cancel;
    try {
      final token = await _tokens.readToken().timeout(
        const Duration(seconds: 1),
      );
      if (token == null || generation != _generation) return;
      final response = await _dio.get<Object>(
        '/api/messenger/inbox',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        cancelToken: cancel,
      );
      if (!mounted || generation != _generation || !_eligible) return;
      if (response.statusCode == 401 || response.statusCode == 403) {
        _tracker.clear();
        parentMessageUnread.value = 0;
        parentChildUnread.value = {};
        parentLessonUnread.value = {};
        return;
      }
      if (response.statusCode == 200) {
        final incoming = _tracker.update(
          response.data,
          DateTime.now().millisecondsSinceEpoch,
          reading: MessengerRooms.reading,
        );
        parentMessageUnread.value = _tracker.unread;
        parentChildUnread.value = _tracker.children;
        parentLessonUnread.value = _tracker.rooms;
        if (incoming.isNotEmpty) {
          setState(() => _preview = incoming.last);
          NativeMessageSound.play();
          _hide?.cancel();
          _hide = Timer(const Duration(seconds: 6), () {
            if (mounted) setState(() => _preview = null);
          });
        }
      }
    } catch (_) {
      /* A failed notification request cannot block a page. */
    } finally {
      _busy = false;
      if (mounted && _eligible) {
        _timer = Timer(const Duration(seconds: 4), _poll);
      }
    }
  }

  void _close() {
    _hide?.cancel();
    setState(() => _preview = null);
  }

  void _resumeHide() {
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _preview = null);
    });
  }

  @override
  void dispose() {
    _generation++;
    _timer?.cancel();
    _hide?.cancel();
    _request?.cancel();
    _dio.close(force: true);
    widget.router.routerDelegate.removeListener(_route);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notice = _preview;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (notice != null)
          Positioned(
            right: 12,
            left: MediaQuery.sizeOf(context).width < 600 ? 12 : null,
            bottom:
                96 +
                MediaQuery.viewInsetsOf(context).bottom +
                MediaQuery.paddingOf(context).bottom,
            child: Semantics(
              liveRegion: true,
              child: Dismissible(
                key: ValueKey(notice.id),
                direction: DismissDirection.horizontal,
                onDismissed: (_) => _close(),
                child: Focus(
                  onFocusChange: (focused) {
                    if (focused) {
                      _hide?.cancel();
                    } else {
                      _resumeHide();
                    }
                  },
                  child: MouseRegion(
                    onEnter: (_) => _hide?.cancel(),
                    onExit: (_) => _resumeHide(),
                    child: Material(
                      color: Colors.transparent,
                      elevation: 5,
                      borderRadius: BorderRadius.circular(8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: MessengerBubbleSurface(
                          margin: EdgeInsets.zero,
                          child: Stack(
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  _close();
                                  final target =
                                      '/parent/${notice.childId}/chats?chat=${notice.lessonId}';
                                  if (_path.endsWith('/chats')) {
                                    widget.router.go(target);
                                  } else {
                                    widget.router.push(target);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    4,
                                    4,
                                    32,
                                    4,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        notice.author,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        notice.text.isEmpty
                                            ? context.l10n.messengerFile
                                            : notice.text,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                right: -5,
                                top: -5,
                                child: IconButton(
                                  tooltip:
                                      context.l10n.messengerNotificationClose,
                                  visualDensity: VisualDensity.compact,
                                  onPressed: _close,
                                  icon: const Icon(Icons.close, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
