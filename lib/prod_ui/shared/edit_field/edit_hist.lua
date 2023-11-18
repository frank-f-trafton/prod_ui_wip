-- To load: local lib = context:getLua("shared/lib")


--[[
	LineEditor history implementation.

	IMPORTANT: For password fields, you should disable undo/redo history.

	The history state contains:
	* A ledger of event entries
	* An index indicating the current position in the ledger. (Can be zero if the ledger is empty.)
	* A max entries limit
--]]


local context = select(1, ...)


local editHist = {}


local _mt_hist = {}
_mt_hist.__index = _mt_hist


-- Entry table pooling.
local entry_stack = {}
local entry_stack_max = 512


local function stackPop()
	return table.remove(entry_stack) or {}
end


local function stackPush(entry)

	local lines = entry.lines
	for i = #lines, 1, -1 do
		lines[i] = nil
	end

	entry_stack[math.min(#entry_stack + 1, entry_stack_max)] = entry
end


-- * Object creation *


function editHist.new()

	local self = {}

	self.enabled = true

	self.ledger = {}

	self.pos = 0
	self.max = 50

	setmetatable(self, _mt_hist)

	return self
end


-- * / Object creation *


-- * Debug *


function _mt_hist:printState()

	print("enabled: " .. self.enabled)
	print("pos/max: " .. self.pos .. "/" .. self.max)

	for i, entry in ipairs(self.ledger) do
		-- XXX WIP
		print("", i, entry)
	end
end


-- * / Debug *


-- * Internal *


local function assertEntryPosition(self)

	if self.pos < 0 or self.pos > #self.ledger then
		error("history position is out of bounds.")
	end
end


local function initEntry(entry, source_lines, car_line, car_byte, h_line, h_byte)

	entry = entry or stackPop()
	entry.lines = entry.lines or {}

	for i = #entry.lines, #source_lines + 1, -1 do
		entry.lines[i] = nil
	end
	for i = 1, #source_lines do
		entry.lines[i] = source_lines[i]
	end

	entry.car_line = car_line
	entry.car_byte = car_byte
	entry.h_line = h_line
	entry.h_byte = h_byte

	return entry
end


-- * / Internal *


-- * Methods *


--- Enable or disable history.
-- @param enabled Truthy to enable, false/nil/empty to disable.
function _mt_hist:setEnabled(enabled)

	self.enabled = not not enabled

	if not self.enabled then
		self:clearAll()
	end
end


--- Set the max history entries for the ledger. Note that this will wipe all existing ledger entries.
-- @param max The max ledger values. Must be an integer >= 0.
function _mt_hist:setMaxEntries(max)

	-- Allow setting max entries, even if not enabled.

	-- Assertions
	-- [[
	if type(max) ~= "number" or max ~= max or max ~= math.floor(max) or max < 0 then
		error("'max' must be an integer >= 0.")
	end
	--]]

	self.max = max
	self:clearAll()
end


--- Write a history entry to the ledger.
-- @param do_advance True, advance to the next ledger entry. False: overwrite the current entry (assuming one exists. If there are no entries, index 1 is created).
-- @param source_lines
function _mt_hist:writeEntry(do_advance, source_lines, car_line, car_byte, h_line, h_byte)

	--print("writeEntry", "do_advance", do_advance, "car_line", car_line, "car_byte", car_byte, "h_line", h_line, "h_byte")

	-- Assertions
	-- [[
	assertEntryPosition(self)
	--]]

	if not self.enabled then
		return
	end

	local ledger = self.ledger

	-- If advancing and ledger is full, remove oldest entry
	if do_advance then
		self.pos = self.pos + 1

		if self.pos >= #ledger and #ledger >= self.max then
			self.pos = self.pos - 1

			stackPush(table.remove(ledger, 1))
		end
	end

	self.pos = math.max(self.pos, 1)

	local entry = ledger[self.pos] or stackPop()
	ledger[self.pos] = initEntry(entry, source_lines, car_line, car_byte, h_line, h_byte)

	-- Remove stale future entries
	for i = #ledger, self.pos + 1, -1 do
		stackPush(table.remove(ledger, i))
	end
end


function _mt_hist:clearAll()

	-- Allow clearing, even if not enabled
	local ledger = self.ledger

	for i = #ledger, 1, -1 do
		stackPush(table.remove(ledger, i))
	end

	self.pos = 0
end


function _mt_hist:moveToEntry(index)

	if not self.enabled then
		return
	end

	local ledger = self.ledger

	local old_pos = self.pos
	self.pos = math.max(1, math.min(index, #ledger))

	if ledger[self.pos] then
		return old_pos ~= self.pos, ledger[self.pos]

	else
		return nil
	end
end


function _mt_hist:getCurrentEntry()
	return self.ledger[self.pos] -- can be nil
end


function _mt_hist:doctorCurrentCaretOffsets(car_line, car_byte, h_line, h_byte)
	local entry = self.ledger[self.pos]

	--print("entry", entry, "self.pos", self.pos)
	--print("car_line, car_byte, h_line, h_byte", car_line, car_byte, h_line, h_byte)

	if entry then
		entry.car_line = car_line
		entry.car_byte = car_byte
		entry.h_line = h_line
		entry.h_byte = h_byte
	end
end


-- * / Methods *


return editHist

