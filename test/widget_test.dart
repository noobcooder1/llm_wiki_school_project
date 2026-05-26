import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llm_wiki_mobile/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('library shows saved knowledge and search works', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    await tester.pumpWidget(const LlmWikiApp());

    expect(find.text('LLM Wiki'), findsOneWidget);

    await tester.tap(find.byKey(const Key('library-search')));
    await tester.enterText(find.byKey(const Key('library-search')), 'keychain');
    await tester.pumpAndSettle();

    expect(find.text('API 키 보관 체크리스트'), findsOneWidget);
    expect(find.text('AI 대화 저장용 SQLite 스키마'), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('capture saves a new conversation with masking', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    await tester.pumpWidget(const LlmWikiApp());

    await tester.tap(find.text('캡처'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('prompt-field')),
      'Use OpenAI with sk-testsecret123456789 and export markdown.',
    );
    await tester.tap(find.byKey(const Key('ask-save-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('저장했습니다'), findsWidgets);

    await tester.tap(find.text('라이브러리'));
    await tester.pumpAndSettle();

    expect(find.textContaining('[masked]'), findsWidgets);
    expect(find.textContaining('sk-testsecret'), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('settings can switch display language to English', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    await tester.pumpWidget(const LlmWikiApp());

    expect(find.text('라이브러리'), findsOneWidget);

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Library'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
