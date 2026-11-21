# Implementation Plan: AGENTS.md Context Integration

Support global instructions (`~/.agents/AGENTS.md`) and local project instructions (`./AGENTS.md`) in the agent's LLM context and system prompt, adhering strictly to pure Perl 5.8.6, zero CPAN dependencies, and Mac OS X 10.4 Tiger compatibility with minimal phases.

---

## Overview

When interacting with LLM providers (Anthropic, Gemini, OpenAI-compatible), developer guidelines, coding rules, and constraints must be provided via the system prompt. This feature introduces automatic discovery and injection of `AGENTS.md` instructions into the context:
1. **Global Instructions**: Read from `~/.agents/AGENTS.md` (or `$HOME/.agents/AGENTS.md`) to establish user-wide preferences, conventions, and operational constraints across all projects.
2. **Local Project Instructions**: Read from `./AGENTS.md` in the current working directory to establish project-specific architectural guidelines, commands, and rules.
3. **Composed System Context**: When present, instructions are cleanly formatted and appended to `$SYSTEM_PROMPT`. If a file is absent or empty, it is silently skipped. If the current working directory is `~/.agents`, deduplication prevents repeating the instructions twice.

To satisfy the requirement for a **minimal amount of phases**, the implementation is structured into two clean, self-contained phases:
- **Phase 1: Core Implementation & Integration** (Source module update, build compilation, and REPL loop integration)
- **Phase 2: Comprehensive Test Suite & Context Verification** (Unit tests covering all edge cases, regression check, and AST/symbol graph synchronization)

---

## Architecture Decisions

### 1. Placement in Source Tree (`src/header.pl` & `src/main.pl`)
- **`src/header.pl`**: Configuration and environment logic already resides here (`get_env_file_path`, `load_env_file`, `$SYSTEM_PROMPT`). We introduce:
  - `read_agents_file($path)`: Pure Perl 5.8.6 safe file reader with UTF-8 decoding.
  - `get_agents_context($home_dir, $cwd)`: Discovers global (`~/.agents/AGENTS.md`) and local (`./AGENTS.md`) files, performs inode/device-based deduplication, trims content, and formats markdown section headers.
  - `get_effective_system_prompt($base_prompt, $home_dir, $cwd)`: Composes base system prompt with discovered context. Accepts optional `$home_dir` and `$cwd` parameters to enable hermetic, mock-free unit testing.
- **`src/main.pl`**: Replaces the static `$SYSTEM_PROMPT` argument in `build_request(...)` with a dynamic invocation of `get_effective_system_prompt()`. This guarantees that if a user or tool updates `AGENTS.md` during an active interactive session, the next API request automatically picks up the updated instructions without requiring a session restart.

### 2. File Discovery & Deduplication Protocol
- Global path: `$ENV{HOME} . "/.agents/AGENTS.md"` (with fallback to `.` if `$ENV{HOME}` is unset).
- Local path: `./AGENTS.md` in the current working directory.
- Deduplication: Uses Perl's standard `stat($file)` (`dev` and `ino` comparison). If both paths refer to the same physical file (e.g. agent launched inside `~/.agents`), it is loaded only once under the global heading.
- Silent fallback: If a file does not exist, cannot be opened, or contains only whitespace, no error is thrown and no extraneous header is appended.

### 3. Pure Perl 5.8.6 & Tiger Compatibility
- No modern Perl syntax (no `//`, `state`, `say`, named regex captures, or `autodie`).
- Standard core modules and built-ins only (`Encode`, `stat`, `open` with `:encoding(UTF-8)`).
- Zero external CPAN dependencies.

---

## Task List

### Phase 1: Core Implementation & Integration

## Task 1: Implement AGENTS.md Context Helpers in `src/header.pl`
**Description:** Implement `read_agents_file`, `get_agents_context`, and `get_effective_system_prompt` in `src/header.pl`. The functions safely read global and local `AGENTS.md` files, handle whitespace trimming, avoid duplicate inclusions when paths point to the same file, and append formatted markdown sections to `$SYSTEM_PROMPT`.

**Acceptance criteria:**
- [x] `read_agents_file($path)` returns decoded UTF-8 string, or empty string on missing/unreadable files.
- [x] `get_agents_context($home_dir, $cwd)` inspects `$home_dir/.agents/AGENTS.md` and `$cwd/AGENTS.md` (defaulting to `$ENV{HOME}` and `./AGENTS.md`).
- [x] Deduplication verifies `stat()` device and inode numbers so identical files are not injected twice.
- [x] Non-empty file contents are wrapped in explicit section headers (`# Global Instructions (~/.agents/AGENTS.md)` and `# Project Instructions (AGENTS.md)`).
- [x] `get_effective_system_prompt($base_prompt, $home_dir, $cwd)` returns base prompt unchanged when neither file exists or both are empty, and appends context sections when present.

**Verification:**
- [x] Syntax check: `perl -c src/header.pl`
- [x] Quick unit check in perl one-liner verifying return values.

**Dependencies:** None
**Files likely touched:**
- `src/header.pl`

**Estimated scope:** Small (1 file, ~45 lines)

---

## Task 2: Integrate Dynamic System Prompt in `src/main.pl` and Build Standalone Artifact
**Description:** Update `src/main.pl` in the turnaround loop so `build_request` receives `get_effective_system_prompt()` instead of static `$SYSTEM_PROMPT`. Run `perl build.pl` to compile modular sources into `code-agent.pl` and verify syntax.

**Acceptance criteria:**
- [x] `src/main.pl` calls `get_effective_system_prompt()` when assembling requests in `build_request`.
- [x] `perl build.pl` regenerates `code-agent.pl` cleanly with exit code 0.
- [x] `perl build.pl --check` confirms source-to-artifact synchronization.
- [x] `perl -c code-agent.pl` passes syntax verification.

**Verification:**
- [x] Run `perl build.pl`
- [x] Run `perl build.pl --check`
- [x] Run `perl -c code-agent.pl`

**Dependencies:** Task 1
**Files likely touched:**
- `src/main.pl`
- `code-agent.pl`

**Estimated scope:** Small (2 files)

---

### Checkpoint: Foundation & Core Integration
- [x] `code-agent.pl` builds without warnings or errors.
- [x] Existing test suite (`prove t/*.t`) continues to pass without regressions.

---

### Phase 2: Comprehensive Test Suite & Context Verification

## Task 3: Create Automated Unit Test Suite `t/agents_context.t`
**Description:** Implement a comprehensive test file `t/agents_context.t` testing all combinations of global and local `AGENTS.md` existence, deduplication, content formatting, and empty file handling.

**Acceptance criteria:**
- [x] Tests base behavior when neither global nor local `AGENTS.md` exists.
- [x] Tests inclusion of global instructions only (`~/.agents/AGENTS.md`).
- [x] Tests inclusion of local instructions only (`./AGENTS.md`).
- [x] Tests combination of both global and local instructions in correct precedence order.
- [x] Tests deduplication when local directory is the same as the global directory.
- [x] Tests that empty or whitespace-only `AGENTS.md` files do not insert empty sections.
- [x] Tests handling of unreadable or missing paths without crashing.
- [x] Verifies full integration with `build_request` across Anthropic, Gemini, and OpenAI request structures.

**Verification:**
- [x] Run `prove -v t/agents_context.t`
- [x] Run entire suite: `prove t/*.t` (all tests passing)

**Dependencies:** Task 2
**Files likely touched:**
- `t/agents_context.t`

**Estimated scope:** Small (1 new test file)

---

## Task 4: Post-Change Context & Symbol Graph Maintenance
**Description:** Per project instructions (`AGENTS.md` Rule 5), refresh AST scans, dependency graphs, and symbol tables after modifying source code. Verify context documentation integrity.

**Acceptance criteria:**
- [x] AST scanner runs: `python3 ~/.gemini/config/skills/codebase-context-generator/scripts/ast_scanner.py --root .`
- [x] Dependency graph updates: `python3 ~/.gemini/config/skills/codebase-context-generator/scripts/dependency_graph.py --manifest .context_cache/ast_manifest.json`
- [x] Symbol graph exports signatures: `python3 ~/.gemini/config/skills/codebase-context-generator/scripts/symbol_graph.py ... --export-signatures context/signatures.md`
- [x] Context verification succeeds: `python3 ~/.gemini/config/skills/codebase-context-generator/scripts/verify_context.py --root .`

**Verification:**
- [x] Verification script outputs success with 0 errors.

**Dependencies:** Task 3
**Files likely touched:**
- `.context_cache/*`
- `context/signatures.md`
- `context/modules.md` (if catalog updated)

**Estimated scope:** Medium (context graph updates)

---

### Checkpoint: Complete
- [x] All 4 tasks completed and verified.
- [x] All unit and regression tests pass (`prove t/*.t`).
- [x] Full compliance with Perl 5.8.6 and Tiger compatibility rules.

---

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| **Perl 5.8.6 File Encoding Incompatibility** | High | Use `open(my $fh, '<:encoding(UTF-8)', $path)` or standard raw read + `Encode::decode('UTF-8', $content, FB_DEFAULT)`, which are tested and verified on Tiger standard Perl. |
| **Path Collisions / Duplicate Context** | Medium | Use `stat($file)` device/inode (`dev`, `ino`) matching to detect when global and local resolve to the exact same file. |
| **Whitespace / Empty Files Adding Noise** | Low | Perform regex trim `s/^\s+|\s+$//g` and check `length $content` before formatting sections. |
| **Overwriting or Bloating System Prompt** | Medium | Append context sections cleanly to `$SYSTEM_PROMPT` with distinct markdown headers, preserving base tool definitions and quirks intact. |

---

## Open Questions

- None. Requirements are clear: global from `~/.agents/AGENTS.md`, local from `./AGENTS.md`, with minimal phases.
