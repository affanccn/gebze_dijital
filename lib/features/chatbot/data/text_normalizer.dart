class TextNormalizer {
  static String normalize(String input) {
    var text = input
        .toLowerCase()
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .replaceAll("'", "")
        .replaceAll("’", "")
        .trim();

    text = text.replaceAll(RegExp(r'[^\w\sçğıöşüÇĞİÖŞÜ]'), '');

    text = text.replaceAll(RegExp(r'\s+'), ' ');

    return text.trim();
  }

  static String stemWord(String word) {
    var stemmed = word;

    final suffixes = [
      'lar',
      'ler',
      'ın',
      'in',
      'un',
      'ün',
      'nın',
      'nin',
      'nun',
      'nün',
      'a',
      'e',
      'ya',
      'ye',
      'da',
      'de',
      'ta',
      'te',
      'dan',
      'den',
      'tan',
      'ten',
      'ı',
      'i',
      'u',
      'ü',
      'sı',
      'si',
      'su',
      'sü',
      'ım',
      'im',
      'um',
      'üm',
      'mız',
      'miz',
      'muz',
      'müz',
      'nız',
      'niz',
      'nuz',
      'nüz',
      'ları',
      'leri',
      'dı',
      'di',
      'du',
      'dü',
      'tı',
      'ti',
      'tu',
      'tü',
      'mış',
      'miş',
      'muş',
      'müş',
      'ecek',
      'acak',
      'yor',
      'r',
      'ar',
      'er',
    ];

    suffixes.sort((a, b) => b.length.compareTo(a.length));

    for (final suffix in suffixes) {
      if (stemmed.endsWith(suffix) && stemmed.length > suffix.length + 2) {
        stemmed = stemmed.substring(0, stemmed.length - suffix.length);
        break;
      }
    }

    return stemmed;
  }
}
