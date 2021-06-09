local mod = get_mod("InspectAnims")

--[[
	Functions
--]]

local function PostStartInspection(self, unit, input, dt, context, t, previous_state, params, ...)
	Unit.animation_event(unit, "select_hover_loop") --Play anim at the end of state entry.
end

local function PostEndInspection(self, unit, input, dt, context, t, next_state, ...)
	Unit.animation_event(unit, "death") --Hack required to override statemachine hierarchy.
	Unit.animation_event(unit, "reset") --Ditto.
	Unit.animation_event(unit, "idle") --Ditto.
	Unit.animation_event(unit, BackendUtils.get_item_template(self.inventory_extension._equipment.slots[self.inventory_extension._equipment.wielded_slot].item_data).wield_anim) --Hack to properly revert to appropriate weapon anim.
end

--[[
	Hooks
--]]

mod:hook_safe(PlayerCharacterStateInspecting, "on_enter", PostStartInspection)
mod:hook_safe(PlayerCharacterStateInspecting, "on_exit", PostEndInspection)