local E, L, V, P, G = unpack(ElvUI); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB, Localize Underscore
local BI = E:NewModule('BagInfo', 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0')
local B = E:GetModule('Bags')

local byte, format = string.byte, string.format
local tinsert, twipe = table.insert, table.wipe

local updateTimer
local containers = {}
local infoArray = {}
local equipmentMap = {}

local function Utf8Sub(str, start, numChars)
  local currentIndex = start
  while numChars > 0 and currentIndex <= #str do
    local char = byte(str, currentIndex)
    if char > 240 then
      currentIndex = currentIndex + 4
    elseif char > 225 then
      currentIndex = currentIndex + 3
    elseif char > 192 then
      currentIndex = currentIndex + 2
    else
      currentIndex = currentIndex + 1
    end
    numChars = numChars -1
  end
  return str:sub(start, currentIndex - 1)
end

local function MapKey(bag, slot)
	return format("%d_%d", bag, slot)
end

local quickFormat = {
	[0] = function(font, map) font:SetText() end,
	[1] = function(font, map) font:SetFormattedText("|cffffffaa%s|r", Utf8Sub(map[1], 1, 4)) end,
	[2] = function(font, map) font:SetFormattedText("|cffffffaa%s %s|r", Utf8Sub(map[1], 1, 4), Utf8Sub(map[2], 1, 4)) end,
	[3] = function(font, map) font:SetFormattedText("|cffffffaa%s %s %s|r", Utf8Sub(map[1], 1, 4), Utf8Sub(map[2], 1, 4), Utf8Sub(map[3], 1, 4)) end,
}

function BI:BuildEquipmentMap(clear)
	-- clear mapped names
	for k, v in pairs(equipmentMap) do
		twipe(v)
	end
	if clear then return end
	
	local name, player, bank, bags, slot, bag, key
	local equipmentSetIDs = C_EquipmentSet.GetEquipmentSetIDs();
	for key,value in pairs(equipmentSetIDs) do
		local name = C_EquipmentSet.GetEquipmentSetInfo(value)
		local infoArray = C_EquipmentSet.GetItemLocations(value)
		for _, location in pairs(infoArray) do
			if location < -1 or location > 1 then
				player, bank, bags, _, slot, bag = EquipmentManager_UnpackLocation(location)
				if ((bank or bags) and slot and bag) then
					key = MapKey(bag, slot)
					equipmentMap[key] = equipmentMap[key] or {}
					tinsert(equipmentMap[key], name)
				end
			end
		end
	end
end

function BI:UpdateContainerFrame(frame, bag, slot)
	if (not frame.equipmentinfo) then
		frame.equipmentinfo = frame:CreateFontString(nil, "OVERLAY")
		frame.equipmentinfo:FontTemplate(E.media.font, 12, "THINOUTLINE")
		frame.equipmentinfo:SetWordWrap(true)
		frame.equipmentinfo:SetJustifyH('CENTER')
		frame.equipmentinfo:SetJustifyV('MIDDLE')
	end

	if (frame.equipmentinfo) then
		frame.equipmentinfo:SetAllPoints(frame)

		local key = MapKey(bag, slot)
		if equipmentMap[key] then	
			quickFormat[#equipmentMap[key] < 4 and #equipmentMap[key] or 3](frame.equipmentinfo, equipmentMap[key])
		else
			quickFormat[0](frame.equipmentinfo, nil)
		end
	end
end

function BI:UpdateBagInformation(clear)
	updateTimer = nil

	self:BuildEquipmentMap(clear)
	for _, container in pairs(containers) do
		for _, bagID in ipairs(container.BagIDs) do
			for slotID = 1, GetContainerNumSlots(bagID) do			
				self:UpdateContainerFrame(container.Bags[bagID][slotID], bagID, slotID)
			end
		end
	end
end

function BI:DelayUpdateBagInformation(event)
	-- delay to make sure multiple bag events are consolidated to one update.
	if not updateTimer then
		updateTimer = BI:ScheduleTimer("UpdateBagInformation", .25)
	end
end

function BI:ToggleSettings()
	if updateTimer then
		self:CancelTimer(updateTimer)
	end

	if E.private.equipment.misc.setoverlay then
		self:RegisterEvent("EQUIPMENT_SETS_CHANGED", "DelayUpdateBagInformation")
		self:RegisterEvent("BAG_UPDATE", "DelayUpdateBagInformation")
		BI:UpdateBagInformation()
	else
		self:UnregisterEvent("EQUIPMENT_SETS_CHANGED")
		self:UnregisterEvent("BAG_UPDATE") 
		BI:UpdateBagInformation(true)
	end		
end

function BI:Initialize()
	if not E.private.bags.enable then return end

	tinsert(containers, _G["ElvUI_ContainerFrame"])	
	self:SecureHook(B, "OpenBank", function()
		self:Unhook(B, "OpenBank")	
		tinsert(containers, _G["ElvUI_BankContainerFrame"])
		BI:ToggleSettings()
	end)
	
	BI:ToggleSettings()
end

E:RegisterModule(BI:GetName())
