import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/features/auth/models/register_flow.dart';
import 'package:larnes_mobile/features/auth/screens/login_screen.dart';
import 'package:larnes_mobile/features/auth/screens/register_contact_screen.dart';
import 'package:larnes_mobile/features/auth/screens/register_otp_screen.dart';
import 'package:larnes_mobile/features/auth/screens/register_profile_screen.dart';
import 'package:larnes_mobile/features/auth/screens/register_type_screen.dart';
import 'package:larnes_mobile/features/auth/screens/splash_screen.dart';
import 'package:larnes_mobile/features/shell/home_placeholder_screen.dart';

GoRouter createAppRouter(AuthSession authSession) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => SplashScreen(authSession: authSession),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(authSession: authSession),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterTypeScreen(),
        routes: [
          GoRoute(
            path: ':type/contact',
            builder: (context, state) {
              final type = RegisterAccountType.fromSlug(state.pathParameters['type']);
              if (type == null) {
                return const RegisterTypeScreen();
              }
              return RegisterContactScreen(accountType: type);
            },
          ),
          GoRoute(
            path: ':type/otp',
            builder: (context, state) {
              final flow = state.extra;
              if (flow is! RegisterFlowData) {
                return const RegisterTypeScreen();
              }
              return RegisterOtpScreen(flow: flow);
            },
          ),
          GoRoute(
            path: ':type/profile',
            builder: (context, state) {
              final flow = state.extra;
              if (flow is! RegisterFlowData) {
                return const RegisterTypeScreen();
              }
              return RegisterProfileScreen(flow: flow);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => HomePlaceholderScreen(authSession: authSession),
      ),
    ],
  );
}
