import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart';

import '../helpers/helpers.dart';

void main() {
  group('AppBackButton', () {
    testWidgets('renders IconButton', (tester) async {
      await tester.pumpApp(
        Scaffold(
          appBar: AppBar(
            leading: const AppBackButton(),
          ),
        ),
      );

      expect(
        find.byType(IconButton),
        findsOneWidget,
      );
    });

    testWidgets('renders IconButton when light', (tester) async {
      await tester.pumpApp(
        Scaffold(
          appBar: AppBar(
            leading: const AppBackButton.light(),
          ),
        ),
      );

      expect(
        find.byType(IconButton),
        findsOneWidget,
      );
    });

    group('navigates', () {
      testWidgets('back when press the icon button', (tester) async {
        final navigator = MockNavigator();
        when(navigator.pop).thenAnswer((_) async {});
        await tester.pumpApp(
          const AppBackButton(),
          navigator: navigator,
        );
        await tester.tap(find.byType(IconButton));
        await tester.pumpAndSettle();
        verify(navigator.pop).called(1);
      });
    });
  });
}
