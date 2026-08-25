# EXECUTE ($)

## Overview
Executes a system command and returns a JSON object containing the command's output.

## Syntax
```
$"command args"
```

The expression after `$` must evaluate to a string. The string is split on whitespace into command and arguments, then executed as a system process.

## Return Value

Returns a JSON object with three properties:

| Property | Type | Description |
| :--- | :--- | :--- |
| `stdout` | String | Standard output from the command. |
| `stderr` | String | Standard error from the command. |
| `exit_code` | Int | The process exit code (0 typically means success). |

## Examples

### Basic usage
```
var result = $"pwd"
println(result.stdout)       # /current/working/directory
println(result.exit_code)    # 0
```

### Capturing stderr
```
var result = $"ls /nonexistent_path"
println(result.stderr)       # No such file or directory
println(result.exit_code)    # 2
```

### Accessing individual properties
```
var echo = $"echo hello world"
assert(echo.stdout == "hello world\n", "stdout captured")
assert(echo.stderr == "", "no errors")
assert(echo.exit_code == 0, "success")
```

### Using in expressions
```
var cmd = $"echo -n cherry"
var output_len = len(cmd.stdout)
println(output_len)          # 6
```

## Notes
- The command is executed directly (no shell), so shell features like pipes, redirects, and environment variable expansion are not available.
- On failure (command not found), a runtime error is raised.
