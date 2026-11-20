# Codebase Signatures & Symbol Index

Quick-reference catalog of function and method signatures, arguments, and return types.

## [`claude-agent.pl`](../claude-agent.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `configure_provider` | `configure_provider()` | L66 | 0 |
| `encode` | `encode()` | L152 | 0 |
| `encode_string` | `encode_string()` | L172 | 0 |
| `decode` | `decode()` | L183 | 0 |
| `_skip_ws` | `_skip_ws()` | L190 | 0 |
| `_decode_value` | `_decode_value()` | L195 | 0 |
| `_decode_object` | `_decode_object()` | L213 | 0 |
| `_decode_array` | `_decode_array()` | L235 | 0 |
| `_decode_string` | `_decode_string()` | L253 | 0 |
| `call_api` | `call_api()` | L288 | 0 |
| `quote` | `quote()` | L349 | 0 |
| `build_headers` | `build_headers()` | L366 | 0 |
| `build_request` | `build_request()` | L380 | 0 |
| `build_request_anthropic` | `build_request_anthropic()` | L387 | 0 |
| `build_request_gemini` | `build_request_gemini()` | L398 | 0 |
| `_gemini_thinking_config` | `_gemini_thinking_config()` | L459 | 0 |
| `build_request_openai` | `build_request_openai()` | L471 | 0 |
| `parse_response` | `parse_response()` | L537 | 0 |
| `parse_response_openai` | `parse_response_openai()` | L544 | 0 |
| `parse_response_anthropic` | `parse_response_anthropic()` | L570 | 0 |
| `parse_response_gemini` | `parse_response_gemini()` | L580 | 0 |
| `fetch_models` | `fetch_models()` | L623 | 0 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L655 | 0 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L687 | 0 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L730 | 0 |
| `_normalize_models` | `_normalize_models()` | L778 | 0 |
| `_select_model_nontty` | `_select_model_nontty()` | L795 | 0 |
| `_read_menu_key` | `_read_menu_key()` | L819 | 0 |
| `_render_menu_lines` | `_render_menu_lines()` | L877 | 0 |
| `select_model_interactive` | `select_model_interactive()` | L918 | 0 |
| `get_current_model` | `get_current_model()` | L1037 | 0 |
| `get_current_provider` | `get_current_provider()` | L1041 | 0 |
| `get_current_api_url` | `get_current_api_url()` | L1045 | 0 |
| `get_auto_mode` | `get_auto_mode()` | L1049 | 0 |
| `set_auto_mode` | `set_auto_mode()` | L1053 | 0 |
| `show_help` | `show_help()` | L1059 | 0 |
| `handle_auto_command` | `handle_auto_command()` | L1073 | 0 |
| `handle_manual_command` | `handle_manual_command()` | L1081 | 0 |
| `handle_models_command` | `handle_models_command()` | L1089 | 0 |
| `confirm` | `confirm()` | L1164 | 0 |
| `confirm_tool` | `confirm_tool()` | L1171 | 0 |
| `slow_print` | `slow_print()` | L1182 | 0 |
| `gemini_key_setup` | `gemini_key_setup()` | L1204 | 0 |
| `_validate_gemini_key` | `_validate_gemini_key()` | L1291 | 0 |
| `_maybe_save_gemini_key` | `_maybe_save_gemini_key()` | L1327 | 0 |
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L1364 | 0 |
| `_debug_log` | `_debug_log()` | L1416 | 0 |
| `_utf8_char_len` | `_utf8_char_len()` | L1438 | 0 |
| `_char_width` | `_char_width()` | L1449 | 0 |
| `_display_width_chars` | `_display_width_chars()` | L1464 | 0 |
| `_display_width` | `_display_width()` | L1472 | 0 |
| `_term_size` | `_term_size()` | L1484 | 0 |
| `_query_cursor_row` | `_query_cursor_row()` | L1503 | 0 |
| `_query_cursor_pos` | `_query_cursor_pos()` | L1559 | 0 |
| `_probe_terminal_size` | `_probe_terminal_size()` | L1626 | 0 |
| `_walk_position` | `_walk_position()` | L1667 | 0 |
| `read_line_interactive` | `read_line_interactive()` | L1687 | 0 |
| `run_tool` | `run_tool()` | L2035 | 0 |
