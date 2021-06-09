return {
	run = function()
		fassert(rawget(_G, "new_mod"), "AimLines must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("AimLines", {
			mod_script       = "scripts/mods/AimLines/AimLines",
			mod_data         = "scripts/mods/AimLines/AimLines_data",
			mod_localization = "scripts/mods/AimLines/AimLines_localization"
		})
	end,
	packages = {
		"resource_packages/AimLines/AimLines"
	}
}
