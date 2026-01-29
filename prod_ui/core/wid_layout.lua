local context = select(1, ...)


local widLayout = {}


local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiTable = require(context.conf.prod_ui_req .. "ui_table")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")


local sash_styles = context.resources.sash_styles


local _nm_axis2d = uiTheme.named_maps.axis_2d


widLayout._nm_layout_base = uiTable.newNamedMapV("LayoutBase",
	"zero",
	"self",
	"viewport",
	"viewport-full",
	"viewport-width",
	"viewport-height",
	"unbounded"
)


widLayout._nm_seg_edge = uiTable.newNamedMapV("SegmentEdge", "left", "right", "top", "bottom")


widLayout._nm_card_mode = uiTable.newNamedMapV("CardSizeMode", "pixel", "unit")


--[[
The parameters of each geometry mode:

"grid":
	x, y: (integer) Tile positions, from 0 to len - 1.
	w, h: (integer) Number of tiles the widget occupies.
	(Refer also to the parent's 'LO_grid' table.)

"null":
	(No parameters.)

"remaining":
	(No paremeters.)

"segment":
	edge: (_nm_seg_edge)
	len: (integer) The desired length of the segment. The final length may be reduced to make room for a sash.
	len_min: (integer) The preferred (not guaranteed) minimum and maximum segment length.
	len_max: ^
	sash_style (string|false/nil) When a string, this segment has a sash on the opposite edge.
	sash_x: (integer) Position and dimensions of the sash bounding box. Internal use.
	sash_y: ^
	sash_w: ^
	sash_h: ^

"segment-unit":
	edge: (_nm_seg_edge)
	unit: (number) The desired portion of the segment, from 0.0 to 1.0. This is a percentage of the original
		parent layout space along the segment's axis.

"relative":
	x: (integer) Position and dimensions. Always scaled.
	y: ^
	w: ^
	h: ^
	flip_x: (boolean) When true, the position is against the other side of the layout space.
	flip_y: (boolean) ^

"static":
	x: (integer) Position and dimensions. Always scaled.
	y: ^
	w: ^
	h: ^
	flip_x: (boolean) When true, the position is against the other side of the layout space.
	flip_y: (boolean) ^

"wallet":
	(No parameters. Refer to the parent's 'LO_wallet' table.)
--]]


widLayout.geo_null = {mode="null"}
widLayout.geo_remaining = {mode="remaining"}
widLayout.geo_wallet = {mode="wallet"}


local function _initGE(self, mode)
	-- Do not call with the "null", "remaining" or "wallet" modes.

	local GE = self.GE

	if GE and GE.mode == mode then
		return GE
	else
		GE = {mode=mode}
		self.GE = GE
		return GE
	end
end


widLayout.geometry_setters = {
	grid = function(self, x, y, w, h)
		uiAssert.numberNotNaN(1, x)
		uiAssert.numberNotNaN(2, y)
		uiAssert.numberNotNaNEval(3, w)
		uiAssert.numberNotNaNEval(4, h)

		local GE = _initGE(self, "grid")

		GE.x = x
		GE.y = y
		GE.w = w and math.max(0, w) or 1
		GE.h = h and math.max(0, h) or 1

		return self
	end,

	null = function(self)
		self.GE = widLayout.geo_null

		return self
	end,

	remaining = function(self)
		self.GE = widLayout.geo_remaining

		return self
	end,

	segment = function(self, edge, len, sash_style, len_min, len_max)
		uiAssert.namedMap(1, edge, widLayout._nm_seg_edge)
		uiAssert.numberNotNaN(2, len)
		uiAssert.typeEval(3, sash_style, "string")
		uiAssert.numberNotNaNEval(4, len_min)
		uiAssert.numberNotNaNEval(5, len_max)

		local GE = _initGE(self, "segment")

		GE.edge = edge
		GE.len_min = len_min and math.max(0, len_min) or 0
		GE.len_max = len_max and math.max(0, len_max) or math.huge
		GE.len = math.max(GE.len_min, math.min(len, GE.len_max))
		GE.sash_style = sash_style or nil
		GE.sash_x, GE.sash_y, GE.sash_w, GE.sash_h = 0, 0, 0, 0 -- internal use

		return self
	end,

	["segment-unit"] = function(self, edge, unit)
		uiAssert.namedMap(1, edge, widLayout._nm_seg_edge)
		uiAssert.numberNotNaN(2, unit)

		local GE = _initGE(self, "segment-unit")

		GE.edge = edge
		GE.unit = math.max(0.0, math.min(unit, 1.0))

		return self
	end,

	relative = function(self, x, y, w, h, flip_x, flip_y)
		uiAssert.numberNotNaN(1, x)
		uiAssert.numberNotNaN(2, y)
		uiAssert.numberNotNaN(3, w)
		uiAssert.numberNotNaN(4, h)
		-- don't assert 'flip_x' or 'flip_y'

		local GE = _initGE(self, "relative")

		GE.x = x
		GE.y = y
		GE.w = math.max(0, w)
		GE.h = math.max(0, h)
		GE.flip_x = not not flip_x
		GE.flip_y = not not flip_y

		return self
	end,

	static = function(self, x, y, w, h, flip_x, flip_y)
		uiAssert.numberNotNaN(1, x)
		uiAssert.numberNotNaN(2, y)
		uiAssert.numberNotNaN(3, w)
		uiAssert.numberNotNaN(4, h)
		-- don't assert 'flip_x' or 'flip_y'

		local GE = _initGE(self, "static")

		GE.x = x
		GE.y = y
		GE.w = math.max(0, w)
		GE.h = math.max(0, h)
		GE.flip_x = not not flip_x
		GE.flip_y = not not flip_y

		return self
	end,

	wallet = function(self)
		self.GE = widLayout.geo_wallet

		return self
	end,
}


local function _calculateSegment(len, sash_half, layout_len, do_scale)
	layout_len = math.max(0, layout_len - sash_half*2)
	len = math.max(0, len - sash_half)
	local scale = do_scale and context.scale or 1.0
	local cut = math.floor(math.max(0, math.min(len * scale, layout_len)))
	return cut, layout_len - cut
end


local function _querySegmentLength(wid, GE, x_axis, cross_length)
	local a, b = wid:evt_getSegmentLength(x_axis, cross_length)
	if a then
		return a, b
	end
	return GE.len, true -- len, do_scale
end


local function _getSashBreadth(style_id)
	if style_id then
		local style = sash_styles[style_id]
		if not style then
			error("unprovisioned sash style: " .. style_id)
		end
		return style.breadth_half
	end
	return 0
end


function widLayout.getSashStyleTable(id)
	local style = sash_styles[id]
	if not style then
		error("unprovisioned sash style: " .. id)
	end
	return style
end


local function _calculateSegmentUnit(unit, layout_len, original_layout_len)
	unit = math.max(0, math.min(unit, 1))
	local cut = math.floor(unit * original_layout_len)
	return cut, layout_len - cut
end


-- arguments: np (parent), nc (child, to be resized), GE (child's geometry table), orig_x, orig_y, orig_w, orig_h
widLayout.handlers = {
	grid = function(np, nc, GE)
		local grid = np.LO_grid

		-- TODO: raise an error here if the table is missing (or don't?)

		if grid then
			local cols, rows = grid.cols, grid.rows
			if cols > 0 and rows > 0 then
				nc.x = np.LO_x + math.floor(GE.x * np.LO_w / rows)
				nc.y = np.LO_y + math.floor(GE.y * np.LO_h / cols)
				nc.w = math.floor(np.LO_w / rows * GE.w)
				nc.h = math.floor(np.LO_h / cols * GE.h)

				return
			end
		end

		nc.x, nc.y, nc.w, nc.h = 0, 0, 0, 0
	end,

	null = function()
		-- do nothing
	end,

	remaining = function(np, nc)
		nc.x, nc.y, nc.w, nc.h = np.LO_x, np.LO_y, np.LO_w, np.LO_h
	end,

	segment = function(np, nc, GE)
		local edge, sash_style = GE.edge, GE.sash_style
		local sash_half = _getSashBreadth(sash_style)
		-- NOTE: the sash box is placed on the opposite side of 'edge'.

		if edge == "left" then
			nc.y, nc.h = np.LO_y, np.LO_h
			local len, do_scale = _querySegmentLength(nc, GE, true, nc.h)
			len = math.max(GE.len_min, math.min(len, GE.len_max))
			nc.w, np.LO_w = _calculateSegment(len, sash_half, np.LO_w, do_scale)
			nc.x = np.LO_x
			np.LO_x = np.LO_x + nc.w + sash_half*2
			if sash_style then
				GE.sash_x, GE.sash_y, GE.sash_w, GE.sash_h = nc.w, 0, sash_half*2, nc.h
			else
				GE.sash_x, GE.sash_y, GE.sash_w, GE.sash_h = 0, 0, 0, 0
			end

		elseif edge == "right" then
			nc.y, nc.h = np.LO_y, np.LO_h
			local len, do_scale = _querySegmentLength(nc, GE, true, nc.h)
			len = math.max(GE.len_min, math.min(len, GE.len_max))
			local old_LO_w = np.LO_w
			nc.w, np.LO_w = _calculateSegment(len, sash_half, np.LO_w, do_scale)
			nc.x = np.LO_x + old_LO_w - nc.w
			if sash_style then
				GE.sash_x, GE.sash_y, GE.sash_w, GE.sash_h = -sash_half*2, 0, sash_half*2, nc.h
			else
				GE.sash_x, GE.sash_y, GE.sash_w, GE.sash_h = 0, 0, 0, 0
			end

		elseif edge == "top" then
			nc.x, nc.w = np.LO_x, np.LO_w
			local len, do_scale = _querySegmentLength(nc, GE, false, nc.w)
			len = math.max(GE.len_min, math.min(len, GE.len_max))
			nc.h, np.LO_h = _calculateSegment(len, sash_half, np.LO_h, do_scale)
			nc.y = np.LO_y
			np.LO_y = np.LO_y + nc.h + sash_half*2
			if sash_style then
				GE.sash_x, GE.sash_y, GE.sash_w, GE.sash_h = 0, nc.h, nc.w, sash_half * 2
			else
				GE.sash_x, GE.sash_y, GE.sash_w, GE.sash_h = 0, 0, 0, 0
			end

		elseif edge == "bottom" then
			nc.x, nc.w = np.LO_x, np.LO_w
			local len, do_scale = _querySegmentLength(nc, GE, false, nc.w)
			len = math.max(GE.len_min, math.min(len, GE.len_max))
			local old_LO_h = np.LO_h
			nc.h, np.LO_h = _calculateSegment(len, sash_half, np.LO_h, do_scale)
			nc.y = np.LO_y + old_LO_h - nc.h
			if sash_style then
				GE.sash_x, GE.sash_y, GE.sash_w, GE.sash_h = 0, -sash_half*2, nc.w, sash_half*2
			else
				GE.sash_x, GE.sash_y, GE.sash_w, GE.sash_h = 0, 0, 0, 0
			end

		else
			error("bad segment edge ID")
		end
	end,

	["segment-unit"] = function(np, nc, GE, orig_x, orig_y, orig_w, orig_h)
		local edge = GE.edge

		if edge == "left" then
			nc.y, nc.h = np.LO_y, np.LO_h
			nc.w, np.LO_w = _calculateSegmentUnit(GE.unit, np.LO_w, orig_w)
			nc.x = np.LO_x
			np.LO_x = np.LO_x + nc.w

		elseif edge == "right" then
			nc.y, nc.h = np.LO_y, np.LO_h
			nc.w, np.LO_w = _calculateSegmentUnit(GE.unit, np.LO_w, orig_w)
			nc.x = np.LO_x + np.LO_w

		elseif edge == "top" then
			nc.x, nc.w = np.LO_x, np.LO_w
			nc.h, np.LO_h = _calculateSegmentUnit(GE.unit, np.LO_h, orig_h)
			nc.y = np.LO_y
			np.LO_y = np.LO_y + nc.h

		elseif edge == "bottom" then
			nc.x, nc.w = np.LO_x, np.LO_w
			nc.h, np.LO_h = _calculateSegmentUnit(GE.unit, np.LO_h, orig_h)
			nc.y = np.LO_y + np.LO_h

		else
			error("bad segment edge ID")
		end
	end,

	relative = function(np, nc, GE, orig_x, orig_y, org_w, orig_h)
		local scale = context.scale

		local px, py, pw, ph = np.LO_x, np.LO_y, np.LO_w, np.LO_h

		nc.w = math.floor(GE.w * scale)
		nc.x = math.floor(GE.x * scale)
		if GE.flip_x then
			nc.x = pw - nc.w - nc.x
		end
		nc.x = nc.x + px

		nc.h = math.floor(GE.h * scale)
		nc.y = math.floor(GE.y * scale)
		if GE.flip_y then
			nc.y = ph - nc.h - nc.y
		end
		nc.y = nc.y + py
	end,

	static = function(np, nc, GE, orig_x, orig_y, orig_w, orig_h)
		local scale = context.scale

		local px, py, pw, ph = orig_x, orig_y, orig_w, orig_h

		nc.w = math.floor(GE.w * scale)
		nc.x = math.floor(GE.x * scale)
		if GE.flip_x then
			nc.x = pw - nc.w - nc.x
		end
		nc.x = nc.x + px

		nc.h = math.floor(GE.h * scale)
		nc.y = math.floor(GE.y * scale)
		if GE.flip_y then
			nc.y = ph - nc.h - nc.y
		end
		nc.y = nc.y + py
	end,

	wallet = function(np, nc, GE, orig_x, orig_y, orig_w, orig_h)
		local scale = context.scale

		-- TODO: raise an error here if the table is missing (or don't?)

		local wal = np.LO_wallet
		if not wal then
			nc.x, nc.y, nc.w, nc.h = 0, 0, 0, 0
			return
		end

		local mode_x, mode_y = wal.mode_x, wal.mode_y
		local cw, ch
		if mode_x == "pixel" then
			cw = math.floor(wal.card_w * scale)
		else -- mode_x == "unit"
			cw = math.floor(np.LO_w * wal.card_w)
		end

		if mode_y == "pixel" then
			ch = math.floor(wal.card_h * scale)
		else -- mode_y == "unit"
			ch = math.floor(np.LO_h * wal.card_h)
		end

		local main_axis = wal.main_axis
		local cpl = wal.cards_per_line
		local dx, dy = wal.dx, wal.dy

		nc.x, nc.y, nc.w, nc.h = wal.x, wal.y, cw, ch

		if wal.main_axis == "x" then
			wal.x = wal.x + cw*dx
			wal.count = wal.count + 1
			if dx < 0 then
				if cpl == 0 and wal.x < np.LO_x
				or cpl > 0 and wal.count >= cpl
				then
					wal.x = np.LO_x + np.LO_w - cw
					wal.y = wal.y + ch*dy
					wal.count = 0
				end

			elseif dx > 0 then
				if cpl == 0 and wal.x >= np.LO_x + np.LO_w - cw
				or cpl > 0 and wal.count >= cpl
				then
					wal.x = np.LO_x
					wal.y = wal.y + ch*dy
					wal.count = 0
				end
			end
		else -- main_axis == "y"
			wal.y = wal.y + ch*dy
			wal.count = wal.count + 1
			if dy < 0 then
				if cpl == 0 and wal.y < np.LO_y
				or cpl > 0 and wal.count >= cpl
				then
					wal.y = np.LO_y + np.LO_h - ch
					wal.x = wal.x + cw*dx
					wal.count = 0
				end

			elseif dy > 0 then
				if cpl == 0 and wal.y >= np.LO_y + np.LO_h - ch
				or cpl > 0 and wal.count >= cpl
				then
					wal.y = np.LO_y
					wal.x = wal.x + cw*dx
					wal.count = 0
				end
			end
		end
	end
}


local methods = {}


local function _hof_sortLayoutList(a, b)
	return a.GE_order < b.GE_order
end


function methods:layoutSort()
	table.sort(self.LO_list, _hof_sortLayoutList)
end


function methods:layoutSetBase(layout_base)
	uiAssert.namedMap(1, layout_base, widLayout._nm_layout_base)

	self.LO_base = layout_base

	return self
end


function methods:layoutGetBase()
	return self.LO_base
end


function methods:layoutSetMargin(x1, y1, x2, y2)
	uiAssert.numberNotNaN(1, x1)

	if y1 then
		uiAssert.numberNotNaN(2, y1)
		uiAssert.numberNotNaN(3, x2)
		uiAssert.numberNotNaN(4, y2)

		self.LO_margin_x1 = math.max(0, x1)
		self.LO_margin_y1 = math.max(0, y1)
		self.LO_margin_x2 = math.max(0, x2)
		self.LO_margin_y2 = math.max(0, y2)
	else
		self.LO_margin_x1 = math.max(0, x1)
		self.LO_margin_y1 = math.max(0, x1)
		self.LO_margin_x2 = math.max(0, x1)
		self.LO_margin_y2 = math.max(0, x1)
	end

	return self
end


function methods:layoutGetMargin()
	return self.LO_margin_x1, self.LO_margin_y1, self.LO_margin_x2, self.LO_margin_y2
end


-- parent.LO_grid: A state table for the 'grid' widget geometry.
local _mt_grid = {
	-- The numbers of columns and rows in the grid.
	cols = 0,
	rows = 0
}


local function _checkGridTable(self)
	self.LO_grid = self.LO_grid or setmetatable({}, _mt_grid)

	return self.LO_grid
end


function methods:layoutSetGridDimensions(cols, rows)
	uiAssert.numberNotNaN(1, cols)
	uiAssert.numberNotNaN(2, rows)

	local LO_grid = _checkGridTable(self)

	LO_grid.cols = cols
	LO_grid.rows = rows

	return self
end


function methods:layoutGetGridDimensions(cols, rows)
	local LO_grid = _checkGridTable(self)

	return LO_grid.cols, LO_grid.rows
end


-- parent.LO_wallet: A state table for the 'wallet' widget geometry.
local _mt_wallet = {
	-- Dimensions of the wallet cards. Must be zero or greater.
	card_w=0, card_h=0,

	-- How to measure cards along each axis.
	-- pixel: as (scaled) pixels
	-- unit: as a portion of the layout space, from 0.0 to 1.0.
	mode_x="pixel", mode_y="pixel",

	-- Number of items per line (along the main axis). Must be zero or greater; when
	-- zero, the limit is based on the layout space.
	cards_per_line=0,

	-- Increment vector, to get to the next card position.
	dx=0, dy=0,

	-- Which axis increments first: "x" or "y".
	main_axis="x",

	-- The temporary card position while updating the layout. Do not modify.
	x=0, y=0,

	-- The temporary count of cards on this line. Do not modify.
	count=0,
}
_mt_wallet.__index = _mt_wallet


local function _checkWalletTable(self)
	self.LO_wallet = self.LO_wallet or setmetatable({}, _mt_wallet)

	return self.LO_wallet
end


function methods:layoutSetWalletCardSize(mode_x, mode_y, card_w, card_h)
	uiAssert.namedMap(1, mode_x, widLayout._nm_card_mode)
	uiAssert.namedMap(2, mode_y, widLayout._nm_card_mode)
	uiAssert.numberGE(3, card_w, 0)
	uiAssert.numberGE(4, card_h, 0)

	if mode_x == "unit" then
		card_w = math.min(card_w, 1.0)
	end

	if mode_y == "unit" then
		card_h = math.min(card_h, 1.0)
	end

	local LO_wallet = _checkWalletTable(self)

	LO_wallet.mode_x = mode_x
	LO_wallet.mode_y = mode_y
	LO_wallet.card_w = card_w
	LO_wallet.card_h = card_h

	return self
end


function methods:layoutGetWalletCardSize()
	local LO_wallet = _checkWalletTable(self)

	return LO_wallet.mode_x, LO_wallet.mode_y, LO_wallet.card_w, LO_wallet.card_h
end


function methods:layoutSetWalletCardsPerLine(cards_per_line)
	uiAssert.numberGE(1, cards_per_line, 0)

	local LO_wallet = _checkWalletTable(self)

	LO_wallet.cards_per_line = cards_per_line

	return self
end


function methods:layoutGetWalletCardsPerLine()
	local LO_wallet = _checkWalletTable(self)

	return LO_wallet.cards_per_line
end


function methods:layoutSetWalletFlow(main_axis, dx, dy)
	uiAssert.namedMap(1, main_axis, _nm_axis2d)
	uiAssert.oneOf(2, dx, -1, 1)
	uiAssert.oneOf(3, dy, -1, 1)

	local LO_wallet = _checkWalletTable(self)

	LO_wallet.main_axis = main_axis
	LO_wallet.dx = dx
	LO_wallet.dy = dy

	return self
end


function methods:layoutGetWalletFlow()
	local LO_wallet = _checkWalletTable(self)

	return LO_wallet.main_axis, LO_wallet.dx, LO_wallet.dy
end


function widLayout.setupContainerDef(def)
	uiTable.patch(def, methods, true)
end


function widLayout.setupLayoutList(self)
	self.LO_list = {}
	self.LO_base = "self"
	self.LO_x, self.LO_y, self.LO_w, self.LO_h = 0, 0, 0, 0
	self.LO_margin_x1, self.LO_margin_y1, self.LO_margin_x2, self.LO_margin_y2 = 0, 0, 0, 0

	-- 'LO_grid' and 'LO_wallet' are created upon calling their associated setter/getter methods.
end


function widLayout.resetLayoutSpace(self)
	local to = self.LO_base

	if to == "zero" then
		self.LO_x, self.LO_y, self.LO_w, self.LO_h = 0, 0, 0, 0

	elseif to == "self" then
		self.LO_x, self.LO_y, self.LO_w, self.LO_h = 0, 0, self.w, self.h

	elseif to == "viewport" then
		local vp = self.vp
		self.LO_x, self.LO_y, self.LO_w, self.LO_h = 0, 0, vp.w, vp.h

	elseif to == "viewport-full" then
		local vp = self.vp
		self.LO_x, self.LO_y, self.LO_w, self.LO_h = vp.x, vp.y, vp.w, vp.h

	elseif to == "viewport-width" then
		self.LO_x, self.LO_y, self.LO_w, self.LO_h = 0, 0, self.vp.w, math.huge

	elseif to == "viewport-height" then
		self.LO_x, self.LO_y, self.LO_w, self.LO_h = 0, 0, math.huge, self.vp.h

	elseif to == "unbounded" then
		self.LO_x, self.LO_y, self.LO_w, self.LO_h = 0, 0, math.huge, math.huge

	else
		error("invalid layout base mode.")
	end
end


function widLayout.applyLayout(self)
	-- check 'self.LO_list' before calling.

	--print("widLayout.applyLayout(): start")

	local scale = context.scale

	-- Margin reduction
	local mx1 = math.floor(self.LO_margin_x1 * scale)
	local my1 = math.floor(self.LO_margin_y1 * scale)
	local mx2 = math.floor(self.LO_margin_x2 * scale)
	local my2 = math.floor(self.LO_margin_y2 * scale)

	self.LO_x = self.LO_x + mx1
	self.LO_y = self.LO_y + my1
	self.LO_w = math.max(0, self.LO_w - mx1 - mx2)
	self.LO_h = math.max(0, self.LO_h - my1 - my2)

	local orig_x, orig_y, orig_w, orig_h = self.LO_x, self.LO_y, self.LO_w, self.LO_h

	-- Initialize wallet state
	local LO_wallet = self.LO_wallet
	if LO_wallet then
		LO_wallet.x = (LO_wallet.dx == 1) and self.LO_x or self.LO_x + self.LO_w - LO_wallet.card_w
		LO_wallet.y = (LO_wallet.dy == 1) and self.LO_y or self.LO_y + self.LO_h - LO_wallet.card_h
		LO_wallet.count = 0
	end

	for i, child in ipairs(self.LO_list) do
		local GE = child.GE
		local handler = widLayout.handlers[GE.mode]
		if not handler then
			error("invalid or missing layout handler: " .. tostring(GE.mode))
		end

		--print("old self XYWH", self.x, self.y, self.w, self.h)
		handler(self, child, GE, orig_x, orig_y, orig_w, orig_h)
		--print("new self XYWH", self.x, self.y, self.w, self.h)

		-- Outpad reduction
		local ox1 = math.floor(child.GE_outpad_x1 * scale)
		local oy1 = math.floor(child.GE_outpad_y1 * scale)
		local ox2 = math.floor(child.GE_outpad_x2 * scale)
		local oy2 = math.floor(child.GE_outpad_y2 * scale)

		child.x = child.x + ox1
		child.y = child.y + oy1
		child.w = math.max(0, child.w - ox1 - ox2)
		child.h = math.max(0, child.h - oy1 - oy2)
	end

	--print("widLayout.applyLayout(): end")
end


return widLayout
