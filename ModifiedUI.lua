local Library = { Version = "1.3.0" }

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer

local White = Color3.new(1, 1, 1)

local Theme = {
	Bg = Color3.fromRGB(9, 9, 16),
	Bg2 = Color3.fromRGB(18, 14, 34),
	Card = Color3.fromRGB(19, 18, 32),
	CardHover = Color3.fromRGB(27, 24, 46),
	Stroke = Color3.fromRGB(42, 40, 66),
	Text = Color3.fromRGB(242, 240, 255),
	Muted = Color3.fromRGB(178, 175, 205),
	Violet = Color3.fromRGB(139, 92, 255),
	Cyan = Color3.fromRGB(34, 211, 238),
	Pink = Color3.fromRGB(255, 77, 166),
	Teal = Color3.fromRGB(20, 184, 166),
	Blue = Color3.fromRGB(59, 130, 246),
	Green = Color3.fromRGB(74, 222, 128),
	Red = Color3.fromRGB(248, 113, 113),
	Amber = Color3.fromRGB(251, 191, 36),
}
Library.Theme = Theme

local ParagraphColors = {
	Red = Color3.fromRGB(248, 113, 113), Orange = Color3.fromRGB(251, 146, 60), Green = Color3.fromRGB(74, 222, 128),
	Blue = Color3.fromRGB(59, 130, 246), Purple = Color3.fromRGB(139, 92, 255), Grey = Color3.fromRGB(148, 153, 166),
}

local TypeColors = {
	success = Theme.Green, error = Theme.Red, warn = Theme.Amber, warning = Theme.Amber, info = Theme.Cyan,
}

local FontBold, FontMed, FontBlack = Enum.Font.GothamBold, Enum.Font.GothamMedium, Enum.Font.GothamBlack
local Left, Right = Enum.TextXAlignment.Left, Enum.TextXAlignment.Right
local AutoY, AutoX = Enum.AutomaticSize.Y, Enum.AutomaticSize.X
local QuartOut, DirOut = Enum.EasingStyle.Quart, Enum.EasingDirection.Out
local MouseButton1, TouchInput, MouseMove = Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch, Enum.UserInputType.MouseMovement
local MAIN_RADIUS = 16

local function New(Class, Props, Parent)
	local Object = Instance.new(Class)
	for K, V in pairs(Props or {}) do
		Object[K] = V
	end
	Object.Parent = Parent
	return Object
end

local function Tween(Object, Time, Props, Style, Direction)
	local T = TweenService:Create(Object, TweenInfo.new(Time, Style or QuartOut, Direction or DirOut), Props)
	T:Play()
	return T
end

local function Corner(Parent, R) return New("UICorner", { CornerRadius = UDim.new(0, R or 10) }, Parent) end

local function Stroke(Parent, Color, Thickness, Transparency)
	return New("UIStroke", {
		Color = Color or Theme.Stroke, Thickness = Thickness or 1, Transparency = Transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, Parent)
end

local function Gradient(Parent, A, B, Rotation)
	return New("UIGradient", { Color = ColorSequence.new(A, B), Rotation = Rotation or 0 }, Parent)
end

local function Pad(Parent, L, T, R, B)
	return New("UIPadding", {
		PaddingLeft = UDim.new(0, L), PaddingTop = UDim.new(0, T), PaddingRight = UDim.new(0, R), PaddingBottom = UDim.new(0, B),
	}, Parent)
end

local function List(Parent, Padding, Props)
	local P = { Padding = UDim.new(0, Padding or 0), SortOrder = Enum.SortOrder.LayoutOrder }
	for K, V in pairs(Props or {}) do P[K] = V end
	return New("UIListLayout", P, Parent)
end

local function Call(Fn, ...)
	if type(Fn) == "function" then task.spawn(Fn, ...) end
end

local function InsetY() return GuiService:GetGuiInset().Y end

local function CopyText(Text)
	local Fn = setclipboard or toclipboard or (syn and syn.write_clipboard)
	if not Fn then return false end
	return (pcall(Fn, Text))
end

local function ParentGui(Gui)
	local Ok = pcall(function() Gui.Parent = gethui and gethui() or CoreGui end)
	if not Ok or not Gui.Parent then Gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
end

local function StripRich(Text)
	return (tostring(Text):gsub("<[^>]+>", ""))
end

local function safeHttpGet(url)
	local ok, res = pcall(function() return game:HttpGet(url) end)
	if ok and type(res) == "string" and #res > 100 then return res end
	local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
	if req then
		local ok2, r = pcall(function() return req({ Url = url, Method = "GET" }) end)
		if ok2 and r then
			if type(r) == "string" and #r > 100 then return r end
			if r.Body and type(r.Body) == "string" and #r.Body > 100 then return r.Body end
		end
	end
	if ok and type(res) == "string" then return res end
	return nil
end

local IconSets = {}

local function LoadIconSet(set)
	if IconSets[set] then return IconSets[set] end
	local S = { ready = false, api = nil, waiters = {}, custom = {} }
	IconSets[set] = S
	task.spawn(function()
		local ok, result = pcall(function()
			local directSrc = safeHttpGet("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/" .. set .. "/dist/Icons.lua")
			if directSrc and type(directSrc) == "string" and #directSrc > 100 then
				local iconsTable = loadstring(directSrc)()
				if type(iconsTable) == "table" then
					return { GetIcon = function(name) return iconsTable[name] or name end }
				end
			end
			local src = safeHttpGet("https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua")
			if not src or type(src) ~= "string" then error("HttpGet returned " .. tostring(type(src)) .. " / empty") end
			local IconsV2 = loadstring(src)()
			if IconsV2.SetIconsType then IconsV2.SetIconsType(set) end
			return {
				GetIcon = function(name)
					if IconsV2.GetIcon then return IconsV2.GetIcon(name) end
					if IconsV2.Icon then return IconsV2.Icon(name, set) end
					return name
				end,
			}
		end)
		if ok and result then
			S.api = result
		else
			warn("[ToolkitUI] Failed to load icon set '" .. set .. "': " .. tostring(result))
		end
		S.ready = true
		for I = #S.waiters, 1, -1 do
			local W = S.waiters[I]
			S.waiters[I] = nil
			pcall(W)
		end
	end)
	return S
end

local function ParseIcon(Icon)
	if type(Icon) == "number" then return "asset", "rbxassetid://" .. Icon end
	if type(Icon) ~= "string" or Icon == "" then return nil end
	if Icon:match("^%d+$") then return "asset", "rbxassetid://" .. Icon end
	if Icon:find("^rbx") or Icon:find("^http") then return "asset", Icon end
	local set, name = Icon:match("^(%w+):(.+)$")
	if set then return set:lower(), name end
	return "lucide", Icon
end

local function ApplyResolved(Label, V)
	if type(V) == "number" then
		Label.Image = "rbxassetid://" .. V
		return true
	elseif type(V) == "string" then
		if V == "" then return false end
		Label.Image = V
		return true
	elseif type(V) == "table" then
		local Img, Data = V.Image, V
		if type(V[1]) == "string" and type(V[2]) == "table" then
			Img, Data = V[1], V[2]
			if (Img == nil or Img == "") and type(Data.Image) == "string" then Img = Data.Image end
		end
		if type(Img) == "number" then Img = "rbxassetid://" .. Img end
		if type(Img) ~= "string" or Img == "" then return false end
		Label.Image = Img
		if Data.ImageRectSize then
			Label.ImageRectSize = Data.ImageRectSize
			Label.ImageRectOffset = Data.ImageRectPosition or Data.ImageRectOffset or Vector2.new(0, 0)
		end
		return true
	end
	return false
end

local function SetLucide(Label, Icon, Fallback)
	local Kind, Val = ParseIcon(Icon)
	if not Kind then return end
	if Kind == "asset" then
		Label.Image = Val
		if Fallback then Fallback.Visible = false end
		return
	end
	local S = LoadIconSet(Kind)
	local function Try()
		if not Label.Parent then return end
		local V = S.custom[Val]
		if V == nil and S.api then
			local ok, r = pcall(S.api.GetIcon, Val)
			if ok and r ~= nil and r ~= Val then V = r end
		end
		if V ~= nil and ApplyResolved(Label, V) then
			if Fallback then Fallback.Visible = false end
		end
	end
	if S.ready then Try() else table.insert(S.waiters, Try) end
end

Library.Creator = {
	AddIcons = function(Set, Tbl)
		local S = LoadIconSet(Set)
		for K, V in pairs(Tbl) do S.custom[K] = V end
	end,
}
function Library:SetIcon(Label, Icon, Fallback) SetLucide(Label, Icon, Fallback) end

local function IconLabel(Parent, Icon, Size, Color, Props, FallbackText)
	local P = {
		Size = UDim2.fromOffset(Size, Size), BackgroundTransparency = 1, ImageColor3 = Color or Theme.Muted,
		ScaleType = Enum.ScaleType.Fit,
	}
	for K, V in pairs(Props or {}) do P[K] = V end
	local L = New("ImageLabel", P, Parent)
	local FB
	if FallbackText then
		FB = New("TextLabel", {
			AnchorPoint = P.AnchorPoint, Position = P.Position, Size = P.Size, BackgroundTransparency = 1,
			Text = FallbackText, TextColor3 = Color or Theme.Muted, TextSize = math.max(Size - 4, 8), Font = FontBold,
			Visible = P.Visible,
		}, Parent)
	end
	SetLucide(L, Icon, FB)
	return L, FB
end

local function GradButton(Parent, Text, Size, Position, ColA, ColB, TextSize)
	local Holder = New("Frame", { Size = Size, Position = Position, BackgroundColor3 = White, BorderSizePixel = 0 }, Parent)
	Corner(Holder, 10)
	local G = Gradient(Holder, ColA, ColB, 20)
	local S = Stroke(Holder, White, 1, 0.85)
	local Button = New("TextButton", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, AutoButtonColor = false, Text = Text,
		TextColor3 = White, TextSize = TextSize or 12, Font = FontBold,
	}, Holder)
	Button.MouseEnter:Connect(function() Tween(S, 0.18, { Transparency = 0.3 }) Tween(G, 0.45, { Rotation = 200 }) end)
	Button.MouseLeave:Connect(function() Tween(S, 0.18, { Transparency = 0.85 }) Tween(G, 0.45, { Rotation = 20 }) end)
	return Button, Holder
end

local function IconButton(Parent, Text, Position, HoverColor)
	local B = New("TextButton", {
		Size = UDim2.fromOffset(26, 26), Position = Position, BackgroundColor3 = Theme.Card, BorderSizePixel = 0,
		AutoButtonColor = false, Text = Text, TextColor3 = Theme.Muted, TextSize = 16, Font = FontBold,
	}, Parent)
	Corner(B, 8)
	Stroke(B, Theme.Stroke, 1)
	B.MouseEnter:Connect(function() Tween(B, 0.15, { BackgroundColor3 = HoverColor, TextColor3 = Theme.Text }) end)
	B.MouseLeave:Connect(function() Tween(B, 0.15, { BackgroundColor3 = Theme.Card, TextColor3 = Theme.Muted }) end)
	return B
end

local Rng = Random.new()

local function Orb(Color, X, Y, Size, Transparency, Parent)
	return New("ImageLabel", {
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(X, Y),
		Size = UDim2.fromOffset(Size, Size), Image = "rbxassetid://6014261993", ImageColor3 = Color,
		ImageTransparency = Transparency, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), ZIndex = 1,
	}, Parent)
end

local function MakeParticles(Parent, Count)
	local L = {}
	for I = 1, Count do
		local S = Rng:NextInteger(2, 3)
		local X, Y = Rng:NextNumber(), Rng:NextNumber()
		local P = New("Frame", {
			Size = UDim2.fromOffset(S, S), Position = UDim2.fromScale(X, Y),
			BackgroundColor3 = (I % 2 == 0) and Theme.Violet or Theme.Cyan,
			BackgroundTransparency = Rng:NextNumber(0.6, 0.9), BorderSizePixel = 0, ZIndex = 1,
		}, Parent)
		Corner(P, 2)
		L[I] = { Obj = P, X = X, Y = Y, Speed = Rng:NextNumber(0.01, 0.03), Drift = Rng:NextNumber(0, 6.28) }
	end
	return L
end

local function Ser(V)
	if typeof(V) == "Color3" then return { __c = { V.R, V.G, V.B } } end
	if typeof(V) == "EnumItem" then return V.Name end
	return V
end

local function Deser(V)
	if type(V) == "table" and V.__c then return Color3.new(V.__c[1], V.__c[2], V.__c[3]) end
	return V
end

local Window = {}
Window.__index = Window

local Elements = {}
Elements.__index = Elements

local TabClass = {}
TabClass.__index = TabClass
setmetatable(TabClass, { __index = Elements })

local SectionClass = {}
SectionClass.__index = SectionClass
setmetatable(SectionClass, { __index = Elements })

local SideSection = {}
SideSection.__index = SideSection

function Window:Connect(Signal, Fn)
	local C = Signal:Connect(Fn)
	table.insert(self.Connections, C)
	return C
end

local function IsPointerStart(I)
	return I.UserInputType == MouseButton1 or I.UserInputType == TouchInput
end

local function IsTrackedMove(Tracked, I)
	if not Tracked then return false end
	if Tracked.UserInputType == TouchInput then return I == Tracked end
	return I.UserInputType == MouseMove
end

local function IsTrackedEnd(Tracked, I)
	if not Tracked then return false end
	if Tracked.UserInputType == TouchInput then return I == Tracked end
	return I.UserInputType == MouseButton1
end

local function MakeDraggable(Win, Handle, Target, GetScale, CanDrag, OnMoved)
	local Tracked, Start, StartPos = nil, nil, nil
	Handle.InputBegan:Connect(function(I)
		if Tracked or not IsPointerStart(I) then return end
		if CanDrag and not CanDrag() then return end
		Tracked, Start, StartPos = I, I.Position, Target.Position
	end)
	Win:Connect(UserInputService.InputChanged, function(I)
		if not IsTrackedMove(Tracked, I) then return end
		local D = (I.Position - Start) / GetScale()
		Target.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + D.X, StartPos.Y.Scale, StartPos.Y.Offset + D.Y)
		if OnMoved and D.Magnitude > 4 then OnMoved() end
	end)
	Win:Connect(UserInputService.InputEnded, function(I)
		if IsTrackedEnd(Tracked, I) then Tracked = nil end
	end)
end

local function MakeDrag(Win, Hit, OnMove, Page)
	local Tracked = nil
	local function Pos(I) return Vector2.new(I.Position.X, I.Position.Y + InsetY()) end
	local function Stop()
		Tracked = nil
		if Page and Page.Parent then Page.ScrollingEnabled = true end
	end
	Hit.Active = true
	Hit.InputBegan:Connect(function(I)
		if Tracked or not IsPointerStart(I) then return end
		Tracked = I
		if Page then Page.ScrollingEnabled = false end
		OnMove(Pos(I))
	end)
	Win:Connect(UserInputService.InputChanged, function(I)
		if IsTrackedMove(Tracked, I) then OnMove(Pos(I)) end
	end)
	Win:Connect(UserInputService.InputEnded, function(I)
		if IsTrackedEnd(Tracked, I) then Stop() end
	end)
end

local function BuildDialog(Host, O)
	O = O or {}
	local D = {}
	local Box, Sc

	function D:Show()
		if Host.Current and Host.Current ~= D then Host.Current:Close(true) end
		if Box then return D end
		Host.Current = D
		Host.Modal.Visible = true
		Tween(Host.Dim, 0.2, { BackgroundTransparency = 0.4 })

		Box = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 340, 0, 0),
			AutomaticSize = AutoY, BackgroundColor3 = Color3.fromRGB(24, 22, 40), BorderSizePixel = 0, ZIndex = 2, Active = true,
		}, Host.Modal)
		Corner(Box, 14)
		Gradient(Stroke(Box, White, 2, 0.05), Theme.Violet, Theme.Cyan, 45)
		Pad(Box, 18, 16, 18, 16)
		List(Box, 12)
		Sc = New("UIScale", { Scale = 0.9 }, Box)
		Tween(Sc, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)

		local TitleRow = New("Frame", { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1 }, Box)
		local TX = 0
		if O.Icon then
			IconLabel(TitleRow, O.Icon, 20, Theme.Violet, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0) }, "•")
			TX = 28
		end
		New("TextLabel", {
			Position = UDim2.fromOffset(TX, 0), Size = UDim2.new(1, -TX, 1, 0), BackgroundTransparency = 1, RichText = true,
			Text = O.Title or "Dialog", TextColor3 = White, TextSize = 16, Font = FontBlack, TextXAlignment = Left,
		}, TitleRow)
		local Body = O.Content or O.Desc
		if Body then
			New("TextLabel", {
				LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, RichText = true,
				Text = Body, TextColor3 = Color3.fromRGB(235, 233, 255), TextSize = 13, Font = FontMed, TextWrapped = true,
				TextXAlignment = Left, TextYAlignment = Enum.TextYAlignment.Top,
			}, Box)
		end

		local Buttons = O.Buttons or {}
		if #Buttons > 0 then
			local Row = New("Frame", { LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1 }, Box)
			List(Row, 8, { FillDirection = Enum.FillDirection.Horizontal })
			local N = #Buttons
			for I, B in ipairs(Buttons) do
				local Size = UDim2.new(1 / N, -8 * (N - 1) / N, 1, 0)
				local Variant = B.Variant or B.Style or "Primary"
				local Btn
				if Variant == "Primary" then
					local Holder
					Btn, Holder = GradButton(Row, B.Title or "Button", Size, UDim2.new(), Theme.Violet, Theme.Blue, 12)
					Holder.LayoutOrder = I
				else
					Btn = New("TextButton", {
						LayoutOrder = I, Size = Size, BackgroundColor3 = Color3.fromRGB(36, 33, 60),
						BackgroundTransparency = Variant == "Tertiary" and 1 or 0, BorderSizePixel = 0, AutoButtonColor = false,
						Text = B.Title or "Button", TextColor3 = Color3.fromRGB(210, 205, 240), TextSize = 12, Font = FontBold,
					}, Row)
					Corner(Btn, 10)
					if Variant ~= "Tertiary" then Stroke(Btn, Theme.Stroke, 1.2) end
				end
				Btn.MouseButton1Click:Connect(function()
					D:Close()
					Call(B.Callback)
				end)
			end
		end
		return D
	end

	function D:Close(Instant)
		if not Box then return end
		local B, S = Box, Sc
		Box, Sc = nil, nil
		if Host.Current == D then Host.Current = nil end
		if Instant then
			B:Destroy()
			return
		end
		Tween(Host.Dim, 0.15, { BackgroundTransparency = 1 })
		Tween(S, 0.15, { Scale = 0.92 })
		task.delay(0.16, function()
			B:Destroy()
			if not Host.Current then Host.Modal.Visible = false end
		end)
	end

	return D
end

local PopupHost
local function GetPopupHost()
	if PopupHost and PopupHost.Gui.Parent then return PopupHost end
	local Gui = New("ScreenGui", {
		Name = "ToolkitUI_Popup", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1000001,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	ParentGui(Gui)
	local Modal = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 40 }, Gui)
	local Dim = New("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
		Active = true, ZIndex = 1,
	}, Modal)
	PopupHost = { Gui = Gui, Modal = Modal, Dim = Dim }
	return PopupHost
end

function Library:Popup(O)
	local D = BuildDialog(GetPopupHost(), O)
	D:Show()
	return D
end

local NotifGui, NotifHolder
local NotifLower = false

local function EnsureNotif()
	if NotifGui and NotifGui.Parent then return end
	NotifGui = New("ScreenGui", {
		Name = "ToolkitUI_Notify", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1000000,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	ParentGui(NotifGui)
	NotifHolder = New("Frame", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, NotifLower and 64 or 16),
		Size = UDim2.new(0, 300, 1, -80), BackgroundTransparency = 1,
	}, NotifGui)
	List(NotifHolder, 8, { VerticalAlignment = Enum.VerticalAlignment.Top, HorizontalAlignment = Enum.HorizontalAlignment.Right })
end

function Library:SetNotificationLower(V)
	NotifLower = V and true or false
	if NotifHolder then NotifHolder.Position = UDim2.new(1, -16, 0, NotifLower and 64 or 16) end
end

function Library:Notify(O)
	if type(O) == "string" then O = { Content = O } end
	O = O or {}
	EnsureNotif()
	local Col = O.Color or (O.Type and TypeColors[string.lower(tostring(O.Type))]) or Theme.Violet
	local Dur = O.Duration or 4

	local Holder = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1 }, NotifHolder)
	local Card = New("Frame", {
		Position = UDim2.fromOffset(340, 0), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY,
		BackgroundColor3 = Color3.fromRGB(24, 22, 40), BorderSizePixel = 0, ClipsDescendants = true,
	}, Holder)
	Corner(Card, 12)
	Stroke(Card, Col, 1.2, 0.3)

	local Body = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1 }, Card)
	Pad(Body, 14, 12, 14, 14)
	local TextX = 0
	if O.Icon then
		IconLabel(Body, O.Icon, 18, Col, { Position = UDim2.fromOffset(0, 1) }, "•")
		TextX = 28
	end
	local Column = New("Frame", {
		Position = UDim2.fromOffset(TextX, 0), Size = UDim2.new(1, -TextX, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1,
	}, Body)
	List(Column, 3)
	New("TextLabel", {
		LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, RichText = true,
		Text = O.Title or "Notification", TextColor3 = Theme.Text, TextSize = 13, Font = FontBold, TextWrapped = true, TextXAlignment = Left,
	}, Column)
	if O.Content then
		New("TextLabel", {
			LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, RichText = true,
			Text = O.Content, TextColor3 = Theme.Muted, TextSize = 11, Font = FontMed, TextWrapped = true, TextXAlignment = Left,
		}, Column)
	end
	local Bar = New("Frame", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 3),
		BackgroundColor3 = Col, BorderSizePixel = 0, ZIndex = 2,
	}, Card)

	local Gone = false
	local function Dismiss()
		if Gone then return end
		Gone = true
		local T = Tween(Card, 0.3, { Position = UDim2.fromOffset(340, 0) })
		T.Completed:Connect(function() Holder:Destroy() end)
	end
	Tween(Card, 0.35, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Back)
	Tween(Bar, Dur, { Size = UDim2.new(0, 0, 0, 3) }, Enum.EasingStyle.Linear)
	task.delay(Dur, Dismiss)
	New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 3 }, Card).MouseButton1Click:Connect(Dismiss)

	return { Close = Dismiss }
end

function Elements:_Next()
	self._n += 1
	return self._n
end

function Elements:_Card(O, RightW, Clickable)
	RightW = RightW or 0
	local Root = New("Frame", {
		Name = "Element", LayoutOrder = self:_Next(), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1,
	}, self.Parent)
	local Card = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Active = true,
	}, Root)
	Corner(Card, 10)
	local CS = Stroke(Card, Theme.Stroke, 1)
	Pad(Card, 12, 8, 12, 8)
	New("UISizeConstraint", { MinSize = Vector2.new(0, 44) }, Card)
	List(Card, 8, { VerticalAlignment = Enum.VerticalAlignment.Center })

	local Lock = New("TextButton", {
		Name = "LockOverlay", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(8, 8, 14), BackgroundTransparency = 0.35,
		BorderSizePixel = 0, Text = "", AutoButtonColor = false, Visible = false, ZIndex = 20,
	}, Root)
	Corner(Lock, 10)
	local LockRow = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(0, 18),
		AutomaticSize = AutoX, BackgroundTransparency = 1,
	}, Lock)
	List(LockRow, 6, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center })
	local LockIconWrap = New("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1 }, LockRow)
	IconLabel(LockIconWrap, "lock", 14, Theme.Amber, { Position = UDim2.fromOffset(0, 0) }, "•")
	local LockLabel = New("TextLabel", {
		LayoutOrder = 2, Size = UDim2.fromOffset(0, 18), AutomaticSize = AutoX, BackgroundTransparency = 1, Text = "Locked",
		TextColor3 = Theme.Text, TextSize = 11, Font = FontBold,
	}, LockRow)

	local HeadProps = { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1 }
	if Clickable then
		HeadProps.Text = ""
		HeadProps.AutoButtonColor = false
	end
	local Head = New(Clickable and "TextButton" or "Frame", HeadProps, Card)
	New("UISizeConstraint", { MinSize = Vector2.new(0, 22) }, Head)

	local TextX, Ico = 0, nil
	if O.Icon and O.Icon ~= "" then
		local IS = O.IconSize or 18
		Ico = IconLabel(Head, O.Icon, IS, Theme.Violet, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0) }, "•")
		TextX = IS + 10
	end

	local Column = New("Frame", {
		Position = UDim2.fromOffset(TextX, 0), Size = UDim2.new(1, -(TextX + (RightW > 0 and RightW + 10 or 0)), 0, 0),
		AutomaticSize = AutoY, BackgroundTransparency = 1,
	}, Head)
	List(Column, 2)
	local Title = New("TextLabel", {
		LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, RichText = true,
		Text = O.Title or "Element", TextColor3 = Theme.Text, TextSize = 13, Font = FontBold, TextWrapped = true, TextXAlignment = Left,
	}, Column)
	local Desc
	if O.Desc then
		Desc = New("TextLabel", {
			LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, RichText = true,
			Text = O.Desc, TextColor3 = Theme.Muted, TextSize = 11, Font = FontMed, TextWrapped = true, TextXAlignment = Left,
		}, Column)
	end

	local Base = { Bg = Theme.Card, Stroke = Theme.Stroke }
	Card.MouseEnter:Connect(function()
		Tween(Card, 0.15, { BackgroundColor3 = Base.Bg:Lerp(White, 0.04) })
		Tween(CS, 0.15, { Color = Theme.Violet })
	end)
	Card.MouseLeave:Connect(function()
		Tween(Card, 0.15, { BackgroundColor3 = Base.Bg })
		Tween(CS, 0.15, { Color = Base.Stroke })
	end)

	return {
		Root = Root, Card = Card, Head = Head, Title = Title, Desc = Desc, Icon = Ico, Stroke = CS,
		Lock = Lock, LockLabel = LockLabel, Base = Base,
	}
end

local function SetLockText(C, Text)
	Text = tostring(Text or "")
	C.LockLabel.Text = Text
	C.LockLabel.Visible = Text ~= ""
end

function Elements:_Finish(O, Obj, C)
	local Win = self.Win
	Obj.Frame = C.Root
	Obj.Locked = false
	SetLockText(C, O.LockTitle or O.LockedTitle or "Locked")

	function Obj:SetTitle(T) C.Title.Text = T end
	function Obj:SetDesc(T)
		if C.Desc then C.Desc.Text = T end
	end
	function Obj:SetLockTitle(T) SetLockText(C, T) end
	function Obj:Lock(Title)
		Obj.Locked = true
		if Title ~= nil then SetLockText(C, Title) end
		if type(Obj.Close) == "function" then pcall(Obj.Close, Obj) end
		C.Lock.Visible = true
	end
	function Obj:Unlock()
		Obj.Locked = false
		C.Lock.Visible = false
	end
	function Obj:Destroy()
		if O.Flag then Win.FlagElements[O.Flag] = nil end
		local I = table.find(Win._Elements, Obj)
		if I then table.remove(Win._Elements, I) end
		C.Root:Destroy()
	end
	table.insert(Win._Elements, Obj)
	if O.Flag then Win.FlagElements[O.Flag] = Obj end
	if O.Locked then Obj:Lock() end
	return Obj
end

function Elements:Toggle(O)
	O = O or {}
	local Checkbox = O.Type == "Checkbox"
	local C = self:_Card(O, Checkbox and 30 or 52, true)
	local Obj = { Value = false }
	local Render

	if Checkbox then
		local Box = New("Frame", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(22, 22),
			BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0,
		}, C.Head)
		Corner(Box, 6)
		local BS = Stroke(Box, Theme.Stroke, 1.5)
		local Fill = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = White, BackgroundTransparency = 1, BorderSizePixel = 0 }, Box)
		Corner(Fill, 6)
		Gradient(Fill, Theme.Violet, Theme.Cyan, 45)
		local Chk, ChkFB = IconLabel(Box, "check", 14, White, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ImageTransparency = 1, ZIndex = 3 }, "✓")
		ChkFB.TextTransparency = 1
		ChkFB.ZIndex = 3
		Render = function(V)
			Tween(Fill, 0.15, { BackgroundTransparency = V and 0 or 1 })
			Tween(Chk, 0.15, { ImageTransparency = V and 0 or 1 })
			Tween(ChkFB, 0.15, { TextTransparency = V and 0 or 1 })
			Tween(BS, 0.15, { Color = V and Theme.Violet or Theme.Stroke })
		end
	else
		local Track = New("Frame", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(42, 22),
			BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0,
		}, C.Head)
		Corner(Track, 11)
		local Fill = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = White, BackgroundTransparency = 1, BorderSizePixel = 0 }, Track)
		Corner(Fill, 11)
		Gradient(Fill, Theme.Violet, Theme.Cyan, 0)
		local Knob = New("Frame", {
			AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(16, 16),
			BackgroundColor3 = White, BorderSizePixel = 0, ZIndex = 2,
		}, Track)
		Corner(Knob, 8)
		Render = function(V)
			Tween(Fill, 0.2, { BackgroundTransparency = V and 0 or 1 })
			Tween(Knob, 0.2, { Position = V and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, Enum.EasingStyle.Back)
		end
	end

	function Obj:Set(V, Silent)
		V = V and true or false
		Obj.Value = V
		Render(V)
		if not Silent then Call(O.Callback, V) end
	end
	C.Head.MouseButton1Click:Connect(function() Obj:Set(not Obj.Value) end)
	local Init = (O.Value == true) or (O.Default == true)
	Obj:Set(Init, not Init)
	return self:_Finish(O, Obj, C)
end

function Elements:Button(O)
	O = O or {}
	local C = self:_Card(O, 40, true)
	local Obj = {}
	local Chip = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(36, 24),
		BackgroundColor3 = White, BorderSizePixel = 0,
	}, C.Head)
	Corner(Chip, 8)
	Gradient(Chip, Theme.Violet, Theme.Blue, 20)
	IconLabel(Chip, "chevron-right", 14, White, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) }, ">")
	C.Head.MouseButton1Click:Connect(function()
		Tween(Chip, 0.08, { Size = UDim2.fromOffset(32, 22) })
		task.delay(0.1, function()
			if Chip.Parent then Tween(Chip, 0.15, { Size = UDim2.fromOffset(36, 24) }) end
		end)
		Call(O.Callback)
	end)
	return self:_Finish(O, Obj, C)
end

function Elements:Slider(O)
	O = O or {}
	local V = type(O.Value) == "table" and O.Value or {}
	local Min, Max = V.Min or O.Min or 0, V.Max or O.Max or 100
	local Default = V.Default
	if Default == nil then Default = O.Default end
	if Default == nil and type(O.Value) == "number" then Default = O.Value end
	local Step = O.Step or 1
	local C = self:_Card(O, 76)
	local Obj = { Value = Min }

	local ValueBox = New("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(76, 18),
		BackgroundTransparency = 1, Text = "", TextColor3 = Theme.Violet, TextSize = 12, Font = FontBold, TextXAlignment = Right,
		ClearTextOnFocus = false, TextEditable = O.IsTextbox == true, TextTruncate = Enum.TextTruncate.AtEnd,
	}, C.Head)
	local Holder = New("Frame", {
		LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Active = true,
	}, C.Card)
	local Track = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0), Size = UDim2.new(1, -18, 0, 6),
		BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0,
	}, Holder)
	Corner(Track, 3)
	local Fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = White, BorderSizePixel = 0 }, Track)
	Corner(Fill, 3)
	Gradient(Fill, Theme.Violet, Theme.Cyan, 0)
	local Knob = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = White, BorderSizePixel = 0, ZIndex = 2,
	}, Track)
	Corner(Knob, 7)
	Stroke(Knob, Theme.Violet, 2)

	local Decimals = #(tostring(Step):match("%.(%d+)") or "")
	function Obj:Set(Val, Silent)
		local Prev = Obj.Value
		Val = tonumber(Val) or Min
		Val = math.clamp(math.floor((Val - Min) / Step + 0.5) * Step + Min, Min, Max)
		Val = tonumber(string.format("%." .. Decimals .. "f", Val))
		Obj.Value = Val
		local R = (Val - Min) / math.max(Max - Min, 1e-9)
		Tween(Fill, 0.08, { Size = UDim2.fromScale(R, 1) })
		Tween(Knob, 0.08, { Position = UDim2.fromScale(R, 0.5) })
		ValueBox.Text = tostring(Val) .. (O.Suffix or "")
		if not Silent and Val ~= Prev then Call(O.Callback, Val) end
	end
	function Obj:SetMax(N)
		Max = N
		Obj:Set(Obj.Value, true)
	end
	function Obj:SetMin(N)
		Min = N
		Obj:Set(Obj.Value, true)
	end

	ValueBox.FocusLost:Connect(function()
		local N = tonumber(ValueBox.Text:match("-?%d+%.?%d*"))
		Obj:Set(N or Obj.Value)
	end)

	MakeDrag(self.Win, Holder, function(P)
		local R = math.clamp((P.X - Track.AbsolutePosition.X) / math.max(Track.AbsoluteSize.X, 1), 0, 1)
		Obj:Set(Min + (Max - Min) * R)
	end, self.Page)

	Obj:Set(Default or Min, Default == nil)
	return self:_Finish(O, Obj, C)
end

function Elements:Dropdown(O)
	O = O or {}
	local Multi = O.Multi == true
	local Values = O.Values or {}
	local C = self:_Card(O, 150)
	local Obj = { Value = Multi and {} or nil, Values = Values }
	local Open = false

	local Pill = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(140, 26),
		BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0, AutoButtonColor = false, Text = "",
	}, C.Head)
	Corner(Pill, 8)
	local PillStroke = Stroke(Pill, Theme.Stroke, 1)
	local ValueLabel = New("TextLabel", {
		Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -32, 1, 0), BackgroundTransparency = 1, Text = "",
		TextColor3 = Theme.Text, TextSize = 11, Font = FontMed, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, Pill)
	local Chevron = IconLabel(Pill, "chevron-down", 14, Theme.Muted, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0) }, "v")

	Pill.MouseEnter:Connect(function()
		if Open then return end
		Tween(PillStroke, 0.15, { Color = Theme.Violet })
		Tween(Pill, 0.15, { BackgroundColor3 = Theme.CardHover })
	end)
	Pill.MouseLeave:Connect(function()
		if Open then return end
		Tween(PillStroke, 0.15, { Color = Theme.Stroke })
		Tween(Pill, 0.15, { BackgroundColor3 = Theme.Bg2 })
	end)

	local Holder = New("Frame", {
		LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0, ClipsDescendants = true, Visible = false,
		Active = true,
	}, C.Card)
	Corner(Holder, 8)
	Stroke(Holder, Theme.Violet, 1, 0.55)
	local Scroll = New("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Violet, CanvasSize = UDim2.new(), AutomaticCanvasSize = AutoY,
		ScrollingDirection = Enum.ScrollingDirection.Y, Active = true,
	}, Holder)
	Pad(Scroll, 4, 4, 4, 4)
	List(Scroll, 2)

	local Buttons = {}
	local ContentH = 0
	local function Height() return math.min(math.max(ContentH, 32), 160) + 8 end

	local function NameOf(Item)
		if Item == nil then return nil end
		if type(Item) == "table" then
			if Item.Title == nil then return nil end
			return tostring(Item.Title)
		end
		return tostring(Item)
	end

	local function Paint(B)
		local T
		if B.Locked then
			T = 1
		elseif B.Down then
			T = 0.5
		elseif B.On then
			T = B.Hover and 0.6 or 0.74
		else
			T = B.Hover and 0.8 or 1
		end
		Tween(B.Btn, 0.12, { BackgroundTransparency = T })
		B.Accent.Visible = B.On and not B.Locked
	end

	local function SetOpen(Val)
		Open = Val
		Obj.Opened = Val
		if Val then
			Holder.Visible = true
			Tween(Holder, 0.25, { Size = UDim2.new(1, 0, 0, Height()) })
		else
			Tween(Holder, 0.2, { Size = UDim2.new(1, 0, 0, 0) })
			task.delay(0.22, function()
				if not Open and Holder.Parent then Holder.Visible = false end
			end)
		end
		Tween(Chevron, 0.2, { Rotation = Val and 180 or 0 })
		Tween(PillStroke, 0.2, { Color = Val and Theme.Violet or Theme.Stroke })
		Tween(Pill, 0.2, { BackgroundColor3 = Val and Theme.CardHover or Theme.Bg2 })
	end

	local function Render()
		if Multi then
			ValueLabel.Text = #Obj.Value == 0 and (O.Placeholder or "None") or table.concat(Obj.Value, ", ")
		else
			ValueLabel.Text = Obj.Value and tostring(Obj.Value) or (O.Placeholder or "Select...")
		end
		for Name, B in pairs(Buttons) do
			local On
			if Multi then On = table.find(Obj.Value, Name) ~= nil else On = Obj.Value == Name end
			B.On = On
			B.Chk.Visible = On
			if B.ChkFB then B.ChkFB.Visible = On and B.Chk.Image == "" end
			if B.Locked then
				B.Lbl.TextColor3 = Theme.Muted
				B.Lbl.TextTransparency = 0.45
			else
				B.Lbl.TextColor3 = On and Theme.Text or Theme.Muted
				B.Lbl.Font = On and FontBold or FontMed
			end
			Paint(B)
		end
	end

	function Obj:Select(Val, Silent)
		if Multi then
			local L = {}
			if type(Val) == "table" and Val.Title == nil then
				for _, Item in ipairs(Val) do
					local N = NameOf(Item)
					if N then table.insert(L, N) end
				end
			elseif Val ~= nil then
				local N = NameOf(Val)
				if N then table.insert(L, N) end
			end
			if O.AllowNone == false and #L == 0 then return end
			Obj.Value = L
		else
			if type(Val) == "table" and Val.Title == nil then Val = Val[1] end
			Obj.Value = NameOf(Val)
		end
		Render()
		if not Silent then Call(O.Callback, Multi and table.clone(Obj.Value) or Obj.Value) end
	end
	Obj.Set = Obj.Select

	local function Build()
		for _, Ch in ipairs(Scroll:GetChildren()) do
			if Ch:IsA("GuiObject") then Ch:Destroy() end
		end
		Buttons = {}
		ContentH = 0
		if #Values == 0 then
			New("TextLabel", {
				LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = O.EmptyText or "No options",
				TextColor3 = Theme.Muted, TextSize = 11, Font = FontMed,
			}, Scroll)
			ContentH = 32
			return
		end
		for I, Raw in ipairs(Values) do
			if type(Raw) == "table" and Raw.Type == "Divider" then
				local Div = New("Frame", { LayoutOrder = I, Size = UDim2.new(1, 0, 0, 7), BackgroundTransparency = 1 }, Scroll)
				New("Frame", {
					AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0), Size = UDim2.new(1, -12, 0, 1),
					BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0,
				}, Div)
				ContentH += 9
			else
				local Name = NameOf(Raw) or tostring(Raw)
				local ItemLocked = type(Raw) == "table" and Raw.Locked == true
				local LockText = "Locked"
				if ItemLocked then
					local T = Raw.LockTitle
					if T == nil then T = Raw.LockedTitle end
					if T ~= nil then LockText = tostring(T) end
				end

				local Btn = New("TextButton", {
					LayoutOrder = I, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.Violet, BackgroundTransparency = 1,
					BorderSizePixel = 0, AutoButtonColor = false, Text = "", ClipsDescendants = true,
				}, Scroll)
				Corner(Btn, 6)
				local Accent = New("Frame", {
					AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(3, 16),
					BackgroundColor3 = Theme.Cyan, BorderSizePixel = 0, Visible = false,
				}, Btn)
				Corner(Accent, 2)
				local Row = New("Frame", {
					Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -38, 1, 0), BackgroundTransparency = 1,
				}, Btn)
				List(Row, 6, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center })
				if type(Raw) == "table" and Raw.Icon then
					local Wrap = New("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1 }, Row)
					IconLabel(Wrap, Raw.Icon, 14, Theme.Violet, { Position = UDim2.fromOffset(0, 0) })
				end
				local Lbl = New("TextLabel", {
					LayoutOrder = 2, Size = UDim2.fromOffset(0, 28), AutomaticSize = AutoX, BackgroundTransparency = 1, Text = Name,
					TextColor3 = Theme.Muted, TextSize = 12, Font = FontMed,
				}, Row)
				if ItemLocked then
					local LockWrap = New("Frame", { LayoutOrder = 3, Size = UDim2.fromOffset(0, 28), AutomaticSize = AutoX, BackgroundTransparency = 1 }, Row)
					List(LockWrap, 4, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center })
					local IconWrap = New("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1 }, LockWrap)
					IconLabel(IconWrap, "lock", 12, Theme.Amber, { Position = UDim2.fromOffset(0, 0) }, "•")
					if LockText ~= "" then
						New("TextLabel", {
							LayoutOrder = 2, Size = UDim2.fromOffset(0, 28), AutomaticSize = AutoX, BackgroundTransparency = 1, Text = LockText,
							TextColor3 = Theme.Amber, TextSize = 10, Font = FontBold,
						}, LockWrap)
					end
				end
				local Chk, ChkFB = IconLabel(Btn, "check", 14, Theme.Cyan, {
					AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Visible = false,
				}, "✓")

				local B = {
					Btn = Btn, Lbl = Lbl, Chk = Chk, ChkFB = ChkFB, Accent = Accent, Locked = ItemLocked,
					On = false, Hover = false, Down = false,
				}
				Btn.MouseEnter:Connect(function()
					B.Hover = true
					Paint(B)
				end)
				Btn.MouseLeave:Connect(function()
					B.Hover = false
					B.Down = false
					Paint(B)
				end)
				Btn.MouseButton1Down:Connect(function()
					B.Down = true
					Paint(B)
				end)
				Btn.MouseButton1Up:Connect(function()
					B.Down = false
					Paint(B)
				end)
				Btn.MouseButton1Click:Connect(function()
					if ItemLocked then return end
					if type(Raw) == "table" then Call(Raw.Callback) end
					if Multi then
						local L = table.clone(Obj.Value)
						local Idx = table.find(L, Name)
						if Idx then table.remove(L, Idx) else table.insert(L, Name) end
						Obj:Select(L)
					else
						if O.AllowNone == true and Obj.Value == Name then Obj:Select(nil) else Obj:Select(Name) end
						SetOpen(false)
					end
				end)
				Buttons[Name] = B
				ContentH += 32
			end
		end
	end

	function Obj:Refresh(NewValues)
		Values = NewValues or {}
		Obj.Values = Values
		Build()
		local Keep = Obj.Value
		if Multi then
			local L = {}
			for _, N in ipairs(Keep) do
				if Buttons[N] then table.insert(L, N) end
			end
			Obj.Value = L
		elseif Keep and not Buttons[Keep] then
			Obj.Value = nil
		end
		Render()
		if Open then Tween(Holder, 0.2, { Size = UDim2.new(1, 0, 0, Height()) }) end
	end
	function Obj:Open() SetOpen(true) end
	function Obj:Close() SetOpen(false) end
	function Obj:Toggle() SetOpen(not Open) end

	Pill.MouseButton1Click:Connect(function() SetOpen(not Open) end)
	Build()
	local Init = O.Value
	if Init == nil then Init = O.Default end
	Obj:Select(Init, Init == nil)
	return self:_Finish(O, Obj, C)
end

function Elements:Input(O)
	O = O or {}
	local Textarea = O.Type == "Textarea"
	local Obj = { Value = "" }
	local C = self:_Card(O, Textarea and 0 or 170)

	local Pill
	if Textarea then
		Pill = New("Frame", {
			LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 72), BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0, ClipsDescendants = true,
		}, C.Card)
	else
		Pill = New("Frame", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(170, 26),
			BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0, ClipsDescendants = true,
		}, C.Head)
	end
	Corner(Pill, 8)
	local PS = Stroke(Pill, Theme.Stroke, 1)

	local TX = 8
	if O.InputIcon then
		IconLabel(Pill, O.InputIcon, 14, Theme.Muted, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, Textarea and 0 or 0.5, Textarea and 14 or 0) })
		TX = 28
	end
	local TB = New("TextBox", {
		Position = UDim2.fromOffset(TX, Textarea and 4 or 0), Size = UDim2.new(1, -(TX + 8), 1, Textarea and -8 or 0),
		BackgroundTransparency = 1, Text = "", PlaceholderText = O.Placeholder or "Enter text...", PlaceholderColor3 = Theme.Muted,
		TextColor3 = Theme.Text, TextSize = 12, Font = FontMed, ClearTextOnFocus = O.ClearTextOnFocus == true, TextXAlignment = Left,
		TextYAlignment = Textarea and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center, MultiLine = Textarea, TextWrapped = Textarea,
	}, Pill)
	TB.Focused:Connect(function() Tween(PS, 0.15, { Color = Theme.Violet }) end)

	function Obj:Set(Val, Silent)
		Val = tostring(Val or "")
		TB.Text = Val
		Obj.Value = Val
		if not Silent then Call(O.Callback, Val) end
	end
	function Obj:SetPlaceholder(T) TB.PlaceholderText = T end
	TB.FocusLost:Connect(function()
		Tween(PS, 0.15, { Color = Theme.Stroke })
		local Text = TB.Text
		if O.Numeric and Text ~= "" and not tonumber(Text) then
			Text = Obj.Value
		end
		Obj:Set(Text)
	end)
	local Init = O.Value
	if Init == nil then Init = O.Default end
	Obj:Set(Init or "", Init == nil)
	return self:_Finish(O, Obj, C)
end

function Elements:Keybind(O)
	O = O or {}
	local C = self:_Card(O, 96)
	local Obj = { Value = "None" }
	local Listening = false

	local Pill = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(86, 26),
		BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0, AutoButtonColor = false, Text = "None", TextColor3 = Theme.Text,
		TextSize = 11, Font = FontBold,
	}, C.Head)
	Corner(Pill, 8)
	local PS = Stroke(Pill, Theme.Stroke, 1)

	function Obj:Set(K, Silent)
		if typeof(K) == "EnumItem" then K = K.Name end
		K = tostring(K or "None")
		Obj.Value = K
		Pill.Text = K
		if not Silent then Call(O.ChangedCallback, K) end
	end

	Pill.MouseButton1Click:Connect(function()
		if O.CanChange == false then return end
		Listening = true
		Pill.Text = "..."
		Tween(PS, 0.15, { Color = Theme.Violet })
	end)

	self.Win:Connect(UserInputService.InputBegan, function(I, Processed)
		if Listening then
			if I.UserInputType == Enum.UserInputType.Keyboard then
				Listening = false
				Tween(PS, 0.15, { Color = Theme.Stroke })
				Obj:Set(I.KeyCode == Enum.KeyCode.Escape and "None" or I.KeyCode.Name)
			end
			return
		end
		if Processed or Obj.Locked then return end
		if I.UserInputType == Enum.UserInputType.Keyboard and Obj.Value ~= "None" and I.KeyCode.Name == Obj.Value then
			Call(O.Callback, I.KeyCode.Name)
		end
	end)

	local Init = O.Value
	if Init == nil then Init = O.Default end
	Obj:Set(Init or "None", true)
	return self:_Finish(O, Obj, C)
end

function Elements:Colorpicker(O)
	O = O or {}
	local C = self:_Card(O, 44, false)
	local Default = O.Default or Theme.Violet
	local H, S, V = Default:ToHSV()
	local Alpha = O.Transparency or 0
	local HasAlpha = O.Transparency ~= nil
	local Obj = { Value = Default, Transparency = Alpha }
	local Open = false
	local PH = 110
	local TotalH = PH + (HasAlpha and 22 or 0)

	local Swatch = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(36, 22),
		BackgroundColor3 = Default, BorderSizePixel = 0, AutoButtonColor = false, Text = "",
	}, C.Head)
	Corner(Swatch, 7)
	Stroke(Swatch, White, 1, 0.7)

	local Holder = New("Frame", {
		LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, ClipsDescendants = true, Visible = false,
	}, C.Card)

	local SV = New("Frame", { Size = UDim2.new(1, -30, 0, PH), BackgroundColor3 = Color3.fromHSV(H, 1, 1), BorderSizePixel = 0 }, Holder)
	Corner(SV, 6)
	local WhiteOv = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = White, BorderSizePixel = 0 }, SV)
	Corner(WhiteOv, 6)
	New("UIGradient", { Transparency = NumberSequence.new(0, 1) }, WhiteOv)
	local BlackOv = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0 }, SV)
	Corner(BlackOv, 6)
	New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }, BlackOv)
	local Cursor = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3,
	}, SV)
	Corner(Cursor, 6)
	Stroke(Cursor, White, 2)

	local HueBar = New("Frame", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(20, PH),
		BackgroundColor3 = White, BorderSizePixel = 0,
	}, Holder)
	Corner(HueBar, 6)
	local Keys = {}
	for I = 0, 6 do table.insert(Keys, ColorSequenceKeypoint.new(I / 6, Color3.fromHSV(I / 6, 1, 1))) end
	New("UIGradient", { Rotation = 90, Color = ColorSequence.new(Keys) }, HueBar)
	local HueCur = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(1, 4, 0, 4),
		BackgroundColor3 = White, BorderSizePixel = 0, ZIndex = 3,
	}, HueBar)
	Corner(HueCur, 2)
	Stroke(HueCur, Color3.new(0, 0, 0), 1, 0.5)

	local AlphaBar, AlphaCur, AlphaGrad
	if HasAlpha then
		AlphaBar = New("Frame", {
			Position = UDim2.fromOffset(0, PH + 8), Size = UDim2.new(1, 0, 0, 14), BackgroundColor3 = White, BorderSizePixel = 0,
		}, Holder)
		Corner(AlphaBar, 6)
		AlphaGrad = Gradient(AlphaBar, Default, Theme.Bg, 0)
		AlphaCur = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(0, 4, 1, 4),
			BackgroundColor3 = White, BorderSizePixel = 0, ZIndex = 3,
		}, AlphaBar)
		Corner(AlphaCur, 2)
		Stroke(AlphaCur, Color3.new(0, 0, 0), 1, 0.5)
	end

	local function Render()
		SV.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
		Cursor.Position = UDim2.fromScale(S, 1 - V)
		HueCur.Position = UDim2.fromScale(0.5, H)
		Swatch.BackgroundColor3 = Obj.Value
		if HasAlpha then
			AlphaGrad.Color = ColorSequence.new(Obj.Value, Theme.Bg)
			AlphaCur.Position = UDim2.fromScale(Alpha, 0.5)
		end
	end
	local function Apply(Silent)
		Obj.Value = Color3.fromHSV(H, S, V)
		Obj.Transparency = Alpha
		Render()
		if not Silent then
			if HasAlpha then Call(O.Callback, Obj.Value, Alpha) else Call(O.Callback, Obj.Value) end
		end
	end

	function Obj:Set(Col, Transp, Silent)
		if typeof(Col) ~= "Color3" then return end
		if type(Transp) == "number" then Alpha = Transp elseif type(Transp) == "boolean" then Silent = Transp end
		H, S, V = Col:ToHSV()
		Apply(Silent)
	end

	MakeDrag(self.Win, SV, function(P)
		S = math.clamp((P.X - SV.AbsolutePosition.X) / math.max(SV.AbsoluteSize.X, 1), 0, 1)
		V = 1 - math.clamp((P.Y - SV.AbsolutePosition.Y) / math.max(SV.AbsoluteSize.Y, 1), 0, 1)
		Apply()
	end, self.Page)
	MakeDrag(self.Win, HueBar, function(P)
		H = math.clamp((P.Y - HueBar.AbsolutePosition.Y) / math.max(HueBar.AbsoluteSize.Y, 1), 0, 0.999)
		Apply()
	end, self.Page)
	if HasAlpha then
		MakeDrag(self.Win, AlphaBar, function(P)
			Alpha = math.clamp((P.X - AlphaBar.AbsolutePosition.X) / math.max(AlphaBar.AbsoluteSize.X, 1), 0, 1)
			Apply()
		end, self.Page)
	end

	local function SetOpen(Val)
		Open = Val
		if Val then
			Holder.Visible = true
			Tween(Holder, 0.25, { Size = UDim2.new(1, 0, 0, TotalH) })
		else
			Tween(Holder, 0.2, { Size = UDim2.new(1, 0, 0, 0) })
			task.delay(0.22, function()
				if not Open and Holder.Parent then Holder.Visible = false end
			end)
		end
	end
	function Obj:Open() SetOpen(true) end
	function Obj:Close() SetOpen(false) end
	Swatch.MouseButton1Click:Connect(function() SetOpen(not Open) end)

	Render()
	if O.Default ~= nil then
		if HasAlpha then Call(O.Callback, Obj.Value, Alpha) else Call(O.Callback, Obj.Value) end
	end
	return self:_Finish(O, Obj, C)
end

function Elements:Paragraph(O)
	O = O or {}
	local C = self:_Card({ Title = O.Title, Desc = O.Desc, Icon = O.Image or O.Icon, IconSize = O.ImageSize or 30 }, 0, false)
	local Obj = {}

	local Col = type(O.Color) == "string" and ParagraphColors[O.Color] or (typeof(O.Color) == "Color3" and O.Color) or nil
	if Col then
		C.Base.Bg = Theme.Card:Lerp(Col, 0.14)
		C.Base.Stroke = Col
		C.Card.BackgroundColor3 = C.Base.Bg
		C.Stroke.Color = Col
	end

	local Thumb
	local function MakeThumb(Image, Size)
		if not Image or Image == "" then
			if Thumb then Thumb.Visible = false end
			return
		end
		if not Thumb then
			Thumb = New("ImageLabel", {
				LayoutOrder = 2, Size = UDim2.new(1, 0, 0, Size or 80), BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0,
				ScaleType = Enum.ScaleType.Crop,
			}, C.Card)
			Corner(Thumb, 8)
		end
		Thumb.Visible = true
		Thumb.Size = UDim2.new(1, 0, 0, Size or 80)
		SetLucide(Thumb, Image)
	end
	MakeThumb(O.Thumbnail, O.ThumbnailSize)

	if O.Buttons and #O.Buttons > 0 then
		local Row = New("Frame", { LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1 }, C.Card)
		List(Row, 6, { FillDirection = Enum.FillDirection.Horizontal, Wraps = true })
		for I, B in ipairs(O.Buttons) do
			local Btn = New("TextButton", {
				LayoutOrder = I, Size = UDim2.fromOffset(0, 28), AutomaticSize = AutoX, BackgroundColor3 = Theme.CardHover,
				BorderSizePixel = 0, AutoButtonColor = false, Text = "",
			}, Row)
			Corner(Btn, 8)
			Stroke(Btn, Theme.Stroke, 1)
			Pad(Btn, 10, 0, 10, 0)
			local Inner = New("Frame", { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AutoX, BackgroundTransparency = 1 }, Btn)
			List(Inner, 6, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center })
			if B.Icon then
				local Wrap = New("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1 }, Inner)
				IconLabel(Wrap, B.Icon, 14, Theme.Violet, { Position = UDim2.fromOffset(0, 0) }, "•")
			end
			New("TextLabel", {
				LayoutOrder = 2, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AutoX, BackgroundTransparency = 1,
				Text = B.Title or "Button", TextColor3 = Theme.Text, TextSize = 11, Font = FontBold,
			}, Inner)
			Btn.MouseButton1Click:Connect(function() Call(B.Callback) end)
		end
	end

	function Obj:SetImage(Image, Size)
		if C.Icon then SetLucide(C.Icon, Image) end
	end
	function Obj:SetThumbnail(Image, Size) MakeThumb(Image, Size) end
	return self:_Finish(O, Obj, C)
end

function Elements:Code(O)
	O = O or {}
	local C = self:_Card({ Title = O.Title or "Code", Icon = O.Icon }, 60, false)
	local Obj = { Value = O.Code or "" }
	local Block = New("Frame", {
		LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundColor3 = Theme.Bg, BorderSizePixel = 0,
	}, C.Card)
	Corner(Block, 8)
	Pad(Block, 10, 8, 10, 8)
	local Lbl = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, Text = Obj.Value, TextColor3 = Theme.Cyan,
		TextSize = 12, Font = Enum.Font.Code, TextWrapped = true, TextXAlignment = Left, TextYAlignment = Enum.TextYAlignment.Top,
	}, Block)
	local Copy = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(56, 24),
		BackgroundColor3 = Theme.CardHover, BorderSizePixel = 0, AutoButtonColor = false, Text = "COPY", TextColor3 = Theme.Text,
		TextSize = 10, Font = FontBold,
	}, C.Head)
	Corner(Copy, 8)
	Stroke(Copy, Theme.Stroke, 1)
	Copy.MouseButton1Click:Connect(function()
		CopyText(Obj.Value)
		Copy.Text = "COPIED"
		task.delay(1.2, function()
			if Copy.Parent then Copy.Text = "COPY" end
		end)
		Call(O.OnCopy)
	end)
	function Obj:SetCode(T)
		Obj.Value = T
		Lbl.Text = T
	end
	return self:_Finish(O, Obj, C)
end

function Elements:Divider()
	local F = New("Frame", { LayoutOrder = self:_Next(), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = White, BorderSizePixel = 0 }, self.Parent)
	New("UIGradient", { Color = ColorSequence.new(Theme.Violet, Theme.Cyan), Transparency = NumberSequence.new(0.3, 1) }, F)
	return F
end

function Elements:Space(O)
	local H = type(O) == "number" and O or (type(O) == "table" and O.Size) or ((type(O) == "table" and O.Columns or 1) * 8)
	return New("Frame", { LayoutOrder = self:_Next(), Size = UDim2.new(1, 0, 0, H), BackgroundTransparency = 1 }, self.Parent)
end

function Elements:Section(O)
	if type(O) == "string" then O = { Title = O } end
	O = O or {}
	local Wrap = New("Frame", { LayoutOrder = self:_Next(), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1 }, self.Parent)
	List(Wrap, 8)

	local Align = ({ Left = Left, Center = Enum.TextXAlignment.Center, Right = Right })[O.TextXAlignment or "Left"] or Left
	local Header = New("TextButton", {
		LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
	}, Wrap)
	local TX = 0
	if O.Icon then
		IconLabel(Header, O.Icon, 16, Theme.Violet, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0) }, "•")
		TX = 24
	end
	local Lbl = New("TextLabel", {
		Position = UDim2.fromOffset(TX, 0), Size = UDim2.new(1, -(TX + 24), 1, 0), BackgroundTransparency = 1, RichText = true,
		Text = O.Title or "Section", TextColor3 = Theme.Text, TextTransparency = O.TextTransparency or 0.05,
		TextSize = O.TextSize or 15, Font = FontBold, TextXAlignment = Align,
	}, Header)
	local Chev = IconLabel(Header, "chevron-down", 14, Theme.Muted, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0) }, "v")

	local Body = New("Frame", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1 }, Wrap)
	if O.Box then
		Body.BackgroundTransparency = 0.3
		Body.BackgroundColor3 = Theme.Bg2
		Corner(Body, 12)
		Stroke(Body, Theme.Stroke, 1)
		Pad(Body, 8, 8, 8, 8)
	end
	List(Body, 8)

	local Sec = setmetatable({ Win = self.Win, Parent = Body, Page = self.Page, _n = 0 }, SectionClass)
	local IsOpen = true
	function Sec:SetOpen(Val)
		IsOpen = Val
		Body.Visible = Val
		Tween(Chev, 0.2, { Rotation = Val and 0 or -90 })
	end
	function Sec:Open() Sec:SetOpen(true) end
	function Sec:Close() Sec:SetOpen(false) end
	function Sec:SetTitle(T) Lbl.Text = T end
	function Sec:Destroy() Wrap:Destroy() end
	Header.MouseButton1Click:Connect(function() Sec:SetOpen(not IsOpen) end)
	if O.Opened == false then Sec:SetOpen(false) end
	return Sec
end

function TabClass:Select(Instant)
	local Win = self.Win
	if self.Locked then return end
	for _, T in ipairs(Win.Tabs) do
		if T ~= self then T:_SetActive(false) end
	end
	self:_SetActive(true, Instant)
	Win.CurrentTab = self
end

function Window:_NextSide()
	self._side += 1
	return self._side
end

local function ShowIcon(Img, Fallback, On)
	if not Img then return end
	Img.Visible = On
	if Fallback then Fallback.Visible = On and Img.Image == "" end
end

function Window:_MakeTab(O, ParentFrame)
	if type(O) == "string" then O = { Title = O } end
	O = O or {}
	local WinRef = self
	local LockTitle = "Locked"
	if O.LockTitle ~= nil then LockTitle = tostring(O.LockTitle) elseif O.LockedTitle ~= nil then LockTitle = tostring(O.LockedTitle) end
	local Tab = setmetatable({ Win = self, _n = 0, Title = O.Title or "Tab", Locked = false, LockTitle = LockTitle }, TabClass)

	local Btn = New("TextButton", {
		LayoutOrder = self:_NextSide(), Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, BorderSizePixel = 0,
		AutoButtonColor = false, Text = "",
	}, ParentFrame)
	Corner(Btn, 10)
	local ActiveFill = New("Frame", {
		Position = UDim2.fromOffset(1, 1), Size = UDim2.new(1, -2, 1, -2), BackgroundColor3 = White, BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, Btn)
	Corner(ActiveFill, 9)
	Gradient(ActiveFill, Theme.Violet, Theme.Blue, 20)
	local ActStroke = Stroke(ActiveFill, Theme.Violet, 1, 1)

	local IconRight = O.IconAlign == "Right"
	local Ico, IcoFB
	local TextL = 12
	if O.Icon then
		if IconRight then
			Ico, IcoFB = IconLabel(Btn, O.Icon, 16, Theme.Muted, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -11, 0.5, 0) }, "•")
		else
			Ico, IcoFB = IconLabel(Btn, O.Icon, 16, Theme.Muted, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 11, 0.5, 0) }, "•")
			TextL = 35
		end
	end
	local LockIco, LockFB = IconLabel(Btn, "lock", 14, Theme.Amber, {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -11, 0.5, 0), Visible = false,
	}, "•")

	local Lbl = New("TextLabel", {
		Position = UDim2.fromOffset(TextL, 0), Size = UDim2.new(1, -(TextL + 10), 1, 0), BackgroundTransparency = 1,
		Text = Tab.Title, TextColor3 = Theme.Muted, TextSize = 12, Font = FontBold, TextXAlignment = Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, Btn)

	local function Reflow()
		local R = 10
		if (Ico and IconRight) or Tab.Locked then R = 36 end
		Lbl.Size = UDim2.new(1, -(TextL + R), 1, 0)
	end
	Reflow()

	local Page = New("ScrollingFrame", {
		Name = "Page_" .. Tab.Title, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Violet, CanvasSize = UDim2.new(), AutomaticCanvasSize = AutoY,
		ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false, Active = true,
	}, self.Content)
	Pad(Page, 3, 3, 12, 3)
	List(Page, 8)

	Tab.Parent, Tab.Page, Tab.TabButton = Page, Page, Btn

	local Selected = false
	function Tab:_SetActive(On, Instant)
		Selected = On
		Tween(ActiveFill, 0.2, { BackgroundTransparency = On and 0.78 or 1 })
		Tween(ActStroke, 0.2, { Transparency = On and 0.4 or 1 })
		Tween(Lbl, 0.2, { TextColor3 = On and Theme.Text or Theme.Muted })
		if Ico then Tween(Ico, 0.2, { ImageColor3 = On and Theme.Violet or Theme.Muted }) end
		if On then
			Page.Visible = true
			if not Instant and WinRef._moving ~= false then
				Page.Position = UDim2.fromOffset(0, 12)
				Tween(Page, 0.3, { Position = UDim2.fromOffset(0, 0) })
			end
		else
			Page.Visible = false
		end
	end
	function Tab:Lock(Title)
		Tab.Locked = true
		if Title ~= nil then Tab.LockTitle = tostring(Title) end
		Lbl.TextTransparency = 0.5
		if IconRight then ShowIcon(Ico, IcoFB, false) end
		ShowIcon(LockIco, LockFB, true)
		Reflow()
	end
	function Tab:Unlock()
		Tab.Locked = false
		Lbl.TextTransparency = 0
		ShowIcon(LockIco, LockFB, false)
		if IconRight then ShowIcon(Ico, IcoFB, true) end
		Reflow()
	end
	function Tab:SetTitle(T)
		Tab.Title = T
		Lbl.Text = T
	end
	function Tab:SetLockTitle(T) Tab.LockTitle = tostring(T or "") end
	function Tab:Destroy()
		local I = table.find(self.Win.Tabs, Tab)
		if I then table.remove(self.Win.Tabs, I) end
		if self.Win.CurrentTab == Tab then self.Win.CurrentTab = nil end
		Page:Destroy()
		Btn:Destroy()
	end
	if O.Locked == true then Tab:Lock() end

	Btn.MouseEnter:Connect(function()
		if Tab.Locked then return end
		if not Selected then
			Tween(Lbl, 0.15, { TextColor3 = Theme.Text })
			Tween(ActiveFill, 0.15, { BackgroundTransparency = 0.92 })
		end
	end)
	Btn.MouseLeave:Connect(function()
		if Tab.Locked then return end
		if not Selected then
			Tween(Lbl, 0.15, { TextColor3 = Theme.Muted })
			Tween(ActiveFill, 0.15, { BackgroundTransparency = 1 })
		end
	end)
	Btn.MouseButton1Click:Connect(function()
		if Tab.Locked then
			Library:Notify({
				Title = Tab.Title, Content = Tab.LockTitle ~= "" and Tab.LockTitle or "Locked", Icon = "lock", Type = "warn", Duration = 2.5,
			})
			return
		end
		Tab:Select()
	end)

	table.insert(self.Tabs, Tab)
	if not self.CurrentTab and not Tab.Locked then Tab:Select(true) end
	return Tab
end

function Window:Tab(O) return self:_MakeTab(O, self.Sidebar) end

function Window:Section(O)
	if type(O) == "string" then O = { Title = O } end
	O = O or {}
	local Wrap = New("Frame", { LayoutOrder = self:_NextSide(), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1 }, self.Sidebar)
	List(Wrap, 4)
	local Header = New("TextButton", { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, Wrap)
	local TX = 6
	if O.Icon then
		IconLabel(Header, O.Icon, 14, Theme.Muted, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0) }, "•")
		TX = 26
	end
	New("TextLabel", {
		Position = UDim2.fromOffset(TX, 0), Size = UDim2.new(1, -(TX + 28), 1, 0), BackgroundTransparency = 1, Text = string.upper(StripRich(O.Title or "SECTION")),
		TextColor3 = Theme.Muted, TextSize = 10, Font = FontBold, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, Header)
	local Chev = IconLabel(Header, "chevron-down", 14, Theme.Muted, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0) }, "v")
	local Body = New("Frame", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1 }, Wrap)
	List(Body, 4)

	local Sec = setmetatable({ Win = self }, SideSection)
	local IsOpen = O.Opened ~= false
	function Sec:Tab(TO) return self.Win:_MakeTab(TO, Body) end
	function Sec:SetOpen(Val)
		IsOpen = Val
		Body.Visible = Val
		Tween(Chev, 0.2, { Rotation = Val and 0 or -90 })
	end
	Header.MouseButton1Click:Connect(function() Sec:SetOpen(not IsOpen) end)
	Sec:SetOpen(IsOpen)
	return Sec
end

function Window:Divider()
	local F = New("Frame", { LayoutOrder = self:_NextSide(), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = White, BorderSizePixel = 0 }, self.Sidebar)
	New("UIGradient", { Color = ColorSequence.new(Theme.Violet, Theme.Cyan), Transparency = NumberSequence.new(0.3, 1) }, F)
	return F
end

function Window:Space(O)
	return New("Frame", { LayoutOrder = self:_NextSide(), Size = UDim2.new(1, 0, 0, type(O) == "number" and O or 8), BackgroundTransparency = 1 }, self.Sidebar)
end

function Window:SelectTab(Index)
	local T = self.Tabs[Index]
	if T then T:Select() end
end

function Window:SetStatus() end

function Window:Open()
	if self.Destroyed or not self.Hidden then return end
	self.Hidden = false
	self.Root.Visible = true
	self.Bubble.Visible = false
	Call(self._onOpen)
end

function Window:Close()
	if self.Destroyed or self.Hidden then return end
	self.Hidden = true
	self.Root.Visible = false
	self.Bubble.Visible = self._openButton
	Call(self._onClose)
end

function Window:Toggle()
	if self.Hidden then self:Open() else self:Close() end
end

function Window:SetToggleKey(Key) self.ToggleKey = Key end
function Window:OnClose(Fn) self._onClose = Fn end
function Window:OnOpen(Fn) self._onOpen = Fn end
function Window:OnDestroy(Fn) self._onDestroy = Fn end

function Window:EditOpenButton(O)
	O = O or {}
	if O.Enabled ~= nil then
		self._openButton = O.Enabled
		if self.Hidden then self.Bubble.Visible = O.Enabled end
	end
	if O.Icon then SetLucide(self.BubbleImg, O.Icon, self.BubbleFB) end
end

function Window:SetTitle(T)
	self.TitleLabel.Text = T
end

function Window:SetAuthor(T)
	self.AuthorLabel.Text = T
end

function Window:Tag(O)
	O = O or {}
	local Col = O.Color or Theme.Violet
	local Tag = New("Frame", {
		LayoutOrder = #self.TagFrame:GetChildren(), Size = UDim2.fromOffset(0, 24), AutomaticSize = AutoX,
		BackgroundColor3 = Col, BackgroundTransparency = 0.8, BorderSizePixel = 0,
	}, self.TagFrame)
	Corner(Tag, math.clamp(O.Radius or 8, 0, 12))
	Stroke(Tag, Col, 1, 0.5)
	Pad(Tag, 8, 0, 8, 0)
	List(Tag, 5, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center })
	if O.Icon then
		local Wrap = New("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1 }, Tag)
		IconLabel(Wrap, O.Icon, 12, Col, nil, "•")
	end
	local Lbl = New("TextLabel", {
		LayoutOrder = 2, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AutoX, BackgroundTransparency = 1,
		Text = O.Title or "Tag", TextColor3 = Col:Lerp(White, 0.3), TextSize = 10, Font = FontBold,
	}, Tag)
	local Obj = {}
	function Obj:SetTitle(T) Lbl.Text = T end
	function Obj:Destroy() Tag:Destroy() end
	return Obj
end

function Window:Notify(O) return Library:Notify(O) end

function Window:Dialog(O)
	local D = BuildDialog(self.Host, O)
	D:Show()
	return D
end

function Window:LockAll() for _, E in ipairs(self._Elements) do E:Lock() end end
function Window:UnlockAll() for _, E in ipairs(self._Elements) do E:Unlock() end end
function Window:GetLocked()
	local L = {}
	for _, E in ipairs(self._Elements) do if E.Locked then table.insert(L, E) end end
	return L
end
function Window:GetUnlocked()
	local L = {}
	for _, E in ipairs(self._Elements) do if not E.Locked then table.insert(L, E) end end
	return L
end
function Window:GetAllElements() return self._Elements end

function Window:SaveConfig(Name)
	Name = Name or "default"
	local Cfg = self.ConfigManager.Configs[Name] or self.ConfigManager:CreateConfig(Name)
	return Cfg:Save()
end

function Window:LoadConfig(Name)
	Name = Name or "default"
	local Cfg = self.ConfigManager.Configs[Name] or self.ConfigManager:CreateConfig(Name)
	return Cfg:Load()
end

function Window:DeleteConfig(Name)
	return self.ConfigManager:DeleteConfig(Name)
end

function Window:GetConfigs()
	return self.ConfigManager:AllConfigs()
end

function Window:SetMovingAnimation(V)
	self._moving = V ~= false
	if not self._moving and self._resetMotion then self._resetMotion() end
end

function Window:SetParticles(V)
	self._particles = V ~= false
	if self._applyParticles then self._applyParticles() end
end

function Window:Destroy()
	if self.Destroyed then return end
	self.Destroyed = true
	Call(self._onDestroy)
	for _, C in ipairs(self.Connections) do pcall(function() C:Disconnect() end) end
	local Ok, T = pcall(Tween, self.RootScale, 0.25, { Scale = 0.8 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	local function Kill() pcall(function() self.Gui:Destroy() end) end
	if Ok and T then T.Completed:Connect(Kill) else Kill() end
end

local function MakeConfigManager(Win)
	local CM = { Configs = {} }
	local Dir = "ToolkitUI/" .. Win.Folder .. "/config"
	local HasList = type(listfiles) == "function" and type(isfile) == "function"
	local CanWrite = type(writefile) == "function" and type(readfile) == "function"

	local function Ensure()
		pcall(function()
			if makefolder and isfolder then
				for _, P in ipairs({ "ToolkitUI", "ToolkitUI/" .. Win.Folder, Dir }) do
					if not isfolder(P) then makefolder(P) end
				end
			end
		end)
	end

	function CM:Sanitize(Name)
		Name = tostring(Name or ""):gsub("[^%w%-_ ]", ""):gsub("^%s+", ""):gsub("%s+$", "")
		return Name:sub(1, 32)
	end

	function CM:ConfigPath(Name)
		return Dir .. "/" .. Name .. ".json"
	end

	function CM:ConfigExists(Name)
		Name = CM:Sanitize(Name)
		if Name == "" then return false end
		if HasList then
			local Ok, R = pcall(isfile, CM:ConfigPath(Name))
			return Ok and R == true
		end
		return CM.Configs[Name] ~= nil
	end

	function CM:CreateConfig(Name)
		Name = CM:Sanitize(Name)
		if Name == "" then Name = "default" end
		if CM.Configs[Name] then return CM.Configs[Name] end

		local Cfg = { Name = Name, Registered = {}, Memory = nil }
		local Path = CM:ConfigPath(Name)

		function Cfg:Register(Key, Element) Cfg.Registered[Key] = Element end

		local function All()
			local T = {}
			for K, E in pairs(Win.FlagElements) do T[K] = E end
			for K, E in pairs(Cfg.Registered) do T[K] = E end
			return T
		end

		function Cfg:Save()
			local Data = {}
			for K, E in pairs(All()) do
				if E.Value ~= nil then Data[K] = Ser(E.Value) end
			end
			if not CanWrite then
				Cfg.Memory = Data
				return true
			end
			Ensure()
			return (pcall(function() writefile(Path, HttpService:JSONEncode(Data)) end))
		end

		function Cfg:Load()
			local Data
			if CanWrite then
				local Ok, Result = pcall(function() return HttpService:JSONDecode(readfile(Path)) end)
				if Ok then Data = Result end
			else
				Data = Cfg.Memory
			end
			if type(Data) ~= "table" then return false end
			local Els = All()
			for K, V in pairs(Data) do
				local E = Els[K]
				if E then pcall(function() if E.Select then E:Select(Deser(V)) else E:Set(Deser(V)) end end) end
			end
			return true
		end

		function Cfg:Exists() return CM:ConfigExists(Name) end
		function Cfg:Delete() return CM:DeleteConfig(Name) end

		CM.Configs[Name] = Cfg
		return Cfg
	end

	function CM:GetConfig(Name)
		return CM.Configs[CM:Sanitize(Name)]
	end

	function CM:DeleteConfig(Name)
		Name = CM:Sanitize(Name)
		if Name == "" then return false end
		local Path = CM:ConfigPath(Name)
		pcall(function()
			if delfile and isfile and isfile(Path) then delfile(Path) end
		end)
		CM.Configs[Name] = nil
		return not CM:ConfigExists(Name)
	end

	function CM:AllConfigs()
		local L, Seen = {}, {}
		if HasList then
			pcall(function()
				for _, F in ipairs(listfiles(Dir)) do
					local N = F:match("([^/\\]+)%.json$")
					if N and not Seen[N] then
						Seen[N] = true
						table.insert(L, N)
					end
				end
			end)
		else
			for N in pairs(CM.Configs) do table.insert(L, N) end
		end
		table.sort(L, function(A, B) return A:lower() < B:lower() end)
		return L
	end

	return CM
end

local function BuildKeyGate(Win, KS)
	local Keys = type(KS.Key) == "table" and KS.Key or { KS.Key }
	local KeyFile = "ToolkitUI/" .. Win.Folder .. "/key.txt"
	local function Valid(K)
		for _, V in ipairs(Keys) do
			if tostring(V) == K then return true end
		end
		return false
	end

	local Gate = New("Frame", {
		Name = "KeyGate", Size = UDim2.fromScale(1, 1), BackgroundColor3 = White, BorderSizePixel = 0, ZIndex = 90, Active = true,
	}, Win.Main)
	Corner(Gate, MAIN_RADIUS)
	Gradient(Gate, Theme.Bg2, Theme.Bg, 135)

	local Box = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 320, 0, 0),
		AutomaticSize = AutoY, BackgroundTransparency = 1, ZIndex = 91,
	}, Gate)
	List(Box, 10, { HorizontalAlignment = Enum.HorizontalAlignment.Center })

	local TI = 1
	if KS.Thumbnail and KS.Thumbnail.Image then
		local Img = New("ImageLabel", {
			LayoutOrder = TI, Size = UDim2.fromOffset(64, 64), BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0, ScaleType = Enum.ScaleType.Crop, ZIndex = 91,
		}, Box)
		Corner(Img, 14)
		SetLucide(Img, KS.Thumbnail.Image)
		TI += 1
	end
	New("TextLabel", {
		LayoutOrder = TI, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Text = (KS.Thumbnail and KS.Thumbnail.Title) or "KEY SYSTEM",
		TextColor3 = White, TextSize = 18, Font = FontBlack, ZIndex = 91,
	}, Box)
	New("TextLabel", {
		LayoutOrder = TI + 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, Text = KS.Note or "Enter your key to continue.",
		TextColor3 = Theme.Muted, TextSize = 12, Font = FontMed, TextWrapped = true, ZIndex = 91,
	}, Box)

	local Pill = New("Frame", { LayoutOrder = TI + 2, Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0, ZIndex = 91 }, Box)
	Corner(Pill, 10)
	local PS = Stroke(Pill, Theme.Stroke, 1)
	local TB = New("TextBox", {
		Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = "Enter key...",
		PlaceholderColor3 = Theme.Muted, TextColor3 = Theme.Text, TextSize = 13, Font = FontMed, ClearTextOnFocus = false, TextXAlignment = Left, ZIndex = 92,
	}, Pill)

	local StatusL = New("TextLabel", {
		LayoutOrder = TI + 3, Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Text = "", TextColor3 = Theme.Muted,
		TextSize = 11, Font = FontMed, ZIndex = 91,
	}, Box)

	local Row = New("Frame", { LayoutOrder = TI + 4, Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, ZIndex = 91 }, Box)
	List(Row, 8, { FillDirection = Enum.FillDirection.Horizontal })

	local function Unlock(K)
		if KS.SaveKey then
			pcall(function()
				if makefolder and isfolder then
					for _, P in ipairs({ "ToolkitUI", "ToolkitUI/" .. Win.Folder }) do
						if not isfolder(P) then makefolder(P) end
					end
				end
				writefile(KeyFile, K)
			end)
		end
		Win._Unlocked = true
		Tween(Gate, 0.3, { BackgroundTransparency = 1 })
		for _, D in ipairs(Gate:GetDescendants()) do
			pcall(function()
				if D:IsA("TextLabel") or D:IsA("TextButton") or D:IsA("TextBox") then Tween(D, 0.25, { TextTransparency = 1 }) end
				if D:IsA("ImageLabel") then Tween(D, 0.25, { ImageTransparency = 1 }) end
				if D:IsA("Frame") then Tween(D, 0.25, { BackgroundTransparency = 1 }) end
			end)
		end
		task.delay(0.35, function() Gate:Destroy() end)
	end

	local function Check()
		local K = TB.Text:gsub("%s+", "")
		if Valid(K) then
			StatusL.Text = "Key accepted!"
			StatusL.TextColor3 = Theme.Green
			Unlock(K)
		else
			StatusL.Text = "Invalid key"
			StatusL.TextColor3 = Theme.Red
			Tween(PS, 0.2, { Color = Theme.Red })
			task.delay(1, function()
				if PS.Parent then Tween(PS, 0.3, { Color = Theme.Stroke }) end
			end)
		end
	end

	if KS.URL then
		local Get = New("TextButton", {
			LayoutOrder = 1, Size = UDim2.new(0.5, -4, 1, 0), BackgroundColor3 = Color3.fromRGB(36, 33, 60), BorderSizePixel = 0,
			AutoButtonColor = false, Text = "GET KEY", TextColor3 = Theme.Text, TextSize = 12, Font = FontBold, ZIndex = 92,
		}, Row)
		Corner(Get, 10)
		Stroke(Get, Theme.Stroke, 1.2)
		Get.MouseButton1Click:Connect(function()
			local Ok = CopyText(KS.URL)
			StatusL.Text = Ok and "Key link copied" or "Copy failed"
			StatusL.TextColor3 = Ok and Theme.Cyan or Theme.Red
		end)
	end
	local Submit, SH = GradButton(Row, "SUBMIT", UDim2.new(KS.URL and 0.5 or 1, KS.URL and -4 or 0, 1, 0), UDim2.new(), Theme.Violet, Theme.Blue, 12)
	SH.LayoutOrder = 2
	SH.ZIndex = 92
	Submit.ZIndex = 93
	Submit.MouseButton1Click:Connect(Check)
	TB.FocusLost:Connect(function(Enter) if Enter then Check() end end)

	if KS.SaveKey then
		local Ok, Saved = pcall(function() return isfile and isfile(KeyFile) and readfile(KeyFile) end)
		if Ok and type(Saved) == "string" then
			local Clean = Saved:gsub("%s+", "")
			if Valid(Clean) then task.defer(function() Unlock(Clean) end) end
		end
	end
end

function Library:CreateWindow(O)
	O = O or {}

	local Size = typeof(O.Size) == "UDim2" and O.Size or UDim2.fromOffset(600, 400)
	local BASE_W, BASE_H = Size.X.Offset, Size.Y.Offset
	local SBW = math.clamp(O.SideBarWidth or 160, 120, math.floor(BASE_W * 0.4))
	local FolderName = O.Folder or O.ConfigFolder or "ToolkitUI"
	local Name = "ToolkitUI_" .. FolderName
	local UserCfg = type(O.User) == "table" and O.User.Enabled and O.User or nil
	local PlainTitle = StripRich(O.Title or "ToolkitUI")

	local Win = setmetatable({
		Connections = {}, Tabs = {}, Destroyed = false, Hidden = false, _side = 0, _Elements = {}, FlagElements = {},
		Folder = FolderName, ToggleKey = O.ToggleKey or Enum.KeyCode.RightShift, _openButton = true,
		_moving = O.MovingAnimation ~= false, _particles = O.Particles ~= false,
	}, Window)

	pcall(function()
		local Containers = { CoreGui }
		local PG = LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if PG then table.insert(Containers, PG) end
		if gethui then
			local Ok, Hui = pcall(gethui)
			if Ok and Hui then table.insert(Containers, Hui) end
		end
		for _, C in ipairs(Containers) do
			local Old = C:FindFirstChild(Name)
			if Old then Old:Destroy() end
		end
	end)

	local Gui = New("ScreenGui", {
		Name = Name, ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	ParentGui(Gui)
	Win.Gui = Gui

	local function ComputeScale()
		local Cam = workspace.CurrentCamera
		local Vp = Cam and Cam.ViewportSize or Vector2.new(1280, 720)
		return math.clamp(math.min((Vp.X - 24) / BASE_W, (Vp.Y - 24) / BASE_H), 0.5, 1.1)
	end
	local TargetScale = ComputeScale()

	local Root = New("Frame", {
		Name = "Root", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(BASE_W, BASE_H), BackgroundTransparency = 1,
	}, Gui)
	local RootScale = New("UIScale", { Scale = TargetScale * 0.85 }, Root)
	Win.Root, Win.RootScale = Root, RootScale

	New("ImageLabel", {
		Name = "Glow", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 70, 1, 70), Image = "rbxassetid://6014261993", ImageColor3 = Theme.Violet, ImageTransparency = 0.55,
		ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), ZIndex = 1,
	}, Root)

	local Main = New("Frame", {
		Name = "Main", Size = UDim2.fromScale(1, 1), BackgroundColor3 = White, BackgroundTransparency = O.Transparent and 0.12 or 0,
		BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 2, Active = true,
	}, Root)
	Corner(Main, MAIN_RADIUS)
	Gradient(Main, Theme.Bg2, Theme.Bg, 135)
	local BorderStroke = Stroke(Main, White, 1.5, 0.1)
	local BorderGrad = New("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Theme.Violet), ColorSequenceKeypoint.new(0.33, Theme.Cyan),
			ColorSequenceKeypoint.new(0.66, Theme.Pink), ColorSequenceKeypoint.new(1, Theme.Violet),
		}),
	}, BorderStroke)
	Win.Main = Main

	local Background = New("CanvasGroup", { Name = "Background", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1 }, Main)
	Corner(Background, MAIN_RADIUS)
	local Orb1 = Orb(Theme.Violet, 0.12, 0.1, 340, 0.72, Background)
	local Orb2 = Orb(Theme.Cyan, 0.95, 0.95, 320, 0.72, Background)
	local Particles = MakeParticles(Background, 14)
	Win._applyParticles = function()
		for _, P in ipairs(Particles) do P.Obj.Visible = Win._particles end
	end
	Win._applyParticles()

	local TopBar = New("Frame", { Name = "TopBar", Size = UDim2.new(1, 0, 0, 54), BackgroundTransparency = 1, ZIndex = 5 }, Main)
	local Logo = New("Frame", {
		Size = UDim2.fromOffset(34, 34), Position = UDim2.fromOffset(14, 10), BackgroundColor3 = White, BorderSizePixel = 0,
	}, TopBar)
	Corner(Logo, 10)
	local LogoGrad = Gradient(Logo, Theme.Violet, Theme.Cyan, 45)
	Stroke(Logo, White, 1, 0.75)
	local LogoImg = New("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.62, 0.62),
		BackgroundTransparency = 1, ImageColor3 = White, ScaleType = Enum.ScaleType.Fit,
	}, Logo)
	local LogoFB = New("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = string.upper(string.sub(PlainTitle, 1, 1)),
		TextColor3 = White, TextSize = 16, Font = FontBlack,
	}, Logo)
	SetLucide(LogoImg, O.Icon or "layout-grid", LogoFB)

	Win.TitleLabel = New("TextLabel", {
		Position = UDim2.fromOffset(58, 8), Size = UDim2.fromOffset(BASE_W - 250, 22), BackgroundTransparency = 1, RichText = true,
		Text = O.Title or "ToolkitUI", TextColor3 = Theme.Text, TextSize = 16, Font = FontBlack, TextXAlignment = Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, TopBar)
	Win.AuthorLabel = New("TextLabel", {
		Position = UDim2.fromOffset(58, 30), Size = UDim2.fromOffset(BASE_W - 250, 14), BackgroundTransparency = 1,
		Text = O.Author or "", TextColor3 = Theme.Muted, TextSize = 10, Font = FontMed, TextXAlignment = Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, TopBar)

	local CloseButton = IconButton(TopBar, "×", UDim2.new(1, -40, 0, 14), Theme.Red)
	local MinButton = IconButton(TopBar, "–", UDim2.new(1, -72, 0, 14), Theme.Violet)

	Win.TagFrame = New("Frame", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -82, 0, 15), Size = UDim2.fromOffset(0, 24),
		AutomaticSize = AutoX, BackgroundTransparency = 1,
	}, TopBar)
	List(Win.TagFrame, 6, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center })

	local function FitTitle()
		local Tw = Win.TagFrame.AbsoluteSize.X / math.max(RootScale.Scale, 0.01)
		local Avail = math.max(BASE_W - 58 - 86 - (Tw > 0 and (Tw + 12) or 6), 40)
		Win.TitleLabel.Size = UDim2.fromOffset(Avail, 22)
		Win.AuthorLabel.Size = UDim2.fromOffset(Avail, 14)
	end
	Win.TagFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(FitTitle)
	FitTitle()

	local Divider = New("Frame", {
		Position = UDim2.fromOffset(14, 53), Size = UDim2.new(1, -28, 0, 1), BackgroundColor3 = White, BorderSizePixel = 0, ZIndex = 5,
	}, Main)
	New("UIGradient", { Color = ColorSequence.new(Theme.Violet, Theme.Cyan), Transparency = NumberSequence.new(0.2, 1) }, Divider)

	local SideBottom = UserCfg and 62 or 12
	local Sidebar = New("ScrollingFrame", {
		Name = "Sidebar", Position = UDim2.fromOffset(8, 60), Size = UDim2.new(0, SBW + 8, 1, -(60 + SideBottom)),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = AutoY, ScrollingDirection = Enum.ScrollingDirection.Y, ClipsDescendants = true, ZIndex = 5, Active = true,
	}, Main)
	Pad(Sidebar, 4, 4, 4, 4)
	List(Sidebar, 4)
	Win.Sidebar = Sidebar

	New("Frame", {
		Position = UDim2.fromOffset(SBW + 20, 68), Size = UDim2.new(0, 1, 1, -(68 + 16)), BackgroundColor3 = Theme.Stroke,
		BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 5,
	}, Main)

	if UserCfg then
		local UC = New("TextButton", {
			Position = UDim2.new(0, 12, 1, -58), Size = UDim2.fromOffset(SBW, 46), BackgroundColor3 = Theme.Card, BorderSizePixel = 0,
			AutoButtonColor = false, Text = "", ZIndex = 5,
		}, Main)
		Corner(UC, 12)
		Stroke(UC, Theme.Stroke, 1)
		local Av = New("ImageLabel", {
			Position = UDim2.fromOffset(8, 7), Size = UDim2.fromOffset(32, 32), BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0,
			Image = UserCfg.Anonymous and "" or ("rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"),
		}, UC)
		Corner(Av, 16)
		New("TextLabel", {
			Position = UDim2.fromOffset(48, 6), Size = UDim2.new(1, -56, 0, 18), BackgroundTransparency = 1,
			Text = UserCfg.Anonymous and "Anonymous" or LocalPlayer.DisplayName, TextColor3 = Theme.Text, TextSize = 12, Font = FontBold,
			TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd,
		}, UC)
		New("TextLabel", {
			Position = UDim2.fromOffset(48, 24), Size = UDim2.new(1, -56, 0, 14), BackgroundTransparency = 1,
			Text = UserCfg.Anonymous and "@anonymous" or ("@" .. LocalPlayer.Name), TextColor3 = Theme.Muted, TextSize = 10, Font = FontMed,
			TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd,
		}, UC)
		UC.MouseButton1Click:Connect(function() Call(UserCfg.Callback) end)
	end

	local Content = New("Frame", {
		Name = "Content", Position = UDim2.fromOffset(SBW + 26, 62), Size = UDim2.new(1, -(SBW + 26 + 12), 1, -(62 + 12)),
		BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 5, Active = true,
	}, Main)
	Win.Content = Content

	local Modal = New("Frame", { Name = "Modal", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 40 }, Main)
	local Dim = New("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
		Active = true, ZIndex = 1,
	}, Modal)
	Corner(Dim, MAIN_RADIUS)
	Win.Modal, Win.Dim = Modal, Dim
	Win.Host = { Modal = Modal, Dim = Dim }

	local Bubble = New("Frame", {
		Size = UDim2.fromOffset(48, 48), Position = UDim2.new(1, -64, 0.5, -24), BackgroundColor3 = White, BorderSizePixel = 0, Visible = false,
		Active = true,
	}, Gui)
	Corner(Bubble, 24)
	Gradient(Bubble, Theme.Violet, Theme.Cyan, 45)
	Stroke(Bubble, White, 1.5, 0.6)
	local BubbleButton = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, Bubble)
	local BubbleImg = New("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(24, 24),
		BackgroundTransparency = 1, ImageColor3 = White,
	}, Bubble)
	local BubbleFB = New("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "≡", TextColor3 = White, TextSize = 20, Font = FontBold,
	}, Bubble)
	SetLucide(BubbleImg, O.Icon or "layout-grid", BubbleFB)
	Win.Bubble, Win.BubbleImg, Win.BubbleFB = Bubble, BubbleImg, BubbleFB

	MakeDraggable(Win, TopBar, Root, function() return RootScale.Scale end, function() return not Modal.Visible end)
	local BubbleMoved = false
	MakeDraggable(Win, BubbleButton, Bubble, function() return 1 end, nil, function() BubbleMoved = true end)

	CloseButton.MouseButton1Click:Connect(function() Win:Destroy() end)
	MinButton.MouseButton1Click:Connect(function() Win:Close() end)
	BubbleButton.MouseButton1Click:Connect(function()
		if BubbleMoved then
			BubbleMoved = false
			return
		end
		Win:Open()
	end)
	Win:Connect(UserInputService.InputBegan, function(I, Processed)
		if Processed or Win.Destroyed then return end
		if I.KeyCode == Win.ToggleKey then Win:Toggle() end
	end)

	Win._resetMotion = function()
		BorderGrad.Rotation = 0
		LogoGrad.Rotation = 45
		Orb1.Position = UDim2.fromScale(0.12, 0.1)
		Orb2.Position = UDim2.fromScale(0.95, 0.95)
	end
	if not Win._moving then Win._resetMotion() end

	local Elapsed, Acc = 0, 0
	Win:Connect(RunService.RenderStepped, function(Dt)
		if Win.Destroyed or Win.Hidden or not Win._moving then return end
		Elapsed += Dt
		BorderGrad.Rotation = (Elapsed * 45) % 360
		LogoGrad.Rotation = (Elapsed * 60) % 360
		Acc += Dt
		if Acc < 1 / 30 then return end
		local Step = Acc
		Acc = 0
		Orb1.Position = UDim2.fromScale(0.12 + math.sin(Elapsed * 0.5) * 0.07, 0.1 + math.cos(Elapsed * 0.4) * 0.06)
		Orb2.Position = UDim2.fromScale(0.95 + math.cos(Elapsed * 0.45) * 0.07, 0.95 + math.sin(Elapsed * 0.35) * 0.06)
		if Win._particles then
			for _, P in ipairs(Particles) do
				local Y = P.Y - P.Speed * Step
				if Y < -0.02 then Y = 1.02 end
				local X = P.X + math.sin(Elapsed + P.Drift) * 0.018 * Step
				P.X, P.Y = X, Y
				P.Obj.Position = UDim2.fromScale(X, Y)
			end
		end
	end)

	Win.ConfigManager = MakeConfigManager(Win)

	if O.ShowIntro == false then
		RootScale.Scale = TargetScale
	else
		Tween(RootScale, 0.4, { Scale = TargetScale }, Enum.EasingStyle.Back)
		local Splash = New("CanvasGroup", {
			Name = "Splash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, ZIndex = 100, Active = true,
		}, Main)
		Corner(Splash, MAIN_RADIUS)
		Gradient(Splash, Theme.Bg2, Theme.Bg, 135)
		Orb(Theme.Violet, 0.92, 0.08, 320, 0.65, Splash)
		Orb(Theme.Cyan, 0.08, 0.92, 320, 0.65, Splash)
		local SLogo = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -44), Size = UDim2.fromOffset(0, 0),
			BackgroundColor3 = White, BorderSizePixel = 0, ZIndex = 2,
		}, Splash)
		Corner(SLogo, 20)
		Gradient(SLogo, Theme.Violet, Theme.Cyan, 45)
		local SImg = New("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.6, 0.6),
			BackgroundTransparency = 1, ImageColor3 = White, ZIndex = 3,
		}, SLogo)
		local SFB = New("TextLabel", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = string.upper(string.sub(PlainTitle, 1, 1)),
			TextColor3 = White, TextSize = 30, Font = FontBlack, ZIndex = 3,
		}, SLogo)
		SetLucide(SImg, O.Icon or "layout-grid", SFB)
		local STitleText = string.upper(PlainTitle)
		local STitle = New("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 20), Size = UDim2.fromOffset(400, 32),
			BackgroundTransparency = 1, Text = STitleText, TextColor3 = White, TextSize = 26, Font = FontBlack,
			MaxVisibleGraphemes = 0, ZIndex = 2,
		}, Splash)
		Gradient(STitle, Theme.Violet, Theme.Cyan, 0)
		local BarBg = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 64), Size = UDim2.fromOffset(220, 4),
			BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, ZIndex = 2,
		}, Splash)
		Corner(BarBg, 2)
		local BarFill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = White, BorderSizePixel = 0 }, BarBg)
		Corner(BarFill, 2)
		Gradient(BarFill, Theme.Violet, Theme.Cyan, 0)
		Tween(SLogo, 0.35, { Size = UDim2.fromOffset(72, 72) }, Enum.EasingStyle.Back)
		Tween(BarFill, 1.4, { Size = UDim2.fromScale(1, 1) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		task.spawn(function()
			for I = 1, #STitleText do
				if Win.Destroyed then return end
				STitle.MaxVisibleGraphemes = I
				task.wait(0.03)
			end
		end)
		task.delay(1.9, function()
			if Win.Destroyed then return end
			Tween(Splash, 0.3, { GroupTransparency = 1 })
			task.delay(0.35, function() pcall(function() Splash:Destroy() end) end)
		end)
	end

	if type(O.KeySystem) == "table" then
		Win._Unlocked = false
		BuildKeyGate(Win, O.KeySystem)
		repeat task.wait(0.1) until Win._Unlocked or Win.Destroyed
	end

	return Win
end

return Library
