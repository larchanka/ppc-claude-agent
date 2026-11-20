# Installation Guide

Setting up `ppc-code-ai-agent` on your vintage PowerPC Mac requires no compilation, no Xcode, and no package managers.

---

## System Requirements

* **Hardware**: PowerPC G3, G4, or G5 Mac (e.g. iBook, PowerBook, PowerMac, iMac, eMac, Mac mini).
* **Operating System**: Mac OS X 10.4.11 (Tiger) or Mac OS X 10.5.8 (Leopard).
* **Perl**: Perl 5.8.6 or newer (standard stock installation on OS X Tiger and Leopard).
* **Terminal**: Built-in Apple `Terminal.app` or any VT100-compatible terminal emulator.

---

## Method 1: Interactive Installation (Recommended)

The easiest method is running the interactive installer script.

1. **Transfer the Repository**:
   Copy the folder onto your PowerPC Mac (via USB drive, AFP / SMB file sharing, or FTP).
2. **Launch the Installer**:
   Double-click **`Install.command`** in the Finder (or run `./Install.command` in a Terminal window).
3. **What `Install.command` Does Automatically**:
   * Creates `$HOME/code-toolchain/bin` and installs the prebuilt TLS 1.2/1.3 `curl`.
   * Verifies that the bundled `curl` executes cleanly on your Mac's CPU.
   * Compiles `code-agent.pl` from `src/*.pl` using `build.pl`.
   * Installs the Mozilla root certificate bundle (`cacert.pem`) to `$HOME/code-build/src/`.
   * Prompts you to choose your primary AI provider (**Google Gemini** or **Anthropic Claude**).
   * Prompts for your API key (pasting without terminal echo) and writes it securely to `$HOME/.code-agent-env` with `chmod 0600` permissions.
   * Creates a launcher executable at `$HOME/bin/code`.
   * Adds `$HOME/bin` to your `$PATH` in `~/.bash_profile`.
   * Executes a live verification probe against the selected API to confirm connectivity before completing setup.
4. **Start the Agent**:
   Open a **new** Terminal window (to reload `$PATH`) and type:
   ```bash
   code
   ```

---

## Method 2: Manual / CLI Setup

If you prefer to configure your environment manually without running the interactive installer:

1. **Build the Standalone Script**:
   From the repository root, run:
   ```bash
   perl build.pl
   ```
2. **Configure Environment Variables**:
   Export your preferred provider and API key in your shell profile (e.g. `~/.bash_profile`):

   **For Google Gemini (Free tier):**
   ```bash
   export GEMINI_API_KEY="AIzaSy..."
   export CLAUDE_PROVIDER="gemini"
   export CLAUDE_CURL="/path/to/curl"
   export CLAUDE_CACERT="/path/to/cacert.pem"
   ```

   **For Anthropic Claude:**
   ```bash
   export ANTHROPIC_API_KEY="sk-ant-..."
   export CLAUDE_PROVIDER="anthropic"
   export CLAUDE_CURL="/path/to/curl"
   export CLAUDE_CACERT="/path/to/cacert.pem"
   ```

   **For Local OpenAI / LAN Models (e.g. Ollama / llama.cpp):**
   ```bash
   export OPENAI_BASE_URL="http://192.168.1.50:8080/v1"
   export CLAUDE_PROVIDER="openai"
   export CLAUDE_MODEL="llama3"
   export CLAUDE_CURL="/path/to/curl"
   export CLAUDE_CACERT="/path/to/cacert.pem"
   ```

3. **Launch Directly**:
   ```bash
   perl code-agent.pl
   ```

---

## Troubleshooting

### "The prebuilt curl did not run on this machine"
The bundled `curl` binary was compiled specifically for PowerPC Darwin on Mac OS X 10.4 Tiger. If your processor or kernel fails to execute it:
* Ensure you are running on a PowerPC G3/G4/G5 system.
* You can supply any custom TLS 1.2+ capable `curl` binary by pointing `CLAUDE_CURL=/path/to/your/curl`.

### "SSL certificate problem: unable to get local issuer certificate"
Modern HTTPS APIs require TLS certificate verification:
* Ensure `cacert.pem` exists in the expected path.
* Set `export CLAUDE_CACERT="/path/to/cacert.pem"` to specify the path explicitly.

### Changing Stored API Keys
Your credentials are saved in `~/.code-agent-env`:
* To view or edit: `nano ~/.code-agent-env`
* To re-run the setup wizard: `rm ~/.code-agent-env && ./Install.command`
