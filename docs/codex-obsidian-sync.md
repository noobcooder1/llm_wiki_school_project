# Codex to Obsidian Auto Save

이 프로젝트는 Codex 앱의 로컬 세션 기록을 Obsidian Vault 안의 Markdown 노트로 변환하는 자동 저장 스크립트를 포함한다.

## 현재 환경에서 확인한 구조

Codex Desktop은 현재 다음 위치에 세션 원문을 저장한다.

```text
~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl
```

스레드 이름은 다음 인덱스에서 읽는다.

```text
~/.codex/session_index.jsonl
```

따라서 `history.jsonl` 하나만 감시하는 예시보다, `sessions` 폴더의 `rollout-*.jsonl` 파일을 스레드별로 Markdown 변환하는 방식이 더 정확하다.

## 한 번 내보내기

Obsidian 설정에서 열린 Vault를 자동 감지해서 `<Vault>/Codex Logs/<Project>/`에 최근 20개 세션을 저장한다.

```sh
node scripts/codex-to-obsidian.js --once
```

특정 Vault를 지정하려면:

```sh
node scripts/codex-to-obsidian.js --once --vault "/Users/a1/Documents/llm wiki for copilot"
```

정확한 출력 루트 폴더를 지정하려면:

```sh
node scripts/codex-to-obsidian.js --once --output "/Users/a1/Documents/llm wiki for copilot/Codex Logs"
```

프로젝트 폴더를 만들지 않고 예전처럼 출력 폴더 바로 아래에 모두 저장하려면 `--flat`을 붙인다.

## 자동 감시

Codex 대화가 이어질 때마다 3초 간격으로 최근 세션 Markdown 파일을 다시 생성한다.

```sh
node scripts/codex-to-obsidian.js --watch --vault "/Users/a1/Documents/llm wiki for copilot"
```

모든 세션을 내보내려면:

```sh
node scripts/codex-to-obsidian.js --once --all --vault "/Users/a1/Documents/llm wiki for copilot"
```

## Obsidian 노트 형식

각 세션은 하나의 Markdown 파일로 저장된다. 기본 구조는 Codex 세션의 `cwd`에서 프로젝트명을 읽어 다음처럼 나눈다.

```text
Codex Logs/
  llm-wiki-codex-logs/
    2026-06-10-프로젝트별-채팅로그-분리-저장-019eaf8b.md
  llm_wiki_school_project/
    2026-05-19-코덱스-옵시디언-자동저장-추가-019e3ec6.md
  Unsorted/
    2026-05-06-Codex-Session-...md
```

노트에는 YAML Frontmatter, 프로젝트명, 세션 메타데이터, 대화 기록이 포함된다.

기본적으로 API 키, 이메일, 카드처럼 보이는 숫자는 마스킹한다. 원문 그대로 저장해야 할 때만 `--no-mask` 옵션을 사용한다.

## macOS 시작 프로그램으로 등록하기

완전 자동화를 원하면 위 `--watch` 명령을 macOS LaunchAgent에 등록하면 된다. 이 단계는 `~/Library/LaunchAgents`에 파일을 써야 하므로 Codex 샌드박스 밖 쓰기 권한이 필요하다.

권장 명령:

```sh
scripts/install-codex-obsidian-launch-agent.sh --vault "/Users/a1/Documents/llm wiki for copilot"
```

등록 후 로그는 다음 파일에서 확인할 수 있다.

```text
~/Library/Logs/com.llmwiki.codex-obsidian-sync.out.log
~/Library/Logs/com.llmwiki.codex-obsidian-sync.err.log
```

## 주의점

- Codex 앱의 내부 기록 포맷은 앱 버전에 따라 바뀔 수 있다.
- 세션 파일에는 대화 원문이 포함되므로 Vault 동기화 서비스를 쓴다면 개인정보 저장 범위를 확인해야 한다.
- 현재 스크립트는 요약을 자동 생성하지 않고, 원문 대화를 Markdown으로 정리한다. 요약은 나중에 별도 AI 정리 단계로 붙이는 것이 안전하다.
