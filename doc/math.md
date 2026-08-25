# MATH

## Overview
The `math` module provides mathematical constants and functions. Functions are called using the `math.method(args...)` syntax.

---

## Constants

| Name | Description |
| :--- | :--- |
| `math.pi` | Ratio of a circle's circumference to its diameter (~3.14159) |
| `math.tau` | Ratio of a circle's circumference to its radius (~6.28318) |

---

## Functions

### Rounding & Restriction

| Function | Parameters | Returns | Description |
| :--- | :--- | :--- | :--- |
| `math.abs(x)` | `x`: Int or Float | Float | Absolute value of `x`. |
| `math.sign(x)` | `x`: Int or Float | Float | Returns `-1.0`, `0.0`, or `1.0` indicating the sign of `x`. |
| `math.floor(x)` | `x`: Int or Float | Float | Largest integer less than or equal to `x`. |
| `math.ceil(x)` | `x`: Int or Float | Float | Smallest integer greater than or equal to `x`. |
| `math.round(x)` | `x`: Int or Float | Float | Nearest integer to `x` (rounds half away from zero). |
| `math.trunc(x)` | `x`: Int or Float | Float | Integer part of `x` (truncates toward zero). |

### Min / Max / Clamp

| Function | Parameters | Returns | Description |
| :--- | :--- | :--- | :--- |
| `math.max(a, b)` | `a`, `b`: Int or Float | Float | Returns the larger of `a` and `b`. |
| `math.min(a, b)` | `a`, `b`: Int or Float | Float | Returns the smaller of `a` and `b`. |
| `math.clamp(val, min, max)` | `val`, `min`, `max`: Int or Float | Float | Clamps `val` to the range `[min, max]`. |

### Powers & Roots

| Function | Parameters | Returns | Description |
| :--- | :--- | :--- | :--- |
| `math.sqrt(x)` | `x`: Int or Float | Float | Square root of `x`. |

### Trigonometry

All trigonometric functions take and return values in **radians**.

| Function | Parameters | Returns | Description |
| :--- | :--- | :--- | :--- |
| `math.sin(x)` | `x`: Int or Float | Float | Sine of `x`. |
| `math.cos(x)` | `x`: Int or Float | Float | Cosine of `x`. |
| `math.tan(x)` | `x`: Int or Float | Float | Tangent of `x`. |
| `math.asin(x)` | `x`: Int or Float | Float | Arcsine of `x` (result in radians). |
| `math.acos(x)` | `x`: Int or Float | Float | Arccosine of `x` (result in radians). |
| `math.atan(x)` | `x`: Int or Float | Float | Arctangent of `x` (result in radians). |
| `math.atan2(y, x)` | `y`, `x`: Int or Float | Float | Angle in radians between the positive x-axis and the point `(x, y)`. |

### Logarithms

| Function | Parameters | Returns | Description |
| :--- | :--- | :--- | :--- |
| `math.log(val, base)` | `val`, `base`: Int or Float | Float | Logarithm of `val` with the given `base`. |

### Interpolation

| Function | Parameters | Returns | Description |
| :--- | :--- | :--- | :--- |
| `math.lerp(val, min, max)` | `val`, `min`, `max`: Int or Float | Float | Linearly interpolates `val` (0.0-1.0) between `min` and `max`. |

### Distance

| Function | Parameters | Returns | Description |
| :--- | :--- | :--- | :--- |
| `math.hypot(x, y)` | `x`, `y`: Int or Float | Float | Length of the hypotenuse: `sqrt(x*x + y*y)`. |

### Random

| Function | Parameters | Returns | Description |
| :--- | :--- | :--- | :--- |
| `math.random()` | *(none)* | Float | Random float in the range `[0.0, 1.0)`. |
| `math.random_range(min, max)` | `min`, `max`: Int or Float | Float | Random float in the range `[min, max)`. |

---

## Examples

### Constants
```
println(math.pi)   # 3.141592653589793
println(math.tau)  # 6.283185307179586
```

### Rounding
```
println(math.floor(2.7))   # 2.0
println(math.ceil(2.3))    # 3.0
println(math.round(2.5))   # 3.0
println(math.round(2.4))   # 2.0
println(math.trunc(-3.9))  # -3.0
```

### Abs and Sign
```
println(math.abs(-42))    # 42.0
println(math.sign(-42))   # -1.0
println(math.sign(0))     # 0.0
println(math.sign(42))    # 1.0
```

### Min, Max, Clamp
```
println(math.max(3, 7))            # 7.0
println(math.min(3, 7))            # 3.0
println(math.clamp(15, 1, 10))     # 10.0
println(math.clamp(-5, 1, 10))     # 1.0
```

### Square Root
```
println(math.sqrt(9))   # 3.0
println(math.sqrt(2))   # 1.4142135
```

### Trigonometry
```
println(math.sin(0))    # 0.0
println(math.cos(0))    # 1.0
println(math.tan(0))    # 0.0
println(math.atan2(1, 1))  # 0.7853982
```

### Logarithm
```
println(math.log(100, 10))  # 2.0
println(math.log(8, 2))     # 3.0
```

### Hypotenuse
```
println(math.hypot(3, 4))  # 5.0
```

### Random
```
var r = math.random()
println(r)                  # random float between 0.0 and 1.0

var r2 = math.random_range(10, 20)
println(r2)                 # random float between 10.0 and 20.0
```

### Lerp
```
println(math.lerp(0.5, 0, 100))  # 50.0
println(math.lerp(1.0, 10, 20))  # 20.0
```
