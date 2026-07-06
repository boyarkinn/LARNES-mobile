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
  });

  final Future<void> Function(String token) onScan;
  final String? externalError;

  /// When true, renders a test button instead of the camera (CI/widget tests).
  final bool mockScanEnabled;
  final String mockScanToken;

  @override
  State<KioskQrScanner> createState() => _KioskQrScannerState();
}

class _KioskQrScannerState extends State<KioskQrScanner> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _handling = false;
  bool _processing = false;
  bool _permissionDenied = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleToken(String token) async {
    if (_handling || token.trim().isEmpty) {
      return;
    }

    setState(() {
      _handling = true;
      _processing = true;
    });

    try {
      await _controller.stop();
      await widget.onScan(token.trim());
    } finally {
      if (mounted) {
        setState(() {
          _handling = false;
          _processing = false;
        });

        if (!widget.mockScanEnabled) {
          await _controller.start();
        }
      }
    }
  }

  Future<void> _retryCamera() async {
    setState(() => _permissionDenied = false);
    await _controller.start();
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

    return Column(
      children: [
        if (_permissionDenied)
          _CameraPermissionCard(
            message: l10n.kioskScanCameraDenied,
            hint: l10n.kioskScanCameraDeniedHint,
            actionLabel: l10n.kioskScanRetryCamera,
            onPressed: _retryCamera,
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: MobileScanner(
                controller: _controller,
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
