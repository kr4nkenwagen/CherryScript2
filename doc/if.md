# IF
## Overview
`if`-blocks are used to create alternating execution paths. `if`-blocks can be followed by `elif`-blocks or `else`-blocks.

| Block | Condition |Repeatable| Description |
|-------|-----------|----------|-------------|
| `if` | Yes | No | This is the first block. this block cant be repeated in the `if`-block chain.|
| `elif` | Yes | Yes | This can be used following an `if`-block. `elif`-blocks have their own condition. This can be repeated as many times as needed.|
| `else` | No | No |This should be the last block in the `if`-block chain. This block has no condition and will always be executed if no preceding `if` or `if` condition was met. `else`-block cannot be repeated in the `if`-block chain.|
## Example
```
if(true){
  #This will always be executed.
} else {
  #This will never be executed.
}
```

```
for(var i = 0; i < 5; i+=1) {
  if(i == 0) {
  println("First iteration.")
  } elif(i == 4) {
    println("Last iteration.")
  } elif(i == 2) {
    println("Middle iteration.")
  } else {
    println("Other iteration.")
  }
}

```
