package varg

import "core:fmt"
import "core:os"
import "core:strings"
import "core:log"

App :: struct {
	name:        string,
	description: string,
	version:     string,
	author:      string,
	// Display help text on empty input
	auto_help:   bool,
	commands:    []Command,
	flags:       []Flag,
	args:        []Argument,
}

Command :: struct {
	name:        string,
	takes_value: bool,
	value:       string,
	help_text:   string,
}

Flag :: struct {
	name:      string,
	help_text: string,
	long:      string,
	short:     string,
}

Argument :: struct {
	name:      string,
	help_text: string,
	long:      string,
	short:     string,
	multiple:  bool,
}

ParsedArgs :: struct {
	command: Command,
	flags:   map[string]bool,
	args:    map[string]string,
}

ParseError :: enum {
	None,
	UnexpectedEOF,
	NoValidArgs,
}

@(private)
parse_command :: proc(
	user_cmds: []Command,
	input: []string,
) -> (
	command: Command,
	err: ParseError,
) {
	for arg, i in input {
		ok: bool
		command, ok = match_command(arg, user_cmds)
		if !ok do continue

		if command.takes_value {
			value := match_value(i, input) or_return
			command.value = value
		}

		return
	}

	return
}

@(private)
match_command :: proc(raw_arg: string, app_cmds: []Command) -> (parsed: Command, ok: bool) {
	for cmd in app_cmds {
		if cmd.name == raw_arg {
			return cmd, true
		}
	}

	return
}

@(private)
prefix_args :: proc(s, l: string) -> (short, long: string) {
	short = strings.concatenate([]string{"-", s})
	long = strings.concatenate([]string{"--", l})
	return
}

// @(private)
// parse_flags :: proc(app: ^App, args: []string) {
// 	for arg in args {
// 		matched := match_flag(arg, app.flags)
// 		if matched != nil {
// 			app.parsed_args.flags[matched.?.name] = true
// 		}
// 	}
// }

@(private)
parse_flags :: proc(user_flags: []Flag, input: []string) -> (parsed_flags: map[string]bool) {
	for arg in input {
		matched, ok := match_flag(arg, user_flags)
		if !ok do continue

		parsed_flags[matched.name] = true
	}

	return
}

@(private)
match_flag :: proc(raw_arg: string, app_flags: []Flag) -> (matched: Flag, ok: bool) {
	for flag in app_flags {
		short, long := prefix_args(flag.short, flag.long)
		if raw_arg == short || raw_arg == long {
			return flag, true
		}
	}

	return
}

@(private)
parse_args :: proc(
	user_args: []Argument,
	input: []string,
) -> (
	args: map[string]string,
	err: ParseError,
) {
	for arg, i in input {
		matched, ok := match_arg(arg, user_args)
		if !ok do continue

		value := match_value(i, input) or_return
		args[matched.name] = value
	}

	return
}

@(private)
match_arg :: proc(raw_arg: string, app_args: []Argument) -> (matched: Argument, ok: bool) {
	for arg in app_args {
		short, long := prefix_args(arg.short, arg.long)
		if raw_arg == short || raw_arg == long {
			return arg, true
		}
	}

	return
}

@(private)
match_value :: proc(index: int, raw_args: []string) -> (value: string, err: ParseError) {
	if len(raw_args) > index + 1 {
		value = raw_args[index + 1]
		return
	}

	err = .UnexpectedEOF
	return
}

parse :: proc(app: ^App, input: []string) -> (parsed: ParsedArgs, err: ParseError) {
	input := input[1:]

	parsed.command = parse_command(app.commands, input) or_return
	parsed.flags = parse_flags(app.flags, input)
	parsed.args = parse_args(app.args, input) or_return

	if parsed.command.name == "" && len(parsed.flags) < 1 && len(parsed.args) < 1 {
		if app.auto_help do print_help(app)
		err = .NoValidArgs
	}

	return
}

@(private)
print_header :: proc(app: ^App) {
	fmt.printf("%s ", app.name)
	if app.version != "" do fmt.printf("(%s) ", app.version)
	if app.description != "" do fmt.printf("- %s", app.description)
	fmt.println()

	if app.author != "" do fmt.printf("Author: %s\n", app.author)

	if len(app.commands) > 0 || len(app.flags) > 0 || len(app.args) > 0 {
		fmt.printf("Usage: %s OPTION\n\n", app.name)
	} else {
		fmt.printf("Usage: %s\n\n", app.name)
	}
}

print_help :: proc(app: ^App) {
	print_header(app)

	cmd_opts := make([]string, len(app.commands))
	cmd_help := make([]string, len(app.commands))
	for cmd, i in app.commands {
		cmd_opts[i] = cmd.name
		cmd_help[i] = cmd.help_text
	}

	cmd_width := calc_col_width(cmd_opts)

	flag_opts := make([]string, len(app.flags))
	flag_help := make([]string, len(app.flags))
	for flag, i in app.flags {
		flag_opts[i] = fmt.aprintf("-%s, --%s", flag.short, flag.long)
		flag_help[i] = flag.help_text
	}

	flag_width := calc_col_width(flag_opts)

	arg_opts := make([]string, len(app.args))
	arg_help := make([]string, len(app.args))
	for arg, i in app.args {
		arg_opts[i] = fmt.aprintf("-%s, --%s <VALUE>", arg.short, arg.long)
		arg_help[i] = arg.help_text
	}

	arg_width := calc_col_width(arg_opts)

	max_width := max(cmd_width, flag_width, arg_width) + 4

	print_section("COMMANDS", cmd_opts, cmd_help, max_width)
	print_section("FLAGS", flag_opts, flag_help, max_width)
	print_section("ARGUMENTS", arg_opts, arg_help, max_width)
}

@(private)
print_section :: proc(title: string, options: []string, help_texts: []string, width: int) {
	if len(options) < 1 do return

	fmt.printf("%s:\n", title)
	for opt, i in options {
		fmt.printf("  %s%s%s\n", opt, strings.repeat(" ", width - len(opt)), help_texts[i])
	}
	fmt.println()
}

@(private)
calc_col_width :: proc(items: []string) -> int {
	max := 0
	for item in items {
		if len(item) > max do max = len(item)
	}

	return max
}

// !! IGNORE THIS !!
//
// It's here for playgrounding purposes.
main :: proc() {
	app := App {
		name        = "test_app",
		version     = "1.0",
		description = "a test app for testing",
		auto_help   = true,
		flags = []Flag {
			{name = "foo", short = "f", long = "foo", help_text = "foo me daddy"}
		}
	}
	_, err := parse(&app, os.args)
	fmt.println(err)
}

