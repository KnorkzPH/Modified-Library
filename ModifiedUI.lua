local LiquidUI = {}
LiquidUI.__index = LiquidUI

LiquidUI.Version = "2.0.0"

LiquidUI.Theme = {
    Background = Color3.fromRGB(12, 22, 39),
    Surface = Color3.fromRGB(19, 35, 59),
    SurfaceLight = Color3.fromRGB(28, 48, 76),
    Accent = Color3.fromRGB(52, 169, 255),
    AccentLight = Color3.fromRGB(83, 218, 255),
    Text = Color3.fromRGB(235, 244, 255),
    SubText = Color3.fromRGB(151, 180, 216),
    Border = Color3.fromRGB(82, 130, 184),
    Success = Color3.fromRGB(76, 220, 155),
    Danger = Color3.fromRGB(255, 100, 120)
}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer

local function Create(class, properties, children)
    local object = Instance.new(class)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    for _, child in ipairs(children or {}) do
        child.Parent = object
    end

    return object
end

local function Corner(parent, radius)
    return Create("UICorner", {
        CornerRadius = UDim.new(0, radius or 12),
        Parent = parent
    })
end

local function Stroke(parent, color, transparency, thickness)
    return Create("UIStroke", {
        Color = color or LiquidUI.Theme.Border,
        Transparency = transparency or 0.4,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent
    })
end

local function Padding(parent, left, right, top, bottom)
    return Create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        Parent = parent
    })
end

local function Tween(object, properties, duration)
    local tween = TweenService:Create(
        object,
        TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        properties
    )
    tween:Play()
    return tween
end

local function Label(parent, text, size, color, bold)
    return Create("TextLabel", {
        BackgroundTransparency = 1,
        Text = text or "",
        TextSize = size or 14,
        Font = bold and Enum.Font.GothamSemibold or Enum.Font.Gotham,
        TextColor3 = color or LiquidUI.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Size = UDim2.new(1, 0, 0, 22),
        Parent = parent
    })
end

function LiquidUI:SetTheme(theme)
    for key, value in pairs(theme or {}) do
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
    local currentTab
    local destroyed = false
    local minimized = false

    local size = options.Size or UDim2.fromOffset(850, 560)
    local title = options.Title or "LiquidUI"

    local gui = Create("ScreenGui", {
        Name = "LiquidUI_" .. tostring(math.random(1000, 999999)),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    local parentSuccess = pcall(function()
        gui.Parent = CoreGui
    end)

    if not parentSuccess then
        gui.Parent = Player:WaitForChild("PlayerGui")
    end

    local shadow = Create("Frame", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = size + UDim2.fromOffset(12, 12),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        Parent = gui
    })
    Corner(shadow, 26)

    local window = Create("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = size,
        BackgroundColor3 = theme.Background,
        BackgroundTransparency = 0.12,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = gui
    })
    Corner(window, 25)
    Stroke(window, theme.Border, 0.08, 1.4)

    local backgroundGradient = Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(27, 51, 81)),
            ColorSequenceKeypoint.new(0.5, theme.Background),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 25, 44))
        }),
        Rotation = 35,
        Parent = window
    })

    local topbar = Create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 72),
        BackgroundColor3 = Color3.fromRGB(25, 45, 72),
        BackgroundTransparency = 0.18,
        BorderSizePixel = 0,
        Parent = window
    })

    local logo = Create("Frame", {
        Position = UDim2.fromOffset(18, 13),
        Size = UDim2.fromOffset(46, 46),
        BackgroundColor3 = theme.Accent,
        BackgroundTransparency = 0.12,
        BorderSizePixel = 0,
        Parent = topbar
    })
    Corner(logo, 14)
    Stroke(logo, theme.AccentLight, 0.3, 1)

    local logoText = Label(logo, options.Logo or "L", 23, theme.Text, true)
    logoText.TextXAlignment = Enum.TextXAlignment.Center
    logoText.Size = UDim2.fromScale(1, 1)

    local titleLabel = Label(topbar, title, 18, theme.Text, true)
    titleLabel.Position = UDim2.fromOffset(76, 12)
    titleLabel.Size = UDim2.new(1, -180, 0, 27)

    local subtitle = Label(topbar, options.Subtitle or "Better tools. Smoother workflow.", 13, theme.SubText, false)
    subtitle.Position = UDim2.fromOffset(77, 39)
    subtitle.Size = UDim2.new(1, -180, 0, 20)

    local minimizeButton = Create("TextButton", {
        Name = "Minimize",
        Position = UDim2.new(1, -84, 0, 15),
        Size = UDim2.fromOffset(32, 34),
        BackgroundTransparency = 1,
        Text = "−",
        TextSize = 25,
        Font = Enum.Font.Gotham,
        TextColor3 = theme.SubText,
        AutoButtonColor = false,
        Parent = topbar
    })

    local closeButton = Create("TextButton", {
        Name = "Close",
        Position = UDim2.new(1, -47, 0, 15),
        Size = UDim2.fromOffset(32, 34),
        BackgroundTransparency = 1,
        Text = "×",
        TextSize = 27,
        Font = Enum.Font.Gotham,
        TextColor3 = theme.Text,
        AutoButtonColor = false,
        Parent = topbar
    })

    local sidebar = Create("Frame", {
        Name = "Sidebar",
        Position = UDim2.fromOffset(0, 72),
        Size = UDim2.new(0, 174, 1, -72),
        BackgroundColor3 = Color3.fromRGB(13, 27, 47),
        BackgroundTransparency = 0.16,
        BorderSizePixel = 0,
        Parent = window
    })

    local sidebarList = Create("ScrollingFrame", {
        Name = "TabList",
        Position = UDim2.fromOffset(10, 13),
        Size = UDim2.new(1, -20, 1, -78),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.Accent,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = sidebar
    })

    local sidebarLayout = Create("UIListLayout", {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = sidebarList
    })

    local profile = Create("Frame", {
        Name = "Profile",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -12),
        Size = UDim2.new(1, -20, 0, 52),
        BackgroundColor3 = theme.SurfaceLight,
        BackgroundTransparency = 0.22,
        BorderSizePixel = 0,
        Parent = sidebar
    })
    Corner(profile, 13)
    Stroke(profile, theme.Border, 0.6, 1)

    local profileIcon = Label(profile, "◉", 23, theme.AccentLight, true)
    profileIcon.Position = UDim2.fromOffset(11, 5)
    profileIcon.Size = UDim2.fromOffset(30, 40)

    local profileName = Label(profile, options.Author or "User", 13, theme.Text, true)
    profileName.Position = UDim2.fromOffset(43, 6)
    profileName.Size = UDim2.new(1, -48, 0, 19)

    local profileVersion = Label(profile, "LiquidUI v" .. self.Version, 10, theme.SubText, false)
    profileVersion.Position = UDim2.fromOffset(43, 25)
    profileVersion.Size = UDim2.new(1, -48, 0, 17)

    local content = Create("Frame", {
        Name = "Content",
        Position = UDim2.new(0, 174, 0, 72),
        Size = UDim2.new(1, -174, 1, -72),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = window
    })

    local tabHeader = Create("Frame", {
        Name = "TabHeader",
        Position = UDim2.fromOffset(14, 10),
        Size = UDim2.new(1, -28, 0, 44),
        BackgroundTransparency = 1,
        Parent = content
    })

    local tabTitle = Label(tabHeader, "Welcome Back!", 20, theme.Text, true)
    tabTitle.Size = UDim2.new(1, 0, 0, 26)

    local tabDescription = Label(tabHeader, "Choose a component to get started.", 12, theme.SubText, false)
    tabDescription.Position = UDim2.fromOffset(0, 25)
    tabDescription.Size = UDim2.new(1, 0, 0, 18)

    local pageHolder = Create("Frame", {
        Name = "Pages",
        Position = UDim2.fromOffset(12, 60),
        Size = UDim2.new(1, -24, 1, -72),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = content
    })

    local resizeGrip = Create("TextButton", {
        Name = "ResizeGrip",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -3, 1, -3),
        Size = UDim2.fromOffset(18, 18),
        BackgroundTransparency = 1,
        Text = "◢",
        TextSize = 13,
        TextColor3 = theme.SubText,
        AutoButtonColor = false,
        Parent = window
    })

    local windowObject = {
        Instance = window,
        ScreenGui = gui,
        Tabs = tabs
    }

    local function AddConnection(connection)
        table.insert(connections, connection)
        return connection
    end

    local function SelectTab(tab)
        if destroyed or not tab then
            return
        end

        currentTab = tab

        for _, item in ipairs(tabs) do
            local active = item == tab

            item.Page.Visible = active
            Tween(item.Button, {
                BackgroundColor3 = active and theme.Accent or theme.Surface,
                BackgroundTransparency = active and 0.1 or 0.55
            }, 0.16)

            item.Button.TextColor3 = active and theme.Text or theme.SubText
            item.Indicator.BackgroundTransparency = active and 0 or 1
        end

        tabTitle.Text = tab.Name
        tabDescription.Text = tab.Description or "Manage your " .. tab.Name .. " components."
    end

    local function MakeCard(parent, height)
        local card = Create("Frame", {
            Size = UDim2.new(1, 0, 0, height or 58),
            BackgroundColor3 = theme.SurfaceLight,
            BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Parent = parent
        })
        Corner(card, 13)
        Stroke(card, theme.Border, 0.58, 1)
        return card
    end

    local function CreateTab(_, name, description)
        name = tostring(name or ("Tab " .. (#tabs + 1)))

        local button = Create("TextButton", {
            Name = name .. "TabButton",
            Size = UDim2.new(1, 0, 0, 43),
            BackgroundColor3 = theme.Surface,
            BackgroundTransparency = 0.55,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Parent = sidebarList
        })
        Corner(button, 12)

        local indicator = Create("Frame", {
            Size = UDim2.new(0, 4, 1, -10),
            Position = UDim2.fromOffset(0, 5),
            BackgroundColor3 = theme.AccentLight,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = button
        })
        Corner(indicator, 4)

        local icon = Label(button, "◇", 19, theme.AccentLight, true)
        icon.Position = UDim2.fromOffset(12, 0)
        icon.Size = UDim2.fromOffset(24, 43)

        local tabLabel = Label(button, name, 13, theme.SubText, true)
        tabLabel.Position = UDim2.fromOffset(43, 0)
        tabLabel.Size = UDim2.new(1, -48, 1, 0)

        local page = Create("ScrollingFrame", {
            Name = name .. "Page",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = theme.Accent,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            Parent = pageHolder
        })

        Padding(page, 1, 5, 1, 8)

        local pageLayout = Create("UIListLayout", {
            Padding = UDim.new(0, 9),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = page
        })

        local tab = {
            Name = name,
            Description = description,
            Button = button,
            Indicator = indicator,
            Page = page,
            Layout = pageLayout
        }

        table.insert(tabs, tab)

        AddConnection(button.MouseButton1Click:Connect(function()
            SelectTab(tab)
        end))

        AddConnection(button.MouseEnter:Connect(function()
            if currentTab ~= tab then
                Tween(button, {BackgroundTransparency = 0.35}, 0.12)
            end
        end))

        AddConnection(button.MouseLeave:Connect(function()
            if currentTab ~= tab then
                Tween(button, {BackgroundTransparency = 0.55}, 0.12)
            end
        end))

        function tab:AddSection(sectionName)
            local section = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 31),
                BackgroundTransparency = 1,
                Parent = page
            })

            local sectionLabel = Label(section, tostring(sectionName), 14, theme.AccentLight, true)
            sectionLabel.Position = UDim2.fromOffset(7, 0)
            sectionLabel.Size = UDim2.new(1, -14, 1, 0)

            return section
        end

        function tab:CreateLabel(config)
            config = type(config) == "table" and config or {Name = tostring(config)}

            local label = Label(page, config.Name or config.Text or "Label", config.TextSize or 13, config.Color or theme.SubText, config.Bold)
            label.Size = UDim2.new(1, -8, 0, config.Height or 27)
            label.TextWrapped = true

            return {
                Instance = label,
                SetText = function(_, value)
                    label.Text = tostring(value)
                end,
                SetVisible = function(_, value)
                    label.Visible = value
                end
            }
        end

        function tab:CreateDivider()
            local divider = Create("Frame", {
                Size = UDim2.new(1, -4, 0, 1),
                BackgroundColor3 = theme.Border,
                BackgroundTransparency = 0.55,
                BorderSizePixel = 0,
                Parent = page
            })
            return divider
        end

        function tab:CreateButton(config)
            config = config or {}

            local card = MakeCard(page, config.Height or 52)

            local button = Create("TextButton", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                Parent = card
            })

            local accent = Create("Frame", {
                Position = UDim2.fromOffset(0, 9),
                Size = UDim2.new(0, 3, 1, -18),
                BackgroundColor3 = theme.AccentLight,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Parent = card
            })
            Corner(accent, 3)

            local nameLabel = Label(card, config.Name or config.Title or "Button", 14, theme.Text, true)
            nameLabel.Position = UDim2.fromOffset(16, 0)
            nameLabel.Size = UDim2.new(1, -55, 1, 0)

            local arrow = Label(card, "›", 25, theme.AccentLight, false)
            arrow.TextXAlignment = Enum.TextXAlignment.Center
            arrow.Position = UDim2.new(1, -37, 0, 0)
            arrow.Size = UDim2.fromOffset(27, 52)

            AddConnection(button.MouseEnter:Connect(function()
                Tween(card, {BackgroundTransparency = 0.08}, 0.13)
                Tween(accent, {BackgroundTransparency = 0}, 0.13)
            end))

            AddConnection(button.MouseLeave:Connect(function()
                Tween(card, {BackgroundTransparency = 0.25}, 0.13)
                Tween(accent, {BackgroundTransparency = 1}, 0.13)
            end))

            AddConnection(button.MouseButton1Click:Connect(function()
                Tween(card, {BackgroundColor3 = theme.Accent}, 0.08)
                task.delay(0.12, function()
                    if card.Parent then
                        Tween(card, {BackgroundColor3 = theme.SurfaceLight}, 0.16)
                    end
                end)

                if config.Callback then
                    task.spawn(config.Callback)
                end
            end))

            return {
                Instance = card,
                Button = button,
                SetText = function(_, value)
                    nameLabel.Text = tostring(value)
                end,
                SetVisible = function(_, value)
                    card.Visible = value
                end
            }
        end

        function tab:CreateToggle(config)
            config = config or {}

            local value = config.Default == true
            local card = MakeCard(page, config.Height or 58)

            local nameLabel = Label(card, config.Name or "Toggle", 13, theme.Text, true)
            nameLabel.Position = UDim2.fromOffset(14, 7)
            nameLabel.Size = UDim2.new(1, -90, 0, 21)

            local description = config.Description
            local descriptionLabel

            if description then
                descriptionLabel = Label(card, description, 11, theme.SubText, false)
                descriptionLabel.Position = UDim2.fromOffset(14, 29)
                descriptionLabel.Size = UDim2.new(1, -90, 0, 18)
                descriptionLabel.TextTruncate = Enum.TextTruncate.AtEnd
            end

            local toggleButton = Create("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -12, 0.5, 0),
                Size = UDim2.fromOffset(42, 24),
                BackgroundColor3 = value and theme.Accent or Color3.fromRGB(57, 76, 103),
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                Parent = card
            })
            Corner(toggleButton, 20)

            local knob = Create("Frame", {
                Position = value and UDim2.new(1, -21, 0, 3) or UDim2.fromOffset(3, 3),
                Size = UDim2.fromOffset(18, 18),
                BackgroundColor3 = Color3.fromRGB(245, 250, 255),
                BorderSizePixel = 0,
                Parent = toggleButton
            })
            Corner(knob, 20)

            local function SetValue(newValue, fireCallback)
                value = newValue == true

                Tween(toggleButton, {
                    BackgroundColor3 = value and theme.Accent or Color3.fromRGB(57, 76, 103)
                }, 0.15)

                Tween(knob, {
                    Position = value and UDim2.new(1, -21, 0, 3) or UDim2.fromOffset(3, 3)
                }, 0.15)

                if fireCallback ~= false and config.Callback then
                    task.spawn(config.Callback, value)
                end
            end

            AddConnection(toggleButton.MouseButton1Click:Connect(function()
                SetValue(not value, true)
            end))

            return {
                Instance = card,
                SetValue = SetValue,
                GetValue = function()
                    return value
                end,
                SetText = function(_, text)
                    nameLabel.Text = tostring(text)
                end,
                SetVisible = function(_, visible)
                    card.Visible = visible
                end
            }
        end

        function tab:CreateSlider(config)
            config = config or {}

            local minimum = tonumber(config.Min) or 0
            local maximum = tonumber(config.Max) or 100

            if maximum < minimum then
                minimum, maximum = maximum, minimum
            end

            local value = math.clamp(tonumber(config.Default) or minimum, minimum, maximum)
            local card = MakeCard(page, config.Height or 72)

            local nameLabel = Label(card, config.Name or "Slider", 13, theme.Text, true)
            nameLabel.Position = UDim2.fromOffset(14, 7)
            nameLabel.Size = UDim2.new(1, -85, 0, 22)

            local valueBox = Create("TextLabel", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -12, 0, 7),
                Size = UDim2.fromOffset(52, 23),
                BackgroundColor3 = theme.Surface,
                BackgroundTransparency = 0.1,
                BorderSizePixel = 0,
                Text = tostring(value),
                TextSize = 12,
                Font = Enum.Font.GothamSemibold,
                TextColor3 = theme.Text,
                Parent = card
            })
            Corner(valueBox, 8)
            Stroke(valueBox, theme.Border, 0.65, 1)

            local bar = Create("Frame", {
                Position = UDim2.new(0, 14, 0, 43),
                Size = UDim2.new(1, -28, 0, 7),
                BackgroundColor3 = Color3.fromRGB(48, 69, 101),
                BorderSizePixel = 0,
                Parent = card
            })
            Corner(bar, 8)

            local percent = maximum == minimum and 0 or (value - minimum) / (maximum - minimum)

            local fill = Create("Frame", {
                Size = UDim2.new(percent, 0, 1, 0),
                BackgroundColor3 = theme.Accent,
                BorderSizePixel = 0,
                Parent = bar
            })
            Corner(fill, 8)

            local knob = Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(percent, 0, 0.5, 0),
                Size = UDim2.fromOffset(15, 15),
                BackgroundColor3 = Color3.fromRGB(220, 241, 255),
                BorderSizePixel = 0,
                Parent = bar
            })
            Corner(knob, 12)
            Stroke(knob, theme.Accent, 0.15, 1)

            local dragging = false

            local function SetValue(newValue, fireCallback)
                newValue = math.clamp(tonumber(newValue) or minimum, minimum, maximum)

                if config.Decimals then
                    local mult = 10 ^ math.clamp(config.Decimals, 0, 4)
                    newValue = math.floor(newValue * mult + 0.5) / mult
                else
                    newValue = math.floor(newValue + 0.5)
                end

                value = newValue

                local ratio = maximum == minimum and 0 or (value - minimum) / (maximum - minimum)

                Tween(fill, {Size = UDim2.new(ratio, 0, 1, 0)}, 0.08)
                Tween(knob, {Position = UDim2.new(ratio, 0, 0.5, 0)}, 0.08)
                valueBox.Text = tostring(value)

                if fireCallback ~= false and config.Callback then
                    task.spawn(config.Callback, value)
                end
            end

            local function UpdateFromInput(input)
                local width = math.max(bar.AbsoluteSize.X, 1)
                local ratio = math.clamp(
                    (input.Position.X - bar.AbsolutePosition.X) / width,
                    0,
                    1
                )

                SetValue(minimum + (maximum - minimum) * ratio, true)
            end

            AddConnection(bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    UpdateFromInput(input)
                end
            end))

            AddConnection(UserInputService.InputChanged:Connect(function(input)
                if not dragging then
                    return
                end

                if input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch then
                    UpdateFromInput(input)
                end
            end))

            AddConnection(UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end))

            return {
                Instance = card,
                SetValue = SetValue,
                GetValue = function()
                    return value
                end,
                SetText = function(_, text)
                    nameLabel.Text = tostring(text)
                end,
                SetVisible = function(_, visible)
                    card.Visible = visible
                end
            }
        end

        function tab:CreateInput(config)
            config = config or {}

            local card = MakeCard(page, 70)

            local nameLabel = Label(card, config.Name or "Input", 13, theme.Text, true)
            nameLabel.Position = UDim2.fromOffset(13, 4)
            nameLabel.Size = UDim2.new(1, -26, 0, 22)

            local inputBox = Create("TextBox", {
                Position = UDim2.fromOffset(12, 30),
                Size = UDim2.new(1, -24, 0, 29),
                BackgroundColor3 = theme.Surface,
                BackgroundTransparency = 0.05,
                BorderSizePixel = 0,
                Text = config.Default or "",
                PlaceholderText = config.Placeholder or "Enter a value...",
                PlaceholderColor3 = theme.SubText,
                TextColor3 = theme.Text,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                ClearTextOnFocus = false,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = card
            })
            Corner(inputBox, 8)
            Stroke(inputBox, theme.Border, 0.65, 1)
            Padding(inputBox, 9, 9, 0, 0)

            AddConnection(inputBox.FocusLost:Connect(function(enterPressed)
                if config.Callback then
                    task.spawn(config.Callback, inputBox.Text, enterPressed)
                end
            end))

            return {
                Instance = card,
                TextBox = inputBox,
                GetValue = function()
                    return inputBox.Text
                end,
                SetValue = function(_, value)
                    inputBox.Text = tostring(value or "")
                end,
                SetVisible = function(_, visible)
                    card.Visible = visible
                end
            }
        end

        function tab:CreateDropdown(config)
            config = config or {}

            local values = config.Options or config.Values or {}
            local selected = config.Default
            local opened = false

            if selected == nil then
                selected = "Select an option"
            end

            local card = MakeCard(page, 58)
            card.ClipsDescendants = false
            card.ZIndex = 3

            local nameLabel = Label(card, config.Name or "Dropdown", 13, theme.Text, true)
            nameLabel.Position = UDim2.fromOffset(13, 4)
            nameLabel.Size = UDim2.new(1, -26, 0, 19)

            local dropdownButton = Create("TextButton", {
                Position = UDim2.fromOffset(10, 27),
                Size = UDim2.new(1, -20, 0, 26),
                BackgroundColor3 = theme.Surface,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                Parent = card
            })
            Corner(dropdownButton, 8)

            local selectedLabel = Label(dropdownButton, tostring(selected), 12, theme.SubText, false)
            selectedLabel.Position = UDim2.fromOffset(9, 0)
            selectedLabel.Size = UDim2.new(1, -30, 1, 0)

            local arrow = Label(dropdownButton, "⌄", 17, theme.AccentLight, true)
            arrow.TextXAlignment = Enum.TextXAlignment.Center
            arrow.Position = UDim2.new(1, -28, 0, 0)
            arrow.Size = UDim2.fromOffset(22, 26)

            local popup = Create("Frame", {
                Position = UDim2.new(0, 0, 1, 5),
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundColor3 = theme.Surface,
                BorderSizePixel = 0,
                Visible = false,
                ClipsDescendants = true,
                ZIndex = 20,
                Parent = card
            })
            Corner(popup, 9)
            Stroke(popup, theme.Border, 0.25, 1)

            local popupList = Create("ScrollingFrame", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = theme.Accent,
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                CanvasSize = UDim2.new(),
                ZIndex = 21,
                Parent = popup
            })

            local popupLayout = Create("UIListLayout", {
                Padding = UDim.new(0, 2),
                Parent = popupList
            })

            Padding(popupList, 4, 4, 4, 4)

            local function RefreshOptions()
                for _, child in ipairs(popupList:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end

                for _, option in ipairs(values) do
                    local optionText = tostring(option)

                    local optionButton = Create("TextButton", {
                        Size = UDim2.new(1, -2, 0, 29),
                        BackgroundColor3 = theme.SurfaceLight,
                        BackgroundTransparency = 0.5,
                        BorderSizePixel = 0,
                        Text = optionText,
                        TextSize = 12,
                        Font = Enum.Font.Gotham,
                        TextColor3 = theme.Text,
                        AutoButtonColor = false,
                        ZIndex = 22,
                        Parent = popupList
                    })
                    Corner(optionButton, 6)

                    optionButton.MouseButton1Click:Connect(function()
                        selected = option
                        selectedLabel.Text = optionText
                        opened = false

                        Tween(popup, {Size = UDim2.new(1, 0, 0, 0)}, 0.12)
                        task.delay(0.13, function()
                            if popup.Parent then
                                popup.Visible = false
                            end
                        end)

                        if config.Callback then
                            task.spawn(config.Callback, option)
                        end
                    end)
                end
            end

            RefreshOptions()

            AddConnection(dropdownButton.MouseButton1Click:Connect(function()
                opened = not opened

                if opened then
                    popup.Visible = true
                    local height = math.min(#values * 31 + 8, 155)
                    Tween(popup, {Size = UDim2.new(1, 0, 0, height)}, 0.16)
                else
                    Tween(popup, {Size = UDim2.new(1, 0, 0, 0)}, 0.12)
                    task.delay(0.13, function()
                        if popup.Parent and not opened then
                            popup.Visible = false
                        end
                    end)
                end
            end))

            return {
                Instance = card,
                SetValue = function(_, value)
                    selected = value
                    selectedLabel.Text = tostring(value)

                    if config.Callback then
                        task.spawn(config.Callback, value)
                    end
                end,
                GetValue = function()
                    return selected
                end,
                Refresh = function(_, newValues)
                    values = newValues or {}
                    RefreshOptions()
                end,
                SetVisible = function(_, visible)
                    card.Visible = visible
                end
            }
        end

        function tab:CreateParagraph(config)
            config = config or {}

            local card = MakeCard(page, config.Height or 82)

            local titleLabel = Label(card, config.Title or config.Name or "Information", 13, theme.Text, true)
            titleLabel.Position = UDim2.fromOffset(13, 8)
            titleLabel.Size = UDim2.new(1, -26, 0, 21)

            local body = Label(card, config.Content or config.Description or "", 12, theme.SubText, false)
            body.Position = UDim2.fromOffset(13, 31)
            body.Size = UDim2.new(1, -26, 0, (config.Height or 82) - 38)
            body.TextWrapped = true
            body.TextYAlignment = Enum.TextYAlignment.Top

            return {
                Instance = card,
                SetTitle = function(_, value)
                    titleLabel.Text = tostring(value)
                end,
                SetContent = function(_, value)
                    body.Text = tostring(value)
                end,
                SetVisible = function(_, visible)
                    card.Visible = visible
                end
            }
        end

        function tab:CreateKeybind(config)
            config = config or {}

            local key = config.Default or Enum.KeyCode.RightShift
            local listening = false

            local card = MakeCard(page, 51)

            local nameLabel = Label(card, config.Name or "Keybind", 13, theme.Text, true)
            nameLabel.Position = UDim2.fromOffset(13, 0)
            nameLabel.Size = UDim2.new(1, -115, 1, 0)

            local keyButton = Create("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -11, 0.5, 0),
                Size = UDim2.fromOffset(88, 30),
                BackgroundColor3 = theme.Surface,
                BorderSizePixel = 0,
                Text = key.Name,
                TextSize = 11,
                Font = Enum.Font.GothamSemibold,
                TextColor3 = theme.AccentLight,
                AutoButtonColor = false,
                Parent = card
            })
            Corner(keyButton, 8)
            Stroke(keyButton, theme.Border, 0.5, 1)

            AddConnection(keyButton.MouseButton1Click:Connect(function()
                listening = true
                keyButton.Text = "Press key..."
            end))

            AddConnection(UserInputService.InputBegan:Connect(function(input, processed)
                if processed then
                    return
                end

                if listening then
                    if input.KeyCode == Enum.KeyCode.Unknown then
                        return
                    end

                    key = input.KeyCode
                    listening = false
                    keyButton.Text = key.Name

                    if config.Changed then
                        task.spawn(config.Changed, key)
                    end

                    return
                end

                if input.KeyCode == key and config.Callback then
                    task.spawn(config.Callback, key)
                end
            end))

            return {
                Instance = card,
                SetValue = function(_, newKey)
                    key = newKey
                    keyButton.Text = newKey.Name
                end,
                GetValue = function()
                    return key
                end
            }
        end

        SelectTab(#tabs == 1 and tab or currentTab)
        return tab
    end

    function windowObject:CreateTab(name, description)
        return CreateTab(self, name, description)
    end

    windowObject.Tab = windowObject.CreateTab

    function windowObject:SetTitle(value)
        titleLabel.Text = tostring(value)
    end

    function windowObject:SetSubtitle(value)
        subtitle.Text = tostring(value)
    end

    function windowObject:SetSize(newSize)
        Tween(window, {Size = newSize}, 0.2)
        Tween(shadow, {Size = newSize + UDim2.fromOffset(12, 12)}, 0.2)
    end

    function windowObject:SetVisible(visible)
        gui.Enabled = visible
    end

    function windowObject:Toggle()
        gui.Enabled = not gui.Enabled
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
        config = type(config) == "table" and config or {Title = "Notification", Content = tostring(config)}

        local toast = Create("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 360, 0, 22),
            Size = UDim2.fromOffset(300, 83),
            BackgroundColor3 = theme.Surface,
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            ZIndex = 100,
            Parent = gui
        })
        Corner(toast, 13)
        Stroke(toast, theme.Accent, 0.3, 1)

        local toastTitle = Label(toast, config.Title or "Notification", 14, theme.Text, true)
        toastTitle.Position = UDim2.fromOffset(14, 9)
        toastTitle.Size = UDim2.new(1, -25, 0, 23)
        toastTitle.ZIndex = 101

        local toastContent = Label(toast, config.Content or config.Message or "", 12, theme.SubText, false)
        toastContent.Position = UDim2.fromOffset(14, 34)
        toastContent.Size = UDim2.new(1, -25, 0, 38)
        toastContent.TextWrapped = true
        toastContent.TextYAlignment = Enum.TextYAlignment.Top
        toastContent.ZIndex = 101

        Tween(toast, {Position = UDim2.new(1, -18, 0, 22)}, 0.25)

        task.delay(tonumber(config.Duration) or 3, function()
            if toast.Parent then
                Tween(toast, {
                    Position = UDim2.new(1, 360, 0, 22),
                    BackgroundTransparency = 1
                }, 0.2)

                task.delay(0.22, function()
                    if toast.Parent then
                        toast:Destroy()
                    end
                end)
            end
        end)

        return toast
    end

    function windowObject:Minimize()
        minimized = not minimized

        if minimized then
            sidebar.Visible = false
            content.Visible = false
            resizeGrip.Visible = false
            Tween(window, {Size = UDim2.new(window.Size.X.Scale, window.Size.X.Offset, 0, 72)}, 0.18)
            Tween(shadow, {Size = UDim2.new(window.Size.X.Scale, window.Size.X.Offset + 12, 0, 84)}, 0.18)
        else
            sidebar.Visible = true
            content.Visible = true
            resizeGrip.Visible = true
            Tween(window, {Size = size}, 0.18)
            Tween(shadow, {Size = size + UDim2.fromOffset(12, 12)}, 0.18)
        end
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

        gui:Destroy()
    end

    AddConnection(minimizeButton.MouseButton1Click:Connect(function()
        windowObject:Minimize()
    end))

    AddConnection(closeButton.MouseButton1Click:Connect(function()
        windowObject:Destroy()
    end))

    AddConnection(minimizeButton.MouseEnter:Connect(function()
        minimizeButton.TextColor3 = theme.AccentLight
    end))

    AddConnection(minimizeButton.MouseLeave:Connect(function()
        minimizeButton.TextColor3 = theme.SubText
    end))

    AddConnection(closeButton.MouseEnter:Connect(function()
        closeButton.TextColor3 = theme.Danger
    end))

    AddConnection(closeButton.MouseLeave:Connect(function()
        closeButton.TextColor3 = theme.Text
    end))

    local dragging = false
    local dragStart
    local startPosition

    AddConnection(topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = window.Position
        end
    end))

    AddConnection(UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart

            window.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )

            shadow.Position = window.Position
        end
    end))

    AddConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    local resizing = false
    local resizeStart
    local originalSize
    local minimumSize = options.MinSize or Vector2.new(380, 300)
    local maximumSize = options.MaxSize or Vector2.new(1400, 900)

    AddConnection(resizeGrip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = input.Position
            originalSize = window.AbsoluteSize
        end
    end))

    AddConnection(UserInputService.InputChanged:Connect(function(input)
        if not resizing then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - resizeStart

            local width = math.clamp(
                originalSize.X + delta.X,
                minimumSize.X,
                math.min(maximumSize.X, workspace.CurrentCamera.ViewportSize.X)
            )

            local height = math.clamp(
                originalSize.Y + delta.Y,
                minimumSize.Y,
                math.min(maximumSize.Y, workspace.CurrentCamera.ViewportSize.Y)
            )

            window.Size = UDim2.fromOffset(width, height)
            shadow.Size = UDim2.fromOffset(width + 12, height + 12)
            size = window.Size
        end
    end))

    AddConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            resizing = false
        end
    end))

    AddConnection(UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Enum.KeyCode.RightShift then
            gui.Enabled = not gui.Enabled
        end
    end))

    AddConnection(window:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if not minimized then
            shadow.Size = window.Size + UDim2.fromOffset(12, 12)
        end
    end))

    if options.Visible == false then
        gui.Enabled = false
    end

    windowObject:Notify({
        Title = title,
        Content = "Interface loaded successfully.",
        Duration = 2
    })

    return windowObject
end

function LiquidUI:Notify(config)
    if self.Window and self.Window.Notify then
        return self.Window:Notify(config)
    end
end

function LiquidUI:CreateWindowAndStore(options)
    local window = self:CreateWindow(options)
    self.Window = window
    return window
end

return LiquidUI
