# Tools Reference

`ppc-code-ai-agent` equips the AI with five core tools to inspect, modify, and manage files and execute commands within your workspace.

All tools are defined in pure Perl with strict JSON Schema definitions exposed to Claude, Gemini, and OpenAI backends.

---

## 1. `read_file`

Reads file contents in UTF-8. Supports optional line-slicing parameters to navigate large codebases efficiently on vintage machines without exhausting memory.

### Parameters
* **`path`** *(string, required)*: The relative or absolute file path to read.
* **`start_line`** *(integer, optional)*: 1-based line number to begin reading from (inclusive).
* **`end_line`** *(integer, optional)*: 1-based line number to stop reading at (inclusive).

### Behavior
* If `start_line` and `end_line` are omitted, the entire file is read.
* Line indices are automatically clamped to file bounds (`1 <= start_line <= end_line <= total_lines`).
* If `start_line > total_lines`, returns an informative out-of-range message rather than crashing.

---

## 2. `write_file`

Creates a new file or completely overwrites an existing file with the provided content.

### Parameters
* **`path`** *(string, required)*: The file path to write.
* **`content`** *(string, required)*: Full content string to write into the file.

### Safety Behavior
* Subject to `confirm_tool()` permission checks when in `manual` mode.
* Automatically creates parent directories if they do not exist.

---

## 3. `edit_file`

Performs targeted multi-line replacements inside an existing file without rewriting the entire file. This is crucial for vintage PowerPC systems where saving large files repeatedly degrades disk performance.

### Parameters
* **`path`** *(string, required)*: The file path to edit.
* **`start_line`** *(integer, required)*: 1-based starting line of the block to replace.
* **`end_line`** *(integer, required)*: 1-based ending line of the block to replace.
* **`content`** *(string, required)*: The replacement string.

### Supported Edit Operations
1. **Replace Lines**: Set `start_line` and `end_line` to the range to replace, and pass new `content`.
2. **Insert Lines**: To insert lines before line `N` without deleting existing lines, set `start_line = N` and `end_line = N - 1`.
3. **Delete Lines**: To delete lines between `start_line` and `end_line`, provide an empty string `""` as `content`.

### Safety Behavior
* Fails with a descriptive error if `path` does not exist.
* Subject to `confirm_tool()` confirmation when in `manual` mode.

---

## 4. `list_dir`

Lists entries within a directory, appending a trailing slash `/` to directories.

### Parameters
* **`path`** *(string, optional)*: Directory path to inspect (defaults to current working directory `.` if omitted).

### Output
Returns a sorted list of filenames and subdirectories. Hidden files (starting with `.`) are included.

---

## 5. `run_shell`

Executes a command line in a POSIX subshell and captures its combined standard output and error.

### Parameters
* **`command`** *(string, required)*: The command string to execute (e.g. `make test`, `git status`, `perl build.pl`).

### Execution Constraints & Safety
* Executes via `/bin/sh` with captured stdout and stderr.
* Gated behind `confirm_tool()` in `manual` mode displaying the full command string for user consent.
* Includes execution timeout safeguards to prevent hanging processes from freezing the agent loop.
