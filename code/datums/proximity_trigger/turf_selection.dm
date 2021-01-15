/decl/turf_selection/proc/get_turfs(atom/origin, range)
	return list()

/decl/turf_selection/line/get_turfs(var/atom/origin, range)
	. = list()
	var/center = get_turf(origin)
	if(!center)
		return
	for( var/i = 0 to range)
		center = get_step(center, origin.dir)
		if(!center) // Reached the end of the world most likely
			return
		. += center

/decl/turf_selection/square/get_turfs(var/atom/origin, range)
	. = list()
	var/center = get_turf(origin)
	if(!center)
		return
	for( var/turf/T in trange(range, center))
		. += T


/decl/turf_selection/view/get_turfs(var/atom/origin, range)
	return origin.turfs_in_view(range)


/decl/turf_selection/cone/get_turfs(var/atom/origin, range, angle = 90, vector2/direction = null)
	var/dirmade = FALSE
	if (!direction)
		dirmade = TRUE
		direction = Vector2.NewFromDir(origin.dir)
	. = get_cone(origin, direction, range, angle)
	if (dirmade)
		release_vector(direction)


//Solid line ensures it has no gaps in it
/decl/turf_selection/solidline/get_turfs(var/atom/origin, range, target)
	. = get_line_between(origin, target, FALSE, TRUE)
	for( var/turf/T in .)
		debug_mark_turf(T)