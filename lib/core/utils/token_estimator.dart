class TokenEstimator {
  /// Rough estimation: ~4 chars per token for English, ~2 chars per token for CJK
  static int estimate(String text) {
    int count = 0;
    for (int i = 0; i < text.length; i++) {
      final char = text.codeUnitAt(i);
      // CJK characters
      if (char >= 0x4E00 && char <= 0x9FFF) {
        count += 1;
      } else {
        count += 1; // Will be divided by 4 later
      }
    }
    // Rough: 4 chars ≈ 1 token for ASCII, CJK already counted
    final asciiChars = text.runes.where((r) => r < 0x4E00 || r > 0x9FFF).length;
    final cjkChars = text.runes.length - asciiChars;
    return (asciiChars / 4).ceil() + cjkChars;
  }
}
