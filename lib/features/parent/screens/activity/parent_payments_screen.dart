import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_activity.dart';
import 'package:larnes_mobile/features/parent/navigation/parent_child_routes.dart';
import 'package:larnes_mobile/features/parent/utils/family_setup_guard.dart';
import 'package:larnes_mobile/features/parent/widgets/activity/parent_activity_payment_row.dart';
import 'package:larnes_mobile/features/parent/widgets/activity/parent_activity_payments_tabs.dart';
import 'package:larnes_mobile/features/parent/widgets/activity/parent_activity_place_dock.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_panel_error_panel.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

/// L2 оплаты — списки начислений и чеков.
class ParentPaymentsScreen extends StatefulWidget {
  const ParentPaymentsScreen({super.key, required this.childId});

  final String childId;

  @override
  State<ParentPaymentsScreen> createState() => _ParentPaymentsScreenState();
}

class _ParentPaymentsScreenState extends State<ParentPaymentsScreen> {
  bool _isLoading = true;
  String? _error;
  String? _errorCode;
  String _placeId = parentActivitySummaryPlaceId;
  List<ParentActivityPlace> _places = const [];
  List<ParentActivityPaymentAccrualItem> _accruals = const [];
  List<ParentActivityPaymentReceiptItem> _receipts = const [];
  ParentActivityPaymentsTab _tab = ParentActivityPaymentsTab.accruals;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  Future<void> _load({String? placeId, bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
        _errorCode = null;
      });
    }

    if (placeId != null) {
      _placeId = placeId;
    }

    try {
      final locale = LocaleScope.read(context).localeCode;
      final api = AuthScope.of(context).parentApi;

      final results = await Future.wait([
        api.fetchActivityContext(
          widget.childId,
          place: _placeId,
          locale: locale,
        ),
        api.fetchPayments(
          widget.childId,
          place: _placeId,
          locale: locale,
        ),
      ]);

      if (!mounted) {
        return;
      }

      final contextPage = results[0] as ParentActivityContextPage;
      final paymentsPage = results[1] as ParentActivityPaymentsPage;

      setState(() {
        _places = contextPage.places;
        _accruals = paymentsPage.accruals;
        _receipts = paymentsPage.receipts;
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

  Future<void> _reloadPayments(String placeId) async {
    if (_placeId == placeId) {
      return;
    }

    setState(() {
      _placeId = placeId;
      _isLoading = true;
      _error = null;
      _errorCode = null;
    });

    try {
      final locale = LocaleScope.read(context).localeCode;
      final paymentsPage = await AuthScope.of(context).parentApi.fetchPayments(
        widget.childId,
        place: placeId,
        locale: locale,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _accruals = paymentsPage.accruals;
        _receipts = paymentsPage.receipts;
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

  Future<void> _openAccrual(ParentActivityPaymentAccrualItem item) async {
    await ParentChildRoutes.pushForChild<void>(
      context,
      childId: widget.childId,
      segment: 'activity/payments/accruals/${item.id}',
      extra: _placeId,
    );
  }

  Future<void> _openReceipt(ParentActivityPaymentReceiptItem item) async {
    await ParentChildRoutes.pushForChild<void>(
      context,
      childId: widget.childId,
      segment: 'activity/payments/receipts/${item.id}',
      extra: _placeId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ParentScaffold(
      title: context.l10n.parentActivityPayments,
      subBar: _places.isEmpty
          ? null
          : ParentActivityPlaceDock(
              places: _places,
              activePlaceId: _placeId,
              onPlaceSelected: _reloadPayments,
            ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final l10n = context.l10n;

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

    final showReceipts = _tab == ParentActivityPaymentsTab.receipts;
    final itemsEmpty = showReceipts ? _receipts.isEmpty : _accruals.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 576),
              child: ParentActivityPaymentsTabs(
                l10n: l10n,
                activeTab: _tab,
                onTabSelected: (tab) => setState(() => _tab = tab),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _load(silent: true),
            color: ParentColors.shell,
            child: itemsEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 36),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 48),
                        child: Text(
                          showReceipts
                              ? l10n.parentActivityPaymentsEmptyReceipts
                              : l10n.parentActivityPaymentsEmptyAccruals,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: ParentColors.inkMuted,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 36),
                    itemCount: showReceipts ? _receipts.length : _accruals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (showReceipts) {
                        final item = _receipts[index];
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 576),
                            child: ParentActivityPaymentRow(
                              dateLabel: item.dateLabel,
                              amountLabel: item.amountLabel,
                              placeLabel: item.placeLabel,
                              onTap: () => _openReceipt(item),
                            ),
                          ),
                        );
                      }

                      final item = _accruals[index];
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 576),
                          child: ParentActivityPaymentRow(
                            dateLabel: item.dateLabel,
                            amountLabel: item.amountLabel,
                            placeLabel: item.placeLabel,
                            onTap: () => _openAccrual(item),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
