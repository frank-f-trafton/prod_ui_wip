require("lib.strict")

--[[
clear && love12d svg2png.lua --source vacuum_dark --tex-scale 1

* Requires the utility 'rsvg-convert', which is part of GNOME librsvg:
  https://gitlab.gnome.org/GNOME/librsvg

  Debian:
  $ sudo apt install librsvg2-bin
--]]

local example_usage = [[love svg2png.lua --source <input_path> --tex-scale <number>]]


local love_major, love_minor = love.getVersion()
if love_major < 12 then
	error("LÖVE 12 is required.")
end


local shared = require("shared")


-- Libraries
local nativefs = require("lib.nativefs")
local t2s2 = require("lib.t2s2.t2s2")


local arg_src_path -- theme name
local arg_scale


local svg_info
local svg_i = 1

local base_data

local out_path


local task_i = 1


local function checkArgSourcePath()
	if not arg_src_path then
		error("missing argument: source path")
	end
end


local function checkArgScale()
	if not arg_scale then
		error("missing argument: tex-scale")
	end
end


local function getQuadScaling(id)
	local scale_x, scale_y = arg_scale, arg_scale
	if base_data.quads then
		local quad = base_data.quads[id]
		if quad then
			if quad.no_scale or quad.no_scale_x then
				scale_x = 1
			end
			if quad.no_scale or quad.no_scale_y then
				scale_y = 1
			end
		end
	end

	return scale_x, scale_y
end


function love.load(arguments)
	if #arguments < 1 then
		error("usage: " .. example_usage)
	end

	local i = 1
	while i <= #arguments do
		local argument = arguments[i]

		if argument == "--source" then
			i = i + 1
			arg_src_path = arguments[i]
			checkArgSourcePath()
			i = i + 1

		elseif argument == "--tex-scale" then
			i = i + 1
			arg_scale = tonumber(arguments[i])
			checkArgScale()
			i = i + 1

		else
			error("unknown argument: " .. tostring(argument))
		end
	end
end


local function scaleCoord(value, tex_scale)
	return math.floor(0.5 + value * tex_scale)
end


local function tryScaleCoord(value, tex_scale)
	if value ~= nil then
		return scaleCoord(value, tex_scale)
	else
		return value
	end
end


local function assertAllOrNone(err_label, ...)
	local has_nil, has_any

	for i = 1, select("#", ...) do
		if select(i, ...) == nil then
			has_nil = true
		else
			has_any = true
		end
	end

	if has_nil and has_any then
		error("mixed nil and content in all-or-nothing parameters: " .. err_label or "(unknown)")
	end
end


local tasks_export = {
	-- 1
	function()
		checkArgSourcePath()
		checkArgScale()

		task_i = task_i + 1
		return true
	end,

	-- 2
	function()
		out_path = "output/" .. arg_src_path .. "/" .. arg_scale
		nativefs.createDirectory(out_path)
		shared.recursiveDelete(out_path)
		nativefs.createDirectory(out_path .. "/png")

		-- Grab and scale coordinates and measurements related to textures.
		if nativefs.getInfo(arg_src_path .. "/base_data.lua") then
			base_data = shared.nfsLoadLuaFile(arg_src_path .. "/base_data.lua")

			base_data.quads = base_data.quads or {}

			print("Scaling quad info -> base_data.lua -> tbl.quads")
			for k, v in pairs(base_data.quads) do
				local x_scale, y_scale = getQuadScaling(k)

				v.ox = tryScaleCoord(v.ox, x_scale) or 0
				v.oy = tryScaleCoord(v.oy, y_scale) or 0
			end

			print("Scaling quadslice coords -> base_data.lua -> tbl.slice_coords")
			for k, v in pairs(base_data.slice_coords) do
				local x_scale, y_scale = getQuadScaling(k)

				v.x = scaleCoord(v.x, x_scale)
				v.y = scaleCoord(v.y, y_scale)
				v.w1 = scaleCoord(v.w1, x_scale)
				v.h1 = scaleCoord(v.h1, y_scale)
				v.w2 = scaleCoord(v.w2, x_scale)
				v.h2 = scaleCoord(v.h2, y_scale)
				v.w3 = scaleCoord(v.w3, x_scale)
				v.h3 = scaleCoord(v.h3, y_scale)

				v.ox1 = tryScaleCoord(v.ox1, x_scale)
				v.oy1 = tryScaleCoord(v.oy1, y_scale)
				v.ox2 = tryScaleCoord(v.ox2, x_scale)
				v.oy2 = tryScaleCoord(v.oy2, y_scale)
			end
			local out_str = t2s2.serialize(base_data)
			shared.nfsWrite("output/" .. arg_src_path .. "/" .. arg_scale .. "/base_data.lua", out_str .. "\n")
		end

		svg_info = nativefs.getDirectoryItemsInfo(arg_src_path .. "/svg")
		task_i = task_i + 1
		return true
	end,

	-- 3
	function()
		if svg_i <= #svg_info then
			local item = svg_info[svg_i]
			if item.type == "file" then
				local file_no_ext = string.sub(item.name, 1, -5)
				local ext = string.sub(item.name, -4)
				if string.lower(ext) == ".svg" then
					local x_scale, y_scale = getQuadScaling(file_no_ext)
					local out_file_path = out_path .. "/png/" .. file_no_ext .. ".png"
					print("export: " .. out_file_path)
					print("OUT_PATH", out_path)
					local ok = os.execute(
						"rsvg-convert --format=png"
						.. " --x-zoom=" .. x_scale .. " --y-zoom=" .. y_scale
						.. " --output=" .. out_file_path
						.. " " .. arg_src_path .. "/svg/" .. item.name
					)
				end
			end
			svg_i = svg_i + 1
		else
			task_i = task_i + 1
		end

		return true
	end,
}


function love.update(dt)
	if false then
	--if love.keyboard.isDown("escape") then
		print("*** Cancelled ***")
		love.event.quit(1)

	elseif not tasks_export[task_i] then
		print("* Finished all tasks.")
		print("task_i", task_i)
		love.event.quit()
		return

	else
		print("* Task #" .. task_i)
		if not tasks_export[task_i]() then
			print("* Aborted on task #" .. task_i)
			love.event.quit()
			return
		end
	end
end
