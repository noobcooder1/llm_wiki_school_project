import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

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
  String get capture => pick(ko: '캡처', en: 'Capture', ja: '保存');
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
  String get captureAiChat =>
      pick(ko: 'AI 대화 캡처', en: 'Capture AI chat', ja: 'AI会話を保存');
  String get captureDescription => pick(
    ko: '프롬프트는 로컬에 저장되고, 자동으로 태그가 생성되며, 이후 OpenAI SDK 연동을 준비합니다.',
    en: 'Prompts are saved locally, tagged automatically, and prepared for future OpenAI SDK integration.',
    ja: 'プロンプトはローカルに保存され、自動でタグ付けされ、今後のOpenAI SDK連携に備えます。',
  );
  String get project => pick(ko: '프로젝트', en: 'Project', ja: 'プロジェクト');
  String get promptLabel => pick(
    ko: '프롬프트 또는 붙여넣은 AI 대화',
    en: 'Prompt or pasted AI conversation',
    ja: 'プロンプトまたは貼り付けたAI会話',
  );
  String get promptHint => pick(
    ko: '대화, 코드 스니펫, 새 AI 프롬프트를 붙여넣으세요...',
    en: 'Paste a conversation, code snippet, or new AI prompt...',
    ja: '会話、コードスニペット、新しいAIプロンプトを貼り付けてください...',
  );
  String get askAndSave =>
      pick(ko: '질문하고 저장', en: 'Ask and save', ja: '質問して保存');
  String get recentCaptures =>
      pick(ko: '최근 캡처', en: 'Recent captures', ja: '最近の保存');
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
  String get sensitiveMasking =>
      pick(ko: '민감정보 마스킹', en: 'Sensitive masking', ja: '機密情報マスキング');
  String get sqlCipherReady =>
      pick(ko: 'SQLCipher 준비', en: 'SQLCipher-ready', ja: 'SQLCipher対応');
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
    ko: 'SQLCipher 기반 SQLite 저장소를 전제로 설계합니다.',
    en: 'Designed for SQLCipher-backed SQLite storage.',
    ja: 'SQLCipherベースのSQLite保存を前提に設計します。',
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
    ko: '운영 단계에서는 이 저장소를 conversations, messages, tags SQLite 테이블에 연결하고, provider 키는 Keychain 또는 Keystore에만 저장하며, 사용자 대화 로그는 제품 서버에 저장하지 않아야 합니다.',
    en: 'Production storage should connect this repository to SQLite tables for conversations, messages, and tags; store provider keys only in Keychain or Keystore; and keep user chat logs off product servers.',
    ja: '本番環境では、このリポジトリをconversations、messages、tagsのSQLiteテーブルに接続し、providerキーはKeychainまたはKeystoreにのみ保存し、ユーザー会話ログを製品サーバーに保存しないようにします。',
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
}

class WikiRepository extends ChangeNotifier {
  WikiRepository()
    : projects = const [
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
      ],
      settings = const SecuritySettings(
        maskSensitiveInfo: true,
        appLockEnabled: false,
        localDbEncryption: true,
        e2eeCloudSync: false,
        apiKeySaved: false,
      ) {
    conversations = _seedConversations();
  }

  final List<ProjectSpace> projects;
  late List<Conversation> conversations;
  SecuritySettings settings;

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

  Conversation createConversation({
    required String projectId,
    required String prompt,
  }) {
    final sanitizedPrompt = settings.maskSensitiveInfo
        ? maskSensitive(prompt)
        : prompt.trim();
    final now = DateTime.now();
    final title = _titleFromPrompt(sanitizedPrompt);
    final assistantReply = _mockAssistantReply(sanitizedPrompt);
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
    notifyListeners();
    return conversation;
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
    notifyListeners();
  }

  void updateSettings(SecuritySettings nextSettings) {
    settings = nextSettings;
    notifyListeners();
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

  String _mockAssistantReply(String prompt) {
    final tags = _tagsFromPrompt(prompt);
    final l = AppText.of(settings.language);
    final tagText = tags.isEmpty
        ? l.pick(ko: '일반 지식', en: 'general knowledge', ja: '一般知識')
        : tags.join(', ');
    return switch (settings.language) {
      AppLanguage.ko => [
        '$tagText 관련 재사용 가능한 지식으로 저장했습니다.',
        '',
        '다음 작업 제안:',
        '- 원본 프롬프트와 응답을 프로젝트에 연결해두세요.',
        '- 내보내기 전에 생성된 태그를 검토하세요.',
        '- 안정화된 결정은 위키 노트로 승격하세요.',
      ].join('\n'),
      AppLanguage.en => [
        'Saved this as reusable knowledge about $tagText.',
        '',
        'Suggested next actions:',
        '- Keep the original prompt and response linked to the project.',
        '- Review generated tags before exporting.',
        '- Promote durable decisions into a wiki note when they become stable.',
      ].join('\n'),
      AppLanguage.ja => [
        '$tagText に関する再利用可能な知識として保存しました。',
        '',
        '次のアクション:',
        '- 元のプロンプトと応答をプロジェクトに紐づけてください。',
        '- エクスポート前に生成されたタグを確認してください。',
        '- 安定した決定事項はWikiノートへ昇格してください。',
      ].join('\n'),
    };
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
  Widget build(BuildContext context) {
    final pages = [
      LibraryPage(repository: repository),
      ChatCapturePage(repository: repository),
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
                icon: const Icon(Icons.library_books_outlined),
                selectedIcon: const Icon(Icons.library_books),
                label: l.library,
              ),
              NavigationDestination(
                icon: const Icon(Icons.add_comment_outlined),
                selectedIcon: const Icon(Icons.add_comment),
                label: l.capture,
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

  @override
  void dispose() {
    promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppText.of(widget.repository.settings.language);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text(l.captureAiChat, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          l.captureDescription,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        DropdownMenu<String>(
          width: double.infinity,
          initialSelection: projectId,
          label: Text(l.project),
          leadingIcon: const Icon(Icons.folder_outlined),
          onSelected: (value) {
            if (value != null) {
              setState(() {
                projectId = value;
              });
            }
          },
          dropdownMenuEntries: widget.repository.projects
              .map(
                (project) => DropdownMenuEntry<String>(
                  value: project.id,
                  label: l.projectName(project.id, project.name),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('prompt-field'),
          controller: promptController,
          minLines: 8,
          maxLines: 14,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            alignLabelWithHint: true,
            labelText: l.promptLabel,
            hintText: l.promptHint,
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 138),
              child: Icon(Icons.chat_bubble_outline),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SecurityNotice(settings: widget.repository.settings),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('ask-save-button'),
          onPressed: _savePrompt,
          icon: const Icon(Icons.auto_awesome),
          label: Text(l.askAndSave),
        ),
        const SizedBox(height: 16),
        Text(l.recentCaptures, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...widget.repository.conversations
            .take(3)
            .map(
              (conversation) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ConversationCard(
                  conversation: conversation,
                  project: widget.repository.projectById(
                    conversation.projectId,
                  ),
                  language: widget.repository.settings.language,
                  onTap: () {},
                ),
              ),
            ),
      ],
    );
  }

  void _savePrompt() {
    final prompt = promptController.text.trim();
    if (prompt.isEmpty) {
      final l = AppText.of(widget.repository.settings.language);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.enterPrompt)));
      return;
    }
    final conversation = widget.repository.createConversation(
      projectId: projectId,
      prompt: prompt,
    );
    promptController.clear();
    final l = AppText.of(widget.repository.settings.language);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.saved(conversation.title))));
    setState(() {});
  }
}

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice({required this.settings});

  final SecuritySettings settings;

  @override
  Widget build(BuildContext context) {
    final l = AppText.of(settings.language);
    final items = [
      (
        settings.maskSensitiveInfo,
        l.sensitiveMasking,
        Icons.visibility_off_outlined,
      ),
      (settings.localDbEncryption, l.sqlCipherReady, Icons.storage_outlined),
      (settings.appLockEnabled, l.appLock, Icons.lock_outline),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            return Chip(
              avatar: Icon(item.$3, size: 16),
              label: Text('${item.$2}: ${l.onOff(item.$1)}'),
            );
          }).toList(),
        ),
      ),
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
              onPressed: () {
                final hasKey = apiKeyController.text.trim().isNotEmpty;
                widget.repository.updateSettings(
                  settings.copyWith(apiKeySaved: hasKey),
                );
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
