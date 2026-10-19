local LiquidUI = {}
LiquidUI.__index = LiquidUI

LiquidUI.Version = "1.2.0"
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
        Transparency = transparency or 0.85,
        Thickness = thickness or 1,
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
    local player = Players.LocalPlayer
    assert(player, "LiquidUI must run on the client")

    local playerGui = player:WaitForChild("PlayerGui")
    local guiName = options.Name or "LiquidUI"
    local previous = playerGui:FindFirstChild(guiName)
    if previous then
        previous:Destroy()
    end

    local connections, tweens, notifications = {}, {}, {}
    local window = {
        Tabs = {},
        ActiveTab = nil,
        Destroyed = false,
        Connections = connections,
        Tweens = tweens
    }

    local function connect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(connections, connection)
        return connection
    end

    local function animate(object, properties, duration)
        if window.Destroyed or not object or not object.Parent then
            return nil
        end
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
        Size = options.Size or UDim2.fromOffset(680, 460),
        Position = options.Position or UDim2.new(0.5, -340, 0.5, -230),
        BackgroundColor3 = self.Theme.Background,
        BackgroundTransparency = self.Theme.Transparency,
        BorderSizePixel = 0,
        ClipsDescendants = true
    })
    main.Parent = gui
    window.Main = main
    corner(main, 14)
    stroke(main, self.Theme.Border, 0.82, 1)

    local topbar = create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = self.Theme.Surface,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Active = true
    })
    topbar.Parent = main

    local title = create("TextLabel", {
        Name = "Title",
        Position = UDim2.fromOffset(18, 0),
        Size = UDim2.new(1, -120, 1, 0),
        BackgroundTransparency = 1,
        Text = options.Author and ((options.Title or "LiquidUI") .. "  •  " .. tostring(options.Author)) or (options.Title or "LiquidUI"),
        TextColor3 = self.Theme.Text,
        TextSize = 17,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left
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
        AutoButtonColor = false
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
        AutoButtonColor = false
    })
    minimize.Parent = topbar
    corner(minimize, 9)

    local sidebarWidth = math.max(tonumber(options.SidebarWidth) or 155, 110)
    local sidebar = create("Frame", {
        Name = "Sidebar",
        Position = UDim2.fromOffset(0, 54),
        Size = UDim2.new(0, sidebarWidth, 1, -54),
        BackgroundColor3 = self.Theme.Surface,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0
    })
    sidebar.Parent = main

    create("UIListLayout", {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder
    }).Parent = sidebar

    create("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10)
    }).Parent = sidebar

    local content = create("Frame", {
        Name = "Content",
        Position = UDim2.new(0, sidebarWidth, 0, 54),
        Size = UDim2.new(1, -sidebarWidth, 1, -54),
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

    local dragging, dragStart, startPosition, activeSlider
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
            else
                if dropdown.Popup then dropdown.Popup:Destroy() end
                dropdown.IsOpen = false
            end
        end
    end

    function window:CreateTab(tabOptions)
        if self.Destroyed then return nil end
        tabOptions = tabOptions or {}
        local tabName = tabOptions.Name or "Tab"

        local tabButton = create("TextButton", {
            Name = tabName .. "Button",
            Size = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = LiquidUI.Theme.Accent,
            BackgroundTransparency = 1,
            Text = tabName,
            TextColor3 = LiquidUI.Theme.Muted,
            TextSize = 13,
            Font = Enum.Font.GothamMedium,
            AutoButtonColor = false
        })
        tabButton.Parent = sidebar
        corner(tabButton, 9)

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

            connect(button.MouseEnter, function()
                animate(button, {BackgroundColor3 = LiquidUI.Theme.SurfaceLight})
            end)
            connect(button.MouseLeave, function()
                animate(button, {BackgroundColor3 = LiquidUI.Theme.Surface})
            end)
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
                animate(track, {
                    BackgroundColor3 = value and LiquidUI.Theme.Accent or LiquidUI.Theme.SurfaceLight
                })
                animate(knob, {
                    Position = value and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
                })
                if config.Callback then task.spawn(config.Callback, value) end
            end
            function toggle:Get() return value end

            connect(row.Activated, function()
                toggle:Set(not value)
            end)
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

            local row = create("Frame", {
                Size = UDim2.new(1, -4, 0, 66),
                BackgroundColor3 = LiquidUI.Theme.Surface
            })
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
            if window.Destroyed then return nil end
            config = config or {}
            local values = config.Options or {}
            local selected = config.Default or values[1] or "Select option"

            local button = create("TextButton", {
                Size = UDim2.new(1, -4, 0, 42),
                BackgroundColor3 = LiquidUI.Theme.Surface,
                Text = (config.Name or "Dropdown") .. ": " .. tostring(selected) .. "  ▾",
                TextColor3 = LiquidUI.Theme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                AutoButtonColor = false,
                ClipsDescendants = false
            })
            button.Parent = page
            corner(button, 10)

            local dropdown = {IsOpen = false, Popup = nil, PopupConnections = {}}
            local function popupConnect(signal, callback)
                local connection = signal:Connect(callback)
                table.insert(dropdown.PopupConnections, connection)
                return connection
            end
            local function clearPopupConnections()
                for _, connection in ipairs(dropdown.PopupConnections) do
                    if connection.Connected then
                        pcall(function() connection:Disconnect() end)
                    end
                end
                table.clear(dropdown.PopupConnections)
            end
            local function updateText()
                button.Text = (config.Name or "Dropdown") .. ": " .. tostring(selected) .. "  ▾"
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
                if dropdown.IsOpen then
                    dropdown:Open()
                end
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
                self:Close()
                self.IsOpen = true
                openDropdown = self

                local popup = create("ScrollingFrame", {
                    Name = "DropdownOptions",
                    BackgroundColor3 = LiquidUI.Theme.SurfaceLight,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 3,
                    CanvasSize = UDim2.new(0, 0, 0, #values * 34),
                    AutomaticCanvasSize = Enum.AutomaticSize.None,
                    ZIndex = 110
                })
                popup.Parent = overlay
                self.Popup = popup
                corner(popup, 8)
                stroke(popup, LiquidUI.Theme.Border, 0.82, 1)

                create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder
                }).Parent = popup

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
                    popupConnect(item.Activated, function()
                        dropdown:Set(option)
                        dropdown:Close()
                    end)
                    popupConnect(item.MouseEnter, function()
                        if item.Parent then item.BackgroundTransparency = 0.85 end
                    end)
                    popupConnect(item.MouseLeave, function()
                        if item.Parent then item.BackgroundTransparency = 1 end
                    end)
                end

                local height = math.min(#values * 34, 170)
                popup.Size = UDim2.fromOffset(button.AbsoluteSize.X, height)
                popup.CanvasSize = UDim2.fromOffset(0, #values * 34)
                positionPopup()
            end

            connect(button.Activated, function()
                if dropdown.IsOpen then dropdown:Close() else dropdown:Open() end
            end)
            connect(page:GetPropertyChangedSignal("CanvasPosition"), function()
                if dropdown.IsOpen then positionPopup() end
            end)
            connect(gui:GetPropertyChangedSignal("AbsoluteSize"), function()
                if dropdown.IsOpen then positionPopup() end
            end)
            return dropdown
        end

        function tab:CreateKeybind(config)
            if window.Destroyed then return nil end
            config = config or {}
            local key = config.Default or Enum.KeyCode.RightShift
            local listening = false
            local button = self:CreateButton({Name = (config.Name or "Keybind") .. ": " .. key.Name})

            connect(button.Activated, function()
                listening = true
                button.Text = (config.Name or "Keybind") .. ": ..."
            end)

            local keybind = {}
            function keybind:Get() return key end
            function keybind:Set(newKey)
                if typeof(newKey) == "EnumItem" and newKey.EnumType == Enum.KeyCode then
                    key = newKey
                    button.Text = (config.Name or "Keybind") .. ": " .. key.Name
                end
            end
            function keybind:Disconnect()
                listening = false
                keybinds[keybind] = nil
            end
            keybinds[keybind] = {
                GetKey = function() return key end,
                IsListening = function() return listening end,
                SetListening = function(value) listening = value end,
                Button = button,
                Config = config,
                Name = config.Name or "Keybind",
                Object = keybind
            }
            return keybind
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
            function paragraph:SetText(value) description.Text = tostring(value or "") end
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

        -- WindUI-style API aliases
        function tab:Section(config)
            if type(config) == "table" then return self:AddSection(config.Title or config.Name) end
            return self:AddSection(config)
        end
        function tab:Button(config)
            config = config or {}
            config.Name = config.Name or config.Title or "Button"
            return self:CreateButton(config)
        end
        function tab:Toggle(config)
            config = config or {}
            config.Name = config.Name or config.Title or "Toggle"
            if config.Default == nil then config.Default = config.Value end
            return self:CreateToggle(config)
        end
        function tab:Slider(config)
            config = config or {}
            config.Name = config.Name or config.Title or "Slider"
            if config.Default == nil then config.Default = config.Value end
            return self:CreateSlider(config)
        end
        function tab:Input(config)
            config = config or {}
            config.Name = config.Name or config.Title or "Input"
            if config.Default == nil then config.Default = config.Value end
            if config.Placeholder == nil then config.Placeholder = config.PlaceholderText end
            return self:CreateInput(config)
        end
        function tab:Dropdown(config)
            config = config or {}
            config.Name = config.Name or config.Title or "Dropdown"
            if config.Options == nil then config.Options = config.Values end
            if config.Default == nil then config.Default = config.Value end
            return self:CreateDropdown(config)
        end
        function tab:Keybind(config)
            config = config or {}
            config.Name = config.Name or config.Title or "Keybind"
            if config.Default == nil then config.Default = config.Value end
            return self:CreateKeybind(config)
        end
        function tab:Paragraph(config) return self:CreateParagraph(config) end
        function tab:Label(config)
            return self:CreateLabel(type(config) == "table" and (config.Title or config.Text or config.Name) or config)
        end
        function tab:Divider() return self:CreateDivider() end

        connect(tabButton.Activated, function()
            window:SelectTab(tabName)
        end)

        table.insert(window.Tabs, {Name = tabName, Button = tabButton, Page = page})
        if #window.Tabs == 1 then window:SelectTab(tabName) end
        return tab
    end

    function window:Tab(tabOptions)
        tabOptions = tabOptions or {}
        tabOptions.Name = tabOptions.Name or tabOptions.Title or "Tab"
        return self:CreateTab(tabOptions)
    end

    function window:SetTitle(value)
        if not self.Destroyed and title.Parent then title.Text = tostring(value or "") end
    end

    function window:SetSize(value)
        if not self.Destroyed and typeof(value) == "UDim2" then
            expandedSize = value
            if not minimized then main.Size = value end
        end
    end

    function window:Toggle()
        if not self.Destroyed then main.Visible = not main.Visible end
    end

    function window:Minimize(value)
        if self.Destroyed then return end
        local nextState = value == nil and not minimized or value == true
        if nextState == minimized then return end
        if nextState then
            expandedSize = main.Size
            minimized = true
            sidebar.Visible = false
            content.Visible = false
            animate(main, {Size = UDim2.new(expandedSize.X.Scale, expandedSize.X.Offset, 0, 54)}, 0.2)
            minimize.Text = "+"
        else
            minimized = false
            sidebar.Visible = true
            content.Visible = true
            animate(main, {Size = expandedSize}, 0.2)
            minimize.Text = "−"
        end
    end

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
            Text = "  " .. (config.Title or "Notification") .. "\n  " .. (config.Content or ""),
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
            if tween then
                tween.Completed:Wait()
            end
            if toast.Parent then toast:Destroy() end
            for i = #notifications, 1, -1 do
                if notifications[i] == toast then
                    table.remove(notifications, i)
                    break
                end
            end
            for i, item in ipairs(notifications) do
                if item.Parent then
                    animate(item, {Position = UDim2.new(1, -18, 1, -18 - ((i - 1) * 66))}, 0.15)
                end
            end
        end)
        return toast
    end

    function window:SetVisible(visible)
        if not self.Destroyed then main.Visible = visible == true end
    end

    function window:Destroy()
        if self.Destroyed then return end
        self.Destroyed = true
        dragging = false
        activeSlider = nil
        closeDropdown()

        for _, connection in ipairs(connections) do
            if connection.Connected then
                pcall(function() connection:Disconnect() end)
            end
        end
        table.clear(connections)

        for _, entry in ipairs(tweens) do
            pcall(function() entry.Tween:Cancel() end)
        end
        table.clear(tweens)
        table.clear(keybinds)
        table.clear(notifications)

        if gui.Parent then gui:Destroy() end
    end

    connect(UserInputService.InputBegan, function(input, processed)
        if window.Destroyed then return end

        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            if input.Position.X >= topbar.AbsolutePosition.X
                and input.Position.X <= topbar.AbsolutePosition.X + topbar.AbsoluteSize.X
                and input.Position.Y >= topbar.AbsolutePosition.Y
                and input.Position.Y <= topbar.AbsolutePosition.Y + topbar.AbsoluteSize.Y
                and not (
                    (input.Position.X >= close.AbsolutePosition.X
                    and input.Position.X <= close.AbsolutePosition.X + close.AbsoluteSize.X
                    and input.Position.Y >= close.AbsolutePosition.Y
                    and input.Position.Y <= close.AbsolutePosition.Y + close.AbsoluteSize.Y)
                    or (input.Position.X >= minimize.AbsolutePosition.X
                    and input.Position.X <= minimize.AbsolutePosition.X + minimize.AbsoluteSize.X
                    and input.Position.Y >= minimize.AbsolutePosition.Y
                    and input.Position.Y <= minimize.AbsolutePosition.Y + minimize.AbsoluteSize.Y)
                ) then
                dragging = true
                dragStart = input.Position
                startPosition = main.Position
            end
        end

        for _, entry in pairs(keybinds) do
            if entry.IsListening() and input.UserInputType == Enum.UserInputType.Keyboard then
                entry.SetListening(false)
                entry.Object:Set(input.KeyCode)
                break
            elseif not processed and not entry.IsListening()
                and input.UserInputType == Enum.UserInputType.Keyboard
                and input.KeyCode == entry.GetKey() and entry.Config.Callback then
                task.spawn(entry.Config.Callback)
            end
        end
    end)

    connect(UserInputService.InputChanged, function(input)
        if window.Destroyed then return end
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
            )
        end

        if activeSlider and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            activeSlider.Update(input.Position.X)
        end
    end)

    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            activeSlider = nil
        end
    end)

    connect(close.Activated, function()
        window:Destroy()
    end)

    connect(minimize.Activated, function()
        window:Minimize()
    end)

    gui.Parent = playerGui
    return window
end

return LiquidUI
