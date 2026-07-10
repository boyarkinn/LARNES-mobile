import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/app/theme/admin_theme.dart';

class AdminAccountScaffold extends StatelessWidget {
  const AdminAccountScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showBack,
  });

  final String title;
  final Widget body;
  final bool? showBack;

  @override
  Widget build(BuildContext context) {
    final canPop = showBack ?? GoRouter.of(context).canPop();

    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: AdminColors.surface,
        foregroundColor: AdminColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: canPop,
        title: Text(title),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AdminColors.line),
        ),
      ),
      body: body,
    );
  }
}
