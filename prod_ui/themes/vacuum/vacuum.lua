-- ProdUI theme: Vacuum


local themeDef = {}


local THIS_THEME_PATH, context = select(1, ...)
local PROD_UI_PATH = context.conf.prod_ui_req


local uiGraphics = require(PROD_UI_PATH .. "ui_graphics")
local uiRes = require(PROD_UI_PATH .. "ui_res")
local uiTheme = require(PROD_UI_PATH .. "ui_theme")
local quadSlice = require(PROD_UI_PATH .. "graphics.quad_slice")


local REQ_PATH = uiRes.pathToRequire(THIS_THEME_PATH, true)
local BASE_PATH = uiRes.pathStripFile(THIS_THEME_PATH)


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
	inst.style = {}

	-- Widget box styles.

	inst.style.boxes = uiTheme.newThemeDataPack()

	local box
	inst.style.boxes.panel = uiTheme.newBoxStyle()

	inst.style.boxes.panel.sl_body_id = "tex_slices/list_box_body"

	inst.style.boxes.panel.outpad_x1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.panel.outpad_x2 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.panel.outpad_y1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.panel.outpad_y2 = math.max(0, math.floor(2 * scale))

	inst.style.boxes.panel.border_x1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.panel.border_x2 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.panel.border_y1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.panel.border_y2 = math.max(0, math.floor(2 * scale))

	inst.style.boxes.panel.margin_x1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.panel.margin_x2 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.panel.margin_y1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.panel.margin_y2 = math.max(0, math.floor(2 * scale))


	inst.style.boxes.frame_norm = uiTheme.newBoxStyle()

	inst.style.boxes.frame_norm.sl_body_id = "tex_slices/list_box_body"

	inst.style.boxes.frame_norm.outpad_x1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.frame_norm.outpad_x2 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.frame_norm.outpad_y1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.frame_norm.outpad_y2 = math.max(0, math.floor(2 * scale))

	inst.style.boxes.frame_norm.border_x1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.frame_norm.border_x2 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.frame_norm.border_y1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.frame_norm.border_y2 = math.max(0, math.floor(2 * scale))

	inst.style.boxes.frame_norm.margin_x1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.frame_norm.margin_x2 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.frame_norm.margin_y1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.frame_norm.margin_y2 = math.max(0, math.floor(2 * scale))


	inst.style.boxes.wimp_group = uiTheme.newBoxStyle()

	-- XXX: WIP.
	inst.style.boxes.frame_norm.outpad_x1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.frame_norm.outpad_x2 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.frame_norm.outpad_y1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.frame_norm.outpad_y2 = math.max(0, math.floor(2 * scale))

	inst.style.boxes.frame_norm.border_x1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.frame_norm.border_x2 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.frame_norm.border_y1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.frame_norm.border_y2 = math.max(0, math.floor(2 * scale))

	inst.style.boxes.frame_norm.margin_x1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.frame_norm.margin_x2 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.frame_norm.margin_y1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.frame_norm.margin_y2 = math.max(0, math.floor(2 * scale))


	inst.style.boxes.button = uiTheme.newBoxStyle()

	-- inst.style.boxes.button: No sl_body_id.

	inst.style.boxes.button.outpad_x1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.button.outpad_x2 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.button.outpad_y1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.button.outpad_y2 = math.max(0, math.floor(2 * scale))

	inst.style.boxes.button.border_x1 = math.max(0, math.floor(4 * scale))
	inst.style.boxes.button.border_x2 = math.max(0, math.floor(4 * scale))
	inst.style.boxes.button.border_y1 = math.max(0, math.floor(4 * scale))
	inst.style.boxes.button.border_y2 = math.max(0, math.floor(4 * scale))

	-- Margin is applied to Viewport #2 (graphic).
	inst.style.boxes.button.margin_x1 = math.max(0, math.floor(4 * scale))
	inst.style.boxes.button.margin_x2 = math.max(0, math.floor(4 * scale))
	inst.style.boxes.button.margin_y1 = math.max(0, math.floor(4 * scale))
	inst.style.boxes.button.margin_y2 = math.max(0, math.floor(4 * scale))


	inst.style.boxes.button_small = uiTheme.newBoxStyle()

	-- inst.style.boxes.button_small: No sl_body_id.

	inst.style.boxes.button_small.outpad_x1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.button_small.outpad_x2 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.button_small.outpad_y1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.button_small.outpad_y2 = math.max(0, math.floor(2 * scale))

	inst.style.boxes.button_small.border_x1 = math.max(0, math.floor(1 * scale))
	inst.style.boxes.button_small.border_x2 = math.max(0, math.floor(1 * scale))
	inst.style.boxes.button_small.border_y1 = math.max(0, math.floor(1 * scale))
	inst.style.boxes.button_small.border_y2 = math.max(0, math.floor(1 * scale))

	-- Margin is applied to Viewport #2 (graphic).
	inst.style.boxes.button_small.margin_x1 = math.max(0, math.floor(1 * scale))
	inst.style.boxes.button_small.margin_x2 = math.max(0, math.floor(1 * scale))
	inst.style.boxes.button_small.margin_y1 = math.max(0, math.floor(1 * scale))
	inst.style.boxes.button_small.margin_y2 = math.max(0, math.floor(1 * scale))


	-- Used with checkboxes and radio buttons.
	inst.style.boxes.button_bijou = uiTheme.newBoxStyle()

	-- inst.style.boxes.button: No sl_body_id.

	inst.style.boxes.button_bijou.outpad_x1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.button_bijou.outpad_x2 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.button_bijou.outpad_y1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.button_bijou.outpad_y2 = math.max(0, math.floor(2 * scale))

	inst.style.boxes.button_bijou.border_x1 = math.max(0, math.floor(4 * scale))
	inst.style.boxes.button_bijou.border_x2 = math.max(0, math.floor(4 * scale))
	inst.style.boxes.button_bijou.border_y1 = math.max(0, math.floor(4 * scale))
	inst.style.boxes.button_bijou.border_y2 = math.max(0, math.floor(4 * scale))

	-- Margin is applied to Viewport #2 (the bijou's drawing area).
	inst.style.boxes.button_bijou.margin_x1 = math.max(0, math.floor(0 * scale))
	inst.style.boxes.button_bijou.margin_x2 = math.max(0, math.floor(0 * scale))
	inst.style.boxes.button_bijou.margin_y1 = math.max(0, math.floor(0 * scale))
	inst.style.boxes.button_bijou.margin_y2 = math.max(0, math.floor(0 * scale))


	-- Input box edges.
	inst.style.boxes.input_box = uiTheme.newBoxStyle()

	-- inst.style.boxes.button: No sl_body_id.

	inst.style.boxes.input_box.outpad_x1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.input_box.outpad_x2 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.input_box.outpad_y1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.input_box.outpad_y2 = math.max(0, math.floor(2 * scale))

	inst.style.boxes.input_box.border_x1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.input_box.border_x2 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.input_box.border_y1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.input_box.border_y2 = math.max(0, math.floor(2 * scale))

	inst.style.boxes.input_box.margin_x1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.input_box.margin_x2 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.input_box.margin_y1 = math.max(0, math.floor(2 * scale))
	inst.style.boxes.input_box.margin_y2 = math.max(0, math.floor(2 * scale))


	-- Icon classifications.
	inst.style.icons = {}

	-- Icons which may be placed next to text.
	inst.style.icons.p = {}
	inst.style.icons.p.w = 16
	inst.style.icons.p.h = 16
	inst.style.icons.p.pad_x1 = 2
	inst.style.icons.p.pad_x2 = 2
	inst.style.icons.p.pad_y = 2


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

	-- How many pixels to extend / pad resize sensors.
	inst.wimp.frame_resize_pad = math.max(1, math.floor(8 * scale))

	-- How tall frame header bars should be.
	inst.wimp.frame_header_height_norm = math.max(1, math.floor(32 * scale))
	inst.wimp.frame_header_height_condensed = math.max(1, math.floor(18 * scale))

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

	-- inst.skins is created in uiTheme.newThemeInstance().

	local loadSkinDef = uiTheme.loadSkinDef

	inst:loadSkinDef("button1", BASE_PATH .. "skins/button1.lua")
	inst:loadSkinDef("button_split1", BASE_PATH .. "skins/button_split1.lua")
	inst:loadSkinDef("button_tq1", BASE_PATH .. "skins/button_tq1.lua")

	inst:loadSkinDef("checkbox1", BASE_PATH .. "skins/checkbox1.lua")
	inst:loadSkinDef("checkbox_multi1", BASE_PATH .. "skins/checkbox_multi1.lua")
	inst:loadSkinDef("combo_box1", BASE_PATH .. "skins/combo_box1.lua")
	inst:loadSkinDef("container1", BASE_PATH .. "skins/container1.lua")

	inst:loadSkinDef("dropdown_box1", BASE_PATH .. "skins/dropdown_box1.lua")
	inst:loadSkinDef("dropdown_pop1", BASE_PATH .. "skins/dropdown_pop1.lua")

	inst:loadSkinDef("icon_box1", BASE_PATH .. "skins/icon_box1.lua")

	inst:loadSkinDef("label1", BASE_PATH .. "skins/label1.lua")
	inst:loadSkinDef("list_box1", BASE_PATH .. "skins/list_box1.lua")

	inst:loadSkinDef("menu1", BASE_PATH .. "skins/menu1.lua")
	inst:loadSkinDef("menu_simple1", BASE_PATH .. "skins/menu_simple1.lua")
	inst:loadSkinDef("menu_tab1", BASE_PATH .. "skins/menu_tab1.lua")
	inst:loadSkinDef("menu_pop1", BASE_PATH .. "skins/menu_pop1.lua")
	inst:loadSkinDef("menu_bar1", BASE_PATH .. "skins/menu_bar1.lua")

	inst:loadSkinDef("number_box1", BASE_PATH .. "skins/number_box1.lua")

	inst:loadSkinDef("progress_bar1", BASE_PATH .. "skins/progress_bar1.lua")
	inst:loadSkinDef("properties_box1", BASE_PATH .. "skins/properties_box1.lua")

	inst:loadSkinDef("radio1", BASE_PATH .. "skins/radio1.lua")

	inst:loadSkinDef("sash1", BASE_PATH .. "skins/sash1.lua")
	inst:loadSkinDef("slider1", BASE_PATH .. "skins/slider1.lua")
	inst:loadSkinDef("stepper1", BASE_PATH .. "skins/stepper1.lua")

	inst:loadSkinDef("text_box_m1", BASE_PATH .. "skins/text_box_m1.lua")
	inst:loadSkinDef("text_box_s1", BASE_PATH .. "skins/text_box_s1.lua")
	inst:loadSkinDef("tree_box1", BASE_PATH .. "skins/tree_box1.lua")

	inst:loadSkinDef("wimp_frame", BASE_PATH .. "skins/wimp_frame.lua")
	inst:loadSkinDef("wimp_frame_header", BASE_PATH .. "skins/wimp_frame_header.lua")
	inst:loadSkinDef("wimp_frame_button", BASE_PATH .. "skins/wimp_frame_button.lua")

	return inst
end


return themeDef
