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

  local ENTITY_INFO = {}
  net.Receive("DT_HUD/EntityInfo", function()
    ENTITY_INFO = {
      Entity = net.ReadEntity(),
      Health = net.ReadFloat(),
      MaxHealth = net.ReadFloat(),
      Disposition = net.ReadUInt(3)
    }
  end)

  local function DisplayEntityInfo()
    local ent = ENTITY_INFO.Entity
    local health = ENTITY_INFO.Health
    local maxHealth = ENTITY_INFO.MaxHealth
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
    if ent == ENTITY_INFO.Entity and DisplayEntityInfo() then
      local health = ENTITY_INFO.Health
      local maxHealth = ENTITY_INFO.MaxHealth
      local text = ent:IsPlayer() and ent:Nick() or language.GetPhrase(ent:GetClass())
      local color = DT_HUD.GetDispositionColor(ENTITY_INFO.Disposition)
      local ctx = DT_HUD.DrawContext()
      if DT_HUD.EntityInfoAbove:GetBool() then
        local pos, height = ent:GetPos(), ent:OBBMaxs().z
        local top = Vector(pos.x, pos.y, pos.z + height)
        local x, y = ctx:FromWorldPos(top)
        if not x or not y then return end
        ctx:SetOrigin(x - 10, y - 4)
        ctx:SetWrapAround(false)
        ctx:DrawText(10, -2, text, {maxLength = 20, xAlign = TEXT_ALIGN_CENTER})
        ctx:DrawBar(0, 0, {
          length = 20, height = 2,
          label = "#dt_hud.health",
          value = health, max = maxHealth,
          color = color, blur = true
        })
      else
        ctx:SetOrigin(1.5, 1)
        ctx:DrawFrame(22, 6, "left")
        ctx:DrawText(1, 1, text, {maxLength = 20})
        ctx:DrawBar(1, 3, {
          length = 20, height = 2,
          label = "#dt_hud.health",
          value = health, max = maxHealth,
          color = color
        })
      end
    end
  end)

end