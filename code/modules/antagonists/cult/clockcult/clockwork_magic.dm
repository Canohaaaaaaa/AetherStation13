///Attempts to weave a spell into the item (I should have made this entire thing a component in hindsight)
/proc/clockwork_spellweaver(obj/item/target_item, datum/action/item_action/clockwork/choosen_spell, mob/owner)
	var/datum/action/item_action/clockwork/spell = new choosen_spell(target_item)
	spell.Grant(owner)
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
	. = ..()
	var/obj/item/target_item = owner.get_active_held_item()
	if(!target_item || !(target_item.type in CLOCKWORK_ITEM_WHITELIST))
		owner.balloon_alert(owner, "No valid clockwork gear in the active hand!")
		return
	var/spell_choice = input("Pick a spell to weave.", "Clockwork spells") as null|anything in subtypesof(/datum/action/item_action/clockwork)
	clockwork_spellweaver(target_item, spell_choice, owner)

//** Spells bound to items, yet not casted by the UI button, instead the button represents the current cooldown and works as a tip
/datum/action/item_action/clockwork
	background_icon_state = "bg_clock"
	check_flags = AB_CHECK_HANDS_BLOCKED|AB_CHECK_CONSCIOUS
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
	///What/Who are we casting this on
	var/list/target_victims = list()
	COOLDOWN_DECLARE(spell_cooldown)

/datum/action/item_action/clockwork/Grant()
	..()
	button.screen_loc = DEFAULT_CULTSPELLS
	button.moved = DEFAULT_CULTSPELLS
	button.ordered = FALSE
	positioning()

///Called when the user clicks the actions button, DOES NOT necessarly trigger the spell
/datum/action/item_action/clockwork/Trigger() //Duplicate code yikes, fix this
	to_chat(owner, span_bloodcult(spell_description)) //TODO.. cult spans
	if(!IsAvailable())
		return FALSE
	if(SEND_SIGNAL(src, COMSIG_ACTION_TRIGGER, src) & COMPONENT_ACTION_BLOCK_TRIGGER)
		return FALSE
	return TRUE

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
	owner.say(spell_phrase)
	cast(target)
	return TRUE

/datum/action/item_action/clockwork/proc/can_cast(atom/target)
	SHOULD_CALL_PARENT(TRUE)
	if(!IsAvailable())
		return FALSE
	if(!COOLDOWN_FINISHED(src, spell_cooldown))
		//TODO.. chat cue
		return FALSE
	for(var/type in target_type_whitelist)
		if(istype(target, type))
			return TRUE
	return FALSE

/datum/action/item_action/clockwork/proc/cast(atom/target)
	return

/datum/action/item_action/clockwork/bogus
	name = "Debug clockwork action"
	spell_phrase = "VA'NISH!"
	cooldown_duration = 5 SECONDS
	target_type_whitelist = list(/mob)

/datum/action/item_action/clockwork/bogus/cast(atom/target)
	var/mob/living/victim = target
	victim.gib()
