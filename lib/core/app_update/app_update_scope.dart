import 'package:flutter/widgets.dart';
import 'package:larnes_mobile/core/app_update/app_update_controller.dart';
import 'package:larnes_mobile/core/app_update/app_update_dialog.dart';

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

class AppUpdateHost extends StatefulWidget {
  const AppUpdateHost({super.key, required this.child});

  final Widget child;

  @override
  State<AppUpdateHost> createState() => _AppUpdateHostState();
}

class _AppUpdateHostState extends State<AppUpdateHost> {
  AppUpdateController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = AppUpdateScope.maybeOf(context);
    if (!identical(_controller, next)) {
      _controller?.removeListener(_handleControllerChanged);
      _controller = next;
      _controller?.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    final controller = _controller;
    if (controller == null || !mounted || !controller.shouldShowColdStartDialog) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.shouldShowColdStartDialog) {
        return;
      }
      controller.markDialogShown();
      showAppUpdateDialog(context, controller: controller);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
