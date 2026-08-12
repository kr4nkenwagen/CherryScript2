# CONTINUE

## Overview
`continue` skips the remainder of the current loop iteration and proceeds to the next iteration of the innermost loop.

## Example
```
for(var i = 0; i < 5; i += 1) {
  if(i == 3) {
    continue
  }
  println(i)
}
```
This prints 0, 1, 2, 4 (skips 3).
