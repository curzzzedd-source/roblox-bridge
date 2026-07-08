--[[
══════════════════════════════════════════════════════════════════════════════
    TSB STAGE 0 AUTOPLAYER — THE STRONGEST BATTLEGROUNDS
    ══════════════════════════════════════════════════════════════════════════════

    Built on REAL TSB mechanics extracted from live sources:
      • Communicate remote system (FireServer) for all inputs
      • Real animation IDs (37 M1, 4 sidedash, 50+ skill, 8 uppercut)
      • Real isRagdolled() and getClosestTarget() implementations
      • Dash velocity modifier via dodgevelocity child
      • Ping-scaled block timing via Stats.Network

    4-PHASE ARCHITECTURE:
      Phase 1 — Mechanical Core (Communicate remote, BDC, Hook Dash)
      Phase 2 — Reactive Defense (Auto Block via animation tracking)
      Phase 3 — Perfect Punishes & Combo Branching
      Phase 4 — Adaptation Loop (Counter-Habits)

    TOGGLE:  Press [P] to enable/disable
═════════════════════════════════════════════════════════════════════════════
]]

-- ════════════════════════════════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════════════════════════════════

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local Stats            = game:GetService("Stats")

local LP = Players.LocalPlayer
local cloneref = cloneref or clonereference or function(inst) return inst end

-- ════════════════════════════════════════════════════════════════════
--  CONFIG LOADING
-- ════════════════════════════════════════════════════════════════════

local Config

local ok, cfg = pcall(function()
    local content = readfile and readfile("tsb_config.lua")
    if not content then return nil end
    local fn = loadstring(content)
    if fn then
        local _, result = pcall(fn)
        return result
    end
    return nil
end)

if ok and cfg and type(cfg) == "table" then
    Config = cfg
else
    error("[TSB] Failed to load tsb_config.lua — make sure it's in your executor's workspace folder")
    return
end

-- ════════════════════════════════════════════════════════════════════
--  GLOBAL STATE
-- ════════════════════════════════════════════════════════════════════

local Character, Root, Humanoid
local isRunning = false
local myCharName = "Unknown"
local frameCounter = 0
local currentPing = 0.05

-- ════════════════════════════════════════════════════════════════════
--  REAL HELPERS — from ByteHub source
-- ════════════════════════════════════════════════════════════════════

-- Real isRagdolled implementation from ByteHub
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

-- Real getClosestTarget from ByteHub — includes dummies
local function getClosestTarget()
    local char = LP.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local closest, bestScore = nil, math.huge

    local function checkModel(model)
        if model == char then return end
        local tRoot = model:FindFirstChild("HumanoidRootPart")
        local hum = model:FindFirstChild("Humanoid")
        if not (tRoot and hum and hum.Health > 0) then return end
        local dist = (root.Position - tRoot.Position).Magnitude
        if dist > 50 then return end  -- LOCK_RANGE
        if dist < bestScore then
            bestScore = dist
            closest = model
        end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            checkModel(plr.Character)
        end
    end

    -- Check for dummies in workspace.Live
    if not closest then
        local possibleContainers = { Workspace:FindFirstChild("Live"), Workspace }
        for _, container in ipairs(possibleContainers) do
            if container then
                for _, child in ipairs(container:GetChildren()) do
                    if child:IsA("Model") and (child.Name:lower():find("dummy") or child.Name == "Weakest Dummy") then
                        checkModel(child)
                    end
                end
            end
        end
    end
    return closest
end

local function getDistance(target)
    if not target then return math.huge end
    local tRoot = target:FindFirstChild("HumanoidRootPart")
    if not tRoot or not Root then return math.huge end
    return (Root.Position - tRoot.Position).Magnitude
end

local function getEnemyVelocity(target)
    if not target then return Vector3.zero end
    local tRoot = target:FindFirstChild("HumanoidRootPart")
    if not tRoot then return Vector3.zero end
    return tRoot.AssemblyLinearVelocity
end

-- Real ping tracking from ByteHub
task.spawn(function()
    while true do
        local ok, val = pcall(function()
            return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        if ok and val then
            currentPing = val / 1000  -- convert ms to seconds
        else
            local p = LP.GetNetworkPing and LP:GetNetworkPing()
            if p then currentPing = p end
        end
        task.wait(2)
    end
end)

-- Check if an animation ID matches a known set
local function animIdMatches(animId, animSet)
    if not animId then return false end
    local numId = tostring(animId):gsub("rbxassetid://", "")
    return animSet[numId] == true
end

-- Check if animation is running on a character
local function isAnimationRunning(char, animId)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    for _, track in pairs(hum:GetPlayingAnimationTracks()) do
        if track.Animation and track.Animation.AnimationId then
            local id = track.Animation.AnimationId:gsub("rbxassetid://", "")
            if id == tostring(animId) then
                return track
            end
        end
    end
    return nil
end

-- Detect our character from GUI or animation matching
local function detectMyCharacter()
    local gui = LP:FindFirstChild("PlayerGui")
    if gui then
        for _, child in ipairs(gui:GetDescendants()) do
            if child:IsA("TextLabel") then
                local text = child.Text:lower()
                for name, data in pairs(Config.Characters) do
                    if text:find(data.displayName:lower()) then
                        return name
                    end
                end
            end
        end
    end
    return "Saitama"
end

local function getCharData(name)
    return Config.Characters[name] or Config.Characters["Saitama"]
end

-- ════════════════════════════════════════════════════════════════════
--  COMMUNICATE REMOTE — the real TSB input system
--  All inputs go through character.Communicate:FireServer(table)
-- ════════════════════════════════════════════════════════════════════

local Comm = {}

-- Get the Communicate remote on our character
function Comm:getRemote()
    if not Character then return nil end
    return cloneref(Character:FindFirstChild("Communicate"))
end

-- Fire a Communicate request
function Comm:fire(data)
    local remote = self:getRemote()
    if not remote then return false end
    local ok, err = pcall(function()
        remote:FireServer(unpack({ data }))
    end)
    return ok
end

-- ════════════════════════════════════════════════════════════════════
--  MODULE 1 — COMBAT CONTROLLER
--  Uses the real Communicate remote for all attacks and abilities.
-- ════════════════════════════════════════════════════════════════════

local CombatController = {}
CombatController.consecutiveHits = 0
CombatController.didGetHit       = false
CombatController.lastHealth      = 100
CombatController.cooldowns       = {}

function CombatController:init()
    if not Humanoid then return end
    self.lastHealth = Humanoid.Health
    Humanoid.HealthChanged:Connect(function(newHealth)
        if newHealth < self.lastHealth then
            self.didGetHit = true
        elseif newHealth > self.lastHealth then
            self.didGetHit = false
        end
        self.lastHealth = newHealth
    end)
end

-- M1 via Communicate remote (LeftClick)
function CombatController:m1()
    Comm:fire(Config.Communicate.m1)
    task.wait(0.01)
    Comm:fire(Config.Communicate.m1Release)
    self.consecutiveHits = self.consecutiveHits + 1
end

function CombatController:m1Combo(count)
    count = count or 4
    for i = 1, count do
        self:m1()
        local delay = 0.05
        if i <= 2 then delay = 0.05
        elseif i == 3 then delay = 0.08
        else delay = 0.1 end
        task.wait(delay)
    end
end

-- Abilities via VirtualInput (key press for ability slots)
function CombatController:useAbility(abilityName)
    local key = Config.AbilityKeyMap[abilityName]
    if not key then return false end

    if self.cooldowns[abilityName] and tick() < self.cooldowns[abilityName] then
        return false
    end

    local vim = game:GetService("VirtualInputManager")
    vim:SendKeyEvent(true, key, false, game)
    task.wait(0.02)
    vim:SendKeyEvent(false, key, false, game)

    self.consecutiveHits = self.consecutiveHits + 1

    local charData = getCharData(myCharName)
    if charData.cooldowns and charData.cooldowns[abilityName] then
        self.cooldowns[abilityName] = tick() + charData.cooldowns[abilityName]
    end
    return true
end

function CombatController:useUltimate()
    return self:useAbility("Ultimate")
end

-- Grab via Communicate (G key)
function CombatController:grab()
    local key = Config.AbilityKeyMap.Grab
    local vim = game:GetService("VirtualInputManager")
    vim:SendKeyEvent(true, key, false, game)
    task.wait(0.02)
    vim:SendKeyEvent(false, key, false, game)
end

-- Evasive via key press
function CombatController:evasive()
    local key = Config.AbilityKeyMap.Evasive
    local vim = game:GetService("VirtualInputManager")
    vim:SendKeyEvent(true, key, false, game)
    task.wait(0.02)
    vim:SendKeyEvent(false, key, false, game)
end

-- Jump via Communicate
function CombatController:jump()
    Comm:fire(Config.Communicate.jump)
end

function CombatController:isOnCooldown(abilityName)
    return self.cooldowns[abilityName] and tick() < self.cooldowns[abilityName] or false
end

function CombatController:resetCooldowns()
    self.cooldowns = {}
end

-- ════════════════════════════════════════════════════════════════════
--  MODULE 2 — MOVEMENT CONTROLLER
--  Uses Communicate remote for dashes (Q + direction).
--  Includes BDC, Hook Dash, Loop Dash, and auto spacing.
-- ════════════════════════════════════════════════════════════════════

local Movement = {}
Movement.isDashing     = false
Movement.lastDashTime  = 0
Movement.dashCooldown  = 0.3
Movement.stamina       = 100
Movement.isBlocking     = false

-- Fire dash via Communicate remote
function Movement:fireDashRemote(direction)
    local dashData = Config.DashRemoteMap[direction] or Config.DashRemoteMap.forward
    Comm:fire(dashData)
    self.isDashing = true
    self.lastDashTime = tick()
end

-- BACKDASH CANCEL — backdash → block cancel → release → buffer punish
function Movement:backdashCancel()
    self:fireDashRemote("back")
    task.wait(Config.getAdjustedDelay(3))

    self:pressBlock()
    task.wait(Config.getAdjustedDelay(1))

    self:releaseBlock()
    self.isDashing = false

    -- Buffer forward dash + M1 for punish
    self:fireDashRemote("forward")
    task.wait(Config.getAdjustedDelay(2))
    CombatController:m1()
end

-- HOOK DASH — side dash → snap camera → maintain momentum → buffer M1
function Movement:hookDash(direction)
    direction = direction or "right"
    self:fireDashRemote(direction)
    task.wait(Config.getAdjustedDelay(3))

    -- Snap camera toward/away from target
    local target = getClosestTarget()
    if target then
        local tRoot = target:FindFirstChild("HumanoidRootPart")
        if tRoot and Root then
            local lookDir = (tRoot.Position - Root.Position).Unit
            local angle = (direction == "right") and math.rad(90) or math.rad(-90)
            if direction == "forward" then angle = math.rad(180) end
            local cosA, sinA = math.cos(angle), math.sin(angle)
            local newLook = Vector3.new(
                lookDir.X * cosA - lookDir.Z * sinA,
                lookDir.Y,
                lookDir.X * sinA + lookDir.Z * cosA
            )
            local cam = Workspace.CurrentCamera
            if cam then
                cam.CFrame = CFrame.lookAt(Root.Position, Root.Position + newLook)
            end
        end
    end

    task.wait(Config.getAdjustedDelay(2))
    CombatController:m1()
end

-- LOOP DASH — oscillate forward/back to bait
function Movement:loopDash(minRange, maxRange)
    local target = getClosestTarget()
    if not target then return end
    local dist = getDistance(target)

    if dist > maxRange then
        self:hookDash("right")
    elseif dist < minRange then
        self:backdashCancel()
        task.wait(Config.getAdjustedDelay(3))
        self:hookDash("forward")
    else
        self:fireDashRemote("forward")
        task.wait(Config.getAdjustedDelay(3))
        self:fireDashRemote("back")
        task.wait(Config.getAdjustedDelay(3))
    end
end

-- COUNTER LOOP DASH — forward → side → forward
function Movement:counterLoopDash()
    self:fireDashRemote("forward")
    task.wait(Config.getAdjustedDelay(2))
    self:fireDashRemote("right")
    task.wait(Config.getAdjustedDelay(2))
    self:fireDashRemote("forward")
    task.wait(Config.getAdjustedDelay(2))
    CombatController:m1()
end

-- AUTO SPACING — maintain ideal distance per character
function Movement:maintainIdealSpacing(target)
    local dist = getDistance(target)
    local charData = getCharData(myCharName)
    local ideal = charData.idealRange or 14

    if dist > ideal + 5 then
        self:hookDash("forward")
    elseif dist < ideal - 5 then
        self:backdashCancel()
    else
        self:loopDash(ideal - 3, ideal + 3)
    end
end

-- BLOCK via Communicate remote (F key)
function Movement:pressBlock()
    if self.isBlocking then return end
    Comm:fire(Config.Communicate.pressBlock)
    self.isBlocking = true
end

function Movement:releaseBlock()
    if not self.isBlocking then return end
    Comm:fire(Config.Communicate.releaseBlock)
    self.isBlocking = false
end

function Movement:jump()
    CombatController:jump()
end

function Movement:dashForward()
    self:fireDashRemote("forward")
end

function Movement:dashBack()
    self:fireDashRemote("back")
end

function Movement:sideDash(side)
    self:fireDashRemote(side or "right")
end

-- ════════════════════════════════════════════════════════════════════
--  MODULE 3 — ANIMATION DETECTOR
--  Uses REAL animation IDs to detect enemy M1s, skills, dashes,
--  and punishable windows.
-- ════════════════════════════════════════════════════════════════════

local AnimDetector = {}
AnimDetector.enemyCurrentAnim   = nil
AnimDetector.enemyLastAnim       = nil
AnimDetector.enemyAnimStartTime  = 0
AnimDetector.enemyAnimId         = nil
AnimDetector.myCurrentAnim       = nil

function AnimDetector:init()
    if Humanoid then
        Humanoid.AnimationPlayed:Connect(function(animTrack)
            self.myCurrentAnim = animTrack.Animation and animTrack.Animation.AnimationId or nil
        end)
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            self:hookPlayer(player)
        end
    end

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            self:hookPlayer(player)
        end)
    end)
end

function AnimDetector:hookPlayer(player)
    if not player.Character then return end
    local hum = player.Character:FindFirstChild("Humanoid")
    if not hum then return end

    hum.AnimationPlayed:Connect(function(animTrack)
        self.enemyLastAnim = self.enemyCurrentAnim
        self.enemyCurrentAnim = animTrack.Animation and animTrack.Animation.AnimationId or nil
        self.enemyAnimStartTime = tick()

        local rawId = self.enemyCurrentAnim or ""
        self.enemyAnimId = tostring(rawId):gsub("rbxassetid://", "")
    end)
end

-- Is enemy playing an M1 animation?
function AnimDetector:isEnemyM1()
    return self.enemyAnimId and Config.M1_ANIMS[self.enemyAnimId] == true or false
end

-- Is enemy playing a skill/ultimate animation?
function AnimDetector:isEnemyUsingSkill()
    return self.enemyAnimId and Config.SKILL_ANIMS[self.enemyAnimId] == true or false
end

-- Is enemy playing a sidedash animation?
function AnimDetector:isEnemySidedashing()
    return self.enemyAnimId and Config.SIDEDASH_ANIMS[self.enemyAnimId] == true or false
end

-- Is enemy uppercutting? (we can counter with jump)
function AnimDetector:isEnemyUppercutting()
    return self.enemyAnimId and Config.UPPERCUT_ANIMS[self.enemyAnimId] == true or false
end

-- Is enemy in endlag/punishable? (skill animation near end)
function AnimDetector:isEnemyPunishable()
    if not self.enemyAnimId then return false end
    if Config.SKILL_ANIMS[self.enemyAnimId] then
        local elapsed = tick() - self.enemyAnimStartTime
        -- Skills are punishable after ~0.2s before end
        return elapsed > 0.3
    end
    -- M1s are punishable after the chain ends
    if Config.M1_ANIMS[self.enemyAnimId] then
        local elapsed = tick() - self.enemyAnimStartTime
        return elapsed > 0.4
    end
    return false
end

-- Is enemy attacking? (startup frames)
function AnimDetector:isEnemyAttacking()
    if not self.enemyAnimId then return false end
    if Config.M1_ANIMS[self.enemyAnimId] or Config.SKILL_ANIMS[self.enemyAnimId] then
        local elapsed = tick() - self.enemyAnimStartTime
        return elapsed < 0.15
    end
    return false
end

-- Did enemy whiff? (attacked but didn't hit us)
function AnimDetector:didEnemyWhiff()
    if not self.enemyAnimId then return false end
    if Config.M1_ANIMS[self.enemyAnimId] or Config.SKILL_ANIMS[self.enemyAnimId] then
        local elapsed = tick() - self.enemyAnimStartTime
        return elapsed < 0.3 and not CombatController.didGetHit
    end
    return false
end

-- ════════════════════════════════════════════════════════════════════
--  MODULE 4 — AUTO BLOCK SYSTEM
--  Uses real animation tracking to block M1s and skills.
--  Implements the ByteHub Auto Block V6 logic.
-- ════════════════════════════════════════════════════════════════════

local AutoBlock = {}
AutoBlock.enabled           = false
AutoBlock.blocking          = false
AutoBlock.unblockScheduled  = false
AutoBlock.lastUnblockTime   = 0
AutoBlock.recentSidedash    = {}

function AutoBlock:init()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            self:watchPlayer(player)
        end
    end
    Players.PlayerAdded:Connect(function(player)
        if player == LP then return end
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            self:watchPlayer(player)
        end)
    end)
end

function AutoBlock:watchPlayer(player)
    if not player.Character then return end
    local hum = player.Character:WaitForChild("Humanoid", 10)
    if not hum then return end
    local animator = hum:WaitForChild("Animator", 10)
    if not animator then return end

    animator.AnimationPlayed:Connect(function(track)
        if not self.enabled then return end
        local id = track.Animation and track.Animation.AnimationId
        if not id then return end
        local numId = id:match("%d+")
        if not numId then return end

        if Config.SKILL_ANIMS[numId] then
            self:onSkillDetected(player, track)
        elseif Config.M1_ANIMS[numId] then
            self:onM1Detected(player)
        elseif Config.SIDEDASH_ANIMS[numId] then
            self:onSidedashDetected(player)
        end
    end)
end

function AutoBlock:getPlayerRange(attacker)
    local lastDash = self.recentSidedash[attacker]
    if lastDash and (tick() - lastDash) < 0 then
        return Config.AutoBlock.SidedashRange
    end
    return Config.AutoBlock.DetectionRange
end

function AutoBlock:onM1Detected(attacker)
    if not self.enabled then return end
    if not Root or not attacker.Character then return end
    local otherRoot = attacker.Character:FindFirstChild("HumanoidRootPart")
    if not otherRoot then return end
    if (Root.Position - otherRoot.Position).Magnitude > self:getPlayerRange(attacker) then return end

    local now = tick()
    if (now - self.lastUnblockTime) < Config.AutoBlock.ReblockDelay then return end

    if not self.blocking then
        self.blocking = true
        Movement:pressBlock()
    end

    if not self.unblockScheduled then
        self.unblockScheduled = true
        task.delay(Config.getPingScaledHold(), function()
            self:doUnblock()
        end)
    end
end

function AutoBlock:onSkillDetected(attacker, track)
    if not self.enabled then return end
    if not Root or not attacker.Character then return end
    local otherRoot = attacker.Character:FindFirstChild("HumanoidRootPart")
    if not otherRoot then return end
    if (Root.Position - otherRoot.Position).Magnitude > self:getPlayerRange(attacker) then return end

    local now = tick()
    if (now - self.lastUnblockTime) < Config.AutoBlock.ReblockDelay then return end

    if not self.blocking then
        self.blocking = true
        Movement:pressBlock()
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
        self:doUnblock()
    end)
end

function AutoBlock:onSidedashDetected(attacker)
    if not self.enabled then return end
    if not Root or not attacker.Character then return end
    local otherRoot = attacker.Character:FindFirstChild("HumanoidRootPart")
    if not otherRoot then return end
    if (Root.Position - otherRoot.Position).Magnitude <= Config.AutoBlock.SidedashRange then
        self.recentSidedash[attacker] = tick()
    end
end

function AutoBlock:doUnblock()
    self.blocking = false
    self.unblockScheduled = false
    self.lastUnblockTime = tick()
    Movement:releaseBlock()
end

function AutoBlock:dropBlock()
    if self.blocking then
        self.blocking = false
        self.unblockScheduled = false
        Movement:releaseBlock()
    end
end

-- ════════════════════════════════════════════════════════════════════
--  MODULE 5 — EXTENDED PUNISH SYSTEM
--  Wall combos, tech chase, aerial extend, cooldown-aware routing.
-- ════════════════════════════════════════════════════════════════════

local ExtendedPunish = {}
ExtendedPunish.comboData = { consecutiveHits = 0, currentStage = "M1" }

function ExtendedPunish:startCombo(target)
    self.comboData.consecutiveHits = 0
    self.comboData.currentStage = "M1"

    local charData = getCharData(myCharName)
    local wc = charData.wallCombo

    self:executeM1Chain(wc.initiator.m1s)
    Movement:fireDashRemote(wc.initiator.dash)
    task.wait(wc.initiator.delay)

    if self:isNearWall(target) then
        self:executeWallString(wc)
    else
        self:standardPunish(target)
    end
end

function ExtendedPunish:executeM1Chain(count)
    for i = 1, count do
        CombatController:m1()
        local delay = (i <= 2) and 0.05 or (i == 3) and 0.08 or 0.1
        task.wait(delay)
    end
    self.comboData.currentStage = "KNOCKBACK"
end

function ExtendedPunish:executeWallString(wc)
    self.comboData.currentStage = "WALL"
    for i, moveName in ipairs(wc.string) do
        if CombatController:isOnCooldown(moveName) then
            Movement:backdashCancel()
            return
        end
        CombatController:useAbility(moveName)
        task.wait(wc.delays[i] or 0.1)
    end
    task.wait(0.1)
    self:techChase()
end

function ExtendedPunish:techChase()
    self.comboData.currentStage = "ENDER"
    local target = getClosestTarget()
    if not target then return end

    local predictedOption = Adaptation:predictTech(target)

    if predictedOption == "left" then
        Movement:sideDash("left")
        task.wait(0.05)
        CombatController:m1Combo()
    elseif predictedOption == "right" then
        Movement:sideDash("right")
        task.wait(0.05)
        CombatController:m1Combo()
    elseif predictedOption == "neutral" then
        Movement:dashForward()
        task.wait(0.08)
        CombatController:grab()
    else
        Movement:dashForward()
        task.wait(0.2)
        CombatController:useAbility("Move4")
    end
end

function ExtendedPunish:standardPunish(target)
    local charData = getCharData(myCharName)
    local route  = charData.punishRoute or { "M1", "M1", "M1", "Move1" }
    local delays = charData.punishDelays or { 0.05, 0.05, 0.08, 0.08 }

    for i, moveName in ipairs(route) do
        if CombatController:isOnCooldown(moveName) then
            Movement:backdashCancel()
            return
        end
        if moveName == "M1" then
            CombatController:m1()
        else
            CombatController:useAbility(moveName)
        end
        task.wait(delays[i] or 0.08)
    end

    if target then
        local tHum = target:FindFirstChild("Humanoid")
        if tHum and tHum.Health > 0 then
            task.wait(0.05)
            self:techChase()
        end
    end
end

function ExtendedPunish:isNearWall(target)
    if not Root then return false end
    local myPos = Root.Position
    local mapSize = 100
    local xEdge = math.min(math.abs(myPos.X - mapSize), math.abs(myPos.X + mapSize))
    local zEdge = math.min(math.abs(myPos.Z - mapSize), math.abs(myPos.Z + mapSize))
    return math.min(xEdge, zEdge) < 25
end

-- ════════════════════════════════════════════════════════════════════
--  MODULE 6 — DECISION ENGINE
--  Priority: RECOVERY > PUNISH > DEFENSIVE > NEUTRAL
-- ════════════════════════════════════════════════════════════════════

local DecisionEngine = {}
DecisionEngine.currentMode = "NEUTRAL"

function DecisionEngine:evaluate()
    local target = getClosestTarget()
    if not target then return end

    local dist = getDistance(target)
    local tHum = target:FindFirstChild("Humanoid")
    if not tHum then return end

    -- PRIORITY 1: RECOVERY
    if isRagdolled(Character) then
        self.currentMode = "RECOVERY"
        return self:doRecovery()
    end

    -- PRIORITY 2: PUNISH
    if AnimDetector:isEnemyPunishable()
    or AnimDetector:didEnemyWhiff()
    or (tHum:GetState() == Enum.HumanoidStateType.Freefall)
    or (tHum:GetState() == Enum.HumanoidStateType.Ragdoll) then
        self.currentMode = "PUNISH"
        return self:doPunish(target)
    end

    -- PRIORITY 3: DEFENSIVE (enemy attacking)
    if AnimDetector:isEnemyAttacking() then
        self.currentMode = "DEFENSIVE"
        return self:doDefensive(target)
    end

    -- Velocity spike detection
    if dist < Config.ZONES.BURST_RANGE then
        local vel = getEnemyVelocity(target)
        if Root then
            local towardsMe = (Root.Position - (target:FindFirstChild("HumanoidRootPart") and target:FindFirstChild("HumanoidRootPart").Position or Root.Position)).Unit
            local approachSpeed = vel:Dot(towardsMe)
            if approachSpeed > Config.VELOCITY_SPIKE_THRESHOLD then
                self.currentMode = "DEFENSIVE"
                return self:doDefensive(target)
            end
        end
    end

    -- Auto uppercut counter
    if AnimDetector:isEnemyUppercutting() and dist < 15 then
        self.currentMode = "DEFENSIVE"
        CombatController:jump()
        return
    end

    -- PRIORITY 4: NEUTRAL
    self.currentMode = "NEUTRAL"
    return self:doNeutral(target, dist)
end

function DecisionEngine:doRecovery()
    local myState = Humanoid:GetState()
    if myState == Enum.HumanoidStateType.Ragdoll
    or myState == Enum.HumanoidStateType.Freefall then
        CombatController:evasive()
    end
    task.wait(0.02)
    Movement:sideDash("right")
    local target = getClosestTarget()
    if target and getDistance(target) < 15 then
        Movement:pressBlock()
    end
end

function DecisionEngine:doPunish(target)
    local dist = getDistance(target)
    if dist > 15 then
        Movement:hookDash("forward")
        task.wait(0.08)
    end
    if ExtendedPunish:isNearWall(target) then
        ExtendedPunish:startCombo(target)
    else
        ExtendedPunish:standardPunish(target)
    end
end

function DecisionEngine:doDefensive(target)
    local dist = getDistance(target)
    if dist < Config.ZONES.THREAT_RANGE then
        Movement:pressBlock()
        task.wait(0.1)
        local myHealth = Humanoid.Health
        task.wait(0.05)
        if Humanoid.Health == myHealth then
            Movement:releaseBlock()
            Movement:backdashCancel()
        else
            Movement:releaseBlock()
            CombatController:grab()
            CombatController:m1Combo()
        end
    else
        Movement:dashBack()
        task.wait(0.05)
        Movement:pressBlock()
    end
end

function DecisionEngine:doNeutral(target, dist)
    if dist > Config.ZONES.BURST_RANGE then
        if dist > Config.ZONES.RESET_RANGE then
            Movement:hookDash("right")
            task.wait(0.1)
            Movement:hookDash("left")
        else
            Movement:counterLoopDash()
            task.wait(0.1)
            Movement:pressBlock()
        end
    elseif dist > Config.ZONES.POINT_BLANK then
        local charData = getCharData(myCharName)
        Movement:loopDash(charData.idealRange - 3, charData.idealRange + 3)
        if math.random() < 0.15 then
            Movement:hookDash("forward")
            CombatController:m1()
            task.wait(0.03)
            Movement:backdashCancel()
        end
    else
        if AnimDetector:isEnemyAttacking() then
            Movement:pressBlock()
        else
            if math.random() < 0.5 then
                CombatController:m1()
                task.wait(0.03)
                Movement:dashBack()
            else
                Movement:dashForward()
                task.wait(0.03)
                Movement:backdashCancel()
            end
        end
    end

    -- Anti-air
    if target then
        local tHum = target:FindFirstChild("Humanoid")
        if tHum and tHum:GetState() == Enum.HumanoidStateType.Jumping then
            Movement:backdashCancel()
            task.wait(0.05)
            CombatController:useAbility("Move2")
        end
    end
end

-- ════════════════════════════════════════════════════════════════════
--  MODULE 7 — ADAPTATION ENGINE
-- ════════════════════════════════════════════════════════════════════

local Adaptation = {}
Adaptation.profiles = {}

local function newProfile()
    return {
        techRollDirection = {},
        preferredMoves    = {},
        approachPattern   = {},
        lastExchangeTime  = 0,
    }
end

function Adaptation:getProfile(target)
    local uid = target.UserId or target.Name or "unknown"
    if not self.profiles[uid] then
        self.profiles[uid] = newProfile()
    end
    return self.profiles[uid]
end

function Adaptation:recordExchange(target)
    if not target or not target:FindFirstChild("Humanoid") then return end
    local profile = self:getProfile(target)

    local tRoot = target:FindFirstChild("HumanoidRootPart")
    local tHum = target:FindFirstChild("Humanoid")

    if tHum:GetState() == Enum.HumanoidStateType.Running and tRoot then
        local vel = tRoot.AssemblyLinearVelocity
        if math.abs(vel.X) > math.abs(vel.Z) then
            table.insert(profile.techRollDirection, vel.X > 0 and "right" or "left")
        else
            table.insert(profile.techRollDirection, "neutral")
        end
        if #profile.techRollDirection > 10 then
            table.remove(profile.techRollDirection, 1)
        end
    end

    if AnimDetector.enemyAnimId then
        if Config.M1_ANIMS[AnimDetector.enemyAnimId] or Config.SKILL_ANIMS[AnimDetector.enemyAnimId] then
            table.insert(profile.preferredMoves, AnimDetector.enemyAnimId)
            if #profile.preferredMoves > 20 then
                table.remove(profile.preferredMoves, 1)
            end
        end
    end

    profile.lastExchangeTime = tick()
end

function Adaptation:predictTech(target)
    local profile = self:getProfile(target)
    local techs = profile.techRollDirection
    if #techs < 3 then
        local opts = { "left", "right", "neutral", "delay" }
        return opts[math.random(1, 3)]
    end
    local counts = {}
    for _, dir in ipairs(techs) do
        counts[dir] = (counts[dir] or 0) + 1
    end
    local best, bestCount = "left", 0
    for dir, count in pairs(counts) do
        if count > bestCount then bestCount = count; best = dir end
    end
    if bestCount > #techs * 0.7 then return best end
    return best
end

-- ════════════════════════════════════════════════════════════════════
--  UI TOGGLE
-- ════════════════════════════════════════════════════════════════════

local function createToggleUI()
    local sg = Instance.new("ScreenGui")
    sg.Name = "TSBAutoplayer"
    sg.ResetOnSpawn = false
    sg.Parent = LP:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 60)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = sg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "TSB Autoplayer [OFF]"
    label.TextColor3 = Color3.fromRGB(255, 80, 80)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -20, 0, 20)
    status.Position = UDim2.new(0, 10, 0, 35)
    status.BackgroundTransparency = 1
    status.Text = "Press [P] to toggle"
    status.TextColor3 = Color3.fromRGB(150, 150, 160)
    status.Font = Enum.Font.Gotham
    status.TextSize = 12
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = frame

    return label, status
end

-- ════════════════════════════════════════════════════════════════════
--  INITIALIZATION & MAIN LOOP
-- ════════════════════════════════════════════════════════════════════

local function onCharacterAdded(newChar)
    Character = newChar
    Root      = newChar:WaitForChild("HumanoidRootPart")
    Humanoid  = newChar:WaitForChild("Humanoid")

    CombatController:init()
    AnimDetector:init()

    CombatController.consecutiveHits = 0
    CombatController.didGetHit = false
    CombatController.lastHealth = Humanoid.Health
    CombatController:resetCooldowns()

    task.wait(1)
    myCharName = detectMyCharacter()
    print("[TSB] Character detected:", myCharName)
end

local function init()
    repeat task.wait() until LP.Character
    repeat task.wait() until LP.Character:FindFirstChild("HumanoidRootPart")
    repeat task.wait() until LP.Character:FindFirstChild("Humanoid")

    Character = LP.Character
    Root       = Character:WaitForChild("HumanoidRootPart")
    Humanoid   = Character:WaitForChild("Humanoid")

    AnimDetector:init()
    CombatController:init()
    AutoBlock:init()

    LP.CharacterAdded:Connect(onCharacterAdded)

    task.wait(1)
    myCharName = detectMyCharacter()
    print("[TSB] Stage 0 Autoplayer initialized — Character:", myCharName)
    print("[TSB] Press [P] to toggle the autoplayer on/off")

    local uiLabel, uiStatus = createToggleUI()

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        local toggleKey = Enum.KeyCode[Config.ToggleKey] or Enum.KeyCode.P
        if input.KeyCode == toggleKey then
            isRunning = not isRunning
            if isRunning then
                uiLabel.Text = "TSB Autoplayer [ON]"
                uiLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
                uiStatus.Text = "Mode: NEUTRAL"
                AutoBlock.enabled = true
                print("[TSB] Autoplayer ENABLED")
            else
                uiLabel.Text = "TSB Autoplayer [OFF]"
                uiLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                uiStatus.Text = "Press [P] to toggle"
                AutoBlock.enabled = false
                AutoBlock:dropBlock()
                Movement:releaseBlock()
                print("[TSB] Autoplayer DISABLED")
            end
        end
    end)

    -- ══ MAIN LOOP ══
    RunService.RenderStepped:Connect(function()
        if not isRunning then return end
        if not Root or not Humanoid then return end

        frameCounter = frameCounter + 1

        if frameCounter % Config.DECISION_INTERVAL == 0 then
            local ok, err = pcall(function()
                DecisionEngine:evaluate()
            end)
            if not ok then
                warn("[TSB] Decision error:", err)
            end
        end

        if frameCounter % Config.ADAPTATION_INTERVAL == 0 then
            local target = getClosestTarget()
            if target then
                pcall(function()
                    Adaptation:recordExchange(target)
                end)
            end
        end

        Movement.stamina = math.min(Movement.stamina + 0.5, 100)
        if tick() - Movement.lastDashTime < Movement.dashCooldown then
            Movement.isDashing = false
        end

        if uiStatus and DecisionEngine.currentMode then
            uiStatus.Text = "Mode: " .. DecisionEngine.currentMode
        end
    end)
end

init()
