import 'package:flutter/material.dart';

/// gap between children, so no layout has to repeat
List<Widget> _interleave(List<Widget> children, Widget gap) {
  return <Widget>[
    for (int index = 0; index < children.length; index++) ...<Widget>[
      if (index > 0) gap,
      children[index],
    ],
  ];
}

/// column of full-width with gap between
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

class EqualWidthRow extends StatelessWidget {
  const EqualWidthRow({super.key, required this.gap, required this.children});

  final double gap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
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
