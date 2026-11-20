# Implementation Plan: `/auto` and `/manual` Mode Slash Commands

## Overview
Implement two new slash commands in `claude-agent.pl`:
- `/auto`: Enables autonomous mode where tools that normally require interactive user confirmation (`write_file` and `run_shell`) execute immediately without prompting.
- `/manual`: Restores default manual mode where side-effect tools require explicit `[y/N]` confirmation via `confirm()`.

This maintains the existing safety-first default while allowing unattended workflows when explicitly activated by the user.

---

## Architecture Decisions

1. **State Management (`$AUTO_MODE`, `get_auto_mode`, `set_auto_mode`)**:
   - Introduce `$AUTO_MODE = 0` (defaulting to manual/disabled).
   - Support optional initialization from `$ENV{CLAUDE_AUTO_MODE}` (if set and truthy, starts in auto mode).
   - Provide `get_auto_mode()` and `set_auto_mode($val)` accessors for clean module encapsulation and testability.

2. **Encapsulated Confirmation Wrapper (`confirm_tool`)**:
   - Rather than scattering conditional `$AUTO_MODE` checks across multiple tool branches in `run_tool`, introduce `confirm_tool($prompt)`:
     ```perl
     sub confirm_tool {
         my ($prompt) = @_;
         return 1 if $AUTO_MODE;
         return confirm($prompt);
     }
     ```
   - In `run_tool`:
     - `write_file`: `unless (confirm_tool("Write to file '$path'?")) { return "Cancelled by user."; }`
     - `run_shell`: `unless (confirm_tool("Run this command: $command")) { return "Cancelled by user."; }`
   - Keeps `confirm()` dedicated to direct user interactions (e.g. saving API keys) while `confirm_tool()` governs tool permissions.

3. **Command Handlers & Help Integration (`handle_auto_command`, `handle_manual_command`)**:
   - Add `handle_auto_command($out_fh)` and `handle_manual_command($out_fh)` accepting an optional output handle for unit test capture.
   - `/auto` prints: `"Auto mode enabled. Tools will execute without user confirmation.\n"`.
   - `/manual` prints: `"Manual mode enabled. Tools will require user confirmation.\n"`.
   - Update `show_help($out_fh)` and the startup greeting to document `/auto` and `/manual`.
   - Dispatch `/auto` and `/manual` in the main interactive conversation loop.

4. **Zero CPAN & Perl 5.8.6 Compatibility**:
   - Use standard Perl 5.8.6 constructs only (no `//`, no `state`, no modern unicode properties).
   - Ensure clean return values and proper UTF-8 handling.

---

## Task List

### Phase 1: Foundation (State & Tool Confirmation Layer)

## Task 1: Auto Mode State Management & `confirm_tool` Helper
**Description:** Add `$AUTO_MODE` variable, `get_auto_mode()`, `set_auto_mode($val)`, and `confirm_tool($prompt)` helper subroutine in `claude-agent.pl`.

**Acceptance criteria:**
- [ ] `$AUTO_MODE` defaults to `0` (manual mode). If `$ENV{CLAUDE_AUTO_MODE}` is truthy, initializes to `1`.
- [ ] `get_auto_mode()` returns current mode (`0` or `1`).
- [ ] `set_auto_mode($val)` updates `$AUTO_MODE` (`1` if truthy, `0` otherwise) and returns the new value.
- [ ] `confirm_tool($prompt)` returns `1` immediately without calling `confirm()` when `$AUTO_MODE` is truthy; calls `confirm($prompt)` when `$AUTO_MODE` is falsy.

**Verification:**
- [ ] `perl -c claude-agent.pl` passes syntax verification.

**Dependencies:** None

**Files likely touched:**
- `claude-agent.pl`

**Estimated scope:** Small (1 file)

---

## Task 2: Tool Execution Integration in `run_tool`
**Description:** Update `write_file` and `run_shell` in `run_tool` to check permission via `confirm_tool(...)` instead of directly calling `confirm(...)`.

**Acceptance criteria:**
- [ ] In `write_file`, file write proceeds without prompt when auto mode is enabled.
- [ ] In `write_file`, file write prompts for confirmation and respects user cancellation when in manual mode.
- [ ] In `run_shell`, command execution proceeds without prompt when auto mode is enabled.
- [ ] In `run_shell`, command execution prompts for confirmation and respects user cancellation when in manual mode.

**Verification:**
- [ ] `perl -c claude-agent.pl` passes syntax verification.

**Dependencies:** Task 1

**Files likely touched:**
- `claude-agent.pl`

**Estimated scope:** Small (1 file)

---

### Checkpoint: Foundation
- [ ] `perl -c claude-agent.pl` passes.
- [ ] Existing test suite (`prove -v t/*.t`) continues to pass with zero regressions.

---

### Phase 2: User Interface & Command Handling

## Task 3: Command Handlers (`/auto`, `/manual`), Help & Main Loop
**Description:** Implement `handle_auto_command($out_fh)` and `handle_manual_command($out_fh)`. Add `/auto` and `/manual` to `show_help($out_fh)`, startup banner, and route the commands in the main loop.

**Acceptance criteria:**
- [ ] `handle_auto_command($out_fh)` activates auto mode and prints confirmation message.
- [ ] `handle_manual_command($out_fh)` activates manual mode and prints confirmation message.
- [ ] `show_help($out_fh)` lists `/auto` and `/manual` with concise descriptions.
- [ ] Main conversation loop intercepts `/auto` and `/manual` input strings, invokes their respective handlers, and restarts input loop.
- [ ] Startup greeting mentions `/auto /manual` commands.

**Verification:**
- [ ] `perl -c claude-agent.pl` passes syntax verification.

**Dependencies:** Task 1, Task 2

**Files likely touched:**
- `claude-agent.pl`

**Estimated scope:** Small (1 file)

---

### Checkpoint: Core Features
- [ ] Syntax check passes.
- [ ] Handlers can be invoked and produce expected output strings.

---

### Phase 3: Verification & Context Maintenance

## Task 4: Unit Test Suite for Auto/Manual Commands
**Description:** Create dedicated test file `t/auto_manual_commands.t` covering state changes, command handlers, `show_help`, tool bypass in auto mode, and tool prompting in manual mode.

**Acceptance criteria:**
- [ ] Tests verify default manual state and accessor functions.
- [ ] Tests verify `/auto` and `/manual` handler outputs and state changes.
- [ ] Tests verify `show_help` output includes `/auto` and `/manual`.
- [ ] Tests verify `run_tool('write_file', ...)` and `run_tool('run_shell', ...)` execute without calling `confirm()` in auto mode.
- [ ] Tests verify `run_tool('write_file', ...)` and `run_tool('run_shell', ...)` prompt via `confirm()` in manual mode.
- [ ] All tests in `t/*.t` pass cleanly (`prove -v t/*.t`).

**Verification:**
- [ ] `prove -v t/auto_manual_commands.t` passes with 100% success.
- [ ] Full test suite `prove -v t/*.t` passes.

**Dependencies:** Tasks 1-3

**Files likely touched:**
- `t/auto_manual_commands.t`

**Estimated scope:** Small (1-2 files)

---

## Task 5: Context & Symbol Graph Refresh
**Description:** Update documentation (`AGENTS.md`, `context/architecture.md`, `context/modules.md`) and run the codebase AST scanner and symbol graph generator.

**Acceptance criteria:**
- [ ] `AGENTS.md` notes the `/auto` and `/manual` modes.
- [ ] `context/architecture.md` and `context/modules.md` document new subroutines.
- [ ] AST scanner, dependency graph, and symbol graph scripts run successfully.
- [ ] `verify_context.py` passes with zero integrity errors.

**Verification:**
- [ ] `python3 /Users/mikhaillarchanka/.gemini/config/skills/codebase-context-generator/scripts/verify_context.py --root .` passes.

**Dependencies:** Tasks 1-4

**Files likely touched:**
- `AGENTS.md`
- `context/architecture.md`
- `context/modules.md`
- `context/signatures.md`
- `.context_cache/`

**Estimated scope:** Medium (3-5 files)

---

### Checkpoint: Complete
- [ ] All acceptance criteria met across all tasks.
- [ ] Zero CPAN dependencies maintained.
- [ ] Perl 5.8.6 syntax compliance verified.
- [ ] Documentation and symbol graphs synchronized.

---

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Unintended execution of destructive shell/file commands in auto mode | High | Auto mode is strictly opt-in via `/auto`, manual mode is default, and `/manual` is always available to revert immediately. |
| Non-tool confirmation prompts (e.g. saving API keys) inadvertently bypassed | Med | Separate `confirm_tool()` from `confirm()`; direct user prompts continue using `confirm()` regardless of auto mode. |
| Breakage of existing unit tests that test `run_tool` or `confirm` | Med | Default mode remains manual (`$AUTO_MODE = 0`), preserving all existing test assertions. |

---

## Open Questions
- None. Requirements are clear and fully specified.
