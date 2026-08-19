# FOR
## Overview
The `for` loop repeatedly executes a block of code based on a condition. It can be used as a traditional three-part loop or as a single-condition loop.

## Syntax
A `for` loop supports two forms:
* **Three-part loop:** `for(initializer; condition; post-iteration) {}`
* **Condition-only loop:** `for(condition) {}`

### Components
| Component | Description |
|---|---|
| *initializer* | *(Optional)* Executed once before the loop starts. Typically used to declare loop counters. |
| *condition* | Executed before each iteration. If this returns `false`, the loop terminates. |
| *post-iteration* | *(Optional)* Executed after each iteration before checking the condition again. Typically used to update counters. |

## Examples

**Three-Part Loop**
```
for(var i = 0; i < 5; i+=1) {
  println(i)
}
```

**Condition-Only Loop**
```
var i = 0
for(i < 5) {
  println(i)
  i += 1
}
```
