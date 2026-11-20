# Codebase Signatures & Symbol Index

Quick-reference catalog of function and method signatures, arguments, and return types.

## [`code-agent.pl`](../code-agent.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `get_env_file_path` | `get_env_file_path()` | L41 | 6 |
| `load_env_file` | `load_env_file()` | L51 | 2 |
| `cursor_hide` | `cursor_hide()` | L81 | 6 |
| `cursor_show` | `cursor_show()` | L86 | 8 |
| `configure_provider` | `configure_provider()` | L114 | 2 |
| `encode` | `encode()` | L189 | 18 |
| `encode_string` | `encode_string()` | L209 | 2 |
| `decode` | `decode()` | L220 | 10 |
| `_skip_ws` | `_skip_ws()` | L227 | 6 |
| `_decode_value` | `_decode_value()` | L232 | 6 |
| `_decode_object` | `_decode_object()` | L249 | 2 |
| `_decode_array` | `_decode_array()` | L271 | 2 |
| `_decode_string` | `_decode_string()` | L289 | 4 |
| `call_api` | `call_api()` | L325 | 8 |
| `quote` | `quote()` | L451 | 2 |
| `build_headers` | `build_headers()` | L465 | 2 |
| `build_request` | `build_request()` | L479 | 2 |
| `build_request_anthropic` | `build_request_anthropic()` | L486 | 2 |
| `build_request_gemini` | `build_request_gemini()` | L516 | 2 |
| `_gemini_thinking_config` | `_gemini_thinking_config()` | L576 | 2 |
| `build_request_openai` | `build_request_openai()` | L588 | 2 |
| `parse_response` | `parse_response()` | L654 | 2 |
| `parse_response_openai` | `parse_response_openai()` | L661 | 2 |
| `parse_response_anthropic` | `parse_response_anthropic()` | L693 | 2 |
| `parse_response_gemini` | `parse_response_gemini()` | L703 | 2 |
| `has_thinking_block` | `has_thinking_block()` | L744 | 2 |
| `fetch_models` | `fetch_models()` | L754 | 2 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L786 | 2 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L818 | 2 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L861 | 2 |
| `_normalize_models` | `_normalize_models()` | L910 | 2 |
| `_select_model_nontty` | `_select_model_nontty()` | L927 | 2 |
| `_read_menu_key` | `_read_menu_key()` | L951 | 2 |
| `_render_menu_lines` | `_render_menu_lines()` | L1009 | 2 |
| `select_model_interactive` | `select_model_interactive()` | L1050 | 2 |
| `get_current_model` | `get_current_model()` | L1175 | 2 |
| `get_current_provider` | `get_current_provider()` | L1179 | 2 |
| `get_current_api_url` | `get_current_api_url()` | L1183 | 2 |
| `get_auto_mode` | `get_auto_mode()` | L1187 | 2 |
| `set_auto_mode` | `set_auto_mode()` | L1191 | 4 |
| `generate_session_id` | `generate_session_id()` | L1197 | 2 |
| `init_session` | `init_session()` | L1204 | 4 |
| `get_current_session` | `get_current_session()` | L1217 | 2 |
| `archive_session` | `archive_session()` | L1222 | 2 |
| `handle_new_command` | `handle_new_command()` | L1231 | 2 |
| `show_help` | `show_help()` | L1243 | 2 |
| `handle_auto_command` | `handle_auto_command()` | L1258 | 2 |
| `handle_manual_command` | `handle_manual_command()` | L1266 | 2 |
| `handle_models_command` | `handle_models_command()` | L1274 | 2 |
| `confirm` | `confirm()` | L1364 | 4 |
| `confirm_tool` | `confirm_tool()` | L1371 | 2 |
| `gemini_key_setup` | `gemini_key_setup()` | L1388 | 2 |
| `_validate_gemini_key` | `_validate_gemini_key()` | L1475 | 0 |
| `_maybe_save_gemini_key` | `_maybe_save_gemini_key()` | L1511 | 0 |
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L1549 | 4 |
| `run_tool` | `run_tool()` | L1586 | 2 |
| `_debug_log` | `_debug_log()` | L1709 | 4 |
| `_utf8_char_len` | `_utf8_char_len()` | L1731 | 2 |
| `_char_width` | `_char_width()` | L1742 | 4 |
| `_display_width_chars` | `_display_width_chars()` | L1755 | 4 |
| `_display_width` | `_display_width()` | L1762 | 0 |
| `_term_size` | `_term_size()` | L1774 | 2 |
| `_query_cursor_row` | `_query_cursor_row()` | L1793 | 2 |
| `_query_cursor_pos` | `_query_cursor_pos()` | L1849 | 2 |
| `_probe_terminal_size` | `_probe_terminal_size()` | L1916 | 2 |
| `_walk_position` | `_walk_position()` | L1957 | 2 |
| `read_line_interactive` | `read_line_interactive()` | L1977 | 8 |
| `extract_basename` | `extract_basename()` | L2331 | 2 |
| `truncate_text` | `truncate_text()` | L2342 | 2 |
| `_format_line_range` | `_format_line_range()` | L2357 | 2 |
| `format_tool_summary` | `format_tool_summary()` | L2372 | 2 |
| `format_tool_call` | `format_tool_call()` | L2428 | 2 |
| `format_thinking_status` | `format_thinking_status()` | L2437 | 4 |
| `finalize_thinking_line` | `finalize_thinking_line()` | L2447 | 2 |
| `clear_thinking_line` | `clear_thinking_line()` | L2452 | 2 |
| `slow_print` | `slow_print()` | L2457 | 2 |
| `show_banner` | `show_banner()` | L2472 | 1 |

## [`src/header.pl`](../src/header.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `get_env_file_path` | `get_env_file_path()` | L40 | 6 |
| `load_env_file` | `load_env_file()` | L50 | 2 |
| `cursor_hide` | `cursor_hide()` | L80 | 6 |
| `cursor_show` | `cursor_show()` | L85 | 8 |
| `configure_provider` | `configure_provider()` | L113 | 2 |

## [`src/json.pl`](../src/json.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `encode` | `encode()` | L4 | 18 |
| `encode_string` | `encode_string()` | L24 | 2 |
| `decode` | `decode()` | L35 | 10 |
| `_skip_ws` | `_skip_ws()` | L42 | 6 |
| `_decode_value` | `_decode_value()` | L47 | 6 |
| `_decode_object` | `_decode_object()` | L64 | 2 |
| `_decode_array` | `_decode_array()` | L86 | 2 |
| `_decode_string` | `_decode_string()` | L104 | 4 |

## [`src/models_menu.pl`](../src/models_menu.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `_normalize_models` | `_normalize_models()` | L4 | 2 |
| `_select_model_nontty` | `_select_model_nontty()` | L21 | 2 |
| `_read_menu_key` | `_read_menu_key()` | L45 | 2 |
| `_render_menu_lines` | `_render_menu_lines()` | L103 | 2 |
| `select_model_interactive` | `select_model_interactive()` | L144 | 2 |

## [`src/providers.pl`](../src/providers.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `build_headers` | `build_headers()` | L7 | 2 |
| `build_request` | `build_request()` | L21 | 2 |
| `build_request_anthropic` | `build_request_anthropic()` | L28 | 2 |
| `build_request_gemini` | `build_request_gemini()` | L58 | 2 |
| `_gemini_thinking_config` | `_gemini_thinking_config()` | L118 | 2 |
| `build_request_openai` | `build_request_openai()` | L130 | 2 |
| `parse_response` | `parse_response()` | L196 | 2 |
| `parse_response_openai` | `parse_response_openai()` | L203 | 2 |
| `parse_response_anthropic` | `parse_response_anthropic()` | L235 | 2 |
| `parse_response_gemini` | `parse_response_gemini()` | L245 | 2 |
| `has_thinking_block` | `has_thinking_block()` | L286 | 2 |
| `fetch_models` | `fetch_models()` | L296 | 2 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L328 | 2 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L360 | 2 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L403 | 2 |

## [`src/session.pl`](../src/session.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `get_current_model` | `get_current_model()` | L2 | 2 |
| `get_current_provider` | `get_current_provider()` | L6 | 2 |
| `get_current_api_url` | `get_current_api_url()` | L10 | 2 |
| `get_auto_mode` | `get_auto_mode()` | L14 | 2 |
| `set_auto_mode` | `set_auto_mode()` | L18 | 4 |
| `generate_session_id` | `generate_session_id()` | L24 | 2 |
| `init_session` | `init_session()` | L31 | 4 |
| `get_current_session` | `get_current_session()` | L44 | 2 |
| `archive_session` | `archive_session()` | L49 | 2 |
| `handle_new_command` | `handle_new_command()` | L58 | 2 |
| `show_help` | `show_help()` | L70 | 2 |
| `handle_auto_command` | `handle_auto_command()` | L85 | 2 |
| `handle_manual_command` | `handle_manual_command()` | L93 | 2 |
| `handle_models_command` | `handle_models_command()` | L101 | 2 |

## [`src/terminal.pl`](../src/terminal.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `_debug_log` | `_debug_log()` | L12 | 4 |
| `_utf8_char_len` | `_utf8_char_len()` | L34 | 2 |
| `_char_width` | `_char_width()` | L45 | 4 |
| `_display_width_chars` | `_display_width_chars()` | L58 | 4 |
| `_display_width` | `_display_width()` | L65 | 0 |
| `_term_size` | `_term_size()` | L77 | 2 |
| `_query_cursor_row` | `_query_cursor_row()` | L96 | 2 |
| `_query_cursor_pos` | `_query_cursor_pos()` | L152 | 2 |
| `_probe_terminal_size` | `_probe_terminal_size()` | L219 | 2 |
| `_walk_position` | `_walk_position()` | L260 | 2 |
| `read_line_interactive` | `read_line_interactive()` | L280 | 8 |

## [`src/tools.pl`](../src/tools.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `confirm` | `confirm()` | L62 | 4 |
| `confirm_tool` | `confirm_tool()` | L69 | 2 |
| `gemini_key_setup` | `gemini_key_setup()` | L86 | 2 |
| `_validate_gemini_key` | `_validate_gemini_key()` | L173 | 0 |
| `_maybe_save_gemini_key` | `_maybe_save_gemini_key()` | L209 | 0 |
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L247 | 4 |
| `run_tool` | `run_tool()` | L284 | 2 |

## [`src/transport.pl`](../src/transport.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `call_api` | `call_api()` | L3 | 8 |
| `quote` | `quote()` | L129 | 2 |

## [`src/ui.pl`](../src/ui.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `extract_basename` | `extract_basename()` | L3 | 2 |
| `truncate_text` | `truncate_text()` | L14 | 2 |
| `_format_line_range` | `_format_line_range()` | L29 | 2 |
| `format_tool_summary` | `format_tool_summary()` | L44 | 2 |
| `format_tool_call` | `format_tool_call()` | L100 | 2 |
| `format_thinking_status` | `format_thinking_status()` | L109 | 4 |
| `finalize_thinking_line` | `finalize_thinking_line()` | L119 | 2 |
| `clear_thinking_line` | `clear_thinking_line()` | L124 | 2 |
| `slow_print` | `slow_print()` | L129 | 2 |
| `show_banner` | `show_banner()` | L144 | 1 |
