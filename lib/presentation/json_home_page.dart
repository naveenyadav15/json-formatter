import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../domain/json_formatter.dart';
import '../domain/search_manager.dart';
import 'widgets/input_panel.dart';
import 'widgets/output_panel.dart';
// import 'widgets/sidebar.dart';

// App-wide intents (top-level)
class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

class _NextMatchIntent extends Intent {
  const _NextMatchIntent();
}

class _PrevMatchIntent extends Intent {
  const _PrevMatchIntent();
}

class _ClearAllIntent extends Intent {
  const _ClearAllIntent();
}

class _CopyOutputIntent extends Intent {
  const _CopyOutputIntent();
}

class JsonHomePage extends StatefulWidget {
  const JsonHomePage({super.key});

  @override
  State<JsonHomePage> createState() => _JsonHomePageState();
}

class _JsonHomePageState extends State<JsonHomePage> {
  double _splitRatio = 0.5;
  final _inputController = TextEditingController();
  final _inputScrollController = ScrollController();
  final _outputScrollController = ScrollController();
  final _inputFieldFocusNode = FocusNode();
  final _inputSearchFocusNode = FocusNode(); // FocusNode for input search bar
  final _outputSearchFocusNode = FocusNode();
  bool _outputPanelActive = false;
  late final JsonFormatter jsonFormatter;
  late final SearchManager searchManager;

  @override
  void initState() {
    super.initState();
    jsonFormatter = Provider.of<JsonFormatter>(context, listen: false);
    searchManager = Provider.of<SearchManager>(context, listen: false);
  }

  void clearAll() {
    _inputController.clear();
    jsonFormatter.clear();
    searchManager.clear();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputScrollController.dispose();
    _outputScrollController.dispose();
    _inputFieldFocusNode.dispose();
    _inputSearchFocusNode.dispose();
    _outputSearchFocusNode.dispose();
    super.dispose();
  }

  void _scrollToInputMatch(SearchManager searchManager) {
    if (searchManager.inputMatches.isEmpty) return;
    final match = searchManager.inputMatches[searchManager.inputCurrentMatch];
    _inputController.selection =
        TextSelection(baseOffset: match.start, extentOffset: match.end);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final text = _inputController.text;
      final beforeMatch = text.substring(0, match.start);
      final lineCount = '\n'.allMatches(beforeMatch).length;
      final offset = (lineCount * 20.0) - 16.0;
      _inputScrollController.animateTo(
        offset < 0 ? 0 : offset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    });
  }

  void _scrollToOutputMatch(SearchManager searchManager) {
    if (searchManager.outputMatches.isEmpty) return;
    final match = searchManager.outputMatches[searchManager.outputCurrentMatch];
    final text = context.read<JsonFormatter>().error.isNotEmpty
        ? context.read<JsonFormatter>().error
        : context.read<JsonFormatter>().output;
    final beforeMatch = text.substring(0, match.start);
    final lineCount = '\n'.allMatches(beforeMatch).length;
    final offset = (lineCount * 20.0) - 16.0;
    _outputScrollController.animateTo(
      offset < 0 ? 0 : offset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (searchManager.inputMatches.isNotEmpty) {
      _scrollToInputMatch(searchManager);
    }
    if (searchManager.outputMatches.isNotEmpty) {
      _scrollToOutputMatch(searchManager);
    }

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        // Focus search: Cmd/Ctrl+F
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyF):
            const _FocusSearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
            const _FocusSearchIntent(),
        // Next match: Cmd/Ctrl+G, F3
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyG):
            const _NextMatchIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyG):
            const _NextMatchIntent(),
        SingleActivator(LogicalKeyboardKey.f3): const _NextMatchIntent(),
        // Prev match: Shift+Cmd/Ctrl+G, Shift+F3
        SingleActivator(LogicalKeyboardKey.keyG, control: true, shift: true):
            const _PrevMatchIntent(),
        SingleActivator(LogicalKeyboardKey.keyG, meta: true, shift: true):
            const _PrevMatchIntent(),
        SingleActivator(LogicalKeyboardKey.f3, shift: true):
            const _PrevMatchIntent(),
        // Clear all: Cmd/Ctrl+K
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK):
            const _ClearAllIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK):
            const _ClearAllIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _FocusSearchIntent: CallbackAction<_FocusSearchIntent>(
            onInvoke: (intent) {
              if (_outputPanelActive) {
                _outputSearchFocusNode.requestFocus();
              } else {
                _inputSearchFocusNode.requestFocus();
              }
              return null;
            },
          ),
          _NextMatchIntent: CallbackAction<_NextMatchIntent>(
            onInvoke: (intent) {
              if (_outputPanelActive) {
                searchManager.nextOutputMatch();
                _scrollToOutputMatch(searchManager);
              } else {
                searchManager.nextInputMatch();
                _scrollToInputMatch(searchManager);
              }
              return null;
            },
          ),
          _PrevMatchIntent: CallbackAction<_PrevMatchIntent>(
            onInvoke: (intent) {
              if (_outputPanelActive) {
                searchManager.prevOutputMatch();
                _scrollToOutputMatch(searchManager);
              } else {
                searchManager.prevInputMatch();
                _scrollToInputMatch(searchManager);
              }
              return null;
            },
          ),
          _ClearAllIntent: CallbackAction<_ClearAllIntent>(
            onInvoke: (intent) {
              clearAll();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cleared input and output')),
              );
              return null;
            },
          ),
        },
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildToolbar(theme),
                    Expanded(
                      child: Row(
                        children: [
                          InputPanel(
                              splitRatio: _splitRatio,
                              controller: _inputController,
                              scrollController: _inputScrollController,
                              focusNode: _inputFieldFocusNode,
                              searchFocusNode: _inputSearchFocusNode,
                              onPanelTap: () {
                                setState(() => _outputPanelActive = false);
                              }),
                          _buildResizeHandle(theme),
                          OutputPanel(
                            splitRatio: _splitRatio,
                            scrollController: _outputScrollController,
                            searchFocusNode: _outputSearchFocusNode,
                            onPanelTap: () {
                              setState(() => _outputPanelActive = true);
                            },
                          ),
                        ],
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

  Widget _buildToolbar(ThemeData theme) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        // border: Border(
        //     bottom: theme.colorScheme.outline.withValues(alpha: 0.2), width: 1,),
      ),
      child: Row(
        children: [
          Text('Grafna Input',
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text('Formatted JSON Output',
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildResizeHandle(ThemeData theme) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          final newRatio = _splitRatio +
              (details.delta.dx / MediaQuery.of(context).size.width);
          _splitRatio = newRatio.clamp(0.2, 0.8);
        });
      },
      child: Container(
        width: 4,
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.outline.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
