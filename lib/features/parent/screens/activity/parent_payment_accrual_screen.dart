import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_activity.dart';
import 'package:larnes_mobile/features/parent/utils/family_setup_guard.dart';
import 'package:larnes_mobile/features/parent/widgets/activity/parent_payment_accrual_table.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_panel_error_panel.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

/// L3 начисление — read-only таблица распределения.
class ParentPaymentAccrualScreen extends StatefulWidget {
  const ParentPaymentAccrualScreen({
    super.key,
    required this.childId,
    required this.batchId,
  });

  final String childId;
  final String batchId;

  @override
  State<ParentPaymentAccrualScreen> createState() => _ParentPaymentAccrualScreenState();
}

class _ParentPaymentAccrualScreenState extends State<ParentPaymentAccrualScreen> {
  bool _isLoading = true;
  String? _error;
  String? _errorCode;
  ParentActivityAccrualDetailPage? _detail;

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
        _errorCode = null;
      });
    }

    try {
      final locale = LocaleScope.read(context).localeCode;
      final detail = await AuthScope.of(context).parentApi.fetchPaymentAccrual(
        widget.childId,
        widget.batchId,
        locale: locale,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } on ParentApiException catch (error) {
      if (mounted && redirectToFamilySetupIfRequired(context, code: error.code)) {
        return;
      }
      if (mounted) {
        setState(() {
          _error = error.message;
          _errorCode = error.code;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = context.l10n.parentActivityLoadFailed;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ParentScaffold(
      title: l10n.parentActivityPaymentAccrualTitle,
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: ParentPanelErrorPanel(
          message: _error!,
          showFamilySetupAction: isFamilySetupRequiredCode(_errorCode),
          onFamilySetup: () => redirectToFamilySetupIfRequired(
            context,
            code: _errorCode,
          ),
          onRetry: _load,
        ),
      );
    }

    final detail = _detail;
    if (detail == null) {
      return Center(
        child: Text(
          l10n.parentActivityPaymentDetailNotFound,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: ParentColors.inkMuted,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      color: ParentColors.shell,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 36),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 576),
              child: ParentPaymentAccrualTable(
                detail: detail,
                l10n: l10n,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
