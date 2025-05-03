/*******************************************************************************************
* This file is based on original work by Ramon Santamaria (https://github.com/raysan5),
* licensed under the zlib/libpng license: https://opensource.org/licenses/Zlib
*
* Modifications by Unuclear, 2025:
* - Translated from C to Odin
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


Vector2i :: [2]i32

LogoState :: enum {
    Blink,           // Small box blinking
    TopLeftBars,     // Top and left bars growing
	RightBottomBars, // Right and bottom bars growing
    Letters,         // "raylib" letters appearing one by one
    ZoomOut,         // Zoom out and write "powered by" above the logo
    FadeOut,         // Fade out the entire logo
	Loaded,          // Blank the screen one last time
}


BarThickness: c.int : 16
BarGrowthPerFrame: c.int : BarThickness / 4
FullBar: c.int : BarThickness * BarThickness
FullBarNoOverlap: c.int : FullBar - BarThickness // Prevent overlap with the top bar

LogoPositionOffset: c.int : FullBar / 2 // To center the logo
LogoText: cstring : "raylib"

PoweredByText: cstring: "powered by"
PoweredBySpacing: c.float = 8


raylibLogoAnimation :: proc(fps: c.int = 60, poweredByCustomFont: ^raylib.Font = nil, poweredByFontSizeFactor: c.float = 3) {
	// Initialization
	//--------------------------------------------------------------------------------------
	state := LogoState.Blink
	framesCounter: uint
	topBar, leftBar, bottomBar, rightBar: c.int = BarThickness, 0, 0, 0
	lettersCount: c.int
	alpha: c.float = 1

	camera := raylib.Camera2D{
		target={},
		offset={},
		rotation=0.0,
		zoom=1.0,
	}

	screenCenter := raylib.Vector2{}

	logoPosition := Vector2i{}

	poweredByFont: raylib.Font
	if poweredByCustomFont != nil do poweredByFont = poweredByCustomFont^
	else do poweredByFont = raylib.GetFontDefault()

	poweredByPosition := raylib.Vector2{}
	poweredBySize := raylib.MeasureTextEx(poweredByFont, PoweredByText, c.float(poweredByFont.baseSize) * poweredByFontSizeFactor, PoweredBySpacing)
	poweredByOffset := raylib.Vector2{poweredBySize.x / 2, poweredBySize.y + PoweredBySpacing}
	poweredByAlpha: c.float = 0

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
					state = .TopLeftBars
					framesCounter = 0 // Reset for later reuse
				}

			case .TopLeftBars:
				topBar += BarGrowthPerFrame
				leftBar += BarGrowthPerFrame

				if topBar == FullBar do state = .RightBottomBars

			case .RightBottomBars:
				rightBar += BarGrowthPerFrame

				if rightBar == FullBarNoOverlap do state = .Letters
				else do bottomBar += BarGrowthPerFrame // Prevent overlap with vertical bars

			case .Letters:
				framesCounter += 1

				// One letter every 8 frames
				if framesCounter == 8 {
					lettersCount += 1
					framesCounter = 0
				}

				if lettersCount >= 10 do state = .ZoomOut

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

		screenCenter.x = c.float(raylib.GetScreenWidth()) / 2
		screenCenter.y = c.float(raylib.GetScreenHeight()) / 2

		// Adjust logo position
		logoPosition.x = c.int(screenCenter.x) - LogoPositionOffset
		logoPosition.y = c.int(screenCenter.y) - LogoPositionOffset

		if camera.zoom < 1 {
			camera.target.x, camera.target.y = screenCenter.x, screenCenter.y
			camera.offset.x, camera.offset.y = screenCenter.x, screenCenter.y

			poweredByPosition.x = screenCenter.x - poweredByOffset.x
			poweredByPosition.y = c.float(logoPosition.y) - poweredByOffset.y
		}
		//----------------------------------------------------------------------------------

		// Draw
		//----------------------------------------------------------------------------------
		raylib.BeginDrawing()
		defer raylib.EndDrawing()

		raylib.ClearBackground(raylib.RAYWHITE)

		switch state {
			case .Blink:
				if (framesCounter / 15) % 2 != 0 {
					raylib.DrawRectangle(logoPosition.x, logoPosition.y, BarThickness, BarThickness, raylib.BLACK)
				}

			case .TopLeftBars:
				raylib.DrawRectangle(logoPosition.x, logoPosition.y, topBar, BarThickness, raylib.BLACK)
				raylib.DrawRectangle(logoPosition.x, logoPosition.y + BarThickness, BarThickness, leftBar, raylib.BLACK)

			case .RightBottomBars:
				raylib.DrawRectangle(logoPosition.x, logoPosition.y, topBar, BarThickness, raylib.BLACK)
				raylib.DrawRectangle(logoPosition.x, logoPosition.y + BarThickness, BarThickness, leftBar, raylib.BLACK)

				raylib.DrawRectangle(logoPosition.x + FullBarNoOverlap, logoPosition.y + BarThickness, BarThickness, rightBar, raylib.BLACK)
				raylib.DrawRectangle(logoPosition.x + BarThickness, logoPosition.y + FullBarNoOverlap, bottomBar, BarThickness, raylib.BLACK)

			case .Letters:
				raylib.DrawRectangle(logoPosition.x, logoPosition.y, topBar, BarThickness, raylib.BLACK)
				raylib.DrawRectangle(logoPosition.x, logoPosition.y + BarThickness, BarThickness, leftBar, raylib.BLACK)

				raylib.DrawRectangle(logoPosition.x + FullBarNoOverlap, logoPosition.y + BarThickness, BarThickness, rightBar, raylib.BLACK)
				raylib.DrawRectangle(logoPosition.x + BarThickness, logoPosition.y + FullBarNoOverlap, bottomBar, BarThickness, raylib.BLACK)

				//raylib.DrawRectangle(c.int(screenCenter.x) - 112, c.int(screenCenter.y) - 112, 224, 224, raylib.RAYWHITE)

				raylib.DrawText(raylib.TextSubtext(LogoText, 0, lettersCount), logoPosition.x + 84, logoPosition.y + 176, 50, raylib.BLACK)

			case .ZoomOut:
				{
					raylib.BeginMode2D(camera)
					defer raylib.EndMode2D()

					raylib.DrawTextEx(poweredByFont, PoweredByText, poweredByPosition, c.float(poweredByFont.baseSize) * poweredByFontSizeFactor, PoweredBySpacing, raylib.Fade(raylib.BLACK, poweredByAlpha))

					raylib.DrawRectangle(logoPosition.x, logoPosition.y, topBar, BarThickness, raylib.BLACK)
					raylib.DrawRectangle(logoPosition.x, logoPosition.y + BarThickness, BarThickness, leftBar, raylib.BLACK)

					raylib.DrawRectangle(logoPosition.x + FullBarNoOverlap, logoPosition.y + BarThickness, BarThickness, rightBar, raylib.BLACK)
					raylib.DrawRectangle(logoPosition.x + BarThickness, logoPosition.y + FullBarNoOverlap, bottomBar, BarThickness, raylib.BLACK)

					//raylib.DrawRectangle(c.int(screenCenter.x) - 112, c.int(screenCenter.y) - 112, 224, 224, raylib.RAYWHITE)

					raylib.DrawText(LogoText, logoPosition.x + 84, logoPosition.y + 176, 50, raylib.BLACK)
				}

			case .FadeOut:
				{
					raylib.BeginMode2D(camera)
					defer raylib.EndMode2D()

					raylib.DrawTextEx(poweredByFont, PoweredByText, poweredByPosition, c.float(poweredByFont.baseSize) * poweredByFontSizeFactor, PoweredBySpacing, raylib.Fade(raylib.BLACK, alpha))

					raylib.DrawRectangle(logoPosition.x, logoPosition.y, topBar, BarThickness, raylib.Fade(raylib.BLACK, alpha))
					raylib.DrawRectangle(logoPosition.x, logoPosition.y + BarThickness, BarThickness, leftBar, raylib.Fade(raylib.BLACK, alpha))

					raylib.DrawRectangle(logoPosition.x + FullBarNoOverlap, logoPosition.y + BarThickness, BarThickness, rightBar, raylib.Fade(raylib.BLACK, alpha))
					raylib.DrawRectangle(logoPosition.x + BarThickness, logoPosition.y + FullBarNoOverlap, bottomBar, BarThickness, raylib.Fade(raylib.BLACK, alpha))

					//raylib.DrawRectangle(logoPosition.x + BarThickness, logoPosition.y + BarThickness, 224, 224, raylib.Fade(raylib.RAYWHITE, alpha))

					raylib.DrawText(LogoText, logoPosition.x + 84, logoPosition.y + 176, 50, raylib.Fade(raylib.BLACK, alpha))
				}

			case .Loaded:
				break logo_loop
		}
		//----------------------------------------------------------------------------------
	}
}
