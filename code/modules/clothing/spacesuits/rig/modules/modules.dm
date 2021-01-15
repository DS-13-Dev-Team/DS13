/*
 * Rigsuit upgrades/abilities.
 */

/datum/rig_charge
	var/short_name = "undef"
	var/display_name = "undefined"
	var/product_type = "undefined"
	var/charges = 0

/obj/item/rig_module
	name = "RIG upgrade"
	desc = "It looks pretty sciency."
	icon = 'icons/obj/rig_modules.dmi'
	icon_state = "module"
	matter = list(MATERIAL_STEEL = 20000, "plastic" = 30000, MATERIAL_GLASS = 5000)

	//If set, no other module with a matching base type can be installed
	var/base_type = null

	var/damage = 0
	var/obj/item/weapon/rig/holder

	var/module_cooldown = 10
	var/next_use = 0

	var/toggleable                      // Set to 1 for the device to show up as an active effect.
	var/usable                          // Set to 1 for the device to have an on-use effect.
	var/selectable                      // Set to 1 to be able to assign the device as primary system.
	var/redundant                       // Set to 1 to ignore duplicate module checking when installing.
	var/permanent                       // If set, the module can't be removed.
	var/disruptive = 1                  // Can disrupt by other effects.
	var/activates_on_touch              // If set, unarmed attacks will call engage() on the target.
	var/process_with_rig = TRUE			// If true, this calls process every tick when the rig does

	var/active                          // Basic module status
	var/disruptable                     // Will deactivate if some other powers are used.

	// Now in joules/watts!
	var/use_power_cost = 0              // Power used when single-use ability called.
	var/active_power_cost = 0           // Power used when turned on.
	var/passive_power_cost = 0          // Power used when turned off.

	var/list/charges                    // Associative list of charge types and remaining numbers.
	var/charge_selected                 // Currently selected option used for charge dispensing.

	// Icons.
	var/suit_overlay
	var/suit_overlay_active             // If set, drawn over icon and mob when effect is active.
	var/suit_overlay_inactive           // As above, inactive.
	var/suit_overlay_used               // As above, when engaged.
	var/suit_overlay_layer	=	HUMAN_LAYER
	var/suit_overlay_plane	=	HUMAN_PLANE
	var/suit_overlay_flags = 0

	//Display fluff
	var/interface_name
	var/interface_desc = ""
	var/engage_string = "Engage"
	var/activate_string = "Activate"
	var/deactivate_string = "Deactivate"

	var/list/datum/stat_rig_module/stat_modules = new()

/obj/item/rig_module/Initialize()
	.=..()
	if (!interface_name)
		interface_name = name

	if (!interface_desc)
		interface_desc = desc


/obj/item/rig_module/examine()
	. = ..()
	switch(damage)
		if(0)
			to_chat(usr, "It is undamaged.")
		if(1)
			to_chat(usr, "It is badly damaged.")
		if(2)
			to_chat(usr, "It is almost completely destroyed.")

/obj/item/rig_module/attackby(obj/item/W as obj, mob/user as mob)

	if(istype(W,/obj/item/stack/nanopaste))

		if(damage == 0)
			to_chat(user, "There is no damage to mend.")
			return

		to_chat(user, "You start mending the damaged portions of \the [src]...")

		if(!do_after(user,30,src) || !W || !src)
			return

		var/obj/item/stack/nanopaste/paste = W
		damage = 0
		to_chat(user, "You mend the damage to [src] with [W].")
		paste.use(1)
		return

	else if(isCoil(W))

		switch(damage)
			if(0)
				to_chat(user, "There is no damage to mend.")
				return
			if(2)
				to_chat(user, "There is no damage that you are capable of mending with such crude tools.")
				return

		var/obj/item/stack/cable_coil/cable = W
		if(!cable.amount >= 5)
			to_chat(user, "You need five units of cable to repair \the [src].")
			return

		to_chat(user, "You start mending the damaged portions of \the [src]...")
		if(!do_after(user,30,src) || !W || !src)
			return

		damage = 1
		to_chat(user, "You mend some of damage to [src] with [W], but you will need more advanced tools to fix it completely.")
		cable.use(5)
		return
	..()

/obj/item/rig_module/Initialize()
	. =..()
	if(suit_overlay_inactive)
		suit_overlay = suit_overlay_inactive

	if(charges && charges.len)
		var/list/processed_charges = list()
		for( var/list/charge in charges)
			var/datum/rig_charge/charge_dat = new

			charge_dat.short_name   = charge[1]
			charge_dat.display_name = charge[2]
			charge_dat.product_type = charge[3]
			charge_dat.charges      = charge[4]

			if(!charge_selected) charge_selected = charge_dat.short_name
			processed_charges[charge_dat.short_name] = charge_dat

		charges = processed_charges

		if (charges.len > 1)
			stat_modules +=	new /datum/stat_rig_module/charge(src)


	if (toggleable)
		stat_modules +=	new /datum/stat_rig_module/activate(src)
		stat_modules +=	new /datum/stat_rig_module/deactivate(src)

	if (usable)
		stat_modules +=	new /datum/stat_rig_module/engage(src)

	if (selectable)
		stat_modules +=	new /datum/stat_rig_module/select(src)

/obj/item/rig_module/Destroy()
	deactivate()
	QDEL_NULL_LIST(stat_modules)
	holder = null
	. = ..()


/obj/item/rig_module/proc/can_install(obj/item/weapon/rig/rig, mob/user, feedback = FALSE, check_conflict = TRUE)
	if (!redundant && check_conflict)
		for( var/obj/item/rig_module/RM in rig.installed_modules)
			//Exact duplicates not allowed
			if (type == RM.type)
				return FALSE

			//Matching base types count as a duplicate, if non null
			if (base_type && base_type == RM.base_type)
				return FALSE
	return TRUE

//Returns any existing module which blocks the installation of this one
/obj/item/rig_module/proc/get_conflicting(obj/item/weapon/rig/rig)
	if (!redundant)
		for( var/obj/item/rig_module/RM in rig.installed_modules)
			//Exact duplicates not allowed
			if (type == RM.type)
				return RM

			//Matching base types count as a duplicate, if non null
			if (base_type && base_type == RM.base_type)
				return RM

	return null


/*
	Called to inform this module that its position in rig is about to be replaced with successor.
	Override this to do any prep work for replacement, like storages transferring contents

	Return false to block the replacement and deny the installation of the sucessor
*/
/obj/item/rig_module/proc/pre_replace(obj/item/weapon/rig/rig, obj/item/rig_module/successor)
	return TRUE

// Called when the module is installed into a suit.
/obj/item/rig_module/proc/installed(obj/item/weapon/rig/new_holder)
	holder = new_holder
	return

//Proc for one-use abilities like teleport.
/obj/item/rig_module/proc/engage()

	if(damage >= 2)
		to_chat(usr, "<span class='warning'>The [interface_name] is damaged beyond use!</span>")
		return 0

	if(world.time < next_use)
		to_chat(usr, "<span class='warning'>You cannot use the [interface_name] again so soon.</span>")
		return 0

	if(!holder || holder.canremove)
		to_chat(usr, "<span class='warning'>The suit is not initialized.</span>")
		return 0

	if(usr.stat || usr.stunned || usr.paralysis)
		to_chat(usr, "<span class='warning'>You cannot use the suit in this state.</span>")
		return 0

	if(holder.wearer && holder.wearer.lying)
		to_chat(usr, "<span class='warning'>The suit cannot function while the wearer is prone.</span>")
		return 0

	if(holder.security_check_enabled && !holder.check_suit_access(usr))
		to_chat(usr, "<span class='danger'>Access denied.</span>")
		return 0

	if(!holder.check_power_cost(usr, use_power_cost, 0, src, (istype(usr,/mob/living/silicon ? 1 : 0) ) ) )
		return 0

	next_use = world.time + module_cooldown

	return 1

// Proc for toggling on active abilities.
/obj/item/rig_module/proc/activate()

	if(active || !engage())
		return 0

	active = 1

	spawn(1)
		if(suit_overlay_active)
			suit_overlay = suit_overlay_active
		else
			suit_overlay = null
		holder.update_icon()

	return 1

// Proc for toggling off active abilities.
/obj/item/rig_module/proc/deactivate()

	if(!active)
		return 0

	active = 0

	spawn(1)
		if(suit_overlay_inactive)
			suit_overlay = suit_overlay_inactive
		else
			suit_overlay = null
		if(holder)
			holder.update_icon()

	return 1

// Called when the module is uninstalled from a suit.
/obj/item/rig_module/proc/uninstalled(obj/item/weapon/rig/former, mob/living/user)
	deactivate()
	holder = null
	return

// Called by the RIG
/obj/item/rig_module/Process()
	if(active)
		return active_power_cost
	else
		return passive_power_cost

// Called by holder rigsuit attackby()
// Checks if an item is usable with this module and handles it if it is
/obj/item/rig_module/proc/accepts_item(obj/item/input_device)
	return 0

/mob/living/carbon/human/Stat()
	. = ..()
	if(. && wearing_rig && statpanel("RIG Modules"))

		if(!wearing_rig.canremove && wearing_rig.installed_modules.len)
			var/cell_status = wearing_rig.cell ? "[wearing_rig.cell.charge]/[wearing_rig.cell.maxcharge]" : "ERROR"
			stat("Suit charge", cell_status)
			for( var/obj/item/rig_module/module in wearing_rig.installed_modules)
			{
				for( var/datum/stat_rig_module/SRM as anything in module.stat_modules)
					if(SRM.CanUse())
						stat(SRM.module.interface_name,SRM)
			}

/datum/stat_rig_module
	parent_type = /atom/movable
	var/module_mode = ""
	var/obj/item/rig_module/module

/datum/stat_rig_module/New(obj/item/rig_module/module)
	..()
	src.module = module

/datum/stat_rig_module/Destroy()
	module = null
	.=..()

/datum/stat_rig_module/proc/AddHref(list/href_list)
	return

/datum/stat_rig_module/proc/CanUse()
	return 0

/datum/stat_rig_module/Click()
	if(CanUse())
		var/list/href_list = list(
							"interact_module" = module.holder.installed_modules.Find(module),
							"module_mode" = module_mode
							)
		AddHref(href_list)
		module.holder.Topic(usr, href_list)

/datum/stat_rig_module/DblClick()
	return Click()

/datum/stat_rig_module/activate/New(obj/item/rig_module/module)
	..()
	name = module.activate_string
	if(module.active_power_cost)
		name += " ([module.active_power_cost*10]A)"
	module_mode = "activate"

/datum/stat_rig_module/activate/CanUse()
	return module.toggleable && !module.active

/datum/stat_rig_module/deactivate/New(obj/item/rig_module/module)
	..()
	name = module.deactivate_string
	// Show cost despite being 0, if it means changing from an active cost.
	if(module.active_power_cost || module.passive_power_cost)
		name += " ([module.passive_power_cost*10]P)"

	module_mode = "deactivate"

/datum/stat_rig_module/deactivate/CanUse()
	return module.toggleable && module.active

/datum/stat_rig_module/engage/New(obj/item/rig_module/module)
	..()
	name = module.engage_string
	if(module.use_power_cost)
		name += " ([module.use_power_cost*10]E)"
	module_mode = "engage"

/datum/stat_rig_module/engage/CanUse()
	return module.usable

/datum/stat_rig_module/select/New()
	..()
	name = "Select"
	module_mode = "select"

/datum/stat_rig_module/select/CanUse()
	if(module.selectable)
		name = module.holder.selected_module == module ? "Selected" : "Select"
		return 1
	return 0

/datum/stat_rig_module/charge/New()
	..()
	name = "Change Charge"
	module_mode = "select_charge_type"

/datum/stat_rig_module/charge/AddHref(var/list/href_list)
	var/charge_index = module.charges.Find(module.charge_selected)
	if(!charge_index)
		charge_index = 0
	else
		charge_index = charge_index == module.charges.len ? 1 : charge_index+1

	href_list["charge_type"] = module.charges[charge_index]

/datum/stat_rig_module/charge/CanUse()
	if(module.charges && module.charges.len)
		var/datum/rig_charge/charge = module.charges[module.charge_selected]
		name = "[charge.display_name] ([charge.charges]C) - Change"
		return 1
	return 0


/obj/item/rig_module/proc/rig_equipped(mob/user, slot)
	return

/obj/item/rig_module/proc/rig_unequipped(mob/user, slot)
	return

//Consumes power, returns true if it works
/obj/item/rig_module/proc/use_power(cost)
	.=FALSE
	if (holder && holder.cell)
		if(holder.cell.check_charge(cost * CELLRATE))
			holder.cell.use(cost * CELLRATE)
			return TRUE