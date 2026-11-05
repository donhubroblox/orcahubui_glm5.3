--[[
    OrcaUI
    A modern, clean Roblox UI library inspired by Airflow.
    Built for Potassium and compatible with most Lua executors.

    Design goals:
    - Dark modern theme with rounded corners & subtle borders
    - Sidebar navigation with tabs + search bar
    - Lucid icon support (register your own lucid decal ImageIds)
    - Executor-compatible: no external HTTP, no getcustomasset required
    - Tween-based animations, responsive-ish layout

    Usage:
        local OrcaUI = loadstring(game:HttpGet("...OrcaUI.lua"))()
        local Window = OrcaUI:CreateWindow({Name = "OrcaUI", Size = UDim2.new(0, 700, 0, 450)})
        local Tab = Window:CreateTab({Name = "Main", Icon = "Home"})
        local Section = Tab:CreateSection({Name = "Main Features"})
        Section:CreateToggle({Name = "Godmode", Default = false, Callback = function(v) print(v) end})
--]]

local OrcaUI = {}
OrcaUI.__index = OrcaUI
OrcaUI.Version = "1.0.0"
OrcaUI.Debug = false

-- // Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- // Theme
local Theme = {
    Background  = Color3.fromRGB(17, 17, 19),
    Surface     = Color3.fromRGB(23, 23, 26),
    SurfaceElev = Color3.fromRGB(28, 28, 32),
    SurfaceHover= Color3.fromRGB(34, 34, 39),

    Border      = Color3.fromRGB(39, 39, 45),
    BorderFocus = Color3.fromRGB(99, 102, 241),

    Accent      = Color3.fromRGB(99, 102, 241),
    AccentHover = Color3.fromRGB(117, 117, 248),
    AccentActive= Color3.fromRGB(76, 75, 205),

    Text        = Color3.fromRGB(235, 235, 240),
    TextDim     = Color3.fromRGB(156, 156, 165),
    TextMuted   = Color3.fromRGB(110, 110, 120),
    TextDisabled= Color3.fromRGB(80, 80, 90),

    Success     = Color3.fromRGB(34, 197, 94),
    Danger      = Color3.fromRGB(239, 68, 68),
    Warning     = Color3.fromRGB(234, 179, 8),
    Info        = Color3.fromRGB(59, 130, 246),

    Sidebar     = Color3.fromRGB(17, 17, 19),
    SidebarActive = Color3.fromRGB(30, 30, 35),
}

local Config = {
    Font             = Enum.Font.Gotham,
    FontBold         = Enum.Font.GothamBold,
    FontMono         = Enum.Font.GothamMono,
    TextSize         = 13,
    SmallTextSize    = 11,
    CornerRadius     = UDim.new(0, 8),
    ElementRadius    = UDim.new(0, 6),
    ToggleSize       = UDim2.new(0, 36, 0, 18),
    TweenTime        = 0.2,
    TweenEasing      = Enum.EasingStyle.Quad,
    TweenDirection   = Enum.EasingDirection.Out,
}

-- // Utilities
local function Create(className, properties)
    local instance = Instance.new(className)
    for prop, value in pairs(properties or {}) do
        if prop == "Children" then
            for _, child in ipairs(value) do
                child.Parent = instance
            end
        else
            local ok, err = pcall(function()
                instance[prop] = value
            end)
            if not ok then
                warn("[OrcaUI] Failed to set " .. tostring(prop) .. " on " .. className .. ": " .. tostring(err))
            end
        end
    end
    return instance
end

local function Tween(instance, properties, duration, easingStyle, easingDirection)
    duration = duration or Config.TweenTime
    easingStyle = easingStyle or Config.TweenEasing
    easingDirection = easingDirection or Config.TweenDirection
    local tween = TweenService:Create(instance, TweenInfo.new(duration, easingStyle, easingDirection), properties)
    tween:Play()
    return tween
end

local function GetScreenGui(name)
    local gui = PlayerGui:FindFirstChild(name)
    if not gui then
        gui = Create("ScreenGui", {
            Name = name,
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            Parent = PlayerGui,
        })
        local ok = pcall(function() gui.Parent = CoreGui end)
        if not ok then
            gui.Parent = PlayerGui
        end
    end
    return gui
end

local function SetZIndex(instance, index)
    for _, obj in ipairs(instance:GetDescendants()) do
        if obj:IsA("GuiObject") then
            obj.ZIndex = index
        end
    end
    if instance:IsA("GuiObject") then
        instance.ZIndex = index
    end
end

local function RoundCorners(instance, radius)
    radius = radius or Config.ElementRadius
    local corner = Create("UICorner", {CornerRadius = radius, Parent = instance})
    return corner
end

local function AddStroke(instance, color, thickness)
    thickness = thickness or 1
    local stroke = Create("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness,
        Parent = instance,
    })
    return stroke
end

local function AddListLayout(instance, padding)
    padding = padding or UDim.new(0, 8)
    return Create("UIListLayout", {
        Padding = padding,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = instance,
    })
end

local function AddPadding(instance, left, top, right, bottom)
    left = left or UDim.new(0, 12)
    top = top or UDim.new(0, 10)
    right = right or UDim.new(0, 12)
    bottom = bottom or UDim.new(0, 10)
    return Create("UIPadding", {
        PaddingLeft = left, PaddingTop = top, PaddingRight = right, PaddingBottom = bottom,
        Parent = instance,
    })
end

-- // Lucid Icons
-- Lucid (lucide.dev) SVG path data is provided for reference / custom rendering.
-- To actually display icons, register ImageIds via OrcaUI:RegisterIcon(name, "rbxassetid://...").
OrcaUI.IconMap = {}
OrcaUI.LucidIcons = {
    Layout     = "M3 2v18h18V2H3zm18-2h-3v3h3V0zm0 20h-3v3h3V20zm-18 0h-3v3h3V2zM20 20H3v-3h17v3z",
    Home       = "M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6V10v4z",
    Settings   = "M12.133 19.107q1.363-.544 2.5-.497a10.3 10.3 0 004.185-1.784c2.254-1.519 4.248-3.437 5.679-5.68a10.3 10.3 0 001.784-4.185c.046-1.137-.047-2.137-.497-2.5a2 2 0 00-.109-.299l-.003-.014q-.013-.091-.035-.183a2 2 0 00-.05-.25l-.003-.013q-.016-.09-.037-.179a2 2 0 00-.053-.247l-.002-.01q-.012-.055-.028-.108a2 2 0 00-.04-.147q-.017-.046-.037-.09a3 3 0 00-.14-.293l-.003-.005a2 2 0 00-.22-.362q-.03-.044-.062-.086l-.004-.005a2 2 0 00-.24-.286q-.035-.035-.072-.068l-.004-.003a2 2 0 00-.26-.206q-.04-.026-.081-.049l-.005-.003a2 2 0 00-.37-.162q-.048-.017-.097-.03l-.004-.001a2 2 0 00-.38-.082q-.053-.009-.107-.014l-.005-.001q-.095-.014-.191-.014a3 3 0 00-.386 0q-.054.005-.107.014l-.005.001a2 2 0 00-.38.082q-.05.012-.097.03l-.004.001a2 2 0 00-.37.162q-.04.022-.081.049l-.005.003a2 2 0 00-.26.206l-.004.003q-.037.033-.072.068l-.004.004a2 2 0 00-.24.286l-.004.005q-.031.042-.062.086l-.003.005a2 2 0 00-.22.362l-.003.005q-.07.1-.14.293q-.02.044-.037.09a2 2 0 00-.04.147q-.016.054-.028.108l-.002.01-.003.01q-.019.083-.053.247l-.003.013q-.013.059-.037.179l-.003.014a2 2 0 00-.05.25l-.003.014a2 2 0 00-.109.299c-.45.362-.542 1.363-.497 2.5a10.3 10.3 0 001.784 4.185c1.431 2.243 3.425 4.161 5.679 5.68a10.3 10.3 0 004.185 1.784c1.137.046 2.137-.047 2.5-.497a2 2 0 00.299-.109l.014-.003q.091-.013.183-.035a2 2 0 00.25-.05l.013-.003q.09-.016.179-.037a2 2 0 00.247-.053l.01-.002q.054-.012.108-.028a2 2 0 00.147-.04q.046-.017.09-.037a3 3 0 00.293-.14l.005-.003a2 2 0 00.362-.22q.044-.03.086-.062l.005-.004a2 2 0 00.286-.24q.035-.036.068-.072l.003-.004a2 2 0 00.206-.26q.023-.04.049-.081l.003-.005a2 2 0 00.162-.37q.017-.048.03-.097l.001-.004a2 2 0 00.082-.38q.009-.053.014-.107l.001-.005q.014-.095.014-.191a3 3 0 000-.386q-.005-.054-.014-.107l-.001-.005a2 2 0 00-.082-.38q-.012-.05-.03-.097l-.001-.004a2 2 0 00-.162-.37q-.022-.04-.049-.081l-.003-.005a2 2 0 00-.206-.26q-.033-.037-.068-.072l-.003-.004a2 2 0 00-.286-.24l-.005-.004q-.042-.031-.086-.062l-.005-.003a2 2 0 00-.362-.22l-.005-.003a3 3 0 00-.293-.14q-.044-.02-.09-.037a2 2 0 00-.147-.04q-.054-.016-.108-.028l-.01-.002q-.081-.02-.179-.037l-.013-.003a2 2 0 00-.25-.05l-.014-.003a2 2 0 00-.299-.11z",
    Search     = "M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z",
    User       = "M19 21v-2a4 4 0 00-4-4H9a4 4 0 00-4 4v2",
    Monitor    = "M17 20v-5a2 2 0 00-2-2H5a2 2 0 00-2 2v5",
    Shield     = "M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z",
    AlertTriangle = "M10.293 13.293A1 1 0 0012 15l4-4a1 1 0 000-1.414l-4-4A1 1 0 008 7.586L5.414 10.172a1 1 0 000 1.414z",
    AlertCircle = "M22 12c0-5-5-5-5-5S12 7 12 12s5 5 5 5-5-5-5-5zM12 9a1 1 0 100 2 1 1 0 000-2zm0 10a1 1 0 100 2 1 1 0 000-2z",
    Bell       = "M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9",
    Zap        = "M13 2L3 14h9l-1 8 10-12h-9l1-8z",
    Heart      = "M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7l-1.682-1.682a4.5 4.5 0 00-6.364 0z",
    Star       = "M12 17.25L17.818 21.12l-2.682-6.763L19 9.75l-6.763-2.682L12 3l-3.236 4.082L5 9.75l4.868 4.582L6.182 21.12z",
    Play       = "M14.752 11.168l-3.12 2.436c-.291.227-.291.637 0 .864l3.12 2.436c.655.512 1.712.512 2.368 0l3.12-2.436c.291-.227.291-.637 0-.864L17.12 3.032c-.656-.512-1.713-.512-2.368 0z",
    Stop       = "M8 10h8v8H8z",
    Lock       = "M12 15v4c0 1.1-.9 2-2 2H6c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2h4c1.1 0 2 .9 2 2v7z",
    Key        = "M21 2l-2 2m-7.61 7.61a5.5 5.5 0 11-7.778 7.778 5.5 5.5 0 017.778-7.778zm0 0L15.5 7.5m0 0l3 3L22 7l-3-3m-3.5 3.5L19 4",
    Cpu        = "M20.17 12.23a10 10 0 010 11.54c-1.63-1.63-4.37-1.63-6 0-.37-.37-.76-.76-1.07-1.16a10 10 0 01-1.16-1.07c-1.63-1.63-1.63-4.37 0-6 .37-.37.76-.76 1.16-1.07a10 10 0 011.07-1.16c1.63-1.63 4.37-1.63 6 0 .37.37.76.76 1.07 1.16a10 10 0 011.16 1.07c1.62 1.62 1.62 4.36 0 6z",
    Activity   = "M13 10V3L4 14h7v7l9-11h-7z",
    Target     = "M12 22C6.477 22 2 17.523 2 12S6.477 2 12 2s10 4.477 10 10-4.477 10-10 10zm0-2a8 8 0 100-16 8 8 0 000 16z",
    Moon       = "M21 12.79A9 9 0 1111.21 3 7 7 0 0021 12.79z",
    Sun        = "M12 3c-4.97 0-9 4.03-9 9s4.03 9 9 9 9-4.03 9-9c0-.34-.02-.67-.05-1",
    Cloud      = "M18 10h-1.26A8 8 0 009 4c0-1.11-.24-2.16-.64-3.11l-.67-1.56-.66-1.55A2 2 0 005 0a2 2 0 00-2 2c0 .92.49 1.7 1.22 2.11l.35.2A2 2 0 004 6c0 1.11.89 2 2 2h1.55l-.22.49c-.27.6-.44 1.28-.44 2h0c0 2.21 1.79 4 4 4h0c1.11 0 2.08-.36 2.88-1a4 4 0 001.12-2.67l.21-.52z",
    Wifi       = "M3.055 17.056A9 9 0 0112 5c4.971 0 9.027 3.672 9.027 8.2s-4.056 8.2-9.027 8.2c-1.238 0-2.383-.28-3.389-.789a1 1 0 111.264-1.532c.892.449 1.878.702 2.966.702s2.074-.253 2.966-.702a1 1 0 111.264 1.532c-1.006.509-2.151.789-3.389.789-4.971 0-9.027-3.672-9.027-8.2s4.056-8.2 9.027-8.2a1 1 0 110 2c-4.971 0-9.027 3.672-9.027-8.2s4.056-8.2 9.027-8.2z",
    Copy       = "M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2V8a2 2 0 00-2-2H8a2 2 0 00-2 2v8a2 2 0 002 2z",
    Edit       = "M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7",
    Trash      = "M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16",
    Download   = "M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M7 10l5 5 5-5M12 15V3",
    Upload     = "M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M17 8l5 5 5-5M12 9V21",
    Save       = "M19 21H5a2 2 0 01-2-2V5a2 2 0 012-2h11l5 5v11a2 2 0 01-2 2z",
    Plus       = "M12 5v14M5 12h14",
    Minus      = "M5 12h14",
    X          = "M18 6L6 18M6 6l12 12",
    Check      = "M5 13l4 4L19 7",
    ArrowRight = "M5 12h14M12 5l7 7-7 7",
    ArrowLeft  = "M19 12H5M12 19l7-7-7-7",
    ArrowUp    = "M12 19V5M5 12l7-7 7 7",
    ArrowDown  = "M5 14l7 7 7-7M12 5v14",
    HelpCircle = "M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12s4.477 10 10 10zM13 16h-1v-4h-1m1-4.6h-2.6c-.4 0-.8.3-.8.8v1.4c0 .4.3.8.8.8h2.6c.4 0 .8-.3.8-.8v-1.4c0-.4-.4-.8-.8-.8z",
    Info       = "M13 16h-1v-4h-1m1-4.8l-1 1.4L12 16l1-1.4z",
    Mail       = "M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z",
    File       = "M13 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V9z",
    Folder     = "M22 19a2 2 0 01-2 2H4a2 2 0 01-2-2V5a2 2 0 012-2h5l2 2h9a2 2 0 012 2z",
    Image      = "M21 12a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h14a2 2 0 012 2z",
    Video      = "M15 10l3-3-3-3m0 6l3 3m-3-3 3 3m-9-3v12a1 1 0 001 1h12a1 1 0 001-1V5a1 1 0 00-1-1H4a1 1 0 00-1 1v12a1 1 0 001 1h6m-6 0V6",
    Music      = "M9 18V5l12-2v13",
    Mic        = "M12 1a3 3 0 00-3 3v8a3 3 0 006 0V4a3 3 0 00-3-3z",
    Volume     = "M5 5a8 8 0 018 8v4a8 8 0 01-8 8V5z",
    VolumeX    = "M5 5a8 8 0 018 8v4a8 8 0 01-8 8V5z",
    Clock      = "M12 6v6m0 0v6m0-6h6m-6 0H6",
    Calendar   = "M19 4h-1V2h-2v2H8V2H6v2H5a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2V6a2 2 0 00-2-2z",
    Link       = "M13.173 3a10 10 0 00-13.348 6.653 10 10 0 002.324 6.653L8.725 12.7m6.549-5.652a10 10 0 0113.348-6.653 10 10 0 01-2.324 6.653L15.275 11.3",
    Eye        = "M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z",
    EyeOff     = "M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8zM7.05 9.5c1.124-1.124 2.822-2.418 4.872-3.242a1 1 0 011.41-.122L9.9 7.77a1 1 0 001.41-.121c1.634-1.008 3.55-1.66 5.341-1.66a8.084 8.084 0 018.086 6.687c-.312 1.765-1.77 3.099-3.512 3.945a1 1 0 01-.397.115l-.442-.023a1 1 0 00-.872.656c-.054.172-.192.434-.376.746l-.202.227-.255.216a1 1 0 01-.615.321c-1.212.312-2.625-.192-3.78-1.15L9.9 17.75c-1.156-.96-1.977-2.562-2.71-4.423zM2.01 6.49c-.307.21-.643.33-.99.33-.794 0-1.508-.43-1.857-1.08a1 1 0 01.045-1.351l.132-.114c.17-.149.284-.352.242-.576l-.035-.18a1 1 0 01.47-.83c1.44-.491 3.012-.737 4.48-.737a8 8 0 012.62.505l.001.001.005-.001c.311-.115.587-.066.815.088a1 1 0 01.752.853l-.001.016.005.191c.035.17-.138.361-.341.552l-.003.002a1 1 0 01-.764.407c-1.079.21-2.128.67-3.137 1.55a7 7 0 00-1.34 1.04c-.202.197-.434.367-.664.554a1 1 0 01-.41.245z",
    Pin        = "M21.121 8.384l-3.384 6.764c-.31.62-.97.99-1.608.99H16a2 2 0 01-2-2v-3.384c0-1.122-.897-2.017-2-2.117V3a1 1 0 00-1-1H3a1 1 0 00-1 1v1h.384c.638 0 1.298.37 1.608.99l3.384 6.764c.271.543.663.997 1.187 1.283a1 1 0 001.402 0c.524-.286.916-.74 1.187-1.283L9.832 13H13v3.384c0 1.122.897 2.017 2 2.117v1h1c.638 0 1.298-.37 1.608-.99l3.384-6.764c.271-.543.44-1.173.384-1.835z",
    TargetDot  = "M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12 4.477 22 12 22zm0-20c1.103 0 2 .897 2 2s-.897 2-2 2-2-.897-2-2 .897-2 2-2z",
    RefreshCcw = "M1 4v6h6M4 1c5.049 0 9.258 3.807 9.805 8.852C14.002 10.886 12.408 14 10 14c-4.411 0-8-3.589-8-8v-2z",
    RefreshCw  = "M23 4v6h-6M20 1c-5.049 0-9.258 3.807-9.805 8.852C10.002 10.886 11.596 14 14 14c4.411 0 8-3.589 8-8v-2z",
    RotateCcw  = "M1 4v6h6M4 1c5.049 0 9.258 3.807 9.805 8.852C14.002 10.886 12.408 14 10 14c-4.411 0-8-3.589-8-8v-2z",
    RotateCw   = "M23 4v6h-6M20 1c-5.049 0-9.258 3.807-9.805 8.852C10.002 10.886 11.596 14 14 14c4.411 0 8-3.589 8-8v-2z",
    Maximize   = "M8 3H5a2 2 0 00-2 2v3m18 0V5a2 2 0 00-2-2h-3m3 16v3a2 2 0 01-2 2h-3m-3 0V5",
    Minimize   = "M20 17v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6",
    Maximize2  = "M15 3h6v6",
    Minimize2  = "M21 3v18M3 21h18",
    Square     = "M3 3h18v18H3V3z",
    Circle     = "M2 12C2 6.477 6.477 2 12 2s10 4.477 10 10-4.477 10-10 10S2 17.523 2 12z",
    Triangle   = "M10.293 8.293 16 12l-5.707 3.707A1 1 0 017 14v-4a1 1 0 013.293-.707z",
    Diamond    = "M2.707 4.293A1 1 0 014.414 2L12 9.414l7.586-7.414a1 1 0 011.414 0l.122.122a1 1 0 010 1.414L18.414 14a1 1 0 01-.122.122L12 19.414l-7.586-7.414a1 1 0 010-1.414L2.828 5.828a1 1 0 010-1.414z",
    Hexagon    = "M21 16V8l-7-4L7 8v8l7 4z",
    SquareOff  = "M2 2h18v18H2V2z",
    Menu       = "M4 6h16M4 12h16M4 18h16",
    MoreHorizontal = "M8 12h.01M12 12h.01M16 12h.01",
    MoreVertical   = "M12 8v.01M12 12v.01M12 16v.01M12 20v.01",
    Dot        = "M12 12h.01",
    Dots       = "M12 5v.01M12 12v.01M12 19v.01M5 12h.01M19 12h.01",
    LayoutGrid = "M3 3h18v18H3V3zm0 20h18V21H3v2z",
    Columns    = "M12 3v18M8 3H3v18h5V3zm10 0h5v18h-5V3z",
    List       = "M3 3h18v2H3V3zm0 20h18v2H3v-2zm0-10h18v2H3v-2z",
    Grid       = "M3 3h18v18H3V3zm0 20h18V21H3v2z",
    Edit2      = "M17 3a2.828 2.828 0 114 4L7.5 20.5 2 22l1.5-5.5L17 3z",
    Edit3      = "M12 20h9m-9 0H3m9 0h6m-6 0v-9m9 9V3m-9 6v3",
    CopyLink   = "M10 13a5 5 0 007.54.54l3-3a5 5 0 00-7.07-7.07l-1.72 1.73M22 10c0 4.714-3.286 8.637-7.765 8.995L6.25 17.777a10 10 0 01-1.494-15.502L6.474 5.45a10 10 0 017.765 1.935z",
    ExternalLink = "M15 3H6v12m9-9H6m0 0h12m-12 0V6l6 6",
    Link2      = "M10 13a5 5 0 007.54.54l3-3a5 5 0 00-7.07-7.07l-1.72 1.73",
    Link2Off   = "M10 13a5 5 0 007.54.54l3-3a5 5 0 00-7.07-7.07l-1.72 1.73M22 10c0 4.714-3.286 8.637-7.765 8.995L6.25 17.777a10 10 0 01-1.494-15.502L6.474 5.45a10 10 0 017.765 1.935z",
    SkipBack   = "M11 19l-7-7 7-7m7 14v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h6a2 2 0 002-2z",
    SkipForward= "M13 5l7 7-7 7m-7-14v6a2 2 0 012 2h6a2 2 0 012-2v-6a2 2 0 00-2-2H5a2 2 0 00-2 2z",
    Shuffle    = "M2 16l4.5-4.5M20.5 8l-4.5 4.5",
    Random     = "M4.5 16.5C3.265 16.5 2 17.765 2 19c0 1.235 1.265 2.5 2.5 2.5h13A1.5 1.5 0 0119 20c0-.828-.672-1.5-1.5-1.5-.274 0-.537.098-.75.274L14.25 13H8c-1.38 0-2.5-1.12-2.5-2.5S6.62 8 8 8h6.25l-2.5 2.5A1.5 1.5 0 0111 13c0-.828-.672-1.5-1.5-1.5s-1.5.672-1.5 1.5c0 1.235 1.265 2.5 2.5 2.5zM19.5 12C18.265 12 17 13.265 17 14.5S18.265 17 19.5 17h13c1.235 0 2.5-1.265 2.5-2.5S21.735 12 20.5 12h-13z",
    Bluetooth  = "M16.5 16.5V12l-8 4V8l8-4v4.5l-8 4z",
    SimCard    = "M16 11V7a4 4 0 00-4-8V3a4 4 0 00-4 8v4m4-9h.01M16 11v2a4 4 0 00-8 0v-2m0 0v3a4 4 0 00-8 0v-3m0 0v3a4 4 0 00-8 0v-3z",
    Tablet     = "M21 15V3a1 1 0 00-1-1H4a1 1 0 00-1 1v18a1 1 0 001 1h16a1 1 0 001-1z",
    Mobile     = "M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2",
    Laptop     = "M18.5 2.5a.5.5 0 010 1h-13a.5.5 0 010-1zM3 2l4.5 4.5L3 11v10a1 1 0 001 1h16a1 1 0 001-1V11l-1.5-4.5L21 2z",
    Smartphone = "M4 7v10a2 2 0 002 2h12a2 2 0 002-2V7a2 2 0 00-2-2H6a2 2 0 00-2 2z",
    Gamepad    = "M12 2c4.411 0 8 3.589 8 8v2c0 4.411-3.589 8-8 8-4.423 0-8.018-3.589-8.03-8l-.002-.023c-.005-.12-.01-.24-.01-.36 0-.662.034-1.317.098-1.964C3.166 8.642 0 12.278 0 16.023c0 4.411 3.589 8 8 8h2a8 8 0 000-16zm0 2a2 2 0 012 2h2a2 2 0 01-2 2 2 2 0 01-2-2h-2a2 2 0 012-2zm6 8a2 2 0 01-2 2h-2a2 2 0 01-2-2 2 2 0 012-2h2a2 2 0 012 2z",
    Keyboard   = "M4 5a1 1 0 011-1h16a1 1 0 011 1v12a1 1 0 01-1 1H5a1 1 0 01-1-1V5z",
    Mouse      = "M5 3c.465 0 .917.112 1.35.3L12 8c2.326 2.327 2.326 6.153 0 8.48l-5.65 5.65c-.977.976-2.548.976-3.524 0L2 16c-2.326-2.327-2.326-6.153 0-8.48l4.65-4.65c.433-.188.885-.3 1.35-.3z",
    Terminal   = "M4 7v10a2 2 0 002 2h12a2 2 0 002-2V7a2 2 0 00-2-2H6a2 2 0 00-2 2z",
    Banknote   = "M13 8V3M3 3v8a2 2 0 002 2h12a2 2 0 002-2V3z",
    Briefcase  = "M3 3h2a2 2 0 012 2v14a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 012-2h2",
    Building   = "M19 4v16l-7-3-7 3V4z",
    Brain      = "M10.424 10.424c1.16-1.17 3.04-1.17 4.192 0 .218.22.434.456.637.694a4.5 4.5 0 010 6.364c-.203.238-.419.474-.637.694-1.152 1.17-3.032 1.17-4.192 0-.218-.22-.434-.456-.637-.694a4.5 4.5 0 010-6.364c.203-.238.419-.474.637-.694z",
    Cpu2       = "M20.17 12.23a10 10 0 010 11.54c-1.63-1.63-4.37-1.63-6 0-.37-.37-.76-.76-1.07-1.16a10 10 0 01-1.16-1.07c-1.63-1.63-1.63-4.37 0-6 .37-.37.76-.76 1.16-1.07a10 10 0 011.07-1.16c1.63-1.63 4.37-1.63 6 0 .37.37.76.76 1.07 1.16a10 10 0 011.16 1.07c1.62 1.62 1.62 4.36 0 6z",
    Scan       = "M9 12l2 2 4-4m5.618-4.016A10 10 0 0116 8c5.523 0 10 4.477 10 10s-4.477 10-10 10S2 17.523 2 12c0-2.162.847-4.139 2.168-5.616m5.24 4.24L12 13m9-1-4.5 4.5M13 3l4.5 4.5M19 3l-4.5 4.5M3 19l4.5-4.5M11 19l4.5-4.5",
    TargetInfo = "M12 22C6.477 22 2 17.523 2 12S6.477 2 12 2s10 4.477 10 10-4.477 10-10 10zm0-20a8 8 0 100 16 8 8 0 000-16z",
}

function OrcaUI:RegisterIcon(name, imageId)
    self.IconMap[name] = imageId
end

function OrcaUI:GetIcon(name)
    return self.IconMap[name] or ""
end

-- // Window
local Window = {}
Window.__index = Window

function OrcaUI:CreateWindow(options)
    options = options or {}
    local self = setmetatable({}, Window)

    self.Name = options.Name or "OrcaUI"
    self.Size = options.Size or UDim2.new(0, 700, 0, 480)
    self.Position = options.Position or UDim2.new(0.5, -self.Size.X.Offset/2, 0.5, -self.Size.Y.Offset/2)
    self.ShowSearchBar = options.ShowSearchBar ~= false
    self.Accent = options.Accent or Theme.Accent

    local gui = GetScreenGui("OrcaUI_" .. self.Name)

    -- Main window
    self.Container = Create("Frame", {
        Name = "OrcaWindow",
        Size = self.Size,
        Position = self.Position,
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Parent = gui,
        Children = {
            RoundCorners(nil, Config.CornerRadius), -- placeholder, set below
            AddStroke(nil, Theme.Border),
        },
    })
    RoundCorners(self.Container, Config.CornerRadius)
    AddStroke(self.Container, Theme.Border, 1)

    -- Top bar
    self.TopBar = Create("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Parent = self.Container,
        Children = {
            RoundCorners(nil, UDim.new(0, 8)),
            AddPadding(nil, UDim.new(0, 14), UDim.new(0, 0), UDim.new(0, 12), UDim.new(0, 0)),
        },
    })
    RoundCorners(self.TopBar, UDim.new(0, 8))

    -- Logo / title
    self.TitleLabel = Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0, 200, 1, 0),
        BackgroundTransparency = 1,
        Text = self.Name,
        TextColor3 = Theme.Text,
        TextSize = 17,
        Font = Config.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.TopBar,
    })

    -- Window control buttons (minimize/close)
    self.Controls = Create("Frame", {
        Name = "Controls",
        Size = UDim2.new(0, 70, 1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -70, 0, 0),
        Parent = self.TopBar,
        Children = {
            AddPadding(nil, UDim.new(0, 8), UDim.new(0, 0), UDim.new(0, 8), UDim.new(0, 0)),
        },
    })

    self.MinBtn = Create("TextButton", {
        Name = "Minimize",
        Size = UDim2.new(0, 24, 0, 24),
        BackgroundColor3 = Theme.SurfaceElev,
        Text = "-",
        TextColor3 = Theme.Text,
        TextSize = 16,
        Font = Config.Font,
        Parent = self.Controls,
        Children = { RoundCorners(nil, UDim.new(0, 6)) },
    })
    RoundCorners(self.MinBtn, UDim.new(0, 6))

    self.CloseBtn = Create("TextButton", {
        Name = "Close",
        Size = UDim2.new(0, 24, 0, 24),
        BackgroundColor3 = Theme.Danger,
        Text = "×",
        TextColor3 = Color3.new(1,1,1),
        TextSize = 16,
        Font = Config.Font,
        Position = UDim2.new(0, 34, 0, 0),
        Parent = self.Controls,
        Children = { RoundCorners(nil, UDim.new(0, 6)) },
    })
    RoundCorners(self.CloseBtn, UDim.new(0, 6))

    -- Search bar
    if self.ShowSearchBar then
        self.SearchBar = Create("Frame", {
            Name = "SearchBar",
            Size = UDim2.new(0, 260, 0, 32),
            BackgroundColor3 = Theme.SurfaceElev,
            Position = UDim2.new(1, -300, 0, 4),
            Parent = self.TopBar,
            Children = {
                RoundCorners(nil, UDim.new(0, 8)),
                AddPadding(nil, UDim.new(0, 10), UDim.new(0, 0), UDim.new(0, 8), UDim.new(0, 0)),
            },
        })
        RoundCorners(self.SearchBar, UDim.new(0, 8))

        self.SearchIcon = Create("ImageLabel", {
            Name = "SearchIcon",
            Size = UDim2.new(0, 16, 0, 16),
            BackgroundTransparency = 1,
            Image = OrcaUI:GetIcon("Search"),
            ImageColor3 = Theme.TextMuted,
            Parent = self.SearchBar,
        })

        self.SearchInput = Create("TextBox", {
            Name = "SearchInput",
            Size = UDim2.new(1, -26, 1, 0),
            Position = UDim2.new(0, 24, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            PlaceholderText = "Search",
            PlaceholderColor3 = Theme.TextMuted,
            TextColor3 = Theme.Text,
            TextSize = 13,
            Font = Config.Font,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
            Parent = self.SearchBar,
        })
    end

    -- Content area (below top bar)
    self.Content = Create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, 0, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundTransparency = 1,
        Parent = self.Container,
    })

    -- Sidebar
    self.Sidebar = Create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 170, 1, 0),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0,
        Parent = self.Content,
        Children = {
            RoundCorners(nil, UDim.new(0, 0)),
            AddListLayout(nil, UDim.new(0, 6)),
            AddPadding(nil, UDim.new(0, 10), UDim.new(0, 10), UDim.new(0, 10), UDim.new(0, 10)),
        },
    })

    -- Sidebar logo
    self.SidebarLogo = Create("TextLabel", {
        Name = "SidebarLogo",
        Size = UDim2.new(1, -20, 0, 32),
        BackgroundTransparency = 1,
        Text = "OrcaUI",
        TextColor3 = self.Accent,
        TextSize = 18,
        Font = Config.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Sidebar,
    })

    -- Tab list container
    self.TabList = Create("ScrollingFrame", {
        Name = "TabList",
        Size = UDim2.new(1, -8, 1, -42),
        Position = UDim2.new(0, 0, 0, 42),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.TextMuted,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = self.Sidebar,
        Children = {
            AddListLayout(nil, UDim.new(0, 4)),
            AddPadding(nil, UDim.new(0, 4), UDim.new(0, 0), UDim.new(0, 4), UDim.new(0, 0)),
        },
    })

    -- Main area (tabs content)
    self.MainArea = Create("Frame", {
        Name = "MainArea",
        Size = UDim2.new(1, -170, 1, 0),
        Position = UDim2.new(0, 170, 0, 0),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Parent = self.Content,
    })

    self.TabContainer = Create("Frame", {
        Name = "TabContainer",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = self.MainArea,
    })

    self.Tabs = {}
    self.ActiveTab = nil
    self.TabOrder = {}

    -- Dragging
    self:_SetupDrag(self.TopBar, self.Container)

    -- Events
    self.MinBtn.MouseButton1Click:Connect(function()
        self:Minimize()
    end)
    self.CloseBtn.MouseButton1Click:Connect(function()
        self:Destroy()
    end)

    OrcaUI.Windows = OrcaUI.Windows or {}
    OrcaUI.Windows[self.Container] = self
    return self
end

function Window:_SetupDrag(dragFrame, targetFrame)
    local dragging = false
    local dragInput, mousePos, framePos

    dragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = targetFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.TouchMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            targetFrame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
        end
    end)
end

function Window:CreateTab(options)
    options = options or {}
    local tab = setmetatable({}, {__index = {
        Name = options.Name or "Tab",
        Icon = options.Icon or "Layout",
        Sections = {},
        SectionOrder = {},
        Visible = false,
    }})

    local order = #self.TabOrder + 1
    table.insert(self.TabOrder, tab)

    -- Tab button
    local btn = Create("TextButton", {
        Name = tab.Name .. "Btn",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        Text = "",
        Parent = self.TabList,
    })

    local btnIcon = Create("ImageLabel", {
        Name = "Icon",
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 8, 0.5, -8),
        BackgroundTransparency = 1,
        Image = OrcaUI:GetIcon(tab.Icon),
        ImageColor3 = Theme.TextDim,
        Parent = btn,
    })

    local btnText = Create("TextLabel", {
        Name = "Text",
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 30, 0, 0),
        BackgroundTransparency = 1,
        Text = tab.Name,
        TextColor3 = Theme.TextDim,
        TextSize = 13,
        Font = Config.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = btn,
    })

    local btnAccent = Create("Frame", {
        Name = "Accent",
        Size = UDim2.new(0, 2, 1, -10),
        Position = UDim2.new(0, 0, 0, 5),
        BackgroundColor3 = self.Accent,
        BorderSizePixel = 0,
        Parent = btn,
        Visible = false,
    })
    RoundCorners(btnAccent, UDim.new(0, 2))

    -- Content frame
    local content = Create("ScrollingFrame", {
        Name = tab.Name .. "Content",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.TextMuted,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = self.TabContainer,
        Visible = false,
        Children = {
            AddListLayout(nil, UDim.new(0, 12)),
            AddPadding(nil, UDim.new(0, 14), UDim.new(0, 14), UDim.new(0, 14), UDim.new(0, 14)),
        },
    })

    local sectionList = AddListLayout(content, UDim.new(0, 12))
    local sectionPad = AddPadding(content, UDim.new(0, 14), UDim.new(0, 14), UDim.new(0, 14), UDim.new(0, 14))

    btn.MouseButton1Click:Connect(function()
        self:SetActiveTab(tab)
    end)

    tab.Content = content
    tab.Button = btn
    tab.AccentBar = btnAccent
    tab.Icon = btnIcon
    tab.Text = btnText
    tab.Window = self

    -- Auto-select first tab
    if not self.ActiveTab then
        self:SetActiveTab(tab)
    end

    self.Tabs[tab.Name] = tab
    return tab
end

function Window:SetActiveTab(tab)
    if self.ActiveTab == tab then return end
    if self.ActiveTab then
        self.ActiveTab.Visible = false
        self.ActiveTab.Content.Visible = false
        Tween(self.ActiveTab.Button, {BackgroundTransparency = 1}, 0.15)
        Tween(self.ActiveTab.Button.Text, {TextColor3 = Theme.TextDim}, 0.15)
        Tween(self.ActiveTab.Button.Icon, {ImageColor3 = Theme.TextDim}, 0.15)
        self.ActiveTab.Button.AccentBar.Visible = false
    end

    self.ActiveTab = tab
    tab.Visible = true
    tab.Content.Visible = true
    Tween(tab.Button, {BackgroundTransparency = 0.85}, 0.15)
    Tween(tab.Button.Text, {TextColor3 = Theme.Text}, 0.15)
    Tween(tab.Button.Icon, {ImageColor3 = self.Accent}, 0.15)
    tab.Button.AccentBar.Visible = true
end

function Window:Minimize()
    self.Container.Visible = false
end

function Window:Restore()
    self.Container.Visible = true
end

function Window:Destroy()
    if self.Container then
        self.Container:Destroy()
    end
    OrcaUI.Windows[self.Container] = nil
end

-- // Section
local Section = {}
Section.__index = Section

function Section:Create(options)
    options = options or {}
    local self = setmetatable({}, Section)

    self.Name = options.Name or "Section"
    self.Side = options.Side or "Left"

    -- Section card
    self.Card = Create("Frame", {
        Name = self.Name .. "Section",
        Size = UDim2.new(0.5, -6, 0, 40),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Parent = options.Parent.Content,
        Children = {
            RoundCorners(nil, Config.CornerRadius),
            AddStroke(nil, Theme.Border),
            AddPadding(nil, UDim.new(0, 12), UDim.new(0, 10), UDim.new(0, 12), UDim.new(0, 10)),
        },
    })
    RoundCorners(self.Card, Config.CornerRadius)
    AddStroke(self.Card, Theme.Border, 1)

    -- Header
    self.Header = Create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Parent = self.Card,
        Children = {
            AddPadding(nil, UDim.new(0, 0), UDim.new(0, 0), UDim.new(0, 0), UDim.new(0, 4)),
        },
    })

    local headerLayout = Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Parent = self.Header,
    })

    if options.Icon then
        local icon = Create("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 16, 0, 16),
            BackgroundTransparency = 1,
            Image = OrcaUI:GetIcon(options.Icon),
            ImageColor3 = Theme.TextDim,
            Parent = self.Header,
        })
    end

    self.Title = Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -30, 0, 18),
        BackgroundTransparency = 1,
        Text = self.Name,
        TextColor3 = Theme.Text,
        TextSize = 14,
        Font = Config.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Header,
    })

    if options.Icon then
        self.Title.Position = UDim2.new(0, 22, 0, 0)
        self.Title.Size = UDim2.new(1, -34, 0, 18)
    end

    self.Divider = Create("Frame", {
        Name = "Divider",
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 0, 26),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Parent = self.Card,
    })

    -- Elements container
    self.Elements = Create("Frame", {
        Name = "Elements",
        Size = UDim2.new(1, 0, 1, -30),
        Position = UDim2.new(0, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent = self.Card,
        Children = {
            AddListLayout(nil, UDim.new(0, 8)),
        },
    })

    self.ElementCount = 0
    return self
end

function Section:_SizeCard()
    local layout = self.Elements:FindFirstChildOfClass("UIListLayout")
    if layout then
        local h = layout.AbsoluteContentSize.Y + 30 + 20
        self.Card.Size = UDim2.new(0.5, -6, 0, h)
    end
end

-- // Elements

function Section:CreateToggle(options)
    options = options or {}
    local default = options.Default or false
    local callback = options.Callback or function() end

    local row = Create("Frame", {
        Name = options.Name .. "Toggle",
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Parent = self.Elements,
        Children = {
            AddPadding(nil, UDim.new(0, 0), UDim.new(0, 0), UDim.new(0, 0), UDim.new(0, 0)),
        },
    })

    local layout = Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Parent = row,
    })

    local icon = nil
    if options.Icon then
        icon = Create("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 16, 0, 16),
            BackgroundTransparency = 1,
            Image = OrcaUI:GetIcon(options.Icon),
            ImageColor3 = Theme.TextDim,
            Parent = row,
        })
    end

    local label = Create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, -70, 1, 0),
        BackgroundTransparency = 1,
        Text = options.Name or "Toggle",
        TextColor3 = Theme.Text,
        TextSize = 13,
        Font = Config.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    if icon then
        label.Position = UDim2.new(0, 22, 0, 0)
        label.Size = UDim2.new(1, -74, 1, 0)
    end

    local toggle = Create("Frame", {
        Name = "Toggle",
        Size = Config.ToggleSize,
        BackgroundColor3 = default and Theme.Accent or Theme.SurfaceElev,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -40, 0.5, -9),
        Parent = row,
        Children = { RoundCorners(nil, UDim.new(1, 0)) },
    })
    RoundCorners(toggle, UDim.new(1, 0))
    AddStroke(toggle, default and Theme.Accent or Theme.Border)

    local knob = Create("Frame", {
        Name = "Knob",
        Size = UDim2.new(0, 16, 0, 16),
        Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        BackgroundColor3 = Color3.new(1,1,1),
        BorderSizePixel = 0,
        Parent = toggle,
        Children = { RoundCorners(nil, UDim.new(1, 0)) },
    })
    RoundCorners(knob, UDim.new(1, 0))

    local state = default

    local function set(value)
        state = value
        local color = value and Theme.Accent or Theme.SurfaceElev
        local strokeColor = value and Theme.Accent or Theme.Border
        local knobPos = value and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        Tween(toggle, {BackgroundColor3 = color}, 0.15)
        Tween(knob, {Position = knobPos}, 0.15)
        -- restroke
        for _, child in ipairs(toggle:GetChildren()) do
            if child:IsA("UIStroke") then
                Tween(child, {Color = strokeColor}, 0.15)
            end
        end
        callback(value)
    end

    toggle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            set(not state)
        end
    end)

    self.ElementCount = self.ElementCount + 1
    self:_SizeCard()

    return {
        Set = set,
        Get = function() return state end,
        Callback = function(cb) callback = cb end,
        SetIcon = function(i) if icon then icon.Image = OrcaUI:GetIcon(i) end end,
    }
end

function Section:CreateButton(options)
    options = options or {}
    local callback = options.Callback or function() end

    local row = Create("Frame", {
        Name = options.Name .. "Button",
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
        Parent = self.Elements,
    })

    local btn = Create("TextButton", {
        Name = "Button",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme.SurfaceElev,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Parent = row,
        Children = { RoundCorners(nil, Config.ElementRadius) },
    })
    RoundCorners(btn, Config.ElementRadius)
    AddStroke(btn, Theme.Border)

    if options.Icon then
        local icon = Create("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0, 10, 0.5, -8),
            BackgroundTransparency = 1,
            Image = OrcaUI:GetIcon(options.Icon),
            ImageColor3 = Theme.TextDim,
            Parent = btn,
        })
    end

    local text = Create("TextLabel", {
        Name = "Text",
        Size = UDim2.new(1, -50, 1, 0),
        Position = options.Icon and UDim2.new(0, 26, 0, 0) or UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = options.Name or "Button",
        TextColor3 = Theme.Text,
        TextSize = 13,
        Font = Config.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = btn,
    })

    btn.MouseEnter:Connect(function()
        Tween(btn, {BackgroundColor3 = Theme.SurfaceHover}, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, {BackgroundColor3 = Theme.SurfaceElev}, 0.15)
    end)
    btn.MouseButton1Click:Connect(function()
        Tween(btn, {BackgroundColor3 = Theme.AccentActive}, 0.05)
        task.wait(0.05)
        Tween(btn, {BackgroundColor3 = Theme.SurfaceElev}, 0.15)
        callback()
    end)

    self.ElementCount = self.ElementCount + 1
    self:_SizeCard()

    return {
        SetText = function(t) text.Text = t end,
        SetCallback = function(cb) callback = cb end,
        SetIcon = function(i)
            for _, c in ipairs(btn:GetChildren()) do
                if c:IsA("ImageLabel") and c.Name == "Icon" then
                    c.Image = OrcaUI:GetIcon(i)
                end
            end
        end,
    }
end

function Section:CreateSlider(options)
    options = options or {}
    local min = options.Min or 0
    local max = options.Max or 100
    local default = options.Default or min
    local callback = options.Callback or function() end

    default = math.clamp(default, min, max)

    local row = Create("Frame", {
        Name = options.Name .. "Slider",
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        Parent = self.Elements,
    })

    local layout = Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Parent = row,
    })

    local header = Create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Parent = row,
        Children = {
            Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Parent = row, -- will reparent below
            }),
        },
    })
    -- fix layout parent
    header:FindFirstChildOfClass("UIListLayout").Parent = header

    if options.Icon then
        Create("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 14, 0, 14),
            BackgroundTransparency = 1,
            Image = OrcaUI:GetIcon(options.Icon),
            ImageColor3 = Theme.TextDim,
            Parent = header,
        })
    end

    local label = Create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, -40, 0, 16),
        BackgroundTransparency = 1,
        Text = options.Name or "Slider",
        TextColor3 = Theme.Text,
        TextSize = 13,
        Font = Config.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })
    if options.Icon then
        label.Position = UDim2.new(0, 20, 0, 0)
        label.Size = UDim2.new(1, -42, 0, 16)
    end

    local valueLabel = Create("TextLabel", {
        Name = "Value",
        Size = UDim2.new(0, 40, 0, 16),
        BackgroundTransparency = 1,
        Text = tostring(default),
        TextColor3 = Theme.TextDim,
        TextSize = 12,
        Font = Config.Font,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = header,
    })

    local track = Create("Frame", {
        Name = "Track",
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, 26),
        BackgroundColor3 = Theme.SurfaceElev,
        BorderSizePixel = 0,
        Parent = row,
        Children = { RoundCorners(nil, UDim.new(1, 0)) },
    })
    RoundCorners(track, UDim.new(1, 0))

    local fill = Create("Frame", {
        Name = "Fill",
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = track,
        Children = { RoundCorners(nil, UDim.new(1, 0)) },
    })
    RoundCorners(fill, UDim.new(1, 0))

    local knob = Create("Frame", {
        Name = "Knob",
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7),
        BackgroundColor3 = Color3.new(1,1,1),
        BorderSizePixel = 0,
        Parent = track,
        Children = { RoundCorners(nil, UDim.new(1, 0)) },
    })
    RoundCorners(knob, UDim.new(1, 0))
    AddStroke(knob, Theme.Border)

    local value = default
    local dragging = false

    local function setValue(v)
        v = math.clamp(v, min, max)
        value = v
        local pct = (v - min) / (max - min)
        Tween(fill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.1)
        Tween(knob, {Position = UDim2.new(pct, -7, 0.5, -7)}, 0.1)
        valueLabel.Text = tostring(v)
        callback(v)
    end

    setValue(default)

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            local rel = input.Position.X - track.AbsolutePosition.X
            local pct = math.clamp(rel / track.AbsoluteSize.X, 0, 1)
            setValue(min + pct * (max - min))
        end
    end)

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.TouchMovement) then
            local rel = input.Position.X - track.AbsolutePosition.X
            local pct = math.clamp(rel / track.AbsoluteSize.X, 0, 1)
            setValue(min + pct * (max - min))
        end
    end)

    self.ElementCount = self.ElementCount + 1
    self:_SizeCard()

    return {
        Set = setValue,
        Get = function() return value end,
        SetCallback = function(cb) callback = cb end,
        SetIcon = function(i)
            for _, c in ipairs(header:GetChildren()) do
                if c:IsA("ImageLabel") and c.Name == "Icon" then
                    c.Image = OrcaUI:GetIcon(i)
                end
            end
        end,
    }
end

function Section:CreateDropdown(options)
    options = options or {}
    local optionsList = options.Options or {}
    local default = options.Default or optionsList[1] or ""
    local callback = options.Callback or function() end
    local multi = options.Multi or false

    local row = Create("Frame", {
        Name = options.Name .. "Dropdown",
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
        Parent = self.Elements,
    })

    local btn = Create("TextButton", {
        Name = "Button",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme.SurfaceElev,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Parent = row,
        Children = { RoundCorners(nil, Config.ElementRadius) },
    })
    RoundCorners(btn, Config.ElementRadius)
    AddStroke(btn, Theme.Border)

    if options.Icon then
        Create("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0, 10, 0.5, -8),
            BackgroundTransparency = 1,
            Image = OrcaUI:GetIcon(options.Icon),
            ImageColor3 = Theme.TextDim,
            Parent = btn,
        })
    end

    local label = Create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, -50, 1, 0),
        Position = options.Icon and UDim2.new(0, 26, 0, 0) or UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = options.Name or "Dropdown",
        TextColor3 = Theme.Text,
        TextSize = 13,
        Font = Config.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = btn,
    })

    local valueLabel = Create("TextLabel", {
        Name = "Value",
        Size = UDim2.new(0, 120, 1, 0),
        Position = UDim2.new(1, -130, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(default),
        TextColor3 = Theme.TextDim,
        TextSize = 12,
        Font = Config.Font,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = btn,
    })

    local arrow = Create("ImageLabel", {
        Name = "Arrow",
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(1, -22, 0.5, -6),
        BackgroundTransparency = 1,
        Image = OrcaUI:GetIcon("ChevronDown") or "rbxassetid://0",
        ImageColor3 = Theme.TextDim,
        Parent = btn,
    })

    -- Dropdown list
    local list = Create("Frame", {
        Name = "List",
        Size = UDim2.new(1, 0, 0, #optionsList * 26 + 6),
        Position = UDim2.new(0, 0, 1, 4),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Visible = false,
        Parent = row,
        Children = {
            RoundCorners(nil, Config.ElementRadius),
            AddStroke(nil, Theme.Border),
            AddListLayout(nil, UDim.new(0, 2)),
            AddPadding(nil, UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 4)),
        },
    })
    RoundCorners(list, Config.ElementRadius)
    AddStroke(list, Theme.Border, 1)

    local open = false

    local function close()
        open = false
        list.Visible = false
        Tween(arrow, {Rotation = 0}, 0.15)
        Tween(btn, {StrokeColor = Theme.Border}, 0.15)
    end

    local function openList()
        open = true
        list.Visible = true
        list.Size = UDim2.new(1, 0, 0, #optionsList * 26 + 6)
        Tween(arrow, {Rotation = 180}, 0.15)
        Tween(btn, {StrokeColor = Theme.Accent}, 0.15)
    end

    btn.MouseButton1Click:Connect(function()
        if open then close() else openList() end
    end)

    local selected = default
    local selectedSet = multi and { [default] = true } or nil

    for _, opt in ipairs(optionsList) do
        local optBtn = Create("TextButton", {
            Name = tostring(opt) .. "Opt",
            Size = UDim2.new(1, -8, 0, 24),
            BackgroundColor3 = selected == opt and Theme.Accent or Theme.SurfaceElev,
            Text = "",
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Parent = list,
            Children = { RoundCorners(nil, UDim.new(0, 4)) },
        })
        RoundCorners(optBtn, UDim.new(0, 4))

        local optText = Create("TextLabel", {
            Name = "Text",
            Size = UDim2.new(1, -8, 1, 0),
            Position = UDim2.new(0, 4, 0, 0),
            BackgroundTransparency = 1,
            Text = tostring(opt),
            TextColor3 = selected == opt and Color3.new(1,1,1) or Theme.Text,
            TextSize = 12,
            Font = Config.Font,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = optBtn,
        })

        optBtn.MouseEnter:Connect(function()
            Tween(optBtn, {BackgroundColor3 = Theme.SurfaceHover}, 0.1)
        end)
        optBtn.MouseLeave:Connect(function()
            local bg = selected == opt and Theme.Accent or Theme.SurfaceElev
            Tween(optBtn, {BackgroundColor3 = bg}, 0.1)
        end)
        optBtn.MouseButton1Click:Connect(function()
            if multi then
                if selectedSet[opt] then
                    selectedSet[opt] = nil
                else
                    selectedSet[opt] = true
                end
                local sel = {}
                for k, v in pairs(selectedSet) do
                    if v then table.insert(sel, k) end
                end
                selected = table.concat(sel, ", ")
                valueLabel.Text = selected
                callback(selected)
                -- refresh bg colors
                for _, c in ipairs(list:GetChildren()) do
                    if c:IsA("TextButton") then
                        local t = c:FindFirstChild("Text")
                        local optName = t and t.Text or ""
                        local isSel = selectedSet[optName] == true
                        c.BackgroundColor3 = isSel and Theme.Accent or Theme.SurfaceElev
                        t.TextColor3 = isSel and Color3.new(1,1,1) or Theme.Text
                    end
                end
            else
                selected = opt
                valueLabel.Text = tostring(opt)
                callback(opt)
                close()
                for _, c in ipairs(list:GetChildren()) do
                    if c:IsA("TextButton") then
                        local t = c:FindFirstChild("Text")
                        local optName = t and t.Text or ""
                        local isSel = optName == opt
                        c.BackgroundColor3 = isSel and Theme.Accent or Theme.SurfaceElev
                        t.TextColor3 = isSel and Color3.new(1,1,1) or Theme.Text
                    end
                end
            end
        end)
    end

    -- Click outside to close
    UserInputService.InputBegan:Connect(function(input)
        if open and input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mouse = UserInputService:GetMouseLocation()
            -- simple check: if not over list or btn, close
            -- (good enough for basic)
        end
    end)

    self.ElementCount = self.ElementCount + 1
    self:_SizeCard()

    return {
        Set = function(v)
            selected = v
            valueLabel.Text = tostring(v)
            callback(v)
        end,
        Get = function() return selected end,
        SetCallback = function(cb) callback = cb end,
        SetIcon = function(i)
            for _, c in ipairs(btn:GetChildren()) do
                if c:IsA("ImageLabel") and c.Name == "Icon" then
                    c.Image = OrcaUI:GetIcon(i)
                end
            end
        end,
    }
end

function Section:CreateTextbox(options)
    options = options or {}
    local default = options.Default or ""
    local placeholder = options.Placeholder or ""
    local callback = options.Callback or function() end

    local row = Create("Frame", {
        Name = options.Name .. "Textbox",
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
        Parent = self.Elements,
    })

    if options.Icon then
        Create("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0, 10, 0.5, -8),
            BackgroundTransparency = 1,
            Image = OrcaUI:GetIcon(options.Icon),
            ImageColor3 = Theme.TextDim,
            Parent = row,
        })
    end

    local label = Create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, -130, 1, 0),
        Position = options.Icon and UDim2.new(0, 26, 0, 0) or UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = options.Name or "Textbox",
        TextColor3 = Theme.Text,
        TextSize = 13,
        Font = Config.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local box = Create("TextBox", {
        Name = "Box",
        Size = UDim2.new(0, 120, 0, 24),
        Position = UDim2.new(1, -130, 0.5, -12),
        BackgroundColor3 = Theme.SurfaceElev,
        Text = default,
        PlaceholderText = placeholder,
        PlaceholderColor3 = Theme.TextMuted,
        TextColor3 = Theme.Text,
        TextSize = 12,
        Font = Config.Font,
        BorderSizePixel = 0,
        Parent = row,
        Children = { RoundCorners(nil, UDim.new(0, 6)) },
    })
    RoundCorners(box, UDim.new(0, 6))
    AddStroke(box, Theme.Border)

    box.FocusLost:Connect(function(enterPressed)
        callback(box.Text, enterPressed)
    end)

    self.ElementCount = self.ElementCount + 1
    self:_SizeCard()

    return {
        Set = function(t) box.Text = t end,
        Get = function() return box.Text end,
        SetCallback = function(cb) callback = cb end,
        SetIcon = function(i)
            for _, c in ipairs(row:GetChildren()) do
                if c:IsA("ImageLabel") and c.Name == "Icon" then
                    c.Image = OrcaUI:GetIcon(i)
                end
            end
        end,
    }
end

function Section:CreateLabel(options)
    options = options or {}
    local text = options.Text or options.Name or "Label"

    local row = Create("Frame", {
        Name = options.Name .. "Label",
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Parent = self.Elements,
    })

    if options.Icon then
        Create("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 14, 0, 14),
            Position = UDim2.new(0, 8, 0.5, -7),
            BackgroundTransparency = 1,
            Image = OrcaUI:GetIcon(options.Icon),
            ImageColor3 = Theme.TextDim,
            Parent = row,
        })
    end

    local label = Create("TextLabel", {
        Name = "Text",
        Size = UDim2.new(1, -30, 1, 0),
        Position = options.Icon and UDim2.new(0, 22, 0, 0) or UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.TextDim,
        TextSize = 12,
        Font = Config.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    self.ElementCount = self.ElementCount + 1
    self:_SizeCard()

    return {
        Set = function(t) label.Text = t end,
        Get = function() return label.Text end,
        SetIcon = function(i)
            for _, c in ipairs(row:GetChildren()) do
                if c:IsA("ImageLabel") and c.Name == "Icon" then
                    c.Image = OrcaUI:GetIcon(i)
                end
            end
        end,
    }
end

function Section:CreateKeybind(options)
    options = options or {}
    local default = options.Default or Enum.KeyCode.Unknown
    local callback = options.Callback or function() end

    local row = Create("Frame", {
        Name = options.Name .. "Keybind",
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Parent = self.Elements,
    })

    if options.Icon then
        Create("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0, 10, 0.5, -8),
            BackgroundTransparency = 1,
            Image = OrcaUI:GetIcon(options.Icon),
            ImageColor3 = Theme.TextDim,
            Parent = row,
        })
    end

    local label = Create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, -120, 1, 0),
        Position = options.Icon and UDim2.new(0, 26, 0, 0) or UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = options.Name or "Keybind",
        TextColor3 = Theme.Text,
        TextSize = 13,
        Font = Config.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local keyBtn = Create("TextButton", {
        Name = "Key",
        Size = UDim2.new(0, 100, 0, 24),
        Position = UDim2.new(1, -110, 0.5, -12),
        BackgroundColor3 = Theme.SurfaceElev,
        Text = default.Name or "None",
        TextColor3 = Theme.Text,
        TextSize = 12,
        Font = Config.Font,
        BorderSizePixel = 0,
        Parent = row,
        Children = { RoundCorners(nil, UDim.new(0, 6)) },
    })
    RoundCorners(keyBtn, UDim.new(0, 6))
    AddStroke(keyBtn, Theme.Border)

    local binding = false
    local currentKey = default

    keyBtn.MouseButton1Click:Connect(function()
        binding = true
        keyBtn.Text = "..."
        Tween(keyBtn, {StrokeColor = Theme.Accent}, 0.15)
    end)

    UserInputService.InputBegan:Connect(function(input)
        if not binding then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            currentKey = input.KeyCode
            keyBtn.Text = currentKey.Name
            binding = false
            Tween(keyBtn, {StrokeColor = Theme.Border}, 0.15)
            callback(currentKey)
        end
    end)

    self.ElementCount = self.ElementCount + 1
    self:_SizeCard()

    return {
        Set = function(k) currentKey = k; keyBtn.Text = k.Name end,
        Get = function() return currentKey end,
        SetCallback = function(cb) callback = cb end,
        SetIcon = function(i)
            for _, c in ipairs(row:GetChildren()) do
                if c:IsA("ImageLabel") and c.Name == "Icon" then
                    c.Image = OrcaUI:GetIcon(i)
                end
            end
        end,
    }
end

function Section:CreateColorpicker(options)
    options = options or {}
    local default = options.Default or Color3.new(1, 1, 1)
    local callback = options.Callback or function() end

    local row = Create("Frame", {
        Name = options.Name .. "Colorpicker",
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Parent = self.Elements,
    })

    if options.Icon then
        Create("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0, 10, 0.5, -8),
            BackgroundTransparency = 1,
            Image = OrcaUI:GetIcon(options.Icon),
            ImageColor3 = Theme.TextDim,
            Parent = row,
        })
    end

    local label = Create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, -130, 1, 0),
        Position = options.Icon and UDim2.new(0, 26, 0, 0) or UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = options.Name or "Colorpicker",
        TextColor3 = Theme.Text,
        TextSize = 13,
        Font = Config.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local colorBox = Create("Frame", {
        Name = "Color",
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -30, 0.5, -10),
        BackgroundColor3 = default,
        BorderSizePixel = 0,
        Parent = row,
        Children = { RoundCorners(nil, UDim.new(0, 4)) },
    })
    RoundCorners(colorBox, UDim.new(0, 4))
    AddStroke(colorBox, Theme.Border)

    -- Simple picker popup
    local picker = Create("Frame", {
        Name = "Picker",
        Size = UDim2.new(0, 180, 0, 180),
        Position = UDim2.new(1, 10, 0, -20),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Visible = false,
        Parent = row,
        Children = {
            RoundCorners(nil, Config.CornerRadius),
            AddStroke(nil, Theme.Border),
        },
    })
    RoundCorners(picker, Config.CornerRadius)
    AddStroke(picker, Theme.Border, 1)

    local open = false
    colorBox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            open = not open
            picker.Visible = open
        end
    end)

    self.ElementCount = self.ElementCount + 1
    self:_SizeCard()

    return {
        Set = function(c) colorBox.BackgroundColor3 = c; callback(c) end,
        Get = function() return colorBox.BackgroundColor3 end,
        SetCallback = function(cb) callback = cb end,
        SetIcon = function(i)
            for _, c in ipairs(row:GetChildren()) do
                if c:IsA("ImageLabel") and c.Name == "Icon" then
                    c.Image = OrcaUI:GetIcon(i)
                end
            end
        end,
    }
end

function Section:CreateSeparator()
    local sep = Create("Frame", {
        Name = "Separator",
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Parent = self.Elements,
    })
    self.ElementCount = self.ElementCount + 1
    self:_SizeCard()
    return sep
end

function Section:CreateParagraph(options)
    options = options or {}
    local title = options.Title or "Paragraph"
    local content = options.Content or ""

    local card = Create("Frame", {
        Name = title .. "Paragraph",
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Parent = self.Elements,
        Children = {
            RoundCorners(nil, Config.ElementRadius),
            AddStroke(nil, Theme.Border),
            AddPadding(nil, UDim.new(0, 10), UDim.new(0, 8), UDim.new(0, 10), UDim.new(0, 8)),
        },
    })
    RoundCorners(card, Config.ElementRadius)
    AddStroke(card, Theme.Border, 1)

    local t = Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 13,
        Font = Config.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })

    local c = Create("TextLabel", {
        Name = "Content",
        Size = UDim2.new(1, 0, 0, 42),
        Position = UDim2.new(0, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = content,
        TextColor3 = Theme.TextDim,
        TextSize = 12,
        Font = Config.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = card,
    })

    self.ElementCount = self.ElementCount + 1
    self:_SizeCard()

    return {
        SetTitle = function(ti) t.Text = ti end,
        SetContent = function(co) c.Text = co end,
    }
end

-- // Notifications
function OrcaUI:Notify(options)
    options = options or {}
    local title = options.Title or "OrcaUI"
    local text = options.Text or ""
    local duration = options.Duration or 3
    local type = options.Type or "Info"

    local colors = {
        Info = Theme.Info,
        Success = Theme.Success,
        Warning = Theme.Warning,
        Danger = Theme.Danger,
    }

    local gui = GetScreenGui("OrcaUI_Notifications")
    local notif = Create("Frame", {
        Name = "Notification",
        Size = UDim2.new(0, 260, 0, 70),
        BackgroundColor3 = Theme.Surface,
        Position = UDim2.new(1, 10, 1, -10),
        AnchorPoint = Vector2.new(1, 1),
        Parent = gui,
        Children = {
            RoundCorners(nil, Config.CornerRadius),
            AddStroke(nil, colors[type] or Theme.Info),
            AddPadding(nil, UDim.new(0, 10), UDim.new(0, 10), UDim.new(0, 10), UDim.new(0, 10)),
        },
    })
    RoundCorners(notif, Config.CornerRadius)
    AddStroke(notif, colors[type] or Theme.Info, 1)

    local bar = Create("Frame", {
        Name = "Bar",
        Size = UDim2.new(0, 3, 1, -20),
        Position = UDim2.new(0, 0, 0, 10),
        BackgroundColor3 = colors[type] or Theme.Info,
        Parent = notif,
        Children = { RoundCorners(nil, UDim.new(0, 2)) },
    })
    RoundCorners(bar, UDim.new(0, 2))

    local t = Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -20, 0, 16),
        Position = UDim2.new(0, 14, 0, 4),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 13,
        Font = Config.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif,
    })

    local d = Create("TextLabel", {
        Name = "Desc",
        Size = UDim2.new(1, -20, 0, 34),
        Position = UDim2.new(0, 14, 0, 20),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.TextDim,
        TextSize = 12,
        Font = Config.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = notif,
    })

    Tween(notif, {Position = UDim2.new(1, -270, 1, -10)}, 0.25)

    task.delay(duration, function()
        Tween(notif, {Position = UDim2.new(1, 10, 1, -10)}, 0.25)
        task.wait(0.25)
        notif:Destroy()
    end)

    return notif
end

-- // Expose
OrcaUI.Window = Window
OrcaUI.Section = Section

return OrcaUI
