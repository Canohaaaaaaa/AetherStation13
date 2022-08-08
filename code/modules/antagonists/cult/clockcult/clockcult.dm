/datum/antagonist/cult/clockcult
	//name = "Cultist"
	//roundend_category = "cultists"
	//antagpanel_category = "Cult"
	suicide_cry = "FOR RATVAR!!"
	job_rank = ROLE_CULTIST
	antag_hud_type = ANTAG_HUD_CULT_CLOCK
	antag_hud_name = "cult"
	greet_alert = 'sound/ambience/antag/clockcultalr.ogg'
	standard_gear = list(/obj/item/melee/clockwork_spear)
	additional_gear = list(/obj/item/clockcult_relay_kit)
	var/datum/action/innate/cult/clockwork/magic = new

/datum/antagonist/cult/clockcult/on_gain()
	. = ..()
	var/mob/living/current = owner.current
	add_objectives()
	if(give_equipment)
		equip_cultist(TRUE)
	current.log_message("has been converted to the cult of Ratvar!", LOG_ATTACK, color="#c77a07")
	var/datum/team/cult/clockcult/cult_team = src.cult_team
	//TODO.. COG sense

/datum/antagonist/cult/clockcult/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = owner.current
	//current.faction |= "cult"
	current.grant_language(/datum/language/narsie, TRUE, TRUE, LANGUAGE_CULTIST) //TODO.. redo ratvarian (hopefully never)
	if(!cult_team.cult_master)
		vote.Grant(current)
	//communion.Grant(current)
	if(ishuman(current))
		magic.Grant(current)
	//current.throw_alert("bloodsense", /atom/movable/screen/alert/bloodsense)
	if(cult_team.cult_risen)
		cult_team.rise(current)
		if(cult_team.cult_ascendent)
			cult_team.ascend(current)

/datum/antagonist/cult/clockcult/remove_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = owner.current
	//current.faction -= "cult"
	current.remove_language(/datum/language/narsie, TRUE, TRUE, LANGUAGE_CULTIST)
	vote.Remove(current)
	//communion.Remove(current)
	magic.Remove(current)
	//current.clear_alert("bloodsense")
	if(ishuman(current))
		var/mob/living/carbon/human/H = current
		H.eye_color = initial(H.eye_color)
		H.dna.update_ui_block(DNA_EYE_COLOR_BLOCK)
		REMOVE_TRAIT(H, TRAIT_CULT_EYES, CULT_TRAIT)
		H.remove_overlay(HALO_LAYER)
		H.update_body()

/datum/team/cult/clockcult
	name ="the pipes the pipes the pipes"
