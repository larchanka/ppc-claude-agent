# Task List: AGENTS.md Context Integration

## Phase 1: Core Implementation & Integration
- [x] Task 1: Implement AGENTS.md Context Helpers in `src/header.pl`
  - [x] Implement `read_agents_file($path)` with UTF-8 decoding and safe file handling
  - [x] Implement `get_agents_context($home_dir, $cwd)` with global & local file discovery and inode deduplication
  - [x] Implement `get_effective_system_prompt($base_prompt, $home_dir, $cwd)`
  - [x] Verify syntax of `src/header.pl`
- [x] Task 2: Integrate Dynamic System Prompt in `src/main.pl` and Build Standalone Artifact
  - [x] Update `src/main.pl` to pass `get_effective_system_prompt()` to `build_request`
  - [x] Run `perl build.pl` to re-generate `code-agent.pl`
  - [x] Run `perl build.pl --check` to verify artifact synchronization
  - [x] Verify syntax of `code-agent.pl` via `perl -c code-agent.pl`

## Checkpoint: Core Integration
- [x] Verify existing test suite passes: `prove t/*.t`

## Phase 2: Comprehensive Test Suite & Context Verification
- [x] Task 3: Create Automated Unit Test Suite `t/agents_context.t`
  - [x] Write unit tests for missing files, global-only, local-only, both, deduplication, and whitespace handling
  - [x] Test integration with `build_request`
  - [x] Run `prove -v t/agents_context.t`
  - [x] Run full test suite: `prove t/*.t`
- [x] Task 4: Post-Change Context & Symbol Graph Maintenance
  - [x] Run AST scanner (`ast_scanner.py`)
  - [x] Update dependency graph (`dependency_graph.py`)
  - [x] Update symbol graph & signatures (`symbol_graph.py`)
  - [x] Run context verification (`verify_context.py`)

## Checkpoint: Complete
- [x] All unit and regression tests pass
- [x] Context documentation and symbol graphs verified
