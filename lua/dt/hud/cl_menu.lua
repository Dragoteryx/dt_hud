hook.Add("AddToolMenuCategories", "DT/Hud.ToolMenu", function()
	spawnmenu.AddToolCategory("Utilities", "dt_hud", "DT Hud")
end)

hook.Add("PopulateToolMenu", "DT/Hud.ToolMenu", function()
	spawnmenu.AddToolMenuOption("Utilities", "dt_hud", "server", "#dt_hud.menu.server", "", "", function(panel)
		local function GetText(placeholder) return language.GetPhrase("dt_hud.menu.server." .. placeholder) end

	end)

	spawnmenu.AddToolMenuOption("Utilities", "dt_hud", "client", "#dt_hud.menu.client", "", "", function(panel)
		local function GetText(placeholder) return language.GetPhrase("dt_hud.menu.client." .. placeholder) end

		panel:ControlHelp("\n" .. GetText("misc"))
		panel:CheckBox(GetText("misc.enabled"), DT_Hud.Enabled:GetName())
		panel:CheckBox(GetText("misc.hide_zoom"), DT_Hud.HideZoom:GetName())
		panel:CheckBox(GetText("misc.hide_poison"), DT_Hud.HidePoison:GetName())
		panel:CheckBox(GetText("misc.hide_crosshair"), DT_Hud.HideCrosshair:GetName())
		panel:CheckBox(GetText("misc.notifications"), DT_Hud.Notifications:GetName())
		panel:NumSlider(GetText("misc.scale"), DT_Hud.Scale:GetName(), 1, 2, 1)
		panel:NumSlider(GetText("misc.blur_quality"), DT_Hud.BlurQuality:GetName(), 0, 3, 0)

		local combo = panel:ComboBox(GetText("misc.measuring_system"), DT_Hud.MeasuringSystem:GetName())
		combo:AddChoice(GetText("misc.measuring_system.metric"), "metric")
		combo:AddChoice(GetText("misc.measuring_system.imperial"), "imperial")
		combo:AddChoice(GetText("misc.measuring_system.hammer"), "hammer")

		panel:ControlHelp("\n" .. GetText("status"))
		panel:CheckBox(GetText("status.enabled"), DT_Hud.StatusEnabled:GetName())
		panel:CheckBox(GetText("status.statistics"), DT_Hud.StatusStatistics:GetName())
		panel:CheckBox(GetText("status.statistics.speed"), DT_Hud.StatusStatisticsSpeed:GetName())
		panel:CheckBox(GetText("status.statistics.framerate"), DT_Hud.StatusStatisticsFramerate:GetName())
		panel:CheckBox(GetText("status.statistics.latency"), DT_Hud.StatusStatisticsLatency:GetName())

		--[[panel:ControlHelp("\n" .. GetText("weapons"))
		panel:CheckBox(GetText("weapons.enabled"), DT_Hud.WeaponEnabled:GetName())
		panel:CheckBox(GetText("weapons.reload.enabled"), DT_Hud.WeaponReloadEnabled:GetName())
		panel:CheckBox(GetText("weapons.reload.crosshair"), DT_Hud.WeaponReloadCrosshair:GetName())]]

		--[[panel:ControlHelp("\n" .. GetText("entity_info"))
		panel:CheckBox(GetText("entity_info.enabled"), DT_Hud.EntityInfoEnabled:GetName())
		panel:CheckBox(GetText("entity_info.above"), DT_Hud.EntityInfoAbove:GetName())]]

		panel:ControlHelp("\n" .. GetText("compass"))
		panel:CheckBox(GetText("compass.enabled"), DT_Hud.CompassEnabled:GetName())
		panel:CheckBox(GetText("compass.last_death"), DT_Hud.CompassLastDeath:GetName())

		panel:ControlHelp("\n" .. GetText("killfeed"))
		panel:CheckBox(GetText("killfeed.enabled"), DT_Hud.KillfeedEnabled:GetName())
		panel:NumSlider(GetText("killfeed.maximum"), DT_Hud.KillfeedMaximum:GetName(), 1, 20, 0)
		panel:NumSlider(GetText("killfeed.duration"), DT_Hud.KillfeedDuration:GetName(), 1, 60, 0)
		panel:Button(GetText("killfeed.clear"), "dt_hud_cmd_clear_killfeed")

		--[[panel:ControlHelp("\n" .. GetText("radar"))
		panel:CheckBox(GetText("radar.enabled"), DT_Hud.RadarEnabled:GetName())]]

		panel:ControlHelp("\n" .. GetText("colors"))
		panel:Button(GetText("colors.reset"), "dt_hud_cmd_reset_colors")
		panel:Button(GetText("colors.randomize"), "dt_hud_cmd_randomize_colors")
		panel:NumSlider(GetText("colors.opacity"), DT_Hud.BackgroundColor.Alpha:GetName(), 0, 255, 0)
		DT_Hud.MainColor:AddToPanel(panel)
		DT_Hud.BackgroundColor:AddToPanel(panel)
		DT_Hud.HealthColor:AddToPanel(panel)
		DT_Hud.ArmorColor:AddToPanel(panel)
		DT_Hud.PrimaryAmmoColor:AddToPanel(panel)
		DT_Hud.SecondaryAmmoColor:AddToPanel(panel)
		DT_Hud.NeutralColor:AddToPanel(panel)
		DT_Hud.AlliesColor:AddToPanel(panel)
		DT_Hud.EnemiesColor:AddToPanel(panel)
	end)
end)