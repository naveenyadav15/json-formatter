import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grafna/domain/search_manager.dart';
import 'package:provider/provider.dart';
import '../../domain/json_formatter.dart';
import 'search_bar.dart';
import 'highlight_builder.dart';
import 'line_number_gutter.dart';

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

  void _scrollToCurrentMatch(
      SearchManager searchManager, JsonFormatter jsonFormatter) {
    if (searchManager.outputMatches.isEmpty) return;
    final match = searchManager.outputMatches[searchManager.outputCurrentMatch];
    final text = jsonFormatter.error.isNotEmpty
        ? jsonFormatter.error
        : jsonFormatter.output;
    final beforeMatch = text.substring(0, match.start);
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
                    _scrollToCurrentMatch(searchManager, jsonFormatter);
                  });
                },
                onNext: () {
                  searchManager.nextOutputMatch();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToCurrentMatch(searchManager, jsonFormatter);
                  });
                },
                onPrev: () {
                  searchManager.prevOutputMatch();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToCurrentMatch(searchManager, jsonFormatter);
                  });
                },
                matchCount: searchManager.outputMatches.length,
                currentMatch: searchManager.outputCurrentMatch,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, right: 6),
                  child: TextButton.icon(
                    onPressed: () {
                      final text = jsonFormatter.error.isNotEmpty
                          ? jsonFormatter.error
                          : jsonFormatter.output;
                      if (text.isNotEmpty) {
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Line numbers based on output or error text
                    AnimatedBuilder(
                      animation: jsonFormatter,
                      builder: (context, _) {
                        final text = jsonFormatter.error.isNotEmpty
                            ? jsonFormatter.error
                            : jsonFormatter.output;
                        final totalLines = text.split('\n').length;
                        return LineNumberGutter(
                          totalLines: totalLines,
                          scrollOffset: widget.scrollController.hasClients
                              ? widget.scrollController.offset
                              : 0.0,
                          lineHeight: 15.0,
                          width: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        );
                      },
                    ),
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          return false;
                        },
                        child: SingleChildScrollView(
                          controller: widget.scrollController,
                          padding: const EdgeInsets.all(16),
                          child: SelectableText.rich(
                            HighlightBuilder(
                              searchQuery: searchManager.outputSearchQuery,
                              matches: searchManager.outputMatches,
                              currentMatch: searchManager.outputCurrentMatch,
                              theme: theme,
                            ).build(
                              jsonFormatter.error.isNotEmpty
                                  ? jsonFormatter.error
                                  : jsonFormatter.output,
                              textStyle: TextStyle(
                                fontFamily: 'SF Mono',
                                fontSize: 13,
                                height: 1.4,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
