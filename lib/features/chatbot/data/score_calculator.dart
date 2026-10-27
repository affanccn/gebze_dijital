import '../domain/chat_intent.dart';
import 'text_normalizer.dart';

class ScoreResult {
  final ChatIntent intent;
  final int score;

  const ScoreResult(this.intent, this.score);
}

class ScoreCalculator {
  static const int exactPhraseScore = 5;
  static const int titleMatchScore = 3;
  static const int keywordMatchScore = 2;
  static const int multipleKeywordBonus = 1;

  static ScoreResult calculate(String normalizedInput, ChatIntent intent) {
    int score = 0;

    // Tam Phrase Eşleşmesi
    for (final phrase in intent.phrases) {
      if (normalizedInput.contains(TextNormalizer.normalize(phrase))) {
        score += exactPhraseScore;
      }
    }

    final words = normalizedInput.split(' ');
    final stemmedWords = words.map((w) => TextNormalizer.stemWord(w)).toList();

    int matchedKeywords = 0;

    for (final keyword in intent.keywords) {
      final normalizedKeyword = TextNormalizer.normalize(keyword);
      final stemmedKeyword = TextNormalizer.stemWord(normalizedKeyword);

      // Başlık eşleşmesi (Title match)
      if (normalizedInput.contains(normalizedKeyword)) {
        score += titleMatchScore;
        matchedKeywords++;
        continue;
      }

      // Kelime bazlı eşleşme
      bool keywordFound = false;
      for (int i = 0; i < words.length; i++) {
        if (words[i] == normalizedKeyword ||
            stemmedWords[i] == stemmedKeyword) {
          score += keywordMatchScore;
          keywordFound = true;
          break;
        }
      }

      if (keywordFound) {
        matchedKeywords++;
      }
    }

    // Birden fazla keyword eşleşmesi bonusu
    if (matchedKeywords > 1) {
      score += (matchedKeywords - 1) * multipleKeywordBonus;
    }

    return ScoreResult(intent, score);
  }
}
