import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/api/parent_panel_error.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_reward.dart';
import 'package:larnes_mobile/features/parent/utils/family_setup_guard.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_panel_error_panel.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/features/parent/widgets/rewards/reward_shop_detail_body.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

/// Витрина и получение награды — web `/parent/:childId/rewards/:shopId`.
class RewardShopDetailScreen extends StatefulWidget {
  const RewardShopDetailScreen({
    super.key,
    required this.childId,
    required this.shopId,
  });

  final String childId;
  final String shopId;

  @override
  State<RewardShopDetailScreen> createState() => _RewardShopDetailScreenState();
}

class _RewardShopDetailScreenState extends State<RewardShopDetailScreen> {
  bool _isLoading = true;
  bool _isClaiming = false;
  String? _error;
  String? _errorCode;
  String? _notice;
  ParentRewardShopDetail? _detail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  Future<void> _load({bool refreshing = false}) async {
    if (!refreshing) {
      setState(() {
        _isLoading = true;
        _error = null;
        _errorCode = null;
      });
    }

    try {
      final locale = LocaleScope.read(context).localeCode;
      final detail = await AuthScope.of(context).parentApi.fetchRewardShop(
        widget.childId,
        widget.shopId,
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
          _error = context.l10n.requestFailed;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _claim(String itemId) async {
    setState(() {
      _isClaiming = true;
      _error = null;
      _notice = null;
    });

    try {
      final locale = LocaleScope.read(context).localeCode;
      await AuthScope.of(context).parentApi.claimRewardItem(
        childId: widget.childId,
        shopId: widget.shopId,
        itemId: itemId,
        locale: locale,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _notice = context.l10n.parentRewardsClaimed;
        _isClaiming = false;
      });
      await _load(refreshing: true);
    } on ParentApiException catch (error) {
      if (mounted && redirectToFamilySetupIfRequired(context, code: error.code)) {
        return;
      }
      if (mounted) {
        setState(() {
          _error = error.message;
          _isClaiming = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = context.l10n.requestFailed;
          _isClaiming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ParentScaffold(
      title: _detail?.title ?? context.l10n.parentRewardsTitle,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: ParentColors.shell));
    }

    if (_detail == null) {
      return Center(
        child: ParentPanelErrorPanel(
          message: _error ?? context.l10n.parentRewardsLoadFailed,
          showFamilySetupAction: isFamilySetupRequiredCode(_errorCode),
          onFamilySetup: () => redirectToFamilySetupIfRequired(
            context,
            code: _errorCode,
          ),
          onRetry: _load,
        ),
      );
    }

    return RewardShopDetailBody(
      detail: _detail!,
      error: _error,
      isClaiming: _isClaiming,
      notice: _notice,
      onClaim: _claim,
    );
  }
}
