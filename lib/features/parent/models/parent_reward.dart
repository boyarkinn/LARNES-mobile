int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return fallback;
}

class ParentRewardShopsPage {
  const ParentRewardShopsPage({
    required this.shops,
    required this.visible,
  });

  factory ParentRewardShopsPage.fromJson(Map<String, dynamic> json) {
    final shops = json['shops'] as List<dynamic>? ?? const [];
    return ParentRewardShopsPage(
      shops: shops
          .map((item) => ParentRewardShopCard.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      visible: json['visible'] == true,
    );
  }

  final List<ParentRewardShopCard> shops;
  final bool visible;
}

class ParentRewardShopCard {
  const ParentRewardShopCard({
    required this.balancePoints,
    required this.ownerKind,
    required this.shopId,
    required this.title,
  });

  factory ParentRewardShopCard.fromJson(Map<String, dynamic> json) {
    return ParentRewardShopCard(
      balancePoints: _asInt(json['balancePoints']),
      ownerKind: json['ownerKind'] as String? ?? 'network',
      shopId: json['shopId'] as String,
      title: json['title'] as String? ?? '',
    );
  }

  final int balancePoints;
  final String ownerKind;
  final String shopId;
  final String title;
}

enum ParentRewardClaimStatus {
  pending('pending'),
  handedOver('handed_over'),
  cancelled('cancelled');

  const ParentRewardClaimStatus(this.apiValue);

  final String apiValue;

  static ParentRewardClaimStatus fromApiValue(String? value) {
    return ParentRewardClaimStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => ParentRewardClaimStatus.pending,
    );
  }
}

class ParentRewardItem {
  const ParentRewardItem({
    required this.canClaim,
    required this.costPoints,
    required this.id,
    required this.title,
    this.imageUrl,
  });

  factory ParentRewardItem.fromJson(Map<String, dynamic> json) {
    final imageUrl = json['imageUrl'] as String?;
    return ParentRewardItem(
      canClaim: json['canClaim'] == true,
      costPoints: _asInt(json['costPoints']),
      id: json['id'] as String,
      imageUrl: imageUrl == null || imageUrl.isEmpty ? null : imageUrl,
      title: json['title'] as String? ?? '',
    );
  }

  final bool canClaim;
  final int costPoints;
  final String id;
  final String? imageUrl;
  final String title;
}

class ParentRewardClaim {
  const ParentRewardClaim({
    required this.createdAt,
    required this.id,
    required this.itemTitle,
    required this.pointsSpent,
    required this.status,
  });

  factory ParentRewardClaim.fromJson(Map<String, dynamic> json) {
    return ParentRewardClaim(
      createdAt: json['createdAt'] as String? ?? '',
      id: json['id'] as String,
      itemTitle: json['itemTitle'] as String? ?? '',
      pointsSpent: _asInt(json['pointsSpent']),
      status: ParentRewardClaimStatus.fromApiValue(json['status'] as String?),
    );
  }

  final String createdAt;
  final String id;
  final String itemTitle;
  final int pointsSpent;
  final ParentRewardClaimStatus status;
}

class ParentRewardShopDetail {
  const ParentRewardShopDetail({
    required this.balancePoints,
    required this.claims,
    required this.items,
    required this.shopId,
    required this.title,
  });

  factory ParentRewardShopDetail.fromJson(Map<String, dynamic> json) {
    final claims = json['claims'] as List<dynamic>? ?? const [];
    final items = json['items'] as List<dynamic>? ?? const [];
    return ParentRewardShopDetail(
      balancePoints: _asInt(json['balancePoints']),
      claims: claims
          .map((item) => ParentRewardClaim.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      items: items
          .map((item) => ParentRewardItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      shopId: json['shopId'] as String,
      title: json['title'] as String? ?? '',
    );
  }

  final int balancePoints;
  final List<ParentRewardClaim> claims;
  final List<ParentRewardItem> items;
  final String shopId;
  final String title;
}
