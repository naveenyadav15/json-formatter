import 'package:flutter_test/flutter_test.dart';
import 'package:grafna/domain/json_formatter.dart';

void main() {
  group('formatJsonWithLineNumbers', () {
    test('wraps long logical line without numbering continuation lines', () {
      const input = '{ "name": "John",\n'
          '"city": "New York",\n'
          '"description": "Some long text that overflows here",\n'
          '"lk": 1 }';

      // Force wrapping with a relatively small width
      final formatted = formatJsonWithLineNumbers(input, maxLineWidth: 30);

      final lines = formatted.split('\n');
      // The last split element after trailing \n will be '' - remove empties at end
      while (lines.isNotEmpty && lines.last.isEmpty) {
        lines.removeLast();
      }

      // There are 4 logical lines, so there must be exactly 4 numbered lines
      final numberedPrefixes =
          lines.where((l) => RegExp(r'^\s*\d+\s\s').hasMatch(l)).length;
      expect(numberedPrefixes, 4);

      // Continuation lines (non-numbered) should be indented by gutterDigits + 2 spaces
      // Gutter digits = len('4') = 1 -> indent should be 3
      final continuationLines =
          lines.where((l) => RegExp(r'^\s{3}[^\d]').hasMatch(l));
      expect(continuationLines.isNotEmpty, true);

      // Verify the specific alignment behavior for the wrapped description line:
      // - The first display line for description starts with '3  '
      // - Its continuation lines start with '   '
      final firstDescIdx = lines.indexWhere((l) => l.startsWith('3  '));
      expect(firstDescIdx, isNonNegative);
      if (firstDescIdx + 1 < lines.length) {
        expect(lines[firstDescIdx + 1].startsWith('   '), isTrue);
      }
    });

    test('does not wrap short lines and numbers each logical line exactly once',
        () {
      const input = '{"a":1}\n{"b":2}\n{"c":3}';
      final formatted = formatJsonWithLineNumbers(input, maxLineWidth: 80);
      final lines = formatted.split('\n');
      while (lines.isNotEmpty && lines.last.isEmpty) {
        lines.removeLast();
      }
      expect(lines.length, 3);
      expect(lines[0], startsWith('1  '));
      expect(lines[1], startsWith('2  '));
      expect(lines[2], startsWith('3  '));
    });

    test('gutter width scales with many lines and continuation indent matches',
        () {
      // Create 123 logical lines; line 5 is long to ensure wrap
      final buffer = StringBuffer();
      for (var i = 1; i <= 123; i++) {
        if (i == 5) {
          buffer.writeln('{"desc":"' + 'x' * 60 + '"}');
        } else {
          buffer.writeln('{"n":$i}');
        }
      }
      final input = buffer.toString().trimRight();

      // With 3-digit gutter, and small width to force wrap of the long line
      final formatted = formatJsonWithLineNumbers(input, maxLineWidth: 25);
      final lines = formatted.split('\n');
      while (lines.isNotEmpty && lines.last.isEmpty) {
        lines.removeLast();
      }

      // Expect first line has 3-digit padded gutter for 123 lines
      expect(lines.first, startsWith('  1  '));

      // Find the first display line of logical line 5
      final idx = lines.indexWhere((l) => l.startsWith('  5  '));
      expect(idx, isNonNegative);
      // Next line should be a continuation with 3-digit indent + 2 spaces = 5 spaces
      expect(lines[idx + 1].startsWith('     '), isTrue);
      // Continuation must not start with a digit immediately after spaces (no extra number)
      expect(RegExp(r'^\s{5}\d').hasMatch(lines[idx + 1]), isFalse);
    });
  });
}
