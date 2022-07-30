/**
 * INNATE SPELL WEAVING ACTION
 */

///Attempts to weave a spell into the item (I should have made this entire thing a component in hindsight)
/proc/clockwork_spellweaver(obj/item/target_item, datum/action/item_action/clockwork/choosen_spell, mob/owner)
	var/datum/action/item_action/clockwork/spell = new choosen_spell(target_item)
	spell.Grant(owner)
	target_item.icon_state = "[initial(target_item.icon_state)]_powered"
	spell.update_item_overlays()
	SEND_SIGNAL(target_item, COMSIG_ITEM_WEAVE_SPELL, spell)

/datum/action/innate/cult/clockwork
	name = "Prepare Clockwork Magic"
	desc = "Weave a powerful spell into your gear. It is quicker in the <b>Requiem</b>."
	background_icon_state = "bg_clock"
	icon_icon = 'icons/obj/clockwork_objects.dmi'
	button_icon_state = "wall_gear"
	buttontooltipstyle = "cult" //TODO.. buttooltip is blood red this is no good

/datum/action/innate/cult/clockwork/Grant()
	. = ..()
	button.screen_loc = DEFAULT_CULTSPELLS
	button.moved = DEFAULT_CULTSPELLS
	button.ordered = FALSE
	button.locked = TRUE

/datum/action/innate/cult/clockwork/Activate()
	var/obj/item/target_item = owner.get_active_held_item()
	if(!target_item || !(target_item.type in CLOCKWORK_ITEM_WHITELIST))
		owner.balloon_alert(owner, "No valid clockwork gear in the active hand!")
		return
	var/spell_choice = input("Pick a spell to weave.", "Clockwork spells") as null|anything in subtypesof(/datum/action/item_action/clockwork)
	clockwork_spellweaver(target_item, spell_choice, owner)

/datum/action/innate/cult/clockwork/Deactivate()
	. = ..()
	//TODO.. say something along the lines of you're out of jazz because of holy water
/**
 * SINGLE TARGET SPELLS
 */
//** Spells bound to items, yet not casted by the UI button, instead the button represents the current cooldown and works as a tip
/datum/action/item_action/clockwork
	icon_icon = 'icons/mob/actions/actions_spells.dmi'
	background_icon_state = "bg_clock"
	check_flags = AB_CHECK_HANDS_BLOCKED|AB_CHECK_CONSCIOUS|AB_CHECK_IMMOBILE
	///What the owner should say when successfully casting the spell
	var/spell_phrase
	///
	var/spell_description
	///TODO.. doc this
	var/spell_category
	///How long should the cooldown last
	var/cooldown_duration
	///What types can we cast this on
	var/list/target_type_whitelist = list()
	COOLDOWN_DECLARE(spell_cooldown)

//Duplicate code yikes TODO..
/datum/action/item_action/clockwork/ApplyIcon(atom/movable/screen/movable/action_button/current_button, force = FALSE)
	if(icon_icon && button_icon_state && ((current_button.button_icon_state != button_icon_state) || force))
		current_button.cut_overlays(TRUE)
		current_button.add_overlay(mutable_appearance(icon_icon, button_icon_state))
		current_button.button_icon_state = button_icon_state

/datum/action/item_action/clockwork/OnUpdatedIcon()
	. = ..()
	update_item_overlays()

/datum/action/item_action/clockwork/Grant()
	..()
	button.screen_loc = DEFAULT_CULTSPELLS
	button.moved = DEFAULT_CULTSPELLS
	button.ordered = FALSE
	positioning()

///Called when the user clicks the actions button, DOES NOT necessarly trigger the spell
/datum/action/item_action/clockwork/Trigger() //Duplicate code yikes, fix this
	to_chat(owner, span_bloodcult(spell_description)) //TODO.. cult spans
	if(SEND_SIGNAL(src, COMSIG_ACTION_TRIGGER, src) & COMPONENT_ACTION_BLOCK_TRIGGER)
		return FALSE
	return TRUE

/datum/action/item_action/clockwork/IsAvailable()
	. = ..()
	if(!COOLDOWN_FINISHED(src, spell_cooldown))
		//TODO.. chat cue
		return FALSE
///make this generic or something idk
/datum/action/item_action/clockwork/proc/positioning()
	var/list/screen_loc_split = splittext(button.screen_loc,",")
	var/list/screen_loc_X = splittext(screen_loc_split[1],":")
	var/list/screen_loc_Y = splittext(screen_loc_split[2],":")
	var/pix_X = text2num(screen_loc_X[2])
	var/list/owner_clockwork_spells = list()
	for(var/datum/action/A in owner.actions)
		if(istype(A, /datum/action/item_action/clockwork))
			owner_clockwork_spells += A
	for(var/datum/action/item_action/clockwork/CWS in owner_clockwork_spells)
		var/order = pix_X+owner_clockwork_spells.Find(CWS)*31
		CWS.button.screen_loc = "[screen_loc_X[1]]:[order],[screen_loc_Y[1]]:[screen_loc_Y[2]]"
		CWS.button.moved = CWS.button.screen_loc

/datum/action/item_action/clockwork/proc/spell_trigger(atom/target)
	if(!can_cast(target))
		return FALSE
	COOLDOWN_START(src, spell_cooldown, cooldown_duration)
	addtimer(CALLBACK(src, .proc/end_cooldown), cooldown_duration + 0.1) //TODO.. this
	update_item_overlays()
	UpdateButtonIcon(status_only = TRUE)
	owner.say(spell_phrase)
	cast(target)

/datum/action/item_action/clockwork/proc/end_cooldown()
	update_item_overlays()
	UpdateButtonIcon(status_only = TRUE)

/datum/action/item_action/clockwork/proc/can_cast(atom/target)
	SHOULD_CALL_PARENT(TRUE)
	if(!IsAvailable())
		return FALSE
	//TODO.. chat cue
	for(var/type in target_type_whitelist)
		if(istype(target, type))
			return TRUE
	return FALSE

/datum/action/item_action/clockwork/proc/cast(atom/target)
	return

/datum/action/item_action/clockwork/proc/update_item_overlays()
	var/spell_ready_overlay = "[target.icon_state]_glow"
	if(COOLDOWN_FINISHED(src, spell_cooldown))
		target.add_overlay(spell_ready_overlay)
	else
		target.cut_overlay(spell_ready_overlay)

/datum/action/item_action/clockwork/bogus
	name = "Debug clockwork action"
	spell_phrase = "VA'NISH!"
	button_icon_state = "gib"
	cooldown_duration = 5 SECONDS
	target_type_whitelist = list(/mob)

/datum/action/item_action/clockwork/bogus/cast(atom/target)
	var/mob/living/victim = target
	victim.gib()

/**
 * SELF CAST SPELLS
 */

/datum/action/item_action/clockwork/self
	background_icon_state = "bg_gear"
	target_type_whitelist = list(/mob/living/carbon) //Hopefully you're not currently floor plating otherwise we have a problem

/datum/action/item_action/clockwork/self/Trigger()
	. = ..()
	if(!.)
		return FALSE
	spell_trigger(owner)

/datum/action/item_action/clockwork/self/fast_forward
	name = "Fast Forward"
	button_icon_state = "fast_forward"
	cooldown_duration = 10 SECONDS
	///How long the speedboost lasts
	var/duration = 5 SECONDS

/datum/action/item_action/clockwork/self/fast_forward/cast(atom/target)
	owner.add_movespeed_modifier(/datum/movespeed_modifier/clock_cult_fast_forward)
	addtimer(CALLBACK(src, .proc/speed_fade), duration)

/datum/action/item_action/clockwork/self/fast_forward/proc/speed_fade()
	//TODO.. chat cue
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/clock_cult_fast_forward)

/datum/movespeed_modifier/clock_cult_fast_forward
	multiplicative_slowdown = -2

/datum/action/item_action/clockwork/self/pause
	name = "Pause"
	button_icon_state = "pause"
	cooldown_duration = 10 SECONDS
	///How long the time should be frozen for
	var/duration = 3 SECONDS
	///The radius of the freezing effect
	var/radius = 1

/datum/action/item_action/clockwork/self/pause/cast(atom/target)
	new /obj/effect/timestop(get_turf(owner), radius, duration, list(owner))

/datum/action/item_action/clockwork/self/rewind
	name = "Rewind"
	button_icon_state = "rewind"
	cooldown_duration = 1 MINUTES
	///At most, How far back in time can we go? DO NOT put anything else than seconds here
	var/time_limit = 20 SECONDS
	///How long should we take to go back in time
	var/rollback_duration = 5 SECONDS
	///What did we look like X seconds in the past, last element being the farthest in the past
	var/list/stored_states = list()
	///What path did we take during those time_limit seconds, last element being the farthest in the past. Allows for smooth movement when rewinding
	var/list/stored_steps = list()

/datum/action/item_action/clockwork/self/rewind/Grant(mob/M)
	. = ..()
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, .proc/record_move)
	START_PROCESSING(SSprocessing, src)

/datum/action/item_action/clockwork/self/rewind/Remove(mob/M)
	. = ..()
	UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)
	STOP_PROCESSING(SSprocessing, src)
	return ..()

/datum/action/item_action/clockwork/self/rewind/Destroy()
	UnregisterSignal(usr, COMSIG_MOVABLE_MOVED, .proc/record_move)
	STOP_PROCESSING(SSprocessing, src)
	return ..()

/datum/action/item_action/clockwork/self/rewind/process(delta_time)
	var/mob/living/carbon/self = owner
	var/new_state = list(
		//Location
		"steps" = list(),
		//living
		"bruteloss" = self.getBruteLoss(),
		"oxyloss" = self.getOxyLoss(),
		"toxloss" = self.getToxLoss(),
		"fireloss" = self.getFireLoss(),
		"cloneloss" = self.getCloneLoss(),
		"staminaloss" = self.getStaminaLoss(),
		"fire_stacks" = self.fire_stacks,
		"eye_blind" = self.eye_blind,
		"bodytemperature" = self.get_body_temp_normal(),
		"blood_volume" = self.blood_volume
	)
	stored_states.Insert(1, list(new_state))
	if(stored_states.len > time_limit / 10)
		stored_states.Cut(time_limit / 10 + 1, 0)

/datum/action/item_action/clockwork/self/rewind/cast(atom/target)
	var/mob/living/carbon/self = owner
	var/previous_incorporeal_move = self.incorporeal_move
	self.incorporeal_move = INCORPOREAL_MOVE_SHADOW
	self.notransform = TRUE
	for(var/list/state in stored_states)
		//Health
		self.adjustBruteLoss(state["bruteloss"] - self.getBruteLoss())
		self.adjustOxyLoss(state["oxyloss"] - self.getOxyLoss())
		self.adjustToxLoss(state["toxloss"] - self.getToxLoss())
		self.adjustFireLoss(state["fireloss"] - self.getFireLoss())
		self.adjustCloneLoss(state["cloneloss"] - self.getCloneLoss())
		self.adjustStaminaLoss(state["staminaloss"] - self.getStaminaLoss())
		self.adjust_fire_stacks(state["firestacks"] - self.fire_stacks)
		self.adjust_bodytemperature(state["bodytemperature"] - self.bodytemperature)
		if(self.stat >= HARD_CRIT) //You were killed during the rewind or somehow went into hard crit in the last X seconds and decided it was a great idea to do it
			break
		//Movements
		for(var/S in state["steps"])
			self.forceMove(get_turf(locate(S["x"], S["y"], S["z"])))
			sleep(rollback_duration / (stored_steps.len))
		if(!state["steps"].len) //We didn't move at this point in time, but time still passed
			sleep(rollback_duration / (stored_steps.len))
	self.incorporeal_move = previous_incorporeal_move
	self.notransform = FALSE

/datum/action/item_action/clockwork/self/rewind/proc/record_move(atom/target)
	SIGNAL_HANDLER
	if(!stored_states.len) //We haven't started recording yet
		return
	var/new_step_state = list(
		"x" = owner.x,
		"y" = owner.y,
		"z" = owner.z,
		"timestamp" = world.time //When did we record this step, so we don't store an infinite amount of steps and remove the older ones
	)
	stored_steps.Insert(1, list(new_step_state))
	stored_states[1]["steps"].Insert(1, list(new_step_state))
	for(var/i = 1; i <= stored_steps.len; i++)
		if(stored_steps[i]["timestamp"] + time_limit < world.time)
			stored_steps.Cut(i, 0)
			return

