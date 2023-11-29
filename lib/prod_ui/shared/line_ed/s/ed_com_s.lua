-- To load: local lib = context:getLua("shared/lib")


-- LineEditor (single) common utility functions.


local context = select(1, ...)


local edComS = {}


--[=[
-- XXX: to be used with single-line versions of text boxes.
function edComS.getDisplayTextSingle(text, font, replace_missing, masked)

	local display_text = text
	if masked then
		display_text = textUtil.getMaskedString(display_text, "*")

	elseif replace_missing then
		display_text = textUtil.replaceMissingCodePointGlyphs(display_text, font, "□")
	end

	return display_text
end
--]=]


function edComS.huntWordBoundary(code_groups, line, byte_n, dir, hit_non_ws, first_group)

	--print("(Single) huntWordBoundary", "dir", dir, "hit_non_ws", hit_non_ws, "first_group", first_group)

	-- If 'hit_non_ws' is true, this function skips over initial whitespace.

	while true do
		--print("LOOP: huntWordBoundary")

		local byte_p, peeked = lineManip.offsetStep(line, dir, byte_n)
		local group = code_groups[peeked]

		--print("byte_p", byte_p, "peeked", peeked)
		--print("group", group)

		-- Beginning or end of document
		if peeked == nil then
			--print("break: peeked == nil")
			byte_n = (dir == 1) and #line + 1 or 1
			break

		-- We're past the initial whitespace and have encountered our first group mismatch.
		elseif hit_non_ws and group ~= first_group then
			--print("break: hit_non_ws and group ~= first_group")
			--print("hit_non_ws", hit_non_ws, "group", group, "first_group", first_group, "peeked: ", peeked)
			-- Correct right-dir offsets
			if dir == 1 then
				byte_n = byte_p
			end

			break

		elseif group ~= "whitespace" then
			hit_non_ws = true
			first_group = code_groups[peeked] -- nil means "content" group
		end

		byte_n = byte_p
	end

	--print("return byte_n", byte_n)

	return byte_n
end


return edComS
