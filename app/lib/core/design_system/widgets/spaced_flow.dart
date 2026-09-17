import 'package:flutter/material.dart';

/// Puts one gap between children, so no layout has to repeat the loop itself.
List<Widget> _interleave(List<Widget> children, Widget gap) {
  return <Widget>[
    for (int index = 0; index < children.length; index++) ...<Widget>[
      if (index > 0) gap,
      children[index],
    ],
  ];
}

/// A column of full-width children with a single, even gap between them.
class SpacedColumn extends StatelessWidget {
  const SpacedColumn({super.key, required this.gap, required this.children});

  final double gap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _interleave(children, SizedBox(height: gap)),
    );
  }
}

/// Children of equal width, each as tall as the tallest, one gap between them.
class EqualWidthRow extends StatelessWidget {
  const EqualWidthRow({super.key, required this.gap, required this.children});

  final double gap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Bounds the row inside a scroll view, where the height is otherwise infinite.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _interleave(<Widget>[
          for (final Widget child in children) Expanded(child: child),
        ], SizedBox(width: gap)),
      ),
    );
  }
}
