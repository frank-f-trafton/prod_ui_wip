-- Access through 'wid_shared.lua'.


local context = select(1, ...)

--[[
uiCall_reshapePre
uiCall_reshapeInner
uiCall_reshapeInner2
uiCall_reshapePost
--]]


--[[DBG]] local PR, TS = print, tostring
--[[DBG]] local ID = function(self) return tostring(self.id) end


local reshapers = {}


local uiLayout = require(context.conf.prod_ui_req .. "ui_layout")


local function _clampDimensions(self)
	self.w = math.max(self.min_w, math.min(self.w, self.max_w))
	self.h = math.max(self.min_h, math.min(self.h, self.max_h))
end


function reshapers.null(self)
	--[[DBG]] PR("reshaper.null: " .. ID(self))
	_clampDimensions(self)
end


function reshapers.pre(self)
	--[[DBG]] PR("reshaper.pre: " .. ID(self))
	self:uiCall_reshapePre()
	_clampDimensions(self)
end


function reshapers.post(self)
	--[[DBG]] PR("reshaper.post: " .. ID(self))
	self.w, self.h = self.pref_w or self.w, self.pref_h or self.h
	_clampDimensions(self)
	self:uiCall_reshapePost()
end


function reshapers.prePost(self)
	--[[DBG]] PR("reshaper.prePost: " .. ID(self))
	if self:uiCall_reshapePre() then
		--[[DBG]] PR("reshaper.prePost: ended early by reshapePre.")
		return
	end
	self.w, self.h = self.pref_w or self.w, self.pref_h or self.h
	_clampDimensions(self)
	self:uiCall_reshapePost()
end


function reshapers.branch(self)
	--[[DBG]] PR("reshaper.branch: " .. ID(self))
	if self:uiCall_reshapePre() then
		--[[DBG]] PR("reshaper.branch: ended early by reshapePre.")
		return
	end
	self.w, self.h = self.pref_w or self.w, self.pref_h or self.h
	for i, wid in ipairs(self.children) do
		wid:reshape()
	end

	_clampDimensions(self)
	self:uiCall_reshapePost()
end


function reshapers.layout(self)
	--[[DBG]] PR("reshaper.full: " .. ID(self) .. ": start.")

	if self:uiCall_reshapePre() then
		--[[DBG]] PR("reshaper.full: ended early by reshapePre.")
		return
	end

	self.w, self.h = self.pref_w or self.w, self.pref_h or self.h

	if self.lp_seq then
		for i, wid in ipairs(self.lp_seq) do
			--[[DBG]] PR("reshaper.full: " .. ID(self) .. ": lp_seq #" .. i .. "(" .. (self.lp_seq.id or "n/a") .. ")")
			-- lo_command is present: this is not a widget, but an arbitrary table with a command + optional data to run.
			if wid.lo_command then
				wid.lo_command(self, wid)
			-- Otherwise, treat as a widget.
			else
				if wid._dead == "dead" then
					error("dead widget reference in layout sequence. It should have been cleaned up when removed.")
				end

				local lc_func = wid.lc_func
				if type(lc_func) == "string" then
					--[[DBG]] PR("reshaper.full: " .. ID(self) .. ": lc_func: " .. lc_func)
					lc_func = uiLayout.handlers[lc_func]
				end

				if not lc_func then
					error("widget has no layout enum or function.")
				end

				_clampDimensions(wid)

				wid:uiCall_reshapeInner()

				lc_func(self, wid, wid.lc_info)

				_clampDimensions(wid)

				wid:uiCall_reshapeInner2()

				--[[DBG]] PR("reshaper.full: " .. ID(self) .. ": seq i #" .. i .. ": child #" .. wid:getIndex() .. " (" .. TS(wid.id) .. ")")
				wid:reshape()
			end
		end
	end

	_clampDimensions(self)
	self:uiCall_reshapePost()

	--[[DBG]] PR("reshaper.full: " .. ID(self) .. ": end")
end


return reshapers