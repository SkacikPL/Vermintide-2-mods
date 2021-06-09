local mod = get_mod("FBA")

return {
	name = "Full Body Awareness",
	description = mod:localize("mod_description"),
	is_togglable = true,
	is_mutator = false,
	mutator_settings = {},
	options_widgets = {
		{
			["setting_name"] = "forcefirstperson",
			["widget_type"] = "checkbox",
			["text"] = mod:localize("forcefirstperson_option_name"),
			["tooltip"] = mod:localize("forcefirstperson_option_tooltip"),
			["default_value"] = false
		}
	}
}