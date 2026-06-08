import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llm_wiki_mobile/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final secureStorage = <String, String>{};

  setUp(() {
    secureStorage.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
          final arguments = call.arguments is Map
              ? Map<Object?, Object?>.from(call.arguments as Map)
              : <Object?, Object?>{};
          final key = arguments['key']?.toString();
          return switch (call.method) {
            'read' => key == null ? null : secureStorage[key],
            'write' => () {
              if (key != null) {
                secureStorage[key] = arguments['value']?.toString() ?? '';
              }
              return null;
            }(),
            'delete' => () {
              if (key != null) {
                secureStorage.remove(key);
              }
              return null;
            }(),
            'containsKey' => key != null && secureStorage.containsKey(key),
            'readAll' => Map<String, String>.from(secureStorage),
            'deleteAll' => secureStorage.clear(),
            _ => null,
          };
        });
  });

  test('repository restores persisted conversations', () async {
    final firstRepository = WikiRepository();
    await firstRepository.initialize();
    await firstRepository.createConversation(
      projectId: 'mobile',
      prompt: 'Remember this local-first SQLite persistence decision.',
    );

    final secondRepository = WikiRepository();
    await secondRepository.initialize();

    expect(
      secondRepository.conversations.first.title,
      contains('local-first SQLite'),
    );
  });

  test('repository creates projects and classifies conversations', () async {
    final repository = WikiRepository();
    await repository.initialize();
    final project = repository.createProject(
      name: '학교 과제',
      description: '발표와 구현 작업',
    );
    await repository.createConversation(
      projectId: project.id,
      prompt: '프로젝트별로 새 채팅을 분류해줘.',
    );

    final restored = WikiRepository();
    await restored.initialize();
    final projectChats = restored.search(
      query: '',
      projectId: project.id,
      selectedTags: const <String>{},
    );

    expect(restored.projects.map((item) => item.name), contains('학교 과제'));
    expect(projectChats, hasLength(1));
    expect(projectChats.first.projectId, project.id);
  });

  testWidgets('library shows saved knowledge and search works', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    await tester.pumpWidget(const LlmWikiApp());

    expect(find.text('LLM Wiki'), findsOneWidget);

    await tester.tap(find.text('라이브러리'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('library-search')));
    await tester.enterText(find.byKey(const Key('library-search')), 'keychain');
    await tester.pumpAndSettle();

    expect(find.text('API 키 보관 체크리스트'), findsOneWidget);
    expect(find.text('AI 대화 저장용 SQLite 스키마'), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'chat starts empty and hides security controls until options open',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1100));
      await tester.pumpWidget(const LlmWikiApp());

      expect(find.text('새 AI 채팅을 시작하세요'), findsOneWidget);
      expect(find.text('AI 대화 저장용 SQLite 스키마'), findsNothing);
      expect(find.textContaining('민감정보 마스킹'), findsNothing);

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      expect(find.text('메시지 옵션'), findsOneWidget);
      expect(find.text('민감정보 자동 마스킹'), findsOneWidget);
      expect(find.text('암호화된 로컬 데이터베이스'), findsOneWidget);
      expect(find.text('FaceID, 지문 또는 PIN 앱 잠금'), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('capture saves a new conversation with masking', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    await tester.pumpWidget(const LlmWikiApp());

    await tester.enterText(
      find.byKey(const Key('prompt-field')),
      'Use OpenAI with sk-testsecret123456789 and export markdown.',
    );
    await tester.tap(find.byKey(const Key('ask-save-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('API 키가 없어'), findsWidgets);

    await tester.tap(find.text('라이브러리'));
    await tester.pumpAndSettle();

    expect(find.textContaining('[masked]'), findsWidgets);
    expect(find.textContaining('sk-testsecret'), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('new chat action clears the active chat surface', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    await tester.pumpWidget(const LlmWikiApp());

    await tester.enterText(
      find.byKey(const Key('prompt-field')),
      'Start a focused project chat.',
    );
    await tester.tap(find.byKey(const Key('ask-save-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Start a focused'), findsWidgets);

    await tester.tap(find.byIcon(Icons.edit_square).first);
    await tester.pumpAndSettle();

    expect(find.text('새 AI 채팅을 시작하세요'), findsOneWidget);
    expect(find.textContaining('Start a focused'), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('saved conversations survive app restart', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    await tester.pumpWidget(const LlmWikiApp());

    await tester.enterText(
      find.byKey(const Key('prompt-field')),
      'Remember this local-first SQLite persistence decision.',
    );
    await tester.tap(find.byKey(const Key('ask-save-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('local-first SQLite'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const LlmWikiApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('local-first SQLite'), findsNothing);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.textContaining('local-first SQLite'), findsWidgets);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('settings can switch display language to English', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    await tester.pumpWidget(const LlmWikiApp());

    expect(find.text('AI 채팅'), findsWidgets);

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
