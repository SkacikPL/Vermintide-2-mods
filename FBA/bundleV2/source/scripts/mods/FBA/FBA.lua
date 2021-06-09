local mod = get_mod("FBA")
local tpe = get_mod("ThirdPersonEquipment") --Compatibility with Third Person Equipment mod to also show equipment on local player while in "FPP".
local TPEFound = tpe ~= nil --Quick bool.

--[[
	Functions
--]]

local function UpdateTPEVsibilities() --Toggle shadows on third person equipment units.
	local player = Managers.player:local_player().player_unit
	local first_person_ext = ScriptUnit.extension(player, "first_person_system")

	if first_person_ext.first_person_mode then 
		tpe.current.firstperson = false
		tpe:set_equipment_visibility(first_person_ext.unit, false)
		
		if tpe.current.equipment[first_person_ext.unit] ~= nil then
			for _, equip in pairs(tpe.current.equipment[first_person_ext.unit]) do
				if equip.right ~= nil then
					local num_meshes = Unit.num_meshes(equip.right)

					for i = 0, num_meshes - 1, 1 do
						Unit.set_mesh_visibility(equip.right, i, false, "shadow_caster")
					end
				end
				if equip.left ~= nil then
					local num_meshes = Unit.num_meshes(equip.left)

					for i = 0, num_meshes - 1, 1 do
						Unit.set_mesh_visibility(equip.left, i, false, "shadow_caster")
					end
				end					
			end
		end
	else
		if tpe.current.equipment[first_person_ext.unit] ~= nil then
			for _, equip in pairs(tpe.current.equipment[first_person_ext.unit]) do
				if equip.right ~= nil then
					local num_meshes = Unit.num_meshes(equip.right)

					for i = 0, num_meshes - 1, 1 do
						Unit.set_mesh_visibility(equip.right, i, true, "shadow_caster")
					end
				end
				if equip.left ~= nil then
					local num_meshes = Unit.num_meshes(equip.left)

					for i = 0, num_meshes - 1, 1 do
						Unit.set_mesh_visibility(equip.left, i, true, "shadow_caster")
					end
				end					
			end
		end				
	end
end

local function PostFPUUpdate(self, unit, input, dt, context, t, ...) --Stuff called after First Person Unit update, set scale of 3p hands/head while in 1p.
	local player = Managers.player:owner(self.unit).player_unit
	local status_extension = ScriptUnit.extension(player, "status_system")
	
	if self.first_person_mode then
		local head = Unit.node(player, "j_head")
		local lefthand = Unit.node(player, "j_leftarm")
		local righthand = Unit.node(player, "j_rightarm")
		
		if status_extension.on_ladder then
			Unit.set_local_scale(player,lefthand, Vector3(1,1,1))
			Unit.set_local_scale(player,righthand, Vector3(1,1,1))
		else
			Unit.set_local_scale(player,lefthand, Vector3(0,0,0))
			Unit.set_local_scale(player,righthand, Vector3(0,0,0))
		end
		Unit.set_local_scale(player,head, Vector3(0,0,0))
	end
end

local function PostFadeUpdate(self, context, t, ...) --Stuff called after Fade System update, force local player to be NOT faded.
	local player = Managers.player:local_player().player_unit
	
	if Unit.alive(player) then
		local first_person_ext = ScriptUnit.extension(player, "first_person_system")
		local status_extension = ScriptUnit.extension(player, "status_system")
		
		if first_person_ext.first_person_mode or status_extension:is_disabled() then
			Unit.set_scalar_for_materials_in_unit_and_childs(player, "inv_jitter_alpha", 0)
		end
	end
end

local function PostPlayerSpawn(self, optional_position, optional_rotation, is_initial_spawn, ammo_melee, ammo_ranged, healthkit, potion, grenade, ...) --Stuff called after local player spawn, hack for keep spawning.
	if self == Managers.player:local_player() then
		local first_person_ext = ScriptUnit.extension(self.player_unit, "first_person_system")
		first_person_ext:set_first_person_mode(true)
	end
end

LocomotionTemplates.PlayerUnitLocomotionExtension.update_rotation = function (data, t, dt) --Override to instantly match 3p unit rotation with current look at direction.
 	local is_server = Managers.player.is_server
	local Unit_set_local_rotation = Unit.set_local_rotation
	local Quaternion_lerp = Quaternion.lerp
	local Quaternion_look = Quaternion.look
	local Quaternion_forward = Quaternion.forward
	local math_smoothstep = math.smoothstep
	local Vector3_normalize = Vector3.normalize
	local Vector3_flat = Vector3.flat
	local Vector3_dot = Vector3.dot

	for unit, extension in pairs(data.all_update_units) do
		if not extension.disable_rotation_update then
			if extension.rotate_along_direction then
				local first_person_extension = extension.first_person_extension
				local current_rotation = first_person_extension:current_rotation()
				local current_rotation_flat = Vector3_flat(Quaternion_forward(current_rotation))
				local velocity_current = extension.velocity_current:unbox()
				velocity_current.z = 0
				local velocity_dot = Vector3_dot(velocity_current, current_rotation_flat)

				if velocity_dot == 0 then
					local current_rotation_normalised = Vector3_normalize(current_rotation_flat)
					local target_rotation = extension.target_rotation:unbox()
					local target_rotation_flat = Vector3_flat(Quaternion_forward(target_rotation))
					local target_rotation_normalised = Vector3_normalize(target_rotation_flat)
					local dot = Vector3_dot(current_rotation_normalised, target_rotation_normalised)

					if dot < 0 then
						extension.target_rotation:store(current_rotation)
					end

					velocity_current = target_rotation_flat
				else
					extension.target_rotation:store(current_rotation)
				end

				if velocity_dot < -0.1 then
					velocity_current = -velocity_current
				end

				local final_rotation = Quaternion_look(velocity_current)
				
				local yaw = Quaternion.yaw(current_rotation)
				local yaw_rotation = Quaternion(Vector3.up(), yaw)				
				
				local first_person_ext = ScriptUnit.extension(unit, "first_person_system")
				
				if first_person_ext.first_person_mode then
					Unit.set_local_rotation(unit, 0, yaw_rotation)
				else
					Unit.set_local_rotation(unit, 0, Quaternion_lerp(Unit.local_rotation(unit, 0), final_rotation, dt * 5))
				end

			elseif extension.target_rotation_data then
				local target_rotation_data = extension.target_rotation_data
				local start_rotation = target_rotation_data.start_rotation:unbox()
				local target_rotation = target_rotation_data.target_rotation:unbox()
				local start_time = target_rotation_data.start_time
				local end_time = target_rotation_data.end_time
				local lerp_t = math_smoothstep(t, start_time, end_time)

				Unit_set_local_rotation(unit, 0, Quaternion_lerp(start_rotation, target_rotation, lerp_t))
			end
		end

		if is_server then
			local current_position = Unit.world_position(unit, 0)
			local found_nav_mesh, z = GwNavQueries.triangle_from_position(extension._nav_world, current_position, 0.1, 0.3, extension._nav_traverse_logic)

			if found_nav_mesh then
				extension._latest_position_on_navmesh:store(Vector3(current_position.x, current_position.y, current_position.z))
			end
		end

		extension.disable_rotation_update = false
	end
end

--[[
	Hooks
--]]

mod:hook(PlayerCharacterStateInspecting, "on_enter", function (func, self, unit, input, dt, context, t, previous_state, params, ...) --Call to set fpp mode and camera state needed to be ordered AFTER inspection state is set.
	self.locomotion_extension:set_wanted_velocity(Vector3.zero())
	CharacterStateHelper.stop_weapon_actions(self.inventory_extension, "inspecting")
	CharacterStateHelper.stop_career_abilities(self.career_extension, "inspecting")
	CharacterStateHelper.play_animation_event(unit, "idle")
	CharacterStateHelper.play_animation_event_first_person(self.first_person_extension, "idle")
	self.status_extension:set_inspecting(true)
	self.first_person_extension:set_first_person_mode(false)
	CharacterStateHelper.change_camera_state(self.player, "follow_third_person")
end)

mod:hook(CharacterStateHelper, "change_camera_state", function (func, player, state, params, ...) --Ditto.

	local status_extension = ScriptUnit.extension(player.player_unit, "status_system")

	if player.bot_player or mod:get("forcefirstperson") and state ~= "follow" and not (status_extension:is_inspecting() and state == "follow_third_person") then
		return
	end

	if Development.parameter("third_person_mode") and state == "follow" then
		state = "follow_third_person_over_shoulder"
	end

	local entity_manager = Managers.state.entity
	local camera_system = entity_manager:system("camera_system")

	camera_system:external_state_change(player, state, params)

end)

mod:hook(PlayerUnitFirstPerson, "calculate_look_rotation", function (func, self, current_rotation, look_delta, ...) --Override to lock yaw and limit pitch on ladders.
	local player = Managers.player:owner(self.unit).player_unit
	local status_extension = ScriptUnit.extension(player, "status_system")
	
	local yaw = Quaternion.yaw(current_rotation) - look_delta.x

	if self.restrict_rotation_angle then
		yaw = math.clamp(yaw, -self.restrict_rotation_angle, self.restrict_rotation_angle)
	end
	
	local pitch = math.clamp(Quaternion.pitch(current_rotation) + look_delta.y, -self.MAX_MIN_PITCH, self.MAX_MIN_PITCH)
	
	if status_extension.on_ladder then
		yaw = Quaternion.yaw(Unit.world_rotation(player, 0))
		pitch = math.clamp(pitch, -self.MAX_MIN_PITCH * 0.8, self.MAX_MIN_PITCH)
	end	
	local yaw_rotation = Quaternion(Vector3.up(), yaw)
	local pitch_rotation = Quaternion(Vector3.right(), pitch)
	local look_rotation = Quaternion.multiply(yaw_rotation, pitch_rotation)

	return look_rotation
end)

mod:hook(PlayerUnitFirstPerson, "update_rotation", function (func, self, t, dt, ...) --Forced look direction for disabled states.
	local first_person_unit = self.first_person_unit
	
	local player = Managers.player:owner(self.unit).player_unit
	local status_extension = ScriptUnit.extension(player, "status_system")
	
	if mod:get("forcefirstperson") then
	
		if status_extension:is_disabled() then
			local headbone = Unit.node(player, "j_neck")
			local look_rotation = Unit.world_rotation(player, headbone)
			
			local disabler = status_extension.get_disabler_unit(status_extension)
		
			if disabler ~= nil then
				local neck_bone = Unit.node(disabler, "j_spine1")
				local disablerrot = Unit.world_rotation(disabler,0)
				local disablerpos = Unit.world_position(disabler,neck_bone)
				local rot = Quaternion.look(-Quaternion.forward(disablerrot), Vector3.up())
				local player = Managers.player:local_player()
				local viewport_name = player.viewport_name
				local viewport = ScriptWorld.viewport(self.world, viewport_name)
				local camera = ScriptViewport.camera(viewport)
				local camera_position = ScriptCamera.position(camera)		
			
				local offset = disablerpos - camera_position
				local look_rot = Quaternion.look(offset, Vector3.up())

				self.forced_look_rotation = QuaternionBox(look_rot)
				self.forced_lerp_timer = 0			
			end	
			
			if status_extension:get_is_ledge_hanging() then
				local ledge_unit = status_extension.current_ledge_hanging_unit
				local disablerrot = Unit.world_rotation(ledge_unit,0)
				local disablerpos = Unit.world_position(ledge_unit,0)
				local rot = Quaternion.look(Quaternion.forward(disablerrot), Vector3.up())
				local player = Managers.player:local_player()
				local viewport_name = player.viewport_name
				local viewport = ScriptWorld.viewport(self.world, viewport_name)
				local camera = ScriptViewport.camera(viewport)
				local camera_position = ScriptCamera.position(camera)		
			
				local offset = camera_position - disablerpos
				local look_rot = Quaternion.look(offset, Vector3.up())
			
				self.forced_look_rotation = QuaternionBox(rot)
				self.forced_lerp_timer = 0
			end
		end
	end
	
	local aim_assist_data = self.smart_targeting_extension:get_targeting_data()

	if self.forced_look_rotation ~= nil then
		local total_lerp_time = self.forced_total_lerp_time or 0.3
		self.forced_lerp_timer = self.forced_lerp_timer + dt
		local p = 1 - self.forced_lerp_timer / total_lerp_time
		p = 1 - p * p
		local look_rotation = Quaternion.lerp(self.look_rotation:unbox(), self.forced_look_rotation:unbox(), p)
		local yaw = Quaternion.yaw(look_rotation)
		local pitch = math.clamp(Quaternion.pitch(look_rotation), -self.MAX_MIN_PITCH, self.MAX_MIN_PITCH)
		local roll = Quaternion.roll(look_rotation)
		local yaw_rotation = Quaternion(Vector3.up(), yaw)
		local pitch_rotation = Quaternion(Vector3.right(), pitch)
		local roll_rotation = Quaternion(Vector3.forward(), roll)
		local yaw_pitch_rotation = Quaternion.multiply(yaw_rotation, pitch_rotation)
		look_rotation = Quaternion.multiply(yaw_pitch_rotation, roll_rotation)

		self.look_rotation:store(look_rotation)

		local first_person_unit = self.first_person_unit

		Unit.set_local_rotation(first_person_unit, 0, look_rotation)

		if total_lerp_time <= self.forced_lerp_timer then
			self.look_delta = nil
			self.forced_look_rotation = nil
			self.forced_lerp_time = nil
		end
	elseif self.look_delta ~= nil then
		local aim_assist_unit = aim_assist_data.unit
		local rotation = self.look_rotation:unbox()
		local look_delta = self.look_delta
		self.look_delta = nil
		local look_rotation = self:calculate_look_rotation(rotation, look_delta)

		if aim_assist_unit and Managers.input:is_device_active("gamepad") then
			look_rotation = self:calculate_aim_assisted_rotation(look_rotation, aim_assist_data, look_delta, dt)
		end

		self.look_rotation:store(look_rotation)

		local first_person_unit = self.first_person_unit
		local is_recoiling, recoil_offset = Managers.state.camera:is_recoiling()

		if is_recoiling and recoil_offset then
			local current_rotation = look_rotation
			local final_rotation = Quaternion.multiply(look_rotation, recoil_offset:unbox())
			look_rotation = final_rotation
		end

		Unit.set_local_rotation(first_person_unit, 0, look_rotation)
		self:update_rig_movement(look_delta)
	end

end)

mod:hook(PlayerUnitFirstPerson, "update_position", function (func, self, ...) --Attach camera to neck of 3p body with some slight forward/upward offset.

	local player = Managers.player:owner(self.unit).player_unit
	local headbone = Unit.node(player, "j_neck")
	local position_root = Unit.world_position(player, headbone)
	local forward = Quaternion.forward(Unit.world_rotation(player, headbone))
	local up = Quaternion.right(Unit.world_rotation(player, headbone))
	local position = position_root + (forward * 0.2) + (up * 0.2)

	Unit.set_local_position(self.first_person_unit, 0, position)

end)

mod:hook(PlayerCharacterStateLedgeHanging, "on_enter", function (func, self, unit, input, dt, context, t, previous_state, params, ...) --Reordered call to set camera.
	local unit = self.unit
	local ledge_unit = params.ledge_unit
	self.ledge_unit = ledge_unit

	CharacterStateHelper.stop_weapon_actions(self.inventory_extension, "ledge_hanging")
	CharacterStateHelper.stop_career_abilities(self.career_extension, "ledge_hanging")
	self.locomotion_extension:enable_script_driven_ladder_movement()
	self.locomotion_extension:set_forced_velocity(Vector3:zero())

	local movement_settings_table = PlayerUnitMovementSettings.get_movement_settings_table(unit)
	self.fall_down_time = t + movement_settings_table.ledge_hanging.time_until_fall_down

	self:calculate_and_start_rotation_to_ledge()
	self:calculate_start_position()
	self:calculate_offset_rotation()
	self:on_enter_animation()
	CharacterStateHelper.set_is_on_ledge(self.ledge_unit, unit, true, self.is_server, self.status_extension)
	self:change_to_third_person_camera()
end)

mod:hook(PlayerUnitFirstPerson, "set_first_person_mode", function (func, self, active, override, ...) --Always show 3p body and ignore 3p calls if option for it is enabled.
	local player = Managers.player:owner(self.unit).player_unit
	local status_extension = ScriptUnit.extension(player, "status_system")
	
	if mod:get("forcefirstperson") and active == false and not (status_extension:is_inspecting() or not Managers.state.entity:system("cutscene_system").ingame_hud_enabled) then
		if status_extension:is_disabled() then 
		
			Unit.set_unit_visibility(self.unit, not active)

			for k, v in pairs(self.flow_unit_attachments) do
				Unit.set_unit_visibility(v, not active)
			end

			if not self.tutorial_first_person then
				Unit.set_unit_visibility(self.first_person_attachment_unit, active)
			end		
			self:hide_weapons("third_person_mode", true)

			if self.first_person_mode ~= active then
				Unit.flow_event(self.unit, "lua_enter_third_person_camera")
			end		
		end	
	
			self.first_person_mode = active
			self._show_first_person_units = active		
		return
	end

	if not self.debug_first_person_mode and (override or not Development.parameter("third_person_mode") or not Development.parameter("attract_mode")) then
		Unit.set_unit_visibility(self.unit, not active)

		for k, v in pairs(self.flow_unit_attachments) do
			Unit.set_unit_visibility(v, not active)
		end

		if not self.tutorial_first_person then
			Unit.set_unit_visibility(self.first_person_attachment_unit, active)
		end

		if active then
			self:unhide_weapons("third_person_mode")

			if self.first_person_mode ~= active then
				Unit.flow_event(self.unit, "lua_exit_third_person_camera")
			end
		else
			self:hide_weapons("third_person_mode", true)

			if self.first_person_mode ~= active then
				Unit.flow_event(self.unit, "lua_enter_third_person_camera")
			end
		end

		self.inventory_extension:show_third_person_inventory(not active)
		self.attachment_extension:show_attachments(not active)
	end
	
	Unit.set_unit_visibility(player, true)
	local num_meshes = Unit.num_meshes(player)

	for i = 0, num_meshes - 1, 1 do
		Unit.set_mesh_visibility(player, i, not active, "shadow_caster")
	end
	
	if not active then
		local head = Unit.node(player, "j_head")
		local lefthand = Unit.node(player, "j_leftarm")
		local righthand = Unit.node(player, "j_rightarm")
		
		Unit.set_local_scale(player,lefthand, Vector3(1,1,1))
		Unit.set_local_scale(player,righthand, Vector3(1,1,1))
		Unit.set_local_scale(player,head, Vector3(1,1,1))
	end	

	self:abort_toggle_visibility_timer()
	self:abort_first_person_units_visibility_timer()

	self.first_person_mode = active
	self._show_first_person_units = active
	
end)


mod:hook_safe(PlayerUnitFirstPerson, "update", function (self, unit, input, dt, context, t, ...)
	PostFPUUpdate(self, unit, input, dt, context, t, ...)
end)

mod:hook_safe(FadeSystem, "update", function (self, context, t, ...)
	PostFadeUpdate(self, context, t, ...)
end)

mod:hook_safe(BulldozerPlayer, "spawn", function (self, optional_position, optional_rotation, is_initial_spawn, ammo_melee, ammo_ranged, healthkit, potion, grenade, ...)
	PostPlayerSpawn(self, optional_position, optional_rotation, is_initial_spawn, ammo_melee, ammo_ranged, healthkit, potion, grenade, ...)
end)

mod:hook_safe(SimpleInventoryExtension, "wield", function (self, slot_name, ...)
	if TPEFound then UpdateTPEVsibilities() end
end)


--[[
	Callbacks
--]]

mod.on_disabled = function(is_first_call) --Call again to return to default state.
	if Managers.player ~= nil then
		if Unit.alive(Managers.player:local_player().player_unit) then
			local player = Managers.player:local_player().player_unit
			local first_person_extension = ScriptUnit.extension(player, "first_person_system")
			
			local head = Unit.node(player, "j_head")
			local lefthand = Unit.node(player, "j_leftarm")
			local righthand = Unit.node(player, "j_rightarm")
			
			Unit.set_local_scale(player,lefthand, Vector3(1,1,1))
			Unit.set_local_scale(player,righthand, Vector3(1,1,1))		
			Unit.set_local_scale(player,head, Vector3(1,1,1))		
			
			if first_person_extension ~= nil then
				first_person_extension:set_first_person_mode(first_person_extension.first_person_mode)
			end
		end
	end
end

mod.on_enabled = function(is_first_call) --Call again to apply modded state.
	if not is_first_call then
		if Unit.alive(Managers.player:local_player().player_unit) then
			local first_person_extension = ScriptUnit.extension(Managers.player:local_player().player_unit, "first_person_system")
			
			if first_person_extension ~= nil then
				first_person_extension:set_first_person_mode(first_person_extension.first_person_mode)
			end
		end
	end
end