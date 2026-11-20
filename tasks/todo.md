# Todo List: `/auto` and `/manual` Mode Slash Commands

## Phase 1: Foundation (State & Tool Confirmation Layer)
- [x] Task 1: Auto Mode State Management & `confirm_tool` Helper
  - [x] Add `$AUTO_MODE` variable with fallback to `$ENV{CLAUDE_AUTO_MODE}` or `0`
  - [x] Implement `get_auto_mode()` and `set_auto_mode($val)`
  - [x] Implement `confirm_tool($prompt)` helper that bypasses `confirm()` when auto mode is active
  - [x] Verify syntax via `perl -c claude-agent.pl`
- [x] Task 2: Tool Execution Integration in `run_tool`
  - [x] Update `run_tool('write_file', ...)` to use `confirm_tool(...)`
  - [x] Update `run_tool('run_shell', ...)` to use `confirm_tool(...)`
  - [x] Verify syntax via `perl -c claude-agent.pl`

### Checkpoint: Foundation
- [x] Syntax check passes (`perl -c claude-agent.pl`)
- [x] Existing tests run and pass (`prove -v t/*.t`)

---

## Phase 2: User Interface & Command Handling
- [x] Task 3: Command Handlers (`/auto`, `/manual`), Help & Main Loop
  - [x] Implement `handle_auto_command($out_fh)`
  - [x] Implement `handle_manual_command($out_fh)`
  - [x] Update `show_help($out_fh)` to include `/auto` and `/manual`
  - [x] Update startup banner to mention `/auto /manual`
  - [x] Add `/auto` and `/manual` routing to the conversation loop
  - [x] Verify syntax via `perl -c claude-agent.pl`

### Checkpoint: Core Features
- [x] All commands routed and verified with clean syntax check

---

## Phase 3: Verification & Context Maintenance
- [x] Task 4: Unit Test Suite for Auto/Manual Commands
  - [x] Create `t/auto_manual_commands.t`
  - [x] Test default state, getters, and setters
  - [x] Test `/auto` and `/manual` handlers and messages
  - [x] Test `show_help` mentions `/auto` and `/manual`
  - [x] Test `run_tool` with `write_file` and `run_shell` in both manual and auto modes
  - [x] Run full test suite (`prove -v t/*.t`)
- [x] Task 5: Context & Symbol Graph Refresh
  - [x] Update `AGENTS.md` and `context/` markdown docs
  - [x] Run AST scanner, dependency graph, and symbol graph scripts
  - [x] Run `verify_context.py` to confirm zero integrity errors

### Checkpoint: Complete
- [x] 100% test pass rate across all test files
- [x] Codebase context and symbol graphs fully synchronized
