# GET
## Overview
The `get()` attempts a get request to the supplied endpoint and returns it as a [json](json.md) object.

## Example
```
var res = get("https://polisen.se/api/events")
for(var i = 0; i <len(res); i+=1){
  if (res[i].location.name == "Kronobergs län") {
      println(res[i].name)
    }
}
```
