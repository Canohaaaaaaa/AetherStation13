/datum/antagonist/cult/bloodcult
	name = "Cultist"
	roundend_category = "cultists"
	antagpanel_category = "Cult"
	suicide_cry = "FOR NAR'SIE!!"
	job_rank = ROLE_CULTIST
	antag_hud_type = ANTAG_HUD_CULT_BLOOD
	antag_hud_name = "cult"
	greet_alert = 'sound/ambience/antag/bloodcult.ogg'
	standard_gear = list(/obj/item/melee/cultblade/dagger)
	additional_gear = list(/obj/item/stack/sheet/runed_metal/ten)
	var/datum/action/innate/cult/blood_magic/magic = new

/datum/antagonist/cult/bloodcult/on_gain()
	. = ..()
	var/mob/living/current = owner.current
	add_objectives()
	if(give_equipment)
		equip_cultist(TRUE)
	current.log_message("has been converted to the cult of Nar'Sie!", LOG_ATTACK, color="#960000")
	var/datum/team/cult/bloodcult/cult_team = src.cult_team
	if(cult_team.blood_target && cult_team.blood_target_image && current.client)
		current.client.images += cult_team.blood_target_image

/datum/antagonist/cult/bloodcult/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = owner.current
	current.faction |= "cult"
	current.grant_language(/datum/language/narsie, TRUE, TRUE, LANGUAGE_CULTIST)
	if(!cult_team.cult_master)
		vote.Grant(current)
	communion.Grant(current)
	if(ishuman(current))
		magic.Grant(current)
	current.throw_alert("bloodsense", /atom/movable/screen/alert/bloodsense)
	if(cult_team.cult_risen)
		cult_team.rise(current)
		if(cult_team.cult_ascendent)
			cult_team.ascend(current)

/datum/antagonist/cult/bloodcult/remove_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = owner.current
	current.faction -= "cult"
	current.remove_language(/datum/language/narsie, TRUE, TRUE, LANGUAGE_CULTIST)
	vote.Remove(current)
	communion.Remove(current)
	magic.Remove(current)
	current.clear_alert("bloodsense")
	if(ishuman(current))
		var/mob/living/carbon/human/H = current
		H.eye_color = initial(H.eye_color)
		H.dna.update_ui_block(DNA_EYE_COLOR_BLOCK)
		REMOVE_TRAIT(H, TRAIT_CULT_EYES, CULT_TRAIT)
		H.remove_overlay(HALO_LAYER)
		H.update_body()

/datum/antagonist/cult/bloodcult/on_removal()
	if(!silent)
		owner.current.visible_message(span_deconversion_message("<span class'warningplain'>[owner.current] looks like [owner.current.p_theyve()] just reverted to [owner.current.p_their()] old faith!</span>"), null, null, null, owner.current)
		to_chat(owner.current, span_userdanger("An unfamiliar white light flashes through your mind, cleansing the taint of the Geometer and all your memories as her servant."))
		owner.current.log_message("has renounced the cult of Nar'Sie!", LOG_ATTACK, color="#960000")
	var/datum/team/cult/bloodcult/cult_team = src.cult_team
	if(cult_team.blood_target && cult_team.blood_target_image && owner.current.client)
		owner.current.client.images -= cult_team.blood_target_image
	. = ..()

/datum/antagonist/cult/bloodcult/get_admin_commands()
	. = ..()
	.["Dagger"] = CALLBACK(src,.proc/admin_give_dagger)
	.["Dagger and Metal"] = CALLBACK(src,.proc/admin_give_metal)
	.["Remove Dagger and Metal"] = CALLBACK(src, .proc/admin_take_all)

/datum/antagonist/cult/bloodcult/proc/admin_give_dagger(mob/admin)
	if(!equip_cultist(roundstart=FALSE))
		to_chat(admin, span_danger("Spawning dagger failed!"))

/datum/antagonist/cult/bloodcult/proc/admin_give_metal(mob/admin)
	if (!equip_cultist(roundstart=TRUE))
		to_chat(admin, span_danger("Spawning runed metal failed!"))

/datum/antagonist/cult/bloodcult/proc/admin_take_all(mob/admin)
	var/mob/living/current = owner.current
	for(var/o in current.get_all_contents())
		if(istype(o, /obj/item/melee/cultblade/dagger) || istype(o, /obj/item/stack/sheet/runed_metal))
			qdel(o)

/datum/antagonist/cult/bloodcult/master
	ignore_implant = TRUE
	show_in_antagpanel = FALSE //Feel free to add this later
	var/datum/action/innate/cult/bloodcult/master/finalreck/reckoning = new
	var/datum/action/innate/cult/bloodcult/master/cultmark/bloodmark = new
	var/datum/action/innate/cult/bloodcult/master/pulse/throwing = new

/datum/antagonist/cult/bloodcult/master/bloodcult/on_gain()
	. = ..()
	var/mob/living/current = owner.current
	set_antag_hud(current, "cultmaster")

/datum/antagonist/cult/bloodcult/master/greet()
	to_chat(owner.current, "<span class='warningplain'><span class='bloodcultlarge'>You are the cult's Master</span>. As the cult's Master, you have a unique title and loud voice when communicating, are capable of marking \
	targets, such as a location or a noncultist, to direct the cult to them, and, finally, you are capable of summoning the entire living cult to your location <b><i>once</i></b>. Use these abilities to direct the cult to victory at any cost.</span>")

/datum/antagonist/cult/bloodcult/master/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = owner.current
	if(mob_override)
		current = mob_override
	if(!cult_team.reckoning_complete)
		reckoning.Grant(current)
	bloodmark.Grant(current)
	throwing.Grant(current)
	current.update_action_buttons_icon()
	current.apply_status_effect(/datum/status_effect/cult_master)
	if(cult_team.cult_risen)
		cult_team.rise(current)
		if(cult_team.cult_ascendent)
			cult_team.ascend(current)

/datum/antagonist/cult/bloodcult/master/remove_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = owner.current
	if(mob_override)
		current = mob_override
	reckoning.Remove(current)
	bloodmark.Remove(current)
	throwing.Remove(current)
	current.update_action_buttons_icon()
	current.remove_status_effect(/datum/status_effect/cult_master)

/datum/antagonist/cult/bloodcult/master/Destroy()
	QDEL_NULL(reckoning)
	QDEL_NULL(bloodmark)
	QDEL_NULL(throwing)
	return ..()

/datum/team/cult/bloodcult
	name = "Cult"
	rise_eye_color = "f00"
	cult_team_type = /datum/team/cult/bloodcult
	var/blood_target
	var/image/blood_target_image
	var/blood_target_reset_timer

/datum/team/cult/bloodcult/setup_objectives()
	var/datum/objective/sacrifice/bloodcult/sacrifice_objective = new
	sacrifice_objective.team = src
	sacrifice_objective.find_target()
	objectives += sacrifice_objective

	var/datum/objective/geometer/summon_objective = new
	summon_objective.team = src
	objectives += summon_objective

/datum/team/cult/bloodcult/roundend_report()
	var/list/parts = list()
	var/victory = check_cult_victory()

	if(victory == CULT_NARSIE_KILLED) // Epic failure, you summoned your god and then someone killed it.
		parts += "<span class='redtext big'>Nar'sie has been killed! The cult will haunt the universe no longer!</span>"
	else if(victory)
		parts += "<span class='greentext big'>The cult has succeeded! Nar'Sie has snuffed out another torch in the void!</span>"
	else
		parts += "<span class='redtext big'>The staff managed to stop the cult! Dark words and heresy are no match for Nanotrasen's finest!</span>"

	if(objectives.len)
		parts += "<b>The cultists' objectives were:</b>"
		var/count = 1
		for(var/datum/objective/objective in objectives)
			if(objective.check_completion())
				parts += "<b>Objective #[count]</b>: [objective.explanation_text] [span_greentext("Success!")]"
			else
				parts += "<b>Objective #[count]</b>: [objective.explanation_text] [span_redtext("Fail.")]"
			count++

	if(members.len)
		parts += "<span class='header'>The cultists were:</span>"
		parts += printplayerlist(members)

	return "<div class='panel redborder'>[parts.Join("<br>")]</div>"

/datum/objective/geometer
	var/summoned = FALSE
	var/killed = FALSE
	var/list/summon_spots = list()

/datum/objective/geometer/New()
	..()
	var/sanity = 0
	while(summon_spots.len < SUMMON_POSSIBILITIES && sanity < 100) //what the fuck is a sanity???
		var/area/summon_area = pick(GLOB.sortedAreas - summon_spots)
		if(summon_area && is_station_level(summon_area.z) && (summon_area.area_flags & VALID_TERRITORY))
			summon_spots += summon_area
		sanity++
	update_explanation_text()

/datum/objective/geometer/update_explanation_text()
	explanation_text = "Summon Nar'Sie by invoking the rune 'Summon Nar'Sie'. <b>The summoning can only be accomplished in [english_list(summon_spots)] - where the veil is weak enough for the ritual to begin.</b>"

/datum/objective/geometer/check_completion()
	if(killed)
		return CULT_NARSIE_KILLED // You failed so hard that even the code went backwards.
	return summoned || completed

/datum/objective/sacrifice/bloodcult

/datum/objective/sacrifice/bloodcult/check_completion()
	return sacced || completed

/datum/objective/sacrifice/bloodcult/update_explanation_text() //TODO.. more flavour
	if(target)
		explanation_text = "Sacrifice [target], the [target.assigned_role.title] via invoking an Offer rune with [target.p_them()] on it and three acolytes around it."
	else
		explanation_text = "The veil has already been weakened here, proceed to the final objective."

/datum/objective/sacrifice/bloodcult/find_target(dupe_search_range)
	if(!istype(team, /datum/team/cult))
		return
	var/datum/team/cult/cult = team
	var/list/target_candidates = list()
	for(var/mob/living/carbon/human/player in GLOB.player_list)
		if(player.mind && !player.mind.has_antag_datum(/datum/antagonist/cult) && !is_convertable_to_cult(player) && player.stat != DEAD)
			target_candidates += player.mind
	if(target_candidates.len == 0)
		message_admins("Cult Sacrifice: Could not find unconvertible target, checking for convertible target.")
		for(var/mob/living/carbon/human/player in GLOB.player_list)
			if(player.mind && !player.mind.has_antag_datum(/datum/antagonist/cult) && player.stat != DEAD)
				target_candidates += player.mind
	list_clear_nulls(target_candidates)
	if(LAZYLEN(target_candidates))
		target = pick(target_candidates)
		update_explanation_text()
	else
		message_admins("Cult Sacrifice: Could not find unconvertible or convertible target. WELP!")
	cult.make_image(src)
	for(var/datum/mind/mind in cult.members)
		if(mind.current)
			mind.current.clear_alert("bloodsense")
			mind.current.throw_alert("bloodsense", /atom/movable/screen/alert/bloodsense)
