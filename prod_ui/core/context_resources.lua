-- To load: local lib = context:getLua("shared/lib")


local contextResources = {}


local context = select(1, ...)


local fontCache = context:getLua("core/res/font_cache")
local pPath = require(context.conf.prod_ui_req .. "lib.pile_path")
local pTable = require(context.conf.prod_ui_req .. "lib.pile_table")
local quadSlice = require(context.conf.prod_ui_req .. "graphics.quad_slice")
local uiRes = require(context.conf.prod_ui_req .. "ui_res")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local utilTable = require(context.conf.prod_ui_req .. "common.util_table")


local _drill = utilTable.drill


local _lut_font_ext = pTable.makeLUTV(".ttf", ".otf", ".fnt", ".png")
local _lut_font_ext_vec = pTable.makeLUTV(".ttf", ".otf")


local _info = {} -- for love.filesystem.getInfo()


local methods = {}
function contextResources.attachMethods(mt)
	for k, v in pairs(methods) do
		if mt[k] then
			error("attempted to overwrite key: " .. tostring(k))
		end
		mt[k] = v
	end
end


function methods:resetResources()
	for k, v in pairs(self.resources) do
		if type(v) == "table" then
			pTable.clear(v)
		end
	end
end


function methods:interpolatePath(path)
	uiShared.type1(1, path, "string")

	return pPath.interpolate(path, self.path_symbols)
end


-- If 'ta' is a table, then deep-copy its key-value pairs to table 'tb'.
local function _deepCopyFields(ta, tb)
	if type(tb) ~= "table" then
		error("the destination does not exist, or it is not a table.")
	end
	if type(ta) == "table" then
		for k, v in pairs(ta) do
			tb[k] = pTable.deepCopy(v)
		end
	end
end


local function _initTexture(texture, metadata)
	local tex_info = {texture=texture}

	if metadata then
		if metadata.config then
			for k, v in pairs(metadata.config) do
				tex_info[k] = v
			end
		end
	end

	pTable.assignIfNil(tex_info, "alpha_mode", "alphamultiply")
	pTable.assignIfNil(tex_info, "blend_mode", "alpha")
	pTable.assignIfNil(tex_info, "filter_mag", "linear")
	pTable.assignIfNil(tex_info, "filter_min", "linear")
	pTable.assignIfNil(tex_info, "wrap_h", "clamp")
	pTable.assignIfNil(tex_info, "wrap_v", "clamp")

	texture:setFilter(tex_info.filter_min, tex_info.filter_mag)
	texture:setWrap(tex_info.wrap_h, tex_info.wrap_v)

	if metadata then
		if metadata.quads then
			tex_info.quads = {}
			for k, v in pairs(metadata.quads) do
				tex_info.quads[k] = {
					x = v.x,
					y = v.y,
					w = v.w,
					h = v.h,
					texture = tex_info.texture,
					quad = love.graphics.newQuad(v.x, v.y, v.w, v.h, tex_info.texture),
					blend_mode = tex_info.blend_mode,
					alpha_mode = tex_info.alpha_mode,
				}
			end
		end

		if metadata.slices then
			tex_info.slices = {}
			for k, v in pairs(metadata.slices) do
				local base_tq = tex_info.quads[k]
				if not base_tq then
					error("missing base texture+quad pair for 9-Slice: " .. tostring(k))
				end

				local tex_slice = {
					tex_quad = base_tq,
					texture = base_tq.texture,
					blend_mode = tex_info.blend_mode,
					alpha_mode = tex_info.alpha_mode,

					slice = quadSlice.newSlice(
						base_tq.x + v.x, base_tq.y + v.y,
						v.w1, v.h1,
						v.w2, v.h2,
						v.w3, v.h3,
						base_tq.texture:getDimensions()
					)
				}

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

				tex_info.slices[k] = tex_slice
			end
		end
	end

	return tex_info
end


--- Loads a PNG and an optional accompanying .lua file of metadata.
local function _loadTextureFiles(path)
	path = context:interpolatePath(path)

	local info = uiRes.assertGetInfo(path, "file", _info)

	local tex = love.graphics.newImage(path)
	local metadata
	local path_lua = path:sub(1, -5) .. ".lua"

	local info2 = love.filesystem.getInfo(path_lua, "file", _info)
	if info2 then
		local chunk, err = love.filesystem.load(path_lua)
		if not chunk then
			error(err)
		end
		metadata = chunk()
	end
	-- TODO: check config fields

	return tex, metadata
end


function methods:_initResourcesTable()
	if self.resources then
		error("'self.resources' is already populated. This method should only be called once.")
	end

	-- ie 'self.resources = self:_initResourcesTable()'
	return {
		boxes = {},
		fonts = {},
		info = {},
		labels = {},
		scroll_bar_data = {},
		scroll_bar_styles = {},

		textures = {},
		quads = {},
		slices = {},

		skins = {}
	}
end


local function _applyReferences(t, resources)
	for k, v in pairs(t) do
		if type(v) == "table" then
			_applyReferences(v, resources)

		elseif type(v) == "string" and v:sub(1, 1) == "*" then
			t[k] = _drill(resources, "/", v:sub(2))
		end
	end
end


function methods:applyTheme(theme)
	local resources = self.resources
	local scale = self.scale

	self:resetResources()
	fontCache.clear()
	uiTheme.setLabel()

	if not theme then
		return
	end

	if theme.boxes then
		uiTheme.pushLabel("boxes")

		_deepCopyFields(theme.boxes, resources.boxes)
		for k, box in pairs(resources.boxes) do
			uiTheme.check.box(resources.boxes, k)
			uiTheme.scaleBox(box, scale)
		end

		uiTheme.popLabel()
		uiTheme.assertLabelLevel(0)
	end

	if theme.fonts then
		uiTheme.pushLabel("fonts")

		for k in pairs(theme.fonts) do
			uiTheme.pushLabel(k)
			uiTheme.checkFontInfo(theme.fonts, k)
			uiTheme.scaleFontInfo(theme.fonts, k, scale)
			uiTheme.popLabel()
		end

		for k, font_info in pairs(theme.fonts) do
			fontCache.createFontObjects(font_info)
		end

		for k, font_info in pairs(theme.fonts) do
			fontCache.setFallbacks(font_info)
			resources.fonts[k] = fontCache.getFont(font_info)
		end

		uiTheme.popLabel()
		uiTheme.assertLabelLevel(0)
	end
	fontCache.clear()


	if theme.info then
		uiTheme.pushLabel("info")

		_deepCopyFields(theme.info, resources.info)

		-- TODO

		uiTheme.popLabel()
		uiTheme.assertLabelLevel(0)
	end


	if theme.labels then
		uiTheme.pushLabel("labels")

		_deepCopyFields(theme.labels, resources.labels)

		-- TODO

		uiTheme.popLabel()
		uiTheme.assertLabelLevel(0)
	end

	if theme.scroll_bar_data then
		uiTheme.pushLabel("scroll_bar_data")

		_deepCopyFields(theme.scroll_bar_data, resources.scroll_bar_data)

		-- TODO

		uiTheme.popLabel()
		uiTheme.assertLabelLevel(0)
	end

	if theme.scroll_bar_styles then
		uiTheme.pushLabel("scroll_bar_styles")

		_deepCopyFields(theme.scroll_bar_styles, resources.scroll_bar_styles)

		-- TODO

		uiTheme.popLabel()
		uiTheme.assertLabelLevel(0)
	end

	-- TODO: support loading a directory of images as one group (like an uncompiled atlas).

	if theme.textures then
		uiTheme.pushLabel("textures")

		for k, tex_info in pairs(theme.textures) do
			local tex, meta = _loadTextureFiles(tex_info.path)
			local tex_tbl = _initTexture(tex, meta)

			resources.textures[k] = tex_tbl

			if tex_tbl.quads then
				resources.quads[k] = tex_tbl.quads
			end

			if tex_tbl.slices then
				resources.slices[k] = tex_tbl.slices
			end
		end

		uiTheme.popLabel()
	end

	if theme.skins then
		for k, v in pairs(theme.skins) do
			resources.skins[k] = v
		end
	end

	_applyReferences(resources, resources)

	for k, v in pairs(resources.skins) do
		local skinner = context.skinners[v.skinner_id]
		if not skinner then
			error("no skinner with ID: " .. tostring(v.skinner_id))
		end

		uiTheme.setLabel("(" .. tostring(v.skinner_id) .. ", " .. tostring(k) .. ")")
		if skinner.validate then
			skinner.validate(v)
		end
		if skinner.transform then
			skinner.transform(v, scale)
		end
		uiTheme.popLabel()
		uiTheme.assertLabelLevel(0)
	end
	uiTheme.assertLabelLevel(0)
end


return contextResources
