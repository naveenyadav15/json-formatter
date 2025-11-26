import 'dart:convert';
import 'package:flutter/material.dart';

/// Formats pre-formatted JSON text (or any text) by adding a left gutter with
/// line numbers for each logical line, wrapping long lines for display without
/// numbering continuation lines.
///
/// Rules:
/// - Numbers logical lines only (split by \n)
/// - Wraps display lines at [maxLineWidth]
/// - Only the first display line of each logical line gets a line number
/// - Continuation lines are indented by the gutter width plus two spaces
/// - Gutter width is computed from the total number of logical lines
/// - Returns a single string where each line ends with a trailing \n
String formatJsonWithLineNumbers(String json, {int maxLineWidth = 80}) {
  final logicalLines = json.split('\n');
  final totalLogicalLines = logicalLines.length;

  // Determine gutter width from the number of digits in the last line number
  final gutterDigits = totalLogicalLines.toString().length;
  const spacer = 2; // space between number and content

  // Content width is the max characters available for content after gutter
  final contentWidth =
      (maxLineWidth - (gutterDigits + spacer)).clamp(1, 1 << 30);

  final buffer = StringBuffer();

  for (var i = 0; i < totalLogicalLines; i++) {
    final lineNumber = (i + 1).toString().padLeft(gutterDigits, ' ');
    final continuationPrefix = '  ' * (gutterDigits + spacer);
    final firstLinePrefix = '$lineNumber${' ' * spacer}';

    final logical = logicalLines[i];

    if (logical.isEmpty) {
      // Preserve empty lines with just the numbered gutter and a trailing newline
      buffer.write(firstLinePrefix);
      buffer.write('\n');
      continue;
    }

    // Wrap the logical line into display-sized chunks
    var start = 0;
    var isFirstChunk = true;
    while (start < logical.length) {
      final endExclusive = (start + contentWidth) > logical.length
          ? logical.length
          : start + contentWidth;
      final chunk = logical.substring(start, endExclusive);

      if (isFirstChunk) {
        buffer.write(firstLinePrefix);
        isFirstChunk = false;
      } else {
        buffer.write(continuationPrefix);
      }
      buffer.write(chunk);
      buffer.write('\n');

      start = endExclusive;
    }
  }

  return buffer.toString();
}

class JsonFormatter extends ChangeNotifier {
  String _input = '';
  String _output = '';
  String _error = '';

  String get input => _input;

  String get output => _output;

  String get error => _error;

  void formatJson(String rawInput) {
    _input = rawInput;
    if (rawInput.trim().isEmpty) {
      _output = '';
      _error = '';
    } else {
      try {
        // final decoded = json.decode(rawInput) as Map<String, dynamic>;
        // final message = decoded['message'];
        // if (message is String) {
        //   try {
        //     decoded['message'] = json.decode(message);
        //   } catch (_) {}
        // }
        final decoded = fullyDecodeJson(rawInput);
        _output = const JsonEncoder.withIndent('  ').convert(decoded);
        _error = '';
      } on FormatException catch (e) {
        _output = '';
        _error = 'Error: [${e.message}]\nAt offset: ${e.offset}';
      } catch (e) {
        _output = '';
        _error = 'Unexpected error: $e';
      }
    }
    notifyListeners();
  }

  dynamic fullyDecodeJson(String jsonString) {
    dynamic decodeNested(dynamic data) {
      if (data is String) {
        // Try decoding string if it looks like JSON
        try {
          final decoded = jsonDecode(data);
          return decodeNested(decoded); // Recursively decode again
        } catch (_) {
          return data; // Not JSON, return as is
        }
      } else if (data is Map<String, dynamic>) {
        return data.map((key, value) => MapEntry(key, decodeNested(value)));
      } else if (data is List) {
        return data.map(decodeNested).toList();
      }
      return data;
    }

    final firstDecode = jsonDecode(jsonString);
    return decodeNested(firstDecode);
  }

  void clear() {
    _input = '';
    _output = '';
    _error = '';
    notifyListeners();
  }
}
