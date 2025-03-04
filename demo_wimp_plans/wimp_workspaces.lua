
local plan = {}


local commonWimp = require("prod_ui.common.common_wimp")


local function _setupWS2(root)
	if root:findTag("alt_workspace") then
		return
	end

	local ws2 = root:newWorkspace()
	ws2:initialize()
	ws2.tag = "alt_workspace"

	local btn = ws2:addChild("base/button")
	btn.x = 32
	btn.y = 32
	btn.w = 256
	btn.h = 64
	btn:initialize()
	btn:setLabel("Back to Workspace #1")

	btn.wid_buttonAction = function(self)
		local ws1 = self.context.root:findTag("main_workspace")
		if ws1 then
			self.context.root:setActiveWorkspace(ws1)
		end
	end

	local frame_ws2 = root:newWindowFrame()
	frame_ws2:setFrameTitle("Associated with Workspace #2")
	frame_ws2.x, frame_ws2.y, frame_ws2.w, frame_ws2.h = 300, 100, 640, 480
	frame_ws2:initialize()
	frame_ws2:setFrameWorkspace(ws2)

	local frame_ws2_text = frame_ws2:addChild("base/label")
	frame_ws2_text.x, frame_ws2_text.y, frame_ws2_text.w, frame_ws2_text.h = 0, 0, 440, 100
	frame_ws2_text:initialize()
	frame_ws2_text:setLabel("This Window Frame is \"associated\" with Workspace #2. It is visible and active only when Workspace #2 is also active.\n\n(Other Window Frames in this demo are \"unassociated\", and will appear in any Workspace.)", "multi")

	-- Make Workspace #2 distinguishable from the main Workspace at a glance.
	local radius = 1
	local canvas2 = love.graphics.newCanvas(radius*2, radius*2)
	love.graphics.push("all")
	love.graphics.setCanvas(canvas2)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.circle("fill", radius, radius, radius)
	love.graphics.circle("line", radius, radius, radius)
	love.graphics.pop()

	local canvas = love.graphics.newCanvas(640, 480)
	canvas:setWrap("repeat", "repeat")
	local quad = love.graphics.newQuad( 0, 0, canvas:getWidth() * 16, canvas:getHeight() * 16, canvas:getWidth(), canvas:getHeight())
	local cw = canvas:getWidth()
	local ch = canvas:getHeight()

	local d_min, d_max = 33, 66

	local snow = {}
	for i = 1, 512 do
		snow[i] = {x=love.math.random(cw), y=love.math.random(ch), dx=love.math.random(d_min, d_max), dy=love.math.random(d_min, d_max)}
	end

	ws2.userUpdate = function(self, dt)
		for i, s in ipairs(snow) do
			s.dx = math.max(d_min, math.min(d_max, s.dx + love.math.random(-0.1, 0.1) * dt))
			s.dy = math.max(d_min, math.min(d_max, s.dy + love.math.random(-0.1, 0.1) * dt))

			s.x = (s.x + s.dx * dt) % cw
			s.y = (s.y + s.dy * dt) % ch
		end
	end

	ws2.render = function(self, ox, oy)
		love.graphics.push("all")
		love.graphics.reset()
		love.graphics.setCanvas(canvas)
		love.graphics.setColor(0.3, 0.3, 0.45, 1.0)
		love.graphics.rectangle("fill", 0, 0, cw, ch)

		love.graphics.setColor(0.9, 0.9, 0.9, 0.75)

		love.graphics.translate(-radius, -radius)
		for i, s in ipairs(snow) do
			local side_x = s.x <= cw / 2 and 1 or -1
			local side_y = s.y <= ch / 2 and 1 or -1
			love.graphics.draw(canvas2, s.x, s.y)
			love.graphics.draw(canvas2, s.x + (cw * side_x), s.y)
			love.graphics.draw(canvas2, s.x, s.y + (ch * side_y))
			love.graphics.draw(canvas2, s.x + (cw * side_x), s.y + (ch * side_y))
		end
		--love.graphics.setColor(1.0, 0.0, 0.0, 1.0)
		--love.graphics.rectangle("line", 0, 0, cw, ch)
		love.graphics.pop()
		love.graphics.draw(canvas, quad, 0, 0)
	end

	ws2:reshape(true)
	frame_ws2:reshape(true)

	return true
end


function plan.make(panel)
	--title("Workspace Frames")

	-- Does Workspace #2 already exist?
	local ws2 = panel.context.root:findTag("alt_workspace")

	panel.auto_layout = true
	panel:setScrollBars(false, true)

	local xx, yy, ww, hh = 16, 16, 192, 32


	-- Button: Create Workspace #2
	do
		local btn = panel:addChild("base/button")
		btn.x = xx
		btn.y = yy
		btn.w = ww
		btn.h = hh
		btn:initialize()
		btn.tag = "btn_crt"
		btn.enabled = not ws2
		btn:setLabel("Create Workspace #2")
		btn.wid_buttonAction = function(self)
			if _setupWS2(self.context.root) then
				self.enabled = false
				local panel = self:findAscendingKeyValue("tag", "plan_container")
				if panel then
					local button_select = panel:findTag("btn_sel")
					if button_select then
						button_select.enabled = true
					end
				end
			end
		end
		yy = yy + hh
	end

	-- Button: Select Workspace #2
	do
		local btn = panel:addChild("base/button")
		btn.x = xx
		btn.y = yy
		btn.w = ww
		btn.h = hh
		btn:initialize()
		btn.enabled = not not ws2
		btn.tag = "btn_sel"
		btn:setLabel("Activate Workspace #2")
		btn.wid_buttonAction = function(self)
			local ws2 = self.context.root:findTag("alt_workspace")
			if ws2 then
				self.context.root:setActiveWorkspace(ws2)

				local panel = self:findAscendingKeyValue("tag", "plan_container")
				if panel then
					local btn_dst = panel:findTag("btn_dst")
					if btn_dst then
						btn_dst.enabled = true
					end
				end
			end
		end
		yy = yy + hh
	end


	-- Button: Destroy Workspace #2
	do
		local btn = panel:addChild("base/button")
		btn.x = xx
		btn.y = yy
		btn.w = ww
		btn.h = hh
		btn:initialize()
		btn.enabled = not not ws2
		btn.tag = "btn_dst"
		btn:setLabel("Destroy Workspace #2")
		btn.wid_buttonAction = function(self)
			local ws1 = self.context.root:findTag("main_workspace")
			local ws2 = self.context.root:findTag("alt_workspace")
			if ws2 then
				if self.context.root.workspace == ws2 then
					self.context.root:setActiveWorkspace(ws1 or false)
				end
				ws2:remove()
				self.context.root:sortG2()
				self.enabled = false
				local panel = self:findAscendingKeyValue("tag", "plan_container")
				if panel then
					local btn_sel = panel:findTag("btn_sel")
					if btn_sel then
						btn_sel.enabled = false
					end
					local btn_crt = panel:findTag("btn_crt")
					if btn_crt then
						btn_crt.enabled = true
					end
				end
			end
		end
		yy = yy + hh
	end
end


return plan
