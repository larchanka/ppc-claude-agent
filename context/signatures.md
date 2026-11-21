# Codebase Signatures & Symbol Index

Quick-reference catalog of function and method signatures, arguments, and return types.

## [`code-agent.pl`](../code-agent.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `get_env_file_path` | `get_env_file_path()` | L41 | 6 |
| `load_env_file` | `load_env_file()` | L51 | 2 |
| `cursor_hide` | `cursor_hide()` | L83 | 6 |
| `cursor_show` | `cursor_show()` | L88 | 10 |
| `configure_provider` | `configure_provider()` | L120 | 2 |
| `get_subagent_base_prompt` | `get_subagent_base_prompt()` | L224 | 2 |
| `get_subagent_system_prompt` | `get_subagent_system_prompt()` | L230 | 2 |
| `get_subagent_initial_prompt` | `get_subagent_initial_prompt()` | L238 | 2 |
| `get_subagent_countdown_note` | `get_subagent_countdown_note()` | L244 | 2 |
| `read_agents_file` | `read_agents_file()` | L251 | 2 |
| `get_agents_context` | `get_agents_context()` | L266 | 2 |
| `get_effective_system_prompt` | `get_effective_system_prompt()` | L301 | 6 |
| `encode` | `encode()` | L319 | 20 |
| `encode_string` | `encode_string()` | L339 | 2 |
| `decode` | `decode()` | L350 | 12 |
| `_skip_ws` | `_skip_ws()` | L357 | 6 |
| `_decode_value` | `_decode_value()` | L362 | 6 |
| `_decode_object` | `_decode_object()` | L379 | 2 |
| `_decode_array` | `_decode_array()` | L401 | 2 |
| `_decode_string` | `_decode_string()` | L419 | 4 |
| `call_api` | `call_api()` | L455 | 10 |
| `quote` | `quote()` | L581 | 2 |
| `build_headers` | `build_headers()` | L595 | 4 |
| `build_request` | `build_request()` | L609 | 4 |
| `build_request_anthropic` | `build_request_anthropic()` | L617 | 2 |
| `build_request_gemini` | `build_request_gemini()` | L647 | 2 |
| `_gemini_thinking_config` | `_gemini_thinking_config()` | L707 | 2 |
| `build_request_openai` | `build_request_openai()` | L719 | 2 |
| `parse_response` | `parse_response()` | L785 | 4 |
| `parse_response_openai` | `parse_response_openai()` | L792 | 2 |
| `parse_response_anthropic` | `parse_response_anthropic()` | L824 | 2 |
| `parse_response_gemini` | `parse_response_gemini()` | L834 | 2 |
| `has_thinking_block` | `has_thinking_block()` | L875 | 2 |
| `fetch_models` | `fetch_models()` | L885 | 2 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L917 | 2 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L949 | 2 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L992 | 2 |
| `_normalize_models` | `_normalize_models()` | L1041 | 2 |
| `_select_model_nontty` | `_select_model_nontty()` | L1058 | 2 |
| `_read_menu_key` | `_read_menu_key()` | L1082 | 2 |
| `_render_menu_lines` | `_render_menu_lines()` | L1140 | 2 |
| `select_model_interactive` | `select_model_interactive()` | L1181 | 2 |
| `get_current_model` | `get_current_model()` | L1306 | 2 |
| `get_current_provider` | `get_current_provider()` | L1310 | 2 |
| `get_current_api_url` | `get_current_api_url()` | L1314 | 2 |
| `get_auto_mode` | `get_auto_mode()` | L1318 | 2 |
| `set_auto_mode` | `set_auto_mode()` | L1322 | 4 |
| `generate_session_id` | `generate_session_id()` | L1328 | 4 |
| `init_session` | `init_session()` | L1335 | 4 |
| `get_current_session` | `get_current_session()` | L1348 | 2 |
| `archive_session` | `archive_session()` | L1353 | 2 |
| `handle_new_command` | `handle_new_command()` | L1362 | 2 |
| `show_help` | `show_help()` | L1374 | 2 |
| `handle_auto_command` | `handle_auto_command()` | L1389 | 2 |
| `handle_manual_command` | `handle_manual_command()` | L1397 | 2 |
| `handle_models_command` | `handle_models_command()` | L1405 | 2 |
| `confirm` | `confirm()` | L1513 | 4 |
| `confirm_tool` | `confirm_tool()` | L1520 | 2 |
| `get_subagent_tools` | `get_subagent_tools()` | L1529 | 2 |
| `gemini_key_setup` | `gemini_key_setup()` | L1552 | 2 |
| `_validate_gemini_key` | `_validate_gemini_key()` | L1639 | 0 |
| `_maybe_save_gemini_key` | `_maybe_save_gemini_key()` | L1675 | 0 |
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L1713 | 4 |
| `run_tool` | `run_tool()` | L1750 | 4 |
| `run_subagent` | `run_subagent()` | L1865 | 2 |
| `_debug_log` | `_debug_log()` | L1988 | 4 |
| `_utf8_char_len` | `_utf8_char_len()` | L2010 | 2 |
| `_char_width` | `_char_width()` | L2021 | 4 |
| `_display_width_chars` | `_display_width_chars()` | L2034 | 4 |
| `_display_width` | `_display_width()` | L2041 | 0 |
| `_term_size` | `_term_size()` | L2053 | 2 |
| `_query_cursor_row` | `_query_cursor_row()` | L2072 | 2 |
| `_query_cursor_pos` | `_query_cursor_pos()` | L2128 | 2 |
| `_probe_terminal_size` | `_probe_terminal_size()` | L2195 | 2 |
| `_walk_position` | `_walk_position()` | L2236 | 2 |
| `read_line_interactive` | `read_line_interactive()` | L2256 | 8 |
| `extract_basename` | `extract_basename()` | L2610 | 2 |
| `truncate_text` | `truncate_text()` | L2621 | 4 |
| `_format_line_range` | `_format_line_range()` | L2636 | 2 |
| `format_tool_summary` | `format_tool_summary()` | L2651 | 4 |
| `format_tool_call` | `format_tool_call()` | L2716 | 2 |
| `format_thinking_status` | `format_thinking_status()` | L2725 | 4 |
| `finalize_thinking_line` | `finalize_thinking_line()` | L2735 | 2 |
| `clear_thinking_line` | `clear_thinking_line()` | L2740 | 4 |
| `format_subagent_start` | `format_subagent_start()` | L2744 | 2 |
| `format_subagent_tool_call` | `format_subagent_tool_call()` | L2753 | 2 |
| `format_subagent_finish` | `format_subagent_finish()` | L2762 | 2 |
| `slow_print` | `slow_print()` | L2772 | 2 |
| `show_banner` | `show_banner()` | L2787 | 1 |

## [`src/header.pl`](../src/header.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `get_env_file_path` | `get_env_file_path()` | L40 | 6 |
| `load_env_file` | `load_env_file()` | L50 | 2 |
| `cursor_hide` | `cursor_hide()` | L82 | 6 |
| `cursor_show` | `cursor_show()` | L87 | 10 |
| `configure_provider` | `configure_provider()` | L119 | 2 |

## [`src/json.pl`](../src/json.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `encode` | `encode()` | L4 | 20 |
| `encode_string` | `encode_string()` | L24 | 2 |
| `decode` | `decode()` | L35 | 12 |
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

## [`src/prompts.pl`](../src/prompts.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `get_subagent_base_prompt` | `get_subagent_base_prompt()` | L68 | 2 |
| `get_subagent_system_prompt` | `get_subagent_system_prompt()` | L74 | 2 |
| `get_subagent_initial_prompt` | `get_subagent_initial_prompt()` | L82 | 2 |
| `get_subagent_countdown_note` | `get_subagent_countdown_note()` | L88 | 2 |
| `read_agents_file` | `read_agents_file()` | L95 | 2 |
| `get_agents_context` | `get_agents_context()` | L110 | 2 |
| `get_effective_system_prompt` | `get_effective_system_prompt()` | L145 | 6 |

## [`src/providers.pl`](../src/providers.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `build_headers` | `build_headers()` | L7 | 4 |
| `build_request` | `build_request()` | L21 | 4 |
| `build_request_anthropic` | `build_request_anthropic()` | L29 | 2 |
| `build_request_gemini` | `build_request_gemini()` | L59 | 2 |
| `_gemini_thinking_config` | `_gemini_thinking_config()` | L119 | 2 |
| `build_request_openai` | `build_request_openai()` | L131 | 2 |
| `parse_response` | `parse_response()` | L197 | 4 |
| `parse_response_openai` | `parse_response_openai()` | L204 | 2 |
| `parse_response_anthropic` | `parse_response_anthropic()` | L236 | 2 |
| `parse_response_gemini` | `parse_response_gemini()` | L246 | 2 |
| `has_thinking_block` | `has_thinking_block()` | L287 | 2 |
| `fetch_models` | `fetch_models()` | L297 | 2 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L329 | 2 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L361 | 2 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L404 | 2 |

## [`src/session.pl`](../src/session.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `get_current_model` | `get_current_model()` | L2 | 2 |
| `get_current_provider` | `get_current_provider()` | L6 | 2 |
| `get_current_api_url` | `get_current_api_url()` | L10 | 2 |
| `get_auto_mode` | `get_auto_mode()` | L14 | 2 |
| `set_auto_mode` | `set_auto_mode()` | L18 | 4 |
| `generate_session_id` | `generate_session_id()` | L24 | 4 |
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
| `confirm` | `confirm()` | L80 | 4 |
| `confirm_tool` | `confirm_tool()` | L87 | 2 |
| `get_subagent_tools` | `get_subagent_tools()` | L96 | 2 |
| `gemini_key_setup` | `gemini_key_setup()` | L119 | 2 |
| `_validate_gemini_key` | `_validate_gemini_key()` | L206 | 0 |
| `_maybe_save_gemini_key` | `_maybe_save_gemini_key()` | L242 | 0 |
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L280 | 4 |
| `run_tool` | `run_tool()` | L317 | 4 |
| `run_subagent` | `run_subagent()` | L432 | 2 |

## [`src/transport.pl`](../src/transport.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `call_api` | `call_api()` | L3 | 10 |
| `quote` | `quote()` | L129 | 2 |

## [`src/ui.pl`](../src/ui.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `extract_basename` | `extract_basename()` | L3 | 2 |
| `truncate_text` | `truncate_text()` | L14 | 4 |
| `_format_line_range` | `_format_line_range()` | L29 | 2 |
| `format_tool_summary` | `format_tool_summary()` | L44 | 4 |
| `format_tool_call` | `format_tool_call()` | L109 | 2 |
| `format_thinking_status` | `format_thinking_status()` | L118 | 4 |
| `finalize_thinking_line` | `finalize_thinking_line()` | L128 | 2 |
| `clear_thinking_line` | `clear_thinking_line()` | L133 | 4 |
| `format_subagent_start` | `format_subagent_start()` | L137 | 2 |
| `format_subagent_tool_call` | `format_subagent_tool_call()` | L146 | 2 |
| `format_subagent_finish` | `format_subagent_finish()` | L155 | 2 |
| `slow_print` | `slow_print()` | L165 | 2 |
| `show_banner` | `show_banner()` | L180 | 1 |
