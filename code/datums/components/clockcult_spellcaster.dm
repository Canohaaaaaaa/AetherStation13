//**TODO.. doc this */
/datum/component/clockcult_spellweaver
	var/datum/action/item_action/clockwork/spell

/datum/component/clockcult_spellweaver/Initialize(spell, trigger_signal)
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/clockcult_spellweaver/RegisterWithParent()
	. = ..()

