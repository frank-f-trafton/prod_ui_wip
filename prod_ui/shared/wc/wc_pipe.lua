local context = select(1, ...)


local wcPipe = {}


local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiTable = require(context.conf.prod_ui_req .. "ui_table")


local pipe_styles = context.resources.pipe_styles


local methods = {}
wcPipe.methods = methods


function wcPipe.setupInstance(self)
	self.S_PIPE_id = false
	self.PIPE_id = "norm"
	self.PIPE_style = false
end


function wcPipe.refreshReferences(self)
	local pipe_id = self.PIPE_id
	local p_st = pipe_styles[pipe_id]

	if not p_st then
		error("unprovisioned PipeStyle: " .. tostring(pipe_id))
	end
	self.PIPE_style = p_st
end


-- expects 'self.skin.PIPE_default_id'
function methods:pipeSetStyle(pipe_id)
	uiAssert.typeEval(1, pipe_id, "string")

	local old_pipe_id = self.PIPE_id

	self.S_PIPE_id = pipe_id or false
	self.PIPE_id = self.S_PIPE_id or self.skin.PIPE_default_id
	assert(self.PIPE_id, "invalid or missing 'skin.PIPE_default_id'")

	wcPipe.refreshReferences(self)

	if old_pipe_id ~= self.PIPE_id then
		self:reshape()
	end

	return self
end


function methods:pipeGetStyle()
	return self.S_PIPE_id
end


function wcPipe.attachMethods(def)
	uiTable.patch(def, wcPipe.methods, false)
end


return wcPipe

