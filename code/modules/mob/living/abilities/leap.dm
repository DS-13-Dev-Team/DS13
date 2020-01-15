
/*
	Code for generic leap attack

	A subtype of charge, leap performs a charge with a few specific differences:
		1. Homing is always off. Can't change direction in mid air
		2. The user is given PASS_FLAG_TABLE  and PASS_FLAG_FLYING for the duration of the leap, allowing them to fly over many lesser obstacles
		3. The user's layer is set to a higher one, making them draw over most things
		4. Once started, the leap does not stop if the user becomes incapacitated mid air


*/
/datum/extension/charge/leap
	verb_action = "leaps"
	verb_name = "leaping"
	name = "Leap"
	var/cached_pass_flags
	var/cached_plane
	var/cached_transform
	var/vector2/cached_pixel_offset
	continue_check = FALSE	//We're not gonna be stopped if we die mid air, the leap continues til it impacts

/datum/extension/charge/leap/New(var/datum/holder, var/atom/_target, var/_speed , var/_lifespan, var/_maxrange, var/_homing, var/_inertia = FALSE, var/_power, var/_cooldown, var/_delay)
	.=..()
	homing = FALSE



/datum/extension/charge/leap/start()
	cached_pass_flags = user.pass_flags
	cached_plane = user.plane
	cached_transform = user.transform
	cached_pixel_offset = new /vector2(user.pixel_x, user.pixel_y)

	//The sprite moves up into the air and a bit closer to the camera
	animate(user, transform = user.transform.Scale(1.18), pixel_y = user.pixel_y + 24, time = max_lifespan())
	user.pass_flags |= (PASS_FLAG_TABLE | PASS_FLAG_FLYING)
	user.plane = ABOVE_HUMAN_PLANE	//Draw over most mobs and objects
	..()

/datum/extension/charge/leap/stop()
	animate(user, transform = cached_transform, pixel_y = cached_pixel_offset.y, time = 0.5 SECONDS)
	user.pass_flags = cached_pass_flags
	user.plane = cached_plane	//Draw over most mobs and objects
	.=..()


//Triggering
/atom/movable/proc/leap_verb(var/atom/A)
	set name = "Charge"
	set category = "Abilities"


	return leap_attack(A)


/atom/movable/proc/leap_attack(var/atom/_target, var/_speed = 7, var/_lifespan = 2 SECONDS, var/_maxrange = null, var/_homing = FALSE, var/_inertia = FALSE, var/_power = 0, var/_cooldown = 20 SECONDS, var/_delay = 0)
	//First of all, lets check if we're currently able to charge
	if (!can_charge(_target, TRUE))
		return FALSE


	//Ok we've passed all safety checks, let's commence charging!
	//We simply create the extension on the movable atom, and everything works from there
	set_extension(src, /datum/extension/charge/leap, _target, _speed, _lifespan, _maxrange, _homing, _inertia, _power, _cooldown, _delay)

	return TRUE