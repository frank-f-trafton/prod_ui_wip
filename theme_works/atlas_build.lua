require("lib.strict")

--[[
(Make the base PNGs with svg2png first.)
clear && love12d atlas_build.lua --png-dir output/vacuum_dark/96/png --dest output/vacuum_dark/96 --bleed 1
[--debug_alpha]

NOTES:

* Premultiplying (--premult) cancels out perimeter alpha-bleeding (--bleed <n>).
--]]

local example_usage = [[love . --png-dir <input_path> --dest <output_path>]]

local love_major, love_minor = love.getVersion()
if love_major < 12 then
	error("LÖVE 12 is required.")
end


local shared = require("shared")


-- Libraries
local atlasB = require("lib.atlas_b.atlas_b")
local idops = require("lib.idops.idops")
local nativefs = require("lib.nativefs")
local t2s2 = require("lib.t2s2.t2s2")


local arg_png_path
local arg_dest_path
local arg_premult = "off"
local arg_bleed = 0
local arg_debug_alpha = false


local bleed_level = 0


local file_info


local task_i = 1


local function checkArgImagePath()
	if not arg_png_path then
		error("missing argument: source (PNG) path")
	end
end


local function checkArgAtlasDest()
	if not arg_dest_path then
		error("missing argument: atlast destination path")
	end
end


local function checkArgBleed()
	local n = tonumber(arg_bleed)
	if not n then
		error("optional argument `bleed`: invalid setting: " .. tostring(arg_bleed))

	elseif n < 0 or math.floor(n) ~= n then
		error("optional argument `bleed`: must be an integer >= 0. Got: " .. n)
	end

	bleed_level = n
end


local tbl_premult = {
	["off"] = true,
	["linear"] = true, -- (applies gamma correction)
	["srgb"] = true,
}


local function checkArgPremult()
	if not tbl_premult[arg_premult] then
		error("optional argument `premult`: invalid setting: " .. tostring(arg_premult))
	end
end


local function checkDestExists()
	local info = shared.nfsGetInfo(arg_dest_path)

	if not info or info.type ~= "directory" then
		error("destination doesn't exist or isn't a directory: " .. tostring(arg_dest_path))
	end
end


function love.load(arguments)
	if #arguments < 1 then
		error("usage: " .. example_usage)
	end

	local i = 1
	while i <= #arguments do
		local argument = arguments[i]

		if argument == "--png-dir" then
			i = i + 1
			arg_png_path = arguments[i]
			checkArgImagePath()
			i = i + 1

		elseif argument == "--dest" then
			i = i + 1
			arg_dest_path = arguments[i]
			checkArgAtlasDest()
			i = i + 1

		elseif argument == "--premult" then
			i = i + 1
			arg_premult = arguments[i]
			checkArgPremult()
			i = i + 1

		elseif argument == "--bleed" then
			i = i + 1
			arg_bleed = arguments[i]
			checkArgBleed()
			i = i + 1

		elseif argument == "--debug_alpha" then
			i = i + 1
			arg_debug_alpha = true

		else
			error("unknown argument: " .. tostring(argument))
		end
	end
end


local tasks_build = {
	-- 1
	function()
		checkArgImagePath()
		checkArgAtlasDest()
		checkArgPremult()
		checkArgBleed()


		-- Strip trailing slashes from paths
		arg_png_path = shared.stripTrailingSlash(arg_png_path)
		arg_dest_path = shared.stripTrailingSlash(arg_dest_path)

		checkDestExists()

		task_i = task_i + 1
		return true
	end,

	-- 2
	function()
		-- Produce an atlas texture
		local i_data_set = {}
		local image_ids = {}

		-- Use file paths+names as tie-breakers during the atlas layout procedure.
		file_info = nativefs.getDirectoryItemsInfo(arg_png_path)

		for i, file_t in ipairs(file_info) do
			if file_t.type == "file" then
				local file_no_ext = string.sub(file_t.name, 1, -5)
				local ext = string.sub(file_t.name, -4)
				if string.lower(ext) == ".png" then
					local i_data = love.image.newImageData(arg_png_path .. "/" .. file_t.name)
					i_data_set[#i_data_set + 1] = i_data
					image_ids[i_data] = file_no_ext

					if bleed_level > 0 then
						idops.bleedRGBToZeroAlpha(i_data, bleed_level)
					end
				end
			end
		end

		local atl = atlasB.newAtlas(2, true, false)
		for i, i_data in ipairs(i_data_set) do
			atl:addBox(0, 0, i_data:getWidth(), i_data:getHeight(), i_data, image_ids[i_data])
		end

		local size = atl:arrange(1, 4096)
		if not size then
			error("atlas arrange pass failed.")
		end
		print("atlas size: " .. size)

		local i_data = atl:renderImageData()

		if arg_debug_alpha then
			idops.forceAlpha(i_data, 1.0)
		end

		if arg_premult ~= "off" then
			idops.premultiply(i_data, (arg_premult == "linear"))
		end

		local img_png = i_data:encode("png")
		shared.nfsWrite(arg_dest_path .. "/atlas.png", img_png)

		local out_data = {}
		local base_data = shared.nfsLoadLuaFile(arg_dest_path .. "/base_data.lua")
		local slice_coords = base_data.slice_coords

		local out_base_data = {
			["!info"] = base_data["!info"],
			config = base_data.config,
			quads = {},
			slices = {},
		}
		-- (base_data.no_scale is dropped here.)

		-- Produce quad tables.
		print("#boxes: " .. #atl.boxes)
		for i, box in ipairs(atl.boxes) do
			out_base_data.quads[box.id] = {x = box.x, y = box.y, w = box.iw, h = box.ih}
		end

		-- Copy the slice tables made by svg2png.
		for k, v in pairs(slice_coords) do
			local quad = out_base_data.quads[k]
			if not quad then
				print("Warning: atlas_build: missing base quad for quadslice: " .. tostring(k))
			end
			out_base_data.slices[k] = v
		end

		local atlas_box_str = t2s2.serialize(out_base_data)
		shared.nfsWrite(arg_dest_path .. "/atlas.lua", atlas_box_str)

		task_i = task_i + 1
		return true
	end,
}


function love.update(dt)
	if love.keyboard.isDown("escape") then
		print("*** Cancelled ***")
		love.event.quit(1)

	elseif not tasks_build[task_i] then
		print("* Finished all tasks.")
		print("task_i", task_i)
		love.event.quit()
		return

	else
		print("* Task #" .. task_i)
		if not tasks_build[task_i]() then
			print("* Aborted on task #" .. task_i)
			love.event.quit()
			return
		end
	end
end
