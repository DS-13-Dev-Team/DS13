/*

	Regenerate ability, used by Ubermorph

	Regrows one limb (with a cool animation), regrows all internal organs, and heals some overall damage.
	The user can't move while its happening

*/
/datum/extension/regenerate
	name = "Regenerate"
	var/verb_name = "regenerating"
	expected_type = /mob/living/carbon/human
	flags = EXTENSION_FLAG_IMMEDIATE
	var/mob/living/carbon/human/user

	var/duration = 5 SECONDS
	var/max_limbs = 1
	var/cooldown = 0
	var/heal_amount = 40
	var/tick_interval = 0.2 SECONDS
	var/shake_interval = 0.6 SECONDS

	//Runtime stuff
	var/list/regenerating_organs = list()
	var/tick_timer
	var/tick_step


/datum/extension/regenerate/New(var/datum/holder, var/_heal_amount, var/_duration, var/_max_limbs, var/_cooldown)
	..()
	user = holder
	max_limbs = _max_limbs
	duration = _duration
	cooldown = _cooldown
	heal_amount = _heal_amount

	start()

//Lets regrow limbs
/datum/extension/regenerate/proc/start()
	tick_step = duration / tick_interval
	var/list/missing_limbs = list()

	//This loop counts and documents the damaged limbs, for the purpose of regrowing them and also for documenting how many there are for stun time
	for(var/limb_type in user.species.has_limbs)

		var/obj/item/organ/external/E = user.organs_by_name[limb_type]
		if (E && E.is_usable())
			//This organ is fine, skip it
			continue
		else if (E.limb_flags & ORGAN_FLAG_CAN_AMPUTATE)
			missing_limbs |= limb_type

		if (max_limbs <= 0)
			continue
		if(E)
			if (!(E.limb_flags & ORGAN_FLAG_CAN_AMPUTATE))
				continue	//We can't regrow something which can never be removed in the first place
			if (!E.is_usable())
				E.removed()
				qdel(E)
				E = null
		if(!E)
			regenerating_organs |= limb_type
			max_limbs--




	//Special effect:
	//If the user is missing two or more limbs, rplays a special sound
	if (missing_limbs.len >= 2)
		user.play_species_audio(user, SOUND_REGEN, VOLUME_MID, 1)

	duration *= (1 + (missing_limbs.len * 0.25))	//more limbs lost, the longer it takes

	//Lets play the animations
	for(var/limb_type in regenerating_organs)
		user.species.regenerate_limb(user, limb_type, duration)

	user.shake_animation(30)
	user.Stun(Ceiling(duration/10), TRUE)

	//And lets start our timer
	tick_timer = addtimer(CALLBACK(src, .proc/tick), tick_interval, TIMER_STOPPABLE)

/datum/extension/regenerate/proc/tick()
	duration -= tick_interval
	shake_interval -= tick_interval
	user.heal_overall_damage(heal_amount * tick_step)
	if (shake_interval <= 0)
		shake_interval = initial(shake_interval)
		user.shake_animation(30)

	if (duration > 0) //Queue next tick
		tick_timer = addtimer(CALLBACK(src, .proc/tick), tick_interval, TIMER_STOPPABLE)
	else
		finish()


/datum/extension/regenerate/proc/finish()
	//Lets finish up. The limb regrowing animations should be done by now
	//Here we actually create the freshly grown limb
	for(var/limb_type in regenerating_organs)
		var/list/organ_data = user.species.has_limbs[limb_type]
		var/limb_path = organ_data["path"]
		var/obj/item/organ/O = new limb_path(user)
		organ_data["descriptor"] = O.name
		user << "<span class='notice'>You feel a slithering sensation as your [O.name] reforms.</span>"


	//Once we're done regenerating limbs, lets also immediately regenerate all internal organs.
	//We're not gonna force these to be done one by one because there's nothing interesting to look at as it happens.
	for(var/organ_tag in user.species.has_organ)
		var/obj/item/organ/internal/I = user.internal_organs_by_name[organ_tag]
		if(I && I.is_usable())
			//The organ is there, skip it
			continue

		if (!I)
			//The organ isn't there, lets figure out first if we can add it
			var/obj/item/organ/external/E = user.organs_by_name[GLOB.organ_parents[organ_tag]]	//We attempt to retrieve the parent organ it should be inside
			if (!istype(E))
				//Parent organ isn't there, we can't do anything. Try next time once you grow your head back!
				continue

		if (I)
			I.removed()
			qdel(I)
			I = null

		//Once we get here, the specified internal organ doesn't exist, and we are clear to add it
		if(!I)
			var/organ_type = user.species.has_organ[organ_tag]
			var/obj/item/organ/O = new organ_type(user)
			user.internal_organs_by_name[organ_tag] = O


	user.update_body()
	stop()

/datum/extension/regenerate/proc/stop()
	user.stunned = 0

	//When we finish, we go on cooldown
	if (cooldown && cooldown > 0)
		addtimer(CALLBACK(src, .proc/finish_cooldown), cooldown)
	else
		finish_cooldown() //If there's no cooldown timer call it now


/datum/extension/regenerate/proc/finish_cooldown()
	remove_extension(holder, /datum/extension/regenerate)


/mob/living/carbon/human/proc/regenerate_verb()
	set name = "Regenerate"
	set category = "Abilities"


	return regenerate_ability(heal_amount = 40, _duration = 4 SECONDS, _max_limbs = 1, _cooldown = 0)


/mob/living/carbon/human/proc/can_regenerate(var/error_messages = TRUE)
	//Check for an existing extension.
	var/datum/extension/regenerate/EC = get_extension(src, /datum/extension/regenerate)
	if(istype(EC))
		if(error_messages) to_chat(src, "You're already [EC.verb_name]!")
		return FALSE
	return TRUE


/mob/living/carbon/human/proc/regenerate_ability(var/_heal_amount, var/_duration, var/_max_limbs, var/_cooldown)

	if (!can_regenerate(TRUE))
		return FALSE


	//Ok we've passed all safety checks, let's commence charging!
	//We simply create the extension on the movable atom, and everything works from there
	set_extension(src, /datum/extension/regenerate, _heal_amount, _duration, _max_limbs, _cooldown)

	return TRUE