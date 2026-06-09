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
    await tester.tap(find.byIcon(Icons.more_horiz));
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
