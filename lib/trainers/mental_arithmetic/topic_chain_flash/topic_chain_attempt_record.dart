import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';

/// The first answer remains separate from the single answer after help.
/// Transport/persistence of this record is owned by the exercise runtime.
class TopicChainAttemptRecord {
  TopicChainAttemptRecord({
    required this.chain,
    required this.firstAnswer,
    this.reviewCompleted = false,
    this.retryAnswer,
  });

  final Chain chain;
  final int firstAnswer;
  bool reviewCompleted;
  int? retryAnswer;

  factory TopicChainAttemptRecord.fromJson(Map<String, dynamic> value) =>
      TopicChainAttemptRecord(
        chain: topicChainFromJson(
          Map<String, dynamic>.from(value['chain'] as Map),
        ),
        firstAnswer: (value['firstAnswer'] as num).toInt(),
        reviewCompleted: value['reviewCompleted'] == true,
        retryAnswer: (value['retryAnswer'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
    'chain': topicChainToJson(chain),
    'firstAnswer': firstAnswer,
    'reviewCompleted': reviewCompleted,
    'retryAnswer': retryAnswer,
  };
}

Map<String, dynamic> topicChainToJson(Chain chain) => {
  'topicId': chain.topicId,
  'answer': chain.answer,
  'steps': [
    for (final step in chain.steps) {'amount': step.amount, 'sign': step.sign},
  ],
  'intermediates': List<int>.of(chain.intermediates),
};

Chain topicChainFromJson(Map<String, dynamic> value) => Chain(
  topicId: value['topicId'] as String,
  answer: (value['answer'] as num).toInt(),
  intermediates: (value['intermediates'] as List)
      .map((value) => (value as num).toInt())
      .toList(),
  steps: (value['steps'] as List).map((value) {
    final step = Map<String, dynamic>.from(value as Map);
    return ChainStep(
      amount: (step['amount'] as num).toInt(),
      sign: step['sign'] as String,
    );
  }).toList(),
);
