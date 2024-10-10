--[[
CursorMgr (Manager)
Version 0.0.1 (Beta)
See README.md for more info.

License: Source code is MIT, demo cursor art is CC0

MIT License

Copyright (c) 2022 RBTS

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]


local cursorMgr = {}


if not love.mouse.isCursorSupported() then
	error("this system does not support mouse cursors.")
end


local enum_modes = {["hardware"] = true, ["texture"] = true}


local function dummyFunc() end


local _mt_mgr_cursor = {}
_mt_mgr_cursor.__index = _mt_mgr_cursor


-- https://love2d.org/wiki/CursorType
-- NOTE: 'image' is not valid for getSystemCursor().
cursorMgr.system_list = {
	"arrow",
	"ibeam",
	"wait",
	"waitarrow",
	"crosshair",
	"sizenwse",
	"sizenesw",
	"sizewe",
	"sizens",
	"sizeall",
	"no",
	"hand",
}


-- Grab a copy of each system cursor.
cursorMgr.system_cursors = {}

for i, id in ipairs(cursorMgr.system_list) do
	cursorMgr.system_cursors[id] = love.mouse.getSystemCursor(id)
end


cursorMgr.default_frame = {
	-- If you want a default texture cursor to appear when no def is assigned,
	-- fill in 'hx', 'hy', 'image' and optionally 'quad' here.
	love_cursor = false,
	duration = math.huge,
}


--- Creates a new animCursor def. Frames must be added before it can be used.
-- @return A bare animCursor skeleton, with default settings and lacking any frames.
function cursorMgr.newAnimatedCursorDef()
	local def = {}

	def.frames = {}
	def.loop_point = 1

	return def
end


function cursorMgr.newFrame(love_cursor, image, quad, hx, hy, duration)
	-- Assertions
	-- [[
	-- Don't type-check the LÖVE userdata objects for now.
	-- Only check 'hx' and 'hy' if 'image' is populated.
	if image then
		if type(hx) ~= "number" or hx ~= math.floor(hx) or hx < 0 or hx >= image:getWidth() then
			error("'hx' must be an integer >= 0 and < image width.")
		elseif type(hy) ~= "number" or hy ~= math.floor(hy) or hy < 0 or hy >= image:getHeight() then
			error("'hy' must be an integer >= 0 and < image height.")
		end
	end
	if type(duration) ~= "number" or duration < 0.0 then
		error("'duration' must be a number >= 0.0")
	end
	--]]

	local frame = {}

	frame.love_cursor = love_cursor
	frame.image = image
	frame.quad = quad
	frame.hx = hx
	frame.hy = hy
	frame.duration = duration

	return frame
end


--- Create a new cursor manager object.
-- @param n_slots (1) How many mouse cursor slots to prepopulate with boolean false. Must be an integer, and greater than zero.
-- @return The cursor manager object.
function cursorMgr.newManager(n_slots)
	-- Defaults
	n_slots = n_slots or 1

	-- Assertions
	-- [[
	if type(n_slots) ~= "number" or n_slots ~= math.floor(n_slots) or n_slots < 1 then
		error("'n_slots' must be an integer >= 1.")
	end
	--]]

	local self = {}

	self.cursor_defs = {}

	self.visible = true
	self._visible_prev = nil

	-- Used to hide texture-based cursors when the mouse moves out of the window bounds.
	-- On some operating systems, love.mousefocused() may not trigger immediately if the user
	-- clicks in the window and drags outside of it.
	self.has_mouse_focus = false

	-- Cursor mode. "hardware" to use hardware cursors, "texture" to use textures + quads.
	self.mode = "hardware"

	-- Some common IDs.
	self.id_default = false
	self.id_busy = "wait"

	--[[
	Sequence of cursor IDs. Lower entries get higher priority, and entries with boolean
	false are skipped. (Do not assign nil, as it will break table iteration.) If all
	entries are false, then the system default cursor is used.

	For example, one might reserve the first slot for an application-wide "busy/wait" cursor,
	and the last slot for the application's standard pointer cursor.
	--]]
	self.slots = {}

	for i = 1, n_slots do
		self.slots[i] = false
	end

	--[[
	The mouse cursor changes in self:refreshMouseState() when current ~= prev.
	Boolean false changes to the default system cursor. Nil is not valid, except in _id_prev,
	to force a cursor load by making current ~= prev.
	--]]
	self.id_current = self.id_default
	self._id_prev = nil

	--[[
	Cursor animation state.
	--]]
	self.timer = 0.0
	self.frame_i = 1
	self._frame_i_prev = nil

	setmetatable(self, _mt_mgr_cursor)

	-- Default to the system cursors. The library user can add to or overwrite them as needed.
	for k, v in pairs(cursorMgr.system_cursors) do
		local def = cursorMgr.newAnimatedCursorDef()
		local frame = cursorMgr.newFrame(v, nil, nil, nil, nil, math.huge)

		def.frames[1] = frame

		self.cursor_defs[k] = def
	end

	return self
end


--- Get the current active cursor frame. The frame may be the "default" which is not connected to any definition.
-- @return The currently active frame table, or false/nil if none is active.
function _mt_mgr_cursor:getCurrentFrame()
	if self.id_current then
		return self.cursor_defs[self.id_current].frames[self.frame_i]
	else
		return cursorMgr.default_frame
	end
end


function _mt_mgr_cursor:setMode(mode)
	-- Assertions
	-- [[
	if not enum_modes[mode] then
		error("invalid cursor mode: " .. tostring(mode))
	end
	--]]
	self.mode = mode

	-- Force the next update to refresh state
	self._id_prev = nil
	self._frame_i_prev = nil
	self._visible_prev = nil

	if self.mode == "texture" then
		love.mouse.setVisible(false)
	end
end


--- Assigns a mouse cursor ID to a slot. The actual LÖVE/SDL2 state change is deferred to self:refreshMouseState(), which should be placed near the end of your project's love.update().
-- @param id (false) String ID of the cursor to set, or false/nil to clear the slot.
-- @param slot_n (#self.slots) Which slot to update.
function _mt_mgr_cursor:assignCursor(id, slot_n)
	-- Defaults
	slot_n = slot_n or #self.slots
	id = id or false

	-- Assertions
	-- [[
	if id and not self.cursor_defs[id] then error("mgr_cursor is missing cursor: " .. tostring(id))
	elseif slot_n < 1 or slot_n > #self.slots then error("'slot_n' is out of bounds.") end
	--]]

	self.slots[slot_n] = id
end


--- Get the cursor ID in a given slot.
-- @param slot_n (#self.slots)
function _mt_mgr_cursor:getCursorID(slot_n)
	-- Defaults
	slot_n = slot_n or #self.slots

	-- Assertions
	-- [[
	if slot_n < 1 or slot_n > #self.slots then error("'slot_n' is out of bounds.") end
	--]]

	return self.slots[slot_n]
end


--- Add to love.mouseFocus(focus) if you are supporting texture cursors.
-- @param focus The 'focus' variable from love.mouseFocus().
function _mt_mgr_cursor:updateMouseFocus(focus)
	self.has_mouse_focus = focus
end


--- Place this near the end of your love.update(). You can also call it arbitrarily to force an update to the
--  visible/cursor state, if for example you want to update the hardware cursor before temporarily hanging the main thread.
-- @param dt The frame delta-time. If calling arbitrarily, set this to 0.
function _mt_mgr_cursor:refreshMouseState(dt)
	local defs = self.cursor_defs

	-- Visibility state
	if self.visible ~= self._visible_prev then
		if self.mode == "hardware" then
			love.mouse.setVisible(self.visible)
		end
		self._visible_prev = self.visible
	end

	-- Grab ID from the highest priority slot, defaulting to the system default if none are populated.
	self.id_current = false
	for _, id in ipairs(self.slots) do
		if id then
			self.id_current = id
			break
		end
	end

	-- Advance animation state
	if self.id_current then
		self.timer = self.timer + dt

		local safety, safety_max = 1, 8
		while safety < safety_max do
			local def = defs[self.id_current]
			local frames = def.frames
			local frame = frames[self.frame_i]

			if not frame then
				break

			else
				-- Forwards animation
				if self.timer > frame.duration then
					self.timer = self.timer - frame.duration

					self.frame_i = self.frame_i + 1
					if self.frame_i > #frames then
						self.frame_i = def.loop_point
					end

				-- Backwards animation
				elseif self.timer < 0 then
					self.frame_i = self.frame_i - 1
					if self.frame_i < 1 then
						self.frame_i = #frames
					end

					self.timer = self.timer + frames[self.frame_i].duration

				-- Done incrementing/decrementing frame
				else
					break
				end
			end
			safety = safety + 1
		end

		-- Reset frame timer if it's still too far ahead.
		if safety == safety_max and self.timer > dt then
			self.timer = 0
		end
	end

	-- Update cursor state
	if self.visible and (self.id_current ~= self._id_prev or self.frame_i ~= self._frame_i_prev) then
		local frame = self:getCurrentFrame()

		if self.mode == "hardware" then
			love.mouse.setCursor(frame.love_cursor or nil)
		end

		self._id_prev = self.id_current
		self._frame_i_prev = self.frame_i
	end
end


--- You can use this at the end of love.draw() if you want to support non-hardware cursors. You may need
-- to write your own logic depending on your needs -- you can use self:getCurrentFrame() for that purpose.
-- @param mx Mouse X position.
-- @param my Mouse Y position.
function _mt_mgr_cursor:drawCurrentFrame(x, y)

	--[[
	You may need to use love.graphics.reset() prior to calling this, to eliminate shader, canvas and
	transformation stack state which might interfere... or not, depending on your implementation.
	Similarly, you may want to replace this with your own logic. There's no reason you couldn't apply
	scaling, rotation, etc., to a quad-based cursor. It's not supported here as the intention is to
	behave similar HW cursors.
	--]]

	if self.mode == "texture" and self.visible and self.has_mouse_focus then
		local frame = self:getCurrentFrame()
		if frame and frame.image then
			if frame.quad then
				love.graphics.draw(frame.image, frame.quad, x - frame.hx, y - frame.hy)
			else
				love.graphics.draw(frame.image, x - frame.hx, y - frame.hy)
			end
		end
	end	
end


--- Use this if you want to assert that a cursor ID is populated without changing the manager state.
-- @param id The cursor ID to assert.
function _mt_mgr_cursor:assertCursorID(id)
	if not self.cursor_defs[self.cursor_id] then
		error("context is missing cursor: " .. tostring(self.cursor_id))
	end
end


function _mt_mgr_cursor:setDirty()
	self._id_prev = nil
	self._visible_prev = nil
	self._frame_i_prev = nil
end


return cursorMgr

