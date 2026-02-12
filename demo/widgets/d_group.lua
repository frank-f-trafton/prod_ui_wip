
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
		:geometrySetMode("segment", "top")
		:layoutSetMargin(4, 4, 4, 4)
		:layoutSetStackFlow("y", 1)
		:layoutSetStackDefaultWidgetSize("pixel", 40)
		:setText("Group")

	-- [=[
	do
		local function cb_selectStyle(self, item_i, item)
			local group = self:nodeFindKeyAscending(true, "tag", "demo_group")
			if group then
				group:pipeSetStyle(item.usr_pipe_id)
			end
		end

		local c_label = group:addChild("base/control_label")
			:geometrySetMode("segment", "top")
			:setText("PipeStyle:")

		local lb = group:addChild("wimp/dropdown_box")
			:geometrySetMode("segment", "top")
			:userCallbackSet("cb_chosenSelection", cb_selectStyle)

		local i1 = lb:addItem("(Skin Default)")
		i1.usr_pipe_id = false

		local i2 = lb:addItem("Norm")
		i2.usr_pipe_id = "norm"

		local i3 = lb:addItem("Double")
		i3.usr_pipe_id = "double"

		local i4 = lb:addItem("Thick")
		i4.usr_pipe_id = "thick"

		lb:setSelection(i2)
	end
	--]=]


	-- [=[
	do
		local function cb_selectDeco(self, item_i, item)
			local group = self:nodeFindKeyAscending(true, "tag", "demo_group")
			if group then
				group:setDecorationStyle(item.usr_deco_id)
			end
		end

		local c_label = group:addChild("base/control_label")
			:geometrySetMode("segment", "top")
			:setText("Decoration:")

		local lb = group:addChild("wimp/dropdown_box")
			:geometrySetMode("segment", "top")
			:userCallbackSet("cb_chosenSelection", cb_selectDeco)

		local i0 = lb:addItem("(Skin Default)")
		i0.usr_deco_id = false

		local i1 = lb:addItem("None")
		i1.usr_deco_id = "none"

		local i2 = lb:addItem("Outline")
		i2.usr_deco_id = "outline"

		local i3 = lb:addItem("Outline + Label")
		i3.usr_deco_id = "outline-label"

		local i4 = lb:addItem("Header")
		i4.usr_deco_id = "header"

		local i5 = lb:addItem("Header + Label")
		i5.usr_deco_id = "header-label"

		local i6 = lb:addItem("Underlined Label")
		i6.usr_deco_id = "underline-label"

		local i7 = lb:addItem("Underlined Label (full breadth)")
		i7.usr_deco_id = "underline-label-wide"

		local i8 = lb:addItem("Just the label")
		i8.usr_deco_id = "label"

		lb:setSelection(i3)
	end
	--]=]

	-- [=[
	do
		local function cb_selectLabelSide(self, item_i, item)
			local group = self:nodeFindKeyAscending(true, "tag", "demo_group")
			if group then
				group:setLabelSide(item.usr_side_id)
			end
		end

		local c_label = group:addChild("base/control_label")
			:geometrySetMode("segment", "top")
			:setText("Label Alignment:")

		local lb = group:addChild("wimp/dropdown_box")
			:geometrySetMode("segment", "top")
			:userCallbackSet("cb_chosenSelection", cb_selectLabelSide)

		local i0 = lb:addItem("(Skin Default)")
		i0.usr_side_id = false

		local i1 = lb:addItem("Left")
		i1.usr_side_id = "left"

		local i2 = lb:addItem("Center")
		i2.usr_side_id = "center"

		local i3 = lb:addItem("Right")
		i3.usr_side_id = "right"

		lb:setSelection(i2)
	end
	--]=]
end


return plan
