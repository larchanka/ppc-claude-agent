# Todo List: Line-Based File Tools Extension (`read_file` & `edit_file`)

## Phase 1: Tool Implementations (Foundation)
- [x] Task 1: Extend `read_file` Tool with Line Range Slicing
  - [x] Add `start_line` and `end_line` optional properties to `read_file` in `@TOOLS`
  - [x] Implement range slicing and bounds clamping in `run_tool('read_file', ...)`
  - [x] Handle error validation when `start_line > end_line`
  - [x] Verify syntax via `perl -c code-agent.pl`
- [x] Task 2: Implement `edit_file` Tool in `@TOOLS` and `run_tool`
  - [x] Add `edit_file` tool schema to `@TOOLS` (`path`, `start_line`, `end_line`, `content`)
  - [x] Add validation for file existence and line ranges in `run_tool('edit_file', ...)`
  - [x] Add `confirm_tool` interactive prompt for `edit_file`
  - [x] Implement `splice`-based line replacement, deletion, and insertion logic
  - [x] Ensure proper UTF-8 file output and newline termination
  - [x] Verify syntax via `perl -c code-agent.pl`

### Checkpoint: Foundation
- [x] Syntax check passes (`perl -c code-agent.pl`)
- [x] Existing tests run and pass (`prove -v t/*.t`)

---

## Phase 2: System Prompt & Provider Integration
- [x] Task 3: Update System Prompt and Tool Descriptions
  - [x] Update `$SYSTEM_PROMPT` to document five available tools including `edit_file`
  - [x] Describe line slicing usage for `read_file`
  - [x] Describe line range replacement and deletion usage for `edit_file`
  - [x] Verify syntax via `perl -c code-agent.pl`

---

## Phase 3: Verification & Context Maintenance
- [x] Task 4: Unit Test Suite for `read_file` and `edit_file`
  - [x] Create `t/tool_read_edit_file.t`
  - [x] Test full vs sliced reading (`read_file`) with edge cases (clamping, out-of-bounds, errors)
  - [x] Test line replacement, insertion, deletion, and newline handling (`edit_file`)
  - [x] Test `confirm_tool` prompt and rejection in manual mode
  - [x] Test `confirm_tool` bypass in auto mode
  - [x] Run full test suite (`prove -v t/*.t`)
- [x] Task 5: Context & Symbol Graph Refresh
  - [x] Update `context/architecture.md`, `context/modules.md`, `context/conventions.md`, and `AGENTS.md`
  - [x] Run AST scanner, dependency graph, and symbol graph scripts
  - [x] Run `verify_context.py` to confirm zero integrity errors

---

## Phase 4: Code Clean-Up
- [x] Task 6: Comments Clean-Up in `code-agent.pl`
  - [x] Clean up redundant narrative/boilerplate comments in `code-agent.pl`
  - [x] Preserve essential Perl 5.8.6 Tiger OS compatibility notes and safety invariants
  - [x] Verify syntax via `perl -c code-agent.pl`
  - [x] Verify test suite via `prove -v t/*.t`

### Checkpoint: Complete
- [x] 100% test pass rate across all test files
- [x] Codebase context and symbol graphs fully synchronized
