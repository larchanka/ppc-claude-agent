# Code Agent for PowerPC Mac

Welcome to the **Code Agent for PowerPC Mac** (`ppc-code-ai-agent`) wiki!

`ppc-code-ai-agent` is a self-contained, interactive terminal AI coding assistant engineered specifically for vintage PowerPC Macintosh computers running **Apple Mac OS X 10.4 (Tiger)** or **10.5 (Leopard)**.

It brings modern agentic coding capabilities—reading files, writing files, targeted line replacements, and running shell commands—to classic Apple hardware (iBook G4, PowerBook G4, PowerMac G4/G5, iMac G4/G5, Mac mini G4) using **Anthropic Claude**, **Google Gemini**, or **local LAN OpenAI-compatible models (Ollama / llama.cpp)**.

---

## Key Highlights

* **Zero CPAN Dependencies**: 100% pure standard Perl 5.8.6. No compiling, no Xcode, and no MacPorts or Homebrew required.
* **Modern TLS 1.2 & 1.3 on Tiger**: Bundles a precompiled PowerPC `curl` binary statically linked against OpenSSL 1.0.2u with the Mozilla CA certificate bundle, bypassing Tiger's outdated system SSL libraries.
* **Pure-Perl JSON Engine (`MiniJSON`)**: Custom built-in recursive descent parser and encoder written in pure Perl.
* **Full-Featured Interactive Line Editor**: Raw terminal mode (`stty raw -echo`) with VT100 ANSI cursor positioning, arrow keys, history recall, line wrapping, and multibyte UTF-8 preservation.
* **Multi-Provider & Fast Switching**: Seamlessly switch between Anthropic Claude, Google Gemini (free tier), and local LAN models without losing conversation context.
* **Safe Autonomous or Manual Execution**: Configurable safety modes (`/auto` vs `/manual`) with interactive `[y/N]` confirmation prompts for all disk writes and command executions.
* **Two-Tone Retro ASCII Art**: Hand-crafted 80-column ANSI terminal banner designed for vintage displays.

---

## Quick Navigation

| Section | Description |
| :--- | :--- |
| **[Installation Guide](Installation-Guide)** | One-click setup via `Install.command`, toolchain deployment, API key configuration, and troubleshooting. |
| **[User Guide & Slash Commands](User-Guide)** | How to use the interactive line editor, keyboard shortcuts, and slash commands (`/help`, `/new`, `/models`, etc.). |
| **[Model Providers](Model-Providers)** | Setting up Google Gemini (free tier), Anthropic Claude, and local OpenAI-compatible endpoints over LAN. |
| **[Tools Reference](Tools-Reference)** | Detailed specifications and parameter references for the 5 built-in agent tools. |
| **[Architecture & Internals](Architecture-&-Internals)** | System design, pure-Perl constraints, `MiniJSON` engine, and manifest assembly pipeline. |
| **[Developer Guide](Developer-Guide)** | Building from source (`build.pl`), test suite (`prove`), GitHub Actions CI, and context graph maintenance. |

---

## Quick Start in 3 Steps

1. **Download & Transfer**: Copy the repository folder onto your PowerPC Mac via USB flash drive or network file sharing.
2. **Install**: Double-click `Install.command` in the Finder and choose your AI provider.
3. **Launch**: Open a Terminal window and type:
   ```bash
   code
   ```
