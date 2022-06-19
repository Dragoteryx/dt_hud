if SERVER then
  util.AddNetworkString("DT_HUD/EntityDeath")

  local function SendToKillfeed(attacker, victim)
    for _, ply in pairs(player.GetHumans()) do
      net.Start("DT_HUD/EntityDeath")
      if attacker:IsPlayer() then
        net.WriteString(attacker:Nick())
        net.WriteBool(true)
      else
        net.WriteString(attacker:GetClass())
        net.WriteBool(false)
      end
      net.WriteUInt(attacker:DT_GetDisposition(ply), 3)
      if victim:IsPlayer() then
        net.WriteString(victim:Nick())
        net.WriteBool(true)
      else
        net.WriteString(victim:GetClass())
        net.WriteBool(false)
      end
      net.WriteUInt(victim:DT_GetDisposition(ply), 3)
      net.Send(ply)
    end
  end

  hook.Add("PlayerDeath", "DT_HUD/SendPlayerDeathToKillfeed", function(ply, _, attacker)
    SendToKillfeed(attacker, ply)
  end)

  hook.Add("OnNPCKilled", "DT_HUD/SendNPCDeathToKillfeed", function(npc, attacker)
    SendToKillfeed(attacker, npc)
  end)

else

  DT_HUD.KillfeedEnabled = DT_Lib.ClientConVar("dt_hud_killfeed", "1")
  DT_HUD.KillfeedMaximum = DT_Lib.ClientConVar("dt_hud_killfeed_maximum", "10")
  DT_HUD.KillfeedDuration = DT_Lib.ClientConVar("dt_hud_killfeed_duration", "10")

  local KILLFEED = {}
  net.Receive("DT_HUD/EntityDeath", function()
    table.insert(KILLFEED, {
      attacker = {
        Name = net.ReadString(),
        IsPlayer = net.ReadBool(),
        Disposition = net.ReadUInt(3)
      },
      victim = {
        Name = net.ReadString(),
        IsPlayer = net.ReadBool(),
        Disposition = net.ReadUInt(3)
      }
    })
    timer.Simple(DT_HUD.KillfeedDuration:GetFloat(), function()
      table.remove(KILLFEED, 1)
    end)
  end)

  hook.Add("DrawDeathNotice", "DT_HUD/HideKillfeed", function()
    if DT_HUD.Enabled:GetBool() and DT_HUD.KillfeedEnabled:GetBool() then
      return false
    end
  end)

  hook.Add("DT_HUD/Paint", "DT_HUD/Killfeed", function()
    if not DT_HUD.KillfeedEnabled:GetBool() then return end

    local ctx = DT_HUD.DrawContext()
    if DT_HUD.RadarAllowed:GetBool() and DT_HUD.RadarEnabled:GetBool() then
      ctx:SetOrigin(-23.5, 3 + 30*DT_HUD.RadarScale:GetFloat())
    else ctx:SetOrigin(-23.5, 1) end

    for i = 1, math.min(#KILLFEED, DT_HUD.KillfeedMaximum:GetInt()) do
      local death = KILLFEED[i]
      ctx:DrawFrame(22, 3, "right")
      ctx:CreateSquare(11, 1.5, 2):Fill(DT_HUD.MainColor.Value, DT_HUD.DeathIcon)
      local attackerColor = DT_HUD.GetDispositionColor(death.attacker.Disposition)
      local attackerText = death.attacker.IsPlayer and death.attacker.Name or language.GetPhrase(death.attacker.Name)
      ctx:DrawText(1, 0.85, attackerText, {color = attackerColor, maxLength = 8.5})
      local victimColor = DT_HUD.GetDispositionColor(death.victim.Disposition)
      local victimText = death.victim.IsPlayer and death.victim.Name or language.GetPhrase(death.victim.Name)
      ctx:DrawText(21, 0.85, victimText, {color = victimColor, maxLength = 8.5, xAlign = TEXT_ALIGN_RIGHT})
      ctx:AddOffset(0, 4)
    end
  end)

end