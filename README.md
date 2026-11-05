# OrcaUI

A modern, clean Roblox UI library inspired by **Airflow**.  
Built for **Potassium** and compatible with most Lua executors (Synapse X, ScriptWare, Krnl, etc.).

## Design

- Dark modern theme with rounded corners & subtle borders
- Sidebar navigation with tabs + search bar (Airflow-style)
- Section cards with headers
- Toggle, Button, Slider, Dropdown, Textbox, Label, Keybind, Colorpicker, Paragraph
- Tween-based animations
- Executor-compatible: **no external HTTP**, **no `getcustomasset` required**

## Installation

```lua
local OrcaUI = loadstring(game:HttpGet("YOUR_RAW_GITHUB_URL/OrcaUI.lua"))()
```

Or require it directly if you have the file in your workspace.

## Quick Start

```lua
local OrcaUI = loadstring(game:HttpGet("..."))()

-- Register Lucid icon ImageIds (upload your lucide decals as Roblox decals/assets)
OrcaUI:RegisterIcon("Home", "rbxassetid://0")
OrcaUI:RegisterIcon("Settings", "rbxassetid://0")
OrcaUI:RegisterIcon("User", "rbxassetid://0")

local Window = OrcaUI:CreateWindow({
    Name = "OrcaUI",
    Size = UDim2.new(0, 720, 0, 500),
    Accent = Color3.fromRGB(99, 102, 241),
    ShowSearchBar = true,
})

local Tab = Window:CreateTab({Name = "Main", Icon = "Home"})
local Section = Tab:CreateSection({Name = "Features", Icon = "Layout"})

Section:CreateToggle({
    Name = "Godmode",
    Icon = "Shield",
    Default = false,
    Callback = function(state) print(state) end,
})

Section:CreateButton({
    Name = "Reset",
    Icon = "RotateCcw",
    Callback = function() print("reset") end,
})

Section:CreateSlider({
    Name = "Walkspeed",
    Min = 16,
    Max = 200,
    Default = 16,
    Callback = function(val) print(val) end,
})
```

## Lucid Icons

OrcaUI includes SVG path data for Lucid icons (in `OrcaUI.LucidIcons`) for reference.  
To display icons, register your own decal ImageIds:

```lua
OrcaUI:RegisterIcon("Name", "rbxassetid://123456789")
```

Then pass `Icon = "Name"` to any element. If no icon is registered, the element shows without an icon (no broken images).

## API

### `OrcaUI:CreateWindow(options)`
- `Name` (string) — window title
- `Size` (UDim2)
- `Position` (UDim2)
- `Accent` (Color3) — theme accent color
- `ShowSearchBar` (bool)

Returns a `Window` object.

### `Window:CreateTab(options)`
- `Name` (string)
- `Icon` (string) — registered icon name

Returns a `Tab` object.

### `Tab:CreateSection(options)`
- `Name` (string)
- `Icon` (string)

Returns a `Section` object.

### Section Elements

| Method | Key Options |
|--------|-------------|
| `CreateToggle` | `Name`, `Icon`, `Default` (bool), `Callback` |
| `CreateButton` | `Name`, `Icon`, `Callback` |
| `CreateSlider` | `Name`, `Icon`, `Min`, `Max`, `Default`, `Callback` |
| `CreateDropdown` | `Name`, `Icon`, `Options` (table), `Default`, `Callback`, `Multi` |
| `CreateTextbox` | `Name`, `Icon`, `Default`, `Placeholder`, `Callback(text, enter)` |
| `CreateLabel` | `Text` / `Name`, `Icon` |
| `CreateKeybind` | `Name`, `Icon`, `Default` (Enum.KeyCode), `Callback(key)` |
| `CreateColorpicker` | `Name`, `Icon`, `Default` (Color3), `Callback(color)` |
| `CreateSeparator` | — |
| `CreateParagraph` | `Title`, `Content` |

### `OrcaUI:Notify(options)`
Toast notification.
- `Title`, `Text`, `Duration` (seconds), `Type` (`"Info"` \| `"Success"` \| `"Warning"` \| `"Danger"`)

## Executor Compatibility

- Uses `game:GetService` only
- Falls back from `CoreGui` to `PlayerGui` automatically
- No external network requests
- No `getcustomasset` / `readfile` dependencies

## Files

- `OrcaUI.lua` — the library module
- `example.lua` — full demo script showing all elements
- `README.md` — this file

## Todo (future improvements)

- Full Lucid icon rendering (canvas/SVG or bundled decals)
- Theme presets & custom color picker window
- Window minimize/restore animation
- Search filtering within tabs
- Config save/load (JSON)
