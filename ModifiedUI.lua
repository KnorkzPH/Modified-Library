local Library = { Version = "1.4.1" }

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer

local White = Color3.new(1, 1, 1)

-- Clean, solid look (less AI, solid borders & flat/clean styling)
local Theme = {
	Bg = Color3.fromRGB(12, 12, 16),
	Bg2 = Color3.fromRGB(18, 18, 24),
	Card = Color3.fromRGB(22, 22, 30),
	CardHover = Color3.fromRGB(30, 30, 40),
	Stroke = Color3.fromRGB(48, 48, 64),
	Text = Color3.fromRGB(240, 240, 245),
	Muted = Color3.fromRGB(160, 160, 175),
	Violet = Color3.fromRGB(110, 80, 220),
	Cyan = Color3.fromRGB(40, 180, 200),
	Pink = Color3.fromRGB(220, 60, 140),
	Teal = Color3.fromRGB(20, 160, 140),
	Blue = Color3.fromRGB(50, 110, 220),
	Green = Color3.fromRGB(60, 200, 110),
	Red = Color3.fromRGB(220, 80, 80),
	Amber = Color3.fromRGB(220, 160, 40),
	NotifBg = Color3.fromRGB(16, 16, 22),
}
Library.Theme = Theme

local ParagraphColors = {
	Red = Color3.fromRGB(220, 80, 80), Orange = Color3.fromRGB(220, 140, 40), Green = Color3.fromRGB(60, 200, 110),
	Blue = Color3.fromRGB(50, 110, 220), Purple = Color3.fromRGB(110, 80, 220), Grey = Color3.fromRGB(130, 130, 145),
}

local TypeColors = {
	success = Theme.Green, error = Theme.Red, warn = Theme.Amber, warning = Theme.Amber, info = Theme.Cyan,
}

local FontBold, FontMed, FontBlack = Enum.Font.GothamBold, Enum.Font.GothamMedium, Enum.Font.GothamBlack
local Left, Right = Enum.TextXAlignment.Left, Enum.TextXAlignment.Right
local AutoY, AutoX = Enum.AutomaticSize.Y, Enum.AutomaticSize.X
local QuartOut, DirOut = Enum.EasingStyle.Quart, Enum.EasingDirection.Out
local MouseButton1, TouchInput, MouseMove = Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch, Enum.UserInputType.MouseMovement
local MAIN_RADIUS = 12

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

local function Corner(Parent, R) return New("UICorner", { CornerRadius = UDim.new(0, R or 8) }, Parent) end

local function Stroke(Parent, Color, Thickness, Transparency)
	return New("UIStroke", {
		Color = Color or Theme.Stroke, Thickness = Thickness or 1, Transparency = Transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, Parent)
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

Library.BackgroundTransparency = 0
local BgRegistry = {}

local function BgCalc(Base)
	Base = Base or 0
	return Base + (1 - Base) * Library.BackgroundTransparency
end

local function PruneBg()
	for I = #BgRegistry, 1, -1 do
		if BgRegistry[I].Obj.Parent == nil then table.remove(BgRegistry, I) end
	end
end

local function Bg(Obj, Base)
	Base = Base or 0
	table.insert(BgRegistry, { Obj = Obj, Base = Base })
	if #BgRegistry % 100 == 0 then PruneBg() end
	Obj.BackgroundTransparency = BgCalc(Base)
	return Obj
end

function Library:SetBackgroundTransparency(V)
	V = math.clamp(tonumber(V) or 0, 0, 1)
	Library.BackgroundTransparency = V
	PruneBg()
	for _, E in ipairs(BgRegistry) do
		pcall(function() E.Obj.BackgroundTransparency = BgCalc(E.Base) end)
	end
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
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 360, 0, 0),
			AutomaticSize = AutoY, BackgroundColor3 = Theme.Card, BorderSizePixel = 0, ZIndex = 2, Active = true,
		}, Host.Modal)
		Bg(Box, 0)
		Corner(Box, 10)
		Stroke(Box, Theme.Stroke, 1.5)
		Pad(Box, 18, 16, 18, 16)
		List(Box, 12)
		Sc = New("UIScale", { Scale = 0.9 }, Box)
		Tween(Sc, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)

		local TitleRow = New("Frame", { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1 }, Box)
		local TX = 0
		if O.Icon then
			IconLabel(TitleRow, O.Icon, 22, Theme.Violet, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0) }, "•")
			TX = 30
		end
		New("TextLabel", {
			Position = UDim2.fromOffset(TX, 0), Size = UDim2.new(1, -TX, 1, 0), BackgroundTransparency = 1, RichText = true,
			Text = O.Title or "Dialog", TextColor3 = White, TextSize = 18, Font = FontBlack, TextXAlignment = Left,
		}, TitleRow)
		local Body = O.Content or O.Desc
		if Body then
			New("TextLabel", {
				LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, RichText = true,
				Text = Body, TextColor3 = Theme.Text, TextSize = 14, Font = FontMed, TextWrapped = true,
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
				local Btn = New("TextButton", {
					LayoutOrder = I, Size = Size, BackgroundColor3 = Variant == "Primary" and Theme.Violet or Theme.Bg2,
					BackgroundTransparency = Variant == "Tertiary" and 1 or 0, BorderSizePixel = 0, AutoButtonColor = false,
					Text = B.Title or "Button", TextColor3 = White, TextSize = 13, Font = FontBold,
				}, Row)
				Corner(Btn, 8)
				if Variant ~= "Tertiary" then Stroke(Btn, Theme.Stroke, 1) end
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

local NotifGui, NotifHolder, NotifList
local NotifOrder = 0
local NotifActive = {}
local NotifMargin = 16
local NotifSide = "Right"

local function ApplyNotifLayout()
	if not (NotifHolder and NotifHolder.Parent) then return end
	local IsLeft = NotifSide == "Left"
	NotifHolder.Size = UDim2.new(1, -NotifMargin * 2, 1, -NotifMargin * 2)
	NotifHolder.AnchorPoint = Vector2.new(IsLeft and 0 or 1, 1)
	NotifHolder.Position = UDim2.new(IsLeft and 0 or 1, IsLeft and NotifMargin or -NotifMargin, 1, -NotifMargin)
	NotifList.HorizontalAlignment = IsLeft and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Right
end

local function EnsureNotif()
	if NotifGui and NotifGui.Parent then return end
	NotifGui = New("ScreenGui", {
		Name = "ToolkitUI_Notify", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1000000,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	ParentGui(NotifGui)
	NotifHolder = New("Frame", { Name = "Holder", BackgroundTransparency = 1 }, NotifGui)
	New("UISizeConstraint", { MaxSize = Vector2.new(380, math.huge) }, NotifHolder)
	NotifList = List(NotifHolder, 8, { VerticalAlignment = Enum.VerticalAlignment.Bottom })
	ApplyNotifLayout()
end

function Library:SetNotificationPosition(Side)
	NotifSide = string.find(string.lower(tostring(Side or "")), "left") and "Left" or "Right"
	ApplyNotifLayout()
end

function Library:SetNotificationLower(V)
	NotifMargin = V and 64 or 16
	ApplyNotifLayout()
end

function Library:Notify(O)
	if type(O) == "string" then O = { Content = O } end
	O = O or {}
	EnsureNotif()
	local Col = O.Color or (O.Type and TypeColors[string.lower(tostring(O.Type))]) or Theme.Violet
	local Dur = math.max(tonumber(O.Duration) or 4, 0.5)
	local OffX = (NotifSide == "Left" and -1 or 1) * 440
	NotifOrder += 1

	while #NotifActive >= 5 do
		local Oldest = table.remove(NotifActive, 1)
		pcall(Oldest)
	end

	local Holder = New("Frame", {
		LayoutOrder = NotifOrder, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1,
	}, NotifHolder)

	local Card = New("Frame", {
		Position = UDim2.fromOffset(OffX, 0), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY,
		BackgroundColor3 = Theme.NotifBg, BorderSizePixel = 0, ClipsDescendants = true,
	}, Holder)
	Bg(Card, 0.02)
	Corner(Card, 8)
	Stroke(Card, Col, 1.5, 0)

	local Fill = New("Frame", {
		Name = "TimerFill", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Col, BackgroundTransparency = 0.8,
		BorderSizePixel = 0, ZIndex = 1,
	}, Card)
	New("Frame", { Name = "Accent", Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = Col, BorderSizePixel = 0, ZIndex = 2 }, Card)

	local Body = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, ZIndex = 3,
	}, Card)
	Pad(Body, 16, 10, 32, 10)
	local TextX = 0
	if O.Icon then
		IconLabel(Body, O.Icon, 20, Col, { Position = UDim2.fromOffset(0, 0) }, "•")
		TextX = 28
	end
	local Column = New("Frame", {
		Position = UDim2.fromOffset(TextX, 0), Size = UDim2.new(1, -TextX, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1,
	}, Body)
	List(Column, 4)
	New("TextLabel", {
		LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, RichText = true,
		Text = O.Title or "Notification", TextColor3 = White, TextSize = 15, Font = FontBold, TextWrapped = true,
		TextXAlignment = Left,
	}, Column)
	if O.Content then
		New("TextLabel", {
			LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, RichText = true,
			Text = O.Content, TextColor3 = Theme.Text, TextSize = 13, Font = FontMed, TextWrapped = true,
			TextXAlignment = Left,
		}, Column)
	end

	local Gone = false
	local function Dismiss()
		if Gone then return end
		Gone = true
		local I = table.find(NotifActive, Dismiss)
		if I then table.remove(NotifActive, I) end
		local T = Tween(Card, 0.2, { Position = UDim2.fromOffset(OffX, 0) }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
		T.Completed:Connect(function() Holder:Destroy() end)
	end
	table.insert(NotifActive, Dismiss)

	Tween(Card, 0.25, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Back)
	Tween(Fill, Dur, { Size = UDim2.new(0, 0, 1, 0) }, Enum.EasingStyle.Linear)
	task.delay(Dur, Dismiss)
	New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 6 }, Card).MouseButton1Click:Connect(Dismiss)

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
	Bg(Card, 0)
	Corner(Card, 8)
	local CS = Stroke(Card, Theme.Stroke, 1)
	Pad(Card, 12, 8, 12, 8)
	New("UISizeConstraint", { MinSize = Vector2.new(0, 42) }, Card)
	List(Card, 8, { VerticalAlignment = Enum.VerticalAlignment.Center })

	local Lock = New("TextButton", {
		Name = "LockOverlay", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(10, 10, 14), BackgroundTransparency = 0.4,
		BorderSizePixel = 0, Text = "", AutoButtonColor = false, Visible = false, ZIndex = 20,
	}, Root)
	Corner(Lock, 8)
	local LockRow = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(0, 20),
		AutomaticSize = AutoX, BackgroundTransparency = 1,
	}, Lock)
	List(LockRow, 6, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center })
	local LockIconWrap = New("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1 }, LockRow)
	IconLabel(LockIconWrap, "lock", 14, Theme.Amber, { Position = UDim2.fromOffset(0, 0) }, "•")
	local LockLabel = New("TextLabel", {
		LayoutOrder = 2, Size = UDim2.fromOffset(0, 20), AutomaticSize = AutoX, BackgroundTransparency = 1, Text = "Locked",
		TextColor3 = Theme.Text, TextSize = 12, Font = FontBold,
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
		Ico = IconLabel(Head, O.Icon, IS, Theme.Muted, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0) }, "•")
		TextX = IS + 8
	end

	local Column = New("Frame", {
		Position = UDim2.fromOffset(TextX, 0), Size = UDim2.new(1, -(TextX + (RightW > 0 and RightW + 8 or 0)), 0, 0),
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
		Tween(Card, 0.12, { BackgroundColor3 = Theme.CardHover })
		Tween(CS, 0.12, { Color = Theme.Violet })
	end)
	Card.MouseLeave:Connect(function()
		Tween(Card, 0.12, { BackgroundColor3 = Base.Bg })
		Tween(CS, 0.12, { Color = Base.Stroke })
	end)

	return {
		Root = Root, Card = Card, Head = Head, Title = Title, Desc = Desc, Icon = Ico, Stroke = CS,
		Lock = Lock, LockLabel = LockLabel, Base = Base,
	}
end

local function SetLockText(C, Text)
	Text = tostring(Text or "")
	C.LockLabel.Text = Text ~= "" and Text or "Locked"
	C.LockLabel.Visible = true
end

function Elements:_Finish(O, Obj, C)
	local Win = self.Win
	Obj.Frame = C.Root
	Obj.Locked = false
	SetLockText(C, O.LockTitle or O.LockedTitle or "")

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
	local C = self:_Card(O, Checkbox and 28 or 46, true)
	local Obj = { Value = false }
	local Render

	if Checkbox then
		local Box = New("Frame", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(20, 20),
			BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0,
		}, C.Head)
		Corner(Box, 4)
		local BS = Stroke(Box, Theme.Stroke, 1)
		local Fill = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Violet, BackgroundTransparency = 1, BorderSizePixel = 0 }, Box)
		Corner(Fill, 4)
		local Chk, ChkFB = IconLabel(Box, "check", 12, White, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ImageTransparency = 1, ZIndex = 3 }, "✓")
		ChkFB.TextTransparency = 1
		ChkFB.ZIndex = 3
		Render = function(V)
			Tween(Fill, 0.12, { BackgroundTransparency = V and 0 or 1 })
			Tween(Chk, 0.12, { ImageTransparency = V and 0 or 1 })
			Tween(ChkFB, 0.12, { TextTransparency = V and 0 or 1 })
			Tween(BS, 0.12, { Color = V and Theme.Violet or Theme.Stroke })
		end
	else
		local Track = New("Frame", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(38, 20),
			BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0,
		}, C.Head)
		Corner(Track, 10)
		local TS = Stroke(Track, Theme.Stroke, 1)
		local Fill = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Violet, BackgroundTransparency = 1, BorderSizePixel = 0 }, Track)
		Corner(Fill, 10)
		local Knob = New("Frame", {
			AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.fromOffset(16, 16),
			BackgroundColor3 = White, BorderSizePixel = 0, ZIndex = 2,
		}, Track)
		Corner(Knob, 8)
		Render = function(V)
			Tween(Fill, 0.15, { BackgroundTransparency = V and 0 or 1 })
			Tween(TS, 0.15, { Color = V and Theme.Violet or Theme.Stroke })
			Tween(Knob, 0.15, { Position = V and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0) })
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
	local C = self:_Card(O, 36, true)
	local Obj = {}
	local Chip = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(32, 22),
		BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0,
	}, C.Head)
	Corner(Chip, 6)
	Stroke(Chip, Theme.Stroke, 1)
	IconLabel(Chip, "chevron-right", 12, Theme.Text, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) }, ">")
	C.Head.MouseButton1Click:Connect(function()
		Tween(Chip, 0.08, { BackgroundColor3 = Theme.CardHover })
		task.delay(0.1, function()
			if Chip.Parent then Tween(Chip, 0.12, { BackgroundColor3 = Theme.Bg2 }) end
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
	local C = self:_Card(O, 70)
	local Obj = { Value = Min }

	local ValueBox = New("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(70, 20),
		BackgroundTransparency = 1, Text = "", TextColor3 = Theme.Cyan, TextSize = 12, Font = FontBold, TextXAlignment = Right,
		ClearTextOnFocus = false, TextEditable = O.IsTextbox == true, TextTruncate = Enum.TextTruncate.AtEnd,
	}, C.Head)
	local Holder = New("Frame", {
		LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Active = true,
	}, C.Card)
	local Track = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.new(1, -8, 0, 5),
		BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0,
	}, Holder)
	Corner(Track, 2)
	Stroke(Track, Theme.Stroke, 1)
	local Fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Theme.Violet, BorderSizePixel = 0 }, Track)
	Corner(Fill, 2)
	local Knob = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = White, BorderSizePixel = 0, ZIndex = 2,
	}, Track)
	Corner(Knob, 6)
	Stroke(Knob, Theme.Stroke, 1)

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
	local C = self:_Card(O, 140)
	local Obj = { Value = Multi and {} or nil, Values = Values }
	local Open = false

	local Pill = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(130, 26),
		BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0, AutoButtonColor = false, Text = "",
	}, C.Head)
	Bg(Pill, 0)
	Corner(Pill, 6)
	local PillStroke = Stroke(Pill, Theme.Stroke, 1)
	local ValueLabel = New("TextLabel", {
		Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -28, 1, 0), BackgroundTransparency = 1, Text = "",
		TextColor3 = Theme.Text, TextSize = 12, Font = FontMed, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, Pill)
	local Chevron = IconLabel(Pill, "chevron-down", 12, Theme.Text, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0) }, "v")

	Pill.MouseEnter:Connect(function()
		if Open then return end
		Tween(PillStroke, 0.12, { Color = Theme.Violet })
		Tween(Pill, 0.12, { BackgroundColor3 = Theme.CardHover })
	end)
	Pill.MouseLeave:Connect(function()
		if Open then return end
		Tween(PillStroke, 0.12, { Color = Theme.Stroke })
		Tween(Pill, 0.12, { BackgroundColor3 = Theme.Bg2 })
	end)

	local Holder = New("Frame", {
		LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0, ClipsDescendants = true, Visible = false,
		Active = true,
	}, C.Card)
	Bg(Holder, 0)
	Corner(Holder, 6)
	Stroke(Holder, Theme.Stroke, 1)
	local Scroll = New("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Violet, CanvasSize = UDim2.new(), AutomaticCanvasSize = AutoY,
		ScrollingDirection = Enum.ScrollingDirection.Y, Active = true,
	}, Holder)
	Pad(Scroll, 4, 4, 4, 4)
	List(Scroll, 2)

	local Buttons = {}
	local ContentH = 0
	local function Height() return math.min(math.max(ContentH, 28), 150) + 8 end

	local function NameOf(Item)
		if Item == nil then return nil end
		if type(Item) == "table" then
			if Item.Title == nil then return nil end
			return tostring(Item.Title)
		end
		return tostring(Item)
	end

	local function Paint(B)
		local T = B.Locked and 1 or (B.Down and 0.4 or (B.On and 0.2 or (B.Hover and 0.1 or 0)))
		Tween(B.Btn, 0.1, { BackgroundTransparency = T })
		B.Accent.Visible = B.On and not B.Locked
	end

	local function SetOpen(Val)
		Open = Val
		Obj.Opened = Val
		if Val then
			Holder.Visible = true
			Tween(Holder, 0.2, { Size = UDim2.new(1, 0, 0, Height()) })
		else
			Tween(Holder, 0.15, { Size = UDim2.new(1, 0, 0, 0) })
			task.delay(0.16, function()
				if not Open and Holder.Parent then Holder.Visible = false end
			end)
		end
		Tween(Chevron, 0.15, { Rotation = Val and 180 or 0 })
		Tween(PillStroke, 0.15, { Color = Val and Theme.Violet or Theme.Stroke })
		Tween(Pill, 0.15, { BackgroundColor3 = Val and Theme.CardHover or Theme.Bg2 })
	end

	local function Render()
		if Multi then
			ValueLabel.Text = #Obj.Value == 0 and (O.Placeholder or "None") or table.concat(Obj.Value, ", ")
		else
			ValueLabel.Text = Obj.Value and tostring(Obj.Value) or (O.Placeholder or "Select...")
		end
		for Name, B in pairs(Buttons) do
			local On = Multi and (table.find(Obj.Value, Name) ~= nil) or (Obj.Value == Name)
			B.On = On
			B.Chk.Visible = On
			if B.ChkFB then B.ChkFB.Visible = On and B.Chk.Image == "" end
			B.Lbl.TextColor3 = B.Locked and Theme.Muted or (On and Theme.Text or Theme.Muted)
			B.Lbl.Font = On and FontBold or FontMed
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
				LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = O.EmptyText or "No options",
				TextColor3 = Theme.Muted, TextSize = 11, Font = FontMed,
			}, Scroll)
			ContentH = 28
			return
		end
		for I, Raw in ipairs(Values) do
			if type(Raw) == "table" and Raw.Type == "Divider" then
				local Div = New("Frame", { LayoutOrder = I, Size = UDim2.new(1, 0, 0, 6), BackgroundTransparency = 1 }, Scroll)
				New("Frame", {
					AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.new(1, -8, 0, 1),
					BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0,
				}, Div)
				ContentH += 6
			else
				local Name = NameOf(Raw) or tostring(Raw)
				local ItemLocked = type(Raw) == "table" and Raw.Locked == true
				local LockText = "Locked"
				if ItemLocked then
					local T = Raw.LockTitle or Raw.LockedTitle
					if T ~= nil then LockText = tostring(T) end
				end

				local Btn = New("TextButton", {
					LayoutOrder = I, Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = Theme.Violet, BackgroundTransparency = 1,
					BorderSizePixel = 0, AutoButtonColor = false, Text = "", ClipsDescendants = true,
				}, Scroll)
				Corner(Btn, 4)
				local Accent = New("Frame", {
					AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(2, 14),
					BackgroundColor3 = Theme.Violet, BorderSizePixel = 0, Visible = false,
				}, Btn)
				local Row = New("Frame", {
					Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -28, 1, 0), BackgroundTransparency = 1,
				}, Btn)
				List(Row, 6, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center })
				if type(Raw) == "table" and Raw.Icon then
					local Wrap = New("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1 }, Row)
					IconLabel(Wrap, Raw.Icon, 12, Theme.Muted, { Position = UDim2.fromOffset(0, 0) })
				end
				local Lbl = New("TextLabel", {
					LayoutOrder = 2, Size = UDim2.fromOffset(0, 28), AutomaticSize = AutoX, BackgroundTransparency = 1, Text = Name,
					TextColor3 = Theme.Muted, TextSize = 12, Font = FontMed,
				}, Row)
				if ItemLocked then
					local LockWrap = New("Frame", { LayoutOrder = 3, Size = UDim2.fromOffset(0, 28), AutomaticSize = AutoX, BackgroundTransparency = 1 }, Row)
					List(LockWrap, 4, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center })
					local IconWrap = New("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1 }, LockWrap)
					IconLabel(IconWrap, "lock", 10, Theme.Amber, { Position = UDim2.fromOffset(0, 0) }, "•")
					if LockText ~= "" then
						New("TextLabel", {
							LayoutOrder = 2, Size = UDim2.fromOffset(0, 28), AutomaticSize = AutoX, BackgroundTransparency = 1, Text = LockText,
							TextColor3 = Theme.Amber, TextSize = 10, Font = FontBold,
						}, LockWrap)
					end
				end
				local Chk, ChkFB = IconLabel(Btn, "check", 12, Theme.Violet, {
					AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Visible = false,
				}, "✓")

				local B = {
					Btn = Btn, Lbl = Lbl, Chk = Chk, ChkFB = ChkFB, Accent = Accent, Locked = ItemLocked,
					On = false, Hover = false, Down = false,
				}
				Btn.MouseEnter:Connect(function() B.Hover = true; Paint(B) end)
				Btn.MouseLeave:Connect(function() B.Hover = false; B.Down = false; Paint(B) end)
				Btn.MouseButton1Down:Connect(function() B.Down = true; Paint(B) end)
				Btn.MouseButton1Up:Connect(function() B.Down = false; Paint(B) end)
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
				ContentH += 28
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
		if Open then Tween(Holder, 0.15, { Size = UDim2.new(1, 0, 0, Height()) }) end
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
	local C = self:_Card(O, Textarea and 0 | 0 or 150)

	local Pill
	if Textarea then
		Pill = New("Frame", {
			LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0, ClipsDescendants = true,
		}, C.Card)
	else
		Pill = New("Frame", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(150, 26),
			BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0, ClipsDescendants = true,
		}, C.Head)
	end
	Bg(Pill, 0)
	Corner(Pill, 6)
	local PS = Stroke(Pill, Theme.Stroke, 1)

	local TX = 8
	if O.InputIcon then
		IconLabel(Pill, O.InputIcon, 12, Theme.Muted, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, Textarea and 0 or 0.5, Textarea and 12 or 0) })
		TX = 24
	end
	local TB = New("TextBox", {
		Position = UDim2.fromOffset(TX, Textarea and 4 or 0), Size = UDim2.new(1, -(TX + 6), 1, Textarea and -8 or 0),
		BackgroundTransparency = 1, Text = "", PlaceholderText = O.Placeholder or "Enter text...", PlaceholderColor3 = Theme.Muted,
		TextColor3 = Theme.Text, TextSize = 12, Font = FontMed, ClearTextOnFocus = O.ClearTextOnFocus == true, TextXAlignment = Left,
		TextYAlignment = Textarea and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center, MultiLine = Textarea, TextWrapped = Textarea,
	}, Pill)
	TB.Focused:Connect(function() Tween(PS, 0.12, { Color = Theme.Violet }) end)

	function Obj:Set(Val, Silent)
		Val = tostring(Val or "")
		TB.Text = Val
		Obj.Value = Val
		if not Silent then Call(O.Callback, Val) end
	end
	function Obj:SetPlaceholder(T) TB.PlaceholderText = T end
	TB.FocusLost:Connect(function()
		Tween(PS, 0.12, { Color = Theme.Stroke })
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
	local C = self:_Card(O, 80)
	local Obj = { Value = "None" }
	local Listening = false

	local Pill = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(80, 26),
		BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0, AutoButtonColor = false, Text = "None", TextColor3 = Theme.Text,
		TextSize = 11, Font = FontBold,
	}, C.Head)
	Bg(Pill, 0)
	Corner(Pill, 6)
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
		Tween(PS, 0.12, { Color = Theme.Violet })
	end)

	self.Win:Connect(UserInputService.InputBegan, function(I, Processed)
		if Listening then
			if I.UserInputType == Enum.UserInputType.Keyboard then
				Listening = false
				Tween(PS, 0.12, { Color = Theme.Stroke })
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
	local C = self:_Card(O, 36, false)
	local Default = O.Default or Theme.Violet
	local H, S, V = Default:ToHSV()
	local Alpha = O.Transparency or 0
	local HasAlpha = O.Transparency ~= nil
	local Obj = { Value = Default, Transparency = Alpha }
	local Open = false
	local PH = 100
	local TotalH = PH + (HasAlpha and 20 or 0)

	local Swatch = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(32, 20),
		BackgroundColor3 = Default, BorderSizePixel = 0, AutoButtonColor = false, Text = "",
	}, C.Head)
	Corner(Swatch, 6)
	Stroke(Swatch, Theme.Stroke, 1)

	local Holder = New("Frame", {
		LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, ClipsDescendants = true, Visible = false,
	}, C.Card)

	local SV = New("Frame", { Size = UDim2.new(1, -26, 0, PH), BackgroundColor3 = Color3.fromHSV(H, 1, 1), BorderSizePixel = 0 }, Holder)
	Corner(SV, 6)
	local WhiteOv = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = White, BorderSizePixel = 0 }, SV)
	Corner(WhiteOv, 6)
	New("UIGradient", { Transparency = NumberSequence.new(0, 1) }, WhiteOv)
	local BlackOv = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0 }, SV)
	Corner(BlackOv, 6)
	New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }, BlackOv)
	local Cursor = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3,
	}, SV)
	Corner(Cursor, 5)
	Stroke(Cursor, White, 1.5)

	local HueBar = New("Frame", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(18, PH),
		BackgroundColor3 = White, BorderSizePixel = 0,
	}, Holder)
	Corner(HueBar, 6)
	local Keys = {}
	for I = 0, 6 do table.insert(Keys, ColorSequenceKeypoint.new(I / 6, Color3.fromHSV(I / 6, 1, 1))) end
	New("UIGradient", { Rotation = 90, Color = ColorSequence.new(Keys) }, HueBar)
	local HueCur = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(1, 2, 0, 3),
		BackgroundColor3 = White, BorderSizePixel = 0, ZIndex = 3,
	}, HueBar)
	Corner(HueCur, 2)
	Stroke(HueCur, Color3.new(0, 0, 0), 1, 0.5)

	local AlphaBar, AlphaCur, AlphaGrad
	if HasAlpha then
		AlphaBar = New("Frame", {
			Position = UDim2.fromOffset(0, PH + 6), Size = UDim2.new(1, 0, 0, 12), BackgroundColor3 = White, BorderSizePixel = 0,
		}, Holder)
		Corner(AlphaBar, 6)
		AlphaGrad = New("UIGradient", { Color = ColorSequence.new(Default, Theme.Bg) }, AlphaBar)
		AlphaCur = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(0, 3, 1, 2),
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
			Tween(Holder, 0.2, { Size = UDim2.new(1, 0, 0, TotalH) })
		else
			Tween(Holder, 0.15, { Size = UDim2.new(1, 0, 0, 0) })
			task.delay(0.16, function()
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
	local C = self:_Card({ Title = O.Title, Desc = O.Desc, Icon = O.Image or O.Icon, IconSize = O.ImageSize or 24 }, 0, false)
	local Obj = {}

	local Col = type(O.Color) == "string" and ParagraphColors[O.Color] or (typeof(O.Color) == "Color3" and O.Color) or nil
	if Col then
		C.Base.Bg = Theme.Card:Lerp(Col, 0.1)
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
				LayoutOrder = 2, Size = UDim2.new(1, 0, 0, Size or 72), BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0,
				ScaleType = Enum.ScaleType.Crop,
			}, C.Card)
			Corner(Thumb, 6)
		end
		Thumb.Visible = true
		Thumb.Size = UDim2.new(1, 0, 0, Size or 72)
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
			Corner(Btn, 6)
			Stroke(Btn, Theme.Stroke, 1)
			Pad(Btn, 8, 0, 8, 0)
			local Inner = New("Frame", { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AutoX, BackgroundTransparency = 1 }, Btn)
			List(Inner, 6, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center })
			if B.Icon then
				local Wrap = New("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1 }, Inner)
				IconLabel(Wrap, B.Icon, 12, Theme.Text, { Position = UDim2.fromOffset(0, 0) }, "•")
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
	local C = self:_Card({ Title = O.Title or "Code", Icon = O.Icon }, 56, false)
	local Obj = { Value = O.Code or "" }
	local Block = New("Frame", {
		LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0,
	}, C.Card)
	Bg(Block, 0)
	Corner(Block, 6)
	Stroke(Block, Theme.Stroke, 1)
	Pad(Block, 8, 6, 8, 6)
	local Lbl = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, Text = Obj.Value, TextColor3 = Theme.Cyan,
		TextSize = 12, Font = Enum.Font.Code, TextWrapped = true, TextXAlignment = Left, TextYAlignment = Enum.TextYAlignment.Top,
	}, Block)
	local Copy = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(52, 22),
		BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0, AutoButtonColor = false, Text = "COPY", TextColor3 = Theme.Text,
		TextSize = 10, Font = FontBold,
	}, C.Head)
	Corner(Copy, 6)
	Stroke(Copy, Theme.Stroke, 1)
	Copy.MouseButton1Click:Connect(function()
		CopyText(Obj.Value)
		Copy.Text = "COPIED"
		task.delay(1, function()
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
	return New("Frame", { LayoutOrder = self:_Next(), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0 }, self.Parent)
end

function Elements:Space(O)
	local H = type(O) == "number" and O or (type(O) == "table" and O.Size) or ((type(O) == "table" and O.Columns or 1) * 6)
	return New("Frame", { LayoutOrder = self:_Next(), Size = UDim2.new(1, 0, 0, H), BackgroundTransparency = 1 }, self.Parent)
end

function Elements:Section(O)
	if type(O) == "string" then O = { Title = O } end
	O = O or {}
	local Wrap = New("Frame", { LayoutOrder = self:_Next(), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1 }, self.Parent)
	List(Wrap, 6)

	local Align = ({ Left = Left, Center = Enum.TextXAlignment.Center, Right = Right })[O.TextXAlignment or "Left"] or Left
	local Header = New("TextButton", {
		LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
	}, Wrap)
	local TX = 0
	if O.Icon then
		IconLabel(Header, O.Icon, 16, Theme.Violet, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0) }, "•")
		TX = 22
	end
	local Lbl = New("TextLabel", {
		Position = UDim2.fromOffset(TX, 0), Size = UDim2.new(1, -(TX + 20), 1, 0), BackgroundTransparency = 1, RichText = true,
		Text = O.Title or "Section", TextColor3 = Theme.Text, TextTransparency = O.TextTransparency or 0,
		TextSize = O.TextSize or 14, Font = FontBold, TextXAlignment = Align, TextTruncate = Enum.TextTruncate.AtEnd,
	}, Header)
	local Chev = IconLabel(Header, "chevron-down", 12, Theme.Muted, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0) }, "v")

	local Body = New("Frame", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1 }, Wrap)
	if O.Box then
		Bg(Body, 0.2)
		Body.BackgroundColor3 = Theme.Bg2
		Corner(Body, 8)
		Stroke(Body, Theme.Stroke, 1)
		Pad(Body, 8, 8, 8, 8)
	end
	List(Body, 6)

	local Sec = setmetatable({ Win = self.Win, Parent = Body, Page = self.Page, _n = 0 }, SectionClass)
	local IsOpen = true
	function Sec:SetOpen(Val)
		IsOpen = Val
		Body.Visible = Val
		Tween(Chev, 0.15, { Rotation = Val and 0 or -90 })
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
		LayoutOrder = self:_NextSide(), Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, BorderSizePixel = 0,
		AutoButtonColor = false, Text = "",
	}, ParentFrame)
	Corner(Btn, 6)
	local ActiveFill = New("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.CardHover, BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, Btn)
	Corner(ActiveFill, 6)
	local ActStroke = Stroke(ActiveFill, Theme.Violet, 1, 1)

	local IconRight = O.IconAlign == "Right"
	local Ico, IcoFB
	local TextL = 10
	if O.Icon then
		if IconRight then
			Ico, IcoFB = IconLabel(Btn, O.Icon, 15, Theme.Muted, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0) }, "•")
		else
			Ico, IcoFB = IconLabel(Btn, O.Icon, 15, Theme.Muted, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0) }, "•")
			TextL = 28
		end
	end
	local LockIco, LockFB = IconLabel(Btn, "lock", 12, Theme.Amber, {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Visible = false,
	}, "•")

	local Lbl = New("TextLabel", {
		Position = UDim2.fromOffset(TextL, 0), Size = UDim2.new(1, -(TextL + 8), 1, 0), BackgroundTransparency = 1,
		Text = Tab.Title, TextColor3 = Theme.Muted, TextSize = 12, Font = FontBold, TextXAlignment = Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, Btn)

	local function Reflow()
		local R = 8
		if (Ico and IconRight) or Tab.Locked then R = 28 end
		Lbl.Size = UDim2.new(1, -(TextL + R), 1, 0)
	end
	Reflow()

	local Page = New("ScrollingFrame", {
		Name = "Page_" .. Tab.Title, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Violet, CanvasSize = UDim2.new(), AutomaticCanvasSize = AutoY,
		ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false, Active = true,
	}, self.Content)
	Pad(Page, 2, 2, 8, 2)
	List(Page, 6)

	Tab.Parent, Tab.Page, Tab.TabButton = Page, Page, Btn

	local Selected = false
	function Tab:_SetActive(On, Instant)
		Selected = On
		Tween(ActiveFill, 0.15, { BackgroundTransparency = On and 0 or 1 })
		Tween(ActStroke, 0.15, { Transparency = On and 0 or 1 })
		Tween(Lbl, 0.15, { TextColor3 = On and Theme.Text or Theme.Muted })
		if Ico then Tween(Ico, 0.15, { ImageColor3 = On and Theme.Text or Theme.Muted }) end
		if On then
			Page.Visible = true
			if not Instant and WinRef._moving ~= false then
				Page.Position = UDim2.fromOffset(0, 8)
				Tween(Page, 0.2, { Position = UDim2.fromOffset(0, 0) })
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
			Tween(Lbl, 0.1, { TextColor3 = Theme.Text })
			Tween(ActiveFill, 0.1, { BackgroundTransparency = 0.5 })
		end
	end)
	Btn.MouseLeave:Connect(function()
		if Tab.Locked then return end
		if not Selected then
			Tween(Lbl, 0.1, { TextColor3 = Theme.Muted })
			Tween(ActiveFill, 0.1, { BackgroundTransparency = 1 })
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
	local Header = New("TextButton", { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, Wrap)
	local TX = 4
	if O.Icon then
		IconLabel(Header, O.Icon, 12, Theme.Muted, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0) }, "•")
		TX = 20
	end
	New("TextLabel", {
		Position = UDim2.fromOffset(TX, 0), Size = UDim2.new(1, -(TX + 22), 1, 0), BackgroundTransparency = 1, Text = string.upper(StripRich(O.Title or "SECTION")),
		TextColor3 = Theme.Muted, TextSize = 10, Font = FontBold, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, Header)
	local Chev = IconLabel(Header, "chevron-down", 12, Theme.Muted, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0) }, "v")
	local Body = New("Frame", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1 }, Wrap)
	List(Body, 4)

	local Sec = setmetatable({ Win = self }, SideSection)
	local IsOpen = O.Opened ~= false
	function Sec:Tab(TO) return self.Win:_MakeTab(TO, Body) end
	function Sec:SetOpen(Val)
		IsOpen = Val
		Body.Visible = Val
		Tween(Chev, 0.15, { Rotation = Val and 0 or -90 })
	end
	Header.MouseButton1Click:Connect(function() Sec:SetOpen(not IsOpen) end)
	Sec:SetOpen(IsOpen)
	return Sec
end

function Window:Divider()
	return New("Frame", { LayoutOrder = self:_NextSide(), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0 }, self.Sidebar)
end

function Window:Space(O)
	return New("Frame", { LayoutOrder = self:_NextSide(), Size = UDim2.new(1, 0, 0, type(O) == "number" and O or 6), BackgroundTransparency = 1 }, self.Sidebar)
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

function Window:SetTitle(T) self.TitleLabel.Text = T end
function Window:SetAuthor(T) self.AuthorLabel.Text = T end

function Window:SetBackgroundTransparency(V)
	Library:SetBackgroundTransparency(V)
end

function Window:Tag(O)
	if type(O) == "string" then O = { Title = O } end
	O = O or {}
	self._tagN += 1
	local Col = O.Color or Theme.Violet
	local Tag = New("Frame", {
		Name = "Tag", LayoutOrder = self._tagN, Size = UDim2.fromOffset(0, 22), AutomaticSize = AutoX,
		BackgroundColor3 = Col, BackgroundTransparency = O.Transparency or 0.7, BorderSizePixel = 0,
	}, self.TagFrame)
	Corner(Tag, math.clamp(O.Radius or 6, 0, 10))
	Stroke(Tag, Col, 1, 0.3)
	Pad(Tag, 8, 0, 8, 0)
	List(Tag, 4, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center })
	if O.Icon then
		local Wrap = New("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1 }, Tag)
		IconLabel(Wrap, O.Icon, 12, Col:Lerp(White, 0.4), nil, "•")
	end
	local Lbl = New("TextLabel", {
		LayoutOrder = 2, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AutoX, BackgroundTransparency = 1,
		Text = O.Title or "Tag", TextColor3 = Col:Lerp(White, 0.5), TextSize = 11, Font = FontBold,
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
	local Ok, T = pcall(Tween, self.RootScale, 0.2, { Scale = 0.8 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
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
				if E.Value ~= nil then Data[K] = serialize and serialize(E.Value) or E.Value end
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
				if E then pcall(function() if E.Select then E:Select(V) else E:Set(V) end end) end
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

function Library:CreateWindow(O)
	O = O or {}

	if type(O.BackgroundTransparency) == "number" then
		Library:SetBackgroundTransparency(O.BackgroundTransparency)
	end

	local Size = typeof(O.Size) == "UDim2" and O.Size or UDim2.fromOffset(560, 380)
	local BASE_W, BASE_H = Size.X.Offset, Size.Y.Offset
	local SBW = math.clamp(O.SideBarWidth | 0 or 150, 110, math.floor(BASE_W * 0.4))
	local FolderName = O.Folder or O.ConfigFolder | 0 or "ToolkitUI"
	local Name = "ToolkitUI_" .. FolderName
	local UserCfg = type(O.User) == "table" and O.User.Enabled and O.User or nil
	local PlainTitle = StripRich(O.Title or "ToolkitUI")

	local Win = setmetatable({
		Connections = {}, Tabs = {}, Destroyed = false, Hidden = false, _side = 0, _tagN = 0, _Elements = {}, FlagElements = {},
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
	local RootScale = New("UIScale", { Scale = TargetScale }, Root)
	Win.Root, Win.RootScale = Root, RootScale

	local Main = New("Frame", {
		Name = "Main", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Bg,
		BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 2, Active = true,
	}, Root)
	Bg(Main, 0)
	Corner(Main, MAIN_RADIUS)
	Stroke(Main, Theme.Stroke, 1.5)
	Win.Main = Main

	local TopBar = New("Frame", { Name = "TopBar", Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, ZIndex = 5 }, Main)
	local Logo = New("Frame", {
		Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(12, 9), BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0,
	}, TopBar)
	Corner(Logo, 6)
	Stroke(Logo, Theme.Stroke, 1)
	local LogoImg = New("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.6, 0.6),
		BackgroundTransparency = 1, ImageColor3 = Theme.Text, ScaleType = Enum.ScaleType.Fit,
	}, Logo)
	local LogoFB = New("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = string.upper(string.sub(PlainTitle, 1, 1)),
		TextColor3 = Theme.Text, TextSize = 14, Font = FontBlack,
	}, Logo)
	SetLucide(LogoImg, O.Icon or "layout-grid", LogoFB)

	Win.TitleLabel = New("TextLabel", {
		Position = UDim2.fromOffset(50, 8), Size = UDim2.fromOffset(BASE_W - 220, 20), BackgroundTransparency = 1, RichText = true,
		Text = O.Title or "ToolkitUI", TextColor3 = Theme.Text, TextSize = 15, Font = FontBlack, TextXAlignment = Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, TopBar)
	Win.AuthorLabel = New("TextLabel", {
		Position = UDim2.fromOffset(50, 26), Size = UDim2.fromOffset(BASE_W - 220, 14), BackgroundTransparency = 1,
		Text = O.Author or "", TextColor3 = Theme.Muted, TextSize = 11, Font = FontMed, TextXAlignment = Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, TopBar)

	local CloseButton = New("TextButton", {
		Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -34, 0, 11), BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0,
		AutoButtonColor = false, Text = "×", TextColor3 = Theme.Muted, TextSize = 18, Font = FontBold,
	}, TopBar)
	Corner(CloseButton, 6)
	Stroke(CloseButton, Theme.Stroke, 1)
	CloseButton.MouseEnter:Connect(function() Tween(CloseButton, 0.1, { BackgroundColor3 = Theme.Red, TextColor3 = White }) end)
	CloseButton.MouseLeave:Connect(function() Tween(CloseButton, 0.1, { BackgroundColor3 = Theme.Bg2, TextColor3 = Theme.Muted }) end)

	local MinButton = New("TextButton", {
		Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -66, 0, 11), BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0,
		AutoButtonColor = false, Text = "–", TextColor3 = Theme.Muted, TextSize = 16, Font = FontBold,
	}, TopBar)
	Corner(MinButton, 6)
	Stroke(MinButton, Theme.Stroke, 1)
	MinButton.MouseEnter:Connect(function() Tween(MinButton, 0.1, { BackgroundColor3 = Theme.CardHover, TextColor3 = Theme.Text }) end)
	MinButton.MouseLeave:Connect(function() Tween(MinButton, 0.1, { BackgroundColor3 = Theme.Bg2, TextColor3 = Theme.Muted }) end)

	local TAG_EDGE = tonumber(O.TagOffset) or 96
	local TagSep = New("Frame", {
		Name = "TagSeparator", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -(TAG_EDGE - 14), 0, 13),
		Size = UDim2.fromOffset(1, 22), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Visible = false,
	}, TopBar)
	local TagScroll = New("ScrollingFrame", {
		Name = "Tags", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -TAG_EDGE, 0, 9), Size = UDim2.fromOffset(0, 30),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Violet,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = AutoX, ScrollingDirection = Enum.ScrollingDirection.X,
		ElasticBehavior = Enum.ElasticBehavior.Never, ClipsDescendants = true, Active = true, Visible = false,
	}, TopBar)
	local TagList = List(TagScroll, 4, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center })
	Win.TagFrame = TagScroll

	local function Relayout()
		local Scale = math.max(RootScale.Scale, 0.01)
		local ContentW = TagList.AbsoluteContentSize.X / Scale
		local MaxW = math.floor(BASE_W * 0.3)
		local W = math.min(ContentW, MaxW)
		local HasTags = ContentW > 0
		TagScroll.Visible = HasTags
		TagSep.Visible = HasTags
		TagScroll.Size = UDim2.fromOffset(W, 30)
		local Reserve = HasTags and (TAG_EDGE + W + 10) or 76
		local Avail = math.max(BASE_W - 50 - Reserve, 30)
		Win.TitleLabel.Size = UDim2.fromOffset(Avail, 20)
		Win.AuthorLabel.Size = UDim2.fromOffset(Avail, 14)
	end
	TagList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(Relayout)
	RootScale:GetPropertyChangedSignal("Scale"):Connect(Relayout)
	Relayout()

	local TagHover = false
	TagScroll.MouseEnter:Connect(function() TagHover = true end)
	TagScroll.MouseLeave:Connect(function() TagHover = false end)
	Win:Connect(UserInputService.InputChanged, function(I)
		if not TagHover or I.UserInputType ~= Enum.UserInputType.MouseWheel then return end
		local ContentW = TagList.AbsoluteContentSize.X / math.max(RootScale.Scale, 0.01)
		local MaxScroll = math.max(ContentW - TagScroll.Size.X.Offset, 0)
		local X = math.clamp(TagScroll.CanvasPosition.X - I.Position.Z * 30, 0, MaxScroll)
		TagScroll.CanvasPosition = Vector2.new(X, 0)
	end)

	local Divider = New("Frame", {
		Position = UDim2.fromOffset(12, 47), Size = UDim2.new(1, -24, 0, 1), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, ZIndex = 5,
	}, Main)

	local SideBottom = UserCfg and 56 or 10
	local Sidebar = New("ScrollingFrame", {
		Name = "Sidebar", Position = UDim2.fromOffset(8, 52), Size = UDim2.new(0, SBW + 6, 1, -(52 + SideBottom)),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = AutoY, ScrollingDirection = Enum.ScrollingDirection.Y, ClipsDescendants = true, ZIndex = 5, Active = true,
	}, Main)
	Pad(Sidebar, 2, 2, 2, 2)
	List(Sidebar, 4)
	Win.Sidebar = Sidebar

	New("Frame", {
		Position = UDim2.fromOffset(SBW + 16, 58), Size = UDim2.new(0, 1, 1, -(58 + 12)), BackgroundColor3 = Theme.Stroke,
		BorderSizePixel = 0, ZIndex = 5,
	}, Main)

	if UserCfg then
		local UC = New("TextButton", {
			Position = UDim2.new(0, 8, 1, -52), Size = UDim2.fromOffset(SBW, 42), BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0,
			AutoButtonColor = false, Text = "", ZIndex = 5,
		}, Main)
		Bg(UC, 0)
		Corner(UC, 8)
		Stroke(UC, Theme.Stroke, 1)
		local Av = New("ImageLabel", {
			Position = UDim2.fromOffset(6, 5), Size = UDim2.fromOffset(32, 32), BackgroundColor3 = Theme.Card, BorderSizePixel = 0,
			Image = UserCfg.Anonymous and "" or ("rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"),
		}, UC)
		Corner(Av, 6)
		New("TextLabel", {
			Position = UDim2.fromOffset(44, 5), Size = UDim2.new(1, -50, 0, 16), BackgroundTransparency = 1,
			Text = UserCfg.Anonymous and "Anonymous" or LocalPlayer.DisplayName, TextColor3 = Theme.Text, TextSize = 12, Font = FontBold,
			TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd,
		}, UC)
		New("TextLabel", {
			Position = UDim2.fromOffset(44, 21), Size = UDim2.new(1, -50, 0, 14), BackgroundTransparency = 1,
			Text = UserCfg.Anonymous and "@anonymous" or ("@" .. LocalPlayer.Name), TextColor3 = Theme.Muted, TextSize = 10, Font = FontMed,
			TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd,
		}, UC)
		UC.MouseButton1Click:Connect(function() Call(UserCfg.Callback) end)
	end

	local Content = New("Frame", {
		Name = "Content", Position = UDim2.fromOffset(SBW + 22, 54), Size = UDim2.new(1, -(SBW + 22 + 10), 1, -(54 + 10)),
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
		Size = UDim2.fromOffset(42, 42), Position = UDim2.new(1, -56, 0.5, -21), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Visible = false,
		Active = true,
	}, Gui)
	Corner(Bubble, 8)
	Stroke(Bubble, Theme.Stroke, 1.5)
	local BubbleButton = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, Bubble)
	local BubbleImg = New("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1, ImageColor3 = Theme.Text,
	}, Bubble)
	local BubbleFB = New("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "≡", TextColor3 = Theme.Text, TextSize = 18, Font = FontBold,
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

	Win.ConfigManager = MakeConfigManager(Win)

	if O.ShowIntro == false then
		RootScale.Scale = TargetScale
	else
		RootScale.Scale = TargetScale * 0.9
		Tween(RootScale, 0.25, { Scale = TargetScale }, Enum.EasingStyle.Back)
	end

	return Win
end

return Library
