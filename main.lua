require("lib.test.strict")

function love.load(arguments)
	local demo_id = arguments[1] or "demo_wimp"

	require(demo_id)
end

