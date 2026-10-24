local Library = { Version = "1.5.0" }

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
	Bg = Color3.fromRGB(18, 19, 22),
	Bg2 = Color3.fromRGB(24, 25, 30),
	Card = Color3.fromRGB(31, 33, 39),
	CardHover = Color3.fromRGB(42, 45, 54),
	Header = Color3.fromRGB(37, 40, 48),
	Stroke = Color3.fromRGB(58, 62, 74),
	Outline = Color3.fromRGB(96, 102, 120),
	Text = Color3.fromRGB(240, 242, 246),
	Muted = Color3.fromRGB(178, 184, 198),
	Accent = Color3.fromRGB(92, 142, 240),
	AccentSoft = Color3.fromRGB(140, 180, 250),
	Green = Color3.fromRGB(74, 222, 128),
	Red = Color3.fromRGB(248, 113, 113),
	Amber = Color3.fromRGB(251, 191, 36),
	NotifBg = Color3.fromRGB(21, 22, 26),
}
-- Old names kept so existing scripts that read Theme.Violet / Theme.Cyan still work
Theme.Violet = Theme.Accent
Theme.Cyan = Theme.AccentSoft
Theme.Pink = Theme.Accent
Theme.Blue = Theme.Accent
Theme.Teal = Color3.fromRGB(20, 184, 166)
Library.Theme = Theme

local ParagraphColors = {
	Red = Color3.fromRGB(248, 113, 113), Orange = Color3.fromRGB(251, 146, 60), Green = Color3.fromRGB(74, 222, 128),
	Blue = Color3.fromRGB(59, 130, 246), Purple = Color3.fromRGB(139, 92, 255), Grey = Color3.fromRGB(148, 153, 166),
}

local TypeColors = {
	success = Theme.Green, error = Theme.Red, warn = Theme.Amber, warning = Theme.Amber, info = Theme.Accent,
}

local FontBold, FontMed, FontBlack = Enum.Font.GothamBold, Enum.Font.GothamMedium, Enum.Font.GothamBlack
local Left, Right = Enum.TextXAlignment.Left, Enum.TextXAlignment.Right
local AutoY, AutoX = Enum.AutomaticSize.Y, Enum.AutomaticSize.X
local QuartOut, DirOut = Enum.EasingStyle.Quart, Enum.EasingDirection.Out
local MouseButton1, TouchInput, MouseMove = Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch, Enum.UserInputType.MouseMovement
local MAIN_RADIUS = 6

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

local function Corner(Parent, R) return New("UICorner", { CornerRadius = UDim.new(0, R or 4) }, Parent) end

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

----------------------------------------------------------------------
-- Background transparency system
-- Every "background" surface (window, cards, dialogs, notifications,
-- inputs...) registers here. Setting BackgroundTransparency on the window
-- (or Library:SetBackgroundTransparency) updates all of them at once.
-- Tags are intentionally NOT registered, so they never change.
----------------------------------------------------------------------
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

-- Flat filled button with a visible outline on hover and a pressed state
local function SolidButton(Parent, Text, Size, Position, Color, TextSize)
	local Holder = New("Frame", { Size = Size, Position = Position, BackgroundColor3 = Color, BorderSizePixel = 0 }, Parent)
	Corner(Holder, 3)
	local Rest = Color:Lerp(White, 0.18)
	local S = Stroke(Holder, Rest, 1, 0.4)
	local Button = New("TextButton", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, AutoButtonColor = false, Text = Text,
		TextColor3 = White, TextSize = TextSize or 13, Font = FontBold,
	}, Holder)
	local Hover = Color:Lerp(White, 0.1)
	Button.MouseEnter:Connect(function()
		Tween(Holder, 0.12, { BackgroundColor3 = Hover })
		Tween(S, 0.12, { Color = White, Transparency = 0.1 })
	end)
	Button.MouseLeave:Connect(function()
		Tween(Holder, 0.12, { BackgroundColor3 = Color })
		Tween(S, 0.12, { Color = Rest, Transparency = 0.4 })
	end)
	Button.MouseButton1Down:Connect(function() Tween(Holder, 0.05, { BackgroundColor3 = Color:Lerp(Theme.Bg, 0.22) }) end)
	Button.MouseButton1Up:Connect(function() Tween(Holder, 0.1, { BackgroundColor3 = Hover }) end)
	return Button, Holder
end

local function IconButton(Parent, Text, Position, HoverColor)
	local B = New("TextButton", {
		Size = UDim2.fromOffset(26, 26), Position = Position, BackgroundColor3 = Theme.Card, BorderSizePixel = 0,
		AutoButtonColor = false, Text = Text, TextColor3 = Theme.Muted, TextSize = 18, Font = FontBold,
	}, Parent)
	Corner(B, 3)
	local S = Stroke(B, Theme.Outline, 1)
	B.MouseEnter:Connect(function()
		Tween(B, 0.12, { BackgroundColor3 = HoverColor, TextColor3 = White })
		Tween(S, 0.12, { Color = White })
	end)
	B.MouseLeave:Connect(function()
		Tween(B, 0.12, { BackgroundColor3 = Theme.Card, TextColor3 = Theme.Muted })
		Tween(S, 0.12, { Color = Theme.Outline })
	end)
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
			BackgroundColor3 = (I % 2 == 0) and Theme.Accent or Theme.Muted,
			BackgroundTransparency = Rng:NextNumber(0.7, 0.92), BorderSizePixel = 0, ZIndex = 1,
		}, Parent)
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
		Tween(Host.Dim, 0.2, { BackgroundTransparency = 0.45 })

		Box = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 360, 0, 0),
			AutomaticSize = AutoY, BackgroundColor3 = Theme.Card, BorderSizePixel = 0, ZIndex = 2, Active = true,
		}, Host.Modal)
		Bg(Box, 0)
		Corner(Box, 6)
		Stroke(Box, Theme.Outline, 1, 0)
		Pad(Box, 18, 16, 18, 16)
		List(Box, 12)
		Sc = New("UIScale", { Scale = 0.95 }, Box)
		Tween(Sc, 0.2, { Scale = 1 })

		local TitleRow = New("Frame", { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1 }, Box)
		local TX = 0
		if O.Icon then
			IconLabel(TitleRow, O.Icon, 22, Theme.AccentSoft, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0) }, "•")
			TX = 30
		end
		New("TextLabel", {
			Position = UDim2.fromOffset(TX, 0), Size = UDim2.new(1, -TX, 1, 0), BackgroundTransparency = 1, RichText = true,
			Text = O.Title or "Dialog", TextColor3 = Theme.Text, TextSize = 17, Font = FontBold, TextXAlignment = Left,
		}, TitleRow)
		local Body = O.Content or O.Desc
		if Body then
			New("TextLabel", {
				LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, RichText = true,
				Text = Body, TextColor3 = Color3.fromRGB(216, 220, 230), TextSize = 14, Font = FontMed, TextWrapped = true,
				TextXAlignment = Left, TextYAlignment = Enum.TextYAlignment.Top,
			}, Box)
		end

		local Buttons = O.Buttons or {}
		if #Buttons > 0 then
			local Row = New("Frame", { LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1 }, Box)
			List(Row, 8, { FillDirection = Enum.FillDirection.Horizontal })
			local N = #Buttons
			for I, B in ipairs(Buttons) do
				local Size = UDim2.new(1 / N, -8 * (N - 1) / N, 1, 0)
				local Variant = B.Variant or B.Style or "Primary"
				local Btn
				if Variant == "Primary" or Variant == "Danger" then
					local Holder
					local Col = Variant == "Danger" and Theme.Red:Lerp(Theme.Bg, 0.3) or Theme.Accent
					Btn, Holder = SolidButton(Row, B.Title or "Button", Size, UDim2.new(), Col, 13)
					Holder.LayoutOrder = I
				else
					local Flat = Variant == "Tertiary"
					Btn = New("TextButton", {
						LayoutOrder = I, Size = Size, BackgroundColor3 = Theme.Header, BackgroundTransparency = Flat and 1 or 0,
						BorderSizePixel = 0, AutoButtonColor = false, Text = B.Title or "Button", TextColor3 = Theme.Text,
						TextSize = 13, Font = FontBold,
					}, Row)
					Corner(Btn, 3)
					local BS = (not Flat) and Stroke(Btn, Theme.Outline, 1.2) or nil
					Btn.MouseEnter:Connect(function()
						if BS then Tween(BS, 0.12, { Color = Theme.Accent }) end
						Tween(Btn, 0.12, { BackgroundColor3 = Theme.CardHover, BackgroundTransparency = 0 })
					end)
					Btn.MouseLeave:Connect(function()
						if BS then Tween(BS, 0.12, { Color = Theme.Outline }) end
						Tween(Btn, 0.12, { BackgroundColor3 = Theme.Header, BackgroundTransparency = Flat and 1 or 0 })
					end)
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
		Tween(S, 0.15, { Scale = 0.96 })
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

----------------------------------------------------------------------
-- Notifications
-- * Square corners, stacked at the BOTTOM of the screen (bottom-right by default)
-- * The auto-dismiss timer is merged into the card: the colored background
--   slowly drains away while the text/icon on top stays fully visible
-- * Large, high-contrast text and follows Library.BackgroundTransparency
----------------------------------------------------------------------
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

-- "Right" (default) or "Left"; both are always at the bottom of the screen
function Library:SetNotificationPosition(Side)
	NotifSide = string.find(string.lower(tostring(Side or "")), "left") and "Left" or "Right"
	ApplyNotifLayout()
end

-- Kept for older scripts: true = lift the stack higher from the bottom edge (useful for mobile)
function Library:SetNotificationLower(V)
	NotifMargin = V and 64 or 16
	ApplyNotifLayout()
end

function Library:Notify(O)
	if type(O) == "string" then O = { Content = O } end
	O = O or {}
	EnsureNotif()
	local Col = O.Color or (O.Type and TypeColors[string.lower(tostring(O.Type))]) or Theme.Accent
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

	-- Square card (no UICorner on purpose)
	local Card = New("Frame", {
		Position = UDim2.fromOffset(OffX, 0), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY,
		BackgroundColor3 = Theme.NotifBg, BorderSizePixel = 0, ClipsDescendants = true,
	}, Holder)
	Bg(Card, 0.02)
	Stroke(Card, Col, 1.5, 0.1)

	-- Disappearance "bar" merged into the background: it drains from right to left behind the content
	local Fill = New("Frame", {
		Name = "TimerFill", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Col, BackgroundTransparency = 0.74,
		BorderSizePixel = 0, ZIndex = 1,
	}, Card)
	-- Solid accent stripe (does not shrink, so the type color is always visible)
	New("Frame", { Name = "Accent", Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = Col, BorderSizePixel = 0, ZIndex = 2 }, Card)

	local Body = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, ZIndex = 3,
	}, Card)
	Pad(Body, 20, 12, 38, 12)
	local TextX = 0
	if O.Icon then
		IconLabel(Body, O.Icon, 24, Col, { Position = UDim2.fromOffset(0, 0) }, "•")
		TextX = 34
	end
	local Column = New("Frame", {
		Position = UDim2.fromOffset(TextX, 0), Size = UDim2.new(1, -TextX, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1,
	}, Body)
	List(Column, 4)
	New("TextLabel", {
		LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, RichText = true,
		Text = O.Title or "Notification", TextColor3 = White, TextSize = 16, Font = FontBold, TextWrapped = true,
		TextXAlignment = Left, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 0.75,
	}, Column)
	if O.Content then
		New("TextLabel", {
			LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, RichText = true,
			Text = O.Content, TextColor3 = Color3.fromRGB(240, 242, 248), TextSize = 15, Font = FontMed, TextWrapped = true,
			TextXAlignment = Left, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 0.75,
		}, Column)
	end
	New("TextLabel", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 6), Size = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1, Text = "×", TextColor3 = Theme.Muted, TextSize = 22, Font = FontBold, ZIndex = 4,
	}, Card)

	local Gone = false
	local function Dismiss()
		if Gone then return end
		Gone = true
		local I = table.find(NotifActive, Dismiss)
		if I then table.remove(NotifActive, I) end
		local T = Tween(Card, 0.25, { Position = UDim2.fromOffset(OffX, 0) }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
		T.Completed:Connect(function() Holder:Destroy() end)
	end
	table.insert(NotifActive, Dismiss)

	Tween(Card, 0.3, { Position = UDim2.fromOffset(0, 0) })
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
	Corner(Card, 4)
	local CS = Stroke(Card, Theme.Stroke, 1)
	Pad(Card, 12, 9, 12, 9)
	New("UISizeConstraint", { MinSize = Vector2.new(0, 44) }, Card)
	List(Card, 8, { VerticalAlignment = Enum.VerticalAlignment.Center })

	-- Lock overlay: lock icon + text. Text is the lock Title, or just "Locked" when none was given.
	local Lock = New("TextButton", {
		Name = "LockOverlay", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(12, 12, 15), BackgroundTransparency = 0.2,
		BorderSizePixel = 0, Text = "", AutoButtonColor = false, Visible = false, ZIndex = 20,
	}, Root)
	Corner(Lock, 4)
	Stroke(Lock, Theme.Amber, 1, 0.5)
	local LockRow = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(0, 20),
		AutomaticSize = AutoX, BackgroundTransparency = 1,
	}, Lock)
	List(LockRow, 6, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center })
	local LockIconWrap = New("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1 }, LockRow)
	IconLabel(LockIconWrap, "lock", 16, Theme.Amber, { Position = UDim2.fromOffset(0, 0) }, "•")
	local LockLabel = New("TextLabel", {
		LayoutOrder = 2, Size = UDim2.fromOffset(0, 20), AutomaticSize = AutoX, BackgroundTransparency = 1, Text = "Locked",
		TextColor3 = Theme.Text, TextSize = 13, Font = FontBold,
	}, LockRow)

	local HeadProps = { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1 }
	if Clickable then
		HeadProps.Text = ""
		HeadProps.AutoButtonColor = false
	end
	local Head = New(Clickable and "TextButton" or "Frame", HeadProps, Card)
	New("UISizeConstraint", { MinSize = Vector2.new(0, 24) }, Head)

	local TextX, Ico = 0, nil
	if O.Icon and O.Icon ~= "" then
		local IS = O.IconSize or 20
		Ico = IconLabel(Head, O.Icon, IS, Theme.AccentSoft, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0) }, "•")
		TextX = IS + 10
	end

	local Column = New("Frame", {
		Position = UDim2.fromOffset(TextX, 0), Size = UDim2.new(1, -(TextX + (RightW > 0 and RightW + 10 or 0)), 0, 0),
		AutomaticSize = AutoY, BackgroundTransparency = 1,
	}, Head)
	List(Column, 2)
	local Title = New("TextLabel", {
		LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, RichText = true,
		Text = O.Title or "Element", TextColor3 = Theme.Text, TextSize = 14, Font = FontBold, TextWrapped = true, TextXAlignment = Left,
	}, Column)
	local Desc
	if O.Desc then
		Desc = New("TextLabel", {
			LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, RichText = true,
			Text = O.Desc, TextColor3 = Theme.Muted, TextSize = 12, Font = FontMed, TextWrapped = true, TextXAlignment = Left,
		}, Column)
	end

	local Base = { Bg = Theme.Card, Stroke = Theme.Stroke }
	-- Interactive cards get a visible outline on hover; static ones (Paragraph, Code) stay still.
	if not O.Static then
		Card.MouseEnter:Connect(function()
			Tween(Card, 0.12, { BackgroundColor3 = Base.Bg:Lerp(White, 0.05) })
			Tween(CS, 0.12, { Color = Theme.Accent })
		end)
		Card.MouseLeave:Connect(function()
			Tween(Card, 0.12, { BackgroundColor3 = Base.Bg })
			Tween(CS, 0.12, { Color = Base.Stroke })
		end)
	end
	if Clickable then
		Head.MouseButton1Down:Connect(function()
			Tween(Card, 0.05, { BackgroundColor3 = Base.Bg:Lerp(Theme.Accent, 0.18) })
		end)
		Head.MouseButton1Up:Connect(function()
			Tween(Card, 0.12, { BackgroundColor3 = Base.Bg:Lerp(White, 0.05) })
		end)
	end

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

	-- Lock title rules:
	--   Obj:Lock("Reason")  -> shows "Reason"
	--   Obj:Lock()          -> shows the LockTitle given at creation, or just "Locked" (with the lock icon)
	local DefaultLock = O.LockTitle
	if DefaultLock == nil then DefaultLock = O.LockedTitle end
	DefaultLock = DefaultLock ~= nil and tostring(DefaultLock) or "Locked"
	SetLockText(C, DefaultLock)

	function Obj:SetTitle(T) C.Title.Text = T end
	function Obj:SetDesc(T)
		if C.Desc then C.Desc.Text = T end
	end
	function Obj:SetLockTitle(T)
		DefaultLock = tostring(T or "")
		SetLockText(C, DefaultLock)
	end
	function Obj:Lock(Title)
		Obj.Locked = true
		if Title ~= nil then SetLockText(C, Title) else SetLockText(C, DefaultLock) end
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
	local C = self:_Card(O, Checkbox and 28 or 48, true)
	local Obj = { Value = false }
	local Render, CtlStroke
	local Hovering = false

	if Checkbox then
		local Box = New("Frame", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(20, 20),
			BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0,
		}, C.Head)
		Corner(Box, 3)
		CtlStroke = Stroke(Box, Theme.Outline, 1.5)
		local Chk, ChkFB = IconLabel(Box, "check", 14, White, {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ImageTransparency = 1, ZIndex = 3,
		}, "✓")
		ChkFB.TextTransparency = 1
		ChkFB.ZIndex = 3
		Render = function(V)
			Tween(Box, 0.12, { BackgroundColor3 = V and Theme.Accent or Theme.Bg2 })
			Tween(Chk, 0.12, { ImageTransparency = V and 0 or 1 })
			Tween(ChkFB, 0.12, { TextTransparency = V and 0 or 1 })
		end
	else
		local Track = New("Frame", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(40, 20),
			BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0,
		}, C.Head)
		Corner(Track, 3)
		CtlStroke = Stroke(Track, Theme.Outline, 1.5)
		local Knob = New("Frame", {
			AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = Theme.Muted, BorderSizePixel = 0, ZIndex = 2,
		}, Track)
		Corner(Knob, 2)
		Render = function(V)
			Tween(Track, 0.15, { BackgroundColor3 = V and Theme.Accent or Theme.Bg2 })
			Tween(Knob, 0.15, {
				Position = V and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
				BackgroundColor3 = V and White or Theme.Muted,
			})
		end
	end

	-- Outline: gray when off, accent when on, brighter on hover
	local function Paint()
		local On = Obj.Value
		local Col
		if Hovering then
			Col = On and Theme.AccentSoft or Theme.Accent
		else
			Col = On and Theme.Accent or Theme.Outline
		end
		Tween(CtlStroke, 0.12, { Color = Col })
	end

	function Obj:Set(V, Silent)
		V = V and true or false
		Obj.Value = V
		Render(V)
		Paint()
		if not Silent then Call(O.Callback, V) end
	end
	C.Card.MouseEnter:Connect(function()
		Hovering = true
		Paint()
	end)
	C.Card.MouseLeave:Connect(function()
		Hovering = false
		Paint()
	end)
	C.Head.MouseButton1Click:Connect(function() Obj:Set(not Obj.Value) end)
	local Init = (O.Value == true) or (O.Default == true)
	Obj:Set(Init, not Init)
	return self:_Finish(O, Obj, C)
end

function Elements:Button(O)
	O = O or {}
	local C = self:_Card(O, 44, true)
	local Obj = {}
	local Chip = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(34, 22),
		BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
	}, C.Head)
	Corner(Chip, 3)
	IconLabel(Chip, "chevron-right", 14, White, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) }, ">")
	C.Card.MouseEnter:Connect(function() Tween(Chip, 0.12, { BackgroundColor3 = Theme.AccentSoft }) end)
	C.Card.MouseLeave:Connect(function() Tween(Chip, 0.12, { BackgroundColor3 = Theme.Accent }) end)
	C.Head.MouseButton1Click:Connect(function()
		Tween(Chip, 0.07, { Size = UDim2.fromOffset(30, 20) })
		task.delay(0.09, function()
			if Chip.Parent then Tween(Chip, 0.12, { Size = UDim2.fromOffset(34, 22) }) end
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
	local C = self:_Card(O, 80)
	local Obj = { Value = Min }

	local ValueBox = New("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(80, 20),
		BackgroundTransparency = 1, Text = "", TextColor3 = Theme.AccentSoft, TextSize = 14, Font = FontBold, TextXAlignment = Right,
		ClearTextOnFocus = false, TextEditable = O.IsTextbox == true, TextTruncate = Enum.TextTruncate.AtEnd,
	}, C.Head)
	local Holder = New("Frame", {
		LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Active = true,
	}, C.Card)
	local Track = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0), Size = UDim2.new(1, -18, 0, 6),
		BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0,
	}, Holder)
	Corner(Track, 3)
	Stroke(Track, Theme.Outline, 1)
	local Fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0 }, Track)
	Corner(Fill, 3)
	local Knob = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = White, BorderSizePixel = 0, ZIndex = 2,
	}, Track)
	Corner(Knob, 3)
	local KnobStroke = Stroke(Knob, Theme.Accent, 2)
	Holder.MouseEnter:Connect(function() Tween(KnobStroke, 0.12, { Color = Theme.AccentSoft, Thickness = 3 }) end)
	Holder.MouseLeave:Connect(function() Tween(KnobStroke, 0.12, { Color = Theme.Accent, Thickness = 2 }) end)

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
	local PillHover = false

	local Pill = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(140, 28),
		BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0, AutoButtonColor = false, Text = "",
	}, C.Head)
	Bg(Pill, 0)
	Corner(Pill, 3)
	local PillStroke = Stroke(Pill, Theme.Outline, 1.5)
	local ValueLabel = New("TextLabel", {
		Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -32, 1, 0), BackgroundTransparency = 1, Text = "",
		TextColor3 = Theme.Text, TextSize = 12, Font = FontMed, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, Pill)
	local Chevron = IconLabel(Pill, "chevron-down", 14, Theme.Muted, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0) }, "v")

	-- Closed: gray outline. Hover: accent outline + lighter fill. Open: accent outline + header fill.
	local function PaintPill()
		local Lit = Open or PillHover
		Tween(PillStroke, 0.12, { Color = Lit and Theme.Accent or Theme.Outline })
		Tween(Pill, 0.12, { BackgroundColor3 = Open and Theme.Header or (PillHover and Theme.CardHover or Theme.Bg2) })
	end
	Pill.MouseEnter:Connect(function()
		PillHover = true
		PaintPill()
	end)
	Pill.MouseLeave:Connect(function()
		PillHover = false
		PaintPill()
	end)

	local Holder = New("Frame", {
		LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0, ClipsDescendants = true, Visible = false,
		Active = true,
	}, C.Card)
	Bg(Holder, 0)
	Corner(Holder, 3)
	Stroke(Holder, Theme.Accent, 1, 0.35)
	local Scroll = New("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = AutoY,
		ScrollingDirection = Enum.ScrollingDirection.Y, Active = true,
	}, Holder)
	Pad(Scroll, 4, 4, 8, 4)
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

	-- Item states (all clearly different):
	--   idle      : no fill, no outline
	--   hover     : lighter fill + accent outline
	--   pressed   : accent-tinted fill + solid accent outline
	--   selected  : accent-tinted fill + accent bar + check
	local function Paint(B)
		local Fill, FillT, StrokeT
		if B.Locked then
			Fill, FillT, StrokeT = Theme.CardHover, 1, 1
		elseif B.Down then
			Fill, FillT, StrokeT = Theme.Accent:Lerp(Theme.Bg2, 0.45), 0, 0
		elseif B.On and B.Hover then
			Fill, FillT, StrokeT = Theme.Accent:Lerp(Theme.Bg2, 0.6), 0, 0
		elseif B.On then
			Fill, FillT, StrokeT = Theme.Accent:Lerp(Theme.Bg2, 0.76), 0, 0.5
		elseif B.Hover then
			Fill, FillT, StrokeT = Theme.CardHover, 0, 0.05
		else
			Fill, FillT, StrokeT = Theme.CardHover, 1, 1
		end
		Tween(B.Btn, 0.1, { BackgroundColor3 = Fill, BackgroundTransparency = FillT })
		Tween(B.Stroke, 0.1, { Transparency = StrokeT })
		B.Accent.Visible = B.On and not B.Locked
		if B.Locked then
			B.Lbl.TextColor3 = Theme.Muted
			B.Lbl.TextTransparency = 0.45
		else
			B.Lbl.TextTransparency = 0
			B.Lbl.TextColor3 = (B.On or B.Hover) and Theme.Text or Theme.Muted
		end
	end

	local function SetOpen(Val)
		Open = Val
		Obj.Opened = Val
		if Val then
			Holder.Visible = true
			Tween(Holder, 0.22, { Size = UDim2.new(1, 0, 0, Height()) })
		else
			Tween(Holder, 0.18, { Size = UDim2.new(1, 0, 0, 0) })
			task.delay(0.2, function()
				if not Open and Holder.Parent then Holder.Visible = false end
			end)
		end
		Tween(Chevron, 0.2, { Rotation = Val and 180 or 0 })
		PaintPill()
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
				LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = O.EmptyText or "No options",
				TextColor3 = Theme.Muted, TextSize = 12, Font = FontMed,
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
					LayoutOrder = I, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.CardHover, BackgroundTransparency = 1,
					BorderSizePixel = 0, AutoButtonColor = false, Text = "",
				}, Scroll)
				Corner(Btn, 3)
				local BStroke = Stroke(Btn, Theme.Accent, 1.2, 1)
				local Accent = New("Frame", {
					AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(3, 16),
					BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Visible = false,
				}, Btn)
				local Row = New("Frame", {
					Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -38, 1, 0), BackgroundTransparency = 1,
				}, Btn)
				List(Row, 6, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center })
				if type(Raw) == "table" and Raw.Icon then
					local Wrap = New("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1 }, Row)
					IconLabel(Wrap, Raw.Icon, 14, Theme.AccentSoft, { Position = UDim2.fromOffset(0, 0) })
				end
				local Lbl = New("TextLabel", {
					LayoutOrder = 2, Size = UDim2.fromOffset(0, 28), AutomaticSize = AutoX, BackgroundTransparency = 1, Text = Name,
					TextColor3 = Theme.Muted, TextSize = 13, Font = FontMed,
				}, Row)
				if ItemLocked then
					local LockWrap = New("Frame", { LayoutOrder = 3, Size = UDim2.fromOffset(0, 28), AutomaticSize = AutoX, BackgroundTransparency = 1 }, Row)
					List(LockWrap, 4, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center })
					local IconWrap = New("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1 }, LockWrap)
					IconLabel(IconWrap, "lock", 12, Theme.Amber, { Position = UDim2.fromOffset(0, 0) }, "•")
					if LockText ~= "" then
						New("TextLabel", {
							LayoutOrder = 2, Size = UDim2.fromOffset(0, 28), AutomaticSize = AutoX, BackgroundTransparency = 1, Text = LockText,
							TextColor3 = Theme.Amber, TextSize = 11, Font = FontBold,
						}, LockWrap)
					end
				end
				local Chk, ChkFB = IconLabel(Btn, "check", 14, Theme.AccentSoft, {
					AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Visible = false,
				}, "✓")

				local B = {
					Btn = Btn, Lbl = Lbl, Chk = Chk, ChkFB = ChkFB, Accent = Accent, Stroke = BStroke, Locked = ItemLocked,
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
				Paint(B)
				ContentH += 32
			end
		end
	end

	-- Replace the option list. Anything no longer in the list is dropped from the selection.
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
		if Open then Tween(Holder, 0.18, { Size = UDim2.new(1, 0, 0, Height()) }) end
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
	local Hovering, Focused = false, false

	local Pill
	if Textarea then
		Pill = New("Frame", {
			LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 72), BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0, ClipsDescendants = true,
			Active = true,
		}, C.Card)
	else
		Pill = New("Frame", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(170, 28),
			BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0, ClipsDescendants = true, Active = true,
		}, C.Head)
	end
	Bg(Pill, 0)
	Corner(Pill, 3)
	local PS = Stroke(Pill, Theme.Outline, 1.5)

	local TX = 8
	if O.InputIcon then
		IconLabel(Pill, O.InputIcon, 14, Theme.Muted, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, Textarea and 0 or 0.5, Textarea and 14 or 0) })
		TX = 28
	end
	local TB = New("TextBox", {
		Position = UDim2.fromOffset(TX, Textarea and 4 or 0), Size = UDim2.new(1, -(TX + 8), 1, Textarea and -8 or 0),
		BackgroundTransparency = 1, Text = "", PlaceholderText = O.Placeholder or "Enter text...", PlaceholderColor3 = Theme.Muted,
		TextColor3 = Theme.Text, TextSize = 13, Font = FontMed, ClearTextOnFocus = O.ClearTextOnFocus == true, TextXAlignment = Left,
		TextYAlignment = Textarea and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center, MultiLine = Textarea, TextWrapped = Textarea,
	}, Pill)
	Obj.TextBox = TB

	-- Outline: gray idle, accent on hover, soft accent while typing
	local function Paint()
		local Col = Focused and Theme.AccentSoft or (Hovering and Theme.Accent or Theme.Outline)
		Tween(PS, 0.12, { Color = Col, Thickness = Focused and 2 or 1.5 })
	end
	local function Hover(On)
		Hovering = On
		Paint()
	end
	Pill.MouseEnter:Connect(function() Hover(true) end)
	Pill.MouseLeave:Connect(function() Hover(false) end)
	TB.MouseEnter:Connect(function() Hover(true) end)
	TB.MouseLeave:Connect(function() Hover(false) end)
	TB.Focused:Connect(function()
		Focused = true
		Paint()
	end)

	function Obj:Set(Val, Silent)
		Val = tostring(Val or "")
		TB.Text = Val
		Obj.Value = Val
		if not Silent then Call(O.Callback, Val) end
	end
	function Obj:SetPlaceholder(T) TB.PlaceholderText = T end
	TB.FocusLost:Connect(function()
		Focused = false
		Paint()
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
	local Hovering = false

	local Pill = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(86, 28),
		BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0, AutoButtonColor = false, Text = "None", TextColor3 = Theme.Text,
		TextSize = 12, Font = FontBold,
	}, C.Head)
	Bg(Pill, 0)
	Corner(Pill, 3)
	local PS = Stroke(Pill, Theme.Outline, 1.5)

	local function Paint()
		local Col = Listening and Theme.AccentSoft or (Hovering and Theme.Accent or Theme.Outline)
		Tween(PS, 0.12, { Color = Col })
		Tween(Pill, 0.12, { BackgroundColor3 = Listening and Theme.Header or (Hovering and Theme.CardHover or Theme.Bg2) })
	end
	Pill.MouseEnter:Connect(function()
		Hovering = true
		Paint()
	end)
	Pill.MouseLeave:Connect(function()
		Hovering = false
		Paint()
	end)

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
		Paint()
	end)

	self.Win:Connect(UserInputService.InputBegan, function(I, Processed)
		if Listening then
			if I.UserInputType == Enum.UserInputType.Keyboard then
				Listening = false
				Obj:Set(I.KeyCode == Enum.KeyCode.Escape and "None" or I.KeyCode.Name)
				Paint()
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
	local Default = O.Default or Theme.Accent
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
	Corner(Swatch, 3)
	local SwStroke = Stroke(Swatch, Theme.Outline, 1.5)
	Swatch.MouseEnter:Connect(function() Tween(SwStroke, 0.12, { Color = Theme.Accent }) end)
	Swatch.MouseLeave:Connect(function() Tween(SwStroke, 0.12, { Color = Theme.Outline }) end)

	local Holder = New("Frame", {
		LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, ClipsDescendants = true, Visible = false,
	}, C.Card)

	local SV = New("Frame", { Size = UDim2.new(1, -30, 0, PH), BackgroundColor3 = Color3.fromHSV(H, 1, 1), BorderSizePixel = 0 }, Holder)
	Corner(SV, 3)
	local WhiteOv = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = White, BorderSizePixel = 0 }, SV)
	Corner(WhiteOv, 3)
	New("UIGradient", { Transparency = NumberSequence.new(0, 1) }, WhiteOv)
	local BlackOv = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0 }, SV)
	Corner(BlackOv, 3)
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
	Corner(HueBar, 3)
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
		Corner(AlphaBar, 3)
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
			Tween(Holder, 0.22, { Size = UDim2.new(1, 0, 0, TotalH) })
		else
			Tween(Holder, 0.18, { Size = UDim2.new(1, 0, 0, 0) })
			task.delay(0.2, function()
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
	local C = self:_Card({ Title = O.Title, Desc = O.Desc, Icon = O.Image or O.Icon, IconSize = O.ImageSize or 30, Static = true }, 0, false)
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
			Corner(Thumb, 3)
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
				LayoutOrder = I, Size = UDim2.fromOffset(0, 30), AutomaticSize = AutoX, BackgroundColor3 = Theme.Header,
				BorderSizePixel = 0, AutoButtonColor = false, Text = "",
			}, Row)
			Corner(Btn, 3)
			local BS = Stroke(Btn, Theme.Outline, 1)
			Pad(Btn, 10, 0, 10, 0)
			local Inner = New("Frame", { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AutoX, BackgroundTransparency = 1 }, Btn)
			List(Inner, 6, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center })
			if B.Icon then
				local Wrap = New("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1 }, Inner)
				IconLabel(Wrap, B.Icon, 14, Theme.AccentSoft, { Position = UDim2.fromOffset(0, 0) }, "•")
			end
			New("TextLabel", {
				LayoutOrder = 2, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AutoX, BackgroundTransparency = 1,
				Text = B.Title or "Button", TextColor3 = Theme.Text, TextSize = 12, Font = FontBold,
			}, Inner)
			Btn.MouseEnter:Connect(function()
				Tween(BS, 0.12, { Color = Theme.Accent })
				Tween(Btn, 0.12, { BackgroundColor3 = Theme.CardHover })
			end)
			Btn.MouseLeave:Connect(function()
				Tween(BS, 0.12, { Color = Theme.Outline })
				Tween(Btn, 0.12, { BackgroundColor3 = Theme.Header })
			end)
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
	local C = self:_Card({ Title = O.Title or "Code", Icon = O.Icon, Static = true }, 64, false)
	local Obj = { Value = O.Code or "" }
	local Block = New("Frame", {
		LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundColor3 = Theme.Bg, BorderSizePixel = 0,
	}, C.Card)
	Bg(Block, 0)
	Corner(Block, 3)
	Stroke(Block, Theme.Stroke, 1)
	Pad(Block, 10, 8, 10, 8)
	local Lbl = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, Text = Obj.Value, TextColor3 = Theme.AccentSoft,
		TextSize = 13, Font = Enum.Font.Code, TextWrapped = true, TextXAlignment = Left, TextYAlignment = Enum.TextYAlignment.Top,
	}, Block)
	local Copy = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(60, 26),
		BackgroundColor3 = Theme.Header, BorderSizePixel = 0, AutoButtonColor = false, Text = "Copy", TextColor3 = Theme.Text,
		TextSize = 12, Font = FontBold,
	}, C.Head)
	Corner(Copy, 3)
	local CopyStroke = Stroke(Copy, Theme.Outline, 1)
	Copy.MouseEnter:Connect(function()
		Tween(CopyStroke, 0.12, { Color = Theme.Accent })
		Tween(Copy, 0.12, { BackgroundColor3 = Theme.CardHover })
	end)
	Copy.MouseLeave:Connect(function()
		Tween(CopyStroke, 0.12, { Color = Theme.Outline })
		Tween(Copy, 0.12, { BackgroundColor3 = Theme.Header })
	end)
	Copy.MouseButton1Click:Connect(function()
		CopyText(Obj.Value)
		Copy.Text = "Copied"
		task.delay(1.2, function()
			if Copy.Parent then Copy.Text = "Copy" end
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
	return New("Frame", {
		LayoutOrder = self:_Next(), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0,
	}, self.Parent)
end

function Elements:Space(O)
	local H = type(O) == "number" and O or (type(O) == "table" and O.Size) or ((type(O) == "table" and O.Columns or 1) * 8)
	return New("Frame", { LayoutOrder = self:_Next(), Size = UDim2.new(1, 0, 0, H), BackgroundTransparency = 1 }, self.Parent)
end

-- Section: a visible header bar (accent notch, outline) with a boxed body underneath.
-- Pass Box = false for the old header-only look.
function Elements:Section(O)
	if type(O) == "string" then O = { Title = O } end
	O = O or {}
	local Wrap = New("Frame", { LayoutOrder = self:_Next(), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1 }, self.Parent)
	List(Wrap, 6)

	local Align = ({ Left = Left, Center = Enum.TextXAlignment.Center, Right = Right })[O.TextXAlignment or "Left"] or Left
	local Header = New("TextButton", {
		LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Theme.Header, BorderSizePixel = 0, Text = "", AutoButtonColor = false,
	}, Wrap)
	Bg(Header, 0)
	Corner(Header, 4)
	local HS = Stroke(Header, Theme.Outline, 1)
	local Notch = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 3, 1, -12),
		BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
	}, Header)
	local TX = 14
	if O.Icon then
		IconLabel(Header, O.Icon, 16, Theme.AccentSoft, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0) }, "•")
		TX = 38
	end
	local Lbl = New("TextLabel", {
		Position = UDim2.fromOffset(TX, 0), Size = UDim2.new(1, -(TX + 30), 1, 0), BackgroundTransparency = 1, RichText = true,
		Text = O.Title or "Section", TextColor3 = Theme.Text, TextTransparency = O.TextTransparency or 0,
		TextSize = O.TextSize or 14, Font = FontBold, TextXAlignment = Align,
	}, Header)
	local Chev = IconLabel(Header, "chevron-down", 14, Theme.Muted, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0) }, "v")
	Header.MouseEnter:Connect(function()
		Tween(HS, 0.12, { Color = Theme.Accent })
		Tween(Header, 0.12, { BackgroundColor3 = Theme.CardHover })
	end)
	Header.MouseLeave:Connect(function()
		Tween(HS, 0.12, { Color = Theme.Outline })
		Tween(Header, 0.12, { BackgroundColor3 = Theme.Header })
	end)

	local Body = New("Frame", {
		LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundColor3 = Theme.Bg2, BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, Wrap)
	if O.Box ~= false then
		Bg(Body, 0.25)
		Corner(Body, 4)
		Stroke(Body, Theme.Stroke, 1, 0.4)
		Pad(Body, 8, 8, 8, 8)
	end
	List(Body, 6)

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
	-- Lock title rules: Tab:Lock("Reason") shows the reason, Tab:Lock() shows LockTitle from creation or just "Locked"
	local DefaultLock = "Locked"
	if O.LockTitle ~= nil then DefaultLock = tostring(O.LockTitle) elseif O.LockedTitle ~= nil then DefaultLock = tostring(O.LockedTitle) end
	local Tab = setmetatable({ Win = self, _n = 0, Title = O.Title or "Tab", Locked = false, LockTitle = DefaultLock }, TabClass)

	local Btn = New("TextButton", {
		LayoutOrder = self:_NextSide(), Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.Header, BackgroundTransparency = 1,
		BorderSizePixel = 0, AutoButtonColor = false, Text = "",
	}, ParentFrame)
	Corner(Btn, 4)
	local BStroke = Stroke(Btn, Theme.Stroke, 1, 1)
	local Bar = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(3, 16),
		BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Visible = false,
	}, Btn)

	local IconRight = O.IconAlign == "Right"
	local Ico, IcoFB
	local TextL = 12
	if O.Icon then
		if IconRight then
			Ico, IcoFB = IconLabel(Btn, O.Icon, 17, Theme.Muted, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -11, 0.5, 0) }, "•")
		else
			Ico, IcoFB = IconLabel(Btn, O.Icon, 17, Theme.Muted, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0) }, "•")
			TextL = 38
		end
	end
	local LockIco, LockFB = IconLabel(Btn, "lock", 14, Theme.Amber, {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -11, 0.5, 0), Visible = false,
	}, "•")

	local Lbl = New("TextLabel", {
		Position = UDim2.fromOffset(TextL, 0), Size = UDim2.new(1, -(TextL + 10), 1, 0), BackgroundTransparency = 1,
		Text = Tab.Title, TextColor3 = Theme.Muted, TextSize = 13, Font = FontBold, TextXAlignment = Left,
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
		ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = AutoY,
		ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false, Active = true,
	}, self.Content)
	Pad(Page, 3, 3, 12, 6)
	List(Page, 8)

	Tab.Parent, Tab.Page, Tab.TabButton = Page, Page, Btn

	local Selected, Hover = false, false
	-- idle: plain | hover: outline + light fill | selected: fill + accent outline + accent bar
	local function Paint()
		if Tab.Locked then
			Tween(Btn, 0.12, { BackgroundTransparency = 1 })
			Tween(BStroke, 0.12, { Transparency = 1 })
			Bar.Visible = false
			return
		end
		if Selected then
			Tween(Btn, 0.12, { BackgroundTransparency = 0 })
			Tween(BStroke, 0.12, { Color = Theme.Accent, Transparency = 0.15 })
		elseif Hover then
			Tween(Btn, 0.12, { BackgroundTransparency = 0.4 })
			Tween(BStroke, 0.12, { Color = Theme.Outline, Transparency = 0 })
		else
			Tween(Btn, 0.12, { BackgroundTransparency = 1 })
			Tween(BStroke, 0.12, { Color = Theme.Stroke, Transparency = 1 })
		end
		Bar.Visible = Selected
		Tween(Lbl, 0.12, { TextColor3 = (Selected or Hover) and Theme.Text or Theme.Muted })
		if Ico then Tween(Ico, 0.12, { ImageColor3 = Selected and Theme.AccentSoft or Theme.Muted }) end
	end

	function Tab:_SetActive(On, Instant)
		Selected = On
		Paint()
		if On then
			Page.Visible = true
			if not Instant and WinRef._moving ~= false then
				Page.Position = UDim2.fromOffset(0, 10)
				Tween(Page, 0.25, { Position = UDim2.fromOffset(0, 0) })
			end
		else
			Page.Visible = false
		end
	end
	function Tab:Lock(Title)
		Tab.Locked = true
		if Title ~= nil then Tab.LockTitle = tostring(Title) else Tab.LockTitle = DefaultLock end
		Lbl.TextTransparency = 0.5
		if IconRight then ShowIcon(Ico, IcoFB, false) end
		ShowIcon(LockIco, LockFB, true)
		Reflow()
		Paint()
	end
	function Tab:Unlock()
		Tab.Locked = false
		Lbl.TextTransparency = 0
		ShowIcon(LockIco, LockFB, false)
		if IconRight then ShowIcon(Ico, IcoFB, true) end
		Reflow()
		Paint()
	end
	function Tab:SetTitle(T)
		Tab.Title = T
		Lbl.Text = T
	end
	function Tab:SetLockTitle(T)
		DefaultLock = tostring(T or "")
		Tab.LockTitle = DefaultLock
	end
	function Tab:Destroy()
		local I = table.find(self.Win.Tabs, Tab)
		if I then table.remove(self.Win.Tabs, I) end
		if self.Win.CurrentTab == Tab then self.Win.CurrentTab = nil end
		Page:Destroy()
		Btn:Destroy()
	end
	if O.Locked == true then Tab:Lock() end

	Btn.MouseEnter:Connect(function()
		Hover = true
		if not Tab.Locked then Paint() end
	end)
	Btn.MouseLeave:Connect(function()
		Hover = false
		if not Tab.Locked then Paint() end
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
	local Header = New("TextButton", { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, Wrap)
	local TX = 6
	if O.Icon then
		IconLabel(Header, O.Icon, 14, Theme.Muted, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0) }, "•")
		TX = 26
	end
	local HLbl = New("TextLabel", {
		Position = UDim2.fromOffset(TX, 0), Size = UDim2.new(1, -(TX + 28), 1, 0), BackgroundTransparency = 1, Text = StripRich(O.Title or "Section"),
		TextColor3 = Theme.Muted, TextSize = 12, Font = FontBold, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, Header)
	local Chev = IconLabel(Header, "chevron-down", 14, Theme.Muted, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0) }, "v")
	Header.MouseEnter:Connect(function() Tween(HLbl, 0.12, { TextColor3 = Theme.Text }) end)
	Header.MouseLeave:Connect(function() Tween(HLbl, 0.12, { TextColor3 = Theme.Muted }) end)
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
	return New("Frame", {
		LayoutOrder = self:_NextSide(), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0,
	}, self.Sidebar)
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

-- 0 = fully solid, 1 = fully see-through. Affects the window, cards, inputs,
-- dialogs and notifications. Tags are never affected.
function Window:SetBackgroundTransparency(V)
	Library:SetBackgroundTransparency(V)
end

----------------------------------------------------------------------
-- Tags: shown left -> right in the exact order they were added.
-- They live in a scrollable strip on the right side of the title bar.
-- Each tag sits inside a holder with 2px of room on every side, so the
-- strip's clipping never cuts the tag outline. Tags keep their own fixed
-- transparency (not affected by BackgroundTransparency).
----------------------------------------------------------------------
function Window:Tag(O)
	if type(O) == "string" then O = { Title = O } end
	O = O or {}
	self._tagN += 1
	local Col = O.Color or Theme.Accent
	local Holder = New("Frame", {
		Name = "TagHolder", LayoutOrder = self._tagN, Size = UDim2.fromOffset(0, 34), AutomaticSize = AutoX, BackgroundTransparency = 1,
	}, self.TagFrame)
	Pad(Holder, 2, 0, 2, 0)
	local Tag = New("Frame", {
		Name = "Tag", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(0, 24),
		AutomaticSize = AutoX, BackgroundColor3 = Col, BackgroundTransparency = O.Transparency or 0.75, BorderSizePixel = 0,
	}, Holder)
	Corner(Tag, math.clamp(O.Radius or 3, 0, 12))
	Stroke(Tag, Col, 1, 0.1)
	Pad(Tag, 9, 0, 9, 0)
	List(Tag, 5, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center })
	if O.Icon then
		local Wrap = New("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1 }, Tag)
		IconLabel(Wrap, O.Icon, 14, Col:Lerp(White, 0.4), nil, "•")
	end
	local Lbl = New("TextLabel", {
		LayoutOrder = 2, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AutoX, BackgroundTransparency = 1,
		Text = O.Title or "Tag", TextColor3 = Col:Lerp(White, 0.6), TextSize = 12, Font = FontBold,
	}, Tag)
	local Obj = {}
	function Obj:SetTitle(T) Lbl.Text = T end
	function Obj:Destroy() Holder:Destroy() end
	return Obj
end

function Window:Notify(O) return Library:Notify(O) end

function Window:Dialog(O)
	local D = BuildDialog(self.Host, O)
	D:Show()
	return D
end

function Window:LockAll(Title) for _, E in ipairs(self._Elements) do E:Lock(Title) end end
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

----------------------------------------------------------------------
-- Configs (optional): the Window API below always works. The UI for it
-- (Window:ConfigTab / Window:ConfigSection) is only built if you call it.
----------------------------------------------------------------------
-- Rebuilds every config dropdown from disk. Deleted configs disappear here.
function Window:_RefreshConfigs()
	local Names = self.ConfigManager:AllConfigs()
	if self.SelectedConfig and not table.find(Names, self.SelectedConfig) then
		self.SelectedConfig = nil
	end
	for I = #self._configDropdowns, 1, -1 do
		local D = self._configDropdowns[I]
		local Ok = pcall(function()
			D:Refresh(Names)
			D:Select(self.SelectedConfig, true)
		end)
		if not Ok then table.remove(self._configDropdowns, I) end
	end
end

function Window:SelectConfig(Name, Silent)
	Name = Name and self.ConfigManager:Sanitize(Name) or nil
	if Name == "" then Name = nil end
	self.SelectedConfig = Name
	for _, D in ipairs(self._configDropdowns) do
		pcall(function() D:Select(Name, true) end)
	end
end

-- Returns the config, or false + a message
function Window:CreateConfig(Name)
	local CM = self.ConfigManager
	local Clean = CM:Sanitize(Name)
	if Clean == "" then return false, "Type a config name first" end
	if CM:ConfigExists(Clean) then return false, "A config named '" .. Clean .. "' already exists" end
	local Cfg = CM:CreateConfig(Clean)
	if not Cfg:Save() then
		CM.Configs[Clean] = nil
		return false, "Could not write the config file"
	end
	self.SelectedConfig = Clean
	self:_RefreshConfigs()
	return Cfg
end

function Window:SaveConfig(Name)
	local CM = self.ConfigManager
	Name = CM:Sanitize(Name or self.SelectedConfig or "default")
	if Name == "" then Name = "default" end
	local Cfg = CM.Configs[Name] or CM:CreateConfig(Name)
	local Ok = Cfg:Save()
	if Ok then self:_RefreshConfigs() end
	return Ok
end

function Window:LoadConfig(Name)
	local CM = self.ConfigManager
	Name = CM:Sanitize(Name or self.SelectedConfig or "default")
	if Name == "" then Name = "default" end
	local Cfg = CM.Configs[Name] or CM:CreateConfig(Name)
	return Cfg:Load()
end

function Window:DeleteConfig(Name)
	local CM = self.ConfigManager
	Name = CM:Sanitize(Name or self.SelectedConfig or "")
	if Name == "" then return false end
	local Ok = CM:DeleteConfig(Name)
	if self.SelectedConfig == Name then self.SelectedConfig = nil end
	self:_RefreshConfigs()
	return Ok
end

function Window:DeleteSelectedConfig()
	if not self.SelectedConfig then return false end
	return self:DeleteConfig(self.SelectedConfig)
end

function Window:GetConfigs()
	return self.ConfigManager:AllConfigs()
end

function Window:ConfigExists(Name)
	return self.ConfigManager:ConfigExists(Name)
end

-- Optional UI. Container = a Tab or Section. Options:
--   Section = true|false (wrap in a section, default true), Title, Icon,
--   ConfirmDelete = false (skip the confirm dialog), Notify = false (no toasts)
function Window:ConfigSection(Container, O)
	O = O or {}
	local Win = self
	local Group = Container
	if O.Section ~= false then
		Group = Container:Section({ Title = O.Title or "Configs", Icon = O.Icon or "save" })
	end
	local function Say(Type, Title, Content)
		if O.Notify == false then return end
		Library:Notify({ Title = Title, Content = Content, Type = Type, Icon = Type == "error" and "x" or (Type == "warn" and "alert-triangle" or "check"), Duration = 3 })
	end

	local NameInput = Group:Input({
		Title = "Config name", Desc = "Letters, numbers, spaces, - and _", Placeholder = "my config", InputIcon = "pencil",
	})
	local Dropdown = Group:Dropdown({
		Title = "Saved configs", Values = Win:GetConfigs(), Placeholder = "Select a config", EmptyText = "No configs yet",
		AllowNone = true, Callback = function(V) Win.SelectedConfig = V end,
	})
	table.insert(Win._configDropdowns, Dropdown)
	if Win.SelectedConfig then Dropdown:Select(Win.SelectedConfig, true) end

	Group:Button({
		Title = "Create config", Desc = "Saves your current settings under the name above", Icon = "plus",
		Callback = function()
			local Cfg, Err = Win:CreateConfig(NameInput.TextBox.Text)
			if Cfg then
				NameInput:Set("", true)
				Say("success", "Config created", Cfg.Name)
			else
				Say("error", "Can't create config", Err)
			end
		end,
	})
	Group:Button({
		Title = "Save config", Desc = "Overwrites the selected config with your current settings", Icon = "save",
		Callback = function()
			local N = Win.SelectedConfig
			if not N then return Say("warn", "No config selected", "Pick one from the dropdown or create a new one") end
			if Win:SaveConfig(N) then Say("success", "Config saved", N) else Say("error", "Save failed", N) end
		end,
	})
	Group:Button({
		Title = "Load config", Desc = "Applies the selected config", Icon = "folder-open",
		Callback = function()
			local N = Win.SelectedConfig
			if not N then return Say("warn", "No config selected", "Pick one from the dropdown first") end
			if Win:LoadConfig(N) then Say("success", "Config loaded", N) else Say("error", "Load failed", "'" .. N .. "' could not be read") end
		end,
	})
	Group:Button({
		Title = "Delete selected config", Desc = "Removes it from disk and from the list", Icon = "trash-2",
		Callback = function()
			local N = Win.SelectedConfig
			if not N then return Say("warn", "No config selected", "Pick one from the dropdown first") end
			local function Run()
				Win:DeleteConfig(N)
				Say("success", "Config deleted", N)
			end
			if O.ConfirmDelete == false then
				Run()
			else
				Win:Dialog({
					Title = "Delete config", Icon = "trash-2", Content = "Delete <b>" .. N .. "</b>? This can't be undone.",
					Buttons = {
						{ Title = "Cancel", Variant = "Secondary" },
						{ Title = "Delete", Variant = "Danger", Callback = Run },
					},
				})
			end
		end,
	})
	return { Input = NameInput, Dropdown = Dropdown, Refresh = function() Win:_RefreshConfigs() end }
end

function Window:ConfigTab(O)
	O = O or {}
	local Opts = {}
	for K, V in pairs(O) do Opts[K] = V end
	if Opts.Section == nil then Opts.Section = false end
	local Tab = self:Tab({ Title = O.TabTitle or O.Title or "Config", Icon = O.TabIcon or O.Icon or "save" })
	self:ConfigSection(Tab, Opts)
	return Tab
end

-- Optional settings. Container = a Tab or Section. Options:
--   Section = true|false, Title, Icon,
--   MovingAnimation = false / Particles = false (leave that toggle out),
--   Transparency = true (adds a window transparency slider),
--   SaveInConfig = true (include these toggles in saved configs)
function Window:SettingsSection(Container, O)
	O = O or {}
	local Win = self
	local Group = Container
	if O.Section ~= false then
		Group = Container:Section({ Title = O.Title or "Interface", Icon = O.Icon or "settings" })
	end
	local function F(Name) return O.SaveInConfig and Name or nil end

	if O.MovingAnimation ~= false then
		Group:Toggle({
			Title = "Disable moving animation", Desc = "Stops the drifting background and the tab slide-in",
			Flag = F("ToolkitUI_DisableMoving"), Value = not Win._moving,
			Callback = function(V) Win:SetMovingAnimation(not V) end,
		})
	end
	if O.Particles ~= false then
		Group:Toggle({
			Title = "Disable particles", Desc = "Hides the floating dots in the background",
			Flag = F("ToolkitUI_DisableParticles"), Value = not Win._particles,
			Callback = function(V) Win:SetParticles(not V) end,
		})
	end
	if O.Transparency then
		Group:Slider({
			Title = "Window transparency", Flag = F("ToolkitUI_Transparency"),
			Value = { Min = 0, Max = 0.9, Default = Library.BackgroundTransparency },
			Step = 0.05, Callback = function(V) Win:SetBackgroundTransparency(V) end,
		})
	end
	return Group
end

-- One tab with the settings, and (with Config = true) the config section too
function Window:SettingsTab(O)
	O = O or {}
	local Opts = {}
	for K, V in pairs(O) do Opts[K] = V end
	local Tab = self:Tab({ Title = O.TabTitle or "Settings", Icon = O.TabIcon or "settings" })
	self:SettingsSection(Tab, Opts)
	if O.Config then
		self:ConfigSection(Tab, { Title = O.ConfigTitle, ConfirmDelete = O.ConfirmDelete, Notify = O.Notify })
	end
	return Tab
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
	local Ok, T = pcall(Tween, self.RootScale, 0.2, { Scale = 0.85 }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
	local function Kill() pcall(function() self.Gui:Destroy() end) end
	if Ok and T then T.Completed:Connect(Kill) else Kill() end
end

local function MakeConfigManager(Win)
	-- Deleted = names hidden for this session when the executor can't delete files
	local CM = { Configs = {}, Deleted = {} }
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
	Ensure()

	function CM:Sanitize(Name)
		local Clean = tostring(Name or ""):gsub("[^%w%-_ ]", "")
		Clean = Clean:gsub("^%s+", "")
		Clean = Clean:gsub("%s+$", "")
		Clean = Clean:sub(1, 32)
		Clean = Clean:gsub("%s+$", "")
		return Clean
	end

	function CM:ConfigPath(Name)
		return Dir .. "/" .. Name .. ".json"
	end

	function CM:ConfigExists(Name)
		Name = CM:Sanitize(Name)
		if Name == "" or CM.Deleted[Name] then return false end
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
			CM.Deleted[Name] = nil
			if not CanWrite then
				Cfg.Memory = Data
				return true
			end
			Ensure()
			return (pcall(function() writefile(Path, HttpService:JSONEncode(Data)) end))
		end

		function Cfg:Load()
			if CM.Deleted[Name] then return false end
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
		-- If the file is still there (no delfile support), hide the name so it is gone from the list
		if HasList then
			local Ok, R = pcall(isfile, Path)
			if Ok and R == true then CM.Deleted[Name] = true end
		end
		return true
	end

	function CM:AllConfigs()
		local L, Seen = {}, {}
		if HasList then
			pcall(function()
				for _, F in ipairs(listfiles(Dir)) do
					local N = F:match("([^/\\]+)%.json$")
					if N and not Seen[N] and not CM.Deleted[N] then
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
		Name = "KeyGate", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, ZIndex = 90, Active = true,
	}, Win.Main)
	Bg(Gate, 0)
	Corner(Gate, MAIN_RADIUS)

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
		Corner(Img, 6)
		SetLucide(Img, KS.Thumbnail.Image)
		TI += 1
	end
	New("TextLabel", {
		LayoutOrder = TI, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = (KS.Thumbnail and KS.Thumbnail.Title) or "Key required",
		TextColor3 = Theme.Text, TextSize = 20, Font = FontBold, ZIndex = 91,
	}, Box)
	New("TextLabel", {
		LayoutOrder = TI + 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, Text = KS.Note or "Enter your key to continue.",
		TextColor3 = Theme.Muted, TextSize = 13, Font = FontMed, TextWrapped = true, ZIndex = 91,
	}, Box)

	local Pill = New("Frame", { LayoutOrder = TI + 2, Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0, ZIndex = 91 }, Box)
	Bg(Pill, 0)
	Corner(Pill, 3)
	local PS = Stroke(Pill, Theme.Outline, 1.5)
	local TB = New("TextBox", {
		Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = "Enter key...",
		PlaceholderColor3 = Theme.Muted, TextColor3 = Theme.Text, TextSize = 14, Font = FontMed, ClearTextOnFocus = false, TextXAlignment = Left, ZIndex = 92,
	}, Pill)
	TB.Focused:Connect(function() Tween(PS, 0.12, { Color = Theme.AccentSoft }) end)
	TB.FocusLost:Connect(function() Tween(PS, 0.12, { Color = Theme.Outline }) end)

	local StatusL = New("TextLabel", {
		LayoutOrder = TI + 3, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = "", TextColor3 = Theme.Muted,
		TextSize = 12, Font = FontMed, ZIndex = 91,
	}, Box)

	local Row = New("Frame", { LayoutOrder = TI + 4, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, ZIndex = 91 }, Box)
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
			StatusL.Text = "Key accepted"
			StatusL.TextColor3 = Theme.Green
			Unlock(K)
		else
			StatusL.Text = "Invalid key"
			StatusL.TextColor3 = Theme.Red
			Tween(PS, 0.2, { Color = Theme.Red })
			task.delay(1, function()
				if PS.Parent then Tween(PS, 0.3, { Color = Theme.Outline }) end
			end)
		end
	end

	if KS.URL then
		local Get = New("TextButton", {
			LayoutOrder = 1, Size = UDim2.new(0.5, -4, 1, 0), BackgroundColor3 = Theme.Header, BorderSizePixel = 0,
			AutoButtonColor = false, Text = "Get key", TextColor3 = Theme.Text, TextSize = 13, Font = FontBold, ZIndex = 92,
		}, Row)
		Corner(Get, 3)
		local GS = Stroke(Get, Theme.Outline, 1.2)
		Get.MouseEnter:Connect(function()
			Tween(GS, 0.12, { Color = Theme.Accent })
			Tween(Get, 0.12, { BackgroundColor3 = Theme.CardHover })
		end)
		Get.MouseLeave:Connect(function()
			Tween(GS, 0.12, { Color = Theme.Outline })
			Tween(Get, 0.12, { BackgroundColor3 = Theme.Header })
		end)
		Get.MouseButton1Click:Connect(function()
			local Ok = CopyText(KS.URL)
			StatusL.Text = Ok and "Key link copied" or "Copy failed"
			StatusL.TextColor3 = Ok and Theme.AccentSoft or Theme.Red
		end)
	end
	local Submit, SH = SolidButton(Row, "Submit", UDim2.new(KS.URL and 0.5 or 1, KS.URL and -4 or 0, 1, 0), UDim2.new(), Theme.Accent, 13)
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

	-- Optional: BackgroundTransparency = 0..1 (applies to window, cards, dialogs, notifications; never to Tags)
	if type(O.BackgroundTransparency) == "number" then
		Library:SetBackgroundTransparency(O.BackgroundTransparency)
	end

	local Size = typeof(O.Size) == "UDim2" and O.Size or UDim2.fromOffset(600, 400)
	local BASE_W, BASE_H = Size.X.Offset, Size.Y.Offset
	local SBW = math.clamp(O.SideBarWidth or 160, 120, math.floor(BASE_W * 0.4))
	local FolderName = O.Folder or O.ConfigFolder or "ToolkitUI"
	local Name = "ToolkitUI_" .. FolderName
	local UserCfg = type(O.User) == "table" and O.User.Enabled and O.User or nil
	local PlainTitle = StripRich(O.Title or "ToolkitUI")

	local Win = setmetatable({
		Connections = {}, Tabs = {}, Destroyed = false, Hidden = false, _side = 0, _tagN = 0, _Elements = {}, FlagElements = {},
		Folder = FolderName, ToggleKey = O.ToggleKey or Enum.KeyCode.RightShift, _openButton = true,
		_moving = O.MovingAnimation ~= false, _particles = O.Particles ~= false, _configDropdowns = {}, SelectedConfig = nil,
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
	local RootScale = New("UIScale", { Scale = TargetScale * 0.9 }, Root)
	Win.Root, Win.RootScale = Root, RootScale

	-- Re-fit the window when the screen size changes (rotation, resize)
	pcall(function()
		local Cam = workspace.CurrentCamera
		if Cam then
			Win:Connect(Cam:GetPropertyChangedSignal("ViewportSize"), function()
				TargetScale = ComputeScale()
				if not Win.Destroyed and RootScale.Parent then Tween(RootScale, 0.2, { Scale = TargetScale }) end
			end)
		end
	end)

	local Main = New("Frame", {
		Name = "Main", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Bg,
		BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 2, Active = true,
	}, Root)
	Bg(Main, O.Transparent and 0.12 or 0)
	Corner(Main, MAIN_RADIUS)
	Stroke(Main, Theme.Outline, 1.5, 0)
	Win.Main = Main

	-- Background: very faint accent glows and dots. "Moving animation" and "Particles" can be turned off.
	local Background = New("CanvasGroup", { Name = "Background", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1 }, Main)
	Corner(Background, MAIN_RADIUS)
	local Orb1 = Orb(Theme.Accent, 0.1, 0.08, 340, 0.88, Background)
	local Orb2 = Orb(Theme.Accent, 0.95, 0.95, 320, 0.9, Background)
	local Particles = MakeParticles(Background, 12)
	Win._applyParticles = function()
		for _, P in ipairs(Particles) do P.Obj.Visible = Win._particles end
	end
	Win._applyParticles()

	local TopBar = New("Frame", { Name = "TopBar", Size = UDim2.new(1, 0, 0, 54), BackgroundTransparency = 1, ZIndex = 5 }, Main)
	local Logo = New("Frame", {
		Size = UDim2.fromOffset(32, 32), Position = UDim2.fromOffset(14, 11), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
	}, TopBar)
	Corner(Logo, 4)
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
		Text = O.Title or "ToolkitUI", TextColor3 = Theme.Text, TextSize = 17, Font = FontBold, TextXAlignment = Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, TopBar)
	Win.AuthorLabel = New("TextLabel", {
		Position = UDim2.fromOffset(58, 30), Size = UDim2.fromOffset(BASE_W - 250, 16), BackgroundTransparency = 1,
		Text = O.Author or "", TextColor3 = Theme.Muted, TextSize = 12, Font = FontMed, TextXAlignment = Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, TopBar)

	local CloseButton = IconButton(TopBar, "×", UDim2.new(1, -40, 0, 14), Theme.Red:Lerp(Theme.Bg, 0.35))
	local MinButton = IconButton(TopBar, "–", UDim2.new(1, -72, 0, 14), Theme.Accent:Lerp(Theme.Bg, 0.3))

	-- Tag strip: scrollable, right side of the title bar, separated from the – and × buttons.
	-- TagOffset = distance (px) from the window's right edge to the strip's right edge.
	local TAG_EDGE = tonumber(O.TagOffset) or 108
	local TagSep = New("Frame", {
		Name = "TagSeparator", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -(TAG_EDGE - 18), 0, 15),
		Size = UDim2.fromOffset(1, 24), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Visible = false,
	}, TopBar)
	local TagScroll = New("ScrollingFrame", {
		Name = "Tags", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -TAG_EDGE, 0, 10), Size = UDim2.fromOffset(0, 34),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = AutoX, ScrollingDirection = Enum.ScrollingDirection.X,
		ElasticBehavior = Enum.ElasticBehavior.Never, ClipsDescendants = true, Active = true, Visible = false,
	}, TopBar)
	local TagList = List(TagScroll, 4, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center })
	Win.TagFrame = TagScroll

	local function Relayout()
		local Scale = math.max(RootScale.Scale, 0.01)
		local ContentW = TagList.AbsoluteContentSize.X / Scale
		local MaxW = math.floor(BASE_W * 0.32)
		local W = math.min(ContentW, MaxW)
		local HasTags = ContentW > 0
		TagScroll.Visible = HasTags
		TagSep.Visible = HasTags
		TagScroll.Size = UDim2.fromOffset(W, 34)
		local Reserve = HasTags and (TAG_EDGE + W + 14) or 86
		local Avail = math.max(BASE_W - 58 - Reserve, 40)
		Win.TitleLabel.Size = UDim2.fromOffset(Avail, 22)
		Win.AuthorLabel.Size = UDim2.fromOffset(Avail, 16)
	end
	TagList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(Relayout)
	RootScale:GetPropertyChangedSignal("Scale"):Connect(Relayout)
	Relayout()

	-- Mouse wheel scrolls the tag strip sideways
	local TagHover = false
	TagScroll.MouseEnter:Connect(function() TagHover = true end)
	TagScroll.MouseLeave:Connect(function() TagHover = false end)
	Win:Connect(UserInputService.InputChanged, function(I)
		if not TagHover or I.UserInputType ~= Enum.UserInputType.MouseWheel then return end
		local ContentW = TagList.AbsoluteContentSize.X / math.max(RootScale.Scale, 0.01)
		local MaxScroll = math.max(ContentW - TagScroll.Size.X.Offset, 0)
		local X = math.clamp(TagScroll.CanvasPosition.X - I.Position.Z * 40, 0, MaxScroll)
		TagScroll.CanvasPosition = Vector2.new(X, 0)
	end)

	New("Frame", {
		Position = UDim2.fromOffset(14, 53), Size = UDim2.new(1, -28, 0, 1), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, ZIndex = 5,
	}, Main)

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
		BorderSizePixel = 0, ZIndex = 5,
	}, Main)

	if UserCfg then
		local UC = New("TextButton", {
			Position = UDim2.new(0, 12, 1, -58), Size = UDim2.fromOffset(SBW, 46), BackgroundColor3 = Theme.Card, BorderSizePixel = 0,
			AutoButtonColor = false, Text = "", ZIndex = 5,
		}, Main)
		Bg(UC, 0)
		Corner(UC, 4)
		local UCS = Stroke(UC, Theme.Stroke, 1)
		UC.MouseEnter:Connect(function() Tween(UCS, 0.12, { Color = Theme.Accent }) end)
		UC.MouseLeave:Connect(function() Tween(UCS, 0.12, { Color = Theme.Stroke }) end)
		local Av = New("ImageLabel", {
			Position = UDim2.fromOffset(8, 7), Size = UDim2.fromOffset(32, 32), BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0,
			Image = UserCfg.Anonymous and "" or ("rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"),
		}, UC)
		Corner(Av, 4)
		New("TextLabel", {
			Position = UDim2.fromOffset(48, 6), Size = UDim2.new(1, -56, 0, 18), BackgroundTransparency = 1,
			Text = UserCfg.Anonymous and "Anonymous" or LocalPlayer.DisplayName, TextColor3 = Theme.Text, TextSize = 13, Font = FontBold,
			TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd,
		}, UC)
		New("TextLabel", {
			Position = UDim2.fromOffset(48, 24), Size = UDim2.new(1, -56, 0, 14), BackgroundTransparency = 1,
			Text = UserCfg.Anonymous and "@anonymous" or ("@" .. LocalPlayer.Name), TextColor3 = Theme.Muted, TextSize = 11, Font = FontMed,
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
		Size = UDim2.fromOffset(44, 44), Position = UDim2.new(1, -64, 0.5, -22), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Visible = false,
		Active = true,
	}, Gui)
	Corner(Bubble, 8)
	Stroke(Bubble, White, 1.5, 0.5)
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
	BubbleButton.InputBegan:Connect(function(I)
		if IsPointerStart(I) then BubbleMoved = false end
	end)
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
		Orb1.Position = UDim2.fromScale(0.1, 0.08)
		Orb2.Position = UDim2.fromScale(0.95, 0.95)
	end
	if not Win._moving then Win._resetMotion() end

	local Elapsed, Acc = 0, 0
	Win:Connect(RunService.RenderStepped, function(Dt)
		if Win.Destroyed or Win.Hidden or not Win._moving then return end
		Elapsed += Dt
		Acc += Dt
		if Acc < 1 / 30 then return end
		local Step = Acc
		Acc = 0
		Orb1.Position = UDim2.fromScale(0.1 + math.sin(Elapsed * 0.5) * 0.07, 0.08 + math.cos(Elapsed * 0.4) * 0.06)
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
		Tween(RootScale, 0.3, { Scale = TargetScale })
		local Splash = New("CanvasGroup", {
			Name = "Splash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, ZIndex = 100, Active = true,
		}, Main)
		Corner(Splash, MAIN_RADIUS)
		local SLogo = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -44), Size = UDim2.fromOffset(0, 0),
			BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, ZIndex = 2,
		}, Splash)
		Corner(SLogo, 8)
		local SImg = New("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.6, 0.6),
			BackgroundTransparency = 1, ImageColor3 = White, ZIndex = 3,
		}, SLogo)
		local SFB = New("TextLabel", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = string.upper(string.sub(PlainTitle, 1, 1)),
			TextColor3 = White, TextSize = 30, Font = FontBlack, ZIndex = 3,
		}, SLogo)
		SetLucide(SImg, O.Icon or "layout-grid", SFB)
		local STitle = New("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 20), Size = UDim2.fromOffset(400, 32),
			BackgroundTransparency = 1, Text = PlainTitle, TextColor3 = Theme.Text, TextSize = 24, Font = FontBold,
			MaxVisibleGraphemes = 0, ZIndex = 2,
		}, Splash)
		local BarBg = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 64), Size = UDim2.fromOffset(220, 3),
			BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, ZIndex = 2,
		}, Splash)
		local BarFill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0 }, BarBg)
		Tween(SLogo, 0.3, { Size = UDim2.fromOffset(72, 72) })
		Tween(BarFill, 1.4, { Size = UDim2.fromScale(1, 1) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		task.spawn(function()
			for I = 1, #PlainTitle do
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
