#!/usr/bin/env node

const http = require('http');

async function sendCommand(action, data = {}) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({ action, data });

    const options = {
      hostname: 'localhost',
      port: 7269,
      path: '/api/command',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          resolve(JSON.parse(data).commandId);
        } else {
          reject(new Error(`Status: ${res.statusCode}`));
        }
      });
    });

    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

function getResult(commandId, timeout = 30000) {
  return new Promise((resolve, reject) => {
    const startTime = Date.now();

    const poll = () => {
      if (Date.now() - startTime > timeout) {
        reject(new Error('Timeout'));
        return;
      }

      http.get(`http://localhost:7269/api/result/${commandId}`, (res) => {
        let data = '';
        res.on('data', (chunk) => data += chunk);
        res.on('end', () => {
          if (res.statusCode === 200) {
            resolve(JSON.parse(data));
          } else if (res.statusCode === 404) {
            setTimeout(poll, 500);
          } else {
            reject(new Error(`Status: ${res.statusCode}`));
          }
        });
      }).on('error', reject);
    };

    poll();
  });
}

async function createHealthBar() {
  try {
    console.log('🎮 Creating Health Bar System...\n');

    // Create health management script (this will create the UI elements)
    console.log('📝 Creating health management script...');
    const healthScriptCode = `
local Players = game:GetService("Players")
local HealthBarGui = script.Parent

local MAX_HEALTH = 100

-- Create UI elements
local function createUI()
    -- Background frame
    local background = Instance.new("Frame")
    background.Name = "HealthBarBackground"
    background.Size = UDim2.new(0, 300, 0, 30)
    background.Position = UDim2.new(0.5, -150, 0, 10)
    background.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    background.BorderSizePixel = 0
    background.AnchorPoint = Vector2.new(0.5, 0)
    background.Parent = HealthBarGui

    -- Health bar
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.Position = UDim2.new(0, 0, 0, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0
    healthBar.ZIndex = 1
    healthBar.Parent = background

    -- Health text
    local healthText = Instance.new("TextLabel")
    healthText.Name = "HealthText"
    healthText.Size = UDim2.new(1, 0, 1, 0)
    healthText.Position = UDim2.new(0, 0, 0, 0)
    healthText.BackgroundTransparency = 1
    healthText.Text = "100/100"
    healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
    healthText.TextSize = 16
    healthText.Font = Enum.Font.GothamBold
    healthText.TextXAlignment = Enum.TextXAlignment.Center
    healthText.TextYAlignment = Enum.TextYAlignment.Center
    healthText.ZIndex = 2
    healthText.Parent = background
end

-- Initialize player health
local function initPlayer(player)
    -- Create leaderstats
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    -- Create health value
    local health = Instance.new("IntValue")
    health.Name = "Health"
    health.Value = MAX_HEALTH
    health.Parent = leaderstats

    -- Create max health for display
    local maxHealth = Instance.new("IntValue")
    maxHealth.Name = "MaxHealth"
    maxHealth.Value = MAX_HEALTH
    maxHealth.Parent = leaderstats
end

-- Update health bar
local function updateHealthBar(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end

    local health = leaderstats:FindFirstChild("Health")
    local maxHealth = leaderstats:FindFirstChild("MaxHealth")

    if health and maxHealth then
        local healthBar = HealthBarGui:FindFirstChild("HealthBarBackground")
        if healthBar then
            local bar = healthBar:FindFirstChild("HealthBar")
            local text = healthBar:FindFirstChild("HealthText")

            if bar then
                local healthPercentage = health.Value / maxHealth.Value
                bar.Size = UDim2.new(healthPercentage, 0, 1, 0)

                -- Change color based on health
                if healthPercentage > 0.5 then
                    bar.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Green
                elseif healthPercentage > 0.25 then
                    bar.BackgroundColor3 = Color3.fromRGB(255, 165, 0) -- Orange
                else
                    bar.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Red
                end
            end

            if text then
                text.Text = health.Value .. "/" .. maxHealth.Value
            end
        end
    end
end

-- Damage function
local function takeDamage(player, amount)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return false end

    local health = leaderstats:FindFirstChild("Health")
    if not health then return false end

    health.Value = math.max(0, health.Value - amount)
    updateHealthBar(player)

    return true
end

-- Heal function
local function heal(player, amount)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return false end

    local health = leaderstats:FindFirstChild("Health")
    local maxHealth = leaderstats:FindFirstChild("MaxHealth")

    if not health or not maxHealth then return false end

    health.Value = math.min(maxHealth.Value, health.Value + amount)
    updateHealthBar(player)

    return true
end

-- Create UI
createUI()

-- Connect player events
Players.PlayerAdded:Connect(function(player)
    -- Wait for character
    player.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        initPlayer(player)
        updateHealthBar(player)

        -- Track health changes
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local health = leaderstats:FindFirstChild("Health")
            if health then
                health.Changed:Connect(function()
                    updateHealthBar(player)
                end)
            end
        end
    end)
end)

-- Test functions (can be called from command bar)
_G.TakeDamage = takeDamage
_G.Heal = heal

print("✅ Health System loaded!")
print("Use _G.TakeDamage(Players.LocalPlayer, 10) to damage")
print("Use _G.Heal(Players.LocalPlayer, 20) to heal")
    `.trim()

    const cmd1 = await sendCommand('create_script', {
      scriptType: 'Script',
      parentPath: 'game.StarterGui',
      name: 'HealthBarGui',
      code: healthScriptCode
    });
    const res1 = await getResult(cmd1);
    console.log('✅ Health bar system created!');

    console.log('\n🎉 Health Bar System Complete!');
    console.log('\n📋 Features:');
    console.log('   - Visual health bar at top of screen');
    console.log('   - Color changes (green → orange → red)');
    console.log('   - Health text display');
    console.log('   - Damage and heal functions');
    console.log('\n💡 Test it in Studio Command Bar:');
    console.log('   _G.TakeDamage(Players.LocalPlayer, 10) -- Take 10 damage');
    console.log('   _G.Heal(Players.LocalPlayer, 20) -- Heal 20 health');

  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

createHealthBar();