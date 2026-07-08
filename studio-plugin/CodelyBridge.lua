-- Codely Bridge Plugin - Bidirectional Version
-- Codely can send commands TO Studio and receive results

local Plugin = plugin or script.Parent
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- Configuration
local SERVER_URL = "http://localhost:7269"
local API_BASE = SERVER_URL .. "/api"

-- Plugin toolbar
local toolbar = plugin:CreateToolbar("Codely Bridge")

-- Create main widget
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Right,
	false,
	false,
	400,
	300,
	400,
	300
)

local widget = plugin:CreateDockWidgetPluginGui("CodelyBridgeWidget", widgetInfo)
widget.Title = "Codely Bridge"

-- UI
local screenGui = Instance.new("ScrollingFrame")
screenGui.Size = UDim2.new(1, -20, 1, -20)
screenGui.Position = UDim2.new(0, 10, 0, 10)
screenGui.BackgroundTransparency = 1
screenGui.ScrollBarThickness = 8
screenGui.Parent = widget

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.Parent = screenGui

local function createLabel(text, textSize)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, textSize or 20)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = textSize or 16
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Parent = screenGui
	return label
end

local function createButton(text, onClick)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 35)
	button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	button.BorderSizePixel = 0
	button.Text = text
	button.TextSize = 16
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamMedium
	button.Parent = screenGui

	button.MouseButton1Click:Connect(onClick)

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	return button
end

-- Status
local statusLabel = createLabel("⚡ Connected", 18)
statusLabel.TextColor3 = Color3.fromRGB(0.3, 1, 0.3)

-- Command log
local logLabel = createLabel("Waiting for commands...", 14)
logLabel.Size = UDim2.new(1, 0, 0, 200)
logLabel.BackgroundTransparency = 0.5
logLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

local processedCommandIds = {}

-- Execute commands from Codely
local function executeCommand(command)
	local action = command.action
	local data = command.data
	local result = { success = false, error = nil }

	logLabel.Text = `Executing: {action}`

	spawn(function()
		local success, response = pcall(function()
			if action == "create_script" then
				-- Create a script in Studio
				local scriptType = data.scriptType or "Script"
				local parent = game
				if data.parentPath then
					parent = parent:FindFirstChild(data.parentPath) or game
				end

				local scriptInstance
				if scriptType == "Script" then
					scriptInstance = Instance.new("Script")
				elseif scriptType == "LocalScript" then
					scriptInstance = Instance.new("LocalScript")
				elseif scriptType == "ModuleScript" then
					scriptInstance = Instance.new("ModuleScript")
				end

				if scriptInstance then
					scriptInstance.Name = data.name or "NewScript"
					scriptInstance.Parent = parent
					scriptInstance.Source = data.code or ""

					result = {
						success = true,
						scriptPath = scriptInstance:GetFullName(),
						scriptType = scriptType
					}
				else
					result = { success = false, error = "Invalid script type" }
				end

			elseif action == "update_script" then
				-- Update an existing script
				local scriptPath = data.scriptPath
				if not scriptPath then
					result = { success = false, error = "Missing scriptPath" }
				else
					local scriptObj = game
					for part in string.gmatch(scriptPath, "([^%.]+)") do
						scriptObj = scriptObj:FindFirstChild(part)
						if not scriptObj then
							break
						end
					end

					if scriptObj and scriptObj:IsA("LuaSourceContainer") then
						scriptObj.Source = data.code or ""
						result = {
							success = true,
							scriptPath = scriptPath
						}
					else
						result = { success = false, error = "Script not found" }
					end
				end

			elseif action == "create_object" then
				-- Create any object in Studio
				local className = data.className
				local parent = game
				if data.parentPath then
					for part in string.gmatch(data.parentPath, "([^%.]+)") do
						parent = parent:FindFirstChild(part) or parent
					end
				end

				if className then
					local obj = Instance.new(className)
					obj.Name = data.name or className
					obj.Parent = parent

					-- Apply properties
					if data.properties then
						for prop, value in pairs(data.properties) do
							pcall(function()
								obj[prop] = value
							end)
						end
					end

					result = {
						success = true,
						objectPath = obj:GetFullName(),
						className = className
					}
				else
					result = { success = false, error = "Missing className" }
				end

			elseif action == "delete_object" then
				-- Delete an object
				local objectPath = data.objectPath
				if not objectPath then
					result = { success = false, error = "Missing objectPath" }
				else
					local obj = game
					for part in string.gmatch(objectPath, "([^%.]+)") do
						obj = obj:FindFirstChild(part)
						if not obj then
							break
						end
					end

					if obj then
						obj:Destroy()
						result = {
							success = true,
							deletedPath = objectPath
						}
					else
						result = { success = false, error = "Object not found" }
					end
				end

			elseif action == "get_object_info" then
				-- Get info about an object
				local objectPath = data.objectPath
				if not objectPath then
					result = { success = false, error = "Missing objectPath" }
				else
					local obj = game
					for part in string.gmatch(objectPath, "([^%.]+)") do
						obj = obj:FindFirstChild(part)
						if not obj then
							break
						end
					end

					if obj then
						local info = {
							className = obj.ClassName,
							name = obj.Name,
							path = obj:GetFullName(),
							parentPath = obj.Parent and obj.Parent:GetFullName() or nil
						}

						-- Get basic properties
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
				end

			elseif action == "execute_luau" then
				-- Execute Luau code (dangerous, but useful)
				local successCode, execResult = pcall(function()
					return loadstring(data.code)()
				end)

				if successCode then
					result = {
						success = true,
						result = tostring(execResult) or "nil"
					}
				else
					result = {
						success = false,
						error = tostring(execResult)
					}
				end

			elseif action == "list_objects" then
				-- List objects in a path
				local parentPath = data.parentPath or ""
				local parent = game

				if parentPath ~= "" then
					for part in string.gmatch(parentPath, "([^%.]+)") do
						parent = parent:FindFirstChild(part) or parent
					end
				end

				local objects = {}
				for _, child in ipairs(parent:GetChildren()) do
					table.insert(objects, {
						name = child.Name,
						className = child.ClassName
					})
				end

				result = {
					success = true,
					objects = objects,
					parentPath = parent:GetFullName()
				}

			else
				result = {
					success = false,
					error = `Unknown action: {action}`
				}
			end

			return result
		end)

		-- Send result back to server
		local resultBody = HttpService:JSONEncode({
			commandId = command.id,
			result = result
		})

		pcall(function()
			HttpService:RequestAsync({
				Url = API_BASE .. "/result",
				Method = "POST",
				Headers = {
					["Content-Type"] = "application/json"
				},
				Body = resultBody
			})
		end)

		logLabel.Text = `Result: {success and "✅ Success" or "❌ Error"}`
	end)
end

-- Poll for commands from Codely
local lastPollTime = 0
local POLL_INTERVAL = 1 -- Check every second

RunService.Heartbeat:Connect(function()
	local currentTime = tick()
	if currentTime - lastPollTime >= POLL_INTERVAL then
		lastPollTime = currentTime

		spawn(function()
			local success, response = pcall(function()
				return HttpService:RequestAsync({
					Url = API_BASE .. "/commands",
					Method = "GET"
				})
			end)

			if success and response.StatusCode == 200 then
				local data = HttpService:JSONDecode(response.Body)
				local commands = data.commands or {}

				for _, command in ipairs(commands) do
					if not processedCommandIds[command.id] then
						processedCommandIds[command.id] = true
						executeCommand(command)
					end
				end

				-- Clear processed commands
				if #commands > 0 then
					local ids = {}
					for _, cmd in ipairs(commands) do
						table.insert(ids, cmd.id)
					end

					pcall(function()
						HttpService:RequestAsync({
							Url = API_BASE .. "/commands/clear",
							Method = "POST",
							Headers = {
								["Content-Type"] = "application/json"
							},
							Body = HttpService:JSONEncode({ commandIds = ids })
						})
					end)
				end
			end
		end)
	end
end)

-- Toggle button
local toggleButton = toolbar:CreateButton("Toggle Codely Bridge", "Open/close Codely Bridge panel")
toggleButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

-- Send to Codely button (still works)
local sendButton = createButton("Open AI Chat (in Terminal)", function()
	logLabel.Text = "Use Codely CLI in terminal to send commands to Studio!"
end)

createLabel("Status: Connected to Codely Bridge", 14)
createLabel("Codely can now execute commands in Studio!", 14)

print("✅ Codely Bridge Plugin loaded (Bidirectional mode)!")
print("💬 Ask Codely in terminal to do things in Studio!")