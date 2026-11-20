# Todo List: `/new` Chat Session Reset Command

## Phase 1: Foundation (Session Abstraction & Command Handler)
- [x] Task 1: Implement Session Abstraction & Lifecycle Hooks
  - [x] Implement `generate_session_id()` with timestamp and monotonic counter in `code-agent.pl`
  - [x] Implement `init_session([$id])` returning structured session hashref
  - [x] Implement `get_current_session()` with lazy initialization
  - [x] Implement `archive_session($session)` extensible hook point
  - [x] Verify syntax via `perl -c code-agent.pl`
- [x] Task 2: Implement `/new` Command Handler and Help Documentation
  - [x] Implement `handle_new_command($out_fh)` archiving old session, creating new session, and printing confirmation
  - [x] Update `show_help($out_fh)` to include `/new` command description
  - [x] Verify syntax via `perl -c code-agent.pl`

### Checkpoint: Foundation
- [x] Syntax check passes (`perl -c code-agent.pl`)
- [x] Existing test suite runs and passes (`prove t/`)

---

## Phase 2: Main Loop Integration
- [x] Task 3: Integrate Session Management and `/new` into Interactive Loop
  - [x] Update startup banner to mention `/new`
  - [x] Wire `/new` dispatch in conversation loop to call `handle_new_command()`
  - [x] Use `$CURRENT_SESSION->{messages}` for message tracking in conversation loop
  - [x] Verify syntax via `perl -c code-agent.pl`

### Checkpoint: Core Features
- [x] Syntax check passes (`perl -c code-agent.pl`)
- [x] Manual or automated verification of interactive loop with `/new` command

---

## Phase 3: Verification & Test Suite
- [x] Task 4: Comprehensive Test Suite for `/new` and Session Management
  - [x] Create `t/new_command.t`
  - [x] Test `generate_session_id`, `init_session`, `get_current_session`
  - [x] Test `handle_new_command` resetting messages and outputting confirmation
  - [x] Test `archive_session` hook invocation
  - [x] Test piped agent execution verifying messages reset between `/new` and subsequent prompt
  - [x] Test `show_help` lists `/new`
  - [x] Verify test suite passes (`prove -v t/new_command.t` and `prove t/`)

### Checkpoint: Verification
- [x] All tests pass (`prove t/`)

---

## Phase 4: Documentation & Context Maintenance
- [x] Task 5: Context & Symbol Graph Refresh
  - [x] Update `README.md` and `README.txt` with `/new` command documentation
  - [x] Update `context/architecture.md` and `context/modules.md` with session abstraction and `handle_new_command`
  - [x] Run AST scanner, dependency graph, and symbol graph generators
  - [x] Run `verify_context.py` to confirm zero integrity errors

### Checkpoint: Complete
- [x] 100% test pass rate across all test files
- [x] Codebase context and symbol graphs fully synchronized
