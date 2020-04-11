/*
	Code for the necromorph mob.
	Most of this is a temporary hack because we don't have proper icons for parts.

`	I am well aware this is not how human mobs and species are supposed to be used
*/
/mob/living/carbon/human/necromorph

/mob/living/carbon/human/necromorph/spitter/New(var/new_loc, var/new_species = SPECIES_NECROMORPH_SPITTER)
	..(new_loc, new_species)

/mob/living/carbon/human/necromorph/puker/New(var/new_loc, var/new_species = SPECIES_NECROMORPH_PUKER)
	..(new_loc, new_species)

/mob/living/carbon/human/necromorph/fodder/New(var/new_loc, var/new_species = SPECIES_NECROMORPH_FODDER)
	..(new_loc, new_species)

/mob/living/carbon/human/necromorph/slasher/New(var/new_loc, var/new_species = SPECIES_NECROMORPH_SLASHER)
	..(new_loc, new_species)

/mob/living/carbon/human/necromorph/slasher/enhanced/New(var/new_loc, var/new_species = SPECIES_NECROMORPH_SLASHER_ENHANCED)
	..(new_loc, new_species)

/mob/living/carbon/human/necromorph/twitcher/New(var/new_loc, var/new_species = SPECIES_NECROMORPH_TWITCHER)
	..(new_loc, new_species)

/mob/living/carbon/human/necromorph/brute/New(var/new_loc, var/new_species = SPECIES_NECROMORPH_BRUTE)
	if (prob(50))
		new_species = SPECIES_NECROMORPH_BRUTE_FLESH
	..(new_loc, new_species)

/mob/living/carbon/human/necromorph/leaper/New(var/new_loc, var/new_species = SPECIES_NECROMORPH_LEAPER)
	..(new_loc, new_species)

/mob/living/carbon/human/necromorph/leaper/enhanced/New(var/new_loc, var/new_species = SPECIES_NECROMORPH_LEAPER_ENHANCED)
	..(new_loc, new_species)

/mob/living/carbon/human/necromorph/ubermorph/New(var/new_loc, var/new_species = SPECIES_NECROMORPH_UBERMORPH)
	..(new_loc, new_species)

/mob/living/carbon/human/necromorph/update_icons()
	.=..()
	update_body(FALSE)



#define DEBUG
//Override all that complicated limb-displaying stuff, with singular icons
/mob/living/carbon/human/necromorph/update_body(var/update_icons=1)
	var/datum/species/necromorph/N = species


	if (!istype(N))
		return

	//If single icon is turned off, do the normal thing
	if (!N.single_icon)
		return ..()

	stand_icon = N.icon_template
	icon = stand_icon

	if (stat == DEAD)
		icon_state = N.icon_dead

	else if (lying)
		icon_state = N.icon_lying
	else
		icon_state = N.icon_normal



//Generic proc to see if a thing is aligned with the necromorph faction
/atom/proc/is_necromorph()
	return FALSE


/mob/living/carbon/human/is_necromorph()
	if (istype(species, /datum/species/necromorph))
		return TRUE
	return FALSE




/mob/Login()
	.=..()
	//Update the necromorph players list
	if (is_necromorph())
		SSnecromorph.necromorph_players[key] = src