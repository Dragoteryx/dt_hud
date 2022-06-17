DT_HUD.StatusEnabled = DT_Lib.ClientConVar("dt_hud_status", "1")
DT_HUD.StatusEffects = DT_Lib.ClientConVar("dt_hud_status_effects", "1")
DT_HUD.StatusInfoEnabled = DT_Lib.ClientConVar("dt_hud_status_info", "1")

local FPS = -1
local PING = -1
local LAST_INFO_REFRESH = 0
hook.Add("Think", "DT_HUD/RefreshFPSPing", function()
  if CurTime() < LAST_INFO_REFRESH + 1 then return end
  PING = math.Round(LocalPlayer():Ping())
  FPS = math.Round(1 / FrameTime())
  LAST_INFO_REFRESH = CurTime()
end)

hook.Add("DT_HUD/ShouldDraw", "DT_HUD/HideStatus", function(name)
  if not DT_HUD.StatusEnabled:GetBool() then return end
  if name == "CHudHealth" or name == "CHudBattery" then
    return false
  end
end)

hook.Add("DT_HUD/Paint", "DT_HUD/Status", function()
  if not DT_HUD.StatusEnabled:GetBool() then return end
  local ply = LocalPlayer()
  if not ply:Alive() then return end

  local ctx = DT_HUD.DrawContext()
  ctx:SetOrigin(1.5, -12)
  ctx:DrawFrame(22, 11, "left")

  local health = ply:Health()
  local maxHealth = ply:GetMaxHealth()
  local healthRatio = math.Clamp(health/maxHealth, 0, 1)
  local fullHealth = DT_HUD.FullHealthColor.Value
  local lowHealth = DT_HUD.LowHealthColor.Value
  ctx:DrawBar(1, 1, {
    length = 20, height = 2,
    label = "#dt_hud.health",
    value = health, max = maxHealth,
    color = Color(
      Lerp(healthRatio, lowHealth.r, fullHealth.r),
      Lerp(healthRatio, lowHealth.g, fullHealth.g),
      Lerp(healthRatio, lowHealth.b, fullHealth.b)
    )
  })

  local armor = ply:Armor()
  local maxArmor = ply:GetMaxArmor()
  ctx:DrawBar(1, 4, {
    length = 20, height = 2,
    label = "#dt_hud.armor",
    value = armor, max = maxArmor,
    color = DT_HUD.ArmorColor.Value
  })

  ctx:SetOrigin(2.5, -5)
  local rect = ctx:CreateRectangle(0, 0, 20, 3)
  rect:Fill(DT_HUD.Background)
  rect:Stroke(DT_HUD.Border)
  ctx:DrawText(1, 1, "if u read this ur gay")

  if DT_HUD.StatusInfoEnabled:GetBool() then
    ctx:SetOrigin(1.5, -16)
    ctx:DrawFrame(22, 3, "left")

    local speed
    local veh = ply:DT_GetVehicle()
    if IsValid(veh) then speed = veh:GetVelocity():Length()
    else speed = ply:GetVelocity():Length() end
    local converted = DT_HUD.ConvertSpeedUnits(speed)
    local text = "???????"
    if converted then
      local unit = DT_HUD.SpeedUnit:GetString()
      text = math.Round(converted).." "..unit
    end
    local speed = ctx:CreateSquare(0.5, 0.6, 2)
    if IsValid(veh) then
      local icon = DT_HUD.GetVehicleIcon(veh)
      speed:Fill(DT_HUD.MainColor.Value, icon)
    else
      speed:Fill(DT_HUD.MainColor.Value, DT_HUD.SpeedIcon)
    end
    ctx:DrawText(8, 1, text, {xAlign = TEXT_ALIGN_RIGHT})
    ctx:DrawLine(9, 0, 9, 3, DT_HUD.Border)

    local fps = ctx:CreateSquare(9.75, 0.65, 1.8)
    fps:Fill(DT_HUD.MainColor.Value, DT_HUD.FPSIcon)
    ctx:DrawText(14.5, 1, FPS, {xAlign = TEXT_ALIGN_RIGHT})
    ctx:DrawLine(15.5, 0, 15.5, 3, DT_HUD.Border)

    local ping = ctx:CreateSquare(16, 0.4, 2.3)
    ping:Fill(DT_HUD.MainColor.Value, DT_HUD.PingIcon)
    ctx:DrawText(21, 1, PING, {xAlign = TEXT_ALIGN_RIGHT})
  end
end)