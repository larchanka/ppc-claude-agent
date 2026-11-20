# Implementation Checklist: Dimmed & Compact Tool Call Visual Formatting

## Phase 1: Foundation (Core Formatting & Color Helpers)
- [x] **Task 1: Implement String Helpers & ANSI Dim Definition in `code-agent.pl`**
  - [x] Add `our $COLOR_DIM = "\x1b[2m";` to color definitions with `NO_COLOR` and `!-t STDOUT` check
  - [x] Implement `extract_basename($path)` for safe filename extraction
  - [x] Implement `truncate_text($str, $max_len)` with newline normalization and `...` truncation
  - [x] Implement `format_tool_summary($name, $input)` returning 3-space separated columns
  - [x] Implement `format_tool_call($name, $input)` decorating summary with `$COLOR_DIM` and `$COLOR_RESET`
  - [x] Verify `perl -c code-agent.pl`

### Checkpoint: Foundation
- [x] `perl -c code-agent.pl` syntax check passes cleanly

---

## Phase 2: Integration
- [x] **Task 2: Integrate `format_tool_call` into Conversation Loop**
  - [x] Replace `print "\n[tool_use] $block->{name}(" . MiniJSON::encode($block->{input}) . ")\n";` with `print "\n" . format_tool_call($block->{name}, $block->{input}) . "\n";` in `code-agent.pl`
  - [x] Verify tool dispatch, confirmation prompts, and execution unaffected
  - [x] Run test suite `prove -I. t/*.t` to verify no regressions

### Checkpoint: Integration
- [x] Existing test suite passes with zero failures (`prove -I. t/*.t`)

---

## Phase 3: Verification & Documentation
- [x] **Task 3: Comprehensive Unit Tests in `t/tool_call_visuals.t`**
  - [x] Write unit tests for `read_file` (with/without line slicing, deep paths)
  - [x] Write unit tests for `write_file` (basename, truncated content)
  - [x] Write unit tests for `edit_file` (basename, range, replacement preview)
  - [x] Write unit tests for `run_shell` (short commands, > 20 char commands cut to 20 + `...`)
  - [x] Write unit tests for `list_dir` (paths and dot)
  - [x] Write unit tests for ANSI `$COLOR_DIM` wrapping and disabled state
  - [x] Run `prove -I. t/tool_call_visuals.t`

- [x] **Task 4: Context Refresh, Architecture Sync & Persistent Memory Log**
  - [x] Re-scan AST and refresh symbol graph (`ast_scanner.py`, `dependency_graph.py`, `symbol_graph.py`)
  - [x] Verify context integrity (`verify_context.py`)
  - [x] Append architectural record to `memo-mcp` via `append_memory`

### Checkpoint: Complete
- [x] All tests pass
- [x] Context documentation verified
- [x] Ready for review
