import 'package:activotrade_app/core/design_system/responsive/adaptive_two_column.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Key _primaryKey = Key('primary');
const Key _secondaryKey = Key('secondary');

void main() {
  // Asserts where the groups land, not which layout widget put them there.
  Future<void> pumpAt(WidgetTester tester, double width) {
    return tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: Size(width, 900)),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: AdaptiveTwoColumn(
            primary: <Widget>[SizedBox(key: _primaryKey, height: 100)],
            secondary: <Widget>[SizedBox(key: _secondaryKey, height: 100)],
          ),
        ),
      ),
    );
  }

  testWidgets('stacks the groups on a phone', (WidgetTester tester) async {
    await pumpAt(tester, 390);

    final Offset primary = tester.getTopLeft(find.byKey(_primaryKey));
    final Offset secondary = tester.getTopLeft(find.byKey(_secondaryKey));

    expect(secondary.dy, greaterThan(primary.dy));
    expect(secondary.dx, primary.dx);
  });

  testWidgets('still stacks on a small tablet', (WidgetTester tester) async {
    await pumpAt(tester, 900);

    final Offset primary = tester.getTopLeft(find.byKey(_primaryKey));
    final Offset secondary = tester.getTopLeft(find.byKey(_secondaryKey));

    expect(secondary.dy, greaterThan(primary.dy));
  });

  testWidgets('sets the groups side by side once wide', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, 1280);

    final Offset primary = tester.getTopLeft(find.byKey(_primaryKey));
    final Offset secondary = tester.getTopLeft(find.byKey(_secondaryKey));

    expect(secondary.dx, greaterThan(primary.dx));
    expect(secondary.dy, primary.dy);
  });

  testWidgets('gives the primary group the wider share', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, 1280);

    final Size primary = tester.getSize(find.byKey(_primaryKey));
    final Size secondary = tester.getSize(find.byKey(_secondaryKey));

    expect(primary.width, greaterThan(secondary.width));
  });
}
