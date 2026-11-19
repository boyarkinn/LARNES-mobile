import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Offline DSP only. The view receives verified local MP3 bytes, decodes them
/// and returns PCM. Audio is played by the native player after preparation.
class TopicChainSpeechRenderer {
  static const _asset = 'assets/call/topic-chain-speech.js';
  static const _chunkBytes = 48 * 1024;
  static const _maxInputBytes = 8 * 1024 * 1024;
  static const _maxPcmBytes = 44_100 * 2 * 31;

  static bool get supported => Platform.isAndroid || Platform.isIOS;

  HeadlessInAppWebView? _view;
  InAppWebViewController? _controller;
  bool _closed = false;
  int _viewGeneration = 0;

  Future<Uint8List> render(String path, Duration budget) async {
    final elapsed = Stopwatch()..start();
    final file = File(path);
    final size = await file.length();
    if (size < 1 || size > _maxInputBytes) {
      throw const FormatException('Invalid catalog speech size');
    }

    try {
      final remaining = budget - elapsed.elapsed;
      final controller = await _open().timeout(remaining);

      Future<Object?> invoke(String body, [Map<String, dynamic>? args]) async {
        _checkOpen();
        final left = budget - elapsed.elapsed;
        if (left <= Duration.zero) throw TimeoutException('Speech rendering');
        final result = await controller
            .callAsyncJavaScript(functionBody: body, arguments: args ?? {})
            .timeout(left);
        if (result == null || result.error != null) {
          throw const FormatException('Unable to prepare speech');
        }
        return result.value;
      }

      await invoke('LarnesTopicChainSpeech.reset(); return true;');
      final reader = await file.open();
      try {
        var offset = 0;
        while (offset < size) {
          final chunk = await reader.read(_chunkBytes);
          if (chunk.isEmpty || offset + chunk.length > size) {
            throw const FormatException('Catalog speech changed while reading');
          }
          offset += chunk.length;
          await invoke('LarnesTopicChainSpeech.append(chunk); return true;', {
            'chunk': base64Encode(chunk),
          });
        }
      } finally {
        await reader.close();
      }
      final length = await invoke(
        'return await LarnesTopicChainSpeech.render();',
      );
      if (length is! num ||
          length != length.toInt() ||
          length < 2 ||
          length > _maxPcmBytes ||
          length.toInt().isOdd) {
        throw const FormatException('Invalid prepared speech size');
      }

      final pcm = Uint8List(length.toInt());
      for (var offset = 0; offset < pcm.length;) {
        final encoded = await invoke(
          'return LarnesTopicChainSpeech.readChunk(offset);',
          {'offset': offset},
        );
        if (encoded is! String) {
          throw const FormatException('Missing PCM chunk');
        }
        final chunk = base64Decode(encoded);
        final expected = (pcm.length - offset).clamp(0, _chunkBytes);
        if (chunk.length != expected) {
          throw const FormatException('Invalid PCM chunk');
        }
        pcm.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }
      await invoke('LarnesTopicChainSpeech.reset(); return true;');
      return pcm;
    } catch (_) {
      // A timed-out JS decode can finish later. It must not populate the next
      // request's buffer, so restart the offline view on a retry.
      await _closeView();
      rethrow;
    }
  }

  Future<InAppWebViewController> _open() async {
    _checkOpen();
    final cached = _controller;
    if (cached != null) return cached;
    final generation = _viewGeneration;
    final bundle = await rootBundle.loadString(_asset);
    _checkOpen();
    if (generation != _viewGeneration) throw StateError('Speech view changed');
    final ready = Completer<InAppWebViewController>();
    final view = HeadlessInAppWebView(
      initialData: InAppWebViewInitialData(
        data: '''<!doctype html><meta charset="utf-8">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'">''',
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        javaScriptCanOpenWindowsAutomatically: false,
        allowFileAccess: false,
        allowContentAccess: false,
        blockNetworkLoads: true,
        isInspectable: false,
      ),
      onLoadStop: (controller, _) {
        if (!ready.isCompleted) ready.complete(controller);
      },
    );
    _view = view;
    await view.run();
    final controller = await ready.future.timeout(const Duration(seconds: 5));
    if (!identical(_view, view)) throw StateError('Speech view changed');
    await controller.evaluateJavascript(source: bundle);
    _checkOpen();
    if (!identical(_view, view)) throw StateError('Speech view changed');
    return _controller = controller;
  }

  void _checkOpen() {
    if (_closed) throw StateError('Speech renderer closed');
  }

  Future<void> _closeView() async {
    _viewGeneration++;
    final view = _view;
    _view = null;
    _controller = null;
    try {
      await view?.dispose().timeout(const Duration(seconds: 2));
    } catch (_) {
      // View teardown must not suppress the preparation error.
    }
  }

  Future<void> dispose() async {
    _closed = true;
    await _closeView();
  }
}
