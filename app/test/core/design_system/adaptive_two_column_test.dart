import 'package:activotrade_app/core/design_system/responsive/adaptive_two_column.dart';
import 'package:activotrade_app/core/design_system/responsive/app_breakpoints.dart';
import 'package:activotrade_app/core/design_system/tokens/app_sizing.dart';
import 'package:activotrade_app/core/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Key _primaryKey = Key('primary');
const Key _secondaryKey = Key('secondary');

const Widget _columns = AdaptiveTwoColumn(
  primary: <Widget>[SizedBox(key: _primaryKey, height: 100)],
  secondary: <Widget>[SizedBox(key: _secondaryKey, height: 100)],
);

void main() {
  // Asserts where the groups land, not which layout widget put them there.
  Future<void> pumpAt(
    WidgetTester tester,
    double width, {
    Widget child = _columns,
  }) {
    // The test window is 800px unless told otherwise, which would clip wider cases.
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    return tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: Size(width, 900)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    );
  }

  bool sideBySide(WidgetTester tester) {
    final Offset primary = tester.getTopLeft(find.byKey(_primaryKey));
    final Offset secondary = tester.getTopLeft(find.byKey(_secondaryKey));
    return secondary.dx > primary.dx && secondary.dy == primary.dy;
  }

  testWidgets('stacks the groups on a phone', (WidgetTester tester) async {
    await pumpAt(tester, 390);

    final Offset primary = tester.getTopLeft(find.byKey(_primaryKey));
    final Offset secondary = tester.getTopLeft(find.byKey(_secondaryKey));

    expect(secondary.dy, greaterThan(primary.dy));
    expect(secondary.dx, primary.dx);
  });

  testWidgets('turns over exactly at the body breakpoint', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, AppBreakpoints.twoColumnBody - 1);
    expect(sideBySide(tester), isFalse);

    await pumpAt(tester, AppBreakpoints.twoColumnBody);
    expect(sideBySide(tester), isTrue);
  });

  testWidgets('reads its own width, not the window, beside the side menu', (
    WidgetTester tester,
  ) async {
    // The regression: a 1024px window split into two columns of about 330px.
    await pumpAt(
      tester,
      1024,
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: AppSizing.sideMenuWidth),
          Expanded(child: _columns),
        ],
      ),
    );

    expect(sideBySide(tester), isFalse);
  });

  testWidgets('keeps two columns in the layout they were approved at', (
    WidgetTester tester,
  ) async {
    // Old 80px menu, its 1px divider, then the page's side gaps.
    await pumpAt(
      tester,
      1024,
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 80),
          SizedBox(width: 1),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl3),
              child: _columns,
            ),
          ),
        ],
      ),
    );

    expect(sideBySide(tester), isTrue);
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
