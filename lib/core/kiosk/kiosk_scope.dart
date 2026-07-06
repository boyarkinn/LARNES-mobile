import 'package:flutter/widgets.dart';
import 'package:larnes_mobile/core/kiosk/kiosk_route_state.dart';

class KioskScope extends InheritedWidget {
  const KioskScope({
    super.key,
    required this.kioskRouteState,
    required super.child,
  });

  final KioskRouteState kioskRouteState;

  static KioskRouteState of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<KioskScope>() ??
        context.findAncestorWidgetOfExactType<KioskScope>();
    assert(scope != null, 'KioskScope not found above context');
    return scope!.kioskRouteState;
  }

  @override
  bool updateShouldNotify(KioskScope oldWidget) =>
      oldWidget.kioskRouteState != kioskRouteState;
}
