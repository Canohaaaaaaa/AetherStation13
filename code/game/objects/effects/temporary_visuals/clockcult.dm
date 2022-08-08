/obj/effect/temp_visual/clockcult
	icon = 'icons/effects/clockcult_effects.dmi'
	randomdir = FALSE

/obj/effect/temp_visual/clockcult/kindle
	duration = 2 SECONDS
	icon_state = "kindle"
	alpha = 0
	var/effect_color = "#d000ff"

/obj/effect/temp_visual/clockcult/kindle/Initialize(mapload)
	. = ..()
	add_atom_colour(effect_color, FIXED_COLOUR_PRIORITY)
	transform = matrix().Scale(4, 4)
	var/matrix/scale_down = matrix().Scale(2, 2)
	animate(src, time = duration, alpha = 255, transform = scale_down.Turn(181), flags = ANIMATION_PARALLEL | ANIMATION_LINEAR_TRANSFORM)

/obj/effect/temp_visual/clockcult/teleport_in
	duration = 5 SECONDS
	icon_state = "teleporting"
	alpha = 0

/obj/effect/temp_visual/clockcult/teleport_in/Initialize(mapload)
	. = ..()
	animate(src, time = 3 SECONDS, alpha = 255)

/obj/effect/temp_visual/clockcult/converted_door
	icon_state = "ratvardoorglow"
	duration = 3 SECONDS

/obj/effect/temp_visual/clockcult/converted_floor
	icon_state = "ratvarfloorglow"
	duration = 3 SECONDS

/obj/effect/temp_visual/clockcult/converted_wall
	icon_state = "ratvarwallglow"
	duration = 3 SECONDS

/obj/effect/temp_visual/clockcult/converted_window_f
	icon_state = "ratvarwindowglow"
	duration = 3 SECONDS

/obj/effect/temp_visual/clockcult/converted_window_s
	icon_state = "ratvarwindowglow_s"
	duration = 3 SECONDS
