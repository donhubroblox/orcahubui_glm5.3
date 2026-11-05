-- OrcaUI Example Script
-- Run this in Potassium (or any executor) to see the library in action.

local OrcaUI = nil

-- Try to load the library safely
local ok, result = pcall(function()
    -- Check if required functions exist
    if not loadstring then
        error("loadstring is not available in this executor")
    end
    if not game or not game.HttpGet then
        error("game.HttpGet is not available in this executor")
    end

    local code = game:HttpGet("https://raw.githubusercontent.com/donhubroblox/orcahubui_glm5.3/main/OrcaUI.lua")
    if not code or code == "" then
        error("Failed to fetch OrcaUI.lua from GitHub (empty response)")
    end

    local chunk = loadstring(code)
    if not chunk then
        error("OrcaUI.lua has a syntax error and could not be compiled")
    end

    return chunk()
end)

if not ok or not result then
    warn("[OrcaUI] Failed to load: " .. tostring(result or "unknown error"))
    warn("[OrcaUI] Make sure you are running this in a supported executor (Potassium, Synapse X, etc.)")
    return
end

OrcaUI = result

-- Register Lucid icon ImageIds (upload your lucide decals and put their rbxassetid:// here)
-- Example:
-- OrcaUI:RegisterIcon("Home", "rbxassetid://123456789")
-- OrcaUI:RegisterIcon("Settings", "rbxassetid://987654321")

-- Create the window
local Window = OrcaUI:CreateWindow({
    Name = "OrcaUI",
    Size = UDim2.new(0, 720, 0, 500),
    Position = UDim2.new(0.5, -360, 0.5, -250),
    Accent = Color3.fromRGB(99, 102, 241), -- indigo accent (Airflow-inspired purple/blue)
    ShowSearchBar = true,
})

-- ============================================
-- TAB: Main
-- ============================================
local MainTab = Window:CreateTab({
    Name = "Main",
    Icon = "Home",
})

local MainSection = MainTab:CreateSection({
    Name = "Main Features",
    Icon = "Layout",
})

MainSection:CreateToggle({
    Name = "Godmode",
    Icon = "Shield",
    Default = false,
    Callback = function(state)
        print("Godmode:", state)
        OrcaUI:Notify({Title = "Godmode", Text = "Toggled to " .. tostring(state), Type = "Info", Duration = 2})
    end,
})

MainSection:CreateToggle({
    Name = "Infinite Jump",
    Icon = "Activity",
    Default = true,
    Callback = function(state)
        print("Infinite Jump:", state)
    end,
})

MainSection:CreateToggle({
    Name = "Noclip",
    Icon = "Layout",
    Default = false,
    Callback = function(state) print("Noclip:", state) end,
})

MainSection:CreateButton({
    Name = "Reset Character",
    Icon = "RotateCcw",
    Callback = function()
        local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
        OrcaUI:Notify({Title = "Reset", Text = "Character reset", Type = "Success", Duration = 2})
    end,
})

MainSection:CreateSlider({
    Name = "Walkspeed",
    Icon = "Activity",
    Min = 16,
    Max = 200,
    Default = 16,
    Callback = function(val)
        local char = game.Players.LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = val end
        end
    end,
})

MainSection:CreateSlider({
    Name = "JumpPower",
    Min = 50,
    Max = 300,
    Default = 50,
    Callback = function(val)
        local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = val end
    end,
})

MainSection:CreateDropdown({
    Name = "Method",
    Icon = "Menu",
    Options = {"Potassium", "ScriptWare", "Krnl", "Synapse X"},
    Default = "Potassium",
    Callback = function(val) print("Method:", val) end,
})

MainSection:CreateTextbox({
    Name = "Custom Value",
    Icon = "Edit",
    Placeholder = "Enter value...",
    Callback = function(text, enter) print("Typed:", text) end,
})

MainSection:CreateKeybind({
    Name = "Menu Key",
    Icon = "Keyboard",
    Default = Enum.KeyCode.RightShift,
    Callback = function(key) print("Keybind:", key.Name) end,
})

MainSection:CreateColorpicker({
    Name = "ESP Color",
    Icon = "Eye",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(color) print("Color:", color) end,
})

-- ============================================
-- TAB: Player
-- ============================================
local PlayerTab = Window:CreateTab({
    Name = "Player",
    Icon = "User",
})

local PlayerSection = PlayerTab:CreateSection({
    Name = "Player Options",
    Icon = "User",
})

PlayerSection:CreateToggle({
    Name = "Fly",
    Icon = "Activity",
    Default = false,
    Callback = function(state) print("Fly:", state) end,
})

PlayerSection:CreateToggle({
    Name = "ESP",
    Icon = "Eye",
    Default = false,
    Callback = function(state) print("ESP:", state) end,
})

PlayerSection:CreateSlider({
    Name = "FOV",
    Min = 70,
    Max = 120,
    Default = 70,
    Callback = function(val)
        local cam = workspace.CurrentCamera
        if cam then cam.FieldOfView = val end
    end,
})

PlayerSection:CreateParagraph({
    Title = "About OrcaUI",
    Content = "A modern Roblox UI library inspired by Airflow.\nBuilt for Potassium and compatible with most executors.\nUse Lucid icons for a clean, consistent look.",
})

-- ============================================
-- TAB: Settings
-- ============================================
local SettingsTab = Window:CreateTab({
    Name = "Settings",
    Icon = "Settings",
})

local SettingsSection = SettingsTab:CreateSection({
    Name = "Configuration",
    Icon = "Settings",
})

SettingsSection:CreateToggle({
    Name = "Notifications",
    Icon = "Bell",
    Default = true,
    Callback = function(state) print("Notifications:", state) end,
})

SettingsSection:CreateToggle({
    Name = "Auto Execute",
    Icon = "Play",
    Default = false,
    Callback = function(state) print("Auto Execute:", state) end,
})

SettingsSection:CreateButton({
    Name = "Destroy UI",
    Icon = "Trash",
    Callback = function()
        Window:Destroy()
    end,
})

print("OrcaUI loaded successfully!")
