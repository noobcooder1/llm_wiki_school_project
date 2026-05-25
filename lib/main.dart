import 'package:flutter/material.dart';
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
  });

  final bool maskSensitiveInfo;
  final bool appLockEnabled;
  final bool localDbEncryption;
  final bool e2eeCloudSync;
  final bool apiKeySaved;

  SecuritySettings copyWith({
    bool? maskSensitiveInfo,
    bool? appLockEnabled,
    bool? localDbEncryption,
    bool? e2eeCloudSync,
    bool? apiKeySaved,
  }) {
    return SecuritySettings(
      maskSensitiveInfo: maskSensitiveInfo ?? this.maskSensitiveInfo,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      localDbEncryption: localDbEncryption ?? this.localDbEncryption,
      e2eeCloudSync: e2eeCloudSync ?? this.e2eeCloudSync,
      apiKeySaved: apiKeySaved ?? this.apiKeySaved,
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
    final selected =
        conversations
            .where(
              (conversation) =>
                  projectId == 'all' || conversation.projectId == projectId,
            )
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final buffer = StringBuffer()
      ..writeln('# LLM Wiki Export')
      ..writeln()
      ..writeln('- Exported: ${_formatDateTime(DateTime.now())}')
      ..writeln(
        '- Scope: ${projectId == 'all' ? 'All projects' : projectById(projectId).name}',
      )
      ..writeln();

    for (final conversation in selected) {
      final project = projectById(conversation.projectId);
      buffer
        ..writeln('## ${conversation.title}')
        ..writeln()
        ..writeln('- Project: ${project.name}')
        ..writeln('- Created: ${_formatDateTime(conversation.createdAt)}')
        ..writeln(
          '- Tags: ${conversation.tags.map((tag) => '#$tag').join(' ')}',
        )
        ..writeln();

      for (final message in conversation.messages) {
        final speaker = message.role == AiRole.user ? 'User' : 'Assistant';
        buffer
          ..writeln('### $speaker')
          ..writeln()
          ..writeln(message.content)
          ..writeln();
      }

      if (conversation.codeSnippets.isNotEmpty) {
        buffer
          ..writeln('### Code Snippets')
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
        title: 'SQLite schema for saved AI chats',
        createdAt: now.subtract(const Duration(days: 4, hours: 3)),
        updatedAt: now.subtract(const Duration(days: 4, hours: 2)),
        manualTags: const ['schema', 'local-first'],
        messages: [
          KnowledgeMessage(
            id: 'msg-1',
            role: AiRole.user,
            createdAt: now.subtract(const Duration(days: 4, hours: 3)),
            content:
                'Design a local SQLite structure for conversations, messages, and tags.',
          ),
          KnowledgeMessage(
            id: 'msg-2',
            role: AiRole.assistant,
            createdAt: now.subtract(const Duration(days: 4, hours: 2)),
            content:
                'Use conversations for project-level records, messages for ordered chat turns, and tags as a many-to-many index. SQLCipher can encrypt the database file while Secure Storage keeps the passphrase outside SQLite.',
          ),
        ],
      ),
      Conversation(
        id: 'conv-seed-2',
        projectId: 'security',
        title: 'API key handling checklist',
        createdAt: now.subtract(const Duration(days: 2, hours: 8)),
        updatedAt: now.subtract(const Duration(days: 2, hours: 7)),
        manualTags: const ['keychain', 'privacy'],
        messages: [
          KnowledgeMessage(
            id: 'msg-3',
            role: AiRole.user,
            createdAt: now.subtract(const Duration(days: 2, hours: 8)),
            content:
                'What should the app do so user OpenAI API keys are not leaked?',
          ),
          KnowledgeMessage(
            id: 'msg-4',
            role: AiRole.assistant,
            createdAt: now.subtract(const Duration(days: 2, hours: 7)),
            content:
                'Never send user API keys to a product server. Store keys in iOS Keychain or Android Keystore, enforce HTTPS/TLS for direct provider requests, and offer app lock plus sensitive information masking.',
          ),
        ],
      ),
      Conversation(
        id: 'conv-seed-3',
        projectId: 'research',
        title: 'Markdown export shape',
        createdAt: now.subtract(const Duration(hours: 20)),
        updatedAt: now.subtract(const Duration(hours: 18)),
        manualTags: const ['export', 'obsidian'],
        messages: [
          KnowledgeMessage(
            id: 'msg-5',
            role: AiRole.user,
            createdAt: now.subtract(const Duration(hours: 20)),
            content: 'Create a markdown template for exporting a chat.',
          ),
          KnowledgeMessage(
            id: 'msg-6',
            role: AiRole.assistant,
            createdAt: now.subtract(const Duration(hours: 18)),
            content:
                'A useful export includes project, tags, created date, each role turn, and extracted code. Example:\n\n```markdown\n## Conversation title\n- Project: Research\n- Tags: #search #memory\n\n### User\nPrompt text\n```',
          ),
        ],
      ),
    ];
  }

  String _mockAssistantReply(String prompt) {
    final tags = _tagsFromPrompt(prompt);
    final tagText = tags.isEmpty ? 'general knowledge' : tags.join(', ');
    return [
      'Saved this as reusable knowledge about $tagText.',
      '',
      'Suggested next actions:',
      '- Keep the original prompt and response linked to the project.',
      '- Review generated tags before exporting.',
      '- Promote durable decisions into a wiki note when they become stable.',
    ].join('\n');
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
      return 'Untitled conversation';
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
        return Scaffold(
          appBar: AppBar(
            title: const Text('LLM Wiki'),
            actions: [
              IconButton(
                tooltip: 'Copy markdown export',
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: repository.exportMarkdown()),
                  );
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Markdown copied')),
                  );
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
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.library_books_outlined),
                selectedIcon: Icon(Icons.library_books),
                label: 'Library',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_comment_outlined),
                selectedIcon: Icon(Icons.add_comment),
                label: 'Capture',
              ),
              NavigationDestination(
                icon: Icon(Icons.ios_share_outlined),
                selectedIcon: Icon(Icons.ios_share),
                label: 'Export',
              ),
              NavigationDestination(
                icon: Icon(Icons.lock_outline),
                selectedIcon: Icon(Icons.lock),
                label: 'Security',
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
          hintText: 'Search title, body, or tag',
          onChanged: (_) => setState(() {}),
          trailing: [
            if (searchController.text.isNotEmpty)
              IconButton(
                tooltip: 'Clear search',
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
          '${conversations.length} saved conversations',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (conversations.isEmpty)
          const _EmptyState()
        else
          ...conversations.map(
            (conversation) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ConversationCard(
                conversation: conversation,
                project: widget.repository.projectById(conversation.projectId),
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
    final snippets = repository.conversations.fold<int>(
      0,
      (count, conversation) => count + conversation.codeSnippets.length,
    );
    final metrics = [
      (
        'Projects',
        repository.projects.length.toString(),
        Icons.folder_outlined,
      ),
      (
        'Chats',
        repository.conversations.length.toString(),
        Icons.forum_outlined,
      ),
      ('Tags', repository.allTags.length.toString(), Icons.sell_outlined),
      ('Code', snippets.toString(), Icons.code),
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
    required this.selectedProjectId,
    required this.onSelected,
  });

  final List<ProjectSpace> projects;
  final String selectedProjectId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('All'),
              selected: selectedProjectId == 'all',
              onSelected: (_) => onSelected('all'),
            ),
          ),
          ...projects.map(
            (project) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: CircleAvatar(backgroundColor: project.color),
                label: Text(project.name),
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
    required this.onTap,
  });

  final Conversation conversation;
  final ProjectSpace project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                      project.name,
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
                    const Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: Icon(Icons.code, size: 16),
                      label: Text('code'),
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
    required this.onAddTag,
  });

  final Conversation conversation;
  final ProjectSpace project;
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
                Text(widget.project.name),
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
                    decoration: const InputDecoration(
                      hintText: 'Add tag',
                      prefixIcon: Icon(Icons.sell_outlined),
                    ),
                    onSubmitted: widget.onAddTag,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Add tag',
                  onPressed: () => widget.onAddTag(tagController.text),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...widget.conversation.messages.map(
              (message) => _MessageBubble(message: message),
            ),
            if (widget.conversation.codeSnippets.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Extracted code',
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
  const _MessageBubble({required this.message});

  final KnowledgeMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == AiRole.user;
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
              isUser ? 'User' : 'Assistant',
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text('Capture AI chat', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Prompts are saved locally, tagged automatically, and prepared for future OpenAI SDK integration.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        DropdownMenu<String>(
          width: double.infinity,
          initialSelection: projectId,
          label: const Text('Project'),
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
                  label: project.name,
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
          decoration: const InputDecoration(
            alignLabelWithHint: true,
            labelText: 'Prompt or pasted AI conversation',
            hintText: 'Paste a conversation, code snippet, or new AI prompt...',
            prefixIcon: Padding(
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
          label: const Text('Ask and save'),
        ),
        const SizedBox(height: 16),
        Text('Recent captures', style: Theme.of(context).textTheme.titleMedium),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a prompt before saving')),
      );
      return;
    }
    final conversation = widget.repository.createConversation(
      projectId: projectId,
      prompt: prompt,
    );
    promptController.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Saved "${conversation.title}"')));
    setState(() {});
  }
}

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice({required this.settings});

  final SecuritySettings settings;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        settings.maskSensitiveInfo,
        'Sensitive masking',
        Icons.visibility_off_outlined,
      ),
      (settings.localDbEncryption, 'SQLCipher-ready', Icons.storage_outlined),
      (settings.appLockEnabled, 'App lock', Icons.lock_outline),
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
              label: Text('${item.$2}: ${item.$1 ? 'on' : 'off'}'),
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
    final markdown = widget.repository.exportMarkdown(projectId: projectId);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text('Markdown export', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Export conversations with project metadata, tags, turns, and code snippets.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        DropdownMenu<String>(
          width: double.infinity,
          initialSelection: projectId,
          label: const Text('Export scope'),
          leadingIcon: const Icon(Icons.filter_alt_outlined),
          onSelected: (value) {
            if (value != null) {
              setState(() {
                projectId = value;
              });
            }
          },
          dropdownMenuEntries: [
            const DropdownMenuEntry(value: 'all', label: 'All projects'),
            ...widget.repository.projects.map(
              (project) => DropdownMenuEntry<String>(
                value: project.id,
                label: project.name,
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
            ).showSnackBar(const SnackBar(content: Text('Markdown copied')));
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copy Markdown'),
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text('Security', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Local-first controls for API keys, encrypted storage, app lock, and masking.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: apiKeyController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'OpenAI API key',
            hintText: settings.apiKeySaved
                ? 'Key saved in secure storage'
                : 'sk-...',
            prefixIcon: const Icon(Icons.key_outlined),
            suffixIcon: IconButton(
              tooltip: 'Save API key',
              onPressed: () {
                final hasKey = apiKeyController.text.trim().isNotEmpty;
                widget.repository.updateSettings(
                  settings.copyWith(apiKeySaved: hasKey),
                );
                apiKeyController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      hasKey
                          ? 'API key marked for secure storage'
                          : 'Enter a key first',
                    ),
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
          title: 'Mask sensitive information',
          subtitle:
              'Redacts API keys, emails, and card-like numbers on capture.',
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
          title: 'FaceID, fingerprint, or PIN app lock',
          subtitle: 'UI-ready control for platform biometric integration.',
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
          title: 'Encrypted local database',
          subtitle: 'Designed for SQLCipher-backed SQLite storage.',
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
          title: 'E2EE cloud sync',
          subtitle:
              'Roadmap toggle for premium sync without server-readable logs.',
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
                  'Implementation boundary',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Production storage should connect this repository to SQLite tables for conversations, messages, and tags; store provider keys only in Keychain or Keystore; and keep user chat logs off product servers.',
                ),
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
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
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
            Text(
              'No matching knowledge yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Try another search or capture a new AI conversation.',
              textAlign: TextAlign.center,
            ),
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
