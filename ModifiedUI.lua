--[[
    LiquidUI - Modern Clean Core Library v3.4.0
    - Fixed minimize logic to compact frame strictly to topbar size
    - Unclamped screen boundaries: drag freely anywhere including below/offscreen
    - Added UI Corner refinements & UIGradients across main components & buttons
    - Clean single-button bottom-right resize grip handle
]]

local LiquidUI = {}
LiquidUI.__index = LiquidUI

LiquidUI.Version = "3.4.0"

LiquidUI.Theme = {
    Background = Color3.fromRGB(8, 9, 12),
    Surface = Color3.fromRGB(14, 15, 20),
    SurfaceLight = Color3.fromRGB(22, 24, 31),
    SurfaceHover = Color3.fromRGB(30, 33, 43),
    Accent = Color3.fromRGB(45, 130, 215),
    AccentLight = Color3.fromRGB(140, 200, 255),
    Text = Color3.fromRGB(245, 247, 250),
    SubText = Color3.fromRGB(155, 163, 177),
    Border = Color3.fromRGB(60, 68, 85),
    BorderLight = Color3.fromRGB(100, 115, 140),
    Success = Color3.fromRGB(80, 220, 155),
    Danger = Color3.fromRGB(255, 100, 115)
}

local LucideIcons = {
    ["home"] = "rbxassetid://10723407389",
    ["zap"] = "rbxassetid://10723371539",
    ["map-pin"] = "rbxassetid://10723346959",
    ["settings"] = "rbxassetid://10723345518",
    ["more-horizontal"] = "rbxassetid://10723345152",
    ["user"] = "rbxassetid://10723343321",
    ["bell"] = "rbxassetid://10723343881",
    ["shield"] = "rbxassetid://10723345388"
}

function LiquidUI:GetIcon(iconName)
    if not iconName then return "" end
    if type(iconName) == "string" and iconName:sub(1, 12) == "rbxassetid://" then
        return iconName
    end
    return LucideIcons[string.lower(iconName)] or "rbxassetid://10723345518"
end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer

local function Create(className, properties, children)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = object
    end
    return object
end

local function Corner(object, radius)
    return Create("UICorner", {
        CornerRadius = UDim.new(0, radius or 10),
        Parent = object
    })
end

local function Stroke(object, color, transparency, thickness)
    return Create("UIStroke", {
        Color = color or LiquidUI.Theme.Border,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = object
    })
end

local function AddPadding(object, left, right, top, bottom)
    return Create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        Parent = object
    })
end

local function PlayTween(object, duration, properties)
    if not object or not object.Parent then return end
    local tween = TweenService:Create(
        object,
        TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        properties
    )
    tween:Play()
    return tween
end

local function Label(parent, text, textSize, color, bold)
    return Create("TextLabel", {
        BackgroundTransparency = 1,
        Text = tostring(text or ""),
        TextColor3 = color or LiquidUI.Theme.Text,
        TextSize = textSize or 13,
        Font = bold and Enum.Font.GothamSemibold or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Size = UDim2.new(1, 0, 0, 22),
        Parent = parent
    })
end

local function Callback(callback, ...)
    if type(callback) ~= "function" then return end
    local args = table.pack(...)
    task.spawn(function()
        local ok, err = pcall(function()
            callback(table.unpack(args, 1, args.n))
        end)
        if not ok then warn("[LiquidUI] Callback error:", err) end
    end)
end

local function Viewport()
    local camera = workspace.CurrentCamera
    return camera and camera.ViewportSize or Vector2.new(800, 600)
end

local function Clamp(number, minimum, maximum)
    return math.max(minimum, math.min(number, maximum))
end

local function IsPointer(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

function LiquidUI:CreateWindow(options)
    options = options or {}

    local theme = self.Theme
    local connections = {}
    local tabs = {}
    local toasts = {}
    local currentTab
    local destroyed = false
    local minimized = false
    local windowVisible = true

    local minimum = options.MinSize or Vector2.new(480, 320)
    local maximum = options.MaxSize or Vector2.new(1200, 800)
    local requestedSize = options.Size or UDim2.fromOffset(720, 520)

    local viewport = Viewport()
    local width = Clamp(requestedSize.X.Offset, minimum.X, math.max(minimum.X, viewport.X))
    local height = Clamp(requestedSize.Y.Offset, minimum.Y, math.max(minimum.Y, viewport.Y))

    local savedSize = Vector2.new(width, height)

    local gui = Create("ScreenGui", {
        Name = "LiquidUI_Clean",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    local parent = options.Parent
    if parent then
        gui.Parent = parent
    else
        local success = pcall(function() gui.Parent = CoreGui end)
        if not success then gui.Parent = Player:WaitForChild("PlayerGui") end
    end

    local function Connect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(connections, connection)
        return connection
    end

    -- Floating Toggle Button (Right Side)
    local FloatingToggle = Create("TextButton", {
        Name = "FloatingToggle",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(44, 44),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 500,
        Parent = gui
    })

    Corner(FloatingToggle, 10)
    Stroke(FloatingToggle, theme.BorderLight, 0.3, 1)

    Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 28, 38)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 13, 18))
        }),
        Rotation = 45,
        Parent = FloatingToggle
    })

    local ToggleIcon = Create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(22, 22),
        BackgroundTransparency = 1,
        Image = LiquidUI:GetIcon(options.Logo or "home"),
        ImageColor3 = theme.AccentLight,
        ZIndex = 501,
        Parent = FloatingToggle
    })

    -- Main GUI Frame
    local window = Create("Frame", {
        Name = "MainWindow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(viewport.X / 2, viewport.Y / 2),
        Size = UDim2.fromOffset(width, height),
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 2,
        Parent = gui
    })

    Corner(window, 14)
    Stroke(window, theme.Border, 0.2, 1)

    Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(16, 18, 24)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8, 9, 12)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 14, 18))
        }),
        Rotation = 30,
        Parent = window
    })

    local topbar = Create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundColor3 = Color3.fromRGB(10, 11, 15),
        BorderSizePixel = 0,
        Active = true,
        ZIndex = 3,
        Parent = window
    })

    Corner(topbar, 14)

    Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 22, 30)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 9, 12))
        }),
        Rotation = 90,
        Parent = topbar
    })

    local logoBox = Create("Frame", {
        Position = UDim2.fromOffset(14, 10),
        Size = UDim2.fromOffset(40, 40),
        BackgroundColor3 = theme.SurfaceLight,
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = topbar
    })

    Corner(logoBox, 9)
    Stroke(logoBox, theme.BorderLight, 0.3, 1)

    local logoText = Label(logoBox, options.Logo or "L", 18, theme.AccentLight, true)
    logoText.TextXAlignment = Enum.TextXAlignment.Center
    logoText.Size = UDim2.fromScale(1, 1)
    logoText.ZIndex = 5

    local titleLabel = Label(topbar, options.Title or "LiquidUI", 14, theme.Text, true)
    titleLabel.Position = UDim2.fromOffset(64, 10)
    titleLabel.Size = UDim2.new(1, -160, 0, 20)
    titleLabel.ZIndex = 4

    local subtitle = Label(topbar, options.Subtitle or "Toolkit Suite", 11, theme.SubText, false)
    subtitle.Position = UDim2.fromOffset(64, 30)
    subtitle.Size = UDim2.new(1, -160, 0, 18)
    subtitle.ZIndex = 4

    local minimizeButton = Create("TextButton", {
        Position = UDim2.new(1, -76, 0, 15),
        Size = UDim2.fromOffset(28, 30),
        BackgroundTransparency = 1,
        Text = "−",
        TextColor3 = theme.SubText,
        TextSize = 22,
        Font = Enum.Font.Gotham,
        AutoButtonColor = false,
        ZIndex = 5,
        Parent = topbar
    })

    local closeButton = Create("TextButton", {
        Position = UDim2.new(1, -42, 0, 15),
        Size = UDim2.fromOffset(28, 30),
        BackgroundTransparency = 1,
        Text = "×",
        TextColor3 = theme.Text,
        TextSize = 22,
        Font = Enum.Font.Gotham,
        AutoButtonColor = false,
        ZIndex = 5,
        Parent = topbar
    })

    local sidebar = Create("Frame", {
        Name = "Sidebar",
        Position = UDim2.fromOffset(0, 60),
        Size = UDim2.new(0, 160, 1, -60),
        BackgroundColor3 = Color3.fromRGB(7, 8, 11),
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = window
    })

    local tabList = Create("ScrollingFrame", {
        Name = "TabList",
        Position = UDim2.fromOffset(8, 10),
        Size = UDim2.new(1, -16, 1, -20),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 4,
        Parent = sidebar
    })

    Create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tabList
    })

    local content = Create("Frame", {
        Name = "Content",
        Position = UDim2.new(0, 160, 0, 60),
        Size = UDim2.new(1, -160, 1, -60),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 3,
        Parent = window
    })

    local header = Create("Frame", {
        Position = UDim2.fromOffset(16, 12),
        Size = UDim2.new(1, -32, 0, 40),
        BackgroundTransparency = 1,
        ZIndex = 4,
        Parent = content
    })

    local pageTitle = Label(header, "Dashboard", 16, theme.Text, true)
    pageTitle.Size = UDim2.new(1, 0, 0, 22)

    local pageSubtitle = Label(header, "Active workspace system.", 11, theme.SubText, false)
    pageSubtitle.Position = UDim2.fromOffset(0, 21)
    pageSubtitle.Size = UDim2.new(1, 0, 0, 16)

    local pageHolder = Create("Frame", {
        Name = "Pages",
        Position = UDim2.fromOffset(14, 56),
        Size = UDim2.new(1, -28, 1, -66),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 4,
        Parent = content
    })

    -- Ergonomic Single Resize Handle
    local resizeGrip = Create("TextButton", {
        Name = "ResizeGrip",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -3, 1, -3),
        Size = UDim2.fromOffset(18, 18),
        BackgroundTransparency = 1,
        Text = "◢",
        TextSize = 12,
        TextColor3 = theme.SubText,
        AutoButtonColor = false,
        Active = true,
        ZIndex = 10,
        Parent = window
    })

    local function SelectTab(tab)
        if destroyed or not tab then return end
        currentTab = tab
        pageTitle.Text = tab.Name
        pageSubtitle.Text = tab.Description

        for _, item in ipairs(tabs) do
            local selected = item == tab
            item.Page.Visible = selected
            item.Button.BackgroundColor3 = selected and theme.SurfaceHover or theme.Surface
            item.Indicator.BackgroundTransparency = selected and 0 or 1
            item.Label.TextColor3 = selected and theme.Text or theme.SubText
            item.Icon.ImageColor3 = selected and theme.AccentLight or theme.SubText
        end
    end

    local function MakeCard(parent, cardHeight)
        local card = Create("Frame", {
            Size = UDim2.new(1, 0, 0, cardHeight or 46),
            BackgroundColor3 = theme.Surface,
            BorderSizePixel = 0,
            Parent = parent
        })

        Corner(card, 9)
        Stroke(card, theme.Border, 0.5, 1)

        Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 24, 32)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 13, 17))
            }),
            Rotation = 45,
            Parent = card
        })

        return card
    end

    local function Handle(instance, methods)
        local result = { Instance = instance }
        for key, value in pairs(methods or {}) do result[key] = value end
        return result
    end

    local windowObject = {
        Instance = window,
        ScreenGui = gui,
        Tabs = tabs
    }

    function windowObject:CreateTab(name, description, iconName)
        name = tostring(name or ("Tab " .. (#tabs + 1)))

        local tabButton = Create("TextButton", {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = theme.Surface,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Parent = tabList
        })

        Corner(tabButton, 8)

        local indicator = Create("Frame", {
            Position = UDim2.fromOffset(0, 6),
            Size = UDim2.new(0, 3, 1, -12),
            BackgroundColor3 = theme.AccentLight,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = tabButton
        })

        Corner(indicator, 2)

        local icon = Create("ImageLabel", {
            Position = UDim2.fromOffset(10, 10),
            Size = UDim2.fromOffset(16, 16),
            BackgroundTransparency = 1,
            Image = LiquidUI:GetIcon(iconName or "home"),
            ImageColor3 = theme.SubText,
            Parent = tabButton
        })

        local tabLabel = Label(tabButton, name, 12, theme.SubText, true)
        tabLabel.Position = UDim2.fromOffset(34, 0)
        tabLabel.Size = UDim2.new(1, -38, 1, 0)
        tabLabel.TextTruncate = Enum.TextTruncate.AtEnd

        local page = Create("ScrollingFrame", {
            Name = name .. "Page",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = theme.BorderLight,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            Parent = pageHolder
        })

        AddPadding(page, 0, 4, 0, 6)

        Create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = page
        })

        local tab = {
            Name = name,
            Description = description or ("Controls for " .. name),
            Button = tabButton,
            Indicator = indicator,
            Icon = icon,
            Label = tabLabel,
            Page = page
        }

        table.insert(tabs, tab)

        Connect(tabButton.Activated, function() SelectTab(tab) end)

        local api = {}

        function api:AddSection(sectionName)
            local section = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
                Parent = page
            })

            local text = Label(section, sectionName, 12, theme.AccentLight, true)
            text.Position = UDim2.fromOffset(2, 0)
            text.Size = UDim2.new(1, -4, 1, 0)

            return section
        end

        function api:CreateButton(config)
            config = config or {}
            local card = MakeCard(page, config.Height or 44)

            local control = Create("TextButton", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                Parent = card
            })

            local text = Label(card, config.Name or "Button", 12, theme.Text, true)
            text.Position = UDim2.fromOffset(12, 0)
            text.Size = UDim2.new(1, -40, 1, 0)

            Connect(control.MouseEnter, function() PlayTween(card, 0.12, { BackgroundColor3 = theme.SurfaceHover }) end)
            Connect(control.MouseLeave, function() PlayTween(card, 0.12, { BackgroundColor3 = theme.Surface }) end)
            Connect(control.Activated, function() Callback(config.Callback) end)

            return Handle(card, {
                SetText = function(_, v) text.Text = tostring(v) end
            })
        end

        function api:CreateToggle(config)
            config = config or {}
            local value = config.Default == true
            local card = MakeCard(page, config.Height or 52)

            local text = Label(card, config.Name or "Toggle", 12, theme.Text, true)
            text.Position = UDim2.fromOffset(12, 6)
            text.Size = UDim2.new(1, -75, 0, 18)

            if config.Description then
                local desc = Label(card, config.Description, 10, theme.SubText, false)
                desc.Position = UDim2.fromOffset(12, 24)
                desc.Size = UDim2.new(1, -75, 0, 16)
            end

            local switch = Create("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -12, 0.5, 0),
                Size = UDim2.fromOffset(36, 20),
                BackgroundColor3 = value and theme.Accent or Color3.fromRGB(40, 40, 48),
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                Parent = card
            })

            Corner(switch, 10)

            local knob = Create("Frame", {
                Position = value and UDim2.new(1, -17, 0, 2) or UDim2.fromOffset(2, 2),
                Size = UDim2.fromOffset(16, 16),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Parent = switch
            })

            Corner(knob, 8)

            local function SetValue(nv, fire)
                value = nv == true
                PlayTween(switch, 0.12, { BackgroundColor3 = value and theme.Accent or Color3.fromRGB(40, 40, 48) })
                PlayTween(knob, 0.12, { Position = value and UDim2.new(1, -17, 0, 2) or UDim2.fromOffset(2, 2) })
                if fire ~= false then Callback(config.Callback, value) end
            end

            Connect(switch.Activated, function() SetValue(not value, true) end)

            return Handle(card, {
                SetValue = SetValue,
                GetValue = function() return value end
            })
        end

        function api:CreateSlider(config)
            config = config or {}
            local minVal = tonumber(config.Min) or 0
            local maxVal = tonumber(config.Max) or 100
            local value = Clamp(tonumber(config.Default) or minVal, minVal, maxVal)
            local card = MakeCard(page, 64)

            local text = Label(card, config.Name or "Slider", 12, theme.Text, true)
            text.Position = UDim2.fromOffset(12, 6)
            text.Size = UDim2.new(1, -70, 0, 18)

            local valLabel = Label(card, tostring(value), 11, theme.AccentLight, true)
            valLabel.TextXAlignment = Enum.TextXAlignment.Right
            valLabel.Position = UDim2.new(1, -60, 0, 6)
            valLabel.Size = UDim2.fromOffset(48, 18)

            local bar = Create("Frame", {
                Position = UDim2.new(0, 12, 0, 38),
                Size = UDim2.new(1, -24, 0, 5),
                BackgroundColor3 = Color3.fromRGB(35, 35, 42),
                BorderSizePixel = 0,
                Active = true,
                Parent = card
            })

            Corner(bar, 3)

            local function Ratio(v)
                if maxVal == minVal then return 0 end
                return Clamp((v - minVal) / (maxVal - minVal), 0, 1)
            end

            local fill = Create("Frame", {
                Size = UDim2.new(Ratio(value), 0, 1, 0),
                BackgroundColor3 = theme.Accent,
                BorderSizePixel = 0,
                Parent = bar
            })

            Corner(fill, 3)

            local function SetValue(nv, fire)
                value = Clamp(tonumber(nv) or minVal, minVal, maxVal)
                local ratio = Ratio(value)
                fill.Size = UDim2.new(ratio, 0, 1, 0)
                valLabel.Text = tostring(value)
                if fire ~= false then Callback(config.Callback, value) end
            end

            local dragging = false
            Connect(bar.InputBegan, function(input) if IsPointer(input) then dragging = true end end)
            Connect(UserInputService.InputChanged, function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local ratio = Clamp((input.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
                    SetValue(minVal + (maxVal - minVal) * ratio)
                end
            end)
            Connect(UserInputService.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
            end)

            return Handle(card, {
                SetValue = SetValue,
                GetValue = function() return value end
            })
        end

        function api:CreateInput(config)
            config = config or {}
            local card = MakeCard(page, 62)

            local text = Label(card, config.Name or "Input", 12, theme.Text, true)
            text.Position = UDim2.fromOffset(12, 4)
            text.Size = UDim2.new(1, -24, 0, 18)

            local box = Create("TextBox", {
                Position = UDim2.fromOffset(10, 26),
                Size = UDim2.new(1, -20, 0, 26),
                BackgroundColor3 = theme.Background,
                BorderSizePixel = 0,
                Text = tostring(config.Default or ""),
                PlaceholderText = config.Placeholder or "Enter value...",
                PlaceholderColor3 = theme.SubText,
                TextColor3 = theme.Text,
                TextSize = 11,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = card
            })

            Corner(box, 6)
            Stroke(box, theme.Border, 0.7, 1)
            AddPadding(box, 8, 8, 0, 0)

            Connect(box.FocusLost, function(enter) Callback(config.Callback, box.Text, enter) end)

            return Handle(card, {
                GetValue = function() return box.Text end,
                SetValue = function(_, v) box.Text = tostring(v or "") end
            })
        end

        SelectTab(#tabs == 1 and tab or currentTab)
        return api
    end

    windowObject.Tab = windowObject.CreateTab

    -- Minimal Toast Notifications
    function windowObject:Notify(config)
        if destroyed then return end
        if type(config) ~= "table" then config = { Title = "Notice", Content = tostring(config) } end

        local toast = Create("Frame", {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, 300, 1, -20),
            Size = UDim2.fromOffset(260, 56),
            BackgroundColor3 = theme.Surface,
            BorderSizePixel = 0,
            ZIndex = 900,
            Parent = gui
        })

        Corner(toast, 10)
        Stroke(toast, theme.BorderLight, 0.3, 1)

        Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 28, 38)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 13, 18))
            }),
            Rotation = 45,
            Parent = toast
        })

        local title = Label(toast, config.Title or "Notice", 12, theme.Text, true)
        title.Position = UDim2.fromOffset(12, 8)
        title.Size = UDim2.new(1, -20, 0, 16)

        local body = Label(toast, config.Content or "", 10, theme.SubText, false)
        body.Position = UDim2.fromOffset(12, 26)
        body.Size = UDim2.new(1, -20, 0, 22)

        table.insert(toasts, toast)

        PlayTween(toast, 0.2, { Position = UDim2.new(1, -16, 1, -20) })

        task.delay(math.max(tonumber(config.Duration) or 3, 1), function()
            if not toast.Parent then return end
            PlayTween(toast, 0.18, { Position = UDim2.new(1, 300, 1, -20), BackgroundTransparency = 1 })
            task.delay(0.2, function() if toast.Parent then toast:Destroy() end end)
        end)
    end

    -- Clean Compact Minimize Logic (Collapses down to Topbar size only)
    function windowObject:Minimize()
        minimized = not minimized
        sidebar.Visible = not minimized
        content.Visible = not minimized
        resizeGrip.Visible = not minimized

        PlayTween(window, 0.18, {
            Size = minimized and UDim2.fromOffset(window.AbsoluteSize.X, 60) or UDim2.fromOffset(savedSize.X, savedSize.Y)
        })
    end

    function windowObject:Toggle()
        windowVisible = not windowVisible
        window.Visible = windowVisible
    end

    function windowObject:Destroy()
        destroyed = true
        for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
        gui:Destroy()
    end

    Connect(FloatingToggle.Activated, function()
        windowVisible = not windowVisible
        window.Visible = windowVisible
    end)

    Connect(minimizeButton.Activated, function() windowObject:Minimize() end)
    Connect(closeButton.Activated, function() windowObject:Destroy() end)

    -- Free Unclamped Dragging (Allows dragging below/off screen)
    local dragging, dragStart, dragOrigin = false, Vector2.zero, Vector2.zero
    Connect(topbar.InputBegan, function(input)
        if destroyed or not IsPointer(input) then return end
        dragging = true
        dragStart = Vector2.new(input.Position.X, input.Position.Y)
        dragOrigin = Vector2.new(window.Position.X.Offset, window.Position.Y.Offset)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end
    end)

    Connect(UserInputService.InputChanged, function(input)
        if not dragging or destroyed then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local curr = Vector2.new(input.Position.X, input.Position.Y)
            local delta = curr - dragStart
            window.Position = UDim2.fromOffset(dragOrigin.X + delta.X, dragOrigin.Y + delta.Y)
        end
    end)

    Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Single Grip Resizing
    local resizing, resizeStart, resizeOrigin = false, Vector2.zero, Vector2.zero
    Connect(resizeGrip.InputBegan, function(input)
        if destroyed or minimized or not IsPointer(input) then return end
        resizing = true
        resizeStart = Vector2.new(input.Position.X, input.Position.Y)
        resizeOrigin = window.AbsoluteSize
    end)

    Connect(UserInputService.InputChanged, function(input)
        if not resizing or destroyed then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local curr = Vector2.new(input.Position.X, input.Position.Y)
            local delta = curr - resizeStart
            local newWidth = math.max(minimum.X, resizeOrigin.X + delta.X)
            local newHeight = math.max(minimum.Y, resizeOrigin.Y + delta.Y)
            savedSize = Vector2.new(newWidth, newHeight)
            window.Size = UDim2.fromOffset(newWidth, newHeight)
        end
    end)

    Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = false
        end
    end)

    window.Visible = true
    self.Window = windowObject
    return windowObject
end

return LiquidUI
