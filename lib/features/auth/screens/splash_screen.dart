import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/routing/home_path_mapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.authSession});

  final AuthSession authSession;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await widget.authSession.bootstrap();
    if (!mounted) {
      return;
    }
    if (widget.authSession.isAuthenticated) {
      final accountType = widget.authSession.user?.accountType;
      context.go(mapHomePathToMobile(accountType == 'parent' ? '/parent' : '/home'));
    } else {
      context.go('/login');
    }
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
