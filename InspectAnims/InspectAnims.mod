return {
	run = function()
		fassert(rawget(_G, "new_mod"), "InspectAnims must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("InspectAnims", {
			mod_script       = "scripts/mods/InspectAnims/InspectAnims",
			mod_data         = "scripts/mods/InspectAnims/InspectAnims_data",
			mod_localization = "scripts/mods/InspectAnims/InspectAnims_localization"
		})
	end,
	packages = {
		"resource_packages/InspectAnims/InspectAnims"
	}
}
