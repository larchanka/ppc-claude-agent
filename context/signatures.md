# Codebase Signatures & Symbol Index

Quick-reference catalog of function and method signatures, arguments, and return types.

## [`claude-agent.pl`](../claude-agent.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `configure_provider` | `configure_provider()` | L62 | 0 |
| `encode` | `encode()` | L148 | 0 |
| `encode_string` | `encode_string()` | L168 | 0 |
| `decode` | `decode()` | L179 | 0 |
| `_skip_ws` | `_skip_ws()` | L186 | 0 |
| `_decode_value` | `_decode_value()` | L191 | 0 |
| `_decode_object` | `_decode_object()` | L209 | 0 |
| `_decode_array` | `_decode_array()` | L231 | 0 |
| `_decode_string` | `_decode_string()` | L249 | 0 |
| `call_api` | `call_api()` | L284 | 0 |
| `quote` | `quote()` | L345 | 0 |
| `build_headers` | `build_headers()` | L362 | 0 |
| `build_request` | `build_request()` | L376 | 0 |
| `build_request_anthropic` | `build_request_anthropic()` | L383 | 0 |
| `build_request_gemini` | `build_request_gemini()` | L394 | 0 |
| `_gemini_thinking_config` | `_gemini_thinking_config()` | L455 | 0 |
| `build_request_openai` | `build_request_openai()` | L467 | 0 |
| `parse_response` | `parse_response()` | L533 | 0 |
| `parse_response_openai` | `parse_response_openai()` | L540 | 0 |
| `parse_response_anthropic` | `parse_response_anthropic()` | L566 | 0 |
| `parse_response_gemini` | `parse_response_gemini()` | L576 | 0 |
| `fetch_models` | `fetch_models()` | L619 | 0 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L651 | 0 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L683 | 0 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L726 | 0 |
| `_normalize_models` | `_normalize_models()` | L774 | 0 |
| `_select_model_nontty` | `_select_model_nontty()` | L791 | 0 |
| `_read_menu_key` | `_read_menu_key()` | L815 | 0 |
| `_render_menu_lines` | `_render_menu_lines()` | L873 | 0 |
| `select_model_interactive` | `select_model_interactive()` | L914 | 0 |
| `get_current_model` | `get_current_model()` | L1033 | 0 |
| `get_current_provider` | `get_current_provider()` | L1037 | 0 |
| `get_current_api_url` | `get_current_api_url()` | L1041 | 0 |
| `show_help` | `show_help()` | L1045 | 0 |
| `handle_models_command` | `handle_models_command()` | L1057 | 0 |
| `confirm` | `confirm()` | L1128 | 0 |
| `slow_print` | `slow_print()` | L1140 | 0 |
| `gemini_key_setup` | `gemini_key_setup()` | L1162 | 0 |
| `_validate_gemini_key` | `_validate_gemini_key()` | L1249 | 0 |
| `_maybe_save_gemini_key` | `_maybe_save_gemini_key()` | L1285 | 0 |
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L1322 | 0 |
| `_debug_log` | `_debug_log()` | L1374 | 0 |
| `_utf8_char_len` | `_utf8_char_len()` | L1396 | 0 |
| `_char_width` | `_char_width()` | L1407 | 0 |
| `_display_width_chars` | `_display_width_chars()` | L1422 | 0 |
| `_display_width` | `_display_width()` | L1430 | 0 |
| `_term_size` | `_term_size()` | L1442 | 0 |
| `_query_cursor_row` | `_query_cursor_row()` | L1461 | 0 |
| `_query_cursor_pos` | `_query_cursor_pos()` | L1517 | 0 |
| `_probe_terminal_size` | `_probe_terminal_size()` | L1584 | 0 |
| `_walk_position` | `_walk_position()` | L1625 | 0 |
| `read_line_interactive` | `read_line_interactive()` | L1645 | 0 |
| `run_tool` | `run_tool()` | L1993 | 0 |
