# Codebase Signatures & Symbol Index

Quick-reference catalog of function and method signatures, arguments, and return types.

## [`code-agent.pl`](../code-agent.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `get_env_file_path` | `get_env_file_path()` | L39 | 0 |
| `load_env_file` | `load_env_file()` | L49 | 0 |
| `configure_provider` | `configure_provider()` | L91 | 0 |
| `encode` | `encode()` | L190 | 0 |
| `encode_string` | `encode_string()` | L210 | 0 |
| `decode` | `decode()` | L221 | 0 |
| `_skip_ws` | `_skip_ws()` | L228 | 0 |
| `_decode_value` | `_decode_value()` | L233 | 0 |
| `_decode_object` | `_decode_object()` | L250 | 0 |
| `_decode_array` | `_decode_array()` | L272 | 0 |
| `_decode_string` | `_decode_string()` | L290 | 0 |
| `call_api` | `call_api()` | L323 | 0 |
| `quote` | `quote()` | L384 | 0 |
| `build_headers` | `build_headers()` | L395 | 0 |
| `build_request` | `build_request()` | L409 | 0 |
| `build_request_anthropic` | `build_request_anthropic()` | L416 | 0 |
| `build_request_gemini` | `build_request_gemini()` | L427 | 0 |
| `_gemini_thinking_config` | `_gemini_thinking_config()` | L487 | 0 |
| `build_request_openai` | `build_request_openai()` | L499 | 0 |
| `parse_response` | `parse_response()` | L565 | 0 |
| `parse_response_openai` | `parse_response_openai()` | L572 | 0 |
| `parse_response_anthropic` | `parse_response_anthropic()` | L598 | 0 |
| `parse_response_gemini` | `parse_response_gemini()` | L608 | 0 |
| `fetch_models` | `fetch_models()` | L649 | 0 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L681 | 0 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L713 | 0 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L756 | 0 |
| `_normalize_models` | `_normalize_models()` | L802 | 0 |
| `_select_model_nontty` | `_select_model_nontty()` | L819 | 0 |
| `_read_menu_key` | `_read_menu_key()` | L843 | 0 |
| `_render_menu_lines` | `_render_menu_lines()` | L901 | 0 |
| `select_model_interactive` | `select_model_interactive()` | L942 | 0 |
| `get_current_model` | `get_current_model()` | L1061 | 0 |
| `get_current_provider` | `get_current_provider()` | L1065 | 0 |
| `get_current_api_url` | `get_current_api_url()` | L1069 | 0 |
| `get_auto_mode` | `get_auto_mode()` | L1073 | 0 |
| `set_auto_mode` | `set_auto_mode()` | L1077 | 0 |
| `show_help` | `show_help()` | L1083 | 0 |
| `handle_auto_command` | `handle_auto_command()` | L1097 | 0 |
| `handle_manual_command` | `handle_manual_command()` | L1105 | 0 |
| `handle_models_command` | `handle_models_command()` | L1113 | 0 |
| `confirm` | `confirm()` | L1200 | 0 |
| `confirm_tool` | `confirm_tool()` | L1207 | 0 |
| `slow_print` | `slow_print()` | L1218 | 0 |
| `gemini_key_setup` | `gemini_key_setup()` | L1238 | 0 |
| `_validate_gemini_key` | `_validate_gemini_key()` | L1325 | 0 |
| `_maybe_save_gemini_key` | `_maybe_save_gemini_key()` | L1361 | 0 |
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L1399 | 0 |
| `_debug_log` | `_debug_log()` | L1444 | 0 |
| `_utf8_char_len` | `_utf8_char_len()` | L1466 | 0 |
| `_char_width` | `_char_width()` | L1477 | 0 |
| `_display_width_chars` | `_display_width_chars()` | L1490 | 0 |
| `_display_width` | `_display_width()` | L1497 | 0 |
| `_term_size` | `_term_size()` | L1509 | 0 |
| `_query_cursor_row` | `_query_cursor_row()` | L1528 | 0 |
| `_query_cursor_pos` | `_query_cursor_pos()` | L1584 | 0 |
| `_probe_terminal_size` | `_probe_terminal_size()` | L1651 | 0 |
| `_walk_position` | `_walk_position()` | L1692 | 0 |
| `read_line_interactive` | `read_line_interactive()` | L1712 | 0 |
| `run_tool` | `run_tool()` | L2058 | 0 |
