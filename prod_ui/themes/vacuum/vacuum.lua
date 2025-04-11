-- ProdUI theme: Vacuum


local themeDef = {}


local THIS_THEME_PATH, context = select(1, ...) -- path/to/vacuum/vacuum.lua
local PROD_UI_REQ = context.conf.prod_ui_req


local uiRes = require(PROD_UI_REQ .. "ui_res")
local uiTheme = require(PROD_UI_REQ .. "ui_theme")
local quadSlice = require(PROD_UI_REQ .. "graphics.quad_slice")


local BASE_REQ = uiRes.pathToRequire(THIS_THEME_PATH, true) -- path.to.vacuum
local BASE_PATH = uiRes.pathStripEnd(THIS_THEME_PATH) -- path/to/vacuum/


function themeDef.newInstance()
	local scale = context.scale
	local dpi = context.dpi

	assert(type(scale) == "number", "invalid scale type.")
	assert(type(dpi) == "number", "invalid DPI type.")

	-- * Textures, Quads, Slices

	-- Setup atlas texture, plus its associated quads and slices.
	local atlas_data = uiRes.loadLuaFile(BASE_PATH .. "tex/" .. tostring(dpi) .. "/atlas.lua")
	local atlas_tex = love.graphics.newImage(BASE_PATH .. "tex/" .. tostring(dpi) .. "/atlas.png")

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

	return inst
end


return themeDef
