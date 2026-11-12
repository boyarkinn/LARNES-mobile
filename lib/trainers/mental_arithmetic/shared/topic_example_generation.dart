import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/generate.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/simple_rules.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';

class TopicExampleProfile {
  const TopicExampleProfile(this.topicId, {this.repeatedDigit});
  final String topicId;
  final int? repeatedDigit;
}

const topicExampleActionCount = 5;

String chainExampleSignature(List<ChainStep> steps) =>
    steps.map((step) => '${step.sign}${step.amount}').join(' ');

Chain generateTopicExample(
  TopicExampleProfile profile, {
  double Function()? random,
  String? previousSignature,
}) {
  final digit = profile.repeatedDigit;
  final rule = digit == null ? null : createRepeatedDigitSimpleTopicRule(digit);
  for (var attempt = 0; ; attempt++) {
    final chain = generateChain(
      GenerateConfig(
        topicId: profile.topicId,
        actionCount: topicExampleActionCount,
        signMode: 'mix',
      ),
      GenerateChainOptions(random: random, rule: rule),
    );
    if (attempt >= 11 ||
        chainExampleSignature(chain.steps) != previousSignature) {
      return chain;
    }
  }
}
