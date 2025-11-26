import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grafna/domain/search_manager.dart';
import 'package:provider/provider.dart';
import '../../domain/json_formatter.dart';
import 'search_bar.dart';
import 'highlight_builder.dart';
// Removed custom gutter; numbering handled in formatted text

class OutputPanel extends StatefulWidget {
  final double splitRatio;
  final ScrollController scrollController;
  final VoidCallback onPanelTap;
  final FocusNode searchFocusNode;

  const OutputPanel({
    super.key,
    required this.splitRatio,
    required this.scrollController,
    required this.onPanelTap,
    required this.searchFocusNode,
  });

  @override
  State<OutputPanel> createState() => _OutputPanelState();
}

class _OutputPanelState extends State<OutputPanel> {
  late final TextEditingController _searchController;
  String _currentDisplayText = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToCurrentMatch(SearchManager searchManager) {
    if (searchManager.outputMatches.isEmpty) return;
    final match = searchManager.outputMatches[searchManager.outputCurrentMatch];
    final beforeMatch = _currentDisplayText.substring(0, match.start);
    final lineCount = '\n'.allMatches(beforeMatch).length;
    final offset = (lineCount * 15.0) - 16.0;
    widget.scrollController.animateTo(
      offset < 0 ? 0 : offset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jsonFormatter = Provider.of<JsonFormatter>(context, listen: true);
    final searchManager = Provider.of<SearchManager>(context);
    // Keep the search field in sync with the searchManager
    if (_searchController.text != searchManager.outputSearchQuery) {
      _searchController.text = searchManager.outputSearchQuery;
      _searchController.selection =
          TextSelection.collapsed(offset: _searchController.text.length);
    }
    return Expanded(
      flex: ((1 - widget.splitRatio) * 100).round(),
      child: Listener(
        onPointerDown: (event) {
          widget.onPanelTap();
        },
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              SearchBarField(
                hint: 'Search output',
                focusNode: widget.searchFocusNode,
                controller: _searchController,
                onChanged: (query) {
                  searchManager.updateOutputMatches(
                    jsonFormatter.error.isNotEmpty
                        ? jsonFormatter.error
                        : jsonFormatter.output,
                    query,
                  );
                  // Scroll to match after search changes
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToCurrentMatch(searchManager);
                  });
                },
                onNext: () {
                  searchManager.nextOutputMatch();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToCurrentMatch(searchManager);
                  });
                },
                onPrev: () {
                  searchManager.prevOutputMatch();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToCurrentMatch(searchManager);
                  });
                },
                matchCount: searchManager.outputMatches.length,
                currentMatch: searchManager.outputCurrentMatch,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final baseText = jsonFormatter.error.isNotEmpty
                        ? jsonFormatter.error
                        : jsonFormatter.output;

                    // Estimate max characters per line for mono font
                    const fontSize = 13.0;
                    final availablePx =
                        (constraints.maxWidth - 32).clamp(100.0, 100000.0);
                    final charWidth =
                        fontSize * 0.6; // approximation for monospace
                    final maxChars = (availablePx / charWidth).floor();

                    final displayText = baseText.isEmpty
                        ? ''
                        : formatJsonWithLineNumbers(baseText,
                            maxLineWidth: maxChars);

                    // Keep search in sync with formatted text
                    if (searchManager.outputSearchQuery.isNotEmpty) {
                      searchManager.updateOutputMatches(
                          displayText, searchManager.outputSearchQuery);
                    }

                    if (_currentDisplayText != displayText) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _currentDisplayText = displayText;
                          });
                        }
                      });
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4, right: 6),
                            child: TextButton.icon(
                              onPressed: () {
                                // Copy unnumbered text (no gutter)
                                if (baseText.isNotEmpty) {
                                  Clipboard.setData(
                                      ClipboardData(text: baseText));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Copied to clipboard')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.copy, size: 18),
                              label: const Text('Copy output'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              return false;
                            },
                            child: SingleChildScrollView(
                              controller: widget.scrollController,
                              padding: const EdgeInsets.all(16),
                              child: Stack(
                                children: [
                                  // Background stripes under the text, not overlapping glyphs
                                  SizedBox(
                                    width: double.infinity,
                                    height: (displayText.isEmpty
                                            ? 0
                                            : ('\n'
                                                    .allMatches(displayText)
                                                    .length +
                                                1)) *
                                        (fontSize * 1.4),
                                    child: CustomPaint(
                                      painter: _AlternatingLinePainter(
                                        totalLines: displayText.isEmpty
                                            ? 0
                                            : '\n'
                                                    .allMatches(displayText)
                                                    .length +
                                                1,
                                        lineHeight: fontSize * 1.4,
                                        colorOdd: theme
                                            .colorScheme.surfaceVariant
                                            .withOpacity(0.08),
                                        colorEven: Colors.transparent,
                                      ),
                                    ),
                                  ),
                                  SelectableText.rich(
                                    HighlightBuilder(
                                      searchQuery:
                                          searchManager.outputSearchQuery,
                                      matches: searchManager.outputMatches,
                                      currentMatch:
                                          searchManager.outputCurrentMatch,
                                      theme: theme,
                                    ).build(
                                      displayText,
                                      textStyle: TextStyle(
                                        fontFamily: 'SF Mono',
                                        fontSize: fontSize,
                                        height: 1.4,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints alternating background stripes for each display line.
class _AlternatingLinePainter extends CustomPainter {
  final int totalLines;
  final double lineHeight;
  final Color colorOdd;
  final Color colorEven;

  _AlternatingLinePainter({
    required this.totalLines,
    required this.lineHeight,
    required this.colorOdd,
    required this.colorEven,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (int i = 0; i < totalLines; i++) {
      paint.color = (i % 2 == 0) ? colorOdd : colorEven;
      final top = i * lineHeight;
      final rect = Rect.fromLTWH(0, top, size.width, lineHeight);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AlternatingLinePainter oldDelegate) {
    return oldDelegate.totalLines != totalLines ||
        oldDelegate.lineHeight != lineHeight ||
        oldDelegate.colorOdd != colorOdd ||
        oldDelegate.colorEven != colorEven;
  }
}
