import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/app/router.dart';
import 'package:larnes_mobile/app/theme/larnes_theme.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';

class LarnesApp extends StatefulWidget {
  const LarnesApp({super.key});

  @override
  State<LarnesApp> createState() => _LarnesAppState();
}

class _LarnesAppState extends State<LarnesApp> {
  late final AuthSession _authSession;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authSession = AuthSession();
    _router = createAppRouter(_authSession);
  }

  @override
  void dispose() {
    _router.dispose();
    _authSession.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LARNES',
      theme: buildLarnesTheme(),
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
      builder: (context, child) {
        return AuthScope(
          authSession: _authSession,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
