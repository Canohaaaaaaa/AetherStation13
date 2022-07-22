/obj/machinery/computer/shuttle/clockcult
	name = "WIP"
	desc = "WIP."
	shuttleId = "clockcult"
	light_color = LIGHT_COLOR_ORANGE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	flags_1 = NODECONSTRUCT_1

/obj/docking_port/mobile/clockcult
	name = "\the Revenant"
	id = "clockcult"

//Stupid, use default canDock and override with new crashsite docking port
/obj/docking_port/mobile/clockcult/canDock(obj/docking_port/stationary/S)
	return SHUTTLE_CAN_DOCK

/obj/item/clockcult_ramming_designator
	name = "WIP"
	icon = 'icons/obj/device.dmi'
	icon_state = "gangtool-orange"
	inhand_icon_state = "radio"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	desc = "This can't be good..."
	//TODO.. that's probably shitcode
	var/shuttle_id = "clockcult"
	var/dwidth = 14
	var/dheight = 5
	var/width = 20
	var/height = 25
	var/lz_dir = 8


/obj/item/clockcult_ramming_designator/attack_self(mob/living/user)
	var/target_area
	target_area = input("Area to land", "Select a Landing Zone", target_area) as null|anything in GLOB.teleportlocs
	if(!target_area)
		return
	var/area/picked_area = GLOB.teleportlocs[target_area]
	if(!src || QDELETED(src))
		return

	var/list/turfs = get_area_turfs(picked_area)
	if (!length(turfs))
		return
	var/turf/T = pick(turfs)
	var/obj/docking_port/stationary/landing_zone = new /obj/docking_port/stationary(T)
	landing_zone.id = "clockcult_ship([REF(src)])"
	landing_zone.port_destinations = "clockcult_ship([REF(src)])"
	landing_zone.name = "Clockcult breach site"
	landing_zone.dwidth = dwidth
	landing_zone.dheight = dheight
	landing_zone.width = width
	landing_zone.height = height
	landing_zone.setDir(lz_dir)

	for(var/obj/machinery/computer/shuttle/S in GLOB.machines)
		if(S.shuttleId == shuttle_id)
			S.possible_destinations = "[landing_zone.id]"

	to_chat(user, span_notice("Landing zone set."))

	qdel(src)
