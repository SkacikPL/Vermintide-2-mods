--[[
 ____  _  _  _   _    __    ____  ____  ____   __    _  _  ____  ___ 
(_  _)( \( )( )_( )  /__\  (  _ \(_  _)(_  _) /__\  ( \( )(_  _)/ __)
 _)(_  )  (  ) _ (  /(__)\  ) _ < _)(_   )(  /(__)\  )  (   )(  \__ \
(____)(_)\_)(_) (_)(__)(__)(____/(____) (__)(__)(__)(_)\_) (__) (___/

SkacikPL - https://www.skacikpl.pl/
--]]

--[[
	Locals
--]]
local mod = get_mod("Inhabitants")

--Store initial data as well as housing some dynamically filled info.
local CharacterData = {
	witch_hunter = {position = Vector3Box(3.71343, -5.16817, 5.17837), rotation = 7, anim = "store_idle"},
	bright_wizard  = {position = Vector3Box(-5.73444, -3.3651, 8.73734), rotation = 5, anim = "store_idle"},
	dwarf_ranger = {position = Vector3Box(-2.52041, 5.39538, 5.02771), rotation = 3.5, anim = "store_idle"},
	wood_elf = {position = Vector3Box(-6.9488, 10.4792, 8.58799), rotation = 4.3, anim = "prologue_stand"},
	empire_soldier = {position = Vector3Box(-5.35476, -2.50643, 5.00663), rotation = 5.2, anim = "store_idle"}
}

--Store spawned unit references and other unit relevant stuff.
local SpawnedUnits = {
	witch_hunter = {},
	bright_wizard = {},
	dwarf_ranger = {},
	wood_elf = {},
	empire_soldier = {}
}

local load_in_progress = false --Triggers checks whether all requested packages finished loading.
local package_names = {} --Queue for packages that required loading by the mod.

--[[
	Functions
--]]
local function UpdateLookats(dt) --Basically find closest player and if he's closer than 3 meters look at him, otherwise stare blankly forward. Also some _potentially_ framerate scaling interpolation for smooth head movement instead of snapping.
	for character,data in pairs(SpawnedUnits) do
		if Unit.alive(data.body) then

			local players = Managers.player:players()
			local closest_player_dist = math.huge
			local headbone = Unit.node(data.body, "j_head")
			local position = Unit.world_position(data.body, headbone)
			local targetposition
			local aim_constraint_anim_var = Unit.animation_find_constraint_target(data.body, "aim_constraint_target")
			
			for id, player in pairs(players) do
				if player.player_unit ~= nil then
					local playerheadbone = Unit.node(player.player_unit, "j_head")
					local player_pos = Unit.world_position(player.player_unit, playerheadbone)
					local distance = Vector3.distance(position, player_pos)
					
					if distance < closest_player_dist then	
						closest_player_dist = distance
						targetposition = player_pos
					end
				end
			end
			
			if closest_player_dist > 3 then
				if data.defaultlookat == nil then
					local offset = Quaternion.forward(Unit.world_rotation(data.body, headbone)) * 3
					data.defaultlookat = Vector3Box(position+offset)
				end
				targetposition = Vector3Box.unbox(data.defaultlookat)
			end
			
			if data.lastlookat ~= nil then targetposition = Vector3.lerp(Vector3Box.unbox(data.lastlookat), targetposition, 3 * dt) end
			
			Unit.animation_set_constraint_target(data.body, aim_constraint_anim_var, targetposition)
			data.lastlookat = Vector3Box(targetposition)
			
		end
	end
end

local function LoadPackages(packages_to_load) --Load passed packages
	local package_manager = Managers.package
	
	for i, name in ipairs(packages_to_load) do
		if not package_manager:has_loaded(name, "Inhabitants") then
			package_manager:load(name, "Inhabitants", nil, true)	
		end
	end

	if not GlobalResources.loaded then
		for i, name in ipairs(GlobalResources) do
			if not package_manager:has_loaded(name) then
				package_manager:load(name, "global", nil, true)
			end		
		end

		GlobalResources.loaded = true
	end		
end

local function CheckSpawnUnspawn() --Triggered every time local/remote player unit is spawned, run a check for existing players and remove/queue spawn NPC units if necessary.
	local players = Managers.player:players()
	local playercharacters = {}
	local world = Managers.world:world("level_world")

	for id, player in pairs(players) do
		if Managers.state.spawn._profile_synchronizer:profile_by_peer(player.peer_id, player._local_player_id) ~= nil then
			local profile = SPProfiles[Managers.state.spawn._profile_synchronizer:profile_by_peer(player.peer_id, player._local_player_id)].display_name
			table.insert(playercharacters, profile)		
			
			if SpawnedUnits[profile] ~= nil then
				if Unit.alive(SpawnedUnits[profile].hat) then 
					World.destroy_unit(world,SpawnedUnits[profile].hat) 
				end
			
				if Unit.alive(SpawnedUnits[profile].body) then 
					Managers.state.unit_spawner.entity_manager:unregister_unit(SpawnedUnits[profile].body)
					POSITION_LOOKUP[SpawnedUnits[profile].body] = nil
					World.destroy_unit(world,SpawnedUnits[profile].body) 
					SpawnedUnits[profile] = {} 
				end
			end
		end
	end
	
	for character,data in pairs(CharacterData) do
		CharacterData[character].shouldspawn = false
		
		local profile_index = FindProfileIndex(character)
		local profile = SPProfiles[profile_index]
		
		if not table.contains(playercharacters, profile.display_name) and #playercharacters ~= 0 and SpawnedUnits[profile.display_name].body == nil then
			local hero_attributes = Managers.backend:get_interface("hero_attributes")
			local career_index = hero_attributes:get(profile.display_name, "career")
			local career = profile.careers[career_index]			
			local career_name = career.name
			local skin_item = BackendUtils.get_loadout_item(career_name, "slot_skin")
			local hat_item = BackendUtils.get_loadout_item(career_name, "slot_hat")
			local item_data = skin_item and skin_item.data
			local hat_item_data = hat_item and hat_item.data
			local skin_name = optional_skin or (item_data and item_data.name) or career.base_skin	
			local hat_name = (hat_item_data and hat_item_data.name) or career.preview_items[2].item_name

			local skin_data = Cosmetics[skin_name]
			local unit_name = skin_data.third_person
			local hat_unit_name = ItemMasterList[hat_name].unit
			local material_changes = skin_data.material_changes
			table.insert(package_names, unit_name)
			table.insert(package_names, hat_unit_name)			

			if material_changes then
				local material_package = material_changes.package_name
				table.insert(package_names, material_package)			
			end
			
			local hat_material_changes = hat_item_data.character_material_changes
			
			if hat_material_changes then
				local material_package = hat_material_changes.package_name
				table.insert(package_names, material_package)
			end			
			
			CharacterData[character].hidehat = false
			
			if skin_data.always_hide_attachment_slots ~= nil then
				for _, slot_name in ipairs(skin_data.always_hide_attachment_slots) do
					if slot_name == "slot_hat" then CharacterData[character].hidehat = true end
				end
			end
			
			CharacterData[character].hatname = hat_name
			CharacterData[character].hat = hat_unit_name
			CharacterData[character].skin_data = skin_data
			CharacterData[character].career_index = 1
			CharacterData[character].shouldspawn = true
			CharacterData[character].name = profile.ingame_short_display_name
		
		end
		
	end	
		LoadPackages(package_names)
		load_in_progress = true
end

local function SpawnNPC(name) --Main function to spawn NPC.
	local skin_data = CharacterData[name].skin_data
	local world = Managers.world:world("level_world")
	local unit_name = skin_data.third_person
	local tint_data = skin_data.color_tint
	local character_unit = Managers.state.unit_spawner:spawn_local_unit_with_extensions(unit_name, "interaction_unit", nil, Vector3Box.unbox(CharacterData[name].position), Quaternion.axis_angle(Vector3.up(), CharacterData[name].rotation)) --World.spawn_unit(world, unit_name, Vector3Box.unbox(CharacterData[name].position), Quaternion.axis_angle(Vector3.up(), CharacterData[name].rotation))
	local interaction_extension = ScriptUnit.has_extension(character_unit, "interactable_system")
	local outline_extension = ScriptUnit.has_extension(character_unit, "outline_system")
	local material_changes = skin_data.material_changes
	local hat_template = ItemHelper.get_template_by_item_name(CharacterData[name].hatname)
	local scene_graph_links = {}
	
	SpawnedUnits[name].body = character_unit
	
	Unit.flow_event(character_unit, "lua_spawn_attachments")
	if not CharacterData[name].hidehat then
		local hat_unit = World.spawn_unit(world, CharacterData[name].hat)
		
		Unit.flow_event(hat_unit, "lua_attachment_unhidden")
		Unit.flow_event(character_unit, hat_template.show_attachments_event)
		GearUtils.link(world, hat_template.attachment_node_linking["slot_hat"], scene_graph_links, character_unit, hat_unit)
		SpawnedUnits[name].hat = hat_unit
	else
		Unit.flow_event(character_unit, "lua_head_default")
	end
	
	if material_changes then
		local third_person_changes = material_changes.third_person
		local flow_unit_attachments = Unit.get_data(character_unit, "flow_unit_attachments") or {}

		for slot_name, material_name in pairs(third_person_changes) do
			for _, unit in pairs(flow_unit_attachments) do
				Unit.set_material(unit, slot_name, material_name)
			end		
		
			Unit.set_material(character_unit, slot_name, material_name)
		end
	end

	if tint_data then
		local gradient_variation = tint_data.gradient_variation
		local gradient_value = tint_data.gradient_value

		CosmeticUtils.color_tint_unit(character_unit, name, gradient_variation, gradient_value)
	end	
	
	interaction_extension.interactable_type = "smartobject"
	outline_extension.set_method("never")
	Unit.set_data(character_unit, "interaction_data", "hud_interaction_action", "interact_talk")
	Unit.set_data(character_unit, "interaction_data", "hud_description", CharacterData[name].name)
	
	Unit.set_flow_variable(character_unit, "current_overcharge", 0)
	Unit.flow_event(character_unit, "lua_update_overcharge")	
	
	Unit.animation_event(character_unit, CharacterData[name].anim)	
end
--[[ Development utility, not needed in release.
function mod.posrot()
	local playerunit = Managers.player:local_player().player_unit
	mod:echo("Position: " .. tostring(Unit.world_position(playerunit, 0)) .. " Rotation: " .. tostring(Quaternion.angle(Unit.world_rotation(playerunit, 0))))
end
--]]
--[[
	Hooks
--]]
mod:hook_safe(BulldozerPlayer, "spawn_unit", CheckSpawnUnspawn) --Hook local player spawn to trigger the check.
mod:hook_safe(RemotePlayer, "set_player_unit", CheckSpawnUnspawn) --Hook remote player spawn to trigger the check.
--There are no bots in keep so no need to hook bot player spawn.

mod:hook(GenericUnitInteractorExtension, "start_interaction", function (func, self, hold_input, interactable_unit, interaction_type, ...) --Requires full replacement to remove assert for interacting with local (non-replicated) units.
	InteractionHelper.printf("[GenericUnitInteractorExtension] start_interaction(interactable_unit=%s, interaction_type=%s)", tostring(interactable_unit), tostring(interaction_type))

	local interaction_context = self.interaction_context
	interaction_context.hold_input = hold_input
	interaction_context.interactable_unit = interactable_unit or interaction_context.interactable_unit
	interaction_context.interaction_type = interaction_type or interaction_context.interaction_type

	fassert(self:can_interact(interaction_context.interactable_unit, interaction_type), "Attempted to start interaction even though the interaction wasn't allowed.")

	interaction_context.interaction_type = InteractionHelper.player_modify_interaction_type(self.unit, interaction_context.interactable_unit, interaction_context.interaction_type)
	local unit = self.unit
	local interaction_type = interaction_context.interaction_type
	local network_manager = Managers.state.network
	local interactor_go_id = Managers.state.unit_storage:go_id(unit)
	local interactable_go_id, is_level_unit = network_manager:game_object_or_level_id(interaction_context.interactable_unit)

	if interactor_go_id == nil or interactable_go_id == nil then
		--Assert was removed here, unit with no game object ID will most likely be our local, non-replicated NPC - no need to panic.
		return
	end

	local interaction_data = interaction_context.data
	local interactor_data = interaction_data.interactor_data
	local interaction_template = InteractionDefinitions[interaction_type]
	local client_functions = interaction_template.client

	table.clear(interactor_data)

	if client_functions.set_interactor_data then
		client_functions.set_interactor_data(unit, interactable_unit, interactor_data)
	end

	self.state = "waiting_for_confirmation"

	InteractionHelper:request(interaction_type, interactor_go_id, interactable_go_id, is_level_unit, self.is_server)
end)

--[[
	Callbacks
--]]
mod.update = function(dt)
	if load_in_progress == true then --Check whether we are actively loading any packages, if all packages in queue are completed spawn all NPCs.
		local all_packages_loaded = true
		for i = 1, #package_names, 1 do
			local package_name = package_names[i]

			if not Managers.package:has_loaded(package_name, reference_name) then
				all_packages_loaded = false

				break
			end
		end

		if all_packages_loaded then
			for character,data in pairs(CharacterData) do
				if CharacterData[character].shouldspawn == true then SpawnNPC(character) end
			end
			load_in_progress = false
		end		
	end
	
--	UpdateLookats(dt) --Unused, currently used anims don't allow lookat anim blending so no point in wasting resources on managing this. If there will ever be unarmed idle anims which support lookat blending this can be uncommented.
end

mod.on_game_state_changed = function(status, state) --Reinitialize all tracked locals and unreference loaded packages so they can be potentially unloaded.
	if state == "StateIngame" and string.match(Managers.state.game_mode:level_key(), "inn_level") then mod:enable_all_hooks() else mod:disable_all_hooks() end
	
	package_names = {}
	SpawnedUnits = {
	witch_hunter = {},
	bright_wizard = {},
	dwarf_ranger = {},
	wood_elf = {},
	empire_soldier = {}
	}
	
	if state == "StateLoading" and #package_names > 0 then
		local package_manager = Managers.package
		for i, name in ipairs(package_names) do
			package_manager:unload(name, "Inhabitants")	
		end
	end
end

--[[
	Initialization
--]]
--mod:command("pos", "", mod.posrot) --Development utility, not needed in release.