import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/features/messenger/messenger_api.dart';
import 'package:larnes_mobile/features/messenger/messenger_panel.dart';
import 'package:larnes_mobile/features/messenger/messenger_room.dart';
import 'package:larnes_mobile/features/messenger/messenger_scope.dart';
import 'package:larnes_mobile/features/messenger/messenger_wire.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

/// Lesson chats for one child. The parent writes as the adult, with no call open.
class ChildChatsScreen extends StatefulWidget {
  const ChildChatsScreen({super.key, required this.childId});

  final String childId;

  @override
  State<ChildChatsScreen> createState() => _ChildChatsScreenState();
}

class _ChildChatsScreenState extends State<ChildChatsScreen>
    with WidgetsBindingObserver {
  MessengerGateway? _gateway;
  MessengerScope? _scope;
  bool _started = false;
  int _generation = 0;
  final List<MessengerArchiveRow> _rows = [];
  String? _cursor;
  String? _error;
  bool _loading = true;
  MessengerRoom? _open;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _open?.resume();
    } else {
      _open?.pause();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _switchScope();
  }

  @override
  void didUpdateWidget(covariant ChildChatsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.childId != widget.childId) _switchScope();
  }

  void _switchScope() {
    final next = _buildScope();
    if (_started && next?.sessionKey == _scope?.sessionKey) return;
    _started = true;
    _generation++;
    final previous = _scope;
    if (previous != null && _gateway is MessengerApi) {
      (_gateway as MessengerApi).cancelScope(previous);
    }
    _open?.pause();
    _open = null;
    _scope = next;
    _rows.clear();
    _cursor = null;
    _error = null;
    _loading = true;
    _load(reset: true);
  }

  MessengerScope? _buildScope() {
    final accountId = AuthScope.of(context).user?.id ?? '';
    if (accountId.isEmpty) return null;
    return MessengerScope.parent(
      accountId: accountId,
      childId: widget.childId,
      lessonSessionId: 'archive',
    );
  }

  Future<void> _load({required bool reset}) async {
    final scope = _scope;
    final generation = _generation;
    if (scope == null) {
      setState(() {
        _error = 'forbidden';
        _loading = false;
      });
      return;
    }
    _gateway ??= MessengerApi();
    final page = await _gateway!.archive(scope, before: reset ? null : _cursor);
    if (!mounted || generation != _generation) return;
    if (page is MessengerDenied<MessengerArchivePage>) {
      setState(() {
        _error = page.code;
        _loading = false;
        if (page.code == 'forbidden') _rows.clear();
      });
      return;
    }
    if (page is MessengerOk<MessengerArchivePage>) {
      setState(() {
        if (reset) _rows.clear();
        _rows.addAll(page.value.rows);
        _cursor = page.value.nextCursor;
        _error = null;
        _loading = false;
      });
    }
  }

  void _show(MessengerArchiveRow row) {
    final scope = _scope?.forLesson(row.lessonSessionId);
    if (scope == null) return;
    final room = MessengerRooms.retain(scope, gateway: _gateway);
    room.setVisible(true);
    setState(() => _open = room);
  }

  void _close() {
    _open?.setVisible(false);
    _open?.pause();
    setState(() => _open = null);
    _load(reset: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _generation++;
    if (_scope != null && _gateway is MessengerApi) {
      (_gateway as MessengerApi).cancelScope(_scope!);
    }
    _open?.setVisible(false);
    _open?.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final open = _open;
    return Scaffold(
      backgroundColor: ParentColors.parchment,
      appBar: AppBar(
        title: Text(
          open == null ? l10n.messengerListTitle : l10n.messengerTitle,
        ),
        backgroundColor: ParentColors.surface,
        foregroundColor: ParentColors.ink,
      ),
      body: open != null
          ? MessengerPanel(room: open, onClose: _close)
          : _list(l10n),
    );
  }

  Widget _list(AppLocalizations l10n) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error == 'forbidden') {
      return Center(child: Text(l10n.messengerForbidden));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.messengerUnavailable),
            TextButton(
              onPressed: () => _load(reset: true),
              child: Text(l10n.messengerRetry),
            ),
          ],
        ),
      );
    }
    if (_rows.isEmpty) return Center(child: Text(l10n.messengerListEmpty));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final row in _rows)
          Card(
            color: ParentColors.surface,
            child: ListTile(
              title: Text(row.title),
              subtitle: Text(
                [
                  messengerWhen(row.occurredAt),
                  if (row.participants.isNotEmpty) row.participants.join(', '),
                  if (row.preview.isNotEmpty) row.preview,
                ].where((part) => part.isNotEmpty).join('\n'),
              ),
              trailing: row.unread > 0
                  ? Text(l10n.messengerUnread(row.unread))
                  : null,
              onTap: () => _show(row),
            ),
          ),
        if (_cursor != null)
          TextButton(
            onPressed: () => _load(reset: false),
            child: Text(l10n.messengerListMore),
          ),
      ],
    );
  }
}
