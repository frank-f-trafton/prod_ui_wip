--[[
Sash development and testing.
--]]


-- ProdUI
local uiLayout = require("prod_ui.ui_layout")


local plan = {}


-- https://gutenberg.org/ebooks/74207
local _text1 = [[
H. G. Adams: Beautiful Shells [1856]

Dr. Johnson gives us no less than eight different meanings for the word Shell. First, he calls it ‘The hard covering of anything; the external crust.’ Second, ‘The covering of a testaceous or crustaceous animal.’ And here we may stop, for this is just the signification which has to do with our subject; so let us turn the sentence inside out, and see what we can make of it. We all know what a covering is—an outer coat, a case, a protection from injury, a husk, a crust, a—in short, a shell,—scyll or scell, as our Saxon forefathers called it; schale, as the Germans now term it. No Latin nor Greek here, but the good old Saxon tongue, somewhat rough and rugged, perhaps, but stout and sturdy, and honest and serviceable; a kind of language to stand wear and tear, like a pair of hob-nailed shoes, with little polish, but useful, yes, very useful! Well, we have got so far, now comes a hard word—Tes-ta-ce-ous, what can it mean? It is pronounced tes-ta-shus, comes from the Latin testaceus—having a Shell, and means consisting of, or composed of shells; so we find that a testacean is a shell-fish, and testaceology is the science of shells. Johnson’s second meaning of the word testaceous is ‘Having continuous, not jointed shells, opposed to crustaceous.’ So we find that some naturalists call those testaceous fish, “whose strong and thick shells are entire and of a piece, because those which are joined, as the lobsters, are crustaceous.”]]


-- https://gutenberg.org/cache/epub/73790/pg73790-images.html
local _text2 = [[
James Slough Zerbe: AUTOMOBILES [1915]

This is a subject in which every boy is interested. While few mechanics have the opportunity to actually build an automobile, it is the knowledge, which he must acquire about every particular device used, that enables him to repair and put such machines in order. The aim of this book is to make the boy acquainted with each element, so that he may understand why it is made in that special way, and what the advantages and disadvantages are of the different types. To that end each structure is shown in detail as much as possible, and the parts separated so as to give a clear insight of the different functions, all of which are explained by original drawings specially prepared to aid the reader.]]


function plan.make(panel)
	--title("Sashes")

	panel.auto_layout = true
	panel:setScrollBars(false, false)

	local wid_a = panel:addChild("base/label")
	wid_a.x = 0
	wid_a.y = 0
	wid_a.w = 256
	wid_a.h = 256
	wid_a:initialize()
	wid_a:register("fit-left")
	wid_a:setLabel(_text1, "multi")

	local wid_sash = panel:addChild("wimp/sash")
	wid_a.x = 0
	wid_a.y = 0
	wid_a.w = 8
	wid_a.h = 256
	wid_sash:initialize()
	wid_sash:register("fit-left")
	wid_sash:setAttachedWidget(wid_a)

	local wid_b = panel:addChild("base/label")
	wid_a.x = 0
	wid_a.y = 0
	wid_a.w = 256
	wid_a.h = 256
	wid_b:initialize()
	wid_b:register("fit-remaining")
	wid_b:setLabel(_text2, "multi")

	panel:reshape()
end


return plan
