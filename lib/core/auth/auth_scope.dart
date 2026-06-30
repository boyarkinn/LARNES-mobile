import 'package:flutter/widgets.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';

class AuthScope extends InheritedWidget {
  const AuthScope({
    super.key,
    required this.authSession,
    required super.child,
  });

  final AuthSession authSession;

  static AuthSession of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AuthScope>() ??
        context.findAncestorWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found above context');
    return scope!.authSession;
  }

  @override
  bool updateShouldNotify(AuthScope oldWidget) =>
      oldWidget.authSession != authSession;
}
