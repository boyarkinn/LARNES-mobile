import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/reading/reading_word_rules.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

/// Web: `platform/src/trainers/reading/letter-word-link/model.ts`

const minWordLinkItemCount = minWordLinkItems;
const maxWordLinkItemCount = maxWordLinkItems;

class WordLinkItem {
  const WordLinkItem({
    required this.displayLabel,
    required this.id,
    required this.isMatch,
    required this.label,
    required this.slug,
    this.audioKey,
  });

  final String displayLabel;
  final String id;
  final bool isMatch;
  final String label;
  final String slug;
  final String? audioKey;
}

class WordLinkRound {
  const WordLinkRound({
    required this.displayLetter,
    required this.letter,
    required this.wordItems,
  });

  final String displayLetter;
  final String letter;
  final List<WordLinkItem> wordItems;
}

class WordLinkConnection {
  const WordLinkConnection({required this.rightId, required this.slug});

  final String rightId;
  final String slug;
}

class BuildWordLinkRoundInput {
  const BuildWordLinkRoundInput({
    required this.entityCount,
    required this.letter,
    required this.letterCase,
    this.random,
    this.seed,
    required this.wordCase,
  });

  final int entityCount;
  final String letter;
  final String letterCase;
  final double Function()? random;
  final int? seed;
  final String wordCase;
}

int countCorrectWordLinkRoundItems(int entityCount, int correctPoolSize) {
  return countCorrectWordLinkItems(entityCount, correctPoolSize);
}

int buildWordLinkRoundSeed(List<Object> parts) {
  return hashParamsSeed([...parts, 'word-link']);
}

bool isCorrectWordLink(WordLinkItem item, String letter) {
  return item.isMatch &&
      normalizeTargetLetter(item.label.isEmpty ? "" : item.label[0]) ==
          normalizeTargetLetter(letter);
}

bool isWordLinkRoundComplete(
  List<WordLinkConnection> connections,
  WordLinkRound round,
) {
  final required = round.wordItems.where((item) => item.isMatch).toList();

  if (required.isEmpty) {
    return false;
  }

  final connectedIds = connections
      .map((connection) => connection.rightId)
      .toSet();

  return required.every((item) => connectedIds.contains(item.id));
}

String normalizeWordLinkRoundLetter(String letter) {
  return normalizeTargetLetter(letter);
}

WordLinkRound? wordLinkRoundFromPayload(Map<String, dynamic>? payload) {
  final round = payload?['round'];
  if (round is! Map || round['wordItems'] is! List) return null;
  return WordLinkRound(
    displayLetter: round['displayLetter'].toString(),
    letter: round['letter'].toString(),
    wordItems: (round['wordItems'] as List)
        .whereType<Map>()
        .map(
          (item) => WordLinkItem(
            displayLabel: item['displayLabel'].toString(),
            id: item['id'].toString(),
            isMatch: item['isMatch'] == true,
            label: item['label'].toString(),
            slug: item['slug'].toString(),
            audioKey: item['audio'] is Map
                ? item['audio']['semanticKey']?.toString()
                : null,
          ),
        )
        .toList(),
  );
}
