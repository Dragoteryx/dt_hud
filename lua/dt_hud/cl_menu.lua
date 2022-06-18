hook.Add("AddToolMenuCategories", "DT_HUD/ToolMenu", function()
  spawnmenu.AddToolCategory("Utilities", "dt_hud", "DT HUD")
end)

hook.Add("PopulateToolMenu", "DT_HUD/ToolMenu", function()
  spawnmenu.AddToolMenuOption("Utilities", "dt_hud", "server", "#dt_hud.menu.server", "", "", function(panel)


  end)

  spawnmenu.AddToolMenuOption("Utilities", "dt_hud", "client", "#dt_hud.menu.client", "", "", function(panel)
    local function GetText(placeholder) return language.GetPhrase("dt_hud.menu.client."..placeholder) end

    panel:CheckBox(GetText("enabled"), DT_HUD.Enabled:GetName())

    panel:ControlHelp("\n"..GetText("status"))
    panel:CheckBox(GetText("status.enabled"), DT_HUD.StatusEnabled:GetName())
    panel:CheckBox(GetText("status.misc"), DT_HUD.StatusMiscEnabled:GetName())

    panel:ControlHelp("\n"..GetText("weapons"))
    panel:CheckBox(GetText("weapons.enabled"), DT_HUD.WeaponEnabled:GetName())
    panel:CheckBox(GetText("weapons.reload.enabled"), DT_HUD.WeaponReload:GetName())
    panel:CheckBox(GetText("weapons.reload.crosshair"), DT_HUD.WeaponReloadCrosshair:GetName())

    panel:ControlHelp("\n"..GetText("entity_info"))
    panel:CheckBox(GetText("entity_info.enabled"), DT_HUD.EntityInfoEnabled:GetName())
    panel:CheckBox(GetText("entity_info.above"), DT_HUD.EntityInfoAbove:GetName())

    panel:ControlHelp("\n"..GetText("killfeed"))
    panel:CheckBox(GetText("killfeed.enabled"), DT_HUD.KillfeedEnabled:GetName())
    panel:NumSlider(GetText("killfeed.maximum"), DT_HUD.KillfeedMaximum:GetName(), 1, 10, 0)
    panel:NumSlider(GetText("killfeed.duration"), DT_HUD.KillfeedDuration:GetName(), 1, 60, 0)

    panel:ControlHelp("\n"..GetText("radar"))
    panel:CheckBox(GetText("radar.enabled"), DT_HUD.RadarEnabled:GetName())

    panel:ControlHelp("\n"..GetText("colors"))
    panel:Button(GetText("colors.reset"), "dt_hud_cmd_reset_colors")
    panel:Button(GetText("colors.randomize"), "dt_hud_cmd_randomize_colors")
    DT_HUD.MainColor:AddToPanel(panel)
    DT_HUD.FullHealthColor:AddToPanel(panel)
    DT_HUD.LowHealthColor:AddToPanel(panel)
    DT_HUD.ArmorColor:AddToPanel(panel)
    DT_HUD.PrimaryAmmoColor:AddToPanel(panel)
    DT_HUD.SecondaryAmmoColor:AddToPanel(panel)
    DT_HUD.NeutralColor:AddToPanel(panel)
    DT_HUD.AlliesColor:AddToPanel(panel)
    DT_HUD.EnemiesColor:AddToPanel(panel)
    DT_HUD.VehiclesColor:AddToPanel(panel)
    DT_HUD.WeaponsColor:AddToPanel(panel)
  end)
end)