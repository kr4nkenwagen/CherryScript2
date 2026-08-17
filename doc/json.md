# JSON 
## Overview
The `json()` function initializes a JSON object. Fields can be accessed directly using dot notation, and new properties can be assigned dynamically at runtime.
It can be initialized with a string or a file.

## Example
```
var a = json('{ "name": "CherryScript", "version": 1, "settings": { "debug": true } }')
if (a.settings.debug) {
  println(a.name .. " Version: " .. a.version)
}

a.version += 1
a.patchnotes = "Bumped version"

```


```
var a = json(@"file")
a.member = "new value" # This will update the file as well as the variable object.
rm a
```
