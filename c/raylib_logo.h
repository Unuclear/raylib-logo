#ifndef RAYLIB_LOGO_H
#define RAYLIB_LOGO_H

typedef struct {
	int x;
	int y;
} Vector2i;

typedef enum {
	Blink,            // Small dot blinking
	TopLeftSides,     // Top and left sides of the square growing out of the dot
	RightBottomSides, // Right and bottom sides growing to complete the square
	Letters,          // "raylib" letters appearing one by one
	ZoomOut,          // Zoom out and write "powered by" above the logo
	FadeOut,          // Fade out the entire logo
	Loaded,           // Blank the screen one last time
} LogoState;

#define LOGO_TEXT "raylib"
#define POWERED_BY_TEXT "powered by"

void DefaultRaylibLogoAnimation();

void DefaultRaylibLogoAnimationWithFrameRate(int fps);

void RaylibLogoAnimation(int fps, Color backgroundColor, Color logoColor, int squareStrokeWidth, Font* poweredByCustomFont, double poweredByFontSizeFactor, double poweredBySpacing);

#endif /* raylib_logo.h */
