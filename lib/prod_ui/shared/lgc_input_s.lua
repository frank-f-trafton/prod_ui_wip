--[[
Shared widget logic for single-line text input.
--]]


local context = select(1, ...)


local lgcInputS = {}


local commonMenu = require(context.conf.prod_ui_req .. "logic.common_menu")
local commonWimp = require(context.conf.prod_ui_req .. "logic.common_wimp")
local editActS = context:getLua("shared/line_ed/s/edit_act_s")
local editMethodsS = context:getLua("shared/line_ed/s/edit_methods_s")
local itemOps = require(context.conf.prod_ui_req .. "logic.item_ops")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local widShared = require(context.conf.prod_ui_req .. "logic.wid_shared")


-- Widget def configuration.
function lgcInputS.setupDef(def)

	-- Attach editing methods to def.
	for k, v in pairs(editMethodsS) do
		def[k] = v
	end
end


function lgcInputS.setupInstance(self)

	-- Caret position and dimensions. Based on 'line_ed.caret_box_*'.
	self.caret_x = 0
	self.caret_y = 0
	self.caret_w = 0
	self.caret_h = 0

	self.caret_fill = "line"

	-- Extends the caret dimensions when keeping the caret within the bounds of the viewport.
	self.caret_extend_x = 0
	self.caret_extend_y = 0

	-- Used to update viewport scrolling as a result of dragging the mouse in update().
	self.mouse_drag_x = 0

	-- Position offset when clicking the mouse.
	-- This is only valid when a mouse action is in progress.
	self.click_byte = 1

	-- How far to offset the line X position depending on the alignment.
	self.align_offset = 0

	-- string: display this text when the input box is empty.
	-- false: disabled.
	self.ghost_text = false

	-- false: use content text alignment.
	-- "left", "center", "right", "justify"
	self.ghost_text_align = false

	-- Caller should create a single line editor object at `self.line_ed`.
end


function lgcInputS.method_scrollGetCaretInBounds(self, immediate)

	local line_ed = self.line_ed

	--print("scrollGetCaretInBounds() BEFORE", self.scr_tx, self.scr_ty)

	-- Get the extended caret rectangle.
	local car_x1 = self.align_offset + line_ed.caret_box_x - self.caret_extend_x
	local car_y1 = line_ed.caret_box_y - self.caret_extend_y
	local car_x2 = self.align_offset + line_ed.caret_box_x + line_ed.caret_box_w + self.caret_extend_x
	local car_y2 = line_ed.caret_box_y + line_ed.caret_box_h + self.caret_extend_y

	-- Clamp the scroll target.
	self.scr_tx = math.max(car_x2 - self.vp_w, math.min(self.scr_tx, car_x1))
	self.scr_ty = math.max(car_y2 - self.vp_h, math.min(self.scr_ty, car_y1))

	if immediate then
		self.scr_fx = self.scr_tx
		self.scr_fy = self.scr_ty
		self.scr_x = math.floor(0.5 + self.scr_fx)
		self.scr_y = math.floor(0.5 + self.scr_fy)
	end

	--print("car_x1", car_x1, "car_y1", car_y1, "car_x2", car_x2, "car_y2", car_y2)
	--print("scr tx ty", self.scr_tx, self.scr_ty)

--[[
	print("BEFORE",
		"scr_x", self.scr_x, "scr_y", self.scr_y, "scr_tx", self.scr_tx, "scr_ty", self.scr_ty,
		"vp_x", self.vp_x, "vp_y", self.vp_y, "vp_w", self.vp_w, "vp_h", self.vp_h,
		"vp2_x", self.vp2_x, "vp2_y", self.vp2_y, "vp2_w", self.vp2_w, "vp2_h", self.vp2_h)
--]]
	self:scrollClampViewport()

--[[
	print("AFTER",
		"scr_x", self.scr_x, "scr_y", self.scr_y, "scr_tx", self.scr_tx, "scr_ty", self.scr_ty,
		"vp_x", self.vp_x, "vp_y", self.vp_y, "vp_w", self.vp_w, "vp_h", self.vp_h,
		"vp2_x", self.vp2_x, "vp2_y", self.vp2_y, "vp2_w", self.vp2_w, "vp2_h", self.vp2_h)
--]]
	--print("scrollGetCaretInBounds() AFTER", self.scr_tx, self.scr_ty)
	--print("doc_w", self.doc_w, "doc_h", self.doc_h)
	--print("vp xywh", self.vp_x, self.vp_y, self.vp_w, self.vp_h)
end


-- @param mouse_x, mouse_y Mouse position relative to widget top-left.
-- @return true if event propagation should be halted.
function lgcInputS.mousePressLogic(self, button, mouse_x, mouse_y)

	local line_ed = self.line_ed
	local context = self.context

	self.line_ed:resetCaretBlink()

	if button == 1 then
		self.press_busy = "text-drag"

		-- Apply scroll + margin offsets
		local mouse_sx = mouse_x + self.scr_x - self.vp_x - self.align_offset

		local core_byte = line_ed:getCharacterDetailsAtPosition(mouse_sx, true)

		if context.cseq_button == 1 then
			-- Not the same byte position as last click: force single-click mode.
			if context.cseq_presses > 1  and core_byte ~= self.click_byte then
				context:forceClickSequence(self, button, 1)
				-- XXX Causes 'cseq_presses' to go from 3 to 1. Not a huge deal but worth checking over.
			end

			if context.cseq_presses == 1 then
				self:caretToX(true, mouse_sx, true)

				self.click_byte = line_ed.car_byte

				self.update_flag = true

			elseif context.cseq_presses == 2 then
				self.click_byte = line_ed.car_byte

				-- Highlight group from highlight position to mouse position.
				self:highlightCurrentWord()

				self.update_flag = true

			elseif context.cseq_presses == 3 then
				self.click_byte = line_ed.car_byte

				--- Highlight everything.
				self:highlightAll()

				self.update_flag = true
			end
		end

	elseif button == 2 then
		commonMenu.widgetConfigureMenuItems(self, self.pop_up_def)

		local root = self:getTopWidgetInstance()

		--print("text_box, current thimble", self.context.current_thimble, root.banked_thimble)

		local ax, ay = self:getAbsolutePosition()
		local pop_up = commonWimp.makePopUpMenu(self, self.pop_up_def, ax + mouse_x, ay + mouse_y)
		root:runStatement("rootCall_doctorCurrentPressed", self, pop_up, "menu-drag")

		pop_up:tryTakeThimble()

		root:runStatement("rootCall_bankThimble", self)

		-- Halt propagation
		return true
	end
end


function lgcInputS.executeRemoteAction(self, item_t)

	local ok, update_viewport, update_caret, write_history = self:executeBoundAction(item_t.bound_func)
	if ok then
		self.update_flag = true
	end

	self:updateDocumentDimensions(self)
	self:scrollGetCaretInBounds(true)
end


function lgcInputS.method_updateDocumentDimensions(self)

	local line_ed = self.line_ed
	local font = line_ed.font

	self.doc_w = font:getWidth(line_ed.disp_text)
	self.doc_h = math.floor(font:getHeight() * font:getLineHeight())

	self:updateAlignOffset()
end


--- Call after changing alignment.
function lgcInputS.method_updateAlignOffset(self)

	local align = self.line_ed.align

	if align == "left" then
		self.align_offset = 0

	elseif align == "center" then
		self.align_offset = (self.doc_w < self.vp_w) and math.floor(0.5 + self.vp_w/2) or math.floor(0.5 + self.doc_w/2)

	else -- align == "right"
		self.align_offset = (self.doc_w < self.vp_w) and self.vp_w or self.doc_w
	end
end


-- Configuration functions for pop-up menu items.


function lgcInputS.configItem_undo(item, client)

	item.selectable = true
	item.actionable = (client.line_ed.hist.pos > 1)
end


function lgcInputS.configItem_redo(item, client)

	item.selectable = true
	item.actionable = (client.line_ed.hist.pos < #client.line_ed.hist.ledger)
end


function lgcInputS.configItem_cutCopyDelete(item, client)

	item.selectable = true
	item.actionable = client.line_ed:isHighlighted()
end


function lgcInputS.configItem_paste(item, client)

	item.selectable = true
	item.actionable = true
end


function lgcInputS.configItem_selectAll(item, client)

	item.selectable = true
	item.actionable = (#client.line_ed.line > 0)
end


-- The default pop-up menu definition.
-- [XXX 17] Add key mnemonics and shortcuts for text box pop-up menu
lgcInputS.pop_up_def = {
	{
		type = "command",
		text = "Undo",
		callback = lgcInputS.executeRemoteAction,
		bound_func = editActS.undo,
		config = lgcInputS.configItem_undo,
	}, {
		type = "command",
		text = "Redo",
		callback = lgcInputS.executeRemoteAction,
		bound_func = editActS.redo,
		config = lgcInputS.configItem_redo,
	},
	itemOps.def_separator,
	{
		type = "command",
		text = "Cut",
		callback = lgcInputS.executeRemoteAction,
		bound_func = editActS.cut,
		config = lgcInputS.configItem_cutCopyDelete,
	}, {
		type = "command",
		text = "Copy",
		callback = lgcInputS.executeRemoteAction,
		bound_func = editActS.copy,
		config = lgcInputS.configItem_cutCopyDelete,
	}, {
		type = "command",
		text = "Paste",
		callback = lgcInputS.executeRemoteAction,
		bound_func = editActS.paste,
		config = lgcInputS.configItem_paste,
	}, {
		type = "command",
		text = "Delete",
		callback = lgcInputS.executeRemoteAction,
		bound_func = editActS.deleteHighlighted,
		config = lgcInputS.configItem_cutCopyDelete,
	},
	itemOps.def_separator,
	{
		type = "command",
		text = "Select All",
		callback = lgcInputS.executeRemoteAction,
		bound_func = editActS.selectAll,
		config = lgcInputS.configItem_selectAll,
	},
}


return lgcInputS
