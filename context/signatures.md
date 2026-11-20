# Codebase Signatures & Symbol Index

Quick-reference catalog of function and method signatures, arguments, and return types.

## [`code-agent.pl`](../code-agent.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `get_env_file_path` | `get_env_file_path()` | L39 | 0 |
| `load_env_file` | `load_env_file()` | L49 | 0 |
| `configure_provider` | `configure_provider()` | L93 | 0 |
| `encode` | `encode()` | L192 | 0 |
| `encode_string` | `encode_string()` | L212 | 0 |
| `decode` | `decode()` | L223 | 0 |
| `_skip_ws` | `_skip_ws()` | L230 | 0 |
| `_decode_value` | `_decode_value()` | L235 | 0 |
| `_decode_object` | `_decode_object()` | L252 | 0 |
| `_decode_array` | `_decode_array()` | L274 | 0 |
| `_decode_string` | `_decode_string()` | L292 | 0 |
| `call_api` | `call_api()` | L325 | 0 |
| `quote` | `quote()` | L386 | 0 |
| `build_headers` | `build_headers()` | L397 | 0 |
| `build_request` | `build_request()` | L411 | 0 |
| `build_request_anthropic` | `build_request_anthropic()` | L418 | 0 |
| `build_request_gemini` | `build_request_gemini()` | L429 | 0 |
| `_gemini_thinking_config` | `_gemini_thinking_config()` | L489 | 0 |
| `build_request_openai` | `build_request_openai()` | L501 | 0 |
| `parse_response` | `parse_response()` | L567 | 0 |
| `parse_response_openai` | `parse_response_openai()` | L574 | 0 |
| `parse_response_anthropic` | `parse_response_anthropic()` | L600 | 0 |
| `parse_response_gemini` | `parse_response_gemini()` | L610 | 0 |
| `fetch_models` | `fetch_models()` | L651 | 0 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L683 | 0 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L715 | 0 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L758 | 0 |
| `_normalize_models` | `_normalize_models()` | L804 | 0 |
| `_select_model_nontty` | `_select_model_nontty()` | L821 | 0 |
| `_read_menu_key` | `_read_menu_key()` | L845 | 0 |
| `_render_menu_lines` | `_render_menu_lines()` | L903 | 0 |
| `select_model_interactive` | `select_model_interactive()` | L944 | 0 |
| `get_current_model` | `get_current_model()` | L1063 | 0 |
| `get_current_provider` | `get_current_provider()` | L1067 | 0 |
| `get_current_api_url` | `get_current_api_url()` | L1071 | 0 |
| `get_auto_mode` | `get_auto_mode()` | L1075 | 0 |
| `set_auto_mode` | `set_auto_mode()` | L1079 | 0 |
| `show_help` | `show_help()` | L1085 | 0 |
| `handle_auto_command` | `handle_auto_command()` | L1099 | 0 |
| `handle_manual_command` | `handle_manual_command()` | L1107 | 0 |
| `handle_models_command` | `handle_models_command()` | L1115 | 0 |
| `confirm` | `confirm()` | L1202 | 0 |
| `confirm_tool` | `confirm_tool()` | L1209 | 0 |
| `slow_print` | `slow_print()` | L1220 | 0 |
| `gemini_key_setup` | `gemini_key_setup()` | L1240 | 0 |
| `_validate_gemini_key` | `_validate_gemini_key()` | L1327 | 0 |
| `_maybe_save_gemini_key` | `_maybe_save_gemini_key()` | L1363 | 0 |
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L1401 | 0 |
| `_debug_log` | `_debug_log()` | L1446 | 0 |
| `_utf8_char_len` | `_utf8_char_len()` | L1468 | 0 |
| `_char_width` | `_char_width()` | L1479 | 0 |
| `_display_width_chars` | `_display_width_chars()` | L1492 | 0 |
| `_display_width` | `_display_width()` | L1499 | 0 |
| `_term_size` | `_term_size()` | L1511 | 0 |
| `_query_cursor_row` | `_query_cursor_row()` | L1530 | 0 |
| `_query_cursor_pos` | `_query_cursor_pos()` | L1586 | 0 |
| `_probe_terminal_size` | `_probe_terminal_size()` | L1653 | 0 |
| `_walk_position` | `_walk_position()` | L1694 | 0 |
| `read_line_interactive` | `read_line_interactive()` | L1714 | 0 |
| `run_tool` | `run_tool()` | L2060 | 0 |
