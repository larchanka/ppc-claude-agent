# Model Providers

`ppc-code-ai-agent` supports three provider backends. You can switch between them on the fly using `/claude`, `/gemini`, and `/openai`, carrying your active conversation context over.

---

## 1. Google Gemini (Default & Free Tier)

Google Gemini offers generous free-tier quotas with zero credit card required, making it the ideal out-of-the-box provider for vintage Mac users.

### How to Get a Free API Key
1. Visit [Google AI Studio](https://ai.google.dev/gemini-api/docs/api-key).
2. Sign in with any Google account.
3. Click **"Get a Gemini API key"** / **"Create API key"**.
4. Copy the resulting key (starts with `AIzaSy...`).

### Interactive Terminal Setup Wizard
If launched without `GEMINI_API_KEY` set, the agent automatically displays a step-by-step setup guide:
* Prompts if you would like to open the browser page automatically (`open https://ai.google.dev/...`).
* Prompts you to paste the key without terminal echoing.
* Tests the key live with a real API probe.
* Prompts to save it into `~/.code-agent-env`.

### Supported Gemini Models
* `gemini-3.5-flash-lite` (Default: ultra-fast, lightweight token usage)
* `gemini-2.5-flash`
* `gemini-2.5-pro`
* Any custom or experimental model discoverable via the `/models` command.

### Extended Thinking / Reasoning
For Gemini 2.5 and 3.x models that support reasoning, the agent automatically configures a thinking budget and streams real-time elapsed thinking status to the terminal:
```text
Thinking... (4s)
```
Once reasoning concludes, it displays the final duration and outputs the response.

---

## 2. Anthropic Claude

Anthropic's Claude models provide state-of-the-art coding and architectural reasoning.

### How to Set Up
1. Sign up at [Anthropic Console](https://console.anthropic.com/).
2. Generate an API key starting with `sk-ant-...`.
3. Set your key:
   ```bash
   export ANTHROPIC_API_KEY="sk-ant-api03-..."
   export CLAUDE_PROVIDER="anthropic"
   ```
   Or switch inside the agent by typing `/claude`.

### Supported Anthropic Models
* `claude-sonnet-4-5-20250929` (Default: exceptional coding capability)
* `claude-3-5-haiku-20241022` (High speed, low latency)
* `claude-3-opus-20240229`
* Any model returned dynamically by GET `/v1/models`.

### Protocol Integration
Uses Anthropic Messages API v1 with structured `tool_use` blocks and system prompt injection.

---

## 3. Local OpenAI-Compatible Endpoints (Ollama / llama.cpp / LM Studio)

Because vintage PowerPC processors cannot run modern 8B–70B LLMs locally, you can run a local LLM on a modern machine (Mac, Linux, or PC) on your local home network (LAN) and connect your PowerPC Mac to it completely offline without internet access.

### Supported Local Backends
* **Ollama**: `http://192.168.1.50:11434/v1`
* **llama.cpp server**: `http://192.168.1.50:8080/v1`
* **LM Studio**: `http://192.168.1.50:1234/v1`
* **vLLM / LocalAI**

### Configuration
Set the base URL and switch provider:
```bash
export OPENAI_BASE_URL="http://192.168.1.50:8080/v1"
export CLAUDE_PROVIDER="openai"
export CLAUDE_MODEL="qwen2.5-coder:7b"
```
Or switch during an interactive session by typing `/openai`.

The startup banner and status line will explicitly show your local endpoint host:
```text
 [openai / qwen2.5-coder:7b @ 192.168.1.50:8080]  mode: manual
```

---

## Switching Models & Providers at Runtime

You can switch models and providers at any point in a session:
* Type `/models` to open the terminal menu and pick another model.
* Type `/claude`, `/gemini`, or `/openai` to change provider.
* **Context Preservation**: The conversation history so far is preserved and translated into the new provider's schema on the next turn.
