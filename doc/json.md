# JSON 
## Overview
The `json()` function initializes a JSON object. Fields can be accessed directly using dot notation, and new properties can be assigned dynamically at runtime.

## Example
```
global var a = json('{ "name": "CherryScript", "version": 1, "settings": { "debug": true } }')
if (a.settings.debug) {
  println(a.name .. " Version: " .. a.version)
}

a.version += 1
a.patchnotes = "Bumped version"
```
