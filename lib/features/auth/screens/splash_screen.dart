import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LARNES',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
