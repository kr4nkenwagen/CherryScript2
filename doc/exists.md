# EXISTS
## Overview
`exists` is used to check if files exists. This can only be used on variables containing a file. `exists` returns `true` if the file exists or `false` if not.

## Example
```
var file = @"file.txt"
if(exists(file)) {
  # This executes if the file exists.
}
```
