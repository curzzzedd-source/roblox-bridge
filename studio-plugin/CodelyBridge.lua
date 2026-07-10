--!strict
-- Codely Bridge Plugin v1.1.0
-- Stable, no-lag, proper Roblox Studio plugin

local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local SERVER = "https://web-production-f04e1.up.railway.app"
local API = SERVER .. "/api"
local VERSION = "v1.1.0"

-- Colors
local WHITE = Color3.fromRGB(255, 255, 255)
local TEXT = Color3.fromRGB(30, 30, 30)
local SUB = Color3.fromRGB(130, 130, 130)
local BLUE = Color3.fromRGB(59, 130, 246)
local GREEN = Color3.fromRGB(34, 197, 94)
local RED = Color3.fromRGB(239, 68, 68)
local GREY = Color3.fromRGB(100, 100, 100)
local BORDER = Color3.fromRGB(230, 230, 230)
local LIGHT = Color3.fromRGB(245, 245, 245)

-- State
local activated = false
local connected = false
local seenCmds: {[string]: boolean} = {}
local running = false

-- Session
local function getSessionId()
	return tostring(game.PlaceId) .. "_" .. tostring(game.PlaceId)
end
local SID = getSessionId()

-- HTTP (with timeout to prevent blocking)
local function httpGet(url)
	return pcall(function()
		return HttpService:RequestAsync({ Url = url, Method = "GET", Timeout = 5 })
	end)
end

local function httpPost(url, body)
	return pcall(function()
		return HttpService:RequestAsync({
			Url = url, Method = "POST", Timeout = 5,
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode(body),
		})
	end)
end

local function register()
	httpPost(API .. "/register", {
		sessionId = SID, placeId = game.PlaceId,
		placeName = "Place_" .. tostring(game.PlaceId),
		gameId = game.GameId, activated = activated,
	})
end

-- ===== TOOLBAR =====
local toolbar = plugin:CreateToolbar("Codely Bridge")
local btn = toolbar:CreateButton("Codely Bridge", "Toggle Codely Bridge panel", "")

-- ===== WIDGET =====
local info = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Right,
	true,   -- auto-open on startup
	false,
	260, 130, 260, 130
)
local widget = plugin:CreateDockWidgetPluginGui("CodelyBridgeV2", info)
widget.Title = "Codely Bridge " .. VERSION

btn.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

-- Only run when widget is open
widget:GetPropertyChangedSignal("Enabled"):Connect(function()
	if widget.Enabled and activated and not running then
		running = true
	elseif not widget.Enabled then
		running = false
	end
end)

-- ===== BUILD UI =====
local root = Instance.new("Frame")
root.Size = UDim2.new(1, 0, 1, 0)
root.BackgroundColor3 = LIGHT
root.BorderSizePixel = 0
root.Parent = widget

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 8)
pad.PaddingBottom = UDim.new(0, 8)
pad.PaddingLeft = UDim.new(0, 10)
pad.PaddingRight = UDim.new(0, 10)
pad.Parent = root

local card = Instance.new("Frame")
card.Size = UDim2.new(1, 0, 0, 110)
card.BackgroundColor3 = WHITE
card.BorderSizePixel = 0
card.Parent = root

local cc = Instance.new("UICorner")
cc.CornerRadius = UDim.new(0, 8)
cc.Parent = card

local stroke = Instance.new("UIStroke")
stroke.Color = BORDER
stroke.Thickness = 1
stroke.Parent = card

local cp = Instance.new("UIPadding")
cp.PaddingTop = UDim.new(0, 8)
cp.PaddingBottom = UDim.new(0, 8)
cp.PaddingLeft = UDim.new(0, 10)
cp.PaddingRight = UDim.new(0, 10)
cp.Parent = card

local cl = Instance.new("UIListLayout")
cl.Padding = UDim.new(0, 5)
cl.Parent = card

-- Row 1: Icon + Name + Toggle
local row1 = Instance.new("Frame")
row1.Size = UDim2.new(1, 0, 0, 28)
row1.BackgroundTransparency = 1
row1.Parent = card

local icon = Instance.new("Frame")
icon.Size = UDim2.new(0, 28, 0, 28)
icon.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
icon.BorderSizePixel = 0
icon.Parent = row1
Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 6)

local iconTxt = Instance.new("TextLabel")
iconTxt.Size = UDim2.new(1, 0, 1, 0)
iconTxt.BackgroundTransparency = 1
iconTxt.Text = "⚡"
iconTxt.TextSize = 16
iconTxt.TextColor3 = WHITE
iconTxt.Parent = icon

local nameCol = Instance.new("Frame")
nameCol.Size = UDim2.new(1, -84, 1, 0)
nameCol.Position = UDim2.new(0, 36, 0, 0)
nameCol.BackgroundTransparency = 1
nameCol.Parent = row1

local nameLbl = Instance.new("TextLabel")
nameLbl.Size = UDim2.new(1, 0, 0, 16)
nameLbl.BackgroundTransparency = 1
nameLbl.Text = "Codely Bridge"
nameLbl.TextSize = 13
nameLbl.TextColor3 = TEXT
nameLbl.Font = Enum.Font.GothamBold
nameLbl.TextXAlignment = Enum.TextXAlignment.Left
nameLbl.Parent = nameCol

local authLbl = Instance.new("TextLabel")
authLbl.Size = UDim2.new(1, 0, 0, 12)
authLbl.BackgroundTransparency = 1
authLbl.Text = "curzzzedd-source"
authLbl.TextSize = 10
authLbl.TextColor3 = BLUE
authLbl.Font = Enum.Font.GothamMedium
authLbl.TextXAlignment = Enum.TextXAlignment.Left
authLbl.Parent = nameCol

-- Toggle
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0, 36, 0, 20)
toggle.BackgroundColor3 = GREY
toggle.BorderSizePixel = 0
toggle.Text = ""
toggle.AutoButtonColor = false
toggle.Parent = row1
toggle.Position = UDim2.new(1, -36, 0.5, -10)
Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)

local knob = Instance.new("Frame")
knob.Size = UDim2.new(0, 14, 0, 14)
knob.Position = UDim2.new(0, 3, 0.5, -7)
knob.BackgroundColor3 = WHITE
knob.BorderSizePixel = 0
knob.Parent = toggle
Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

-- Row 2: Description
local descLbl = Instance.new("TextLabel")
descLbl.Size = UDim2.new(1, 0, 0, 12)
descLbl.BackgroundTransparency = 1
descLbl.Text = "Connect Studio to Codely CLI"
descLbl.TextSize = 10
descLbl.TextColor3 = SUB
descLbl.Font = Enum.Font.Gotham
descLbl.TextXAlignment = Enum.TextXAlignment.Left
descLbl.Parent = card

-- Row 3: Permissions
local permLbl = Instance.new("TextLabel")
permLbl.Size = UDim2.new(1, 0, 0, 11)
permLbl.BackgroundTransparency = 1
permLbl.Text = "HTTP ✓ | Script Injection ✓"
permLbl.TextSize = 9
permLbl.TextColor3 = GREY
permLbl.Font = Enum.Font.GothamMedium
permLbl.TextXAlignment = Enum.TextXAlignment.Left
permLbl.Parent = card

-- Row 4: Status
local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, 0, 0, 13)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "● Inactive"
statusLbl.TextSize = 10
statusLbl.TextColor3 = GREY
statusLbl.Font = Enum.Font.GothamMedium
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Parent = card

-- ===== TOGGLE =====
local function setToggle(on)
	activated = on
	local tw = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	if on then
		TweenService:Create(toggle, tw, { BackgroundColor3 = GREEN }):Play()
		TweenService:Create(knob, tw, { Position = UDim2.new(0, 19, 0.5, -7) }):Play()
		statusLbl.Text = "● Connected"
		statusLbl.TextColor3 = GREEN
		running = true
		register()
		httpPost(API .. "/heartbeat", { sessionId = SID, activated = true })
	else
		TweenService:Create(toggle, tw, { BackgroundColor3 = GREY }):Play()
		TweenService:Create(knob, tw, { Position = UDim2.new(0, 3, 0.5, -7) }):Play()
		statusLbl.Text = "● Inactive"
		statusLbl.TextColor3 = GREY
		running = false
		httpPost(API .. "/heartbeat", { sessionId = SID, activated = false })
	end
end

toggle.MouseButton1Click:Connect(function()
	if not connected then
		local ok, res = httpGet(API .. "/commands?sessionId=" .. SID)
		if ok and res.StatusCode == 200 then
			connected = true
			register()
		else
			statusLbl.Text = "● Server unreachable"
			statusLbl.TextColor3 = RED
			task.wait(2)
			if not activated then
				statusLbl.Text = "● Inactive"
				statusLbl.TextColor3 = GREY
			end
			return
		end
	end
	setToggle(not activated)
end)

-- ===== RESOLVE PATH =====
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

-- ===== EXECUTE =====
local function exec(cmd)
	local a = cmd.action
	local d = cmd.data or {}
	local r = { success = false }

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
					r = { success = true, scriptPath = s:GetFullName() }
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
				r = { success = true, objects = list }
			else
				r = { success = false, error = "Unknown: " .. a }
			end
		end)
		httpPost(API .. "/result", { commandId = cmd.id, result = r, sessionId = SID })
	end)
end

-- ===== MAIN LOOP — only runs when activated =====
task.spawn(function()
	while true do
		task.wait(1.5)
		-- STOP if widget closed or not activated — no lag
		if not widget.Enabled or not activated or not connected then
			continue
		end

		local ok, res = httpGet(API .. "/commands?sessionId=" .. SID)
		if ok and res.StatusCode == 200 then
			local p, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
			if p and data.commands then
				for _, c in ipairs(data.commands) do
					if not seenCmds[c.id] then
						seenCmds[c.id] = true
						exec(c)
					end
				end
				if #data.commands > 0 then
					local ids = {}
					for _, c in ipairs(data.commands) do table.insert(ids, c.id) end
					httpPost(API .. "/commands/clear", { commandIds = ids, sessionId = SID })
				end
			end
		else
			connected = false
			if activated then setToggle(false) end
		end
	end
end)

-- ===== HEARTBEAT =====
task.spawn(function()
	while true do
		task.wait(15)
		if connected and activated and widget.Enabled then
			httpPost(API .. "/heartbeat", { sessionId = SID, activated = true })
		end
	end
end)

-- ===== INIT =====
task.spawn(function()
	task.wait(3)
	local ok, res = httpGet(API .. "/commands?sessionId=" .. SID)
	if ok and res.StatusCode == 200 then
		connected = true
		register()
		statusLbl.Text = "● Ready — toggle to connect"
		statusLbl.TextColor3 = SUB
	else
		statusLbl.Text = "● Server unreachable"
		statusLbl.TextColor3 = RED
	end
end)

-- Cleanup
plugin.Unloading:Connect(function()
	httpPost(API .. "/heartbeat", { sessionId = SID, activated = false })
end)

print("⚡ Codely Bridge " .. VERSION)