///Redo this shitcode
#define CLOCKWORK_SPELL_LIST list( \
	/datum/action/item_action/clockwork/bogus, \
)

///Attempts to weave a spell into the item (I should have made this entire thing a component in hindsight)
/proc/clockwork_spellweaver(obj/item/target_item, datum/action/item_action/clockwork/choosen_spell, mob/owner)
	var/datum/action/item_action/clockwork/spell = new choosen_spell(target_item)
	ower.Grant(spell)
	SEND_SIGNAL(target_item, COMSIG_ITEM_WEAVE_SPELL, spell)

/datum/action/innate/cult/clockwork
	background_icon_state = "bg_clock"
	icon_icon = 'icons/obj/clockwork_objects.dmi'
	button_icon_state = "wall_gear"
	desc = "Weave a powerful spell into your gear. It is quicker in the <b>Requiem</b>."

/datum/action/innate/cult/clockwork/Grant()
	. = ..()
	button.screen_loc = DEFAULT_BLOODSPELLS
	button.moved = DEFAULT_BLOODSPELLS
	button.ordered = FALSE
	button.locked = TRUE

/datum/action/innate/cult/clockwork/Activate()
	. = ..()
	var/obj/item/target_item = owner.get_active_held_item()
	if(!(target_item.type in CLOCKWORK_ITEM_WHITELIST))
		return
	var/spell_choice = input("Pick a spell to weave.", "Clockwork spells") as null|anything in CLOCKWORK_SPELL_LIST
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

///Called when the user clicks the actions button, DOES NOT necessarly trigger the spell
/datum/action/item_action/clockwork/Trigger() //Duplicate code yikes, fix this
	to_chat(owner, span_cult(spell_description)) //TODO.. cult spans
	if(!IsAvailable())
		return FALSE
	if(SEND_SIGNAL(src, COMSIG_ACTION_TRIGGER, src) & COMPONENT_ACTION_BLOCK_TRIGGER)
		return FALSE
	return TRUE

/datum/action/item_action/clockwork/proc/spell_trigger(atom/target)
	if(!can_cast(target))
		return
	COOLDOWN_START(src, spell_cooldown, cooldown_duration)
	owner.say(spell_phrase)
	cast(target)

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
