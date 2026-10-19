
local LiquidUI = {}
LiquidUI.__index = LiquidUI

LiquidUI.Version = "1.0.0"
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

local function animate(object, properties, duration)
    local tween = TweenService:Create(
        object,
        TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        properties
    )
    tween:Play()
    return tween
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

    local gui = create("ScreenGui", {
        Name = options.Name or "LiquidUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    local main = create("Frame", {
        Name = "Window",
        Size = options.Size or UDim2.fromOffset(680, 460),
        Position = UDim2.new(0.5, -340, 0.5, -230),
        BackgroundColor3 = self.Theme.Background,
        BackgroundTransparency = self.Theme.Transparency,
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, {
        corner(nil, 14)
    })

    main.Parent = gui
    corner(main, 14)
    stroke(main, self.Theme.Border, 0.82, 1)

    local topbar = create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = self.Theme.Surface,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0
    })
    topbar.Parent = main

    local title = create("TextLabel", {
        Name = "Title",
        Position = UDim2.fromOffset(18, 0),
        Size = UDim2.new(1, -80, 1, 0),
        BackgroundTransparency = 1,
        Text = options.Title or "LiquidUI",
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

    local sidebar = create("Frame", {
        Name = "Sidebar",
        Position = UDim2.fromOffset(0, 54),
        Size = UDim2.new(0, 155, 1, -54),
        BackgroundColor3 = self.Theme.Surface,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0
    })
    sidebar.Parent = main

    local tabList = create("UIListLayout", {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    tabList.Parent = sidebar

    create("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10)
    }).Parent = sidebar

    local content = create("Frame", {
        Name = "Content",
        Position = UDim2.new(0, 155, 0, 54),
        Size = UDim2.new(1, -155, 1, -54),
        BackgroundTransparency = 1
    })
    content.Parent = main

    local window = {
        Gui = gui,
        Main = main,
        Tabs = {},
        ActiveTab = nil,
        Destroyed = false
    }

    function window:CreateTab(tabOptions)
        tabOptions = tabOptions or {}

        local tabName = tabOptions.Name or "Tab"
        local button = create("TextButton", {
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
        button.Parent = sidebar
        corner(button, 9)

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

        local tab = {
            Button = button,
            Page = page
        }

        function tab:AddSection(name)
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
            config = config or {}
            local buttonFrame = create("TextButton", {
                Size = UDim2.new(1, -4, 0, 42),
                BackgroundColor3 = LiquidUI.Theme.Surface,
                Text = config.Name or "Button",
                TextColor3 = LiquidUI.Theme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                AutoButtonColor = false
            })
            buttonFrame.Parent = page
            corner(buttonFrame, 10)
            stroke(buttonFrame, LiquidUI.Theme.Border, 0.9)

            buttonFrame.MouseEnter:Connect(function()
                animate(buttonFrame, {BackgroundColor3 = LiquidUI.Theme.SurfaceLight})
            end)
            buttonFrame.MouseLeave:Connect(function()
                animate(buttonFrame, {BackgroundColor3 = LiquidUI.Theme.Surface})
            end)
            buttonFrame.Activated:Connect(function()
                if config.Callback then
                    task.spawn(config.Callback)
                end
            end)
            return buttonFrame
        end

        function tab:CreateToggle(config)
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
                value = nextValue == true
                animate(track, {
                    BackgroundColor3 = value and LiquidUI.Theme.Accent or LiquidUI.Theme.SurfaceLight
                })
                animate(knob, {
                    Position = value and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
                })
                if config.Callback then
                    task.spawn(config.Callback, value)
                end
            end

            function toggle:Get()
                return value
            end

            row.Activated:Connect(function()
                toggle:Set(not value)
            end)

            if config.Callback then
                task.spawn(config.Callback, value)
            end

            return toggle
        end

        function tab:CreateSlider(config)
            config = config or {}
            local minimum = config.Min or 0
            local maximum = config.Max or 100
            local value = math.clamp(config.Default or minimum, minimum, maximum)

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
                Size = UDim2.new((value - minimum) / math.max(maximum - minimum, 1), 0, 1, 0),
                BackgroundColor3 = LiquidUI.Theme.Accent
            })
            fill.Parent = bar
            corner(fill, 6)

            local dragging = false
            local slider = {}

            local function update(input)
                local scale = math.clamp(
                    (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X,
                    0, 1
                )
                value = minimum + (maximum - minimum) * scale
                value = math.floor(value + 0.5)
                fill.Size = UDim2.new((value - minimum) / math.max(maximum - minimum, 1), 0, 1, 0)
                label.Text = (config.Name or "Slider") .. ": " .. tostring(value)
                if config.Callback then
                    task.spawn(config.Callback, value)
                end
            end

            function slider:Set(nextValue)
                value = math.clamp(nextValue, minimum, maximum)
                fill.Size = UDim2.new((value - minimum) / math.max(maximum - minimum, 1), 0, 1, 0)
                label.Text = (config.Name or "Slider") .. ": " .. tostring(value)
                if config.Callback then
                    task.spawn(config.Callback, value)
                end
            end

            function slider:Get()
                return value
            end

            label.Text = (config.Name or "Slider") .. ": " .. tostring(value)

            bar.Activated:Connect(function()
                update({Position = UserInputService:GetMouseLocation()})
            end)
            bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    update(input)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                    update(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            return slider
        end

        function tab:CreateInput(config)
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

            input.FocusLost:Connect(function(enterPressed)
                if config.Callback then
                    task.spawn(config.Callback, input.Text, enterPressed)
                end
            end)

            return input
        end

        function tab:CreateDropdown(config)
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
                AutoButtonColor = false
            })
            button.Parent = page
            corner(button, 10)

            local dropdown = {}
            local open = false

            function dropdown:SetOptions(newOptions)
                values = newOptions or {}
            end

            function dropdown:Set(value)
                selected = value
                button.Text = (config.Name or "Dropdown") .. ": " .. tostring(selected) .. "  ▾"
                if config.Callback then
                    task.spawn(config.Callback, selected)
                end
            end

            function dropdown:Get()
                return selected
            end

            button.Activated:Connect(function()
                open = not open
                for _, item in ipairs(button:GetChildren()) do
                    if item.Name == "OptionList" then
                        item:Destroy()
                    end
                end
                if not open then return end

                local list = create("Frame", {
                    Name = "OptionList",
                    Size = UDim2.new(1, 0, 0, math.min(#values * 34, 170)),
                    Position = UDim2.new(0, 0, 1, 5),
                    BackgroundColor3 = LiquidUI.Theme.SurfaceLight,
                    ZIndex = 10
                })
                list.Parent = button
                corner(list, 8)

                create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder
                }).Parent = list

                for _, option in ipairs(values) do
                    local item = create("TextButton", {
                        Size = UDim2.new(1, 0, 0, 34),
                        BackgroundTransparency = 1,
                        Text = tostring(option),
                        TextColor3 = LiquidUI.Theme.Text,
                        TextSize = 12,
                        Font = Enum.Font.Gotham,
                        ZIndex = 11
                    })
                    item.Parent = list
                    item.Activated:Connect(function()
                        dropdown:Set(option)
                        open = false
                        list:Destroy()
                    end)
                end
            end)

            return dropdown
        end

        function tab:CreateKeybind(config)
            config = config or {}
            local key = config.Default or Enum.KeyCode.RightShift
            local listening = false

            local button = self:CreateButton({
                Name = (config.Name or "Keybind") .. ": " .. key.Name
            })

            button.Activated:Connect(function()
                listening = true
                button.Text = (config.Name or "Keybind") .. ": ..."
            end)

            local connection
            connection = UserInputService.InputBegan:Connect(function(input, processed)
                if processed then return end
                if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                    key = input.KeyCode
                    listening = false
                    button.Text = (config.Name or "Keybind") .. ": " .. key.Name
                    return
                end
                if not listening and input.KeyCode == key and config.Callback then
                    task.spawn(config.Callback)
                end
            end)

            return {
                Get = function() return key end,
                Set = function(_, newKey) key = newKey end,
                Disconnect = function() connection:Disconnect() end
            }
        end

        function window:SelectTab(name)
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

        table.insert(window.Tabs, {
            Name = tabName,
            Button = button,
            Page = page
        })

        button.Activated:Connect(function()
            window:SelectTab(tabName)
        end)

        if #window.Tabs == 1 then
            window:SelectTab(tabName)
        end

        return tab
    end

    function window:Notify(config)
        config = config or {}
        local toast = create("TextLabel", {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -18, 1, -18),
            Size = UDim2.fromOffset(270, 58),
            BackgroundColor3 = LiquidUI.Theme.Surface,
            Text = "  " .. (config.Title or "Notification") .. "\n  " .. (config.Content or ""),
            TextColor3 = LiquidUI.Theme.Text,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 50
        })
        toast.Parent = gui
        corner(toast, 12)
        stroke(toast, LiquidUI.Theme.Border, 0.8)

        task.delay(config.Duration or 3, function()
            if toast.Parent then
                animate(toast, {BackgroundTransparency = 1, TextTransparency = 1}, 0.2)
                task.wait(0.25)
                toast:Destroy()
            end
        end)

        return toast
    end

    function window:SetVisible(visible)
        main.Visible = visible
    end

    function window:Destroy()
        if self.Destroyed then return end
        self.Destroyed = true
        gui:Destroy()
    end

    close.Activated:Connect(function()
        window:Destroy()
    end)

    gui.Parent = player:WaitForChild("PlayerGui")

    local dragging, dragStart, startPosition
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = main.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return window
end

return LiquidUI
