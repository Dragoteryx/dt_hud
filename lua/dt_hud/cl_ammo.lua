DT_HUD.AmmoEnabled = DT_Lib.ClientConVar("dt_hud_ammo", "1")
DT_HUD.WeaponReload = DT_Lib.ClientConVar("dt_hud_weapon_reload", "1")
DT_HUD.WeaponReloadCrosshair = DT_Lib.ClientConVar("dt_hud_weapon_reload_crosshair", "1")

hook.Add("DT_HUD/ShouldDraw", "DT_HUD/HideAmmo", function(name)
  if not DT_HUD.AmmoEnabled:GetBool() then return end
  if name == "CHudAmmo" or name == "CHudSecondaryAmmo" then return false end
end)

hook.Add("DT_HUD/Paint", "DT_HUD/Ammo", function()
  if not DT_HUD.AmmoEnabled:GetBool() then return end
  local ply = LocalPlayer()
  if not ply:Alive() then return end
  if ply:InVehicle() then return end
  local weap = ply:GetActiveWeapon()
  if not IsValid(weap) then return end

  local ctx = DT_HUD.DrawContext()
  ctx:SetOrigin(-23.5, -12)
  ctx:DrawFrame(22, 11, "right")

  ctx:DrawText(1, 0.635, weap:GetPrintName(), {maxLength = 20})
  ctx:DrawLine(0, 2.5, 22, 2.5, DT_HUD.Border)

  for i = 1, 2 do
    local pieX, pieY, pieR, textX, textY
    local ammo, clipsize, ammoType, color
    if i == 1 then
      pieX, pieY, pieR = 4, 6.75, 3
      textX, textY = 8, 3.5
      ammo = weap:Clip1()
      clipsize = weap:GetMaxClip1()
      ammoType = weap:GetPrimaryAmmoType()
      color = DT_HUD.AmmoColor.Value
    else
      pieX, pieY, pieR = 10, 8, 2
      textX, textY = 13, 6.5
      ammo = weap:Clip2()
      clipsize = weap:GetMaxClip2()
      ammoType = weap:GetSecondaryAmmoType()
      color = DT_HUD.Ammo2Color.Value
    end

    local ammoCount = ply:GetAmmoCount(ammoType)
    if clipsize > 0 then
      ctx:DrawText(textX, textY, ammo.." / "..clipsize.." | "..ammoCount, {color = color})
      ctx:DrawPie(pieX, pieY, {
        radius = pieR,
        value = ammo, max = clipsize,
        color = color
      })
    elseif ammoType ~= -1 then
      ctx:DrawText(textX, textY, ammoCount.." remaining", {color = color})
      local hex = ctx:CreateHexagon(pieX, pieY, pieR)
      if ammoCount <= 0 then
        hex:Fill(DT_HUD.Background)
        hex:Stroke(DT_HUD.Border)
      else hex:Fill(color) end
    elseif i == 1 then
      ctx:DrawText(4, 6.5, "∞", {
        color = color, font = "DT_HUD/Humongous",
        xAlign = TEXT_ALIGN_CENTER,
        yAlign = TEXT_ALIGN_CENTER
      })
    end
  end

  local vm = ply:GetViewModel()
  if IsValid(vm) and DT_HUD.WeaponReload:GetBool()
  and weap:GetClass() ~= "weapon_physcannon" then
    local seq = vm:GetSequence()
    local act = vm:GetSequenceActivity(seq)
    local name = string.lower(vm:GetSequenceName(seq))
    if act == ACT_VM_RELOAD or string.find(name, "reload") then
      local cycle = math.Round(vm:GetCycle(), 2)
      if cycle == 1 then return end
      local outerRadius = 4
      local innerRadius = 2

      if DT_HUD.WeaponReloadCrosshair:GetBool() then
        ctx:SetOrigin(ctx:GetCenter())
      else
        ctx:SetOrigin(-23.5 - outerRadius - 1, -outerRadius - 1)
        ctx:CreateRing(0, 0, outerRadius, innerRadius, 80)
          :Fill(DT_HUD.Background)
          :Blur(DT_HUD.Blur:GetInt())
          :Stroke(DT_HUD.Border)
      end

      local ring = ctx:CreateRing(0, 0, 0, innerRadius + 0.75, 100)
      ring.OuterCircle = ctx:CreateCirclePiece(0, 0, outerRadius - 0.75, 100, nil, math.Round(100 * cycle), 100)
      ring:Fill(DT_HUD.MainColor.Value)
    end
  end
end)