---
name: confirm-large-edits
description: Use before broad refactors, bulk rewrites, many-file edits, generated code changes, or any code change with high blast radius. Inspect first, summarize the plan, list affected areas, and ask the user for confirmation before editing.
---

# Confirm Large Edits

Before large code edits, pause and ask the user to confirm.

Trigger when the change may:

- Edit 5+ files
- Change 200+ lines
- Touch shared architecture, build config, data models, routing, or public APIs
- Affect behavior outside the immediate request

Confirmation message:

```text
이 변경은 범위가 큽니다. 진행 전에 확인할게요.

예상 변경:
- ...

영향 범위:
- ...

이 방향으로 코드 수정을 진행해도 될까요?
```

Skip confirmation only when the user already approved this plan or explicitly asked to proceed without asking.
