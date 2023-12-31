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
	auto_help:   bool,
	commands:    []Command,
	flags:       []Flag,
	args:        []Argument,
	parsed_args: ParsedArgs,
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
	RequiredValueNotProvided,
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
			value, valid := match_value(i, input)
			if valid {
				command.value = value
			} else {
				err = .RequiredValueNotProvided
			}
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
		matched := match_flag(arg, user_flags)
		if matched != nil {
			parsed_flags[matched.?.name] = true
		}
	}

	return
}

@(private)
match_flag :: proc(raw_arg: string, app_flags: []Flag) -> Maybe(Flag) {
	for flag in app_flags {
		short, long := prefix_args(flag.short, flag.long)
		if raw_arg == short || raw_arg == long {
			return flag
		}
	}

	return nil
}

@(private)
parse_args :: proc(user_args: []Argument, input: []string) -> (args: map[string]string) {
	for arg, i in input {
		matched := match_arg(arg, user_args)
		if matched != nil {
			value, ok := match_value(i, input)
			if ok {
				args[matched.?.name] = value
			}
		}
	}

	return
}

@(private)
match_arg :: proc(raw_arg: string, app_args: []Argument) -> Maybe(Argument) {
	for arg in app_args {
		short, long := prefix_args(arg.short, arg.long)
		if raw_arg == short || raw_arg == long {
			return arg
		}
	}

	return nil
}

@(private)
match_value :: proc(index: int, raw_args: []string) -> (value: string, ok: bool) {
	if len(raw_args) > index + 1 {
		value = raw_args[index + 1]
		ok = true
		return
	}

	return
}

parse :: proc(app: ^App, input: []string) -> (parsed: ParsedArgs) {
	input := input[1:]
	parsed.command, _ = parse_command(app.commands, input)
	parsed.flags = parse_flags(app.flags, input)
	parsed.args = parse_args(app.args, input)
	return
}

print_help :: proc(app: ^App) {
	fmt.printf("%s (%s) - %s\n", app.name, app.version, app.description)
	fmt.printf("Author: %s\n", app.author)
	fmt.printf("Usage: %s OPTION\n\n", app.name)

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

main :: proc() {
	context.logger = log.create_console_logger()
	defer log.destroy_console_logger(context.logger)

	fmt.println(parse_command([]Command{{name = "foo"}}, os.args[1:]))
}

