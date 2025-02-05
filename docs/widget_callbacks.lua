return {
	type = "reference",
	title = "Widget Callbacks",
	id = "widget_callback",
	schema = {
		main = {
			["#"] = {
				name = "string",
				call_site = "string",
				description = "string",
				signature = "string",
				parameters = {
					["#"] = {
						name = "string",
						type = "string",
						description = "string"
					}
				},
				returns = "nil|string",
				example = "nil|string",
				notes = "nil|string"
			}
		}
	},
	main = {
		{
			name = "render",
			call_site = "uiDraw.drawContext",
			description = "Draws the widget (before its children).",
			signature = "def:render(os_x, os_y)",
			parameters = {
				["#"] = {
					name = "os_x, os_y",
					type = "number",
					description = "X and Y offsets, in screen pixels.",
				}
			},
			returns = "Nothing.",
			notes = [==[
                The graphics state is already translated so that 0,0 is the top-left corner of the widget. The parameters os_x and os_y typically aren't needed, unless the widget needs to adjust the current scissor box.
			]==]
		},

		{
			name = "renderLast",
			call_site = "uiDraw.drawContext",
			description = "Draws the widget (after its children).",
			signature = "def:renderLast(os_x, os_y)",
			parameters = {
				["#"] = {
					name = "os_x, os_y",
					type = "number",
					description = "X and Y offsets, in screen pixels.",
				}
			},
			returns = "Nothing.",
			notes = [==[
                See 'render' for applicable notes.
			]==]
		},

		{
			name = "renderThimble",
			call_site = "uiDraw.drawContext",
			description = "Draws the visual representation of keyboard focus for a widget.",
			signature = "def:renderThimble(os_x, os_y)",
			parameters = {
				["#"] = {
					name = "os_x, os_y",
					type = "number",
					description = "X and Y offsets, in screen pixels.",
				}
			},
			returns = "Nothing.",
		},

		{
			name = "ui_evaluateHover",
			call_site = "mouseLogic.checkHover",
			description = "Determines if the mouse cursor is hovering over this widget.",
			signature = "def:ui_evaluateHover(mx, my, os_x, os_y)",
			parameters = {
				["#"] = {
					name = "mx, my",
					type = "number",
					description = "The mouse cursor position in UI space.",
				}, {
					name = "os_x, os_y",
					type = "number",
					description = "Position offsets, such that mx + os_x and my + os_y give the widget's top-left position in UI space.",
				}
			},
			returns = "True to indicate that this widget can be considered hovered, false if not. When returning true, this widget will be chosen only if none of its children also return true.",
		},

		{
			name = "ui_evaluatePress",
			call_site = "mouseLogic.checkPressed",
			description = "Determines if the mouse is pressing this widget.",
			signature = "def:ui_evaluatePress(mx, my, os_x, os_y, button, istouch, presses)",
			parameters = {
				["#"] = {
					name = "mx, my",
					type = "number",
					description = "The mouse cursor position in UI space.",
				}, {
					name = "os_x, os_y",
					type = "number",
					description = "Position offsets, such that mx + os_x and my + os_y give the widget's top-left position in UI space.",
				}, {
					name = "button",
					type = "number",
					description = "The pressed mouse button index."
				}, {
					name = "istouch",
					type = "boolean",
					description = "True if this is a touch event."
				}, {
					name = "presses",
					type = "number",
					description = "The number of consecutive presses, as determined by love.mousepressed()."
				}
			},
			returns = "True to indicate that this widget can be considered pressed, false if not. When returning true, this widget will be chosen only if none of its children also return true.",
		},
	}
}
