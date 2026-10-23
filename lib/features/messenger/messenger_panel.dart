import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/messenger/messenger_room.dart';
import 'package:larnes_mobile/features/messenger/messenger_wire.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class MessengerPanel extends StatefulWidget {
  const MessengerPanel({super.key, required this.onClose, required this.room});

  final VoidCallback onClose;
  final MessengerRoom room;

  @override
  State<MessengerPanel> createState() => _MessengerPanelState();
}

class _MessengerPanelState extends State<MessengerPanel> {
  final _list = ScrollController();
  final _draft = TextEditingController();
  bool _earlier = false;

  @override
  void initState() {
    super.initState();
    _draft.text = widget.room.draft;
    widget.room.addListener(_onRoom);
    WidgetsBinding.instance.addPostFrameCallback((_) => _stick());
  }

  @override
  void didUpdateWidget(covariant MessengerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.room != widget.room) {
      oldWidget.room.removeListener(_onRoom);
      widget.room.addListener(_onRoom);
      _draft.text = widget.room.draft;
    }
  }

  @override
  void dispose() {
    widget.room.removeListener(_onRoom);
    _list.dispose();
    _draft.dispose();
    super.dispose();
  }

  void _onRoom() {
    if (!mounted) return;
    if (_draft.text != widget.room.draft) {
      _draft.value = TextEditingValue(
        text: widget.room.draft,
        selection: TextSelection.collapsed(offset: widget.room.draft.length),
      );
    }
    setState(() {});
    if (widget.room.stuck) _stick();
  }

  void _stick() {
    if (!_list.hasClients) return;
    _list.jumpTo(_list.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final room = widget.room;
    final send = room.capabilities?.send == true;
    final readOnly = room.capabilities?.read == true && !send;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Material(
      color: ParentColors.surface,
      child: Padding(
        padding: EdgeInsets.only(bottom: inset),
        child: Column(
          children: [
            _header(l10n),
            Expanded(child: _messages(l10n, room)),
            if (room.commandNotice != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  room.commandNotice == 'reported'
                      ? l10n.messengerReported
                      : l10n.messengerRemoved,
                ),
              ),
            if (room.errorCode != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Text(
                  _notice(l10n, room.errorCode!),
                  style: const TextStyle(color: Color(0xFFB42318)),
                ),
              ),
            if (readOnly)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(l10n.messengerArchive),
              ),
            if (room.capabilities == null && room.errorCode == null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(l10n.messengerLoading),
              ),
            if (send) _composer(l10n, room),
            if (room.errorCode != null &&
                room.errorCode != 'forbidden' &&
                !send)
              TextButton(
                onPressed: room.resume,
                child: Text(l10n.messengerRetry),
              ),
          ],
        ),
      ),
    );
  }

  Widget _header(AppLocalizations l10n) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ParentColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                l10n.messengerTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.messengerClose,
            onPressed: widget.onClose,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _messages(AppLocalizations l10n, MessengerRoom room) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final metrics = notification.metrics;
        final atEnd = metrics.maxScrollExtent - metrics.pixels <= 48;
        room.setStuck(atEnd);
        return false;
      },
      child: ListView(
        controller: _list,
        padding: const EdgeInsets.all(12),
        children: [
          if (room.earlier != null)
            TextButton(
              onPressed: _earlier
                  ? null
                  : () async {
                      setState(() => _earlier = true);
                      await room.loadEarlier();
                      if (mounted) setState(() => _earlier = false);
                    },
              child: Text(l10n.messengerEarlier),
            ),
          if (room.entries.isEmpty && room.capabilities?.read == true)
            Text(l10n.messengerEmpty),
          for (final entry in room.entries)
            if (entry.access)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  entry.action ?? '',
                  style: const TextStyle(
                    color: ParentColors.inkMuted,
                    fontSize: 12,
                  ),
                ),
              )
            else
              _message(l10n, room, entry),
          if (!room.stuck)
            TextButton(
              onPressed: () {
                room.setStuck(true);
                _stick();
              },
              child: Text(l10n.messengerNewer),
            ),
        ],
      ),
    );
  }

  Widget _message(
    AppLocalizations l10n,
    MessengerRoom room,
    MessengerEntry entry,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ParentColors.parchment,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.author,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          if (entry.redacted)
            Text(l10n.messengerRemoved)
          else if (entry.body.isNotEmpty)
            Text(entry.body),
          for (final id in entry.fileIds)
            Row(
              children: [
                TextButton(
                  onPressed: () => room.openFile(id),
                  child: Text(l10n.messengerFile),
                ),
                TextButton(
                  onPressed: () => room.shareFile(id),
                  child: Text(l10n.messengerShare),
                ),
              ],
            ),
          if (!entry.redacted &&
              room.capabilities?.read == true &&
              entry.messageId != null)
            TextButton(
              onPressed: () => room.command('report', entry),
              child: Text(l10n.messengerReport),
            ),
          if (!entry.redacted &&
              room.capabilities?.send == true &&
              entry.authorParticipantId ==
                  room.capabilities?.authorParticipantId &&
              entry.authorParticipantId != null)
            TextButton(
              onPressed: () => room.command('redact', entry),
              child: Text(l10n.messengerRemoveOwn),
            ),
          if (!entry.redacted &&
              room.capabilities?.send == true &&
              entry.messageId != null)
            TextButton(
              onPressed: () => room.setReply(entry.messageId),
              child: Text(l10n.messengerReply),
            ),
        ],
      ),
    );
  }

  Widget _composer(AppLocalizations l10n, MessengerRoom room) {
    final blocked =
        room.sending || room.uploads.any((file) => file.status != 'ready');
    final empty = _draft.text.trim().isEmpty && room.uploads.isEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (room.replyTo != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.messengerReply,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () => room.setReply(null),
                  child: Text(l10n.messengerCancelReply),
                ),
              ],
            ),
          for (final file in room.uploads)
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${file.name} · ${_fileStatus(l10n, file.status)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: l10n.messengerRemoveFile,
                  onPressed: room.sending
                      ? null
                      : () => room.cancelUpload(file.id),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          TextField(
            controller: _draft,
            minLines: 1,
            maxLines: 5,
            maxLength: 4000,
            enabled: !room.sending,
            decoration: InputDecoration(
              hintText: l10n.messengerPlaceholder,
              counterText: '',
            ),
            onChanged: room.setDraft,
          ),
          Row(
            children: [
              TextButton(
                onPressed:
                    room.sending || room.uploads.length >= messengerFileLimit
                    ? null
                    : () async {
                        await room.pickAndUpload();
                      },
                child: Text(l10n.messengerAttach),
              ),
              const Spacer(),
              FilledButton(
                onPressed: blocked || empty ? null : room.send,
                child: Text(
                  room.sending
                      ? l10n.messengerSaving
                      : room.errorCode != null
                      ? l10n.messengerRetry
                      : l10n.messengerSend,
                ),
              ),
            ],
          ),
          Text(
            l10n.messengerFileLimit,
            style: const TextStyle(color: ParentColors.inkMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _fileStatus(AppLocalizations l10n, String status) {
    return switch (status) {
      'ready' => l10n.messengerFileReady,
      'error' || 'rejected' => l10n.messengerFileError,
      'uploading' => l10n.messengerFileUploading,
      _ => l10n.messengerFileChecking,
    };
  }

  String _notice(AppLocalizations l10n, String code) {
    return switch (code) {
      'forbidden' => l10n.messengerForbidden,
      'closed' => l10n.messengerClosed,
      'conflict' => l10n.messengerConflict,
      'rate' => l10n.messengerRate,
      'file' => l10n.messengerFileError,
      _ => l10n.messengerUnavailable,
    };
  }
}
