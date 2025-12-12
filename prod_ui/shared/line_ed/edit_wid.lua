-- Functions, methods and plug-ins for widgets with LineEditor (either) state.


local context = select(1, ...)


local editWid = {}


local uiTable = require(context.conf.prod_ui_req .. "ui_table")


editWid._nm_align = uiTable.newNamedMapV("EditAlignMode", "left", "center", "right")

editWid._nm_ghost_mode = uiTable.newNamedMapV("GhostTextMode", "no-text", "no-focus", "off")
--[[
no-text: show when the text box is empty.
no-focus: show when the text box is empty and unfocused.
off: never show ghost text.
--]]

editWid._nm_bad_input = uiTable.newNamedMapV("EditBadInputRule", "trim", "replacement_char")


function editWid.updateCaretShape(self)
	local LE = self.LE

	self.LE_caret_x = LE.caret_box_x
	self.LE_caret_y = LE.caret_box_y
	self.LE_caret_w = LE.caret_box_w
	self.LE_caret_h = LE.caret_box_h

	if self.LE_replace_mode then
		self.LE_caret_fill = "line"
	else
		self.LE_caret_fill = "fill"
		self.LE_caret_w = LE.caret_line_width
	end
end


function editWid.resetCaretBlink(self)
	self.LE_caret_blink_time = self.LE_caret_blink_reset
end


function editWid.updateCaretBlink(self, dt)
	if not context.window_focus then
		self.LE_caret_blink_time = 0
		self.LE_caret_showing = true
	else
		local blink_on, blink_off = self.LE_caret_blink_on, self.LE_caret_blink_off

		self.LE_caret_blink_time = self.LE_caret_blink_time + dt
		if self.LE_caret_blink_time > blink_on + blink_off then
			self.LE_caret_blink_time = math.max(-(blink_on + blink_off), self.LE_caret_blink_time - (blink_on + blink_off))
		end

		self.LE_caret_showing = self.LE_caret_blink_time < blink_off
	end
end


return editWid