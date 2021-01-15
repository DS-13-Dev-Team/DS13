/obj/structure/displaycase
	name = "display case"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "glassbox"
	desc = "A display case for prized possessions. It taunts you to kick it."
	density = 1
	anchored = 1
	unacidable = 1//Dissolving the case would also delete the gun.
	alpha = 150
	health = 20
	resistance = 10
	var/destroyed = 0

/obj/structure/displaycase/Initialize()
	. = ..()
	var/turf/T = get_turf(src)
	for( var/atom/movable/AM in T)
		if(AM.simulated && !AM.anchored)
			AM.forceMove(src)
	update_icon()

/obj/structure/displaycase/examine(user)
	..()
	if(contents.len)
		to_chat(user, "Inside you see [english_list(contents)].")



/obj/structure/displaycase/take_damage(amount, damtype = BRUTE, user, used_weapon, bypass_resist)
	.=..()
	playsound(src.loc, 'sound/effects/Glasshit.ogg', 75, 1)

/obj/structure/displaycase/zero_health()
	if (!destroyed)
		set_density(0)
		destroyed = 1
		new /obj/item/weapon/material/shard(loc)
		for( var/atom/movable/AM in src)
			AM.dropInto(loc)
		playsound(src, "shatter", 70, 1)
		update_icon()

/obj/structure/displaycase/update_icon()
	if(destroyed)
		icon_state = "glassboxb"
	else
		icon_state = "glassbox"
	underlays.Cut()
	for( var/atom/movable/AM in contents)
		underlays += AM.appearance

