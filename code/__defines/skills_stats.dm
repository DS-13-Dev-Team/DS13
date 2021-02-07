#define SKILL_NONE     1
#define SKILL_BASIC    2
#define SKILL_ADEPT    3
#define SKILL_EXPERT   4
#define SKILL_PROF     5

#define SKILL_MIN      1 // Min skill value selectable
#define SKILL_MAX      5 // Max skill value selectable
#define SKILL_DEFAULT  4 //most mobs will default to this

#define SKILL_EASY     1
#define SKILL_AVERAGE  2
#define SKILL_HARD     4

#define SKILL_EVA           /decl/hierarchy/skill/general/EVA
#define SKILL_HAULING       /decl/hierarchy/skill/general/hauling
#define SKILL_PILOT         /decl/hierarchy/skill/general/pilot
#define SKILL_COMPUTER      /decl/hierarchy/skill/general/computer
#define SKILL_COOKING       /decl/hierarchy/skill/service/cooking
#define SKILL_COMBAT        /decl/hierarchy/skill/security/combat
#define SKILL_WEAPONS       /decl/hierarchy/skill/security/weapons
#define SKILL_CONSTRUCTION  /decl/hierarchy/skill/engineering/construction
#define SKILL_ELECTRICAL    /decl/hierarchy/skill/engineering/electrical
#define SKILL_MEDICAL       /decl/hierarchy/skill/medical/medical
#define SKILL_ANATOMY       /decl/hierarchy/skill/medical/anatomy
#define SKILL_DEVICES		/decl/hierarchy/skill/research/devices
#define SKILL_BOTANY		/decl/hierarchy/skill/service/botany
#define SKILL_FORENSICS		/decl/hierarchy/skill/security/forensics

//Value modifiers for extensions
#define STATMOD_MOVESPEED_ADDITIVE	"additive movespeed modifiers"
#define STATMOD_MOVESPEED_MULTIPLICATIVE	"multiplicative movespeed modifiers"
#define STATMOD_INCOMING_DAMAGE_MULTIPLICATIVE	"multiplicative recieved damage modifiers"
#define STATMOD_RANGED_ACCURACY	"ranged accuracy modifiers"
#define STATMOD_ATTACK_SPEED "attack speed"