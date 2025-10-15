import 'package:flutter/material.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:provider/provider.dart';
import '../../domain/json_formatter.dart';
import '../../domain/search_manager.dart';
import 'search_bar.dart';
import 'highlight_builder.dart';

class InputPanel extends StatefulWidget {
  final double splitRatio;
  final TextEditingController controller;
  final ScrollController scrollController;
  final FocusNode focusNode;
  final VoidCallback onPanelTap;
  final FocusNode searchFocusNode;

  const InputPanel({
    super.key,
    required this.splitRatio,
    required this.controller,
    required this.scrollController,
    required this.focusNode,
    required this.onPanelTap,
    required this.searchFocusNode,
  });

  @override
  State<InputPanel> createState() => _InputPanelState();
}

class _InputPanelState extends State<InputPanel> {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jsonFormatter = Provider.of<JsonFormatter>(context);
    final searchManager = Provider.of<SearchManager>(context);
    // Keep the search field in sync with the searchManager
    if (_searchController.text != searchManager.inputSearchQuery) {
      _searchController.text = searchManager.inputSearchQuery;
      _searchController.selection =
          TextSelection.collapsed(offset: _searchController.text.length);
    }
    return Expanded(
      flex: (widget.splitRatio * 100).round(),
      child: GestureDetector(
        onTap: widget.onPanelTap,
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
                hint: 'Search input',
                focusNode: widget.searchFocusNode,
                controller: _searchController,
                onChanged: (query) => searchManager.updateInputMatches(
                    jsonFormatter.input, query),
                onNext: searchManager.nextInputMatch,
                onPrev: searchManager.prevInputMatch,
                matchCount: searchManager.inputMatches.length,
                currentMatch: searchManager.inputCurrentMatch,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: ExtendedTextField(
                  onTap: widget.onPanelTap,
                  focusNode: widget.focusNode,
                  controller: widget.controller,
                  scrollController: widget.scrollController,
                  maxLines: null,
                  expands: true,
                  style: TextStyle(
                    fontFamily: 'SF Mono',
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                    height: 1.4,
                  ),
                  specialTextSpanBuilder: HighlightBuilder(
                    searchQuery: searchManager.inputSearchQuery,
                    matches: searchManager.inputMatches,
                    currentMatch: searchManager.inputCurrentMatch,
                    theme: theme,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    hintText: 'Paste your JSON here...',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontFamily: 'SF Mono',
                      fontSize: 13,
                    ),
                  ),
                  onChanged: (val) =>
                      context.read<JsonFormatter>().formatJson(val),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
