import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/time/user_time_zone.dart';
import 'package:larnes_mobile/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserTimeZone.initialize();
  runApp(const LarnesApp());
}
