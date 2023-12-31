package varg

import "core:strings"
import "core:testing"

@(test)
t_parse_command :: proc(t: ^testing.T) {
	tests := []struct {
		input: string,
		expected: string
	}{
		{"shake", "shake"},
		{"bake cake", "bake"},
		{"12 snake flake", "snake"},
	}

	commands := []Command {
		{ name = "shake" },
		{ name = "bake" },
		{ name = "snake" },
	}

	for test in tests {
		args := strings.split(test.input, " ")
		cmd, err := parse_command(commands, args)

		testing.expect_value(t, err, ParseError.None)
		testing.expect_value(t, cmd.name, test.expected)
	}
}

@(test)
t_parse_command_with_value :: proc(t: ^testing.T) {
	tests := []struct {
		input: string, 
		expected_name: string,
		expected_err: ParseError,
	}{
		{"git push", "push", .None},
		{"123 git paid", "paid", .None},
		{"git rekt nerd", "rekt", .None},
		{"git", "", .RequiredValueNotProvided}
	}

	commands := []Command {{name = "git", takes_value = true}}

	for test in tests {
		args := strings.split(test.input, " ")
		cmd, err := parse_command(commands, args)

		testing.expect_value(t, err, test.expected_err)
		testing.expect_value(t, cmd.value, test.expected_name)
	}
}

@(test)
t_parse_flags :: proc(t: ^testing.T) {
	tests := []struct {
		input: string,
		expected: map[string]bool,
	}{
		{"foo -b", {"blurple" = true}},
		{"foo -d -e", {"dangly" = true, "enigmatic" = true}},
		{"foo --long-boi-flag --enigmatic", {"long-boi-flag" = true, "enigmatic" = true}},
	}

	flags := []Flag {
		{name = "blurple", short = "b"},
		{name = "dangly", short = "d"},
		{name = "enigmatic", short = "e", long = "--enigmatic"},
		{name = "long-boi-flag", long = "long-boi-flag"},
	}

	for test in tests {
		args := strings.split(test.input, " ")
		flags := parse_flags(flags, args)

		for k, v in flags {
			testing.expect_value(t, v, test.expected[k])
		}
	}
}
