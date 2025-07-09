--[[
Shared widget logic for multi-line text input.
--]]


local context = select(1, ...)


local lgcInputM = {}


local editActM = context:getLua("shared/line_ed/m/edit_act_m")
local editMethodsM = context:getLua("shared/line_ed/m/edit_methods_m")
local lineEdM = context:getLua("shared/line_ed/m/line_ed_m")
local pTable = require(context.conf.prod_ui_req .. "lib.pile_table")


-- Widget def configuration.
function lgcInputM.setupDef(def)
	pTable.patch(def, editMethodsM, true)
end


function lgcInputM.setupInstance(self)
	-- Extends the caret dimensions when keeping the caret within the bounds of the viewport.
	self.caret_extend_x = 0
	self.caret_extend_y = 0

	-- How far to offset the line X position depending on the alignment.
	self.align_offset = 0

	self.line_ed = lineEdM.new()

	-- Enable/disable specific editing actions.
	self.allow_input = true -- affects nearly all operations, except navigation, highlighting and copying
	self.allow_cut = true
	self.allow_copy = true
	self.allow_paste = true
	self.allow_highlight = true -- XXX: Whoops, this is not checked in the mouse action code.

	-- Affects presses of enter/return and the pasting of text that includes line feeds.
	self.allow_line_feed = true

	self.allow_tab = false -- affects single presses of the tab key
	self.allow_untab = false -- affects shift+tab (unindenting)
	self.tabs_to_spaces = true -- affects '\t' in writeText()

	-- When inserting a new line, copies the leading whitespace from the previous line.
	self.auto_indent = false

	-- When true, typing overwrites the current position instead of inserting.
	-- Exception: Replace Mode still inserts characters at the end of a line (so before a line feed character or
	-- the end of the text string).
	self.replace_mode = false

	-- What to do when there's a UTF-8 encoding problem.
	-- Applies to input text, and also to clipboard get/set.
	-- See 'textUtil.sanitize()' for options.
	self.bad_input_rule = false

	-- Should be updated with core dimensions change.
	self.page_jump_steps = 1

	-- Helps with amending vs making new history entries
	self.input_category = false

	-- Max number of Unicode characters (not bytes) permitted in the field.
	self.u_chars_max = 5000
end


function lgcInputM.cb_action(self, item_t)
	local ok, update_viewport, caret_in_view, write_history = self:executeBoundAction(item_t.func)
	if ok then
		self.update_flag = true
	end

	self:updateDocumentDimensions(self)
	self:scrollGetCaretInBounds(true)
end


-- Configuration functions for pop-up menu items.


function lgcInputM.configItem_undo(item, client)
	item.selectable = true
	item.actionable = (client.line_ed.hist.pos > 1)
end


function lgcInputM.configItem_redo(item, client)
	item.selectable = true
	item.actionable = (client.line_ed.hist.pos < #client.line_ed.hist.ledger)
end


function lgcInputM.configItem_cutCopyDelete(item, client)
	item.selectable = true
	item.actionable = client.line_ed:isHighlighted()
end


function lgcInputM.configItem_paste(item, client)
	item.selectable = true

	-- XXX: There is an SDL function to check if the clipboard has text: https://wiki.libsdl.org/SDL_HasClipboardText
	-- I tested it here: https://github.com/rabbitboots/love/tree/12.0-development-clipboard/src/modules/system
	-- (Search 'hasclipboard' in src/modules/system.)
	-- But the SDL function didn't seem to be 100% reliable when I looked at it (and I don't recall when that
	-- was). Have to follow up on it.

	-- Something like this:
	-- item.actionable = love.system.hasClipboardText()

	item.actionable = true
end


function lgcInputM.configItem_selectAll(item, client)
	item.selectable = true
	item.actionable = (not client.line_ed.lines:isEmpty())
end


-- The default pop-up menu definition.
-- [XXX 17] Add key mnemonics and shortcuts for text box pop-up menu
lgcInputM.pop_up_def = {
	{
		type = "command",
		text = "Undo",
		callback = lgcInputM.cb_action,
		func = editActM.undo,
		config = lgcInputM.configItem_undo,
	}, {
		type = "command",
		text = "Redo",
		callback = lgcInputM.cb_action,
		func = editActM.redo,
		config = lgcInputM.configItem_redo,
	},
	{type="separator"},
	{
		type = "command",
		text = "Cut",
		callback = lgcInputM.cb_action,
		func = editActM.cut,
		config = lgcInputM.configItem_cutCopyDelete,
	}, {
		type = "command",
		text = "Copy",
		callback = lgcInputM.cb_action,
		func = editActM.copy,
		config = lgcInputM.configItem_cutCopyDelete,
	}, {
		type = "command",
		text = "Paste",
		callback = lgcInputM.cb_action,
		func = editActM.paste,
		config = lgcInputM.configItem_paste,
	}, {
		type = "command",
		text = "Delete",
		callback = lgcInputM.cb_action,
		func = editActM.deleteHighlighted,
		config = lgcInputM.configItem_cutCopyDelete,
	},
	{type="separator"},
	{
		type = "command",
		text = "Select All",
		callback = lgcInputM.cb_action,
		func = editActM.selectAll,
		config = lgcInputM.configItem_selectAll,
	},
}


return lgcInputM