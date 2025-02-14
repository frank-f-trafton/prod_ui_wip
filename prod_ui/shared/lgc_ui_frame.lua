-- To load: local lib = context:getLua("shared/lib")

--[[
Shared UI Frame logic.
--]]


local context = select(1, ...)


local lgcUIFrame = {}


local widShared = require(context.conf.prod_ui_req .. "common.wid_shared")


--[==[
function lgcUIFrame.definitionSetup(def)
	-- Set to false if you do not want this frame to be selectable by the root.
	-- Intended for specialized interfaces, like a floating box that controls the
	-- playback of music.
	-- When false:
	-- * No widget in the frame should be capable of taking the thimble.
	--   (Otherwise, why not just make it selectable?)
	-- * The frame should never be made modal, or be part of a modal chain.
	def.frame_is_selectable = true

	-- Don't let inter-generational thimble stepping leave this widget's children.
	def.block_step_intergen = true
end


function lgcUIFrame.instanceSetup(self)

end
--]==]


return lgcUIFrame