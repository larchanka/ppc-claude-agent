# Codebase Signatures & Symbol Index

Quick-reference catalog of function and method signatures, arguments, and return types.

## [`code-agent.pl`](../code-agent.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `get_env_file_path` | `get_env_file_path()` | L41 | 0 |
| `load_env_file` | `load_env_file()` | L51 | 0 |
| `cursor_hide` | `cursor_hide()` | L81 | 0 |
| `cursor_show` | `cursor_show()` | L86 | 0 |
| `configure_provider` | `configure_provider()` | L114 | 0 |
| `encode` | `encode()` | L189 | 0 |
| `encode_string` | `encode_string()` | L209 | 0 |
| `decode` | `decode()` | L220 | 0 |
| `_skip_ws` | `_skip_ws()` | L227 | 0 |
| `_decode_value` | `_decode_value()` | L232 | 0 |
| `_decode_object` | `_decode_object()` | L249 | 0 |
| `_decode_array` | `_decode_array()` | L271 | 0 |
| `_decode_string` | `_decode_string()` | L289 | 0 |
| `call_api` | `call_api()` | L325 | 0 |
| `quote` | `quote()` | L451 | 0 |
| `build_headers` | `build_headers()` | L465 | 0 |
| `build_request` | `build_request()` | L479 | 0 |
| `build_request_anthropic` | `build_request_anthropic()` | L486 | 0 |
| `build_request_gemini` | `build_request_gemini()` | L516 | 0 |
| `_gemini_thinking_config` | `_gemini_thinking_config()` | L576 | 0 |
| `build_request_openai` | `build_request_openai()` | L588 | 0 |
| `parse_response` | `parse_response()` | L654 | 0 |
| `parse_response_openai` | `parse_response_openai()` | L661 | 0 |
| `parse_response_anthropic` | `parse_response_anthropic()` | L693 | 0 |
| `parse_response_gemini` | `parse_response_gemini()` | L703 | 0 |
| `has_thinking_block` | `has_thinking_block()` | L744 | 0 |
| `fetch_models` | `fetch_models()` | L754 | 0 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L786 | 0 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L818 | 0 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L861 | 0 |
| `_normalize_models` | `_normalize_models()` | L910 | 0 |
| `_select_model_nontty` | `_select_model_nontty()` | L927 | 0 |
| `_read_menu_key` | `_read_menu_key()` | L951 | 0 |
| `_render_menu_lines` | `_render_menu_lines()` | L1009 | 0 |
| `select_model_interactive` | `select_model_interactive()` | L1050 | 0 |
| `get_current_model` | `get_current_model()` | L1175 | 0 |
| `get_current_provider` | `get_current_provider()` | L1179 | 0 |
| `get_current_api_url` | `get_current_api_url()` | L1183 | 0 |
| `get_auto_mode` | `get_auto_mode()` | L1187 | 0 |
| `set_auto_mode` | `set_auto_mode()` | L1191 | 0 |
| `generate_session_id` | `generate_session_id()` | L1197 | 0 |
| `init_session` | `init_session()` | L1204 | 0 |
| `get_current_session` | `get_current_session()` | L1217 | 0 |
| `archive_session` | `archive_session()` | L1222 | 0 |
| `handle_new_command` | `handle_new_command()` | L1231 | 0 |
| `show_help` | `show_help()` | L1243 | 0 |
| `handle_auto_command` | `handle_auto_command()` | L1258 | 0 |
| `handle_manual_command` | `handle_manual_command()` | L1266 | 0 |
| `handle_models_command` | `handle_models_command()` | L1274 | 0 |
| `confirm` | `confirm()` | L1364 | 0 |
| `confirm_tool` | `confirm_tool()` | L1371 | 0 |
| `gemini_key_setup` | `gemini_key_setup()` | L1388 | 0 |
| `_validate_gemini_key` | `_validate_gemini_key()` | L1475 | 0 |
| `_maybe_save_gemini_key` | `_maybe_save_gemini_key()` | L1511 | 0 |
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L1549 | 0 |
| `run_tool` | `run_tool()` | L1586 | 0 |
| `_debug_log` | `_debug_log()` | L1709 | 0 |
| `_utf8_char_len` | `_utf8_char_len()` | L1731 | 0 |
| `_char_width` | `_char_width()` | L1742 | 0 |
| `_display_width_chars` | `_display_width_chars()` | L1755 | 0 |
| `_display_width` | `_display_width()` | L1762 | 0 |
| `_term_size` | `_term_size()` | L1774 | 0 |
| `_query_cursor_row` | `_query_cursor_row()` | L1793 | 0 |
| `_query_cursor_pos` | `_query_cursor_pos()` | L1849 | 0 |
| `_probe_terminal_size` | `_probe_terminal_size()` | L1916 | 0 |
| `_walk_position` | `_walk_position()` | L1957 | 0 |
| `read_line_interactive` | `read_line_interactive()` | L1977 | 0 |
| `extract_basename` | `extract_basename()` | L2331 | 0 |
| `truncate_text` | `truncate_text()` | L2342 | 0 |
| `_format_line_range` | `_format_line_range()` | L2357 | 0 |
| `format_tool_summary` | `format_tool_summary()` | L2372 | 0 |
| `format_tool_call` | `format_tool_call()` | L2428 | 0 |
| `format_thinking_status` | `format_thinking_status()` | L2437 | 0 |
| `finalize_thinking_line` | `finalize_thinking_line()` | L2447 | 0 |
| `clear_thinking_line` | `clear_thinking_line()` | L2452 | 0 |
| `slow_print` | `slow_print()` | L2457 | 0 |
| `show_banner` | `show_banner()` | L2472 | 0 |

## [`src/header.pl`](../src/header.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `get_env_file_path` | `get_env_file_path()` | L40 | 0 |
| `load_env_file` | `load_env_file()` | L50 | 0 |
| `cursor_hide` | `cursor_hide()` | L80 | 0 |
| `cursor_show` | `cursor_show()` | L85 | 0 |
| `configure_provider` | `configure_provider()` | L113 | 0 |

## [`src/json.pl`](../src/json.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `encode` | `encode()` | L4 | 0 |
| `encode_string` | `encode_string()` | L24 | 0 |
| `decode` | `decode()` | L35 | 0 |
| `_skip_ws` | `_skip_ws()` | L42 | 0 |
| `_decode_value` | `_decode_value()` | L47 | 0 |
| `_decode_object` | `_decode_object()` | L64 | 0 |
| `_decode_array` | `_decode_array()` | L86 | 0 |
| `_decode_string` | `_decode_string()` | L104 | 0 |

## [`src/models_menu.pl`](../src/models_menu.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `_normalize_models` | `_normalize_models()` | L4 | 0 |
| `_select_model_nontty` | `_select_model_nontty()` | L21 | 0 |
| `_read_menu_key` | `_read_menu_key()` | L45 | 0 |
| `_render_menu_lines` | `_render_menu_lines()` | L103 | 0 |
| `select_model_interactive` | `select_model_interactive()` | L144 | 0 |

## [`src/providers.pl`](../src/providers.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `build_headers` | `build_headers()` | L7 | 0 |
| `build_request` | `build_request()` | L21 | 0 |
| `build_request_anthropic` | `build_request_anthropic()` | L28 | 0 |
| `build_request_gemini` | `build_request_gemini()` | L58 | 0 |
| `_gemini_thinking_config` | `_gemini_thinking_config()` | L118 | 0 |
| `build_request_openai` | `build_request_openai()` | L130 | 0 |
| `parse_response` | `parse_response()` | L196 | 0 |
| `parse_response_openai` | `parse_response_openai()` | L203 | 0 |
| `parse_response_anthropic` | `parse_response_anthropic()` | L235 | 0 |
| `parse_response_gemini` | `parse_response_gemini()` | L245 | 0 |
| `has_thinking_block` | `has_thinking_block()` | L286 | 0 |
| `fetch_models` | `fetch_models()` | L296 | 0 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L328 | 0 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L360 | 0 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L403 | 0 |

## [`src/session.pl`](../src/session.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `get_current_model` | `get_current_model()` | L2 | 0 |
| `get_current_provider` | `get_current_provider()` | L6 | 0 |
| `get_current_api_url` | `get_current_api_url()` | L10 | 0 |
| `get_auto_mode` | `get_auto_mode()` | L14 | 0 |
| `set_auto_mode` | `set_auto_mode()` | L18 | 0 |
| `generate_session_id` | `generate_session_id()` | L24 | 0 |
| `init_session` | `init_session()` | L31 | 0 |
| `get_current_session` | `get_current_session()` | L44 | 0 |
| `archive_session` | `archive_session()` | L49 | 0 |
| `handle_new_command` | `handle_new_command()` | L58 | 0 |
| `show_help` | `show_help()` | L70 | 0 |
| `handle_auto_command` | `handle_auto_command()` | L85 | 0 |
| `handle_manual_command` | `handle_manual_command()` | L93 | 0 |
| `handle_models_command` | `handle_models_command()` | L101 | 0 |

## [`src/terminal.pl`](../src/terminal.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `_debug_log` | `_debug_log()` | L12 | 0 |
| `_utf8_char_len` | `_utf8_char_len()` | L34 | 0 |
| `_char_width` | `_char_width()` | L45 | 0 |
| `_display_width_chars` | `_display_width_chars()` | L58 | 0 |
| `_display_width` | `_display_width()` | L65 | 0 |
| `_term_size` | `_term_size()` | L77 | 0 |
| `_query_cursor_row` | `_query_cursor_row()` | L96 | 0 |
| `_query_cursor_pos` | `_query_cursor_pos()` | L152 | 0 |
| `_probe_terminal_size` | `_probe_terminal_size()` | L219 | 0 |
| `_walk_position` | `_walk_position()` | L260 | 0 |
| `read_line_interactive` | `read_line_interactive()` | L280 | 0 |

## [`src/tools.pl`](../src/tools.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `confirm` | `confirm()` | L62 | 0 |
| `confirm_tool` | `confirm_tool()` | L69 | 0 |
| `gemini_key_setup` | `gemini_key_setup()` | L86 | 0 |
| `_validate_gemini_key` | `_validate_gemini_key()` | L173 | 0 |
| `_maybe_save_gemini_key` | `_maybe_save_gemini_key()` | L209 | 0 |
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L247 | 0 |
| `run_tool` | `run_tool()` | L284 | 0 |

## [`src/transport.pl`](../src/transport.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `call_api` | `call_api()` | L3 | 0 |
| `quote` | `quote()` | L129 | 0 |

## [`src/ui.pl`](../src/ui.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `extract_basename` | `extract_basename()` | L3 | 0 |
| `truncate_text` | `truncate_text()` | L14 | 0 |
| `_format_line_range` | `_format_line_range()` | L29 | 0 |
| `format_tool_summary` | `format_tool_summary()` | L44 | 0 |
| `format_tool_call` | `format_tool_call()` | L100 | 0 |
| `format_thinking_status` | `format_thinking_status()` | L109 | 0 |
| `finalize_thinking_line` | `finalize_thinking_line()` | L119 | 0 |
| `clear_thinking_line` | `clear_thinking_line()` | L124 | 0 |
| `slow_print` | `slow_print()` | L129 | 0 |
| `show_banner` | `show_banner()` | L144 | 0 |
