DT_HUD.EntityInfoAllowed = DT_Lib.ConVar("dt_hud_entity_info_allowed", "1")
DT_HUD.EntityInfoTickrate = DT_Lib.ConVar("dt_hud_entity_info_tickrate", "10")

if SERVER then
  util.AddNetworkString("DT_HUD/EntityInfo")

  local LAST_UPDATE = 0
  hook.Add("Think", "DT_HUD/UpdateEntityInfo", function()
    if not DT_HUD.EntityInfoAllowed:GetBool() then return end
    local delay = 1 / DT_HUD.EntityInfoTickrate:GetInt()
    if CurTime() < LAST_UPDATE + delay then return end
    LAST_UPDATE = CurTime()
    for _, ply in ipairs(player.GetHumans()) do
      local ent = ply:GetEyeTrace().Entity
      if not IsValid(ent) then continue end
      net.Start("DT_HUD/EntityInfo")
      net.WriteEntity(ent)
      net.WriteFloat(ent:Health())
      net.WriteFloat(ent:GetMaxHealth())
      net.WriteUInt(ent:DT_GetDisposition(ply), 3)
      net.Send(ply)
    end
  end)

else

  DT_HUD.EntityInfoEnabled = DT_Lib.ClientConVar("dt_hud_entity_info", "1")
  DT_HUD.EntityInfoAbove = DT_Lib.ClientConVar("dt_hud_entity_info_above", "1")

  DT_HUD.EntityInfo = {}
  net.Receive("DT_HUD/EntityInfo", function()
    local oldEnt = DT_HUD.EntityInfo.Entity
    DT_HUD.EntityInfo.Entity = net.ReadEntity()
    DT_HUD.EntityInfo.Health = net.ReadFloat()
    DT_HUD.EntityInfo.MaxHealth = net.ReadFloat()
    DT_HUD.EntityInfo.Disposition = net.ReadUInt(3)
    if oldEnt ~= DT_HUD.EntityInfo.Entity then
      DT_HUD.EntityInfo.DisplayedHealth = nil
    end
  end)
  hook.Add("Think", "DT_HUD/EntityHealthLerp", function()
    if LocalPlayer():GetEyeTrace().Entity == DT_HUD.EntityInfo.Entity then
      DT_HUD.EntityInfo.DisplayedHealth = DT_HUD.EntityInfo.DisplayedHealth
        and Lerp(0.2, DT_HUD.EntityInfo.DisplayedHealth, DT_HUD.EntityInfo.Health)
        or DT_HUD.EntityInfo.Health
    else DT_HUD.EntityInfo = {} end
  end)

  local function DisplayEntityInfo()
    local ent = DT_HUD.EntityInfo.Entity
    local health = DT_HUD.EntityInfo.Health
    local maxHealth = DT_HUD.EntityInfo.MaxHealth
    if not IsValid(ent) then return false end
    return ent:DT_IsTarget()
      or (ent:GetClass() == "prop_physics" and (health > 0 or maxHealth > 1))
  end

  hook.Add("DT_HUD/Paint", "DT_HUD/EntityInfo", function()
    if not DT_HUD.EntityInfoAllowed:GetBool() then return end
    if not DT_HUD.EntityInfoEnabled:GetBool() then return end
    local ply = LocalPlayer()
    if ply:InVehicle() then return end
    local ent = ply:GetEyeTrace().Entity
    if ent == DT_HUD.EntityInfo.Entity and DisplayEntityInfo() then
      local maxHealth = DT_HUD.EntityInfo.MaxHealth
      local health = DT_HUD.EntityInfo.DisplayedHealth or DT_HUD.EntityInfo.Health
      local text = ent:IsPlayer() and ent:Nick() or language.GetPhrase(ent:GetClass())
      local color = DT_HUD.GetDispositionColor(DT_HUD.EntityInfo.Disposition)
      local ctx = DT_HUD.DrawContext()
      if DT_HUD.EntityInfoAbove:GetBool() then
        local pos, height = ent:GetPos(), ent:OBBMaxs().z
        local top = Vector(pos.x, pos.y, pos.z + height)
        local x, y = ctx:FromWorldPos(top)
        if not x or not y then return end
        ctx:SetOffset(x - 10, y - 4)
        ctx:DrawText(10, -2, text, {maxLength = 20, xAlign = TEXT_ALIGN_CENTER})
        ctx:DrawBar(0, 0, {
          length = 20, height = 2,
          label = "#dt_hud.health",
          value = health, max = maxHealth,
          color = color, blur = true,
          animId = "entity_info"
        })
      else
        ctx:SetOrigin(1.5, 1)
        ctx:DrawFrame(22, 6, "left")
        ctx:DrawText(1, 1, text, {maxLength = 20})
        ctx:DrawBar(1, 3, {
          length = 20, height = 2,
          label = "#dt_hud.health",
          value = health, max = maxHealth,
          color = color, blur = false,
          animId = "entity_info"
        })
      end
    end
  end)

end