# Terminal

## Overview
The `terminal` object provides real-time dimensions of the active console window. It exposes properties to retrieve character grid bounds (rows and columns) as well as absolute pixel dimensions, enabling responsive CLI layouts, canvas rendering, and ASCII art scaling.

---

## Properties

| Property | Type | Description | Example Output |
| :--- | :--- | :--- | :--- |
| `width` | Integer | The terminal width in character columns | `80` |
| `height` | Integer | The terminal height in character rows | `24` |
| `pixel_width` | Integer | The total horizontal terminal window size in pixels | `1920` |
| `pixel_height` | Integer | The total vertical terminal window size in pixels | `1080` |

---

## Examples

### Reading Terminal Dimensions
 
```
println("Character Grid: " ,, terminal.width .. "x" .. terminal.height)
println("Pixel Grid: " .. terminal.pixel_width .. "x" .. terminal.pixel_height)
```

### Dynamic ASCII Separator Bar
```
var line = ""
for (var i = 0; i < terminal.width; i += 1) {
  line += "="
}
println(line)
remove line
```

### Calculating Cell Aspect Ratio
```
var cell_width = terminal.pixel_width / terminal.width
var cell_height = terminal.pixel_height / terminal.height

println("Character cell size: " .. cell_width .. "px by " .. cell_height .. "px")
remove cell_width, cell_height
```
