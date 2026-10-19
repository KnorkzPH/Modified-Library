local LiquidUI = {}
LiquidUI.__index = LiquidUI
LiquidUI.Version = "1.3.0"
LiquidUI.Theme = {
    Background = Color3.fromRGB(15, 17, 24),
    Surface = Color3.fromRGB(24, 27, 37),
    SurfaceLight = Color3.fromRGB(34, 38, 51),
    Accent = Color3.fromRGB(130, 110, 255),
    Text = Color3.fromRGB(245, 246, 255),
    Muted = Color3.fromRGB(155, 160, 180),
    Border = Color3.fromRGB(255, 255, 255),
    Transparency = 0.12
}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")

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
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 10), Parent = parent })
end

local function stroke(parent, color, transparency, thickness)
    return create("UIStroke", { Color = color or LiquidUI.Theme.Border, Transparency = transparency or 0.85, Thickness = thickness or 1, Parent = parent })
end

local function getIconUrl(iconString)
    if not iconString or type(iconString) ~= "string" then return nil end
    if iconString:match("^rbxasset") or iconString:match("^http") then
        return iconString
    end
    local prefix, name = iconString:match("^([^:]+):(.+)$")
    if prefix and name then
        prefix = prefix:lower()
        if prefix == "lucide" then
            return string.format("rbxassetid://6031094678", name) -- Fallback asset or dynamic resolver map
        elseif prefix == "solar" then
            return string.format("rbxassetid://6023426915", name)
        end
    end
    return nil
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
    local player = Players.LocalPlayer
    assert(player, "LiquidUI must run on the client")
    local playerGui = player:WaitForChild("PlayerGui")
    local guiName = options.Name or "LiquidUI"
    local previous = playerGui:FindFirstChild(guiName)
    if previous then previous:Destroy() end

    local connections, tweens, notifications = {}, {}, {}
    local window = { Tabs = {}, ActiveTab = nil, Destroyed = false, Connections = connections, Tweens = tweens }

    local function connect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(connections, connection)
        return connection
    end

    local function animate(object, properties, duration)
        if window.Destroyed or not object or not object.Parent then return nil end
        for i = #tweens, 1, -1 do
            local entry = tweens[i]
            if entry.Object == object then
                pcall(function() entry.Tween:Cancel() end)
                table.remove(tweens, i)
            end
        end
        local tween = TweenService:Create(
            object,
            TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            properties
        )
        local entry = {Object = object, Tween = tween}
        table.insert(tweens, entry)
        local completedConnection
        completedConnection = tween.Completed:Connect(function()
            if completedConnection then
                completedConnection:Disconnect()
                for i = #connections, 1, -1 do
                    if connections[i] == completedConnection then
                        table.remove(connections, i)
                        break
                    end
                end
            end
            for i = #tweens, 1, -1 do
                if tweens[i] == entry then
                    table.remove(tweens, i)
                    break
                end
            end
        end)
        table.insert(connections, completedConnection)
        tween:Play()
        return tween
    end

    local gui = create("ScreenGui", {
        Name = guiName,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })
    window.Gui = gui

    local main = create("Frame", {
        Name = "Window",
        Size = options.Size or UDim2.fromOffset(720, 520),
        Position = options.Position or UDim2.new(0.5, -360, 0.5, -260),
        BackgroundColor3 = self.Theme.Background,
        BackgroundTransparency = options.Transparent and self.Theme.Transparency or 0,
        BorderSizePixel = 0,
        ClipsDescendants = true
    })
    main.Parent = gui
    corner(main, 14)
    stroke(main, self.Theme.Border, 0.82, 1)

    -- Optional Background Image
    if options.Background then
        local bgImage = create("ImageLabel", {
            Name = "BackgroundImage",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Image = options.Background,
            ImageTransparency = options.BackgroundImageTransparency or 0.65,
            ScaleType = Enum.ScaleType.Crop,
            ZIndex = 0
        })
        bgImage.Parent = main
    end

    local topbar = create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = self.Theme.Surface,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Active = true,
        ZIndex = 2
    })
    topbar.Parent = main

    if options.Icon then
        local iconImg = create("ImageLabel", {
            Name = "Icon",
            Size = UDim2.fromOffset(24, 24),
            Position = UDim2.new(0, 16, 0.5, -12),
            BackgroundTransparency = 1,
            Image = getIconUrl(options.Icon) or options.Icon,
            ImageColor3 = self.Theme.Text,
            ZIndex = 3
        })
        iconImg.Parent = topbar
    end

    local titleText = options.Author and ((options.Title or "LiquidUI") .. " • " .. tostring(options.Author)) or (options.Title or "LiquidUI")
    local title = create("TextLabel", {
        Name = "Title",
        Position = UDim2.fromOffset(options.Icon and 48 or 18, 0),
        Size = UDim2.new(1, options.Icon and -148 or -120, 1, 0),
        BackgroundTransparency = 1,
        Text = titleText,
        TextColor3 = self.Theme.Text,
        TextSize = 17,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3
    })
    title.Parent = topbar

    local close = create("TextButton", {
        Name = "Close",
        Size = UDim2.fromOffset(32, 32),
        Position = UDim2.new(1, -42, 0.5, -16),
        BackgroundColor3 = self.Theme.SurfaceLight,
        Text = "×",
        TextColor3 = self.Theme.Text,
        TextSize = 22,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false,
        ZIndex = 3
    })
    close.Parent = topbar
    corner(close, 9)

    local minimize = create("TextButton", {
        Name = "Minimize",
        Size = UDim2.fromOffset(32, 32),
        Position = UDim2.new(1, -80, 0.5, -16),
        BackgroundColor3 = self.Theme.SurfaceLight,
        Text = "−",
        TextColor3 = self.Theme.Text,
        TextSize = 22,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false,
        ZIndex = 3
    })
    minimize.Parent = topbar
    corner(minimize, 9)

    local sidebarWidth = math.max(tonumber(options.SideBarWidth or options.SidebarWidth) or 220, 110)
    local sidebar = create("ScrollingFrame", {
        Name = "Sidebar",
        Position = UDim2.fromOffset(0, 54),
        Size = UDim2.new(0, sidebarWidth, 1, -54),
        BackgroundColor3 = self.Theme.Surface,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 2
    })
    sidebar.Parent = main
    create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }).Parent = sidebar
    create("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }).Parent = sidebar

    local content = create("Frame", {
        Name = "Content",
        Position = UDim2.new(0, sidebarWidth, 0, 54),
        Size = UDim2.new(1, -sidebarWidth, 1, -54),
        BackgroundTransparency = 1,
        ZIndex = 2
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

    -- Resizable handler
    if options.Resizable then
        local resizeButton = create("TextButton", {
            Name = "Resizer",
            Size = UDim2.fromOffset(18, 18),
            Position = UDim2.new(1, -18, 1, -18),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 10
        })
        resizeButton.Parent = main
        local resizing, resizeStart, startSize = false, nil, nil
        connect(resizeButton.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                resizing = true
                resizeStart = input.Position
                startSize = main.AbsoluteSize
            end
        end)
        connect(UserInputService.InputChanged, function(input)
            if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - resizeStart
                local minSize = options.MinSize or Vector2.new(500, 350)
                local maxSize = options.MaxSize or Vector2.new(1200, 800)
                local newX = math.clamp(startSize.X + delta.X, minSize.X, maxSize.X)
                local newY = math.clamp(startSize.Y + delta.Y, minSize.Y, maxSize.Y)
                main.Size = UDim2.fromOffset(newX, newY)
            end
        end)
        connect(UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                resizing = false
            end
        end)
    end

    -- EditOpenButton (Floating Toggle)
    if options.EditOpenButton or true then
        local ebOpts = type(options.EditOpenButton) == "table" and options.EditOpenButton or {
            Title = options.Title or "LiquidUI",
            Icon = options.Icon or "lucide:layout-dashboard",
            CornerRadius = UDim.new(0, 20),
            StrokeThickness = 1.4,
            Color = ColorSequence.new(Color3.fromHex("0B1F4D"), Color3.fromHex("02030A")),
            OnlyMobile = false,
            Enabled = true,
            Draggable = true
        }
        if ebOpts.Enabled ~= false then
            local openBtn = create("TextButton", {
                Name = "OpenButton",
                Size = UDim2.fromOffset(140, 42),
                Position = UDim2.new(0, 20, 0.5, -21),
                BackgroundColor3 = Color3.fromRGB(20, 24, 33),
                Text = "  " .. (ebOpts.Title or "Menu"),
                TextColor3 = self.Theme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                AutoButtonColor = false,
                ZIndex = 150,
                Visible = not ebOpts.OnlyMobile or UserInputService.TouchEnabled
            })
            openBtn.Parent = gui
            corner(openBtn, ebOpts.CornerRadius and ebOpts.CornerRadius.Offset or 20)
            stroke(openBtn, self.Theme.Border, 0.7, ebOpts.StrokeThickness or 1.4)

            if ebOpts.Icon then
                local icon = create("ImageLabel", {
                    Size = UDim2.fromOffset(20, 20),
                    Position = UDim2.new(0, 12, 0.5, -10),
                    BackgroundTransparency = 1,
                    Image = getIconUrl(ebOpts.Icon) or ebOpts.Icon,
                    ImageColor3 = self.Theme.Text,
                    ZIndex = 151
                })
                icon.Parent = openBtn
                openBtn.Text = "      " .. (ebOpts.Title or "Menu")
            end

            local btnDragging, btnDragStart, btnStartPos = false, nil, nil
            connect(openBtn.InputBegan, function(input)
                if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                    btnDragging = true
                    btnDragStart = input.Position
                    btnStartPos = openBtn.Position
                end
            end)
            connect(UserInputService.InputChanged, function(input)
                if ebOpts.Draggable and btnDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local delta = input.Position - btnDragStart
                    openBtn.Position = UDim2.new(
                        btnStartPos.X.Scale,
                        btnStartPos.X.Offset + delta.X,
                        btnStartPos.Y.Scale,
                        btnStartPos.Y.Offset + delta.Y
                    )
                end
            end)
            connect(UserInputService.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    btnDragging = false
                end
            end)
            connect(openBtn.Activated, function()
                main.Visible = not main.Visible
            end)
        end
    end

    local dragging, dragStart, startPosition, activeSlider = false, nil, nil, nil
    local minimized = false
    local expandedSize = main.Size
    local keybinds = {}
    local openDropdown

    local function closeDropdown()
        if openDropdown then
            local dropdown = openDropdown
            openDropdown = nil
            if dropdown.Close then
                dropdown:Close()
            elseif dropdown.Popup then
                dropdown.Popup:Destroy()
                dropdown.IsOpen = false
            end
        end
    end

    function window:CreateTab(tabOptions)
        if self.Destroyed then return nil end
        tabOptions = tabOptions or {}
        local tabName = tabOptions.Name or tabOptions.Title or "Tab"
        local iconAsset = getIconUrl(tabOptions.Icon)

        local tabButton = create("TextButton", {
            Name = tabName .. "Button",
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = LiquidUI.Theme.Accent,
            BackgroundTransparency = 1,
            Text = "    " .. tabName,
            TextColor3 = LiquidUI.Theme.Muted,
            TextSize = 13,
            Font = Enum.Font.GothamMedium,
            AutoButtonColor = false,
            ZIndex = 3
        })
        tabButton.Parent = sidebar
        corner(tabButton, 9)

        if iconAsset then
            create("ImageLabel", {
                Size = UDim2.fromOffset(18, 18),
                Position = UDim2.new(0, 12, 0.5, -9),
                BackgroundTransparency = 1,
                Image = iconAsset,
                ImageColor3 = LiquidUI.Theme.Muted,
                ZIndex = 4
            }, {}).Parent = tabButton
            tabButton.Text = "        " .. tabName
        end

        local page = create("ScrollingFrame", {
            Name = tabName .. "Page",
            Size = UDim2.new(1, -24, 1, -24),
            Position = UDim2.fromOffset(12, 12),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = LiquidUI.Theme.Accent,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            ZIndex = 2
        })
        page.Parent = content
        create("UIListLayout", { Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder }).Parent = page
        create("UIPadding", { PaddingBottom = UDim.new(0, 12) }).Parent = page

        local tab = {Button = tabButton, Page = page}

        function tab:AddSection(name)
            if window.Destroyed then return nil end
            local section = create("TextLabel", {
                Size = UDim2.new(1, -4, 0, 28),
                BackgroundTransparency = 1,
                Text = string.upper(name or "SECTION"),
                TextColor3 = LiquidUI.Theme.Muted,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            section.Parent = page
            return section
        end

        function tab:CreateButton(config)
            if window.Destroyed then return nil end
            config = config or {}
            local button = create("TextButton", {
                Name = config.Name or "Button",
                Size = UDim2.new(1, -4, 0, 42),
                BackgroundColor3 = LiquidUI.Theme.Surface,
                Text = config.Name or "Button",
                TextColor3 = LiquidUI.Theme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                AutoButtonColor = false
            })
            button.Parent = page
            corner(button, 10)
            stroke(button, LiquidUI.Theme.Border, 0.9)

            connect(button.MouseEnter, function() animate(button, {BackgroundColor3 = LiquidUI.Theme.SurfaceLight}) end)
            connect(button.MouseLeave, function() animate(button, {BackgroundColor3 = LiquidUI.Theme.Surface}) end)
            connect(button.Activated, function()
                if not window.Destroyed and config.Callback then
                    task.spawn(config.Callback)
                end
            end)
            return button
        end

        function tab:CreateToggle(config)
            if window.Destroyed then return nil end
            config = config or {}
            local value = config.Default == true
            local row = create("TextButton", {
                Size = UDim2.new(1, -4, 0, 44),
                BackgroundColor3 = LiquidUI.Theme.Surface,
                Text = "",
                AutoButtonColor = false
            })
            row.Parent = page
            corner(row, 10)

            create("TextLabel", {
                Position = UDim2.fromOffset(13, 0),
                Size = UDim2.new(1, -70, 1, 0),
                BackgroundTransparency = 1,
                Text = config.Name or "Toggle",
                TextColor3 = LiquidUI.Theme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left
            }).Parent = row

            local track = create("Frame", {
                Size = UDim2.fromOffset(36, 20),
                Position = UDim2.new(1, -48, 0.5, -10),
                BackgroundColor3 = value and LiquidUI.Theme.Accent or LiquidUI.Theme.SurfaceLight
            })
            track.Parent = row
            corner(track, 20)

            local knob = create("Frame", {
                Size = UDim2.fromOffset(14, 14),
                Position = value and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
                BackgroundColor3 = Color3.new(1, 1, 1)
            })
            knob.Parent = track
            corner(knob, 20)

            local toggle = {}
            function toggle:Set(nextValue)
                if window.Destroyed then return end
                value = nextValue == true
                animate(track, { BackgroundColor3 = value and LiquidUI.Theme.Accent or LiquidUI.Theme.SurfaceLight })
                animate(knob, { Position = value and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7) })
                if config.Callback then task.spawn(config.Callback, value) end
            end
            function toggle:Get() return value end

            connect(row.Activated, function() toggle:Set(not value) end)
            if config.Callback then task.spawn(config.Callback, value) end
            return toggle
        end

        function tab:CreateSlider(config)
            if window.Destroyed then return nil end
            config = config or {}
            local minimum = tonumber(config.Min) or 0
            local maximum = tonumber(config.Max) or 100
            if maximum < minimum then minimum, maximum = maximum, minimum end
            local value = math.clamp(tonumber(config.Default) or minimum, minimum, maximum)
            local step = math.max(tonumber(config.Step) or 1, 0.000001)

            local row = create("Frame", { Size = UDim2.new(1, -4, 0, 66), BackgroundColor3 = LiquidUI.Theme.Surface })
            row.Parent = page
            corner(row, 10)

            local label = create("TextLabel", {
                Position = UDim2.fromOffset(13, 7),
                Size = UDim2.new(1, -26, 0, 20),
                BackgroundTransparency = 1,
                TextColor3 = LiquidUI.Theme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            label.Parent = row

            local bar = create("TextButton", {
                Position = UDim2.fromOffset(13, 39),
                Size = UDim2.new(1, -26, 0, 6),
                BackgroundColor3 = LiquidUI.Theme.SurfaceLight,
                Text = "",
                AutoButtonColor = false
            })
            bar.Parent = row
            corner(bar, 6)

            local fill = create("Frame", {
                Size = UDim2.new(maximum == minimum and 0 or (value - minimum) / (maximum - minimum), 0, 1, 0),
                BackgroundColor3 = LiquidUI.Theme.Accent
            })
            fill.Parent = bar
            corner(fill, 6)

            local function render()
                local ratio = maximum == minimum and 0 or (value - minimum) / (maximum - minimum)
                fill.Size = UDim2.new(ratio, 0, 1, 0)
                label.Text = (config.Name or "Slider") .. ": " .. tostring(value)
            end

            local function updateFromX(x)
                if window.Destroyed or not bar.Parent then return end
                local width = bar.AbsoluteSize.X
                if width <= 0 then return end
                local ratio = math.clamp((x - bar.AbsolutePosition.X) / width, 0, 1)
                local raw = minimum + (maximum - minimum) * ratio
                value = math.clamp(minimum + math.floor(((raw - minimum) / step) + 0.5) * step, minimum, maximum)
                value = math.floor(value * 100000 + 0.5) / 100000
                render()
                if config.Callback then task.spawn(config.Callback, value) end
            end

            local slider = {}
            function slider:Set(nextValue)
                if window.Destroyed then return end
                value = math.clamp(tonumber(nextValue) or minimum, minimum, maximum)
                value = math.floor((minimum + math.floor(((value - minimum) / step) + 0.5) * step) * 100000 + 0.5) / 100000
                render()
                if config.Callback then task.spawn(config.Callback, value) end
            end
            function slider:Get() return value end

            render()
            connect(bar.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    activeSlider = {Bar = bar, Update = updateFromX, Input = input}
                    updateFromX(input.Position.X)
                end
            end)
            return slider
        end

        function tab:CreateInput(config)
            if window.Destroyed then return nil end
            config = config or {}
            local input = create("TextBox", {
                Size = UDim2.new(1, -4, 0, 42),
                BackgroundColor3 = LiquidUI.Theme.Surface,
                Text = config.Default or "",
                PlaceholderText = config.Placeholder or config.Name or "Enter text...",
                PlaceholderColor3 = LiquidUI.Theme.Muted,
                TextColor3 = LiquidUI.Theme.Text,
                TextSize = 13,
                Font = Enum.Font.Gotham,
                ClearTextOnFocus = false
            })
            input.Parent = page
            corner(input, 10)
            create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }).Parent = input

            connect(input.FocusLost, function(enterPressed)
                if not window.Destroyed and config.Callback then
                    task.spawn(config.Callback, input.Text, enterPressed)
                end
            end)
            return input
        end

        function tab:CreateDropdown(config)
            if window.Destroyed then return nil end
            config = config or {}
            local values = config.Options or {}
            local selected = config.Default or values[1] or "Select option"

            local button = create("TextButton", {
                Size = UDim2.new(1, -4, 0, 42),
                BackgroundColor3 = LiquidUI.Theme.Surface,
                Text = (config.Name or "Dropdown") .. ": " .. tostring(selected) .. " ▾",
                TextColor3 = LiquidUI.Theme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                AutoButtonColor = false,
                ClipsDescendants = false
            })
            button.Parent = page
            corner(button, 10)

            local dropdown = {IsOpen = false, Popup = nil, PopupConnections = {}}

            local function clearPopupConnections()
                for _, connection in ipairs(dropdown.PopupConnections) do
                    if connection.Connected then pcall(function() connection:Disconnect() end) end
                end
                table.clear(dropdown.PopupConnections)
            end

            local function updateText()
                button.Text = (config.Name or "Dropdown") .. ": " .. tostring(selected) .. " ▾"
            end

            local function positionPopup()
                if not dropdown.Popup or not button.Parent then return end
                local pos, size = button.AbsolutePosition, button.AbsoluteSize
                local popupHeight = dropdown.Popup.AbsoluteSize.Y
                local screenHeight = gui.AbsoluteSize.Y
                local y = pos.Y + size.Y + 5
                if y + popupHeight > screenHeight and pos.Y - popupHeight - 5 > 0 then
                    y = pos.Y - popupHeight - 5
                end
                dropdown.Popup.Position = UDim2.fromOffset(pos.X, y)
                dropdown.Popup.Size = UDim2.fromOffset(size.X, popupHeight)
            end

            function dropdown:SetOptions(newOptions)
                values = newOptions or {}
                if dropdown.IsOpen then dropdown:Open() end
            end
            function dropdown:Set(value)
                selected = value
                updateText()
                if config.Callback then task.spawn(config.Callback, selected) end
            end
            function dropdown:Get() return selected end

            function dropdown:Close()
                clearPopupConnections()
                if self.Popup then self.Popup:Destroy() end
                self.Popup = nil
                self.IsOpen = false
                if openDropdown == self then openDropdown = nil end
            end

            function dropdown:Open()
                if window.Destroyed then return end
                closeDropdown()
                self.IsOpen = true
                openDropdown = self

                local popup = create("ScrollingFrame", {
                    Name = "DropdownOptions",
                    BackgroundColor3 = LiquidUI.Theme.SurfaceLight,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 3,
                    CanvasSize = UDim2.new(0, 0, 0, #values * 34),
                    ZIndex = 110
                })
                popup.Parent = overlay
                self.Popup = popup
                corner(popup, 8)
                stroke(popup, LiquidUI.Theme.Border, 0.82, 1)
                create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }).Parent = popup

                for _, option in ipairs(values) do
                    local item = create("TextButton", {
                        Size = UDim2.new(1, -4, 0, 34),
                        BackgroundTransparency = 1,
                        Text = tostring(option),
                        TextColor3 = LiquidUI.Theme.Text,
                        TextSize = 12,
                        Font = Enum.Font.Gotham,
                        AutoButtonColor = false,
                        ZIndex = 111
                    })
                    item.Parent = popup
                    table.insert(dropdown.PopupConnections, item.Activated:Connect(function()
                        dropdown:Set(option)
                        dropdown:Close()
                    end))
                end

                local height = math.min(#values * 34, 170)
                popup.Size = UDim2.fromOffset(button.AbsoluteSize.X, height)
                positionPopup()
            end

            connect(button.Activated, function()
                if dropdown.IsOpen then dropdown:Close() else dropdown:Open() end
            end)
            return dropdown
        end

        function tab:CreateParagraph(config)
            if window.Destroyed then return nil end
            config = config or {}
            local holder = create("Frame", {
                Name = config.Name or "Paragraph",
                Size = UDim2.new(1, -4, 0, 64),
                BackgroundColor3 = LiquidUI.Theme.Surface,
                BorderSizePixel = 0
            })
            holder.Parent = page
            corner(holder, 10)
            stroke(holder, LiquidUI.Theme.Border, 0.92, 1)

            local heading = create("TextLabel", {
                Position = UDim2.fromOffset(12, 7),
                Size = UDim2.new(1, -24, 0, 18),
                BackgroundTransparency = 1,
                Text = config.Title or config.Name or "Information",
                TextColor3 = LiquidUI.Theme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamSemibold,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            heading.Parent = holder

            local description = create("TextLabel", {
                Position = UDim2.fromOffset(12, 27),
                Size = UDim2.new(1, -24, 1, -33),
                BackgroundTransparency = 1,
                Text = config.Desc or config.Content or "",
                TextColor3 = LiquidUI.Theme.Muted,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                AutomaticSize = Enum.AutomaticSize.Y
            })
            description.Parent = holder

            local paragraph = {}
            function paragraph:SetTitle(value) heading.Text = tostring(value or "") end
            function paragraph:SetDesc(value) description.Text = tostring(value or "") end
            return paragraph
        end

        function tab:CreateLabel(textValue)
            if window.Destroyed then return nil end
            local label = create("TextLabel", {
                Size = UDim2.new(1, -4, 0, 28),
                BackgroundTransparency = 1,
                Text = tostring(textValue or "Label"),
                TextColor3 = LiquidUI.Theme.Text,
                TextSize = 13,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            label.Parent = page
            return label
        end

        function tab:CreateDivider()
            if window.Destroyed then return nil end
            local divider = create("Frame", {
                Size = UDim2.new(1, -4, 0, 1),
                BackgroundColor3 = LiquidUI.Theme.Border,
                BackgroundTransparency = 0.85,
                BorderSizePixel = 0
            })
            divider.Parent = page
            return divider
        end

        -- WindUI Aliases
        function tab:Section(config) return self:AddSection(type(config) == "table" and (config.Title or config.Name) or config) end
        function tab:Button(config) return self:CreateButton(type(config) == "table" and config or {Name = config}) end
        function tab:Toggle(config) return self:CreateToggle(config) end
        function tab:Slider(config) return self:CreateSlider(config) end
        function tab:Input(config) return self:CreateInput(config) end
        function tab:Dropdown(config) return self:CreateDropdown(config) end
        function tab:Paragraph(config) return self:CreateParagraph(config) end
        function tab:Label(config) return self:CreateLabel(type(config) == "table" and (config.Title or config.Text or config.Name) or config) end
        function tab:Divider() return self:CreateDivider() end

        connect(tabButton.Activated, function() window:SelectTab(tabName) end)
        table.insert(window.Tabs, {Name = tabName, Button = tabButton, Page = page})
        if #window.Tabs == 1 then window:SelectTab(tabName) end
        return tab
    end

    function window:Tab(tabOptions) return self:CreateTab(tabOptions) end
    function window:SelectTab(name)
        if self.Destroyed then return end
        closeDropdown()
        for _, item in ipairs(self.Tabs) do
            local active = item.Name == name
            item.Page.Visible = active
            animate(item.Button, {
                BackgroundTransparency = active and 0 or 1,
                TextColor3 = active and LiquidUI.Theme.Text or LiquidUI.Theme.Muted
            })
        end
        self.ActiveTab = name
    end

    function window:Notify(config)
        if self.Destroyed then return nil end
        config = config or {}
        local toast = create("TextLabel", {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -18, 1, -18 - (#notifications * 66)),
            Size = UDim2.fromOffset(270, 58),
            BackgroundColor3 = LiquidUI.Theme.Surface,
            Text = " " .. (config.Title or "Notification") .. "\n " .. (config.Content or ""),
            TextColor3 = LiquidUI.Theme.Text,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 120
        })
        toast.Parent = overlay
        corner(toast, 12)
        stroke(toast, LiquidUI.Theme.Border, 0.8)
        table.insert(notifications, toast)

        task.delay(math.max(tonumber(config.Duration) or 3, 0), function()
            if window.Destroyed or not toast.Parent then return end
            local tween = animate(toast, {BackgroundTransparency = 1, TextTransparency = 1}, 0.2)
            if tween then tween.Completed:Wait() end
            if toast.Parent then toast:Destroy() end
            for i = #notifications, 1, -1 do
                if notifications[i] == toast then table.remove(notifications, i) break end
            end
        end)
        return toast
    end

    function window:Destroy()
        if self.Destroyed then return end
        self.Destroyed = true
        closeDropdown()
        for _, connection in ipairs(connections) do if connection.Connected then pcall(function() connection:Disconnect() end) end end
        if gui.Parent then gui:Destroy() end
    end

    connect(UserInputService.InputBegan, function(input, processed)
        if window.Destroyed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if input.Position.X >= topbar.AbsolutePosition.X and input.Position.X <= topbar.AbsolutePosition.X + topbar.AbsoluteSize.X and
               input.Position.Y >= topbar.AbsolutePosition.Y and input.Position.Y <= topbar.AbsolutePosition.Y + topbar.AbsoluteSize.Y then
                dragging = true
                dragStart = input.Position
                startPosition = main.Position
            end
        end
    end)

    connect(UserInputService.InputChanged, function(input)
        if window.Destroyed then return end
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
        if activeSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            activeSlider.Update(input.Position.X)
        end
    end)

    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            activeSlider = nil
        end
    end)

    connect(close.Activated, function() window:Destroy() end)
    connect(minimize.Activated, function() window:Minimize() end)

    gui.Parent = playerGui
    return window
end

return LiquidUI
