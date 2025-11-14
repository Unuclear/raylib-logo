# Raylib logo animation

Customizable startup animation for games and applications using [raylib](https://github.com/raysan5/raylib).
It is based on this [raylib example](https://github.com/raysan5/raylib/blob/master/examples/shapes/shapes_logo_raylib_anim.c).

## Use

There are a C and an Odin implementation. They are identical in functionality.

### C

```c
#include "raylib.h"
#include "raylib_logo.h"

int main() {
    // Window initialization
    SetConfigFlags(FLAG_WINDOW_RESIZABLE);
    InitWindow(360, 360, "raylib logo test");
    SetWindowMinSize(360, 360);

    DefaultRaylibLogoAnimationWithFrameRate(90);

    CloseWindow();
    return 0;
}
```

### Odin

Assuming the following folder structure:

```
├── raylib_logo/
│   └── raylib_logo.odin
└── main.odin
```

```odin
package main

import "vendor:raylib"

import "raylib_logo"

main :: proc() {
    // Window initialization
    raylib.SetConfigFlags({raylib.ConfigFlag.WINDOW_RESIZABLE})
    raylib.InitWindow(360, 360, "raylib logo test")
    defer raylib.CloseWindow()
    raylib.SetWindowMinSize(360, 360)

    raylib_logo.raylibLogoAnimation(fps=90)
}
```
