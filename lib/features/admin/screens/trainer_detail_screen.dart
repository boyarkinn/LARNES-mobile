import 'package:flutter/material.dart';
import 'package:larnes_mobile/features/admin/screens/trainer_play_panel.dart';
import 'package:larnes_mobile/features/admin/widgets/admin_account_scaffold.dart';

class TrainerDetailScreen extends StatelessWidget {
  const TrainerDetailScreen({super.key, required this.trainerKey});

  final String trainerKey;

  @override
  Widget build(BuildContext context) {
    return AdminAccountScaffold(
      title: trainerKey,
      body: TrainerPlayPanel(trainerKey: trainerKey),
    );
  }
}
