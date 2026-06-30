import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:larnes_mobile/app/theme/larnes_theme.dart';
import 'package:larnes_mobile/core/config/turnstile_url.dart';

class TurnstileWidget extends StatefulWidget {
  const TurnstileWidget({
    super.key,
    required this.pageUrl,
    this.onTokenChanged,
    this.resetKey = 0,
  });

  final String pageUrl;
  final ValueChanged<String?>? onTokenChanged;
  final int resetKey;

  @override
  State<TurnstileWidget> createState() => _TurnstileWidgetState();
}

class _TurnstileWidgetState extends State<TurnstileWidget> {
  WebViewController? _controller;
  bool _isBooting = true;
  bool _isVerifying = false;
  bool _challengeRevealed = false;
  String? _error;
  bool _captchaResolved = false;
  int _loadGeneration = 0;
  Timer? _bootTimeoutTimer;
  Timer? _verifyTimeoutTimer;

  static const _cardHeight = 72.0;
  static const _webviewSlotHeight = 76.0;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void dispose() {
    _cancelPendingTimers();
    super.dispose();
  }

  void _cancelPendingTimers() {
    _bootTimeoutTimer?.cancel();
    _verifyTimeoutTimer?.cancel();
    _bootTimeoutTimer = null;
    _verifyTimeoutTimer = null;
  }

  void _beginNewSession() {
    _loadGeneration += 1;
    _cancelPendingTimers();
  }

  @override
  void didUpdateWidget(covariant TurnstileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageUrl != widget.pageUrl || oldWidget.resetKey != widget.resetKey) {
      widget.onTokenChanged?.call(null);
      setState(() {
        _isBooting = true;
        _isVerifying = false;
        _challengeRevealed = false;
        _error = null;
        _captchaResolved = false;
      });
      _loadPage();
    }
  }

  Future<void> _initController() async {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'TurnstileBridge',
        onMessageReceived: (message) => _handleTurnstilePath(message.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _onPageFinished(),
          onWebResourceError: (error) {
            if (error.isForMainFrame != true) {
              return;
            }
            final failedUrl = error.url ?? '';
            if (failedUrl.contains('challenges.cloudflare.com')) {
              return;
            }
            if (!mounted || _captchaResolved) {
              return;
            }
            setState(() {
              _isBooting = false;
              _isVerifying = false;
              _error = 'Не удалось загрузить проверку';
            });
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri?.scheme == 'larnes-turnstile') {
              _handleTurnstilePath('${uri!.host}${uri.hasQuery ? '?${uri.query}' : ''}');
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    if (!kIsWeb && Platform.isAndroid) {
      final platform = controller.platform;
      if (platform is AndroidWebViewController) {
        platform.setMediaPlaybackRequiresUserGesture(false);
        await AndroidWebViewCookieManager(
          const PlatformWebViewCookieManagerCreationParams(),
        ).setAcceptThirdPartyCookies(platform, true);
      }
    }

    if (!mounted) {
      return;
    }

    setState(() => _controller = controller);
    await _loadPage();
  }

  Future<void> _onPageFinished() async {
    _bootTimeoutTimer?.cancel();
    final generation = _loadGeneration;
    _bootTimeoutTimer = Timer(const Duration(seconds: 15), () {
      if (!mounted || _captchaResolved || !_isBooting || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _isBooting = false;
        _error = 'Не удалось загрузить проверку. Потяните экран вниз и попробуйте снова.';
      });
    });
  }

  void _handleTurnstilePath(String path) {
    final uri = Uri.tryParse('larnes-turnstile://$path');
    if (uri == null) {
      return;
    }

    switch (uri.host) {
      case 'ready':
        if (mounted) {
          setState(() => _isBooting = false);
        }
      case 'interactive':
        _verifyTimeoutTimer?.cancel();
        if (mounted) {
          setState(() {
            _challengeRevealed = true;
            _isVerifying = false;
          });
        }
      case 'callback':
        _cancelPendingTimers();
        final token = uri.queryParameters['token'];
        widget.onTokenChanged?.call(
          token != null && token.isNotEmpty ? token : null,
        );
        if (mounted) {
          setState(() {
            _captchaResolved = true;
            _challengeRevealed = false;
            _isVerifying = false;
            _error = null;
          });
        }
      case 'expired':
        widget.onTokenChanged?.call(null);
        if (mounted) {
          setState(() {
            _captchaResolved = false;
            _challengeRevealed = false;
            _isVerifying = false;
            _isBooting = false;
            _error = 'Проверка истекла. Нажмите ещё раз.';
          });
        }
      case 'error':
        widget.onTokenChanged?.call(null);
        if (mounted) {
          final reason = uri.queryParameters['reason'];
          setState(() {
            _captchaResolved = false;
            _challengeRevealed = false;
            _isVerifying = false;
            _isBooting = reason == 'init-timeout';
            _error = reason == 'init-timeout'
                ? 'Не удалось загрузить проверку. Нажмите ещё раз.'
                : 'Проверка не пройдена. Нажмите ещё раз.';
          });
        }
    }
  }

  Future<void> _loadPage() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    _beginNewSession();

    final base = normalizeTurnstilePageUrl(widget.pageUrl);
    final uri = Uri.parse(base).replace(
      queryParameters: {
        ...Uri.parse(base).queryParameters,
        '_t': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    await controller.loadRequest(uri);
  }

  Future<void> _startVerification() async {
    if (_captchaResolved || _isBooting || _isVerifying) {
      return;
    }

    final controller = _controller;
    if (controller == null) {
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      final started = await controller.runJavaScriptReturningResult(
        'typeof window.startTurnstileChallenge === "function" && window.startTurnstileChallenge()',
      );
      final didStart = started == true || started == 'true';
      if (!didStart) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isVerifying = false;
          _error = 'Проверка ещё загружается. Подождите пару секунд.';
        });
        return;
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isVerifying = false;
        _error = 'Не удалось запустить проверку';
      });
      return;
    }

    _verifyTimeoutTimer?.cancel();
    final generation = _loadGeneration;
    _verifyTimeoutTimer = Timer(const Duration(seconds: 20), () {
      if (!mounted ||
          _captchaResolved ||
          _challengeRevealed ||
          generation != _loadGeneration) {
        return;
      }
      setState(() {
        _isVerifying = false;
        _error = 'Проверка не завершилась. Нажмите ещё раз.';
      });
    });
  }

  BoxDecoration _cardDecoration({
    required Color borderColor,
    Color? backgroundColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildStatusIcon({
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildWebViewSlot(
    WebViewController controller, {
    required bool visible,
    double? height,
  }) {
    return SizedBox(
      height: height ?? _webviewSlotHeight,
      width: double.infinity,
      child: Opacity(
        opacity: visible ? 1 : 0,
        child: IgnorePointer(
          ignoring: !visible,
          child: WebViewWidget(controller: controller),
        ),
      ),
    );
  }

  Widget _buildResolvedCard() {
    return Container(
      height: _cardHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _cardDecoration(
        borderColor: LarnesColors.teal.withValues(alpha: 0.55),
        backgroundColor: LarnesColors.teal.withValues(alpha: 0.06),
      ),
      child: Row(
        children: [
          _buildStatusIcon(
            icon: Icons.verified_rounded,
            color: LarnesColors.teal,
            background: LarnesColors.teal.withValues(alpha: 0.18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Проверка пройдена',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: LarnesColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Можно продолжить регистрацию',
                  style: TextStyle(
                    fontSize: 12,
                    color: LarnesColors.textSecondary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            color: LarnesColors.teal.withValues(alpha: 0.85),
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCard() {
    final canTap = !_isBooting && !_isVerifying;
    final subtitle = _isBooting
        ? 'Подготовка...'
        : _isVerifying
            ? 'Проверка...'
            : 'Нажмите для проверки';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canTap ? _startVerification : null,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: _cardHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: _cardDecoration(borderColor: LarnesColors.border),
          child: Row(
            children: [
              _buildStatusIcon(
                icon: Icons.shield_outlined,
                color: LarnesColors.coral,
                background: LarnesColors.coral.withValues(alpha: 0.12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Защита от ботов',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: LarnesColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: LarnesColors.textSecondary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isBooting || _isVerifying)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: LarnesColors.coral,
                  ),
                )
              else
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: LarnesColors.textSecondary.withValues(alpha: 0.7),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChallengePanel(WebViewController controller) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: _cardDecoration(
        borderColor: LarnesColors.indigo.withValues(alpha: 0.4),
        backgroundColor: Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _buildWebViewSlot(controller, visible: true),
      ),
    );
  }

  Widget _buildChallengeSlot() {
    final controller = _controller;

    if (_challengeRevealed && controller != null) {
      return _buildChallengePanel(controller);
    }

    return SizedBox(
      height: _cardHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null)
            _buildWebViewSlot(controller, visible: false, height: 8),
          _buildInviteCard(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_captchaResolved) _buildResolvedCard() else _buildChallengeSlot(),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
