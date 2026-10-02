import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class LessonCallDock extends StatelessWidget {
  const LessonCallDock({
    super.key,
    required this.audioOn,
    required this.callReady,
    required this.cameraNote,
    required this.canRetry,
    required this.closed,
    required this.connectFailed,
    required this.hearBlocked,
    required this.lost,
    required this.micNote,
    required this.onHear,
    required this.onLeave,
    required this.onRetry,
    required this.onToggleAudio,
    required this.onToggleVideo,
    required this.reconnecting,
    required this.videoOn,
  });

  final bool audioOn;
  final bool callReady;
  final String? cameraNote;
  final bool canRetry;
  final bool closed;
  final bool connectFailed;
  final bool hearBlocked;
  final bool lost;
  final String? micNote;
  final VoidCallback onHear;
  final VoidCallback onLeave;
  final VoidCallback onRetry;
  final VoidCallback onToggleAudio;
  final VoidCallback onToggleVideo;
  final bool reconnecting;
  final bool videoOn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final notes = <String>[
      if (connectFailed) l10n.parentLiveLessonCallFailed,
      if (closed) l10n.parentLiveLessonLinkClosed,
      if (lost) l10n.parentLiveLessonLinkLost,
      if (cameraNote != null) _deviceNote(l10n, video: true, block: cameraNote!),
      if (micNote != null) _deviceNote(l10n, video: false, block: micNote!),
    ];

    return Semantics(
      container: true,
      label: l10n.parentLiveLessonDockLabel,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: ParentColors.surface,
          border: Border(top: BorderSide(color: ParentColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                if (hearBlocked) ...[
                  _CallDockButton(
                    attention: false,
                    enabled: true,
                    icon: Icons.volume_off,
                    label: l10n.parentLiveLessonHear,
                    off: true,
                    onPressed: onHear,
                  ),
                  const SizedBox(width: 8),
                ],
                _CallDockButton(
                  attention: callReady && !videoOn,
                  enabled: callReady,
                  icon: videoOn ? Icons.videocam : Icons.videocam_off,
                  label: videoOn ? l10n.parentLiveLessonCameraOn : l10n.parentLiveLessonCameraOff,
                  off: !videoOn,
                  onPressed: onToggleVideo,
                ),
                const SizedBox(width: 8),
                _CallDockButton(
                  attention: callReady && !audioOn,
                  enabled: callReady,
                  icon: audioOn ? Icons.mic : Icons.mic_off,
                  label: audioOn ? l10n.parentLiveLessonMicOn : l10n.parentLiveLessonMicOff,
                  off: !audioOn,
                  onPressed: onToggleAudio,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (reconnecting)
                          Text(
                            l10n.parentLiveLessonLinkReconnecting,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF92400E),
                              fontSize: 14,
                              height: 1.25,
                            ),
                          ),
                        for (final note in notes)
                          Text(
                            note,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFB91C1C),
                              fontSize: 14,
                              height: 1.25,
                            ),
                          ),
                        if (lost || (connectFailed && canRetry))
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: ParentColors.ink,
                              minimumSize: const Size(0, 40),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              side: const BorderSide(color: Color(0xFFE8E7E4)),
                              textStyle: const TextStyle(fontSize: 14),
                            ),
                            onPressed: onRetry,
                            child: Text(l10n.parentLiveLessonLinkRetry),
                          ),
                      ],
                    ),
                  ),
                ),
                _CallDockButton(
                  attention: false,
                  enabled: true,
                  icon: Icons.call_end,
                  label: l10n.parentLiveLessonLeave,
                  off: true,
                  onPressed: onLeave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _deviceNote(AppLocalizations l10n, {required bool video, required String block}) {
    if (video) {
      return switch (block) {
        'denied' => l10n.parentLiveLessonCameraDenied,
        'missing' => l10n.parentLiveLessonCameraMissing,
        _ => l10n.parentLiveLessonCameraAskAgain,
      };
    }
    return switch (block) {
      'denied' => l10n.parentLiveLessonMicDenied,
      'missing' => l10n.parentLiveLessonMicMissing,
      _ => l10n.parentLiveLessonMicAskAgain,
    };
  }
}

class _CallDockButton extends StatefulWidget {
  const _CallDockButton({
    required this.attention,
    required this.enabled,
    required this.icon,
    required this.label,
    required this.off,
    required this.onPressed,
  });

  final bool attention;
  final bool enabled;
  final IconData icon;
  final String label;
  final bool off;
  final VoidCallback onPressed;

  @override
  State<_CallDockButton> createState() => _CallDockButtonState();
}

class _CallDockButtonState extends State<_CallDockButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ping = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  bool _played = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPing(restart: false);
  }

  @override
  void didUpdateWidget(covariant _CallDockButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.attention != oldWidget.attention) {
      _syncPing(restart: widget.attention);
    }
  }

  void _syncPing({required bool restart}) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (!widget.attention || reduce) {
      _ping.stop();
      _ping.value = 0;
      if (!widget.attention) {
        _played = false;
      }
      return;
    }
    if (_played && !restart) {
      return;
    }
    _played = true;
    _ping.repeat(count: 3);
  }

  @override
  void dispose() {
    _ping.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final off = widget.off;
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      child: Opacity(
        opacity: widget.enabled ? 1 : 0.5,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Material(
                color: off ? const Color(0xFFDC2626) : ParentColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: off ? Colors.transparent : ParentColors.line),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: widget.enabled ? widget.onPressed : null,
                  child: Icon(
                    widget.icon,
                    color: off ? Colors.white : ParentColors.ink,
                    size: 24,
                  ),
                ),
              ),
              if (widget.attention)
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _ping,
                    builder: (context, child) {
                      if (!_ping.isAnimating && _ping.value == 0) {
                        return const SizedBox.shrink();
                      }
                      final t = Curves.easeOut.transform(_ping.value);
                      return Opacity(
                        opacity: 0.85 * (1 - t),
                        child: Transform.scale(
                          scale: 1 + 0.6 * t,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              border: Border.fromBorderSide(
                                BorderSide(color: Color(0xFFDC2626), width: 3),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
