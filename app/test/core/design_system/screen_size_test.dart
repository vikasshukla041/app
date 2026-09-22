import 'package:activotrade_app/core/design_system/responsive/screen_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Case = ({double width, ScreenSize expected});

// A breakpoint counts as the bigger class, so 768 already has the sidebar.
const List<_Case> _cases = <_Case>[
  (width: 320, expected: ScreenSize.compact),
  (width: 390, expected: ScreenSize.compact),
  (width: 767, expected: ScreenSize.compact),
  (width: 768, expected: ScreenSize.medium),
  (width: 1023, expected: ScreenSize.medium),
  (width: 1024, expected: ScreenSize.expanded),
  (width: 1920, expected: ScreenSize.expanded),
];

void main() {
  group('forWidth', () {
    for (final _Case testCase in _cases) {
      test('${testCase.width.toInt()}px is ${testCase.expected.name}', () {
        expect(ScreenSize.forWidth(testCase.width), testCase.expected);
      });
    }
  });

  group('of', () {
    // The path every widget actually takes, so this also tests MediaQuery.
    for (final _Case testCase in _cases) {
      final double width = testCase.width;
      final ScreenSize expected = testCase.expected;

      testWidgets('${width.toInt()}px is ${expected.name}', (
        WidgetTester tester,
      ) async {
        late ScreenSize observed;

        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(size: Size(width, 800)),
            child: Builder(
              builder: (BuildContext context) {
                observed = ScreenSize.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(observed, expected);
      });
    }
  });

  test('pick returns the value belonging to its own class', () {
    expect(ScreenSize.compact.pick(compact: 1, medium: 2, expanded: 3), 1);
    expect(ScreenSize.medium.pick(compact: 1, medium: 2, expanded: 3), 2);
    expect(ScreenSize.expanded.pick(compact: 1, medium: 2, expanded: 3), 3);
  });
}
