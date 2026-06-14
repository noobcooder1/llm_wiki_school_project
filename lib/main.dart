import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

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

enum AiProvider {
  gemini('gemini', 'Gemini'),
  openAi('openai', 'GPT / OpenAI'),
  anthropic('anthropic', 'Claude'),
  xAi('xai', 'Grok');

  const AiProvider(this.id, this.label);

  final String id;
  final String label;
}

enum AppLanguage {
  ko('ko', '한국어'),
  en('en', 'English'),
  ja('ja', '日本語');

  const AppLanguage(this.code, this.label);

  final String code;
  final String label;
}

extension AiProviderStorage on AiProvider {
  static AiProvider fromId(String? id) {
    return AiProvider.values.firstWhere(
      (provider) => provider.id == id,
      orElse: () => AiProvider.gemini,
    );
  }
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
  String get manage => pick(ko: '관리', en: 'Manage', ja: '管理');
  String get rename => pick(ko: '이름 변경', en: 'Rename', ja: '名前を変更');
  String get move => pick(ko: '이동', en: 'Move', ja: '移動');
  String get delete => pick(ko: '삭제', en: 'Delete', ja: '削除');
  String get trash => pick(ko: '휴지통', en: 'Trash', ja: 'ゴミ箱');
  String get moveToTrash =>
      pick(ko: '휴지통으로 이동', en: 'Move to trash', ja: 'ゴミ箱へ移動');
  String get restore => pick(ko: '복원', en: 'Restore', ja: '復元');
  String get deleteForever =>
      pick(ko: '영구 삭제', en: 'Delete forever', ja: '完全に削除');
  String get emptyTrash =>
      pick(ko: '휴지통이 비어 있습니다', en: 'Trash is empty', ja: 'ゴミ箱は空です');
  String get clearTrash =>
      pick(ko: '휴지통 비우기', en: 'Empty trash', ja: 'ゴミ箱を空にする');
  String trashItemCount(int count) => pick(
    ko: '삭제한 항목 $count개',
    en: '$count deleted items',
    ja: '削除済み項目 $count件',
  );
  String get trashProjectSubtitle => pick(
    ko: '프로젝트와 포함된 대화',
    en: 'Project and included chats',
    ja: 'プロジェクトと含まれる会話',
  );
  String get trashConversationSubtitle =>
      pick(ko: '대화 1개', en: '1 chat', ja: '会話1件');
  String get deleteForeverConfirm => pick(
    ko: '이 항목은 복원할 수 없도록 완전히 삭제됩니다.',
    en: 'This item will be permanently deleted and cannot be restored.',
    ja: 'この項目は復元できないよう完全に削除されます。',
  );
  String get emptyTrashConfirm => pick(
    ko: '휴지통의 모든 항목을 복원할 수 없도록 완전히 삭제할까요?',
    en: 'Permanently delete every item in trash?',
    ja: 'ゴミ箱のすべての項目を完全に削除しますか？',
  );
  String get deleteConversation =>
      pick(ko: '대화 삭제', en: 'Delete chat', ja: '会話を削除');
  String get deleteProject =>
      pick(ko: '프로젝트 삭제', en: 'Delete project', ja: 'プロジェクトを削除');
  String get projectGroups =>
      pick(ko: '프로젝트별', en: 'By project', ja: 'プロジェクト別');
  String get allChats => pick(ko: '전체 채팅', en: 'All chats', ja: 'すべての会話');
  String get moveConversation =>
      pick(ko: '프로젝트 이동', en: 'Move to project', ja: 'プロジェクトへ移動');
  String get conversationTitle =>
      pick(ko: '대화 제목', en: 'Chat title', ja: '会話タイトル');
  String get deleteProjectWithChats => pick(
    ko: '프로젝트와 포함된 대화를 휴지통으로 이동할까요?',
    en: 'Move this project and all chats inside it to trash?',
    ja: 'このプロジェクトと含まれる会話をゴミ箱へ移動しますか？',
  );
  String get deleteConversationConfirm => pick(
    ko: '이 대화를 휴지통으로 이동할까요?',
    en: 'Move this chat to trash?',
    ja: 'この会話をゴミ箱へ移動しますか？',
  );
  String get undone => pick(ko: '되돌리기', en: 'Undo', ja: '元に戻す');
  String get deleted => pick(ko: '삭제했습니다', en: 'Deleted', ja: '削除しました');
  String get movedToTrash =>
      pick(ko: '휴지통으로 이동했습니다', en: 'Moved to trash', ja: 'ゴミ箱へ移動しました');
  String get restored => pick(ko: '복원했습니다', en: 'Restored', ja: '復元しました');
  String get moved => pick(ko: '이동했습니다', en: 'Moved', ja: '移動しました');
  String get renamed => pick(ko: '이름을 변경했습니다', en: 'Renamed', ja: '名前を変更しました');
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
  String get createProjectFirst => pick(
    ko: '먼저 프로젝트를 만들어주세요',
    en: 'Create a project first',
    ja: '先にプロジェクトを作成してください',
  );
  String get openRecentChats =>
      pick(ko: '최근 채팅 열기', en: 'Open recent chats', ja: '最近のチャットを開く');
  String get chatSearch => pick(ko: '채팅 검색', en: 'Search chats', ja: 'チャット検索');
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
  String missingApiKeyAssistant(AiProvider provider) => pick(
    ko: '${provider.label} API 키가 아직 저장되어 있지 않아 실제 답변을 생성하지 못했습니다. 설정 화면에서 API 키를 저장한 뒤 다시 질문하면 AI 답변과 함께 대화가 저장됩니다.',
    en: 'No ${provider.label} API key is saved yet, so I could not generate a real answer. Save your API key in Settings, then ask again to store the AI response with the conversation.',
    ja: '${provider.label} APIキーがまだ保存されていないため、実際の回答を生成できませんでした。設定画面でAPIキーを保存してから再度質問すると、AI応答と一緒に会話が保存されます。',
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
  String apiKey(AiProvider provider) => pick(
    ko: '${provider.label} API 키',
    en: '${provider.label} API key',
    ja: '${provider.label} APIキー',
  );
  String get aiProvider =>
      pick(ko: 'AI 제공자', en: 'AI provider', ja: 'AIプロバイダー');
  String get apiKeySaved => pick(
    ko: '보안 저장소에 키가 저장됨',
    en: 'Key saved in secure storage',
    ja: 'キーは安全なストレージに保存済み',
  );
  String get saveApiKey =>
      pick(ko: 'API 키 저장', en: 'Save API key', ja: 'APIキーを保存');
  String get apiKeyMarked => pick(
    ko: 'API 키를 보안 저장소에 추가했습니다',
    en: 'API key added to secure storage',
    ja: 'APIキーを安全な保存先に追加しました',
  );
  String get registeredApiKeys =>
      pick(ko: '등록된 API 키', en: 'Saved API keys', ja: '保存済みAPIキー');
  String get noRegisteredApiKeys =>
      pick(ko: '아직 등록된 키가 없습니다', en: 'No saved keys yet', ja: '保存済みキーはまだありません');
  String get apiKeyMaskedNotice => pick(
    ko: '보안을 위해 키는 일부만 표시됩니다.',
    en: 'Keys are partially masked for safety.',
    ja: '安全のためキーは一部のみ表示されます。',
  );
  String get activeApiKey => pick(ko: '사용 중', en: 'Active', ja: '使用中');
  String get addNewApiKey =>
      pick(ko: '새 API 키 추가', en: 'Add new API key', ja: '新しいAPIキーを追加');
  String get apiKeySelected => pick(
    ko: '사용할 API 키를 변경했습니다',
    en: 'Active API key changed',
    ja: '使用するAPIキーを変更しました',
  );
  String get apiKeyDeleted =>
      pick(ko: 'API 키를 삭제했습니다', en: 'API key deleted', ja: 'APIキーを削除しました');
  String get enterKeyFirst =>
      pick(ko: '먼저 키를 입력하세요', en: 'Enter a key first', ja: '先にキーを入力してください');
  String get settingsTitle => pick(ko: '설정', en: 'Settings', ja: '設定');
  String get settingsDescription => pick(
    ko: '언어, AI 제공자, API 키, 암호화 저장소, 앱 잠금, 마스킹을 관리합니다.',
    en: 'Manage language, AI provider, API keys, encrypted storage, app lock, and masking.',
    ja: '言語、AIプロバイダー、APIキー、暗号化ストレージ、アプリロック、マスキングを管理します。',
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

  ProjectSpace copyWith({String? name, String? description, Color? color}) {
    return ProjectSpace(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
    );
  }

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

String _wikiAssistantInstructions(AppLanguage language) {
  final l = AppText.of(language);
  return l.pick(
    ko: '너는 LLM Wiki 앱 안에서 사용자의 AI 대화를 지식으로 정리하는 도우미야. 한국어로 자연스럽고 실용적으로 답변해. 필요한 경우 핵심 요약과 다음 행동을 짧게 제안해.',
    en: 'You are an assistant inside LLM Wiki that helps turn AI conversations into reusable knowledge. Answer naturally and practically in English. When useful, include a short summary and next actions.',
    ja: 'あなたはLLM Wikiアプリ内で、AI会話を再利用可能な知識に整理するアシスタントです。日本語で自然かつ実用的に答えてください。必要に応じて短い要約と次の行動を提案してください。',
  );
}

String? _extractResponsesApiText(dynamic decoded) {
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

class AiProviderException implements Exception {
  const AiProviderException(this.message, {this.statusCode, this.model});

  final String message;
  final int? statusCode;
  final String? model;

  @override
  String toString() {
    final modelText = model == null ? '' : ' [$model]';
    return '$modelText$message';
  }
}

bool _canRetryWithFallback(Object error) {
  if (error is! AiProviderException) {
    return false;
  }
  final statusCode = error.statusCode;
  if (statusCode == 404 || statusCode == 429) {
    return true;
  }
  if (statusCode == 400 || statusCode == 403) {
    final message = error.message.toLowerCase();
    return message.contains('model') ||
        message.contains('not found') ||
        message.contains('permission') ||
        message.contains('access') ||
        message.contains('quota') ||
        message.contains('rate limit');
  }
  return false;
}

class OpenAiClient {
  OpenAiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  static const _models = ['gpt-5.4-nano', 'gpt-5.4-mini'];

  Future<String> generateAnswer({
    required String apiKey,
    required String prompt,
    required AppLanguage language,
  }) async {
    Object? lastError;
    for (final model in _models) {
      try {
        return await _generateWithModel(
          apiKey: apiKey,
          prompt: prompt,
          language: language,
          model: model,
        );
      } catch (error) {
        lastError = error;
        if (!_canRetryWithFallback(error)) {
          rethrow;
        }
      }
    }
    throw lastError ?? Exception('OpenAI API failed.');
  }

  Future<String> _generateWithModel({
    required String apiKey,
    required String prompt,
    required AppLanguage language,
    required String model,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('https://api.openai.com/v1/responses'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'instructions': _wikiAssistantInstructions(language),
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
      throw AiProviderException(
        message ?? 'OpenAI API ${response.statusCode}',
        statusCode: response.statusCode,
        model: model,
      );
    }

    final outputText = _extractResponsesApiText(decoded);
    if (outputText == null || outputText.trim().isEmpty) {
      throw Exception('OpenAI response did not include output text.');
    }
    return outputText.trim();
  }
}

class GeminiClient {
  GeminiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  static const _models = ['gemini-2.5-flash-lite', 'gemini-2.5-flash'];

  Future<String> generateAnswer({
    required String apiKey,
    required String prompt,
    required AppLanguage language,
  }) async {
    Object? lastError;
    for (final model in _models) {
      try {
        return await _generateWithModel(
          apiKey: apiKey,
          prompt: prompt,
          language: language,
          model: model,
        );
      } catch (error) {
        lastError = error;
        if (!_canRetryWithFallback(error)) {
          rethrow;
        }
      }
    }
    throw lastError ?? Exception('Gemini API failed.');
  }

  Future<String> _generateWithModel({
    required String apiKey,
    required String prompt,
    required AppLanguage language,
    required String model,
  }) async {
    final response = await _httpClient.post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
      ),
      headers: {'x-goog-api-key': apiKey, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': _wikiAssistantInstructions(language)},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt},
            ],
          },
        ],
      }),
    );

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error'] is Map<String, dynamic>
                ? decoded['error']['message']?.toString()
                : decoded['error']?.toString()
          : null;
      throw AiProviderException(
        _geminiReadableError(message, response.statusCode),
        statusCode: response.statusCode,
        model: model,
      );
    }

    final outputText = _extractOutputText(decoded);
    if (outputText == null || outputText.trim().isEmpty) {
      throw Exception('Gemini response did not include output text.');
    }
    return outputText.trim();
  }

  String? _extractOutputText(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      return null;
    }
    final chunks = <String>[];
    for (final candidate in candidates) {
      if (candidate is! Map<String, dynamic>) {
        continue;
      }
      final content = candidate['content'];
      if (content is! Map<String, dynamic>) {
        continue;
      }
      final parts = content['parts'];
      if (parts is! List) {
        continue;
      }
      for (final part in parts) {
        if (part is Map<String, dynamic>) {
          final text = part['text'];
          if (text is String && text.trim().isNotEmpty) {
            chunks.add(text);
          }
        }
      }
    }
    return chunks.isEmpty ? null : chunks.join('\n');
  }

  String _geminiReadableError(String? message, int statusCode) {
    final normalized = message?.trim();
    if (statusCode == 403) {
      return [
        'Gemini API 키는 앱에서 정상적으로 읽었지만 Google 프로젝트 권한이 거절되었습니다.',
        'Google AI Studio에서 이 키가 연결된 프로젝트의 Gemini API 사용 권한, 결제/할당량, 키 제한을 확인해 주세요.',
        if (normalized != null && normalized.isNotEmpty) '원본 오류: $normalized',
      ].join('\n');
    }
    return normalized == null || normalized.isEmpty
        ? 'Gemini API $statusCode'
        : normalized;
  }
}

class AnthropicClient {
  AnthropicClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  static const _models = ['claude-haiku-4-5', 'claude-sonnet-4-6'];

  Future<String> generateAnswer({
    required String apiKey,
    required String prompt,
    required AppLanguage language,
  }) async {
    Object? lastError;
    for (final model in _models) {
      try {
        return await _generateWithModel(
          apiKey: apiKey,
          prompt: prompt,
          language: language,
          model: model,
        );
      } catch (error) {
        lastError = error;
        if (!_canRetryWithFallback(error)) {
          rethrow;
        }
      }
    }
    throw lastError ?? Exception('Claude API failed.');
  }

  Future<String> _generateWithModel({
    required String apiKey,
    required String prompt,
    required AppLanguage language,
    required String model,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'max_tokens': 1024,
        'system': _wikiAssistantInstructions(language),
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error'] is Map<String, dynamic>
                ? decoded['error']['message']?.toString()
                : decoded['error']?.toString()
          : null;
      throw AiProviderException(
        message ?? 'Claude API ${response.statusCode}',
        statusCode: response.statusCode,
        model: model,
      );
    }

    final outputText = _extractOutputText(decoded);
    if (outputText == null || outputText.trim().isEmpty) {
      throw Exception('Claude response did not include output text.');
    }
    return outputText.trim();
  }

  String? _extractOutputText(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final content = decoded['content'];
    if (content is! List || content.isEmpty) {
      return null;
    }
    final chunks = <String>[];
    for (final block in content) {
      if (block is Map<String, dynamic>) {
        final text = block['text'];
        if (text is String && text.trim().isNotEmpty) {
          chunks.add(text);
        }
      }
    }
    return chunks.isEmpty ? null : chunks.join('\n');
  }
}

class XAiClient {
  XAiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<String> generateAnswer({
    required String apiKey,
    required String prompt,
    required AppLanguage language,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('https://api.x.ai/v1/responses'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'grok-4.3',
        'input': [
          {'role': 'system', 'content': _wikiAssistantInstructions(language)},
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error'] is Map<String, dynamic>
                ? decoded['error']['message']?.toString()
                : decoded['error']?.toString()
          : null;
      throw Exception(message ?? 'Grok API ${response.statusCode}');
    }

    final outputText = _extractResponsesApiText(decoded);
    if (outputText == null || outputText.trim().isEmpty) {
      throw Exception('Grok response did not include output text.');
    }
    return outputText.trim();
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
    return {..._autoTagsFromText(body), ...manualTags}.toList()..sort();
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
    String? projectId,
    String? title,
    List<KnowledgeMessage>? messages,
    DateTime? updatedAt,
    List<String>? manualTags,
  }) {
    return Conversation(
      id: id,
      projectId: projectId ?? this.projectId,
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
    this.aiProvider = AiProvider.gemini,
    this.activeApiKeyIds = const {},
    this.language = AppLanguage.ko,
  });

  final bool maskSensitiveInfo;
  final bool appLockEnabled;
  final bool localDbEncryption;
  final bool e2eeCloudSync;
  final bool apiKeySaved;
  final AiProvider aiProvider;
  final Map<String, String> activeApiKeyIds;
  final AppLanguage language;

  SecuritySettings copyWith({
    bool? maskSensitiveInfo,
    bool? appLockEnabled,
    bool? localDbEncryption,
    bool? e2eeCloudSync,
    bool? apiKeySaved,
    AiProvider? aiProvider,
    Map<String, String>? activeApiKeyIds,
    AppLanguage? language,
  }) {
    return SecuritySettings(
      maskSensitiveInfo: maskSensitiveInfo ?? this.maskSensitiveInfo,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      localDbEncryption: localDbEncryption ?? this.localDbEncryption,
      e2eeCloudSync: e2eeCloudSync ?? this.e2eeCloudSync,
      apiKeySaved: apiKeySaved ?? this.apiKeySaved,
      aiProvider: aiProvider ?? this.aiProvider,
      activeApiKeyIds: activeApiKeyIds ?? this.activeApiKeyIds,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maskSensitiveInfo': maskSensitiveInfo,
      'appLockEnabled': appLockEnabled,
      'localDbEncryption': localDbEncryption,
      'e2eeCloudSync': e2eeCloudSync,
      'aiProvider': aiProvider.id,
      'activeApiKeyIds': activeApiKeyIds,
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
      aiProvider: AiProviderStorage.fromId(json['aiProvider']?.toString()),
      activeApiKeyIds: _stringMapFromJson(json['activeApiKeyIds']),
      language: AppLanguageStorage.fromCode(json['language']?.toString()),
    );
  }
}

class ApiKeyEntry {
  const ApiKeyEntry({
    required this.id,
    required this.label,
    required this.value,
    required this.createdAt,
  });

  final String id;
  final String label;
  final String value;
  final DateTime createdAt;

  String get maskedValue {
    final clean = value.trim();
    if (clean.length <= 8) {
      return '••••';
    }
    final prefix = clean.substring(0, clean.length >= 6 ? 6 : clean.length);
    final suffix = clean.substring(clean.length - 4);
    return '$prefix••••$suffix';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'value': value,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static ApiKeyEntry fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return ApiKeyEntry(
      id: json['id']?.toString() ?? 'key-${now.microsecondsSinceEpoch}',
      label: json['label']?.toString() ?? 'API key',
      value: json['value']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? now,
    );
  }
}

class _PersistedSnapshot {
  const _PersistedSnapshot({
    required this.settings,
    required this.projects,
    required this.conversations,
    required this.trashedItems,
  });

  final SecuritySettings settings;
  final List<ProjectSpace> projects;
  final List<Conversation> conversations;
  final List<TrashItem> trashedItems;
}

enum TrashItemType { conversation, project }

class TrashItem {
  const TrashItem({
    required this.id,
    required this.type,
    required this.deletedAt,
    this.project,
    this.conversation,
    this.conversations = const [],
  });

  final String id;
  final TrashItemType type;
  final DateTime deletedAt;
  final ProjectSpace? project;
  final Conversation? conversation;
  final List<Conversation> conversations;

  String title(AppText l) {
    return switch (type) {
      TrashItemType.conversation => conversation?.title ?? l.chats,
      TrashItemType.project =>
        project == null
            ? l.projects
            : l.projectName(project!.id, project!.name),
    };
  }

  int get conversationCount {
    return switch (type) {
      TrashItemType.conversation => conversation == null ? 0 : 1,
      TrashItemType.project => conversations.length,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'deletedAt': deletedAt.toIso8601String(),
      'project': project?.toJson(),
      'conversation': conversation?.toJson(),
      'conversations': conversations
          .map((conversation) => conversation.toJson())
          .toList(),
    };
  }

  static TrashItem fromJson(Map<String, dynamic> json) {
    final type = switch (json['type']?.toString()) {
      'project' => TrashItemType.project,
      _ => TrashItemType.conversation,
    };
    final conversationsJson = json['conversations'];
    return TrashItem(
      id:
          json['id']?.toString() ??
          'trash-${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      deletedAt:
          DateTime.tryParse(json['deletedAt']?.toString() ?? '') ??
          DateTime.now(),
      project: json['project'] is Map
          ? ProjectSpace.fromJson(Map<String, dynamic>.from(json['project']))
          : null,
      conversation: json['conversation'] is Map
          ? Conversation.fromJson(
              Map<String, dynamic>.from(json['conversation']),
            )
          : null,
      conversations: conversationsJson is List
          ? conversationsJson
                .whereType<Map>()
                .map(
                  (conversation) => Conversation.fromJson(
                    Map<String, dynamic>.from(conversation),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

List<String> _stringListFromJson(dynamic value) {
  if (value is! List) {
    return const [];
  }
  return value.map((item) => item.toString()).toList();
}

Map<String, String> _stringMapFromJson(dynamic value) {
  if (value is! Map) {
    return const {};
  }
  return value.map((key, item) => MapEntry(key.toString(), item.toString()));
}

List<String> _autoTagsFromText(String text) {
  final lower = text.toLowerCase();
  final compact = lower.replaceAll(RegExp(r'\s+'), '');
  final tags = <String>{};

  const exactKeywords = {
    'flutter': 'flutter',
    '플러터': 'flutter',
    'hot reload': 'hot-reload',
    '핫리로드': 'hot-reload',
    'hot restart': 'hot-restart',
    '핫리스타트': 'hot-restart',
    'sqlite': 'sqlite',
    'sqlcipher': 'sqlcipher',
    'openai': 'openai',
    'gemini': 'gemini',
    '제미나이': 'gemini',
    'gpt': 'gpt',
    '지피티': 'gpt',
    'claude': 'claude',
    '클로드': 'claude',
    'anthropic': 'anthropic',
    'grok': 'grok',
    '그록': 'grok',
    'xai': 'xai',
    'api key': 'api-key',
    'api키': 'api-key',
    'api 키': 'api-key',
    'markdown': 'markdown',
    '마크다운': 'markdown',
    'obsidian': 'obsidian',
    '옵시디언': 'obsidian',
    'security': 'security',
    '보안': 'security',
    'encrypt': 'encryption',
    '암호화': 'encryption',
    'vector': 'semantic-search',
    '벡터': 'semantic-search',
    'search': 'search',
    '검색': 'search',
    'code': 'code',
    '코드': 'code',
    'dart': 'dart',
    'prompt': 'prompting',
    '프롬프트': 'prompting',
  };

  for (final entry in exactKeywords.entries) {
    final keyword = entry.key.replaceAll(' ', '');
    if (lower.contains(entry.key) || compact.contains(keyword)) {
      tags.add(entry.value);
    }
  }

  const semanticGroups = <String, List<String>>{
    '체지방': ['체지방', '지방', '살', '체중', '몸무게', '비만'],
    '다이어트': ['다이어트', '감량', '살빼', '빼기', '체중감량', '식단', '운동', '칼로리', '대사', '지방분해'],
    '건강': ['건강', '영양', '호르몬', '혈액순환', '신진대사', '근육'],
    '학습': ['공부', '학습', '학교', '과제', '시험', '발표'],
    '앱개발': ['앱', '모바일', '안드로이드', 'ios', '에뮬레이터', '위젯'],
    '데이터저장': ['저장', '데이터베이스', '로컬', '복원', 'sqlite', 'securestorage'],
  };

  for (final entry in semanticGroups.entries) {
    if (entry.value.any((keyword) => compact.contains(keyword.toLowerCase()))) {
      tags.add(entry.key);
    }
  }

  if (tags.contains('체지방') &&
      (compact.contains('빼') ||
          compact.contains('어렵') ||
          compact.contains('감량') ||
          compact.contains('운동'))) {
    tags.add('다이어트');
  }

  tags.addAll(_genericTopicTags(text, tags));
  return tags.toList()..sort();
}

List<String> _genericTopicTags(String text, Set<String> existingTags) {
  final tokens = _tagTokensFromText(text);
  final tokenScores = <String, int>{};
  final phraseScores = <String, int>{};

  for (var index = 0; index < tokens.length; index += 1) {
    final token = tokens[index];
    if (_isUsefulTagToken(token) && !existingTags.contains(token)) {
      final earlyTopicBoost = index < 8 ? 2 : 0;
      tokenScores[token] = (tokenScores[token] ?? 0) + 2 + earlyTopicBoost;
    }
  }

  for (var index = 0; index < tokens.length - 1; index += 1) {
    final first = tokens[index];
    final second = tokens[index + 1];
    if (!_isUsefulTagToken(first) || !_isUsefulTagToken(second)) {
      continue;
    }
    final phrase = '$first-$second';
    if (!existingTags.contains(phrase)) {
      phraseScores[phrase] = (phraseScores[phrase] ?? 0) + 3;
    }
  }

  int compareTagsByScore(MapEntry<String, int> a, MapEntry<String, int> b) {
    final scoreCompare = b.value.compareTo(a.value);
    if (scoreCompare != 0) {
      return scoreCompare;
    }
    final lengthCompare = b.key.length.compareTo(a.key.length);
    if (lengthCompare != 0) {
      return lengthCompare;
    }
    return a.key.compareTo(b.key);
  }

  final rankedTokens = tokenScores.entries.toList()..sort(compareTagsByScore);
  final rankedPhrases = phraseScores.entries.toList()..sort(compareTagsByScore);
  final result = <String>[...rankedTokens.take(6).map((entry) => entry.key)];
  for (final phrase in rankedPhrases.take(2).map((entry) => entry.key)) {
    if (!result.contains(phrase)) {
      result.add(phrase);
    }
  }
  return result;
}

List<String> _tagTokensFromText(String text) {
  final tokenPattern = RegExp(r'[A-Za-z][A-Za-z0-9+#.-]{2,}|[가-힣]{2,}');
  return tokenPattern
      .allMatches(text)
      .map((match) => _normalizeTagToken(match.group(0) ?? ''))
      .where((token) => token.isNotEmpty)
      .toList();
}

String _normalizeTagToken(String raw) {
  var token = raw.toLowerCase().trim();
  token = token.replaceAll(
    RegExp(r'^[^a-z0-9가-힣+#.-]+|[^a-z0-9가-힣+#.-]+$'),
    '',
  );
  if (!RegExp(r'[가-힣]').hasMatch(token)) {
    return token;
  }

  const suffixes = [
    '입니다',
    '합니다',
    '해주세요',
    '알려줘',
    '인가요',
    '이라는',
    '들은',
    '에서',
    '으로',
    '에게',
    '부터',
    '까지',
    '처럼',
    '보다',
    '이라',
    '라고',
    '하고',
    '이며',
    '에는',
    '해줘',
    '까요',
    '나요',
    '은',
    '는',
    '이',
    '가',
    '을',
    '를',
    '의',
    '도',
    '만',
    '로',
    '에',
    '와',
    '과',
    '랑',
    '들',
  ];

  var changed = true;
  while (changed) {
    changed = false;
    for (final suffix in suffixes) {
      if (token.endsWith(suffix) && token.length - suffix.length >= 2) {
        token = token.substring(0, token.length - suffix.length);
        changed = true;
        break;
      }
    }
  }
  return token;
}

bool _isUsefulTagToken(String token) {
  if (token.length < 2 || RegExp(r'^\d+$').hasMatch(token)) {
    return false;
  }
  const stopWords = {
    'ai',
    'api',
    'the',
    'and',
    'for',
    'with',
    'this',
    'that',
    'what',
    'how',
    'why',
    'when',
    'where',
    'please',
    'about',
    'answer',
    'question',
    'user',
    'assistant',
    'test',
    'error',
    'model',
    '사용자',
    '답변',
    '질문',
    '대화',
    '내용',
    '설명',
    '방법',
    '이유',
    '경우',
    '관련',
    '관계',
    '정도',
    '부분',
    '테스트',
    '간단',
    '무엇',
    '뭐야',
    '어떻게',
    '어떤',
    '있어',
    '없어',
    '가능',
    '중요',
    '관리',
    '어렵',
    '문의',
    '추가',
    '저장',
    '사용',
    '위해',
    '대한',
    '대해',
    '하면',
    '할까',
    '하나',
    '하나요',
    '해주세요',
    '알려줘',
    '그리고',
    '하지만',
    '그러면',
    '예시',
    '정상',
    '오류',
    '발생',
    '확인',
    '요약',
    '원인',
  };
  return !stopWords.contains(token);
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
    trashedItems = const [];
  }

  static const _legacyOpenAiApiKeyStorageKey = 'openai_api_key';
  static const _appStateStorageKey = 'llm_wiki_app_state_v1';
  static const _legacySeedProjectIds = {'mobile', 'research', 'security'};
  static const _legacySeedConversationIds = {
    'conv-seed-1',
    'conv-seed-2',
    'conv-seed-3',
  };
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final OpenAiClient _openAiClient = OpenAiClient();
  final GeminiClient _geminiClient = GeminiClient();
  final AnthropicClient _anthropicClient = AnthropicClient();
  final XAiClient _xAiClient = XAiClient();

  late List<ProjectSpace> projects;
  late List<Conversation> conversations;
  late List<TrashItem> trashedItems;
  Map<AiProvider, List<ApiKeyEntry>> apiKeys = {
    for (final provider in AiProvider.values) provider: const [],
  };
  SecuritySettings settings;
  bool isInitialized = false;

  ProjectSpace projectById(String id) {
    return projects.firstWhere(
      (project) => project.id == id,
      orElse: () => ProjectSpace(
        id: id,
        name: id,
        description: '',
        color: const Color(0xFF6B7280),
      ),
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

  void updateProject({
    required String projectId,
    required String name,
    String? description,
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      return;
    }
    projects = projects.map((project) {
      if (project.id != projectId) {
        return project;
      }
      return project.copyWith(
        name: cleanName,
        description: description?.trim(),
      );
    }).toList();
    unawaited(_persistSnapshot());
    notifyListeners();
  }

  ({ProjectSpace project, List<Conversation> conversations})? deleteProject(
    String projectId,
  ) {
    final index = projects.indexWhere((project) => project.id == projectId);
    if (index < 0) {
      return null;
    }
    final removedProject = projects[index];
    final removedConversations = conversations
        .where((conversation) => conversation.projectId == projectId)
        .toList();
    projects = [...projects.take(index), ...projects.skip(index + 1)];
    conversations = conversations
        .where((conversation) => conversation.projectId != projectId)
        .toList();
    trashedItems = [
      TrashItem(
        id: 'trash-project-${DateTime.now().microsecondsSinceEpoch}',
        type: TrashItemType.project,
        deletedAt: DateTime.now(),
        project: removedProject,
        conversations: removedConversations,
      ),
      ...trashedItems,
    ];
    unawaited(_persistSnapshot());
    notifyListeners();
    return (project: removedProject, conversations: removedConversations);
  }

  void restoreProject(
    ProjectSpace project,
    List<Conversation> projectConversations,
  ) {
    if (!projects.any((item) => item.id == project.id)) {
      projects = [...projects, project];
    }
    final existingConversationIds = conversations
        .map((item) => item.id)
        .toSet();
    conversations = [
      ...projectConversations.where(
        (conversation) => !existingConversationIds.contains(conversation.id),
      ),
      ...conversations,
    ];
    trashedItems = trashedItems.where((item) {
      return !(item.type == TrashItemType.project &&
          item.project?.id == project.id);
    }).toList();
    unawaited(_persistSnapshot());
    notifyListeners();
  }

  void renameConversation({
    required String conversationId,
    required String title,
  }) {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      return;
    }
    conversations = conversations.map((conversation) {
      if (conversation.id != conversationId) {
        return conversation;
      }
      return conversation.copyWith(
        title: cleanTitle,
        updatedAt: DateTime.now(),
      );
    }).toList();
    unawaited(_persistSnapshot());
    notifyListeners();
  }

  void moveConversation({
    required String conversationId,
    required String projectId,
  }) {
    if (!projects.any((project) => project.id == projectId)) {
      return;
    }
    conversations = conversations.map((conversation) {
      if (conversation.id != conversationId) {
        return conversation;
      }
      return conversation.copyWith(
        projectId: projectId,
        updatedAt: DateTime.now(),
      );
    }).toList();
    unawaited(_persistSnapshot());
    notifyListeners();
  }

  Conversation? deleteConversation(String conversationId) {
    final index = conversations.indexWhere(
      (conversation) => conversation.id == conversationId,
    );
    if (index < 0) {
      return null;
    }
    final removed = conversations[index];
    conversations = [
      ...conversations.take(index),
      ...conversations.skip(index + 1),
    ];
    trashedItems = [
      TrashItem(
        id: 'trash-conversation-${DateTime.now().microsecondsSinceEpoch}',
        type: TrashItemType.conversation,
        deletedAt: DateTime.now(),
        conversation: removed,
      ),
      ...trashedItems,
    ];
    unawaited(_persistSnapshot());
    notifyListeners();
    return removed;
  }

  void restoreConversation(Conversation conversation) {
    if (conversations.any((item) => item.id == conversation.id)) {
      return;
    }
    if (!projects.any((project) => project.id == conversation.projectId)) {
      projects = [
        ...projects,
        ProjectSpace(
          id: conversation.projectId,
          name: conversation.projectId,
          description: '',
          color: _projectColorForIndex(projects.length),
        ),
      ];
    }
    conversations = [conversation, ...conversations];
    trashedItems = trashedItems.where((item) {
      return !(item.type == TrashItemType.conversation &&
          item.conversation?.id == conversation.id);
    }).toList();
    unawaited(_persistSnapshot());
    notifyListeners();
  }

  void restoreTrashItem(String trashItemId) {
    final item = trashedItems
        .where((trashItem) => trashItem.id == trashItemId)
        .firstOrNull;
    if (item == null) {
      return;
    }
    switch (item.type) {
      case TrashItemType.conversation:
        final conversation = item.conversation;
        if (conversation != null &&
            !conversations.any((saved) => saved.id == conversation.id)) {
          if (!projects.any(
            (project) => project.id == conversation.projectId,
          )) {
            projects = [
              ...projects,
              ProjectSpace(
                id: conversation.projectId,
                name: conversation.projectId,
                description: '',
                color: _projectColorForIndex(projects.length),
              ),
            ];
          }
          conversations = [conversation, ...conversations];
        }
      case TrashItemType.project:
        final project = item.project;
        if (project != null) {
          if (!projects.any((saved) => saved.id == project.id)) {
            projects = [...projects, project];
          }
          final existingConversationIds = conversations
              .map((conversation) => conversation.id)
              .toSet();
          conversations = [
            ...item.conversations.where(
              (conversation) =>
                  !existingConversationIds.contains(conversation.id),
            ),
            ...conversations,
          ];
        }
    }
    trashedItems = trashedItems
        .where((trashItem) => trashItem.id != trashItemId)
        .toList();
    unawaited(_persistSnapshot());
    notifyListeners();
  }

  void permanentlyDeleteTrashItem(String trashItemId) {
    trashedItems = trashedItems
        .where((trashItem) => trashItem.id != trashItemId)
        .toList();
    unawaited(_persistSnapshot());
    notifyListeners();
  }

  void emptyTrash() {
    trashedItems = const [];
    unawaited(_persistSnapshot());
    notifyListeners();
  }

  Future<void> initialize() async {
    final snapshot = await _readPersistedSnapshot();
    if (snapshot != null) {
      settings = snapshot.settings;
      projects = snapshot.projects;
      conversations = snapshot.conversations;
      trashedItems = snapshot.trashedItems;
      unawaited(_persistSnapshot());
    }
    await _refreshApiKeys();
    settings = _settingsWithValidActiveApiKeys(
      settings,
    ).copyWith(apiKeySaved: _hasApiKey(settings.aiProvider));
    unawaited(_persistSnapshot());
    isInitialized = true;
    notifyListeners();
  }

  List<ApiKeyEntry> apiKeysFor(AiProvider provider) {
    return List.unmodifiable(apiKeys[provider] ?? const []);
  }

  String? activeApiKeyIdFor(AiProvider provider) {
    final activeId = settings.activeApiKeyIds[provider.id];
    if (activeId != null &&
        (apiKeys[provider] ?? const []).any((entry) => entry.id == activeId)) {
      return activeId;
    }
    final entries = apiKeys[provider] ?? const [];
    return entries.isEmpty ? null : entries.first.id;
  }

  bool _hasApiKey(AiProvider provider) {
    return activeApiKeyIdFor(provider) != null;
  }

  Future<void> _refreshApiKeys() async {
    for (final provider in AiProvider.values) {
      apiKeys = {...apiKeys, provider: await _loadApiKeyEntries(provider)};
    }
  }

  Future<List<ApiKeyEntry>> _loadApiKeyEntries(AiProvider provider) async {
    try {
      final entries = <ApiKeyEntry>[];
      final raw = await _secureStorage.read(
        key: _apiKeyRingStorageKey(provider),
      );
      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          entries.addAll(
            decoded
                .whereType<Map>()
                .map(
                  (item) =>
                      ApiKeyEntry.fromJson(Map<String, dynamic>.from(item)),
                )
                .where((entry) => entry.value.trim().isNotEmpty),
          );
        }
      }

      final legacyKey = await _secureStorage.read(
        key: _apiKeyStorageKey(provider),
      );
      if (legacyKey != null &&
          legacyKey.trim().isNotEmpty &&
          !entries.any((entry) => entry.value == legacyKey.trim())) {
        entries.add(
          ApiKeyEntry(
            id: '${provider.id}-legacy',
            label: '${provider.label} 키 ${entries.length + 1}',
            value: legacyKey.trim(),
            createdAt: DateTime.now(),
          ),
        );
        await _persistApiKeys(provider, entries);
      }

      return entries;
    } on MissingPluginException {
      return const [];
    } catch (_) {
      return const [];
    }
  }

  SecuritySettings _settingsWithValidActiveApiKeys(SecuritySettings current) {
    final activeIds = Map<String, String>.from(current.activeApiKeyIds);
    for (final provider in AiProvider.values) {
      final entries = apiKeys[provider] ?? const [];
      final activeId = activeIds[provider.id];
      if (activeId == null || !entries.any((entry) => entry.id == activeId)) {
        if (entries.isEmpty) {
          activeIds.remove(provider.id);
        } else {
          activeIds[provider.id] = entries.first.id;
        }
      }
    }
    return current.copyWith(activeApiKeyIds: activeIds);
  }

  SecuritySettings _settingsWithSelectedApiKey(
    AiProvider provider,
    String? apiKeyId, {
    SecuritySettings? base,
  }) {
    final activeIds = Map<String, String>.from(
      (base ?? settings).activeApiKeyIds,
    );
    if (apiKeyId == null) {
      activeIds.remove(provider.id);
    } else {
      activeIds[provider.id] = apiKeyId;
    }
    final next = (base ?? settings).copyWith(activeApiKeyIds: activeIds);
    return _settingsWithValidActiveApiKeys(next);
  }

  Future<void> _persistApiKeys(
    AiProvider provider,
    List<ApiKeyEntry> entries,
  ) async {
    await _secureStorage.write(
      key: _apiKeyRingStorageKey(provider),
      value: jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<void> selectApiKey(AiProvider provider, String apiKeyId) async {
    if (!(apiKeys[provider] ?? const []).any((entry) => entry.id == apiKeyId)) {
      return;
    }
    settings = settings.copyWith(aiProvider: provider, apiKeySaved: true);
    settings = _settingsWithSelectedApiKey(provider, apiKeyId);
    await _persistSnapshot();
    notifyListeners();
  }

  Future<void> loadSecureState() async {
    await initialize();
  }

  Future<bool> saveApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    final provider = settings.aiProvider;
    final entries = [...apiKeysFor(provider)];
    final existing = entries
        .where((entry) => entry.value.trim() == trimmed)
        .firstOrNull;
    final selected =
        existing ??
        ApiKeyEntry(
          id: '${provider.id}-key-${DateTime.now().microsecondsSinceEpoch}',
          label: '${provider.label} 키 ${entries.length + 1}',
          value: trimmed,
          createdAt: DateTime.now(),
        );
    if (existing == null) {
      entries.add(selected);
      apiKeys = {...apiKeys, provider: entries};
      await _persistApiKeys(provider, entries);
    }
    settings = _settingsWithSelectedApiKey(
      provider,
      selected.id,
      base: settings.copyWith(apiKeySaved: true),
    );
    await _persistSnapshot();
    notifyListeners();
    return true;
  }

  Future<void> deleteApiKey(AiProvider provider, String apiKeyId) async {
    final entries = apiKeysFor(
      provider,
    ).where((entry) => entry.id != apiKeyId).toList();
    apiKeys = {...apiKeys, provider: entries};
    await _persistApiKeys(provider, entries);
    final nextActiveId = entries.isEmpty ? null : entries.first.id;
    settings = _settingsWithSelectedApiKey(
      provider,
      nextActiveId,
      base: settings.copyWith(
        apiKeySaved: provider == settings.aiProvider
            ? nextActiveId != null
            : settings.apiKeySaved,
      ),
    );
    await _persistSnapshot();
    notifyListeners();
  }

  Future<String?> _readApiKey() async {
    final provider = settings.aiProvider;
    var entries = apiKeys[provider] ?? const [];
    if (entries.isEmpty) {
      await _refreshApiKeys();
      entries = apiKeys[provider] ?? const [];
    }
    final activeId = activeApiKeyIdFor(provider);
    if (activeId == null) {
      return null;
    }
    return entries
        .where((entry) => entry.id == activeId)
        .map((entry) => entry.value.trim())
        .firstOrNull;
  }

  Future<void> updateAiProvider(AiProvider provider) async {
    await _refreshApiKeys();
    final selectedId = activeApiKeyIdFor(provider);
    settings = _settingsWithSelectedApiKey(
      provider,
      selectedId,
      base: settings.copyWith(
        aiProvider: provider,
        apiKeySaved: selectedId != null,
      ),
    );
    await _persistSnapshot();
    notifyListeners();
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
      assistantReply = l.missingApiKeyAssistant(settings.aiProvider);
    } else {
      try {
        assistantReply = switch (settings.aiProvider) {
          AiProvider.openAi => await _openAiClient.generateAnswer(
            apiKey: apiKey,
            prompt: sanitizedPrompt,
            language: settings.language,
          ),
          AiProvider.gemini => await _geminiClient.generateAnswer(
            apiKey: apiKey,
            prompt: sanitizedPrompt,
            language: settings.language,
          ),
          AiProvider.anthropic => await _anthropicClient.generateAnswer(
            apiKey: apiKey,
            prompt: sanitizedPrompt,
            language: settings.language,
          ),
          AiProvider.xAi => await _xAiClient.generateAnswer(
            apiKey: apiKey,
            prompt: sanitizedPrompt,
            language: settings.language,
          ),
        };
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

  Future<_PersistedSnapshot?> _readPersistedSnapshot() async {
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
      final trashJson = decoded['trash'];
      final restoredSettings = settingsJson is Map<String, dynamic>
          ? SecuritySettings.fromJson(settingsJson, apiKeySaved: false)
          : settings.copyWith(apiKeySaved: false);
      final restoredProjects = projectsJson is List
          ? projectsJson
                .whereType<Map>()
                .map(
                  (project) =>
                      ProjectSpace.fromJson(Map<String, dynamic>.from(project)),
                )
                .where((project) => project.id.trim().isNotEmpty)
                .where((project) => !_legacySeedProjectIds.contains(project.id))
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
                .where(
                  (conversation) =>
                      !_legacySeedConversationIds.contains(conversation.id),
                )
                .where(
                  (conversation) =>
                      !_legacySeedProjectIds.contains(conversation.projectId),
                )
                .toList()
          : <Conversation>[];
      final restoredTrash = trashJson is List
          ? trashJson
                .whereType<Map>()
                .map(
                  (item) => TrashItem.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : <TrashItem>[];
      return _PersistedSnapshot(
        settings: restoredSettings,
        projects: restoredProjects,
        conversations: restoredConversations,
        trashedItems: restoredTrash,
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
        'trash': trashedItems.map((item) => item.toJson()).toList(),
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

  String _apiKeyStorageKey(AiProvider provider) {
    return switch (provider) {
      AiProvider.openAi => _legacyOpenAiApiKeyStorageKey,
      AiProvider.gemini => 'gemini_api_key',
      AiProvider.anthropic => 'anthropic_api_key',
      AiProvider.xAi => 'xai_api_key',
    };
  }

  String _apiKeyRingStorageKey(AiProvider provider) {
    return '${provider.id}_api_key_ring_v1';
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
    return const [];
  }

  List<ProjectSpace> _defaultProjects() {
    return const [];
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
    return _autoTagsFromText(prompt);
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
  static const String _groupedProjectId = '__grouped__';
  final TextEditingController searchController = TextEditingController();
  String selectedProjectId = _groupedProjectId;
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
      projectId: selectedProjectId == _groupedProjectId
          ? 'all'
          : selectedProjectId,
      selectedTags: selectedTags,
    );
    final isGrouped = selectedProjectId == _groupedProjectId;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _MetricStrip(repository: widget.repository),
        const SizedBox(height: 12),
        _TrashAccessCard(
          count: widget.repository.trashedItems.length,
          language: widget.repository.settings.language,
          onTap: () => _openTrash(context),
        ),
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
          groupedProjectId: _groupedProjectId,
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
        else if (isGrouped)
          ..._buildProjectSections(context, conversations)
        else
          ...conversations.map(
            (conversation) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ConversationCard(
                conversation: conversation,
                project: widget.repository.projectById(conversation.projectId),
                language: widget.repository.settings.language,
                onTap: () => _openConversation(context, conversation),
                onRename: () => _renameConversation(context, conversation),
                onMove: () => _moveConversation(context, conversation),
                onDelete: () => _deleteConversation(context, conversation),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildProjectSections(
    BuildContext context,
    List<Conversation> conversations,
  ) {
    final grouped = <String, List<Conversation>>{};
    for (final conversation in conversations) {
      grouped.putIfAbsent(conversation.projectId, () => []).add(conversation);
    }
    final projectIds = grouped.keys.toList()
      ..sort((a, b) {
        final projectA = widget.repository.projectById(a).name;
        final projectB = widget.repository.projectById(b).name;
        return projectA.compareTo(projectB);
      });

    return projectIds.expand((projectId) {
      final project = widget.repository.projectById(projectId);
      final projectConversations = grouped[projectId] ?? const <Conversation>[];
      return [
        _ProjectSectionHeader(
          project: project,
          language: widget.repository.settings.language,
          count: projectConversations.length,
          onRename: () => _renameProject(context, project),
          onDelete: () => _deleteProject(context, project),
        ),
        const SizedBox(height: 8),
        ...projectConversations.map(
          (conversation) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ConversationCard(
              conversation: conversation,
              project: project,
              language: widget.repository.settings.language,
              onTap: () => _openConversation(context, conversation),
              onRename: () => _renameConversation(context, conversation),
              onMove: () => _moveConversation(context, conversation),
              onDelete: () => _deleteConversation(context, conversation),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ];
    }).toList();
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
          onRename: () {
            Navigator.pop(context);
            _renameConversation(context, conversation);
          },
          onMove: () {
            Navigator.pop(context);
            _moveConversation(context, conversation);
          },
          onDelete: () {
            Navigator.pop(context);
            _deleteConversation(context, conversation);
          },
        );
      },
    );
  }

  void _openTrash(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return TrashSheet(
          repository: widget.repository,
          language: widget.repository.settings.language,
          onChanged: () {
            if (mounted) {
              setState(() {});
            }
          },
        );
      },
    );
  }

  Future<void> _renameConversation(
    BuildContext context,
    Conversation conversation,
  ) async {
    final l = AppText.of(widget.repository.settings.language);
    final title = await _showTextEditDialog(
      context: context,
      title: l.rename,
      label: l.conversationTitle,
      initialValue: conversation.title,
    );
    if (title == null) {
      return;
    }
    widget.repository.renameConversation(
      conversationId: conversation.id,
      title: title,
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.renamed)));
  }

  Future<void> _moveConversation(
    BuildContext context,
    Conversation conversation,
  ) async {
    final l = AppText.of(widget.repository.settings.language);
    final projectId = await _showProjectPickerDialog(
      context: context,
      repository: widget.repository,
      currentProjectId: conversation.projectId,
    );
    if (projectId == null) {
      return;
    }
    widget.repository.moveConversation(
      conversationId: conversation.id,
      projectId: projectId,
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.moved)));
  }

  Future<void> _deleteConversation(
    BuildContext context,
    Conversation conversation,
  ) async {
    final l = AppText.of(widget.repository.settings.language);
    final confirmed = await _confirm(
      context: context,
      title: l.deleteConversation,
      message: l.deleteConversationConfirm,
      confirmLabel: l.moveToTrash,
    );
    if (!confirmed) {
      return;
    }
    final deleted = widget.repository.deleteConversation(conversation.id);
    if (!context.mounted || deleted == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.movedToTrash),
        action: SnackBarAction(
          label: l.undone,
          onPressed: () => widget.repository.restoreConversation(deleted),
        ),
      ),
    );
  }

  Future<void> _renameProject(
    BuildContext context,
    ProjectSpace project,
  ) async {
    final l = AppText.of(widget.repository.settings.language);
    final name = await _showTextEditDialog(
      context: context,
      title: l.rename,
      label: l.projectNameLabel,
      initialValue: project.name,
    );
    if (name == null) {
      return;
    }
    widget.repository.updateProject(projectId: project.id, name: name);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.renamed)));
  }

  Future<void> _deleteProject(
    BuildContext context,
    ProjectSpace project,
  ) async {
    final l = AppText.of(widget.repository.settings.language);
    final confirmed = await _confirm(
      context: context,
      title: l.deleteProject,
      message: l.deleteProjectWithChats,
      confirmLabel: l.moveToTrash,
    );
    if (!confirmed) {
      return;
    }
    final deleted = widget.repository.deleteProject(project.id);
    if (!context.mounted || deleted == null) {
      return;
    }
    setState(() {
      selectedProjectId = _groupedProjectId;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.movedToTrash),
        action: SnackBarAction(
          label: l.undone,
          onPressed: () => widget.repository.restoreProject(
            deleted.project,
            deleted.conversations,
          ),
        ),
      ),
    );
  }
}

class _TrashAccessCard extends StatelessWidget {
  const _TrashAccessCard({
    required this.count,
    required this.language,
    required this.onTap,
  });

  final int count;
  final AppLanguage language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppText.of(language);
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.trash,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      count == 0 ? l.emptyTrash : l.trashItemCount(count),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class TrashSheet extends StatefulWidget {
  const TrashSheet({
    super.key,
    required this.repository,
    required this.language,
    required this.onChanged,
  });

  final WikiRepository repository;
  final AppLanguage language;
  final VoidCallback onChanged;

  @override
  State<TrashSheet> createState() => _TrashSheetState();
}

class _TrashSheetState extends State<TrashSheet> {
  @override
  Widget build(BuildContext context) {
    final l = AppText.of(widget.language);
    final items = widget.repository.trashedItems;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      maxChildSize: 0.92,
      minChildSize: 0.38,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.trash,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                if (items.isNotEmpty)
                  IconButton(
                    tooltip: l.clearTrash,
                    onPressed: _emptyTrash,
                    icon: const Icon(Icons.delete_sweep_outlined),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              items.isEmpty ? l.emptyTrash : l.trashItemCount(items.length),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 56),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 44,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l.emptyTrash,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TrashItemCard(
                    item: item,
                    language: widget.language,
                    onRestore: () => _restore(item),
                    onDeleteForever: () => _deleteForever(item),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _restore(TrashItem item) {
    final l = AppText.of(widget.language);
    widget.repository.restoreTrashItem(item.id);
    widget.onChanged();
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.restored)));
  }

  Future<void> _deleteForever(TrashItem item) async {
    final l = AppText.of(widget.language);
    final confirmed = await _confirm(
      context: context,
      title: l.deleteForever,
      message: l.deleteForeverConfirm,
      confirmLabel: l.deleteForever,
    );
    if (!confirmed || !mounted) {
      return;
    }
    widget.repository.permanentlyDeleteTrashItem(item.id);
    widget.onChanged();
    setState(() {});
  }

  Future<void> _emptyTrash() async {
    final l = AppText.of(widget.language);
    final confirmed = await _confirm(
      context: context,
      title: l.clearTrash,
      message: l.emptyTrashConfirm,
      confirmLabel: l.deleteForever,
    );
    if (!confirmed || !mounted) {
      return;
    }
    widget.repository.emptyTrash();
    widget.onChanged();
    setState(() {});
  }
}

class _TrashItemCard extends StatelessWidget {
  const _TrashItemCard({
    required this.item,
    required this.language,
    required this.onRestore,
    required this.onDeleteForever,
  });

  final TrashItem item;
  final AppLanguage language;
  final VoidCallback onRestore;
  final VoidCallback onDeleteForever;

  @override
  Widget build(BuildContext context) {
    final l = AppText.of(language);
    final isProject = item.type == TrashItemType.project;
    final subtitle = isProject
        ? '${l.trashProjectSubtitle} · ${l.savedConversationCount(item.conversationCount)}'
        : l.trashConversationSubtitle;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isProject
                      ? Icons.folder_delete_outlined
                      : Icons.chat_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title(l),
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$subtitle · ${l.pick(ko: '삭제일', en: 'Deleted', ja: '削除日')} ${_formatDateTime(item.deletedAt)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onRestore,
                  icon: const Icon(Icons.restore_outlined),
                  label: Text(l.restore),
                ),
                TextButton.icon(
                  onPressed: onDeleteForever,
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: Text(l.deleteForever),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<String?> _showTextEditDialog({
  required BuildContext context,
  required String title,
  required String label,
  required String initialValue,
}) async {
  final controller = TextEditingController(text: initialValue);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(labelText: label),
        textInputAction: TextInputAction.done,
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    ),
  );
  controller.dispose();
  return result == null || result.trim().isEmpty ? null : result.trim();
}

Future<String?> _showProjectPickerDialog({
  required BuildContext context,
  required WikiRepository repository,
  required String currentProjectId,
}) {
  final l = AppText.of(repository.settings.language);
  return showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(l.moveConversation),
      children: repository.projects
          .map(
            (project) => SimpleDialogOption(
              onPressed: () => Navigator.pop(context, project.id),
              child: Row(
                children: [
                  Icon(Icons.folder_outlined, color: project.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(l.projectName(project.id, project.name)),
                  ),
                  if (project.id == currentProjectId)
                    Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
          )
          .toList(),
    ),
  );
}

Future<bool> _confirm({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ) ??
      false;
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
    required this.groupedProjectId,
    required this.onSelected,
  });

  final List<ProjectSpace> projects;
  final AppLanguage language;
  final String selectedProjectId;
  final String groupedProjectId;
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
              label: Text(l.projectGroups),
              selected: selectedProjectId == groupedProjectId,
              onSelected: (_) => onSelected(groupedProjectId),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(l.allChats),
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

class _ProjectSectionHeader extends StatelessWidget {
  const _ProjectSectionHeader({
    required this.project,
    required this.language,
    required this.count,
    required this.onRename,
    required this.onDelete,
  });

  final ProjectSpace project;
  final AppLanguage language;
  final int count;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = AppText.of(language);
    return Row(
      children: [
        Icon(Icons.folder_outlined, color: project.color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${l.projectName(project.id, project.name)} · $count',
            style: Theme.of(context).textTheme.titleMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        PopupMenuButton<String>(
          tooltip: l.manage,
          onSelected: (value) {
            switch (value) {
              case 'rename':
                onRename();
              case 'delete':
                onDelete();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'rename',
              child: ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(l.rename),
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l.delete),
              ),
            ),
          ],
        ),
      ],
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
    this.onRename,
    this.onMove,
    this.onDelete,
  });

  final Conversation conversation;
  final ProjectSpace project;
  final AppLanguage language;
  final VoidCallback onTap;
  final VoidCallback? onRename;
  final VoidCallback? onMove;
  final VoidCallback? onDelete;

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
                  if (onRename != null || onMove != null || onDelete != null)
                    PopupMenuButton<String>(
                      tooltip: l.manage,
                      onSelected: (value) {
                        switch (value) {
                          case 'rename':
                            onRename?.call();
                          case 'move':
                            onMove?.call();
                          case 'delete':
                            onDelete?.call();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'rename',
                          child: ListTile(
                            leading: const Icon(Icons.edit_outlined),
                            title: Text(l.rename),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'move',
                          child: ListTile(
                            leading: const Icon(Icons.drive_file_move_outlined),
                            title: Text(l.moveConversation),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: const Icon(Icons.delete_outline),
                            title: Text(l.delete),
                          ),
                        ),
                      ],
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
    required this.onRename,
    required this.onMove,
    required this.onDelete,
  });

  final Conversation conversation;
  final ProjectSpace project;
  final AppLanguage language;
  final ValueChanged<String> onAddTag;
  final VoidCallback onRename;
  final VoidCallback onMove;
  final VoidCallback onDelete;

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
            Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<String>(
                tooltip: l.manage,
                onSelected: (value) {
                  switch (value) {
                    case 'rename':
                      widget.onRename();
                    case 'move':
                      widget.onMove();
                    case 'delete':
                      widget.onDelete();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'rename',
                    child: ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: Text(l.rename),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'move',
                    child: ListTile(
                      leading: const Icon(Icons.drive_file_move_outlined),
                      title: Text(l.moveConversation),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: const Icon(Icons.delete_outline),
                      title: Text(l.delete),
                    ),
                  ),
                ],
              ),
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
  static const String _allDrawerProjects = 'all';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? projectId;
  final TextEditingController promptController = TextEditingController();
  final TextEditingController drawerSearchController = TextEditingController();
  String drawerProjectFilterId = _allDrawerProjects;
  Conversation? activeConversation;
  bool isSaving = false;

  @override
  void dispose() {
    promptController.dispose();
    drawerSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drawerConversations = widget.repository.search(
      query: drawerSearchController.text,
      projectId: drawerProjectFilterId,
      selectedTags: const <String>{},
    );

    return Scaffold(
      key: _scaffoldKey,
      drawerScrimColor: Colors.black.withValues(alpha: 0.42),
      drawer: ChatHistoryDrawer(
        repository: widget.repository,
        conversations: drawerConversations,
        activeConversationId: activeConversation?.id,
        selectedProjectId: drawerProjectFilterId,
        searchController: drawerSearchController,
        language: widget.repository.settings.language,
        onSearchChanged: (_) => setState(() {}),
        onProjectSelected: (value) {
          setState(() {
            drawerProjectFilterId = value;
          });
        },
        onNewChat: () {
          Navigator.pop(context);
          _startNewChat();
        },
        onConversationSelected: (conversation) {
          setState(() {
            activeConversation = conversation;
            projectId = conversation.projectId;
            drawerProjectFilterId = conversation.projectId;
          });
          Navigator.pop(context);
        },
      ),
      body: Column(
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
                  _EmptyChatState(
                    language: widget.repository.settings.language,
                  ),
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
      ),
    );
  }

  Future<void> _savePrompt() async {
    final prompt = promptController.text.trim();
    if (projectId == null) {
      final l = AppText.of(widget.repository.settings.language);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.createProjectFirst)));
      await _openCreateProjectDialog();
      return;
    }
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
        projectId: projectId!,
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

  void _selectProject(String? value) {
    if (value == null) {
      return;
    }
    final projectChats = widget.repository.search(
      query: '',
      projectId: value,
      selectedTags: const <String>{},
    );
    setState(() {
      projectId = value;
      activeConversation = projectChats.isEmpty ? null : projectChats.first;
      drawerProjectFilterId = value;
    });
  }

  void _openRecentChats() {
    _scaffoldKey.currentState?.openDrawer();
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
    if (project == null || !mounted) {
      return;
    }
    setState(() {
      projectId = project.id;
      activeConversation = null;
    });
  }
}

class ChatHistoryDrawer extends StatelessWidget {
  const ChatHistoryDrawer({
    super.key,
    required this.repository,
    required this.conversations,
    required this.activeConversationId,
    required this.selectedProjectId,
    required this.searchController,
    required this.language,
    required this.onSearchChanged,
    required this.onProjectSelected,
    required this.onNewChat,
    required this.onConversationSelected,
  });

  static const String _allProjects = 'all';

  final WikiRepository repository;
  final List<Conversation> conversations;
  final String? activeConversationId;
  final String selectedProjectId;
  final TextEditingController searchController;
  final AppLanguage language;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onProjectSelected;
  final VoidCallback onNewChat;
  final ValueChanged<Conversation> onConversationSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppText.of(language);
    final colorScheme = Theme.of(context).colorScheme;
    final width = math.min(MediaQuery.of(context).size.width * 0.86, 390.0);
    return Drawer(
      width: width,
      backgroundColor: const Color(0xFFFBFAF5),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const Key('chat-drawer-search'),
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: l.chatSearch,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l.clearSearch,
                          onPressed: () {
                            searchController.clear();
                            onSearchChanged('');
                          },
                          icon: const Icon(Icons.close),
                        ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.65,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onNewChat,
                  icon: const Icon(Icons.edit_square),
                  label: Text(l.newChat),
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(l.allChats),
                        selected: selectedProjectId == _allProjects,
                        onSelected: (_) => onProjectSelected(_allProjects),
                      ),
                    ),
                    ...repository.projects.map(
                      (project) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: CircleAvatar(backgroundColor: project.color),
                          label: Text(l.projectName(project.id, project.name)),
                          selected: selectedProjectId == project.id,
                          onSelected: (_) => onProjectSelected(project.id),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(l.chats, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Expanded(
                child: conversations.isEmpty
                    ? _EmptyRecentChats(language: language)
                    : ListView.separated(
                        itemCount: conversations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final conversation = conversations[index];
                          return _ChatHistoryTile(
                            conversation: conversation,
                            project: repository.projectById(
                              conversation.projectId,
                            ),
                            language: language,
                            selected: conversation.id == activeConversationId,
                            onTap: () => onConversationSelected(conversation),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatHistoryTile extends StatelessWidget {
  const _ChatHistoryTile({
    required this.conversation,
    required this.project,
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final Conversation conversation;
  final ProjectSpace project;
  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppText.of(language);
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? colorScheme.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                      conversation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _relativeTime(conversation.updatedAt),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l.projectName(project.id, project.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Text(
                conversation.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (conversation.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: conversation.tags
                      .take(3)
                      .map(
                        (tag) => Text(
                          '#$tag',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: colorScheme.primary),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
  final String? projectId;
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
  final String? projectId;
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.hub_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l.aiProvider,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownMenu<AiProvider>(
                  key: const Key('ai-provider-menu'),
                  width: double.infinity,
                  initialSelection: settings.aiProvider,
                  label: Text(l.aiProvider),
                  onSelected: (provider) async {
                    if (provider == null) {
                      return;
                    }
                    await widget.repository.updateAiProvider(provider);
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  dropdownMenuEntries: AiProvider.values
                      .map(
                        (provider) => DropdownMenuEntry<AiProvider>(
                          value: provider,
                          label: provider.label,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ApiKeyListCard(
          repository: widget.repository,
          provider: settings.aiProvider,
          language: settings.language,
          onChanged: () {
            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('api-key-field'),
          controller: apiKeyController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: '${l.addNewApiKey} · ${l.apiKey(settings.aiProvider)}',
            hintText: settings.apiKeySaved
                ? l.apiKeySaved
                : switch (settings.aiProvider) {
                    AiProvider.gemini => 'AIza...',
                    AiProvider.openAi => 'sk-...',
                    AiProvider.anthropic => 'sk-ant-...',
                    AiProvider.xAi => 'xai-...',
                  },
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

class _ApiKeyListCard extends StatelessWidget {
  const _ApiKeyListCard({
    required this.repository,
    required this.provider,
    required this.language,
    required this.onChanged,
  });

  final WikiRepository repository;
  final AiProvider provider;
  final AppLanguage language;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppText.of(language);
    final entries = repository.apiKeysFor(provider);
    final activeId = repository.activeApiKeyIdFor(provider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.vpn_key_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.registeredApiKeys,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l.apiKeyMaskedNotice,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            if (entries.isEmpty)
              Text(l.noRegisteredApiKeys)
            else
              ...entries.map((entry) {
                final isActive = entry.id == activeId;
                return ListTile(
                  key: Key('api-key-option-${entry.id}'),
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isActive
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(entry.label)),
                      if (isActive)
                        Text(
                          l.activeApiKey,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(entry.maskedValue),
                  trailing: IconButton(
                    tooltip: l.apiKeyDeleted,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await repository.deleteApiKey(provider, entry.id);
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(l.apiKeyDeleted)));
                      onChanged();
                    },
                  ),
                  onTap: () async {
                    await repository.selectApiKey(provider, entry.id);
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(l.apiKeySelected)));
                    onChanged();
                  },
                );
              }),
          ],
        ),
      ),
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
