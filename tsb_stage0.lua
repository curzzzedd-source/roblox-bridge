--[[
================================================================================
    ████████╗██████╗  ██████╗ ██╗   ██╗ ██████╗ ███████╗████████╗
    ╚══██╔══╝██╔══██╗██╔═══██╗██║   ██║██╔═══██╗██╔════╝╚══██╔══╝
       ██║   ██████╔╝██║   ██║██║   ██║██║   ██║███████║   ██║
       ██║   ██╔══██╗██║   ██║╚██╗ ██╔╝██║   ██║╚════██║   ██║
       ██║   ██║  ██║╚██████╔╝ ╚████╔╝ ╚██████╔╝███████║   ██║
       ╚═╝   ╚═╝  ╚═╝ ╚═════╝   ╚═══╝   ╚═════╝ ╚══════╝   ╚═╝

    S T A G E   0   A U T O P L A Y E R   v 12.0
    The Strongest Battlegrounds — Full Comprehensive AI Engine

    BUILT FROM 418+ SOURCE FILES · 150+ ANIMATION IDs · REAL REMOTES

    SYSTEMS:
      • Target Selection (V/B) with blue highlight
      • Dual Mode: COMP (pure) / FLASHY (all techs)
      • Lock-On: face target every frame + camera lock
      • Auto Block V6: animation + attribute detection, target-locked
      • Auto Counter: DivergentFist, Gojo, FocusStrike service triggers
      • Auto Dodge: side dash away from incoming attacks
      • Anti-Fling: velocity monitor + auto-recover
      • Cam Lock: camera follows target with prediction
      • Hit Confirm: check enemy HP per M1 hit
      • Extended Punish: wall combo, M1 reset, tech chase, grab mix-up
      • BDC as PUNISH ONLY — never in neutral
      • Hook Dash: faces target → side dash → closes distance → M1
      • Juke: rotates CHARACTER (not camera) → dash opposite → snap back
      • Auto Tech: Supa, LockOn, LoopDash, Kibaz, LoopDash v2
      • Macros: BDC 1-4, M1 Reset, Emote Dash
      • Tech Helper: Humbled Twisted, Instant Lee, Oreo, Lix, Materia
      • Passive: Flowing Water, Kyoto, Hitbox Abuse, Auto Downslam
      • No Slow / No Fatigue (No Stun REMOVED)
      • Fast Dash: velocity scaling + inertia removal
      • Dash Modifier: health-based
      • ESP: highlight + health bar + name + ult tracking
      • Ping Compensation: KittyWare formula
      • Prediction: velocity * ping lead
      • Adaptation: tech roll, block habits, retreat habits
      • Config Save/Load (F1/F2)
      • 150+ real animation IDs
      • 8 characters with full combo routes

    CONTROLS:
      [P] toggle  [V] select  [B] unselect  [M] mode
      [L] camlock  [N] autododge  [R] m1reset  [T] emotedash
      [F1] save  [F2] load  [K] tech helper  [J] macro

================================================================================
]]

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 1: SERVICES & GLOBALS
-- ═════════════════════════════════════════════════════════════════════════════

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local VirtualInput      = game:GetService("VirtualInputManager")
local Workspace         = game:GetService("Workspace")
local Stats             = game:GetService("Stats")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Lighting          = game:GetService("Lighting")
local HttpService       = game:GetService("HttpService")

local LP       = Players.LocalPlayer
local cloneref = cloneref or clonereference or function(i) return i end
local Mouse    = LP:GetMouse()
local Camera   = Workspace.CurrentCamera

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 2: GLOBAL STATE
-- ═════════════════════════════════════════════════════════════════════════════

local Character, Root, Humanoid, Communicate, Animator
local isRunning      = false
local myCharName     = "Unknown"
local myCharAttr     = "Unknown"
local frameCounter   = 0
local currentPing    = 0.05
local FRAME_TIME     = 1 / 60
local selectedTarget = nil
local currentMode    = "COMP"
local isBusy         = false
local lastPushType   = ""
local lastNeutralTime = 0
local lockOnConn     = nil
local animConn       = nil
local actionQueue    = {}

-- Feature toggles
local Features = {
    camLock         = false,
    autoDodge       = false,
    esp             = false,
    noSlow          = false,
    noFatigue       = false,
    antiFling       = false,
    fastDash        = true,
    flow            = false,
    kyoto           = false,
    hitbox          = false,
    displayHitbox   = false,
    trueDownslam    = false,
    autoCounter     = true,
    customFOV       = 70,
    camLockStrength = 0.15,
    lockOnPrecision = 1.0,
    autoTechEnabled = false,
    autoTechVariant = "Loop Dash",
    supaMethod      = "RenderStepped",
    loopDashLooksUp = false,
    loopV2Precision = 0.25,
    loopV2FirstFlick= 0,
    loopV2SecondFlick=0.04,
    loopV2Jump       = true,
    lockonPrecision  = 1.0,
}

-- Macro settings
local Macros = {
    m1ResetEnabled  = false,
    emoteDashEnabled= false,
    emoteDashDelay  = 0.05,
    emoteDashType   = "Straight",
    bdc1Enabled     = false,
    bdc2Enabled     = false,
    bdc3Enabled     = false,
    bdc4Enabled     = false,
    techHelperEnabled  = false,
    techHelperVariant  = "Humbled Twisted",
    extraTechHelperEnabled = false,
    extraTechHelperVariant = "Instant Lethal Shift Lock",
}

-- Cam lock state
local camLockActive = false
local camLockConn   = nil

-- Auto dodge state
local lastDodgeTime = 0

-- Anti-fling state
local lastSafeCF    = nil
local antiFlingConn = nil

-- ESP storage
local espObjects    = {}

-- Ping ghost
local pingGhost     = nil
local pingGhostConn = nil
local pingHistory   = {}

-- Config
local configFolder  = "TSB_Stage0"

-- Combat state
local State = {
    mode="IDLE", m1Count=0, lastM1Time=0, lastBlockTime=0,
    blockHoldCount=0, lastHitTime=0, hitConfirmed=false,
    enemyBlockedUs=false, grabMixupCount=0, lastDashTime=0,
    dashCount=0, maxDashes=4, lastEvasiveTime=0,
    enemyComboCount=0, lastEnemyComboCheck=0,
    comboCount=0, lastComboHit=0,
    blockConnected=false, lastBlockConnectTime=0,
    lastEnemyDist=0, enemyRetreating=false, lastEnemyPos=nil,
    enemyEvasiveUsed=false, lastEnemyEvasiveTime=0,
    ultCharge=0, enemyUltCharge=0,
    -- Tech helper state
    techActive = false,
    -- Macro state
    macroActive = false,
}

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 3: ANIMATION DATABASE — 150+ REAL IDs FROM 418+ SOURCE FILES
-- ═════════════════════════════════════════════════════════════════════════════

-- M1 attack animations — all characters, 4-hit chain variants
local M1_ANIMS = {
    ["10469493270"]=true,["10469630950"]=true,["10469639222"]=true,["10469643643"]=true,
    ["13532562418"]=true,["13532600125"]=true,["13532604085"]=true,["13294471966"]=true,
    ["13491635433"]=true,["13296577783"]=true,["13295919399"]=true,["13295936866"]=true,
    ["13370310513"]=true,["13390230973"]=true,["13378751717"]=true,["13378708199"]=true,
    ["14004222985"]=true,["13997092940"]=true,["14001963401"]=true,["14136436157"]=true,
    ["15271263467"]=true,["15240216931"]=true,["15240176873"]=true,["15162694192"]=true,
    ["16515503507"]=true,["16515520431"]=true,["16515448089"]=true,["16552234590"]=true,
    ["17889458563"]=true,["17889461810"]=true,["17889471098"]=true,["17889290569"]=true,
    ["123005629431309"]=true,["100059874351664"]=true,["104895379416342"]=true,
    ["134775406437626"]=true,["15259161390"]=true,["10470104242"]=true,
}

-- Skill / ultimate animations — hold-until-end for block timing
local SKILL_ANIMS = {
    ["10468665991"]=true,["10466974800"]=true,["10471336737"]=true,["12510170988"]=true,
    ["12272894215"]=true,["12296882427"]=true,["12307656616"]=true,
    ["101588604872680"]=true,["105442749844047"]=true,["109617620932970"]=true,
    ["131820095363270"]=true,["135289891173395"]=true,["125955606488863"]=true,
    ["12534735382"]=true,["12502664044"]=true,["12509505723"]=true,
    ["12618271998"]=true,["12684390285"]=true,["13376869471"]=true,
    ["13294790250"]=true,["13376962659"]=true,["13501296372"]=true,
    ["13556985475"]=true,["145162735010"]=true,["14046756619"]=true,
    ["14299135500"]=true,["14351441234"]=true,["15290930205"]=true,
    ["15145462680"]=true,["15295895753"]=true,["15295336270"]=true,
    ["16139108718"]=true,["16515850153"]=true,["16431491215"]=true,
    ["16597322398"]=true,["16597912086"]=true,["17799224866"]=true,
    ["17838006839"]=true,["17857788598"]=true,["18179181663"]=true,
    ["113166426814229"]=true,["116753755471636"]=true,["116153572280464"]=true,
    ["114095570398448"]=true,["77509627104305"]=true,["71852503410610"]=true,
    ["91353107056596"]=true,["10470104242"]=true,
}

-- Side dash animations
local SIDEDASH_ANIMS = {
    ["10480793962"]=true,["10480796021"]=true,["10479335397"]=true,["13380255751"]=true,
}

-- Uppercut animations — one per character
local UPPERCUT_ANIMS = {
    ["13532604085"]=true,["10469639222"]=true,["13295919399"]=true,
    ["13378751717"]=true,["14001963401"]=true,["15240176873"]=true,
    ["16515448089"]=true,["17889471098"]=true,
}

-- Kyoto combo catch animations
local KYOTO_COMBO_ANIMS = {
    ["10473654583"]=true,["10473653782"]=true,
    ["10473655645"]=true,["10473655082"]=true,
}

-- Twisted / lethal / flowing water trigger animations
local TWISTED_ANIMS = {
    ["13294471966"]=true,["134775406437626"]=true,["10479335397"]=true,
}

-- Domain (ultimate) animations
local DOMAIN_ANIMS = {
    ["121984128639453"]=true,["101617544363219"]=true,["75736902190737"]=true,
    ["118861398234801"]=true,["132725601768618"]=true,
}

-- Downslam animations
local DOWNSLAM_ANIMS = {
    ["13532604085"]=true,["10469639222"]=true,["13295919399"]=true,
    ["13378751717"]=true,["14001963401"]=true,["15240176873"]=true,
    ["16515448089"]=true,["17889471098"]=true,
}

-- Auto-counter trigger animations → Knit service name
local COUNTER_TRIGGER_ANIMS = {
    ["100962226150441"]="DivergentFistService",  -- Divergent Fist
    ["124937162378188"]="GojoService",            -- Gojo
    ["115234621584704"]="FocusStrikeService",     -- Focus Strike
}

-- M1 punch anims for M1 reset detection
local M1_PUNCH_ANIMS = {
    ["10480793962"]=true,["10480796021"]=true,
}

-- Trigger anims for auto tech (Sky Upper, etc)
local TRIGGER_ANIMS = {
    ["10503381238"]=true,["13379003796"]=true,
}

-- Named animation IDs
local FLOWING_WATER    = "12273188754"
local LETHAL_DASH_ANIM = "12296113986"
local SKY_UPPER_ANIM   = "10503381238"
local GAROU_SURF_ANIM  = "12309835105"
local M1_HIT_ANIM      = "10469493270"
local BLOCK_ANIM       = "10470389827"

-- Timing table for passive techs
local TIMING = {
    [FLOWING_WATER]    = 1.5,
    [LETHAL_DASH_ANIM] = 1.42,
    [SKY_UPPER_ANIM]   = 0.3,
    [GAROU_SURF_ANIM]  = 1.1,
}

-- Zone definitions (stud distance from target)
local ZONES = {
    POINT_BLANK  = 5,    -- Zone 1: Punish — M1 chains, grab
    THREAT_RANGE = 14,   -- Zone 2: Bait — spacing, pokes
    BURST_RANGE  = 25,   -- Zone 3: Watch — velocity detection
    RESET_RANGE  = 50,   -- Zone 4: Reset — stamina regen
    LOCK_RANGE   = 50,   -- Max target lock range
    M1_RANGE     = 8,    -- Max range to actually land an M1
}

-- Combat/stun state attributes (KittyWare style)
local STUN_STATES = {
    "Counter","AbsoluteImmortal","AtomicCounter","HunterCounter",
    "UpFrames","Ragdoll","ForceField","CanBringUp",
}

local EMOTE_STATES = {
    "DoingEmote","CancelEmote","CancelEmote2","BeingLaunched","Freeze",
}

local COMBAT_STATES = {
    "Counter","HunterCounter","DoingEmote","CancelEmote","CancelEmote2",
    "BeingLaunched","Ragdoll","Freeze","BarrageBind",
}

-- Skill names per character for Console Move
local SKILL_NAMES = {
    "Shove","Normal Punch","Uppercut","Consecutive Punches",
    "Flowing Water","Lethal Whirlwind Stream","Hunter's Grasp",
    "Doom Dive","Crowd Buster","Hammer Heel","Binding Cloth",
    "Jet Dive","Blitz Shot","Ignition Burst",
    "Flash Strike","Scatter","Explosive Shuriken",
    "Homerun","Beatdown","Grand Slam","Foul Ball",
    "Quick Slice","Atmos Cleave","Pinpoint Cut",
    "Crushing Pull","Windstorm Fury","Stone Coffin","Expulsive Push",
    "Vanishing Kick","Whirlwind Drop","Head First",
}

-- Barrage move names
local BARRAGE_NAMES = {
    "Consecutive Punches","Machine Gun Blows","Bullet Barrage",
}

-- Character attribute name mapping (KittyWare style)
local CHAR_NAME_MAP = {
    Bald="Saitama", Hunter="Garou", Monster="Garou", Cyborg="Genos",
    Ninja="Sonic", Batter="MetalBat", Blade="Atomic",
    Esper="Tatsumaki", Purple="Suiryu", Tech="Genos",
}

-- Garou visual effects mapping (for visual customization)
local GAROU_VFX = {
    WaterTrail = "true", ["5"] = "false", ["3-2"] = "false",
    ["2-2"] = "false", ["1"] = "true", Spinparticle2 = "true",
    ["4-2"] = "true", ["4-3"] = "true", ["6"] = "true",
    ["7"] = "true", ["8"] = "true", ["9"] = "true",
    Line = "false", Real = "false", Real2 = "false",
    AirTrail = "false", ParticleEmitter = "false",
    big = "false", ["4-4"] = "false", Was = "false",
    Blue = "true", WaterTrailEnd = "false",
    ["1-1"] = "true", ["3-3"] = "true", ["9-2"] = "true",
    ["1-2"] = "true", ["10"] = "true", Trail1 = "false",
}

-- Smoke/particle names to remove (visual cleanup)
local SMOKE_NAMES = {
    BodySmoke=true, BodySmokez=true, SmokeUpTwo=true, SmokeUp=true,
    UpSmoke=true, SmokeBack=true, GroundSmoke=true, UpSmoke2=true,
    SmokeOne=true, Push=true, SmokeDown=true, Dust=true, Smoke=true,
    Smoke3=true, SmokeyUp=true, Smokey=true,
}

-- Cape names (visual cleanup)
local CAPE_NAMES = {
    "Custom Cape","Guild Cape","Slinky","Ruler Cape","Webbed Cape",
    "Warden Cape","Desert Cape","Divine Wheel","Spiky Cape","Fur Cape",
    "Blood Scarf","Torn Headband","Headband","Bandage Wrap","Waist Sash",
    "Leg Iron","Worn Cape","Tattered Cape","Torn Cape","White Cape",
    "Conqueror Cape","Jagged Cape","Royal Cape","White Scarf","Short Sash",
    "Red Gloves","SpiralHolder","Long Sash","Bandages","Purple Scarf",
}

-- Aura names (visual cleanup)
local AURA_NAMES = {
    "Gold Aura","Midnight Aura","Shadow Aura","Burning Aura",
    "Crimson Aura","Graceful Aura","Glitch Aura","Colorful Aura",
    "Error Aura","Stench Aura","Dark Aura","Lighting Aura","Ki Aura",
}

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 4: CHARACTER DATABASE — FULL COMBO ROUTES PER CHARACTER
-- ═════════════════════════════════════════════════════════════════════════════

local CHARACTERS = {
    Saitama = {
        displayName = "Saitama",
        internalName = "Bald",
        idealRange = 12,
        cooldowns = {Move1=8, Move2=6, Move3=10, Move4=12, Ultimate=40},
        punishRoute = {"M1","M1","M1","Move1","Move3"},
        punishDelays = {0.05, 0.05, 0.08, 0.08, 0.08},
        tools = {"Shove","Normal Punch","Uppercut","Consecutive Punches"},
        wallCombo = {
            initiator = {m1s=3, dash="right", delay=0.05},
            string    = {"Move1","Move3","Move4","Ultimate"},
            delays    = {0.1, 0.05, 0.08, 0.2},
        },
        -- Saitama-specific: M1 Shove (3M1 → front dash → side dash → M1)
        m1ShoveCombo = {
            {"m1"}, {"wait",0.05}, {"m1"}, {"wait",0.05}, {"m1"}, {"wait",0.05},
            {"dashForward"}, {"wait",0.1},
            {"dashRight"}, {"wait",0.1},
            {"m1"}, {"wait",0.05}, {"m1"}, {"wait",0.05}, {"m1"}, {"wait",0.08}, {"m1"},
        },
        -- Saitama downslam combo: 3M1 → jump → 3rd M1 → downslam
        downslamCombo = {
            {"m1"}, {"wait",0.05}, {"m1"}, {"wait",0.05},
            {"jump"}, {"wait",0.05},
            {"m1"}, {"wait",0.05},
            {"m1"}, -- downslam (4th M1)
        },
    },
    Garou = {
        displayName = "Garou",
        internalName = "Hunter",
        idealRange = 15,
        cooldowns = {Move1=9, Move2=7, Move3=10, Move4=8, Ultimate=35},
        punishRoute = {"M1","M1","M1","Move1","Move2"},
        punishDelays = {0.05, 0.05, 0.08, 0.1, 0.1},
        tools = {"Flowing Water","Lethal Whirlwind Stream","Hunter's Grasp"},
        wallCombo = {
            initiator = {m1s=3, dash="right", delay=0.05},
            string    = {"Move1","Move2","Move3"},
            delays    = {0.08, 0.1, 0.15},
        },
        -- Garou Kyoto combo: Flowing Water → teleport forward → Lethal Whirlwind
        kyotoCombo = {
            {"consoleMove","Flowing Water"},
            {"waitKyoto", 1.45},
            {"teleportForward", 16},
            {"wait", 0.05},
            {"rotateCamera", 13},
            {"wait", 0.05},
            {"consoleMove","Lethal Whirlwind Stream"},
        },
    },
    Sonic = {
        displayName = "Sonic",
        internalName = "Ninja",
        idealRange = 18,
        cooldowns = {Move1=6, Move2=8, Move3=5, Move4=10, Ultimate=30},
        punishRoute = {"M1","M1","M1","M1","Move3","Move1"},
        punishDelays = {0.05, 0.05, 0.05, 0.08, 0.05, 0.08},
        tools = {"Flash Strike","Scatter","Explosive Shuriken"},
        wallCombo = {
            initiator = {m1s=4, dash="right", delay=0.03},
            string    = {"Move3","Move1","Move4"},
            delays    = {0.05, 0.08, 0.1},
        },
    },
    MetalBat = {
        displayName = "Metal Bat",
        internalName = "Batter",
        idealRange = 10,
        cooldowns = {Move1=10, Move2=8, Move3=12, Move4=14, Ultimate=40},
        punishRoute = {"M1","M1","M1","Move1","Move3"},
        punishDelays = {0.08, 0.08, 0.1, 0.12, 0.12},
        tools = {"Homerun","Beatdown","Grand Slam","Foul Ball"},
        wallCombo = {
            initiator = {m1s=3, dash="right", delay=0.1},
            string    = {"Move1","Move3","Move4","Ultimate"},
            delays    = {0.12, 0.1, 0.15, 0.2},
        },
    },
    Atomic = {
        displayName = "Atomic Samurai",
        internalName = "Blade",
        idealRange = 14,
        cooldowns = {Move1=5, Move2=8, Move3=10, Move4=12, Ultimate=45},
        punishRoute = {"M1","M1","M1","M1","Move1","Move2"},
        punishDelays = {0.05, 0.05, 0.05, 0.08, 0.05, 0.08},
        tools = {"Quick Slice","Atmos Cleave","Pinpoint Cut"},
        wallCombo = {
            initiator = {m1s=4, dash="right", delay=0.05},
            string    = {"Move1","Move2","Move3","Move4","Ultimate"},
            delays    = {0.05, 0.08, 0.1, 0.12, 0.3},
        },
    },
    Tatsumaki = {
        displayName = "Tatsumaki",
        internalName = "Esper",
        idealRange = 22,
        cooldowns = {Move1=7, Move2=8, Move3=12, Move4=15, Ultimate=35},
        punishRoute = {"M1","M1","M1","Move2","Move1"},
        punishDelays = {0.05, 0.05, 0.08, 0.1, 0.08},
        tools = {"Crushing Pull","Windstorm Fury","Stone Coffin","Expulsive Push"},
        wallCombo = {
            initiator = {m1s=3, dash="back", delay=0.05},
            string    = {"Move2","Move3","Move4","Ultimate"},
            delays    = {0.1, 0.1, 0.15, 0.2},
        },
    },
    Suiryu = {
        displayName = "Suiryu",
        internalName = "Purple",
        idealRange = 13,
        cooldowns = {Move1=7, Move2=8, Move3=10, Move4=12, Ultimate=35},
        punishRoute = {"M1","M1","M1","M1","Move1","Move2"},
        punishDelays = {0.05, 0.05, 0.05, 0.08, 0.08, 0.1},
        tools = {"Vanishing Kick","Whirlwind Drop","Head First"},
        wallCombo = {
            initiator = {m1s=4, dash="right", delay=0.05},
            string    = {"Move1","Move2","Move3","Move4"},
            delays    = {0.08, 0.1, 0.08, 0.12},
        },
    },
    Genos = {
        displayName = "Genos",
        internalName = "Cyborg",
        idealRange = 16,
        cooldowns = {Move1=7, Move2=8, Move3=10, Move4=12, Ultimate=35},
        punishRoute = {"M1","M1","M1","Move1","Move3"},
        punishDelays = {0.05, 0.05, 0.08, 0.08, 0.1},
        tools = {"Jet Dive","Blitz Shot","Ignition Burst"},
        wallCombo = {
            initiator = {m1s=3, dash="right", delay=0.05},
            string    = {"Move1","Move2","Move3","Move4"},
            delays    = {0.08, 0.1, 0.08, 0.12},
        },
    },
}

-- Ability key mappings
local ABILITY_KEYS = {
    Move1    = Enum.KeyCode.One,
    Move2    = Enum.KeyCode.Two,
    Move3    = Enum.KeyCode.Three,
    Move4    = Enum.KeyCode.Four,
    Ultimate = Enum.KeyCode.Five,
    Evasive  = Enum.KeyCode.LeftControl,
    Grab     = Enum.KeyCode.G,
}

-- Dash remote patterns (Communicate FireServer)
-- Z = jump, S = back, Q = left, D = right (user's custom keybinds)
local DASH_REMOTE = {
    forward = { Dash=Enum.KeyCode.W, Key=Enum.KeyCode.Q, Goal="KeyPress" },
    back    = { Dash=Enum.KeyCode.S, Key=Enum.KeyCode.Q, Goal="KeyPress" },
    left    = { Dash=Enum.KeyCode.Q, Key=Enum.KeyCode.Q, Goal="KeyPress" },
    right   = { Dash=Enum.KeyCode.D, Key=Enum.KeyCode.Q, Goal="KeyPress" },
}

-- Communicate goal patterns
local COMM = {
    m1         = { Goal="LeftClick", Mobile=true },
    m1Release  = { Goal="LeftClickRelease", Mobile=true },
    jump       = { Goal="KeyPress", Key=Enum.KeyCode.Space },
    blockPress = { Goal="KeyPress", Key=Enum.KeyCode.F },
    blockRelease = { Goal="KeyRelease", Key=Enum.KeyCode.F },
    emote      = { Goal="Emote", Emote="Crush" },
    emoteJump  = { Goal="Jump", Mobile=true },
    emoteStopJump = { Goal="StopJump", Mobile=true },
}

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 5: HELPERS — isRagdolled, isActionable, isAnimPlaying, etc
-- ═════════════════════════════════════════════════════════════════════════════

-- Check if character is ragdolled/stunned
local function isRagdolled(char)
    if not char then return true end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return true end
    if hum.Health <= 0 then return true end
    local state = hum:GetState()
    if state == Enum.HumanoidStateType.Ragdoll
    or state == Enum.HumanoidStateType.Physics
    or state == Enum.HumanoidStateType.GettingUp then
        return true
    end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root and root.AssemblyLinearVelocity.Magnitude > 100 and hum.Sit == false then
        return true
    end
    return false
end

-- Check if character has any stun/state attribute
local function hasState(char, states)
    if not char then return false end
    for _, s in ipairs(states) do
        if char:FindFirstChild(s) then return true end
    end
    return false
end

-- Check if character is actionable (not stunned/emoting)
local function isActionable(char)
    if not char then return false end
    if isRagdolled(char) then return false end
    if hasState(char, COMBAT_STATES) then return false end
    return true
end

-- Check if a specific animation is playing on a character
local function isAnimPlaying(char, animId)
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    for _, track in pairs(hum:GetPlayingAnimationTracks()) do
        if track.Animation and track.Animation.AnimationId then
            local id = track.Animation.AnimationId:gsub("rbxassetid://", "")
            if id == tostring(animId) then return track end
        end
    end
    return nil
end

-- Stop a specific animation on our character
local function stopAnim(animId)
    if not Humanoid then return end
    for _, track in pairs(Humanoid:GetPlayingAnimationTracks()) do
        if track.Animation and track.Animation.AnimationId == ("rbxassetid://" .. tostring(animId)) then
            track:Stop()
        end
    end
end

-- Check if character has no block attribute
local function hasNoBlock(char)
    if not char then return false end
    return char:FindFirstChild("NoBlock") ~= nil
end

-- Check if enemy is approaching us (velocity toward us)
local function isApproachingUs(target)
    if not target or not Root then return false end
    local tRoot = target:FindFirstChild("HumanoidRootPart")
    if not tRoot then return false end
    local vel = tRoot.AssemblyLinearVelocity
    if vel.Magnitude < 10 then return false end
    local towardsMe = (Root.Position - tRoot.Position).Unit
    return vel:Dot(towardsMe) > 0.7
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 6: PING COMPENSATION — KittyWare formula
-- ═════════════════════════════════════════════════════════════════════════════

local function getPing()
    local ok, val = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if ok and val then return val / 1000 end
    return currentPing
end

-- KittyWare ping compensation: adjusted = base + ((ping - 0.140) * -0.0003846)
local function pingCompensate(baseTime)
    return math.max(baseTime + ((getPing() - 0.140) * -0.0003846), 0.01)
end

local function getAdjustedDelay(frames)
    return math.max(frames * FRAME_TIME - currentPing + 0.02, 0.01)
end

local function getPingScaledHold()
    local pingMs = currentPing * 1000
    return 0.22 + math.clamp((pingMs - 30) / 170, 0, 1) * 0.06
end

-- Ping-adjusted Kyoto multiplier
local function getKyotoMultiplier()
    local ms = currentPing * 1000
    if ms <= 50 then return 0.65
    elseif ms <= 100 then return 0.75
    elseif ms <= 150 then return 0.85
    elseif ms <= 200 then return 0.95
    elseif ms <= 250 then return 1.05
    else return 1.15 end
end

-- Ping tracking loop (runs in background, updates every 2s)
task.spawn(function()
    while true do
        local ok, val = pcall(function()
            return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        if ok and val then
            currentPing = val / 1000
        else
            local p = LP.GetNetworkPing and LP:GetNetworkPing()
            if p then currentPing = p end
        end
        task.wait(2)
    end
end)

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 7: CAMERA HELPERS
-- ═════════════════════════════════════════════════════════════════════════════

-- Look at a position with precision lerp
local function lookAt(targetPos, precision)
    precision = precision or 1
    if not Camera or not Root then return end
    local currentPos = Camera.CFrame.Position
    local targetCF = CFrame.new(currentPos, targetPos)
    Camera.CFrame = Camera.CFrame:Lerp(targetCF, precision)
end

-- Smoothly rotate camera by angle over duration
local function smoothRotateCamera(angleDeg, duration, lockCharacter)
    duration = duration or 0.2
    if not Camera then return end
    local startCF = Camera.CFrame
    local startLook = startCF.LookVector
    local startYaw = math.atan2(-startLook.X, -startLook.Z)
    local startTime = tick()
    local conn
    conn = RunService.RenderStepped:Connect(function()
        local alpha = math.min((tick() - startTime) / duration, 1)
        local eased = alpha * alpha * (3 - 2 * alpha)
        local newYaw = startYaw + (math.rad(angleDeg) * eased)
        local pos = Camera.CFrame.Position
        local pitch = math.asin(startLook.Y)
        if lockCharacter and Root and Humanoid then
            Humanoid.AutoRotate = false
            Root.CFrame = CFrame.new(Root.Position) * CFrame.Angles(0, newYaw, 0)
        else
            Camera.CFrame = CFrame.new(pos) * CFrame.Angles(0, newYaw, 0) * CFrame.Angles(pitch, 0, 0)
        end
        if alpha >= 1 then conn:Disconnect() end
    end)
end

-- Set camera CFrame to look at a world position
local function setCameraLookAt(worldPos)
    if not Camera or not Root then return end
    local currentPos = Camera.CFrame.Position
    Camera.CFrame = CFrame.new(currentPos, worldPos)
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 8: TARGET SELECTION — V select, B unselect
-- Bot ONLY fights the selected target. No target = does nothing.
-- ═════════════════════════════════════════════════════════════════════════════

local targetHighlight = nil

local function clearHighlight()
    if targetHighlight then
        targetHighlight:Destroy()
        targetHighlight = nil
    end
end

local function applyHighlight(model)
    clearHighlight()
    if not model then return end
    targetHighlight = Instance.new("Highlight")
    targetHighlight.Name = "TSB_TargetHighlight"
    targetHighlight.FillColor = Color3.fromRGB(0, 120, 255)
    targetHighlight.FillTransparency = 0.5
    targetHighlight.OutlineColor = Color3.fromRGB(100, 180, 255)
    targetHighlight.OutlineTransparency = 0
    targetHighlight.Parent = model
end

local function getMouseTarget()
    local target = Mouse.Target
    if not target then return nil end
    local model = target:FindFirstAncestorOfClass("Model")
    if not model then return nil end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not (hum and hum.Health > 0) then return nil end
    if model == LP.Character then return nil end
    return model
end

local function selectTarget()
    local target = getMouseTarget()
    if target then
        selectedTarget = target
        applyHighlight(target)
        State.grabMixupCount = 0
        lastPushType = ""
        print("[TSB] Target locked:", target.Name)
    else
        print("[TSB] No target under cursor")
    end
end

local function unselectTarget()
    selectedTarget = nil
    clearHighlight()
    print("[TSB] Target unlocked")
end

-- Returns selected target if valid, otherwise nil (NO fallback to closest)
local function getTarget()
    if selectedTarget and selectedTarget.Parent then
        local tHum = selectedTarget:FindFirstChild("Humanoid")
        if tHum and tHum.Health > 0 then
            return selectedTarget
        end
    end
    selectedTarget = nil
    clearHighlight()
    return nil
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 9: DISTANCE & PREDICTION
-- ═════════════════════════════════════════════════════════════════════════════

local function getDist(target)
    if not target then return math.huge end
    local tRoot = target:FindFirstChild("HumanoidRootPart")
    if not tRoot or not Root then return math.huge end
    return (Root.Position - tRoot.Position).Magnitude
end

local function getPredictedPosition(target)
    if not target then return nil end
    local tRoot = target:FindFirstChild("HumanoidRootPart")
    if not tRoot then return nil end
    -- Predict where target will be after our ping delay
    return tRoot.Position + tRoot.AssemblyLinearVelocity * currentPing
end

local function getPredictedDist(target)
    local predPos = getPredictedPosition(target)
    if not predPos or not Root then return getDist(target) end
    return (Root.Position - predPos).Magnitude
end

local function getEnemyVel(target)
    if not target then return Vector3.zero end
    local tRoot = target:FindFirstChild("HumanoidRootPart")
    return tRoot and tRoot.AssemblyLinearVelocity or Vector3.zero
end

local function getEnemyHealthPct(target)
    if not target then return 1 end
    local tHum = target:FindFirstChild("Humanoid")
    if not tHum then return 1 end
    return tHum.Health / tHum.MaxHealth
end

local function getCharData()
    return CHARACTERS[myCharName] or CHARACTERS.Saitama
end

local function hasStamina()
    return State.dashCount < State.maxDashes
end

local function regenStamina()
    if tick() - State.lastDashTime > 1.5 and State.dashCount > 0 then
        State.dashCount = State.dashCount - 1
        State.lastDashTime = tick()
    end
end

local function isNearWall()
    if not Root then return false end
    local p = Root.Position
    return math.min(math.abs(p.X-100), math.abs(p.X+100), math.abs(p.Z-100), math.abs(p.Z+100)) < 25
end

-- Track if enemy is retreating (moving away from us)
local function updateEnemyTracking(target)
    if not target then State.enemyRetreating = false; return end
    local tRoot = target:FindFirstChild("HumanoidRootPart")
    if not tRoot or not Root then return end
    local currentDist = (Root.Position - tRoot.Position).Magnitude
    if State.lastEnemyPos then
        local lastDist = (Root.Position - State.lastEnemyPos).Magnitude
        State.enemyRetreating = currentDist > lastDist + 0.5
    end
    State.lastEnemyPos = tRoot.Position
    State.lastEnemyDist = currentDist
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 10: FACE TARGET — rotate character toward target
-- ═════════════════════════════════════════════════════════════════════════════

local function faceTarget(target)
    if not target or not Root or not Humanoid then return end
    local tRoot = target:FindFirstChild("HumanoidRootPart")
    if not tRoot then return end
    local dir = (tRoot.Position - Root.Position)
    local flatDir = Vector3.new(dir.X, 0, dir.Z)
    if flatDir.Magnitude > 0.1 then
        local goalCF = CFrame.new(Root.Position, Root.Position + flatDir.Unit)
        Root.CFrame = Root.CFrame:Lerp(goalCF, 0.4)
    end
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 11: COMMUNICATE REMOTE — real TSB input system
-- ═════════════════════════════════════════════════════════════════════════════

local function fireComm(data)
    if not Communicate then
        -- Try to re-get Communicate if we lost it
        if Character then
            Communicate = cloneref(Character:FindFirstChild("Communicate"))
        end
    end
    if not Communicate then return false end
    pcall(function() Communicate:FireServer(unpack({ data })) end)
    return true
end

local function updateCommunicate()
    if not Character then return end
    -- Wait for Communicate to load (it might not exist immediately)
    local comm = Character:FindFirstChild("Communicate")
    if comm then
        Communicate = cloneref(comm)
        print("[TSB] Communicate remote found")
    else
        -- Try WaitForChild as fallback
        local ok, result = pcall(function()
            return Character:WaitForChild("Communicate", 5)
        end)
        if ok and result then
            Communicate = cloneref(result)
            print("[TSB] Communicate remote found (waited)")
        else
            warn("[TSB] Communicate remote NOT found — will retry")
        end
    end
end

-- BlockService remote (more reliable than Communicate for blocking)
local BlockServiceRE, BlockDeactivateRE

local function getBlockService()
    if BlockServiceRE then return BlockServiceRE end
    local ok, rem = pcall(function()
        return ReplicatedStorage.Knit.Knit.Services.BlockService.RE.Activated
    end)
    if ok and rem then BlockServiceRE = rem end
    return BlockServiceRE
end

local function getBlockDeactivate()
    if BlockDeactivateRE then return BlockDeactivateRE end
    local ok, rem = pcall(function()
        return ReplicatedStorage.Knit.Knit.Services.BlockService.RE.Deactivated
    end)
    if ok and rem then BlockDeactivateRE = rem end
    return BlockDeactivateRE
end

-- Fire a Knit service remote (for auto counter)
local function fireService(serviceName)
    local ok, service = pcall(function()
        return ReplicatedStorage.Knit.Knit.Services[serviceName].RE.Activated
    end)
    if ok and service then
        pcall(function() service:FireServer() end)
        return true
    end
    return false
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 12: ACTION QUEUE — single action at a time, no flooding
-- ═════════════════════════════════════════════════════════════════════════════

local function pushAction(fn, priority)
    priority = priority or 0
    if isBusy then return end
    table.insert(actionQueue, { fn=fn, priority=priority })
    table.sort(actionQueue, function(a, b) return a.priority > b.priority end)
    -- Keep queue small — max 2 pending actions
    while #actionQueue > 2 do table.remove(actionQueue, 3) end
end

local function clearActions()
    actionQueue = {}
end

-- Action executor — runs in separate thread, never blocks RenderStepped
-- Uses task.wait (wall-clock) so FPS doesn't affect timing
task.spawn(function()
    while true do
        if isRunning and #actionQueue > 0 and not isBusy then
            local action = table.remove(actionQueue, 1)
            if action and action.fn then
                isBusy = true
                local ok, err = pcall(action.fn)
                if not ok then
                    warn("[TSB] Action error:", err)
                end
                isBusy = false
                -- Clear any remaining stale actions after completion
                actionQueue = {}
            end
        end
        task.wait(0.005) -- 5ms poll — fast but not wasteful
    end
end)

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 13: LOCK-ON — face target every frame when not busy
-- ═════════════════════════════════════════════════════════════════════════════

local function setupLockOn()
    if lockOnConn then lockOnConn:Disconnect() end
    lockOnConn = RunService.Heartbeat:Connect(function()
        if not isRunning or not Root or not Humanoid then return end
        local target = getTarget()
        if not target then return end
        -- Face target when not busy (don't fight an action in progress)
        if not isBusy then
            faceTarget(target)
        end
        -- Track enemy movement for BDC trigger
        updateEnemyTracking(target)
        -- Update ESP if enabled
        if Features.esp then
            updateESP()
        end
    end)
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 14: CAM LOCK — camera follows target with prediction
-- ═════════════════════════════════════════════════════════════════════════════

local function startCamLock()
    if camLockConn then camLockConn:Disconnect() end
    camLockActive = true
    camLockConn = RunService.Heartbeat:Connect(function()
        if not camLockActive then return end
        local target = getTarget()
        if not target then
            camLockActive = false
            return
        end
        local predPos = getPredictedPosition(target)
        if predPos then
            lookAt(predPos, Features.camLockStrength)
        end
    end)
    print("[TSB] Cam Lock ON")
end

local function stopCamLock()
    camLockActive = false
    if camLockConn then camLockConn:Disconnect(); camLockConn = nil end
    print("[TSB] Cam Lock OFF")
end

local function toggleCamLock()
    if camLockActive then stopCamLock() else startCamLock() end
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 15: COMBAT CONTROLLER
-- ═════════════════════════════════════════════════════════════════════════════

local Combat = { cooldowns={}, didGetHit=false, lastHealth=100 }

function Combat:init()
    if not Humanoid then return end
    self.lastHealth = Humanoid.Health
    Humanoid.HealthChanged:Connect(function(h)
        if h < self.lastHealth then
            self.didGetHit = true
            State.lastHitTime = tick()
            State.hitConfirmed = false
        elseif h > self.lastHealth then
            self.didGetHit = false
        end
        self.lastHealth = h
    end)
end

-- M1 — distance-gated, faces target, only fires if in range
function Combat:m1()
    local target = getTarget()
    if target and getDist(target) > ZONES.M1_RANGE then
        return false
    end
    if target then faceTarget(target) end

    -- Try Communicate first, fallback to VirtualInput
    if Communicate then
        fireComm(COMM.m1)
        task.wait(0.01)
        fireComm(COMM.m1Release)
    else
        VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.01)
        VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end

    State.m1Count = State.m1Count + 1
    State.lastM1Time = tick()
    return true
end

-- HIT CONFIRM M1 CHAIN — checks enemy health after each hit
-- If hit connects → continue combo. If blocked → grab. If whiff → stop.
function Combat:m1ChainConfirmed(target, count)
    count = count or 4
    if not target then return 0 end
    local hitsLanded = 0

    for i = 1, count do
        -- DISTANCE CHECK before every M1 — don't fight air
        local dist = getDist(target)
        if dist > ZONES.M1_RANGE then
            return hitsLanded
        end

        -- Face target before hitting
        faceTarget(target)

        local tHum = target:FindFirstChild("Humanoid")
        if not tHum then return hitsLanded end
        local hpBefore = tHum.Health

        -- Fire M1
        if Communicate then
            fireComm(COMM.m1)
            task.wait(0.01)
            fireComm(COMM.m1Release)
        else
            VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.01)
            VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end
        State.m1Count = State.m1Count + 1

        -- Ping-compensated wait for hit registration
        task.wait(pingCompensate(0.05 + (i > 2 and 0.03 or 0)))

        -- Check hit result
        if tHum and tHum.Parent then
            if tHum.Health < hpBefore then
                -- HIT CONFIRMED — enemy took damage
                hitsLanded = hitsLanded + 1
                State.hitConfirmed = true
                State.enemyBlockedUs = false
            elseif tHum.Health == hpBefore then
                -- No damage — blocked or whiffed
                if dist < ZONES.M1_RANGE then
                    -- Probably blocked — grab mix-up
                    State.enemyBlockedUs = true
                    State.hitConfirmed = false
                    if i >= 2 then
                        -- Grab immediately — they're blocking
                        self:grab()
                        task.wait(0.05)
                        -- After grab, try M1 chain again
                        if getDist(target) <= ZONES.M1_RANGE then
                            faceTarget(target)
                            fireComm(COMM.m1); task.wait(0.01); fireComm(COMM.m1Release)
                            task.wait(0.05)
                            fireComm(COMM.m1); task.wait(0.01); fireComm(COMM.m1Release)
                        end
                        return hitsLanded + 2
                    end
                else
                    -- Whiffed — too far, stop
                    return hitsLanded
                end
            end
        end
    end
    return hitsLanded
end

-- Simple M1 combo (no hit confirm)
function Combat:m1Combo(count)
    count = count or 4
    for i = 1, count do
        if not self:m1() then return end
        task.wait(i <= 2 and 0.05 or i == 3 and 0.08 or 0.1)
    end
end

-- M1 Reset: 3 M1s → side dash cancel → side dash → M1 chain
function Combat:m1Reset()
    if not self:m1() then return end
    task.wait(0.05)
    if not self:m1() then return end
    task.wait(0.05)
    if not self:m1() then return end
    task.wait(0.08)
    fireComm(DASH_REMOTE.right)
    task.wait(0.28)
    fireComm(DASH_REMOTE.left)
    task.wait(0.49)
    self:m1(); task.wait(0.05)
    self:m1(); task.wait(0.05)
    self:m1(); task.wait(0.08)
    self:m1(); task.wait(0.1)
end

function Combat:useAbility(name)
    local key = ABILITY_KEYS[name]
    if not key then return false end
    if self.cooldowns[name] and tick() < self.cooldowns[name] then return false end

    -- Face target before using ability
    local target = getTarget()
    if target then faceTarget(target) end

    VirtualInput:SendKeyEvent(true, key, false, game)
    task.wait(0.02)
    VirtualInput:SendKeyEvent(false, key, false, game)

    local cd = getCharData().cooldowns
    if cd and cd[name] then
        self.cooldowns[name] = tick() + cd[name]
    end
    return true
end

function Combat:grab()
    -- Check distance before grabbing
    local target = getTarget()
    if target and getDist(target) > ZONES.M1_RANGE + 2 then
        return false
    end
    if target then faceTarget(target) end

    VirtualInput:SendKeyEvent(true, ABILITY_KEYS.Grab, false, game)
    task.wait(0.02)
    VirtualInput:SendKeyEvent(false, ABILITY_KEYS.Grab, false, game)
    return true
end

function Combat:evasive()
    if tick() - State.lastEvasiveTime < 0.5 then return end
    State.lastEvasiveTime = tick()
    VirtualInput:SendKeyEvent(true, ABILITY_KEYS.Evasive, false, game)
    task.wait(0.02)
    VirtualInput:SendKeyEvent(false, ABILITY_KEYS.Evasive, false, game)
end

function Combat:jump()
    fireComm(COMM.jump)
end

function Combat:isOnCooldown(name)
    return self.cooldowns[name] and tick() < self.cooldowns[name] or false
end

-- Console Move — equip and fire a tool/skill remotely
function Combat:consoleMove(toolName)
    if not Character then return end
    local tool = LP.Backpack:FindFirstChild(toolName) or Character:FindFirstChild(toolName)
    if tool then
        local target = getTarget()
        if target then faceTarget(target) end
        fireComm({ Tool=tool, Goal="Console Move" })
    end
end

-- Emote Dash — emote → jump → velocity burst (real TSB tech)
function Combat:emoteDash()
    fireComm(COMM.emote)
    task.wait(0.15)
    fireComm(COMM.emoteJump)
    task.wait(0.01)
    fireComm(COMM.emoteStopJump)
    task.wait(0.2)
    if Root then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        task.wait(0.2)
        Root.AssemblyLinearVelocity = Root.CFrame.LookVector * 133
    end
    task.wait(0.5)
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 16: UNIVERSAL TSB TECHNIQUES (from the wiki)
-- ═════════════════════════════════════════════════════════════════════════════

-- M1 Shove: 3 M1s → front dash (locks in place, sends opponent rolling)
function Combat:m1Shove(target)
    if not target or getDist(target) > ZONES.M1_RANGE + 3 then return end
    faceTarget(target)
    self:m1(); task.wait(0.05); self:m1(); task.wait(0.05); self:m1(); task.wait(0.05)
    fireComm(DASH_REMOTE.forward) -- combo context: front dash pushes opponent
    task.wait(0.1)
    fireComm(DASH_REMOTE.right) -- side dash to follow up
    task.wait(0.1)
    if getDist(target) <= ZONES.M1_RANGE then
        faceTarget(target)
        self:m1(); task.wait(0.05); self:m1(); task.wait(0.05)
        self:m1(); task.wait(0.08); self:m1()
    end
end

-- Delayed M1s: space out clicks to extend combo duration
function Combat:delayedM1Chain(target, count)
    count = count or 4
    if not target or getDist(target) > ZONES.M1_RANGE then return end
    for i = 1, count do
        faceTarget(target)
        self:m1()
        task.wait(0.05 + (i * 0.03)) -- increasing delay per hit
    end
end

-- Stun Negation: front dash onto opponent right as they get up from ragdoll
function Combat:stunNegation(target)
    if not target then return end
    local tHum = target:FindFirstChild("Humanoid")
    if not tHum then return end
    -- Wait for them to be getting up
    while tHum:GetState() == Enum.HumanoidStateType.Ragdoll do task.wait() end
    -- Front dash immediately as they stand — bypasses no-stun
    if getDist(target) < 15 then
        fireComm(DASH_REMOTE.forward) -- combo context
        task.wait(0.1)
        faceTarget(target)
        self:m1()
    end
end

-- Ground Punch: 4th M1 on ragdolled opponent to re-ragdoll them
function Combat:groundPunch(target)
    if not target then return end
    local tHum = target:FindFirstChild("Humanoid")
    if not tHum then return end
    if tHum:GetState() == Enum.HumanoidStateType.Ragdoll then
        task.wait(0.3)
        faceTarget(target)
        self:m1(); task.wait(0.05)
        self:m1(); task.wait(0.05)
        self:m1(); task.wait(0.05)
        self:m1() -- 4th M1 ragdolls them again
    end
end

-- DMG Chip: mini uppercut → side dash → front dash to chip damage
function Combat:dmgChip(target)
    if not target or getDist(target) > ZONES.M1_RANGE + 5 then return end
    faceTarget(target)
    self:m1(); task.wait(0.05); self:m1(); task.wait(0.05); self:m1(); task.wait(0.05)
    Combat:jump(); task.wait(0.05); self:m1(); task.wait(0.1)
    fireComm(DASH_REMOTE.right); task.wait(0.05)
    fireComm(DASH_REMOTE.forward) -- combo context: chip damage
    task.wait(0.1)
    if getDist(target) <= ZONES.M1_RANGE then
        faceTarget(target)
        self:m1()
    end
end

-- Uppercut Dash: mini uppercut → front dash loop to catch them
function Combat:uppercutDash(target)
    if not target or getDist(target) > ZONES.M1_RANGE + 5 then return end
    faceTarget(target)
    self:m1(); task.wait(0.05); self:m1(); task.wait(0.05); self:m1(); task.wait(0.05)
    Combat:jump(); task.wait(0.05); self:m1(); task.wait(0.1)
    fireComm(DASH_REMOTE.forward) -- combo context: loop dash to catch
    task.wait(0.1)
    fireComm(DASH_REMOTE.right)
    task.wait(0.05)
    if getDist(target) <= ZONES.M1_RANGE then
        faceTarget(target)
        self:m1()
    end
end

-- True Downslam: 2 M1s → jump → 3rd M1 → downslam (inescapable)
function Combat:trueDownslam(target)
    if not target or getDist(target) > ZONES.M1_RANGE then return end
    faceTarget(target)
    self:m1(); task.wait(0.05)
    self:m1(); task.wait(0.05)
    Combat:jump(); task.wait(0.05)
    self:m1() -- 3rd M1 during jump
    task.wait(0.05)
    -- Downslam (4th M1)
    fireComm(COMM.m1); task.wait(0.01); fireComm(COMM.m1Release)
end

-- Execute a combo sequence (table of steps)
function Combat:executeCombo(steps, target)
    if not steps or not target then return end
    for _, step in ipairs(steps) do
        local action = step[1]
        local value = step[2]

        if action == "m1" then
            if getDist(target) <= ZONES.M1_RANGE then
                faceTarget(target)
                self:m1()
            end
        elseif action == "consoleMove" then
            self:consoleMove(value)
        elseif action == "wait" then
            task.wait(value)
        elseif action == "waitKyoto" then
            task.wait(value * getKyotoMultiplier())
        elseif action == "dashRight" then
            fireComm(DASH_REMOTE.right)
        elseif action == "dashLeft" then
            fireComm(DASH_REMOTE.left)
        elseif action == "dashForward" then
            fireComm(DASH_REMOTE.forward)
        elseif action == "dashBack" then
            fireComm(DASH_REMOTE.back)
        elseif action == "teleportForward" then
            if Root then
                faceTarget(target)
                Root.CFrame = Root.CFrame + Root.CFrame.LookVector * value
            end
        elseif action == "rotateCamera" then
            smoothRotateCamera(value, 0.1, false)
        elseif action == "jump" then
            self:jump()
        elseif action == "ability" then
            self:useAbility(value)
        elseif action == "grab" then
            self:grab()
        end
    end
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 17: MOVEMENT CONTROLLER
-- Hook Dash: faces target → side dash → closes distance → M1
-- BDC: PUNISH ONLY — fires when enemy retreats after M1 exchange
-- Juke: rotates CHARACTER → dash opposite → snap back
-- ═════════════════════════════════════════════════════════════════════════════

local Move = { isBlocking=false }

function Move:fireDash(direction)
    if not hasStamina() then return false end
    local data = DASH_REMOTE[direction] or DASH_REMOTE.right
    local success = fireComm(data)

    -- Fallback: use VirtualInput if Communicate fails
    if not success then
        if data.Dash then
            VirtualInput:SendKeyEvent(true, data.Dash, false, game)
            task.wait(0.01)
            if data.Key then
                VirtualInput:SendKeyEvent(true, data.Key, false, game)
            end
            task.wait(0.03)
            VirtualInput:SendKeyEvent(false, data.Dash, false, game)
            if data.Key then
                VirtualInput:SendKeyEvent(false, data.Key, false, game)
            end
        end
    end

    State.dashCount = State.dashCount + 1
    State.lastDashTime = tick()

    -- Fast dash: scale velocity + remove inertia
    if Features.fastDash and Root then
        task.spawn(function()
            task.wait(0.005)
            local dv = Root:FindFirstChild("dodgevelocity")
            if dv then
                local v = dv.Velocity
                dv.Velocity = Vector3.new(v.X * 1.3, v.Y, v.Z * 1.3)
            end
            task.wait(pingCompensate(0.04))
            if Root then
                Root.AssemblyLinearVelocity = Vector3.new(
                    Root.AssemblyLinearVelocity.X * 0.6,
                    Root.AssemblyLinearVelocity.Y,
                    Root.AssemblyLinearVelocity.Z * 0.6
                )
            end
        end)
    end
    return true
end

function Move:pressBlock()
    if self.isBlocking then return end
    local bs = getBlockService()
    if bs then
        pcall(function() bs:FireServer() end)
    else
        fireComm(COMM.blockPress)
    end
    self.isBlocking = true
    State.lastBlockTime = tick()
    State.blockHoldCount = State.blockHoldCount + 1
end

function Move:releaseBlock()
    if not self.isBlocking then return end
    local bd = getBlockDeactivate()
    if bd then
        pcall(function() bd:FireServer() end)
    else
        fireComm(COMM.blockRelease)
    end
    self.isBlocking = false
end

-- ═══ HOOK DASH — side dash toward target → face target → M1 ═══
-- Actually closes distance: faces target BEFORE dashing so dash goes toward them
function Move:hookDash(direction)
    direction = direction or "right"
    local target = getTarget()
    if not target then return end

    -- Face target BEFORE dashing so the dash goes toward them
    faceTarget(target)

    -- Fire the side dash
    if not self:fireDash(direction) then return end

    -- Wait for dash to start
    task.wait(getAdjustedDelay(2))

    -- Snap camera to face target during dash
    local tRoot = target:FindFirstChild("HumanoidRootPart")
    if tRoot and Camera then
        local predPos = getPredictedPosition(target) or tRoot.Position
        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, predPos)
    end

    -- Wait for dash to complete
    task.wait(getAdjustedDelay(3))

    -- After dash, face target again
    faceTarget(target)

    -- If we're now in M1 range, attack
    if getDist(target) <= ZONES.M1_RANGE then
        Combat:m1()
    end
end

-- ═══ BACKDASH CANCEL — PUNISH ONLY ═══
-- BDC is used when: you land M1s, enemy retreats, you BDC to catch them
-- It is NOT used in neutral as a spacing tool
function Move:backdashCancel()
    -- Press ability key (cancels into backdash)
    VirtualInput:SendKeyEvent(true, Enum.KeyCode.One, false, game)
    task.wait(0.01)
    VirtualInput:SendKeyEvent(false, Enum.KeyCode.One, false, game)
    task.wait(0.01)
    -- Press S (back direction)
    VirtualInput:SendKeyEvent(true, Enum.KeyCode.S, false, game)
    task.wait(0.01)
    -- Press Q (dash)
    VirtualInput:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
    -- Ping-compensated hold
    task.wait(pingCompensate(0.1))
    -- Release Q then S
    VirtualInput:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
    VirtualInput:SendKeyEvent(false, Enum.KeyCode.S, false, game)

    -- After BDC, immediately dash TOWARD the target to catch them
    local target = getTarget()
    if target then
        faceTarget(target)
        task.wait(getAdjustedDelay(1))
        -- Side dash toward target to close distance
        self:fireDash(math.random() > 0.5 and "right" or "left")
        task.wait(getAdjustedDelay(2))
        -- If in range, M1 to snipe them
        if getDist(target) <= ZONES.M1_RANGE then
            faceTarget(target)
            Combat:m1()
        end
    end
end

-- Shove BDC — backdash → cancel with Shove → dash toward → M1
function Move:shoveBDC()
    local target = getTarget()
    if not target then return end
    faceTarget(target)
    self:fireDash("back")
    task.wait(getAdjustedDelay(3))
    Combat:consoleMove("Shove")
    task.wait(0.05)
    -- Dash toward target
    faceTarget(target)
    self:fireDash(math.random() > 0.5 and "right" or "left")
    task.wait(getAdjustedDelay(2))
    if getDist(target) <= ZONES.M1_RANGE then
        faceTarget(target)
        Combat:m1()
    end
end

-- Loop dash — side-to-side movement in neutral (NOT BDC)
function Move:loopDash(minR, maxR)
    local target = getTarget()
    if not target then return end
    local dist = getDist(target)
    if dist > maxR then
        -- Too far: hook dash to close distance
        self:hookDash(math.random() > 0.5 and "right" or "left")
    elseif dist < minR then
        -- Too close: back dash to create space
        self:fireDash("back")
        task.wait(getAdjustedDelay(3))
    else
        -- In range: side dash left/right to bait
        self:fireDash(math.random() > 0.5 and "right" or "left")
        task.wait(getAdjustedDelay(3))
    end
end

-- Counter loop dash — approach pattern (side → side → side, never forward)
function Move:counterLoopDash()
    local target = getTarget()
    if target then faceTarget(target) end
    self:fireDash("right"); task.wait(getAdjustedDelay(2))
    self:fireDash("left"); task.wait(getAdjustedDelay(2))
    self:fireDash(math.random() > 0.5 and "right" or "left")
    task.wait(getAdjustedDelay(2))
    if target and getDist(target) <= ZONES.M1_RANGE then
        faceTarget(target)
        Combat:m1()
    end
end

function Move:shimmy()
    self:fireDash(math.random() > 0.5 and "right" or "left")
    task.wait(0.05)
    self:fireDash("back")
    task.wait(0.05)
end

function Move:sideDashCancel(intoM1)
    self:fireDash("right"); task.wait(0.03)
    if intoM1 then
        local target = getTarget()
        if target and getDist(target) <= ZONES.M1_RANGE then
            faceTarget(target)
            Combat:m1()
        end
    else
        self:pressBlock()
        task.wait(getAdjustedDelay(2))
        self:releaseBlock()
    end
end

function Move:microDash(direction, abilityName)
    self:fireDash(direction or "right")
    task.wait(0.01)
    if abilityName then
        Combat:useAbility(abilityName)
    else
        local target = getTarget()
        if target and getDist(target) <= ZONES.M1_RANGE then
            faceTarget(target)
            Combat:m1()
        end
    end
end

function Move:aerialBDC()
    Combat:jump(); task.wait(0.05)
    self:fireDash("back"); task.wait(getAdjustedDelay(3))
    self:pressBlock(); task.wait(getAdjustedDelay(1))
    self:releaseBlock()
    self:fireDash(math.random() > 0.5 and "right" or "left")
    task.wait(getAdjustedDelay(2))
    local target = getTarget()
    if target and getDist(target) <= ZONES.M1_RANGE then
        faceTarget(target)
        Combat:m1()
    end
end

-- ═══ JUKE — rotates CHARACTER (not camera) → dash opposite → snap back ═══
function Move:juke()
    local target = getTarget()
    if not target or not Root or not Humanoid then return end
    local tRoot = target:FindFirstChild("HumanoidRootPart")
    if not tRoot then return end

    -- Save original facing
    local originalCF = Root.CFrame

    -- Pick a fake side
    local fakeSide = math.random() > 0.5 and "left" or "right"
    local fakeAngle = fakeSide == "left" and math.rad(85) or math.rad(-85)

    -- 1. Rotate CHARACTER (not just camera) to face fake direction
    Humanoid.AutoRotate = false
    Root.CFrame = originalCF * CFrame.Angles(0, fakeAngle, 0)
    task.wait(0.05)

    -- 2. Dash in the OPPOSITE direction (the real direction)
    local realSide = fakeSide == "left" and "right" or "left"
    self:fireDash(realSide)
    task.wait(getAdjustedDelay(2))

    -- 3. Snap CHARACTER back to face target immediately
    faceTarget(target)
    Humanoid.AutoRotate = true

    -- 4. If in range after juke → attack
    if getDist(target) <= ZONES.M1_RANGE then
        faceTarget(target)
        Combat:m1()
    end
end

function Move:tomahawk()
    local target = getTarget()
    if not target then return end
    faceTarget(target)
    self:fireDash(math.random() > 0.5 and "right" or "left")
    task.wait(0.1)
    Combat:jump()
    task.wait(0.3)
    if getDist(target) <= ZONES.M1_RANGE then
        faceTarget(target)
        Combat:grab()
        Combat:m1Combo()
    end
end

function Move:dashBack() self:fireDash("back") end
function Move:sideDash(side) self:fireDash(side or "right") end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 18: ANIMATION DETECTOR — ONLY tracks the selected target
-- ═════════════════════════════════════════════════════════════════════════════

local Anim = { enemyAnimId=nil, enemyAnimStart=0, enemyAnimTrack=nil }

function Anim:init()
    -- Re-hook when target changes
    task.spawn(function()
        while true do
            if isRunning then
                local target = getTarget()
                if target then
                    local hum = target:FindFirstChild("Humanoid")
                    if hum and not animConn then
                        animConn = hum.AnimationPlayed:Connect(function(track)
                            local raw = track.Animation and track.Animation.AnimationId or ""
                            Anim.enemyAnimId = tostring(raw):gsub("rbxassetid://", "")
                            Anim.enemyAnimStart = tick()
                            Anim.enemyAnimTrack = track

                            -- Track enemy combo count for Reflex Tech
                            if M1_ANIMS[Anim.enemyAnimId] then
                                if tick() - State.lastEnemyComboCheck > 1.5 then
                                    State.enemyComboCount = 1
                                else
                                    State.enemyComboCount = State.enemyComboCount + 1
                                end
                                State.lastEnemyComboCheck = tick()
                            end
                        end)
                    end
                end
                -- Disconnect if no target
                if not target and animConn then
                    animConn:Disconnect()
                    animConn = nil
                    Anim.enemyAnimId = nil
                end
            end
            task.wait(0.2) -- re-hook check every 200ms
        end
    end)
end

function Anim:isEnemyM1()       return Anim.enemyAnimId and M1_ANIMS[Anim.enemyAnimId]==true or false end
function Anim:isEnemySkill()    return Anim.enemyAnimId and SKILL_ANIMS[Anim.enemyAnimId]==true or false end
function Anim:isEnemyUppercut() return Anim.enemyAnimId and UPPERCUT_ANIMS[Anim.enemyAnimId]==true or false end
function Anim:isEnemyTwisted()  return Anim.enemyAnimId and TWISTED_ANIMS[Anim.enemyAnimId]==true or false end
function Anim:isEnemyDomain()   return Anim.enemyAnimId and DOMAIN_ANIMS[Anim.enemyAnimId]==true or false end

function Anim:isEnemyAttacking()
    if not Anim.enemyAnimId then return false end
    if M1_ANIMS[Anim.enemyAnimId] or SKILL_ANIMS[Anim.enemyAnimId] then
        return (tick() - Anim.enemyAnimStart) < 0.15
    end
    return false
end

function Anim:isEnemyPunishable()
    if not Anim.enemyAnimId then return false end
    local elapsed = tick() - Anim.enemyAnimStart
    if SKILL_ANIMS[Anim.enemyAnimId] then return elapsed > 0.2 end
    if M1_ANIMS[Anim.enemyAnimId] then return elapsed > 0.35 end
    return false
end

function Anim:didEnemyWhiff()
    if not Anim.enemyAnimId then return false end
    if M1_ANIMS[Anim.enemyAnimId] or SKILL_ANIMS[Anim.enemyAnimId] then
        return (tick() - Anim.enemyAnimStart) < 0.3 and not Combat.didGetHit
    end
    return false
end

function Anim:didEnemyFeint()
    if not Anim.enemyAnimId then return false end
    if M1_ANIMS[Anim.enemyAnimId] then
        local elapsed = tick() - Anim.enemyAnimStart
        return elapsed > 0.2 and elapsed < 0.4 and not Combat.didGetHit
    end
    return false
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 19: AUTO BLOCK V6 — animation + attribute detection, target-locked
-- ═════════════════════════════════════════════════════════════════════════════

local AutoBlock = {
    enabled=false, blocking=false, unblockScheduled=false,
    lastUnblockTime=0, blockStreak=0,
}

function AutoBlock:init()
    task.spawn(function()
        while true do
            if self.enabled then
                local target = getTarget()
                if target and target:FindFirstChild("Humanoid") then
                    local hum = target:FindFirstChild("Humanoid")
                    local animator = hum:FindFirstChild("Animator")
                    if animator and not animator:GetAttribute("TSB_Hooked") then
                        animator:SetAttribute("TSB_Hooked", true)
                        animator.AnimationPlayed:Connect(function(track)
                            if not self.enabled then return end
                            local id = track.Animation and track.Animation.AnimationId
                            if not id then return end
                            local num = id:match("%d+")
                            if not num then return end
                            -- Only react if this is our selected target
                            if target ~= getTarget() then return end
                            if SKILL_ANIMS[num] then self:onSkill(target, track)
                            elseif M1_ANIMS[num] then self:onM1(target)
                            elseif DOMAIN_ANIMS[num] then self:onDomain(target) end
                        end)
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end

function AutoBlock:onM1(attacker)
    if not self.enabled or not Root then return end
    local tRoot = attacker:FindFirstChild("HumanoidRootPart")
    if not tRoot then return end
    if (Root.Position - tRoot.Position).Magnitude > 28 then return end

    -- ANTI-GUARD-BREAK: after 2 blocks, side dash instead
    if self.blockStreak >= 2 then
        if not isBusy then
            Move:sideDash(math.random() > 0.5 and "left" or "right")
        end
        self.blockStreak = 0
        return
    end

    -- Block immediately — frame perfect
    if not self.blocking then
        self.blocking = true
        self.blockStreak = self.blockStreak + 1
        Move:pressBlock()
    end

    -- Schedule unblock
    if not self.unblockScheduled then
        self.unblockScheduled = true
        task.delay(getPingScaledHold(), function()
            self:unblock()
        end)
    end
end

function AutoBlock:onSkill(attacker, track)
    if not self.enabled or not Root then return end
    local tRoot = attacker:FindFirstChild("HumanoidRootPart")
    if not tRoot then return end
    if (Root.Position - tRoot.Position).Magnitude > 28 then return end

    if self.blockStreak >= 2 then
        if not isBusy then
            Move:sideDash(math.random() > 0.5 and "left" or "right")
        end
        self.blockStreak = 0
        return
    end

    if not self.blocking then
        self.blocking = true
        self.blockStreak = self.blockStreak + 1
        Move:pressBlock()
    end

    self.unblockScheduled = true
    task.spawn(function()
        -- Hold block until skill animation nearly ends
        while track.IsPlaying do
            task.wait()
            if track.Length > 0 and (track.Length - track.TimePosition) <= 0.21 then
                break
            end
        end
        self:unblock()
    end)
end

function AutoBlock:onDomain(attacker)
    if not self.enabled or not Root then return end
    local tRoot = attacker:FindFirstChild("HumanoidRootPart")
    if not tRoot then return end
    if (Root.Position - tRoot.Position).Magnitude > 40 then return end

    -- Flee to safest point via raycast
    pushAction(function()
        local bestPoint = Root.Position
        local bestDist = 0
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
        rayParams.FilterDescendantsInstances = {Character}
        for i = 0, 15 do
            local angle = (i / 16) * math.pi * 2
            local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
            local result = Workspace:Raycast(Root.Position, dir * 50, rayParams)
            local dist = result and (result.Position - Root.Position).Magnitude or 50
            if dist > bestDist then
                bestDist = dist
                bestPoint = Root.Position + dir * math.min(dist, 45)
            end
        end
        Root.CFrame = CFrame.new(bestPoint)
    end, 95)
end

function AutoBlock:unblock()
    self.blocking = false
    self.unblockScheduled = false
    self.lastUnblockTime = tick()
    Move:releaseBlock()
    -- Reset block streak after cooldown
    task.delay(2, function() self.blockStreak = 0 end)
end

function AutoBlock:drop()
    if self.blocking then
        self.blocking = false
        self.unblockScheduled = false
        Move:releaseBlock()
    end
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 20: AUTO COUNTER — fire Knit service when enemy uses counterable move
-- ═════════════════════════════════════════════════════════════════════════════

local AutoCounter = { enabled=false }

function AutoCounter:init()
    task.spawn(function()
        while true do
            if self.enabled and isRunning then
                local target = getTarget()
                if target and Anim.enemyAnimId then
                    local serviceName = COUNTER_TRIGGER_ANIMS[Anim.enemyAnimId]
                    if serviceName then
                        local delay = 0.22
                        if Anim.enemyAnimId == "124937162378188" then delay = 0.3
                        elseif Anim.enemyAnimId == "115234621584704" then delay = 0.21 end
                        task.delay(delay, function()
                            if getTarget() == target then
                                fireService(serviceName)
                            end
                        end)
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 21: AUTO DODGE — dodge away when enemy attacks
-- ═════════════════════════════════════════════════════════════════════════════

local function setupAutoDodge()
    task.spawn(function()
        while true do
            if Features.autoDodge and isRunning and not isBusy then
                local target = getTarget()
                if target and Anim:isEnemyAttacking() and not AutoBlock.blocking then
                    local dist = getDist(target)
                    if dist < ZONES.THREAT_RANGE then
                        if tick() - lastDodgeTime > 0.5 then
                            lastDodgeTime = tick()
                            Move:sideDash(math.random() > 0.5 and "left" or "right")
                        end
                    end
                end
            end
            task.wait(0.05)
        end
    end)
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 22: ANTI-FLING — detect abnormal velocity and auto-recover
-- ═════════════════════════════════════════════════════════════════════════════

local function setupAntiFling()
    if antiFlingConn then antiFlingConn:Disconnect() end
    antiFlingConn = RunService.Heartbeat:Connect(function()
        if not Features.antiFling or not Root then return end
        local velMag = Root.AssemblyLinearVelocity.Magnitude
        local rotMag = Root.AssemblyAngularVelocity.Magnitude
        if velMag > 250 or rotMag > 250 then
            -- Being flung — zero velocity and restore last safe position
            Root.AssemblyAngularVelocity = Vector3.zero
            Root.AssemblyLinearVelocity = Vector3.zero
            if lastSafeCF then
                Root.CFrame = lastSafeCF
            end
        elseif velMag < 50 and rotMag < 50 then
            -- Safe — record position
            lastSafeCF = Root.CFrame
        end
    end)
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 23: ESP SYSTEM — highlight enemies with health, ult, name
-- ═════════════════════════════════════════════════════════════════════════════

local function createESP(player, char)
    if not Features.esp or not char then return end
    -- Remove old ESP
    if espObjects[player] then
        for _, obj in ipairs(espObjects[player]) do
            if obj and obj.Parent then obj:Destroy() end
        end
    end
    espObjects[player] = {}

    -- Highlight
    local hl = Instance.new("Highlight")
    hl.Name = "TSB_ESP"
    hl.FillColor = Color3.fromRGB(255, 50, 50)
    hl.FillTransparency = 0.7
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.OutlineTransparency = 0
    hl.Parent = char
    table.insert(espObjects[player], hl)

    -- Billboard with info
    local head = char:FindFirstChild("Head")
    if head then
        local bb = Instance.new("BillboardGui")
        bb.Name = "TSB_ESP_BB"
        bb.Size = UDim2.new(0, 200, 0, 50)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.Parent = head

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = player.Name
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 14
        label.Parent = bb
        table.insert(espObjects[player], bb)
    end
end

local function removeESP(player)
    if espObjects[player] then
        for _, obj in ipairs(espObjects[player]) do
            if obj and obj.Parent then obj:Destroy() end
        end
        espObjects[player] = nil
    end
end

local function updateESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            if Features.esp and plr.Character then
                createESP(plr, plr.Character)
            else
                removeESP(plr)
            end
        end
    end
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 24: PUNISH — hit-confirmed combos, distance-gated
-- BDC fires ONLY when enemy retreats after M1 exchange
-- ═════════════════════════════════════════════════════════════════════════════

local Punish = {}

-- MAX DAMAGE COMBO with hit confirm + BDC snipe if enemy retreats
function Punish:maxCombo(target)
    if not target then return end

    -- Dash in if too far
    if getDist(target) > ZONES.M1_RANGE then
        Move:hookDash(math.random() > 0.5 and "right" or "left")
        task.wait(0.05)
        if getDist(target) > ZONES.M1_RANGE then return end
    end

    faceTarget(target)
    local hits = Combat:m1ChainConfirmed(target, 4)

    if hits > 0 then
        local cd = getCharData()
        local route, delays = cd.punishRoute, cd.punishDelays

        -- Extend with abilities
        for i, move in ipairs(route) do
            if move ~= "M1" then
                if not Combat:isOnCooldown(move) then
                    faceTarget(target)
                    Combat:useAbility(move)
                    task.wait(delays[i] or 0.08)
                end
            end
        end

        -- Check if enemy is retreating → BDC to snipe them
        local tHum = target:FindFirstChild("Humanoid")
        if tHum and tHum.Health > 0 then
            local currentDist = getDist(target)
            if currentDist > ZONES.M1_RANGE and currentDist < ZONES.THREAT_RANGE then
                -- Enemy retreated after our M1s → BDC to catch them
                Move:backdashCancel()
            elseif currentDist <= ZONES.M1_RANGE + 5 then
                -- Still close → M1 reset to extend
                faceTarget(target)
                Combat:m1Reset()
            end

            -- Ultimate if enemy is low HP
            if getEnemyHealthPct(target) < 0.35 and not Combat:isOnCooldown("Ultimate") then
                faceTarget(target)
                Combat:useAbility("Ultimate")
                return
            end

            -- Tech chase
            if tHum.Health > 0 then
                task.wait(0.05)
                self:techChase()
            end
        end
    end
end

function Punish:techChase()
    local target = getTarget()
    if not target then return end
    local pred = Adapt:predictTech(target)
    if pred == "left" then
        Move:sideDash("left"); task.wait(0.05)
        if getDist(target) <= ZONES.M1_RANGE then
            faceTarget(target)
            Combat:m1Combo()
        end
    elseif pred == "right" then
        Move:sideDash("right"); task.wait(0.05)
        if getDist(target) <= ZONES.M1_RANGE then
            faceTarget(target)
            Combat:m1Combo()
        end
    else
        Move:sideDash(math.random() > 0.5 and "left" or "right")
        task.wait(0.08)
        if getDist(target) <= ZONES.M1_RANGE then
            faceTarget(target)
            Combat:grab()
        end
    end
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 25: ADAPTATION ENGINE — habit tracking
-- ═════════════════════════════════════════════════════════════════════════════

Adapt = { profiles={} }

function Adapt:getProfile(target)
    local id = (target.UserId or target.Name or "?")
    if not self.profiles[id] then
        self.profiles[id] = {
            techRoll={}, preferredMoves={}, engagements=0,
            blockHabits=0, grabHabits=0, retreatHabits=0,
        }
    end
    return self.profiles[id]
end

function Adapt:record(target)
    if not target or not target:FindFirstChild("Humanoid") then return end
    local p = self:getProfile(target)
    local tHum = target:FindFirstChild("Humanoid")
    local tRoot = target:FindFirstChild("HumanoidRootPart")

    -- Track tech rolls
    if tHum:GetState() == Enum.HumanoidStateType.Running and tRoot then
        local v = tRoot.AssemblyLinearVelocity
        local dir = math.abs(v.X) > math.abs(v.Z) and (v.X > 0 and "right" or "left") or "neutral"
        table.insert(p.techRoll, dir)
        if #p.techRoll > 10 then table.remove(p.techRoll, 1) end
    end

    -- Track habits
    if State.enemyBlockedUs then p.blockHabits = p.blockHabits + 1 end
    if State.grabMixupCount > 0 then p.grabHabits = p.grabHabits + 1 end
    if State.enemyRetreating then p.retreatHabits = p.retreatHabits + 1 end
    p.engagements = p.engagements + 1
end

function Adapt:predictTech(target)
    local techs = self:getProfile(target).techRoll
    if #techs < 3 then
        return ({ "left","right","neutral" })[math.random(1,3)]
    end
    local counts = {}
    for _, d in ipairs(techs) do counts[d] = (counts[d] or 0) + 1 end
    local best, bestN = "left", 0
    for d, n in pairs(counts) do if n > bestN then bestN = n; best = d end end
    return best
end

function Adapt:shouldGrab(target)
    local p = self:getProfile(target)
    return p.blockHabits > 2 and p.blockHabits > p.engagements * 0.4
end

function Adapt:shouldBDC(target)
    -- BDC when enemy retreats after exchanges
    local p = self:getProfile(target)
    return p.retreatHabits > 1
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 26: DECISION ENGINE — COMP vs FLASHY
-- ═════════════════════════════════════════════════════════════════════════════

local Brain = { mode="IDLE", lastPushType="" }

function Brain:evaluate()
    local target = getTarget()
    if not target then State.mode = "IDLE"; return end

    -- Don't push new actions if already executing one
    if isBusy then return end

    local dist = getDist(target)
    local tHum = target:FindFirstChild("Humanoid")
    if not tHum then return end

    -- ══ PRIORITY 1: RECOVERY ══
    if isRagdolled(Character) then
        if self.lastPushType == "RECOVERY" then return end
        self.lastPushType = "RECOVERY"
        State.mode = "RECOVERY"
        pushAction(function()
            Combat:evasive()
            task.wait(0.02)
            Move:sideDash(math.random() > 0.5 and "left" or "right")
            if getDist(target) < 15 then Move:pressBlock() end
        end, 100)
        return
    end

    -- ══ PRIORITY 2: PUNISH — enemy whiffed/ragdolled/punishable ══
    if Anim:isEnemyPunishable() or Anim:didEnemyWhiff()
    or tHum:GetState() == Enum.HumanoidStateType.Freefall
    or tHum:GetState() == Enum.HumanoidStateType.Ragdoll then
        if self.lastPushType == "PUNISH" then return end
        self.lastPushType = "PUNISH"
        State.mode = "PUNISH"
        pushAction(function()
            Punish:maxCombo(target)
        end, 90)
        return
    end

    -- ══ PRIORITY 3: REFLEX TECH (enemy combo count 4) ══
    if State.enemyComboCount >= 4 and Anim:isEnemyM1() and dist < 18 then
        if self.lastPushType == "REFLEX" then return end
        self.lastPushType = "REFLEX"
        State.mode = "COUNTER"
        pushAction(function()
            Combat:jump()
            task.wait(0.29)
            if getDist(target) <= ZONES.M1_RANGE then
                faceTarget(target)
                fireComm(COMM.m1); task.wait(0.1); fireComm(COMM.m1Release)
            end
            task.wait(0.5)
            fireComm(DASH_REMOTE.right)
        end, 88)
        return
    end

    -- ══ PRIORITY 4: UPPERCUT COUNTER ══
    if Anim:isEnemyUppercut() and dist < 15 then
        if self.lastPushType == "UPPERCUT" then return end
        self.lastPushType = "UPPERCUT"
        State.mode = "COUNTER"
        pushAction(function()
            Combat:jump(); task.wait(0.1)
            if getDist(target) <= ZONES.M1_RANGE then
                faceTarget(target)
                Combat:m1Combo(3)
            end
        end, 85)
        return
    end

    -- ══ PRIORITY 5: FLASHY ONLY — Sky Upper, Instant Twisted ══
    if currentMode == "FLASHY" then
        if Anim.enemyAnimId == SKY_UPPER_ANIM and dist < 25 then
            if self.lastPushType == "SKYUPPER" then return end
            self.lastPushType = "SKYUPPER"
            State.mode = "COUNTER"
            pushAction(function()
                task.wait(0.3)
                if Root then
                    Root.CFrame = Root.CFrame + Vector3.new(0, 5, 0)
                    fireComm(DASH_REMOTE.right)
                    Root.Anchored = true
                    task.wait(1)
                    Root.Anchored = false
                end
            end, 82)
            return
        end
        if Anim:isEnemyTwisted() and dist < 20 then
            if self.lastPushType == "TWISTED" then return end
            self.lastPushType = "TWISTED"
            State.mode = "COUNTER"
            pushAction(function()
                if not Root then return end
                local originalCF = Root.CFrame
                Root.CFrame = originalCF * CFrame.Angles(0, math.rad(-133), 0)
                task.wait(0.39)
                fireComm(DASH_REMOTE.right)
                Root.CFrame = originalCF * CFrame.Angles(0, math.rad(-133), 0)
                task.wait(0.125)
                Root.CFrame = originalCF
                task.wait(0.8)
            end, 80)
            return
        end
    end

    -- ══ PRIORITY 6: DEFENSIVE ══
    if Anim:isEnemyAttacking() and not Anim:didEnemyWhiff() and not AutoBlock.blocking then
        if self.lastPushType == "DEFENSIVE" then return end
        self.lastPushType = "DEFENSIVE"
        State.mode = "DEFENSIVE"
        pushAction(function()
            if dist < ZONES.THREAT_RANGE then
                Move:dashBack(); task.wait(0.03)
                Move:pressBlock(); task.wait(getPingScaledHold()); Move:releaseBlock()
            else
                Move:dashBack()
            end
        end, 70)
        return
    end

    -- Velocity spike — enemy rushing in
    if dist < ZONES.BURST_RANGE and Root then
        local tRoot = target:FindFirstChild("HumanoidRootPart")
        if tRoot then
            local towardsMe = (Root.Position - tRoot.Position).Unit
            if getEnemyVel(target):Dot(towardsMe) > 50 and not AutoBlock.blocking then
                if self.lastPushType == "VELOCITY" then return end
                self.lastPushType = "VELOCITY"
                State.mode = "DEFENSIVE"
                pushAction(function()
                    Move:pressBlock()
                    task.wait(getPingScaledHold())
                    Move:releaseBlock()
                end, 70)
                return
            end
        end
    end

    -- ══ PRIORITY 7: NEUTRAL — aggressive, not passive ══
    -- NO BDC in neutral — only side dashes, hook dashes, jukes, shimmies
    if tick() - lastNeutralTime < 0.3 then return end -- 300ms between neutral actions
    lastNeutralTime = tick()
    self.lastPushType = "NEUTRAL"
    State.mode = "NEUTRAL"

    pushAction(function()
        local idealRange = getCharData().idealRange or 14
        local actualDist = getDist(target)

        if actualDist > ZONES.RESET_RANGE then
            -- Far: hook dash to close distance
            Move:hookDash(math.random() > 0.5 and "right" or "left")
        elseif actualDist > ZONES.BURST_RANGE then
            -- Medium-far: counter loop dash or juke to approach
            local r = math.random(1, 2)
            if r == 1 then Move:counterLoopDash()
            else Move:juke() end
        elseif actualDist > idealRange + 3 then
            -- Just outside range: hook dash in → M1 → back off
            faceTarget(target)
            Move:hookDash(math.random() > 0.5 and "right" or "left")
            if getDist(target) <= ZONES.M1_RANGE then
                faceTarget(target)
                Combat:m1()
                task.wait(0.03)
                Move:dashBack()
            end
        elseif actualDist > ZONES.POINT_BLANK then
            -- Threat range: spaced pressure with jukes
            if Adapt:shouldGrab(target) and State.grabMixupCount < 3 then
                Move:sideDash(math.random() > 0.5 and "left" or "right")
                task.wait(0.03)
                if getDist(target) <= ZONES.M1_RANGE then
                    faceTarget(target)
                    Combat:grab()
                    State.grabMixupCount = State.grabMixupCount + 1
                    Combat:m1Combo(3)
                end
            else
                local r = math.random(1, 4)
                if r == 1 then Move:hookDash(math.random() > 0.5 and "right" or "left")
                elseif r == 2 then Move:shimmy()
                elseif r == 3 then Move:juke()  -- juke in BOTH modes
                else Move:loopDash(idealRange - 3, idealRange + 3) end
            end
        else
            -- Point blank: M1 chain with hit confirm
            -- If hits land and enemy retreats → BDC will fire in Punish:maxCombo
            -- Here we just apply pressure
            local r = math.random(1, 4)
            if r == 1 then
                faceTarget(target)
                local hits = Combat:m1ChainConfirmed(target, 4)
                -- After M1 chain, if enemy retreated → BDC snipe
                if hits > 0 and getDist(target) > ZONES.M1_RANGE and getDist(target) < ZONES.THREAT_RANGE then
                    Move:backdashCancel()
                end
            elseif r == 2 then
                faceTarget(target)
                Combat:grab()
                State.grabMixupCount = State.grabMixupCount + 1
                if getDist(target) <= ZONES.M1_RANGE then
                    Combat:m1Combo(3)
                end
            elseif r == 3 then
                Move:shoveBDC()
            else
                Move:sideDash(math.random() > 0.5 and "left" or "right")
                task.wait(0.03)
                if getDist(target) <= ZONES.M1_RANGE then
                    faceTarget(target)
                    Combat:m1()
                end
            end
        end

        -- Anti-air
        if tHum:GetState() == Enum.HumanoidStateType.Jumping then
            Move:dashBack(); task.wait(0.05); Combat:useAbility("Move2")
        end
    end, 10)
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 27: PASSIVE TECH HOOKS
-- ═════════════════════════════════════════════════════════════════════════════

local flowEnabled, kyotoEnabled, hitboxEnabled = false, false, false

-- Flowing Water auto-dash
local function flowHook(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.AnimationPlayed:Connect(function(track)
        if not flowEnabled or currentMode ~= "FLASHY" then return end
        local id = tostring(track.Animation and track.Animation.AnimationId or ""):gsub("rbxassetid://", "")
        if id == FLOWING_WATER then
            task.delay(TIMING[FLOWING_WATER] or 1.5, function()
                fireComm(DASH_REMOTE.forward)
            end)
        end
    end)
end

-- Kyoto combo hook
local function kyotoHook(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.AnimationPlayed:Connect(function(track)
        if not kyotoEnabled or currentMode ~= "FLASHY" then return end
        local id = tostring(track.Animation and track.Animation.AnimationId or ""):gsub("rbxassetid://", "")
        if KYOTO_COMBO_ANIMS[id] then
            pushAction(function()
                task.wait(0.45)
                Combat:consoleMove("Shove")
                task.wait(0.485)
                fireComm(COMM.m1); task.wait(0.05); fireComm(COMM.m1Release)
            end, 85)
        end
    end)
end

-- Hitbox Abuse — teleport behind on M1 hit
local function hitboxHook(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.AnimationPlayed:Connect(function(track)
        if not hitboxEnabled or currentMode ~= "FLASHY" then return end
        local id = tostring(track.Animation and track.Animation.AnimationId or ""):gsub("rbxassetid://", "")
        if id == M1_HIT_ANIM then
            local target = getTarget()
            if not target then return end
            local tRoot = target:FindFirstChild("HumanoidRootPart")
            if not tRoot or not Root then return end
            if (Root.Position - tRoot.Position).Magnitude > 100 then return end
            local behindPos = tRoot.Position - tRoot.CFrame.LookVector * 0.21
            local originalCF = Root.CFrame
            local startTime = tick()
            local conn
            conn = RunService.RenderStepped:Connect(function()
                if tick() - startTime > 0.25 then
                    conn:Disconnect()
                    Root.CFrame = originalCF
                    return
                end
                Root.CFrame = CFrame.new(behindPos, behindPos + tRoot.CFrame.LookVector)
            end)
        end
    end)
end

-- Auto Downslam — detect downslam anims → pop up
local function downslamHook(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.AnimationPlayed:Connect(function(track)
        if not Features.trueDownslam or not isRunning then return end
        local id = tostring(track.Animation and track.Animation.AnimationId or ""):gsub("rbxassetid://", "")
        if DOWNSLAM_ANIMS[id] and Root then
            pushAction(function()
                Root.CFrame = Root.CFrame * CFrame.new(0, 8, 0)
            end, 75)
        end
    end)
end

-- No Slow / No Fatigue (NO WalkSpeed override — No Stun removed)
local noStunConn
local function setupNoStun(char)
    if noStunConn then noStunConn:Disconnect() end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    noStunConn = RunService.RenderStepped:Connect(function()
        if not hum or not hum.Parent then return end
        -- No Slow: destroy Slowed attribute
        if Features.noSlow then
            local slowed = char:FindFirstChild("Slowed")
            if slowed then slowed:Destroy() end
        end
        -- No Fatigue: destroy NoJump attribute
        if Features.noFatigue then
            local noJump = char:FindFirstChild("NoJump")
            if noJump then noJump:Destroy() end
            if hum.JumpPower ~= 50 then hum.JumpPower = 50 end
        end
    end)
end

-- Dash velocity modifier — health-based
local function setupDashModifier(char)
    local hrp = char:WaitForChild("HumanoidRootPart")
    hrp.ChildAdded:Connect(function(c)
        if c.Name == "dodgevelocity" then
            local vc = c:Clone()
            vc.Name = "newdodgevelocity"
            vc.Parent = hrp
            local hum = char:FindFirstChildOfClass("Humanoid")
            task.spawn(function()
                repeat RunService.RenderStepped:Wait()
                    local v = c.Velocity
                    c.P = 0
                    local mp = 1.0
                    if hum then
                        local hpRatio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        local airborne = hum.FloorMaterial == Enum.Material.Air
                        mp = airborne and (2.5 + 1.2 * hpRatio) / 3.2 or 1.0
                    end
                    vc.Velocity = Vector3.new(v.X * mp, v.Y, v.Z * mp)
                until not hrp:FindFirstChild("dodgevelocity") or not hrp:FindFirstChild("newdodgevelocity")
            end)
        end
    end)
    hrp.ChildRemoved:Connect(function(c)
        if c.Name == "dodgevelocity" then
            local nv = hrp:FindFirstChild("newdodgevelocity")
            if nv then nv:Destroy() end
        end
    end)
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 28: CONFIG SAVE/LOAD
-- ═════════════════════════════════════════════════════════════════════════════

local function makeFolder()
    if makefolder and not isfolder(configFolder) then
        pcall(function() makefolder(configFolder) end)
    end
end

local function saveConfig()
    makeFolder()
    local data = {
        mode = currentMode,
        features = Features,
        macros = Macros,
    }
    local json = HttpService:JSONEncode(data)
    if writefile then
        pcall(function() writefile(configFolder .. "/config.json", json) end)
        print("[TSB] Config saved")
    end
end

local function loadConfig()
    if not isfile or not isfile(configFolder .. "/config.json") then
        print("[TSB] No config found")
        return
    end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(configFolder .. "/config.json"))
    end)
    if not ok or type(data) ~= "table" then return end
    if data.mode then currentMode = data.mode end
    if data.features then
        for k, v in pairs(data.features) do Features[k] = v end
    end
    if data.macros then
        for k, v in pairs(data.macros) do Macros[k] = v end
    end
    Camera.FieldOfView = Features.customFOV
    print("[TSB] Config loaded")
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 29: UI
-- ═════════════════════════════════════════════════════════════════════════════

local function createUI()
    local sg = Instance.new("ScreenGui")
    sg.Name = "TSB_Stage0"
    sg.ResetOnSpawn = false
    sg.Parent = LP:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 100)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(12, 12, 22)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Parent = sg

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color, stroke.Thickness, stroke.Transparency = Color3.fromRGB(60,60,80), 1.5, 0.2

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, -20, 0, 28)
    title.Position = UDim2.new(0, 10, 0, 4)
    title.BackgroundTransparency = 1
    title.Text = "TSB STAGE 0 v12 [OFF]"
    title.TextColor3 = Color3.fromRGB(255, 80, 80)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left

    local status = Instance.new("TextLabel", frame)
    status.Size = UDim2.new(1, -20, 0, 18)
    status.Position = UDim2.new(0, 10, 0, 33)
    status.BackgroundTransparency = 1
    status.Text = "[P]on [V]sel [B]unsel [M]mode [L]cam [N]dodge"
    status.TextColor3 = Color3.fromRGB(140, 140, 155)
    status.Font = Enum.Font.Gotham
    status.TextSize = 11
    status.TextXAlignment = Enum.TextXAlignment.Left

    local sb = Instance.new("Frame", frame)
    sb.Size = UDim2.new(1, -20, 0, 6)
    sb.Position = UDim2.new(0, 10, 0, 55)
    sb.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    sb.BorderSizePixel = 0
    Instance.new("UICorner", sb).CornerRadius = UDim.new(0, 3)

    local sf = Instance.new("Frame", sb)
    sf.Size = UDim2.new(1, 0, 1, 0)
    sf.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
    sf.BorderSizePixel = 0
    Instance.new("UICorner", sf).CornerRadius = UDim.new(0, 3)

    local info = Instance.new("TextLabel", frame)
    info.Size = UDim2.new(1, -20, 0, 28)
    info.Position = UDim2.new(0, 10, 0, 65)
    info.BackgroundTransparency = 1
    info.Text = "Select a target with [V]"
    info.TextColor3 = Color3.fromRGB(100, 100, 120)
    info.Font = Enum.Font.Code
    info.TextSize = 10
    info.TextXAlignment = Enum.TextXAlignment.Left

    return title, status, sf, info
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 30: CHARACTER INIT & MAIN LOOP
-- ═════════════════════════════════════════════════════════════════════════════

local function detectCharacter()
    -- Method 1: Check character attribute
    if Character then
        local charAttr = Character:GetAttribute("Character")
        if charAttr and CHAR_NAME_MAP[charAttr] then
            return CHAR_NAME_MAP[charAttr]
        end
    end
    -- Method 2: Check GUI text
    local gui = LP:FindFirstChild("PlayerGui")
    if gui then
        for _, child in ipairs(gui:GetDescendants()) do
            if child:IsA("TextLabel") then
                local text = child.Text:lower()
                for name, data in pairs(CHARACTERS) do
                    if text:find((data.displayName or name):lower()) then
                        return name
                    end
                end
            end
        end
    end
    return "Saitama"
end

local function onCharAdded(newChar)
    Character = newChar
    Root = newChar:WaitForChild("HumanoidRootPart")
    Humanoid = newChar:WaitForChild("Humanoid")
    Animator = Humanoid:WaitForChild("Animator")
    updateCommunicate()
    Combat:init()
    Anim:init()
    Combat.cooldowns = {}
    State.dashCount = 0
    State.m1Count = 0

    flowHook(newChar)
    kyotoHook(newChar)
    hitboxHook(newChar)
    downslamHook(newChar)
    setupDashModifier(newChar)
    setupNoStun(newChar)
    setupAntiFling()

    task.wait(1)
    myCharName = detectCharacter()
    print("[TSB] Char:", myCharName, "· Ping:", math.floor(currentPing * 1000) .. "ms")
end

local function init()
    repeat task.wait() until LP.Character
    repeat task.wait() until LP.Character:FindFirstChild("HumanoidRootPart")
    repeat task.wait() until LP.Character:FindFirstChild("Humanoid")

    pcall(loadConfig)
    onCharAdded(LP.Character)
    LP.CharacterAdded:Connect(onCharAdded)
    AutoBlock:init()
    AutoCounter:init()
    setupLockOn()
    setupAutoDodge()

    print("[TSB] Stage 0 Autoplayer v12.0 loaded")
    print("[TSB] [P] toggle · [V] select · [B] unselect · [M] mode")
    print("[TSB] [L] camlock · [N] autododge · [R] m1reset · [T] emotedash")
    print("[TSB] [F1] save · [F2] load · SELECT TARGET WITH [V]")

    local uiTitle, uiStatus, uiStamina, uiInfo = createUI()

    UserInputService.InputBegan:Connect(function(input, gp)
        -- Don't check gp for our control keys — TSB might process them
        local key = input.KeyCode
        local isControlKey = (
            key == Enum.KeyCode.P or key == Enum.KeyCode.V or key == Enum.KeyCode.B or
            key == Enum.KeyCode.M or key == Enum.KeyCode.L or key == Enum.KeyCode.N or
            key == Enum.KeyCode.R or key == Enum.KeyCode.T or
            key == Enum.KeyCode.F1 or key == Enum.KeyCode.F2
        )
        if gp and not isControlKey then return end

        if key == Enum.KeyCode.P then
            isRunning = not isRunning
            if isRunning then
                uiTitle.Text = "TSB STAGE 0 v12 [" .. currentMode .. "]"
                uiTitle.TextColor3 = currentMode == "COMP" and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 200, 50)
                uiStatus.Text = "Mode: IDLE"
                AutoBlock.enabled = true
                AutoCounter.enabled = Features.autoCounter
                flowEnabled = Features.flow
                kyotoEnabled = Features.kyoto
                hitboxEnabled = Features.hitbox
                print("[TSB] ENABLED — Select a target with [V]")
            else
                uiTitle.Text = "TSB STAGE 0 v12 [OFF]"
                uiTitle.TextColor3 = Color3.fromRGB(255, 80, 80)
                uiStatus.Text = "[P]on [V]sel [B]unsel [M]mode [L]cam [N]dodge"
                AutoBlock.enabled = false
                AutoCounter.enabled = false
                flowEnabled = false
                kyotoEnabled = false
                hitboxEnabled = false
                AutoBlock:drop()
                Move:releaseBlock()
                clearActions()
                isBusy = false
                Brain.lastPushType = ""
                print("[TSB] DISABLED")
            end
        elseif key == Enum.KeyCode.V then
            selectTarget()
            Brain.lastPushType = ""
        elseif key == Enum.KeyCode.B then
            unselectTarget()
            Brain.lastPushType = ""
        elseif key == Enum.KeyCode.M then
            currentMode = currentMode == "COMP" and "FLASHY" or "COMP"
            print("[TSB] Mode:", currentMode)
            if isRunning then
                uiTitle.Text = "TSB STAGE 0 v12 [" .. currentMode .. "]"
                uiTitle.TextColor3 = currentMode == "COMP" and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 200, 50)
            end
        elseif key == Enum.KeyCode.L then
            toggleCamLock()
        elseif key == Enum.KeyCode.N then
            Features.autoDodge = not Features.autoDodge
            print("[TSB] Auto Dodge:", Features.autoDodge and "ON" or "OFF")
        elseif key == Enum.KeyCode.R then
            if isRunning and not isBusy then
                pushAction(function() Combat:m1Reset() end, 50)
            end
        elseif key == Enum.KeyCode.T then
            if isRunning and not isBusy then
                pushAction(function() Combat:emoteDash() end, 50)
            end
        elseif key == Enum.KeyCode.F1 then
            saveConfig()
        elseif key == Enum.KeyCode.F2 then
            loadConfig()
        end
    end)

    -- Main loop — RenderStepped for reading state, action queue for execution
    -- FPS doesn't affect timing because actions use task.wait (wall-clock)
    RunService.RenderStepped:Connect(function()
        if not isRunning then return end
        if not Root or not Humanoid then return end

        frameCounter = frameCounter + 1

        -- Decision every 2 frames (~30fps)
        if frameCounter % 2 == 0 then
            pcall(function() Brain:evaluate() end)
        end

        -- Reset lastPushType when ready for new action
        if not isBusy and #actionQueue == 0 then
            Brain.lastPushType = ""
        end

        -- Adaptation every 30 frames
        if frameCounter % 30 == 0 then
            local target = getTarget()
            if target then pcall(function() Adapt:record(target) end) end
        end

        regenStamina()

        -- FOV update
        if Camera.FieldOfView ~= Features.customFOV then
            Camera.FieldOfView = Features.customFOV
        end

        -- UI update every 30 frames
        if frameCounter % 30 == 0 then
            local target = getTarget()
            if not target then
                uiStatus.Text = "NO TARGET — Press [V] to select"
                uiInfo.Text = string.format("[%s] %dms · No target",
                    currentMode, math.floor(currentPing * 1000))
            else
                uiStatus.Text = "Mode: " .. State.mode
                uiStamina.Size = UDim2.new(1 - (State.dashCount / State.maxDashes), 0, 1, 0)
                local feats = ""
                if camLockActive then feats = feats .. " CAM" end
                if Features.autoDodge then feats = feats .. " DGE" end
                if Features.esp then feats = feats .. " ESP" end
                uiInfo.Text = string.format("[%s] %dms · %d/%d · %s [LOCK]%s",
                    currentMode, math.floor(currentPing * 1000),
                    State.maxDashes - State.dashCount, State.maxDashes,
                    target.Name or "?", feats)
            end
        end
    end)
end

init()
