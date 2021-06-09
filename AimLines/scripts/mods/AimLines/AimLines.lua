--[[
                                 
      _/_/    _/                 
   _/    _/      _/_/_/  _/_/    
  _/_/_/_/  _/  _/    _/    _/   
 _/    _/  _/  _/    _/    _/    
_/    _/  _/  _/    _/    _/     
                                 
                                 
                                                
    _/        _/                                
   _/            _/_/_/      _/_/      _/_/_/   
  _/        _/  _/    _/  _/_/_/_/  _/_/        
 _/        _/  _/    _/  _/            _/_/     
_/_/_/_/  _/  _/    _/    _/_/_/  _/_/_/        
                                                
SkacikPL(2018) - https://www.skacikpl.pl
--]]												

local mod = get_mod("AimLines")
local LineObjectKeeper = nil --We need to keep it for existing level

--[[
	Callbacks
--]]

-- Called on every update to mods
-- dt - time in milliseconds since last update
mod.update = function(dt) --We do everything in here
	if Managers.state.network and Managers.state.network:game() and not Managers.player:local_player().network_manager.matchmaking_manager._ingame_ui.is_in_inn and mod:is_enabled() then --But only when whe should and when we can.
	local world = Managers.world:world("level_world") --Get the world before anything else.
	
	if LineObjectKeeper == nil then --If there's no LineObject for current level we need to create it.
		LineObjectKeeper = World.create_line_object(world, false) --Ditto.
	end
	
	LineObject.reset(LineObjectKeeper) --Reset before drawing next batch.
	
	local players = Managers.player:players() --Let's get all players.

		for id, player in pairs(players) do --Let's iterate through all players.
			if player ~= Managers.player:local_player() and Unit.alive(player.player_unit) then --It's pointless and inaccurate to draw it for local player based on those params (or dead people).
				local unit_storage = Managers.state.unit_storage --Get stored units.
				local unit_id = unit_storage.go_id(unit_storage, player.player_unit) --Get game object ID for currently iterated player).
				local game = Managers.state.network:game() --Get current game.
				local observer_fpp = GameSession.game_object_field(game, unit_id, "aim_position") --Get the perspective position for currently iterated player.
				local observer_forward = GameSession.game_object_field(game, unit_id, "aim_direction") --Get the forward vector of perspective.
				
				local opacity = mod:get("opacity") --Player set.
				local color = Color(opacity, 255, 255, 255) --Declared to be set later.
				
				local profile = SPProfiles[player:profile_index()] --Get player profile.
				local charactername = profile.character_name --Get character name so we can change line color based on character.
			
				if string.match(charactername,"dwarf") then color = Color(opacity, 139, 69, 19) end --Barding gets brown.
				if string.match(charactername,"witch") then color = Color(opacity, 128, 0, 0) end --Saltzpyre gets dark red.
				if string.match(charactername,"wizard") then color = Color(opacity, 218, 165, 32) end --Sienna gets gold.
				if string.match(charactername,"wood") then color = Color(opacity, 0, 255, 127) end --Kerilian gets blue'ish green.
				if string.match(charactername,"empire") then color = Color(opacity, 128, 0, 128) end --Kruber gets purple.
				
				local wielded_slot_name = ScriptUnit.extension(player.player_unit, "inventory_system"):get_wielded_slot_name() --Get name of currently wielded slot.
				local weapon_template = nil --Declare for future use.
				local israpier = false --Exception for rapier which is both melee and ranged.
				
				if mod:get("rangedonly") then --Do this stuff only if lines are restricted to just ranged weapons.
					weapon_template = ScriptUnit.extension(player.player_unit, "inventory_system"):get_wielded_slot_item_template() --Get weapon template.
					if weapon_template ~= nil then --This shit is horrible.
						if weapon_template.actions.action_three ~=  nil then --And this is even worse.
							if weapon_template.actions.action_three.default.kind == "handgun" then israpier = true end --If it has a handgun shot as 3rd action then it's a rapier.
						end
					end
				end
				
				if not mod:get("rangedonly") or mod:get("rangedonly") and (wielded_slot_name == "slot_ranged" or wielded_slot_name == "slot_career_skill_weapon" or wielded_slot_name == "slot_grenade" or israpier) then --Draw always or based on slot/rapier if drawing only for rangeds.
					LineObject.add_line(LineObjectKeeper, color, observer_fpp, observer_fpp + (observer_forward * mod:get("distance"))) --Add line for currently iterated player to the list that will be dispatched for this frame.
				end
			end
		end
		
		LineObject.dispatch(world,LineObjectKeeper) --Once we're done iterating through all of the players, draw all of the lines at once.
	
	end
	
end

-- Called when game state changes (e.g. StateLoading -> StateIngame)
-- status - "enter" or "exit"
-- state  - "StateLoading", "StateIngame" etc.
mod.on_game_state_changed = function(status, state)
	if state == "StateIngame" then LineObjectKeeper = nil end --Failsafe, make sure we recreate LineObject for each new level.
end

-- Called when the checkbox for this mod is unchecked
-- is_first_call - true if called right after mod initialization
mod.on_disabled = function(is_first_call)
if LineObjectKeeper then 
local world = Managers.world:world("level_world")
LineObject.reset(LineObjectKeeper) 
end --Failsafe.
end