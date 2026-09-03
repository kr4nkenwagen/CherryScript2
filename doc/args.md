# ARGS

## Overview
`args` is a built-in global array of command-line arguments passed to a `.cherry` script when it is executed. It uses zero-based indexing, where `args[0]` is the first argument after the script filename.

## Passing arguments
Arguments are passed after the script file when running the interpreter:

```
cherry script.cherry arg1 arg2 arg3
```

Inside `script.cherry`, the arguments are available as:
- `args[0]` → `"arg1"`
- `args[1]` → `"arg2"`
- `args[2]` → `"arg3"`

## Example
```
println(args[0])
println(args[1])
```

Running the following:
```
cherry script.cherry hello world
```

Outputs:
```
hello
world
```

## Notes
- All arguments are available as [`string`](string.md) values, even numeric-looking ones.
- When no arguments are passed, `args` is an empty array.
- The number of arguments can be obtained with [`len`](len.md): `len(args)`.