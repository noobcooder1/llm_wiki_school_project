#!/usr/bin/env node

const fs = require('fs');
const os = require('os');
const path = require('path');

const DEFAULT_INTERVAL_MS = 3000;

function usage() {
  return [
    'Usage: node scripts/codex-to-obsidian.js [options]',
    '',
    'Options:',
    '  --once              Export once and exit (default)',
    '  --watch             Keep watching Codex session files',
    '  --all               Export every session instead of only recent sessions',
    '  --recent <number>   Number of recent sessions to export (default: 20)',
    '  --vault <path>      Obsidian vault path; output goes to <vault>/Codex Logs',
    '  --output <path>     Exact output folder for Markdown notes',
    '  --flat              Write all notes directly to the output folder',
    '  --codex-home <path> Codex home folder (default: ~/.codex)',
    '  --no-mask           Do not mask common secrets in exported notes',
    '  --help              Show this help',
  ].join('\n');
}

function parseArgs(argv) {
  const args = {
    mode: 'once',
    recent: 20,
    all: false,
    mask: true,
    flat: false,
    vault: process.env.OBSIDIAN_VAULT || '',
    output: process.env.OBSIDIAN_OUTPUT_DIR || '',
    codexHome: process.env.CODEX_HOME || path.join(os.homedir(), '.codex'),
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === '--once') args.mode = 'once';
    else if (arg === '--watch') args.mode = 'watch';
    else if (arg === '--all') args.all = true;
    else if (arg === '--no-mask') args.mask = false;
    else if (arg === '--flat') args.flat = true;
    else if (arg === '--recent') {
      index += 1;
      args.recent = Number.parseInt(argv[index] || '', 10);
    } else if (arg === '--vault') {
      index += 1;
      args.vault = argv[index] || '';
    } else if (arg === '--output') {
      index += 1;
      args.output = argv[index] || '';
    } else if (arg === '--codex-home') {
      index += 1;
      args.codexHome = argv[index] || '';
    } else if (arg === '--help' || arg === '-h') {
      console.log(usage());
      process.exit(0);
    } else {
      throw new Error(`Unknown option: ${arg}`);
    }
  }

  if (!Number.isFinite(args.recent) || args.recent < 1) {
    throw new Error('--recent must be a positive number');
  }

  args.codexHome = expandHome(args.codexHome);
  args.vault = args.vault ? expandHome(args.vault) : '';
  args.output = args.output ? expandHome(args.output) : '';
  return args;
}

function expandHome(value) {
  if (!value) return value;
  if (value === '~') return os.homedir();
  if (value.startsWith('~/')) return path.join(os.homedir(), value.slice(2));
  return value;
}

function readJsonl(filePath) {
  if (!fs.existsSync(filePath)) return [];
  return fs
    .readFileSync(filePath, 'utf8')
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => {
      try {
        return JSON.parse(line);
      } catch {
        return null;
      }
    })
    .filter(Boolean);
}

function loadThreadNames(codexHome) {
  const indexPath = path.join(codexHome, 'session_index.jsonl');
  const names = new Map();
  for (const record of readJsonl(indexPath)) {
    if (record.id && record.thread_name) {
      names.set(record.id, record.thread_name);
    }
  }
  return names;
}

function detectObsidianVault() {
  const configPath = path.join(
    os.homedir(),
    'Library',
    'Application Support',
    'obsidian',
    'obsidian.json',
  );
  if (!fs.existsSync(configPath)) return '';

  try {
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    const vaults = Object.values(config.vaults || {}).filter((vault) => {
      return vault && vault.path && fs.existsSync(vault.path);
    });
    if (vaults.length === 0) return '';

    const openVaults = vaults.filter((vault) => vault.open);
    const candidates = openVaults.length > 0 ? openVaults : vaults;
    candidates.sort((a, b) => (b.ts || 0) - (a.ts || 0));

    const llmVault = candidates.find((vault) => /llm|wiki/i.test(vault.path));
    return (llmVault || candidates[0]).path;
  } catch {
    return '';
  }
}

function resolveOutputDir(args) {
  if (args.output) return args.output;
  const vault = args.vault || detectObsidianVault();
  if (!vault) {
    throw new Error(
      'No Obsidian vault detected. Pass --vault "/path/to/vault" or --output "/path/to/folder".',
    );
  }
  return path.join(vault, 'Codex Logs');
}

function findSessionFiles(codexHome) {
  const sessionsDir = path.join(codexHome, 'sessions');
  const files = [];
  walk(sessionsDir, files);
  return files
    .filter((filePath) => path.basename(filePath).startsWith('rollout-'))
    .filter((filePath) => filePath.endsWith('.jsonl'))
    .map((filePath) => ({
      filePath,
      mtimeMs: fs.statSync(filePath).mtimeMs,
    }))
    .sort((a, b) => b.mtimeMs - a.mtimeMs);
}

function walk(dir, files) {
  if (!fs.existsSync(dir)) return;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const entryPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(entryPath, files);
    } else if (entry.isFile()) {
      files.push(entryPath);
    }
  }
}

function parseSession(filePath, threadNames, mask) {
  const records = readJsonl(filePath);
  const meta = records.find((record) => record.type === 'session_meta') || {};
  const payload = meta.payload || {};
  const threadId = payload.id || threadIdFromFile(filePath);
  const title = threadNames.get(threadId) || titleFromFile(filePath);
  const createdAt = payload.timestamp || firstTimestamp(records);
  const updatedAt = lastTimestamp(records);
  const cwd = payload.cwd || '';
  const originator = payload.originator || '';
  const turns = extractTurns(records, mask);

  return {
    threadId,
    title,
    createdAt,
    updatedAt,
    cwd,
    originator,
    sourcePath: filePath,
    turns,
  };
}

function extractTurns(records, mask) {
  const turns = [];
  const seen = new Set();

  for (const record of records) {
    const payload = record.payload || {};
    let role = '';
    let text = '';

    if (record.type === 'event_msg' && payload.type === 'user_message') {
      role = 'User';
      text = payload.message || '';
    } else if (record.type === 'event_msg' && payload.type === 'agent_message') {
      role = 'Assistant';
      text = payload.message || '';
    } else if (record.type === 'response_item' && payload.type === 'message') {
      if (payload.role === 'user') role = 'User';
      if (payload.role === 'assistant') role = 'Assistant';
      text = contentToText(payload.content);
    }

    text = normalizeText(text);
    if (!role || !text || isNoiseMessage(text)) continue;

    const safeText = mask ? maskSensitive(text) : text;
    const key = `${role}\n${safeText}`;
    if (seen.has(key)) continue;
    seen.add(key);
    turns.push({ role, text: safeText, timestamp: record.timestamp || '' });
  }

  return turns;
}

function contentToText(content) {
  if (typeof content === 'string') return content;
  if (!Array.isArray(content)) return '';
  return content
    .map((item) => {
      if (!item) return '';
      if (typeof item.text === 'string') return item.text;
      if (typeof item.content === 'string') return item.content;
      return '';
    })
    .filter(Boolean)
    .join('\n\n');
}

function normalizeText(text) {
  return String(text || '')
    .replace(/\r\n/g, '\n')
    .trim();
}

function isNoiseMessage(text) {
  return (
    text.startsWith('<environment_context>') ||
    text.startsWith('<permissions instructions>') ||
    text.startsWith('# Collaboration Mode:')
  );
}

function maskSensitive(text) {
  return text
    .replace(/sk-[A-Za-z0-9_-]{12,}/g, '[masked-api-key]')
    .replace(
      /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g,
      '[masked-email]',
    )
    .replace(/\b(?:\d[ -]*?){13,16}\b/g, '[masked-number]');
}

function threadIdFromFile(filePath) {
  const match = path.basename(filePath).match(
    /([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\.jsonl$/i,
  );
  return match ? match[1] : path.basename(filePath, '.jsonl');
}

function titleFromFile(filePath) {
  return path.basename(filePath, '.jsonl').replace(/^rollout-/, 'Codex Session ');
}

function firstTimestamp(records) {
  const record = records.find((item) => item.timestamp);
  return record ? record.timestamp : new Date().toISOString();
}

function lastTimestamp(records) {
  for (let index = records.length - 1; index >= 0; index -= 1) {
    if (records[index].timestamp) return records[index].timestamp;
  }
  return new Date().toISOString();
}

function renderMarkdown(session) {
  const tags = ['codex', 'ai-log', 'obsidian', 'llm-wiki'];
  const createdDate = toDatePart(session.createdAt);
  const project = projectNameFromSession(session);
  const lines = [
    '---',
    `title: ${yamlQuote(session.title)}`,
    `created: ${session.createdAt || ''}`,
    `updated: ${session.updatedAt || ''}`,
    `source: ${yamlQuote(session.originator || 'Codex')}`,
    `thread_id: ${yamlQuote(session.threadId)}`,
    `project: ${yamlQuote(project)}`,
    'tags:',
    ...tags.map((tag) => `  - ${tag}`),
    '---',
    '',
    `# ${session.title}`,
    '',
    '## Metadata',
    '',
    `- Date: ${createdDate}`,
    `- Project: ${project}`,
    `- Thread ID: ${session.threadId}`,
    session.cwd ? `- Workspace: ${session.cwd}` : '',
    `- Source file: ${session.sourcePath}`,
    '',
    '## Summary',
    '',
    '- Codex session transcript exported automatically for later review.',
    '- Add a human summary here after the session if this note becomes durable knowledge.',
    '',
    '## Conversation',
    '',
  ].filter((line) => line !== '');

  for (const turn of session.turns) {
    lines.push(`### ${turn.role}`);
    lines.push('');
    if (turn.timestamp) lines.push(`_Time: ${turn.timestamp}_`);
    if (turn.timestamp) lines.push('');
    lines.push(turn.text);
    lines.push('');
  }

  if (session.turns.length === 0) {
    lines.push('_No user or assistant messages were found in this session yet._');
    lines.push('');
  }

  return `${lines.join('\n').trim()}\n`;
}

function yamlQuote(value) {
  return JSON.stringify(String(value || ''));
}

function toDatePart(value) {
  if (!value) return new Date().toISOString().slice(0, 10);
  return String(value).slice(0, 10);
}

function outputFileName(session) {
  const date = toDatePart(session.createdAt);
  const slug = slugify(session.title || session.threadId);
  return `${date}-${slug}-${session.threadId.slice(0, 8)}.md`;
}

function outputSubdirName(session) {
  return slugify(projectNameFromSession(session));
}

function projectNameFromSession(session) {
  if (session.cwd) {
    const cwd = path.resolve(session.cwd);
    const baseName = path.basename(cwd);
    const parentName = path.basename(path.dirname(cwd));

    if (parentName && /^\d{4}-\d{2}-\d{2}$/.test(parentName)) {
      return baseName || parentName;
    }

    if (baseName && baseName !== path.parse(cwd).root) return baseName;
  }

  return 'Unsorted';
}

function slugify(value) {
  const cleaned = String(value || 'codex-session')
    .normalize('NFC')
    .replace(/[\\/:*?"<>|#\[\]]/g, ' ')
    .replace(/\s+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 72);
  return cleaned || 'codex-session';
}

function exportSessions(args) {
  const outputDir = resolveOutputDir(args);
  fs.mkdirSync(outputDir, { recursive: true });

  const threadNames = loadThreadNames(args.codexHome);
  const files = findSessionFiles(args.codexHome);
  const selected = args.all ? files : files.slice(0, args.recent);
  const written = [];

  for (const entry of selected) {
    const session = parseSession(entry.filePath, threadNames, args.mask);
    const markdown = renderMarkdown(session);
    const sessionOutputDir = args.flat
      ? outputDir
      : path.join(outputDir, outputSubdirName(session));
    fs.mkdirSync(sessionOutputDir, { recursive: true });
    const outputPath = path.join(sessionOutputDir, outputFileName(session));
    fs.writeFileSync(outputPath, markdown, 'utf8');
    written.push(outputPath);
  }

  return { outputDir, written, scanned: files.length };
}

function watch(args) {
  let lastSignature = '';

  const tick = () => {
    const files = findSessionFiles(args.codexHome);
    const selected = args.all ? files : files.slice(0, args.recent);
    const signature = selected
      .map((entry) => `${entry.filePath}:${entry.mtimeMs}`)
      .join('|');

    if (signature !== lastSignature) {
      const result = exportSessions(args);
      console.log(
        `[${new Date().toISOString()}] exported ${result.written.length} session note(s) to ${result.outputDir}`,
      );
      lastSignature = signature;
    }
  };

  tick();
  setInterval(tick, DEFAULT_INTERVAL_MS);
}

function main() {
  try {
    const args = parseArgs(process.argv.slice(2));
    if (args.mode === 'watch') {
      watch(args);
      return;
    }

    const result = exportSessions(args);
    console.log(`Scanned ${result.scanned} Codex session file(s).`);
    console.log(`Wrote ${result.written.length} Markdown note(s) to ${result.outputDir}`);
    for (const outputPath of result.written) {
      console.log(`- ${outputPath}`);
    }
  } catch (error) {
    console.error(error.message);
    console.error('');
    console.error(usage());
    process.exit(1);
  }
}

main();
