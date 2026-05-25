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

    expect(find.text('API key handling checklist'), findsOneWidget);
    expect(find.text('SQLite schema for saved AI chats'), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('capture saves a new conversation with masking', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    await tester.pumpWidget(const LlmWikiApp());

    await tester.tap(find.text('Capture'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('prompt-field')),
      'Use OpenAI with sk-testsecret123456789 and export markdown.',
    );
    await tester.tap(find.byKey(const Key('ask-save-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Saved'), findsWidgets);

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();

    expect(find.textContaining('[masked]'), findsWidgets);
    expect(find.textContaining('sk-testsecret'), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });
}
