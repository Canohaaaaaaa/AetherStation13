/**
 * INNATE SPELL WEAVING ACTION
 */

///Attempts to weave a spell into the item (I should have made this entire thing a component in hindsight)
/proc/clockwork_spellweaver(obj/item/target_item, datum/action/item_action/clockwork/choosen_spell, mob/owner)
	var/datum/action/item_action/clockwork/spell = new choosen_spell(target_item)
	spell.Grant(owner)
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
	///Should you be able to target non-adjacent atoms?
	var/ranged = FALSE
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
	///What color should the energy overlay be
	var/spell_color = "#ce2121"
	///This item has a spell
	var/mutable_appearance/powered_overlay
	///This item spell is ready
	var/mutable_appearance/ready_overlay
	COOLDOWN_DECLARE(spell_cooldown)

/datum/action/item_action/clockwork/New(Target)
	. = ..()
	RegisterSignal(target, COMSIG_ATOM_UPDATE_APPEARANCE, .proc/update_item_overlays)
	ready_overlay = mutable_appearance('icons/obj/clocktools.dmi', "[target.icon_state]_glow")
	ready_overlay.appearance_flags |= RESET_COLOR
	ready_overlay.color = spell_color
	powered_overlay = mutable_appearance('icons/obj/clocktools.dmi', "[target.icon_state]_powered")
	powered_overlay.appearance_flags |= RESET_COLOR
	powered_overlay.color = spell_color
	target.add_overlay(powered_overlay)

/datum/action/item_action/clockwork/Destroy()
	target.cut_overlay(powered_overlay)
	target.cut_overlay(ready_overlay)
	return ..()

//Duplicate code yikes TODO..
/datum/action/item_action/clockwork/ApplyIcon(atom/movable/screen/movable/action_button/current_button, force = FALSE)
	if(icon_icon && button_icon_state && ((current_button.button_icon_state != button_icon_state) || force))
		current_button.cut_overlays(TRUE)
		current_button.add_overlay(mutable_appearance(icon_icon, button_icon_state))
		current_button.button_icon_state = button_icon_state

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
	addtimer(CALLBACK(src, .proc/end_cooldown), cooldown_duration + 0.1)
	UpdateButtonIcon(status_only = TRUE)
	update_item_overlays()
	owner.say(spell_phrase)
	cast(target)


/datum/action/item_action/clockwork/proc/end_cooldown()
	UpdateButtonIcon(status_only = TRUE)
	target.update_appearance()

/datum/action/item_action/clockwork/proc/can_cast(atom/target)
	SHOULD_CALL_PARENT(TRUE)
	if(!IsAvailable())
		return FALSE
	if(!ranged && !owner.CanReach(target))
		return FALSE
	//TODO.. chat cue
	for(var/type in target_type_whitelist)
		if(istype(target, type))
			return TRUE
	return FALSE

/datum/action/item_action/clockwork/proc/cast(atom/target)
	return

/datum/action/item_action/clockwork/proc/update_item_overlays()
	SIGNAL_HANDLER
	if(!COOLDOWN_FINISHED(src, spell_cooldown))
		target.cut_overlay(ready_overlay)
		return
	target.cut_overlay(ready_overlay)
	var/mutable_appearance/new_ready_overlay = mutable_appearance('icons/obj/clocktools.dmi', "[target.icon_state]_glow")
	new_ready_overlay.appearance_flags |= RESET_COLOR
	new_ready_overlay.color = spell_color
	ready_overlay = new_ready_overlay
	target.add_overlay(ready_overlay)

/datum/action/item_action/clockwork/bogus
	name = "Debug clockwork action"
	spell_phrase = "VA'NISH!"
	button_icon_state = "gib"
	cooldown_duration = 5 SECONDS
	target_type_whitelist = list(/mob)

/datum/action/item_action/clockwork/bogus/cast(atom/target)
	var/mob/living/victim = target
	victim.gib()

/datum/action/item_action/clockwork/kindle
	name = "Kindle"
	spell_phrase = ""
	button_icon_state = "magicm"
	cooldown_duration = 12 SECONDS
	target_type_whitelist = list(/mob/living)
	spell_color = "#d000ff"
	///Stun duration
	var/duration = 4 SECONDS

/datum/action/item_action/clockwork/kindle/cast(atom/target)
	var/mob/living/victim = target
	//TODO.. feedback
	new /obj/effect/temp_visual/clockcult/kindle(get_turf(victim))
	victim.Stun(duration)
	victim.flash_act(override_blindness_check = TRUE, length = duration / 4)
	victim.Jitter(duration)

/datum/action/item_action/clockwork/electrocute
	name = "Electrocute"
	spell_phrase = ""
	button_icon_state = "lightning"
	cooldown_duration = 12 SECONDS
	target_type_whitelist = list(/mob/living)
	spell_color = "#ffee00"
	///Knockdown duration
	var/duration = 2 SECONDS
	//Shock damage
	var/damage = 15

/datum/action/item_action/clockwork/electrocute/cast(atom/target)
	var/mob/living/victim = target
	//TODO.. feedback
	var/datum/effect_system/lightning_spread/visual_effect = new /datum/effect_system/lightning_spread
	visual_effect.set_up(5, TRUE, victim)
	visual_effect.start()
	victim.electrocute_act(damage, owner, flags = SHOCK_NOGLOVES | SHOCK_NOSTUN)
	victim.Knockdown(duration)

/datum/action/item_action/clockwork/ignite
	name = "Ignite"
	spell_phrase = ""
	button_icon_state = "sacredflame"
	cooldown_duration = 12 SECONDS
	target_type_whitelist = list(/mob/living)
	spell_color = "#ff8c00"
	///Hot hot hot
	var/firestacks = 12
	///The instant damage inflicted
	var/damage = 30
	///How far they're blasted away
	var/throw_range = 3

/datum/action/item_action/clockwork/ignite/cast(atom/target)
	var/mob/living/victim = target
	//TODO.. feedback
	victim.adjust_fire_stacks(firestacks)
	victim.IgniteMob()
	victim.adjustFireLoss(damage)
	victim.throw_at(get_ranged_target_turf(victim, get_dir(owner, victim), throw_range), throw_range, 1, owner)

/datum/action/item_action/clockwork/abduct
	name = "Abduct"
	spell_phrase = ""
	button_icon_state = "tentacle"
	icon_icon = 'icons/mob/actions/actions_changeling.dmi'
	cooldown_duration = 120 SECONDS
	ranged = TRUE
	target_type_whitelist = list(/atom)
	spell_color = "#9d00ff"

/datum/action/item_action/clockwork/abduct/cast(atom/target)
	var/obj/item/ammo_casing/magic/tentacle/brass_hook/hook = new
	hook.fire_casing(target, owner, null, 0, FALSE, "", 0, src)
	qdel(hook)

/obj/item/ammo_casing/magic/tentacle/brass_hook
	name = "hook"
	desc = "A brass hook with a chain of cogs."
	projectile_type = /obj/projectile/brass_hook

/obj/projectile/brass_hook
	name = "brass hook"
	icon_state = "brass_hook"
	pass_flags = PASSTABLE
	damage = 0
	range = 8
	hitsound = 'sound/weapons/thudswoosh.ogg'
	var/chain

/obj/projectile/brass_hook/fire(setAngle)
	if(firer)
		chain = firer.Beam(src, icon_state = "cog_chain")
	..()

/obj/projectile/brass_hook/Destroy()
	qdel(chain)
	return ..()

/obj/projectile/brass_hook/on_hit(atom/target, blocked = FALSE)
	var/mob/living/carbon/human/thief = firer
	if(blocked >= 100)
		return BULLET_ACT_BLOCK
	if(isitem(target))
		var/obj/item/grabbed_item = target
		if(grabbed_item.anchored)
			return BULLET_ACT_BLOCK
		if(thief.get_active_held_item()) //We have our spell-woven tool inhand, hopefully our other hand is empty
			thief.swap_hand()
		to_chat(firer, span_notice("You pull [grabbed_item] towards yourself."))
		thief.throw_mode_on(THROW_MODE_TOGGLE)
		grabbed_item.throw_at(thief, 10, 2)
		return BULLET_ACT_HIT
	else if(!isliving(target))
		return BULLET_ACT_BLOCK

	var/mob/living/living_victim = target
	if(living_victim.anchored || living_victim.throwing)//avoid double hits
		return BULLET_ACT_BLOCK
	if(iscarbon(living_victim))
		var/mob/living/carbon/carbon_victim = living_victim
		var/obj/item/stolen_item
		if(carbon_victim.get_active_held_item())
			stolen_item = carbon_victim.get_active_held_item()
		else
			stolen_item = carbon_victim.get_inactive_held_item()
		if(stolen_item) //Something inhand to steal
			if(carbon_victim.dropItemToGround(stolen_item))
				carbon_victim.visible_message(span_danger("[stolen_item] is yanked off [carbon_victim]'s hand by [src]!"),span_userdanger("A claw pulls [stolen_item] away from you!"))
				on_hit(stolen_item)
				return BULLET_ACT_HIT
			else
				to_chat(firer, span_warning("You can't seem to pry [stolen_item] off [carbon_victim]'s hands!"))
				return BULLET_ACT_BLOCK
		//nothing to steal inhand, let's grab them
		carbon_victim.visible_message(span_danger("[living_victim] is grabbed by a claw!"),span_userdanger("A claw grabs you and pulls you towards [thief]!"))
		carbon_victim.throw_at(get_step_towards(thief,carbon_victim), 8, 2, thief, TRUE, TRUE, callback=CALLBACK(src, .proc/brass_hook_grab, thief, carbon_victim))
		return BULLET_ACT_HIT
	else
		living_victim.visible_message(span_danger("[living_victim] is pulled by a claw!"), span_userdanger("A claw grabs you and pulls you towards [thief]!"))
		living_victim.throw_at(get_step_towards(thief, living_victim), 8, 2, callback=CALLBACK(src, .proc/brass_hook_grab, thief, living_victim))
		return BULLET_ACT_HIT

/obj/projectile/brass_hook/proc/brass_hook_grab(mob/living/carbon/source, mob/living/target)
	if(!source.Adjacent(target))
		return
	if(source.get_inactive_held_item())
		source.swap_hand()
	target.grabbedby(source)
	target.grippedby(source, instant = TRUE)

/datum/action/item_action/clockwork/translocate
	name = "Translocate"
	spell_phrase = ""
	button_icon_state = "repulse"
	cooldown_duration = 120 SECONDS
	ranged = TRUE
	target_type_whitelist = list(/mob)
	spell_color = "#001aff"

/datum/action/item_action/clockwork/translocate/cast(atom/target)
	var/turf/target_turf = get_turf(target)
	var/turf/owner_turf = get_turf(owner)
	do_teleport(owner, target_turf, asoundin = 'sound/effects/phasein.ogg')
	do_teleport(target, owner_turf, asoundin = 'sound/effects/phasein.ogg')

/datum/action/item_action/clockwork/apprehend
	name = "Apprehend"
	spell_phrase = ""
	button_icon_state = "time"
	icon_icon = 'icons/mob/actions/actions_cult.dmi'
	cooldown_duration = 30 SECONDS
	target_type_whitelist = list(/mob/living)
	var/duration = 10 SECONDS
	spell_color = "#00ff26"

/datum/action/item_action/clockwork/apprehend/cast(atom/target)
	var/mob/living/victim = target
	//is_convertable_to_cult(target, owner.cult) TODO.. mindshield tests
	victim.Immobilize(duration)

/datum/action/item_action/clockwork/force_wall
	name = "Force Wall"
	spell_phrase = ""
	button_icon_state = "cultforcewall"
	icon_icon = 'icons/mob/actions/actions_cult.dmi'
	cooldown_duration = 30 SECONDS
	target_type_whitelist = list(/turf/open)
	var/duration = 10 SECONDS
	spell_color = "#ff8800"

/datum/action/item_action/clockwork/force_wall/cast(atom/target)
	var/target_dir = get_dir(owner, target)
	var/turf/tile_1 = get_step(owner, target_dir)
	var/turf/tile_2
	var/turf/tile_3
	switch(target_dir) //TODO.. redo this garbage
		if(NORTH,SOUTH)
			tile_2 = locate(tile_1.x-1, tile_1.y, tile_1.z)
			tile_3 = locate(tile_1.x+1, tile_1.y, tile_1.z)
		if(EAST,WEST)
			tile_2 = locate(tile_1.x, tile_1.y+1, tile_1.z)
			tile_3 = locate(tile_1.x, tile_1.y-1, tile_1.z)
		if(NORTHEAST)
			tile_2 = locate(tile_1.x, tile_1.y-1, tile_1.z)
			tile_3 = locate(tile_1.x-1, tile_1.y, tile_1.z)
		if(NORTHWEST)
			tile_2 = locate(tile_1.x, tile_1.y-1, tile_1.z)
			tile_3 = locate(tile_1.x+1, tile_1.y, tile_1.z)
		if(SOUTHEAST)
			tile_2 = locate(tile_1.x, tile_1.y+1, tile_1.z)
			tile_3 = locate(tile_1.x-1, tile_1.y, tile_1.z)
		if(SOUTHWEST)
			tile_2 = locate(tile_1.x, tile_1.y+1, tile_1.z)
			tile_3 = locate(tile_1.x+1, tile_1.y, tile_1.z)
	var/mutable_appearance/rotate_gear_1 = mutable_appearance('icons/obj/clockwork_objects.dmi', "gear_summon")
	var/mutable_appearance/rotate_gear_2 = mutable_appearance('icons/obj/clockwork_objects.dmi', "gear_summon")
	var/mutable_appearance/rotate_gear_3 = mutable_appearance('icons/obj/clockwork_objects.dmi', "gear_summon")
	var/obj/effect/forcefield/clockcult/wall_1 = new(tile_1)
	var/obj/effect/forcefield/clockcult/wall_2 = new(tile_2)
	var/obj/effect/forcefield/clockcult/wall_3 = new(tile_3)
	wall_1.add_overlay(rotate_gear_1)
	wall_2.add_overlay(rotate_gear_2)
	wall_3.add_overlay(rotate_gear_3)
	animate(wall_1, duration, transform = matrix().Turn(179), flags = ANIMATION_PARALLEL)
	animate(wall_2, duration, transform = matrix().Turn(181), flags = ANIMATION_PARALLEL)
	animate(wall_3, duration, transform = matrix().Turn(181), flags = ANIMATION_PARALLEL)
	//animate(rotate_gear_1, duration, transform = matrix().Turn(179), flags = ANIMATION_PARALLEL)
	//animate(rotate_gear_2, duration, transform = matrix().Turn(181), flags = ANIMATION_PARALLEL)
	//animate(rotate_gear_3, duration, transform = matrix().Turn(181), flags = ANIMATION_PARALLEL)
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
	UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)
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
	if(stored_states.len > time_limit / 10) //Cut oldest states
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
	for(var/i = 1; i <= stored_steps.len; i++) //Cut oldest steps
		if(stored_steps[i]["timestamp"] + time_limit < world.time)
			stored_steps.Cut(i, 0)
			return

