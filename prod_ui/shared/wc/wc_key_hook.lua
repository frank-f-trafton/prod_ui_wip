-- To load: local lib = context:getLua("shared/lib")


local context = select(1, ...)


local wcKeyHook = {}


function wcKeyHook.setupInstance(self)
	-- Table of widgets to offer keyPressed and keyReleased input.
	self.KH_trickle_key_pressed = {}
	self.KH_trickle_key_released = {}
	self.KH_key_pressed = {}
	self.KH_key_released = {}
end


return wcKeyHook
