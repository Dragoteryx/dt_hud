if SERVER then
  util.AddNetworkString("DT_HUD/PlayerTakeDamage")

  hook.Add("EntityTakeDamage", "DT_HUD/PlayerTakeDamage", function(ent, dmginfo)
    if ent:IsPlayer() then
      net.Start("DT_HUD/PlayerTakeDamage")
      net.WriteUInt(dmginfo:GetDamageType(), 32)
      net.Send(ent)
    end
  end)

else

  DT_HUD.StatusEnabled = DT_Lib.ClientConVar("dt_hud_status_info", "1")
  DT_HUD.StatusEffects = DT_Lib.ClientConVar("dt_hud_status_effects", "1")
  DT_HUD.StatusMiscEnabled = DT_Lib.ClientConVar("dt_hud_status_misc", "1")

  local FPS = -1
  local PING = -1
  local LAST_INFO_REFRESH = 0
  hook.Add("Think", "DT_HUD/RefreshFPSPing", function()
    if CurTime() < LAST_INFO_REFRESH + 1 then return end
    PING = math.Round(LocalPlayer():Ping())
    FPS = math.Round(1 / FrameTime())
    LAST_INFO_REFRESH = CurTime()
  end)

  local HEALTH = nil
  local ARMOR = nil
  hook.Add("Think", "DT_HUD/HealthArmorLerp", function()
    local ply = LocalPlayer()
    if ply:Alive() then
      HEALTH = HEALTH and Lerp(0.2, HEALTH, ply:Health()) or ply:Health()
      ARMOR = ARMOR and Lerp(0.2, ARMOR, ply:Armor()) or ply:Armor()
    else
      HEALTH = nil
      ARMOR = nil
    end
  end)

  local DMG_TYPES = {
    {dmgtype = DMG_SLASH, last = -1, mat = Material("dt_hud/slash.png")},
    {dmgtype = DMG_BLAST + DMG_BLAST_SURFACE, last = -1, mat = Material("dt_hud/blast.png")},
    {dmgtype = DMG_BURN + DMG_SLOWBURN, last = -1, mat = Material("dt_hud/fire.png")},
    {dmgtype = DMG_SHOCK, last = -1, mat = Material("dt_hud/shock.png")},
    {dmgtype = DMG_ACID + DMG_POISON + DMG_PARALYZE, last = -1, mat = Material("dt_hud/poison.png")},
    {dmgtype = DMG_RADIATION, last = -1, mat = Material("dt_hud/radiation.png")}
  }

  net.Receive("DT_HUD/PlayerTakeDamage", function()
    local type = net.ReadUInt(32)
    for _, res in ipairs(DMG_TYPES) do
      if bit.band(type, res.dmgtype) ~= 0 then
        res.last = CurTime()
      end
    end
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
    if DT_HUD.StatusEffects:GetBool() then
      ctx:SetOrigin(1.5, -12)
      ctx:DrawFrame(22, 11, "left")
    else
      ctx:SetOrigin(1.5, -8)
      ctx:DrawFrame(22, 7, "left")
    end

    -- health & armor --

    local health = HEALTH or ply:Health()
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

    local armor = ARMOR or ply:Armor()
    local maxArmor = ply:GetMaxArmor()
    ctx:DrawBar(1, 4, {
      length = 20, height = 2,
      label = "#dt_hud.armor",
      value = armor, max = maxArmor,
      color = DT_HUD.ArmorColor.Value
    })

    -- misc info --

    if DT_HUD.StatusMiscEnabled:GetBool() then
      ctx:MoveOrigin(0, -4)
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
      local speed = ctx:CreateSquare(1.5, 1.6, 2)
      if IsValid(veh) then
        local icon = DT_HUD.GetVehicleIcon(veh)
        speed:Fill(DT_HUD.MainColor.Value, icon)
      else
        speed:Fill(DT_HUD.MainColor.Value, DT_HUD.SpeedIcon)
      end

      ctx:DrawText(8, 1, text, {xAlign = TEXT_ALIGN_RIGHT})
      ctx:DrawLine(9, 0, 9, 3, DT_HUD.Border)

      ctx:CreateSquare(10.65, 1.55, 1.8):Fill(DT_HUD.MainColor.Value, DT_HUD.FPSIcon)
      ctx:DrawText(14.5, 1, FPS, {xAlign = TEXT_ALIGN_RIGHT})
      ctx:DrawLine(15.5, 0, 15.5, 3, DT_HUD.Border)

      ctx:CreateSquare(17.15, 1.55, 2.3):Fill(DT_HUD.MainColor.Value, DT_HUD.PingIcon)
      ctx:DrawText(21, 1, PING, {xAlign = TEXT_ALIGN_RIGHT})
    end

    -- status effects --

    if DT_HUD.StatusEffects:GetBool() then
      ctx:SetOrigin(2.5, -5)
      ctx:CreateRectangle(0, 0, 20, 3)
        :Fill(DT_HUD.Background)
        :Stroke(DT_HUD.Border)

      local n = #DMG_TYPES
      local l = 20 / n
      for i, res in ipairs(DMG_TYPES) do
        local icon = ctx:CreateSquare(l/2, 1.5, math.min(l, 3) - 0.5)
        if CurTime() < res.last + 5 then
          icon:Fill(DT_HUD.MainColor.Value, res.mat)
        else
          icon:Fill(DT_HUD.Background, res.mat)
        end

        ctx:AddOffset(l, 0)
        if i ~= n then
          ctx:DrawLine(0, 0, 0, 3, DT_HUD.Border)
        end
      end
    end
  end)

end