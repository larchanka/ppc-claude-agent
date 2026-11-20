# Implementation Plan: `/new` Chat Session Reset Command

## Overview
Implement a `/new` slash command in `code-agent.pl` to clean up the current conversation context (clearing chat history) so users can start fresh conversations without restarting the agent. While sessions are not stored to disk in this initial iteration, the underlying state is architected with a formal `Session` data model and lifecycle hooks (`init_session`, `archive_session`, `generate_session_id`) to cleanly enable future session persistence and continuation.

---

## Architecture Decisions

### 1. Session Data Model (`$CURRENT_SESSION`)
Currently, conversation history is held in a lexical array (`my @messages`) scoped inside `unless (caller) { ... }`, making it opaque to modular handlers and automated tests.
We introduce a structured session representation:
```perl
{
    id         => $session_id,     # e.g., session-20261120-153000-001
    created_at => time(),
    provider   => $PROVIDER,
    model      => $MODEL,
    messages   => [],              # Array of Anthropic-style message structures
}
```
- Managed via package-level variable `our $CURRENT_SESSION = undef;`.
- Accessor `get_current_session()` lazily initializes a session if none exists.
- `init_session([$id])` instantiates a new session with unique timestamp-based ID and empty message list.
- Monotonic counter + `localtime` ensure unique IDs in standard Perl 5.8.6 without UUID libraries.

### 2. Extensible Persistence Hook (`archive_session`)
To satisfy the requirement *"for now we dont store old sessions, but later we would like to store and be able to continue"*:
- `handle_new_command()` invokes `archive_session($CURRENT_SESSION)` immediately before re-initializing.
- In this release, `archive_session()` acts as an explicit hook (in-memory or no-op) with metadata preserved.
- When disk persistence is introduced later, `archive_session()` will serialize `$session` to JSON via `MiniJSON::encode` and write to `~/.code-agent-sessions/`, allowing seamless resume/continue commands without altering command loop contracts.

### 3. Command Handler & User Feedback
- `handle_new_command($out_fh, $session)`:
  - Takes an optional filehandle (defaulting to `\*STDOUT`) and optional session reference.
  - Calls `archive_session($session)`.
  - Re-initializes `$CURRENT_SESSION = init_session()`.
  - Prints: `Started a new conversation. Chat history cleared.`
  - Returns the new session hashref.
- `show_help()` is updated to document `/new`.
- Startup banner updated to mention `/new`.

### 4. Compatibility & Invariants
- 100% pure standard Perl 5.8.6 compatible (no `//`, no external modules).
- Maintains raw STDIN and UTF-8 output separation.
- Preserves full testability: unit tests can require `code-agent.pl` and test session state and command handling directly.

---

## Task List

### Phase 1: Foundation (Session Abstraction & Command Handler)

## Task 1: Implement Session Abstraction & Lifecycle Hooks
**Description:** Add session data structures and helper functions (`generate_session_id`, `init_session`, `get_current_session`, `archive_session`) to `code-agent.pl`.

**Acceptance criteria:**
- [ ] `generate_session_id()` produces unique timestamped session identifiers.
- [ ] `init_session()` creates and returns a session hashref with `id`, `created_at`, `provider`, `model`, and an empty `messages` arrayref.
- [ ] `get_current_session()` returns the active `$CURRENT_SESSION`, initializing one if undefined.
- [ ] `archive_session($session)` provides an explicit, safe hook for future session persistence.

**Verification:**
- [ ] `perl -c code-agent.pl` passes syntax check.

**Dependencies:** None

**Files likely touched:**
- `code-agent.pl`

**Estimated scope:** Small (1 file)

---

## Task 2: Implement `/new` Command Handler and Help Documentation
**Description:** Implement `handle_new_command($out_fh)` and update `show_help($out_fh)` to include `/new`.

**Acceptance criteria:**
- [ ] `handle_new_command($out_fh)` archives current session, creates a new session, prints `"Started a new conversation. Chat history cleared.\n"`, and returns new session.
- [ ] `show_help($out_fh)` lists `/new     - Start a new conversation (clears chat history)`.

**Verification:**
- [ ] `perl -c code-agent.pl` passes syntax check.

**Dependencies:** Task 1

**Files likely touched:**
- `code-agent.pl`

**Estimated scope:** Small (1 file)

---

### Checkpoint: Foundation
- [ ] `perl -c code-agent.pl` passes syntax verification.
- [ ] Existing test suite (`prove t/`) runs with 0 failures.

---

### Phase 2: Main Loop Integration

## Task 3: Integrate Session Management and `/new` into Interactive Loop
**Description:** Wire `$CURRENT_SESSION` and `/new` dispatch into the interactive conversation loop and startup banner in `code-agent.pl`.

**Acceptance criteria:**
- [ ] Startup banner lists `/new` alongside `/models`, `/auto`, `/manual`.
- [ ] Entering `/new` in the interactive loop invokes `handle_new_command()` and resets the conversation context.
- [ ] User and assistant messages in subsequent turns append to the new session's messages list.

**Verification:**
- [ ] `perl -c code-agent.pl` passes syntax check.

**Dependencies:** Task 2

**Files likely touched:**
- `code-agent.pl`

**Estimated scope:** Small (1 file)

---

### Phase 3: Verification & Test Suite

## Task 4: Comprehensive Test Suite for `/new` and Session Management
**Description:** Create `t/new_command.t` testing session lifecycle, `/new` handler output, message isolation between sessions, and mock integration loop.

**Acceptance criteria:**
- [ ] Tests `init_session()`, `get_current_session()`, and `generate_session_id()`.
- [ ] Tests `handle_new_command()` clears messages and outputs confirmation.
- [ ] Tests `archive_session()` hook invocation.
- [ ] Tests integration: running agent with simulated stdin piping messages and `/new`, verifying subsequent API requests exclude previous turn messages.
- [ ] Tests `show_help()` includes `/new`.

**Verification:**
- [ ] `prove -v t/new_command.t` passes.
- [ ] Full test suite (`prove -v t/*.t`) passes 100%.

**Dependencies:** Task 3

**Files likely touched:**
- `t/new_command.t`

**Estimated scope:** Small (1 file)

---

### Phase 4: Documentation & Context Maintenance

## Task 5: Context & Symbol Graph Refresh
**Description:** Update documentation (`README.md`, `README.txt`, `context/` docs) to document `/new` and regenerate symbol/dependency graphs.

**Acceptance criteria:**
- [x] `README.md` and `README.txt` document the `/new` command.
- [x] `context/architecture.md` and `context/modules.md` reflect session management and `/new` handler.
- [x] AST scanner, dependency graph, and symbol graph scripts run successfully.
- [x] `verify_context.py` passes with zero errors.

**Verification:**
- [x] `python3 /Users/mikhaillarchanka/.gemini/config/skills/codebase-context-generator/scripts/verify_context.py --root .` passes.

**Dependencies:** Task 4

**Files likely touched:**
- `README.md`
- `README.txt`
- `context/architecture.md`
- `context/modules.md`
- `context/signatures.md`
- `.context_cache/`

**Estimated scope:** Medium (4-5 files)

---

### Checkpoint: Complete
- [x] All acceptance criteria met across all 5 tasks.
- [x] 100% test pass rate across all unit test files.
- [x] Codebase context and symbol graphs fully synchronized.

---

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Leaking old conversation messages into new session | High | `init_session` creates a fresh anonymous array reference (`messages => []`); integration tests verify that messages before `/new` do not appear in API payload after `/new`. |
| Breaking caller test harnesses relying on `code-agent.pl` globals | Med | `$CURRENT_SESSION` is declared via `our`, and `get_current_session()` ensures backward compatibility even if called without explicit initialization. |
| Non-unique session IDs when invoked rapidly | Low | `generate_session_id` combines timestamp down to seconds with an incrementing counter (`%03d`). |

---

## Open Questions
- None. Requirements and design align directly with requested `/new` behavior and future session continuation capabilities.
