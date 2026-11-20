# Todo List: `/auto` and `/manual` Mode Slash Commands

## Phase 1: Foundation (State & Tool Confirmation Layer)
- [ ] Task 1: Auto Mode State Management & `confirm_tool` Helper
  - [ ] Add `$AUTO_MODE` variable with fallback to `$ENV{CLAUDE_AUTO_MODE}` or `0`
  - [ ] Implement `get_auto_mode()` and `set_auto_mode($val)`
  - [ ] Implement `confirm_tool($prompt)` helper that bypasses `confirm()` when auto mode is active
  - [ ] Verify syntax via `perl -c claude-agent.pl`
- [ ] Task 2: Tool Execution Integration in `run_tool`
  - [ ] Update `run_tool('write_file', ...)` to use `confirm_tool(...)`
  - [ ] Update `run_tool('run_shell', ...)` to use `confirm_tool(...)`
  - [ ] Verify syntax via `perl -c claude-agent.pl`

### Checkpoint: Foundation
- [ ] Syntax check passes (`perl -c claude-agent.pl`)
- [ ] Existing tests run and pass (`prove -v t/*.t`)

---

## Phase 2: User Interface & Command Handling
- [ ] Task 3: Command Handlers (`/auto`, `/manual`), Help & Main Loop
  - [ ] Implement `handle_auto_command($out_fh)`
  - [ ] Implement `handle_manual_command($out_fh)`
  - [ ] Update `show_help($out_fh)` to include `/auto` and `/manual`
  - [ ] Update startup banner to mention `/auto /manual`
  - [ ] Add `/auto` and `/manual` routing to the conversation loop
  - [ ] Verify syntax via `perl -c claude-agent.pl`

### Checkpoint: Core Features
- [ ] All commands routed and verified with clean syntax check

---

## Phase 3: Verification & Context Maintenance
- [ ] Task 4: Unit Test Suite for Auto/Manual Commands
  - [ ] Create `t/auto_manual_commands.t`
  - [ ] Test default state, getters, and setters
  - [ ] Test `/auto` and `/manual` handlers and messages
  - [ ] Test `show_help` mentions `/auto` and `/manual`
  - [ ] Test `run_tool` with `write_file` and `run_shell` in both manual and auto modes
  - [ ] Run full test suite (`prove -v t/*.t`)
- [ ] Task 5: Context & Symbol Graph Refresh
  - [ ] Update `AGENTS.md` and `context/` markdown docs
  - [ ] Run AST scanner, dependency graph, and symbol graph scripts
  - [ ] Run `verify_context.py` to confirm zero integrity errors

### Checkpoint: Complete
- [ ] 100% test pass rate across all test files
- [ ] Codebase context and symbol graphs fully synchronized
