# FILE
## Overview
`file` type is a file handler that allows the script to interact with the file system.

## Example
###Initialize a file handler.
```
var file = @"file.txt"
```

###Write to file 
Using the `<-` operator you can write content to a file. The content will be followed by a `\n`
```
file<-1 = "text"
```
*This will input the string `"text"` to line `1` in `file`.*

### Return file content
```
var file_content = file->1
```
*This will save line `1` of `file` to variable file_content.*

