/*******************************************************************************************
* This file is based on original work by Ramon Santamaria (https://github.com/raysan5),
* licensed under the zlib/libpng license: https://opensource.org/licenses/Zlib
*
* Modifications by Unuclear, 2025:
* - Translated code from C to Odin
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

package logo

import "core:c"
import "vendor:raylib"


Vector2i :: [2]c.int

LogoState :: enum {
	Blink,            // Small dot blinking
	TopLeftSides,     // Top and left sides of the square growing out of the dot
	RightBottomSides, // Right and bottom sides growing to complete the square
	Letters,          // "raylib" letters appearing one by one
	ZoomOut,          // Zoom out and write "powered by" above the logo
	FadeOut,          // Fade out the entire logo
	Loaded,           // Blank the screen one last time
}


LogoText: cstring : "raylib"
PoweredByText: cstring: "powered by"


raylibLogoAnimation :: proc(
	fps: c.int = 60,
	backgroundColor: raylib.Color = raylib.RAYWHITE,
	logoColor: raylib.Color = raylib.BLACK,
	squareStrokeWidth: c.int = 16,
	poweredByCustomFont: ^raylib.Font = nil,
	poweredByFontSizeFactor: c.float = 3,
	poweredBySpacing: c.float = 8
) {
	// Initialization
	//--------------------------------------------------------------------------------------
	// Settings
	squareGrowthRate := squareStrokeWidth / 4 // side growth per frame
	squareSide := squareStrokeWidth * squareStrokeWidth
	squareSideNoOverlap := squareSide - squareStrokeWidth // to prevent overlap with the top side
	//squareFillSize := squareSideNoOverlap - squareStrokeWidth // inner square

	poweredByFont: raylib.Font
	if poweredByCustomFont != nil do poweredByFont = poweredByCustomFont^
	else do poweredByFont = raylib.GetFontDefault()

	poweredByFontSize := c.float(poweredByFont.baseSize) * poweredByFontSizeFactor
	poweredByDimensions := raylib.MeasureTextEx(poweredByFont, PoweredByText, poweredByFontSize, poweredBySpacing)
	//-------------------------------------------
	// State variables
	state := LogoState.Blink
	framesCounter: uint
	topSide, leftSide, bottomSide, rightSide: c.int = squareStrokeWidth, 0, 0, 0 // start with a dot of 16x16 (by default)
	lettersCount: c.int
	poweredByAlpha: c.float = 0
	alpha: c.float = 1
	//-------------------------------------------
	// Render textures
	squareRt := raylib.LoadRenderTexture(squareSide, squareSide)
	defer raylib.UnloadRenderTexture(squareRt)
	logoRt := raylib.LoadRenderTexture(squareSide, squareSide)
	defer raylib.UnloadRenderTexture(logoRt)
	//-------------------------------------------
	// Positioning
	screenWidth, screenHeight, lastScreenWidth, lastScreenHeight: c.int
	screenCenter := raylib.Vector2{}
	logoPosition := Vector2i{}
	logoPositionOffset: c.int = squareSide / 2
	poweredByPosition := raylib.Vector2{}
	poweredByPositionOffsets := raylib.Vector2{poweredByDimensions.x / 2, poweredByDimensions.y + poweredBySpacing}
	//-------------------------------------------
	// Camera
	camera := raylib.Camera2D{target={}, offset={}, rotation=0.0, zoom=1.0}
	//-------------------------------------------
	// FPS
	raylib.SetTargetFPS(fps)
	//--------------------------------------------------------------------------------------

	logo_loop: for !raylib.WindowShouldClose() {
		// Update
		//----------------------------------------------------------------------------------
		// On Enter or screen tap, skip logo animation
		if raylib.IsKeyPressed(raylib.KeyboardKey.ENTER) || raylib.IsGestureDetected(raylib.Gesture.TAP) {
			state = .Loaded
		}

		switch state {
			case .Blink:
				framesCounter += 1

				if framesCounter == 60 {
					state = .TopLeftSides
					framesCounter = 0 // Reset for later reuse
				}

			case .TopLeftSides:
				topSide += squareGrowthRate
				leftSide += squareGrowthRate

				if topSide == squareSide do state = .RightBottomSides

			case .RightBottomSides:
				rightSide += squareGrowthRate

				if rightSide == squareSideNoOverlap {
					state = .Letters

					// Logo square is now fully loaded and will not be changed any more
					raylib.BeginTextureMode(squareRt)
					defer raylib.EndTextureMode()

					raylib.DrawRectangle(0, 0, topSide, squareStrokeWidth, logoColor)
					raylib.DrawRectangle(0, squareStrokeWidth, squareStrokeWidth, leftSide, logoColor)

					raylib.DrawRectangle(squareSideNoOverlap, squareStrokeWidth, squareStrokeWidth, rightSide, logoColor)
					raylib.DrawRectangle(squareStrokeWidth, squareSideNoOverlap, bottomSide, squareStrokeWidth, logoColor)

					//raylib.DrawRectangle(squareStrokeWidth, squareStrokeWidth, squareFillSize, squareFillSize, backgroundColor)
				} else do bottomSide += squareGrowthRate // to prevent overlap with left and right sides

			case .Letters:
				framesCounter += 1

				// One letter every 8 frames
				if framesCounter == 8 {
					lettersCount += 1
					framesCounter = 0
				}

				if lettersCount >= 10 {
					state = .ZoomOut

					// The logo itself is now fully loaded
					raylib.BeginTextureMode(logoRt)
					defer raylib.EndTextureMode()

					raylib.DrawTextureRec(
						squareRt.texture,
						raylib.Rectangle{0, 0, c.float(squareRt.texture.width), -c.float(squareRt.texture.height)}, // y-axis is flipped
						raylib.Vector2{0, 0},
						raylib.WHITE
					)

					raylib.DrawText(LogoText, 84, 176, 50, logoColor)
				}

			case .ZoomOut:
				camera.zoom -= 0.0025

				if camera.zoom <= 0.85 do state = .FadeOut
				else if poweredByAlpha >= 1 do poweredByAlpha = 1
				else do poweredByAlpha += 0.02

			case .FadeOut:
				alpha -= 0.02

				if alpha <= 0 do state = .Loaded

			case .Loaded:
		}

		screenWidth, screenHeight = raylib.GetScreenWidth(), raylib.GetScreenHeight()

		// If screen dimensions have changed
		if screenWidth != lastScreenWidth || screenHeight != lastScreenHeight {
			screenCenter.x = c.float(screenWidth) / 2
			screenCenter.y = c.float(screenHeight) / 2

			// Adjust logo position
			logoPosition.x = c.int(screenCenter.x) - logoPositionOffset
			logoPosition.y = c.int(screenCenter.y) - logoPositionOffset

			// If camera is used (also implies that "powered by" is displayed)
			if camera.zoom < 1 {
				camera.target.x, camera.target.y = screenCenter.x, screenCenter.y
				camera.offset.x, camera.offset.y = screenCenter.x, screenCenter.y

				poweredByPosition.x = screenCenter.x - poweredByPositionOffsets.x
				poweredByPosition.y = c.float(logoPosition.y) - poweredByPositionOffsets.y
			}
		}
		//----------------------------------------------------------------------------------

		// Draw
		//----------------------------------------------------------------------------------
		raylib.BeginDrawing()
		defer raylib.EndDrawing()

		raylib.ClearBackground(backgroundColor)

		switch state {
			case .Blink:
				if (framesCounter / 15) % 2 != 0 {
					raylib.DrawRectangle(logoPosition.x, logoPosition.y, squareStrokeWidth, squareStrokeWidth, logoColor)
				}

			case .TopLeftSides:
				raylib.DrawRectangle(logoPosition.x, logoPosition.y, topSide, squareStrokeWidth, logoColor)
				raylib.DrawRectangle(logoPosition.x, logoPosition.y + squareStrokeWidth, squareStrokeWidth, leftSide, logoColor)

			case .RightBottomSides:
				raylib.DrawRectangle(logoPosition.x, logoPosition.y, topSide, squareStrokeWidth, logoColor)
				raylib.DrawRectangle(logoPosition.x, logoPosition.y + squareStrokeWidth, squareStrokeWidth, leftSide, logoColor)

				raylib.DrawRectangle(logoPosition.x + squareSideNoOverlap, logoPosition.y + squareStrokeWidth, squareStrokeWidth, rightSide, logoColor)
				raylib.DrawRectangle(logoPosition.x + squareStrokeWidth, logoPosition.y + squareSideNoOverlap, bottomSide, squareStrokeWidth, logoColor)

			case .Letters:
				raylib.DrawTextureRec(
					squareRt.texture,
					raylib.Rectangle{0, 0, c.float(squareRt.texture.width), -c.float(squareRt.texture.height)}, // y-axis is flipped
					raylib.Vector2{c.float(logoPosition.x), c.float(logoPosition.y)},
					raylib.WHITE
				)

				raylib.DrawText(raylib.TextSubtext(LogoText, 0, lettersCount), logoPosition.x + 84, logoPosition.y + 176, 50, logoColor)

			case .ZoomOut:
				{
					raylib.BeginMode2D(camera)
					defer raylib.EndMode2D()

					raylib.DrawTextEx(poweredByFont, PoweredByText, poweredByPosition, poweredByFontSize, poweredBySpacing, raylib.Fade(logoColor, poweredByAlpha))

					raylib.DrawTextureRec(
						logoRt.texture,
						raylib.Rectangle{0, 0, c.float(logoRt.texture.width), -c.float(logoRt.texture.height)}, // y-axis is flipped
						raylib.Vector2{c.float(logoPosition.x), c.float(logoPosition.y)},
						raylib.WHITE
					)
				}

			case .FadeOut:
				{
					raylib.BeginMode2D(camera)
					defer raylib.EndMode2D()

					raylib.DrawTextEx(poweredByFont, PoweredByText, poweredByPosition, poweredByFontSize, poweredBySpacing, raylib.Fade(logoColor, alpha))

					raylib.DrawTextureRec(
						logoRt.texture,
						raylib.Rectangle{0, 0, c.float(logoRt.texture.width), -c.float(logoRt.texture.height)}, // y-axis is flipped
						raylib.Vector2{c.float(logoPosition.x), c.float(logoPosition.y)},
						raylib.Fade(raylib.WHITE, alpha) // fade out entire texture
					)
				}

			case .Loaded:
				break logo_loop
		}
		//----------------------------------------------------------------------------------
	}
}
