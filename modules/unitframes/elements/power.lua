local E, L, V, P, G = unpack(ElvUI);
local UF = E:GetModule('UnitFrames')

local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitName = UnitName


function UF:Configure_Power(frame)
	local power = frame.Power
	if not power then return end
    
    local role = UnitGroupRolesAssigned(player)
    print(role)
        if role ~= "HEALER" then return end
        print("healer gevonden")
        power.hide()
end
