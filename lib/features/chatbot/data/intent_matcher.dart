import '../domain/chat_intent.dart';
import 'chatbot_intents.dart';
import 'score_calculator.dart';
import 'text_normalizer.dart';

class IntentMatcher {
  static const int minConfidenceScore = 3;

  static ChatIntent? match(String input) {
    if (input.trim().isEmpty) return null;

    final normalizedInput = TextNormalizer.normalize(input);

    ScoreResult? bestResult;

    for (final intent in chatbotIntents) {
      final result = ScoreCalculator.calculate(normalizedInput, intent);

      if (bestResult == null || result.score > bestResult.score) {
        bestResult = result;
      }
    }

    if (bestResult != null && bestResult.score >= minConfidenceScore) {
      return bestResult.intent;
    }

    return null;
  }
}
