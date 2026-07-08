import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/kiosk/kiosk_route_state.dart';
import 'package:larnes_mobile/core/routing/home_path_mapper.dart';
import 'package:larnes_mobile/features/auth/models/register_flow.dart';
import 'package:larnes_mobile/features/auth/models/password_reset_flow.dart';
import 'package:larnes_mobile/features/auth/screens/login_screen.dart';
import 'package:larnes_mobile/features/auth/screens/password_reset_contact_screen.dart';
import 'package:larnes_mobile/features/auth/screens/password_reset_otp_screen.dart';
import 'package:larnes_mobile/features/auth/screens/password_reset_password_screen.dart';
import 'package:larnes_mobile/features/auth/screens/register_contact_screen.dart';
import 'package:larnes_mobile/features/auth/screens/register_otp_screen.dart';
import 'package:larnes_mobile/features/auth/screens/register_profile_screen.dart';
import 'package:larnes_mobile/features/auth/screens/register_type_screen.dart';
import 'package:larnes_mobile/features/auth/screens/splash_screen.dart';
import 'package:larnes_mobile/features/kiosk/screens/kiosk_enroll_screen.dart';
import 'package:larnes_mobile/features/kiosk/screens/kiosk_settings_screen.dart';
import 'package:larnes_mobile/features/kiosk/screens/kiosk_shell.dart';
import 'package:larnes_mobile/features/network/screens/network_centers_screen.dart';
import 'package:larnes_mobile/features/parent/models/parent_program.dart';
import 'package:larnes_mobile/features/parent/screens/account/account_change_contact_screen.dart';
import 'package:larnes_mobile/features/parent/screens/account/account_child_detail_screen.dart';
import 'package:larnes_mobile/features/parent/screens/account/account_children_screen.dart';
import 'package:larnes_mobile/features/parent/screens/account/account_relationship_screen.dart';
import 'package:larnes_mobile/features/parent/screens/account/account_city_screen.dart';
import 'package:larnes_mobile/features/parent/screens/account/account_date_of_birth_screen.dart';
import 'package:larnes_mobile/features/parent/screens/account/account_edit_child_screen.dart';
import 'package:larnes_mobile/features/invite/screens/family_guardian_invite_screen.dart';
import 'package:larnes_mobile/features/invite/screens/family_join_request_invite_screen.dart';
import 'package:larnes_mobile/features/parent/screens/account/account_hub_screen.dart';
import 'package:larnes_mobile/features/parent/screens/family_join_dedup_screen.dart';
import 'package:larnes_mobile/features/parent/screens/family_setup_screen.dart';
import 'package:larnes_mobile/features/parent/screens/account/account_login_screen.dart';
import 'package:larnes_mobile/features/parent/screens/account/account_password_screen.dart';
import 'package:larnes_mobile/features/parent/screens/account/account_profile_screen.dart';
import 'package:larnes_mobile/features/parent/screens/add_child_screen.dart';
import 'package:larnes_mobile/features/parent/screens/child_picker_screen.dart';
import 'package:larnes_mobile/features/parent/screens/child_profile_screen.dart';
import 'package:larnes_mobile/features/parent/screens/direction_programs_screen.dart';
import 'package:larnes_mobile/features/parent/screens/homework_list_screen.dart';
import 'package:larnes_mobile/features/parent/screens/homework_player_screen.dart';
import 'package:larnes_mobile/features/parent/screens/program_player_screen.dart';
import 'package:larnes_mobile/features/parent/screens/study_hub_screen.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_shell_scaffold.dart';
import 'package:larnes_mobile/features/shell/home_placeholder_screen.dart';

final _parentChildrenNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'parentChildren');
final _parentAccountNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'parentAccount');

GoRouter createAppRouter({
  required AuthSession authSession,
  required KioskRouteState kioskRouteState,
}) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: Listenable.merge([authSession, kioskRouteState]),
    redirect: (context, state) {
      return resolveAppRedirect(
        isLoading: authSession.isLoading,
        isAuthenticated: authSession.isAuthenticated,
        path: state.matchedLocation,
        accountType: authSession.user?.accountType,
        hasDeviceToken: kioskRouteState.hasDeviceToken,
        familySetupComplete: authSession.familySetupComplete,
      );
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => SplashScreen(
          authSession: authSession,
          kioskRouteState: kioskRouteState,
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          authSession: authSession,
          redirectPath: state.uri.queryParameters['from'],
        ),
      ),
      GoRoute(
        path: '/password-reset',
        builder: (context, state) => const PasswordResetContactScreen(),
        routes: [
          GoRoute(
            path: 'otp',
            builder: (context, state) {
              final flow = state.extra;
              if (flow is! PasswordResetFlowData) {
                return const PasswordResetContactScreen();
              }
              return PasswordResetOtpScreen(flow: flow);
            },
          ),
          GoRoute(
            path: 'password',
            builder: (context, state) {
              final flow = state.extra;
              if (flow is! PasswordResetFlowData) {
                return const PasswordResetContactScreen();
              }
              return PasswordResetPasswordScreen(flow: flow);
            },
          ),
        ],
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ParentShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Account branch first: go_router matches branches in order, so
          // `/parent/account` must win over children `:childId`.
          StatefulShellBranch(
            navigatorKey: _parentAccountNavigatorKey,
            routes: [
              GoRoute(
                path: '/parent/account',
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
                    path: 'relationship',
                    builder: (context, state) {
                      final relationship = state.uri.queryParameters['relationship'];
                      return AccountRelationshipScreen(initialRelationship: relationship);
                    },
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
                    path: 'phone',
                    builder: (context, state) => const AccountChangeContactScreen(
                      channel: AccountContactChangeChannel.phone,
                    ),
                  ),
                  GoRoute(
                    path: 'email',
                    builder: (context, state) => const AccountChangeContactScreen(
                      channel: AccountContactChangeChannel.email,
                    ),
                  ),
                  GoRoute(
                    path: 'password',
                    builder: (context, state) => const AccountPasswordScreen(),
                  ),
                  GoRoute(
                    path: 'guardians',
                    redirect: (context, state) => '/parent/account',
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
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _parentChildrenNavigatorKey,
            routes: [
              GoRoute(
                path: '/parent',
                builder: (context, state) => const ChildPickerScreen(),
                routes: [
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
                        path: 'profile',
                        builder: (context, state) {
                          final childId = state.pathParameters['childId'];
                          if (childId == null || childId.isEmpty) {
                            return const ChildPickerScreen();
                          }
                          return ChildProfileScreen(
                            childId: childId,
                            origin: childProfileOriginFromQuery(state.uri.queryParameters['from']),
                          );
                        },
                      ),
                      GoRoute(
                        path: 'homework',
                        builder: (context, state) {
                          final childId = state.pathParameters['childId'];
                          if (childId == null || childId.isEmpty) {
                            return const ChildPickerScreen();
                          }
                          return HomeworkListScreen(childId: childId);
                        },
                        routes: [
                          GoRoute(
                            path: ':assignmentId',
                            builder: (context, state) {
                              final childId = state.pathParameters['childId'];
                              final assignmentId = state.pathParameters['assignmentId'];
                              if (childId == null ||
                                  childId.isEmpty ||
                                  assignmentId == null ||
                                  assignmentId.isEmpty) {
                                return const ChildPickerScreen();
                              }
                              return HomeworkPlayerScreen(
                                childId: childId,
                                assignmentId: assignmentId,
                              );
                            },
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'directions/:directionId',
                        builder: (context, state) {
                          final childId = state.pathParameters['childId'];
                          final directionId = state.pathParameters['directionId'];
                          if (childId == null ||
                              childId.isEmpty ||
                              directionId == null ||
                              directionId.isEmpty) {
                            return const ChildPickerScreen();
                          }
                          final extra = state.extra;
                          DirectionProgramsRouteExtra? routeExtra;
                          if (extra is DirectionProgramsRouteExtra) {
                            routeExtra = extra;
                          } else if (extra is String) {
                            routeExtra = DirectionProgramsRouteExtra(
                              directionTitle: extra,
                              directionSlug: '',
                            );
                          }
                          return DirectionProgramsScreen(
                            childId: childId,
                            directionId: directionId,
                            directionTitle: routeExtra?.directionTitle ?? '',
                            directionSlug: routeExtra?.directionSlug ?? '',
                            sortOrder: routeExtra?.sortOrder ?? 0,
                          );
                        },
                      ),
                      GoRoute(
                        path: 'programs/:programId',
                        builder: (context, state) {
                          final childId = state.pathParameters['childId'];
                          final programId = state.pathParameters['programId'];
                          if (childId == null ||
                              childId.isEmpty ||
                              programId == null ||
                              programId.isEmpty) {
                            return const ChildPickerScreen();
                          }
                          return ProgramPlayerScreen(
                            childId: childId,
                            programId: programId,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/parent/family-setup',
        builder: (context, state) => const FamilySetupScreen(),
      ),
      GoRoute(
        path: '/parent/family-join-dedup',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          final kind = state.uri.queryParameters['kind'] ?? '';
          return FamilyJoinDedupScreen(token: token, kind: kind);
        },
      ),
      GoRoute(
        path: '/invite/family-join-request',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return FamilyJoinRequestInviteScreen(token: token);
        },
      ),
      GoRoute(
        path: '/invite/family-guardian',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return FamilyGuardianInviteScreen(token: token);
        },
      ),
      GoRoute(
        path: '/network',
        builder: (context, state) => const NetworkCentersScreen(),
      ),
      GoRoute(
        path: '/kiosk/enroll',
        builder: (context, state) => const KioskEnrollScreen(),
      ),
      GoRoute(
        path: '/kiosk',
        builder: (context, state) => const KioskShell(),
        routes: [
          GoRoute(
            path: 'settings',
            builder: (context, state) => const KioskSettingsScreen(),
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
