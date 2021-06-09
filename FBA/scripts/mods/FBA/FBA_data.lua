local mod = get_mod("FBA")

return {
	name = "Full Body Awareness",
	description = mod:localize("mod_description"),
	is_togglable = true,
	is_mutator = false,
	mutator_settings = {},
	options ={
		collapsed_widgets = {},
		widgets = {
			{
				setting_id      = "forcefirstperson",
				type          = "checkbox",
				default_value = false,		
				title = "forcefirstperson_option_name",
				tooltip = "forcefirstperson_option_tooltip",
			}
		}
	}
}