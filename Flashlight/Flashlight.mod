return {
	run = function()
		fassert(rawget(_G, "new_mod"), "Flashlight must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("Flashlight", {
			mod_script       = "scripts/mods/Flashlight/Flashlight",
			mod_data         = "scripts/mods/Flashlight/Flashlight_data",
			mod_localization = "scripts/mods/Flashlight/Flashlight_localization"
		})
	end,
	packages = {
		"resource_packages/Flashlight/Flashlight"
	}
}
