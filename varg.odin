package varg

import "core:fmt"
import "core:os"
import "core:strings"

// name: string
// description: string
// version: string
// author: string
// commands: []Command
// flags: []Flag,
// args: []Argument
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

ParseError :: enum {
	None,
	CommandNotFound,
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

main :: proc() {
	help := Command {
		name      = "help",
		help_text = "show help message",
	}

	foo := Command {
		name      = "foo",
		help_text = "placeholder garbage",
	}

	dingus := Flag {
		name      = "dingus",
		help_text = "i am a dingus",
		short     = "d",
		long      = "dingus",
	}

	bar := Flag {
		name      = "bar",
		help_text = "more placeholder",
		short     = "b",
		long      = "bar",
	}

	baz := Argument {
		name      = "baz",
		help_text = "placeholder, but argument",
		short     = "z",
		long      = "baz",
	}

	app := App {
		name = "varg",
		description = "a command line argument parsing library written by a tard",
		author = "dogue",
		version = "1.0.0",
		commands = {help, foo},
		flags = {dingus, bar},
		args = {baz},
	}

	parsed := parse(app)

	fmt.println(parsed)
}

