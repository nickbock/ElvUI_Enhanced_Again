local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB, Localize Underscore
local TT = E:GetModule('Tooltip')

local tiers = { "EmN", "NH" }
local levels = { 
	"Mythic", 
	"Heroic", 
	"Normal",
	"LFR",
}

local bosses = {
	{ -- Emerald Nightmare
		{ --Mythic
			10914, 10923, 10927, 10919, 10931, 10935, 10939, 
		},
		{ -- Herioc
			10913, 10922, 10926, 10917, 10930, 10934, 10938, 
		},
		{ -- Normal
			10912, 10921, 10925, 10916, 10929, 10933, 10937, 
		},
		{ -- LFR
			10911, 10920, 10924, 10915, 10928, 10932, 10936, 
		},
	},
	{ -- Nighthold
		{ --Mythic
			10943, 10947, 10951, 10955, 10960, 10964, 10968, 10972, 10976, 10980
		},
		{ -- Herioc
			10942, 10946, 10950, 10954, 10959, 10963, 10967, 10971, 10975, 10979
		},
		{ -- Normal
			10941, 10945, 10949, 10953, 10957, 10962, 10966, 10970, 10974, 10978
		},
		{ -- LFR
			10940, 10944, 10948, 10952, 10956, 10961, 10965, 10969, 10973, 10977
		},
	},
}

local playerGUID = UnitGUID("player")
local progressCache = {}
local highest = { 0, 0 }

local function GetProgression(guid)
	local kills, complete, pos = 0, false, 0
	local statFunc = guid == playerGUID and GetStatistic or GetComparisonStatistic
	
	for tier = 1, 2 do
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
			for tier = 1, 2 do
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
		for tier = 1, 2 do
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
