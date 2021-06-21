GLOBAL_LIST_INIT(bitflags, list(1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768))


// Flag Utils
#define GET_FLAGS(field, mask)      ((field) & (mask))
#define HAS_FLAGS(field, mask)      (((field) & (mask)) == (mask))
#define SET_FLAGS(field, mask)      ((field) |= (mask))
#define CLEAR_FLAGS(field, mask)    ((field) &= ~(mask))
#define FLIP_FLAGS(field, mask)     ((field) ^= (mask))

#define CLOSET_HAS_LOCK  1
#define CLOSET_CAN_BE_WELDED 2

#define CLOSET_STORAGE_MISC       1
#define CLOSET_STORAGE_ITEMS      2
#define CLOSET_STORAGE_MOBS       4
#define CLOSET_STORAGE_STRUCTURES 8
#define CLOSET_STORAGE_ALL   (~0)

// Flags bitmasks.

#define ATOM_FLAG_CHECKS_BORDER			(1<<0) // If a dense atom (potentially) only blocks movements from a given direction, i.e. window panes
#define ATOM_FLAG_CLIMBABLE				(1<<1) // This object can be climbed on
#define ATOM_FLAG_NO_BLOOD				(1<<2) // Used for items if they don't want to get a blood overlay.
#define ATOM_FLAG_NO_REACT				(1<<3) // Reagents don't react inside this container.
#define ATOM_FLAG_OPEN_CONTAINER		(1<<4) // Is an open container for chemistry purposes.
#define ATOM_FLAG_INITIALIZED			(1<<5) // Has this atom been initialized
#define ATOM_FLAG_INTANGIBLE			(1<<6) // This atom does not physically exist, and can't be subjected to physical forces
#define ATOM_FLAG_UNTARGETABLE			(1<<7) // The atom cannot be targetted by a gun
#define ATOM_FLAG_INDESTRUCTIBLE		(1<<8) // The atom is immune to all damage mechanics
#define ATOM_FLAG_OVERLAY_QUEUED		(1<<9)

#define MOVABLE_FLAG_PROXMOVE            0x0001 // Does this object require proximity checking in Enter()?

#define OBJ_FLAG_ANCHORABLE              0x0001 // This object can be stuck in place with a tool
#define OBJ_FLAG_CONDUCTIBLE             0x0002 // Conducts electricity. (metal etc.)

#define MOB_FLAG_HOLY_BAD                0x001  // If this mob is allergic to holiness

//Flags for items (equipment)
#define ITEM_FLAG_NO_BLUDGEON            0x0001 // When an item has this it produces no "X has been hit by Y with Z" message with the default handler.
#define ITEM_FLAG_PHORONGUARD            0x0002 // Does not get contaminated by phoron.
#define ITEM_FLAG_NO_PRINT               0x0004 // This object does not leave the user's prints/fibres when using it
#define ITEM_FLAG_THICKMATERIAL          0x0010 // Prevents syringes, reagent pens, and hyposprays if equiped to slot_suit or slot_head.
#define ITEM_FLAG_STOPPRESSUREDAMAGE     0x0020 // Counts towards pressure protection. Note that like temperature protection, body_parts_covered is considered here as well.
#define ITEM_FLAG_AIRTIGHT               0x0040 // Functions with internals.
#define ITEM_FLAG_NOSLIP                 0x0080 // Prevents from slipping on wet floors, in space, etc.
#define ITEM_FLAG_BLOCK_GAS_SMOKE_EFFECT 0x0100 // Blocks the effect that chemical clouds would have on a mob -- glasses, mask and helmets ONLY! (NOTE: flag shared with ONESIZEFITSALL)
#define ITEM_FLAG_FLEXIBLEMATERIAL       0x0200 // At the moment, masks with this flag will not prevent eating even if they are covering your face.
#define ITEM_FLAG_PREMODIFIED            0x0400 // Gloves that are clipped by default
#define ITEM_FLAG_IS_BELT                0x0800 // Items that can be worn on the belt slot, even with no undersuit equipped
#define ITEM_FLAG_SILENT                 0x1000 // sneaky shoes
#define ITEM_FLAG_NO_EMBED				 0x2000	// This item can't embed in people

// Flags for pass_flags.
#define PASS_FLAG_TABLE  	0x1			//Small, crawly things that can go under or over tables and similar shaped objects
#define PASS_FLAG_GLASS  	0x2			//Lasers, light
#define PASS_FLAG_GRILLE 	0x4			//Generally gases and very tiny things
#define PASS_FLAG_FLYING 	0x8			//Objects that are not touching the ground
#define PASS_FLAG_NOMOB		0x10		//For things that don't collide with mobs at all

// for /datum/var/datum_flags
#define DF_USE_TAG		(1<<0)
#define DF_VAR_EDITED	(1<<1)
#define DF_ISPROCESSING (1<<2)