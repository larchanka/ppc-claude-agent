# User Guide & Slash Commands

This guide covers everyday usage, interactive terminal navigation, keyboard shortcuts, safety modes, and built-in slash commands.

---

## The Startup Screen

When you launch `code` (or `perl code-agent.pl`), you are greeted by the two-tone retro ASCII banner:

```text
   _____          _         ___                    _   
  / ____|        | |       / _ \                  | |  
 | |     ___   __| | ___  / /_\ \ __ _  ___ _ __  | |_ 
 | |    / _ \ / _` |/ _ \ |  _  |/ _` |/ _ \ '_ \ | __|
 | |___| (_) | (_| |  __/ | | | | (_| |  __/ | | || |_ 
  \_____\___/ \__,_|\___| \_| |_/\__, |\___|_| |_| \__|
                                  __/ |                
                                 |___/                 

 [gemini / gemini-3.5-flash-lite]  mode: manual
 Type /help for commands, /models to switch model.

User> █
```

### Visual Styling
* **`Code`**: Displayed in Yellow (`\x1b[33m`).
* **`Agent`**: Displayed in Magenta (`\x1b[35m`).
* **Status line**: Identifies active provider, model, local server host (if OpenAI-compatible), and current tool mode (`manual` or `auto`).
* **`User>`**: Prompts in blue with blinking cursor.

---

## Interactive Terminal Controls

The agent features a pure-Perl raw-mode line editor (`src/terminal.pl`) providing modern editing capabilities on vintage Apple terminals:

| Key / Shortcut | Action |
| :--- | :--- |
| **Left Arrow** / **Right Arrow** | Moves the cursor character-by-character within the input line. |
| **Up Arrow** / **Down Arrow** | Cycles backward and forward through command history. |
| **Ctrl + A** / **Home** | Jumps to the beginning of the line. |
| **Ctrl + E** / **End** | Jumps to the end of the line. |
| **Backspace** | Deletes the character to the left of the cursor. |
| **Delete** / `\e[3~` | Deletes the character directly under the cursor. |
| **Ctrl + K** | Kills (cuts) text from cursor position to end of line. |
| **Ctrl + U** | Clears the entire current line. |
| **Ctrl + C** | Cancels current input and starts a fresh prompt. |
| **Ctrl + D** / `exit` | Exits the agent cleanly. |

### Multibyte UTF-8 & CJK Support
Perl 5.8.6 on OS X Tiger suffered from multibyte buffer truncation in raw `STDIN`. The line editor handles raw bytes explicitly at buffer boundaries, correctly rendering Japanese, Chinese, accented European characters, and Unicode symbols with East Asian double-width calculation.

---

## Safety & Autonomous Execution Modes

Safety is a primary design principle. Code AI Agent operates in two distinct modes:

### Manual Mode (`mode: manual` — Default)
In manual mode, all tools that create side effects require affirmative user confirmation:
* Modifying files (`write_file`, `edit_file`)
* Running shell commands (`run_shell`)

When the model decides to invoke a side-effect tool, an interactive prompt displays the full action and parameter summary:
```text
Run tool: write_file path="src/main.pl" [y/N]?
```
Type `y` to allow execution, or press `Enter` / `n` to reject. Rejection notifies the model that permission was denied, allowing it to adapt gracefully.

### Autonomous Mode (`mode: auto`)
In autonomous mode, the agent executes file writes, file edits, and shell commands without prompting for confirmation.
* Switch to autonomous mode: Type `/auto`
* Switch back to manual mode: Type `/manual`
* Launch directly in auto mode: Set environment variable `CLAUDE_AUTO_MODE=1`

---

## Slash Commands Reference

Slash commands can be entered at the `User>` prompt at any time:

### `/help`
Displays the quick reference of all available slash commands.

### `/new`
Archives the current conversation history and initializes a clean session with an empty context window. Use this when starting an unrelated coding task to save tokens and avoid context pollution.

### `/models`
Opens the interactive terminal model selection menu.
* Fetches all models available on your active provider account.
* Use **Up / Down Arrow** keys to navigate the list, or type a number directly.
* Press **Enter** to switch to the highlighted model.
* Press **Esc** or **Ctrl + C** to cancel.

### `/claude`
Switches the active AI provider to **Anthropic Claude**. If `ANTHROPIC_API_KEY` is not yet saved, it guides you through entering and saving one. The conversation history carries over to the new provider seamlessly.

### `/gemini`
Switches the active AI provider to **Google Gemini**. If `GEMINI_API_KEY` is unset, launches the interactive setup wizard.

### `/openai`
Switches to an **OpenAI-compatible server** running on your local network (e.g. `http://192.168.1.50:8080/v1`). Requires `OPENAI_BASE_URL` to be configured.

### `/auto`
Enables autonomous execution mode (tools run without individual confirmation prompts).

### `/manual`
Enables manual execution mode (tools modifying files or executing shell commands require `[y/N]` confirmation).

### `exit` (or `Ctrl-D`)
Exits the agent and returns to the system shell.
