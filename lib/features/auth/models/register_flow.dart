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
  });

  final RegisterAccountType accountType;
  final String contact;
  final RegisterContactChannel channel;
  final String verificationToken;

  RegisterFlowData copyWith({
    String? contact,
    RegisterContactChannel? channel,
    String? verificationToken,
  }) {
    return RegisterFlowData(
      accountType: accountType,
      contact: contact ?? this.contact,
      channel: channel ?? this.channel,
      verificationToken: verificationToken ?? this.verificationToken,
    );
  }
}
