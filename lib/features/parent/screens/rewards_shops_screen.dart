import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/api/parent_panel_error.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_reward.dart';
import 'package:larnes_mobile/features/parent/navigation/parent_child_routes.dart';
import 'package:larnes_mobile/features/parent/theme/hub_card_appearance.dart';
import 'package:larnes_mobile/features/parent/utils/family_setup_guard.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_panel_error_panel.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/features/parent/widgets/study_hub_card.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

/// Список витрин ребёнка — web `/parent/:childId/rewards`.
class RewardsShopsScreen extends StatefulWidget {
  const RewardsShopsScreen({super.key, required this.childId});

  final String childId;

  @override
  State<RewardsShopsScreen> createState() => _RewardsShopsScreenState();
}

class _RewardsShopsScreenState extends State<RewardsShopsScreen> {
  bool _isLoading = true;
  String? _error;
  String? _errorCode;
  List<ParentRewardShopCard> _shops = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _errorCode = null;
    });

    try {
      final locale = LocaleScope.read(context).localeCode;
      final page = await AuthScope.of(context).parentApi.fetchRewardShops(
        widget.childId,
        locale: locale,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _shops = page.shops;
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
          _error = context.l10n.requestFailed;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ParentScaffold(
      title: context.l10n.parentRewardsTitle,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final l10n = context.l10n;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: ParentColors.shell));
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

    if (_shops.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            l10n.parentRewardsEmptyShops,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: ParentColors.inkMuted,
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 36),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: ParentChildCardMetrics.pickerMaxWidth),
            child: Column(
              children: [
                for (var i = 0; i < _shops.length; i++) ...[
                  if (i > 0) const SizedBox(height: ParentChildCardMetrics.pickerListGap),
                  StudyHubCard(
                    title: _shops[i].title,
                    subtitle: l10n.parentRewardsBalance(_shops[i].balancePoints),
                    tokens: rewardsHubCardTokens(),
                    icon: HubCardIconKind.rewards,
                    onTap: () => ParentChildRoutes.pushForChild(
                      context,
                      childId: widget.childId,
                      segment: 'rewards/${_shops[i].shopId}',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
