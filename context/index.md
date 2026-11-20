# Codebase Context & Navigation

This directory provides structured technical documentation about the system architecture, modules, dependencies, and engineering conventions of `ppc-claude-agent`.

## Navigation Map

1. [System Architecture](./architecture.md) — High-level diagrams, core subsystems, request lifecycle, data flow.
2. [Module Catalog](./modules.md) — Breakdown of script components, functions, interfaces, and responsibilities.
3. [Signatures & Symbol Index](./signatures.md) — Complete function and method signatures, argument types, return types, and callers.
4. [Dependencies & Integrations](./dependencies.md) — External dependencies, bundled binaries, network endpoints, and system tools.
5. [Engineering Conventions](./conventions.md) — Idiomatic patterns, Mac OS X 10.4 Tiger compatibility invariants, error handling, terminal UI design.

## Quick Facts
- **Total Source Files**: 2 (`code-agent.pl`, `Install.command`)
- **Primary Languages**: Perl 5.8.6, Bash / POSIX Shell
- **Key Entrypoint**: [`code-agent.pl`](../code-agent.pl)
- **Installer**: [`Install.command`](../Install.command)
- **Target Platform**: Apple Mac OS X 10.4 Tiger (PowerPC G3 / G4 / G5)
