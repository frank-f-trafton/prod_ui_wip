local clipboardWrapper = {}


-- Option to maintain an internal clipboard that is totally separate from the OS clipboard.
-- Use if the OS clipboard doesn't cooperate, or if you otherwise want them separated.
clipboardWrapper.use_internal = false
clipboardWrapper.internal = ""


-- Clipboard wrapper
function clipboardWrapper.set(text)
	text = tostring(text)
	if clipboardWrapper.use_internal then
		clipboardWrapper.internal = text

	else
		love.system.setClipboardText(text)
	end
end


function clipboardWrapper.get()
	if clipboardWrapper.use_internal then
		local text = clipboardWrapper.internal

		if text == nil then
			text = ""
		else
			text = tostring(text)
		end

		return text

	else
		return love.system.getClipboardText()
	end
end


return clipboardWrapper
