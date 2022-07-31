///List of every item allowed to be imbued with clockwork spells
#define CLOCKWORK_ITEM_WHITELIST list( \
	/obj/item/melee/clockwork_spear, \
	/obj/item/crowbar/power/clockwork, \
	/obj/item/weldingtool/experimental/clockwork, \
	/obj/item/screwdriver/power/clockwork, \
	/obj/item/multitool/clockwork, \
)

/obj/item/melee/clockwork_spear
	name = "WIP"
	icon = 'icons/obj/clockwork_objects.dmi'
	lefthand_file = 'icons/mob/inhands/antag/clockwork_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/antag/clockwork_righthand.dmi'
	icon_state = "ratvarian_spear" //TODO.. find sprites to make this an ACTUAL spear
	force = 15
	throwforce = 25
	armour_penetration = 35
	w_class = WEIGHT_CLASS_SMALL
	worn_icon_state = "" //TODO.. worn icon
	inhand_icon_state = ""//TODO.. inhand off icon_state
	var/datum/action/item_action/clockwork/stored_spell

	/// "On" sound, played when switching between states
	var/on_sound
	/// Are we on or off?
	var/on = TRUE
	/// What is our sprite when turned on
	var/on_icon_state = "ratvarian_spear"
	/// What is our sprite when turned off
	var/off_icon_state = "truesight_lens"
	/// What is our in-hand sprite when turned on
	var/on_inhand_icon_state =  "ratvarian_spear"
	/// Damage when on - not stunning
	var/force_on = 15
	/// Damage when off - not stunning
	var/force_off = 5
	/// What is the new size class when turned on
	var/weight_class_on = WEIGHT_CLASS_BULKY

/obj/item/melee/clockwork_spear/Initialize()
	. = ..()
	//TODO.. butchering?
	RegisterSignal(src, COMSIG_ITEM_WEAVE_SPELL, .proc/spell_link)

/obj/item/melee/clockwork_spear/afterattack_secondary(atom/target, mob/user, proximity_flag, click_parameters)
	if(!stored_spell)
		return COMPONENT_SECONDARY_CONTINUE_ATTACK_CHAIN
	if(stored_spell.spell_trigger(target))
		return COMPONENT_SECONDARY_CANCEL_ATTACK_CHAIN
	return COMPONENT_SECONDARY_CONTINUE_ATTACK_CHAIN

/obj/item/melee/clockwork_spear/attack_self(mob/user, modifiers)
	on = !on

	if(on)
		force = force_on
		throwforce = initial(throwforce)
		w_class = weight_class_on
		icon_state = initial(icon_state)
		inhand_icon_state = on_inhand_icon_state
		armour_penetration = initial(armour_penetration)
		worn_icon_state = initial(worn_icon_state)
	else
		force = force_off
		throwforce = 2 //Is that too low?
		w_class = initial(w_class)
		icon_state = off_icon_state
		inhand_icon_state = ""
		armour_penetration = 0
		worn_icon_state = ""
		inhand_icon_state = initial(inhand_icon_state)
	//playsound(src.loc, on_sound, 50, TRUE) TODO.. SFX
	add_fingerprint(user)
	update_icon_state()

/obj/item/melee/clockwork_spear/proc/spell_link(source, spell)
	if(stored_spell)
		qdel(stored_spell)
	stored_spell = spell

///Has the special recharging property of the experimental while being slightly slower
/obj/item/weldingtool/experimental/clockwork
	name = "WIP"
	desc = "WIP"
	icon = 'icons/obj/clocktools.dmi'
	icon_state = "brasswelder"
	toolspeed = 0.75
	light_color = LIGHT_COLOR_PURPLE
	light_power = 1
	light_range = 2.5
	change_icons = TRUE
	var/datum/action/item_action/clockwork/stored_spell

/obj/item/weldingtool/experimental/clockwork/Initialize()
	. = ..()
	//TODO.. butchering?
	RegisterSignal(src, COMSIG_ITEM_WEAVE_SPELL, .proc/spell_link)

/obj/item/weldingtool/experimental/clockwork/proc/spell_link(source, spell)
	if(stored_spell)
		qdel(stored_spell)
	stored_spell = spell

/obj/item/weldingtool/experimental/clockwork/afterattack_secondary(atom/target, mob/user, proximity_flag, click_parameters)
	if(!stored_spell)
		return COMPONENT_SECONDARY_CONTINUE_ATTACK_CHAIN
	if(stored_spell.spell_trigger(target))
		return COMPONENT_SECONDARY_CANCEL_ATTACK_CHAIN
	return COMPONENT_SECONDARY_CONTINUE_ATTACK_CHAIN

/obj/item/crowbar/power/clockwork
	name = "WIP"
	desc = "WIP"
	icon = 'icons/obj/clocktools.dmi'
	icon_state = "jaws_cutter_brass"
	force_opens = FALSE
	icon_state_cutter = "jaws_cutter_brass"
	icon_state_crowbar = "jaws_pry_brass"
	var/datum/action/item_action/clockwork/stored_spell

/obj/item/crowbar/power/clockwork/Initialize()
	. = ..()
	RegisterSignal(src, COMSIG_ITEM_WEAVE_SPELL, .proc/spell_link)

/obj/item/crowbar/power/clockwork/afterattack_secondary(atom/target, mob/user, proximity_flag, click_parameters)
	if(!stored_spell)
		return COMPONENT_SECONDARY_CONTINUE_ATTACK_CHAIN
	if(stored_spell.spell_trigger(target))
		return COMPONENT_SECONDARY_CANCEL_ATTACK_CHAIN
	return COMPONENT_SECONDARY_CONTINUE_ATTACK_CHAIN

/obj/item/crowbar/power/clockwork/proc/spell_link(source, spell)
	if(stored_spell)
		qdel(stored_spell)
	stored_spell = spell
	icon_state_cutter = "jaws_cutter_brass_powered"
	icon_state_crowbar = "jaws_pry_brass_powered"

/obj/item/screwdriver/power/clockwork
	name = "WIP"
	desc = "WIP"
	icon = 'icons/obj/clocktools.dmi'
	icon_state = "brassdrill_screw"
	var/datum/action/item_action/clockwork/stored_spell

/obj/item/screwdriver/power/clockwork/Initialize()
	. = ..()
	RegisterSignal(src, COMSIG_ITEM_WEAVE_SPELL, .proc/spell_link)

/obj/item/screwdriver/power/clockwork/attack_self(mob/user)
	playsound(get_turf(user), 'sound/items/change_drill.ogg', 50, TRUE)
	if(tool_behaviour == TOOL_SCREWDRIVER)
		tool_behaviour = TOOL_WRENCH
		balloon_alert(user, "attached bolt bit")
		icon_state = "brassdrill_bolt"
	else
		tool_behaviour = TOOL_SCREWDRIVER
		balloon_alert(user, "attached screw bit")
		icon_state = "brassdrill_screw"

/obj/item/screwdriver/power/clockwork/afterattack_secondary(atom/target, mob/user, proximity_flag, click_parameters)
	if(!stored_spell)
		return COMPONENT_SECONDARY_CONTINUE_ATTACK_CHAIN
	if(stored_spell.spell_trigger(target))
		return COMPONENT_SECONDARY_CANCEL_ATTACK_CHAIN
	return COMPONENT_SECONDARY_CONTINUE_ATTACK_CHAIN

/obj/item/screwdriver/power/clockwork/proc/spell_link(source, spell)
	if(stored_spell)
		qdel(stored_spell)
	stored_spell = spell


/obj/item/multitool/clockwork
	name = "WIP"
	desc = "WIP"
	icon = 'icons/obj/clockwork_objects.dmi'
	lefthand_file = 'icons/mob/inhands/antag/clockwork_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/antag/clockwork_righthand.dmi'
	icon_state = "dread_ipad" //Nice name
	inhand_icon_state = "clockwork_slab"
	var/datum/action/item_action/clockwork/stored_spell

/obj/item/multitool/clockwork/Initialize()
	. = ..()
	RegisterSignal(src, COMSIG_ITEM_WEAVE_SPELL, .proc/spell_link)

/obj/item/multitool/clockwork/afterattack_secondary(atom/target, mob/user, proximity_flag, click_parameters)
	if(!stored_spell)
		return COMPONENT_SECONDARY_CONTINUE_ATTACK_CHAIN
	if(stored_spell.spell_trigger(target))
		return COMPONENT_SECONDARY_CANCEL_ATTACK_CHAIN
	return COMPONENT_SECONDARY_CONTINUE_ATTACK_CHAIN

/obj/item/multitool/clockwork/proc/spell_link(source, spell)
	if(stored_spell)
		qdel(stored_spell)
	stored_spell = spell

