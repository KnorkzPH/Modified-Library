
local LiquidUI = {}
LiquidUI.__index = LiquidUI

LiquidUI.Version = "3.0.0"

LiquidUI.Theme = {
    Background = Color3.fromRGB(3, 3, 4),
    Surface = Color3.fromRGB(8, 8, 10),
    SurfaceLight = Color3.fromRGB(15, 15, 18),
    SurfaceHover = Color3.fromRGB(23, 23, 27),
    Accent = Color3.fromRGB(45, 130, 215),
    AccentLight = Color3.fromRGB(140, 200, 255),
    Text = Color3.fromRGB(245, 247, 250),
    SubText = Color3.fromRGB(155, 163, 177),
    Border = Color3.fromRGB(76, 87, 105),
    BorderLight = Color3.fromRGB(132, 151, 180),
    Success = Color3.fromRGB(80, 220, 155),
    Danger = Color3.fromRGB(255, 100, 115)
}

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
    if not object or not object.Parent then
        return
    end

    local tween = TweenService:Create(
        object,
        TweenInfo.new(
            duration or 0.18,
            Enum.EasingStyle.Quint,
            Enum.EasingDirection.Out
        ),
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

local function Button(parent, text, height)
    local theme = LiquidUI.Theme

    local button = Create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = theme.SurfaceLight,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height or 40),
        Text = tostring(text or ""),
        TextColor3 = theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        Parent = parent
    })

    Corner(button, 9)
    Stroke(button, theme.Border, 0.35, 1)

    button.MouseEnter:Connect(function()
        PlayTween(button, 0.14, {
            BackgroundColor3 = theme.SurfaceHover
        })
    end)

    button.MouseLeave:Connect(function()
        PlayTween(button, 0.14, {
            BackgroundColor3 = theme.SurfaceLight
        })
    end)

    return button
end

local function Callback(callback, ...)
    if type(callback) ~= "function" then
        return
    end

    local arguments = table.pack(...)

    task.spawn(function()
        local ok, err = pcall(function()
            callback(table.unpack(arguments, 1, arguments.n))
        end)

        if not ok then
            warn("[LiquidUI] Callback error:", err)
        end
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

function LiquidUI:SetTheme(newTheme)
    for key, value in pairs(newTheme or {}) do
        if self.Theme[key] ~= nil then
            self.Theme[key] = value
        end
    end
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

    local toggleKey = options.ToggleKey or Enum.KeyCode.RightShift
    local minimum = options.MinSize or Vector2.new(360, 300)
    local maximum = options.MaxSize or Vector2.new(1400, 900)
    local requestedSize = options.Size or UDim2.fromOffset(900, 580)

    local viewport = Viewport()
    local width = Clamp(
        requestedSize.X.Offset > 0 and requestedSize.X.Offset or 900,
        math.min(minimum.X, viewport.X),
        math.min(maximum.X, viewport.X)
    )
    local height = Clamp(
        requestedSize.Y.Offset > 0 and requestedSize.Y.Offset or 580,
        math.min(minimum.Y, viewport.Y),
        math.min(maximum.Y, viewport.Y)
    )

    local savedSize = Vector2.new(width, height)

    local gui = Create("ScreenGui", {
        Name = "LiquidUI_BlackGlass",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    local parent = options.Parent

    if parent then
        gui.Parent = parent
    else
        local success = pcall(function()
            gui.Parent = CoreGui
        end)

        if not success then
            gui.Parent = Player:WaitForChild("PlayerGui")
        end
    end

    local function Connect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(connections, connection)
        return connection
    end

    -- Opening layer

    local opening = Create("Frame", {
        Name = "OpeningLayer",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(2, 2, 3),
        BorderSizePixel = 0,
        ZIndex = 100,
        Parent = gui
    })

    local openingGradient = Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 12, 18)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(2, 2, 3)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(9, 10, 14))
        }),
        Rotation = 35,
        Parent = opening
    })

    local openingCard = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(350, 255),
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        ZIndex = 101,
        Parent = opening
    })

    Corner(openingCard, 20)
    Stroke(openingCard, theme.BorderLight, 0.12, 1.3)

    local openingAccent = Create("Frame", {
        Position = UDim2.fromOffset(22, 20),
        Size = UDim2.fromOffset(54, 54),
        BackgroundColor3 = Color3.fromRGB(15, 17, 22),
        BorderSizePixel = 0,
        ZIndex = 102,
        Parent = openingCard
    })

    Corner(openingAccent, 15)
    Stroke(openingAccent, theme.AccentLight, 0.18, 1)

    local openingLogo = Label(
        openingAccent,
        options.Logo or "L",
        28,
        theme.AccentLight,
        true
    )

    openingLogo.TextXAlignment = Enum.TextXAlignment.Center
    openingLogo.Size = UDim2.fromScale(1, 1)
    openingLogo.ZIndex = 103

    local openingTitle = Label(
        openingCard,
        options.Title or "LiquidUI",
        21,
        theme.Text,
        true
    )

    openingTitle.Position = UDim2.fromOffset(22, 88)
    openingTitle.Size = UDim2.new(1, -44, 0, 31)
    openingTitle.ZIndex = 102

    local openingSubtitle = Label(
        openingCard,
        options.Subtitle or "BLACK GLASS INTERFACE",
        10,
        theme.SubText,
        false
    )

    openingSubtitle.Position = UDim2.fromOffset(23, 119)
    openingSubtitle.Size = UDim2.new(1, -46, 0, 20)
    openingSubtitle.ZIndex = 102

    local loadingTrack = Create("Frame", {
        Position = UDim2.new(0, 23, 0, 166),
        Size = UDim2.new(1, -46, 0, 4),
        BackgroundColor3 = Color3.fromRGB(35, 37, 43),
        BorderSizePixel = 0,
        ZIndex = 102,
        Parent = openingCard
    })

    Corner(loadingTrack, 5)

    local loadingFill = Create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = theme.AccentLight,
        BorderSizePixel = 0,
        ZIndex = 103,
        Parent = loadingTrack
    })

    Corner(loadingFill, 5)

    local openingStatus = Label(
        openingCard,
        "INITIALIZING INTERFACE",
        10,
        theme.SubText,
        false
    )

    openingStatus.Position = UDim2.fromOffset(23, 180)
    openingStatus.Size = UDim2.new(1, -46, 0, 20)
    openingStatus.ZIndex = 102

    local openingVersion = Label(
        openingCard,
        "LIQUIDUI  /  V" .. self.Version,
        9,
        theme.SubText,
        false
    )

    openingVersion.Position = UDim2.fromOffset(23, 222)
    openingVersion.Size = UDim2.new(1, -46, 0, 16)
    openingVersion.ZIndex = 102

    local shadow = Create("Frame", {
        Name = "WindowOutline",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(viewport.X / 2, viewport.Y / 2),
        Size = UDim2.fromOffset(width + 4, height + 4),
        BackgroundColor3 = theme.BorderLight,
        BackgroundTransparency = 0.28,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 1,
        Parent = gui
    })

    Corner(shadow, 17)

    local window = Create("Frame", {
        Name = "MainWindow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(viewport.X / 2, viewport.Y / 2),
        Size = UDim2.fromOffset(width, height),
        BackgroundColor3 = theme.Background,
        BackgroundTransparency = 0.025,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 2,
        Parent = gui
    })

    Corner(window, 16)
    Stroke(window, theme.BorderLight, 0.08, 1.2)

    Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 14, 17)),
            ColorSequenceKeypoint.new(0.45, Color3.fromRGB(4, 4, 5)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(9, 10, 13))
        }),
        Rotation = 40,
        Parent = window
    })

    local topbar = Create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 65),
        BackgroundColor3 = Color3.fromRGB(9, 9, 11),
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Active = true,
        ZIndex = 3,
        Parent = window
    })

    local logoBox = Create("Frame", {
        Position = UDim2.fromOffset(14, 12),
        Size = UDim2.fromOffset(40, 40),
        BackgroundColor3 = theme.SurfaceLight,
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = topbar
    })

    Corner(logoBox, 11)
    Stroke(logoBox, theme.BorderLight, 0.2, 1)

    local logoText = Label(logoBox, options.Logo or "L", 20, theme.AccentLight, true)
    logoText.TextXAlignment = Enum.TextXAlignment.Center
    logoText.Size = UDim2.fromScale(1, 1)
    logoText.ZIndex = 5

    local titleLabel = Label(topbar, options.Title or "LiquidUI", 15, theme.Text, true)
    titleLabel.Position = UDim2.fromOffset(65, 10)
    titleLabel.Size = UDim2.new(1, -170, 0, 23)
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.ZIndex = 4

    local subtitle = Label(
        topbar,
        options.Subtitle or options.Author or "Black Glass Interface",
        11,
        theme.SubText,
        false
    )

    subtitle.Position = UDim2.fromOffset(66, 32)
    subtitle.Size = UDim2.new(1, -170, 0, 18)
    subtitle.TextTruncate = Enum.TextTruncate.AtEnd
    subtitle.ZIndex = 4

    local minimizeButton = Create("TextButton", {
        Position = UDim2.new(1, -77, 0, 15),
        Size = UDim2.fromOffset(28, 30),
        BackgroundTransparency = 1,
        Text = "−",
        TextColor3 = theme.SubText,
        TextSize = 23,
        Font = Enum.Font.Gotham,
        AutoButtonColor = false,
        ZIndex = 5,
        Parent = topbar
    })

    local closeButton = Create("TextButton", {
        Position = UDim2.new(1, -43, 0, 15),
        Size = UDim2.fromOffset(28, 30),
        BackgroundTransparency = 1,
        Text = "×",
        TextColor3 = theme.Text,
        TextSize = 24,
        Font = Enum.Font.Gotham,
        AutoButtonColor = false,
        ZIndex = 5,
        Parent = topbar
    })

    local separator = Create("Frame", {
        Position = UDim2.new(0, 0, 0, 64),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = theme.Border,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = window
    })

    local sidebar = Create("Frame", {
        Name = "Sidebar",
        Position = UDim2.fromOffset(0, 65),
        Size = UDim2.new(0, 165, 1, -65),
        BackgroundColor3 = Color3.fromRGB(7, 7, 9),
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = window
    })

    local tabList = Create("ScrollingFrame", {
        Name = "TabList",
        Position = UDim2.fromOffset(9, 12),
        Size = UDim2.new(1, -18, 1, -75),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.BorderLight,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 4,
        Parent = sidebar
    })

    AddPadding(tabList, 0, 0, 0, 4)

    Create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tabList
    })

    local profile = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -10),
        Size = UDim2.new(1, -18, 0, 47),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = sidebar
    })

    Corner(profile, 10)
    Stroke(profile, theme.Border, 0.5, 1)

    local profileTitle = Label(profile, options.Author or "Toolkit", 12, theme.Text, true)
    profileTitle.Position = UDim2.fromOffset(11, 5)
    profileTitle.Size = UDim2.new(1, -20, 0, 18)
    profileTitle.ZIndex = 5

    local profileSubtitle = Label(profile, "v" .. self.Version, 10, theme.SubText, false)
    profileSubtitle.Position = UDim2.fromOffset(11, 23)
    profileSubtitle.Size = UDim2.new(1, -20, 0, 15)
    profileSubtitle.ZIndex = 5

    local content = Create("Frame", {
        Name = "Content",
        Position = UDim2.new(0, 165, 0, 65),
        Size = UDim2.new(1, -165, 1, -65),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 3,
        Parent = window
    })

    local header = Create("Frame", {
        Position = UDim2.fromOffset(14, 9),
        Size = UDim2.new(1, -28, 0, 43),
        BackgroundTransparency = 1,
        ZIndex = 4,
        Parent = content
    })

    local pageTitle = Label(header, "Welcome", 18, theme.Text, true)
    pageTitle.Size = UDim2.new(1, 0, 0, 23)
    pageTitle.ZIndex = 5

    local pageSubtitle = Label(header, "Choose a section to get started.", 11, theme.SubText, false)
    pageSubtitle.Position = UDim2.fromOffset(0, 23)
    pageSubtitle.Size = UDim2.new(1, 0, 0, 17)
    pageSubtitle.ZIndex = 5

    local pageHolder = Create("Frame", {
        Name = "Pages",
        Position = UDim2.fromOffset(12, 55),
        Size = UDim2.new(1, -24, 1, -67),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 4,
        Parent = content
    })

    local resizeGrip = Create("TextButton", {
        Name = "ResizeGrip",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -2, 1, -2),
        Size = UDim2.fromOffset(19, 19),
        BackgroundTransparency = 1,
        Text = "◢",
        TextSize = 13,
        TextColor3 = theme.SubText,
        AutoButtonColor = false,
        Active = true,
        ZIndex = 10,
        Parent = window
    })

    local function SyncShadow()
        if shadow.Parent and window.Parent then
            shadow.Position = window.Position
            shadow.Size = UDim2.new(
                window.Size.X.Scale,
                window.Size.X.Offset + 4,
                window.Size.Y.Scale,
                window.Size.Y.Offset + 4
            )
        end
    end

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
        if destroyed or not tab then
            return
        end

        currentTab = tab
        pageTitle.Text = tab.Name
        pageSubtitle.Text = tab.Description

        for _, item in ipairs(tabs) do
            local selected = item == tab

            item.Page.Visible = selected
            item.Button.BackgroundColor3 = selected and theme.SurfaceHover or theme.Surface
            item.Button.BackgroundTransparency = selected and 0.05 or 0.4
            item.Indicator.BackgroundTransparency = selected and 0 or 1
            item.Label.TextColor3 = selected and theme.Text or theme.SubText
            item.Icon.TextColor3 = selected and theme.AccentLight or theme.SubText
        end
    end

    local function MakeCard(parent, cardHeight)
        local card = Create("Frame", {
            Size = UDim2.new(1, 0, 0, cardHeight or 48),
            BackgroundColor3 = theme.Surface,
            BackgroundTransparency = 0.12,
            BorderSizePixel = 0,
            Parent = parent
        })

        Corner(card, 10)
        Stroke(card, theme.Border, 0.5, 1)

        return card
    end

    local function Handle(instance, methods)
        local result = {
            Instance = instance
        }

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

    function windowObject:CreateTab(name, description, iconText)
        name = tostring(name or ("Tab " .. (#tabs + 1)))

        local tabButton = Create("TextButton", {
            Size = UDim2.new(1, 0, 0, 39),
            BackgroundColor3 = theme.Surface,
            BackgroundTransparency = 0.4,
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

        Corner(indicator, 3)

        local icon = Label(tabButton, iconText or "◇", 16, theme.SubText, true)
        icon.Position = UDim2.fromOffset(9, 0)
        icon.Size = UDim2.fromOffset(25, 39)

        local tabLabel = Label(tabButton, name, 12, theme.SubText, true)
        tabLabel.Position = UDim2.fromOffset(37, 0)
        tabLabel.Size = UDim2.new(1, -42, 1, 0)
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

        AddPadding(page, 1, 4, 1, 6)

        Create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = page
        })

        local tab = {
            Name = name,
            Description = description or ("Manage " .. name .. " components."),
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
                Size = UDim2.new(1, 0, 0, 25),
                BackgroundTransparency = 1,
                Parent = page
            })

            local text = Label(section, sectionName, 13, theme.AccentLight, true)
            text.Position = UDim2.fromOffset(4, 0)
            text.Size = UDim2.new(1, -8, 1, 0)

            return section
        end

        function api:CreateLabel(config)
            if type(config) ~= "table" then
                config = {Name = tostring(config)}
            end

            local label = Label(
                page,
                config.Name or config.Text or "Label",
                config.TextSize or 13,
                config.Color or theme.SubText,
                config.Bold
            )

            label.Size = UDim2.new(1, -5, 0, config.Height or 25)
            label.TextWrapped = true

            return Handle(label, {
                SetText = function(_, value)
                    label.Text = tostring(value)
                end
            })
        end

        function api:CreateDivider()
            return Create("Frame", {
                Size = UDim2.new(1, -4, 0, 1),
                BackgroundColor3 = theme.Border,
                BackgroundTransparency = 0.55,
                BorderSizePixel = 0,
                Parent = page
            })
        end

        function api:CreateButton(config)
            config = config or {}

            local card = MakeCard(page, config.Height or 48)

            local control = Create("TextButton", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                Parent = card
            })

            local text = Label(card, config.Name or "Button", 13, theme.Text, true)
            text.Position = UDim2.fromOffset(13, 0)
            text.Size = UDim2.new(1, -50, 1, 0)
            text.TextTruncate = Enum.TextTruncate.AtEnd

            local arrow = Label(card, "›", 23, theme.AccentLight, false)
            arrow.TextXAlignment = Enum.TextXAlignment.Center
            arrow.Position = UDim2.new(1, -32, 0, 0)
            arrow.Size = UDim2.fromOffset(23, config.Height or 48)

            Connect(control.MouseEnter, function()
                PlayTween(card, 0.13, {
                    BackgroundColor3 = theme.SurfaceHover
                })
            end)

            Connect(control.MouseLeave, function()
                PlayTween(card, 0.13, {
                    BackgroundColor3 = theme.Surface
                })
            end)

            Connect(control.Activated, function()
                Callback(config.Callback)
            end)

            return Handle(card, {
                Button = control,

                SetText = function(_, value)
                    text.Text = tostring(value)
                end
            })
        end

        function api:CreateToggle(config)
            config = config or {}

            local value = config.Default == true
            local card = MakeCard(page, config.Height or 57)

            local text = Label(card, config.Name or "Toggle", 13, theme.Text, true)
            text.Position = UDim2.fromOffset(13, 5)
            text.Size = UDim2.new(1, -85, 0, 21)

            if config.Description then
                local desc = Label(card, config.Description, 10, theme.SubText, false)
                desc.Position = UDim2.fromOffset(13, 27)
                desc.Size = UDim2.new(1, -85, 0, 17)
                desc.TextTruncate = Enum.TextTruncate.AtEnd
            end

            local switch = Create("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -12, 0.5, 0),
                Size = UDim2.fromOffset(39, 22),
                BackgroundColor3 = value and theme.Accent or Color3.fromRGB(49, 49, 55),
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                Parent = card
            })

            Corner(switch, 20)

            local knob = Create("Frame", {
                Position = value and UDim2.new(1, -19, 0, 3) or UDim2.fromOffset(3, 3),
                Size = UDim2.fromOffset(16, 16),
                BackgroundColor3 = Color3.fromRGB(245, 247, 250),
                BorderSizePixel = 0,
                Parent = switch
            })

            Corner(knob, 20)

            local function SetValue(newValue, fire)
                value = newValue == true

                PlayTween(switch, 0.13, {
                    BackgroundColor3 = value and theme.Accent or Color3.fromRGB(49, 49, 55)
                })

                PlayTween(knob, 0.13, {
                    Position = value and UDim2.new(1, -19, 0, 3) or UDim2.fromOffset(3, 3)
                })

                if fire ~= false then
                    Callback(config.Callback, value)
                end
            end

            Connect(switch.Activated, function()
                SetValue(not value, true)
            end)

            return Handle(card, {
                SetValue = SetValue,
                GetValue = function()
                    return value
                end,
                SetText = function(_, newText)
                    text.Text = tostring(newText)
                end
            })
        end

        function api:CreateSlider(config)
            config = config or {}

            local minimumValue = tonumber(config.Min) or 0
            local maximumValue = tonumber(config.Max) or 100

            if maximumValue < minimumValue then
                minimumValue, maximumValue = maximumValue, minimumValue
            end

            local value = Clamp(tonumber(config.Default) or minimumValue, minimumValue, maximumValue)
            local decimals = Clamp(tonumber(config.Decimals) or 0, 0, 4)
            local card = MakeCard(page, 70)

            local text = Label(card, config.Name or "Slider", 13, theme.Text, true)
            text.Position = UDim2.fromOffset(13, 5)
            text.Size = UDim2.new(1, -80, 0, 20)

            local valueLabel = Label(card, value, 11, theme.AccentLight, true)
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            valueLabel.Position = UDim2.new(1, -65, 0, 5)
            valueLabel.Size = UDim2.fromOffset(52, 20)

            local bar = Create("Frame", {
                Position = UDim2.new(0, 13, 0, 43),
                Size = UDim2.new(1, -26, 0, 6),
                BackgroundColor3 = Color3.fromRGB(43, 45, 52),
                BorderSizePixel = 0,
                Active = true,
                Parent = card
            })

            Corner(bar, 8)

            local function Ratio(number)
                if maximumValue == minimumValue then
                    return 0
                end

                return Clamp((number - minimumValue) / (maximumValue - minimumValue), 0, 1)
            end

            local fill = Create("Frame", {
                Size = UDim2.new(Ratio(value), 0, 1, 0),
                BackgroundColor3 = theme.Accent,
                BorderSizePixel = 0,
                Parent = bar
            })

            Corner(fill, 8)

            local knob = Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(Ratio(value), 0, 0.5, 0),
                Size = UDim2.fromOffset(14, 14),
                BackgroundColor3 = Color3.fromRGB(242, 247, 255),
                BorderSizePixel = 0,
                Parent = bar
            })

            Corner(knob, 12)
            Stroke(knob, theme.AccentLight, 0.1, 1)

            local function SetValue(newValue, fire)
                local multiplier = 10 ^ decimals

                value = Clamp(tonumber(newValue) or minimumValue, minimumValue, maximumValue)
                value = math.floor(value * multiplier + 0.5) / multiplier

                local ratio = Ratio(value)

                fill.Size = UDim2.new(ratio, 0, 1, 0)
                knob.Position = UDim2.new(ratio, 0, 0.5, 0)
                valueLabel.Text = tostring(value)

                if fire ~= false then
                    Callback(config.Callback, value)
                end
            end

            local dragging = false
            local activeTouch

            local function Update(input)
                local ratio = Clamp(
                    (input.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1),
                    0,
                    1
                )

                SetValue(minimumValue + (maximumValue - minimumValue) * ratio)
            end

            Connect(bar.InputBegan, function(input)
                if not IsPointer(input) then
                    return
                end

                dragging = true
                activeTouch = input.UserInputType == Enum.UserInputType.Touch and input or nil
                Update(input)
            end)

            Connect(UserInputService.InputChanged, function(input)
                if not dragging then
                    return
                end

                if input.UserInputType == Enum.UserInputType.MouseMovement and not activeTouch then
                    Update(input)
                elseif input.UserInputType == Enum.UserInputType.Touch and input == activeTouch then
                    Update(input)
                end
            end)

            Connect(UserInputService.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input == activeTouch then
                    dragging = false
                    activeTouch = nil
                end
            end)

            return Handle(card, {
                SetValue = SetValue,
                GetValue = function()
                    return value
                end,
                SetText = function(_, newText)
                    text.Text = tostring(newText)
                end
            })
        end

        function api:CreateInput(config)
            config = config or {}

            local card = MakeCard(page, 67)

            local text = Label(card, config.Name or "Input", 13, theme.Text, true)
            text.Position = UDim2.fromOffset(12, 4)
            text.Size = UDim2.new(1, -24, 0, 20)

            local box = Create("TextBox", {
                Position = UDim2.fromOffset(10, 29),
                Size = UDim2.new(1, -20, 0, 28),
                BackgroundColor3 = theme.Background,
                BorderSizePixel = 0,
                Text = tostring(config.Default or ""),
                PlaceholderText = config.Placeholder or "Enter a value...",
                PlaceholderColor3 = theme.SubText,
                TextColor3 = theme.Text,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                Parent = card
            })

            Corner(box, 7)
            Stroke(box, theme.Border, 0.55, 1)
            AddPadding(box, 8, 8, 0, 0)

            Connect(box.FocusLost, function(enterPressed)
                Callback(config.Callback, box.Text, enterPressed)
            end)

            return Handle(card, {
                TextBox = box,
                GetValue = function()
                    return box.Text
                end,
                SetValue = function(_, newValue)
                    box.Text = tostring(newValue or "")
                end,
                SetText = function(_, newText)
                    text.Text = tostring(newText)
                end
            })
        end

        function api:CreateDropdown(config)
            config = config or {}

            local values = config.Options or {}
            local selected = config.Default or "Select an option"
            local opened = false
            local optionConnections = {}

            local card = MakeCard(page, 59)
            card.ClipsDescendants = false
            card.ZIndex = 6

            local text = Label(card, config.Name or "Dropdown", 13, theme.Text, true)
            text.Position = UDim2.fromOffset(12, 3)
            text.Size = UDim2.new(1, -24, 0, 20)

            local dropdownButton = Create("TextButton", {
                Position = UDim2.fromOffset(9, 27),
                Size = UDim2.new(1, -18, 0, 25),
                BackgroundColor3 = theme.Background,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 7,
                Parent = card
            })

            Corner(dropdownButton, 7)
            Stroke(dropdownButton, theme.Border, 0.6, 1)

            local selectedText = Label(dropdownButton, selected, 11, theme.SubText, false)
            selectedText.Position = UDim2.fromOffset(8, 0)
            selectedText.Size = UDim2.new(1, -30, 1, 0)
            selectedText.TextTruncate = Enum.TextTruncate.AtEnd
            selectedText.ZIndex = 8

            local arrow = Label(dropdownButton, "⌄", 15, theme.AccentLight, true)
            arrow.Position = UDim2.new(1, -26, 0, 0)
            arrow.Size = UDim2.fromOffset(20, 25)
            arrow.TextXAlignment = Enum.TextXAlignment.Center
            arrow.ZIndex = 8

            local popup = Create("Frame", {
                Position = UDim2.new(0, 0, 1, 4),
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundColor3 = theme.Surface,
                BorderSizePixel = 0,
                Visible = false,
                ClipsDescendants = true,
                ZIndex = 30,
                Parent = card
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
                ZIndex = 31,
                Parent = popup
            })

            AddPadding(list, 4, 4, 4, 4)

            Create("UIListLayout", {
                Padding = UDim.new(0, 3),
                Parent = list
            })

            local function ClearOptions()
                for _, connection in ipairs(optionConnections) do
                    connection:Disconnect()
                end

                table.clear(optionConnections)

                for _, child in ipairs(list:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end
            end

            local function SetOpen(state)
                opened = state

                if opened then
                    popup.Visible = true

                    PlayTween(popup, 0.14, {
                        Size = UDim2.new(1, 0, 0, math.min(#values * 29 + 8, 145))
                    })
                else
                    PlayTween(popup, 0.12, {
                        Size = UDim2.new(1, 0, 0, 0)
                    })

                    task.delay(0.13, function()
                        if popup.Parent and not opened then
                            popup.Visible = false
                        end
                    end)
                end
            end

            local function Refresh()
                ClearOptions()

                for _, option in ipairs(values) do
                    local value = option

                    local optionButton = Create("TextButton", {
                        Size = UDim2.new(1, 0, 0, 27),
                        BackgroundColor3 = theme.SurfaceLight,
                        BackgroundTransparency = 0.25,
                        BorderSizePixel = 0,
                        Text = tostring(value),
                        TextColor3 = theme.Text,
                        TextSize = 11,
                        Font = Enum.Font.Gotham,
                        AutoButtonColor = false,
                        ZIndex = 32,
                        Parent = list
                    })

                    Corner(optionButton, 6)

                    table.insert(optionConnections, optionButton.Activated:Connect(function()
                        selected = value
                        selectedText.Text = tostring(value)
                        SetOpen(false)
                        Callback(config.Callback, value)
                    end))
                end
            end

            Refresh()

            Connect(dropdownButton.Activated, function()
                SetOpen(not opened)
            end)

            Connect(card.Destroying, ClearOptions)

            return Handle(card, {
                GetValue = function()
                    return selected
                end,

                SetValue = function(_, value, fire)
                    selected = value
                    selectedText.Text = tostring(value)

                    if fire ~= false then
                        Callback(config.Callback, value)
                    end
                end,

                Refresh = function(_, newOptions)
                    values = newOptions or {}
                    Refresh()
                end,

                SetText = function(_, newText)
                    text.Text = tostring(newText)
                end
            })
        end

        function api:CreateParagraph(config)
            config = config or {}

            local card = MakeCard(page, config.Height or 78)

            local text = Label(card, config.Title or config.Name or "Information", 13, theme.Text, true)
            text.Position = UDim2.fromOffset(12, 7)
            text.Size = UDim2.new(1, -24, 0, 20)

            local body = Label(card, config.Content or "", 11, theme.SubText, false)
            body.Position = UDim2.fromOffset(12, 30)
            body.Size = UDim2.new(1, -24, 1, -36)
            body.TextWrapped = true
            body.TextYAlignment = Enum.TextYAlignment.Top

            return Handle(card, {
                SetTitle = function(_, value)
                    text.Text = tostring(value)
                end,

                SetContent = function(_, value)
                    body.Text = tostring(value)
                end
            })
        end

        function api:CreateKeybind(config)
            config = config or {}

            local key = config.Default or Enum.KeyCode.RightShift
            local listening = false
            local card = MakeCard(page, 48)

            local text = Label(card, config.Name or "Keybind", 13, theme.Text, true)
            text.Position = UDim2.fromOffset(12, 0)
            text.Size = UDim2.new(1, -115, 1, 0)

            local keyButton = Button(card, key.Name, 28)
            keyButton.AnchorPoint = Vector2.new(1, 0.5)
            keyButton.Position = UDim2.new(1, -10, 0.5, 0)
            keyButton.Size = UDim2.fromOffset(90, 28)

            Connect(keyButton.Activated, function()
                listening = true
                keyButton.Text = "Press key"
            end)

            Connect(UserInputService.InputBegan, function(input, processed)
                if processed or destroyed then
                    return
                end

                if listening then
                    if input.KeyCode == Enum.KeyCode.Unknown then
                        return
                    end

                    key = input.KeyCode
                    keyButton.Text = key.Name
                    listening = false
                    Callback(config.Changed, key)
                elseif input.KeyCode == key then
                    Callback(config.Callback, key)
                end
            end)

            return Handle(card, {
                SetValue = function(_, newKey)
                    if typeof(newKey) == "EnumItem" then
                        key = newKey
                        keyButton.Text = key.Name
                    end
                end,

                GetValue = function()
                    return key
                end,

                SetText = function(_, value)
                    text.Text = tostring(value)
                end
            })
        end

        SelectTab(#tabs == 1 and tab or currentTab)

        return api
    end

    windowObject.Tab = windowObject.CreateTab

    function windowObject:SetTitle(value)
        titleLabel.Text = tostring(value)
    end

    function windowObject:SetSubtitle(value)
        subtitle.Text = tostring(value)
    end

    function windowObject:SetSize(newSize)
        if destroyed or typeof(newSize) ~= "UDim2" then
            return
        end

        local view = Viewport()

        local newWidth = Clamp(
            newSize.X.Offset,
            math.min(minimum.X, view.X),
            math.min(maximum.X, view.X)
        )

        local newHeight = Clamp(
            newSize.Y.Offset,
            math.min(minimum.Y, view.Y),
            math.min(maximum.Y, view.Y)
        )

        savedSize = Vector2.new(newWidth, newHeight)

        PlayTween(window, 0.17, {
            Size = UDim2.fromOffset(newWidth, newHeight)
        })

        PlayTween(shadow, 0.17, {
            Size = UDim2.fromOffset(newWidth + 4, newHeight + 4)
        })
    end

    function windowObject:SetVisible(visible)
        windowVisible = visible == true

        if not destroyed then
            shadow.Visible = windowVisible and not minimized
            window.Visible = windowVisible
        end
    end

    function windowObject:Toggle()
        windowVisible = not windowVisible

        if not destroyed then
            window.Visible = windowVisible
            shadow.Visible = windowVisible and not minimized
        end
    end

    function windowObject:SelectTab(name)
        for _, tab in ipairs(tabs) do
            if tab.Name == name then
                SelectTab(tab)
                return true
            end
        end

        return false
    end

    function windowObject:Notify(config)
        if destroyed then
            return
        end

        if type(config) ~= "table" then
            config = {
                Title = "Notification",
                Content = tostring(config)
            }
        end

        local toast = Create("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 330, 0, 18),
            Size = UDim2.fromOffset(285, 76),
            BackgroundColor3 = theme.Surface,
            BorderSizePixel = 0,
            ZIndex = 80,
            Parent = gui
        })

        Corner(toast, 12)
        Stroke(toast, theme.BorderLight, 0.15, 1)

        local accent = Create("Frame", {
            Size = UDim2.new(0, 3, 1, -18),
            Position = UDim2.fromOffset(0, 9),
            BackgroundColor3 = theme.AccentLight,
            BorderSizePixel = 0,
            ZIndex = 81,
            Parent = toast
        })

        Corner(accent, 4)

        local toastTitle = Label(toast, config.Title or "Notification", 13, theme.Text, true)
        toastTitle.Position = UDim2.fromOffset(13, 8)
        toastTitle.Size = UDim2.new(1, -24, 0, 21)
        toastTitle.ZIndex = 81

        local toastBody = Label(toast, config.Content or config.Message or "", 11, theme.SubText, false)
        toastBody.Position = UDim2.fromOffset(13, 30)
        toastBody.Size = UDim2.new(1, -24, 0, 37)
        toastBody.TextWrapped = true
        toastBody.TextYAlignment = Enum.TextYAlignment.Top
        toastBody.ZIndex = 81

        table.insert(toasts, toast)

        PlayTween(toast, 0.22, {
            Position = UDim2.new(1, -15, 0, 18)
        })

        task.delay(math.max(tonumber(config.Duration) or 3, 0.1), function()
            if not toast.Parent then
                return
            end

            PlayTween(toast, 0.18, {
                Position = UDim2.new(1, 330, 0, 18),
                BackgroundTransparency = 1
            })

            task.delay(0.2, function()
                if toast.Parent then
                    toast:Destroy()
                end
            end)
        end)

        return toast
    end

    function windowObject:Minimize()
        if destroyed then
            return
        end

        minimized = not minimized

        if minimized then
            sidebar.Visible = false
            content.Visible = false
            resizeGrip.Visible = false

            PlayTween(window, {
                Size = UDim2.fromOffset(window.AbsoluteSize.X, 65)
            }, 0.16)

            PlayTween(shadow, {
                Size = UDim2.fromOffset(window.AbsoluteSize.X + 4, 69)
            }, 0.16)
        else
            sidebar.Visible = true
            content.Visible = true
            resizeGrip.Visible = true

            PlayTween(window, {
                Size = UDim2.fromOffset(savedSize.X, savedSize.Y)
            }, 0.16)

            PlayTween(shadow, {
                Size = UDim2.fromOffset(savedSize.X + 4, savedSize.Y + 4)
            }, 0.16)
        end

        shadow.Visible = windowVisible and not minimized
    end

    function windowObject:Destroy()
        if destroyed then
            return
        end

        destroyed = true

        for _, connection in ipairs(connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end

        table.clear(connections)
        table.clear(tabs)
        table.clear(toasts)

        gui:Destroy()

        if LiquidUI.Window == self then
            LiquidUI.Window = nil
        end
    end

    Connect(minimizeButton.Activated, function()
        windowObject:Minimize()
    end)

    Connect(closeButton.Activated, function()
        windowObject:Destroy()
    end)

    Connect(minimizeButton.MouseEnter, function()
        minimizeButton.TextColor3 = theme.AccentLight
    end)

    Connect(minimizeButton.MouseLeave, function()
        minimizeButton.TextColor3 = theme.SubText
    end)

    Connect(closeButton.MouseEnter, function()
        closeButton.TextColor3 = theme.Danger
    end)

    Connect(closeButton.MouseLeave, function()
        closeButton.TextColor3 = theme.Text
    end)

    -- Dragging: touch and mouse, with the close/minimize buttons excluded.

    local dragging = false
    local dragInput
    local dragStart
    local dragOrigin
    local dragConnection

    local function StopDrag()
        dragging = false
        dragInput = nil
        dragStart = nil
        dragOrigin = nil

        if dragConnection then
            dragConnection:Disconnect()
            dragConnection = nil
        end
    end

    local function UpdateDrag(input)
        if not dragging or not dragStart or not dragOrigin or destroyed then
            return
        end

        local delta = input.Position - dragStart
        local target = UDim2.fromOffset(
            dragOrigin.X + delta.X,
            dragOrigin.Y + delta.Y
        )

        window.Position = ClampPosition(target)
        SyncShadow()
    end

    Connect(topbar.InputBegan, function(input)
        if destroyed or not IsPointer(input) then
            return
        end

        local mousePosition = input.Position
        local closePosition = closeButton.AbsolutePosition
        local minimizePosition = minimizeButton.AbsolutePosition

        local function Within(position, size)
            return mousePosition.X >= position.X
                and mousePosition.X <= position.X + size.X
                and mousePosition.Y >= position.Y
                and mousePosition.Y <= position.Y + size.Y
        end

        if Within(closePosition, closeButton.AbsoluteSize)
            or Within(minimizePosition, minimizeButton.AbsoluteSize) then
            return
        end

        dragging = true
        dragInput = input.UserInputType == Enum.UserInputType.Touch and input or nil
        dragStart = input.Position
        dragOrigin = Vector2.new(
            window.Position.X.Offset,
            window.Position.Y.Offset
        )

        if dragInput then
            dragConnection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    StopDrag()
                else
                    UpdateDrag(input)
                end
            end)
        end
    end)

    Connect(UserInputService.InputChanged, function(input)
        if dragging and not dragInput and input.UserInputType == Enum.UserInputType.MouseMovement then
            UpdateDrag(input)
        end
    end)

    Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not dragInput then
            StopDrag()
        elseif dragInput and input == dragInput then
            StopDrag()
        end
    end)

    -- Resizing

    local resizing = false
    local resizeInput
    local resizeStart
    local resizeOrigin
    local resizeConnection

    local function StopResize()
        resizing = false
        resizeInput = nil
        resizeStart = nil
        resizeOrigin = nil

        if resizeConnection then
            resizeConnection:Disconnect()
            resizeConnection = nil
        end
    end

    local function UpdateResize(input)
        if not resizing or not resizeStart or not resizeOrigin or destroyed then
            return
        end

        local delta = input.Position - resizeStart
        local view = Viewport()

        local minWidth = math.min(minimum.X, view.X)
        local minHeight = math.min(minimum.Y, view.Y)
        local maxWidth = math.max(minWidth, math.min(maximum.X, view.X))
        local maxHeight = math.max(minHeight, math.min(maximum.Y, view.Y))

        local newWidth = Clamp(resizeOrigin.X + delta.X, minWidth, maxWidth)
        local newHeight = Clamp(resizeOrigin.Y + delta.Y, minHeight, maxHeight)

        savedSize = Vector2.new(newWidth, newHeight)

        window.Size = UDim2.fromOffset(newWidth, newHeight)
        SyncShadow()
    end

    Connect(resizeGrip.InputBegan, function(input)
        if destroyed or minimized or not IsPointer(input) then
            return
        end

        resizing = true
        resizeInput = input.UserInputType == Enum.UserInputType.Touch and input or nil
        resizeStart = input.Position
        resizeOrigin = window.AbsoluteSize

        if resizeInput then
            resizeConnection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    StopResize()
                else
                    UpdateResize(input)
                end
            end)
        end
    end)

    Connect(UserInputService.InputChanged, function(input)
        if resizing and not resizeInput and input.UserInputType == Enum.UserInputType.MouseMovement then
            UpdateResize(input)
        end
    end)

    Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not resizeInput then
            StopResize()
        elseif resizeInput and input == resizeInput then
            StopResize()
        end
    end)

    -- Keyboard toggle and responsive positioning.

    Connect(UserInputService.InputBegan, function(input, processed)
        if destroyed or processed then
            return
        end

        if input.KeyCode == toggleKey then
            windowVisible = not windowVisible
            window.Visible = windowVisible
            shadow.Visible = windowVisible and not minimized
        end
    end)

    local viewportConnection

    local function UpdateViewport()
        if destroyed then
            return
        end

        local view = Viewport()

        local newWidth = Clamp(
            window.AbsoluteSize.X,
            math.min(minimum.X, view.X),
            math.min(maximum.X, view.X)
        )

        local newHeight = Clamp(
            window.AbsoluteSize.Y,
            math.min(minimum.Y, view.Y),
            math.min(maximum.Y, view.Y)
        )

        savedSize = Vector2.new(newWidth, newHeight)
        window.Size = UDim2.fromOffset(newWidth, newHeight)
        window.Position = ClampPosition(window.Position)
        SyncShadow()
    end

    local function WatchCamera()
        if viewportConnection then
            viewportConnection:Disconnect()
            viewportConnection = nil
        end

        local camera = workspace.CurrentCamera

        if camera then
            viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateViewport)
        end
    end

    Connect(workspace:GetPropertyChangedSignal("CurrentCamera"), WatchCamera)
    WatchCamera()

    Connect(gui.Destroying, function()
        StopDrag()
        StopResize()

        if viewportConnection then
            viewportConnection:Disconnect()
        end
    end)

    -- Open the main window after the animated intro.

    local function OpenMain()
        if destroyed then
            return
        end

        openingStatus.Text = "READY"

        PlayTween(loadingFill, 0.25, {
            Size = UDim2.fromScale(1, 1)
        })

        task.delay(0.3, function()
            if destroyed or not opening.Parent then
                return
            end

            PlayTween(openingCard, 0.2, {
                Position = UDim2.fromScale(0.5, 0.47),
                BackgroundTransparency = 1
            })

            PlayTween(opening, 0.24, {
                BackgroundTransparency = 1
            })

            for _, object in ipairs(openingCard:GetDescendants()) do
                if object:IsA("TextLabel") then
                    PlayTween(object, 0.15, {
                        TextTransparency = 1
                    })
                elseif object:IsA("UIStroke") then
                    PlayTween(object, 0.15, {
                        Transparency = 1
                    })
                elseif object:IsA("Frame") then
                    PlayTween(object, 0.15, {
                        BackgroundTransparency = 1
                    })
                end
            end

            task.delay(0.26, function()
                if destroyed then
                    return
                end

                opening:Destroy()
                window.Visible = true
                shadow.Visible = true

                window.Size = UDim2.fromOffset(savedSize.X - 12, savedSize.Y - 12)
                shadow.Size = UDim2.fromOffset(savedSize.X - 8, savedSize.Y - 8)

                PlayTween(window, 0.24, {
                    Size = UDim2.fromOffset(savedSize.X, savedSize.Y)
                })

                PlayTween(shadow, 0.24, {
                    Size = UDim2.fromOffset(savedSize.X + 4, savedSize.Y + 4)
                })

                windowObject:Notify({
                    Title = options.Title or "LiquidUI",
                    Content = "Black Glass interface loaded.",
                    Duration = 2.5
                })
            end)
        end)
    end

    self.Window = windowObject

    task.spawn(function()
        PlayTween(loadingFill, 0.65, {
            Size = UDim2.new(0.72, 0, 1, 0)
        })

        task.wait(0.68)

        if destroyed then
            return
        end

        openingStatus.Text = "PREPARING WORKSPACE"

        PlayTween(loadingFill, 0.4, {
            Size = UDim2.new(1, 0, 1, 0)
        })

        task.wait(0.42)
        OpenMain()
    end)

    if options.Visible == false then
        windowVisible = false
        window.Visible = false
        shadow.Visible = false
    end

    return windowObject
end

function LiquidUI:Notify(config)
    if self.Window then
        return self.Window:Notify(config)
    end
end

return LiquidUI
