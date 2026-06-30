import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/app/router.dart';
import 'package:larnes_mobile/app/theme/larnes_theme.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';

class LarnesApp extends StatefulWidget {
  const LarnesApp({super.key});

  @override
  State<LarnesApp> createState() => _LarnesAppState();
}

class _LarnesAppState extends State<LarnesApp> {
  late final AuthSession _authSession;
  late final LocaleController _localeController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authSession = AuthSession();
    _localeController = LocaleController()..load();
    _router = createAppRouter(_authSession);
    _authSession.addListener(_onStateChanged);
    _localeController.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _authSession.removeListener(_onStateChanged);
    _localeController.removeListener(_onStateChanged);
    _router.dispose();
    _authSession.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LARNES',
      theme: buildLarnesTheme(),
      locale: _localeController.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
      builder: (context, child) {
        return LocaleScope(
          localeController: _localeController,
          child: AuthScope(
            authSession: _authSession,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
