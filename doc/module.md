# MODULE
## Overview
`module` is used to import another cherry script file. This will import the external cherry script on the line of the `module` statements. This means that anything before the `module` cant access the module content. If module is pointed to a directory, it will attempt to import all .cherry scripts in that directory.

## Example
```
module "file/location/external.cherry"
```
