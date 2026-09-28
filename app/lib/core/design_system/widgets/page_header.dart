import 'package:flutter/material.dart';

import '../responsive/screen_size.dart';
import '../tokens/app_spacing.dart';

/// The title row at the top of a page, with its buttons on the right.
///
/// Replaces the app bar: it scrolls with the page and lines up with the
/// content below it instead of sitting in a separate band.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.actions,
    this.leading,
  });

  final String title;

  /// Buttons on the right, such as the bell and the profile menu.
  final List<Widget> actions;

  /// A back button, on the screens that need one.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Widget? leading = this.leading;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        ScreenSize.of(context).pageGap,
        AppSpacing.xl,
        ScreenSize.of(context).pageGap,
        AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          if (leading != null) ...<Widget>[
            leading,
            const SizedBox(width: AppSpacing.sm),
          ],
          // A long name must shrink rather than push the buttons off the edge.
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall,
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
