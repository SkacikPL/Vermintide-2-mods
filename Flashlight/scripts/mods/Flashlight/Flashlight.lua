local mod = get_mod("Flashlight")
mod.FlashlightEnabled = false
local FlashlightUnit = nil
local FlashlightUnitLight = nil

--[[
	Functions
--]]

local function CleanUpFlashlight(reboot)
	local world = Managers.world:world("level_world")
	
	if Unit.alive(FlashlightUnit) then
		World.destroy_unit(world,FlashlightUnit)
		FlashlightUnit = nil
		FlashlightUnitLight = nil
	end
	
	mod.FlashlightEnabled = false
	if reboot then mod.ToggleFlashlight(true) end
end

local function UpdateFlashlightSettings()
	if FlashlightUnit ~= nil then
		if Unit.alive(FlashlightUnit) then
			Light.set_casts_shadows(FlashlightUnitLight, mod:get("castshadows"))
			Light.set_intensity(FlashlightUnitLight, mod:get("intensity") / 100)
			Light.set_color(FlashlightUnitLight, Vector3(mod:get("red") / 255, mod:get("green") / 255, mod:get("blue") / 255))
			Light.set_falloff_start(FlashlightUnitLight, 0.5 * mod:get("intensity"))
			Light.set_falloff_end(FlashlightUnitLight, 1.2 * mod:get("intensity"))
			if mod:get("flicker") ~= "none" then Light.set_flicker_type(FlashlightUnitLight, mod:get("flicker"))
			local offsetpos = Vector3(mod:get("xoffset") / 10, 0, mod:get("zoffset") / 10)
			Unit.set_local_position(FlashlightUnit,0,offsetpos)			
			else
				CleanUpFlashlight(true)
			end
		end	
	end
end

local function SetupFlashlightUnit()
	local world = Managers.world:world("level_world")
	local first_person_ext = ScriptUnit.extension(Managers.player:local_player().player_unit, "first_person_system")
	local FPU = first_person_ext.get_first_person_unit(first_person_ext)
	local camerabone = Unit.node(FPU, "camera_node")
	FlashlightUnit = World.spawn_unit(world,"units/lights/light",cm)
	FlashlightUnitLight = Unit.light(FlashlightUnit,0)
	
	Light.set_casts_shadows(FlashlightUnitLight, mod:get("castshadows"))
	Light.set_color(FlashlightUnitLight, Vector3(mod:get("red") / 255, mod:get("green") / 255, mod:get("blue") / 255))
	Light.set_type(FlashlightUnitLight, "spot")
	Light.set_intensity(FlashlightUnitLight, mod:get("intensity") / 100)
	Light.set_falloff_start(FlashlightUnitLight, 0.5 * mod:get("intensity"))
	Light.set_falloff_end(FlashlightUnitLight, 1.2 * mod:get("intensity"))
	Light.set_spot_angle_start(FlashlightUnitLight, math.rad(Application.user_setting("render_settings", "fov") / 3))
	Light.set_spot_angle_end(FlashlightUnitLight, math.rad(Application.user_setting("render_settings", "fov")))
	if mod:get("flicker") ~= "none" then Light.set_flicker_type(FlashlightUnitLight, mod:get("flicker")) end	
	
	World.link_unit(world, FlashlightUnit, 0, FPU, camerabone)
	local offsetpos = Vector3(mod:get("xoffset") / 10, 0, mod:get("zoffset") / 10)
	Unit.set_local_position(FlashlightUnit,0,offsetpos)
end

local function PostFPUUpdate(self, unit, input, dt, context, t, ...)
	if FlashlightUnit ~= nil then
		if Unit.alive(FlashlightUnit) and mod.FlashlightEnabled then
			Light.set_enabled(FlashlightUnitLight, self.first_person_mode)
		end
	end
end

function mod.ToggleFlashlight(silent)
	if not Unit.alive(Managers.player:local_player().player_unit) then return end
	
	if FlashlightUnit == nil or not Unit.alive(FlashlightUnit) then
		SetupFlashlightUnit()
	end
	
	if not silent then
		local world = Managers.world:world("level_world")
		local wwise_world = Managers.world:wwise_world(world) 
		wwise_world:trigger_event("hud_chat_message", Managers.player:local_player().player_unit)	
	end
	
	if mod.FlashlightEnabled then
		Light.set_enabled(FlashlightUnitLight,false)
	else
		Light.set_enabled(FlashlightUnitLight,true)
	end
	
	mod.FlashlightEnabled = not mod.FlashlightEnabled
end


--[[
	Hooks
--]]

mod:hook_safe(PlayerUnitFirstPerson, "update", function (self, unit, input, dt, context, t, ...)
	PostFPUUpdate(self, unit, input, dt, context, t, ...)
end)

mod:hook(BulldozerPlayer, "despawn", function (func, self, ...)
	if self == Managers.player:local_player() then
		CleanUpFlashlight()
	end

	for mood, _ in pairs(MoodSettings) do
		MOOD_BLACKBOARD[mood] = false
	end

	Managers.state.camera:set_additional_fov_multiplier(1)

	local first_person_extension = ScriptUnit.has_extension(self.player_unit, "first_person_system")

	if first_person_extension then
		first_person_extension:play_hud_sound_event("Stop_ability_loop_turn_off")
	end

	local player_unit = self.player_unit

	if Unit.alive(player_unit) then
		REMOVE_PLAYER_UNIT_FROM_LISTS(player_unit)
		Managers.state.unit_spawner:mark_for_deletion(player_unit)
	else
		print("bulldozer_player was already despanwed. Should not happen.")
	end
end)


--[[
	Callbacks
--]]

mod.on_unload = function(exit_game)
	if Managers.player then
		if Unit.alive(Managers.player:local_player().player_unit) then
			if FlashlightUnit ~= nil then
				CleanUpFlashlight()
			end
		end
	end	
end

mod.on_game_state_changed = function(status, state)
	if state == "StateIngame" then CleanUpFlashlight() end
end

mod.on_setting_changed = function(setting_name)
	UpdateFlashlightSettings()
end

mod.on_disabled = function(is_first_call)
	if Managers.player then
		if Unit.alive(Managers.player:local_player().player_unit) then
			if FlashlightUnit ~= nil then
				CleanUpFlashlight()
			end
		end
	end
end
