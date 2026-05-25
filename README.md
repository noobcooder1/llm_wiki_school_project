# LLM Wiki Mobile

Flutter implementation of the PRD for a local-first app that saves AI conversations as reusable personal knowledge.

## Implemented 첫 번째 개발 단계 Flow

- Project-based conversation library
- Title/body/tag search
- Automatic keyword tags
- Code snippet extraction from fenced or inline code
- Prompt capture with mock AI response
- Sensitive information masking for API keys, emails, and card-like numbers
- Markdown export with project metadata, tags, messages, and code snippets
- Codex Desktop session export to Obsidian Markdown notes
- Security controls for app lock, encrypted local DB readiness, API key storage, and future E2EE sync

## PRD Mapping

- `conversations/messages/tags`: represented by the in-app repository model in `lib/main.dart`
- SQLite and SQLCipher: modeled as the next persistence boundary
- Secure Storage: represented by the API key security flow
- OpenAI SDK: represented by the capture flow, currently using a mock response
- 두 번째 개발 단계 Obsidian Sync and 세 번째 개발 단계 AI Memory Graph: left as roadmap-ready extension points

## Run

```sh
flutter run
```

## Codex to Obsidian Sync

Export recent Codex Desktop sessions into an Obsidian Vault:

```sh
node scripts/codex-to-obsidian.js --once --vault "/Users/a1/Documents/llm wiki for copilot"
```

Keep the notes updated while Codex is running:

```sh
node scripts/codex-to-obsidian.js --watch --vault "/Users/a1/Documents/llm wiki for copilot"
```

See `docs/codex-obsidian-sync.md` for setup details.

## Verify

```sh
flutter analyze
flutter test
```
