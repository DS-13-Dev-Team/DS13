/obj/item/clothing/suit/storage/toggle/labcoat
	name = "labcoat"
	desc = "A suit that protects against minor chemical spills."
	icon_state = "labcoat_open"
	//item_state = "labcoat" //Is this even used for anything?
	icon_open = "labcoat_open"
	icon_closed = "labcoat"
	blood_overlay_type = "coat"
	body_parts_covered = UPPER_TORSO|ARMS
	extra_allowed = list(/obj/item/stack/medical,
	/obj/item/weapon/reagent_containers/dropper,
	/obj/item/weapon/reagent_containers/syringe,
	/obj/item/weapon/reagent_containers/hypospray,
	/obj/item/weapon/reagent_containers/glass/bottle,
	/obj/item/weapon/reagent_containers/glass/beaker,
	/obj/item/weapon/reagent_containers/pill,
	/obj/item/weapon/storage/pill_bottle,
	/obj/item/weapon/paper)
	armor = list(melee = 0, bullet = 0, laser = 0,energy = 0, bomb = 0, bio = 50, rad = 0)
	valid_accessory_slots = list(ACCESSORY_SLOT_ARMBAND)
	restricted_accessory_slots = list(ACCESSORY_SLOT_ARMBAND)
	acid_resistance = 4	//Made for working with chemicals

/obj/item/clothing/suit/storage/toggle/labcoat/cmo
	name = "chief medical officer's labcoat"
	desc = "Bluer than the standard model."
	icon_state = "labcoat_cmo_open"
	//item_state = "labcoat_cmo"
	icon_open = "labcoat_cmo_open"
	icon_closed = "labcoat_cmo"

/obj/item/clothing/suit/storage/toggle/labcoat/rd
	name = "research director's labcoat"
	desc = "A full-body labcoat covered in red and black designs, denoting it as a NanoTrasen management coat. Judging by the amount of designs on it, it is only to be worn by the most enthusiastic of NanoTrasen employees."
	icon_state = "labcoat_rd_open"
	icon_open = "labcoat_rd_open"
	icon_closed = "labcoat_rd"
	body_parts_covered = UPPER_TORSO|LOWER_TORSO|LEGS|ARMS

/obj/item/clothing/suit/storage/toggle/labcoat/blue
	name = "blue-edged labcoat"
	desc = "A suit that protects against minor chemical spills. This one has blue trim."
	icon_state = "blue_edge_labcoat_open"
	icon_open = "blue_edge_labcoat_open"
	icon_closed = "blue_edge_labcoat"

/obj/item/clothing/suit/storage/toggle/labcoat/coat
	name = "coat"
	desc = "A cozy overcoat."
	color = "#292929"
