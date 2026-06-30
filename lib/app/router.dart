import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/routing/home_path_mapper.dart';
import 'package:larnes_mobile/features/auth/models/register_flow.dart';
import 'package:larnes_mobile/features/auth/screens/login_screen.dart';
import 'package:larnes_mobile/features/auth/screens/register_contact_screen.dart';
import 'package:larnes_mobile/features/auth/screens/register_otp_screen.dart';
import 'package:larnes_mobile/features/auth/screens/register_profile_screen.dart';
import 'package:larnes_mobile/features/auth/screens/register_type_screen.dart';
import 'package:larnes_mobile/features/auth/screens/splash_screen.dart';
import 'package:larnes_mobile/features/parent/screens/add_child_screen.dart';
import 'package:larnes_mobile/features/parent/screens/account/account_child_detail_screen.dart';
import 'package:larnes_mobile/features/parent/screens/account/account_children_screen.dart';
import 'package:larnes_mobile/features/parent/screens/account/account_city_screen.dart';
import 'package:larnes_mobile/features/parent/screens/account/account_date_of_birth_screen.dart';
import 'package:larnes_mobile/features/parent/screens/account/account_edit_child_screen.dart';
import 'package:larnes_mobile/features/parent/screens/account/account_hub_screen.dart';
import 'package:larnes_mobile/features/parent/screens/account/account_login_screen.dart';
import 'package:larnes_mobile/features/parent/screens/account/account_password_screen.dart';
import 'package:larnes_mobile/features/parent/screens/account/account_profile_screen.dart';
import 'package:larnes_mobile/features/parent/screens/child_picker_screen.dart';
import 'package:larnes_mobile/features/parent/screens/homework_list_screen.dart';
import 'package:larnes_mobile/features/parent/screens/study_hub_screen.dart';
import 'package:larnes_mobile/features/shell/home_placeholder_screen.dart';

GoRouter createAppRouter(AuthSession authSession) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authSession,
    redirect: (context, state) {
      final path = state.matchedLocation;
      final isAuthRoute = path == '/login' ||
          path == '/splash' ||
          path.startsWith('/register');
      final isParentRoute = path == '/parent' || path.startsWith('/parent/');

      if (!authSession.isLoading &&
          !authSession.isAuthenticated &&
          !isAuthRoute) {
        return '/login';
      }

      if (authSession.isAuthenticated && isParentRoute && !isParentAccount(authSession.user?.accountType)) {
        return '/home';
      }

      if (authSession.isAuthenticated && (path == '/login' || path == '/splash')) {
        return mapHomePathToMobile(authSession.user?.accountType == 'parent' ? '/parent' : '/home');
      }

      return null;
    },
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
        path: '/parent',
        builder: (context, state) => const ChildPickerScreen(),
        routes: [
          GoRoute(
            path: 'account',
            builder: (context, state) => const AccountHubScreen(),
            routes: [
              GoRoute(
                path: 'profile',
                builder: (context, state) => const AccountProfileScreen(),
              ),
              GoRoute(
                path: 'date-of-birth',
                builder: (context, state) => const AccountDateOfBirthScreen(),
              ),
              GoRoute(
                path: 'city',
                builder: (context, state) => const AccountCityScreen(),
              ),
              GoRoute(
                path: 'login',
                builder: (context, state) => const AccountLoginScreen(),
              ),
              GoRoute(
                path: 'password',
                builder: (context, state) => const AccountPasswordScreen(),
              ),
              GoRoute(
                path: 'children',
                builder: (context, state) => const AccountChildrenScreen(),
                routes: [
                  GoRoute(
                    path: ':childId',
                    builder: (context, state) {
                      final childId = state.pathParameters['childId'];
                      if (childId == null || childId.isEmpty) {
                        return const AccountChildrenScreen();
                      }
                      return AccountChildDetailScreen(childId: childId);
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) {
                          final childId = state.pathParameters['childId'];
                          if (childId == null || childId.isEmpty) {
                            return const AccountChildrenScreen();
                          }
                          return AccountEditChildScreen(childId: childId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'children/new',
            builder: (context, state) => const AddChildScreen(),
          ),
          GoRoute(
            path: ':childId',
            builder: (context, state) {
              final childId = state.pathParameters['childId'];
              if (childId == null || childId.isEmpty) {
                return const ChildPickerScreen();
              }
              return StudyHubScreen(childId: childId);
            },
            routes: [
              GoRoute(
                path: 'homework',
                builder: (context, state) {
                  final childId = state.pathParameters['childId'];
                  if (childId == null || childId.isEmpty) {
                    return const ChildPickerScreen();
                  }
                  return HomeworkListScreen(childId: childId);
                },
              ),
            ],
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
