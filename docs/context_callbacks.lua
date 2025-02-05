return {
	type = "reference",
	title = "Context LÖVE Callbacks",
	id = "context_love_callback",
	schema = {
		main = {
			["#"] = {
				name = "string",
				love_callback = "string",
				signature = "string",
			}
		}
	},
	main = {
		{
			name = "context:love_keypressed",
			love_callback = "[love.keypressed](https://love2d.org/wiki/love.keypressed)",
			signature = "context:love_keypressed(key, scancode, isrepeat)"
		},

		{
			name = "context:love_keyreleased",
			love_callback = "[love.keyreleased](https://love2d.org/wiki/love.keyreleased)",
			signature = "context:love_keyreleased(key, scancode)"
		},

		{
			name = "context:love_update",
			love_callback = "[love.update](https://love2d.org/wiki/love.update)",
			signature = "context:love_update(dt)",
		},

		{
			name = "context:love_textinput",
			love_callback = "[love.textinput](https://love2d.org/wiki/love.textinput)",
			signature = "context:love_textinput(text)",
		},

		{
			name = "context:love_focus",
			love_callback = "[love.focus](https://love2d.org/wiki/love.focus)",
			signature = "context:love_focus(focus)",
		},

		{
			name = "context:love_visible",
			love_callback = "[love.visible](https://love2d.org/wiki/love.visible)",
			signature = "context:love_visible(visible)",
		},

		{
			name = "context:love_mousefocus",
			love_callback = "[love.mousefocus](https://love2d.org/wiki/love.mousefocus)",
			signature = "context:love_mousefocus(focus)",
		},

		{
			name = "context:love_wheelmoved",
			love_callback = "[love.wheelmoved](https://love2d.org/wiki/love.wheelmoved)",
			signature = "context:love_wheelmoved(x, y)",
		},

		{
			name = "context:love_mousereleased",
			love_callback = "[love.mousereleased](https://love2d.org/wiki/love.mousereleased)",
			signature = "context:love_mousereleased(x, y, button, istouch, presses)",
		},

		{
			name = "context:love_mousemoved",
			love_callback = "[love.mousemoved](https://love2d.org/wiki/love.mousemoved)",
			signature = "context:love_mousemoved(x, y, dx, dy, istouch)",
		},

		{
			name = "context:love_mousepressed",
			love_callback = "[love.mousepressed](https://love2d.org/wiki/love.mousepressed)",
			signature = "context:love_mousepressed(x, y, button, istouch, presses)",
		},

		{
			name = "context:love_resize",
			love_callback = "[love.resize](https://love2d.org/wiki/love.resize)",
			signature = "context:love_resize(w, h)",
		},

		{
			name = "context:love_joystickadded",
			love_callback = "[love.joystickadded](https://love2d.org/wiki/love.joystickadded)",
			signature = "context:love_joystickadded(joystick)",
		},

		{
			name = "context:love_joystickremoved",
			love_callback = "[love.joystickremoved](https://love2d.org/wiki/love.joystickremoved)",
			signature = "context:love_joystickremoved(joystick)",
		},

		{
			name = "context:love_joystickpressed",
			love_callback = "[love.joystickpressed](https://love2d.org/wiki/love.joystickpressed)",
			signature = "context:love_joystickpressed(joystick, button)",
		},

		{
			name = "context:love_joystickreleased",
			love_callback = "[love.joystickreleased](https://love2d.org/wiki/love.joystickreleased)",
			signature = "context:love_joystickreleased(joystick, button)",
		},

		{
			name = "context:love_joystickaxis",
			love_callback = "[love.joystickaxis](https://love2d.org/wiki/love.joystickaxis)",
			signature = "context:love_joystickaxis(joystick, axis, value)",
		},

		{
			name = "context:love_joystickhat",
			love_callback = "[love.joystickhat](https://love2d.org/wiki/love.joystickhat)",
			signature = "context:love_joystickhat(joystick, hat, direction)",
		},

		{
			name = "context:love_gamepadpressed",
			love_callback = "[love.gamepadpressed](https://love2d.org/wiki/love.gamepadpressed)",
			signature = "context:love_gamepadpressed(joystick, button)",
		},

		{
			name = "context:love_gamepadreleased",
			love_callback = "[love.gamepadreleased](https://love2d.org/wiki/love.gamepadreleased)",
			signature = "context:love_gamepadreleased(joystick, button)",
		},

		{
			name = "context:love_gamepadaxis",
			love_callback = "[love.gamepadaxis](https://love2d.org/wiki/love.gamepadaxis)",
			signature = "context:love_gamepadaxis(joystick, axis, value)",
		},

		{
			name = "context:love_filedropped",
			love_callback = "[love.filedropped](https://love2d.org/wiki/love.filedropped)",
			signature = "context:love_filedropped(file)",
		},

		{
			name = "context:love_directorydropped",
			love_callback = "[love.directorydropped](https://love2d.org/wiki/love.directorydropped)",
			signature = "context:love_directorydropped(path)",
		},
	},
}
