# STRING

## Overview
Strings are sequences of characters enclosed in double quotes `"..."` or single quotes `'...'`. They support arithmetic operators for manipulation (`+`, `-`, `*`, `/`, `%`, `..`) as well as a set of methods for common text operations.

Methods are called using the `string.method(obj, args...)` syntax.

---

## Methods

| Method | Parameters | Description |
| :--- | :--- | :--- |
| `string.contains(str, sub)` | `str`: String, `sub`: String | Returns `true` if `sub` is found within `str`. |
| `string.first_index_of(str, sub)` | `str`: String, `sub`: String | Returns the index of the first occurrence of `sub`, or `-1` if not found. |
| `string.last_index_of(str, sub)` | `str`: String, `sub`: String | Returns the index of the last occurrence of `sub`, or `-1` if not found. |
| `string.first_index_of_from(str, sub, start)` | `str`: String, `sub`: String, `start`: Int | Returns the index of the first occurrence of `sub` starting from `start`, or `-1` if not found. |
| `string.trim_start(str)` | `str`: String | Returns a copy with leading whitespace removed. |
| `string.trim_end(str)` | `str`: String | Returns a copy with trailing whitespace removed. |
| `string.trim(str)` | `str`: String | Returns a copy with leading and trailing whitespace removed. |
| `string.to_upper(str)` | `str`: String | Returns an uppercase copy of the string. |
| `string.to_lower(str)` | `str`: String | Returns a lowercase copy of the string. |
| `string.pad_start(str, count)` | `str`: String, `count`: Int | Pads the string on the left with spaces to reach the target length. |
| `string.pad_end(str, count)` | `str`: String, `count`: Int | Pads the string on the right with spaces to reach the target length. |
| `string.replace_all(str, old, new)` | `str`: String, `old`: String, `new`: String | Returns a copy with every occurrence of `old` replaced by `new`. |

---

## Examples

### Searching
```
var s = "Hello, World!"
println(string.contains(s, "World"))         # true
println(string.first_index_of(s, "World"))   # 7
println(string.last_index_of(s, "l"))        # 10
println(string.first_index_of_from(s, "l", 5))  # 10
```

### Trimming and Casing
```
var s = "  Hello, World!  "
println(string.trim_start(s))        # "Hello, World!  "
println(string.trim_end(s))          # "  Hello, World!"
println(string.trim(s))              # "Hello, World!"
println(string.to_upper(string.trim(s)))  # "HELLO, WORLD!"
println(string.to_lower(string.trim(s)))  # "hello, world!"
```

### Padding
```
var s = "hi"
println(string.pad_start(s, 5))   # "   hi"
println(string.pad_end(s, 5))     # "hi   "
```

### Replace
```
var s = "hello world, hello cherry"
println(string.replace_all(s, "hello", "hi"))   # "hi world, hi cherry"
```
