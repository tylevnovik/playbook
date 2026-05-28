class ParsedBlock {
  final String speakerName;
  final String content;

  const ParsedBlock({required this.speakerName, required this.content});

  @override
  String toString() => 'ParsedBlock($speakerName: $content)';
}

class LlmParser {
  /// Parses raw LLM output into speaker blocks.
  /// Recognizes [Speaker]: content or [Speaker]：content patterns at the start of lines.
  static List<ParsedBlock> parseBlocks(String text) {
    final List<ParsedBlock> blocks = [];
    final lines = text.split('\n');
    String? currentSpeaker;
    final StringBuffer currentContent = StringBuffer();

    // Regex to match e.g. [Carter]: content or [旁白]：content
    final speakerRegex = RegExp(r'^\[([^\]]+)\][:：]\s*(.*)$');

    for (final line in lines) {
      final trimmedLine = line.trim();
      final match = speakerRegex.firstMatch(trimmedLine);
      if (match != null) {
        // If we had a previous speaker, save it if it has content
        if (currentSpeaker != null && currentContent.toString().trim().isNotEmpty) {
          blocks.add(ParsedBlock(
            speakerName: currentSpeaker,
            content: currentContent.toString().trim(),
          ));
          currentContent.clear();
        }
        currentSpeaker = match.group(1);
        currentContent.write(match.group(2) ?? '');
      } else {
        if (currentSpeaker == null) {
          // If we haven't seen any speaker tag yet, we default to 'default'
          currentSpeaker = 'default';
        } else {
          currentContent.writeln();
        }
        currentContent.write(line);
      }
    }

    if (currentSpeaker != null && currentContent.toString().trim().isNotEmpty) {
      blocks.add(ParsedBlock(
        speakerName: currentSpeaker,
        content: currentContent.toString().trim(),
      ));
    }
    return blocks;
  }
}
