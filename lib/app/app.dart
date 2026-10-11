import 'dart:async';
import 'package:larnes_mobile/core/time/user_time_zone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/app/router.dart';
import 'package:larnes_mobile/app/theme/larnes_theme.dart';
import 'package:larnes_mobile/core/app_update/app_update_controller.dart';
import 'package:larnes_mobile/core/app_update/app_update_scope.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/deep_links/invite_deep_link.dart';
import 'package:larnes_mobile/core/kiosk/kiosk_route_state.dart';
import 'package:larnes_mobile/core/kiosk/kiosk_scope.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';

class LarnesApp extends StatefulWidget {
  const LarnesApp({super.key});

  @override
  State<LarnesApp> createState() => _LarnesAppState();
}

class _LarnesAppState extends State<LarnesApp> with WidgetsBindingObserver {
  Timer? _timeTimer;
  String _day = UserTimeZone.dayKey();
  String? _zone = UserTimeZone.effectiveZone;
  bool _checkingTime = false;

  Future<void> _checkTime({bool resumed = false}) async {
    if (_checkingTime) return;
    _checkingTime = true;
    try {
      await UserTimeZone.refreshDeviceZone();
      if (!mounted) return;
      final day = UserTimeZone.dayKey();
      final zone = UserTimeZone.effectiveZone;
      if (resumed || day != _day || zone != _zone) {
        _day = day;
        _zone = zone;
        if (_authSession.isAuthenticated) {
          await _authSession.refreshUser();
          _authSession.notifyParentDataChanged();
        }
        if (mounted) setState(() {});
      }
    } finally {
      _checkingTime = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkTime(resumed: true));
    }
  }

  late final AuthSession _authSession;
  late final KioskRouteState _kioskRouteState;
  late final LocaleController _localeController;
  late final AppUpdateController _appUpdateController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timeTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(_checkTime()),
    );
    _authSession = AuthSession();
    _kioskRouteState = KioskRouteState();
    _localeController = LocaleController()..load();
    _appUpdateController = AppUpdateController();
    _router = createAppRouter(
      authSession: _authSession,
      kioskRouteState: _kioskRouteState,
    );
    _authSession.addListener(_onStateChanged);
    _kioskRouteState.addListener(_onStateChanged);
    _localeController.addListener(_onStateChanged);
    _kioskRouteState.refreshDeviceToken();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timeTimer?.cancel();
    _authSession.removeListener(_onStateChanged);
    _kioskRouteState.removeListener(_onStateChanged);
    _localeController.removeListener(_onStateChanged);
    _appUpdateController.dispose();
    _router.dispose();
    _authSession.dispose();
    _kioskRouteState.dispose();
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
        return AppUpdateScope(
          controller: _appUpdateController,
          child: AppUpdateHost(
            child: InviteDeepLinkBinder(
              router: _router,
              child: LocaleScope(
                localeController: _localeController,
                child: AuthScope(
                  authSession: _authSession,
                  child: KioskScope(
                    kioskRouteState: _kioskRouteState,
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
