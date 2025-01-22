-- ProdUI theme: Vacuum


local themeDef = {}


local THIS_THEME_PATH, context = select(1, ...) -- path/to/vacuum/vacuum.lua
local PROD_UI_REQ = context.conf.prod_ui_req


local pTable = require(PROD_UI_REQ .. "lib.pile_table")
local uiGraphics = require(PROD_UI_REQ .. "ui_graphics")
local uiRes = require(PROD_UI_REQ .. "ui_res")
local uiTheme = require(PROD_UI_REQ .. "ui_theme")
local quadSlice = require(PROD_UI_REQ .. "graphics.quad_slice")


local BASE_REQ = uiRes.pathToRequire(THIS_THEME_PATH, true) -- path.to.vacuum
local BASE_PATH = uiRes.pathStripEnd(THIS_THEME_PATH) -- path/to/vacuum/


--- Creates a new theme instance.
-- @param scale The desired scaling value for resources (fonts, etc.) May be clamped or rounded by the function.
-- @return The new theme instance.
function themeDef.newInstance(scale)
	local inst = uiTheme.newThemeInstance()

	-- General fonts
	inst.fonts = {}

	-- For internal widgets.
	inst.fonts.internal = love.graphics.newFont(math.floor(13 * scale))

	inst.fonts.h1 = love.graphics.newFont(math.floor(32 * scale))
	inst.fonts.h2 = love.graphics.newFont(math.floor(24 * scale))
	inst.fonts.h3 = love.graphics.newFont(math.floor(18 * scale))
	inst.fonts.h4 = love.graphics.newFont(math.floor(15 * scale))

	inst.fonts.p = love.graphics.newFont(math.floor(14 * scale))
	inst.fonts.small = love.graphics.newFont(math.floor(12 * scale))


	-- XXX: Test symbol substitution in single-line text boxes
	local test_font = love.graphics.newFont(BASE_PATH .. "fonts/noto_sans/NotoSans-Regular.ttf", math.floor(14 * scale))
	local test_font2 = love.graphics.newFont(BASE_PATH .. "fonts/noto_sans/NotoSansSymbols-Regular.ttf", math.floor(14 * scale))
	local test_font3 = love.graphics.newFont(BASE_PATH .. "fonts/noto_sans/NotoSansSymbols2-Regular.ttf", math.floor(14 * scale))
	test_font:setFallbacks(test_font2, test_font3)
	inst.fonts.p = test_font


	-- Textures, quads, slices
	inst.tex_defs = {}
	inst.tex_quads = {}
	inst.tex_slices = {}

	-- Setup atlas texture, plus its associated quads and slices.
	local atlas_data = uiRes.loadLuaFile(BASE_PATH .. "tex/96/atlas.lua")
	local atlas_tex = love.graphics.newImage(BASE_PATH .. "tex/96/atlas.png")

	local config = atlas_data.config
	atlas_tex:setFilter(config.filter_min, config.filter_mag)
	atlas_tex:setWrap(config.wrap_h, config.wrap_v)

	config.texture = atlas_tex

	inst.tex_defs["atlas"] = config

	for k, v in pairs(atlas_data.quads) do
		inst.tex_quads[k] = {
			x = v.x,
			y = v.y,
			w = v.w,
			h = v.h,
			texture = inst.tex_defs["atlas"].texture,
			quad = love.graphics.newQuad(v.x, v.y, v.w, v.h, inst.tex_defs["atlas"].texture),
			blend_mode = inst.tex_defs["atlas"].blend_mode,
			alpha_mode = inst.tex_defs["atlas"].alpha_mode,
		}
	end

	for k, v in pairs(atlas_data.slices) do
		local base_tq = inst.tex_quads[k]
		if not base_tq then
			error("missing base texture+quad pair for 9-Slice: " .. tostring(k))
		end

		local tex_slice = {
			x = v.x, y = v.y,
			w1 = v.w1, h1 = v.h1,
			w2 = v.w2, h2 = v.h2,
			w3 = v.w3, h3 = v.h3,

			tex_quad = base_tq,
			texture = base_tq.texture,
			blend_mode = inst.tex_defs["atlas"].blend_mode,
			alpha_mode = inst.tex_defs["atlas"].alpha_mode,
		}

		tex_slice.slice = quadSlice.newSlice(
			base_tq.x + v.x, base_tq.y + v.y,
			v.w1, v.h1,
			v.w2, v.h2,
			v.w3, v.h3,
			tex_slice.texture:getDimensions()
		)

		-- If specified, attach a starting draw function.
		if v.draw_fn_id then
			local draw_fn = quadSlice.draw_functions[v.draw_fn_id]
			if not draw_fn then
				error("in 'quadSlice.draw_functions', cannot find function with ID: " .. v.draw_fn_id)
			end

			tex_slice.slice.drawFromParams = draw_fn
		end

		-- If specified, set the initial state of each tile.
		-- 'tiles_state' is an array of bools. Only indexes 1-9 with true or
		-- false are considered. All other values are ignored (so they will default
		-- to being enabled).
		if v.tiles_state then
			for i = 1, 9 do
				if type(v.tiles_state[i]) == "boolean" then
					tex_slice.slice:setTileEnabled(i, false)
				end
			end
		end

		inst.tex_slices[k] = tex_slice
	end

	-- General style defaults
	inst.style_default = uiRes.loadLuaFile(BASE_PATH .. "data.lua")
	inst.style = pTable.deepCopy(inst.style_default)
	local inspect = require("lib.test.inspect") -- WIP
	print(inspect(inst.style))

	local _mt_box_style = uiTheme._mt_box_style
	for k2, v2 in pairs(inst.style.boxes) do
		setmetatable(v2, _mt_box_style)

		for k, v in pairs(v2) do
			if k == "outpad" or k == "border" or k == "margin" then
				v.x1 = math.max(0, math.floor(v.x1 * scale))
				v.x2 = math.max(0, math.floor(v.x2 * scale))
				v.y1 = math.max(0, math.floor(v.y1 * scale))
				v.y2 = math.max(0, math.floor(v.y2 * scale))
			end
		end
	end

	-- Icon classifications.
	inst.style.icons = {}

	-- Icons which may be placed next to text.
	inst.style.icons.p = {
		w = 16,
		h = 16,
		pad_x1 = 2,
		pad_x2 = 2,
		pad_y = 2
	}

	-- Widget text label styles.
	inst.style.labels = {}

	-- Standard text label.
	-- font: The LÖVE Font object to use when measuring and rendering label text.
	-- ul_color: An independent underline color (in the form of {R, G, B, A}), or false to use the text color.
	-- ul_h: Underline height or thickness.
	-- ul_oy: Vertical offset for the underline.
	-- Text color, text offsets (for inset buttons), etc. are provided by skin resource tables.
	inst.style.labels.norm = {}
	inst.style.labels.norm.font = inst.fonts.p
	inst.style.labels.norm.ul_color = false
	inst.style.labels.norm.ul_h = math.max(1, math.floor(0.5 + 1 * scale))
	inst.style.labels.norm.ul_oy = math.floor(0.5 + (inst.style.labels.norm.font:getHeight() - inst.style.labels.norm.ul_h))

	-- General WIMP settings
	inst.wimp = {}

	-- How far to allow resizing a widget outside the bounds of its parent.
	-- Used to prevent stretching frames too far outside the LÖVE application window.
	inst.wimp.frame_outbound_limit = math.max(1, math.floor(32 * scale))

	-- How many pixels to extend / pad resize sensors.
	inst.wimp.frame_resize_pad = math.max(1, math.floor(8 * scale))

	-- Theme -> Skin settings
	inst.wimp.frame_render_shadow = true
	inst.wimp.header_button_side = "right"
	inst.wimp.header_condensed = false
	inst.wimp.header_enable_close_button = true
	inst.wimp.header_enable_size_button = true
	inst.wimp.header_show_close_button = true
	inst.wimp.header_show_size_button = true
	inst.wimp.header_text = "Untitled Frame"
	inst.wimp.header_text_align_h = 0.5
	inst.wimp.header_text_align_v = 0.5


	-- Common / shared render state + functions.
	inst.common = {}

	-- Common details for drawing a rectangular thimble glow.
	-- If you mix the default thimble renderer with custom renderers, you can overwrite the contents of
	-- uiWidget.thimble_info with these fields to maintain consistency.
	inst.common.thimble_info = {}
	inst.common.thimble_info.mode = "line"
	inst.common.thimble_info.color = {0.2, 0.2, 1.0, 1.0}
	inst.common.thimble_info.line_style = "smooth"
	inst.common.thimble_info.line_width = math.max(1, math.floor(2 * scale))
	inst.common.thimble_info.line_join = "miter"
	inst.common.thimble_info.corner_rx = 1
	inst.common.thimble_info.corner_ry = 1

	-- Pushes the thimble outline out from the widget rectangle.
	-- This is overridden if the widget contains 'self.thimble_x(|y|w|h)'.
	inst.common.thimble_info.outline_pad = 0

	inst.common.thimble_info.segments = nil


	-- XXX WIP
	--[====[
	-- Scroll settings tables.
	-- Hints to use immediate scroll-to depending on the kind of input:
	-- * immediate_thumb: When dragging the thumb with the mouse.
	-- * immediate_key: With keypress events.
	-- * immediate_scr_button: When clicking the scroll bar buttons.
	-- * immediate_wheel: When turning the mouse wheel.
	inst.style.scroll_settings = {}

	inst.style.scroll_settings.default = {}

	inst.style.scroll_settings.default.immediate_thumb = true
	inst.style.scroll_settings.default.immediate_key = true
	inst.style.scroll_settings.default.immediate_scr_button = false
	inst.style.scroll_settings.default.immediate_wheel = false


	inst.style.scroll_settings.instant = {}

	inst.style.scroll_settings.instant.immediate_thumb = true
	inst.style.scroll_settings.instant.immediate_key = true
	inst.style.scroll_settings.instant.immediate_scr_button = true
	inst.style.scroll_settings.instant.immediate_wheel = true


	inst.style.scroll_settings.smooth = {}

	inst.style.scroll_settings.smooth.immediate_thumb = false
	inst.style.scroll_settings.smooth.immediate_key = false
	inst.style.scroll_settings.smooth.immediate_scr_button = false
	inst.style.scroll_settings.smooth.immediate_wheel = false
	--]====]

	-- Scroll bar styles (measurements and initial behavior).
	inst.style.scroll_bar_styles = {}

	inst.style.scroll_bar_styles.norm = {}

	inst.style.scroll_bar_styles.norm.has_buttons = true
	inst.style.scroll_bar_styles.norm.trough_enabled = true
	inst.style.scroll_bar_styles.norm.thumb_enabled = true

	inst.style.scroll_bar_styles.norm.bar_size = math.max(1, math.floor(16 * scale))
	inst.style.scroll_bar_styles.norm.button_size = math.max(1, math.floor(16 * scale))
	inst.style.scroll_bar_styles.norm.thumb_size_min = math.max(1, math.floor(16 * scale))
	inst.style.scroll_bar_styles.norm.thumb_size_max = math.max(1, math.floor(2^16 * scale))

	inst.style.scroll_bar_styles.norm.v_near_side = false
	inst.style.scroll_bar_styles.norm.v_auto_hide = false

	inst.style.scroll_bar_styles.norm.v_button1_enabled = true
	inst.style.scroll_bar_styles.norm.v_button1_mode = "pend-cont"
	inst.style.scroll_bar_styles.norm.v_button2_enabled = true
	inst.style.scroll_bar_styles.norm.v_button2_mode = "pend-cont"

	inst.style.scroll_bar_styles.norm.h_near_side = false
	inst.style.scroll_bar_styles.norm.h_auto_hide = false

	inst.style.scroll_bar_styles.norm.h_button1_enabled = true
	inst.style.scroll_bar_styles.norm.h_button1_mode = "pend-cont"
	inst.style.scroll_bar_styles.norm.h_button2_enabled = true
	inst.style.scroll_bar_styles.norm.h_button2_mode = "pend-cont"


	-- Use cases: dropdown drawers
	inst.style.scroll_bar_styles.norm_hide = {}

	inst.style.scroll_bar_styles.norm_hide.has_buttons = true
	inst.style.scroll_bar_styles.norm_hide.trough_enabled = true
	inst.style.scroll_bar_styles.norm_hide.thumb_enabled = true

	inst.style.scroll_bar_styles.norm_hide.bar_size = math.max(1, math.floor(16 * scale))
	inst.style.scroll_bar_styles.norm_hide.button_size = math.max(1, math.floor(16 * scale))
	inst.style.scroll_bar_styles.norm_hide.thumb_size_min = math.max(1, math.floor(16 * scale))
	inst.style.scroll_bar_styles.norm_hide.thumb_size_max = math.max(1, math.floor(2^16 * scale))

	inst.style.scroll_bar_styles.norm_hide.v_near_side = false
	inst.style.scroll_bar_styles.norm_hide.v_auto_hide = true

	inst.style.scroll_bar_styles.norm_hide.v_button1_enabled = true
	inst.style.scroll_bar_styles.norm_hide.v_button1_mode = "pend-cont"
	inst.style.scroll_bar_styles.norm_hide.v_button2_enabled = true
	inst.style.scroll_bar_styles.norm_hide.v_button2_mode = "pend-cont"

	inst.style.scroll_bar_styles.norm_hide.h_near_side = false
	inst.style.scroll_bar_styles.norm_hide.h_auto_hide = true

	inst.style.scroll_bar_styles.norm_hide.h_button1_enabled = true
	inst.style.scroll_bar_styles.norm_hide.h_button1_mode = "pend-cont"
	inst.style.scroll_bar_styles.norm_hide.h_button2_enabled = true
	inst.style.scroll_bar_styles.norm_hide.h_button2_mode = "pend-cont"


	inst.style.scroll_bar_styles.half = {}

	inst.style.scroll_bar_styles.half.has_buttons = true
	inst.style.scroll_bar_styles.half.trough_enabled = true
	inst.style.scroll_bar_styles.half.thumb_enabled = true

	inst.style.scroll_bar_styles.half.bar_size = math.max(1, math.floor(8 * scale))
	inst.style.scroll_bar_styles.half.button_size = math.max(1, math.floor(8 * scale))
	inst.style.scroll_bar_styles.half.thumb_size_min = math.max(1, math.floor(8 * scale))
	inst.style.scroll_bar_styles.half.thumb_size_max = math.max(1, math.floor(2^16 * scale))

	inst.style.scroll_bar_styles.half.v_near_side = false
	inst.style.scroll_bar_styles.half.v_auto_hide = false

	inst.style.scroll_bar_styles.half.v_button1_enabled = true
	inst.style.scroll_bar_styles.half.v_button1_mode = "pend-cont"
	inst.style.scroll_bar_styles.half.v_button2_enabled = true
	inst.style.scroll_bar_styles.half.v_button2_mode = "pend-cont"

	inst.style.scroll_bar_styles.half.h_near_side = false
	inst.style.scroll_bar_styles.half.h_auto_hide = false

	inst.style.scroll_bar_styles.half.h_button1_enabled = true
	inst.style.scroll_bar_styles.half.h_button1_mode = "pend-cont"
	inst.style.scroll_bar_styles.half.h_button2_enabled = true
	inst.style.scroll_bar_styles.half.h_button2_mode = "pend-cont"


	-- Common scroll bar graphical resources
	inst.common.scroll_bar1 = {}

	inst.common.scroll_bar1.tquad_pixel = inst.tex_quads["pixel"]
	inst.common.scroll_bar1.tq_arrow_down = inst.tex_quads["arrow2_down"]
	inst.common.scroll_bar1.tq_arrow_up = inst.tex_quads["arrow2_up"]
	inst.common.scroll_bar1.tq_arrow_left = inst.tex_quads["arrow2_left"]
	inst.common.scroll_bar1.tq_arrow_right = inst.tex_quads["arrow2_right"]

	-- This might be helpful if the buttons and trough do not fit snugly into the scroll bar's rectangular body.
	inst.common.scroll_bar1.render_body = false

	inst.common.scroll_bar1.body_color = {0.1, 0.1, 0.1, 1.0}
	inst.common.scroll_bar1.col_trough = {0.1, 0.1, 0.1, 1.0}

	-- In this implementation, the thumb and buttons share slices and colors for idle, hover and press states.
	inst.common.scroll_bar1.shared = {}

	inst.common.scroll_bar1.shared.idle = {}
	inst.common.scroll_bar1.shared.idle.slice = inst.tex_slices["scroll_button"]
	inst.common.scroll_bar1.shared.idle.col_body = {1.0, 1.0, 1.0, 1.0}
	inst.common.scroll_bar1.shared.idle.col_symbol = {0.65, 0.65, 0.65, 1.0}

	inst.common.scroll_bar1.shared.hover = {}
	inst.common.scroll_bar1.shared.hover.slice = inst.tex_slices["scroll_button_hover"]
	inst.common.scroll_bar1.shared.hover.col_body = {1.0, 1.0, 1.0, 1.0}
	inst.common.scroll_bar1.shared.hover.col_symbol = {0.75, 0.75, 0.75, 1.0}

	inst.common.scroll_bar1.shared.press = {}
	inst.common.scroll_bar1.shared.press.slice = inst.tex_slices["scroll_button_press"]
	inst.common.scroll_bar1.shared.press.col_body = {1.0, 1.0, 1.0, 1.0}
	inst.common.scroll_bar1.shared.press.col_symbol = {0.3, 0.3, 0.3, 1.0}

	inst.common.scroll_bar1.shared.disabled = {}
	inst.common.scroll_bar1.shared.disabled.slice = inst.tex_slices["scroll_button_disabled"]
	inst.common.scroll_bar1.shared.disabled.col_body = {0.5, 0.5, 0.5, 1.0}
	inst.common.scroll_bar1.shared.disabled.col_symbol = {0.1, 0.1, 0.1, 1.0}


	-- Common column implementations. (For tabular menus, etc.)
	inst.common.impl_column = {}

	inst.common.impl_column.bar_height = math.max(0, math.floor(32 * scale))

	inst.common.impl_column.color_body = {0.25, 0.25, 0.25, 1.0}
	inst.common.impl_column.color_col_sep = {0.4, 0.4, 0.4, 1.0} -- vertical separator between columns
	inst.common.impl_column.color_body_sep = {0.4, 0.4, 0.4, 1.0} -- a line between the header body and rest of widget

	inst.common.impl_column.col_sep_line_width = math.max(1, math.floor(1 * scale))

	inst.common.impl_column.font = inst.fonts.p
	inst.common.impl_column.bijou_arrow_up = inst.tex_quads["arrow2_up"]
	inst.common.impl_column.bijou_arrow_down = inst.tex_quads["arrow2_down"]

	inst.common.impl_column.bijou_w = math.floor(math.max(1, 12 * scale))
	inst.common.impl_column.bijou_h = math.floor(math.max(1, 12 * scale))

	-- Padding between:
	-- * Category panel left and label text
	-- * Category panel right and sorting badge
	inst.common.impl_column.category_h_pad = math.floor(math.max(0, 4 * scale))

	inst.common.impl_column.shared = {}

	inst.common.impl_column.shared.idle = {}

	inst.common.impl_column.shared.idle.sl_body = inst.tex_slices["tabular_category_body"]
	inst.common.impl_column.shared.idle.color_body = {1.0, 1.0, 1.0, 1.0}
	inst.common.impl_column.shared.idle.color_text = {0.8, 0.8, 0.8, 1.0}
	inst.common.impl_column.shared.idle.offset_x = 0
	inst.common.impl_column.shared.idle.offset_y = 0

	inst.common.impl_column.shared.hover = {}

	inst.common.impl_column.shared.hover.sl_body = inst.tex_slices["tabular_category_body_hover"]
	inst.common.impl_column.shared.hover.color_body = {1.0, 1.0, 1.0, 1.0}
	inst.common.impl_column.shared.hover.color_text = {0.9, 0.9, 0.9, 1.0}
	inst.common.impl_column.shared.hover.offset_x = 0
	inst.common.impl_column.shared.hover.offset_y = 0

	inst.common.impl_column.shared.press = {}

	inst.common.impl_column.shared.press.sl_body = inst.tex_slices["tabular_category_body_press"]
	inst.common.impl_column.shared.press.color_body = {1.0, 1.0, 1.0, 1.0}
	inst.common.impl_column.shared.press.color_text = {1.0, 1.0, 1.0, 1.0}
	inst.common.impl_column.shared.press.offset_x = 0
	inst.common.impl_column.shared.press.offset_y = math.max(1, math.floor(1 * scale))


	-- Key shortcut underline style.
	inst.shortcut_style = {}
	inst.shortcut_style.line_width = math.max(1, math.floor(1 * scale))

	-- * (TODO) Textual menu items
	-- * (TODO) Status bar along the bottom

	-- 'inst.skins' is created in uiTheme.newThemeInstance().

	-- To resolve an ordering problem, skins need to be pulled in and initialized
	-- after widgets and skinners.

	-- To load all SkinDefs in a folder:
	-- inst:loadSkinDefs(BASE_PATH .. "path/to/skins", true)

	-- To load SkinDefs individually:
	-- inst:loadSkinDef("button1", BASE_PATH .. "skins/my_skin.lua")

	return inst
end


return themeDef
