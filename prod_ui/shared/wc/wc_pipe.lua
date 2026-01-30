local context = select(1, ...)


local wcPipe = {}


local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiTable = require(context.conf.prod_ui_req .. "ui_table")


local pipe_styles = context.resources.pipe_styles


local methods = {}
wcPipe.methods = methods


function methods:pipeSetStyle(pipe_id)
	uiAssert.typeEval(1, pipe_id, "string")

	if not pipe_id then
		self.PIPE_id = false
	else
		local p_st = pipe_styles[pipe_id]
		if not p_st then
			error("unprovisioned PipeStyle: " .. pipe_id)
		end

		self.PIPE_id = pipe_id
	end

	self:reshape()

	return self
end


function methods:pipeGetStyle()
	return self.PIPE_id
end


function wcPipe.attachMethods(def)
	uiTable.patch(def, wcPipe.methods, false)
end


return wcPipe

