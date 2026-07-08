--[[
══════════════════════════════════════════════════════════════════════════════
    TSB REMOTE SPY — ANIMATION ID & REMOTE FARMER
    ══════════════════════════════════════════════════════════════════════════════

    Hooks into __namecall to intercept:
      • FireServer / InvokeServer calls (combat remotes, ability remotes)
      • LoadAnimation calls (animation asset IDs)
      • AnimationTrack playback

    Logs everything to the Output window AND a live on-screen GUI.

    USAGE:
      1. Execute this script in your executor while in a TSB match.
      2. Play each character — use M1, each ability (1-5), dash, block, grab.
      3. Copy the discovered animation IDs from the output.
      4. Paste them into tsb_config.lua → Config.Characters[CharacterName].animations

    TOGGLE:  Press [L] to clear the log  |  Press [K] to toggle the GUI
═════════════════════════════════════════════════════════════════════════════
]]

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local LP = Players.LocalPlayer

-- ════════════════════════════════════════════════════════════════════
--  STATE
-- ════════════════════════════════════════════════════════════════════

local Spy = {
    remotesFound    = {},   -- remote path → list of args seen
    animationsFound = {},   -- animation ID → play count
    characterAnims  = {},   -- character name → list of anim IDs
    isEnabled       = true,
    logLines        = {},
    maxLogLines     = 50,
}

-- ════════════════════════════════════════════════════════════════════
--  LOGGING
-- ════════════════════════════════════════════════════════════════════

local function log(msg)
    print("[TSB-Spy]", msg)
    table.insert(Spy.logLines, msg)
    if #Spy.logLines > Spy.maxLogLines then
        table.remove(Spy.logLines, 1)
    end
end

local function getFullPath(obj)
    local path = {}
    local current = obj
    while current and current ~= game do
        table.insert(path, 1, current.Name)
        current = current.Parent
    end
    return table.concat(path, ".")
end

local function serializeArgs(args, maxDepth)
    maxDepth = maxDepth or 3
    local function serialize(val, depth)
        depth = depth or 0
        if depth > maxDepth then return "..." end
        local t = type(val)
        if t == "string" then return '"' .. val .. '"'
        elseif t == "number" then return tostring(val)
        elseif t == "boolean" then return tostring(val)
        elseif t == "nil" then return "nil"
        elseif t == "table" then
            local parts = {}
            for k, v in pairs(val) do
                table.insert(parts, "[" .. serialize(k, depth + 1) .. "] = " .. serialize(v, depth + 1))
            end
            return "{" .. table.concat(parts, ", ") .. "}"
        elseif t == "Instance" then
            return getFullPath(val)
        elseif t == "Vector3" then
            return string.format("Vector3(%.2f, %.2f, %.2f)", val.X, val.Y, val.Z)
        elseif t == "CFrame" then
            return "CFrame(...)"
        elseif t == "EnumItem" then
            return tostring(val)
        else
            return "<" .. t .. ">"
        end
    end
    local parts = {}
    for i, arg in ipairs(args) do
        table.insert(parts, serialize(arg))
    end
    return table.concat(parts, ", ")
end

-- ════════════════════════════════════════════════════════════════════
--  HOOK __namecall
-- ════════════════════════════════════════════════════════════════════

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    if not Spy.isEnabled then
        return oldNamecall(self, ...)
    end

    local method = getnamecallmethod()
    local args = { ... }
    local remotePath = getFullPath(self)
    local remoteName = self.Name or ""

    -- ═══ Catch FireServer / InvokeServer ═══
    if method == "FireServer" or method == "InvokeServer" then
        -- Filter for combat-related remotes
        local lowerName = remoteName:lower()
        local isCombatRemote = lowerName:find("attack")
            or lowerName:find("m1")
            or lowerName:find("ability")
            or lowerName:find("move")
            or lowerName:find("dash")
            or lowerName:find("block")
            or lowerName:find("skill")
            or lowerName:find("combat")
            or lowerName:find("hit")
            or lowerName:find("grab")
            or lowerName:find("ultimate")
            or lowerName:find("evade")
            or lowerName:find("remote")
            or lowerName:find("event")
            or true  -- Log everything by default; comment out to filter

        if isCombatRemote then
            local argStr = serializeArgs(args)
            log(string.format("REMOTE [%s] %s.%s(%s)",
                method, remotePath, method, argStr))

            -- Store for later analysis
            if not Spy.remotesFound[remotePath] then
                Spy.remotesFound[remotePath] = { method = method, calls = {} }
            end
            table.insert(Spy.remotesFound[remotePath].calls, {
                time = tick(),
                args = argStr,
            })
            -- Keep last 10 calls per remote
            if #Spy.remotesFound[remotePath].calls > 10 then
                table.remove(Spy.remotesFound[remotePath].calls, 1)
            end
        end
    end

    -- ═══ Catch LoadAnimation ═══
    if method == "LoadAnimation" then
        local animObj = args[1]
        if animObj and typeof(animObj) == "Instance" and animObj:IsA("Animation") then
            local animId = animObj.AnimationId
            if animId then
                Spy.animationsFound[animId] = (Spy.animationsFound[animId] or 0) + 1
                log(string.format("ANIMATION LOADED: %s (plays: %d)",
                    animId, Spy.animationsFound[animId]))

                -- Try to determine which character this belongs to
                local animParent = animObj.Parent
                if animParent then
                    local parentName = animParent.Name
                    if not Spy.characterAnims[parentName] then
                        Spy.characterAnims[parentName] = {}
                    end
                    if not table.find(Spy.characterAnims[parentName], animId) then
                        table.insert(Spy.characterAnims[parentName], animId)
                    end
                end
            end
        end
    end

    return oldNamecall(self, ...)
end)

log("Remote Spy installed — hook on __namecall active")
log("Play each character's moves to discover animation IDs")
log("Press [L] to clear log  |  Press [K] to toggle GUI")

-- ════════════════════════════════════════════════════════════════════
--  HOOK Animator:LoadAnimationTrack (alternative path)
-- ════════════════════════════════════════════════════════════════════

local function hookAnimator(animator)
    if not animator then return end
    local originalLoad = animator.LoadAnimationTrack
    if not originalLoad then return end

    -- Some executors don't allow hooking on Instance methods directly
    -- This is a best-effort hook
    local ok2 = pcall(function()
        local oldLoad
        oldLoad = hookfunction(originalLoad, function(self, anim)
            if anim and anim:IsA("Animation") then
                local animId = anim.AnimationId
                if animId then
                    Spy.animationsFound[animId] = (Spy.animationsFound[animId] or 0) + 1
                    log(string.format("ANIM TRACK: %s (plays: %d) via %s",
                        animId, Spy.animationsFound[animId], getFullPath(self)))
                end
            end
            return oldLoad(self, anim)
        end)
    end)

    if ok2 then
        log("Animator hook installed for: " .. getFullPath(animator))
    end
end

-- Hook our own animator
task.spawn(function()
    repeat task.wait() until LP.Character
    local hum = LP.Character:WaitForChild("Humanoid")
    local animator = hum:WaitForChild("Animator", 5)
    if animator then
        hookAnimator(animator)
    end
end)

-- Hook enemy animators as they spawn
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            local animator = hum:WaitForChild("Animator", 5)
            if animator then
                hookAnimator(animator)
            end
        end
    end)
end)

-- Hook existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LP and player.Character then
        local hum = player.Character:FindFirstChild("Humanoid")
        if hum then
            local animator = hum:FindFirstChild("Animator")
            if animator then
                hookAnimator(animator)
            end
        end
    end
end

-- ════════════════════════════════════════════════════════════════════
--  LIVE GUI — Shows discovered IDs in real time
-- ════════════════════════════════════════════════════════════════════

local guiVisible = true

local function createSpyGUI()
    local sg = Instance.new("ScreenGui")
    sg.Name = "TSBSpy"
    sg.ResetOnSpawn = false
    sg.Parent = LP:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 300)
    frame.Position = UDim2.new(1, -420, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Parent = sg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "TSB Remote Spy — Animation & Remote Farmer"
    title.TextColor3 = Color3.fromRGB(100, 200, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    -- Scrolling frame for log
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -80)
    scroll.Position = UDim2.new(0, 10, 0, 40)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 2)
    layout.Parent = scroll

    -- Stats label
    local stats = Instance.new("TextLabel")
    stats.Size = UDim2.new(1, -20, 0, 20)
    stats.Position = UDim2.new(0, 10, 1, -25)
    stats.BackgroundTransparency = 1
    stats.Text = "Animations: 0 | Remotes: 0"
    stats.TextColor3 = Color3.fromRGB(150, 150, 160)
    stats.Font = Enum.Font.Gotham
    stats.TextSize = 12
    stats.TextXAlignment = Enum.TextXAlignment.Left
    stats.Parent = frame

    -- Clear button
    local clearBtn = Instance.new("TextButton")
    clearBtn.Size = UDim2.new(0, 80, 0, 20)
    clearBtn.Position = UDim2.new(1, -90, 1, -25)
    clearBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    clearBtn.BorderSizePixel = 0
    clearBtn.Text = "Clear"
    clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.TextSize = 12
    clearBtn.Parent = frame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = clearBtn

    -- Export button
    local exportBtn = Instance.new("TextButton")
    exportBtn.Size = UDim2.new(0, 80, 0, 20)
    exportBtn.Position = UDim2.new(1, -175, 1, -25)
    exportBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    exportBtn.BorderSizePixel = 0
    exportBtn.Text = "Export"
    exportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    exportBtn.Font = Enum.Font.GothamBold
    exportBtn.TextSize = 12
    exportBtn.Parent = frame

    local exportCorner = Instance.new("UICorner")
    exportCorner.CornerRadius = UDim.new(0, 4)
    exportCorner.Parent = exportBtn

    -- Functions
    local function refreshLog()
        -- Clear existing
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("TextLabel") then
                child:Destroy()
            end
        end

        -- Add current lines
        for i = #Spy.logLines, 1, -1 do
            local line = Instance.new("TextLabel")
            line.Size = UDim2.new(1, 0, 0, 18)
            line.BackgroundTransparency = 1
            line.Text = Spy.logLines[i]
            line.TextColor3 = Color3.fromRGB(200, 200, 210)
            line.Font = Enum.Font.Code
            line.TextSize = 11
            line.TextXAlignment = Enum.TextXAlignment.Left
            line.TextWrapped = false
            line.Parent = scroll
        end

        local animCount = 0
        for _ in pairs(Spy.animationsFound) do animCount = animCount + 1 end
        local remoteCount = 0
        for _ in pairs(Spy.remotesFound) do remoteCount = remoteCount + 1 end
        stats.Text = string.format("Animations: %d | Remotes: %d", animCount, remoteCount)
    end

    clearBtn.MouseButton1Click:Connect(function()
        Spy.logLines = {}
        refreshLog()
    end)

    exportBtn.MouseButton1Click:Connect(function()
        -- Print all discovered animations in config format
        print("\n═══════════════════════════════════════════════════")
        print("  TSB SPY EXPORT — Copy into tsb_config.lua")
        print("═══════════════════════════════════════════════════\n")

        print("-- ANIMATION IDs DISCOVERED:")
        for animId, count in pairs(Spy.animationsFound) do
            print(string.format('  %s,  -- played %d times', animId, count))
        end

        print("\n-- REMOTES DISCOVERED:")
        for path, data in pairs(Spy.remotesFound) do
            print(string.format('  -- %s (%s)', path, data.method))
            if data.calls[1] then
                print(string.format('  --   last args: %s', data.calls[#data.calls].args))
            end
        end

        print("\n-- PER-CHARACTER ANIMATIONS:")
        for charName, anims in pairs(Spy.characterAnims) do
            print(string.format('  -- %s:', charName))
            for _, animId in ipairs(anims) do
                print(string.format('  %s,', animId))
            end
        end

        print("\n═══════════════════════════════════════════════════")
        print("  END EXPORT")
        print("═══════════════════════════════════════════════════\n")

        log("Export printed to output — check console (F9)")
    end)

    -- Refresh loop (every 0.5 seconds)
    task.spawn(function()
        while true do
            if guiVisible then
                refreshLog()
            end
            task.wait(0.5)
        end
    end)

    return sg
end

local spyGui = createSpyGUI()

-- ════════════════════════════════════════════════════════════════════
--  KEYBINDS
-- ════════════════════════════════════════════════════════════════════

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- [L] = Clear log
    if input.KeyCode == Enum.KeyCode.L then
        Spy.logLines = {}
        log("Log cleared")

    -- [K] = Toggle GUI
    elseif input.KeyCode == Enum.KeyCode.K then
        guiVisible = not guiVisible
        if spyGui then
            spyGui.Enabled = guiVisible
        end
        log("GUI " .. (guiVisible and "shown" or "hidden"))
    end
end)

-- ════════════════════════════════════════════════════════════════════
--  ANIMATION TRACKING — Hook Humanoid.AnimationPlayed for all players
-- ════════════════════════════════════════════════════════════════════

local function hookAnimationPlayed(player)
    if not player.Character then return end
    local hum = player.Character:FindFirstChild("Humanoid")
    if not hum then return end

    hum.AnimationPlayed:Connect(function(animTrack)
        if not Spy.isEnabled then return end

        local anim = animTrack.Animation
        if anim and anim:IsA("Animation") then
            local animId = anim.AnimationId
            if animId then
                Spy.animationsFound[animId] = (Spy.animationsFound[animId] or 0) + 1
                local playerName = player.Name
                local isLocal = (player == LP) and " [SELF]" or ""
                log(string.format("ANIM PLAYED: %s — by %s%s (count: %d)",
                    animId, playerName, isLocal, Spy.animationsFound[animId]))
            end
        end
    end)
end

-- Hook existing players
for _, player in ipairs(Players:GetPlayers()) do
    hookAnimationPlayed(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        hookAnimationPlayed(player)
    end)
end

-- Hook future players
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        hookAnimationPlayed(player)
    end)
end)

log("AnimationPlayed hooks installed for all players")
log("Ready — go play each character's moves!")
