--[[
    TSB Stage 0 Autoplayer — Configuration Module
    ─────────────────────────────────────────────
    Contains REAL animation IDs discovered from live TSB sources,
    the Communicate remote patterns, zone definitions, character
    spacing tables, wall combo routes, and cooldown data.
]]

local Config = {}

-- ════════════════════════════════════════════════════════════════════
--  ZONE DEFINITIONS (stud distance from opponent)
-- ════════════════════════════════════════════════════════════════════

Config.ZONES = {
    POINT_BLANK  = 5,    -- Zone 1: Punish zone — M1 chains, grab counters
    THREAT_RANGE = 14,   -- Zone 2: Bait zone — BDC, hook dash, whiff punish
    BURST_RANGE  = 25,   -- Zone 3: Watch zone — velocity spike detection, pre-block
    RESET_RANGE  = 50,   -- Zone 4: Reset zone — stamina regen, approach setup
}

Config.VELOCITY_SPIKE_THRESHOLD = 50
Config.DECISION_INTERVAL = 2
Config.ADAPTATION_INTERVAL = 10
Config.FRAME_TIME = 1 / 60

-- ════════════════════════════════════════════════════════════════════
--  REAL ANIMATION IDs — discovered from live TSB sources
--  These are universal across all characters (not per-character)
-- ════════════════════════════════════════════════════════════════════

-- M1 attack animations (all characters, 4-hit chain variants)
Config.M1_ANIMS = {
    ["10469493270"] = true,
    ["10469630950"] = true,
    ["10469639222"] = true,
    ["10469643643"] = true,
    ["13532562418"] = true,
    ["13532600125"] = true,
    ["13532604085"] = true,
    ["13294471966"] = true,
    ["13491635433"] = true,
    ["13296577783"] = true,
    ["13295919399"] = true,
    ["13295936866"] = true,
    ["13370310513"] = true,
    ["13390230973"] = true,
    ["13378751717"] = true,
    ["13378708199"] = true,
    ["14004222985"] = true,
    ["13997092940"] = true,
    ["14001963401"] = true,
    ["14136436157"] = true,
    ["15271263467"] = true,
    ["15240216931"] = true,
    ["15240176873"] = true,
    ["15162694192"] = true,
    ["16515503507"] = true,
    ["16515520431"] = true,
    ["16515448089"] = true,
    ["16552234590"] = true,
    ["17889458563"] = true,
    ["17889461810"] = true,
    ["17889471098"] = true,
    ["17889290569"] = true,
    ["123005629431309"] = true,
    ["100059874351664"] = true,
    ["104895379416342"] = true,
    ["134775406437626"] = true,
    ["15259161390"] = true,
}

-- Sidedash animations (dash left/right)
Config.SIDEDASH_ANIMS = {
    ["10480793962"] = true,
    ["10480796021"] = true,
    ["10479335397"] = true,
    ["13380255751"] = true,
}

-- Hold-until-end animations (skills/ultimates with long active frames)
Config.SKILL_ANIMS = {
    ["10468665991"] = true,
    ["10466974800"] = true,
    ["10471336737"] = true,
    ["12510170988"] = true,
    ["12272894215"] = true,
    ["12296882427"] = true,
    ["12307656616"] = true,
    ["101588604872680"] = true,
    ["105442749844047"] = true,
    ["109617620932970"] = true,
    ["131820095363270"] = true,
    ["135289891173395"] = true,
    ["125955606488863"] = true,
    ["12534735382"] = true,
    ["12502664044"] = true,
    ["12509505723"] = true,
    ["12618271998"] = true,
    ["12684390285"] = true,
    ["13376869471"] = true,
    ["13294790250"] = true,
    ["13376962659"] = true,
    ["13501296372"] = true,
    ["13556985475"] = true,
    ["145162735010"] = true,
    ["14046756619"] = true,
    ["14299135500"] = true,
    ["14351441234"] = true,
    ["15290930205"] = true,
    ["15145462680"] = true,
    ["15295895753"] = true,
    ["15295336270"] = true,
    ["16139108718"] = true,
    ["16515850153"] = true,
    ["16431491215"] = true,
    ["16597322398"] = true,
    ["16597912086"] = true,
    ["17799224866"] = true,
    ["17838006839"] = true,
    ["17857788598"] = true,
    ["18179181663"] = true,
    ["113166426814229"] = true,
    ["116753755471636"] = true,
    ["116153572280464"] = true,
    ["114095570398448"] = true,
    ["77509627104305"] = true,
    ["71852503410610"] = true,
    ["91353107056596"] = true,
}

-- Uppercut animations (one per character — used for auto-counter)
Config.UPPERCUT_ANIMS = {
    ["13532604085"] = true,
    ["10469639222"] = true,
    ["13295919399"] = true,
    ["13378751717"] = true,
    ["14001963401"] = true,
    ["15240176873"] = true,
    ["16515448089"] = true,
    ["17889471098"] = true,
}

-- Additional trigger animations (from skibidi tech)
Config.TRIGGER_ANIMS = {
    ["10503381238"] = true,
    ["13379003796"] = true,
}

-- Flowing Water animation (auto-dash after 1.57s delay)
Config.FLOWING_WATER_ANIM = "12273188754"
Config.FLOWING_WATER_DASH_DELAY = 1.57

-- M1 hit animation (for hitbox abuse trigger)
Config.M1_HIT_ANIM = "10469493270"

-- ════════════════════════════════════════════════════════════════════
--  COMMUNICATE REMOTE PATTERNS — the real TSB input system
--  character:FindFirstChild("Communicate"):FireServer(table)
-- ════════════════════════════════════════════════════════════════════

Config.Communicate = {
    -- Block (key = F)
    pressBlock    = { Goal = "KeyPress",   Key = Enum.KeyCode.F },
    releaseBlock  = { Goal = "KeyRelease", Key = Enum.KeyCode.F },

    -- M1 (left click)
    m1            = { Goal = "LeftClick",        Mobile = true },
    m1Release     = { Goal = "LeftClickRelease", Mobile = true },

    -- Jump
    jump          = { Goal = "KeyPress", Key = Enum.KeyCode.Space },

    -- Dash (direction + Q modifier)
    dashForward   = { Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress" },
    dashBackward  = { Dash = Enum.KeyCode.S, Key = Enum.KeyCode.Q, Goal = "KeyPress" },
    dashLeft      = { Dash = Enum.KeyCode.A, Key = Enum.KeyCode.Q, Goal = "KeyPress" },
    dashRight     = { Dash = Enum.KeyCode.D, Key = Enum.KeyCode.Q, Goal = "KeyPress" },

    -- Emote
    emoteCrush    = { Goal = "Emote", Emote = "Crush" },

    -- Delete body velocity (for stick/skid tech)
    -- deleteBV = { Goal = "delete bv", BV = bodyVelocityInstance },

    -- Console Move (fire a tool/ability)
    -- consoleMove = { Tool = toolInstance, Goal = "Console Move" },
}

-- ════════════════════════════════════════════════════════════════════
--  KEYBINDS — TSB actual controls
-- ════════════════════════════════════════════════════════════════════

Config.Keybinds = {
    M1         = "MouseButton1",
    Block      = "F",      -- TSB block key is F (NOT Q!)
    Dash       = "Q",      -- Q is the dash modifier key
    Jump       = "Space",
    Grab       = "G",
    Evasive    = "LeftControl",
    Move1      = "One",
    Move2      = "Two",
    Move3      = "Three",
    Move4      = "Four",
    Ultimate   = "Five",
}

Config.ToggleKey = "P"

-- ════════════════════════════════════════════════════════════════════
--  AUTO BLOCK SETTINGS (from ByteHub Auto Block V6)
-- ════════════════════════════════════════════════════════════════════

Config.AutoBlock = {
    Enabled          = false,
    DetectionRange   = 28,    -- studs for M1 detection
    SidedashRange    = 40,    -- studs for sidedash detection
    BaseHold         = 0.25,  -- base block hold time in seconds
    ReblockDelay     = 0,     -- delay between blocks
    -- Dash modifier (health-based dash speed)
    GroundFullHP     = 3.2,
    GroundMinHP      = 3.2,
    AirFullHP        = 3.7,
    AirMinHP         = 2.5,
    NaturalFullHP    = 3.2,
    NaturalMinHP     = 3.2,
}

-- ════════════════════════════════════════════════════════════════════
--  PING COMPENSATION
-- ════════════════════════════════════════════════════════════════════

function Config.getPing()
    local lp = game:GetService("Players").LocalPlayer
    -- Method 1: GetNetworkPing (returns seconds)
    local ok, ping = pcall(function()
        if lp.GetNetworkPing then return lp:GetNetworkPing() end
        return nil
    end)
    if ok and ping then return ping end

    -- Method 2: Stats (returns ms)
    local ok2, val = pcall(function()
        return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if ok2 and val then return val / 1000 end

    return 0.05  -- fallback 50ms
end

function Config.getAdjustedDelay(frames)
    local ping = Config.getPing()
    local raw = frames * Config.FRAME_TIME
    return math.max(raw - ping + 0.02, 0.01)
end

-- Ping-scaled block hold time
function Config.getPingScaledHold()
    local ping = Config.getPing() * 1000  -- convert to ms
    local pingRatio = math.clamp((ping - 30) / (200 - 30), 0, 1)
    return Config.AutoBlock.BaseHold + pingRatio * 0.08
end

-- ════════════════════════════════════════════════════════════════════
--  ABILITY KEY MAP
-- ════════════════════════════════════════════════════════════════════

Config.AbilityKeyMap = {
    Move1     = Enum.KeyCode.One,
    Move2     = Enum.KeyCode.Two,
    Move3     = Enum.KeyCode.Three,
    Move4     = Enum.KeyCode.Four,
    Ultimate  = Enum.KeyCode.Five,
    Evasive   = Enum.KeyCode.LeftControl,
    Grab      = Enum.KeyCode.G,
    Block     = Enum.KeyCode.F,
    Dash      = Enum.KeyCode.Q,
}

Config.DashKeyMap = {
    forward = Enum.KeyCode.W,
    back    = Enum.KeyCode.S,
    left    = Enum.KeyCode.A,
    right   = Enum.KeyCode.D,
}

-- Dash remote patterns (for Communicate FireServer)
Config.DashRemoteMap = {
    forward = { Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress" },
    back    = { Dash = Enum.KeyCode.S, Key = Enum.KeyCode.Q, Goal = "KeyPress" },
    left    = { Dash = Enum.KeyCode.A, Key = Enum.KeyCode.Q, Goal = "KeyPress" },
    right   = { Dash = Enum.KeyCode.D, Key = Enum.KeyCode.Q, Goal = "KeyPress" },
}

-- ════════════════════════════════════════════════════════════════════
--  CHARACTER DATABASE
--  Ideal spacing and combo routes per character.
--  Animation IDs are universal (not per-character) — see above.
-- ════════════════════════════════════════════════════════════════════

Config.Characters = {
    Saitama = {
        displayName = "Saitama",
        idealRange  = 12,
        cooldowns   = { Move1 = 8, Move2 = 6, Move3 = 10, Move4 = 12, Ultimate = 40 },
        wallCombo   = {
            initiator = { m1s = 3, dash = "forward", delay = 0.05 },
            string    = { "Move1", "Move3", "Move4", "Ultimate" },
            delays    = { 0.1, 0.05, 0.08, 0.2 },
        },
        punishRoute  = { "M1", "M1", "M1", "Move1", "Move3" },
        punishDelays = { 0.05, 0.05, 0.08, 0.08, 0.08 },
    },
    Garou = {
        displayName = "Garou",
        idealRange  = 15,
        cooldowns   = { Move1 = 9, Move2 = 7, Move3 = 10, Move4 = 8, Ultimate = 35 },
        wallCombo   = {
            initiator = { m1s = 3, dash = "forward", delay = 0.05 },
            string    = { "Move1", "Move2", "Move3" },
            delays    = { 0.08, 0.1, 0.15 },
        },
        punishRoute  = { "M1", "M1", "M1", "Move1", "Move2" },
        punishDelays = { 0.05, 0.05, 0.08, 0.1, 0.1 },
    },
    Sonic = {
        displayName = "Sonic",
        idealRange  = 18,
        cooldowns   = { Move1 = 6, Move2 = 8, Move3 = 5, Move4 = 10, Ultimate = 30 },
        wallCombo   = {
            initiator = { m1s = 4, dash = "side", delay = 0.03 },
            string    = { "Move3", "Move1", "Move4" },
            delays    = { 0.05, 0.08, 0.1 },
        },
        punishRoute  = { "M1", "M1", "M1", "M1", "Move3", "Move1" },
        punishDelays = { 0.05, 0.05, 0.05, 0.08, 0.05, 0.08 },
    },
    MetalBat = {
        displayName = "Metal Bat",
        idealRange  = 10,
        cooldowns   = { Move1 = 10, Move2 = 8, Move3 = 12, Move4 = 14, Ultimate = 40 },
        wallCombo   = {
            initiator = { m1s = 3, dash = "forward", delay = 0.1 },
            string    = { "Move1", "Move3", "Move4", "Ultimate" },
            delays    = { 0.12, 0.1, 0.15, 0.2 },
        },
        punishRoute  = { "M1", "M1", "M1", "Move1", "Move3" },
        punishDelays = { 0.08, 0.08, 0.1, 0.12, 0.12 },
    },
    Atomic = {
        displayName = "Atomic Samurai",
        idealRange  = 14,
        cooldowns   = { Move1 = 5, Move2 = 8, Move3 = 10, Move4 = 12, Ultimate = 45 },
        wallCombo   = {
            initiator = { m1s = 4, dash = "forward", delay = 0.05 },
            string    = { "Move1", "Move2", "Move3", "Move4", "Ultimate" },
            delays    = { 0.05, 0.08, 0.1, 0.12, 0.3 },
        },
        punishRoute  = { "M1", "M1", "M1", "M1", "Move1", "Move2" },
        punishDelays = { 0.05, 0.05, 0.05, 0.08, 0.05, 0.08 },
    },
    Tatsumaki = {
        displayName = "Tatsumaki",
        idealRange  = 22,
        cooldowns   = { Move1 = 7, Move2 = 8, Move3 = 12, Move4 = 15, Ultimate = 35 },
        wallCombo   = {
            initiator = { m1s = 3, dash = "back", delay = 0.05 },
            string    = { "Move2", "Move3", "Move4", "Ultimate" },
            delays    = { 0.1, 0.1, 0.15, 0.2 },
        },
        punishRoute  = { "M1", "M1", "M1", "Move2", "Move1" },
        punishDelays = { 0.05, 0.05, 0.08, 0.1, 0.08 },
    },
    Suiryu = {
        displayName = "Suiryu",
        idealRange  = 13,
        cooldowns   = { Move1 = 7, Move2 = 8, Move3 = 10, Move4 = 12, Ultimate = 35 },
        wallCombo   = {
            initiator = { m1s = 4, dash = "forward", delay = 0.05 },
            string    = { "Move1", "Move2", "Move3", "Move4" },
            delays    = { 0.08, 0.1, 0.08, 0.12 },
        },
        punishRoute  = { "M1", "M1", "M1", "M1", "Move1", "Move2" },
        punishDelays = { 0.05, 0.05, 0.05, 0.08, 0.08, 0.1 },
    },
    Genos = {
        displayName = "Genos",
        idealRange  = 16,
        cooldowns   = { Move1 = 7, Move2 = 8, Move3 = 10, Move4 = 12, Ultimate = 35 },
        wallCombo   = {
            initiator = { m1s = 3, dash = "forward", delay = 0.05 },
            string    = { "Move1", "Move2", "Move3", "Move4" },
            delays    = { 0.08, 0.1, 0.08, 0.12 },
        },
        punishRoute  = { "M1", "M1", "M1", "Move1", "Move3" },
        punishDelays = { 0.05, 0.05, 0.08, 0.08, 0.1 },
    },
}

return Config
