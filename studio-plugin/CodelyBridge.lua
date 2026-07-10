-- Codely Bridge — Lemonade-style UI
-- Clean, compact, activation-gated

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
local widgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right, false, false, 260, 180, 260, 180)
local widget = plugin:CreateDockWidgetPluginGui("CodelyBridgeWidget", widgetInfo)
widget.Title = "Codely Bridge"

-- ===== STYLES =====
local C_BG = Color3.fromRGB(255, 255, 255)
local C_TEXT = Color3.fromRGB(40, 40, 40)
local C_SUBTEXT = Color3.fromRGB(130, 130, 130)
local C_GREEN = Color3.fromRGB(34, 197, 94)
local C_RED = Color3.fromRGB(220, 50, 50)
local C_GREY = Color3.fromRGB(55, 55, 55)
local C_LIGHT_GREY = Color3.fromRGB(240, 240, 240)

-- Root frame
local root = Instance.new("Frame")
root.Size = UDim2.new(1, 0, 1, 0)
root.BackgroundColor3 = C_BG
root.BorderSizePixel = 0
root.Parent = widget

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 12)
padding.PaddingBottom = UDim.new(0, 12)
padding.PaddingLeft = UDim.new(0, 14)
padding.PaddingRight = UDim.new(0, 14)
padding.Parent = root

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = root

-- Helper: pill button
local function createPillButton(text, bgColor)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 90, 0, 30)
	btn.BackgroundColor3 = bgColor
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextSize = 14
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.AutoButtonColor = false
	btn.Parent = root

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = btn

	return btn
end

-- Helper: label
local function createLabel(text, textSize, color)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, textSize or 14)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextSize = textSize or 14
	lbl.TextColor3 = color or C_TEXT
	lbl.Font = Enum.Font.Gotham
	lbl.TextXAlignment = Enum.TextXAlignment.Center
	lbl.Parent = root
	return lbl
end

-- ===== HEADER =====
local headerFrame = Instance.new("Frame")
headerFrame.Size = UDim2.new(1, 0, 0, 32)
headerFrame.BackgroundTransparency = 1
headerFrame.Parent = root

local headerLayout = Instance.new("UIListLayout")
headerLayout.FillDirection = Enum.FillDirection.Horizontal
headerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
headerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
headerLayout.Padding = UDim.new(0, 6)
headerLayout.Parent = headerFrame

-- Icon (emoji as text)
local iconLabel = Instance.new("TextLabel")
iconLabel.Size = UDim2.new(0, 22, 0, 22)
iconLabel.BackgroundTransparency = 1
iconLabel.Text = "⚡"
iconLabel.TextSize = 18
iconLabel.TextColor3 = C_TEXT
iconLabel.Parent = headerFrame

-- Version
local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(0, 60, 0, 22)
versionLabel.BackgroundTransparency = 1
versionLabel.Text = VERSION
versionLabel.TextSize = 13
versionLabel.TextColor3 = C_SUBTEXT
versionLabel.Font = Enum.Font.GothamMedium
versionLabel.TextXAlignment = Enum.TextXAlignment.Left
versionLabel.Parent = headerFrame

-- ===== BUTTONS ROW =====
local btnRow = Instance.new("Frame")
btnRow.Size = UDim2.new(1, 0, 0, 34)
btnRow.BackgroundTransparency = 1
btnRow.Parent = root

local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection = Enum.FillDirection.Horizontal
btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
btnLayout.Padding = UDim.new(0, 8)
btnLayout.Parent = btnRow

-- Connect button (ACTIVATE)
local connectBtn = createPillButton("Connect", C_GREEN)
connectBtn.Parent = btnRow

-- Status button (shows state)
local statusBtn = createPillButton("Status", C_GREY)
statusBtn.Parent = btnRow

-- ===== INSTRUCTION TEXT =====
local instructionLabel = createLabel("Open a place in Studio then press Connect", 13, C_SUBTEXT)
instructionLabel.Size = UDim2.new(1, -10, 0, 32)
instructionLabel.TextWrapped = true

-- ===== PLACE NAME (hidden until connected) =====
local placeLabel = createLabel("", 12, C_SUBTEXT)
placeLabel.Visible = false

-- ===== LOGS BUTTON =====
local logsBtn = Instance.new("TextButton")
logsBtn.Size = UDim2.new(0, 80, 0, 24)
logsBtn.BackgroundColor3 = C_BG
logsBtn.BorderSizePixel = 1
logsBtn.BorderColor3 = C_LIGHT_GREY
logsBtn.Text = "Logs Off"
logsBtn.TextSize = 12
logsBtn.TextColor3 = C_SUBTEXT
logsBtn.Font = Enum.Font.GothamMedium
logsBtn.AutoButtonColor = false
logsBtn.Parent = root

local logsCorner = Instance.new("UICorner")
logsCorner.CornerRadius = UDim.new(1, 0)
logsCorner.Parent = logsBtn

-- ===== STATE =====
local isActivated = false
local isConnected = false
local logsVisible = false
local processedCommandIds = {}

-- ===== LOG PANEL (hidden by default) =====
local logPanel = Instance.new("TextLabel")
logPanel.Size = UDim2.new(1, 0, 0, 0)
logPanel.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
logPanel.BorderSizePixel = 0
logPanel.Text = ""
logPanel.TextSize = 11
logPanel.TextColor3 = C_SUBTEXT
logPanel.Font = Enum.Font.Code
logPanel.TextXAlignment = Enum.TextXAlignment.Left
logPanel.TextYAlignment = Enum.TextYAlignment.Top
logPanel.TextWrapped = true
logPanel.Visible = false
logPanel.Parent = root

local logCorner = Instance.new("UICorner")
logCorner.CornerRadius = UDim.new(0, 6)
logCorner.Parent = logPanel

-- ===== LOGIC =====

local function log(msg)
	local stamp = os.date("%H:%M:%S")
	logPanel.Text = logPanel.Text .. "[" .. stamp .. "] " .. msg .. "\n"
	if string.len(logPanel.Text) > 600 then
		logPanel.Text = string.sub(logPanel.Text, -500)
	end
end

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
	placeLabel.Text = info.placeName
	placeLabel.Visible = true
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

-- ===== ACTIVATION TOGGLE =====

local function setActivated(activated)
	isActivated = activated
	if activated then
		connectBtn.Text = "Disconnect"
		connectBtn.BackgroundColor3 = C_RED
		instructionLabel.Text = "Codely is connected and active"
		instructionLabel.TextColor3 = C_GREEN
		statusBtn.Text = "Active"
		statusBtn.BackgroundColor3 = C_GREEN
		log("✅ Activated")
		registerSession()
		safeHttpPost(API_BASE .. "/heartbeat", {
			sessionId = SESSION_ID, placeInfo = getPlaceInfo(), activated = true,
		})
	else
		connectBtn.Text = "Connect"
		connectBtn.BackgroundColor3 = C_GREEN
		instructionLabel.Text = "Open a place in Studio then press Connect"
		instructionLabel.TextColor3 = C_SUBTEXT
		statusBtn.Text = "Status"
		statusBtn.BackgroundColor3 = C_GREY
		log("🛑 Deactivated")
		safeHttpPost(API_BASE .. "/heartbeat", {
			sessionId = SESSION_ID, placeInfo = getPlaceInfo(), activated = false,
		})
	end
end

connectBtn.MouseButton1Click:Connect(function()
	if not isConnected then
		testConnection()
	end
	if isConnected then
		setActivated(not isActivated)
	else
		instructionLabel.Text = "Cannot connect — check server"
		instructionLabel.TextColor3 = C_RED
	end
end)

statusBtn.MouseButton1Click:Connect(function()
	if isActivated then
		instructionLabel.Text = "✅ Active — " .. placeInfo.placeName
		instructionLabel.TextColor3 = C_GREEN
	else
		instructionLabel.Text = "🔒 Inactive — press Connect"
		instructionLabel.TextColor3 = C_SUBTEXT
	end
end)

-- Logs toggle
logsBtn.MouseButton1Click:Connect(function()
	logsVisible = not logsVisible
	if logsVisible then
		logsBtn.Text = "Logs On"
		logPanel.Size = UDim2.new(1, 0, 0, 80)
		logPanel.Visible = true
		widget.Size = Vector2.new(260, 280)
		widget.MinSize = Vector2.new(260, 280)
	else
		logsBtn.Text = "Logs Off"
		logPanel.Size = UDim2.new(1, 0, 0, 0)
		logPanel.Visible = false
		widget.Size = Vector2.new(260, 180)
		widget.MinSize = Vector2.new(260, 180)
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
		log("⚠ Rejected: not activated")
		safeHttpPost(API_BASE .. "/result", { commandId = command.id, result = result, sessionId = SESSION_ID })
		return
	end

	log("→ " .. action)

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
					log("✓ " .. si:GetFullName())
				else
					result = { success = false, error = "Invalid script type" }
				end

			elseif action == "update_script" then
				local so = resolvePath(data.scriptPath)
				if so and so:IsA("LuaSourceContainer") then
					so.Source = data.code or ""
					result = { success = true, scriptPath = data.scriptPath }
					log("✓ Updated " .. data.scriptPath)
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
					log("✓ " .. obj:GetFullName())
				else
					result = { success = false, error = "Missing className" }
				end

			elseif action == "delete_object" then
				local obj = resolvePath(data.objectPath)
				if obj and obj ~= game then
					local p = obj:GetFullName()
					obj:Destroy()
					result = { success = true, deletedPath = p }
					log("✓ Deleted " .. p)
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
					log("✓ Info " .. obj:GetFullName())
				else
					result = { success = false, error = "Object not found" }
				end

			elseif action == "execute_luau" then
				local ok, r = pcall(function() return loadstring(data.code)() end)
				if ok then
					result = { success = true, result = tostring(r) or "nil" }
					log("✓ Executed")
				else
					result = { success = false, error = tostring(r) }
					log("✗ " .. tostring(r))
				end

			elseif action == "list_objects" then
				local parent = resolvePath(data.parentPath) or game
				local objects = {}
				for _, c in ipairs(parent:GetChildren()) do
					table.insert(objects, { name = c.Name, className = c.ClassName })
				end
				result = { success = true, objects = objects, parentPath = parent:GetFullName() }
				log("✓ Listed " .. #objects)

			else
				result = { success = false, error = "Unknown: " .. action }
			end
		end)

		safeHttpPost(API_BASE .. "/result", { commandId = command.id, result = result, sessionId = SESSION_ID })
		log("← " .. (result.success and "OK" or "ERR"))
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
				setActivated(false)
				log("⚠ Disconnected")
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
	instructionLabel.Text = "⚠️ Enable HTTP in Game Settings"
	instructionLabel.TextColor3 = C_RED
end

print("⚡ Codely Bridge " .. VERSION .. " loaded — INACTIVE")
print("🔒 Press Connect in the panel to activate")