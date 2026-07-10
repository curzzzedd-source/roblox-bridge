-- Codely Bridge — Auto-popup, Lemonade-style
-- Shows immediately when Studio opens a place

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local StudioService = game:GetService("StudioService")
local TweenService = game:GetService("TweenService")

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
local httpOK = pcall(function() return HttpService:GetAsync(SERVER_URL .. "/health") end)

-- ===== PLUGIN SETUP =====
local toolbar = plugin:CreateToolbar("Codely Bridge")

-- KEY: initialEnabled = true makes it pop up on startup!
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,  -- Floating window
	true,   -- initialEnabled = TRUE (auto-open)
	false,  -- initialEnabledShouldOverrideRestore
	280,    -- width
	160,    -- height
	280,    -- minWidth
	160     -- minHeight
)

local widget = plugin:CreateDockWidgetPluginGui("CodelyBridgePanel", widgetInfo)
widget.Title = "Codely Bridge " .. VERSION
widget.Name = "CodelyBridgePanel"

-- ===== COLORS =====
local C_BG = Color3.fromRGB(255, 255, 255)
local C_CARD = Color3.fromRGB(255, 255, 255)
local C_TEXT = Color3.fromRGB(30, 30, 30)
local C_SUB = Color3.fromRGB(130, 130, 130)
local C_BLUE = Color3.fromRGB(59, 130, 246)
local C_GREEN = Color3.fromRGB(34, 197, 94)
local C_RED = Color3.fromRGB(239, 68, 68)
local C_GREY = Color3.fromRGB(100, 100, 100)
local C_DARKGREY = Color3.fromRGB(55, 55, 55)
local C_BORDER = Color3.fromRGB(230, 230, 230)
local C_LIGHT = Color3.fromRGB(245, 245, 245)

-- Root
local root = Instance.new("Frame")
root.Size = UDim2.new(1, 0, 1, 0)
root.BackgroundColor3 = C_LIGHT
root.BorderSizePixel = 0
root.Parent = widget

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 10)
pad.PaddingBottom = UDim.new(0, 10)
pad.PaddingLeft = UDim.new(0, 12)
pad.PaddingRight = UDim.new(0, 12)
pad.Parent = root

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.Parent = root

-- ===== CARD =====
local card = Instance.new("Frame")
card.Size = UDim2.new(1, 0, 0, 120)
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
cardPad.PaddingTop = UDim.new(0, 10)
cardPad.PaddingBottom = UDim.new(0, 10)
cardPad.PaddingLeft = UDim.new(0, 12)
cardPad.PaddingRight = UDim.new(0, 12)
cardPad.Parent = card

local cardLayout = Instance.new("UIListLayout")
cardLayout.Padding = UDim.new(0, 5)
cardLayout.Parent = card

-- Row 1: Icon + Name + Toggle
local row1 = Instance.new("Frame")
row1.Size = UDim2.new(1, 0, 0, 32)
row1.BackgroundTransparency = 1
row1.Parent = card

-- Icon box
local iconBox = Instance.new("Frame")
iconBox.Size = UDim2.new(0, 32, 0, 32)
iconBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
iconBox.BorderSizePixel = 0
iconBox.Parent = row1

local ic = Instance.new("UICorner")
ic.CornerRadius = UDim.new(0, 8)
ic.Parent = iconBox

local iconLbl = Instance.new("TextLabel")
iconLbl.Size = UDim2.new(1, 0, 1, 0)
iconLbl.BackgroundTransparency = 1
iconLbl.Text = "⚡"
iconLbl.TextSize = 18
iconLbl.TextColor3 = C_BG
iconLbl.Parent = iconBox

-- Name + author
local nameCol = Instance.new("Frame")
nameCol.Size = UDim2.new(1, -100, 1, 0)
nameCol.Position = UDim2.new(0, 40, 0, 0)
nameCol.BackgroundTransparency = 1
nameCol.Parent = row1

local nameLbl = Instance.new("TextLabel")
nameLbl.Size = UDim2.new(1, 0, 0, 18)
nameLbl.BackgroundTransparency = 1
nameLbl.Text = "Codely Bridge"
nameLbl.TextSize = 14
nameLbl.TextColor3 = C_TEXT
nameLbl.Font = Enum.Font.GothamBold
nameLbl.TextXAlignment = Enum.TextXAlignment.Left
nameLbl.Parent = nameCol

local authorLbl = Instance.new("TextLabel")
authorLbl.Size = UDim2.new(1, 0, 0, 14)
authorLbl.BackgroundTransparency = 1
authorLbl.Text = "curzzzedd-source"
authorLbl.TextSize = 12
authorLbl.TextColor3 = C_BLUE
authorLbl.Font = Enum.Font.GothamMedium
authorLbl.TextXAlignment = Enum.TextXAlignment.Left
authorLbl.Parent = nameCol

-- Toggle switch
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0, 40, 0, 22)
toggle.BackgroundColor3 = C_GREY
toggle.BorderSizePixel = 0
toggle.Text = ""
toggle.AutoButtonColor = false
toggle.Parent = row1
toggle.Position = UDim2.new(1, -40, 0.5, -11)

local tc = Instance.new("UICorner")
tc.CornerRadius = UDim.new(1, 0)
tc.Parent = toggle

local knob = Instance.new("Frame")
knob.Size = UDim2.new(0, 16, 0, 16)
knob.Position = UDim2.new(0, 3, 0.5, -8)
knob.BackgroundColor3 = C_BG
knob.BorderSizePixel = 0
knob.Parent = toggle

local kc = Instance.new("UICorner")
kc.CornerRadius = UDim.new(1, 0)
kc.Parent = knob

-- Row 2: Description
local descLbl = Instance.new("TextLabel")
descLbl.Size = UDim2.new(1, 0, 0, 14)
descLbl.BackgroundTransparency = 1
descLbl.Text = "Connect Roblox Studio to Codely CLI"
descLbl.TextSize = 12
descLbl.TextColor3 = C_SUB
descLbl.Font = Enum.Font.Gotham
descLbl.TextXAlignment = Enum.TextXAlignment.Left
descLbl.Parent = card

-- Row 3: Permissions
local permLbl = Instance.new("TextLabel")
permLbl.Size = UDim2.new(1, 0, 0, 12)
permLbl.BackgroundTransparency = 1
permLbl.Text = "HTTP Requests ✓  |  Script Injection ✓"
permLbl.TextSize = 10
permLbl.TextColor3 = C_GREY
permLbl.Font = Enum.Font.GothamMedium
permLbl.TextXAlignment = Enum.TextXAlignment.Left
permLbl.Parent = card

-- Row 4: Status
local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, 0, 0, 14)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "● Inactive"
statusLbl.TextSize = 11
statusLbl.TextColor3 = C_GREY
statusLbl.Font = Enum.Font.GothamMedium
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Parent = card

-- ===== STATE =====
local isOn = false
local isConn = false
local seen = {}

-- ===== HTTP =====
local function get(url)
	return pcall(function() return HttpService:RequestAsync({ Url = url, Method = "GET" }) end)
end

local function post(url, body)
	return pcall(function()
		return HttpService:RequestAsync({
			Url = url, Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode(body),
		})
	end)
end

local function register()
	local i = getPlaceInfo()
	post(API_BASE .. "/register", {
		sessionId = SESSION_ID, placeId = i.placeId,
		placeName = i.placeName, gameId = i.gameId, activated = isOn,
	})
end

local function checkConn()
	local ok, r = get(API_BASE .. "/commands?sessionId=" .. SESSION_ID)
	if ok and r.StatusCode == 200 then
		isConn = true
		register()
		return true
	end
	isConn = false
	return false
end

-- ===== TOGGLE =====
local function flip(on)
	isOn = on
	local tw = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	if on then
		TweenService:Create(toggle, tw, { BackgroundColor3 = C_GREEN }):Play()
		TweenService:Create(knob, tw, { Position = UDim2.new(0, 21, 0.5, -8) }):Play()
		statusLbl.Text = "● Connected"
		statusLbl.TextColor3 = C_GREEN
		register()
		post(API_BASE .. "/heartbeat", { sessionId = SESSION_ID, placeInfo = getPlaceInfo(), activated = true })
	else
		TweenService:Create(toggle, tw, { BackgroundColor3 = C_GREY }):Play()
		TweenService:Create(knob, tw, { Position = UDim2.new(0, 3, 0.5, -8) }):Play()
		statusLbl.Text = "● Inactive"
		statusLbl.TextColor3 = C_GREY
		post(API_BASE .. "/heartbeat", { sessionId = SESSION_ID, placeInfo = getPlaceInfo(), activated = false })
	end
end

toggle.MouseButton1Click:Connect(function()
	if not isConn then checkConn() end
	if isConn then
		flip(not isOn)
	else
		statusLbl.Text = "● Cannot reach server"
		statusLbl.TextColor3 = C_RED
		task.wait(2)
		if not isOn then
			statusLbl.Text = "● Inactive"
			statusLbl.TextColor3 = C_GREY
		end
	end
end)

-- ===== EXECUTE =====
local function resolve(pathStr)
	if not pathStr or pathStr == "" then return game end
	local o = game
	for p in string.gmatch(pathStr, "([^%.]+)") do
		if p ~= "game" then
			o = o:FindFirstChild(p)
			if not o then return nil end
		end
	end
	return o
end

local function exec(cmd)
	local a = cmd.action
	local d = cmd.data or {}
	local r = { success = false }

	if not isOn then
		r = { success = false, error = "Not activated" }
		post(API_BASE .. "/result", { commandId = cmd.id, result = r, sessionId = SESSION_ID })
		return
	end

	task.spawn(function()
		pcall(function()
			if a == "create_script" then
				local st = d.scriptType or "Script"
				local p = resolve(d.parentPath) or game
				local s
				if st == "Script" then s = Instance.new("Script")
				elseif st == "LocalScript" then s = Instance.new("LocalScript")
				elseif st == "ModuleScript" then s = Instance.new("ModuleScript") end
				if s then
					s.Name = d.name or "NewScript"
					s.Parent = p
					s.Source = d.code or ""
					r = { success = true, scriptPath = s:GetFullName(), scriptType = st }
				else r = { success = false, error = "Bad type" } end

			elseif a == "update_script" then
				local s = resolve(d.scriptPath)
				if s and s:IsA("LuaSourceContainer") then
					s.Source = d.code or ""
					r = { success = true }
				else r = { success = false, error = "Not found" } end

			elseif a == "create_object" then
				local p = resolve(d.parentPath) or game
				if d.className then
					local o = Instance.new(d.className)
					o.Name = d.name or d.className
					o.Parent = p
					if d.properties then
						for k, v in pairs(d.properties) do pcall(function() o[k] = v end) end
					end
					r = { success = true, objectPath = o:GetFullName() }
				else r = { success = false, error = "No className" } end

			elseif a == "delete_object" then
				local o = resolve(d.objectPath)
				if o and o ~= game then
					o:Destroy()
					r = { success = true }
				else r = { success = false, error = "Not found" } end

			elseif a == "get_object_info" then
				local o = resolve(d.objectPath)
				if o then
					local i = { className = o.ClassName, name = o.Name, path = o:GetFullName() }
					if o:IsA("BasePart") then
						i.position = { x = o.Position.X, y = o.Position.Y, z = o.Position.Z }
						i.size = { x = o.Size.X, y = o.Size.Y, z = o.Size.Z }
					elseif o:IsA("LuaSourceContainer") then
						i.source = o.Source
					end
					r = { success = true, info = i }
				else r = { success = false, error = "Not found" } end

			elseif a == "execute_luau" then
				local ok, res = pcall(function() return loadstring(d.code)() end)
				if ok then r = { success = true, result = tostring(res) }
				else r = { success = false, error = tostring(res) } end

			elseif a == "list_objects" then
				local p = resolve(d.parentPath) or game
				local list = {}
				for _, c in ipairs(p:GetChildren()) do
					table.insert(list, { name = c.Name, className = c.ClassName })
				end
				r = { success = true, objects = list, parentPath = p:GetFullName() }
			else
				r = { success = false, error = "Unknown: " .. a }
			end
		end)
		post(API_BASE .. "/result", { commandId = cmd.id, result = r, sessionId = SESSION_ID })
	end)
end

-- ===== POLL =====
local last = 0
RunService.Heartbeat:Connect(function()
	local t = tick()
	if t - last < 1 then return end
	last = t

	if not isConn then checkConn() return end
	if not isOn then return end

	task.spawn(function()
		local ok, res = get(API_BASE .. "/commands?sessionId=" .. SESSION_ID)
		if ok and res.StatusCode == 200 then
			local p, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
			if p and data.commands then
				for _, c in ipairs(data.commands) do
					if not seen[c.id] then
						seen[c.id] = true
						exec(c)
					end
				end
				if #data.commands > 0 then
					local ids = {}
					for _, c in ipairs(data.commands) do table.insert(ids, c.id) end
					post(API_BASE .. "/commands/clear", { commandIds = ids, sessionId = SESSION_ID })
				end
			end
		else
			if isConn then isConn = false flip(false) end
		end
	end)
end)

-- Heartbeat
task.spawn(function()
	while true do
		if isConn then
			post(API_BASE .. "/heartbeat", { sessionId = SESSION_ID, placeInfo = getPlaceInfo(), activated = isOn })
		end
		task.wait(15)
	end
end)

-- Init
task.spawn(function()
	task.wait(2)
	checkConn()
end)

-- Toolbar button
local btn = toolbar:CreateButton("Codely Bridge", "Toggle panel visibility")
btn.Click:Connect(function() widget.Enabled = not widget.Enabled end)

-- Plugin lifecycle — re-check on place change
plugin.Unloading:Connect(function()
	post(API_BASE .. "/heartbeat", { sessionId = SESSION_ID, placeInfo = getPlaceInfo(), activated = false })
end)

if not httpOK then
	statusLbl.Text = "● Enable HTTP in Game Settings"
	statusLbl.TextColor3 = C_RED
end

print("⚡ Codely Bridge " .. VERSION .. " — Toggle to connect")