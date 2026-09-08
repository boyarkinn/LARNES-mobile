import 'package:flutter/widgets.dart';
import 'package:larnes_mobile/core/app_update/app_update_controller.dart';

class AppUpdateScope extends InheritedNotifier<AppUpdateController> {
  const AppUpdateScope({
    super.key,
    required AppUpdateController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppUpdateController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppUpdateScope>();
    assert(scope != null, 'AppUpdateScope not found');
    return scope!.notifier!;
  }

  static AppUpdateController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppUpdateScope>()?.notifier;
  }
}

/// Pass-through wrapper kept for stable tree shape in [LarnesApp].
class AppUpdateHost extends StatelessWidget {
  const AppUpdateHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
