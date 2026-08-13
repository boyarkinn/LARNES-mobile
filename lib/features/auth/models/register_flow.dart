import 'package:larnes_mobile/core/api/register_school_offers_api.dart';

enum RegisterAccountType {
  parent('parent'),
  teacher('teacher'),
  networkOwner('network-owner');

  const RegisterAccountType(this.routeSlug);

  final String routeSlug;

  static RegisterAccountType? fromSlug(String? slug) {
    if (slug == null) {
      return null;
    }
    for (final type in RegisterAccountType.values) {
      if (type.routeSlug == slug) {
        return type;
      }
    }
    return null;
  }
}

enum RegisterContactChannel { sms, email }

class RegisterFlowData {
  const RegisterFlowData({
    required this.accountType,
    this.contact = '',
    this.channel = RegisterContactChannel.sms,
    this.verificationToken = '',
    this.selectedSchoolOfferChildIds = const [],
    this.primarySchoolOfferChildId,
    this.schoolOffers = const [],
  });

  final RegisterAccountType accountType;
  final String contact;
  final RegisterContactChannel channel;
  final String verificationToken;
  final List<String> selectedSchoolOfferChildIds;
  final String? primarySchoolOfferChildId;
  final List<PendingSchoolOffer> schoolOffers;

  bool get hasSchoolOffers => selectedSchoolOfferChildIds.isNotEmpty;

  RegisterFlowData copyWith({
    String? contact,
    RegisterContactChannel? channel,
    String? verificationToken,
    List<String>? selectedSchoolOfferChildIds,
    String? primarySchoolOfferChildId,
    List<PendingSchoolOffer>? schoolOffers,
  }) {
    return RegisterFlowData(
      accountType: accountType,
      contact: contact ?? this.contact,
      channel: channel ?? this.channel,
      verificationToken: verificationToken ?? this.verificationToken,
      selectedSchoolOfferChildIds:
          selectedSchoolOfferChildIds ?? this.selectedSchoolOfferChildIds,
      primarySchoolOfferChildId:
          primarySchoolOfferChildId ?? this.primarySchoolOfferChildId,
      schoolOffers: schoolOffers ?? this.schoolOffers,
    );
  }
}
