import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// QR scanner for kiosk scan mode. Calls [onScan] with decoded token payload.
class KioskQrScanner extends StatefulWidget {
  const KioskQrScanner({
    super.key,
    required this.onScan,
    this.externalError,
    this.mockScanEnabled = false,
    this.mockScanToken = 'mock-qr-token',
    this.previewForTest = false,
  });

  final Future<void> Function(String token) onScan;
  final String? externalError;

  /// When true, renders a test button instead of the camera (CI/widget tests).
  final bool mockScanEnabled;
  final String mockScanToken;

  /// When true, renders preview chrome (incl. flip button) without a real camera.
  @visibleForTesting
  final bool previewForTest;

  @override
  State<KioskQrScanner> createState() => _KioskQrScannerState();
}

class _KioskQrScannerState extends State<KioskQrScanner> {
  MobileScannerController? _controller;

  bool _handling = false;
  bool _processing = false;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    if (widget.mockScanEnabled || widget.previewForTest) {
      return;
    }

    // Do not create the controller as a field initializer — MobileScanner must
    // attach before start(); release builds are stricter about that ordering.
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  Future<void> _handleToken(String token) async {
    final controller = _controller;
    if (_handling || token.trim().isEmpty) {
      return;
    }

    if (!widget.mockScanEnabled && controller == null) {
      return;
    }

    setState(() {
      _handling = true;
      _processing = true;
    });

    try {
      if (controller != null) {
        await controller.stop();
      }
      await widget.onScan(token.trim());
    } finally {
      if (mounted) {
        setState(() {
          _handling = false;
          _processing = false;
        });

        if (!widget.mockScanEnabled && controller != null) {
          await controller.start();
        }
      }
    }
  }

  Future<void> _switchCamera() async {
    final controller = _controller;
    if (controller == null || _handling || _processing) {
      return;
    }

    await controller.switchCamera();
  }

  Future<void> _retryCamera() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    setState(() => _permissionDenied = false);

    try {
      await controller.start();
    } on MobileScannerException catch (error) {
      if (!mounted) {
        return;
      }

      if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
        setState(() => _permissionDenied = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (widget.mockScanEnabled) {
      return Column(
        children: [
          OutlinedButton(
            onPressed: _handling
                ? null
                : () {
                    _handleToken(widget.mockScanToken);
                  },
            child: Text(l10n.kioskScanEnableCamera),
          ),
          if (widget.externalError != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.externalError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      );
    }

    final controller = _controller;

    return Column(
      children: [
        if (_permissionDenied)
          _CameraPermissionCard(
            message: l10n.kioskScanCameraDenied,
            hint: l10n.kioskScanCameraDeniedHint,
            actionLabel: l10n.kioskScanRetryCamera,
            onPressed: _retryCamera,
          )
        else if (controller != null || widget.previewForTest)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.previewForTest)
                    const ColoredBox(color: Color(0x14000000))
                  else
                    MobileScanner(
                      controller: controller!,
                      onDetect: (capture) async {
                        if (_handling) {
                          return;
                        }

                        for (final barcode in capture.barcodes) {
                          final value = barcode.rawValue;
                          if (value != null && value.isNotEmpty) {
                            await _handleToken(value);
                            break;
                          }
                        }
                      },
                      errorBuilder: (context, error) {
                        if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() => _permissionDenied = true);
                            }
                          });
                        }

                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              l10n.kioskScanErrorCamera,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                      placeholderBuilder: (context) {
                        return Center(
                          child: Text(l10n.kioskScanStartingCamera),
                        );
                      },
                    ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: _FlipCameraButton(
                      label: l10n.kioskScanSwitchCamera,
                      onPressed: (_handling || _processing)
                          ? null
                          : () {
                              unawaited(_switchCamera());
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_processing) ...[
          const SizedBox(height: 12),
          Text(
            l10n.kioskScanProcessing,
            textAlign: TextAlign.center,
          ),
        ],
        if (widget.externalError != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.externalError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _FlipCameraButton extends StatelessWidget {
  const _FlipCameraButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      style: IconButton.styleFrom(
        backgroundColor: const Color(0x8C111827),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0x59111827),
        disabledForegroundColor: Colors.white70,
      ),
      tooltip: label,
      onPressed: onPressed,
      icon: const Icon(Icons.cameraswitch),
    );
  }
}

class _CameraPermissionCard extends StatelessWidget {
  const _CameraPermissionCard({
    required this.message,
    required this.hint,
    required this.actionLabel,
    required this.onPressed,
  });

  final String message;
  final String hint;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onPressed,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
