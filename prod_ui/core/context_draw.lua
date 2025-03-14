-- contextDraw: Implements the context draw loop.


local contextDraw = {}


--local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


-- DEBUG: printing wrappers.


--[==[
local old_setScis = love.graphics.setScissor
local old_intScis = love.graphics.intersectScissor
local old_push = love.graphics.push
local old_pop = love.graphics.pop
local old_newCanv = love.graphics.newCanvas
local old_setCanv = love.graphics.setCanvas

local stack_n = 0

local function stringScissor()
	local sx, sy, sw, sh = love.graphics.getScissor()

	if not sx then
		return "Scissor: (None)"
	else
		return "Scissor: x " .. tostring(sx) .. ", y " .. tostring(sy) .. ", w " .. tostring(sw) .. ", h " .. tostring(sh)
	end
end

love.graphics.push = function(stack_type)
	stack_n = stack_n + 1
	print("love.graphics.push(" .. tostring(stack_type) .. ") STACK N " .. tostring(stack_n) .. " " .. stringScissor())
	--print(debug.traceback())
	old_push(stack_type)
end
love.graphics.pop = function()
	print("love.graphics.pop() STACK N " .. tostring(stack_n) .. " " .. stringScissor())
	stack_n = stack_n - 1
	--print(debug.traceback())
	old_pop()
end
love.graphics.setScissor = function(x, y, w, h)
	print("love.graphics.setScissor(", x, y, w, h, ")")
	--print(debug.traceback())
	old_setScis(x, y, w, h)
end
love.graphics.intersectScissor = function(x, y, w, h)
	print("love.graphics.intersectScissor(", x, y, w, h, ")")
	--print(debug.traceback())
	old_intScis(x, y, w, h)
end
love.graphics.newCanvas = function(...) -- untested
	io.write("love.graphics.newCanvas()")
	for i = 1, select("#", ...) do
		io.write("\t" .. select(i, ...))
	end
	io.write("\n")
	print(debug.traceback())
	old_newCanv(...)
end
love.graphics.setCanvas = function(...)
	io.write("love.graphics.setCanvas()")
	for i = 1, select("#", ...) do
		io.write("\t" .. tostring(select(i, ...)))
	end
	io.write("\n")
	print(debug.traceback())
	old_setCanv(...)
end
--]==]


local graphics_limits = love.graphics.getSystemLimits()


local temp_transform = love.math.newTransform()
local temp_quad = love.graphics.newQuad(0, 0, 1, 1, 1, 1)


-- The last known window dimensions. Used to determine when canvas layers should be discarded.
local last_w, last_h = love.graphics.getDimensions()


local function newCanvasEntry(context, w, h, sx, sy, sw, sh)
	local entry = {}

	w = math.min(w, graphics_limits.texturesize)
	h = math.min(h, graphics_limits.texturesize)

	entry.canvas = love.graphics.newCanvas(w, h, context.canvas_settings)

	-- The scissor box state to restore after popping this layer.
	-- No sx == no scissor box.
	entry.sx = sx
	entry.sy = sy
	entry.sw = sw
	entry.sh = sh

	return entry
end


--- Push a canvas layer.
local function pushLayer(context, sx, sy, sw, sh)
	context.canvas_layers_i = context.canvas_layers_i + 1
	if context.canvas_layers_i > context.canvas_layers_max then
		error("max canvas stack size exceeded (" .. context.canvas_layers_max .. ")")
	end

	local entry = context.canvas_layers[context.canvas_layers_i]
	if not entry then
		local win_w, win_h = love.graphics.getDimensions()
		entry = newCanvasEntry(context, win_w, win_h, sx, sy, sw, sh)
	end
	context.canvas_layers[context.canvas_layers_i] = entry

	love.graphics.setScissor()
	love.graphics.setCanvas(entry.canvas)
	love.graphics.clear()
	love.graphics.setScissor(sx, sy, sw, sh)
end


--- Pop a canvas layer.
local function popLayer(context)
	local entry = context.canvas_layers[context.canvas_layers_i]
	if not entry then
		error("no canvas table at stack position: " .. tostring(context.canvas_layers_i))
	end
	context.canvas_layers_i = context.canvas_layers_i - 1

	local new_top = context.canvas_layers[context.canvas_layers_i]
	if not new_top then
		love.graphics.setCanvas()
	else
		love.graphics.setCanvas(new_top.canvas)
	end

	if entry.sx then
		love.graphics.setScissor(
			entry.sx,
			entry.sy,
			math.max(0, entry.sw),
			math.max(0, entry.sh)
		)
	else
		love.graphics.setScissor()
	end

	return entry.canvas
end


--- Clears all entries in the canvas layer stack. Call outside of contextDraw.draw().
local function clearAllLayers(context)
	for i = #context.canvas_layers, 1, -1 do
		context.canvas_layers[i].canvas:release()
		context.canvas_layers[i] = nil
	end
	context.canvas_layers_i = 0
end


--- The internal draw loop.
-- @param wid The current widget being drawn.
-- @param os_x, os_y X and Y offsets of the widget in screen space (for scissor boxes).
-- @param thimble1 The current thimble1, if applicable.
-- @param thimble2 The current thimble2, if applicable.
local function drawLoop(context, wid, os_x, os_y, thimble1, thimble2)
	-- [[DBG]] print("drawLoop " .. wid.id .. ": Start")
	if wid.visible then
		local do_layering = wid.ly_enabled

		if do_layering then
			local sx, sy, sw, sh = love.graphics.getScissor()
			pushLayer(context, sx, sy, sw, sh)
		end

		wid:render(os_x, os_y)

		if not wid.hide_children then
			love.graphics.push("all") -- [s]

			love.graphics.translate(-wid.scr_x, -wid.scr_y)

			if wid.clip_scissor == true then
				love.graphics.intersectScissor(
					os_x + wid.x,
					os_y + wid.y,
					math.max(0, wid.w),
					math.max(0, wid.h)
				)

			elseif wid.clip_scissor == "manual" then
				love.graphics.intersectScissor(
					os_x + wid.x + wid.clip_scissor_x,
					os_y + wid.y + wid.clip_scissor_y,
					math.max(0, wid.clip_scissor_w),
					math.max(0, wid.clip_scissor_h)
				)
			end

			-- Keep temporary copies of offsets so that they don't change mid-loop.
			local wx = wid.x - wid.scr_x + os_x
			local wy = wid.y - wid.scr_y + os_y

			local children = wid.children
			local first = math.max(wid.draw_first, 1)
			local last = math.min(wid.draw_last, #children)

			for i = first, last do
				local child = children[i]

				love.graphics.push("all") -- [s]

				love.graphics.translate(child.x, child.y)
				drawLoop(context, child, wx, wy, thimble1, thimble2)

				love.graphics.pop() -- []
			end

			love.graphics.pop() -- []
		end

		wid:renderLast(os_x, os_y)

		-- Render the thimble glow, if applicable.
		if wid == thimble1 or wid == thimble2 then
			love.graphics.push("all") -- [s]

			wid:renderThimble(os_x, os_y)

			love.graphics.pop() -- []
		end

		-- Finish up canvas layer rendering.
		if do_layering then
			local canvas = popLayer(context)
			-- ^ Restores old canvas and scissor box

			love.graphics.push("all") -- [l]
			love.graphics.setBlendMode(wid.ly_blend_mode, "premultiplied")

			local a = wid.ly_a
			love.graphics.setColor(wid.ly_r * a, wid.ly_g * a, wid.ly_b * a, wid.ly_a)

			temp_transform:setTransformation(
				wid.ly_x,
				wid.ly_y,
				wid.ly_angle,
				wid.ly_sx,
				wid.ly_sy,
				wid.ly_ox,
				wid.ly_oy,
				wid.ly_kx,
				wid.ly_ky
			)

			love.graphics.origin()
			love.graphics.applyTransform(temp_transform)

			if wid.ly_use_quad then
				temp_quad:setViewport(wid.ly_qx, wid.ly_qy, wid.ly_qw, wid.ly_qh, canvas:getDimensions())
				wid:ly_fn_start(canvas, os_x, os_y, temp_transform, temp_quad)
				love.graphics.draw(canvas, temp_quad, wid.ly_qx, wid.ly_qy)
			else
				wid:ly_fn_start(canvas, os_x, os_y, temp_transform)
				love.graphics.draw(canvas)
			end

			wid:ly_fn_end()

			love.graphics.pop() --[]
		end

		-- Uncomment to enable a user event for debug rendering.
		--[[
		if wid.userDebugRender then
			wid:_runUserEvent("userDebugRender", os_x, os_y)
		end
		--]]
	end -- / if wid.visible
	-- [[DBG]] print("drawLoop " .. wid.id .. ": End")
end


--- Draw the UI context.
-- @param context The context to draw.
-- @param x, y The top-left origin point.
function contextDraw.draw(context, x, y)
	-- Discard recycled canvas layers if the window's graphical dimensions have changed.
	local win_w, win_h = love.graphics.getDimensions()
	if last_w ~= win_w or last_h ~= win_h then
		clearAllLayers(context)
	end
	last_w, last_h = win_w, win_h

	local root = context.root

	love.graphics.push("all") -- [s]

	love.graphics.translate(x + root.x, y + root.y)
	drawLoop(context, root, x, y, context.thimble1, context.thimble2)

	love.graphics.pop() -- []
end


return contextDraw
