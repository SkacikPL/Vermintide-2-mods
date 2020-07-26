return {
	run = function()
		fassert(rawget(_G, "new_mod"), "Inhabitants must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("Inhabitants", {
			mod_script       = "scripts/mods/Inhabitants/Inhabitants",
			mod_data         = "scripts/mods/Inhabitants/Inhabitants_data",
			mod_localization = "scripts/mods/Inhabitants/Inhabitants_localization"
		})
	end,
	packages = {
		"resource_packages/Inhabitants/Inhabitants"
	}
}
