local mod = get_mod("Flashlight")

return {
	name = "Flashlight",
	description = mod:localize("mod_description"),
	is_togglable = true,
	is_mutator = false,
	mutator_settings = {},
	options = {
    collapsed_widgets = {
      "flashlightproperties",
	},	
		widgets = {
--		  {
--			setting_id    = "automatic",
--			type          = "checkbox",
--			default_value = true,
--		  },
		  {
			  setting_id      = "hotkey",
			  type            = "keybind",
			  default_value   = { },
			  keybind_global  = false,
			  keybind_trigger = "pressed",
			  keybind_type    = "function_call",
			  function_name   = "ToggleFlashlight",
		  },
			{
			  setting_id  = "flashlightproperties",
			  type        = "group",
			  sub_widgets = { 
			{
				  setting_id    = "castshadows",
					type          = "checkbox",
					default_value = false,
				},
				{
				  setting_id      = "intensity",
				  type            = "numeric",
				  default_value   = 10,
				  range           = {0, 100},
				},
				{
				  setting_id      = "red",
				  type            = "numeric",
				  default_value   = 233,
				  range           = {0, 255},
				},
				{
				  setting_id      = "green",
				  type            = "numeric",
				  default_value   = 233,
				  range           = {0, 255},
				},
				{
				  setting_id      = "blue",
				  type            = "numeric",
				  default_value   = 233,
				  range           = {0, 255},
				},
				{
				  setting_id    = "flicker",
				  type          = "dropdown",
				  default_value = "none",
				  options = {
					{text = "flicker_none",   value = "none"},
					{text = "flicker_default",   value = "default"},
					{text = "flicker_default2", value = "default2"},
					{text = "flicker_torch01",  value = "torch01"},
					{text = "flicker_torch02",  value = "torch02"},
					{text = "flicker_ambienttorch01",  value = "ambient_torch01"},
					{text = "flicker_firebigintense",  value = "fire_big_intense"},
					{text = "flicker_firebigcalm",  value = "fire_big_calm"},
					{text = "flicker_firesmallintense",  value = "fire_small_intense"},
					{text = "flicker_firesmallcalm",  value = "fire_small_calm"},
				  },
				},
				{
				  setting_id      = "xoffset",
				  type            = "numeric",
				  default_value   = 0,
				  range           = {-10, 10},
				},
				{
				  setting_id      = "zoffset",
				  type            = "numeric",
				  default_value   = 0,
				  range           = {-10, 10},
				},				
			  }
			},		  			
		},
	},
}