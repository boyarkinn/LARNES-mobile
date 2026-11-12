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

  Map<String, dynamic> toJson() => {
    'chain': {
      'topicId': chain.topicId,
      'answer': chain.answer,
      'steps': [
        for (final step in chain.steps)
          {'amount': step.amount, 'sign': step.sign},
      ],
      'intermediates': List<int>.of(chain.intermediates),
    },
    'firstAnswer': firstAnswer,
    'reviewCompleted': reviewCompleted,
    'retryAnswer': retryAnswer,
  };
}
