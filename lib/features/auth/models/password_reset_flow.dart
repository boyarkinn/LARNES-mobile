enum PasswordResetChannel { sms, email }

class PasswordResetFlowData {
  const PasswordResetFlowData({
    this.contact = '',
    this.channel = PasswordResetChannel.sms,
    this.verificationToken = '',
  });

  final String contact;
  final PasswordResetChannel channel;
  final String verificationToken;

  PasswordResetFlowData copyWith({
    String? contact,
    PasswordResetChannel? channel,
    String? verificationToken,
  }) {
    return PasswordResetFlowData(
      contact: contact ?? this.contact,
      channel: channel ?? this.channel,
      verificationToken: verificationToken ?? this.verificationToken,
    );
  }

  static PasswordResetChannel channelFromApi(String value) {
    return value == 'email' ? PasswordResetChannel.email : PasswordResetChannel.sms;
  }
}
