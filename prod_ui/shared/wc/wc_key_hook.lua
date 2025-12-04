-- To load: local lib = context:getLua("shared/lib")


--[[
	Keyhooks are a way to apply non-hardcoded keyboard shortcuts to widgets (typically UI Frames or the root widget).

	Keyhooks are implemented as PILE HookLists, which are callable arrays.

	The Keyhook callbacks are:

	(trickle) love.keypressed -> self.KH_trickle_key_pressed
	(trickle) love.keyreleased -> self.KH_trickle_key_released
	(bubble, direct) love.keypressed -> self.KH_key_pressed
	(bubble, direct) love.keyreleased -> self.KH_key_released

	Each keyhook entry is a function that takes the widget as its first argument, followed by the standard arguments
	provided by the LÖVE callback. See source comments for parameter lists.

	These HookLists are set to evaluate in reverse order, so the most recently added hook gets priority. You should not
	add or remove keyhooks during the evaluation loop.

	-- keyPressed: self.KH_key_pressed(wid, key, scancode, isrepeat)
	-- keyReleased: self.KH_key_released(wid, key, scancode)
--]]


local context = select(1, ...)


local wcKeyHook = {}


local pHook = require(context.conf.prod_ui_req .. "lib.pile_hook")


local function _filter(self)
	if not self._dead then
		return true
	end
end


function wcKeyHook.setupInstance(self)
	-- Table of widgets to offer keyPressed and keyReleased input.
	self.KH_trickle_key_pressed = pHook.newHookList(true, _filter)
	self.KH_trickle_key_released = pHook.newHookList(true, _filter)
	self.KH_key_pressed = pHook.newHookList(true, _filter)
	self.KH_key_released = pHook.newHookList(true, _filter)
end


return wcKeyHook
