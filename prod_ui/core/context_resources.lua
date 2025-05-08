-- To load: local lib = context:getLua("shared/lib")


local contextResources = {}


local context = select(1, ...)


local fontCache = context:getLua("core/res/font_cache")
local pPath = require(context.conf.prod_ui_req .. "lib.pile_path")
local pTable = require(context.conf.prod_ui_req .. "lib.pile_table")
local quadSlice = require(context.conf.prod_ui_req .. "graphics.quad_slice")
local uiRes = require(context.conf.prod_ui_req .. "ui_res")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local utilTable = require(context.conf.prod_ui_req .. "common.util_table")


local _drill = utilTable.drill


local _lut_font_ext = pTable.makeLUT({".ttf", ".otf", ".fnt", ".png"})
local _lut_font_ext_vec = pTable.makeLUT({".ttf", ".otf"})


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
		pTable.clear(v)
	end
end


function methods:interpolatePath(path)
	uiShared.type1(1, path, "string")

	return pPath.interpolate(path, self.path_symbols)
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
					x = v.x, y = v.y,
					w1 = v.w1, h1 = v.h1,
					w2 = v.w2, h2 = v.h2,
					w3 = v.w3, h3 = v.h3,

					tex_quad = base_tq,
					texture = base_tq.texture,
					blend_mode = tex_info.blend_mode,
					alpha_mode = tex_info.alpha_mode,
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


function methods:applyTheme(theme)
	local resources = self.resources
	local scale = self.scale

	self:resetResources()

	self.theme = theme

	fontCache.clear()
	if theme.fonts then
		for k, font_info in pairs(theme.fonts) do
			fontCache.createFontObjects(font_info)
		end

		for k, font_info in pairs(theme.fonts) do
			fontCache.setFallbacks(font_info)
			resources.fonts[k] = fontCache.getFont(font_info)
		end
	end
	fontCache.clear()

	-- TODO: support loading a directory of images as one group (like an uncompiled atlas).

	if theme.textures then
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
	end

	if theme.boxes then
		for k2, v2 in pairs(theme.boxes) do
			for k, v in pairs(v2) do
				if k == "outpad" or k == "border" or k == "margin" then
					v.x1 = math.max(0, math.floor(v.x1 * scale))
					v.x2 = math.max(0, math.floor(v.x2 * scale))
					v.y1 = math.max(0, math.floor(v.y1 * scale))
					v.y2 = math.max(0, math.floor(v.y2 * scale))
				end
			end
		end
	end

	-- TODO: Icon classifications

	-- TODO: Widget label styles

	-- TODO: I need to give these proper handling and care, but for now, I just
	-- want to get the library booting again.
	resources.boxes = pTable.deepCopy(theme.boxes)
	resources.icons = pTable.deepCopy(theme.icons)
	resources.labels = pTable.deepCopy(theme.labels)
	resources.scroll_bar_styles = pTable.deepCopy(theme.scroll_bar_styles)
	resources.scroll_bar_data = pTable.deepCopy(theme.scroll_bar_data)
	resources.wimp = pTable.deepCopy(theme.wimp)
	resources.thimble_info = pTable.deepCopy(theme.thimble_info)

	-- TODO: Replace/rewrite this.
	local function _recursiveDrill(t)
		for k, v in pairs(t) do
			if type(v) == "table" then
				_recursiveDrill(v)

			elseif type(v) == "string" and v:sub(1, 1) == "*" then
				t[k] = _drill(resources, "/", v:sub(2))
			end
		end
	end
	_recursiveDrill(resources)

	if theme.skins then
		for k, v in pairs(theme.skins) do
			self:registerSkinDef(v, k)
		end
	end
end


--- Registers a SkinDef table to the theming system and creates a SkinInstance.
-- @param skin_def The SkinDef table to assign.
-- @param id The SkinDef ID to use. It must be a string, a number or a table, and it cannot already be registerd.
--  If the value is a table, then it must be the SkinDef table (skin_def == id).
function methods:registerSkinDef(skin_def, id)
	uiShared.type1(1, skin_def, "table")
	uiShared.type(1, id, "string", "number", "table")

	if type(id) == "table" and skin_def ~= id then
		error("when using a table as the ID, it must be the same table as the SkinDef (skin_def == id).")
	end

	local skins = self.resources.skins
	if skins[id] then
		error("a SkinDef is already registered with this ID: " .. tostring(id))
	end

	local skin_inst = setmetatable({}, skin_def)
	skins[id] = skin_inst
	self:refreshSkinDefInstance(id)
end


local _dummy_schema = {}


local _ref_handlers = {
	["*"] = function(self, v)
		return false, _drill(self.resources, "/", v:sub(2))
	end,
	["#"] = function(self, v)
		return true, _drill(self.resources, "/", v:sub(2))
	end,
	-- "&" is handled earlier in the function.
}


local _schema_commands = {
	["scaled-int"] = function(self, v)
		return math.floor(v * self.scale)
	end,
	["unit-interval"] = function(self, v)
		return math.max(0, math.min(v, 1))
	end
}


-- @param schema_root The topmost schema table.
-- @param schema_table The current subtable (starting with 'main' at the first level).
local function _skinDeepCopy(self, inst, def, schema_root, schema_table, _depth)
	--print("_skinDeepCopy: start", _depth)

	--[[
	setmetatable(inst, inst)
	inst.__index = def
	--]]

	for k, v in pairs(def) do
		local symbol = type(v) == "string" and v:sub(1, 1)
		if symbol == "&" then
			local tbl = schema_table[v:sub(2)]
			if not tbl then
				error("schema table lookup failed. Address: " .. tostring(v))
			end
			inst[k] = _skinDeepCopy(self, {}, v, schema_root or _dummy_schema, tbl, _depth + 1)

		elseif type(v) == "table" then
			inst[k] = _skinDeepCopy(self, {}, v, schema_root or _dummy_schema, schema_table[k] or _dummy_schema, _depth + 1)

		else
			--print("***", "k", k, "v", v)
			-- Pull in resources from the main theme table
			local stop_processing
			local ref_handler = _ref_handlers[symbol]
			if ref_handler then
				--print(">>> do lookup")
				stop_processing, inst[k] = ref_handler(self, v)
				--print(">>> value is now: ", tostring(inst[k]), "stop_processing: " .. tostring(stop_processing))
			else
				--print(">>> direct copy")
				inst[k] = v
			end

			if schema_table[k] and not stop_processing then
				local command = schema_table[k]
				local func = _schema_commands[command]
				if func then
					--print("schema command", command, "inst[k]", inst[k])
					inst[k] = func(self, inst[k])
				else
					error("unhandled schema command: " .. tostring(command))
				end
			end
		end
	end
	--print("_skinDeepCopy: end", _depth)
	return inst
end


local function _getSkinTables(self, id)
	local skin_inst = self.resources.skins[id]
	if not skin_inst then
		error("no skin loaded with ID: " .. tostring(id))
	end
	local skin_def = getmetatable(skin_inst)
	if not skin_def then
		error("missing SkinDef for ID: " .. tostring(id))
	end

	return skin_def, skin_inst
end


function methods:refreshSkinDefInstance(id)
	local skin_def, skin_inst = _getSkinTables(self, id)

	local skinner = context.skinners[skin_def.skinner_id]
	if not skinner then
		error("missing skinner (the implementation). Skinner ID: " .. tostring(skin_def.skinner_id) .. ", requesting skin: " .. tostring(id))
	end
	local schema = skinner.schema or _dummy_schema
	local main = schema and schema.main or schema

	_skinDeepCopy(self, skin_inst, skin_def, schema, main, 1)
end


function methods:cloneSkinDef(skin_def_id)
	local skin_def = _getSkinTables(self, skin_def_id)
	local clone_def = pTable.deepCopy(skin_def)

	self:registerSkinDef(clone_def, clone_def)

	return clone_def
end


--- Remove a SkinDef from the theme registry.
-- @param id ID of the SkinDef to remove.
function methods:removeSkinDef(id) -- XXX Untested
	--[[
	The library user must *completely* uninstall the skin from all widgets.
	Any de-skinned widgets which require a skin must have replacements ASAP.
	--]]

	local skin = self.resources.skins[id]
	if not skin then
		error("Skin not found. ID: " .. tostring(id))
	end

	self.resources.skins[id] = nil
end


return contextResources
