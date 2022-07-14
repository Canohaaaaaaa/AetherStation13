#define SUMMON_POSSIBILITIES 3
#define CULT_VICTORY 1
#define CULT_LOSS 0
#define CULT_NARSIE_KILLED -1
#define CULT_RATVAR_KILLED -2

/datum/antagonist/cult
	name = "Cultist"
	roundend_category = "cultists"
	antagpanel_category = "Cult"
	antag_moodlet = /datum/mood_event/cult
	var/datum/action/innate/cult/comm/communion = new
	var/datum/action/innate/cult/mastervote/vote = new
	var/ignore_implant = FALSE
	var/give_equipment = FALSE
	var/datum/team/cult/cult_team
	///Sound that should be played upon conversion/roundstart
	var/greet_alert
	///What gear a cultist should be given when first converted
	var/list/obj/item/standard_gear = list()
	///What gear should they be given roundstart
	var/list/obj/item/additional_gear = list()

/datum/antagonist/cult/get_team()
	return cult_team

/datum/antagonist/cult/create_team(datum/team/cult/new_team)
	if(!new_team)
		//todo remove this and allow admin buttons to create more than one cult
		for(var/datum/antagonist/cult/H in GLOB.antagonists)
			if(!H.owner)
				continue
			if(H.cult_team)
				cult_team = H.cult_team
				return
		cult_team = new /datum/team/cult
		cult_team.setup_objectives()
		return
	if(!istype(new_team))
		stack_trace("Wrong team type passed to [type] initialization.")
	cult_team = new_team

/datum/antagonist/cult/proc/add_objectives()
	objectives |= cult_team.objectives

/datum/antagonist/cult/Destroy()
	QDEL_NULL(communion)
	QDEL_NULL(vote)
	return ..()

/datum/antagonist/cult/can_be_owned(datum/mind/new_owner)
	. = ..()
	if(. && !ignore_implant)
		. = is_convertable_to_cult(new_owner.current,cult_team)

/datum/antagonist/cult/greet()
	to_chat(owner, span_userdanger("You are a member of the cult!"))
	owner.current.playsound_local(get_turf(owner.current), greet_alert, 100, FALSE, pressure_affected = FALSE, use_reverb = FALSE)//subject to change
	owner.announce_objectives()

/datum/antagonist/cult/proc/equip_cultist(roundstart=TRUE)
	var/mob/living/carbon/H = owner.current
	if(!istype(H))
		return
	var/list/obj/item/all_gear = standard_gear
	if(roundstart)
		all_gear += additional_gear
	for(var/obj/item/gear as anything in all_gear)
		. += cult_give_item(gear, H)
	to_chat(owner, "These will help you start the cult on this station. Use them well, and remember - you are not the only one.</span>")


/datum/antagonist/cult/proc/cult_give_item(obj/item/item_path, mob/living/carbon/human/mob)
	var/list/slots = list(
		"backpack" = ITEM_SLOT_BACKPACK,
		"left pocket" = ITEM_SLOT_LPOCKET,
		"right pocket" = ITEM_SLOT_RPOCKET
	)

	var/T = new item_path(mob)
	var/item_name = initial(item_path.name)
	var/where = mob.equip_in_one_of_slots(T, slots)
	if(!where)
		to_chat(mob, span_userdanger("Unfortunately, you weren't able to get a [item_name]. This is very bad and you should adminhelp immediately (press F1)."))
		return FALSE
	else
		to_chat(mob, span_danger("You have a [item_name] in your [where]."))
		if(where == "backpack")
			SEND_SIGNAL(mob.back, COMSIG_TRY_STORAGE_SHOW, mob)
		return TRUE

/datum/antagonist/cult/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = owner.current
	if(mob_override)
		current = mob_override
	add_antag_hud(antag_hud_type, antag_hud_name, current)
	handle_clown_mutation(current, mob_override ? null : "Your training has allowed you to overcome your clownish nature, allowing you to wield weapons without harming yourself.")

/datum/antagonist/cult/remove_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = owner.current
	if(mob_override)
		current = mob_override
	remove_antag_hud(antag_hud_type, current)
	handle_clown_mutation(current, removing = FALSE)

/datum/antagonist/cult/admin_add(datum/mind/new_owner,mob/admin)
	give_equipment = FALSE
	new_owner.add_antag_datum(src)
	var/datum/action/innate/cult/clockwork/debug_action = new //TODO.. remove this
	debug_action.Grant(new_owner.current)
	message_admins("[key_name_admin(admin)] has cult-ed [key_name_admin(new_owner)].")
	log_admin("[key_name(admin)] has cult-ed [key_name(new_owner)].")

/datum/antagonist/cult/admin_remove(mob/user)
	silent = TRUE
	return ..()

/datum/team/cult
	name = "Cult"

	var/rise_eye_color
	var/cult_vote_called = FALSE
	var/mob/living/cult_master
	var/reckoning_complete = FALSE
	var/cult_risen = FALSE
	var/cult_ascendent = FALSE

/datum/team/cult/proc/check_size()
	if(cult_ascendent)
		return
	var/alive = 0
	var/cultplayers = 0
	for(var/I in GLOB.player_list)
		var/mob/M = I
		if(M.stat != DEAD)
			if(IS_CULTIST(M))
				++cultplayers
			else
				++alive
	var/ratio = cultplayers/alive
	if(ratio > CULT_RISEN && !cult_risen)
		for(var/datum/mind/B in members)
			if(B.current)
				SEND_SOUND(B.current, 'sound/hallucinations/i_see_you2.ogg')
				to_chat(B.current, span_bloodcultlarge("<span class='warningplain'>The veil weakens as your cult grows, your eyes begin to glow...</span>")) //TODO.. Flavour text
				addtimer(CALLBACK(src, .proc/rise, B.current), 200)
		cult_risen = TRUE

	if(ratio > CULT_ASCENDENT && !cult_ascendent)
		for(var/datum/mind/B in members)
			if(B.current)
				SEND_SOUND(B.current, 'sound/hallucinations/im_here1.ogg')
				to_chat(B.current, span_bloodcultlarge("<span class='warningplain'>Your cult is ascendent and the red harvest approaches - you cannot hide your true nature for much longer!!</span>"))
				addtimer(CALLBACK(src, .proc/ascend, B.current), 200)
		cult_ascendent = TRUE


/datum/team/cult/proc/rise(cultist)
	if(ishuman(cultist))
		var/mob/living/carbon/human/H = cultist
		H.eye_color = rise_eye_color
		H.dna.update_ui_block(DNA_EYE_COLOR_BLOCK)
		ADD_TRAIT(H, TRAIT_CULT_EYES, CULT_TRAIT) //TODO.. redo the trait check to make sense flavour-wise
		H.update_body()

/datum/team/cult/proc/ascend(cultist) //TODO.. clockwork halo
	if(ishuman(cultist))
		var/mob/living/carbon/human/human = cultist
		new /obj/effect/temp_visual/cult/sparks(get_turf(human), human.dir)
		var/istate = pick("halo1","halo2","halo3","halo4","halo5","halo6")
		var/mutable_appearance/new_halo_overlay = mutable_appearance('icons/effects/32x64.dmi', istate, -HALO_LAYER)
		human.overlays_standing[HALO_LAYER] = new_halo_overlay
		human.apply_overlay(HALO_LAYER)

/datum/team/cult/proc/make_image(datum/objective/sacrifice/sac_objective)
	if(!sac_objective)
		return
	var/datum/job/job_of_sacrifice = sac_objective.target.assigned_role
	var/datum/preferences/prefs_of_sacrifice = sac_objective.target.current.client.prefs
	var/icon/reshape = get_flat_human_icon(null, job_of_sacrifice, prefs_of_sacrifice, list(SOUTH))
	reshape.Shift(SOUTH, 4)
	reshape.Shift(EAST, 1)
	reshape.Crop(7,4,26,31)
	reshape.Crop(-5,-3,26,30)
	sac_objective.sac_image = reshape

/datum/objective/sacrifice/find_target(dupe_search_range)
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

/datum/team/cult/proc/setup_objectives()
	var/datum/objective/sacrifice/sacrifice_objective = new
	sacrifice_objective.team = src
	sacrifice_objective.find_target()
	objectives += sacrifice_objective

	var/datum/objective/eldergod/summon_objective = new
	summon_objective.team = src
	objectives += summon_objective

/datum/objective/sacrifice
	var/sacced = FALSE
	var/sac_image

/datum/objective/sacrifice/check_completion()
	return sacced || completed

/datum/objective/sacrifice/update_explanation_text() //TODO.. more flavour
	if(target)
		explanation_text = "Sacrifice [target], the [target.assigned_role.title] via invoking an Offer rune with [target.p_them()] on it and three acolytes around it."
	else
		explanation_text = "The veil has already been weakened here, proceed to the final objective."

/datum/objective/eldergod
	var/summoned = FALSE
	var/killed = FALSE
	var/list/summon_spots = list()

/datum/objective/eldergod/New()
	..()
	var/sanity = 0
	while(summon_spots.len < SUMMON_POSSIBILITIES && sanity < 100) //what the fuck is a sanity???
		var/area/summon_area = pick(GLOB.sortedAreas - summon_spots)
		if(summon_area && is_station_level(summon_area.z) && (summon_area.area_flags & VALID_TERRITORY))
			summon_spots += summon_area
		sanity++
	update_explanation_text()

/datum/objective/eldergod/update_explanation_text()
	explanation_text = "Summon Nar'Sie by invoking the rune 'Summon Nar'Sie'. <b>The summoning can only be accomplished in [english_list(summon_spots)] - where the veil is weak enough for the ritual to begin.</b>"

/datum/objective/eldergod/check_completion()
	if(killed)
		return CULT_NARSIE_KILLED // You failed so hard that even the code went backwards.
	return summoned || completed

/datum/team/cult/proc/check_cult_victory()
	for(var/datum/objective/O in objectives)
		if(O.check_completion() == CULT_NARSIE_KILLED || O.check_completion() == CULT_RATVAR_KILLED)
			return O.check_completion()
		else if(!O.check_completion())
			return CULT_LOSS
	return CULT_VICTORY

/datum/team/cult/proc/is_sacrifice_target(datum/mind/mind)
	for(var/datum/objective/sacrifice/sac_objective in objectives)
		if(mind == sac_objective.target)
			return TRUE
	return FALSE

/// Returns whether the given mob is convertable to the blood cult
/proc/is_convertable_to_cult(mob/living/M, datum/team/cult/specific_cult)
	if(!istype(M))
		return FALSE
	if(M.mind)
		if(ishuman(M) && (M.mind.holy_role))
			return FALSE
		if(specific_cult?.is_sacrifice_target(M.mind))
			return FALSE
		if(M.mind.enslaved_to && !IS_CULTIST(M.mind.enslaved_to))
			return FALSE
		if(M.mind.unconvertable)
			return FALSE
	else
		return FALSE
	if(HAS_TRAIT(M, TRAIT_MINDSHIELD) || issilicon(M) || isbot(M) || isdrone(M) || !M.client)
		return FALSE //can't convert machines, shielded, or braindead
	return TRUE
