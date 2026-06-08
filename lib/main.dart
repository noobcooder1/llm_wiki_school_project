import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const LlmWikiApp());
}

class LlmWikiApp extends StatelessWidget {
  const LlmWikiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF176B5D),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'LLM Wiki',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko'), Locale('en'), Locale('ja')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F5EF),
        appBarTheme: const AppBarTheme(centerTitle: false),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE3DFD3)),
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const WikiShell(),
    );
  }
}

enum AiRole { user, assistant }

enum AppLanguage {
  ko('ko', '한국어'),
  en('en', 'English'),
  ja('ja', '日本語');

  const AppLanguage(this.code, this.label);

  final String code;
  final String label;
}

extension AiRoleStorage on AiRole {
  String get storageValue {
    return switch (this) {
      AiRole.user => 'user',
      AiRole.assistant => 'assistant',
    };
  }

  static AiRole fromStorageValue(String? value) {
    return switch (value) {
      'assistant' => AiRole.assistant,
      _ => AiRole.user,
    };
  }
}

extension AppLanguageStorage on AppLanguage {
  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (language) => language.code == code,
      orElse: () => AppLanguage.ko,
    );
  }
}

class AppText {
  const AppText(this.language);

  final AppLanguage language;

  static AppText of(AppLanguage language) => AppText(language);

  String pick({required String ko, required String en, required String ja}) {
    return switch (language) {
      AppLanguage.ko => ko,
      AppLanguage.en => en,
      AppLanguage.ja => ja,
    };
  }

  String get copyMarkdownExport => pick(
    ko: '마크다운 내보내기 복사',
    en: 'Copy markdown export',
    ja: 'Markdownエクスポートをコピー',
  );
  String get markdownCopied =>
      pick(ko: '마크다운을 복사했습니다', en: 'Markdown copied', ja: 'Markdownをコピーしました');
  String get library => pick(ko: '라이브러리', en: 'Library', ja: 'ライブラリ');
  String get aiChat => pick(ko: 'AI 채팅', en: 'AI Chat', ja: 'AIチャット');
  String get export => pick(ko: '내보내기', en: 'Export', ja: 'エクスポート');
  String get settings => pick(ko: '설정', en: 'Settings', ja: '設定');
  String get searchHint => pick(
    ko: '제목, 본문, 태그 검색',
    en: 'Search title, body, or tag',
    ja: 'タイトル、本文、タグを検索',
  );
  String get clearSearch =>
      pick(ko: '검색 지우기', en: 'Clear search', ja: '検索をクリア');
  String get all => pick(ko: '전체', en: 'All', ja: 'すべて');
  String savedConversationCount(int count) => pick(
    ko: '저장된 대화 $count개',
    en: '$count saved conversations',
    ja: '保存された会話 $count件',
  );
  String get projects => pick(ko: '프로젝트', en: 'Projects', ja: 'プロジェクト');
  String get chats => pick(ko: '대화', en: 'Chats', ja: '会話');
  String get tags => pick(ko: '태그', en: 'Tags', ja: 'タグ');
  String get code => pick(ko: '코드', en: 'Code', ja: 'コード');
  String get addTag => pick(ko: '태그 추가', en: 'Add tag', ja: 'タグを追加');
  String get extractedCode =>
      pick(ko: '추출된 코드', en: 'Extracted code', ja: '抽出コード');
  String get user => pick(ko: '사용자', en: 'User', ja: 'ユーザー');
  String get assistant => pick(ko: 'AI', en: 'Assistant', ja: 'AI');
  String get captureAiChat => pick(ko: 'AI 채팅', en: 'AI Chat', ja: 'AIチャット');
  String get captureDescription => pick(
    ko: '사용자 API 키로 답변을 생성하고 대화를 암호화된 로컬 지식으로 저장합니다.',
    en: 'Uses your API key to answer and save the chat as encrypted local knowledge.',
    ja: 'ユーザーのAPIキーで回答し、会話を暗号化されたローカル知識として保存します。',
  );
  String get project => pick(ko: '프로젝트', en: 'Project', ja: 'プロジェクト');
  String get promptLabel => pick(ko: '메시지', en: 'Message', ja: 'メッセージ');
  String get promptHint =>
      pick(ko: 'AI에게 물어보세요', en: 'Ask AI', ja: 'AIに質問してください');
  String get askAndSave => pick(ko: '보내기', en: 'Send', ja: '送信');
  String get askingAndSaving =>
      pick(ko: '답변 생성 중...', en: 'Asking...', ja: '回答を生成中...');
  String get recentCaptures =>
      pick(ko: '최근 AI 채팅', en: 'Recent AI chats', ja: '最近のAIチャット');
  String get newChat => pick(ko: '새 채팅', en: 'New chat', ja: '新しいチャット');
  String get newProject =>
      pick(ko: '새 프로젝트', en: 'New project', ja: '新しいプロジェクト');
  String get projectNameLabel =>
      pick(ko: '프로젝트 이름', en: 'Project name', ja: 'プロジェクト名');
  String get projectDescriptionLabel =>
      pick(ko: '프로젝트 설명', en: 'Project description', ja: 'プロジェクト説明');
  String get create => pick(ko: '만들기', en: 'Create', ja: '作成');
  String get cancel => pick(ko: '취소', en: 'Cancel', ja: 'キャンセル');
  String get enterProjectName => pick(
    ko: '프로젝트 이름을 입력하세요',
    en: 'Enter a project name',
    ja: 'プロジェクト名を入力してください',
  );
  String get openRecentChats =>
      pick(ko: '최근 채팅 열기', en: 'Open recent chats', ja: '最近のチャットを開く');
  String get messageOptions =>
      pick(ko: '메시지 옵션', en: 'Message options', ja: 'メッセージオプション');
  String get securityControls =>
      pick(ko: '보안 기능', en: 'Security controls', ja: 'セキュリティ機能');
  String get emptyChatTitle =>
      pick(ko: '새 AI 채팅을 시작하세요', en: 'Start a new AI chat', ja: '新しいAIチャットを開始');
  String get emptyChatHint => pick(
    ko: '아래 입력창에 메시지를 보내면 답변과 함께 로컬 지식으로 저장됩니다.',
    en: 'Send a message below to save the answer as local knowledge.',
    ja: '下の入力欄から送信すると、回答と一緒にローカル知識として保存されます。',
  );
  String get noRecentChats => pick(
    ko: '아직 최근 채팅이 없습니다',
    en: 'No recent chats yet',
    ja: '最近のチャットはまだありません',
  );
  String get savedLocally =>
      pick(ko: '응답 후 로컬 저장', en: 'Save after response', ja: '応答後にローカル保存');
  String get savedLocallyDescription => pick(
    ko: '메시지와 AI 답변을 암호화된 로컬 지식으로 남깁니다.',
    en: 'Keeps messages and AI answers as encrypted local knowledge.',
    ja: 'メッセージとAI回答を暗号化されたローカル知識として保存します。',
  );
  String get enterPrompt => pick(
    ko: '저장할 프롬프트를 입력하세요',
    en: 'Enter a prompt before saving',
    ja: '保存する前にプロンプトを入力してください',
  );
  String saved(String title) => pick(
    ko: '"$title" 대화를 저장했습니다',
    en: 'Saved "$title"',
    ja: '「$title」を保存しました',
  );
  String get missingApiKeyAssistant => pick(
    ko: 'OpenAI API 키가 아직 저장되어 있지 않아 실제 답변을 생성하지 못했습니다. 설정 화면에서 API 키를 저장한 뒤 다시 질문하면 AI 답변과 함께 대화가 저장됩니다.',
    en: 'No OpenAI API key is saved yet, so I could not generate a real answer. Save your API key in Settings, then ask again to store the AI response with the conversation.',
    ja: 'OpenAI APIキーがまだ保存されていないため、実際の回答を生成できませんでした。設定画面でAPIキーを保存してから再度質問すると、AI応答と一緒に会話が保存されます。',
  );
  String aiErrorAssistant(String detail) => pick(
    ko: 'AI 답변 생성에 실패했습니다. 프롬프트는 저장했지만 응답은 가져오지 못했습니다.\n\n오류: $detail',
    en: 'Failed to generate the AI answer. The prompt was saved, but the response could not be fetched.\n\nError: $detail',
    ja: 'AI回答の生成に失敗しました。プロンプトは保存しましたが、応答を取得できませんでした。\n\nエラー: $detail',
  );
  String get savedWithMissingKey => pick(
    ko: 'API 키가 없어 안내 메시지와 함께 저장했습니다',
    en: 'Saved with API key guidance',
    ja: 'APIキー案内と一緒に保存しました',
  );
  String get savedWithAiError => pick(
    ko: 'AI 응답 오류 내용을 함께 저장했습니다',
    en: 'Saved with the AI response error',
    ja: 'AI応答エラーと一緒に保存しました',
  );
  String get sensitiveMasking =>
      pick(ko: '민감정보 마스킹', en: 'Sensitive masking', ja: '機密情報マスキング');
  String get sqlCipherReady =>
      pick(ko: '암호화 저장', en: 'Encrypted storage', ja: '暗号化保存');
  String get appLock => pick(ko: '앱 잠금', en: 'App lock', ja: 'アプリロック');
  String onOff(bool value) => value
      ? pick(ko: '켜짐', en: 'on', ja: 'オン')
      : pick(ko: '꺼짐', en: 'off', ja: 'オフ');
  String get markdownExport =>
      pick(ko: '마크다운 내보내기', en: 'Markdown export', ja: 'Markdownエクスポート');
  String get exportDescription => pick(
    ko: '프로젝트 정보, 태그, 대화 턴, 코드 스니펫을 포함해 대화를 내보냅니다.',
    en: 'Export conversations with project metadata, tags, turns, and code snippets.',
    ja: 'プロジェクト情報、タグ、会話、コードスニペットを含めてエクスポートします。',
  );
  String get exportScope =>
      pick(ko: '내보내기 범위', en: 'Export scope', ja: 'エクスポート範囲');
  String get allProjects =>
      pick(ko: '모든 프로젝트', en: 'All projects', ja: 'すべてのプロジェクト');
  String get copyMarkdown =>
      pick(ko: '마크다운 복사', en: 'Copy Markdown', ja: 'Markdownをコピー');
  String get apiKey =>
      pick(ko: 'OpenAI API 키', en: 'OpenAI API key', ja: 'OpenAI APIキー');
  String get apiKeySaved => pick(
    ko: '보안 저장소에 키가 저장됨',
    en: 'Key saved in secure storage',
    ja: 'キーは安全なストレージに保存済み',
  );
  String get saveApiKey =>
      pick(ko: 'API 키 저장', en: 'Save API key', ja: 'APIキーを保存');
  String get apiKeyMarked => pick(
    ko: 'API 키를 보안 저장 대상으로 표시했습니다',
    en: 'API key marked for secure storage',
    ja: 'APIキーを安全な保存対象として設定しました',
  );
  String get enterKeyFirst =>
      pick(ko: '먼저 키를 입력하세요', en: 'Enter a key first', ja: '先にキーを入力してください');
  String get settingsTitle => pick(ko: '설정', en: 'Settings', ja: '設定');
  String get settingsDescription => pick(
    ko: '언어, API 키, 암호화 저장소, 앱 잠금, 마스킹을 관리합니다.',
    en: 'Manage language, API keys, encrypted storage, app lock, and masking.',
    ja: '言語、APIキー、暗号化ストレージ、アプリロック、マスキングを管理します。',
  );
  String get languageLabel => pick(ko: '언어', en: 'Language', ja: '言語');
  String get languageDescription => pick(
    ko: '앱 표시 언어를 변경합니다. 기본 언어는 한국어입니다.',
    en: 'Change the app display language. Korean is the default.',
    ja: 'アプリの表示言語を変更します。既定は韓国語です。',
  );
  String get maskSensitiveTitle => pick(
    ko: '민감정보 자동 마스킹',
    en: 'Mask sensitive information',
    ja: '機密情報を自動マスキング',
  );
  String get maskSensitiveSubtitle => pick(
    ko: '캡처 시 API 키, 이메일, 카드처럼 보이는 숫자를 가립니다.',
    en: 'Redacts API keys, emails, and card-like numbers on capture.',
    ja: '保存時にAPIキー、メール、カード番号らしき数字を伏せます。',
  );
  String get appLockTitle => pick(
    ko: 'FaceID, 지문 또는 PIN 앱 잠금',
    en: 'FaceID, fingerprint, or PIN app lock',
    ja: 'FaceID、指紋、PINによるアプリロック',
  );
  String get appLockSubtitle => pick(
    ko: '플랫폼 생체 인증 연동을 위한 설정입니다.',
    en: 'UI-ready control for platform biometric integration.',
    ja: 'プラットフォームの生体認証連携に向けた設定です。',
  );
  String get encryptedDbTitle => pick(
    ko: '암호화된 로컬 데이터베이스',
    en: 'Encrypted local database',
    ja: '暗号化ローカルデータベース',
  );
  String get encryptedDbSubtitle => pick(
    ko: '대화와 설정을 기기 보안 저장소에 남기고, SQLCipher SQLite 전환 경계를 유지합니다.',
    en: 'Persists conversations and settings in device secure storage while keeping the SQLCipher SQLite migration boundary clear.',
    ja: '会話と設定を端末の安全なストレージに保存し、SQLCipher SQLiteへの移行境界を保ちます。',
  );
  String get e2eeTitle =>
      pick(ko: 'E2EE 클라우드 동기화', en: 'E2EE cloud sync', ja: 'E2EEクラウド同期');
  String get e2eeSubtitle => pick(
    ko: '서버가 읽을 수 없는 프리미엄 동기화 기능을 위한 로드맵 설정입니다.',
    en: 'Roadmap toggle for premium sync without server-readable logs.',
    ja: 'サーバーが読めないプレミアム同期に向けたロードマップ設定です。',
  );
  String get implementationBoundary =>
      pick(ko: '구현 경계', en: 'Implementation boundary', ja: '実装境界');
  String get implementationBoundaryBody => pick(
    ko: '현재 1단계는 대화, 태그, 보안 설정을 암호화된 로컬 스냅샷으로 복원합니다. 대용량 운영 단계에서는 같은 저장소 경계를 conversations, messages, tags SQLCipher 테이블로 교체하고, provider 키는 Keychain 또는 Keystore에만 저장해야 합니다.',
    en: 'This phase restores conversations, tags, and security settings from an encrypted local snapshot. At larger production scale, the same repository boundary can move to SQLCipher tables for conversations, messages, and tags while provider keys stay only in Keychain or Keystore.',
    ja: '現在の第1段階では、会話、タグ、セキュリティ設定を暗号化されたローカルスナップショットから復元します。大規模な本番運用では、同じリポジトリ境界をconversations、messages、tagsのSQLCipherテーブルに移行し、providerキーはKeychainまたはKeystoreのみに保存します。',
  );
  String get noKnowledge => pick(
    ko: '일치하는 지식이 없습니다',
    en: 'No matching knowledge yet',
    ja: '一致する知識はまだありません',
  );
  String get noKnowledgeHint => pick(
    ko: '다른 검색어를 입력하거나 새 AI 대화를 캡처해보세요.',
    en: 'Try another search or capture a new AI conversation.',
    ja: '別の検索語を試すか、新しいAI会話を保存してください。',
  );

  String projectName(String id, String fallback) => switch (id) {
    'mobile' => pick(ko: '모바일 앱', en: 'Mobile App', ja: 'モバイルアプリ'),
    'research' => pick(ko: '리서치', en: 'Research', ja: 'リサーチ'),
    'security' => pick(ko: '보안', en: 'Security', ja: 'セキュリティ'),
    _ => fallback,
  };
}

class ProjectSpace {
  const ProjectSpace({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
  });

  final String id;
  final String name;
  final String description;
  final Color color;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color.toARGB32(),
    };
  }

  static ProjectSpace fromJson(Map<String, dynamic> json) {
    return ProjectSpace(
      id:
          json['id']?.toString() ??
          'project-${DateTime.now().microsecondsSinceEpoch}',
      name: json['name']?.toString() ?? 'Project',
      description: json['description']?.toString() ?? '',
      color: Color(json['color'] is int ? json['color'] as int : 0xFF176B5D),
    );
  }
}

class KnowledgeMessage {
  const KnowledgeMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final AiRole role;
  final String content;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.storageValue,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static KnowledgeMessage fromJson(Map<String, dynamic> json) {
    return KnowledgeMessage(
      id:
          json['id']?.toString() ??
          'msg-${DateTime.now().microsecondsSinceEpoch}',
      role: AiRoleStorage.fromStorageValue(json['role']?.toString()),
      content: json['content']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

enum CaptureSaveResult { answered, missingApiKey, apiError }

class CaptureResult {
  const CaptureResult({required this.conversation, required this.result});

  final Conversation conversation;
  final CaptureSaveResult result;
}

class OpenAiClient {
  OpenAiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<String> generateAnswer({
    required String apiKey,
    required String prompt,
    required AppLanguage language,
  }) async {
    final l = AppText.of(language);
    final response = await _httpClient.post(
      Uri.parse('https://api.openai.com/v1/responses'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-4.1-mini',
        'instructions': l.pick(
          ko: '너는 LLM Wiki 앱 안에서 사용자의 AI 대화를 지식으로 정리하는 도우미야. 한국어로 자연스럽고 실용적으로 답변해. 필요한 경우 핵심 요약과 다음 행동을 짧게 제안해.',
          en: 'You are an assistant inside LLM Wiki that helps turn AI conversations into reusable knowledge. Answer naturally and practically in English. When useful, include a short summary and next actions.',
          ja: 'あなたはLLM Wikiアプリ内で、AI会話を再利用可能な知識に整理するアシスタントです。日本語で自然かつ実用的に答えてください。必要に応じて短い要約と次の行動を提案してください。',
        ),
        'input': prompt,
      }),
    );

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error'] is Map<String, dynamic>
                ? decoded['error']['message']?.toString()
                : decoded['error']?.toString()
          : null;
      throw Exception(message ?? 'OpenAI API ${response.statusCode}');
    }

    final outputText = _extractOutputText(decoded);
    if (outputText == null || outputText.trim().isEmpty) {
      throw Exception('OpenAI response did not include output text.');
    }
    return outputText.trim();
  }

  String? _extractOutputText(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final direct = decoded['output_text'];
    if (direct is String && direct.trim().isNotEmpty) {
      return direct;
    }

    final chunks = <String>[];
    final output = decoded['output'];
    if (output is List) {
      for (final item in output) {
        if (item is! Map<String, dynamic>) {
          continue;
        }
        final content = item['content'];
        if (content is List) {
          for (final part in content) {
            if (part is Map<String, dynamic>) {
              final text = part['text'];
              if (text is String && text.trim().isNotEmpty) {
                chunks.add(text);
              }
            }
          }
        }
      }
    }
    return chunks.isEmpty ? null : chunks.join('\n');
  }
}

class Conversation {
  const Conversation({
    required this.id,
    required this.projectId,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.manualTags = const [],
  });

  final String id;
  final String projectId;
  final String title;
  final List<KnowledgeMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> manualTags;

  String get body => messages.map((message) => message.content).join('\n\n');

  List<String> get tags {
    final generated = <String>{};
    final lower = body.toLowerCase();
    const keywordMap = {
      'flutter': 'flutter',
      'sqlite': 'sqlite',
      'sqlcipher': 'sqlcipher',
      'openai': 'openai',
      'api key': 'api-key',
      'markdown': 'markdown',
      'obsidian': 'obsidian',
      'security': 'security',
      'encrypt': 'encryption',
      'vector': 'semantic-search',
      'search': 'search',
      'code': 'code',
      'dart': 'dart',
      'prompt': 'prompting',
    };
    for (final entry in keywordMap.entries) {
      if (lower.contains(entry.key)) {
        generated.add(entry.value);
      }
    }
    generated.addAll(manualTags);
    return generated.toList()..sort();
  }

  List<String> get codeSnippets {
    final fenced = RegExp(
      r'```(?:[a-zA-Z0-9_+-]+)?\s*([\s\S]*?)```',
      multiLine: true,
    );
    final snippets = fenced
        .allMatches(body)
        .map((match) => match.group(1)?.trim() ?? '')
        .where((snippet) => snippet.isNotEmpty)
        .toList();
    if (snippets.isNotEmpty) {
      return snippets;
    }

    final inlineCode = RegExp(r'`([^`\n]+)`');
    return inlineCode
        .allMatches(body)
        .map((match) => match.group(1)?.trim() ?? '')
        .where((snippet) => snippet.length > 8)
        .toList();
  }

  Conversation copyWith({
    String? title,
    List<KnowledgeMessage>? messages,
    DateTime? updatedAt,
    List<String>? manualTags,
  }) {
    return Conversation(
      id: id,
      projectId: projectId,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      manualTags: manualTags ?? this.manualTags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'manualTags': manualTags,
      'messages': messages.map((message) => message.toJson()).toList(),
    };
  }

  static Conversation fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final messagesJson = json['messages'];
    return Conversation(
      id: json['id']?.toString() ?? 'conv-${now.microsecondsSinceEpoch}',
      projectId: json['projectId']?.toString() ?? 'mobile',
      title: json['title']?.toString() ?? 'Untitled conversation',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? now,
      manualTags: _stringListFromJson(json['manualTags']),
      messages: messagesJson is List
          ? messagesJson
                .whereType<Map>()
                .map(
                  (message) => KnowledgeMessage.fromJson(
                    Map<String, dynamic>.from(message),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

class SecuritySettings {
  const SecuritySettings({
    required this.maskSensitiveInfo,
    required this.appLockEnabled,
    required this.localDbEncryption,
    required this.e2eeCloudSync,
    required this.apiKeySaved,
    this.language = AppLanguage.ko,
  });

  final bool maskSensitiveInfo;
  final bool appLockEnabled;
  final bool localDbEncryption;
  final bool e2eeCloudSync;
  final bool apiKeySaved;
  final AppLanguage language;

  SecuritySettings copyWith({
    bool? maskSensitiveInfo,
    bool? appLockEnabled,
    bool? localDbEncryption,
    bool? e2eeCloudSync,
    bool? apiKeySaved,
    AppLanguage? language,
  }) {
    return SecuritySettings(
      maskSensitiveInfo: maskSensitiveInfo ?? this.maskSensitiveInfo,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      localDbEncryption: localDbEncryption ?? this.localDbEncryption,
      e2eeCloudSync: e2eeCloudSync ?? this.e2eeCloudSync,
      apiKeySaved: apiKeySaved ?? this.apiKeySaved,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maskSensitiveInfo': maskSensitiveInfo,
      'appLockEnabled': appLockEnabled,
      'localDbEncryption': localDbEncryption,
      'e2eeCloudSync': e2eeCloudSync,
      'language': language.code,
    };
  }

  static SecuritySettings fromJson(
    Map<String, dynamic> json, {
    required bool apiKeySaved,
  }) {
    return SecuritySettings(
      maskSensitiveInfo: json['maskSensitiveInfo'] == true,
      appLockEnabled: json['appLockEnabled'] == true,
      localDbEncryption: json['localDbEncryption'] != false,
      e2eeCloudSync: json['e2eeCloudSync'] == true,
      apiKeySaved: apiKeySaved,
      language: AppLanguageStorage.fromCode(json['language']?.toString()),
    );
  }
}

class _PersistedSnapshot {
  const _PersistedSnapshot({
    required this.settings,
    required this.projects,
    required this.conversations,
  });

  final SecuritySettings settings;
  final List<ProjectSpace> projects;
  final List<Conversation> conversations;
}

List<String> _stringListFromJson(dynamic value) {
  if (value is! List) {
    return const [];
  }
  return value.map((item) => item.toString()).toList();
}

class WikiRepository extends ChangeNotifier {
  WikiRepository()
    : settings = const SecuritySettings(
        maskSensitiveInfo: true,
        appLockEnabled: false,
        localDbEncryption: true,
        e2eeCloudSync: false,
        apiKeySaved: false,
      ) {
    projects = _defaultProjects();
    conversations = _seedConversations();
  }

  static const _apiKeyStorageKey = 'openai_api_key';
  static const _appStateStorageKey = 'llm_wiki_app_state_v1';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final OpenAiClient _openAiClient = OpenAiClient();

  late List<ProjectSpace> projects;
  late List<Conversation> conversations;
  SecuritySettings settings;
  bool isInitialized = false;

  ProjectSpace projectById(String id) {
    return projects.firstWhere(
      (project) => project.id == id,
      orElse: () => projects.first,
    );
  }

  Conversation? conversationById(String id) {
    for (final conversation in conversations) {
      if (conversation.id == id) {
        return conversation;
      }
    }
    return null;
  }

  List<Conversation> search({
    required String query,
    required String projectId,
    required Set<String> selectedTags,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    return conversations.where((conversation) {
      final matchesProject =
          projectId == 'all' || conversation.projectId == projectId;
      final searchable = [
        conversation.title,
        conversation.body,
        ...conversation.tags,
      ].join(' ').toLowerCase();
      final matchesQuery =
          normalizedQuery.isEmpty || searchable.contains(normalizedQuery);
      final matchesTags =
          selectedTags.isEmpty ||
          selectedTags.every(conversation.tags.toSet().contains);
      return matchesProject && matchesQuery && matchesTags;
    }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<String> get allTags {
    return conversations
        .expand((conversation) => conversation.tags)
        .toSet()
        .toList()
      ..sort();
  }

  ProjectSpace createProject({required String name, String description = ''}) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('Project name is required');
    }
    final now = DateTime.now();
    final project = ProjectSpace(
      id: _projectIdFromName(cleanName, now),
      name: cleanName,
      description: description.trim().isEmpty
          ? 'Custom project'
          : description.trim(),
      color: _projectColorForIndex(projects.length),
    );
    projects = [...projects, project];
    unawaited(_persistSnapshot());
    notifyListeners();
    return project;
  }

  Future<void> initialize() async {
    final apiKeySaved = await _loadApiKeySaved();
    final snapshot = await _readPersistedSnapshot(apiKeySaved: apiKeySaved);
    if (snapshot != null) {
      settings = snapshot.settings;
      projects = snapshot.projects;
      conversations = snapshot.conversations;
    } else if (apiKeySaved != settings.apiKeySaved) {
      settings = settings.copyWith(apiKeySaved: apiKeySaved);
    }
    isInitialized = true;
    notifyListeners();
  }

  Future<void> loadSecureState() async {
    await initialize();
  }

  Future<bool> _loadApiKeySaved() async {
    try {
      final apiKey = await _secureStorage.read(key: _apiKeyStorageKey);
      return apiKey != null && apiKey.trim().isNotEmpty;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> saveApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    await _secureStorage.write(key: _apiKeyStorageKey, value: trimmed);
    settings = settings.copyWith(apiKeySaved: true);
    await _persistSnapshot();
    notifyListeners();
    return true;
  }

  Future<String?> _readApiKey() async {
    try {
      final apiKey = await _secureStorage.read(key: _apiKeyStorageKey);
      if (apiKey == null || apiKey.trim().isEmpty) {
        return null;
      }
      return apiKey.trim();
    } on MissingPluginException {
      return null;
    }
  }

  Future<CaptureResult> createConversation({
    required String projectId,
    required String prompt,
  }) async {
    final sanitizedPrompt = settings.maskSensitiveInfo
        ? maskSensitive(prompt)
        : prompt.trim();
    final now = DateTime.now();
    final title = _titleFromPrompt(sanitizedPrompt);
    final l = AppText.of(settings.language);
    CaptureSaveResult result = CaptureSaveResult.answered;
    var assistantReply = '';
    final apiKey = await _readApiKey();
    if (apiKey == null) {
      result = CaptureSaveResult.missingApiKey;
      assistantReply = l.missingApiKeyAssistant;
    } else {
      try {
        assistantReply = await _openAiClient.generateAnswer(
          apiKey: apiKey,
          prompt: sanitizedPrompt,
          language: settings.language,
        );
      } catch (error) {
        result = CaptureSaveResult.apiError;
        assistantReply = l.aiErrorAssistant(_readableError(error));
      }
    }
    final conversation = Conversation(
      id: 'conv-${now.microsecondsSinceEpoch}',
      projectId: projectId,
      title: title,
      createdAt: now,
      updatedAt: now,
      manualTags: _tagsFromPrompt(sanitizedPrompt),
      messages: [
        KnowledgeMessage(
          id: 'msg-${now.microsecondsSinceEpoch}-u',
          role: AiRole.user,
          content: sanitizedPrompt,
          createdAt: now,
        ),
        KnowledgeMessage(
          id: 'msg-${now.microsecondsSinceEpoch}-a',
          role: AiRole.assistant,
          content: assistantReply,
          createdAt: now.add(const Duration(seconds: 2)),
        ),
      ],
    );
    conversations = [conversation, ...conversations];
    await _persistSnapshot();
    notifyListeners();
    return CaptureResult(conversation: conversation, result: result);
  }

  String _readableError(Object error) {
    final text = error.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }

  void addTag(String conversationId, String tag) {
    final normalized = tag.trim().toLowerCase().replaceAll(' ', '-');
    if (normalized.isEmpty) {
      return;
    }
    conversations = conversations.map((conversation) {
      if (conversation.id != conversationId) {
        return conversation;
      }
      final tags = {...conversation.manualTags, normalized}.toList()..sort();
      return conversation.copyWith(manualTags: tags, updatedAt: DateTime.now());
    }).toList();
    unawaited(_persistSnapshot());
    notifyListeners();
  }

  void updateSettings(SecuritySettings nextSettings) {
    settings = nextSettings;
    unawaited(_persistSnapshot());
    notifyListeners();
  }

  Future<_PersistedSnapshot?> _readPersistedSnapshot({
    required bool apiKeySaved,
  }) async {
    try {
      final raw = await _secureStorage.read(key: _appStateStorageKey);
      if (raw == null || raw.trim().isEmpty) {
        return null;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final settingsJson = decoded['settings'];
      final projectsJson = decoded['projects'];
      final conversationsJson = decoded['conversations'];
      final restoredSettings = settingsJson is Map<String, dynamic>
          ? SecuritySettings.fromJson(settingsJson, apiKeySaved: apiKeySaved)
          : settings.copyWith(apiKeySaved: apiKeySaved);
      final restoredProjects = projectsJson is List
          ? projectsJson
                .whereType<Map>()
                .map(
                  (project) =>
                      ProjectSpace.fromJson(Map<String, dynamic>.from(project)),
                )
                .where((project) => project.id.trim().isNotEmpty)
                .toList()
          : <ProjectSpace>[];
      final restoredConversations = conversationsJson is List
          ? conversationsJson
                .whereType<Map>()
                .map(
                  (conversation) => Conversation.fromJson(
                    Map<String, dynamic>.from(conversation),
                  ),
                )
                .where((conversation) => conversation.messages.isNotEmpty)
                .toList()
          : <Conversation>[];
      return _PersistedSnapshot(
        settings: restoredSettings,
        projects: restoredProjects.isEmpty
            ? _defaultProjects()
            : restoredProjects,
        conversations: restoredConversations,
      );
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistSnapshot() async {
    try {
      final payload = {
        'schemaVersion': 1,
        'savedAt': DateTime.now().toIso8601String(),
        'settings': settings.toJson(),
        'projects': projects.map((project) => project.toJson()).toList(),
        'conversations': conversations
            .map((conversation) => conversation.toJson())
            .toList(),
      };
      await _secureStorage.write(
        key: _appStateStorageKey,
        value: jsonEncode(payload),
      );
    } on MissingPluginException {
      return;
    } catch (_) {
      return;
    }
  }

  String exportMarkdown({String projectId = 'all'}) {
    final l = AppText.of(settings.language);
    final selected =
        conversations
            .where(
              (conversation) =>
                  projectId == 'all' || conversation.projectId == projectId,
            )
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final buffer = StringBuffer()
      ..writeln(
        '# ${l.pick(ko: 'LLM Wiki 내보내기', en: 'LLM Wiki Export', ja: 'LLM Wikiエクスポート')}',
      )
      ..writeln()
      ..writeln(
        '- ${l.pick(ko: '내보낸 시간', en: 'Exported', ja: 'エクスポート日時')}: ${_formatDateTime(DateTime.now())}',
      )
      ..writeln(
        '- ${l.pick(ko: '범위', en: 'Scope', ja: '範囲')}: ${projectId == 'all' ? l.allProjects : l.projectName(projectById(projectId).id, projectById(projectId).name)}',
      )
      ..writeln();

    for (final conversation in selected) {
      final project = projectById(conversation.projectId);
      buffer
        ..writeln('## ${conversation.title}')
        ..writeln()
        ..writeln('- ${l.project}: ${l.projectName(project.id, project.name)}')
        ..writeln(
          '- ${l.pick(ko: '생성일', en: 'Created', ja: '作成日')}: ${_formatDateTime(conversation.createdAt)}',
        )
        ..writeln(
          '- ${l.tags}: ${conversation.tags.map((tag) => '#$tag').join(' ')}',
        )
        ..writeln();

      for (final message in conversation.messages) {
        final speaker = message.role == AiRole.user ? l.user : l.assistant;
        buffer
          ..writeln('### $speaker')
          ..writeln()
          ..writeln(message.content)
          ..writeln();
      }

      if (conversation.codeSnippets.isNotEmpty) {
        buffer
          ..writeln('### ${l.extractedCode}')
          ..writeln();
        for (final snippet in conversation.codeSnippets) {
          buffer
            ..writeln('```')
            ..writeln(snippet)
            ..writeln('```')
            ..writeln();
        }
      }
    }

    return buffer.toString();
  }

  static String maskSensitive(String input) {
    var output = input.trim();
    final patterns = [
      RegExp(r'sk-[A-Za-z0-9_-]{12,}'),
      RegExp(
        r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}',
        caseSensitive: false,
      ),
      RegExp(r'\b(?:\d[ -]*?){13,16}\b'),
    ];
    for (final pattern in patterns) {
      output = output.replaceAllMapped(pattern, (_) => '[masked]');
    }
    return output;
  }

  List<Conversation> _seedConversations() {
    final now = DateTime.now();
    return [
      Conversation(
        id: 'conv-seed-1',
        projectId: 'mobile',
        title: 'AI 대화 저장용 SQLite 스키마',
        createdAt: now.subtract(const Duration(days: 4, hours: 3)),
        updatedAt: now.subtract(const Duration(days: 4, hours: 2)),
        manualTags: const ['schema', 'local-first'],
        messages: [
          KnowledgeMessage(
            id: 'msg-1',
            role: AiRole.user,
            createdAt: now.subtract(const Duration(days: 4, hours: 3)),
            content: 'conversations, messages, tags를 위한 로컬 SQLite 구조를 설계해줘.',
          ),
          KnowledgeMessage(
            id: 'msg-2',
            role: AiRole.assistant,
            createdAt: now.subtract(const Duration(days: 4, hours: 2)),
            content:
                'conversations는 프로젝트 단위 대화 기록, messages는 순서가 있는 대화 턴, tags는 다대다 검색 인덱스로 분리하는 것이 좋습니다. SQLCipher로 DB 파일을 암호화하고, 암호화 키는 Secure Storage에 보관합니다.',
          ),
        ],
      ),
      Conversation(
        id: 'conv-seed-2',
        projectId: 'security',
        title: 'API 키 보관 체크리스트',
        createdAt: now.subtract(const Duration(days: 2, hours: 8)),
        updatedAt: now.subtract(const Duration(days: 2, hours: 7)),
        manualTags: const ['keychain', 'privacy'],
        messages: [
          KnowledgeMessage(
            id: 'msg-3',
            role: AiRole.user,
            createdAt: now.subtract(const Duration(days: 2, hours: 8)),
            content: '사용자의 OpenAI API 키가 유출되지 않게 앱에서 무엇을 해야 할까?',
          ),
          KnowledgeMessage(
            id: 'msg-4',
            role: AiRole.assistant,
            createdAt: now.subtract(const Duration(days: 2, hours: 7)),
            content:
                '사용자 API 키를 제품 서버로 보내지 않아야 합니다. 키는 iOS Keychain 또는 Android Keystore에 저장하고, provider 직접 요청에는 HTTPS/TLS를 사용하며, 앱 잠금과 민감정보 마스킹 옵션을 제공합니다.',
          ),
        ],
      ),
      Conversation(
        id: 'conv-seed-3',
        projectId: 'research',
        title: '마크다운 내보내기 형식',
        createdAt: now.subtract(const Duration(hours: 20)),
        updatedAt: now.subtract(const Duration(hours: 18)),
        manualTags: const ['export', 'obsidian'],
        messages: [
          KnowledgeMessage(
            id: 'msg-5',
            role: AiRole.user,
            createdAt: now.subtract(const Duration(hours: 20)),
            content: '대화를 내보내기 위한 마크다운 템플릿을 만들어줘.',
          ),
          KnowledgeMessage(
            id: 'msg-6',
            role: AiRole.assistant,
            createdAt: now.subtract(const Duration(hours: 18)),
            content:
                '유용한 내보내기에는 프로젝트, 태그, 생성일, 역할별 대화 턴, 추출된 코드가 포함되어야 합니다. 예시:\n\n```markdown\n## 대화 제목\n- 프로젝트: 리서치\n- 태그: #search #memory\n\n### 사용자\n프롬프트 내용\n```',
          ),
        ],
      ),
    ];
  }

  List<ProjectSpace> _defaultProjects() {
    return const [
      ProjectSpace(
        id: 'mobile',
        name: 'Mobile App',
        description: 'Flutter, local-first storage, release notes',
        color: Color(0xFF176B5D),
      ),
      ProjectSpace(
        id: 'research',
        name: 'Research',
        description: 'AI memory, search, knowledge graph ideas',
        color: Color(0xFF8C4A2F),
      ),
      ProjectSpace(
        id: 'security',
        name: 'Security',
        description: 'Keychain, SQLCipher, privacy controls',
        color: Color(0xFF5B628A),
      ),
    ];
  }

  String _projectIdFromName(String name, DateTime now) {
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9가-힣]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final base = slug.isEmpty ? 'project' : slug;
    return '$base-${now.microsecondsSinceEpoch}';
  }

  Color _projectColorForIndex(int index) {
    const colors = [
      Color(0xFF176B5D),
      Color(0xFF8C4A2F),
      Color(0xFF5B628A),
      Color(0xFFC99A2E),
      Color(0xFF3E6F8E),
      Color(0xFF7A4E7D),
    ];
    return colors[index % colors.length];
  }

  List<String> _tagsFromPrompt(String prompt) {
    final lower = prompt.toLowerCase();
    final tags = <String>{};
    const keywords = {
      'flutter': 'flutter',
      'sqlite': 'sqlite',
      'openai': 'openai',
      'api': 'api',
      'security': 'security',
      'markdown': 'markdown',
      'export': 'export',
      'search': 'search',
      'code': 'code',
      'obsidian': 'obsidian',
      'memory': 'memory',
    };
    for (final entry in keywords.entries) {
      if (lower.contains(entry.key)) {
        tags.add(entry.value);
      }
    }
    return tags.toList()..sort();
  }

  String _titleFromPrompt(String prompt) {
    final clean = prompt.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) {
      return AppText.of(
        settings.language,
      ).pick(ko: '제목 없는 대화', en: 'Untitled conversation', ja: '無題の会話');
    }
    return clean.length > 54 ? '${clean.substring(0, 54)}...' : clean;
  }
}

class WikiShell extends StatefulWidget {
  const WikiShell({super.key});

  @override
  State<WikiShell> createState() => _WikiShellState();
}

class _WikiShellState extends State<WikiShell> {
  final WikiRepository repository = WikiRepository();
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeRepository();
  }

  Future<void> _initializeRepository() async {
    await repository.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ChatCapturePage(repository: repository),
      LibraryPage(repository: repository),
      ExportPage(repository: repository),
      SecurityPage(repository: repository),
    ];

    return AnimatedBuilder(
      animation: repository,
      builder: (context, _) {
        final l = AppText.of(repository.settings.language);
        return Scaffold(
          appBar: AppBar(
            title: const Text('LLM Wiki'),
            actions: [
              IconButton(
                tooltip: l.copyMarkdownExport,
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: repository.exportMarkdown()),
                  );
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l.markdownCopied)));
                },
                icon: const Icon(Icons.file_copy_outlined),
              ),
            ],
          ),
          body: SafeArea(child: pages[selectedIndex]),
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.chat_bubble_outline),
                selectedIcon: const Icon(Icons.chat_bubble),
                label: l.aiChat,
              ),
              NavigationDestination(
                icon: const Icon(Icons.library_books_outlined),
                selectedIcon: const Icon(Icons.library_books),
                label: l.library,
              ),
              NavigationDestination(
                icon: const Icon(Icons.ios_share_outlined),
                selectedIcon: const Icon(Icons.ios_share),
                label: l.export,
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: l.settings,
              ),
            ],
          ),
        );
      },
    );
  }
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, required this.repository});

  final WikiRepository repository;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final TextEditingController searchController = TextEditingController();
  String selectedProjectId = 'all';
  final Set<String> selectedTags = {};

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppText.of(widget.repository.settings.language);
    final conversations = widget.repository.search(
      query: searchController.text,
      projectId: selectedProjectId,
      selectedTags: selectedTags,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _MetricStrip(repository: widget.repository),
        const SizedBox(height: 16),
        SearchBar(
          key: const Key('library-search'),
          controller: searchController,
          leading: const Icon(Icons.search),
          hintText: l.searchHint,
          onChanged: (_) => setState(() {}),
          trailing: [
            if (searchController.text.isNotEmpty)
              IconButton(
                tooltip: l.clearSearch,
                onPressed: () {
                  searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _ProjectFilter(
          projects: widget.repository.projects,
          language: widget.repository.settings.language,
          selectedProjectId: selectedProjectId,
          onSelected: (projectId) {
            setState(() {
              selectedProjectId = projectId;
            });
          },
        ),
        if (widget.repository.allTags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: widget.repository.allTags.map((tag) {
              final selected = selectedTags.contains(tag);
              return FilterChip(
                label: Text('#$tag'),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      selectedTags.add(tag);
                    } else {
                      selectedTags.remove(tag);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          l.savedConversationCount(conversations.length),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (conversations.isEmpty)
          _EmptyState(language: widget.repository.settings.language)
        else
          ...conversations.map(
            (conversation) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ConversationCard(
                conversation: conversation,
                project: widget.repository.projectById(conversation.projectId),
                language: widget.repository.settings.language,
                onTap: () => _openConversation(context, conversation),
              ),
            ),
          ),
      ],
    );
  }

  void _openConversation(BuildContext context, Conversation conversation) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return ConversationDetailSheet(
          conversation: conversation,
          project: widget.repository.projectById(conversation.projectId),
          language: widget.repository.settings.language,
          onAddTag: (tag) {
            widget.repository.addTag(conversation.id, tag);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}

class _MetricStrip extends StatelessWidget {
  const _MetricStrip({required this.repository});

  final WikiRepository repository;

  @override
  Widget build(BuildContext context) {
    final l = AppText.of(repository.settings.language);
    final snippets = repository.conversations.fold<int>(
      0,
      (count, conversation) => count + conversation.codeSnippets.length,
    );
    final metrics = [
      (
        l.projects,
        repository.projects.length.toString(),
        Icons.folder_outlined,
      ),
      (
        l.chats,
        repository.conversations.length.toString(),
        Icons.forum_outlined,
      ),
      (l.tags, repository.allTags.length.toString(), Icons.sell_outlined),
      (l.code, snippets.toString(), Icons.code),
    ];

    return Row(
      children: metrics.map((metric) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(metric.$3, size: 20),
                    const SizedBox(height: 8),
                    Text(
                      metric.$2,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      metric.$1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ProjectFilter extends StatelessWidget {
  const _ProjectFilter({
    required this.projects,
    required this.language,
    required this.selectedProjectId,
    required this.onSelected,
  });

  final List<ProjectSpace> projects;
  final AppLanguage language;
  final String selectedProjectId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppText.of(language);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(l.all),
              selected: selectedProjectId == 'all',
              onSelected: (_) => onSelected('all'),
            ),
          ),
          ...projects.map(
            (project) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: CircleAvatar(backgroundColor: project.color),
                label: Text(l.projectName(project.id, project.name)),
                selected: selectedProjectId == project.id,
                onSelected: (_) => onSelected(project.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConversationCard extends StatelessWidget {
  const ConversationCard({
    super.key,
    required this.conversation,
    required this.project,
    required this.language,
    required this.onTap,
  });

  final Conversation conversation;
  final ProjectSpace project;
  final AppLanguage language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppText.of(language);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: project.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.projectName(project.id, project.name),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  Text(
                    _relativeTime(conversation.updatedAt),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                conversation.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                conversation.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ...conversation.tags
                      .take(5)
                      .map(
                        (tag) => Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text('#$tag'),
                        ),
                      ),
                  if (conversation.codeSnippets.isNotEmpty)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.code, size: 16),
                      label: Text(l.code.toLowerCase()),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConversationDetailSheet extends StatefulWidget {
  const ConversationDetailSheet({
    super.key,
    required this.conversation,
    required this.project,
    required this.language,
    required this.onAddTag,
  });

  final Conversation conversation;
  final ProjectSpace project;
  final AppLanguage language;
  final ValueChanged<String> onAddTag;

  @override
  State<ConversationDetailSheet> createState() =>
      _ConversationDetailSheetState();
}

class _ConversationDetailSheetState extends State<ConversationDetailSheet> {
  final TextEditingController tagController = TextEditingController();

  @override
  void dispose() {
    tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppText.of(widget.language);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.86,
      maxChildSize: 0.94,
      minChildSize: 0.45,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              widget.conversation.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.folder_outlined, color: widget.project.color),
                const SizedBox(width: 8),
                Text(l.projectName(widget.project.id, widget.project.name)),
                const Spacer(),
                Text(_formatDateTime(widget.conversation.createdAt)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: widget.conversation.tags
                  .map((tag) => Chip(label: Text('#$tag')))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: tagController,
                    decoration: InputDecoration(
                      hintText: l.addTag,
                      prefixIcon: const Icon(Icons.sell_outlined),
                    ),
                    onSubmitted: widget.onAddTag,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: l.addTag,
                  onPressed: () => widget.onAddTag(tagController.text),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...widget.conversation.messages.map(
              (message) =>
                  _MessageBubble(message: message, language: widget.language),
            ),
            if (widget.conversation.codeSnippets.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l.extractedCode,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...widget.conversation.codeSnippets.map(
                (snippet) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF202124),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    snippet,
                    style: const TextStyle(
                      color: Color(0xFFF8F8F2),
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.language});

  final KnowledgeMessage message;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == AiRole.user;
    final l = AppText.of(language);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFDCEDE8) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE3DFD3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUser ? l.user : l.assistant,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Text(message.content),
          ],
        ),
      ),
    );
  }
}

class ChatCapturePage extends StatefulWidget {
  const ChatCapturePage({super.key, required this.repository});

  final WikiRepository repository;

  @override
  State<ChatCapturePage> createState() => _ChatCapturePageState();
}

class _ChatCapturePageState extends State<ChatCapturePage> {
  late String projectId = widget.repository.projects.first.id;
  final TextEditingController promptController = TextEditingController();
  Conversation? activeConversation;
  bool isSaving = false;

  @override
  void dispose() {
    promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ChatTopBar(
          repository: widget.repository,
          projectId: projectId,
          onOpenRecentChats: _openRecentChats,
          onNewChat: _startNewChat,
          onCreateProject: _openCreateProjectDialog,
          onProjectSelected: _selectProject,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              if (activeConversation != null) ...[
                _ActiveConversationTitle(
                  conversation: activeConversation!,
                  project: widget.repository.projectById(
                    activeConversation!.projectId,
                  ),
                  language: widget.repository.settings.language,
                ),
                const SizedBox(height: 14),
                ...activeConversation!.messages.map(
                  (message) => _ChatMessageBubble(
                    message: message,
                    language: widget.repository.settings.language,
                  ),
                ),
              ] else
                _EmptyChatState(language: widget.repository.settings.language),
            ],
          ),
        ),
        _ChatComposer(
          controller: promptController,
          isSaving: isSaving,
          repository: widget.repository,
          language: widget.repository.settings.language,
          projectId: projectId,
          onProjectSelected: _selectProject,
          onCreateProject: _openCreateProjectDialog,
          onSubmit: _savePrompt,
        ),
      ],
    );
  }

  Future<void> _savePrompt() async {
    final prompt = promptController.text.trim();
    if (prompt.isEmpty) {
      final l = AppText.of(widget.repository.settings.language);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.enterPrompt)));
      return;
    }
    final l = AppText.of(widget.repository.settings.language);
    setState(() {
      isSaving = true;
    });
    try {
      final result = await widget.repository.createConversation(
        projectId: projectId,
        prompt: prompt,
      );
      if (!mounted) {
        return;
      }
      promptController.clear();
      setState(() {
        activeConversation = result.conversation;
      });
      final message = switch (result.result) {
        CaptureSaveResult.answered => l.saved(result.conversation.title),
        CaptureSaveResult.missingApiKey => l.savedWithMissingKey,
        CaptureSaveResult.apiError => l.savedWithAiError,
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void _startNewChat() {
    promptController.clear();
    setState(() {
      activeConversation = null;
    });
  }

  void _selectProject(String value) {
    final projectChats = widget.repository.search(
      query: '',
      projectId: value,
      selectedTags: const <String>{},
    );
    setState(() {
      projectId = value;
      activeConversation = projectChats.isEmpty ? null : projectChats.first;
    });
  }

  void _openRecentChats() {
    final l = AppText.of(widget.repository.settings.language);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final conversations = widget.repository.search(
          query: '',
          projectId: projectId,
          selectedTags: const <String>{},
        );
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            children: [
              Text(
                '${l.recentCaptures} · ${l.projectName(widget.repository.projectById(projectId).id, widget.repository.projectById(projectId).name)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _startNewChat();
                },
                icon: const Icon(Icons.edit_square),
                label: Text(l.newChat),
              ),
              const SizedBox(height: 12),
              if (conversations.isEmpty)
                _EmptyRecentChats(language: widget.repository.settings.language)
              else
                ...conversations.map(
                  (conversation) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ConversationCard(
                      conversation: conversation,
                      project: widget.repository.projectById(
                        conversation.projectId,
                      ),
                      language: widget.repository.settings.language,
                      onTap: () {
                        setState(() {
                          activeConversation = conversation;
                          projectId = conversation.projectId;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openCreateProjectDialog() async {
    final l = AppText.of(widget.repository.settings.language);
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final project = await showDialog<ProjectSpace>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l.newProject),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('new-project-name-field'),
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l.projectNameLabel,
                  prefixIcon: const Icon(Icons.folder_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: l.projectDescriptionLabel,
                  prefixIcon: const Icon(Icons.notes_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.cancel),
            ),
            FilledButton(
              key: const Key('create-project-button'),
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l.enterProjectName)));
                  return;
                }
                final created = widget.repository.createProject(
                  name: name,
                  description: descriptionController.text,
                );
                Navigator.pop(context, created);
              },
              child: Text(l.create),
            ),
          ],
        );
      },
    );
    nameController.dispose();
    descriptionController.dispose();
    if (project == null || !mounted) {
      return;
    }
    setState(() {
      projectId = project.id;
      activeConversation = null;
    });
  }
}

class _ChatTopBar extends StatelessWidget {
  const _ChatTopBar({
    required this.repository,
    required this.projectId,
    required this.onOpenRecentChats,
    required this.onNewChat,
    required this.onCreateProject,
    required this.onProjectSelected,
  });

  static const String _newProjectMenuValue = '__new_project__';

  final WikiRepository repository;
  final String projectId;
  final VoidCallback onOpenRecentChats;
  final VoidCallback onNewChat;
  final VoidCallback onCreateProject;
  final ValueChanged<String> onProjectSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppText.of(repository.settings.language);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 12, 10),
      child: Row(
        children: [
          IconButton(
            tooltip: l.openRecentChats,
            onPressed: onOpenRecentChats,
            icon: const Icon(Icons.menu),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.captureAiChat,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  l.captureDescription,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l.newChat,
            onPressed: onNewChat,
            icon: const Icon(Icons.edit_square),
          ),
          IconButton(
            tooltip: l.copyMarkdownExport,
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: repository.exportMarkdown()),
              );
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l.markdownCopied)));
            },
            icon: const Icon(Icons.ios_share_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: l.project,
            icon: const Icon(Icons.more_horiz),
            initialValue: projectId,
            onSelected: (value) {
              if (value == _newProjectMenuValue) {
                onCreateProject();
                return;
              }
              onProjectSelected(value);
            },
            itemBuilder: (context) {
              return [
                ...repository.projects.map(
                  (project) => PopupMenuItem<String>(
                    value: project.id,
                    child: Row(
                      children: [
                        Icon(Icons.folder_outlined, color: project.color),
                        const SizedBox(width: 8),
                        Text(l.projectName(project.id, project.name)),
                      ],
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: _newProjectMenuValue,
                  child: Row(
                    children: [
                      const Icon(Icons.create_new_folder_outlined),
                      const SizedBox(width: 8),
                      Text(l.newProject),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }
}

class _ActiveConversationTitle extends StatelessWidget {
  const _ActiveConversationTitle({
    required this.conversation,
    required this.project,
    required this.language,
  });

  final Conversation conversation;
  final ProjectSpace project;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final l = AppText.of(language);
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.auto_awesome,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                conversation.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                l.projectName(project.id, project.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: l.copyMarkdownExport,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: conversation.body));
            if (!context.mounted) {
              return;
            }
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l.markdownCopied)));
          },
          icon: const Icon(Icons.content_copy_outlined),
        ),
      ],
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({required this.message, required this.language});

  final KnowledgeMessage message;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == AiRole.user;
    final l = AppText.of(language);
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isUser ? colorScheme.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
            bottomLeft: Radius.circular(isUser ? 22 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 22),
          ),
          border: isUser ? null : Border.all(color: const Color(0xFFE3DFD3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l.assistant,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message.content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isUser ? Colors.white : const Color(0xFF26332E),
                height: 1.48,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState({required this.language});

  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final l = AppText.of(language);
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l.emptyChatTitle,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l.emptyChatHint,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyRecentChats extends StatelessWidget {
  const _EmptyRecentChats({required this.language});

  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final l = AppText.of(language);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(l.noRecentChats)),
          ],
        ),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.isSaving,
    required this.repository,
    required this.language,
    required this.projectId,
    required this.onProjectSelected,
    required this.onCreateProject,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isSaving;
  final WikiRepository repository;
  final AppLanguage language;
  final String projectId;
  final ValueChanged<String> onProjectSelected;
  final VoidCallback onCreateProject;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l = AppText.of(language);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F5EF),
        border: Border(top: BorderSide(color: Color(0xFFE3DFD3))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFD9DED7)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                tooltip: l.messageOptions,
                onPressed: () => _openMessageOptions(context),
                icon: const Icon(Icons.tune),
              ),
              Expanded(
                child: TextField(
                  key: const Key('prompt-field'),
                  controller: controller,
                  keyboardType: TextInputType.multiline,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  textCapitalization: TextCapitalization.none,
                  enableSuggestions: true,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: l.promptLabel,
                    hintText: l.promptHint,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                key: const Key('ask-save-button'),
                tooltip: isSaving ? l.askingAndSaving : l.askAndSave,
                onPressed: isSaving ? null : onSubmit,
                icon: isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chat_bubble),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMessageOptions(BuildContext context) {
    final l = AppText.of(language);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final settings = repository.settings;
            return SafeArea(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  Text(
                    l.messageOptions,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  DropdownMenu<String>(
                    width: double.infinity,
                    initialSelection: projectId,
                    label: Text(l.project),
                    leadingIcon: const Icon(Icons.folder_outlined),
                    onSelected: (value) {
                      if (value != null) {
                        onProjectSelected(value);
                      }
                    },
                    dropdownMenuEntries: repository.projects
                        .map(
                          (project) => DropdownMenuEntry<String>(
                            value: project.id,
                            label: l.projectName(project.id, project.name),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onCreateProject,
                    icon: const Icon(Icons.create_new_folder_outlined),
                    label: Text(l.newProject),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.securityControls,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _SecuritySwitch(
                    title: l.maskSensitiveTitle,
                    subtitle: l.maskSensitiveSubtitle,
                    value: settings.maskSensitiveInfo,
                    icon: Icons.visibility_off_outlined,
                    onChanged: (value) {
                      repository.updateSettings(
                        repository.settings.copyWith(maskSensitiveInfo: value),
                      );
                      setSheetState(() {});
                    },
                  ),
                  _SecuritySwitch(
                    title: l.encryptedDbTitle,
                    subtitle: l.encryptedDbSubtitle,
                    value: settings.localDbEncryption,
                    icon: Icons.enhanced_encryption_outlined,
                    onChanged: (value) {
                      repository.updateSettings(
                        repository.settings.copyWith(localDbEncryption: value),
                      );
                      setSheetState(() {});
                    },
                  ),
                  _SecuritySwitch(
                    title: l.appLockTitle,
                    subtitle: l.appLockSubtitle,
                    value: settings.appLockEnabled,
                    icon: Icons.fingerprint,
                    onChanged: (value) {
                      repository.updateSettings(
                        repository.settings.copyWith(appLockEnabled: value),
                      );
                      setSheetState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.save_alt_outlined),
                      title: Text(l.savedLocally),
                      subtitle: Text(l.savedLocallyDescription),
                      trailing: const Icon(Icons.check_circle),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class ExportPage extends StatefulWidget {
  const ExportPage({super.key, required this.repository});

  final WikiRepository repository;

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  String projectId = 'all';

  @override
  Widget build(BuildContext context) {
    final l = AppText.of(widget.repository.settings.language);
    final markdown = widget.repository.exportMarkdown(projectId: projectId);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text(l.markdownExport, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          l.exportDescription,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        DropdownMenu<String>(
          width: double.infinity,
          initialSelection: projectId,
          label: Text(l.exportScope),
          leadingIcon: const Icon(Icons.filter_alt_outlined),
          onSelected: (value) {
            if (value != null) {
              setState(() {
                projectId = value;
              });
            }
          },
          dropdownMenuEntries: [
            DropdownMenuEntry(value: 'all', label: l.allProjects),
            ...widget.repository.projects.map(
              (project) => DropdownMenuEntry<String>(
                value: project.id,
                label: l.projectName(project.id, project.name),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: markdown));
            if (!context.mounted) {
              return;
            }
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l.markdownCopied)));
          },
          icon: const Icon(Icons.copy),
          label: Text(l.copyMarkdown),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF202124),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            markdown,
            style: const TextStyle(
              color: Color(0xFFF8F8F2),
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key, required this.repository});

  final WikiRepository repository;

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final TextEditingController apiKeyController = TextEditingController();

  @override
  void dispose() {
    apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.repository.settings;
    final l = AppText.of(settings.language);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text(l.settingsTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          l.settingsDescription,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.language),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.languageLabel,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l.languageDescription,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownMenu<AppLanguage>(
                  key: const Key('language-menu'),
                  width: double.infinity,
                  initialSelection: settings.language,
                  label: Text(l.languageLabel),
                  onSelected: (language) {
                    if (language == null) {
                      return;
                    }
                    widget.repository.updateSettings(
                      settings.copyWith(language: language),
                    );
                    setState(() {});
                  },
                  dropdownMenuEntries: AppLanguage.values
                      .map(
                        (language) => DropdownMenuEntry<AppLanguage>(
                          value: language,
                          label: language.label,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: apiKeyController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: l.apiKey,
            hintText: settings.apiKeySaved ? l.apiKeySaved : 'sk-...',
            prefixIcon: const Icon(Icons.key_outlined),
            suffixIcon: IconButton(
              tooltip: l.saveApiKey,
              onPressed: () async {
                final hasKey = await widget.repository.saveApiKey(
                  apiKeyController.text,
                );
                if (!context.mounted) {
                  return;
                }
                apiKeyController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(hasKey ? l.apiKeyMarked : l.enterKeyFirst),
                  ),
                );
                setState(() {});
              },
              icon: const Icon(Icons.save_outlined),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SecuritySwitch(
          title: l.maskSensitiveTitle,
          subtitle: l.maskSensitiveSubtitle,
          value: settings.maskSensitiveInfo,
          icon: Icons.visibility_off_outlined,
          onChanged: (value) {
            widget.repository.updateSettings(
              settings.copyWith(maskSensitiveInfo: value),
            );
            setState(() {});
          },
        ),
        _SecuritySwitch(
          title: l.appLockTitle,
          subtitle: l.appLockSubtitle,
          value: settings.appLockEnabled,
          icon: Icons.fingerprint,
          onChanged: (value) {
            widget.repository.updateSettings(
              settings.copyWith(appLockEnabled: value),
            );
            setState(() {});
          },
        ),
        _SecuritySwitch(
          title: l.encryptedDbTitle,
          subtitle: l.encryptedDbSubtitle,
          value: settings.localDbEncryption,
          icon: Icons.enhanced_encryption_outlined,
          onChanged: (value) {
            widget.repository.updateSettings(
              settings.copyWith(localDbEncryption: value),
            );
            setState(() {});
          },
        ),
        _SecuritySwitch(
          title: l.e2eeTitle,
          subtitle: l.e2eeSubtitle,
          value: settings.e2eeCloudSync,
          icon: Icons.cloud_sync_outlined,
          onChanged: (value) {
            widget.repository.updateSettings(
              settings.copyWith(e2eeCloudSync: value),
            );
            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.implementationBoundary,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(l.implementationBoundaryBody),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SecuritySwitch extends StatelessWidget {
  const _SecuritySwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final IconData icon;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.language});

  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final l = AppText.of(language);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.manage_search,
              size: 44,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(l.noKnowledge, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(l.noKnowledgeHint, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.year}-${_two(local.month)}-${_two(local.day)} ${_two(local.hour)}:${_two(local.minute)}';
}

String _relativeTime(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) {
    return 'now';
  }
  if (diff.inHours < 1) {
    return '${diff.inMinutes}m';
  }
  if (diff.inDays < 1) {
    return '${diff.inHours}h';
  }
  return '${diff.inDays}d';
}

String _two(int value) => value.toString().padLeft(2, '0');
