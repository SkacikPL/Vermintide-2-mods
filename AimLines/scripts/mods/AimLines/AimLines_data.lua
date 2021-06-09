local mod = get_mod("AimLines")

return {
	name = "Aim Lines",
	description = mod:localize("mod_description"),
	is_togglable = true,
	is_mutator = false,
	mutator_settings = {},
	options_widgets = {
		{
			["setting_name"] = "distance",
			["widget_type"] = "numeric",
			["text"] = mod:localize("distance_option_name"),
			["tooltip"] = mod:localize("distance_option_tooltip"),
            ["range"] = {10, 10000},
			["default_value"] = 100
		},
		{
			["setting_name"] = "opacity",
			["widget_type"] = "numeric",
			["text"] = mod:localize("opacity_option_name"),
			["tooltip"] = mod:localize("opacity_option_tooltip"),
            ["range"] = {1, 255},
			["default_value"] = 75
		},
		{
			["setting_name"] = "rangedonly",
			["widget_type"] = "checkbox",
			["text"] = mod:localize("rangedonly_option_name"),
			["tooltip"] = mod:localize("rangedonly_option_tooltip"),
			["default_value"] = true
		}		
	}
}