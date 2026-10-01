import 'package:flutter/material.dart';

import '../responsive/screen_size.dart';
import '../tokens/app_spacing.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.actions,
    this.leading,
  });

  final String title;

  /// buttons on right, bell and profile
  final List<Widget> actions;

  /// back button
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
          // long name shrink
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
