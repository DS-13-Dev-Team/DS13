#define AIM_NO_CLICKHANDLER	1	//We're fine to enter aiming modes, but not to use the RMB click handler
#define AIM_FINE	2	//We're fine for aiming and click handler


//Parent gun type. Guns are weapons that can be aimed at mobs and act over a distance
/obj/item/weapon/gun
	name = "gun"
	desc = "Its a gun. It's pretty terrible, though."
	icon = 'icons/obj/gun.dmi'
	item_icons = list(
		slot_l_hand_str = 'icons/mob/onmob/items/lefthand_guns.dmi',
		slot_r_hand_str = 'icons/mob/onmob/items/righthand_guns.dmi',
		)
	icon_state = "detective"
	item_state = "gun"
	obj_flags =  OBJ_FLAG_CONDUCTIBLE
	slot_flags = SLOT_BELT|SLOT_HOLSTER
	matter = list(MATERIAL_STEEL = 2000)
	w_class = ITEM_SIZE_NORMAL
	throwforce = 5

	throw_range = 5
	force = 5
	origin_tech = list(TECH_COMBAT = 1)
	attack_verb = list("struck", "hit", "bashed")
	zoomdevicename = "scope"
	unacidable = TRUE	//Guns melting is too powerful

	max_health = 150

	resistance = 5	//Guns are not intended as melee weapons, but they're moderately tough

	var/burst = 1
	var/fire_delay = 6 	//delay after shooting before the gun can be used again
	var/burst_delay = 2	//delay between shots, if firing in bursts
	var/windup_time	= 0	//A delay between pressing the button, and actually firing
	var/windup_sound	//Sound played during windup time
	var/move_delay = 1
	var/fire_sound = 'sound/weapons/gunshot/gunshot.ogg'
	var/shot_volume = VOLUME_MID
	var/fire_sound_text = "gunshot"
	var/fire_anim = null
	var/screen_shake = 0 //shouldn't be greater than 2 unless zoomed
	var/silenced = 0
	var/move_accuracy_mod	=	-7.5	//Modifier applied to accuracy while moving. Should generally be negative

	var/stop_firing_when_dropped = TRUE	//If false, a gun can continue firing when dropped by the user. No current use cases, but may be useful in future

	var/list/dispersion = list(0)

	var/wielded_item_state
	var/combustion	//whether it creates hotspot when fired

	var/last_fire_attempt = 0	//Last time afterattack was called, regardless of result
	var/next_fire_time = 0

	var/sel_mode = 1 //index of the currently selected mode
	var/list/datum/firemode/firemodes = list()
	var/datum/firemode/current_firemode
	var/selector_sound = 'sound/weapons/guns/selector.ogg'
	var/firing = FALSE //True if currently firing, limited implementation, mostly for sustained/automatic weapons

	//Accuracy handling
	var/accuracy = 0   //Default 0: Percentage bonus or penalty to accuracy, this is applied to the base accuracy of projectiles (usually 100)
	var/one_hand_penalty
	var/scoped_accuracy = null
	var/list/burst_accuracy = list(0) //allows for different accuracies for each shot in a burst. Applied on top of accuracy

	//Damage handling
	var/damage_factor = 1	//Multiplier on damage

	//aiming system stuff
	var/keep_aim = 1 	//1 for keep shooting until aim is lowered
						//0 for one bullet after tarrget moves and aim is lowered
	var/multi_aim = 0 //Used to determine if you can target multiple people.
	var/tmp/list/mob/living/aim_targets //List of who yer targeting.
	var/require_aiming = FALSE	//If true, this gun can ONLY be fired while in ironsights mode. it will fail to fire if not aiming down the sights
	var/require_held = TRUE	//If true, this gun can only be fired while held in the hands of a human. Should usually be true, but set false for rare special cases


	//Aiming Modes: Scopes, ironsights, etc
	var/selected_aiming_mode	//Typepath of the aiming mode datum we will create when we activate aiming mode
	var/datum/extension/aim_mode/active_aiming_mode	//Reference to an aiming mode extension we are currently using.
	var/list/aiming_modes = list(/datum/extension/aim_mode/basic)	//Possible aiming modes this gun can use
	var/datum/click_handler/rmb_aim/ACH	//Click handler used for rightclick toggling

	var/tmp/mob/living/last_moved_mob //Used to fire faster at more than one person.
	var/tmp/told_cant_shoot = 0 //So that it doesn't spam them with the fact they cannot hit them.
	var/tmp/lock_time = -100
	var/tmp/last_safety_check = -INFINITY
	var/suppress_delay_warning = FALSE
	var/safety_state = 0
	var/has_safety = TRUE


	var/projectile_type = null	//What type of projectile will we fire when the trigger is pulled? If this is set, it overrides default ammo-based typing in projectile guns
	var/ammo_cost = 1	//How many shots' worth of ammo do we consume to fire once?

	var/mag_insert_sound
	var/mag_remove_sound
	var/empty_sound = 'sound/weapons/empty.ogg'

/obj/item/weapon/gun/Initialize()
	.=..()
	// Updating firing modes at appropriate times
	// Now uses events to avoid unnecessarily complex proc overrides
	GLOB.item_equipped_event.register(src, src, .proc/update_equipped)
	GLOB.item_unequipped_event.register(src, src, .proc/update_all_stop)
	GLOB.swapped_to_event.register(src, src, .proc/update_all)
	GLOB.swapped_from_event.register(src, src, .proc/update_all_stop)

	for(var/i in 1 to firemodes.len)
		var/list/L = firemodes[i]

		//If this var is set, it means spawn a specific subclass of firemode
		if (L["mode_type"])
			var/newtype = L["mode_type"]
			var/datum/firemode/F = new newtype(src, L)
			firemodes[i] = F
		else
			firemodes[i] = new /datum/firemode(src, L)

	//Properly initialize the default firing mode
	if (firemodes.len)
		var/datum/firemode/F = firemodes[sel_mode]
		F.apply_to(src)

	if (aiming_modes.len)
		selected_aiming_mode = aiming_modes[1]

	if(isnull(scoped_accuracy))
		scoped_accuracy = accuracy

/obj/item/weapon/gun/Destroy()
	GLOB.item_equipped_event.unregister(src, src, .proc/update_all)
	GLOB.item_unequipped_event.unregister(src, src, .proc/update_all_stop)
	GLOB.swapped_to_event.unregister(src, src, .proc/update_all)
	GLOB.swapped_from_event.unregister(src, src, .proc/update_all_stop)
	if (current_firemode)
		current_firemode.unapply_to(src)
	QDEL_LIST(firemodes)

	disable_aiming_mode()
	//TODO: Delete ACH click handler
	.=..()

//Called when the user moves while holding this gun.
//Must be manually registered to the moved event if your gun needs it
/obj/item/weapon/gun/proc/user_moved()
	return

/obj/item/weapon/gun/update_twohanding()
	if(one_hand_penalty)
		update_icon() // In case item_state is set somewhere else.
	..()

/obj/item/weapon/gun/update_icon()
	var/mob/living/M = loc
	overlays.Cut()
	if(istype(M))
		if(wielded_item_state)
			if(M.can_wield_item(src) && src.is_held_twohanded(M))
				item_state_slots[slot_l_hand_str] = wielded_item_state
				item_state_slots[slot_r_hand_str] = wielded_item_state
			else
				item_state_slots[slot_l_hand_str] = initial(item_state)
				item_state_slots[slot_r_hand_str] = initial(item_state)
			update_wear_icon()
		if(M.skill_check(SKILL_WEAPONS,SKILL_BASIC))
			overlays += image(icon,"safety[safety()]")


//Returns a number that represents the remaining quantity of whatever resource we use to fire.
//In most cases, this is an integer number of bullets
//It could also be the charge remaining in a power cell, the volume in a fueltank, etc
/obj/item/weapon/gun/proc/get_remaining_ammo()
	return 0


//Checks whether a given mob can use the gun
//Any checks that shouldn't result in handle_click_empty() being called if they fail should go here.
//Otherwise, if you want handle_click_empty() to be called, check in consume_next_projectile() and return null there.
/obj/item/weapon/gun/proc/special_check(var/mob/user)

	if(!istype(user, /mob/living))
		return 0
	if(!user.is_advanced_tool_user())
		return 0

	var/mob/living/M = user
	if(!firing && !safety() && world.time > last_safety_check + 5 MINUTES && !user.skill_check(SKILL_WEAPONS, SKILL_BASIC))
		if(prob(30))
			toggle_safety()
			return 1
	if(HULK in M.mutations)
		to_chat(M, "<span class='danger'>Your fingers are much too large for the trigger guard!</span>")
		return 0
	if((CLUMSY in M.mutations) && prob(40)) //Clumsy handling
		var/obj/P = consume_next_projectile()
		if(P)
			if(process_projectile(P, user, user, pick(BP_L_FOOT, BP_R_FOOT)))
				handle_post_fire(user, user)
				user.visible_message(
					"<span class='danger'>\The [user] shoots \himself in the foot with \the [src]!</span>",
					"<span class='danger'>You shoot yourself in the foot with \the [src]!</span>"
					)
				M.unequip_item()
		else
			handle_click_empty(user)
		return 0
	return 1

/obj/item/weapon/gun/emp_act(severity)
	for(var/obj/O in contents)
		O.emp_act(severity)

//Return true if we successfully fired
/obj/item/weapon/gun/afterattack(atom/A, mob/living/user, adjacent, params, var/vector2/world_pixel_click)
	last_fire_attempt = world.time
	if(adjacent) return //A is adjacent, is the user, or is on the user's person

	if(!user.aiming)
		user.aiming = new(user)

	//Check that the gun is able to fire
	if (!can_fire(A, user, params))
		//If its not able to fire, lets check why
		if(safety() || !has_ammo())
			handle_click_empty()
		return

	//When firing in harm intent, at anything that isn't a mob, you'll autoaim at viable mobs in the same tile
	if (user && user.a_intent == I_HURT && !isliving(A))
		for (var/mob/living/L in A)
			if (L.stat != DEAD && L != user)
				A = L


	if(user && user.client && user.aiming && user.aiming.active && user.aiming.aiming_at != A)
		baycode_aim(A,user,params) //They're using the new gun system, locate what they're aiming at.
		return TRUE

	//Do prefire first
	if (!pre_fire(A, user, params))
		return

	Fire(A,user,params) //Otherwise, fire normally.

	return TRUE

/obj/item/weapon/gun/proc/pre_fire(var/atom/target, var/mob/living/user, var/clickparams, var/pointblank=0, var/reflex=0)
	return TRUE

/obj/item/weapon/gun/attack(atom/A, mob/living/user, def_zone)

	if (A == user && user.zone_sel.selecting == BP_MOUTH && !mouthshoot && can_fire(A, user))
		handle_suicide(user)
	else if(user.a_intent == I_HURT && can_fire(A, user)) //point blank shooting
		Fire(A, user, pointblank=1)
	else
		return ..() //Pistolwhippin'

/obj/item/weapon/gun/dropped(var/mob/living/user)
	if(istype(user) && istype(loc, /turf))
		if(!safety() && prob(5) && !user.skill_check(SKILL_WEAPONS, SKILL_BASIC) && can_fire(null, user, TRUE))
			to_chat(user, "<span class='warning'>[src] fires on its own!</span>")
			var/list/targets = list(user)
			targets += trange(2, src)
			afterattack(pick(targets), user)
	if (stop_firing_when_dropped)
		stop_firing()
	else
		//Stop_firing already calls this, so lets not do it twice
		update_firemode()
	update_icon()
	return ..()


//Return true if firing is okay right now
/obj/item/weapon/gun/proc/can_fire(atom/target, mob/living/user, clickparams, var/silent = FALSE)
	if(world.time < next_fire_time)
		if (!silent && !suppress_delay_warning && world.time % 3) //to prevent spam
			to_chat(user, SPAN_WARNING("[src] is not ready to fire again!"))
		return FALSE

	if (!can_ever_fire(user))
		return FALSE

	if(target && user && (target.z != user.z))
		return FALSE

	return TRUE

//Returns true if the gun can fire now, or will become able to fire in the near future without any active intervention
/*
	This only counts problems that will not resolve themselves in time.

	The following things are not counted:
		Cooldown times/overheating
*/
/obj/item/weapon/gun/proc/can_ever_fire(mob/living/user)
	if(safety() || ((!current_firemode || current_firemode.req_ammo) && !has_ammo()))
		return FALSE

	//We'll only do the special check if a user is supplied
	if (user && !special_check(user))
		return FALSE

	if (require_aiming && !active_aiming_mode)
		return FALSE

	if (require_held && !is_held())
		return FALSE

	if(current_firemode && !current_firemode.can_fire(user))
		return FALSE

	return TRUE

//Does this gun have enough ammo/power/resources to fire at least once?
/obj/item/weapon/gun/proc/has_ammo()
	return TRUE


/obj/item/weapon/gun/is_held_twohanded(var/mob/user)
	.=..()
	if (.)
		if (!user.can_wield_item(src))
			return FALSE

//Safety checks are done by the time fire is called
/obj/item/weapon/gun/proc/Fire(var/atom/target, var/mob/living/user, var/clickparams, var/pointblank=0, var/reflex=0)



	if (current_firemode && current_firemode.override_fire)
		current_firemode.fire(target, user, clickparams, pointblank, reflex)
		return

	if(!user || !target) return	//Except this one, apparently


	add_fingerprint(user)



	if(target.atom_flags & ATOM_FLAG_UNTARGETABLE)
		target = target.loc

	last_safety_check = world.time
	var/shoot_time = (burst - 1)* burst_delay
	user.set_click_cooldown(shoot_time+windup_time) //no clicking on things while shooting
	user.set_move_cooldown(shoot_time+windup_time) //no moving while shooting either
	next_fire_time = world.time + shoot_time + windup_time

	var/held_twohanded = is_held_twohanded(user)

	if (windup_time)
		if (windup_sound)
			playsound(user, windup_sound, VOLUME_HIGH, 1)
		sleep(windup_time)

	//actually attempt to shoot
	var/turf/targloc = get_turf(target) //cache this in case target gets deleted during shooting, e.g. if it was a securitron that got destroyed.
	for(var/i in 1 to burst)
		var/obj/projectile = consume_next_projectile(user)
		.=projectile	//We'll return the projectile
		if(!projectile)
			handle_click_empty(user)
			if (current_firemode)
				current_firemode.on_fire(target, user, clickparams, pointblank, reflex, FALSE)	//Tell the firemode that we tried and failed to fire
			break

		//Consume next projectile may just return TRUE instead of an object. In that case we don't launch any bullets, but still count it as a successful fire
		if (istype(projectile))

			process_accuracy(projectile, user, target, i, held_twohanded)

			if(pointblank)
				process_point_blank(projectile, user, target)

			process_projectile(projectile, user, target, user.zone_sel.selecting, clickparams)


			if(i < burst)
				sleep(burst_delay)

			if(!(target && target.loc))
				target = targloc
				pointblank = 0

		play_fire_sound(user,projectile)

		handle_post_fire(user, target, pointblank, reflex)
		if (current_firemode)	current_firemode.on_fire(target, user, clickparams, pointblank, reflex, TRUE, projectile)//Tell the firemode that we successfully fired

	//update timing
	next_fire_time = world.time + fire_delay

//obtains the next projectile to fire
/obj/item/weapon/gun/proc/consume_next_projectile()
	if (ammo_cost > 1)
		return consume_projectiles(ammo_cost)
	return TRUE

//Attempts to consume a specified number of projectiles. Returns false if the gun doesn't have enough ammo
/obj/item/weapon/gun/proc/consume_projectiles(var/number = 1)
	if (projectile_type)
		return new projectile_type(src)
	return TRUE

//used by aiming code
/obj/item/weapon/gun/proc/can_hit(atom/target as mob, var/mob/living/user as mob)
	if(!special_check(user))
		return 2
	//just assume we can shoot through glass and stuff. No big deal, the player can just choose to not target someone
	//on the other side of a window if it makes a difference. Or if they run behind a window, too bad.
	return check_trajectory(target, user)

//called if there was no projectile to shoot
/obj/item/weapon/gun/proc/handle_click_empty(mob/user)
	if (check_audio_cooldown("gunclick"))
		if (user)
			user.visible_message("*click click*", "<span class='danger'>*click*</span>")
		else
			src.visible_message("*click click*")

		playsound(src.loc, empty_sound, VOLUME_MID, 1, 2)
		set_audio_cooldown("gunclick", 4 SECONDS)
	update_firemode() //Stops automatic weapons spamming this endlessly

//called after successfully firing
/obj/item/weapon/gun/proc/handle_post_fire(mob/user, atom/target, var/pointblank=0, var/reflex=0)
	if(fire_anim)
		flick(fire_anim, src)

	if(!silenced)
		if(reflex)
			user.visible_message(
				"<span class='reflex_shoot'><b>\The [user] fires \the [src][pointblank ? " point blank at \the [target]":""] by reflex!</b></span>",
				"<span class='reflex_shoot'>You fire \the [src] by reflex!</span>",
				"You hear a [fire_sound_text]!"
			)

	/*
	if(one_hand_penalty)
		if(!src.is_held_twohanded(user))
			switch(one_hand_penalty)
				if(1)
					if(prob(50)) //don't need to tell them every single time
						to_chat(user, "<span class='warning'>Your aim wavers slightly.</span>")
				if(2)
					to_chat(user, "<span class='warning'>Your aim wavers as you fire \the [src] with just one hand.</span>")
				if(3)
					to_chat(user, "<span class='warning'>You have trouble keeping \the [src] on target with just one hand.</span>")
				if(4 to INFINITY)
					to_chat(user, "<span class='warning'>You struggle to keep \the [src] on target with just one hand!</span>")
		else if(!user.can_wield_item(src))
			switch(one_hand_penalty)
				if(1)
					if(prob(50)) //don't need to tell them every single time
						to_chat(user, "<span class='warning'>Your aim wavers slightly.</span>")
				if(2)
					to_chat(user, "<span class='warning'>Your aim wavers as you try to hold \the [src] steady.</span>")
				if(3)
					to_chat(user, "<span class='warning'>You have trouble holding \the [src] steady.</span>")
				if(4 to INFINITY)
					to_chat(user, "<span class='warning'>You struggle to hold \the [src] steady!</span>")
	*/
	if(screen_shake)
		spawn()
			shake_camera(user, screen_shake+1, screen_shake)

	if(combustion)
		var/turf/curloc = get_turf(src)
		curloc.hotspot_expose(700, 5)

	update_icon()


/obj/item/weapon/gun/proc/process_point_blank(obj/projectile, mob/user, atom/target)
	var/obj/item/projectile/P = projectile
	if(!istype(P))
		return //default behaviour only applies to true projectiles

	//default point blank multiplier
	var/max_mult = 1.3

	//determine multiplier due to the target being grabbed
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		for(var/obj/item/grab/G in H.grabbed_by)
			if(G.point_blank_mult() > max_mult)
				max_mult = G.point_blank_mult()
	P.damage *= max_mult

/obj/item/weapon/gun/proc/process_accuracy(obj/projectile, mob/living/user, atom/target, var/burst, var/held_twohanded)
	var/obj/item/projectile/P = projectile
	if(!istype(P))
		return //default behaviour only applies to true projectiles

	P.damage *= damage_factor
	var/acc_mod = accuracy
	if (burst_accuracy)
		acc_mod += burst_accuracy[min(burst, burst_accuracy.len)]
	var/disp_mod = dispersion[min(burst, dispersion.len)]
	var/stood_still = round((world.time - user.l_move_time)/15)
	if(stood_still < 1 SECOND)
		acc_mod += move_accuracy_mod

	if(one_hand_penalty && !held_twohanded)
		acc_mod += one_hand_penalty
		disp_mod += one_hand_penalty*0.5 //dispersion per point of two-handedness

	if(burst > 1 && !user.skill_check(SKILL_WEAPONS, SKILL_ADEPT))
		acc_mod -= 1
		disp_mod += 0.5

	//Accuracy modifiers
	P.accuracy += acc_mod
	P.dispersion = disp_mod

	/*accuracy bonus from aiming
	if (aim_targets && (target in aim_targets))
		//If you aim at someone beforehead, it'll hit more often.
		//Kinda balanced by fact you need like 2 seconds to aim
		//As opposed to no-delay pew pew
		P.accuracy += 2*/

	P.accuracy += user.ranged_accuracy_mods()

//does the actual launching of the projectile
/obj/item/weapon/gun/proc/process_projectile(obj/projectile, mob/user, atom/target, var/target_zone, var/params=null)
	var/obj/item/projectile/P = projectile
	if(!istype(P))
		return 0 //default behaviour only applies to true projectiles

	if(params)
		P.set_clickpoint(params)

	//shooting while in shock
	var/x_offset = 0
	var/y_offset = 0
	if(istype(user, /mob/living/carbon/human))
		var/mob/living/carbon/human/mob = user
		if(mob.shock_stage > 120)
			y_offset = rand(-2,2)
			x_offset = rand(-2,2)
		else if(mob.shock_stage > 70)
			y_offset = rand(-1,1)
			x_offset = rand(-1,1)

	var/launched = !P.launch_from_gun(target, user, src, target_zone, x_offset, y_offset)



	return launched

/obj/item/weapon/gun/proc/play_fire_sound(var/mob/user, var/obj/item/projectile/P)
	var/shot_sound = (istype(P) && P.fire_sound)? P.fire_sound : fire_sound
	if (islist(shot_sound))
		shot_sound = pick(shot_sound)
	if(silenced)
		playsound(user, shot_sound, VOLUME_QUIET, 1, -2)
	else
		playsound(user, shot_sound, shot_volume, 1)

//Suicide handling.
/obj/item/weapon/gun/var/mouthshoot = 0 //To stop people from suiciding twice... >.>
/obj/item/weapon/gun/proc/handle_suicide(mob/living/user)
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/M = user

	mouthshoot = 1
	M.visible_message("<span class='danger'>[user] sticks their gun in their mouth, ready to pull the trigger...</span>")
	if(!do_after(user, 40, progress=0))
		M.visible_message("<span class='notice'>[user] decided life was worth living</span>")
		mouthshoot = 0
		return
	var/obj/item/projectile/in_chamber = consume_next_projectile()
	if (istype(in_chamber))
		user.visible_message("<span class = 'warning'>[user] pulls the trigger.</span>")
		var/shot_sound = in_chamber.fire_sound? in_chamber.fire_sound : fire_sound
		if(silenced)
			playsound(user, shot_sound, 10, 1)
		else
			playsound(user, shot_sound, 50, 1)
		if(istype(in_chamber, /obj/item/projectile/beam/lastertag))
			user.show_message("<span class = 'warning'>You feel rather silly, trying to commit suicide with a toy.</span>")
			mouthshoot = 0
			return

		in_chamber.on_hit(M)
		if (in_chamber.damage_type != PAIN)
			log_and_message_admins("[key_name(user)] commited suicide using \a [src]")
			user.apply_damage(in_chamber.damage*2.5, in_chamber.damage_type, BP_HEAD, 0, in_chamber.damage_flags(), used_weapon = "Point blank shot in the mouth with \a [in_chamber]")
			user.death()
		else
			to_chat(user, "<span class = 'notice'>Ow...</span>")
			user.apply_effect(110,PAIN,0)
		qdel(in_chamber)
		mouthshoot = 0
		return
	else
		handle_click_empty(user)
		mouthshoot = 0
		return

/obj/item/weapon/gun/proc/toggle_scope(mob/user, var/zoom_amount=2.0)
	//looking through a scope limits your periphereal vision
	//still, increase the view size by a tiny amount so that sniping isn't too restricted to NSEW
	var/zoom_offset = round(world.view * zoom_amount)
	var/view_size = round(world.view + zoom_amount)
	var/scoped_accuracy_mod = zoom_offset

	if(zoom)
		unzoom(user)
		return

	zoom(user, zoom_offset, view_size)
	if(zoom)
		accuracy = scoped_accuracy + scoped_accuracy_mod
		if(user.skill_check(SKILL_WEAPONS, SKILL_PROF))
			accuracy += 2
		if(screen_shake)
			screen_shake = round(screen_shake*zoom_amount+1) //screen shake is worse when looking through a scope

//make sure accuracy and screen_shake are reset regardless of how the item is unzoomed.
/obj/item/weapon/gun/zoom()
	..()
	if(!zoom)
		accuracy = initial(accuracy)
		screen_shake = initial(screen_shake)

/obj/item/weapon/gun/examine(mob/user)
	. = ..()
	if(user.skill_check(SKILL_WEAPONS, SKILL_BASIC))
		if(firemodes.len > 1)
			to_chat(user, "The fire selector is set to [current_firemode.name].")
	to_chat(user, "The safety is [safety() ? "on" : "off"].")
	last_safety_check = world.time

/obj/item/weapon/gun/proc/switch_firemodes()

	var/next_mode = get_next_firemode()
	if(!next_mode || next_mode == sel_mode)
		return null
	var/datum/firemode/current_mode = firemodes[sel_mode]
	update_firemode(FALSE) //Disable the old firing mode before we switch away from it
	current_mode.unapply_to(src)	//Set any vars the firemode altered back to default
	sel_mode = next_mode
	var/datum/firemode/new_mode = firemodes[sel_mode]
	new_mode.apply_to(src)
	new_mode.update()
	update_aiming_handler()
	playsound(loc, selector_sound, 50, 1)
	return new_mode

/obj/item/weapon/gun/proc/get_firemode()
	return firemodes[sel_mode]

/obj/item/weapon/gun/proc/get_next_firemode()
	if(firemodes.len <= 1)
		return null
	. = sel_mode + 1
	if(. > firemodes.len)
		. = 1

/obj/item/weapon/gun/attack_self(mob/user)
	var/datum/firemode/new_mode = switch_firemodes(user)
	if(prob(20) && !user.skill_check(SKILL_WEAPONS, SKILL_BASIC))
		new_mode = switch_firemodes(user)
	if(new_mode)
		to_chat(user, "<span class='notice'>\The [src] is now set to [new_mode.name].</span>")

/obj/item/weapon/gun/proc/toggle_safety(var/mob/user)
	safety_state = !safety_state
	update_icon()
	if(user)
		to_chat(user, "<span class='notice'>You switch the safety [safety_state ? "on" : "off"] on [src].</span>")
		last_safety_check = world.time
		playsound(src, 'sound/weapons/flipblade.ogg', 30, 1)
	update_firemode()
	update_aiming_handler()

/obj/item/weapon/gun/verb/toggle_safety_verb()
	set src in usr
	set category = "Object"
	set name = "Toggle Gun Safety"
	if(usr == loc)
		toggle_safety(usr)

/obj/item/weapon/gun/CtrlClick(var/mob/user)
	if(loc == user)
		toggle_safety(user)
	else
		..()

/obj/item/weapon/gun/proc/safety()
	return has_safety && safety_state

/obj/item/weapon/gun/attack_hand()
	..()
	update_icon()


//Finds the current firemode and calls update on it. This is called from a few places:
//When firemode is changed
//When safety is toggled
//When gun is picked up
//When gun is readied/swapped to
/obj/item/weapon/gun/proc/update_firemode(var/force_state = null)
	if (sel_mode && firemodes && firemodes.len)
		var/datum/firemode/new_mode = firemodes[sel_mode]
		new_mode.update(force_state)

/obj/item/weapon/gun/proc/update_all(force_state = null)
	update_icon()
	update_firemode(force_state)
	update_aiming_handler()

/obj/item/weapon/gun/proc/update_equipped(obj/self, mob/equipper, slot)
	if(!equipper)
		CRASH("update_equipped called on [self] with slot [slot] and invalid mob!")
	if(slot == equipper.get_active_hand_slot())
		update_all()
		return
	update_all_stop()

/obj/item/weapon/gun/proc/update_all_stop()
	update_all(FALSE)


/obj/item/weapon/gun/proc/can_stop_firing()
	if (!can_ever_fire())
		return TRUE
	return current_firemode.can_stop_firing()

//Used by sustained weapons. Call to make the gun stop doing its thing
/obj/item/weapon/gun/proc/stop_firing()
	if(can_stop_firing())
		firing = FALSE
		next_fire_time = world.time + max(fire_delay, 1)	//A tiny minimum delay is needed to prevent an additional click going through on sustained/automatic weapons when the mouse button is released
		if(current_firemode)
			current_firemode.stop_firing()
		update_aiming_handler()
		return TRUE

/obj/item/weapon/gun/attack_hand(mob/user as mob)
	if(user.get_inactive_hand() == src)
		unload_ammo(user, allow_dump=0)
	else
		return ..()

//Ammo handling, used by most types of weapons
/obj/item/weapon/gun/proc/unload_ammo(mob/user, var/allow_dump)
	playsound(loc, mag_remove_sound, 50, 1)


/obj/item/weapon/gun/proc/load_ammo(var/obj/item/A, mob/user)
	playsound(loc, mag_insert_sound, 50, 1)

/obj/item/weapon/gun/attackby(var/obj/item/A as obj, mob/user as mob)
	load_ammo(A, user)



/*------------------------
	Aiming Mode Handling
-------------------------*/

//Check any existing aiming mode, and click handler. Called regularly from lots of places
/obj/item/weapon/gun/proc/update_aiming_mode()
	if (active_aiming_mode)
		active_aiming_mode.safety()

	.=aiming_safety()




//Enables if not enabled
//Disables if enabled
/obj/item/weapon/gun/proc/toggle_aiming_mode()
	if (active_aiming_mode)
		disable_aiming_mode()
	else
		enable_aiming_mode()

/obj/item/weapon/gun/proc/enable_aiming_mode()
	.=update_aiming_mode()	//First of all, update. If theres an existing one gone stale, this will remove it
	if (active_aiming_mode)
		return	//If one still exists, leave it in place, we are done here

	//Okay lets create the aim extension on the user!
	if (.)//Update aiming mode did the safety checks for us
		var/mob/living/user = loc

		active_aiming_mode = set_extension(user, selected_aiming_mode, src)
		return TRUE	//Return true if we changed aiming state


/obj/item/weapon/gun/proc/disable_aiming_mode()
	if (active_aiming_mode)
		active_aiming_mode.remove()
		active_aiming_mode = null
		return TRUE	//Return true if we changed aiming state

//Switches to the next aiming mode
/obj/item/weapon/gun/proc/cycle_aiming_mode()
	if (!aiming_modes || aiming_modes.len <= 1 || !selected_aiming_mode)
		return

	var/element = aiming_modes.Find(selected_aiming_mode)
	element = Wrap(element+1, 1, aiming_modes.len+1)
	selected_aiming_mode = aiming_modes[element]
	playsound(src, 'sound/weapons/flipblade.ogg', 30, 1)
	var/datum/extension/aim_mode/AR = selected_aiming_mode
	if (usr)
		to_chat(usr, SPAN_NOTICE("Selected [initial(AR.name)]"))

/obj/item/weapon/gun/CtrlAltClick(var/mob/user)
	if (user == loc && is_held() && selected_aiming_mode)
		toggle_aiming_mode()
		return
	.=..()


/obj/item/weapon/gun/AltClick(var/mob/user)
	if (user == loc && is_held() && aiming_modes.len > 1)
		cycle_aiming_mode()
		return
	.=..()

/obj/item/weapon/gun/proc/aiming_safety()
	if (is_held())
		.=AIM_FINE	//
		var/mob/user = loc
		if (safety())
			.=AIM_NO_CLICKHANDLER

		else if (user.get_active_hand() != src)
			.=AIM_NO_CLICKHANDLER


		return

	return FALSE


/*------------------------
	RMB Aiming
-------------------------*/

/obj/item/weapon/gun/proc/update_aiming_handler()
	var/check = update_aiming_mode()
	if (check == AIM_FINE)
		create_click_handlers()
	else
		remove_click_handlers()

//Here we create all click handlers that are needed and don't currently exist. Check if they do exist.
//All other safety checks are already done. At this point we know that:
	//The gun is in the user's active hand
	//The gun safety is disabled
/obj/item/weapon/gun/proc/create_click_handlers()
	var/mob/living/user = loc

	if (ACH && (ACH.user != user))
		QDEL_NULL(ACH)
	if (selected_aiming_mode && !ACH)
		//Then lets make one
		ACH = user.PushClickHandler(/datum/click_handler/rmb_aim)
		ACH.gun = src


/obj/item/weapon/gun/proc/remove_click_handlers()
	if (ACH)
		QDEL_NULL(ACH)


//This is called on automatic weapons when the user pulls the trigger
//It will only be triggered once per mouseclick, no matter how long they hold it down
/obj/item/weapon/gun/proc/started_firing()
	firing = TRUE
	return

//just a wrapper, used in click handler callbacks
/obj/item/weapon/gun/proc/is_firing()
	return firing