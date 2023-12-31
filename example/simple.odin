package example

import "core:fmt"
import "core:os"
import "core:mem"
import "../../varg"

main :: proc() {
	// The `App` acts as a container for defined commands, flags, and arguments
	// It also contains metadata about the program
	//
	// * name: (required)
	// * version: (optional)
	// * description: (optional)
	// * author: (optional)
	// * auto_help: (default false)
	//
	// The values marked optional will not be displayed in help text if not set.
	// `auto_help` sets whether the parser should automatically print the help text
	// if no valid values could be parsed from the input. (similar to clap-rs behavior)
	app, err := varg.app_create(
		"my_app",
		version = "4.20.69",
		description = "an example app using varg",
		author = "dogue",
		auto_help = true,
	)

	if err != nil {
		fmt.eprintf("Error allocating memory for the app: %v", err)
		os.exit(1)
	}

	defer varg.app_destroy(app)

	// These procs return a `mem.Allocator_Error`, but we're not handling those for brevity
	//
	// A command is a string that acts as a subcommand to the app
	varg.add_command(app, "foo", help_text = "fights the foo", takes_value = false)

	// A flag is a boolean switch (does not take a value)
	varg.add_flag(app, "bar", short = "b", long = "bar", help_text = "enable bar-related features")

	// An argument is like a flag, except it requires a value to be passed to it (`my_app -z some_value`)
	varg.add_argument(app, "baz", short = "z", long = "baz", help_text = "provide your own baz")

	// ParsedArgs :: struct {
	// 	command: string,
	// 	flags:   map[string]bool,
	// 	args:    map[string]string,
	// }
	//
	// ParseError :: enum {
	// 	None,
	// 	UnexpectedEOF,
	// 	NoValidArgs,
	// }

	parsed_args, parse_err := varg.parse(app, os.args)

	switch parsed_args.command {
	case "foo":
	// do some foo stuff
	}

	if parsed_args.flags["bar"] {
		// do some bar stuff
	}

	if parsed_args.args["baz"] != "" {
		// do something with baz
	}
}

