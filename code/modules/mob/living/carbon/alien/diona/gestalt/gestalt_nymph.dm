/mob/living/carbon/alien/diona/proc/gestalt_with(mob/living/carbon/alien/diona/chirp)
	if(!istype(chirp) || chirp == src || istype(chirp.loc, /obj/structure/diona_gestalt) || istype(loc, /obj/structure/diona_gestalt))
		return FALSE
	visible_message("<span class='notice'>\The [chirp] and \the [src] twine together in gestalt!</span>")
	var/obj/structure/diona_gestalt/blob = new(get_turf(src))
	blob.take_nymph(chirp, silent = TRUE)
	blob.take_nymph(src, silent = TRUE)
	return TRUE

/obj/structure/diona_gestalt/proc/take_nymph(mob/living/carbon/alien/diona/chirp, silent)
	if(!silent)
		visible_message("<span class='notice'>\The [chirp] is engulfed by \the [src].</span>")
	nymphs[chirp] = TRUE
	chirp.forceMove(src)
	update_icon()

/obj/structure/diona_gestalt/proc/shed_nymph(mob/living/carbon/alien/diona/nymph, silent, forcefully)
	if(!nymph && LAZYLEN(nymphs))
		nymph = pick(nymphs)
	if(nymph)
		nymphs -= nymph // unsure if pick_n_take() works on assoc lists.
		nymph.dropInto(loc)
		if(!silent)    visible_message("<span class='danger'>\The [nymph] splits away from \the [src]!</span>")
		if(forcefully) nymph.throw_at(get_edge_target_turf(src,pick(GLOB.alldirs)),rand(1,3),rand(3,5))
	check_nymphs()

// If there are less than two nymphs (or if none of the nymphs have players), it isn't a viable gestalt.
/obj/structure/diona_gestalt/proc/check_nymphs()
	if(LAZYLEN(nymphs.len) >= 2)
		for( var/nimp in nymphs)
			var/mob/living/carbon/alien/diona/chirp = nimp
			if(chirp.client)
				return
	visible_message("<span class='danger'>\The [src] has completely split apart!</span>")
	qdel(src)
