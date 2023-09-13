DT_Hud.EntityInfoAllowed = DT_Core.ConVar("dt_hud_entity_info_allowed", "1")
DT_Hud.EntityInfoTickrate = DT_Core.ConVar("dt_hud_entity_info_tickrate", "10")

local EntityInfo = DT_Core.NetworkableStruct()

function EntityInfo:__new(ent, ply)
	self.Ent = ent
	self.Health = ent:Health()
	self.MaxHealth = ent:GetMaxHealth()
	self.Disp = ent:DT_GetDisposition(ply)
end

function EntityInfo:__read()
	self.Ent = net.ReadEntity()
	self.Health = net.ReadFloat()
	self.MaxHealth = net.ReadFloat()
	self.Disp = net.ReadUInt(3)
end

function EntityInfo:__write()
	net.WriteEntity(self.Ent)
	net.WriteFloat(self.Health)
	net.WriteFloat(self.MaxHealth)
	net.WriteUInt(self.Disp, 3)
end

function EntityInfo.__index:IsValid()
	if not IsValid(self.Ent) then return false end
	if CLIENT and self.Ent:IsDormant() then return false end
	return true
end

if SERVER then
	util.AddNetworkString("DT/Hud.EntityInfo")

	local LAST_UPDATE = 0
	hook.Add("Think", "DT/Hud.UpdateEntity", function()
		if not DT_Hud.EntityInfoAllowed:GetBool() then return end
		local delay = 1 / DT_Hud.EntityInfoTickrate:GetInt()
		if CurTime() < LAST_UPDATE + delay then return end
		LAST_UPDATE = CurTime()
		for _, ply in ipairs(player.GetHumans()) do
			local ent = ply:GetEyeTrace().Entity
			if not IsValid(ent) then continue end
			if not ent:DT_IsTarget() then continue end
			local entityInfo = EntityInfo(ent, ply)
			entityInfo:Send("DT/Hud.EntityInfo", ply)
		end
	end)

else

	DT_Hud.EntityInfoEnabled = DT_Core.ClientConVar("dt_hud_entity_info", "1")
	DT_Hud.EntityInfoAbove = DT_Core.ClientConVar("dt_hud_entity_info_above", "1")

	local ENTITY_INFO = nil
	EntityInfo.Receive("DT/Hud.EntityInfo", function(entityInfo)
		local displayedHealth = ENTITY_INFO and ENTITY_INFO.DisplayedHealth
		local oldEnt = ENTITY_INFO and ENTITY_INFO.Ent
		ENTITY_INFO = entityInfo
		ENTITY_INFO.Time = CurTime()
		if oldEnt == ENTITY_INFO.Ent then
			ENTITY_INFO.DisplayedHealth = displayedHealth
		end
	end)

	hook.Add("Think", "DT/Hud.UpdateEntityInfo", function()
		if ENTITY_INFO then
			ENTITY_INFO.DisplayedHealth = ENTITY_INFO.DisplayedHealth
				and Lerp(0.05, ENTITY_INFO.DisplayedHealth, ENTITY_INFO.Health)
				or ENTITY_INFO.Health
		end
	end)

	hook.Add("DT/Hud.Draw", "DT/Hud.DrawEntityInfo", function()
		if not DT_Hud.EntityInfoAllowed:GetBool() then return end
		if not DT_Hud.EntityInfoEnabled:GetBool() then return end
		local ctx, ply = DT_Hud.DrawContext(), LocalPlayer()
		if ply:InVehicle() then return end
		if IsValid(ENTITY_INFO) and CurTime() < ENTITY_INFO.Time + 1 then
			local ent = ENTITY_INFO.Ent
			local maxHealth = ENTITY_INFO.MaxHealth
			local health = ENTITY_INFO.DisplayedHealth or ENTITY_INFO.Health
			local text = ent:IsPlayer() and ent:Nick() or language.GetPhrase(ent:GetClass())
			local color = DT_Hud.GetDispositionColor(ENTITY_INFO.Disp)
			if DT_Hud.EntityInfoAbove:GetBool() then
				local pos, height = ent:GetPos(), ent:OBBMaxs().z
				local top = Vector(pos.x, pos.y, pos.z + height)
				local x, y = ctx:FromWorldPos(top)
				if not x or not y then return end
				ctx:SetOrigin(x, y - 6)
				ctx:DrawText(0, 0, text, {
					xAlign = TEXT_ALIGN_CENTER,
					outline = true
				})

				ctx:Hud_DrawBar(-10, 2, {
					length = 20, height = 2,
					value = health, max = maxHealth,
					color = color, blur = true,
					outline = true
				})
			else
				ctx:MoveOrigin(1, 1)
				ctx:Hud_DrawBackground(0, 0, 22, 3)
				ctx:DrawText(1, 1.5, text, {
					yAlign = TEXT_ALIGN_CENTER,
					maxLength = 20,
					outline = true
				})

				ctx:MoveOrigin(0, 3.5)
				ctx:Hud_DrawBackground(0, 0, 22, 3)
				ctx:DrawMaterial(1.5, 1.5, 2, DT_Hud.HealthIcon, true)
				ctx:Hud_DrawBar(3, 0.5, {
					length = 18.5, height = 2,
					value = health, max = maxHealth,
					color = color,
					outline = true
				})
			end
		end
	end)

end