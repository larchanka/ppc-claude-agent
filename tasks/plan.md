# Implementation Plan: Dimmed & Compact Tool Call Visual Formatting

## Overview
Improve the interactive visual experience of `code-agent.pl` by replacing raw, noisy JSON tool call output (`[tool_use] name({"key":"value",...})`) with clean, dimmed, single-line summaries (e.g., `read_file   README.md   L10-20`, `write_file   README.md   adjklsadjsakldjskad...`, `run_shell   git status --porcel...`). File paths are stripped to base filenames, command execution strings and payload contents are truncated to 20 characters with ellipses, line ranges are compactly formatted as `L<start>-<end>`, and elements are separated by 3 spaces and styled with dimmed ANSI attributes (`\x1b[2m`).

---

## Architecture Decisions

### 1. Separation of Formatting Logic and ANSI Styling
- **`format_tool_summary($name, $input)`**: Pure string builder that formats tool invocations into clean columns without ANSI escape sequences. This ensures deterministic, effortless unit testing and fallback when colors are disabled.
- **`format_tool_call($name, $input)`**: Decorates `format_tool_summary` with `$COLOR_DIM` and `$COLOR_RESET` when color is enabled (`-t STDOUT` and no `NO_COLOR`).
- Column separation: 3 spaces (`   `) between parts as specified by user requirements.

### 2. Tool-Specific Formatting Specifications
- **`read_file`**:
  - Target: Basename of `path` (e.g. `/foo/bar/README.md` -> `README.md`).
  - Range:
    - Both `start_line` and `end_line` defined: `L<start_line>-<end_line>` (e.g., `L10-20`).
    - Only `start_line` defined: `L<start_line>-`.
    - Only `end_line` defined: `L1-<end_line>`.
    - Neither defined: omitted.
  - Examples: `read_file   README.md   L10-20`, `read_file   README.md`.
- **`write_file`**:
  - Target: Basename of `path`.
  - Content: Flattened into single line (newlines replaced by spaces), whitespace collapsed, and truncated to 20 characters + `...` if length exceeds 20 characters.
  - Example: `write_file   README.md   adjklsadjsakldjskad...`.
- **`edit_file`**:
  - Target: Basename of `path`.
  - Range: `L<start_line>-<end_line>`.
  - Replacement: If present (via `content` or `replacement`), flattened and truncated to 20 characters + `...`.
  - Example: `edit_file   README.md   L10-20   my new content...`.
- **`run_shell`**:
  - Command: Truncated to 20 characters + `...` if length > 20 chars.
  - Example: `run_shell   git status --porcel...` or `run_shell   ls -la`.
- **`list_dir`**:
  - Target: Basename of `path` (or `.` if path is omitted or `.`).
  - Example: `list_dir   src` or `list_dir   .`.
- **Fallback / Generic tool**:
  - Summarize first string parameter or key-value pair, truncated to 20 characters.

### 3. Pure Perl 5.8.6 Compatibility & Path Handling
- Zero CPAN dependencies.
- Avoid modern 5.10+ syntax: do NOT use defined-or `//` or `state`. Use `defined($val) ? $val : $default`.
- Path basename extraction: Use pure regex `sub extract_basename` that strips trailing slashes and extracts trailing filename/directory segment, avoiding platform-specific path separator issues while remaining 100% Tiger compatible.

### 4. ANSI Styling & Theme Safety
- Define `our $COLOR_DIM = "\x1b[2m";` alongside `$COLOR_USER` and `$COLOR_MODEL`.
- Disable `$COLOR_DIM = '';` when `!-t STDOUT || exists $ENV{NO_COLOR}`.
- Wraps formatted tool summary in `${COLOR_DIM}$summary${COLOR_RESET}`.

---

## Task List

### Phase 1: Foundation (Core Formatting & Color Helpers)

## Task 1: Implement String Helpers & ANSI Dim Definition in `code-agent.pl`
**Description:** Define `$COLOR_DIM`, implement `extract_basename($path)`, `truncate_text($str, $max_len)`, `format_tool_summary($name, $input)`, and `format_tool_call($name, $input)` in `code-agent.pl`.

**Acceptance criteria:**
- `our $COLOR_DIM` is initialized to `"\x1b[2m"` and cleared when `!-t STDOUT` or `$ENV{NO_COLOR}` is present.
- `extract_basename` correctly handles absolute paths, relative paths, trailing slashes, and empty/dot paths.
- `truncate_text` collapses whitespace/newlines and trims strings exceeding max length (default 20), appending `...`.
- `format_tool_summary` outputs exact user-specified patterns with 3 spaces between elements.
- `format_tool_call` wraps summary in dimmed ANSI attributes when color is active.
- Perl 5.8.6 syntax check passes (`perl -c code-agent.pl`).

**Verification:**
- `perl -c code-agent.pl`
- Verified in isolated one-liner or test.

**Dependencies:** None
**Files likely touched:** `code-agent.pl`
**Estimated scope:** Small (1 file)

---

### Checkpoint: Foundation
- [ ] `perl -c code-agent.pl` passes cleanly.

---

### Phase 2: Integration

## Task 2: Integrate `format_tool_call` into Conversation Loop
**Description:** In `code-agent.pl`, replace the legacy `print "\n[tool_use] $block->{name}(" . MiniJSON::encode($block->{input}) . ")\n";` with `print "\n" . format_tool_call($block->{name}, $block->{input}) . "\n";`.

**Acceptance criteria:**
- Tool use block rendering displays the formatted dimmed string instead of raw JSON.
- Tool execution logic (`run_tool`) and result handling remain completely intact and unaffected.
- Existing tests in `t/` continue to pass without regression.

**Verification:**
- `prove -I. t/*.t`

**Dependencies:** Task 1
**Files likely touched:** `code-agent.pl`
**Estimated scope:** Small (1 file)

---

### Checkpoint: Integration
- [ ] All existing tests pass (`prove -I. t/*.t`).

---

### Phase 3: Verification & Documentation

## Task 3: Comprehensive Unit Tests in `t/tool_call_visuals.t`
**Description:** Create dedicated test file `t/tool_call_visuals.t` testing all formatting rules, edge cases, truncation boundaries, and ANSI attribute toggling.

**Acceptance criteria:**
- Tests `read_file` without lines, with line range, with only start_line, with only end_line.
- Tests `write_file` with short content, long content (> 20 chars), and multiline content.
- Tests `edit_file` with line range and replacement text.
- Tests `run_shell` with commands <= 20 chars and > 20 chars.
- Tests `list_dir` with paths and root/dot.
- Tests filename extraction on nested paths (`/a/b/c/file.txt`).
- Tests `$COLOR_DIM` presence and `NO_COLOR` bypass.

**Verification:**
- `prove -I. t/tool_call_visuals.t`
- `prove -I. t/*.t`

**Dependencies:** Task 2
**Files likely touched:** `t/tool_call_visuals.t`
**Estimated scope:** Small (1 file)

## Task 4: Context Refresh, Architecture Sync & Persistent Memory Log
**Description:** Update context files, re-run AST and dependency graph generators, verify documentation integrity, and record architectural decisions to persistent memory via `memo-mcp`.

**Acceptance criteria:**
- AST scanner, dependency graph, and symbol graph re-executed without errors.
- `verify_context.py` passes with zero issues.
- `append_memory` called with `[ppc-claude-agent]` decision and tags.

**Verification:**
- `python3 /Users/mikhaillarchanka/.gemini/config/skills/codebase-context-generator/scripts/verify_context.py --root .`

**Dependencies:** Task 3
**Files likely touched:** `context/signatures.md`, `.context_cache/*`
**Estimated scope:** Small

---

### Checkpoint: Complete
- [ ] All tests pass.
- [ ] Context documentation and AST graphs verified.
- [ ] Ready for review and merge.

---

## Risks and Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| Terminal capability on vintage Macs (Tiger/Leopard) handling `\x1b[2m` | Low | Standard ANSI dim `\x1b[2m` is supported by VT100/xterm emulators; `$COLOR_DIM` is disabled automatically when `NO_COLOR` or non-terminal output is detected. |
| Missing properties in tool input hashrefs | Low | Use defensive extraction with `defined` and defaults so undef warnings are never raised. |
