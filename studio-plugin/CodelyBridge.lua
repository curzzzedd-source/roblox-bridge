-- Codely Bridge — Plugin Card Style
-- Clean toggle card like Lemonade

local Plugin = plugin or script.Parent
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local StudioService = game:GetService("StudioService")

local SERVER_URL = "https://web-production-f04e1.up.railway.app"
local API_BASE = SERVER_URL .. "/api"
local VERSION = "v1.0.0"

-- Place info
local function getPlaceInfo()
	local placeId = game.PlaceId
	local placeName = "Unknown"
	pcall(function()
		placeName = StudioService.ActiveScript and StudioService.ActiveScript:GetFullName() or "Untitled"
	end)
	if placeName == "Untitled" or placeName == "Unknown" then
		placeName = "Place_" .. tostring(placeId)
	end
	return {
		placeId = placeId, placeName = placeName, gameId = game.GameId,
		sessionId = tostring(placeId) .. "_" .. tostring(game.PlaceId),
	}
end

local placeInfo = getPlaceInfo()
local SESSION_ID = placeInfo.sessionId

-- HTTP check
local httpSuccess, _ = pcall(function() return HttpService:GetAsync(SERVER_URL .. "/health") end)

-- Plugin toolbar
local toolbar = plugin:CreateToolbar("Codely Bridge")
local widgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right, false, false, 300, 200, 300, 200)
local widget = plugin:CreateDockWidgetPluginGui("CodelyBridgeWidget", widgetInfo)
widget.Title = "Codely Bridge"

-- ===== COLORS =====
local C_WHITE = Color3.fromRGB(255, 255, 255)
local C_BG = Color3.fromRGB(245, 245, 245)
local C_CARD = Color3.fromRGB(255, 255, 255)
local C_TEXT = Color3.fromRGB(30, 30, 30)
local C_SUBTEXT = Color3.fromRGB(130, 130, 130)
local C_BLUE = Color3.fromRGB(59, 130, 246)
local C_GREEN = Color3.fromRGB(34, 197, 94)
local C_RED = Color3.fromRGB(239, 68, 68)
local C_GREY = Color3.fromRGB(100, 100, 100)
local C_BORDER = Color3.fromRGB(230, 230, 230)

-- Root
local root = Instance.new("Frame")
root.Size = UDim2.new(1, 0, 1, 0)
root.BackgroundColor3 = C_BG
root.BorderSizePixel = 0
root.Parent = widget

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 12)
padding.PaddingBottom = UDim.new(0, 12)
padding.PaddingLeft = UDim.new(0, 12)
padding.PaddingRight = UDim.new(0, 12)
padding.Parent = root

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.Parent = root

-- ===== HEADER =====
local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, 24)
header.BackgroundTransparency = 1
header.Text = "Plugins"
header.TextSize = 18
header.TextColor3 = C_TEXT
header.Font = Enum.Font.GothamBold
header.TextXAlignment = Enum.TextXAlignment.Left
header.Parent = root

-- ===== CARD =====
local card = Instance.new("Frame")
card.Size = UDim2.new(1, 0, 0, 130)
card.BackgroundColor3 = C_CARD
card.BorderSizePixel = 0
card.Parent = root

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 10)
cardCorner.Parent = card

local cardStroke = Instance.new("UIStroke")
cardStroke.Color = C_BORDER
cardStroke.Thickness = 1
cardStroke.Parent = card

local cardPad = Instance.new("UIPadding")
cardPad.PaddingTop = UDim.new(0, 12)
cardPad.PaddingBottom = UDim.new(0, 12)
cardPad.PaddingLeft = UDim.new(0, 12)
cardPad.PaddingRight = UDim.new(0, 12)
cardPad.Parent = card

local cardLayout = Instance.new("UIListLayout")
cardLayout.Padding = UDim.new(0, 6)
cardLayout.Parent = card

-- Row 1: Icon + Name + Author + Toggle
local topRow = Instance.new("Frame")
topRow.Size = UDim2.new(1, 0, 0, 36)
topRow.BackgroundTransparency = 1
topRow.Parent = card

-- Icon (square black box with ⚡)
local iconBox = Instance.new("Frame")
iconBox.Size = UDim2.new(0, 36, 0, 36)
iconBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
iconBox.BorderSizePixel = 0
iconBox.Parent = topRow

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(0, 8)
iconCorner.Parent = iconBox

local iconText = Instance.new("TextLabel")
iconText.Size = UDim2.new(1, 0, 1, 0)
iconText.BackgroundTransparency = 1
iconText.Text = "⚡"
iconText.TextSize = 20
iconText.TextColor3 = C_WHITE
iconText.Parent = iconBox

-- Name + Author
local nameFrame = Instance.new("Frame")
nameFrame.Size = UDim2.new(1, -100, 1, 0)
nameFrame.Position = UDim2.new(0, 44, 0, 0)
nameFrame.BackgroundTransparency = 1
nameFrame.Parent = topRow

local nameLayout = Instance.new("UIListLayout")
nameLayout.Padding = UDim.new(0, 0)
nameLayout.Parent = nameFrame

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, 0, 0, 20)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "Codely Bridge"
nameLabel.TextSize = 15
nameLabel.TextColor3 = C_TEXT
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Parent = nameFrame

local authorLabel = Instance.new("TextLabel")
authorLabel.Size = UDim2.new(1, 0, 0, 16)
authorLabel.BackgroundTransparency = 1
authorLabel.Text = "curzzzedd-source"
authorLabel.TextSize = 13
authorLabel.TextColor3 = C_BLUE
authorLabel.Font = Enum.Font.GothamMedium
authorLabel.TextXAlignment = Enum.TextXAlignment.Left
authorLabel.Parent = nameFrame

-- Toggle switch (right side)
local toggleFrame = Instance.new("TextButton")
toggleFrame.Size = UDim2.new(0, 44, 0, 24)
toggleFrame.BackgroundColor3 = C_GREY
toggleFrame.BorderSizePixel = 0
toggleFrame.Text = ""
toggleFrame.AutoButtonColor = false
toggleFrame.Parent = topRow
toggleFrame.Position = UDim2.new(1, -44, 0.5, -12)

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(1, 0)
toggleCorner.Parent = toggleFrame

local toggleKnob = Instance.new("Frame")
toggleKnob.Size = UDim2.new(0, 18, 0, 18)
toggleKnob.Position = UDim2.new(0, 3, 0.5, -9)
toggleKnob.BackgroundColor3 = C_WHITE
toggleKnob.BorderSizePixel = 0
toggleKnob.Parent = toggleFrame

local knobCorner = Instance.new("UICorner")
knobCorner.CornerRadius = UDim.new(1, 0)
knobCorner.Parent = toggleKnob

-- Row 2: Description
local descLabel = Instance.new("TextLabel")
descLabel.Size = UDim2.new(1, 0, 0, 16)
descLabel.BackgroundTransparency = 1
descLabel.Text = "Connect Roblox Studio to Codely CLI."
descLabel.TextSize = 13
descLabel.TextColor3 = C_SUBTEXT
descLabel.Font = Enum.Font.Gotham
descLabel.TextXAlignment = Enum.TextXAlignment.Left
descLabel.Parent = card

-- Row 3: Permissions
local permsLabel = Instance.new("TextLabel")
permsLabel.Size = UDim2.new(1, 0, 0, 14)
permsLabel.BackgroundTransparency = 1
permsLabel.Text = "HTTP Requests ✓  |  Script Injection Allowed"
permsLabel.TextSize = 11
permsLabel.TextColor3 = C_GREY
permsLabel.Font = Enum.Font.GothamMedium
permsLabel.TextXAlignment = Enum.TextXAlignment.Left
permsLabel.Parent = card

-- Row 4: Status text
local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, 0, 0, 14)
statusText.BackgroundTransparency = 1
statusText.Text = "● Inactive — Click toggle to connect"
statusText.TextSize = 11
statusText.TextColor3 = C_GREY
statusText.Font = Enum.Font.GothamMedium
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = card

-- ===== STATE =====
local isActivated = false
local isConnected = false
local processedCommandIds = {}

-- ===== LOGIC =====

local function safeHttpGet(url)
	return pcall(function() return HttpService:RequestAsync({ Url = url, Method = "GET" }) end)
end

local function safeHttpPost(url, data)
	return pcall(function()
		return HttpService:RequestAsync({
			Url = url, Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode(data),
		})
	end)
end

local function registerSession()
	local info = getPlaceInfo()
	safeHttpPost(API_BASE .. "/register", {
		sessionId = SESSION_ID, placeId = info.placeId,
		placeName = info.placeName, gameId = info.gameId,
		activated = isActivated,
	})
end

local function testConnection()
	local ok, res = safeHttpGet(API_BASE .. "/commands?sessionId=" .. SESSION_ID)
	if ok and res.StatusCode == 200 then
		isConnected = true
		registerSession()
		return true
	else
		isConnected = false
		return false
	end
end

-- Toggle animation
local function setToggle(on)
	isActivated = on
	if on then
		-- Animate knob right
		local tw = Instance.new("TweenInfo")
		tw = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		game:GetService("TweenService"):Create(toggleFrame, tw, { BackgroundColor3 = C_GREEN }):Play()
		game:GetService("TweenService"):Create(toggleKnob, tw, { Position = UDim2.new(0, 23, 0.5, -9) }):Play()
		statusText.Text = "● Active — " .. placeInfo.placeName
		statusText.TextColor3 = C_GREEN
		registerSession()
		safeHttpPost(API_BASE .. "/heartbeat", {
			sessionId = SESSION_ID, placeInfo = getPlaceInfo(), activated = true,
		})
	else
		local tw = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		game:GetService("TweenService"):Create(toggleFrame, tw, { BackgroundColor3 = C_GREY }):Play()
		game:GetService("TweenService"):Create(toggleKnob, tw, { Position = UDim2.new(0, 3, 0.5, -9) }):Play()
		statusText.Text = "● Inactive — Click toggle to connect"
		statusText.TextColor3 = C_GREY
		safeHttpPost(API_BASE .. "/heartbeat", {
			sessionId = SESSION_ID, placeInfo = getPlaceInfo(), activated = false,
		})
	end
end

toggleFrame.MouseButton1Click:Connect(function()
	if not isConnected then
		testConnection()
	end
	if isConnected then
		setToggle(not isActivated)
	else
		statusText.Text = "● Cannot connect — check server"
		statusText.TextColor3 = C_RED
	end
end)

-- ===== COMMAND EXECUTION =====

local function resolvePath(pathString)
	if not pathString or pathString == "" then return game end
	local obj = game
	for part in string.gmatch(pathString, "([^%.]+)") do
		if part ~= "game" then
			obj = obj:FindFirstChild(part)
			if not obj then return nil end
		end
	end
	return obj
end

local function executeCommand(command)
	local action = command.action
	local data = command.data or {}
	local result = { success = false, error = nil }

	if not isActivated then
		result = { success = false, error = "Not activated" }
		safeHttpPost(API_BASE .. "/result", { commandId = command.id, result = result, sessionId = SESSION_ID })
		return
	end

	spawn(function()
		pcall(function()
			if action == "create_script" then
				local scriptType = data.scriptType or "Script"
				local parent = resolvePath(data.parentPath) or game
				local si
				if scriptType == "Script" then si = Instance.new("Script")
				elseif scriptType == "LocalScript" then si = Instance.new("LocalScript")
				elseif scriptType == "ModuleScript" then si = Instance.new("ModuleScript") end
				if si then
					si.Name = data.name or "NewScript"
					si.Parent = parent
					si.Source = data.code or ""
					result = { success = true, scriptPath = si:GetFullName(), scriptType = scriptType }
				else
					result = { success = false, error = "Invalid script type" }
				end

			elseif action == "update_script" then
				local so = resolvePath(data.scriptPath)
				if so and so:IsA("LuaSourceContainer") then
					so.Source = data.code or ""
					result = { success = true, scriptPath = data.scriptPath }
				else
					result = { success = false, error = "Script not found" }
				end

			elseif action == "create_object" then
				local cn = data.className
				local parent = resolvePath(data.parentPath) or game
				if cn then
					local obj = Instance.new(cn)
					obj.Name = data.name or cn
					obj.Parent = parent
					if data.properties then
						for p, v in pairs(data.properties) do
							pcall(function() obj[p] = v end)
						end
					end
					result = { success = true, objectPath = obj:GetFullName(), className = cn }
				else
					result = { success = false, error = "Missing className" }
				end

			elseif action == "delete_object" then
				local obj = resolvePath(data.objectPath)
				if obj and obj ~= game then
					local p = obj:GetFullName()
					obj:Destroy()
					result = { success = true, deletedPath = p }
				else
					result = { success = false, error = "Object not found" }
				end

			elseif action == "get_object_info" then
				local obj = resolvePath(data.objectPath)
				if obj then
					local info = { className = obj.ClassName, name = obj.Name, path = obj:GetFullName() }
					if obj:IsA("BasePart") then
						info.position = { x = obj.Position.X, y = obj.Position.Y, z = obj.Position.Z }
						info.size = { x = obj.Size.X, y = obj.Size.Y, z = obj.Size.Z }
					elseif obj:IsA("LuaSourceContainer") then
						info.source = obj.Source
					end
					result = { success = true, info = info }
				else
					result = { success = false, error = "Object not found" }
				end

			elseif action == "execute_luau" then
				local ok, r = pcall(function() return loadstring(data.code)() end)
				if ok then
					result = { success = true, result = tostring(r) or "nil" }
				else
					result = { success = false, error = tostring(r) }
				end

			elseif action == "list_objects" then
				local parent = resolvePath(data.parentPath) or game
				local objects = {}
				for _, c in ipairs(parent:GetChildren()) do
					table.insert(objects, { name = c.Name, className = c.ClassName })
				end
				result = { success = true, objects = objects, parentPath = parent:GetFullName() }

			else
				result = { success = false, error = "Unknown: " .. action }
			end
		end)

		safeHttpPost(API_BASE .. "/result", { commandId = command.id, result = result, sessionId = SESSION_ID })
	end)
end

-- ===== POLLING =====
local lastPollTime = 0
RunService.Heartbeat:Connect(function()
	local t = tick()
	if t - lastPollTime < 1 then return end
	lastPollTime = t

	if not isConnected then
		testConnection()
		return
	end
	if not isActivated then return end

	spawn(function()
		local ok, res = safeHttpGet(API_BASE .. "/commands?sessionId=" .. SESSION_ID)
		if ok and res.StatusCode == 200 then
			local parsed, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
			if parsed and data.commands then
				for _, cmd in ipairs(data.commands) do
					if not processedCommandIds[cmd.id] then
						processedCommandIds[cmd.id] = true
						executeCommand(cmd)
					end
				end
				if #data.commands > 0 then
					local ids = {}
					for _, c in ipairs(data.commands) do table.insert(ids, c.id) end
					safeHttpPost(API_BASE .. "/commands/clear", { commandIds = ids, sessionId = SESSION_ID })
				end
			end
		else
			if isConnected then
				isConnected = false
				setToggle(false)
			end
		end
	end)
end)

-- Heartbeat
task.spawn(function()
	while true do
		if isConnected then
			safeHttpPost(API_BASE .. "/heartbeat", {
				sessionId = SESSION_ID, placeInfo = getPlaceInfo(), activated = isActivated,
			})
		end
		task.wait(15)
	end
end)

-- Init
task.spawn(function()
	task.wait(2)
	testConnection()
end)

-- Toolbar button
local toggleBtn = toolbar:CreateButton("Toggle Codely Bridge", "Open/close panel")
toggleBtn.Click:Connect(function() widget.Enabled = not widget.Enabled end)

if not httpSuccess then
	statusText.Text = "● HTTP not enabled — check Game Settings"
	statusText.TextColor3 = C_RED
end

print("⚡ Codely Bridge " .. VERSION .. " loaded")
print("🔒 Click the toggle to activate")