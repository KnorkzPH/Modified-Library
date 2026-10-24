--[[
    ToolkitUI  •  v1.0
    WindUI-style UI library — same look as ToolkitLoader (violet/cyan, gradient border, orbs)

    Icons:  "lucide:home"  |  "home" (default = lucide)  |  "solar:home-2-bold"  |  "rbxassetid://123"
    Elements: Toggle, Button, Slider, Dropdown (Multi), Input, Keybind, Colorpicker, Label/Paragraph, Divider, Section
    Extras:  Notify, Dialog, Status bar, Config save/load (Flag), Minimize bubble, Toggle key
]]

local Library = { Flags = {}, Options = {}, Version = "v1.0" }

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
	Blurple = Color3.fromRGB(88, 101, 242),
	Green = Color3.fromRGB(74, 222, 128),
	Red = Color3.fromRGB(248, 113, 113),
	Amber = Color3.fromRGB(251, 191, 36),
}

local FontBold, FontMed, FontBlack, FontReg = Enum.Font.GothamBold, Enum.Font.GothamMedium, Enum.Font.GothamBlack, Enum.Font.Gotham
local Left, Right = Enum.TextXAlignment.Left, Enum.TextXAlignment.Right
local AutoY = Enum.AutomaticSize.Y
local QuartOut, DirOut = Enum.EasingStyle.Quart, Enum.EasingDirection.Out
local MAIN_RADIUS = 16

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------
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

local function Corner(Parent, R)
	return New("UICorner", { CornerRadius = UDim.new(0, R or 10) }, Parent)
end

local function Stroke(Parent, Color, Thickness, Transparency)
	return New("UIStroke", {
		Color = Color or Theme.Stroke,
		Thickness = Thickness or 1,
		Transparency = Transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, Parent)
end

local function Gradient(Parent, A, B, Rotation)
	return New("UIGradient", { Color = ColorSequence.new(A, B), Rotation = Rotation or 0 }, Parent)
end

local function Pad(Parent, L, T, R, B)
	return New("UIPadding", {
		PaddingLeft = UDim.new(0, L), PaddingTop = UDim.new(0, T),
		PaddingRight = UDim.new(0, R), PaddingBottom = UDim.new(0, B),
	}, Parent)
end

local function List(Parent, Padding, Props)
	local P = { Padding = UDim.new(0, Padding or 0), SortOrder = Enum.SortOrder.LayoutOrder }
	for K, V in pairs(Props or {}) do
		P[K] = V
	end
	return New("UIListLayout", P, Parent)
end

local function Pulse(Object, Prop, A, B, Time)
	Object[Prop] = A
	TweenService:Create(Object, TweenInfo.new(Time or 1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { [Prop] = B }):Play()
end

local function Call(Fn, ...)
	if type(Fn) == "function" then
		task.spawn(Fn, ...)
	end
end

local function InsetY()
	return GuiService:GetGuiInset().Y
end

local function CopyText(Text)
	local Fn = setclipboard or toclipboard or (syn and syn.write_clipboard)
	if not Fn then return false end
	return (pcall(Fn, Text))
end

----------------------------------------------------------------------
-- Icons  (lucide / solar / any Footagesus set / rbxassetid)
----------------------------------------------------------------------
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

local IconSets = {} -- [set] = { ready, api, waiters, custom }

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
			if Data.Image and type(Data.Image) == "string" and Img == "" then Img = Data.Image end
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

local function SetIcon(Label, Icon, Fallback)
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

function Library:SetIcon(Label, Icon) SetIcon(Label, Icon) end

function Library:AddIcons(Set, Tbl)
	local S = LoadIconSet(Set)
	for K, V in pairs(Tbl) do S.custom[K] = V end
end

local function IconLabel(Parent, Icon, Size, Color, Props)
	local P = {
		Size = UDim2.fromOffset(Size, Size), BackgroundTransparency = 1,
		ImageColor3 = Color or Theme.Muted, ScaleType = Enum.ScaleType.Fit,
	}
	for K, V in pairs(Props or {}) do P[K] = V end
	local L = New("ImageLabel", P, Parent)
	SetIcon(L, Icon)
	return L
end

----------------------------------------------------------------------
-- Shared widgets
----------------------------------------------------------------------
local function GradButton(Parent, Text, Size, Position, ColA, ColB, TextSize)
	local Holder = New("Frame", { Size = Size, Position = Position, BackgroundColor3 = White, BorderSizePixel = 0 }, Parent)
	Corner(Holder, 10)
	local G = Gradient(Holder, ColA, ColB, 20)
	local S = Stroke(Holder, White, 1, 0.85)
	local Button = New("TextButton", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, AutoButtonColor = false,
		Text = Text, TextColor3 = White, TextSize = TextSize or 12, Font = FontBold,
	}, Holder)
	Button.MouseEnter:Connect(function()
		Tween(S, 0.18, { Transparency = 0.3 })
		Tween(G, 0.45, { Rotation = 200 })
	end)
	Button.MouseLeave:Connect(function()
		Tween(S, 0.18, { Transparency = 0.85 })
		Tween(G, 0.45, { Rotation = 20 })
	end)
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
	if typeof(V) == "EnumItem" then return { __k = V.Name } end
	return V
end

local function Deser(V)
	if type(V) == "table" then
		if V.__c then return Color3.new(V.__c[1], V.__c[2], V.__c[3]) end
		if V.__k then return V.__k end
	end
	return V
end

----------------------------------------------------------------------
-- Classes
----------------------------------------------------------------------
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

function Window:Connect(Signal, Fn)
	local C = Signal:Connect(Fn)
	table.insert(self.Connections, C)
	return C
end

local function MakeDraggable(Win, Handle, Target, GetScale, CanDrag, OnMoved)
	local Dragging, Start, StartPos, DragInput = false, nil, nil, nil
	Handle.InputBegan:Connect(function(I)
		if (I.UserInputType == Enum.UserInputType.MouseButton1 or I.UserInputType == Enum.UserInputType.Touch)
			and (not CanDrag or CanDrag()) then
			Dragging, Start, StartPos = true, I.Position, Target.Position
			I.Changed:Connect(function()
				if I.UserInputState == Enum.UserInputState.End then Dragging = false end
			end)
		end
	end)
	Handle.InputChanged:Connect(function(I)
		if I.UserInputType == Enum.UserInputType.MouseMovement or I.UserInputType == Enum.UserInputType.Touch then
			DragInput = I
		end
	end)
	Win:Connect(UserInputService.InputChanged, function(I)
		if I == DragInput and Dragging then
			local D = (I.Position - Start) / GetScale()
			Target.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + D.X, StartPos.Y.Scale, StartPos.Y.Offset + D.Y)
			if OnMoved and D.Magnitude > 4 then OnMoved() end
		end
	end)
end

local function MakeDrag(Win, Hit, OnMove, Page)
	local Active = false
	local function Pos(I) return Vector2.new(I.Position.X, I.Position.Y + InsetY()) end
	Hit.InputBegan:Connect(function(I)
		if I.UserInputType == Enum.UserInputType.MouseButton1 or I.UserInputType == Enum.UserInputType.Touch then
			Active = true
			if Page then Page.ScrollingEnabled = false end
			OnMove(Pos(I))
			local C
			C = I.Changed:Connect(function()
				if I.UserInputState == Enum.UserInputState.End then
					Active = false
					if Page then Page.ScrollingEnabled = true end
					C:Disconnect()
				end
			end)
		end
	end)
	Win:Connect(UserInputService.InputChanged, function(I)
		if Active and (I.UserInputType == Enum.UserInputType.MouseMovement or I.UserInputType == Enum.UserInputType.Touch) then
			OnMove(Pos(I))
		end
	end)
end

----------------------------------------------------------------------
-- Elements
----------------------------------------------------------------------
function Elements:_Next()
	self._n += 1
	return self._n
end

-- Base card. Returns { Card, Head, Title, Desc, Stroke }.  RightW = width reserved on the right of the head row.
function Elements:_Card(O, RightW, Clickable)
	RightW = RightW or 0
	local Card = New("Frame", {
		Name = "Element", LayoutOrder = self:_Next(), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY,
		BackgroundColor3 = Theme.Card, BorderSizePixel = 0,
	}, self.Parent)
	Corner(Card, 10)
	local CS = Stroke(Card, Theme.Stroke, 1)
	Pad(Card, 12, 8, 12, 8)
	New("UISizeConstraint", { MinSize = Vector2.new(0, 44) }, Card)
	List(Card, 8, { VerticalAlignment = Enum.VerticalAlignment.Center })

	local HeadProps = { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1 }
	if Clickable then
		HeadProps.Text = ""
		HeadProps.AutoButtonColor = false
	end
	local Head = New(Clickable and "TextButton" or "Frame", HeadProps, Card)
	New("UISizeConstraint", { MinSize = Vector2.new(0, 22) }, Head)

	local TextX = 0
	local Ico
	if O.Icon then
		Ico = IconLabel(Head, O.Icon, 18, Theme.Violet, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0) })
		TextX = 28
	end

	local Column = New("Frame", {
		Position = UDim2.fromOffset(TextX, 0),
		Size = UDim2.new(1, -(TextX + (RightW > 0 and RightW + 10 or 0)), 0, 0),
		AutomaticSize = AutoY, BackgroundTransparency = 1,
	}, Head)
	List(Column, 2)

	local Title = New("TextLabel", {
		LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1,
		RichText = true, Text = O.Title or "Element", TextColor3 = Theme.Text, TextSize = 13, Font = FontBold,
		TextWrapped = true, TextXAlignment = Left,
	}, Column)
	local Desc
	if O.Desc then
		Desc = New("TextLabel", {
			LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1,
			RichText = true, Text = O.Desc, TextColor3 = Theme.Muted, TextSize = 11, Font = FontMed,
			TextWrapped = true, TextXAlignment = Left,
		}, Column)
	end

	Card.MouseEnter:Connect(function()
		Tween(Card, 0.15, { BackgroundColor3 = Theme.CardHover })
		Tween(CS, 0.15, { Color = Theme.Violet })
	end)
	Card.MouseLeave:Connect(function()
		Tween(Card, 0.15, { BackgroundColor3 = Theme.Card })
		Tween(CS, 0.15, { Color = Theme.Stroke })
	end)

	return { Card = Card, Head = Head, Title = Title, Desc = Desc, Icon = Ico, Stroke = CS }
end

function Elements:_Finish(O, Obj, C)
	Obj.Frame = C.Card
	function Obj:SetTitle(T) C.Title.Text = T end
	function Obj:SetDesc(T) if C.Desc then C.Desc.Text = T end end
	function Obj:Destroy()
		if O.Flag then
			Library.Options[O.Flag] = nil
			Library.Flags[O.Flag] = nil
		end
		C.Card:Destroy()
	end
	if O.Flag then
		Library.Options[O.Flag] = Obj
		Library.Flags[O.Flag] = Obj.Value
	end
	return Obj
end

function Elements:Toggle(O)
	O = O or {}
	local C = self:_Card(O, 52, true)
	local Obj = { Value = false }

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

	function Obj:Set(V, Silent)
		V = V and true or false
		Obj.Value = V
		if O.Flag then Library.Flags[O.Flag] = V end
		Tween(Fill, 0.2, { BackgroundTransparency = V and 0 or 1 })
		Tween(Knob, 0.2, { Position = V and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, Enum.EasingStyle.Back)
		if not Silent then Call(O.Callback, V) end
	end

	C.Head.MouseButton1Click:Connect(function() Obj:Set(not Obj.Value) end)
	Obj:Set(O.Default == true, O.Default == nil)
	return self:_Finish(O, Obj, C)
end

function Elements:Button(O)
	O = O or {}
	local C = self:_Card(O, 70, true)
	local Obj = {}
	local Chip = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(62, 24),
		BackgroundColor3 = White, BorderSizePixel = 0,
	}, C.Head)
	Corner(Chip, 8)
	Gradient(Chip, Theme.Violet, Theme.Blue, 20)
	New("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = O.ButtonText or "RUN",
		TextColor3 = White, TextSize = 10, Font = FontBold,
	}, Chip)
	function Obj:Fire() Call(O.Callback) end
	C.Head.MouseButton1Click:Connect(function()
		Tween(Chip, 0.08, { Size = UDim2.fromOffset(56, 22) })
		task.delay(0.1, function()
			if Chip.Parent then Tween(Chip, 0.15, { Size = UDim2.fromOffset(62, 24) }) end
		end)
		Obj:Fire()
	end)
	return self:_Finish(O, Obj, C)
end

function Elements:Slider(O)
	O = O or {}
	local Min, Max, Step = O.Min or 0, O.Max or 100, O.Step or 1
	local C = self:_Card(O, 70)
	local Obj = { Value = Min }

	local ValueLabel = New("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(70, 18),
		BackgroundTransparency = 1, Text = "", TextColor3 = Theme.Violet, TextSize = 12, Font = FontBold, TextXAlignment = Right,
	}, C.Head)
	local Holder = New("Frame", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1 }, C.Card)
	local Track = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 6),
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
	function Obj:Set(V, Silent)
		local Prev = Obj.Value
		V = tonumber(V) or Min
		V = math.clamp(math.floor((V - Min) / Step + 0.5) * Step + Min, Min, Max)
		V = tonumber(string.format("%." .. Decimals .. "f", V))
		Obj.Value = V
		if O.Flag then Library.Flags[O.Flag] = V end
		local R = (V - Min) / math.max(Max - Min, 1e-9)
		Tween(Fill, 0.08, { Size = UDim2.fromScale(R, 1) })
		Tween(Knob, 0.08, { Position = UDim2.fromScale(R, 0.5) })
		ValueLabel.Text = tostring(V) .. (O.Suffix or "")
		if not Silent and V ~= Prev then Call(O.Callback, V) end
	end

	MakeDrag(self.Win, Holder, function(P)
		local R = math.clamp((P.X - Track.AbsolutePosition.X) / math.max(Track.AbsoluteSize.X, 1), 0, 1)
		Obj:Set(Min + (Max - Min) * R)
	end, self.Page)

	Obj:Set(O.Default or Min, O.Default == nil)
	return self:_Finish(O, Obj, C)
end

function Elements:Dropdown(O)
	O = O or {}
	local Multi = O.Multi == true
	local Values = O.Values or {}
	local C = self:_Card(O, 150)
	local Obj = { Value = Multi and {} or nil, Values = Values }

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
	local ChevFallback = New("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1, Text = "v", TextColor3 = Theme.Muted, TextSize = 10, Font = FontBold,
	}, Pill)
	local Chevron = IconLabel(Pill, "lucide:chevron-down", 14, Theme.Muted, {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
	})
	SetIcon(Chevron, "lucide:chevron-down", ChevFallback)

	local Holder = New("Frame", {
		LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0,
		ClipsDescendants = true, Visible = false,
	}, C.Card)
	Corner(Holder, 8)
	Stroke(Holder, Theme.Stroke, 1)
	local Scroll = New("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Violet, CanvasSize = UDim2.new(), AutomaticCanvasSize = AutoY,
	}, Holder)
	Pad(Scroll, 4, 4, 4, 4)
	List(Scroll, 2)

	local Buttons = {}
	local Open = false

	local function Height() return math.min(math.max(#Values, 1), 5) * 30 + 8 end

	local function SetOpen(V)
		Open = V
		if V then
			Holder.Visible = true
			Tween(Holder, 0.25, { Size = UDim2.new(1, 0, 0, Height()) })
		else
			Tween(Holder, 0.2, { Size = UDim2.new(1, 0, 0, 0) })
			task.delay(0.22, function()
				if not Open and Holder.Parent then Holder.Visible = false end
			end)
		end
		Tween(Chevron, 0.2, { Rotation = V and 180 or 0 })
		Tween(PillStroke, 0.2, { Color = V and Theme.Violet or Theme.Stroke })
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
			B.Chk.Visible = On
			B.Lbl.TextColor3 = On and Theme.Text or Theme.Muted
		end
	end

	function Obj:Set(V, Silent)
		if Multi then
			local New_ = {}
			for _, Item in ipairs(type(V) == "table" and V or {}) do
				table.insert(New_, tostring(Item))
			end
			Obj.Value = New_
		else
			Obj.Value = V ~= nil and tostring(V) or nil
		end
		if O.Flag then Library.Flags[O.Flag] = Obj.Value end
		Render()
		if not Silent then Call(O.Callback, Obj.Value) end
	end

	local function Build()
		for _, B in pairs(Buttons) do B.Btn:Destroy() end
		Buttons = {}
		for I, Raw in ipairs(Values) do
			local Name = tostring(Raw)
			local Btn = New("TextButton", {
				LayoutOrder = I, Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = Theme.CardHover,
				BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Text = "",
			}, Scroll)
			Corner(Btn, 6)
			local Lbl = New("TextLabel", {
				Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -34, 1, 0), BackgroundTransparency = 1, Text = Name,
				TextColor3 = Theme.Muted, TextSize = 12, Font = FontMed, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd,
			}, Btn)
			local Chk = New("TextLabel", {
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(14, 14),
				BackgroundTransparency = 1, Text = "•", TextColor3 = Theme.Violet, TextSize = 20, Font = FontBold, Visible = false,
			}, Btn)
			Btn.MouseEnter:Connect(function() Tween(Btn, 0.1, { BackgroundTransparency = 0.4 }) end)
			Btn.MouseLeave:Connect(function() Tween(Btn, 0.1, { BackgroundTransparency = 1 }) end)
			Btn.MouseButton1Click:Connect(function()
				if Multi then
					local L = table.clone(Obj.Value)
					local Idx = table.find(L, Name)
					if Idx then table.remove(L, Idx) else table.insert(L, Name) end
					Obj:Set(L)
				else
					Obj:Set(Name)
					SetOpen(false)
				end
			end)
			Buttons[Name] = { Btn = Btn, Lbl = Lbl, Chk = Chk }
		end
	end

	function Obj:Refresh(NewValues, Keep)
		Values = NewValues or {}
		Obj.Values = Values
		Build()
		if Keep then Render() else Obj:Set(Multi and {} or nil, true) end
		if Open then Tween(Holder, 0.2, { Size = UDim2.new(1, 0, 0, Height()) }) end
	end

	Pill.MouseButton1Click:Connect(function() SetOpen(not Open) end)
	Build()
	Obj:Set(O.Default, O.Default == nil)
	return self:_Finish(O, Obj, C)
end

function Elements:Input(O)
	O = O or {}
	local C = self:_Card(O, 160)
	local Obj = { Value = "" }
	local Pill = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(160, 26),
		BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0, ClipsDescendants = true,
	}, C.Head)
	Corner(Pill, 8)
	local PS = Stroke(Pill, Theme.Stroke, 1)
	local TB = New("TextBox", {
		Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0), BackgroundTransparency = 1, Text = "",
		PlaceholderText = O.Placeholder or "Type here...", PlaceholderColor3 = Theme.Muted, TextColor3 = Theme.Text,
		TextSize = 12, Font = FontMed, ClearTextOnFocus = false, TextXAlignment = Left,
	}, Pill)
	TB.Focused:Connect(function() Tween(PS, 0.15, { Color = Theme.Violet }) end)

	function Obj:Set(V, Silent)
		V = tostring(V or "")
		if O.Numeric then V = V:gsub("[^%d%.%-]", "") end
		TB.Text = V
		Obj.Value = V
		if O.Flag then Library.Flags[O.Flag] = V end
		if not Silent then Call(O.Callback, V) end
	end
	TB.FocusLost:Connect(function()
		Tween(PS, 0.15, { Color = Theme.Stroke })
		Obj:Set(TB.Text)
	end)
	Obj:Set(O.Default or "", O.Default == nil)
	return self:_Finish(O, Obj, C)
end

function Elements:Keybind(O)
	O = O or {}
	local C = self:_Card(O, 96)
	local Obj = { Value = Enum.KeyCode.Unknown }
	local Listening = false

	local Pill = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(86, 26),
		BackgroundColor3 = Theme.Bg2, BorderSizePixel = 0, AutoButtonColor = false, Text = "None",
		TextColor3 = Theme.Text, TextSize = 11, Font = FontBold,
	}, C.Head)
	Corner(Pill, 8)
	local PS = Stroke(Pill, Theme.Stroke, 1)

	function Obj:Set(K, Silent)
		if type(K) == "string" then
			local ok, v = pcall(function() return Enum.KeyCode[K] end)
			K = ok and v or Enum.KeyCode.Unknown
		end
		if typeof(K) ~= "EnumItem" then K = Enum.KeyCode.Unknown end
		Obj.Value = K
		if O.Flag then Library.Flags[O.Flag] = K end
		Pill.Text = K == Enum.KeyCode.Unknown and "None" or K.Name
		if not Silent then Call(O.OnChange, K) end
	end

	Pill.MouseButton1Click:Connect(function()
		Listening = true
		Pill.Text = "..."
		Tween(PS, 0.15, { Color = Theme.Violet })
	end)

	self.Win:Connect(UserInputService.InputBegan, function(I, Processed)
		if Listening then
			if I.UserInputType == Enum.UserInputType.Keyboard then
				Listening = false
				Tween(PS, 0.15, { Color = Theme.Stroke })
				Obj:Set(I.KeyCode == Enum.KeyCode.Escape and Enum.KeyCode.Unknown or I.KeyCode)
			end
			return
		end
		if Processed then return end
		if I.UserInputType == Enum.UserInputType.Keyboard and Obj.Value ~= Enum.KeyCode.Unknown and I.KeyCode == Obj.Value then
			Call(O.Callback, I.KeyCode)
		end
	end)

	Obj:Set(O.Default or Enum.KeyCode.Unknown, true)
	return self:_Finish(O, Obj, C)
end

function Elements:Colorpicker(O)
	O = O or {}
	local C = self:_Card(O, 44, false)
	local Default = O.Default or Theme.Violet
	local H, S, V = Default:ToHSV()
	local Obj = { Value = Default }
	local Open = false
	local PH = 110

	local Swatch = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(36, 22),
		BackgroundColor3 = Default, BorderSizePixel = 0, AutoButtonColor = false, Text = "",
	}, C.Head)
	Corner(Swatch, 7)
	Stroke(Swatch, White, 1, 0.7)

	local Holder = New("Frame", {
		LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, ClipsDescendants = true, Visible = false,
	}, C.Card)

	local SV = New("Frame", {
		Size = UDim2.new(1, -30, 0, PH), BackgroundColor3 = Color3.fromHSV(H, 1, 1), BorderSizePixel = 0,
	}, Holder)
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
	for I = 0, 6 do
		table.insert(Keys, ColorSequenceKeypoint.new(I / 6, Color3.fromHSV(I / 6, 1, 1)))
	end
	New("UIGradient", { Rotation = 90, Color = ColorSequence.new(Keys) }, HueBar)
	local HueCur = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(1, 4, 0, 4),
		BackgroundColor3 = White, BorderSizePixel = 0, ZIndex = 3,
	}, HueBar)
	Corner(HueCur, 2)
	Stroke(HueCur, Color3.new(0, 0, 0), 1, 0.5)

	local function Render()
		SV.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
		Cursor.Position = UDim2.fromScale(S, 1 - V)
		HueCur.Position = UDim2.fromScale(0.5, H)
		Swatch.BackgroundColor3 = Obj.Value
	end
	local function Apply(Silent)
		Obj.Value = Color3.fromHSV(H, S, V)
		if O.Flag then Library.Flags[O.Flag] = Obj.Value end
		Render()
		if not Silent then Call(O.Callback, Obj.Value) end
	end

	function Obj:Set(Col, Silent)
		if typeof(Col) ~= "Color3" then return end
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

	Swatch.MouseButton1Click:Connect(function()
		Open = not Open
		if Open then
			Holder.Visible = true
			Tween(Holder, 0.25, { Size = UDim2.new(1, 0, 0, PH) })
		else
			Tween(Holder, 0.2, { Size = UDim2.new(1, 0, 0, 0) })
			task.delay(0.22, function()
				if not Open and Holder.Parent then Holder.Visible = false end
			end)
		end
	end)

	Render()
	if O.Default ~= nil then Call(O.Callback, Obj.Value) end
	return self:_Finish(O, Obj, C)
end

function Elements:Label(O)
	if type(O) == "string" then O = { Title = O } end
	O = O or {}
	local C = self:_Card(O, 0)
	return self:_Finish(O, {}, C)
end
Elements.Paragraph = Elements.Label

function Elements:Divider()
	local F = New("Frame", { LayoutOrder = self:_Next(), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = White, BorderSizePixel = 0 }, self.Parent)
	New("UIGradient", { Color = ColorSequence.new(Theme.Violet, Theme.Cyan), Transparency = NumberSequence.new(0.3, 1) }, F)
	return F
end

function Elements:Section(O)
	if type(O) == "string" then O = { Title = O } end
	O = O or {}
	local Wrap = New("Frame", {
		LayoutOrder = self:_Next(), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1,
	}, self.Parent)
	List(Wrap, 8)

	local Header = New("TextButton", {
		LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
	}, Wrap)
	local Lbl = New("TextLabel", {
		Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1,
		Text = string.upper(O.Title or "SECTION"), TextColor3 = Theme.Muted, TextSize = 10, Font = FontBold,
	}, Header)
	local Line = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = Theme.Violet, BackgroundTransparency = 0.7, BorderSizePixel = 0,
	}, Header)
	local Chev = IconLabel(Header, "lucide:chevron-down", 14, Theme.Muted, {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0),
	})
	local function Fit()
		local W = Lbl.TextBounds.X + 10
		Line.Position = UDim2.new(0, W, 0.5, 0)
		Line.Size = UDim2.new(1, -(W + 24), 0, 1)
	end
	Fit()
	Lbl:GetPropertyChangedSignal("TextBounds"):Connect(Fit)

	local Body = New("Frame", {
		LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1,
	}, Wrap)
	List(Body, 8)

	local Sec = setmetatable({ Win = self.Win, Parent = Body, Page = self.Page, _n = 0 }, SectionClass)
	local IsOpen = true
	function Sec:SetOpen(V)
		IsOpen = V
		Body.Visible = V
		Tween(Chev, 0.2, { Rotation = V and 0 or -90 })
	end
	Header.MouseButton1Click:Connect(function() Sec:SetOpen(not IsOpen) end)
	if O.Open == false then Sec:SetOpen(false) end
	return Sec
end

----------------------------------------------------------------------
-- Tabs
----------------------------------------------------------------------
function TabClass:Select(Instant)
	local Win = self.Win
	for _, T in ipairs(Win.Tabs) do
		if T ~= self then T:_SetActive(false) end
	end
	self:_SetActive(true, Instant)
	Win.CurrentTab = self
end

function Window:SelectTab(Tab) Tab:Select() end

function Window:_NextSide()
	self._side += 1
	return self._side
end

function Window:Header(Text)
	New("TextLabel", {
		LayoutOrder = self:_NextSide(), Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
		Text = "  " .. string.upper(Text or ""), TextColor3 = Theme.Muted, TextSize = 9, Font = FontBold, TextXAlignment = Left,
	}, self.Sidebar)
end

function Window:Tab(O)
	if type(O) == "string" then O = { Title = O } end
	O = O or {}
	local Tab = setmetatable({ Win = self, _n = 0, Title = O.Title or "Tab" }, TabClass)

	local Btn = New("TextButton", {
		LayoutOrder = self:_NextSide(), Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, BorderSizePixel = 0,
		AutoButtonColor = false, Text = "",
	}, self.Sidebar)
	Corner(Btn, 10)
	local ActiveFill = New("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = White, BackgroundTransparency = 1, BorderSizePixel = 0,
	}, Btn)
	Corner(ActiveFill, 10)
	Gradient(ActiveFill, Theme.Violet, Theme.Blue, 20)
	local ActStroke = Stroke(Btn, Theme.Violet, 1, 1)

	local TextX, Ico = 12, nil
	if O.Icon then
		Ico = IconLabel(Btn, O.Icon, 16, Theme.Muted, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0) })
		TextX = 34
	end
	local Lbl = New("TextLabel", {
		Position = UDim2.fromOffset(TextX, 0), Size = UDim2.new(1, -(TextX + 8), 1, 0), BackgroundTransparency = 1,
		Text = Tab.Title, TextColor3 = Theme.Muted, TextSize = 12, Font = FontBold, TextXAlignment = Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, Btn)

	local Page = New("ScrollingFrame", {
		Name = "Page_" .. Tab.Title, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Violet, CanvasSize = UDim2.new(), AutomaticCanvasSize = AutoY,
		ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false,
	}, self.Content)
	Pad(Page, 2, 2, 10, 2)
	List(Page, 8)

	Tab.Parent = Page
	Tab.Page = Page
	Tab.Button = Btn

	local Selected = false
	function Tab:_SetActive(On, Instant)
		Selected = On
		Tween(ActiveFill, 0.2, { BackgroundTransparency = On and 0.78 or 1 })
		Tween(ActStroke, 0.2, { Transparency = On and 0.4 or 1 })
		Tween(Lbl, 0.2, { TextColor3 = On and Theme.Text or Theme.Muted })
		if Ico then Tween(Ico, 0.2, { ImageColor3 = On and Theme.Violet or Theme.Muted }) end
		if On then
			Page.Visible = true
			if not Instant then
				Page.Position = UDim2.fromOffset(0, 12)
				Tween(Page, 0.3, { Position = UDim2.fromOffset(0, 0) })
			end
		else
			Page.Visible = false
		end
	end

	Btn.MouseEnter:Connect(function()
		if not Selected then Tween(Lbl, 0.15, { TextColor3 = Theme.Text }) end
	end)
	Btn.MouseLeave:Connect(function()
		if not Selected then Tween(Lbl, 0.15, { TextColor3 = Theme.Muted }) end
	end)
	Btn.MouseButton1Click:Connect(function() Tab:Select() end)

	table.insert(self.Tabs, Tab)
	if #self.Tabs == 1 then Tab:Select(true) end
	return Tab
end

----------------------------------------------------------------------
-- Window API
----------------------------------------------------------------------
function Window:SetStatus(Text, Color)
	Color = Color or Theme.Green
	self.Status.Text = Text
	Tween(self.StatusDot, 0.2, { BackgroundColor3 = Color })
	Tween(self.StatusBar, 0.25, { BackgroundColor3 = Theme.Card:Lerp(Color, 0.16) })
	self.StatusStroke.Color = Color
	self.StatusStroke.Thickness = 3
	Tween(self.StatusStroke, 0.6, { Thickness = 1.2 })
end

function Window:SetHidden(V)
	if self.Destroyed then return end
	self.Hidden = V
	self.Root.Visible = not V
	self.Bubble.Visible = V
end

function Window:Toggle() self:SetHidden(not self.Hidden) end

function Window:Notify(O)
	if type(O) == "string" then O = { Content = O } end
	O = O or {}
	local Colors = { info = Theme.Cyan, success = Theme.Green, warn = Theme.Amber, error = Theme.Red }
	local Col = Colors[O.Type or "info"] or Theme.Cyan
	local Dur = O.Duration or 4

	local Holder = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1 }, self.Notifs)
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
		IconLabel(Body, O.Icon, 18, Col, { Position = UDim2.fromOffset(0, 1) })
		TextX = 28
	end
	local Col_ = New("Frame", {
		Position = UDim2.fromOffset(TextX, 0), Size = UDim2.new(1, -TextX, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1,
	}, Body)
	List(Col_, 3)
	New("TextLabel", {
		LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, RichText = true,
		Text = O.Title or "Notification", TextColor3 = Theme.Text, TextSize = 13, Font = FontBold, TextWrapped = true, TextXAlignment = Left,
	}, Col_)
	if O.Content then
		New("TextLabel", {
			LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, RichText = true,
			Text = O.Content, TextColor3 = Theme.Muted, TextSize = 11, Font = FontMed, TextWrapped = true, TextXAlignment = Left,
		}, Col_)
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

	local Hit = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 3 }, Card)
	Hit.MouseButton1Click:Connect(Dismiss)
end

function Window:Dialog(O)
	O = O or {}
	if self._dlg then self._dlg:Destroy() end
	local Modal, Dim = self.Modal, self.Dim
	Modal.Visible = true
	Tween(Dim, 0.2, { BackgroundTransparency = 0.4 })

	local Box = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 340, 0, 0),
		AutomaticSize = AutoY, BackgroundColor3 = Color3.fromRGB(24, 22, 40), BorderSizePixel = 0, ZIndex = 2,
	}, Modal)
	Corner(Box, 14)
	Gradient(Stroke(Box, White, 2, 0.05), Theme.Violet, Theme.Cyan, 45)
	Pad(Box, 18, 16, 18, 16)
	List(Box, 12)
	local Sc = New("UIScale", { Scale = 0.9 }, Box)
	Tween(Sc, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
	self._dlg = Box

	New("TextLabel", {
		LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, RichText = true, Text = O.Title or "Dialog",
		TextColor3 = White, TextSize = 16, Font = FontBlack, TextXAlignment = Left,
	}, Box)
	if O.Content then
		New("TextLabel", {
			LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, RichText = true,
			Text = O.Content, TextColor3 = Color3.fromRGB(235, 233, 255), TextSize = 13, Font = FontMed, TextWrapped = true,
			TextXAlignment = Left, TextYAlignment = Enum.TextYAlignment.Top,
		}, Box)
	end

	local Row = New("Frame", { LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1 }, Box)
	List(Row, 8, { FillDirection = Enum.FillDirection.Horizontal })

	local function Close()
		if self._dlg == Box then self._dlg = nil end
		Tween(Dim, 0.15, { BackgroundTransparency = 1 })
		Tween(Sc, 0.15, { Scale = 0.92 })
		task.delay(0.16, function()
			Box:Destroy()
			if not self._dlg and not self.Destroyed then Modal.Visible = false end
		end)
	end
	function self:CloseDialog() Close() end

	local Buttons = O.Buttons or { { Title = "OK", Style = "Primary" } }
	local N = #Buttons
	for I, B in ipairs(Buttons) do
		local Size = UDim2.new(1 / N, -8 * (N - 1) / N, 1, 0)
		local Btn
		if B.Style == "Secondary" or B.Style == "Cancel" then
			Btn = New("TextButton", {
				LayoutOrder = I, Size = Size, BackgroundColor3 = Color3.fromRGB(36, 33, 60), BorderSizePixel = 0,
				AutoButtonColor = false, Text = B.Title or "CANCEL", TextColor3 = Color3.fromRGB(210, 205, 240),
				TextSize = 12, Font = FontBold,
			}, Row)
			Corner(Btn, 10)
			Stroke(Btn, Theme.Stroke, 1.2)
		else
			local Holder
			Btn, Holder = GradButton(Row, B.Title or "OK", Size, UDim2.new(), B.ColorA or Theme.Violet, B.ColorB or Theme.Blue, 12)
			Holder.LayoutOrder = I
		end
		Btn.MouseButton1Click:Connect(function()
			if not B.Keep then Close() end
			Call(B.Callback)
		end)
	end
	return { Close = Close }
end

function Window:SaveConfig(Name)
	Name = Name or "default"
	local Data = {}
	for Flag, Obj in pairs(Library.Options) do
		if Obj.Value ~= nil then Data[Flag] = Ser(Obj.Value) end
	end
	local ok = pcall(function()
		if makefolder and isfolder and not isfolder(self.ConfigFolder) then makefolder(self.ConfigFolder) end
		writefile(self.ConfigFolder .. "/" .. Name .. ".json", HttpService:JSONEncode(Data))
	end)
	return ok
end

function Window:LoadConfig(Name)
	Name = Name or "default"
	local ok, Data = pcall(function()
		return HttpService:JSONDecode(readfile(self.ConfigFolder .. "/" .. Name .. ".json"))
	end)
	if not ok or type(Data) ~= "table" then return false end
	for Flag, V in pairs(Data) do
		local Obj = Library.Options[Flag]
		if Obj and Obj.Set then pcall(Obj.Set, Obj, Deser(V)) end
	end
	return true
end

function Window:Destroy()
	if self.Destroyed then return end
	self.Destroyed = true
	for _, C in ipairs(self.Connections) do pcall(function() C:Disconnect() end) end
	local Ok, T = pcall(Tween, self.RootScale, 0.25, { Scale = 0.8 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	local function Kill() pcall(function() self.Gui:Destroy() end) end
	if Ok and T then T.Completed:Connect(Kill) else Kill() end
end

----------------------------------------------------------------------
-- CreateWindow
----------------------------------------------------------------------
function Library:CreateWindow(O)
	O = O or {}
	for K, V in pairs(O.Theme or {}) do Theme[K] = V end

	local BASE_W, BASE_H = O.Width or 600, O.Height or 400
	local Name = O.Name or "ToolkitUI"

	local Win = setmetatable({
		Connections = {}, Tabs = {}, Destroyed = false, Hidden = false, _side = 0,
		ConfigFolder = O.ConfigFolder or "ToolkitUI",
	}, Window)

	-- remove old copies
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
		Name = Name, ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999999,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	do
		local Ok = pcall(function()
			Gui.Parent = gethui and gethui() or CoreGui
		end)
		if not Ok or not Gui.Parent then Gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
	end
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
		Name = "Main", Size = UDim2.fromScale(1, 1), BackgroundColor3 = White, BorderSizePixel = 0,
		ClipsDescendants = true, ZIndex = 2,
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

	local Background = New("CanvasGroup", {
		Name = "Background", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1,
	}, Main)
	Corner(Background, MAIN_RADIUS)
	local Orb1 = Orb(Theme.Violet, 0.12, 0.1, 340, 0.72, Background)
	local Orb2 = Orb(Theme.Cyan, 0.95, 0.95, 320, 0.72, Background)
	local Particles = MakeParticles(Background, 14)

	-- TopBar
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
	SetIcon(LogoImg, O.Icon or "lucide:layout-grid")

	local TitleText = O.Accent and (string.upper(O.Title or "TOOLKIT") .. ' <font color="#8B5CFF">' .. string.upper(O.Accent) .. "</font>")
		or string.upper(O.Title or "TOOLKIT UI")
	New("TextLabel", {
		Position = UDim2.fromOffset(58, 8), Size = UDim2.new(1, -160, 0, 22), BackgroundTransparency = 1, RichText = true,
		Text = TitleText, TextColor3 = Theme.Text, TextSize = 16, Font = FontBlack, TextXAlignment = Left,
	}, TopBar)
	New("TextLabel", {
		Position = UDim2.fromOffset(58, 30), Size = UDim2.new(1, -160, 0, 14), BackgroundTransparency = 1,
		Text = (O.Tagline or "Access Beyond Ordinary") .. "  •  " .. (O.Version or Library.Version),
		TextColor3 = Theme.Muted, TextSize = 10, Font = FontMed, TextXAlignment = Left,
	}, TopBar)

	local CloseButton = IconButton(TopBar, "×", UDim2.new(1, -40, 0, 14), Theme.Red)
	local MinButton = IconButton(TopBar, "–", UDim2.new(1, -72, 0, 14), Theme.Violet)

	local Divider = New("Frame", {
		Position = UDim2.fromOffset(14, 53), Size = UDim2.new(1, -28, 0, 1), BackgroundColor3 = White, BorderSizePixel = 0, ZIndex = 5,
	}, Main)
	New("UIGradient", { Color = ColorSequence.new(Theme.Violet, Theme.Cyan), Transparency = NumberSequence.new(0.2, 1) }, Divider)

	-- Sidebar + Content + Status
	local Sidebar = New("ScrollingFrame", {
		Name = "Sidebar", Position = UDim2.fromOffset(12, 62), Size = UDim2.new(0, 148, 1, -74), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = AutoY, ZIndex = 5,
	}, Main)
	List(Sidebar, 4)
	Win.Sidebar = Sidebar

	local Content = New("Frame", {
		Name = "Content", Position = UDim2.fromOffset(168, 62), Size = UDim2.new(1, -180, 1, -112),
		BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 5,
	}, Main)
	Win.Content = Content

	local StatusBar = New("Frame", {
		Position = UDim2.new(0, 168, 1, -44), Size = UDim2.new(1, -180, 0, 32),
		BackgroundColor3 = Theme.Card:Lerp(Theme.Green, 0.16), BorderSizePixel = 0, ZIndex = 5,
	}, Main)
	Corner(StatusBar, 10)
	local StatusStroke = Stroke(StatusBar, Theme.Green, 1.2, 0)
	local StatusDot = New("Frame", {
		Size = UDim2.fromOffset(10, 10), Position = UDim2.new(0, 12, 0.5, -5), BackgroundColor3 = Theme.Green, BorderSizePixel = 0,
	}, StatusBar)
	Corner(StatusDot, 5)
	Pulse(StatusDot, "BackgroundTransparency", 0, 0.5, 0.8)
	local Status = New("TextLabel", {
		Position = UDim2.fromOffset(30, 0), Size = UDim2.new(1, -40, 1, 0), BackgroundTransparency = 1,
		Text = O.Status or "Ready", TextColor3 = White, TextSize = 12, Font = FontBold, TextXAlignment = Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, StatusBar)
	Win.Status, Win.StatusDot, Win.StatusBar, Win.StatusStroke = Status, StatusDot, StatusBar, StatusStroke

	-- Modal (Dialog host)
	local Modal = New("Frame", { Name = "Modal", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 40 }, Main)
	local Dim = New("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
		BorderSizePixel = 0, Active = true, ZIndex = 1,
	}, Modal)
	Corner(Dim, MAIN_RADIUS)
	Win.Modal, Win.Dim = Modal, Dim

	-- Notifications
	local Notifs = New("Frame", {
		Name = "Notifications", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 300, 1, -32), BackgroundTransparency = 1,
	}, Gui)
	List(Notifs, 8, { VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right })
	Win.Notifs = Notifs

	-- Minimize bubble
	local Bubble = New("Frame", {
		Size = UDim2.fromOffset(48, 48), Position = UDim2.new(1, -64, 0.5, -24), BackgroundColor3 = White,
		BorderSizePixel = 0, Visible = false,
	}, Gui)
	Corner(Bubble, 24)
	Gradient(Bubble, Theme.Violet, Theme.Cyan, 45)
	Stroke(Bubble, White, 1.5, 0.6)
	local BubbleButton = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, Bubble)
	local BubbleImg = New("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(24, 24),
		BackgroundTransparency = 1, ImageColor3 = White, Active = false,
	}, Bubble)
	SetIcon(BubbleImg, O.Icon or "lucide:layout-grid")
	Win.Bubble = Bubble

	-- Dragging
	MakeDraggable(Win, TopBar, Root, function() return RootScale.Scale end, function() return not Modal.Visible end)
	local BubbleMoved = false
	MakeDraggable(Win, BubbleButton, Bubble, function() return 1 end, nil, function() BubbleMoved = true end)

	CloseButton.MouseButton1Click:Connect(function() Win:Destroy() end)
	MinButton.MouseButton1Click:Connect(function() Win:SetHidden(true) end)
	BubbleButton.MouseButton1Click:Connect(function()
		if BubbleMoved then
			BubbleMoved = false
			return
		end
		Win:SetHidden(false)
	end)

	local ToggleKey = O.ToggleKey or Enum.KeyCode.RightShift
	Win:Connect(UserInputService.InputBegan, function(I, Processed)
		if Processed or Win.Destroyed then return end
		if I.KeyCode == ToggleKey then Win:Toggle() end
	end)

	-- Animation loop
	local Elapsed, Acc = 0, 0
	Win:Connect(RunService.RenderStepped, function(Dt)
		if Win.Destroyed or Win.Hidden then return end
		Elapsed += Dt
		BorderGrad.Rotation = (Elapsed * 45) % 360
		LogoGrad.Rotation = (Elapsed * 60) % 360
		Acc += Dt
		if Acc < 1 / 30 then return end
		local Step = Acc
		Acc = 0
		Orb1.Position = UDim2.fromScale(0.12 + math.sin(Elapsed * 0.5) * 0.07, 0.1 + math.cos(Elapsed * 0.4) * 0.06)
		Orb2.Position = UDim2.fromScale(0.95 + math.cos(Elapsed * 0.45) * 0.07, 0.95 + math.sin(Elapsed * 0.35) * 0.06)
		for _, P in ipairs(Particles) do
			local Y = P.Y - P.Speed * Step
			if Y < -0.02 then Y = 1.02 end
			local X = P.X + math.sin(Elapsed + P.Drift) * 0.018 * Step
			P.X, P.Y = X, Y
			P.Obj.Position = UDim2.fromScale(X, Y)
		end
	end)

	-- Intro splash
	if O.ShowIntro == false then
		RootScale.Scale = TargetScale
	else
		Tween(RootScale, 0.4, { Scale = TargetScale }, Enum.EasingStyle.Back)
		local Splash = New("CanvasGroup", {
			Name = "Splash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, ZIndex = 100,
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
		SetIcon(SImg, O.Icon or "lucide:layout-grid")
		local STitleText = string.upper((O.Title or "TOOLKIT") .. (O.Accent and (" " .. O.Accent) or (O.Title and "" or " UI")))
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

	return Win
end

Library.Theme = Theme
return Library
