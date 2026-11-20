# Tasks: Modular Assembly of code-agent.pl

## Phase 1: Build Tooling & Harness
- [x] Task 1: Create `build.pl` Build Script
  - [x] Implement manifest-driven module concatenation in pure Perl 5.8.6
  - [x] Add atomic write and executable permission (`chmod 0755`)
  - [x] Add automatic syntax check (`$^X -c code-agent.pl`)
  - [x] Verify syntax: `perl -c build.pl`
- [x] Task 2: Create Build Script Unit Test `t/build.t`
  - [x] Test build execution and exit code
  - [x] Test file generation and executable permissions
  - [x] Test syntax verification
  - [x] Test error reporting for missing or corrupt files
  - [x] Verify: `prove -v t/build.t`

## Checkpoint: Foundation
- [x] `build.pl` and `t/build.t` operational

## Phase 2: Source File Decomposition (`src/*.pl`)
- [x] Task 3: Extract `src/header.pl`, `src/json.pl`, and `src/transport.pl`
  - [x] Create `src/` directory
  - [x] Extract `src/header.pl` (pragmas, constants, colors, cursor, env helpers, globals, `configure_provider`, `$SYSTEM_PROMPT`)
  - [x] Extract `src/json.pl` (`package MiniJSON;` parser & encoder, resetting to `package main;`)
  - [x] Extract `src/transport.pl` (`call_api`, `quote`)
- [x] Task 4: Extract `src/providers.pl` and `src/models_menu.pl`
  - [x] Extract `src/providers.pl` (headers, request builders, response parsers, model discovery)
  - [x] Extract `src/models_menu.pl` (`_normalize_models`, `_select_model_nontty`, `_read_menu_key`, `_render_menu_lines`, `select_model_interactive`, `our $FORCE_RAW`)
- [x] Task 5: Extract `src/session.pl` and `src/tools.pl`
  - [x] Extract `src/session.pl` (session management, slash command handlers)
  - [x] Extract `src/tools.pl` (`@TOOLS`, confirmation helpers, Gemini setup helpers, `run_tool`)
- [x] Task 6: Extract `src/terminal.pl`, `src/ui.pl`, and `src/main.pl`
  - [x] Extract `src/terminal.pl` (scoped readline, ANSI measurement, history)
  - [x] Extract `src/ui.pl` (basename extraction, text truncation, tool call & thinking formatting)
  - [x] Extract `src/main.pl` (unified `unless (caller)` entrypoint, banner, REPL loop, exit, `1;`)
- [x] Task 7: Assemble `code-agent.pl` via `build.pl` and Verify Zero Test Regressions
  - [x] Run `perl build.pl` to build `code-agent.pl`
  - [x] Verify `perl -c code-agent.pl`
  - [x] Run full test suite: `prove -v t/*.t` (all tests pass)

## Checkpoint: Assembly & Regressions
- [x] `code-agent.pl` builds cleanly from `src/*.pl`
- [x] All 11 test files pass with 0 regressions

## Phase 3: Installer Integration, Documentation & Symbol Graph
- [x] Task 8: Integrate Build Step into `Install.command`
  - [x] Add check for `build.pl` and `src/` directory
  - [x] Run `perl build.pl` during installation if present
  - [x] Verify shell syntax with `bash -n Install.command`
- [x] Task 9: Update Documentation (`AGENTS.md`, `README.md`, `README.txt`)
  - [x] Document `src/` modular layout and `build.pl` in `AGENTS.md`
  - [x] Document build command in `README.md` and `README.txt`
- [x] Task 10: Refresh Symbol Graphs and Context Documentation
  - [x] Run `ast_scanner.py`
  - [x] Run `dependency_graph.py`
  - [x] Run `symbol_graph.py`
  - [x] Verify context integrity with `verify_context.py`

## Checkpoint: Complete
- [x] All tasks completed and verified
- [x] All 11 test files in `t/*.t` pass
- [x] Documentation and symbol graphs synchronized
