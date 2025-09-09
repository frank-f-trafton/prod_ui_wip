local coreErr = {}


--- The context is locked.
function coreErr.errLockedContext(action)
	error("cannot " .. action .. " while context is locked for updating.", 2)
end


--- A widget's parent is locked.
function coreErr.errLockedParent(action)
	error("cannot " .. action .. " while widget's parent is locked for updating.", 2)
end


--- A widget is locked.
function coreErr.errLocked(action)
	error("cannot " .. action .. " while widget is locked for updating.", 2)
end


return coreErr
