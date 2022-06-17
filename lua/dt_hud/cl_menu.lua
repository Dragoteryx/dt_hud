--[[hook.Add("DrG/ToolMenu", "DT_HUD/ToolMenu", function(AddCategory)
  AddCategory("dthud.menu", function(AddSubCategory)
    AddSubCategory("server", nil, function(panel, GetText)
      --
    end)

    AddSubCategory("client", nil, function(panel, GetText)
      panel:ControlHelp("\n"..GetText("colors"))
      panel:Button(GetText("colors.reset"), "dthud_cmd_reset_colors")
      DT_HUD.MainColor:AddToPanel(panel, GetText("colors.main"))
      DT_HUD.FullHealthColor:AddToPanel(panel, GetText("colors.full_health"))
      DT_HUD.LowHealthColor:AddToPanel(panel, GetText("colors.low_health"))
      DT_HUD.ArmorColor:AddToPanel(panel, GetText("colors.armor"))
      DT_HUD.AmmoColor:AddToPanel(panel, GetText("colors.ammo"))
      DT_HUD.Ammo2Color:AddToPanel(panel, GetText("colors.ammo2"))
      DT_HUD.NeutralColor:AddToPanel(panel, GetText("colors.neutral"))
      DT_HUD.AllyColor:AddToPanel(panel, GetText("colors.ally"))
      DT_HUD.EnemyColor:AddToPanel(panel, GetText("colors.enemy"))
      DT_HUD.VehicleColor:AddToPanel(panel, GetText("colors.vehicle"))
      DT_HUD.WeaponColor:AddToPanel(panel, GetText("colors.weapon"))
    end)
  end)
end)]]