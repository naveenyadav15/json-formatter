import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SearchBarField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final int matchCount;
  final int currentMatch;
  final TextEditingController controller;
  final FocusNode focusNode; // Add FocusNode

  const SearchBarField({
    super.key,
    required this.hint,
    required this.onChanged,
    required this.onNext,
    required this.onPrev,
    required this.matchCount,
    required this.currentMatch,
    required this.controller,
    required this.focusNode, // Add to constructor
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: TextStyle(
                  fontFamily: 'SF Mono',
                  fontSize: 13,
                  color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: onChanged,
              onSubmitted: (_) {
                // Enter -> next match
                onNext();
              },
              inputFormatters: const <TextInputFormatter>[],
              // Handle Shift+Enter for previous
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              onEditingComplete: () {},
            ),
          ),
          // Key event handler for Shift+Enter
          Focus(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.enter) {
                final isShift = HardwareKeyboard.instance.logicalKeysPressed
                        .contains(LogicalKeyboardKey.shiftLeft) ||
                    HardwareKeyboard.instance.logicalKeysPressed
                        .contains(LogicalKeyboardKey.shiftRight);
                if (isShift) {
                  onPrev();
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: const SizedBox.shrink(),
          ),
          if (matchCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '${currentMatch + 1}/$matchCount',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up, size: 18),
            tooltip: 'Previous match',
            onPressed: matchCount > 0 ? onPrev : null,
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 18),
            tooltip: 'Next match',
            onPressed: matchCount > 0 ? onNext : null,
          ),
        ],
      ),
    );
  }
}
