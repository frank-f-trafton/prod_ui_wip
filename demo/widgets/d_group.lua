
-- ProdUI
local demoShared = require("demo_shared")


local plan = {}


-- TODO: stack layout needs padding options...
local WID_PAD_Y = 8


function plan.make(panel)
	demoShared.makeTitle(panel, nil, "Groups of Controls")
	demoShared.makeParagraph(panel, nil, "\n***Under Construction***\n")

	local context = panel.context

	panel:layoutSetBase("viewport-width")
	panel:containerSetScrollRangeMode("auto")
	panel:setScrollBars(false, true)

	local group = panel:addChild("base/group")
		:setTag("demo_group")
		:geometrySetMode("relative", 0, 0, 256, 256)
		:layoutSetMargin(4, 4, 4, 4)
		:layoutSetStackFlow("y", 1)
		:layoutSetStackDefaultWidgetSize("pixel", 40)
		:setText("Group")


	do
		local function cb_selectStyle(self, item_i, item)
			local group = self:nodeFindKeyAscending(true, "tag", "demo_group")
			if group then
				group:pipeSetStyle(item.usr_pipe_id)
			end
		end

		local lb = group:addChild("wimp/dropdown_box")
			:geometrySetMode("stack", "pixel", 32 + WID_PAD_Y)
			:geometrySetPadding(0, 0, 0, WID_PAD_Y)
			:userCallbackSet("cb_chosenSelection", cb_selectStyle)

		local i1 = lb:addItem("PipeStyle: None")
		i1.usr_pipe_id = false

		local i2 = lb:addItem("PipeStyle: Norm")
		i2.usr_pipe_id = "norm"

		local i3 = lb:addItem("PipeStyle: Double")
		i3.usr_pipe_id = "double"

		local i4 = lb:addItem("PipeStyle: Thick")
		i4.usr_pipe_id = "thick"

		lb:setSelection(i2)
	end


	do
		local function cb_selectDeco(self, item_i, item)
			local group = self:nodeFindKeyAscending(true, "tag", "demo_group")
			if group then
				if item.usr_deco_id then
					group:setDecorationStyle(item.usr_deco_id)
				end
			end
		end

		local lb = group:addChild("wimp/dropdown_box")
			:geometrySetMode("stack", "pixel", 32 + WID_PAD_Y)
			:geometrySetPadding(0, 0, 0, WID_PAD_Y)
			:userCallbackSet("cb_chosenSelection", cb_selectDeco)

		local i1 = lb:addItem("Decoration: None")
		i1.usr_deco_id = "none"

		local i2 = lb:addItem("Decoration: Outline")
		i2.usr_deco_id = "outline"

		local i3 = lb:addItem("Decoration: Outline + Label")
		i3.usr_deco_id = "outline-label"

		local i4 = lb:addItem("Decoration: Header")
		i4.usr_deco_id = "header"

		local i5 = lb:addItem("Decoration: Header + Label")
		i5.usr_deco_id = "header-label"

		local i6 = lb:addItem("Decoration: Underlined Label")
		i6.usr_deco_id = "underline-label"

		local i7 = lb:addItem("Decoration: Underlined Lbl 2")
		i7.usr_deco_id = "underline-label-wide"

		local i8 = lb:addItem("Decoration: Label")
		i8.usr_deco_id = "label"

		lb:setSelection(i3)
	end


	do
		local function cb_selectLabelSide(self, item_i, item)
			local group = self:nodeFindKeyAscending(true, "tag", "demo_group")
			if group then
				if item.usr_side_id then
					group:setLabelSide(item.usr_side_id)
				end
			end
		end

		local lb = group:addChild("wimp/dropdown_box")
			:geometrySetMode("stack", "pixel", 32)
			:userCallbackSet("cb_chosenSelection", cb_selectLabelSide)

		local i1 = lb:addItem("Label Side: Left")
		i1.usr_side_id = "left"

		local i2 = lb:addItem("Label Side: Center")
		i2.usr_side_id = "center"

		local i3 = lb:addItem("Label Side: Right")
		i3.usr_side_id = "right"

		lb:setSelection(i2)
	end
end


return plan
