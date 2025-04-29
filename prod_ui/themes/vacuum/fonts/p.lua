--[[
return {
	path = "default",
	size = 14
}
--]]


-- [[
-- XXX: Test symbol substitution in single-line text boxes
return {
	path = "noto_sans/NotoSans-Regular.ttf",
	size = 14,
	fallbacks = {
		{
			path = "noto_sans/NotoSansSymbols-Regular.ttf",
			size = 14
		},
		{
			path = "noto_sans/NotoSansSymbols2-Regular.ttf",
			size = 14
		}
	}
}
--]]
