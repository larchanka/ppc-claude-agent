# Dependencies & Ecosystem

This document inventories internal module relationships, system toolchains, bundled binaries, and external network APIs.

---

## Internal Dependency Graph

- **Application Entrypoint**:
  - [`claude-agent.pl`](../claude-agent.pl): Standalone agent. Invokes `curl` via shell/exec for HTTPS operations.
- **Installer Entrypoint**:
  - [`Install.command`](../Install.command): Copies and provisions `claude-agent.pl`, `curl`, and `cacert.pem` into `$HOME/claude-toolchain` and `$HOME/claude-build`.
- **Generated Wrapper**:
  - `$HOME/bin/code`: Sourced shell wrapper pointing to `$HOME/.claude-agent-env`, `$HOME/claude-toolchain/bin/curl`, and `$HOME/claude-build/claude-agent.pl`.

---

## Third-Party Libraries & Bundled Assets

| Asset / Library | Type | Purpose | Key Usage Files |
| :--- | :--- | :--- | :--- |
| [`curl`](../curl) | Prebuilt PPC Darwin binary | TLS 1.2/1.3-capable HTTPS transport (statically linked against OpenSSL 1.0.2u) | [`Install.command`](../Install.command), [`claude-agent.pl`](../claude-agent.pl) |
| [`cacert.pem`](../cacert.pem) | CA Cert Bundle | Mozilla root certificates for verifying TLS certificates | [`Install.command`](../Install.command), [`claude-agent.pl`](../claude-agent.pl) |
| `Encode` | Perl Core Module | Character set conversion (UTF-8) with fallback handling (`FB_DEFAULT`) | [`claude-agent.pl`](../claude-agent.pl) |
| `stty` | Mac OS X System Utility | Terminal line discipline configuration (raw mode, echo toggling) | [`claude-agent.pl`](../claude-agent.pl), [`Install.command`](../Install.command) |

---

## External Services & Network APIs

| Endpoint | Protocol | Provider | Purpose |
| :--- | :--- | :--- | :--- |
| `https://api.anthropic.com/v1/messages` | HTTPS (TLS 1.2/1.3) | Anthropic | Claude 3.5 Sonnet / Claude Sonnet 4.5 LLM chat completions and tool calls |
| `https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent` | HTTPS (TLS 1.2/1.3) | Google | Gemini models (`gemini-3.5-flash-lite`, etc.) chat and tool use |
| `http://{LAN_HOST}:{PORT}/v1/chat/completions` | HTTP/HTTPS | Local / Self-Hosted | OpenAI-compatible local LLM endpoints (Ollama, llama.cpp, LM Studio) |
