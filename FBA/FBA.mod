return {
	run = function()
		fassert(rawget(_G, "new_mod"), "FBA must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("FBA", {
			mod_script       = "scripts/mods/FBA/FBA",
			mod_data         = "scripts/mods/FBA/FBA_data",
			mod_localization = "scripts/mods/FBA/FBA_localization"
		})
	end,
	packages = {
		"resource_packages/FBA/FBA"
	}
}
