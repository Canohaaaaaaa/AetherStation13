///List of every item allowed to be imbued with clockwork spells
#define CLOCKWORK_ITEM_WHITELIST list( \
	/obj/item/spear/clockwork, \
)

/obj/item/spear/clockwork
	icon = 'icons/obj/clockwork_objects.dmi'
	icon_state = "ratvarian_spear" //TODO.. find sprites to make this an ACTUAL spear
	var/datum/action/item_action/clockwork/stored_spell

/obj/item/spear/clockwork/Initialize()
	. = ..()
	RegisterSignal(src, COMSIG_ITEM_PRE_ATTACK_SECONDARY, .proc/cast_spell)
	RegisterSignal(src, COMSIG_ITEM_WEAVE_SPELL_ATTEMPT, /proc/clockwork_spellweaver)
	RegisterSignal(src, COMSIG_ITEM_WEAVE_SPELL, .proc/spell_link)

/obj/item/spear/clockwork/proc/spell_link(source, spell)
	//TODO.. add enchanted sprite
	stored_spell = spell
	actions_types += spell

/obj/item/spear/clockwork/proc/cast_spell(datum/source, atom/target, mob/user, params)
	if(!stored_spell)
		return COMPONENT_SECONDARY_CALL_NORMAL_ATTACK_CHAIN
	stored_spell.spell_trigger(target)
	return COMPONENT_SECONDARY_CANCEL_ATTACK_CHAIN

/obj/item/spear/clockwork/update_icon_state()
	return
