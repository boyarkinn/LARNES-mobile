import 'package:flutter/widgets.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';

class LocaleScope extends InheritedNotifier<LocaleController> {
  const LocaleScope({
    super.key,
    required LocaleController localeController,
    required super.child,
  }) : super(notifier: localeController);

  static LocaleController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<LocaleScope>() ??
            context.findAncestorWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope not found above context');
    return scope!.notifier!;
  }

  /// Без подписки на перестроение — для initState / async callbacks.
  static LocaleController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<LocaleScope>() ??
        context.findAncestorWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope not found above context');
    return scope!.notifier!;
  }
}
