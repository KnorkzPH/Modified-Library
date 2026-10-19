local LiquidUI = {}
LiquidUI.__index = LiquidUI

LiquidUI.Version = "2.0.0"
LiquidUI.Theme = {
    Background = Color3.fromRGB(15, 17, 24),
    Surface = Color3.fromRGB(24, 27, 37),
    SurfaceLight = Color3.fromRGB(34, 38, 51),
    Accent = Color3.fromRGB(130, 110, 255),
    Text = Color3.fromRGB(245, 246, 255),
    Muted = Color3.fromRGB(155, 160, 180),
    Border = Color3.fromRGB(255, 255, 255),
    Transparency = 0.10
}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local function create(class, props, children)
    local object = Instance.new(class)
    for property, value in pairs(props or {}) do
        object[property] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = object
    end
    return object
end

local function corner(parent, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 10),
        Parent = parent
    })
end

local function stroke(parent, color, transparency, thickness)
    return create("UIStroke", {
        Color = color or LiquidUI.Theme.Border,
        Transparency = transparency == nil and 0.85 or transparency,
        Thickness = thickness or 1,
        Parent = parent
    })
end

local function round(value, places)
    local factor = 10 ^ (places or 5)
    return math.floor(value * factor + 0.5) / factor
end

local function disconnectAll(list)
    for _, connection in ipairs(list) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(list)
end

function LiquidUI:SetTheme(theme)
    for key, value in pairs(theme or {}) do
        if self.Theme[key] ~= nil then
            self.Theme[key] = value
        end
    end

    for _, window in ipairs(self._windows or {}) do
        if not window.Destroyed and window.RefreshTheme then
            window:RefreshTheme()
        end
    end
end

LiquidUI._windows = {}

function LiquidUI:CreateWindow(options)
    options = options or {}

    local player = Players.LocalPlayer
    assert(player, "LiquidUI must run on the client")

    local playerGui = player:WaitForChild("PlayerGui")
    local guiName = options.Name or "LiquidUI"
    local previous = playerGui:FindFirstChild(guiName)

    if previous then
        previous:Destroy()
    end

    local connections = {}
    local tweens = {}
    local notifications = {}
    local themed = {}
    local keybinds = {}

    local window = {
        Tabs = {},
        ActiveTab = nil,
        Destroyed = false,
        Connections = connections,
        Tweens = tweens
    }

    table.insert(LiquidUI._windows, window)

    local function connect(signal, callback, bucket)
        local connection = signal:Connect(callback)
        table.insert(bucket or connections, connection)
        return connection
    end

    local function animate(object, properties, duration)
        if window.Destroyed or not object or not object.Parent then
            return
        end

        for i = #tweens, 1, -1 do
            local entry = tweens[i]
            if entry.Object == object then
                pcall(function()
                    entry.Tween:Cancel()
                end)
                table.remove(tweens, i)
            end
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

        local entry = {
            Object = object,
            Tween = tween
        }

        table.insert(tweens, entry)

        local completed
        completed = tween.Completed:Connect(function()
            if completed then
                completed:Disconnect()
            end

            for i = #tweens, 1, -1 do
                if tweens[i] == entry then
                    table.remove(tweens, i)
                    break
                end
            end
        end)

        table.insert(connections, completed)
        tween:Play()

        return tween
    end

    local function track(object, kind)
        table.insert(themed, {
            Object = object,
            Kind = kind
        })
        return object
    end

    local function themedCorner(object, radius)
        corner(object, radius)
        return object
    end

    local theme = LiquidUI.Theme

    local gui = create("ScreenGui", {
        Name = guiName,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = tonumber(options.DisplayOrder) or 20
    })

    window.Gui = gui

    local initialSize = options.Size or UDim2.fromOffset(680, 460)

    local main = create("Frame", {
        Name = "Window",
        Size = initialSize,
        Position = options.Position or UDim2.fromScale(0.5, 0.5),
        AnchorPoint = options.PositionAnchorPoint or Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.Background,
        BackgroundTransparency = theme.Transparency,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Active = true
    })

    main.Parent = gui
    window.Main = main

    corner(main, 14)
    local mainStroke = stroke(main, theme.Border, 0.80, 1)
    track(main, "Background")
    track(mainStroke, "Stroke")

    local topbar = create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 0.12,
        BorderSizePixel = 0,
        Active = true
    })

    topbar.Parent = main
    track(topbar, "Surface")

    local title = create("TextLabel", {
        Name = "Title",
        Position = UDim2.fromOffset(16, 0),
        Size = UDim2.new(1, -125, 1, 0),
        BackgroundTransparency = 1,
        Text = options.Author
            and ((options.Title or "LiquidUI") .. "  •  " .. tostring(options.Author))
            or (options.Title or "LiquidUI"),
        TextColor3 = theme.Text,
        TextSize = 15,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    })

    title.Parent = topbar
    track(title, "Text")

    local function createTopButton(name, text, xOffset)
        local button = create("TextButton", {
            Name = name,
            Size = UDim2.fromOffset(30, 30),
            Position = UDim2.new(1, xOffset, 0.5, -15),
            BackgroundColor3 = theme.SurfaceLight,
            Text = text,
            TextColor3 = theme.Text,
            TextSize = 20,
            Font = Enum.Font.GothamMedium,
            AutoButtonColor = false
        })

        button.Parent = topbar
        corner(button, 9)
        track(button, "SurfaceLight")
        track(button, "Text")

        connect(button.MouseEnter, function()
            animate(button, {
                BackgroundColor3 = theme.Accent
            }, 0.12)
        end)

        connect(button.MouseLeave, function()
            animate(button, {
                BackgroundColor3 = theme.SurfaceLight
            }, 0.12)
        end)

        return button
    end

    local close = createTopButton("Close", "×", -39)
    local minimize = createTopButton("Minimize", "−", -75)

    local sidebarWidth = math.clamp(
        tonumber(options.SidebarWidth) or 155,
        105,
        240
    )

    local sidebar = create("Frame", {
        Name = "Sidebar",
        Position = UDim2.fromOffset(0, 52),
        Size = UDim2.new(0, sidebarWidth, 1, -52),
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0
    })

    sidebar.Parent = main
    track(sidebar, "Surface")

    create("UIListLayout", {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder
    }).Parent = sidebar

    create("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 9),
        PaddingRight = UDim.new(0, 9)
    }).Parent = sidebar

    local content = create("Frame", {
        Name = "Content",
        Position = UDim2.new(0, sidebarWidth, 0, 52),
        Size = UDim2.new(1, -sidebarWidth, 1, -52),
        BackgroundTransparency = 1
    })

    content.Parent = main

    local overlay = create("Frame", {
        Name = "Overlay",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 100,
        ClipsDescendants = false
    })

    overlay.Parent = gui

    local minimized = false
    local expandedSize = initialSize
    local dragging = false
    local dragStart
    local startPosition
    local resizing = false
    local resizeStart
    local resizeSize
    local activeSlider
    local openDropdown

    local minSize = options.MinSize or Vector2.new(420, 300)
    local maxSize = options.MaxSize or Vector2.new(1200, 900)

    local function closeDropdown()
        if not openDropdown then
            return
        end

        local dropdown = openDropdown
        openDropdown = nil

        if dropdown.Close then
            dropdown:Close()
        end
    end

    function window:RefreshTheme()
        if self.Destroyed then
            return
        end

        for _, entry in ipairs(themed) do
            local object = entry.Object

            if object and object.Parent then
                pcall(function()
                    if entry.Kind == "Background" then
                        object.BackgroundColor3 = theme.Background
                    elseif entry.Kind == "Surface" then
                        object.BackgroundColor3 = theme.Surface
                    elseif entry.Kind == "SurfaceLight" then
                        object.BackgroundColor3 = theme.SurfaceLight
                    elseif entry.Kind == "Accent" then
                        object.BackgroundColor3 = theme.Accent
                    elseif entry.Kind == "Text" then
                        object.TextColor3 = theme.Text
                    elseif entry.Kind == "Muted" then
                        object.TextColor3 = theme.Muted
                    elseif entry.Kind == "Stroke" then
                        object.Color = theme.Border
                    end
                end)
            end
        end

        main.BackgroundTransparency = theme.Transparency
    end

    function window:CreateTab(tabOptions)
        if self.Destroyed then
            return
        end

        tabOptions = tabOptions or {}
        local tabName = tabOptions.Name or tabOptions.Title or "Tab"

        local tabButton = create("TextButton", {
            Name = tabName .. "Button",
            Size = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = theme.Accent,
            BackgroundTransparency = 1,
            Text = tabName,
            TextColor3 = theme.Muted,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            AutoButtonColor = false,
            TextTruncate = Enum.TextTruncate.AtEnd
        })

        tabButton.Parent = sidebar
        corner(tabButton, 9)
        track(tabButton, "Muted")

        local page = create("ScrollingFrame", {
            Name = tabName .. "Page",
            Size = UDim2.new(1, -24, 1, -24),
            Position = UDim2.fromOffset(12, 12),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = theme.Accent,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false
        })

        page.Parent = content

        create("UIListLayout", {
            Padding = UDim.new(0, 9),
            SortOrder = Enum.SortOrder.LayoutOrder
        }).Parent = page

        create("UIPadding", {
            PaddingBottom = UDim.new(0, 12)
        }).Parent = page

        local tab = {
            Button = tabButton,
            Page = page
        }

        local function styleRow(object, radius)
            corner(object, radius or 10)
            track(object, "Surface")
            return object
        end

        local function styleText(object, muted)
            track(object, muted and "Muted" or "Text")
            return object
        end

        function tab:AddSection(name)
            if window.Destroyed then
                return
            end

            local section = create("TextLabel", {
                Size = UDim2.new(1, -4, 0, 25),
                BackgroundTransparency = 1,
                Text = string.upper(tostring(name or "SECTION")),
                TextColor3 = theme.Muted,
                TextSize = 10,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            section.Parent = page
            styleText(section, true)
            return section
        end

        function tab:CreateButton(config)
            if window.Destroyed then
                return
            end

            config = config or {}

            local button = create("TextButton", {
                Name = config.Name or "Button",
                Size = UDim2.new(1, -4, 0, 42),
                BackgroundColor3 = theme.Surface,
                Text = config.Name or "Button",
                TextColor3 = theme.Text,
                TextSize = 12,
                Font = Enum.Font.GothamMedium,
                AutoButtonColor = false,
                TextTruncate = Enum.TextTruncate.AtEnd
            })

            button.Parent = page
            styleRow(button)
            styleText(button)
            stroke(button, theme.Border, 0.91)

            connect(button.MouseEnter, function()
                animate(button, {
                    BackgroundColor3 = theme.SurfaceLight
                }, 0.12)
            end)

            connect(button.MouseLeave, function()
                animate(button, {
                    BackgroundColor3 = theme.Surface
                }, 0.12)
            end)

            connect(button.Activated, function()
                if not window.Destroyed and config.Callback then
                    task.spawn(config.Callback)
                end
            end)

            return button
        end

        function tab:CreateToggle(config)
            if window.Destroyed then
                return
            end

            config = config or {}
            local value = config.Default == true

            local row = create("TextButton", {
                Size = UDim2.new(1, -4, 0, 44),
                BackgroundColor3 = theme.Surface,
                Text = "",
                AutoButtonColor = false
            })

            row.Parent = page
            styleRow(row)

            local textLabel = create("TextLabel", {
                Position = UDim2.fromOffset(13, 0),
                Size = UDim2.new(1, -70, 1, 0),
                BackgroundTransparency = 1,
                Text = config.Name or "Toggle",
                TextColor3 = theme.Text,
                TextSize = 12,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            textLabel.Parent = row
            styleText(textLabel)

            local trackFrame = create("Frame", {
                Size = UDim2.fromOffset(36, 20),
                Position = UDim2.new(1, -48, 0.5, -10),
                BackgroundColor3 = value and theme.Accent or theme.SurfaceLight
            })

            trackFrame.Parent = row
            corner(trackFrame, 20)
            track(trackFrame, value and "Accent" or "SurfaceLight")

            local knob = create("Frame", {
                Size = UDim2.fromOffset(14, 14),
                Position = value
                    and UDim2.new(1, -17, 0.5, -7)
                    or UDim2.new(0, 3, 0.5, -7),
                BackgroundColor3 = Color3.new(1, 1, 1)
            })

            knob.Parent = trackFrame
            corner(knob, 20)

            local toggle = {}

            function toggle:Set(nextValue)
                if window.Destroyed then
                    return
                end

                value = nextValue == true

                animate(trackFrame, {
                    BackgroundColor3 = value and theme.Accent or theme.SurfaceLight
                })

                animate(knob, {
                    Position = value
                        and UDim2.new(1, -17, 0.5, -7)
                        or UDim2.new(0, 3, 0.5, -7)
                })

                if config.Callback then
                    task.spawn(config.Callback, value)
                end
            end

            function toggle:Get()
                return value
            end

            connect(row.Activated, function()
                toggle:Set(not value)
            end)

            if config.Callback then
                task.spawn(config.Callback, value)
            end

            return toggle
        end

        function tab:CreateSlider(config)
            if window.Destroyed then
                return
            end

            config = config or {}

            local minimum = tonumber(config.Min) or 0
            local maximum = tonumber(config.Max) or 100

            if maximum < minimum then
                minimum, maximum = maximum, minimum
            end

            local step = math.max(tonumber(config.Step) or 1, 0.000001)
            local value = math.clamp(
                tonumber(config.Default) or minimum,
                minimum,
                maximum
            )

            local row = create("Frame", {
                Size = UDim2.new(1, -4, 0, 66),
                BackgroundColor3 = theme.Surface
            })

            row.Parent = page
            styleRow(row)

            local label = create("TextLabel", {
                Position = UDim2.fromOffset(13, 7),
                Size = UDim2.new(1, -26, 0, 20),
                BackgroundTransparency = 1,
                TextColor3 = theme.Text,
                TextSize = 12,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            label.Parent = row
            styleText(label)

            local bar = create("TextButton", {
                Position = UDim2.fromOffset(13, 40),
                Size = UDim2.new(1, -26, 0, 6),
                BackgroundColor3 = theme.SurfaceLight,
                Text = "",
                AutoButtonColor = false
            })

            bar.Parent = row
            corner(bar, 6)
            track(bar, "SurfaceLight")

            local fill = create("Frame", {
                Size = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = theme.Accent
            })

            fill.Parent = bar
            corner(fill, 6)
            track(fill, "Accent")

            local function render()
                local ratio = maximum == minimum and 0
                    or (value - minimum) / (maximum - minimum)

                fill.Size = UDim2.new(ratio, 0, 1, 0)
                label.Text = (config.Name or "Slider") .. ": " .. tostring(value)
            end

            local function setValue(nextValue, callCallback)
                value = math.clamp(
                    tonumber(nextValue) or minimum,
                    minimum,
                    maximum
                )

                value = math.clamp(
                    minimum + math.floor(((value - minimum) / step) + 0.5) * step,
                    minimum,
                    maximum
                )

                value = round(value)
                render()

                if callCallback and config.Callback then
                    task.spawn(config.Callback, value)
                end
            end

            local function updateFromX(x)
                if not bar.Parent or bar.AbsoluteSize.X <= 0 then
                    return
                end

                local ratio = math.clamp(
                    (x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X,
                    0,
                    1
                )

                setValue(minimum + (maximum - minimum) * ratio, true)
            end

            local slider = {}

            function slider:Set(nextValue)
                if not window.Destroyed then
                    setValue(nextValue, true)
                end
            end

            function slider:Get()
                return value
            end

            render()

            connect(bar.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    activeSlider = {
                        Update = updateFromX,
                        Input = input
                    }

                    updateFromX(input.Position.X)
                end
            end)

            return slider
        end

        function tab:CreateInput(config)
            if window.Destroyed then
                return
            end

            config = config or {}

            local input = create("TextBox", {
                Size = UDim2.new(1, -4, 0, 42),
                BackgroundColor3 = theme.Surface,
                Text = tostring(config.Default or ""),
                PlaceholderText = config.Placeholder or config.Name or "Enter text...",
                PlaceholderColor3 = theme.Muted,
                TextColor3 = theme.Text,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                ClearTextOnFocus = false
            })

            input.Parent = page
            styleRow(input)
            styleText(input)

            create("UIPadding", {
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12)
            }).Parent = input

            connect(input.FocusLost, function(enterPressed)
                if not window.Destroyed and config.Callback then
                    task.spawn(config.Callback, input.Text, enterPressed)
                end
            end)

            return input
        end

        function tab:CreateDropdown(config)
            if window.Destroyed then
                return
            end

            config = config or {}

            local values = config.Options or {}
            local selected = config.Default

            if selected == nil then
                selected = values[1] or "Select option"
            end

            local button = create("TextButton", {
                Size = UDim2.new(1, -4, 0, 42),
                BackgroundColor3 = theme.Surface,
                Text = "",
                TextColor3 = theme.Text,
                TextSize = 12,
                Font = Enum.Font.GothamMedium,
                AutoButtonColor = false,
                ClipsDescendants = false
            })

            button.Parent = page
            styleRow(button)
            styleText(button)

            local dropdown = {
                IsOpen = false,
                Popup = nil,
                PopupConnections = {}
            }

            local function popupConnect(signal, callback)
                local connection = signal:Connect(callback)
                table.insert(dropdown.PopupConnections, connection)
                return connection
            end

            local function clearPopupConnections()
                disconnectAll(dropdown.PopupConnections)
            end

            local function updateText()
                button.Text = (config.Name or "Dropdown")
                    .. ": " .. tostring(selected) .. "  ▾"
            end

            local function positionPopup()
                if not dropdown.Popup or not button.Parent then
                    return
                end

                local pos = button.AbsolutePosition
                local size = button.AbsoluteSize
                local popupHeight = dropdown.Popup.AbsoluteSize.Y
                local screenHeight = gui.AbsoluteSize.Y

                local y = pos.Y + size.Y + 5

                if y + popupHeight > screenHeight
                    and pos.Y - popupHeight - 5 > 0 then
                    y = pos.Y - popupHeight - 5
                end

                local x = math.clamp(
                    pos.X,
                    4,
                    math.max(4, gui.AbsoluteSize.X - size.X - 4)
                )

                dropdown.Popup.Position = UDim2.fromOffset(x, y)
                dropdown.Popup.Size = UDim2.fromOffset(size.X, popupHeight)
            end

            function dropdown:Close()
                clearPopupConnections()

                if self.Popup then
                    self.Popup:Destroy()
                end

                self.Popup = nil
                self.IsOpen = false

                if openDropdown == self then
                    openDropdown = nil
                end
            end

            function dropdown:Set(nextValue)
                selected = nextValue
                updateText()

                if config.Callback then
                    task.spawn(config.Callback, selected)
                end
            end

            function dropdown:Get()
                return selected
            end

            function dropdown:SetOptions(newOptions)
                values = newOptions or {}

                local found = false

                for _, option in ipairs(values) do
                    if option == selected then
                        found = true
                        break
                    end
                end

                if not found then
                    selected = values[1] or "Select option"
                end

                updateText()

                if self.IsOpen then
                    self:Open()
                end
            end

            function dropdown:Open()
                if window.Destroyed then
                    return
                end

                closeDropdown()
                self:Close()

                self.IsOpen = true
                openDropdown = self

                local popup = create("ScrollingFrame", {
                    Name = "DropdownOptions",
                    BackgroundColor3 = theme.SurfaceLight,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 3,
                    CanvasSize = UDim2.new(),
                    AutomaticCanvasSize = Enum.AutomaticSize.None,
                    ZIndex = 110
                })

                popup.Parent = overlay
                self.Popup = popup

                corner(popup, 8)
                stroke(popup, theme.Border, 0.8)

                create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder
                }).Parent = popup

                for _, option in ipairs(values) do
                    local item = create("TextButton", {
                        Size = UDim2.new(1, -4, 0, 34),
                        BackgroundTransparency = 1,
                        Text = tostring(option),
                        TextColor3 = theme.Text,
                        TextSize = 12,
                        Font = Enum.Font.Gotham,
                        AutoButtonColor = false,
                        ZIndex = 111
                    })

                    item.Parent = popup

                    popupConnect(item.Activated, function()
                        dropdown:Set(option)
                        dropdown:Close()
                    end)

                    popupConnect(item.MouseEnter, function()
                        if item.Parent then
                            item.BackgroundTransparency = 0.84
                        end
                    end)

                    popupConnect(item.MouseLeave, function()
                        if item.Parent then
                            item.BackgroundTransparency = 1
                        end
                    end)
                end

                local height = math.max(34, math.min(#values * 34, 170))

                popup.Size = UDim2.fromOffset(button.AbsoluteSize.X, height)
                popup.CanvasSize = UDim2.fromOffset(0, #values * 34)

                positionPopup()
            end

            updateText()

            connect(button.Activated, function()
                if dropdown.IsOpen then
                    dropdown:Close()
                else
                    dropdown:Open()
                end
            end)

            connect(page:GetPropertyChangedSignal("CanvasPosition"), function()
                if dropdown.IsOpen then
                    positionPopup()
                end
            end)

            connect(gui:GetPropertyChangedSignal("AbsoluteSize"), function()
                if dropdown.IsOpen then
                    positionPopup()
                end
            end)

            connect(main:GetPropertyChangedSignal("Position"), function()
                if dropdown.IsOpen then
                    positionPopup()
                end
            end)

            return dropdown
        end

        function tab:CreateKeybind(config)
            if window.Destroyed then
                return
            end

            config = config or {}

            local key = config.Default or Enum.KeyCode.RightShift
            local listening = false

            local button = self:CreateButton({
                Name = (config.Name or "Keybind") .. ": " .. key.Name
            })

            local keybind = {}

            function keybind:Get()
                return key
            end

            function keybind:Set(nextKey)
                if typeof(nextKey) == "EnumItem"
                    and nextKey.EnumType == Enum.KeyCode
                    and nextKey ~= Enum.KeyCode.Unknown then
                    key = nextKey
                    button.Text = (config.Name or "Keybind") .. ": " .. key.Name
                end
            end

            function keybind:Disconnect()
                listening = false
                keybinds[keybind] = nil
            end

            keybinds[keybind] = {
                GetKey = function()
                    return key
                end,
                IsListening = function()
                    return listening
                end,
                SetListening = function(value)
                    listening = value
                end,
                Button = button,
                Config = config,
                Name = config.Name or "Keybind",
                Object = keybind
            }

            connect(button.Activated, function()
                listening = true
                button.Text = (config.Name or "Keybind") .. ": press key..."
            end)

            return keybind
        end

        function tab:CreateParagraph(config)
            if window.Destroyed then
                return
            end

            config = config or {}

            local holder = create("Frame", {
                Name = config.Name or "Paragraph",
                Size = UDim2.new(1, -4, 0, 64),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = theme.Surface,
                BorderSizePixel = 0
            })

            holder.Parent = page
            corner(holder, 10)
            stroke(holder, theme.Border, 0.91)
            track(holder, "Surface")

            local heading = create("TextLabel", {
                Position = UDim2.fromOffset(12, 8),
                Size = UDim2.new(1, -24, 0, 18),
                BackgroundTransparency = 1,
                Text = config.Title or config.Name or "Information",
                TextColor3 = theme.Text,
                TextSize = 12,
                Font = Enum.Font.GothamSemibold,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd
            })

            heading.Parent = holder
            styleText(heading)

            local description = create("TextLabel", {
                Position = UDim2.fromOffset(12, 30),
                Size = UDim2.new(1, -24, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Text = config.Desc or config.Content or "",
                TextColor3 = theme.Muted,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top
            })

            description.Parent = holder
            styleText(description, true)

            create("UIPadding", {
                PaddingBottom = UDim.new(0, 10)
            }).Parent = holder

            local paragraph = {}

            function paragraph:SetTitle(value)
                heading.Text = tostring(value or "")
            end

            function paragraph:SetDesc(value)
                description.Text = tostring(value or "")
            end

            function paragraph:SetText(value)
                description.Text = tostring(value or "")
            end

            return paragraph
        end

        function tab:CreateLabel(value)
            if window.Destroyed then
                return
            end

            local label = create("TextLabel", {
                Size = UDim2.new(1, -4, 0, 28),
                BackgroundTransparency = 1,
                Text = tostring(value or "Label"),
                TextColor3 = theme.Text,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true
            })

            label.Parent = page
            styleText(label)

            return label
        end

        function tab:CreateDivider()
            if window.Destroyed then
                return
            end

            return create("Frame", {
                Size = UDim2.new(1, -4, 0, 1),
                BackgroundColor3 = theme.Border,
                BackgroundTransparency = 0.86,
                BorderSizePixel = 0,
                Parent = page
            })
        end

        function tab:Section(config)
            return self:AddSection(
                type(config) == "table" and (config.Title or config.Name) or config
            )
        end

        function tab:Button(config)
            config = config or {}
            config.Name = config.Name or config.Title or "Button"
            return self:CreateButton(config)
        end

        function tab:Toggle(config)
            config = config or {}
            config.Name = config.Name or config.Title or "Toggle"

            if config.Default == nil then
                config.Default = config.Value
            end

            return self:CreateToggle(config)
        end

        function tab:Slider(config)
            config = config or {}
            config.Name = config.Name or config.Title or "Slider"

            if config.Default == nil then
                config.Default = config.Value
            end

            return self:CreateSlider(config)
        end

        function tab:Input(config)
            config = config or {}
            config.Name = config.Name or config.Title or "Input"

            if config.Default == nil then
                config.Default = config.Value
            end

            config.Placeholder = config.Placeholder or config.PlaceholderText
            return self:CreateInput(config)
        end

        function tab:Dropdown(config)
            config = config or {}
            config.Name = config.Name or config.Title or "Dropdown"
            config.Options = config.Options or config.Values

            if config.Default == nil then
                config.Default = config.Value
            end

            return self:CreateDropdown(config)
        end

        function tab:Keybind(config)
            config = config or {}
            config.Name = config.Name or config.Title or "Keybind"

            if config.Default == nil then
                config.Default = config.Value
            end

            return self:CreateKeybind(config)
        end

        function tab:Paragraph(config)
            return self:CreateParagraph(config)
        end

        function tab:Label(config)
            return self:CreateLabel(
                type(config) == "table"
                    and (config.Title or config.Text or config.Name)
                    or config
            )
        end

        function tab:Divider()
            return self:CreateDivider()
        end

        connect(tabButton.Activated, function()
            window:SelectTab(tabName)
        end)

        table.insert(window.Tabs, {
            Name = tabName,
            Button = tabButton,
            Page = page
        })

        if #window.Tabs == 1 then
            window:SelectTab(tabName)
        end

        return tab
    end

    function window:Tab(config)
        config = config or {}
        config.Name = config.Name or config.Title or "Tab"
        return self:CreateTab(config)
    end

    function window:SetTitle(value)
        if not self.Destroyed then
            title.Text = tostring(value or "")
        end
    end

    function window:SetSize(value)
        if self.Destroyed or typeof(value) ~= "UDim2" then
            return
        end

        expandedSize = value

        if not minimized then
            main.Size = value
        end
    end

    function window:GetSize()
        return expandedSize
    end

    function window:SetPosition(value)
        if not self.Destroyed and typeof(value) == "UDim2" then
            main.Position = value
        end
    end

    function window:Toggle()
        if not self.Destroyed then
            main.Visible = not main.Visible
        end
    end

    function window:SetVisible(visible)
        if not self.Destroyed then
            main.Visible = visible == true
        end
    end

    function window:Minimize(value)
        if self.Destroyed then
            return
        end

        local nextState = value == nil and not minimized or value == true

        if nextState == minimized then
            return
        end

        if nextState then
            expandedSize = main.Size
            minimized = true
            sidebar.Visible = false
            content.Visible = false

            animate(main, {
                Size = UDim2.new(
                    expandedSize.X.Scale,
                    expandedSize.X.Offset,
                    0,
                    52
                )
            }, 0.18)

            minimize.Text = "+"
        else
            minimized = false
            sidebar.Visible = true
            content.Visible = true

            animate(main, {
                Size = expandedSize
            }, 0.18)

            minimize.Text = "−"
        end
    end

    function window:SelectTab(name)
        if self.Destroyed then
            return
        end

        closeDropdown()

        local found = false

        for _, item in ipairs(self.Tabs) do
            local active = item.Name == name
            item.Page.Visible = active

            if active then
                found = true
            end

            animate(item.Button, {
                BackgroundTransparency = active and 0 or 1,
                TextColor3 = active and theme.Text or theme.Muted
            })
        end

        if found then
            self.ActiveTab = name
        end
    end

    function window:Notify(config)
        if self.Destroyed then
            return
        end

        config = config or {}

        local toast = create("TextLabel", {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(
                1,
                -16,
                1,
                -16 - (#notifications * 64)
            ),
            Size = UDim2.fromOffset(280, 56),
            BackgroundColor3 = theme.Surface,
            BackgroundTransparency = 0.05,
            Text = "  " .. tostring(config.Title or "Notification")
                .. "\n  " .. tostring(config.Content or ""),
            TextColor3 = theme.Text,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextWrapped = true,
            ZIndex = 120
        })

        toast.Parent = overlay
        corner(toast, 12)
        stroke(toast, theme.Border, 0.8)
        table.insert(notifications, toast)

        task.delay(math.max(tonumber(config.Duration) or 3, 0), function()
            if window.Destroyed or not toast.Parent then
                return
            end

            local tween = animate(toast, {
                BackgroundTransparency = 1,
                TextTransparency = 1
            }, 0.18)

            if tween then
                tween.Completed:Wait()
            end

            if toast.Parent then
                toast:Destroy()
            end

            for i = #notifications, 1, -1 do
                if notifications[i] == toast then
                    table.remove(notifications, i)
                    break
                end
            end

            for i, item in ipairs(notifications) do
                if item.Parent then
                    animate(item, {
                        Position = UDim2.new(
                            1,
                            -16,
                            1,
                            -16 - ((i - 1) * 64)
                        )
                    }, 0.12)
                end
            end
        end)

        return toast
    end

    local resizeGrip = create("TextButton", {
        Name = "ResizeGrip",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 0, 1, 0),
        Size = UDim2.fromOffset(22, 22),
        BackgroundTransparency = 1,
        Text = "◢",
        TextColor3 = theme.Muted,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        AutoButtonColor = false,
        ZIndex = 10
    })

    resizeGrip.Parent = main
    track(resizeGrip, "Muted")

    connect(topbar.InputBegan, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local p = input.Position

        local function hit(object)
            local pos = object.AbsolutePosition
            local size = object.AbsoluteSize

            return p.X >= pos.X
                and p.X <= pos.X + size.X
                and p.Y >= pos.Y
                and p.Y <= pos.Y + size.Y
        end

        if not hit(close) and not hit(minimize) then
            dragging = true
            dragStart = p
            startPosition = main.Position
        end
    end)

    connect(resizeGrip.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = input.Position
            resizeSize = main.AbsoluteSize
        end
    end)

    connect(UserInputService.InputChanged, function(input)
        if window.Destroyed then
            return
        end

        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - dragStart

            main.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end

        if resizing and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - resizeStart

            local width = math.clamp(
                resizeSize.X + delta.X,
                minSize.X,
                maxSize.X
            )

            local height = math.clamp(
                resizeSize.Y + delta.Y,
                minSize.Y,
                maxSize.Y
            )

            expandedSize = UDim2.fromOffset(width, height)

            if not minimized then
                main.Size = expandedSize
            end
        end

        if activeSlider and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            activeSlider.Update(input.Position.X)
        end
    end)

    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            resizing = false
            activeSlider = nil
        end
    end)

    connect(UserInputService.InputBegan, function(input, processed)
        if window.Destroyed or input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end

        for _, entry in pairs(keybinds) do
            if entry.IsListening() then
                entry.SetListening(false)

                if input.KeyCode ~= Enum.KeyCode.Unknown
                    and input.KeyCode ~= Enum.KeyCode.Escape then
                    entry.Object:Set(input.KeyCode)
                else
                    entry.Button.Text = entry.Name .. ": " .. entry.GetKey().Name
                end

                break
            elseif not processed
                and input.KeyCode == entry.GetKey()
                and entry.Config.Callback then
                task.spawn(entry.Config.Callback)
            end
        end
    end)

    connect(close.Activated, function()
        window:Destroy()
    end)

    connect(minimize.Activated, function()
        window:Minimize()
    end)

    connect(gui:GetPropertyChangedSignal("AbsoluteSize"), function()
        if window.Destroyed then
            return
        end

        local viewport = gui.AbsoluteSize
        local size = main.AbsoluteSize
        local pos = main.AbsolutePosition

        if viewport.X > 0 and viewport.Y > 0 then
            if size.X > viewport.X then
                main.Size = UDim2.fromOffset(
                    math.max(300, viewport.X - 16),
                    math.min(size.Y, viewport.Y - 16)
                )
            end

            if pos.X + size.X < 24
                or pos.X > viewport.X - 24
                or pos.Y + 24 > viewport.Y
                or pos.Y < 0 then
                main.Position = UDim2.fromScale(0.5, 0.5)
            end
        end
    end)

    function window:Destroy()
        if self.Destroyed then
            return
        end

        self.Destroyed = true
        dragging = false
        resizing = false
        activeSlider = nil

        closeDropdown()

        for _, entry in ipairs(tweens) do
            pcall(function()
                entry.Tween:Cancel()
            end)
        end

        table.clear(tweens)
        disconnectAll(connections)
        table.clear(keybinds)
        table.clear(notifications)

        if gui.Parent then
            gui:Destroy()
        end

        for i = #LiquidUI._windows, 1, -1 do
            if LiquidUI._windows[i] == self then
                table.remove(LiquidUI._windows, i)
                break
            end
        end
    end

    gui.Parent = playerGui

    return window
end

return LiquidUI
