-- Codely Bridge Plugin v1.0.0
-- Auto-pops up on startup, shows in Manage Plugins

local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local StudioService = game:GetService("StudioService")

local SERVER_URL = "https://web-production-f04e1.up.railway.app"
local API_BASE = SERVER_URL .. "/api"
local VERSION = "v1.0.0"

-- ===== Colors =====
local WHITE = Color3.fromRGB(255, 255, 255)
local TEXT = Color3.fromRGB(30, 30, 30)
local SUB = Color3.fromRGB(130, 130, 130)
local BLUE = Color3.fromRGB(59, 130, 246)
local GREEN = Color3.fromRGB(34, 197, 94)
local RED = Color3.fromRGB(239, 68, 68)
local GREY = Color3.fromRGB(100, 100, 100)
local BORDER = Color3.fromRGB(230, 230, 230)
local LIGHT = Color3.fromRGB(245, 245, 245)

-- ===== Place info =====
local function getPlaceInfo()
	local pid = game.PlaceId
	local pname = "Place_" .. tostring(pid)
	pcall(function()
		if StudioService.ActiveScript then
			pname = StudioService.ActiveScript.Name
		end
	end)
	return {
		placeId = pid, placeName = pname, gameId = game.GameId,
		sessionId = tostring(pid) .. "_" .. tostring(pid),
	}
end

local placeInfo = getPlaceInfo()
local SID = placeInfo.sessionId
local isOn = false
local isConn = false
local seen = {}

-- ===== HTTP helpers =====
local function httpGet(url)
	return pcall(function()
		return HttpService:RequestAsync({ Url = url, Method = "GET" })
	end)
end

local function httpPost(url, body)
	return pcall(function()
		return HttpService:RequestAsync({
			Url = url, Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode(body),
		})
	end)
end

local function register()
	httpPost(API_BASE .. "/register", {
		sessionId = SID, placeId = placeInfo.placeId,
		placeName = placeInfo.placeName, gameId = placeInfo.gameId,
		activated = isOn,
	})
end

-- ===== Toolbar button =====
local toolbar = plugin:CreateToolbar("Codely Bridge")
local toolbarBtn = toolbar:CreateButton(
	"Codely Bridge",
	"Open Codely Bridge panel",
	"rbxasset://textures/ui/GuiImagePlaceholder.png"
)

-- ===== Widget — Right dock, auto-open =====
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Right,  -- Right side, no drag bugs
	true,   -- initialEnabled = TRUE → pops up on startup
	false,  -- override restore
	280,    -- width
	150,    -- height
	280,    -- minWidth
	150     -- minHeight
)

local widget = plugin:CreateDockWidgetPluginGui("CodelyBridgePanel", widgetInfo)
widget.Title = "Codely Bridge"

-- Close button on toolbar opens/closes widget
toolbarBtn.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

-- ===== Build UI =====
local root = Instance.new("Frame")
root.Size = UDim2.new(1, 0, 1, 0)
root.BackgroundColor3 = LIGHT
root.BorderSizePixel = 0
root.Parent = widget

local rp = Instance.new("UIPadding")
rp.PaddingTop = UDim.new(0, 8)
rp.PaddingBottom = UDim.new(0, 8)
rp.PaddingLeft = UDim.new(0, 10)
rp.PaddingRight = UDim.new(0, 10)
rp.Parent = root

local rl = Instance.new("UIListLayout")
rl.Padding = UDim.new(0, 6)
rl.Parent = root

-- Card
local card = Instance.new("Frame")
card.Size = UDim2.new(1, 0, 0, 110)
card.BackgroundColor3 = WHITE
card.BorderSizePixel = 0
card.Parent = root

local cc = Instance.new("UICorner")
cc.CornerRadius = UDim.new(0, 8)
cc.Parent = card

local cs = Instance.new("UIStroke")
cs.Color = BORDER
cs.Thickness = 1
cs.Parent = card

local cp = Instance.new("UIPadding")
cp.PaddingTop = UDim.new(0, 10)
cp.PaddingBottom = UDim.new(0, 10)
cp.PaddingLeft = UDim.new(0, 10)
cp.PaddingRight = UDim.new(0, 10)
cp.Parent = card

local cl = Instance.new("UIListLayout")
cl.Padding = UDim.new(0, 4)
cl.Parent = card

-- Row 1: Icon + Name + Toggle
local row1 = Instance.new("Frame")
row1.Size = UDim2.new(1, 0, 0, 30)
row1.BackgroundTransparency = 1
row1.Parent = card

local iconBox = Instance.new("Frame")
iconBox.Size = UDim2.new(0, 30, 0, 30)
iconBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
iconBox.BorderSizePixel = 0
iconBox.Parent = row1

local ic = Instance.new("UICorner")
ic.CornerRadius = UDim.new(0, 7)
ic.Parent = iconBox

local iconTxt = Instance.new("TextLabel")
iconTxt.Size = UDim2.new(1, 0, 1, 0)
iconTxt.BackgroundTransparency = 1
iconTxt.Text = "⚡"
iconTxt.TextSize = 16
iconTxt.TextColor3 = WHITE
iconTxt.Parent = iconBox

local nameCol = Instance.new("Frame")
nameCol.Size = UDim2.new(1, -90, 1, 0)
nameCol.Position = UDim2.new(0, 38, 0, 0)
nameCol.BackgroundTransparency = 1
nameCol.Parent = row1

local nameLbl = Instance.new("TextLabel")
nameLbl.Size = UDim2.new(1, 0, 0, 17)
nameLbl.BackgroundTransparency = 1
nameLbl.Text = "Codely Bridge"
nameLbl.TextSize = 14
nameLbl.TextColor3 = TEXT
nameLbl.Font = Enum.Font.GothamBold
nameLbl.TextXAlignment = Enum.TextXAlignment.Left
nameLbl.Parent = nameCol

local authLbl = Instance.new("TextLabel")
authLbl.Size = UDim2.new(1, 0, 0, 13)
authLbl.BackgroundTransparency = 1
authLbl.Text = "curzzzedd-source"
authLbl.TextSize = 11
authLbl.TextColor3 = BLUE
authLbl.Font = Enum.Font.GothamMedium
authLbl.TextXAlignment = Enum.TextXAlignment.Left
authLbl.Parent = nameCol

-- Toggle switch
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0, 38, 0, 20)
toggle.BackgroundColor3 = GREY
toggle.BorderSizePixel = 0
toggle.Text = ""
toggle.AutoButtonColor = false
toggle.Parent = row1
toggle.Position = UDim2.new(1, -38, 0.5, -10)

local tc = Instance.new("UICorner")
tc.CornerRadius = UDim.new(1, 0)
tc.Parent = toggle

local knob = Instance.new("Frame")
knob.Size = UDim2.new(0, 14, 0, 14)
knob.Position = UDim2.new(0, 3, 0.5, -7)
knob.BackgroundColor3 = WHITE
knob.BorderSizePixel = 0
knob.Parent = toggle

local kc = Instance.new("UICorner")
kc.CornerRadius = UDim.new(1, 0)
kc.Parent = knob

-- Row 2: Description
local descLbl = Instance.new("TextLabel")
descLbl.Size = UDim2.new(1, 0, 0, 13)
descLbl.BackgroundTransparency = 1
descLbl.Text = "Connect Studio to Codely CLI"
descLbl.TextSize = 11
descLbl.TextColor3 = SUB
descLbl.Font = Enum.Font.Gotham
descLbl.TextXAlignment = Enum.TextXAlignment.Left
descLbl.Parent = card

-- Row 3: Permissions
local permLbl = Instance.new("TextLabel")
permLbl.Size = UDim2.new(1, 0, 0, 11)
permLbl.BackgroundTransparency = 1
permLbl.Text = "HTTP Requests ✓ | Script Injection ✓"
permLbl.TextSize = 10
permLbl.TextColor3 = GREY
permLbl.Font = Enum.Font.GothamMedium
permLbl.TextXAlignment = Enum.TextXAlignment.Left
permLbl.Parent = card

-- Row 4: Status
local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, 0, 0, 13)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "● Inactive"
statusLbl.TextSize = 11
statusLbl.TextColor3 = GREY
statusLbl.Font = Enum.Font.GothamMedium
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Parent = card

-- ===== Toggle logic =====
local function flip(on)
	isOn = on
	local tw = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	if on then
		TweenService:Create(toggle, tw, { BackgroundColor3 = GREEN }):Play()
		TweenService:Create(knob, tw, { Position = UDim2.new(0, 21, 0.5, -7) }):Play()
		statusLbl.Text = "● Connected"
		statusLbl.TextColor3 = GREEN
		register()
		httpPost(API_BASE .. "/heartbeat", { sessionId = SID, placeInfo = getPlaceInfo(), activated = true })
	else
		TweenService:Create(toggle, tw, { BackgroundColor3 = GREY }):Play()
		TweenService:Create(knob, tw, { Position = UDim2.new(0, 3, 0.5, -7) }):Play()
		statusLbl.Text = "● Inactive"
		statusLbl.TextColor3 = GREY
		httpPost(API_BASE .. "/heartbeat", { sessionId = SID, placeInfo = getPlaceInfo(), activated = false })
	end
end

toggle.MouseButton1Click:Connect(function()
	if not isConn then
		local ok, res = httpGet(API_BASE .. "/commands?sessionId=" .. SID)
		if ok and res.StatusCode == 200 then
			isConn = true
			register()
		else
			statusLbl.Text = "● Cannot reach server"
			statusLbl.TextColor3 = RED
			return
		end
	end
	flip(not isOn)
end)

-- ===== Resolve path =====
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

-- ===== Execute command =====
local function exec(cmd)
	local a = cmd.action
	local d = cmd.data or {}
	local r = { success = false }

	if not isOn then
		r = { success = false, error = "Not activated" }
		httpPost(API_BASE .. "/result", { commandId = cmd.id, result = r, sessionId = SID })
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
		httpPost(API_BASE .. "/result", { commandId = cmd.id, result = r, sessionId = SID })
	end)
end

-- ===== Polling — using task.spawn loop, NOT Heartbeat =====
-- This prevents the drag/screen bug
task.spawn(function()
	while true do
		task.wait(1)

		if not isConn then
			local ok, res = httpGet(API_BASE .. "/commands?sessionId=" .. SID)
			if ok and res.StatusCode == 200 then
				isConn = true
				register()
			end
		end

		if isConn and isOn then
			local ok, res = httpGet(API_BASE .. "/commands?sessionId=" .. SID)
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
						httpPost(API_BASE .. "/commands/clear", { commandIds = ids, sessionId = SID })
					end
				end
			else
				isConn = false
				if isOn then flip(false) end
			end
		end
	end
end)

-- ===== Heartbeat loop =====
task.spawn(function()
	while true do
		task.wait(15)
		if isConn then
			httpPost(API_BASE .. "/heartbeat", { sessionId = SID, placeInfo = getPlaceInfo(), activated = isOn })
		end
	end
end)

-- ===== Init =====
task.spawn(function()
	task.wait(2)
	local ok, res = httpGet(API_BASE .. "/commands?sessionId=" .. SID)
	if ok and res.StatusCode == 200 then
		isConn = true
		register()
		statusLbl.Text = "● Ready — toggle to connect"
		statusLbl.TextColor3 = SUB
	else
		statusLbl.Text = "● Server unreachable"
		statusLbl.TextColor3 = RED
	end
end)

-- Cleanup on unload
plugin.Unloading:Connect(function()
	httpPost(API_BASE .. "/heartbeat", { sessionId = SID, placeInfo = getPlaceInfo(), activated = false })
end)

print("⚡ Codely Bridge " .. VERSION .. " loaded — toggle to connect")