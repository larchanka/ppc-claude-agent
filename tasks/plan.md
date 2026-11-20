# Implementation Plan: Modular Assembly of code-agent.pl

## Overview
Decompose the monolithic `code-agent.pl` (~2,640 lines) into clean, focused source files in `src/*.pl` using Option 2 (Modular Assembly). A pure Perl 5.8.6 build script `build.pl` will concatenate the modules in an explicit manifest order, verify syntax via `perl -c`, set executable permissions, and output the standalone `code-agent.pl` artifact. The assembled `code-agent.pl` will remain committed in git for zero-dependency distribution. The `Install.command` script will automatically invoke `build.pl` when present, ensuring 100% backward compatibility with vintage Mac OS X 10.4 Tiger runtimes, existing installation workflows, and unit test suites (`prove -v t/*.t`).

---

## Architecture Decisions

### 1. Modular Assembly Pattern (Option 2)
- **Source Directory (`src/*.pl`)**: Contains the modular, readable source files organized by functional domain. Developers work directly in `src/`.
- **Distribution Artifact (`code-agent.pl`)**: Standalone, single-file distribution script assembled by concatenating `src/*.pl`. It remains checked into git so users without build tooling can run or install immediately.
- **Zero CPAN Build Tool (`build.pl`)**: Pure Perl 5.8.6 script with zero non-core dependencies that builds `code-agent.pl`, sets executable permissions (`chmod 0755`), and runs syntax verification (`$^X -c code-agent.pl`).
- **Test Integrity**: All existing test scripts (`t/*.t`) require `code-agent.pl`. Because the assembled file preserves the exact subroutines and semantics, existing tests pass with zero regressions.

### 2. Module Decomposition Breakdown (10 Modules)
The modules and assembly sequence:
1. `src/header.pl`: Shebang (`#!/usr/bin/perl`), pragmas (`use strict; use warnings; use utf8; use Encode; use POSIX;`), I/O binmode, global config (`$CURL`, `$CACERT`, `$MAX_TOKENS`), theme colors (`$COLOR_*`), cursor helpers (`cursor_hide`, `cursor_show`), environment helpers (`get_env_file_path`, `load_env_file`), runtime globals (`$PROVIDER`, `$API_KEY`, `$MODEL`, `$API_URL`, `$ANTHROPIC_VERSION`, `$AUTO_MODE`, `$CURRENT_SESSION`, `$SESSION_COUNTER`, `$LAST_API_ELAPSED`), provider configuration (`configure_provider`), and system prompt constant (`$SYSTEM_PROMPT`).
2. `src/json.pl`: Pure Perl recursive descent JSON parser and encoder (`package MiniJSON;`), resetting back to `package main;` at the end of the file.
3. `src/transport.pl`: Toolchain curl invocation (`call_api`) with config file creation, live timer child process fork for TTY, synchronous fallback, and UTF-8 response decoding; plus `quote()` shell-escaping helper.
4. `src/providers.pl`: Provider-specific header and request builders (`build_headers`, `build_request`, `build_request_anthropic`, `build_request_gemini`, `_gemini_thinking_config`, `build_request_openai`), response parsers (`parse_response`, `parse_response_openai`, `parse_response_anthropic`, `parse_response_gemini`, `has_thinking_block`), and model discovery (`fetch_models`, `_fetch_models_anthropic`, `_fetch_models_gemini`, `_fetch_models_openai`).
5. `src/models_menu.pl`: Interactive curses-like terminal model selection menu with arrow keys, non-TTY fallback, and raw mode handling (`_normalize_models`, `_select_model_nontty`, `_read_menu_key`, `_render_menu_lines`, `select_model_interactive`, `our $FORCE_RAW`).
6. `src/session.pl`: Session accessors and slash command handlers (`get_current_model`, `get_current_provider`, `get_current_api_url`, `get_auto_mode`, `set_auto_mode`, `generate_session_id`, `init_session`, `get_current_session`, `archive_session`, `handle_new_command`, `show_help`, `handle_auto_command`, `handle_manual_command`, `handle_models_command`).
7. `src/tools.pl`: Tool definitions (`our @TOOLS`), user confirmation utilities (`confirm`, `confirm_tool`, `slow_print`), Gemini API key interactive onboarding (`gemini_key_setup`, `_validate_gemini_key`, `_maybe_save_gemini_key`, `read_secret_or_cancel`), and the tool execution dispatcher (`run_tool`).
8. `src/terminal.pl`: Pure-Perl interactive readline implementation with history and ANSI cursor positioning (`{ my @HISTORY; ... }`, `_debug_log`, `_utf8_char_len`, `_char_width`, `_display_width_chars`, `_display_width`, `_term_size`, `_query_cursor_row`, `_query_cursor_pos`, `_probe_terminal_size`, `_walk_position`, `read_line_interactive`).
9. `src/ui.pl`: Visual formatting helpers: `extract_basename`, `truncate_text`, `_format_line_range`, `format_tool_summary`, `format_tool_call`, `format_thinking_status`, `finalize_thinking_line`, `clear_thinking_line`.
10. `src/main.pl`: Guarded entrypoint under `unless (caller)`: loads environment, configures provider with Gemini onboarding fallback, prints welcome banner, runs interactive REPL loop, handles slash commands, dispatches model queries and tool executions, prints exit message, and ends with `1;`.

### 3. Build Script Design (`build.pl`)
- Written in pure Perl 5.8.6 using standard core modules (`File::Spec`, `File::Basename`).
- Explicit ordered manifest array `@MODULES`.
- Atomic generation: concatenates modules into a temporary file or buffer, writes to `code-agent.pl`, sets `chmod 0755`, and validates syntax via `system($^X, '-c', $target)`.
- Delimits module boundaries with readable comments (e.g. `# --- BEGIN src/transport.pl ---`) while keeping `#!/usr/bin/perl` on line 1.
- Provides `--check` flag to verify that `code-agent.pl` matches the output of `src/*.pl`.

### 4. Installer Integration (`Install.command`)
- Check if `build.pl` exists and `src/` directory exists.
- If present, run `perl build.pl` before installing `code-agent.pl` to `$BUILD_DIR/code-agent.pl`.
- If absent, proceed with the existing committed `code-agent.pl`.

---

## Task List

### Phase 1: Build Tooling & Harness

## Task 1: Create `build.pl` Build Script
**Description:** Implement `build.pl` in pure Perl 5.8.6. The script reads modules listed in a manifest from `src/`, concatenates them, writes `code-agent.pl`, applies `chmod 0755`, and runs a syntax check via `perl -c`.

**Acceptance criteria:**
- [ ] Uses only core Perl 5.8.6 modules (no CPAN dependencies).
- [ ] Defines ordered manifest: `header.pl`, `json.pl`, `transport.pl`, `providers.pl`, `models_menu.pl`, `session.pl`, `tools.pl`, `terminal.pl`, `ui.pl`, `main.pl`.
- [ ] Strips duplicate shebangs so only `header.pl` provides `#!/usr/bin/perl` on line 1.
- [ ] Verifies output file with `system($^X, '-c', $output_file) == 0`.
- [ ] Exits with code 0 on success, non-zero on error with a descriptive error message.

**Verification:**
- [ ] Run syntax check: `perl -c build.pl`

**Dependencies:** None

**Files likely touched:**
- `build.pl`

**Estimated scope:** Small (1 file)

---

## Task 2: Create Build Script Unit Test `t/build.t`
**Description:** Add a test file `t/build.t` that tests `build.pl` execution, verification mode, output file permissions, and syntax validation.

**Acceptance criteria:**
- [ ] Tests execution of `build.pl` via `$^X build.pl`.
- [ ] Asserts `code-agent.pl` exists and is executable (`-x`).
- [ ] Asserts `perl -c code-agent.pl` passes cleanly.
- [ ] Asserts failure behavior when a source file is missing or contains invalid syntax.

**Verification:**
- [ ] Run `prove -v t/build.t`

**Dependencies:** Task 1

**Files likely touched:**
- `t/build.t`

**Estimated scope:** Small (1 file)

---

### Checkpoint: Foundation
- [ ] `build.pl` compiles and runs cleanly.
- [ ] `t/build.t` scaffold passes.

---

### Phase 2: Source File Decomposition (`src/*.pl`)

## Task 3: Extract `src/header.pl`, `src/json.pl`, and `src/transport.pl`
**Description:** Create `src/` directory and extract the initial foundation files: header/config/globals (`src/header.pl`), pure-Perl JSON parser/encoder (`src/json.pl`), and curl transport layer (`src/transport.pl`).

**Acceptance criteria:**
- [ ] `src/header.pl` contains shebang, pragmas, UTF-8 binmode, constants, ANSI colors, cursor utilities, env helpers, globals, `configure_provider`, and `$SYSTEM_PROMPT`.
- [ ] `src/json.pl` contains `package MiniJSON;` parser and encoder functions, ending with `package main;`.
- [ ] `src/transport.pl` contains `call_api` (with curl config, timer fork, sync fallback) and `quote`.

**Verification:**
- [ ] Verify each file syntax or partial concatenation syntax.

**Dependencies:** Task 1

**Files likely touched:**
- `src/header.pl`
- `src/json.pl`
- `src/transport.pl`

**Estimated scope:** Medium (3 files)

---

## Task 4: Extract `src/providers.pl` and `src/models_menu.pl`
**Description:** Extract API adapters and interactive model selection: request builders, response parsers, model discovery (`src/providers.pl`), and the curses-like terminal model menu (`src/models_menu.pl`).

**Acceptance criteria:**
- [ ] `src/providers.pl` contains all provider request/response routines for Anthropic, Gemini, OpenAI, plus `fetch_models` and subroutines.
- [ ] `src/models_menu.pl` contains `_normalize_models`, `_select_model_nontty`, `_read_menu_key`, `_render_menu_lines`, `select_model_interactive`, and `our $FORCE_RAW`.

**Verification:**
- [ ] Files created cleanly with exact code from `code-agent.pl`.

**Dependencies:** Task 3

**Files likely touched:**
- `src/providers.pl`
- `src/models_menu.pl`

**Estimated scope:** Small (2 files)

---

## Task 5: Extract `src/session.pl` and `src/tools.pl`
**Description:** Extract session state management and tool execution: session IDs, history archiving, slash commands (`src/session.pl`), and tool definitions (`@TOOLS`), confirmation helpers, Gemini setup helpers, and `run_tool` dispatcher (`src/tools.pl`).

**Acceptance criteria:**
- [ ] `src/session.pl` contains `get_current_model`, `get_auto_mode`, `set_auto_mode`, `generate_session_id`, `init_session`, `get_current_session`, `archive_session`, and slash command handlers (`/new`, `/help`, `/auto`, `/manual`, `/models`).
- [ ] `src/tools.pl` contains `@TOOLS`, `confirm`, `confirm_tool`, `slow_print`, Gemini setup/validation helpers, and `run_tool` (`read_file`, `write_file`, `edit_file`, `list_dir`, `run_shell`).

**Verification:**
- [ ] Files created cleanly without lost functions.

**Dependencies:** Task 4

**Files likely touched:**
- `src/session.pl`
- `src/tools.pl`

**Estimated scope:** Small (2 files)

---

## Task 6: Extract `src/terminal.pl`, `src/ui.pl`, and `src/main.pl`
**Description:** Extract the pure-Perl terminal readline engine (`src/terminal.pl`), UI formatting helpers (`src/ui.pl`), and the main conversational loop entrypoint (`src/main.pl`).

**Acceptance criteria:**
- [ ] `src/terminal.pl` contains `{ my @HISTORY; ... }` and `read_line_interactive` with all ANSI/cursor measurement subs.
- [ ] `src/ui.pl` contains `extract_basename`, `truncate_text`, `_format_line_range`, `format_tool_summary`, `format_tool_call`, `format_thinking_status`, `finalize_thinking_line`, `clear_thinking_line`.
- [ ] `src/main.pl` contains unified `unless (caller)` block with startup provider configuration, banner display, REPL loop, tool dispatch turnaround, clean exit, and terminating `1;`.

**Verification:**
- [ ] All 10 source files exist under `src/`.

**Dependencies:** Task 5

**Files likely touched:**
- `src/terminal.pl`
- `src/ui.pl`
- `src/main.pl`

**Estimated scope:** Medium (3 files)

---

## Task 7: Assemble `code-agent.pl` via `build.pl` and Verify Zero Test Regressions
**Description:** Run `perl build.pl` to produce the assembled `code-agent.pl`. Execute the entire test suite across all 11 test files to confirm 100% backward compatibility and test passing.

**Acceptance criteria:**
- [ ] `perl build.pl` succeeds and generates `code-agent.pl`.
- [ ] `perl -c code-agent.pl` succeeds with `syntax OK`.
- [ ] `prove -v t/*.t` runs all 11 test files and reports 100% PASS with 0 failures.

**Verification:**
- [ ] `perl build.pl`
- [ ] `prove -v t/*.t`

**Dependencies:** Tasks 1-6

**Files likely touched:**
- `code-agent.pl`

**Estimated scope:** Small (1 file)

---

### Checkpoint: Assembly & Regressions
- [ ] `code-agent.pl` builds cleanly from `src/*.pl`.
- [ ] All 11 test files in `t/*.t` pass.

---

### Phase 3: Installer Integration, Documentation & Symbol Graph

## Task 8: Integrate Build Step into `Install.command`
**Description:** Update `Install.command` to automatically check for `build.pl` and `src/`, running `perl build.pl` before installing `code-agent.pl` to the user's build directory.

**Acceptance criteria:**
- [x] Checks `[ -f "build.pl" ] && [ -d "src" ]`.
- [x] Displays informative message: `Building code-agent.pl from src/...`.
- [x] Executes `perl build.pl` and respects `set -e` on any build error.
- [x] Works cleanly when `build.pl` is present as well as when only prebuilt `code-agent.pl` exists.

**Verification:**
- [x] Run `bash -n Install.command` to verify shell syntax.
- [x] Dry-run/test installer logic.

**Dependencies:** Task 7

**Files likely touched:**
- `Install.command`

**Estimated scope:** Small (1 file)

---

## Task 9: Update Documentation (`AGENTS.md`, `README.md`, `README.txt`)
**Description:** Update developer documentation to describe the `src/` modular layout, `build.pl` compilation, and build verification instructions while noting that `code-agent.pl` remains the standalone distribution artifact.

**Acceptance criteria:**
- [x] `AGENTS.md` documents `src/`, `build.pl`, assembly commands, and architectural constraints.
- [x] `README.md` and `README.txt` reflect modular assembly and building from source.

**Verification:**
- [x] Review documentation diffs.

**Dependencies:** Task 8

**Files likely touched:**
- `AGENTS.md`
- `README.md`
- `README.txt`

**Estimated scope:** Medium (3 files)

---

## Task 10: Refresh Symbol Graphs and Context Documentation
**Description:** Run codebase context generator tools to scan AST, refresh symbol and dependency graphs, export signatures, and verify context integrity.

**Acceptance criteria:**
- [x] `ast_scanner.py` runs successfully on root.
- [x] `dependency_graph.py` updates call/import graphs.
- [x] `symbol_graph.py` updates `context/signatures.md`.
- [x] `verify_context.py` passes with zero integrity errors.

**Verification:**
- [x] `python3 /Users/mikhaillarchanka/.gemini/config/skills/codebase-context-generator/scripts/verify_context.py --root .`

**Dependencies:** Task 9

**Files likely touched:**
- `.context_cache/*`
- `context/*`

**Estimated scope:** Small (metadata updates)

---

### Checkpoint: Complete
- [x] All 10 tasks completed and verified.
- [x] All acceptance criteria satisfied.
- [x] Full test suite passes.
- [x] Ready for final review and pull request.

---

## Risks and Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| Missing package declaration causes namespace pollution in concatenated file | High | Ensure `src/json.pl` explicitly ends with `package main;` and `src/transport.pl` begins with `package main;`. |
| Subroutine ordering or prototype issues across modules | Medium | Subroutines in `code-agent.pl` are un-prototyped named subroutines in package `main`, which Perl resolves dynamically at runtime. Assembling modules preserves file scope. |
| Inadvertent omission of code during splitting | High | Compare subroutines and symbols between monolithic baseline and newly assembled `code-agent.pl`; comprehensive test suite (`prove -v t/*.t`) checks all functionality. |
| Installer fails if `src/` is absent (standalone tarball distribution) | Medium | Guard with `if [ -f "build.pl" ] && [ -d "src" ]; then ... fi` so prebuilt `code-agent.pl` can still be installed directly. |

## Open Questions
None. Option 2 (Modular Assembly) and requirements are explicitly specified.
