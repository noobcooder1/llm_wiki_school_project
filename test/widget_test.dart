import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
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

  Future<void> createProjectInUi(WidgetTester tester, String name) async {
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.text('새 프로젝트'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('new-project-name-field')),
      name,
    );
    await tester.tap(find.byKey(const Key('create-project-button')));
    await tester.pumpAndSettle();
  }

  test('repository restores persisted conversations', () async {
    final firstRepository = WikiRepository();
    await firstRepository.initialize();
    final project = firstRepository.createProject(name: '테스트 프로젝트');
    await firstRepository.createConversation(
      projectId: project.id,
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

  test('repository manages conversations and projects', () async {
    final repository = WikiRepository();
    await repository.initialize();
    final firstProject = repository.createProject(name: '첫 프로젝트');
    final secondProject = repository.createProject(name: '둘 프로젝트');
    final result = await repository.createConversation(
      projectId: firstProject.id,
      prompt: '관리 기능 테스트 대화',
    );

    repository.renameConversation(
      conversationId: result.conversation.id,
      title: '수정된 대화 제목',
    );
    expect(
      repository.conversationById(result.conversation.id)?.title,
      '수정된 대화 제목',
    );

    repository.moveConversation(
      conversationId: result.conversation.id,
      projectId: secondProject.id,
    );
    expect(
      repository.conversationById(result.conversation.id)?.projectId,
      secondProject.id,
    );

    final deletedConversation = repository.deleteConversation(
      result.conversation.id,
    );
    expect(deletedConversation, isNotNull);
    expect(repository.conversationById(result.conversation.id), isNull);
    expect(repository.trashedItems, hasLength(1));
    expect(repository.trashedItems.first.type, TrashItemType.conversation);
    repository.restoreTrashItem(repository.trashedItems.first.id);
    expect(repository.conversationById(result.conversation.id), isNotNull);
    expect(repository.trashedItems, isEmpty);

    repository.updateProject(projectId: secondProject.id, name: '변경된 프로젝트');
    expect(repository.projectById(secondProject.id).name, '변경된 프로젝트');

    final deletedProject = repository.deleteProject(secondProject.id);
    expect(deletedProject, isNotNull);
    expect(
      repository.projects.any((project) => project.id == secondProject.id),
      isFalse,
    );
    expect(repository.trashedItems, hasLength(1));
    expect(repository.trashedItems.first.type, TrashItemType.project);
    expect(repository.trashedItems.first.conversationCount, 1);
    repository.restoreTrashItem(repository.trashedItems.first.id);
    expect(
      repository.projects.any((project) => project.id == secondProject.id),
      isTrue,
    );
    expect(repository.conversationById(result.conversation.id), isNotNull);
    expect(repository.trashedItems, isEmpty);
    expect(deletedProject, isNotNull);
  });

  test('repository persists trash and restores from trash item', () async {
    final repository = WikiRepository();
    await repository.initialize();
    final project = repository.createProject(name: '휴지통 테스트');
    final result = await repository.createConversation(
      projectId: project.id,
      prompt: '나중에 복원할 대화',
    );

    repository.deleteConversation(result.conversation.id);
    await Future<void>.delayed(Duration.zero);

    final restoredRepository = WikiRepository();
    await restoredRepository.initialize();

    expect(restoredRepository.conversationById(result.conversation.id), isNull);
    expect(restoredRepository.trashedItems, hasLength(1));
    restoredRepository.restoreTrashItem(
      restoredRepository.trashedItems.first.id,
    );
    expect(
      restoredRepository.conversationById(result.conversation.id),
      isNotNull,
    );
    expect(restoredRepository.trashedItems, isEmpty);
  });

  test('conversation auto-generates Korean health tags', () {
    final now = DateTime.now();
    final conversation = Conversation(
      id: 'conv-health',
      projectId: 'health',
      title: '목은 체지방들은 빼기가 어렵니?',
      createdAt: now,
      updatedAt: now,
      messages: [
        KnowledgeMessage(
          id: 'msg-user',
          role: AiRole.user,
          content: '목은 체지방들은 빼기가 어렵니?',
          createdAt: now,
        ),
        KnowledgeMessage(
          id: 'msg-ai',
          role: AiRole.assistant,
          content: '체지방 감량에는 식단, 운동, 신진대사 관리가 중요합니다.',
          createdAt: now,
        ),
      ],
    );

    expect(conversation.tags, containsAll(['체지방', '다이어트', '건강']));
  });

  test('conversation auto-generates tags for arbitrary topics', () {
    final now = DateTime.now();
    final historyConversation = Conversation(
      id: 'conv-history',
      projectId: 'study',
      title: '프랑스 혁명',
      createdAt: now,
      updatedAt: now,
      messages: [
        KnowledgeMessage(
          id: 'msg-history-user',
          role: AiRole.user,
          content: '프랑스 혁명의 원인과 나폴레옹 시대를 요약해줘.',
          createdAt: now,
        ),
        KnowledgeMessage(
          id: 'msg-history-ai',
          role: AiRole.assistant,
          content: '프랑스 혁명은 계몽사상, 신분제, 재정 위기와 연결됩니다.',
          createdAt: now,
        ),
      ],
    );
    final climateConversation = Conversation(
      id: 'conv-climate',
      projectId: 'study',
      title: '기후 변화',
      createdAt: now,
      updatedAt: now,
      messages: [
        KnowledgeMessage(
          id: 'msg-climate-user',
          role: AiRole.user,
          content: '기후 변화와 탄소 배출권의 관계를 알려줘.',
          createdAt: now,
        ),
        KnowledgeMessage(
          id: 'msg-climate-ai',
          role: AiRole.assistant,
          content: '탄소 배출권은 온실가스 감축을 유도하는 시장 기반 정책입니다.',
          createdAt: now,
        ),
      ],
    );

    expect(historyConversation.tags, containsAll(['프랑스', '혁명', '나폴레옹']));
    expect(climateConversation.tags, containsAll(['기후', '변화', '탄소', '배출권']));
  });

  test('conversation skips connective endings and sentence filler tags', () {
    final now = DateTime.now();
    final conversation = Conversation(
      id: 'conv-connectives',
      projectId: 'study',
      title: '미래 전망',
      createdAt: now,
      updatedAt: now,
      messages: [
        KnowledgeMessage(
          id: 'msg-connective-user',
          role: AiRole.user,
          content: '그렇다면 추후의 미래에는 전망이 어떻게 변할까?',
          createdAt: now,
        ),
        KnowledgeMessage(
          id: 'msg-connective-ai',
          role: AiRole.assistant,
          content: '미래 전망은 AI 기술과 사회 변화에 따라 달라질 것입니다.',
          createdAt: now,
        ),
      ],
    );

    expect(conversation.tags, containsAll(['미래', '전망']));
    expect(conversation.tags, isNot(contains('그렇다면')));
    expect(conversation.tags, isNot(contains('변할까')));
    expect(conversation.tags, isNot(contains('것입니다')));
    expect(conversation.tags, isNot(contains('그렇다면-추후')));
  });

  test('conversation ignores assistant failure text when generating tags', () {
    final now = DateTime.now();
    final conversation = Conversation(
      id: 'conv-error-tags',
      projectId: 'coding',
      title: '플러터 장점',
      createdAt: now,
      updatedAt: now,
      messages: [
        KnowledgeMessage(
          id: 'msg-error-user',
          role: AiRole.user,
          content: '플러터의 장점은 뭐야?',
          createdAt: now,
        ),
        KnowledgeMessage(
          id: 'msg-error-ai',
          role: AiRole.assistant,
          content:
              'AI 답변 생성에 실패했습니다. 원본 오류: Your project has been denied access. Please contact support.',
          createdAt: now,
        ),
      ],
    );

    expect(conversation.tags, contains('flutter'));
    expect(conversation.tags, isNot(contains('api-key')));
    expect(conversation.tags, isNot(contains('contact-support')));
    expect(conversation.tags, isNot(contains('denied-access')));
  });

  test(
    'repository saves prompt-derived tags before ai response succeeds',
    () async {
      final repository = WikiRepository();
      await repository.initialize();
      final project = repository.createProject(name: '건강 질문');

      final result = await repository.createConversation(
        projectId: project.id,
        prompt: '목은 체지방들은 빼기가 어렵니?',
      );

      expect(result.conversation.manualTags, containsAll(['체지방', '다이어트']));
      expect(result.conversation.tags, containsAll(['체지방', '다이어트']));
    },
  );

  test('repository can save reviewed title and tags only', () async {
    final repository = WikiRepository();
    await repository.initialize();
    final project = repository.createProject(name: '검토 저장');
    final preview = repository.previewConversationMetadata(
      'Flutter hot reload 정리',
    );

    expect(preview.title, contains('Flutter hot reload'));
    expect(preview.tags, contains('flutter'));

    final result = await repository.createConversation(
      projectId: project.id,
      prompt: 'Flutter hot reload 정리',
      reviewedTitle: '직접 정한 제목',
      reviewedTags: const ['직접태그'],
      metadataReviewed: true,
    );

    expect(result.conversation.title, '직접 정한 제목');
    expect(result.conversation.manualTags, ['직접태그']);
    expect(result.conversation.tags, ['직접태그']);
  });

  test('repository stores provider api keys independently', () async {
    final repository = WikiRepository();
    await repository.initialize();

    expect(repository.settings.aiProvider, AiProvider.gemini);
    expect(repository.settings.apiKeySaved, isFalse);

    expect(await repository.saveApiKey('AIza-test-gemini-key'), isTrue);
    expect(repository.settings.apiKeySaved, isTrue);
    final firstGeminiKeyId = repository.activeApiKeyIdFor(AiProvider.gemini);
    expect(repository.apiKeysFor(AiProvider.gemini), hasLength(1));

    expect(await repository.saveApiKey('AIza-second-gemini-key'), isTrue);
    expect(repository.apiKeysFor(AiProvider.gemini), hasLength(2));
    expect(
      repository.activeApiKeyIdFor(AiProvider.gemini),
      isNot(firstGeminiKeyId),
    );

    await repository.selectApiKey(AiProvider.gemini, firstGeminiKeyId!);
    expect(repository.activeApiKeyIdFor(AiProvider.gemini), firstGeminiKeyId);

    await repository.updateAiProvider(AiProvider.openAi);
    expect(repository.settings.apiKeySaved, isFalse);

    expect(await repository.saveApiKey('sk-test-openai-key'), isTrue);
    expect(repository.settings.apiKeySaved, isTrue);

    await repository.updateAiProvider(AiProvider.anthropic);
    expect(repository.settings.apiKeySaved, isFalse);

    expect(await repository.saveApiKey('sk-ant-test-claude-key'), isTrue);
    expect(repository.settings.apiKeySaved, isTrue);

    await repository.updateAiProvider(AiProvider.xAi);
    expect(repository.settings.apiKeySaved, isFalse);

    expect(await repository.saveApiKey('xai-test-grok-key'), isTrue);
    expect(repository.settings.apiKeySaved, isTrue);

    await repository.updateAiProvider(AiProvider.gemini);
    expect(repository.settings.apiKeySaved, isTrue);
  });

  test('repository migrates legacy provider api key into key list', () async {
    secureStorage['gemini_api_key'] = 'AIza-legacy-gemini-key';

    final repository = WikiRepository();
    await repository.initialize();

    expect(repository.apiKeysFor(AiProvider.gemini), hasLength(1));
    expect(
      repository.apiKeysFor(AiProvider.gemini).single.maskedValue,
      contains('AIza-l'),
    );
    expect(repository.activeApiKeyIdFor(AiProvider.gemini), isNotNull);
    expect(repository.settings.apiKeySaved, isTrue);
  });

  test(
    'gemini client uses supported model endpoint and api key header',
    () async {
      late http.Request capturedRequest;
      final client = _RecordingHttpClient((request) {
        capturedRequest = request;
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': '응답 완료'},
                    ],
                  },
                },
              ],
            }),
          ),
          200,
        );
      });

      final answer = await GeminiClient(httpClient: client).generateAnswer(
        apiKey: 'AIza-test-key',
        prompt: '테스트',
        language: AppLanguage.ko,
      );

      expect(answer, '응답 완료');
      expect(
        capturedRequest.url.toString(),
        contains('models/gemini-2.5-flash-lite:generateContent'),
      );
      expect(capturedRequest.headers['x-goog-api-key'], 'AIza-test-key');
    },
  );

  test(
    'gemini client falls back when the light model is unavailable',
    () async {
      final requestedUrls = <String>[];
      final client = _RecordingHttpClient((request) {
        requestedUrls.add(request.url.toString());
        if (requestedUrls.length == 1) {
          return http.Response(
            jsonEncode({
              'error': {'message': 'Model not found.'},
            }),
            404,
          );
        }
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'fallback 응답'},
                    ],
                  },
                },
              ],
            }),
          ),
          200,
        );
      });

      final answer = await GeminiClient(httpClient: client).generateAnswer(
        apiKey: 'AIza-test-key',
        prompt: '테스트',
        language: AppLanguage.ko,
      );

      expect(answer, 'fallback 응답');
      expect(requestedUrls, hasLength(2));
      expect(requestedUrls.first, contains('gemini-2.5-flash-lite'));
      expect(requestedUrls.last, contains('gemini-2.5-flash'));
    },
  );

  test('gemini client explains project permission failures', () async {
    final client = _RecordingHttpClient(
      (_) => http.Response(
        jsonEncode({
          'error': {
            'message':
                'Your project has been denied access. Please contact support.',
          },
        }),
        403,
      ),
    );

    expect(
      () => GeminiClient(httpClient: client).generateAnswer(
        apiKey: 'AIza-test-key',
        prompt: '테스트',
        language: AppLanguage.ko,
      ),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Google 프로젝트 권한이 거절'),
        ),
      ),
    );
  });

  testWidgets('library starts without dummy projects chats or tags', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    await tester.pumpWidget(const LlmWikiApp());

    expect(find.text('LLM Wiki'), findsOneWidget);

    await tester.tap(find.text('라이브러리'));
    await tester.pumpAndSettle();

    expect(find.text('저장된 대화 0개'), findsOneWidget);
    expect(find.text('일치하는 지식이 없습니다'), findsOneWidget);
    expect(find.text('모바일 앱'), findsNothing);
    expect(find.text('리서치'), findsNothing);
    expect(find.text('보안'), findsNothing);
    expect(find.textContaining('#'), findsNothing);
    expect(find.text('API 키 보관 체크리스트'), findsNothing);
    expect(find.text('AI 대화 저장용 SQLite 스키마'), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('library collapses tags and expands them on demand', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    final repository = WikiRepository();
    await repository.initialize();
    final project = repository.createProject(name: '태그 정리');
    final now = DateTime.now();
    repository.conversations = List.generate(10, (index) {
      return Conversation(
        id: 'conv-tag-$index',
        projectId: project.id,
        title: '태그 대화 $index',
        createdAt: now.add(Duration(minutes: index)),
        updatedAt: now.add(Duration(minutes: index)),
        manualTags: ['공통', '태그$index'],
        metadataReviewed: true,
        messages: [
          KnowledgeMessage(
            id: 'msg-tag-$index',
            role: AiRole.user,
            content: '태그 화면 정리 $index',
            createdAt: now.add(Duration(minutes: index)),
          ),
        ],
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LibraryPage(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.tagUsage.first.key, '공통');
    expect(find.widgetWithText(FilterChip, '#공통'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, '#태그9'), findsNothing);
    expect(find.textContaining('더보기'), findsOneWidget);

    await tester.tap(find.textContaining('더보기'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilterChip, '#태그9'), findsOneWidget);
    expect(find.text('태그 접기'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('library defaults to grouped project view', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    await tester.pumpWidget(const LlmWikiApp());

    await tester.tap(find.text('라이브러리'));
    await tester.pumpAndSettle();

    expect(find.text('프로젝트별'), findsOneWidget);
    expect(find.text('전체 채팅'), findsOneWidget);
    expect(find.text('휴지통'), findsOneWidget);
    expect(find.text('휴지통이 비어 있습니다'), findsOneWidget);
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
    await createProjectInUi(tester, '마스킹 테스트');

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
    await createProjectInUi(tester, '새 채팅 테스트');

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

  testWidgets('chat overflow menu manages the active conversation', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    await tester.pumpWidget(const LlmWikiApp());
    await createProjectInUi(tester, '관리 테스트');

    await tester.enterText(find.byKey(const Key('prompt-field')), '삭제 전 대화');
    await tester.tap(find.byKey(const Key('ask-save-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();

    expect(find.text('이름 변경'), findsOneWidget);
    expect(find.text('프로젝트 이동'), findsOneWidget);
    expect(find.text('휴지통으로 이동'), findsOneWidget);

    await tester.tap(find.text('이름 변경'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '관리 메뉴 변경 제목');
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();

    expect(find.text('관리 메뉴 변경 제목'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text('휴지통으로 이동'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('휴지통으로 이동'));
    await tester.pumpAndSettle();

    expect(find.text('새 AI 채팅을 시작하세요'), findsOneWidget);
    expect(find.text('관리 메뉴 변경 제목'), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('library refreshes immediately after moving a chat to trash', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    await tester.pumpWidget(const LlmWikiApp());
    await createProjectInUi(tester, '즉시 갱신 테스트');

    await tester.enterText(
      find.byKey(const Key('prompt-field')),
      '라이브러리 삭제 테스트',
    );
    await tester.tap(find.byKey(const Key('ask-save-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('라이브러리'));
    await tester.pumpAndSettle();

    expect(find.textContaining('라이브러리 삭제 테스트'), findsWidgets);

    await tester.tap(find.byTooltip('관리').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('휴지통으로 이동'));
    await tester.pumpAndSettle();

    expect(find.textContaining('라이브러리 삭제 테스트'), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('metadata review option asks before saving chat', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    await tester.pumpWidget(const LlmWikiApp());

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('저장 전 제목/태그 확인'));
    await tester.tap(find.text('저장 전 제목/태그 확인'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.chat_bubble_outline));
    await tester.pumpAndSettle();
    await createProjectInUi(tester, '메타데이터 검토');

    await tester.enterText(
      find.byKey(const Key('prompt-field')),
      'Flutter hot reload 정리',
    );
    await tester.tap(find.byKey(const Key('ask-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('저장 전 확인'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('metadata-title-field')),
      '직접 수정한 제목',
    );
    await tester.enterText(
      find.byKey(const Key('metadata-tags-field')),
      '#직접태그, #검토',
    );
    await tester.tap(find.byKey(const Key('metadata-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('직접 수정한 제목'), findsOneWidget);

    await tester.tap(find.text('라이브러리'));
    await tester.pumpAndSettle();

    expect(find.text('#직접태그'), findsWidgets);
    expect(find.text('#flutter'), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('chat menu opens a searchable side drawer', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    await tester.pumpWidget(const LlmWikiApp());
    await createProjectInUi(tester, '검색 테스트');

    await tester.enterText(
      find.byKey(const Key('prompt-field')),
      '검색 가능한 채팅 목록을 확인해줘.',
    );
    await tester.tap(find.byKey(const Key('ask-save-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-drawer-search')), findsOneWidget);
    expect(find.text('새 채팅'), findsWidgets);
    expect(find.text('프로젝트별 채팅 보기'), findsOneWidget);
    expect(find.textContaining('검색 가능한 채팅'), findsWidgets);
    expect(find.textContaining('#'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('chat-drawer-search')),
      '없는 대화',
    );
    await tester.pumpAndSettle();

    expect(find.text('아직 최근 채팅이 없습니다'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('saved conversations survive app restart', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    await tester.pumpWidget(const LlmWikiApp());
    await createProjectInUi(tester, '복원 테스트');

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

  testWidgets('settings can choose Gemini, GPT, Claude, or Grok key storage', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    await tester.pumpWidget(const LlmWikiApp());

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Gemini API 키'), findsOneWidget);
    expect(find.text('구현 경계'), findsNothing);

    await tester.tap(find.byKey(const Key('ai-provider-menu')));
    await tester.pumpAndSettle();
    expect(find.text('GPT / OpenAI'), findsWidgets);
    expect(find.text('Claude'), findsWidgets);
    expect(find.text('Grok'), findsWidgets);

    await tester.tap(find.text('Claude').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Claude API 키'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('settings shows saved api keys and active selection', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    await tester.pumpWidget(const LlmWikiApp());

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();

    expect(find.text('아직 등록된 키가 없습니다'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('api-key-field')),
      'AIza-visible-gemini-key-1234',
    );
    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();

    expect(find.text('등록된 API 키'), findsOneWidget);
    expect(find.textContaining('AIza-v'), findsOneWidget);
    expect(find.textContaining('1234'), findsOneWidget);
    expect(find.text('사용 중'), findsOneWidget);
    expect(find.textContaining('visible-gemini-key'), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });
}

class _RecordingHttpClient extends http.BaseClient {
  _RecordingHttpClient(this.handler);

  final http.Response Function(http.Request request) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final typedRequest = request as http.Request;
    final response = handler(typedRequest);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
    );
  }
}
