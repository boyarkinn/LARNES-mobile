import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/trainers/audio/speech_bank.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

class ContentBankImageScope extends InheritedWidget {
  const ContentBankImageScope({
    super.key,
    required this.payload,
    required super.child,
  });
  final Map<String, dynamic>? payload;
  static Map? imageOf(BuildContext context, String slug) {
    final material = materialOf(context, slug);
    return material?['image'] is Map ? material!['image'] as Map : null;
  }

  static Map? materialOf(BuildContext context, String slug) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ContentBankImageScope>();
    final provenance = scope?.payload?['contentBank'];
    final materials = provenance is Map ? provenance['materials'] : null;
    if (materials is List) {
      for (final item in materials) {
        if (item is Map && item['materialId'] == slug) return item;
      }
    }
    return null;
  }

  @override
  bool updateShouldNotify(ContentBankImageScope oldWidget) =>
      oldWidget.payload != payload;
}

Future<void> playContentBankWord(BuildContext context, String slug) async {
  final audio = ContentBankImageScope.materialOf(context, slug)?['audio'];
  final key = audio is Map ? audio['semanticKey']?.toString() : null;
  final path = speechPlaybackPath(key);
  if (path != null) {
    await getSharedClipPlayer().play([path], playbackRate: 1);
  } else if (context.mounted) {
    final message = switch (Localizations.localeOf(context).languageCode) {
      'en' => 'Audio for this word is unavailable.',
      'ar' => 'صوت هذه الكلمة غير متاح.',
      _ => 'Озвучка этого слова недоступна.',
    };
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }
}

Future<void> cancelContentBankWordAudio() => getSharedClipPlayer().cancel();

/// The server grants one exact frozen version/file. No asset-name fallback or
/// arbitrary remote URL is accepted by the transport.
class ContentBankImage extends StatefulWidget {
  const ContentBankImage({
    super.key,
    required this.slug,
    this.fallback = const SizedBox.shrink(),
    this.height,
    this.semanticLabel,
  });
  final String slug;
  final Widget fallback;
  final double? height;
  final String? semanticLabel;
  @override
  State<ContentBankImage> createState() => _ContentBankImageState();
}

class _ContentBankImageState extends State<ContentBankImage> {
  String? _url;
  Future<Uint8List>? _bytes;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _read();
  }

  @override
  void didUpdateWidget(ContentBankImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _read();
  }

  void _read() {
    final descriptor = ContentBankImageScope.imageOf(context, widget.slug);
    final url = descriptor?['url']?.toString();
    if (url == _url) return;
    _url = url;
    _bytes = descriptor == null
        ? null
        : AuthScope.of(context).trainerContentBankApi.image(descriptor);
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes == null) return widget.fallback;
    return FutureBuilder<Uint8List>(
      key: ValueKey(_url),
      future: _bytes,
      builder: (context, snapshot) => snapshot.hasData
          ? Image.memory(
              snapshot.data!,
              height: widget.height,
              fit: BoxFit.contain,
              semanticLabel: widget.semanticLabel,
              errorBuilder: (_, _, _) => widget.fallback,
            )
          : widget.fallback,
    );
  }
}
