///List of every item allowed to be imbued with clockwork spells
#define CLOCKWORK_ITEM_WHITELIST list( \
	/obj/item/melee/clockwork/spear, \
)

/obj/item/melee/clockwork/spear
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

/obj/item/melee/clockwork/spear/Initialize()
	. = ..()
	//TODO.. butchering?
	RegisterSignal(src, COMSIG_ITEM_PRE_ATTACK_SECONDARY, .proc/cast_spell)
	RegisterSignal(src, COMSIG_ITEM_WEAVE_SPELL_ATTEMPT, /proc/clockwork_spellweaver)
	RegisterSignal(src, COMSIG_ITEM_WEAVE_SPELL, .proc/spell_link)

/obj/item/melee/clockwork/spear/attack_self(mob/user, modifiers)
	on = !on

	if(on)
		force = force_on
		throwforce = initial(throwforce)
		w_class = weight_class_on
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

/obj/item/melee/clockwork/spear/proc/spell_link(source, spell)
	//TODO.. add enchanted sprite
	stored_spell = spell
	actions_types += spell

/obj/item/melee/clockwork/spear/proc/cast_spell(datum/source, atom/target, mob/user, params)
	if(!stored_spell)
		return COMPONENT_SECONDARY_CALL_NORMAL_ATTACK_CHAIN
	stored_spell.spell_trigger(target)
	return COMPONENT_SECONDARY_CANCEL_ATTACK_CHAIN
