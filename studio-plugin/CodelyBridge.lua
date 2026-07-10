-- Codely Bridge — Bare minimum, works 100%
local HttpService = game:GetService("HttpService")

local SERVER = "https://web-production-f04e1.up.railway.app"
local API = SERVER .. "/api"
local SID = tostring(game.PlaceId)

local activated = false
local connected = false
local seen = {}

local function request(method, path, body)
	local ok, res = pcall(function()
		local reqData = {
			Url = API .. path,
			Method = method,
			Headers = { ["Content-Type"] = "application/json" },
		}
		if body then
			reqData.Body = HttpService:JSONEncode(body)
		end
		return HttpService:RequestAsync(reqData)
	end)
	if ok and res and res.Success then
		local p, d = pcall(function() return HttpService:JSONDecode(res.Body) end)
		if p then return d end
	end
	return nil
end

local function post(path, body)
	return request("POST", path, body)
end

local function get(path)
	return request("GET", path, nil)
end

-- Register
post("/register", { sessionId = SID, placeId = game.PlaceId, placeName = "Place", gameId = game.GameId, activated = false })

-- Toolbar
local toolbar = plugin:CreateToolbar("Codely Bridge")
local btn = toolbar:CreateButton("Connect", "Click to connect Codely Bridge", "")

-- Simple widget
local info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right, true, false, 200, 80, 200, 80)
local widget = plugin:CreateDockWidgetPluginGui("CodelyBridge", info)
widget.Title = "Codely Bridge"

local frame = Instance.new("Frame")
frame.Size = UDim2.new(1, 0, 1, 0)
frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
frame.Parent = widget

local button = Instance.new("TextButton")
button.Size = UDim2.new(1, -20, 0, 50)
button.Position = UDim2.new(0, 10, 0, 15)
button.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
button.Text = "CONNECT"
button.TextSize = 20
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.GothamBold
button.Parent = frame
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

btn.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

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
				r = { success = true, path = s:GetFullName() }
			end

		elseif a == "update_script" then
			local s = resolve(d.scriptPath)
			if s and s:IsA("LuaSourceContainer") then
				s.Source = d.code or ""
				r = { success = true }
			end

		elseif a == "create_object" then
			local p = resolve(d.parentPath) or game
			if d.className then
				local o = Instance.new(d.className)
				o.Name = d.name or d.className
				o.Parent = p
				if d.properties then
					for k, v in pairs(d.properties) do pcall(function() o[k] = v end) end
				end
				r = { success = true, path = o:GetFullName() }
			end

		elseif a == "delete_object" then
			local o = resolve(d.objectPath)
			if o and o ~= game then
				o:Destroy()
				r = { success = true }
			end

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
			end

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
		end
	end)

	post("/result", { commandId = cmd.id, result = r, sessionId = SID })
end

-- Toggle
button.MouseButton1Click:Connect(function()
	activated = not activated
	if activated then
		button.Text = "DISCONNECT"
		button.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
		connected = true
		post("/register", { sessionId = SID, placeId = game.PlaceId, placeName = "Place", gameId = game.GameId, activated = true })
		post("/heartbeat", { sessionId = SID, activated = true })
	else
		button.Text = "CONNECT"
		button.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
		post("/heartbeat", { sessionId = SID, activated = false })
	end
end)

-- Poll loop — only when activated
task.spawn(function()
	while true do
		task.wait(2)
		if not activated or not widget.Enabled then continue end

		local data = get("/commands?sessionId=" .. SID)
		if data and data.commands then
			for _, c in ipairs(data.commands) do
				if not seen[c.id] then
					seen[c.id] = true
					exec(c)
				end
			end
			if #data.commands > 0 then
				local ids = {}
				for _, c in ipairs(data.commands) do table.insert(ids, c.id) end
				post("/commands/clear", { commandIds = ids, sessionId = SID })
			end
		end
	end
end)

-- Heartbeat
task.spawn(function()
	while true do
		task.wait(15)
		if activated then
			post("/heartbeat", { sessionId = SID, activated = true })
		end
	end
end)

plugin.Unloading:Connect(function()
	post("/heartbeat", { sessionId = SID, activated = false })
end)

print("⚡ Codely Bridge loaded — click CONNECT")