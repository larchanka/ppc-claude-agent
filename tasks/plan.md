# Implementation Plan: Line-Based File Tools Extension (`read_file` & `edit_file`)

## Overview
Extend the agent's file manipulation toolset in `code-agent.pl` to support targeted line-level operations without requiring external dependencies or modern Perl versions:
1. Extend `read_file` to accept optional `start_line` and `end_line` parameters (1-based, inclusive), returning only the lines in the specified range while preserving full-file reading when omitted.
2. Implement a new `edit_file` tool that replaces a specified range of lines (`start_line` to `end_line`) with new content (or deletes lines when content is empty), complete with interactive user confirmation via `confirm_tool(...)` and bounds validation.
3. Update the system prompt to instruct language models on how and when to use line-level reading and editing.

---

## Architecture Decisions

### 1. 1-Based Inclusive Line Indexing
- In line with text editors, Unix conventions (`sed`, `ed`), and LLM tool patterns (Aider, Claude Code, Cursor), lines are 1-based and inclusive.
- For a file with $N$ lines, valid line ranges are $1 \le \text{start\_line} \le \text{end\_line} \le N$.
- **Insertion without deletion**: When $\text{end\_line} = \text{start\_line} - 1$, the length of replaced lines is zero, allowing content insertion before $\text{start\_line}$ (e.g. `start_line: 1, end_line: 0` prepends at the top; `start_line: N + 1, end_line: N` appends at EOF).
- **Deletion**: When `content` is empty string `""`, lines $\text{start\_line}$ through $\text{end\_line}$ are excised.

### 2. Backward Compatibility & Clamping Semantics for `read_file`
- If neither `start_line` nor `end_line` is specified: reads and returns the entire file content (existing behavior).
- If only `start_line` is specified: reads from `start_line` to EOF.
- If only `end_line` is specified: reads from line 1 to `end_line`.
- Clamping:
  - `start_line < 1` clamps to 1.
  - `end_line > total_lines` clamps to `total_lines`.
  - `start_line > total_lines`: returns empty string `""`.
  - `start_line > end_line` (when both provided): returns error message `"Error: start_line ($start_line) cannot be greater than end_line ($end_line)"`.
- Preserves raw byte/UTF-8 decoding without modifying original line breaks.

### 3. Splicing Engine & Normalization for `edit_file`
- Uses Perl's native `splice(@lines, $offset, $length, $content)`:
  - `$offset = $start_line - 1`
  - `$length = $end_line >= $start_line ? ($end_line - $start_line + 1) : 0`
- Normalization: if `$content ne '' && $content !~ /\n\z/`, automatically append `"\n"` to prevent subsequent lines from being accidentally merged onto the same line.
- Content synonym tolerance: accepts `$input->{content}` or `$input->{replacement}`.
- Bounds validation:
  - Returns error if `start_line > total_lines + 1`.
  - Returns error if `end_line < start_line - 1`.
  - Clamps `end_line = total_lines` if `end_line > total_lines`.

### 4. Safety & Confirmation via `confirm_tool`
- In accordance with project rule 5 ("Preserve User Confirmations on Side Effects"), `edit_file` modifies the filesystem and must prompt the user:
  ```perl
  unless (confirm_tool("Edit file '$path' (lines $start_line-$end_line)?")) {
      return "Cancelled by user.";
  }
  ```
- Works seamlessly with both default manual mode (prompts `[y/N]`) and autonomous mode (`$AUTO_MODE = 1`).

### 5. Multi-Provider Compatibility & Perl 5.8.6 Constraints
- `@TOOLS` schema definitions automatically translate to Anthropic JSON schema, Gemini `functionDeclarations`, and OpenAI function tools via existing adapters.
- Pure Perl 5.8.6: standard `open`, array slicing, `splice`, no CPAN modules, no `//` operator (use ternary `defined(...) ? ... : ...`).

---

## Task List

### Phase 1: Tool Implementations (Foundation)

## Task 1: Extend `read_file` Tool with Line Range Slicing
**Description:** Update `read_file` schema in `@TOOLS` to add optional `start_line` and `end_line` integer parameters, and update `run_tool('read_file', ...)` in `code-agent.pl` to implement range slicing, bounds clamping, and error validation.

**Acceptance criteria:**
- [x] `@TOOLS` definition for `read_file` documents optional `start_line` and `end_line` properties.
- [x] If neither `start_line` nor `end_line` is provided, returns the entire file.
- [x] If `start_line` and/or `end_line` are specified, returns only lines in `[start_line, end_line]`.
- [x] Clamps `start_line < 1` to 1, clamps `end_line > total` to `total`, and returns empty string if `start_line > total`.
- [x] Returns error if `start_line > end_line`.
- [x] Non-existent file returns `"Error: cannot open $path: $!"`.

**Verification:**
- [x] `perl -c code-agent.pl` passes syntax verification.

**Dependencies:** None

**Files likely touched:**
- `code-agent.pl`

**Estimated scope:** Small (1 file)

---

## Task 2: Implement `edit_file` Tool in `@TOOLS` and `run_tool`
**Description:** Add `edit_file` tool definition to `@TOOLS` and implement line replacement logic in `run_tool('edit_file', ...)` with validation, confirmation, and file rewriting.

**Acceptance criteria:**
- [x] `@TOOLS` registers `edit_file` with `path`, `start_line`, `end_line`, and `content` properties.
- [x] Validates line range (`start_line <= total + 1`, `end_line >= start_line - 1`).
- [x] Calls `confirm_tool("Edit file '$path' (lines $start_line-$end_line)?")` and aborts if rejected.
- [x] Correctly replaces target lines, inserts lines without deletion, deletes lines when `content` is `""`, and appends trailing `\n` to non-empty replacement if missing.
- [x] Writes file in UTF-8 encoding and returns success confirmation string.
- [x] Returns descriptive error if file does not exist or line numbers are out of valid range.

**Verification:**
- [x] `perl -c code-agent.pl` passes syntax verification.

**Dependencies:** Task 1

**Files likely touched:**
- `code-agent.pl`

**Estimated scope:** Small (1 file)

---

### Checkpoint: Foundation
- [x] `perl -c code-agent.pl` passes.
- [x] Existing test suite (`prove -v t/*.t`) continues to pass with zero regressions.

---

### Phase 2: System Prompt & Provider Integration

## Task 3: Update System Prompt and Tool Descriptions
**Description:** Update `$SYSTEM_PROMPT` in `code-agent.pl` to inform models of the five available tools (`read_file`, `write_file`, `edit_file`, `list_dir`, `run_shell`) and clarify line-based reading and editing best practices.

**Acceptance criteria:**
- [x] `$SYSTEM_PROMPT` reflects five available tools including `edit_file`.
- [x] Explains when to prefer `edit_file` (targeted updates) versus `write_file` (full file creation/overwrites).
- [x] Explains `read_file` optional line slicing for inspecting specific sections of large files.

**Verification:**
- [x] `perl -c code-agent.pl` passes syntax verification.

**Dependencies:** Task 2

**Files likely touched:**
- `code-agent.pl`

**Estimated scope:** Extra Small (1 file)

---

### Phase 3: Verification & Context Maintenance

## Task 4: Unit Test Suite for `read_file` and `edit_file`
**Description:** Create dedicated test file `t/tool_read_edit_file.t` covering line range reading, line editing, deletions, insertions, confirmations, auto-mode bypass, and error cases.

**Acceptance criteria:**
- [x] Tests full and partial line reads with `read_file`.
- [x] Tests out-of-bounds, clampings, and inverted line range errors for `read_file`.
- [x] Tests single-line, multi-line, deletion, and insertion edits with `edit_file`.
- [x] Tests `confirm_tool` interactive prompt and rejection in manual mode.
- [x] Tests `confirm_tool` immediate bypass in auto mode.
- [x] Tests error handling for non-existent files and invalid line ranges.
- [x] Full test suite (`prove -v t/*.t`) passes with 100% success.

**Verification:**
- [x] `prove -v t/tool_read_edit_file.t` passes.
- [x] `prove -v t/*.t` passes.

**Dependencies:** Tasks 1-3

**Files likely touched:**
- `t/tool_read_edit_file.t`

**Estimated scope:** Small (1 file)

---

## Task 5: Context & Symbol Graph Refresh
**Description:** Update architectural documentation (`AGENTS.md`, `context/architecture.md`, `context/modules.md`, `context/conventions.md`) and regenerate symbol and dependency graphs.

**Acceptance criteria:**
- [x] `context/architecture.md` and `context/modules.md` document `edit_file` and `read_file` line range support.
- [x] `context/conventions.md` documents `confirm_tool` check on `edit_file`.
- [x] AST scanner, dependency graph, and symbol graph scripts run successfully.
- [x] `verify_context.py` passes with zero integrity errors.

**Verification:**
- [x] `python3 /Users/mikhaillarchanka/.gemini/config/skills/codebase-context-generator/scripts/verify_context.py --root .` passes.

**Dependencies:** Tasks 1-4

**Files likely touched:**
- `AGENTS.md`
- `context/architecture.md`
- `context/modules.md`
- `context/conventions.md`
- `context/signatures.md`
- `.context_cache/`

**Estimated scope:** Medium (3-5 files)

---

### Phase 4: Code Clean-Up

## Task 6: Comments Clean-Up in `code-agent.pl`
**Description:** Clean up redundant narrative/boilerplate comments in `code-agent.pl`, preserving essential Perl 5.8.6 Tiger OS compatibility and safety invariants.

**Acceptance criteria:**
- [x] Redundant narrative and repetitive boilerplate comments removed from `code-agent.pl`.
- [x] Essential documentation of Perl 5.8.6 Tiger OS constraints, raw STDIN handling, security/confirmation invariants, and subtle algorithm details preserved.
- [x] `perl -c code-agent.pl` passes syntax verification.
- [x] Full test suite (`prove -v t/*.t`) continues to pass with zero regressions.

**Verification:**
- [x] `perl -c code-agent.pl` passes.
- [x] `prove -v t/*.t` passes.

**Dependencies:** Tasks 1-5

**Files likely touched:**
- `code-agent.pl`

**Estimated scope:** Small (1 file)

---

### Checkpoint: Complete
- [x] All acceptance criteria met across all 5 tasks.
- [x] Zero CPAN dependencies maintained; Perl 5.8.6 syntax compliance verified.
- [x] 100% test pass rate across all unit test files.
- [x] Codebase context and symbol graphs fully synchronized.

---

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Index off-by-one errors in line replacement or slicing | High | Strict 1-based indexing in schemas, mapped to 0-based array offsets (`$start_line - 1`); comprehensive unit tests for single-line, multi-line, prepending, appending, and deletion edge cases. |
| Corrupting files without trailing newlines | Med | Automatically ensure trailing `\n` on non-empty replacement content; test newline termination explicitly. |
| Unintended overwrites without user confirmation | High | `edit_file` calls `confirm_tool(...)` before any disk write; tested in both manual (confirmation required) and auto modes. |
| Incompatibility with Gemini/OpenAI tool formats | Med | Schema conforms strictly to standard JSON Schema subset handled by existing `build_request_gemini` and `build_request_openai` converters. |

---

## Open Questions
- None. Requirements are clear, standard, and fully specified.
