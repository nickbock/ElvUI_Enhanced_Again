local E, L, V, P, G = unpack(ElvUI); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB, Localize Underscore
local M = E:NewModule('MiscEnh', 'AceHook-3.0', 'AceEvent-3.0');

E.MiscEnh = M;

function M:LoadAutoRelease()
	if not E.private.general.pvpautorelease then return end

	local autoreleasepvp = CreateFrame("frame")
	autoreleasepvp:RegisterEvent("PLAYER_DEAD")
	autoreleasepvp:SetScript("OnEvent", function(self, event)
		local inInstance, instanceType = IsInInstance()
		if (inInstance and (instanceType == "pvp")) then
			local soulstone = GetSpellInfo(20707)
			if ((E.myclass ~= "SHAMAN") and not (soulstone and UnitBuff("player", soulstone))) then
				RepopMe()
			end
		end

		-- auto resurrection for world PvP area...when active
		for index = 1, GetNumWorldPVPAreas() do
			local pvpID, localizedName, isActive, canQueue, startTime, canEnter = GetWorldPVPAreaInfo(index)
			
			if (GetRealZoneText() == localizedName and isActive) then
				RepopMe()
			end
		end
	end)
end

--function M:UseOldTabTarget()
--	if not E.private.general.useoldtabtarget then return end
--	local useoldtabtarget = CreateFrame("frame")

--	useoldtabtarget:RegisterEvent("PLAYER_ENTERING_WORLD")

--	if GetCVar("TargetNearestUseOld") ~= "1" then 
--		useoldtabtarget:SetScript("OnEvent", function(self, event)
--			SetCVar("TargetNearestUseOld", 1)
			--DEFAULT_CHAT_FRAME:AddMessage(L['Use Old TabTarget Enabled'], 1.0, 0.5, 0.0)
--		end)
--	end
--end

function M:Initialize()
	self:LoadAutoRelease()
	self:LoadQuestReward()
	self:LoadWatchedFaction()
	self:LoadMoverTransparancy()
	--self:UseOldTabTarget()
end

E:RegisterModule(M:GetName())