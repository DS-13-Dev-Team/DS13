/turf/simulated/wall/r_wall
	icon_state = "rgeneric"

/turf/simulated/wall/r_wall/New(newloc)
	..(newloc, MATERIAL_PLASTEEL,MATERIAL_PLASTEEL) //3strong


/turf/simulated/wall/r_wall/rglass_wall/New(newloc) //Structural, but doesn't impede line of sight. Fairly pretty anyways.
	..(newloc, "rglass", "steel")
	icon_state = "rgeneric"

/turf/simulated/wall/r_wall/hull
	name = "hull"
	color = COLOR_HULL

/turf/simulated/wall/prepainted
	paint_color = COLOR_GUNMETAL
/turf/simulated/wall/r_wall/prepainted
	paint_color = COLOR_GUNMETAL

/turf/simulated/wall/r_wall/hull/Initialize()
	. = ..()
	paint_color = color
	color = null //color is just for mapping
	if(prob(40))
		var/spacefacing = FALSE
		for(var/direction in GLOB.cardinal)
			var/turf/T = get_step(src, direction)
			var/area/A = get_area(T)
			if(A && (A.area_flags & AREA_FLAG_EXTERNAL))
				spacefacing = TRUE
				break
		if(spacefacing)
			var/bleach_factor = rand(10,50)
			paint_color = adjust_brightness(paint_color, bleach_factor)
	update_icon()



/turf/simulated/wall/cult
	icon_state = "cult"
	blend_turfs = list(/turf/simulated/wall)

/turf/simulated/wall/cult/New(newloc, reinforce = 0)
	..(newloc,"cult",reinforce ? "cult2" : null)

/turf/simulated/wall/cult/reinf/New(newloc)
	..(newloc, 1)

/turf/simulated/wall/cult/dismantle_wall()
	GLOB.cult.remove_cultiness(CULTINESS_PER_TURF)
	..()

/turf/simulated/wall/cult/can_join_with(turf/simulated/wall/W)
	if(material && W.material && material.icon_base == W.material.icon_base)
		return 1
	else if(istype(W, /turf/simulated/wall))
		return 1
	return 0

/turf/unsimulated/wall/cult
	name = "cult wall"
	desc = "Hideous images dance beneath the surface."
	icon = 'icons/turf/wall_masks.dmi'
	icon_state = "cult"

/turf/simulated/wall/iron/New(newloc)
	..(newloc,"iron")

/turf/simulated/wall/uranium/New(newloc)
	..(newloc,"uranium")

/turf/simulated/wall/diamond/New(newloc)
	..(newloc,MATERIAL_DIAMOND)

/turf/simulated/wall/gold/New(newloc)
	..(newloc,MATERIAL_GOLD)

/turf/simulated/wall/silver/New(newloc)
	..(newloc,MATERIAL_SILVER)

/turf/simulated/wall/phoron/New(newloc)
	..(newloc,MATERIAL_PHORON)

/turf/simulated/wall/sandstone/New(newloc)
	..(newloc,MATERIAL_SANDSTONE)

/turf/simulated/wall/wood/New(newloc)
	..(newloc,"wood")

/turf/simulated/wall/ironphoron/New(newloc)
	..(newloc,"iron",MATERIAL_PHORON)

/turf/simulated/wall/golddiamond/New(newloc)
	..(newloc,MATERIAL_GOLD,MATERIAL_DIAMOND)

/turf/simulated/wall/silvergold/New(newloc)
	..(newloc,MATERIAL_SILVER,MATERIAL_GOLD)

/turf/simulated/wall/sandstonediamond/New(newloc)
	..(newloc,MATERIAL_SANDSTONE,MATERIAL_DIAMOND)


// Kind of wondering if this is going to bite me in the butt.
/turf/simulated/wall/voxshuttle/New(newloc)
	..(newloc,"voxalloy")
/turf/simulated/wall/voxshuttle/attackby()
	return
/turf/simulated/wall/titanium/New(newloc)
	..(newloc,MATERIAL_TITANIUM)

/turf/simulated/wall/alium
	icon_state = "jaggy"
	floor_type = /turf/simulated/floor/fixed/alium
	list/blend_objects = newlist()

/turf/simulated/wall/alium/New(newloc)
	..(newloc,"aliumium")

/turf/simulated/wall/alium/ex_act(severity)
	if(prob(explosion_resistance))
		return
	..()