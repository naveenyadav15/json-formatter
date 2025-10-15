import 'package:flutter/material.dart';
import 'package:extended_text_field/extended_text_field.dart';

class HighlightBuilder extends SpecialTextSpanBuilder {
  final String searchQuery;
  final List<TextRange> matches;
  final int currentMatch;
  final ThemeData theme;

  HighlightBuilder({
    required this.searchQuery,
    required this.matches,
    required this.currentMatch,
    required this.theme,
  });

  @override
  TextSpan build(String data,
      {TextStyle? textStyle, onTap, bool? hideSpecialText}) {
    if (searchQuery.isEmpty || data.isEmpty) {
      return TextSpan(text: data, style: textStyle);
    }
    final spans = <TextSpan>[];
    int last = 0;
    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      if (last < match.start) {
        spans.add(TextSpan(
            text: data.substring(last, match.start), style: textStyle));
      }
      spans.add(TextSpan(
        text: data.substring(match.start, match.end),
        style: textStyle?.copyWith(
          backgroundColor: i == currentMatch
              ? theme.colorScheme.primary.withOpacity(0.4)
              : theme.colorScheme.primary.withOpacity(0.2),
        ),
      ));
      last = match.end;
    }
    if (last < data.length) {
      spans.add(TextSpan(text: data.substring(last), style: textStyle));
    }
    return TextSpan(children: spans, style: textStyle);
  }

  @override
  SpecialText? createSpecialText(String flag,
      {TextStyle? textStyle, SpecialTextGestureTapCallback? onTap, required int index}) {
    return null;
  }
}