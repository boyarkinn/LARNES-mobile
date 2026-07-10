import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/admin_theme.dart';
import 'package:larnes_mobile/core/api/admin_trainers_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/admin/models/trainer_catalog.dart';
import 'package:larnes_mobile/features/admin/widgets/trainer_catalog_card.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class TrainersCatalogScreen extends StatefulWidget {
  const TrainersCatalogScreen({super.key});

  @override
  State<TrainersCatalogScreen> createState() => _TrainersCatalogScreenState();
}

class _TrainersCatalogScreenState extends State<TrainersCatalogScreen> {
  bool _isLoading = true;
  String? _error;
  TrainerCatalogSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final locale = LocaleScope.read(context).localeCode;
      final snapshot = await AuthScope.of(context).adminTrainersApi.fetchCatalog(locale: locale);
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _isLoading = false;
        _error = null;
      });
    } on AdminTrainersApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = context.l10n.adminTrainersLoadFailed;
        _isLoading = false;
      });
    }
  }

  void _openTrainer(String trainerKey) {
    context.push('/admin/trainers/$trainerKey');
  }

  String _directionLabel(AppLocalizations l10n, TrainerCatalogDirection direction) {
    switch (direction) {
      case TrainerCatalogDirection.math:
        return l10n.adminTrainersDirectionMath;
      case TrainerCatalogDirection.reading:
        return l10n.adminTrainersDirectionReading;
      case TrainerCatalogDirection.mental:
        return l10n.adminTrainersDirectionMental;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: AdminColors.surface,
        foregroundColor: AdminColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.adminTrainersTitle),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AdminColors.line),
        ),
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading && _snapshot == null) {
      return const Center(child: CircularProgressIndicator(color: AdminColors.accent));
    }

    if (_error != null && _snapshot == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AdminColors.inkMuted),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AdminColors.accent),
                onPressed: _load,
                child: Text(l10n.continueButton),
              ),
            ],
          ),
        ),
      );
    }

    final groups = _snapshot?.groups ?? const [];

    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            l10n.adminTrainersHint,
            style: GoogleFonts.inter(fontSize: 14, color: AdminColors.inkMuted),
          ),
          const SizedBox(height: 20),
          for (var groupIndex = 0; groupIndex < groups.length; groupIndex++) ...[
            if (groupIndex > 0) const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _directionLabel(l10n, groups[groupIndex].direction),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.ink,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.adminTrainersGroupCount(groups[groupIndex].trainers.length),
                  style: GoogleFonts.inter(fontSize: 12, color: AdminColors.inkMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var trainerIndex = 0; trainerIndex < groups[groupIndex].trainers.length; trainerIndex++) ...[
              if (trainerIndex > 0) const SizedBox(height: 12),
              TrainerCatalogCard(
                trainer: groups[groupIndex].trainers[trainerIndex],
                l10n: l10n,
                onOpen: () => _openTrainer(groups[groupIndex].trainers[trainerIndex].key),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
