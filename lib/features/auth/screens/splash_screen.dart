import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_text_theme.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/kiosk/kiosk_route_state.dart';
import 'package:larnes_mobile/core/routing/home_path_mapper.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.authSession,
    required this.kioskRouteState,
  });

  final AuthSession authSession;
  final KioskRouteState kioskRouteState;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      widget.authSession.bootstrap(),
      widget.kioskRouteState.refreshDeviceToken(),
    ]);
    if (!mounted) {
      return;
    }

    context.go(
      resolveSplashDestination(
        hasDeviceToken: widget.kioskRouteState.hasDeviceToken,
        isAuthenticated: widget.authSession.isAuthenticated,
        accountType: widget.authSession.user?.accountType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Theme(
      data: Theme.of(context).copyWith(textTheme: buildParentTextTheme()),
      child: ParentParchmentBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.appTitle,
                  style: GoogleFonts.fredoka(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.02 * 32,
                    color: ParentColors.shell,
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: ParentColors.shell,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
