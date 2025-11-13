/*******************************************************************************************
* This file is based on original work by Ramon Santamaria (https://github.com/raysan5),
* licensed under the zlib/libpng license: https://opensource.org/licenses/Zlib
*
* Modifications by Unuclear, 2025:
* - Optimized drawing of logo with render textures
* - Added zoom-out animation with "powered by" text
*
* These modifications are dual-licensed under the zlib/libpng license and the
* BSD Zero Clause License (0BSD): https://opensource.org/licenses/0bsd
*
* Note: This dual licensing applies only to the modifications listed above.
* The remainder of the code remains under the original zlib/libpng license (see below),
* which must be retained in full.
********************************************************************************************

Copyright (c) 2013-2025 Ramon Santamaria (@raysan5)

This software is provided "as-is", without any express or implied warranty. In no event
will the authors be held liable for any damages arising from the use of this software.

Permission is granted to anyone to use this software for any purpose, including commercial
applications, and to alter it and redistribute it freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not claim that you
wrote the original software. If you use this software in a product, an acknowledgment
in the product documentation would be appreciated but is not required.

2. Altered source versions must be plainly marked as such, and must not be misrepresented
as being the original software.

3. This notice may not be removed or altered from any source distribution.
********************************************************************************************/

#include <stddef.h>

#include "raylib.h"

#include "raylib_logo.h"


void DefaultRaylibLogoAnimation() {
	DefaultRaylibLogoAnimationWithFrameRate(60);
}


void DefaultRaylibLogoAnimationWithFrameRate(int fps) {
	RaylibLogoAnimation(fps, RAYWHITE, BLACK, 16, NULL, 3, 8);
}


void RaylibLogoAnimation(int fps, Color backgroundColor, Color logoColor, int squareStrokeWidth, Font* poweredByCustomFont, double poweredByFontSizeFactor, double poweredBySpacing) {
	// Initialization
	//--------------------------------------------------------------------------------------
	// Settings
	int squareGrowthRate = squareStrokeWidth / 4; // side growth per frame
	int squareSide = squareStrokeWidth * squareStrokeWidth;
	int squareSideNoOverlap = squareSide - squareStrokeWidth; // to prevent overlap with the top side
	//int squareFillSize = squareSideNoOverlap - squareStrokeWidth; // inner square

	Font poweredByFont;
	if (poweredByCustomFont)
		poweredByFont = *poweredByCustomFont;
	else
		poweredByFont = GetFontDefault();

	float poweredByFontSize = (float)poweredByFont.baseSize * poweredByFontSizeFactor;
	Vector2 poweredByDimensions = MeasureTextEx(poweredByFont, POWERED_BY_TEXT, poweredByFontSize, poweredBySpacing);
	//-------------------------------------------
	// State variables
	LogoState state = Blink;
	unsigned int framesCounter = 0;
	int topSide = squareStrokeWidth, leftSide = 0, bottomSide = 0, rightSide = 0; // start with a dot of 16x16 (by default)
	unsigned int lettersCount = 0;
	float poweredByAlpha = 0.0f;
	float alpha = 1.0f;
	//-------------------------------------------
	// Render textures
	RenderTexture2D squareRt = LoadRenderTexture(squareSide, squareSide);
	RenderTexture2D logoRt = LoadRenderTexture(squareSide, squareSide);
	//-------------------------------------------
	// Positioning
	int screenWidth, screenHeight, lastScreenWidth = 0, lastScreenHeight = 0;
	Vector2 screenCenter = {};
	Vector2i logoPosition = {};
	int logoPositionOffset = squareSide / 2;
	Vector2 poweredByPosition = {};
	Vector2 poweredByPositionOffsets = { poweredByDimensions.x / 2.0f, poweredByDimensions.y + poweredBySpacing };
	//-------------------------------------------
	// Camera
	Camera2D camera = { 0 };
	camera.zoom = 1.0f;
	//-------------------------------------------
	// FPS
	SetTargetFPS(fps);
	//--------------------------------------------------------------------------------------

	while (!WindowShouldClose()) {
		// Update
		//----------------------------------------------------------------------------------
		// On Enter or screen tap, skip logo animation
		if (IsKeyPressed(KEY_ENTER) || IsGestureDetected(GESTURE_TAP))
			state = Loaded;

		switch (state) {
			case Blink:
				framesCounter++;

				if (framesCounter == 60) {
					state = TopLeftSides;
					framesCounter = 0; // Reset for later reuse
				}

				break;

			case TopLeftSides:
				topSide += squareGrowthRate;
				leftSide += squareGrowthRate;

				if (topSide == squareSide)
					state = RightBottomSides;

				break;

			case RightBottomSides:
				rightSide += squareGrowthRate;

				if (rightSide == squareSideNoOverlap) {
					state = Letters;

					// Logo square is now fully loaded and will not be changed any more
					BeginTextureMode(squareRt);
					{
						DrawRectangle(0, 0, topSide, squareStrokeWidth, logoColor);
						DrawRectangle(0, squareStrokeWidth, squareStrokeWidth, leftSide, logoColor);

						DrawRectangle(squareSideNoOverlap, squareStrokeWidth, squareStrokeWidth, rightSide, logoColor);
						DrawRectangle(squareStrokeWidth, squareSideNoOverlap, bottomSide, squareStrokeWidth, logoColor);

						//DrawRectangle(squareStrokeWidth, squareStrokeWidth, squareFillSize, squareFillSize, backgroundColor);
					}
					EndTextureMode();
				} else {
					bottomSide += squareGrowthRate; // to prevent overlap with left and right sides
				}

				break;

			case Letters:
				framesCounter++;

				// One letter every 8 frames
				if (framesCounter == 8) {
					lettersCount++;
					framesCounter = 0;
				}

				if (lettersCount >= 10) {
					state = ZoomOut;

					// The logo itself is now fully loaded
					BeginTextureMode(logoRt);
					{
						DrawTextureRec(
							squareRt.texture,
							(Rectangle){0.0f, 0.0f, squareRt.texture.width, -squareRt.texture.height}, // y-axis is flipped
							(Vector2){},
							WHITE
						);

						DrawText(LOGO_TEXT, 84, 176, 50, logoColor);
					}
					EndTextureMode();
				}

				break;

			case ZoomOut:
				camera.zoom -= 0.0025f;

				if (camera.zoom <= 0.85f)
					state = FadeOut;
				else if (poweredByAlpha >= 1.0f)
					poweredByAlpha = 1.0f;
				else
					poweredByAlpha += 0.02f;

				break;

			case FadeOut:
				alpha -= 0.02f;

				if (alpha <= 0.0f)
					state = Loaded;

				break;
		}

		if (state == Loaded)
			break;

		screenWidth = GetScreenWidth();
		screenHeight = GetScreenHeight();

		// If screen dimensions have changed
		if (screenWidth != lastScreenWidth || screenHeight != lastScreenHeight) {
			screenCenter.x = (float)screenWidth / 2.0f;
			screenCenter.y = (float)screenHeight / 2.0f;

			// Adjust logo position
			logoPosition.x = (int)screenCenter.x - logoPositionOffset;
			logoPosition.y = (int)screenCenter.y - logoPositionOffset;

			// If camera is used (also implies that "powered by" is displayed)
			if (camera.zoom < 1.0f) {
				camera.target.x = screenCenter.x;
				camera.target.y = screenCenter.y;

				camera.offset.x = screenCenter.x;
				camera.offset.y = screenCenter.y;

				poweredByPosition.x = screenCenter.x - poweredByPositionOffsets.x;
				poweredByPosition.y = (float)logoPosition.y - poweredByPositionOffsets.y;
			}
		}
		//----------------------------------------------------------------------------------

		// Draw
		//----------------------------------------------------------------------------------
		BeginDrawing();
		{
			ClearBackground(backgroundColor);

			switch (state) {
				case Blink:
					if ((framesCounter / 15) % 2)
						DrawRectangle(logoPosition.x, logoPosition.y, squareStrokeWidth, squareStrokeWidth, logoColor);
					break;

				case TopLeftSides:
					DrawRectangle(logoPosition.x, logoPosition.y, topSide, squareStrokeWidth, logoColor);
					DrawRectangle(logoPosition.x, logoPosition.y + squareStrokeWidth, squareStrokeWidth, leftSide, logoColor);
					break;

				case RightBottomSides:
					DrawRectangle(logoPosition.x, logoPosition.y, topSide, squareStrokeWidth, logoColor);
					DrawRectangle(logoPosition.x, logoPosition.y + squareStrokeWidth, squareStrokeWidth, leftSide, logoColor);
					DrawRectangle(logoPosition.x + squareSideNoOverlap, logoPosition.y + squareStrokeWidth, squareStrokeWidth, rightSide, logoColor);
					DrawRectangle(logoPosition.x + squareStrokeWidth, logoPosition.y + squareSideNoOverlap, bottomSide, squareStrokeWidth, logoColor);
					break;

				case Letters:
					DrawTextureRec(
						squareRt.texture,
						(Rectangle){0.0f, 0.0f, squareRt.texture.width, -squareRt.texture.height}, // y-axis is flipped
						(Vector2){logoPosition.x, logoPosition.y},
						WHITE
					);
					DrawText(TextSubtext(LOGO_TEXT, 0, lettersCount), logoPosition.x + 84, logoPosition.y + 176, 50, logoColor);
					break;

				case ZoomOut:
					BeginMode2D(camera);
					{
						DrawTextEx(poweredByFont, POWERED_BY_TEXT, poweredByPosition, poweredByFontSize, poweredBySpacing, Fade(logoColor, poweredByAlpha));

						DrawTextureRec(
							logoRt.texture,
							(Rectangle){0.0f, 0.0f, logoRt.texture.width, -logoRt.texture.height}, // y-axis is flipped
							(Vector2){logoPosition.x, logoPosition.y},
							WHITE
						);
					}
					EndMode2D();
					break;

				case FadeOut:
					BeginMode2D(camera);
					{
						DrawTextEx(poweredByFont, POWERED_BY_TEXT, poweredByPosition, poweredByFontSize, poweredBySpacing, Fade(logoColor, alpha));

						DrawTextureRec(
							logoRt.texture,
							(Rectangle){0.0f, 0.0f, logoRt.texture.width, -logoRt.texture.height}, // y-axis is flipped
							(Vector2){logoPosition.x, logoPosition.y},
							Fade(WHITE, alpha) // fade out entire texture
						);
					}
					EndMode2D();
					break;
			}
		}
		EndDrawing();
		//----------------------------------------------------------------------------------
	}

	// Cleanup
	//--------------------------------------------------------------------------------------
	UnloadRenderTexture(squareRt);
	UnloadRenderTexture(logoRt);
	//--------------------------------------------------------------------------------------
}
