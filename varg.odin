package varg

import "core:fmt"
import "core:os"
import "core:strings"

App :: struct {
	name:        string,
	description: string,
	version:     string,
	author:      string,
	commands:    []Command,
	flags:       []Flag,
	args:        []Argument,
	parsed_args: ParsedArgs,
}

Command :: struct {
	name:      string,
	help_text: string,
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
	command: Maybe(Command),
	flags:   map[string]bool,
	args:    map[string]string,
}

@(private)
parse_command :: proc(app: ^App) {
	raw_args := os.args[1:]
	for arg in raw_args {
		for cmd, i in app.commands {
			if arg == cmd.name {
				app.parsed_args.command = app.commands[i]
				return
			}
		}
	}
}

@(private)
prefix_args :: proc(s, l: string) -> (short, long: string) {
	short = strings.concatenate([]string{"-", s})
	long = strings.concatenate([]string{"--", l})
	return
}

@(private)
parse_flags :: proc(app: ^App) {
	raw_args := os.args[1:]
	for arg in raw_args {
		matched := match_flag(arg, app.flags)
		if matched != nil {
			app.parsed_args.flags[matched.?.name] = true
		}
	}
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
parse_args :: proc(app: ^App) {
	raw_args := os.args[1:]
	for arg, i in raw_args {
		matched := match_arg(arg, app.args)
		if matched != nil {
			value := match_value(i, raw_args)
			if value != nil do app.parsed_args.args[matched.?.name] = value.?
		}
	}
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
match_value :: proc(index: int, raw_args: []string) -> Maybe(string) {
	if len(raw_args) > index + 1 {
		return raw_args[index + 1]
	}

	return nil
}

parse :: proc(app: App) -> ParsedArgs {
	app := app
	parse_command(&app)
	parse_flags(&app)
	parse_args(&app)
	return app.parsed_args
}

print_help :: proc(app: App) {
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

