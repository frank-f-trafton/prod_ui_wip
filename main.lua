require("lib.test.strict")


--[[
Loads and executes files other than 'main.lua' under LÖVE 11.x.

Should work with LÖVE 12, though it is no longer necessary.

Run the default project (defined below):
$ love .

Run something else:
$ love . path/to/some_file.lua

Run a directory:
$ love . some/dir

(Inside that directory, make a file named 'autorun.txt' and write the
file name as the first line.)
--]]


function love.load(arguments)
	local launch_file = arguments[1] or "demo/wimp"

	if launch_file == "main.lua" then
		error("'main.lua' can't launch itself")
	end

	launch_file = launch_file:match("^(.-)/*$")

	-- Directory?
	if launch_file:sub(-4) ~= ".lua" then
		local auto_run_file, err = love.filesystem.read(launch_file .. "/autorun.txt")
		if not auto_run_file then
			error(err)
		end

		auto_run_file = auto_run_file:match("^([^\n]*)\n?")
		if not auto_run_file then
			error("couldn't parse the file name in 'autorun.txt'")
		end

		launch_file = launch_file .. "/" .. auto_run_file
	end

	local chunk, err = love.filesystem.load(launch_file)
	if not chunk then
		error(err)
	else
		chunk()
	end
end
