# Agent Instructions & Codebase Guidelines

Welcome to `ppc-claude-agent`. This file provides essential guidelines, architecture overview, verified commands, and operating constraints for AI agents and automated tools working in this repository.

---

## 1. Project Overview
- **Repository Purpose**: Self-contained terminal AI agent designed for vintage PowerPC Macs running Mac OS X 10.4 (Tiger). It enables interactive chat and agentic tool usage (reading/writing files, executing shell commands) via Anthropic Claude, Google Gemini, or local OpenAI-compatible endpoints with zero CPAN dependencies.
- **Core Languages & Frameworks**: Perl 5.8.6 (pure Perl standard library only, no external modules), Bash / POSIX shell.
- **Primary Runtime / Environment**: Mac OS X 10.4 Tiger (PowerPC G3/G4/G5), Perl >= 5.8.6, bundled TLS 1.2/1.3 `curl` binary with OpenSSL 1.0.2u.

---

## 2. Essential Commands & Workflow

> [!IMPORTANT]
> Run all commands from the repository root unless explicitly noted.

### Build & Setup
```bash
# Verify Perl syntax of the standalone agent script
perl -c claude-agent.pl

# Run installation workflow (Finder double-click or CLI)
./Install.command
```

### Execution & Running
```bash
# Direct execution (with Anthropic API)
export ANTHROPIC_API_KEY="sk-ant-..."
export CLAUDE_PROVIDER="anthropic"
perl claude-agent.pl

# Direct execution (with Gemini API)
export GEMINI_API_KEY="AIzaSy..."
export CLAUDE_PROVIDER="gemini"
perl claude-agent.pl

# Execution with custom toolchain curl & cacert
export CLAUDE_CURL="./curl"
export CLAUDE_CACERT="./cacert.pem"
perl claude-agent.pl
```

### Verification & Testing
```bash
# Perl syntax check
perl -c claude-agent.pl

# Verify context documentation integrity
python3 /Users/mikhaillarchanka/.gemini/config/skills/codebase-context-generator/scripts/verify_context.py --root .
```

---

## 3. Architecture & Context Navigation

For in-depth architectural details, refer to the documentation in the [`context/`](./context/) directory:

- [**context/index.md**](./context/index.md): Documentation map and quick index.
- [**context/architecture.md**](./context/architecture.md): High-level system design, subsystem relationships, and data flows.
- [**context/modules.md**](./context/modules.md): Complete module catalog with public interfaces and responsibilities.
- [**context/signatures.md**](./context/signatures.md): Searchable index of all function signatures, parameters, and return types.
- [**context/dependencies.md**](./context/dependencies.md): Internal call graphs and third-party dependencies.
- [**context/conventions.md**](./context/conventions.md): Code style, error handling patterns, and test standards.

### Key Entry Points & Core Components
| Component / File | Role | Type |
| :--- | :--- | :--- |
| [`claude-agent.pl`](./claude-agent.pl) | Standalone interactive CLI agent loop, JSON engine, API adapters, and tool executors | Entrypoint / Core |
| [`Install.command`](./Install.command) | Interactive setup script for Finder and terminal, toolchain deployment, API key configuration | Installer Entrypoint |
| [`curl`](./curl) | Prebuilt TLS 1.2/1.3 PowerPC Tiger curl binary | Binary Utility |
| [`cacert.pem`](./cacert.pem) | Mozilla root certificate bundle for TLS verification | Security Asset |
| [`README.txt`](./README.txt) | User installation and operational manual | Documentation |

---

## 4. Agent Rules & Operational Constraints

Follow these rules on every task:

1. **Zero External Perl Dependencies**: `claude-agent.pl` MUST remain 100% self-contained in standard Perl 5.8.6. Never introduce `cpan` dependencies or modern modules (e.g., `JSON::XS`, `LWP::UserAgent`, `Mojo::*`).
2. **Mac OS X 10.4 Tiger Compatibility**: Do not use Perl features newer than 5.8.6 (avoid `state` variables, `say`, defined-or `//`, named regex captures, modern unicode properties).
3. **Surgical Changes**: Touch only lines necessary for requested features or fixes. Do not reformat unrelated subroutines or comments.
4. **Preserve Raw STDIN / UTF-8 Separation**: Keep STDIN as raw bytes to prevent multibyte boundary corruption in Perl 5.8.6 PerlIO. Decode explicitly at line or buffer boundaries.
5. **Preserve User Confirmations on Side Effects**: All filesystem modifications (`write_file`) and command executions (`run_shell`) MUST prompt the user for confirmation via `confirm()`.

---

## 5. Automatic Context & Graph Maintenance (Post-Change Instruction)

> [!IMPORTANT]
> **Always Keep Context & Symbol Graphs In Sync**:
> If any code was created, modified, or deleted during your task, you MUST refresh the symbol graph and context artifacts.

Run the following update sequence:

```bash
# 1. Rescan AST and update symbol/call graphs
python3 /Users/mikhaillarchanka/.gemini/config/skills/codebase-context-generator/scripts/ast_scanner.py --root .
python3 /Users/mikhaillarchanka/.gemini/config/skills/codebase-context-generator/scripts/dependency_graph.py --manifest .context_cache/ast_manifest.json
python3 /Users/mikhaillarchanka/.gemini/config/skills/codebase-context-generator/scripts/symbol_graph.py \
  --manifest .context_cache/ast_manifest.json \
  --save-graph .context_cache/symbol_graph.json \
  --export-signatures context/signatures.md

# 2. Verify documentation integrity
python3 /Users/mikhaillarchanka/.gemini/config/skills/codebase-context-generator/scripts/verify_context.py --root .
```
