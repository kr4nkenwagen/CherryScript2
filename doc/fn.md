# FN
## Overview
`fn` is used to declare functions. Functions have their own stack and will only be able to access its arguments and itself(This allows for recursion).

## Example
```
fn my_function(var arg1, var arg2) {
  println(arg1 .. ' ' .. arg2)
}

my_function("Hello", "World")
```
