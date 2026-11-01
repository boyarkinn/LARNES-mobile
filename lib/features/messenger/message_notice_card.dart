import 'package:flutter/material.dart';

/// The same avatar/name/preview composition as the shared lesson notification.
class MessageNoticeCard extends StatelessWidget {
  const MessageNoticeCard({
    super.key,
    required this.author,
    required this.text,
    required this.closeLabel,
    required this.onOpen,
    required this.onClose,
  });
  final String author, text, closeLabel;
  final VoidCallback onOpen, onClose;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = Color(dark ? 0xFFEEF1F5 : 0xFF171B24);
    final muted = Color(dark ? 0xFFA6AEBB : 0xFF596170);
    final words = author
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    final initials = words.isEmpty
        ? '?'
        : '${words.first.characters.first}${words.length > 1 ? words.last.characters.first : ''}'
              .toUpperCase();
    return Material(
      color: Color(dark ? 0xFF1B1F26 : 0xFFFFFFFF),
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Color(dark ? 0xFF333A45 : 0xFFDFE3E9)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 10, 38, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ExcludeSemantics(
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFF4679B8),
                      foregroundColor: Colors.white,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ink,
                            fontSize: 17,
                            height: 24 / 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: muted,
                            fontSize: 16,
                            height: 24 / 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            end: 3,
            top: 3,
            child: IconButton(
              tooltip: closeLabel,
              color: muted,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              padding: const EdgeInsets.all(6),
              alignment: Alignment.center,
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
