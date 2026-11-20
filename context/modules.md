# Module Catalog

This document details the modules, script architectures, subroutines, and system roles across the repository.

---

## 1. Module: `claude-agent.pl`

### Overview
The primary executable for the PowerPC AI agent. It is a single, self-contained Perl script designed to run on Perl 5.8.6 under Mac OS X 10.4 Tiger without any CPAN dependencies.

### Packages & Namespaces

#### Package `MiniJSON` (Lines 134–270)
A recursive-descent JSON parser and encoder tailored for standard Perl scalars, arrays, and hashes.
- `MiniJSON::encode($value)`: Encodes a Perl reference or scalar into JSON text.
- `MiniJSON::encode_string($str)`: Escapes quotes, backslashes, control characters, and Unicode sequences.
- `MiniJSON::decode($json_text)`: Decodes JSON text into Perl data structures.
- `MiniJSON::_skip_ws($str_ref, $pos_ref)`: Advances index past whitespace.
- `MiniJSON::_decode_value($str_ref, $pos_ref)`: Identifies token type (string, object, array, boolean, number, null).
- `MiniJSON::_decode_object($str_ref, $pos_ref)`: Parses JSON key-value mappings.
- `MiniJSON::_decode_array($str_ref, $pos_ref)`: Parses JSON arrays.
- `MiniJSON::_decode_string($str_ref, $pos_ref)`: Parses escaped JSON strings into Perl strings.

---

### Core Subroutines in `main`

#### Provider Management & Setup
- `configure_provider($provider)`: Configures `$API_KEY`, `$MODEL`, `$API_URL`, and `$ANTHROPIC_VERSION` for `anthropic`, `gemini`, or `openai`.
- `gemini_key_setup()`: Interactive CLI wizard guiding users through setting up a free Google AI Studio key.
- `_validate_gemini_key($key)`: Performs a lightweight test query to verify validity.
- `_maybe_save_gemini_key($key)`: Prompts the user to save credentials to `~/.claude-agent-env`.
- `read_secret_or_cancel($prompt)`: Prompts for sensitive input with echo disabled, supporting cancel via Escape or Ctrl+C.
- `get_current_model()`: Returns active `$MODEL`.
- `get_current_provider()`: Returns active `$PROVIDER`.
- `get_current_api_url()`: Returns active `$API_URL`.

#### Model Discovery & Selection
- `fetch_models($provider)`: Dispatches to provider-specific fetchers and returns normalized `($models_ref, $error)`.
- `_fetch_models_anthropic()`: Queries Anthropic GET `/v1/models?limit=100` and extracts model descriptors.
- `_fetch_models_gemini()`: Queries Gemini GET `/v1beta/models?pageSize=100`, filters for `generateContent` support, and strips `models/` prefix.
- `_fetch_models_openai()`: Queries OpenAI-compatible GET `<base>/models` and extracts IDs.
- `_normalize_models($models_ref)`: Normalizes model array into uniform `[{ id => "...", display => "..." }]` structures.
- `select_model_interactive($models_ref, $current_model, $in_fh, $out_fh)`: Interactive full-terminal or non-TTY fallback selector with arrow keys, direct numeric typing, Enter to confirm, and Esc/Ctrl+C to cancel.
- `_select_model_nontty($models_ref, $current_model, $in_fh, $out_fh)`: Numbered model selector fallback for non-interactive or piped streams.
- `_read_menu_key($in_fh)`: Reads single keypress in raw mode with 50ms escape sequence disambiguation (Esc vs Arrow keys).
- `_render_menu_lines($models, $cursor, $window_start, $page_size, $current_model, $num_buf)`: Formats paginated windowed model list and status line for terminal rendering.
- `handle_models_command($in_fh, $out_fh)`: Command handler for `/models` slash command, coordinating fetch, selection, and model switching.
- `show_help($out_fh)`: Displays available slash commands and descriptions.

#### Request & Response Construction
- `build_headers()`: Returns array of HTTP headers tailored to current provider (e.g. `x-api-key`, `anthropic-version`, `x-goog-api-key`, `Authorization`).
- `build_request($messages_ref, $tools_ref, $system_prompt)`: Dispatches to provider-specific request builder.
- `build_request_anthropic($messages_ref, $tools_ref, $system)`: Translates conversation history into Anthropic Messages API v1 format.
- `build_request_gemini($messages_ref, $tools_ref, $system)`: Translates history and tool declarations into Google Gemini `generateContent` format.
- `_gemini_thinking_config()`: Configures reasoning budget / thinking level for Gemini 3.x models.
- `build_request_openai($messages_ref, $tools_ref, $system)`: Formats request for OpenAI-compatible chat completions endpoints.
- `parse_response($response_json)`: Decodes provider response into uniform text or tool-call structures.
- `parse_response_anthropic($data)`: Extracts text and `tool_use` blocks from Anthropic API responses.
- `parse_response_gemini($data)`: Extracts text candidates and `functionCall` items from Gemini responses.
- `parse_response_openai($data)`: Extracts messages and `tool_calls` from OpenAI responses.

#### Interactive Terminal Engine & ANSI Helpers
- `read_line_interactive($prompt)`: Full raw-mode terminal reader with ANSI line editing, history, wrapping, and multibyte UTF-8 handling.
- `_probe_terminal_size()`: Determines column and row bounds using ioctl or escape sequences.
- `_term_size()`: Fallback terminal dimension detector.
- `_query_cursor_pos()` / `_query_cursor_row()`: Issues VT100 DSR `\e[6n` query to track actual cursor location.
- `_walk_position($text, $cols)`: Simulates cursor wrap mechanics across terminal columns.
- `_char_width($codepoint)`: East Asian Width calculation for proper double-width character layout.
- `_display_width($str)` / `_display_width_chars(@chars)`: Calculates visual column footprint of strings.
- `_utf8_char_len($byte)`: Inspects leading UTF-8 byte to determine expected continuation length.

#### Network & Tool Execution
- `call_api($url, $headers_ref, $body_json, $method)`: Executes bundled `curl` with SSL certificate bundle for POST or GET requests and returns HTTP response body.
- `confirm($prompt)`: Displays a `[y/N]` prompt requiring affirmative user consent before executing side effects.
- `slow_print($text)`: Prints output with simulated typewriter delay for vintage terminal ambiance.
- `run_tool($name, $input)`: Executes requested agent tools (`read_file`, `write_file`, `list_dir`, `run_shell`).

---

## 2. Module: `Install.command`

### Overview
A standalone Bash script providing one-click installation on Mac OS X 10.4 Tiger.

### Key Operations
1. **Toolchain Installation**: Copies `curl` to `$HOME/claude-toolchain/bin/curl` and sets executable permissions.
2. **Runtime Deployment**: Copies `claude-agent.pl` and `cacert.pem` to `$HOME/claude-build/`.
3. **Curl Verification**: Executes `curl --version` to verify PowerPC CPU and kernel compatibility.
4. **Interactive Provider Selection**: Guides user to choose Anthropic or Gemini, prompts for API key without echo, and writes `~/.claude-agent-env` with permissions `0600`.
5. **Launcher Wrapper**: Generates `$HOME/bin/code`, which sources the environment and launches `claude-agent.pl`.
6. **Path Configuration**: Updates `$HOME/.bash_profile` with `$HOME/bin` if not already present.
7. **End-to-End Connectivity Verification**: Makes a test HTTP request to verify API keys and network connectivity before concluding setup.

---

## 3. Supplementary Assets

| File | Purpose |
| :--- | :--- |
| [`curl`](../curl) | PowerPC Darwin executable, statically linked against OpenSSL 1.0.2u supporting TLS 1.2 and 1.3 |
| [`cacert.pem`](../cacert.pem) | Mozilla CA certificate bundle required for HTTPS verification |
| [`README.txt`](../README.txt) | Plain-text end-user guide for setup and requirements |
