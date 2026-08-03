import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/app/theme/parent_text_theme.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/kiosk/kiosk_route_state.dart';
import 'package:larnes_mobile/core/routing/home_path_mapper.dart';

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
        familySetupComplete: widget.authSession.familySetupComplete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(textTheme: buildParentTextTheme()),
      child: ParentParchmentBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/brand/logo-horizontal-blue.svg',
                  width: 184,
                  semanticsLabel: 'LARNES',
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
