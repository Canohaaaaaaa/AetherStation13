GLOBAL_LIST_EMPTY(clockcult_anchors)
GLOBAL_LIST_EMPTY(clockcult_relays)

/proc/get_valid_clockcult_anchors()
	var/list/result = list()
	for(var/obj/machinery/clockcult_anchor/anchor as anything in GLOB.clockcult_anchors)
		if(anchor.anchored)
			result += anchor
	return result

/obj/machinery/clockcult_anchor
	name = "celestial anchor"
	desc = "A teleporter capable of harnessing the energy of the delerict to instantly move matter without the use of bluespace."
	icon = 'icons/obj/clockwork_objects.dmi'
	icon_state = "clockcult_teleporter"
	use_power = NO_POWER_USE
	interaction_flags_atom = INTERACT_ATOM_ATTACK_HAND | INTERACT_ATOM_REQUIRES_ANCHORED
	interaction_flags_machine = INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_OPEN_SILICON | INTERACT_MACHINE_SET_MACHINE

/obj/machinery/clockcult_anchor/Initialize()
	. = ..()
	GLOB.clockcult_anchors += src

/obj/machinery/clockcult_anchor/Destroy()
	. = ..()
	GLOB.clockcult_anchors -= src

/obj/machinery/clockcult_anchor/update_icon_state()
	. = ..()
	icon_state = "clockcult_teleporter[anchored ? "" : "_unwrenched"]"

/obj/machinery/clockcult_anchor/wrench_act(mob/living/user, obj/item/tool)
	if(default_unfasten_wrench(user, tool))
		update_appearance()
		//TODO.. perhaps tell the cult about this ?
	return TRUE

/obj/machinery/clockcult_anchor/can_interact(mob/user)
	. = ..()
	if(!Adjacent(user)) //No long range teleporting from sillicons, TODO.. cultist check + reckoning
		return FALSE

/obj/machinery/clockcult_anchor/interact(mob/user, special_state)
	. = ..()
	if(!GLOB.clockcult_relays.len)
		to_chat(user, span_warning("TODO.. EPIC MESSAGE IDK"))
		return
	var/list/available_relays = list()
	for(var/obj/machinery/clockcult_relay/relay as anything in GLOB.clockcult_relays)
		if(!relay.teleporter_name) //Somehow someone made a relay without a proper name
			continue
		available_relays[relay.teleporter_name] = relay
	var/choice = tgui_input_list(usr, "Pick a destination beacon.", "Teleport", sort_list(available_relays))
	if(!choice)
		return
	var/pulled = user.pulling
	if(Adjacent(user) && do_teleport(user, available_relays[choice], channel = TELEPORT_CHANNEL_CULT))
		user.visible_message(span_warning("[user] vanishes !"), span_danger("You activate the [src]!"))
		if(pulled && do_teleport(pulled, available_relays[choice], channel = TELEPORT_CHANNEL_CULT))
			user.start_pulling(pulled)

/obj/item/clockcult_relay_kit
	name = "celestial relay deployment kit."
	desc = "Should be used away from prying eyes."
	icon = 'icons/obj/clockwork_objects.dmi'
	icon_state = "lens_gem"

/obj/item/clockcult_relay_kit/attack_self(mob/user, modifiers)
	to_chat(user, span_notice("You begin deploying the relay..."))
	if(do_after(user, 6 SECONDS))
		var/obj/machinery/clockcult_relay/new_relay = new(user.loc)
		var/default_name = get_area(new_relay)
		var/relay_name = stripped_input(user, "Would you like to name it ?", "Relay name", default_name, 50)
		for(var/obj/machinery/clockcult_relay/relay in GLOB.clockcult_relays)
			if(relay.teleporter_name == relay_name)
				relay_name += " [rand(1000)]"
		new_relay.teleporter_name = relay_name
		qdel(src)

/obj/machinery/clockcult_relay
	name = "celestial relay"
	desc = "A teleporter capable of recalling users to The Revenant." //TODO.. shipname + non cultist examine
	icon = 'icons/obj/clockwork_objects.dmi'
	icon_state = "relay"
	interaction_flags_atom = INTERACT_ATOM_ATTACK_HAND
	interaction_flags_machine = INTERACT_ATOM_REQUIRES_ANCHORED | INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_SET_MACHINE
	idle_power_usage = 5000
	var/teleporter_name

/obj/machinery/clockcult_relay/Initialize()
	. = ..()
	GLOB.clockcult_relays += src

/obj/machinery/clockcult_relay/Destroy()
	. = ..()
	GLOB.clockcult_relays -= src

/obj/machinery/clockcult_relay/deconstruct(disassembled)
	if(disassembled)
		new /obj/item/clockcult_relay_kit(src)
	return ..()

/obj/machinery/clockcult_relay/can_interact(mob/user)
	. = ..()
	if(!Adjacent(user)) //TODO.. cultist check + reckoning
		return FALSE

/obj/machinery/clockcult_relay/interact(mob/user, special_state)
	. = ..()
	to_chat(user, span_notice("[src] calibrates..."))
	var/list/valid_targets = get_valid_clockcult_anchors()
	if(!valid_targets.len)
		to_chat(user, span_warning("TODO.. EPIC MESSAGE IDK"))
		return
	if(!do_after(user, 5 SECONDS, timed_action_flags = IGNORE_HELD_ITEM))
		return
	var/atom/destination = pick(valid_targets)
	var/atom/movable/pulled = user.pulling
	do_teleport(user, destination, forced = TRUE, asoundin = 'sound/effects/phasein.ogg')
	if(pulled && do_teleport(pulled, destination, forced = TRUE, asoundin = 'sound/effects/phasein.ogg'))
		user.start_pulling(pulled)



/obj/machinery/clockcult_relay/wrench_act(mob/living/user, obj/item/tool)
	to_chat(user, span_notice("You begin dismantling [src]..."))
	if(tool.use_tool(src, user, 4 SECONDS))
		deconstruct(TRUE)
		qdel(src)
	return TRUE

//CLOCKCULT SHURIKEN ???
/obj/machinery/computer/camera_advanced/clockcult_mass_teleporter
	name = "mass teleporter"
	desc = "Controls The Revenant teleporter pads, allowing to teleport multiple individuals at the same time and at the same place. One way trip only." //TODO.. ship name
	use_power = NO_POWER_USE
	interaction_flags_atom = INTERACT_ATOM_ATTACK_HAND | INTERACT_ATOM_REQUIRES_ANCHORED
	var/datum/action/innate/clockcult_mass_teleport/beam_down = new

/obj/machinery/computer/camera_advanced/clockcult_mass_teleporter/CreateEye()
	. = ..()
	eyeobj.visible_icon = TRUE
	eyeobj.icon = 'icons/mob/cameramob.dmi'
	eyeobj.icon_state = "clockcult_camera"
	eyeobj.invisibility = INVISIBILITY_OBSERVER

/obj/machinery/computer/camera_advanced/clockcult_mass_teleporter/GrantActions(mob/living/carbon/user)
	. = ..()
	beam_down.Grant(user)
	actions += beam_down

/datum/action/innate/clockcult_mass_teleport
	name = "Deploy"
	icon_icon = 'icons/mob/actions/actions_minor_antag.dmi'
	button_icon_state = "clockcult_teleport"
	var/cooldown_duration = 10 SECONDS
	COOLDOWN_DECLARE(cooldown)

/datum/action/innate/clockcult_mass_teleport/Activate()
	if(!COOLDOWN_FINISHED(src, cooldown))
		to_chat(owner, span_warning("The anchors are cooling off!"))
		return
	COOLDOWN_START(src, cooldown, cooldown_duration)
	for(var/obj/machinery/clockcult_telepad/pad in GLOB.machines)
		if(GLOB.cameranet.checkTurfVis(owner.remote_control.loc))
			pad.prime(owner.remote_control.loc, cooldown_duration)

/obj/machinery/clockcult_telepad
	name = "synchronous anchor"
	desc = "A networked anchor capable of group deployement, only a single being can be teleported per anchor. They are controlled from the ship mass teleporter."
	icon = 'icons/obj/clockwork_objects.dmi'
	icon_state = "tele_pad"
	use_power = NO_POWER_USE

/obj/machinery/clockcult_telepad/proc/restore()
	icon_state = initial(icon_state)

/obj/machinery/clockcult_telepad/proc/prime(turf/target, cooldown)
	icon_state = "tele_pad_primed"
	//TODO.. fluff
	addtimer(CALLBACK(src, .proc/teleport, target, cooldown), 5 SECONDS, TIMER_UNIQUE | TIMER_STOPPABLE)

/obj/machinery/clockcult_telepad/proc/teleport(turf/target, cooldown)
	for(var/mob/teleporte in get_turf(src))
		if(do_teleport(teleporte, target, channel = TELEPORT_CHANNEL_CULT))
			break
	icon_state = "tele_pad_cooldown"
	addtimer(CALLBACK(src, .proc/restore, target), cooldown, TIMER_UNIQUE | TIMER_STOPPABLE)

