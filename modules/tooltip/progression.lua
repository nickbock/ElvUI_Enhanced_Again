local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB, Localize Underscore
local TT = E:GetModule('Tooltip')

local tiers = { "HFC","BRF","HM" }
local levels = { 
	"Mythic", 
	"Heroic", 
	"Normal",
	"LFR",
}

local bosses = {
	{ -- HFC
		{ --Mythic
			10204, 10208, 10212, 10216, 10220, 10224, 10228, 10232, 10236, 10240, 10244, 10248, 10252,
		},
		{ -- Herioc
			10203, 10207, 10211, 10215, 10219, 10223, 10227, 10231, 10235, 10239, 10243, 10247, 10251,
		},
		{ -- Normal
			10202, 10206, 10210, 10214, 10218, 10222, 10226, 10230, 10234, 10238, 10242, 10246, 10250,
		},
		{ -- LFR
			10201, 10205, 10209, 10213, 10217, 10221, 10225, 10229, 10233, 10237, 10241, 10245, 10249,
		},
	},
	{ -- Blackrock Foundry
		{ --Mythic
			9319, 9323, 9329, 9333, 9338, 9342, 9353, 9357, 9361, 9365, 
		},
		{ -- Herioc
			9318, 9322, 9328, 9332, 9337, 9341, 9351, 9356, 9360, 9364, 
		},
		{ -- Normal
			9317, 9321, 9327, 9331, 9336, 9340, 9349, 9355, 9359, 9363, 
		},
		{ -- LFR
			9316, 9320, 9324, 9330, 9334, 9339, 9343, 9354, 9358, 9362, 
		},
	},
	{ -- HighMaul
		{ -- Mythic
			9285, 9289, 9294, 9300, 9304, 9311, 9315,
		},
		{ -- Herioc
			9284, 9288, 9293, 9298, 9303, 9310, 9314,
		},
		{ --Normal
			9282, 9287, 9292, 9297, 9302, 9308, 9313,
		},
		{ --LFR
			9280, 9286, 9290, 9295, 9301, 9306, 9312,
		},
	},
}

local playerGUID = UnitGUID("player")
local progressCache = {}
local highest = { 0, 0 }

local function GetProgression(guid)
	local kills, complete, pos = 0, false, 0
	local statFunc = guid == playerGUID and GetStatistic or GetComparisonStatistic
	
	for tier = 1, 3 do
		progressCache[guid].header[tier] = {}
		progressCache[guid].info[tier] = {}
		for level = 1, 4 do
			highest = 0
			for statInfo = 1, #bosses[tier][level] do
				kills = tonumber((statFunc(bosses[tier][level][statInfo])))
				if kills and kills > 0 then						
					highest = highest + 1
				end
			end
			pos = highest
			if (highest > 0) then
				progressCache[guid].header[tier][level] = ("%s [%s]:"):format(tiers[tier], levels[level])
				progressCache[guid].info[tier][level] = ("%d/%d"):format(highest, #bosses[tier][level])
				if highest == #bosses[tier][level] then
					break
				end
			end
		end
	end		
end

local function UpdateProgression(guid)
	progressCache[guid] = progressCache[guid] or {}
	progressCache[guid].header = progressCache[guid].header or {}
	progressCache[guid].info =  progressCache[guid].info or {}
	progressCache[guid].timer = GetTime()
		
	GetProgression(guid)	
end

local function SetProgressionInfo(guid, tt)
	if progressCache[guid] then
		local updated = 0
		for i=1, tt:NumLines() do
			local leftTipText = _G["GameTooltipTextLeft"..i]	
			for tier = 1, 3 do
				for level = 1, 4 do
					if (leftTipText:GetText() and leftTipText:GetText():find(tiers[tier]) and leftTipText:GetText():find(levels[level])) then
						-- update found tooltip text line
						local rightTipText = _G["GameTooltipTextRight"..i]
						leftTipText:SetText(progressCache[guid].header[tier][level])
						rightTipText:SetText(progressCache[guid].info[tier][level])
						updated = 1
					end
				end
			end
		end
		if updated == 1 then return end
		-- add progression tooltip line
		if highest > 0 then tt:AddLine(" ") end
		for tier = 1, 3 do
			for level = 1, 4 do
				tt:AddDoubleLine(progressCache[guid].header[tier][level], progressCache[guid].info[tier][level], nil, nil, nil, 1, 1, 1)
			end
		end
	end
end

function TT:INSPECT_ACHIEVEMENT_READY(event, GUID)
	if (self.compareGUID ~= GUID) then return end

	local unit = "mouseover"
	if UnitExists(unit) then
		UpdateProgression(GUID)
		GameTooltip:SetUnit(unit)
	end
	ClearAchievementComparisonUnit()
	self:UnregisterEvent("INSPECT_ACHIEVEMENT_READY")
end

hooksecurefunc(TT, 'ShowInspectInfo', function(self, tt, unit, level, r, g, b, numTries)
	if InCombatLockdown() then return end
	if not E.db.tooltip.progressInfo then return end
	if not level or level < MAX_PLAYER_LEVEL then return end
	if not (unit and CanInspect(unit)) then return end
	
	local guid = UnitGUID(unit)
	if not progressCache[guid] or (GetTime() - progressCache[guid].timer) > 600 then
		if guid == playerGUID then
			UpdateProgression(guid)
		else
			ClearAchievementComparisonUnit()		
			if not self.loadedComparison and select(2, IsAddOnLoaded("Blizzard_AchievementUI")) then
				AchievementFrame_DisplayComparison(unit)
				HideUIPanel(AchievementFrame)
				ClearAchievementComparisonUnit()
				self.loadedComparison = true
			end
			
			self.compareGUID = guid
			if SetAchievementComparisonUnit(unit) then
				self:RegisterEvent("INSPECT_ACHIEVEMENT_READY")
			end
			return
		end
	end

	SetProgressionInfo(guid, tt)
end)
