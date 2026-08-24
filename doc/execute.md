# EXECUTE ($)
## Overview
Executes a system command and returns its stdout as a string.

## Syntax
```
$"command args"
```

The expression after `$` must evaluate to a string. The string is split on whitespace into command and arguments, then executed as a system process. The command's stdout is returned as a Cherry string.

## Examples
```
var cwd = $"pwd"
println(cwd)

var files = $"ls -la src"
println(files)

var len = $"wc -l src/main.odin"
println(len)
```

## Notes
- The command is executed directly (no shell), so shell features like pipes, redirects, and environment variable expansion are not available.
- On failure (command not found, non-zero exit), a runtime error is raised.
