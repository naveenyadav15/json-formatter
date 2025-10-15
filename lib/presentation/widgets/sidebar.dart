import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../domain/json_formatter.dart';
import '../../domain/search_manager.dart';

class Sidebar extends StatelessWidget {
  final VoidCallback onClearAll;

  const Sidebar({
    super.key,
    required this.onClearAll,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final jsonFormatter = Provider.of<JsonFormatter>(context);

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface.withOpacity(0.8) : theme
            .colorScheme.surface,
        border: Border(right: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2), width: 1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.code, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'JSON Formatter',
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Actions',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.clear_all,
                  label: 'Clear All',
                  onPressed: onClearAll
                ),
                const SizedBox(height: 8),
                _ActionButton(
                  icon: Icons.copy,
                  label: 'Copy Output',
                  onPressed: () {
                    if (jsonFormatter.output.isNotEmpty) {
                      Clipboard.setData(
                          ClipboardData(text: jsonFormatter.output));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Paste JSON to format and beautify',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton(
      {required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          alignment: Alignment.centerLeft,
          backgroundColor: Colors.transparent,
          foregroundColor: theme.colorScheme.onSurface,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(label, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}