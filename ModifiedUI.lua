--[[
    LiquidUI - Clean Core Library v3.5.1 Enterprise Edition
    - Fixed syntax error on CreateButton height evaluation
    - Fixed all remaining unrounded frames with UICorner & UIStroke
    - Clean dropdown animations and circular slider knobs
]]

local LiquidUI = {}
LiquidUI.__index = LiquidUI

LiquidUI.Version = "3.5.1"

LiquidUI.Theme = {
    Background = Color3.fromRGB(4, 4, 6),
    Surface = Color3.fromRGB(10, 11, 14),
    SurfaceLight = Color3.fromRGB(16, 18, 23),
    SurfaceHover = Color3.fromRGB(24, 27, 34),
    Accent = Color3.fromRGB(59, 142, 234),
    AccentLight = Color3.fromRGB(153, 210, 255),
    Text = Color3.fromRGB(248, 250, 252),
    SubText = Color3.fromRGB(148, 163, 184),
    Border = Color3.fromRGB(51, 65, 85),
    BorderLight = Color3.fromRGB(100, 116, 139),
    Success = Color3.fromRGB(74, 222, 128),
    Danger = Color3.fromRGB(248, 113, 113)
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
    return Create("UICorner", { CornerRadius = UDim.new(0, radius or 10), Parent = object })
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
    local tween = TweenService:Create(object, TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), properties)
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
    local arguments = table.pack(...)
    task.spawn(function()
        local ok, err = pcall(function()
            callback(table.unpack(arguments, 1, arguments.n))
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
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
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

    local minimum = options.MinSize or Vector2.new(400, 320)
    local maximum = options.MaxSize or Vector2.new(1400, 900)
    local requestedSize = options.Size or UDim2.fromOffset(920, 600)

    local viewport = Viewport()
    local width = Clamp(requestedSize.X.Offset > 0 and requestedSize.X.Offset or 920, math.min(minimum.X, viewport.X), math.min(maximum.X, viewport.X))
    local height = Clamp(requestedSize.Y.Offset > 0 and requestedSize.Y.Offset or 600, math.min(minimum.Y, viewport.Y), math.min(maximum.Y, viewport.Y))
    local savedSize = Vector2.new(width, height)

    local gui = Create("ScreenGui", {
        Name = "LiquidUI_Enterprise",
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

    -- Floating Square Toggle Button
    local FloatingToggle = Create("TextButton", {
        Name = "FloatingToggle",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(44, 44),
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 500,
        Parent = gui
    })
    Corner(FloatingToggle, 10)
    Stroke(FloatingToggle, theme.BorderLight, 0.3, 1)

    Create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(22, 22),
        BackgroundTransparency = 1,
        Image = LiquidUI:GetIcon(options.Logo or "home"),
        ImageColor3 = theme.AccentLight,
        ZIndex = 501,
        Parent = FloatingToggle
    })

    -- Opening Layer Animation
    local opening = Create("Frame", {
        Name = "OpeningLayer",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(2, 2, 4),
        BorderSizePixel = 0,
        ZIndex = 100,
        Parent = gui
    })

    Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 14, 20)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(3, 3, 5)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 12, 16))
        }),
        Rotation = 45,
        Parent = opening
    })

    local openingCard = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(360, 260),
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        ZIndex = 101,
        Parent = opening
    })
    Corner(openingCard, 14)
    Stroke(openingCard, theme.BorderLight, 0.2, 1)

    local openingAccent = Create("Frame", {
        Position = UDim2.fromOffset(24, 22),
        Size = UDim2.fromOffset(52, 52),
        BackgroundColor3 = theme.SurfaceLight,
        BorderSizePixel = 0,
        ZIndex = 102,
        Parent = openingCard
    })
    Corner(openingAccent, 12)
    Stroke(openingAccent, theme.AccentLight, 0.2, 1)

    local openingLogo = Label(openingAccent, options.Logo or "L", 26, theme.AccentLight, true)
    openingLogo.TextXAlignment = Enum.TextXAlignment.Center
    openingLogo.Size = UDim2.fromScale(1, 1)
    openingLogo.ZIndex = 103

    local openingTitle = Label(openingCard, options.Title or "LiquidUI", 20, theme.Text, true)
    openingTitle.Position = UDim2.fromOffset(24, 88)
    openingTitle.Size = UDim2.new(1, -48, 0, 30)
    openingTitle.ZIndex = 102

    local openingSubtitle = Label(openingCard, options.Subtitle or "ENTERPRISE SUITE", 10, theme.SubText, false)
    openingSubtitle.Position = UDim2.fromOffset(24, 118)
    openingSubtitle.Size = UDim2.new(1, -48, 0, 20)
    openingSubtitle.ZIndex = 102

    local loadingTrack = Create("Frame", {
        Position = UDim2.new(0, 24, 0, 168),
        Size = UDim2.new(1, -48, 0, 6),
        BackgroundColor3 = theme.SurfaceLight,
        BorderSizePixel = 0,
        ZIndex = 102,
        Parent = openingCard
    })
    Corner(loadingTrack, 3)

    local loadingFill = Create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = theme.AccentLight,
        BorderSizePixel = 0,
        ZIndex = 103,
        Parent = loadingTrack
    })
    Corner(loadingFill, 3)

    local openingStatus = Label(openingCard, "INITIALIZING MODULES", 10, theme.SubText, false)
    openingStatus.Position = UDim2.fromOffset(24, 184)
    openingStatus.Size = UDim2.new(1, -48, 0, 20)
    openingStatus.ZIndex = 102

    -- Main Window Container
    local window = Create("Frame", {
        Name = "MainWindow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(viewport.X / 2, viewport.Y / 2),
        Size = UDim2.fromOffset(width, height),
        BackgroundColor3 = theme.Background,
        BackgroundTransparency = 0.01,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 2,
        Parent = gui
    })
    Corner(window, 14)
    Stroke(window, theme.Border, 0.3, 1)

    -- Resizing Input Blocker Overlay
    local resizeBlocker = Create("TextButton", {
        Name = "ResizeInputBlocker",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Visible = false,
        ZIndex = 999,
        Parent = window
    })

    local topbar = Create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Active = true,
        ZIndex = 3,
        Parent = window
    })

    local logoBox = Create("Frame", {
        Position = UDim2.fromOffset(14, 11),
        Size = UDim2.fromOffset(40, 40),
        BackgroundColor3 = theme.SurfaceLight,
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = topbar
    })
    Corner(logoBox, 10)
    Stroke(logoBox, theme.Border, 0.3, 1)

    local logoText = Label(logoBox, options.Logo or "L", 18, theme.AccentLight, true)
    logoText.TextXAlignment = Enum.TextXAlignment.Center
    logoText.Size = UDim2.fromScale(1, 1)
    logoText.ZIndex = 5

    local titleLabel = Label(topbar, options.Title or "LiquidUI", 15, theme.Text, true)
    titleLabel.Position = UDim2.fromOffset(66, 10)
    titleLabel.Size = UDim2.new(1, -170, 0, 22)
    titleLabel.ZIndex = 4

    local subtitle = Label(topbar, options.Subtitle or "Enterprise Suite", 11, theme.SubText, false)
    subtitle.Position = UDim2.fromOffset(66, 32)
    subtitle.Size = UDim2.new(1, -170, 0, 18)
    subtitle.ZIndex = 4

    local minimizeButton = Create("TextButton", {
        Position = UDim2.new(1, -76, 0, 16),
        Size = UDim2.fromOffset(28, 30),
        BackgroundTransparency = 1,
        Text = "−",
        TextColor3 = theme.SubText,
        TextSize = 20,
        Font = Enum.Font.Gotham,
        AutoButtonColor = false,
        ZIndex = 5,
        Parent = topbar
    })

    local closeButton = Create("TextButton", {
        Position = UDim2.new(1, -42, 0, 16),
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

    Create("Frame", {
        Position = UDim2.new(0, 0, 0, 62),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = theme.Border,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = window
    })

    local sidebar = Create("Frame", {
        Name = "Sidebar",
        Position = UDim2.fromOffset(0, 63),
        Size = UDim2.new(0, 170, 1, -63),
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = window
    })

    local tabList = Create("ScrollingFrame", {
        Name = "TabList",
        Position = UDim2.fromOffset(10, 12),
        Size = UDim2.new(1, -20, 1, -24),
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
        Position = UDim2.new(0, 170, 0, 63),
        Size = UDim2.new(1, -170, 1, -63),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 3,
        Parent = window
    })

    local header = Create("Frame", {
        Position = UDim2.fromOffset(18, 14),
        Size = UDim2.new(1, -36, 0, 42),
        BackgroundTransparency = 1,
        ZIndex = 4,
        Parent = content
    })

    local pageTitle = Label(header, "Dashboard", 16, theme.Text, true)
    pageTitle.Size = UDim2.new(1, 0, 0, 22)
    pageTitle.ZIndex = 5

    local pageSubtitle = Label(header, "Enterprise workspace active.", 11, theme.SubText, false)
    pageSubtitle.Position = UDim2.fromOffset(0, 22)
    pageSubtitle.Size = UDim2.new(1, 0, 0, 18)
    pageSubtitle.ZIndex = 5

    local pageHolder = Create("Frame", {
        Name = "Pages",
        Position = UDim2.new(0, 16, 0, 60),
        Size = UDim2.new(1, -32, 1, -70),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 4,
        Parent = content
    })

    local resizeGrip = Create("TextButton", {
        Name = "ResizeGrip",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -3, 1, -3),
        Size = UDim2.fromOffset(16, 16),
        BackgroundTransparency = 1,
        Text = "◢",
        TextSize = 12,
        TextColor3 = theme.SubText,
        AutoButtonColor = false,
        Active = true,
        ZIndex = 10,
        Parent = window
    })

    local function ClampPosition(position)
        local view = Viewport()
        local absoluteSize = window.AbsoluteSize
        local halfWidth = absoluteSize.X / 2
        local halfHeight = absoluteSize.Y / 2
        local inset = GuiService:GetGuiInset()

        return UDim2.fromOffset(
            Clamp(position.X.Offset, math.min(halfWidth, view.X / 2), math.max(halfWidth, view.X - halfWidth)),
            Clamp(position.Y.Offset, math.min(halfHeight, view.Y / 2 + inset.Y / 2), math.max(halfHeight, view.Y - halfHeight))
        )
    end

    local function SelectTab(tab)
        if destroyed or not tab then return end
        currentTab = tab
        pageTitle.Text = tab.Name
        pageSubtitle.Text = tab.Description

        for _, item in ipairs(tabs) do
            local selected = item == tab
            item.Page.Visible = selected
            item.Button.BackgroundColor3 = selected and theme.SurfaceHover or theme.Surface
            item.Button.BackgroundTransparency = selected and 0.05 or 0.7
            item.Indicator.BackgroundTransparency = selected and 0 or 1
            item.Label.TextColor3 = selected and theme.Text or theme.SubText
            item.Icon.ImageColor3 = selected and theme.AccentLight or theme.SubText
        end
    end

    local function MakeCard(parent, cardHeight)
        local card = Create("Frame", {
            Size = UDim2.new(1, 0, 0, cardHeight or 48),
            BackgroundColor3 = theme.Surface,
            BackgroundTransparency = 0.15,
            BorderSizePixel = 0,
            Parent = parent
        })
        Corner(card, 10)
        Stroke(card, theme.Border, 0.5, 1)
        return card
    end

    local function Handle(instance, methods)
        local result = { Instance = instance }
        for key, value in pairs(methods or {}) do
            result[key] = value
        end
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
            Size = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = theme.Surface,
            BackgroundTransparency = 0.7,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Parent = tabList
        })
        Corner(tabButton, 9)

        local indicator = Create("Frame", {
            Position = UDim2.fromOffset(0, 7),
            Size = UDim2.new(0, 3, 1, -14),
            BackgroundColor3 = theme.AccentLight,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = tabButton
        })
        Corner(indicator, 2)

        local icon = Create("ImageLabel", {
            Position = UDim2.fromOffset(11, 11),
            Size = UDim2.fromOffset(16, 16),
            BackgroundTransparency = 1,
            Image = LiquidUI:GetIcon(iconName or "home"),
            ImageColor3 = theme.SubText,
            Parent = tabButton
        })

        local tabLabel = Label(tabButton, name, 12, theme.SubText, true)
        tabLabel.Position = UDim2.fromOffset(36, 0)
        tabLabel.Size = UDim2.new(1, -40, 1, 0)
        tabLabel.TextTruncate = Enum.TextTruncate.AtEnd

        local page = Create("ScrollingFrame", {
            Name = name .. "Page",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = theme.BorderLight,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            Parent = pageHolder
        })
        AddPadding(page, 0, 6, 0, 8)

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

        Connect(tabButton.Activated, function()
            SelectTab(tab)
        end)

        local api = {}

        function api:AddSection(sectionName)
            local section = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 24),
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
            local card = MakeCard(page, config.Height or 46)

            local control = Create("TextButton", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                Parent = card
            })

            local text = Label(card, config.Name or "Button", 13, theme.Text, true)
            text.Position = UDim2.fromOffset(14, 0)
            text.Size = UDim2.new(1, -45, 1, 0)

            Connect(control.MouseEnter, function()
                PlayTween(card, 0.12, { BackgroundColor3 = theme.SurfaceHover })
            end)

            Connect(control.MouseLeave, function()
                PlayTween(card, 0.12, { BackgroundColor3 = theme.Surface })
            end)

            Connect(control.Activated, function()
                Callback(config.Callback)
            end)

            return Handle(card, {
                SetText = function(_, v) text.Text = tostring(v) end
            })
        end

        function api:CreateToggle(config)
            config = config or {}
            local value = config.Default == true
            local card = MakeCard(page, config.Height or 54)

            local text = Label(card, config.Name or "Toggle", 13, theme.Text, true)
            text.Position = UDim2.fromOffset(14, 6)
            text.Size = UDim2.new(1, -80, 0, 20)

            if config.Description then
                local desc = Label(card, config.Description, 10, theme.SubText, false)
                desc.Position = UDim2.fromOffset(14, 26)
                desc.Size = UDim2.new(1, -80, 0, 18)
            end

            local switch = Create("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -14, 0.5, 0),
                Size = UDim2.fromOffset(40, 22),
                BackgroundColor3 = value and theme.Accent or Color3.fromRGB(45, 45, 55),
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                Parent = card
            })
            Corner(switch, 11)

            local knob = Create("Frame", {
                Position = value and UDim2.new(1, -19, 0, 3) or UDim2.fromOffset(3, 3),
                Size = UDim2.fromOffset(16, 16),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Parent = switch
            })
            Corner(knob, 8)

            local function SetValue(nv, fire)
                value = nv == true
                PlayTween(switch, 0.12, { BackgroundColor3 = value and theme.Accent or Color3.fromRGB(45, 45, 55) })
                PlayTween(knob, 0.12, { Position = value and UDim2.new(1, -19, 0, 3) or UDim2.fromOffset(3, 3) })
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
            local card = MakeCard(page, 66)

            local text = Label(card, config.Name or "Slider", 13, theme.Text, true)
            text.Position = UDim2.fromOffset(14, 6)
            text.Size = UDim2.new(1, -75, 0, 20)

            local valLabel = Label(card, tostring(value), 11, theme.AccentLight, true)
            valLabel.TextXAlignment = Enum.TextXAlignment.Right
            valLabel.Position = UDim2.new(1, -65, 0, 6)
            valLabel.Size = UDim2.fromOffset(50, 20)

            local bar = Create("Frame", {
                Position = UDim2.new(0, 14, 0, 40),
                Size = UDim2.new(1, -28, 0, 6),
                BackgroundColor3 = theme.SurfaceLight,
                BorderSizePixel = 0,
                Active = true,
                Parent = card
            })
            Corner(bar, 3)
            Stroke(bar, theme.Border, 0.4, 1)

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

            local sliderCircle = Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(Ratio(value), 0, 0.5, 0),
                Size = UDim2.fromOffset(14, 14),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Parent = bar
            })
            Corner(sliderCircle, 7)
            Stroke(sliderCircle, theme.AccentLight, 0.1, 1)

            local function SetValue(nv, fire)
                value = Clamp(tonumber(nv) or minVal, minVal, maxVal)
                local ratio = Ratio(value)
                fill.Size = UDim2.new(ratio, 0, 1, 0)
                sliderCircle.Position = UDim2.new(ratio, 0, 0.5, 0)
                valLabel.Text = tostring(value)
                if fire ~= false then Callback(config.Callback, value) end
            end

            local dragging = false
            Connect(bar.InputBegan, function(input)
                if IsPointer(input) then dragging = true end
            end)
            Connect(UserInputService.InputChanged, function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local ratio = Clamp((input.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
                    SetValue(minVal + (maxVal - minVal) * ratio)
                end
            end)
            Connect(UserInputService.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            return Handle(card, {
                SetValue = SetValue,
                GetValue = function() return value end
            })
        end

        function api:CreateInput(config)
            config = config or {}
            local card = MakeCard(page, 64)

            local text = Label(card, config.Name or "Input", 13, theme.Text, true)
            text.Position = UDim2.fromOffset(14, 6)
            text.Size = UDim2.new(1, -28, 0, 20)

            local box = Create("TextBox", {
                Position = UDim2.fromOffset(12, 28),
                Size = UDim2.new(1, -24, 0, 26),
                BackgroundColor3 = theme.Background,
                BorderSizePixel = 0,
                Text = tostring(config.Default or ""),
                PlaceholderText = config.Placeholder or "Enter value...",
                PlaceholderColor3 = theme.SubText,
                TextColor3 = theme.Text,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = card
            })
            Corner(box, 7)
            Stroke(box, theme.Border, 0.5, 1)
            AddPadding(box, 8, 8, 0, 0)

            Connect(box.FocusLost, function(enter)
                Callback(config.Callback, box.Text, enter)
            end)

            return Handle(card, {
                GetValue = function() return box.Text end,
                SetValue = function(_, v) box.Text = tostring(v or "") end
            })
        end

        function api:CreateDropdown(config)
            config = config or {}
            local values = config.Options or {}
            local selected = config.Default or "Select an option..."
            local opened = false
            local optionConnections = {}

            local card = MakeCard(page, 62)
            card.ClipsDescendants = false
            card.ZIndex = 20

            local text = Label(card, config.Name or "Dropdown", 13, theme.Text, true)
            text.Position = UDim2.fromOffset(14, 6)
            text.Size = UDim2.new(1, -28, 0, 20)

            local dropButton = Create("TextButton", {
                Position = UDim2.fromOffset(12, 28),
                Size = UDim2.new(1, -24, 0, 26),
                BackgroundColor3 = theme.Background,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 21,
                Parent = card
            })
            Corner(dropButton, 7)
            Stroke(dropButton, theme.Border, 0.5, 1)

            local selectedText = Label(dropButton, selected, 12, theme.SubText, false)
            selectedText.Position = UDim2.fromOffset(10, 0)
            selectedText.Size = UDim2.new(1, -30, 1, 0)
            selectedText.ZIndex = 22

            local arrow = Label(dropButton, "▾", 14, theme.AccentLight, true)
            arrow.Position = UDim2.new(1, -24, 0, 0)
            arrow.Size = UDim2.fromOffset(20, 26)
            arrow.TextXAlignment = Enum.TextXAlignment.Center
            arrow.ZIndex = 22

            local popup = Create("Frame", {
                Position = UDim2.new(0, 0, 1, 4),
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundColor3 = theme.Surface,
                BorderSizePixel = 0,
                Visible = false,
                ClipsDescendants = true,
                ZIndex = 50,
                Parent = dropButton
            })
            Corner(popup, 8)
            Stroke(popup, theme.BorderLight, 0.2, 1)

            local list = Create("ScrollingFrame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = theme.Accent,
                CanvasSize = UDim2.new(),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ZIndex = 51,
                Parent = popup
            })
            AddPadding(list, 4, 4, 4, 4)

            Create("UIListLayout", { Padding = UDim.new(0, 3), Parent = list })

            local function ClearOptions()
                for _, c in ipairs(optionConnections) do c:Disconnect() end
                table.clear(optionConnections)
                for _, child in ipairs(list:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
            end

            local function Refresh()
                ClearOptions()
                for _, option in ipairs(values) do
                    local optVal = option
                    local btn = Create("TextButton", {
                        Size = UDim2.new(1, 0, 0, 28),
                        BackgroundColor3 = theme.SurfaceLight,
                        BackgroundTransparency = 0.2,
                        BorderSizePixel = 0,
                        Text = tostring(optVal),
                        TextColor3 = theme.Text,
                        TextSize = 11,
                        Font = Enum.Font.Gotham,
                        AutoButtonColor = false,
                        ZIndex = 52,
                        Parent = list
                    })
                    Corner(btn, 6)
                    table.insert(optionConnections, btn.Activated:Connect(function()
                        selected = optVal
                        selectedText.Text = tostring(optVal)
                        opened = false
                        PlayTween(popup, 0.12, { Size = UDim2.new(1, 0, 0, 0) })
                        task.delay(0.13, function() popup.Visible = false end)
                        Callback(config.Callback, optVal)
                    end))
                end
            end

            Refresh()

            Connect(dropButton.Activated, function()
                opened = not opened
                if opened then
                    popup.Visible = true
                    PlayTween(popup, 0.14, { Size = UDim2.new(1, 0, 0, math.min(#values * 31 + 8, 150)) })
                else
                    PlayTween(popup, 0.12, { Size = UDim2.new(1, 0, 0, 0) })
                    task.delay(0.13, function() if not opened then popup.Visible = false end end)
                end
            end)

            return Handle(card, {
                GetValue = function() return selected end,
                SetValue = function(_, v) selected = v; selectedText.Text = tostring(v) end
            })
        end

        SelectTab(#tabs == 1 and tab or currentTab)
        return api
    end

    windowObject.Tab = windowObject.CreateTab

    function windowObject:Notify(config)
        if destroyed then return end
        if type(config) ~= "table" then
            config = { Title = "Notification", Content = tostring(config) }
        end

        local toast = Create("Frame", {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, 320, 1, -20),
            Size = UDim2.fromOffset(270, 58),
            BackgroundColor3 = theme.Surface,
            BackgroundTransparency = 0.04,
            BorderSizePixel = 0,
            ZIndex = 900,
            Parent = gui
        })
        Corner(toast, 10)
        Stroke(toast, theme.BorderLight, 0.3, 1)

        local title = Label(toast, config.Title or "Notice", 12, theme.Text, true)
        title.Position = UDim2.fromOffset(12, 8)
        title.Size = UDim2.new(1, -20, 0, 18)
        title.ZIndex = 901

        local body = Label(toast, config.Content or "", 10, theme.SubText, false)
        body.Position = UDim2.fromOffset(12, 28)
        body.Size = UDim2.new(1, -20, 0, 22)
        body.ZIndex = 901

        table.insert(toasts, toast)
        PlayTween(toast, 0.2, { Position = UDim2.new(1, -16, 1, -20) })

        task.delay(math.max(tonumber(config.Duration) or 3, 1), function()
            if not toast.Parent then return end
            PlayTween(toast, 0.18, { Position = UDim2.new(1, 320, 1, -20), BackgroundTransparency = 1 })
            task.delay(0.2, function()
                if toast.Parent then toast:Destroy() end
            end)
        end)
    end

    function windowObject:Minimize()
        minimized = not minimized
        window.Visible = not minimized
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

    -- Fixed Safe Dragging Logic
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
            window.Position = ClampPosition(UDim2.fromOffset(dragOrigin.X + delta.X, dragOrigin.Y + delta.Y))
        end
    end)

    Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Fixed Resizing Logic with Touch Input Blocker
    local resizing = false
    local resizeStart, resizeOrigin = Vector2.zero, Vector2.zero
    Connect(resizeGrip.InputBegan, function(input)
        if destroyed or minimized or not IsPointer(input) then return end
        resizing = true
        resizeBlocker.Visible = true
        resizeStart = Vector2.new(input.Position.X, input.Position.Y)
        resizeOrigin = window.AbsoluteSize
    end)

    Connect(UserInputService.InputChanged, function(input)
        if not resizing or destroyed then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local curr = Vector2.new(input.Position.X, input.Position.Y)
            local delta = curr - resizeStart
            local view = Viewport()
            local newWidth = Clamp(resizeOrigin.X + delta.X, math.min(minimum.X, view.X), math.max(minimum.X, math.min(maximum.X, view.X)))
            local newHeight = Clamp(resizeOrigin.Y + delta.Y, math.min(minimum.Y, view.Y), math.max(minimum.Y, math.min(maximum.Y, view.Y)))
            savedSize = Vector2.new(newWidth, newHeight)
            window.Size = UDim2.fromOffset(newWidth, newHeight)
        end
    end)

    Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if resizing then
                resizing = false
                resizeBlocker.Visible = false
            end
        end
    end)

    -- Opening Animation Sequence
    task.spawn(function()
        PlayTween(loadingFill, 0.4, { Size = UDim2.new(1, 0, 1, 0) })
        task.wait(0.45)
        PlayTween(openingCard, 0.2, { BackgroundTransparency = 1 })
        PlayTween(opening, 0.2, { BackgroundTransparency = 1 })
        task.wait(0.22)
        opening:Destroy()
        window.Visible = true

        windowObject:Notify({
            Title = options.Title or "LiquidUI",
            Content = "Enterprise modules loaded successfully.",
            Duration = 2.5
        })
    end)

    self.Window = windowObject
    return windowObject
end

return LiquidUI
