//Timing subsystem
//Don't run if there is an identical unique timer active
//if the arguments to addtimer are the same as an existing timer, it doesn't create a new timer, and returns the id of the existing timer
#define TIMER_UNIQUE		0x1

//For unique timers: Replace the old timer rather then not start this one
#define TIMER_OVERRIDE		0x2

//Timing should be based on how timing progresses on clients, not the sever.
//	tracking this is more expensive,
//	should only be used in conjuction with things that have to progress client side, such as animate() or sound()
#define TIMER_CLIENT_TIME   0x4

//Timer can be stopped using deltimer()
#define TIMER_STOPPABLE     0x8
//To be used with TIMER_UNIQUE
//prevents distinguishing identical timers with the wait variable
#define TIMER_NO_HASH_WAIT 0x10

#define TIMER_NO_INVOKE_WARNING 600 //number of byond ticks that are allowed to pass before the timer subsystem thinks it hung on something

#define TIMER_ID_NULL -1

//For servers that can't do with any additional lag, set this to none in flightpacks.dm in subsystem/processing.
#define FLIGHTSUIT_PROCESSING_NONE 0
#define FLIGHTSUIT_PROCESSING_FULL 1

#define INITIALIZATION_INSSATOMS      0	//New should not call Initialize
#define INITIALIZATION_INSSATOMS_LATE 1	//New should not call Initialize; after the first pass is complete (handled differently)
#define INITIALIZATION_INNEW_MAPLOAD  2	//New should call Initialize(TRUE)
#define INITIALIZATION_INNEW_REGULAR  3	//New should call Initialize(FALSE)

#define INITIALIZE_HINT_NORMAL   0  //Nothing happens
#define INITIALIZE_HINT_LATELOAD 1  //Call LateInitialize
#define INITIALIZE_HINT_QDEL     2  //Call qdel on the atom

//type and all subtypes should always call Initialize in New()
#define INITIALIZE_IMMEDIATE(X) ##X/New(loc, ...){\
	..();\
	if(!(atom_flags & ATOM_FLAG_INITIALIZED)) {\
		args[1] = TRUE;\
		SSatoms.InitAtom(src, args);\
	}\
}

// Subsystem init_order, from highest priority to lowest priority
// Subsystems shutdown in the reverse of the order they initialize in
// The numbers just define the ordering, they are meaningless otherwise.



#define SS_INIT_GARBAGE			10
#define SS_INIT_ANTAGS			9
#define SS_INIT_PLANTS			8
#define SS_INIT_SKYBOX			7
#define SS_INIT_MAPPING			6
#define SS_INIT_CIRCUIT			5
#define SS_INIT_NECROMORPH		5
#define SS_INIT_ATOMS			4
#define SS_INIT_ICON_UPDATE		3
#define SS_INIT_MACHINES		2
#define SS_INIT_OVERLAYS		1
#define SS_INIT_DEFAULT			0
#define SS_INIT_AIR				-1
#define SS_INIT_MISC_LATE		-2
#define SS_INIT_ALARM			-3
#define SS_INIT_MISC_CODEX		-3
#define SS_INIT_SHUTTLE			-4
#define SS_INIT_LIGHTING		-20
#define SS_INIT_XENOARCH		-50
#define SS_INIT_OPEN_SPACE		-150
#define SS_INIT_BAY_LEGACY		-200
#define SS_INIT_CRAFT			-201
#define SS_INIT_ASSET			-240	//This should be near the end, other systems should do their stuff first
#define SS_INIT_UNIT_TESTS		-250
#define SS_INIT_SLOW			-999	//Make this subsystem last, even after other things that think they should be last.
									//It starts work that is intended to continue running after roundstart

// SS runlevels

#define RUNLEVEL_INIT 0
#define RUNLEVEL_LOBBY 1
#define RUNLEVEL_SETUP 2
#define RUNLEVEL_GAME 4
#define RUNLEVEL_POSTGAME 8

#define RUNLEVELS_DEFAULT (RUNLEVEL_SETUP | RUNLEVEL_GAME | RUNLEVEL_POSTGAME)



//Process times
#define MOB_PROCESS_INTERVAL	2 SECONDS
#define FAST_PROCESS_INTERVAL	0.2 SECONDS
#define SLOW_PROCESS_INTERVAL	1 MINUTE
#define MACHINE_PROCESS_INTERVAL	2 SECONDS
#define EVENT_PROCESS_INTERVAL	2 SECONDS

#define COMPILE_OVERLAYS(A) \
	do {\
		var/list/ad = A.add_overlays;\
		var/list/rm = A.remove_overlays;\
		var/list/po = A.priority_overlays;\
		if(LAZYLEN(rm)){\
			A.overlays -= rm;\
			rm.Cut();\
		}\
		if(LAZYLEN(ad)){\
			A.overlays |= ad;\
			ad.Cut();\
		}\
		if(LAZYLEN(po)){\
			A.overlays |= po;\
		}\
		A.atom_flags &= ~ATOM_FLAG_OVERLAY_QUEUED;\
	} while (FALSE)
