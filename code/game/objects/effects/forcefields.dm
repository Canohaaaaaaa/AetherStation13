/obj/effect/forcefield
	desc = "A space wizard's magic wall."
	name = "FORCEWALL"
	icon_state = "m_shield"
	anchored = TRUE
	opacity = FALSE
	density = TRUE
	CanAtmosPass = ATMOS_PASS_DENSITY
	var/timeleft = 300 //Set to 0 for permanent forcefields (ugh)

/obj/effect/forcefield/Initialize()
	. = ..()
	if(timeleft)
		QDEL_IN(src, timeleft)

/obj/effect/forcefield/singularity_pull()
	return

/obj/effect/forcefield/clockcult
	desc = "The cogs of a machine you cannot comprehend."
	name = "Shifting gear"
	icon = 'icons/obj/clockwork_objects.dmi'
	icon_state = "wall_gear"
	timeleft = 10 SECONDS
	alpha = 180

/obj/effect/forcefield/cult
	desc = "An unholy shield that blocks all attacks."
	name = "glowing wall"
	icon = 'icons/effects/bloodcult_effects.dmi'
	icon_state = "cultshield"
	CanAtmosPass = ATMOS_PASS_NO
	timeleft = 200

/// A form of the cult forcefield that lasts permanently.
/// Used on the Shuttle 667.
/obj/effect/forcefield/cult/permanent
	timeleft = 0

///////////Mimewalls///////////

/obj/effect/forcefield/mime
	icon_state = "nothing"
	name = "invisible wall"
	desc = "You have a bad feeling about this."
	alpha = 0

/obj/effect/forcefield/mime/advanced
	name = "invisible blockade"
	desc = "You're gonna be here awhile."
	timeleft = 600
