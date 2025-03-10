-- To load: local lib = context:getLua("shared/lib")


local context = select(1, ...)


local lgcKeyHooks = {}


function lgcKeyHooks.setupInstance(self)
	-- Table of widgets to offer keyPressed and keyReleased input.
	self.hooks_trickle_key_pressed = {}
	self.hooks_trickle_key_released = {}
	self.hooks_key_pressed = {}
	self.hooks_key_released = {}
end


return lgcKeyHooks
