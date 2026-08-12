# FOR
## Overview
The `for` loop repeatedly executes a block of code while a specified condition evaluates to true. `for` takes three expressions, *initializer*, *condition* and *post-iteration*. A `for`-loop should be structured like so; `for(initializer; condition; post-iteration) {}`.
| Component| Description |
|----------|-------------|
| *initializer* | Executed once before the loop starts. Typically used to declare and set up loop counters. |
| *condition* | Executes before each iteration. If this returns `false`, the loop instantly breaks. |
| *post-iteration* | Executed after each iteration before checking the condition again. Typically used to increment counters. |
## Example
```
for(var i = 0; i < 5; i+=1) {
  println(i)
}
```
