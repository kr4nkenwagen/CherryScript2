# Time
## Overview
The `time` object provides access to individual components of a date and time instance. You can access date parts, time units, and calendar calculations directly using property getters (e.g., `time.minute`, `time.day_of_week`).
Most property names support both **singular and plural** forms interchangeably (e.g., `time.minute` and `time.minutes` return the same value).

## Properties
| Property / Aliases | Type | Description | Example Output |
| :--- | :--- | :--- | :--- |
| `year`, `years` | Integer | The full year | `2026` |
| `month`, `months` | Integer | Month of the year (`1` – `12`) | `8` |
| `month_name` | String | Lowercase name of the month name| `"march"` |
| `month_short_name` | String | Lowercase short name of the month name| `"jan"` |
| `day`, `days` | Integer | Day of the month (`1` – `31`) | `12` |
| `hour`, `hours` | Integer | Hour of the day (`0` – `23`) | `14` |
| `minute`, `minutes` | Integer | Minute of the hour (`0` – `59`) | `30` |
| `second`, `seconds` | Integer | Second of the minute (`0` – `59`) | `45` |
| `millisecond`, `milliseconds` | Integer | Sub-second milliseconds (`0` – `999`) | `123` |
| `microsecond`, `microseconds` | Integer | Sub-second microseconds (`0` – `999999`) | `123456` |
| `nanosecond`, `nanoseconds`, `nano` | Integer | Sub-second nanoseconds (`0` – `999999999`) | `123456789` |
| `weekday` | String | Lowercase name of the day of the week | `"wednesday"` |
| `day_of_week` | Integer | Zero-indexed day of the week (`0` = Monday, `6` = Sunday) | `2` |
| `day_of_year`, `year_day` | Integer | Day number of the current year (`1` – `366`) | `224` |
| `execution_time` | Float | Time since execution start in seconds | `1.5` |
---

## Example
```
# Accessing date and time components
var now = time.now();

print(now.year);        # 2026
print(now.month);       # 8
print(now.day);         # 12

print(now.hour);        # 14
print(now.minute);      # 30
print(now.second);      # 45

# Both singular and plural properties work identically
print(now.milliseconds); # 123
print(now.nano);         # 123456789

# Day metadata
print(now.weekday);     # "wednesday"
print(now.day_of_week); # 2 (Monday is 0, Sunday is 6)
print(now.day_of_year); # 224
```
