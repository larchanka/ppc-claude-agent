# Codebase Signatures & Symbol Index

Quick-reference catalog of function and method signatures, arguments, and return types.

## [`code-agent.pl`](../code-agent.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `get_env_file_path` | `get_env_file_path()` | L39 | 0 |
| `load_env_file` | `load_env_file()` | L49 | 0 |
| `configure_provider` | `configure_provider()` | L95 | 0 |
| `encode` | `encode()` | L194 | 0 |
| `encode_string` | `encode_string()` | L214 | 0 |
| `decode` | `decode()` | L225 | 0 |
| `_skip_ws` | `_skip_ws()` | L232 | 0 |
| `_decode_value` | `_decode_value()` | L237 | 0 |
| `_decode_object` | `_decode_object()` | L254 | 0 |
| `_decode_array` | `_decode_array()` | L276 | 0 |
| `_decode_string` | `_decode_string()` | L294 | 0 |
| `call_api` | `call_api()` | L327 | 0 |
| `quote` | `quote()` | L388 | 0 |
| `build_headers` | `build_headers()` | L399 | 0 |
| `build_request` | `build_request()` | L413 | 0 |
| `build_request_anthropic` | `build_request_anthropic()` | L420 | 0 |
| `build_request_gemini` | `build_request_gemini()` | L431 | 0 |
| `_gemini_thinking_config` | `_gemini_thinking_config()` | L491 | 0 |
| `build_request_openai` | `build_request_openai()` | L503 | 0 |
| `parse_response` | `parse_response()` | L569 | 0 |
| `parse_response_openai` | `parse_response_openai()` | L576 | 0 |
| `parse_response_anthropic` | `parse_response_anthropic()` | L602 | 0 |
| `parse_response_gemini` | `parse_response_gemini()` | L612 | 0 |
| `fetch_models` | `fetch_models()` | L653 | 0 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L685 | 0 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L717 | 0 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L760 | 0 |
| `_normalize_models` | `_normalize_models()` | L806 | 0 |
| `_select_model_nontty` | `_select_model_nontty()` | L823 | 0 |
| `_read_menu_key` | `_read_menu_key()` | L847 | 0 |
| `_render_menu_lines` | `_render_menu_lines()` | L905 | 0 |
| `select_model_interactive` | `select_model_interactive()` | L946 | 0 |
| `get_current_model` | `get_current_model()` | L1065 | 0 |
| `get_current_provider` | `get_current_provider()` | L1069 | 0 |
| `get_current_api_url` | `get_current_api_url()` | L1073 | 0 |
| `get_auto_mode` | `get_auto_mode()` | L1077 | 0 |
| `set_auto_mode` | `set_auto_mode()` | L1081 | 0 |
| `generate_session_id` | `generate_session_id()` | L1087 | 0 |
| `init_session` | `init_session()` | L1094 | 0 |
| `get_current_session` | `get_current_session()` | L1107 | 0 |
| `archive_session` | `archive_session()` | L1112 | 0 |
| `handle_new_command` | `handle_new_command()` | L1121 | 0 |
| `show_help` | `show_help()` | L1133 | 0 |
| `handle_auto_command` | `handle_auto_command()` | L1148 | 0 |
| `handle_manual_command` | `handle_manual_command()` | L1156 | 0 |
| `handle_models_command` | `handle_models_command()` | L1164 | 0 |
| `confirm` | `confirm()` | L1251 | 0 |
| `confirm_tool` | `confirm_tool()` | L1258 | 0 |
| `slow_print` | `slow_print()` | L1269 | 0 |
| `gemini_key_setup` | `gemini_key_setup()` | L1289 | 0 |
| `_validate_gemini_key` | `_validate_gemini_key()` | L1376 | 0 |
| `_maybe_save_gemini_key` | `_maybe_save_gemini_key()` | L1412 | 0 |
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L1450 | 0 |
| `_debug_log` | `_debug_log()` | L1495 | 0 |
| `_utf8_char_len` | `_utf8_char_len()` | L1517 | 0 |
| `_char_width` | `_char_width()` | L1528 | 0 |
| `_display_width_chars` | `_display_width_chars()` | L1541 | 0 |
| `_display_width` | `_display_width()` | L1548 | 0 |
| `_term_size` | `_term_size()` | L1560 | 0 |
| `_query_cursor_row` | `_query_cursor_row()` | L1579 | 0 |
| `_query_cursor_pos` | `_query_cursor_pos()` | L1635 | 0 |
| `_probe_terminal_size` | `_probe_terminal_size()` | L1702 | 0 |
| `_walk_position` | `_walk_position()` | L1743 | 0 |
| `read_line_interactive` | `read_line_interactive()` | L1763 | 0 |
| `run_tool` | `run_tool()` | L2109 | 0 |
