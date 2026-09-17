import 'package:activotrade_app/core/design_system/responsive/app_window_class.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Case = ({double width, AppWindowClass expected});

// A breakpoint belongs to the class above it, so 768 already has the sidebar.
const List<_Case> _cases = <_Case>[
  (width: 320, expected: AppWindowClass.compact),
  (width: 390, expected: AppWindowClass.compact),
  (width: 767, expected: AppWindowClass.compact),
  (width: 768, expected: AppWindowClass.medium),
  (width: 1023, expected: AppWindowClass.medium),
  (width: 1024, expected: AppWindowClass.expanded),
  (width: 1920, expected: AppWindowClass.expanded),
];

void main() {
  group('forWidth', () {
    for (final _Case testCase in _cases) {
      test('${testCase.width.toInt()}px is ${testCase.expected.name}', () {
        expect(AppWindowClass.forWidth(testCase.width), testCase.expected);
      });
    }
  });

  group('of', () {
    // The path every widget actually takes, so the MediaQuery wiring is covered too.
    for (final _Case testCase in _cases) {
      final double width = testCase.width;
      final AppWindowClass expected = testCase.expected;

      testWidgets('${width.toInt()}px is ${expected.name}', (
        WidgetTester tester,
      ) async {
        late AppWindowClass observed;

        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(size: Size(width, 800)),
            child: Builder(
              builder: (BuildContext context) {
                observed = AppWindowClass.of(context);
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
    expect(AppWindowClass.compact.pick(compact: 1, medium: 2, expanded: 3), 1);
    expect(AppWindowClass.medium.pick(compact: 1, medium: 2, expanded: 3), 2);
    expect(AppWindowClass.expanded.pick(compact: 1, medium: 2, expanded: 3), 3);
  });
}
