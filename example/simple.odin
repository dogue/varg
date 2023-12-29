package example

import "core:fmt"
import "../../varg"

main :: proc() {
	help := varg.Command {
		name      = "help",
		help_text = "show this message",
	}

	foo := varg.Command {
		name      = "foo",
		help_text = "an original placeholder",
	}

	bar := varg.Flag {
		name      = "bar",
		help_text = "an even more original placeholder",
		short     = "b",
		long      = "bar",
	}

	baz := varg.Argument {
		name      = "baz",
		help_text = "placeholder, but argument",
		short     = "z",
		long      = "baz",
	}

	app := varg.App {
		name = "varg-example",
		description = "a brief showcase of varg",
		author = "dogue",
		version = "1.0.0",
		// []varg.Command
		commands = {help, foo},
		// []varg.Flag
		flags = {bar},
		// []varg.Argument
		args = {baz},
	}

	varg.print_help(app)

	parsed_args := varg.parse(app)

	fmt.println(parsed_args)

	// ❯ odin run . -- foo -b --baz hellope
	// ParsedArgs{command = Command{name = "foo", help_text = "an original placeholder"}, flags = map[bar=true], args = map[baz="hellope"]}
}

