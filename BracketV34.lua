local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local PlayerService = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local GuiInset = GuiService:GetGuiInset()
local LocalPlayer = PlayerService.LocalPlayer

local Bracket = {
	Screen = nil,
	IsLocal = not identifyexecutor,

	SectionInclude = {
		"Divider",
		"Label",
		"Button",
		"Toggle",
		"Slider",
		"Textbox",
		"Keybind",
		"Dropdown",
		"Colorpicker"
	}
}

Bracket.Utilities = {
	TableToColor = function(Table)
		if type(Table) ~= "table" then return Table end
		return Color3.fromHSV(Table[1], Table[2], Table[3])
	end,
	ColorToString = function(Color)
		return ("%i, %i, %i"):format(Color.R * 255, Color.G * 255, Color.B * 255)
	end,
	Scale = function(Value, InputMin, InputMax, OutputMin, OutputMax)
		return OutputMin + (Value - InputMin) * (OutputMax - OutputMin) / (InputMax - InputMin)
	end,
	DeepCopy = function(Self, Original)
		if type(Original) ~= "table" then return Original end
		local Copy = {}

		for Index, Value in pairs(Original) do
			if type(Value) == "table" then
				Value = Self:DeepCopy(Value)
			end

			Copy[Index] = Value
		end

		return Copy
	end,
	DeepEquals = function(Self, Object1, Object2)
		if Object1 == Object2 then return true end

		local Object1Type = type(Object1)
		local Object2Type = type(Object2)

		if Object1Type ~= Object2Type then return false end
		if Object1Type ~= "table" then return false end

		local KeySet = {}

		for Key1, Value1 in Object1 do
			local Value2 = Object2[Key1]

			if Value2 == nil or Self:DeepEquals(Value1, Value2) == false then
				return false
			end

			KeySet[Key1] = true
		end

		for Key2 in Object2 do
			if not KeySet[Key2] then
				return false
			end
		end

		return true
	end,
	Proxify = function(Table)
		local Proxy, Events = {}, {}
		local ChangedEvent = Instance.new("BindableEvent")
		Proxy.Changed = ChangedEvent.Event
		Proxy.Internal = Table

		function Proxy:GetPropertyChangedSignal(Property)
			local PropertyEvent = Instance.new("BindableEvent")

			Events[Property] = Events[Property] or {}
			table.insert(Events[Property], PropertyEvent)

			return PropertyEvent.Event
		end

		setmetatable(Proxy, {
			__index = function(Self, Key)
				return Table[Key]
			end,
			__newindex = function(Self, Key, Value)
				local OldValue = Table[Key]
				Table[Key] = Value

				ChangedEvent:Fire(Key, Value, OldValue)
				if Events[Key] then
					for Index, Event in ipairs(Events[Key]) do
						Event:Fire(Value, OldValue)
					end
				end
			end
		})

		return Proxy
	end,
	GetType = function(Self, Object, Type, Default, UseProxy)
		if typeof(Object) == Type then
			return UseProxy and Self.Proxify(Object) or Object
		end

		return UseProxy and Self.Proxify(Default) or Default
	end,
	GetTextBounds = function(Text, Font, Size)
		return TextService:GetTextSize(Text, Size.Y, Font, Vector2.new(Size.X, 1e6))
	end,
	MakeDraggable = function(Dragger, Object, OnChange, OnEnd)
		local Position, StartPosition = nil, nil

		Dragger.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				Position = UserInputService:GetMouseLocation()
				StartPosition = Object.AbsolutePosition
			end
		end)
		UserInputService.InputChanged:Connect(function(Input)
			if StartPosition and Input.UserInputType == Enum.UserInputType.MouseMovement then
				local Mouse = UserInputService:GetMouseLocation()
				local Delta = Mouse - Position
				Position = Mouse

				Delta = Object.Position + UDim2.fromOffset(Delta.X, Delta.Y)
				if OnChange then OnChange(Delta) end
			end
		end)
		Dragger.InputEnded:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if OnEnd then OnEnd(Object.Position, StartPosition) end
				Position, StartPosition = nil, nil
			end
		end)
	end,
	MakeResizeable = function(Dragger, Object, MinSize, MaxSize, OnChange, OnEnd)
		local Position, StartSize = nil, nil

		Dragger.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				Position = UserInputService:GetMouseLocation()
				StartSize = Object.AbsoluteSize
			end
		end)
		UserInputService.InputChanged:Connect(function(Input)
			if StartSize and Input.UserInputType == Enum.UserInputType.MouseMovement then
				local Mouse = UserInputService:GetMouseLocation()
				local Delta = Mouse - Position
				local Size = StartSize + Delta

				local SizeX = math.max(MinSize.X, Size.X)
				-- SizeX = math.min(MaxSize.X, Size.X)

				local SizeY = math.max(MinSize.Y, Size.Y)
				-- SizeY = math.min(MaxSize.Y, Size.Y)

				OnChange(UDim2.fromOffset(SizeX, SizeY))
			end
		end)
		Dragger.InputEnded:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if OnEnd then OnEnd(Object.Size, StartSize) end
				Position, StartSize = nil, nil
			end
		end)
	end,
	ClosePopUps = function()
		for Index, Object in pairs(Bracket.Screen:GetChildren()) do
			if Object.Name == "OptionContainer" or Object.Name == "Palette" then
				Object.Visible = false
			end
		end
	end,
	ChooseTab = function(TabButtonAsset, TabAsset)
		for Index, Object in pairs(Bracket.Screen:GetChildren()) do
			if Object.Name == "OptionContainer" or Object.Name == "Palette" then
				Object.Visible = false
			end
		end
		for Index, Object in pairs(Bracket.Screen.Window.TabContainer:GetChildren()) do
			if Object:IsA("ScrollingFrame") then
				Object.Visible = Object == TabAsset
			end
		end
		for Index, Object in pairs(Bracket.Screen.Window.TabButtonContainer:GetChildren()) do
			if Object:IsA("TextButton") then
				Object.Highlight.Visible = Object == TabButtonAsset
			end
		end
	end,
	ChooseTabLegacy = function(TabButtonAsset, TabAsset)
		for Index, Object in pairs(Bracket.Screen:GetChildren()) do
			if Object.Name == "OptionContainer" or Object.Name == "Palette" then
				Object.Visible = false
			end
		end
		for Index, Object in pairs(Bracket.Screen.Window.TabContainer:GetChildren()) do
			if Object:IsA("ScrollingFrame") then
				Object.Visible = Object == TabAsset
			end
		end
		for Index, Object in pairs(Bracket.Screen.Window.TabButtonContainer:GetChildren()) do
			if Object:IsA("TextButton") then
				Object.BackgroundTransparency = (Object == TabButtonAsset) and 0 or 1
			end
		end
	end,
	GetNumberOfTabs = function()
		local NumberOfTabs = 0

		for Index, Object in pairs(Bracket.Screen.Window.TabContainer:GetChildren()) do
			if Object:IsA("ScrollingFrame") then
				NumberOfTabs = NumberOfTabs + 1
			end
		end

		return NumberOfTabs
	end,
	GetLongestSide = function(TabAsset)
		local LeftSideSize = TabAsset.LeftSide.ListLayout.AbsoluteContentSize
		local RightSideSize = TabAsset.RightSide.ListLayout.AbsoluteContentSize
		return LeftSideSize.Y >= RightSideSize.Y and TabAsset.LeftSide or TabAsset.RightSide
	end,
	GetShortestSide = function(TabAsset)
		local LeftSideSize = TabAsset.LeftSide.ListLayout.AbsoluteContentSize
		local RightSideSize = TabAsset.RightSide.ListLayout.AbsoluteContentSize
		return LeftSideSize.Y <= RightSideSize.Y and TabAsset.LeftSide or TabAsset.RightSide
	end,
	ChooseTabSide = function(Self, TabAsset, Mode)
		if Mode == "Left" then
			return TabAsset.LeftSide
		elseif Mode == "Right" then
			return TabAsset.RightSide
		else
			return Self.GetShortestSide(TabAsset)
		end
	end,
	FindElementByFlag = function(Elements, Flag)
		for Index, Element in pairs(Elements) do
			if Element.Flag and Element.Flag == Flag then
				return Element
			end
		end
	end,
	GetConfigs = function(FolderName)
		if not isfolder(FolderName) then makefolder(FolderName) end
		if not isfolder(FolderName .. "\\Configs") then makefolder(FolderName .. "\\Configs") end

		local Configs = {}
		for Index, Config in pairs(listfiles(FolderName .. "\\Configs") or {}) do
			Config = Config:gsub(FolderName .. "\\Configs\\", "")
			Config = Config:gsub(".json", "")

			Configs[#Configs + 1] = Config
		end

		return Configs
	end,
	ConfigsToList = function(FolderName)
		if not isfolder(FolderName) then makefolder(FolderName) end
		if not isfolder(FolderName .. "\\Configs") then makefolder(FolderName .. "\\Configs") end
		if not isfile(FolderName .. "\\AutoLoads.json") then writefile(FolderName .. "\\AutoLoads.json", "[]") end

		local AutoLoads = HttpService:JSONDecode(readfile(FolderName .. "\\AutoLoads.json"))
		local AutoLoad = AutoLoads[tostring(game.GameId)]

		local Configs = {}
		for Index, Config in pairs(listfiles(FolderName .. "\\Configs") or {}) do
			Config = Config:gsub(FolderName .. "\\Configs\\", "")
			Config = Config:gsub(".json", "")

			Configs[#Configs + 1] = {
				Name = Config,
				Mode = "Button",
				Value = Config == AutoLoad
			}
		end

		return Configs
	end
}
Bracket.Assets = {
	Screen = function(Self)
		local Screen = Instance.new("ScreenGui")
		Screen.Name = "Bracket"
		Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		Screen.ResetOnSpawn = false
		Screen.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
		Screen.IgnoreGuiInset = true
		Screen.DisplayOrder = Bracket.IsLocal and 0 or 10

		local Watermark = Self.Watermark()
		Watermark.Parent = Screen

		-- Push Notification Container
		local PNContainer = Self.PNContainer()
		PNContainer.Parent = Screen

		-- Toast Notification Container
		local TNContainer = Self.TNContainer()
		TNContainer.Parent = Screen

		local KeybindList = Self.KeybindList()
		KeybindList.Parent = Screen

		return Screen
	end,
	Tooltip = function()
		local Tooltip = Instance.new("TextLabel")
		Tooltip.Name = "Tooltip"
		Tooltip.ZIndex = 6
		Tooltip.Visible = false
		Tooltip.AnchorPoint = Vector2.new(0, 1)
		Tooltip.Size = UDim2.new(0, 45, 0, 18)
		Tooltip.BorderColor3 = Color3.fromRGB(63, 63, 63)
		Tooltip.Position = UDim2.new(0, 50, 0, 50)
		Tooltip.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Tooltip.TextStrokeTransparency = 0.75
		Tooltip.TextSize = 14
		Tooltip.RichText = true
		Tooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
		-- Tooltip.TextYAlignment = Enum.TextYAlignment.Top
		Tooltip.Text = "Tooltip"
		Tooltip.FontFace = Font.fromEnum(Enum.Font.SourceSans)

		return Tooltip
	end,
	Watermark = function()
		local Watermark = Instance.new("TextLabel")
		Watermark.Name = "Watermark"
		Watermark.Visible = false
		Watermark.AnchorPoint = Vector2.new(1, 0)
		Watermark.Size = UDim2.new(0, 61, 0, 18)
		Watermark.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Watermark.Position = UDim2.new(1, -18, 0, 18)
		Watermark.BorderSizePixel = 2
		Watermark.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Watermark.TextStrokeTransparency = 0.75
		Watermark.TextSize = 14
		Watermark.RichText = true
		Watermark.TextColor3 = Color3.fromRGB(255, 255, 255)
		-- Watermark.TextYAlignment = Enum.TextYAlignment.Top
		Watermark.Text = "Watermark"
		Watermark.FontFace = Font.fromEnum(Enum.Font.SourceSansSemibold)

		local Stroke = Instance.new("UIStroke")
		Stroke.Name = "Stroke"
		Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Stroke.LineJoinMode = Enum.LineJoinMode.Miter
		Stroke.Color = Color3.fromRGB(63, 63, 63)
		Stroke.Parent = Watermark

		return Watermark
	end,
	PNContainer = function()
		local PNContainer = Instance.new("Frame")
		PNContainer.Name = "PNContainer"
		PNContainer.ZIndex = 5
		PNContainer.AnchorPoint = Vector2.new(0.5, 0.5)
		PNContainer.Size = UDim2.new(1, 0, 1, 0)
		PNContainer.BorderColor3 = Color3.fromRGB(0, 0, 0)
		PNContainer.BackgroundTransparency = 1
		PNContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
		PNContainer.BorderSizePixel = 0
		PNContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Name = "ListLayout"
		ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		ListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout.Padding = UDim.new(0, 12)
		ListLayout.Parent = PNContainer

		local Padding = Instance.new("UIPadding")
		Padding.Name = "Padding"
		Padding.PaddingTop = UDim.new(0, 10)
		Padding.PaddingBottom = UDim.new(0, 10)
		Padding.PaddingLeft = UDim.new(0, 10)
		Padding.PaddingRight = UDim.new(0, 10)
		Padding.Parent = PNContainer


		return PNContainer
	end,
	TNContainer = function()
		local TNContainer = Instance.new("Frame")
		TNContainer.Name = "TNContainer"
		TNContainer.ZIndex = 5
		TNContainer.AnchorPoint = Vector2.new(0.5, 0.5)
		TNContainer.Size = UDim2.new(1, 0, 1, 0)
		TNContainer.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TNContainer.BackgroundTransparency = 1
		TNContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
		TNContainer.BorderSizePixel = 0
		TNContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Name = "ListLayout"
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout.Padding = UDim.new(0, 5)
		ListLayout.Parent = TNContainer

		local Padding = Instance.new("UIPadding")
		Padding.Name = "Padding"
		Padding.PaddingTop = UDim.new(0, 39)
		Padding.PaddingBottom = UDim.new(0, 10)
		Padding.Parent = TNContainer

		return TNContainer
	end,
	KeybindList = function()
		local KeybindList = Instance.new("Frame")
		KeybindList.Name = "KeybindList"
		KeybindList.ZIndex = 2
		KeybindList.Visible = false
		KeybindList.Size = UDim2.new(0, 121, 0, 246)
		KeybindList.BorderColor3 = Color3.fromRGB(0, 0, 0)
		KeybindList.Position = UDim2.new(0, 10, 0.5, -123)
		KeybindList.BorderSizePixel = 2
		KeybindList.BackgroundColor3 = Color3.fromRGB(31, 31, 31)

		local Stroke = Instance.new("UIStroke")
		Stroke.Name = "Stroke"
		Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Stroke.LineJoinMode = Enum.LineJoinMode.Miter
		Stroke.Color = Color3.fromRGB(63, 63, 63)
		Stroke.Parent = KeybindList

		local Topbar = Instance.new("Frame")
		Topbar.Name = "Topbar"
		Topbar.AnchorPoint = Vector2.new(0.5, 0)
		Topbar.Size = UDim2.new(1, 0, 0, 18)
		Topbar.BorderColor3 = Color3.fromRGB(63, 63, 63)
		Topbar.Position = UDim2.new(0.5, 0, 0, 0)
		Topbar.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Topbar.Parent = KeybindList

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.AnchorPoint = Vector2.new(0, 0.5)
		Title.Size = UDim2.new(1, -8, 1, 0)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0, 4, 0.5, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Title.TextStrokeTransparency = 0.75
		Title.TextTruncate = Enum.TextTruncate.SplitWord
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		-- Title.TextYAlignment = Enum.TextYAlignment.Top
		Title.Text = "Keybinds"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSansSemibold)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = Topbar

		local Background = Instance.new("ImageLabel")
		Background.Name = "Background"
		Background.ZIndex = 2
		Background.AnchorPoint = Vector2.new(0.5, 0)
		Background.Size = UDim2.new(1, 0, 1, -19)
		Background.ClipsDescendants = true
		Background.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Background.BackgroundTransparency = 1
		Background.Position = UDim2.new(0.5, 0, 0, 19)
		Background.BorderSizePixel = 0
		Background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Background.ScaleType = Enum.ScaleType.Tile
		Background.ImageColor3 = Color3.fromRGB(0, 0, 0)
		Background.TileSize = UDim2.new(0, 74, 0, 74)
		Background.Image = "rbxassetid://5553946656"
		Background.Parent = KeybindList

		local Resize = Instance.new("ImageButton")
		Resize.Name = "Resize"
		Resize.ZIndex = 4
		Resize.AnchorPoint = Vector2.new(1, 1)
		Resize.Size = UDim2.new(0, 10, 0, 10)
		Resize.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Resize.BackgroundTransparency = 1
		Resize.Position = UDim2.new(1, 0, 1, 0)
		Resize.BorderSizePixel = 0
		Resize.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Resize.ImageColor3 = Color3.fromRGB(63, 63, 63)
		Resize.ScaleType = Enum.ScaleType.Fit
		Resize.ResampleMode = Enum.ResamplerMode.Pixelated
		Resize.Image = "rbxassetid://7368471234"
		Resize.Parent = KeybindList

		local BindContainer = Instance.new("ScrollingFrame")
		BindContainer.Name = "BindContainer"
		BindContainer.ZIndex = 3
		BindContainer.AnchorPoint = Vector2.new(0.5, 0)
		BindContainer.Size = UDim2.new(1, 0, 1, -19)
		BindContainer.BorderColor3 = Color3.fromRGB(0, 0, 0)
		BindContainer.BackgroundTransparency = 1
		BindContainer.Position = UDim2.new(0.5, 0, 0, 19)
		BindContainer.Active = true
		BindContainer.BorderSizePixel = 0
		BindContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		BindContainer.ScrollingDirection = Enum.ScrollingDirection.Y
		BindContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
		BindContainer.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
		BindContainer.MidImage = "rbxassetid://6432766838"
		BindContainer.ScrollBarThickness = 0
		BindContainer.TopImage = "rbxassetid://6432766838"
		BindContainer.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
		BindContainer.BottomImage = "rbxassetid://6432766838"
		BindContainer.Parent = KeybindList

		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Name = "ListLayout"
		ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout.Padding = UDim.new(0, 4)
		ListLayout.Parent = BindContainer

		local Padding = Instance.new("UIPadding")
		Padding.Name = "Padding"
		Padding.PaddingTop = UDim.new(0, 4)
		Padding.PaddingLeft = UDim.new(0, 4)
		Padding.PaddingRight = UDim.new(0, 4)
		Padding.Parent = BindContainer

		return KeybindList
	end,
	KeybindMimic = function()
		local KeybindMimic = Instance.new("Frame")
		KeybindMimic.Name = "KeybindMimic"
		KeybindMimic.Size = UDim2.new(1, 0, 0, 14)
		KeybindMimic.BorderColor3 = Color3.fromRGB(0, 0, 0)
		KeybindMimic.BackgroundTransparency = 1
		KeybindMimic.BorderSizePixel = 0
		KeybindMimic.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.AnchorPoint = Vector2.new(0, 0.5)
		Title.Size = UDim2.new(1, -60, 1, 0)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0, 14, 0.5, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Title.TextStrokeTransparency = 0.75
		Title.TextTruncate = Enum.TextTruncate.SplitWord
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Keybind Mimic"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = KeybindMimic

		local Tick = Instance.new("Frame")
		Tick.Name = "Tick"
		Tick.Size = UDim2.new(0, 10, 0, 10)
		Tick.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Tick.Position = UDim2.new(0, 0, 0, 2)
		Tick.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		Tick.Parent = KeybindMimic

		local Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		Gradient.Parent = Tick

		local Layout = Instance.new("Frame")
		Layout.Name = "Layout"
		Layout.AnchorPoint = Vector2.new(1, 0)
		Layout.Size = UDim2.new(1, -14, 0, 14)
		Layout.ClipsDescendants = true
		Layout.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Layout.BackgroundTransparency = 1
		Layout.Position = UDim2.new(1, 0, 0, 0)
		Layout.BorderSizePixel = 0
		Layout.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Layout.Parent = KeybindMimic

		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Name = "ListLayout"
		ListLayout.FillDirection = Enum.FillDirection.Horizontal
		ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		ListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout.Padding = UDim.new(0, 4)
		ListLayout.Parent = Layout

		local Keybind = Instance.new("TextLabel")
		Keybind.Name = "Keybind"
		Keybind.Size = UDim2.new(0, 42, 1, 0)
		Keybind.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Keybind.BackgroundTransparency = 1
		Keybind.BorderSizePixel = 0
		Keybind.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Keybind.FontSize = Enum.FontSize.Size14
		Keybind.TextStrokeTransparency = 0.75
		Keybind.TextSize = 14
		Keybind.RichText = true
		Keybind.TextColor3 = Color3.fromRGB(191, 191, 191)
		Keybind.Text = "[ NONE ]"
		Keybind.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Keybind.Parent = Layout

		return KeybindMimic
	end,
	Window = function()
		local Window = Instance.new("Frame")
		Window.Name = "Window"
		Window.ZIndex = 3
		Window.Size = UDim2.new(0, 496, 0, 496)
		Window.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Window.Position = UDim2.new(0.5, -248, 0.5, -248)
		Window.BorderSizePixel = 2
		Window.BackgroundColor3 = Color3.fromRGB(31, 31, 31)

		local Stroke = Instance.new("UIStroke")
		Stroke.Name = "Stroke"
		Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Stroke.LineJoinMode = Enum.LineJoinMode.Miter
		Stroke.Color = Color3.fromRGB(63, 63, 63)
		Stroke.Parent = Window

		local Topbar = Instance.new("Frame")
		Topbar.Name = "Topbar"
		Topbar.AnchorPoint = Vector2.new(0.5, 0)
		Topbar.Size = UDim2.new(1, 0, 0, 18)
		Topbar.BorderColor3 = Color3.fromRGB(63, 63, 63)
		Topbar.Position = UDim2.new(0.5, 0, 0, 0)
		Topbar.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Topbar.Parent = Window

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.AnchorPoint = Vector2.new(0, 0.5)
		Title.Size = UDim2.new(1, -74, 1, 0)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0, 4, 0.5, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Title.TextStrokeTransparency = 0.75
		Title.TextTruncate = Enum.TextTruncate.SplitWord
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		-- Title.TextYAlignment = Enum.TextYAlignment.Top
		Title.Text = "Title"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSansSemibold)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = Topbar

		local Label = Instance.new("TextLabel")
		Label.Name = "Label"
		Label.AnchorPoint = Vector2.new(1, 0.5)
		Label.Size = UDim2.new(0, 62, 1, 0)
		Label.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Label.BackgroundTransparency = 1
		Label.Position = UDim2.new(1, -4, 0.5, 0)
		Label.BorderSizePixel = 0
		Label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Label.TextStrokeTransparency = 0.75
		Label.TextSize = 14
		Label.RichText = true
		Label.TextColor3 = Color3.fromRGB(191, 191, 191)
		-- Label.TextYAlignment = Enum.TextYAlignment.Top
		Label.Text = "Bracket V3.4"
		Label.FontFace = Font.fromEnum(Enum.Font.SourceSansSemibold)
		Label.TextXAlignment = Enum.TextXAlignment.Right
		Label.Parent = Topbar

		local Background = Instance.new("ImageLabel")
		Background.Name = "Background"
		Background.ZIndex = 2
		Background.AnchorPoint = Vector2.new(0.5, 0)
		Background.Size = UDim2.new(1, 0, 1, -19)
		Background.ClipsDescendants = true
		Background.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Background.BackgroundTransparency = 1
		Background.Position = UDim2.new(0.5, 0, 0, 19)
		Background.BorderSizePixel = 0
		Background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Background.ScaleType = Enum.ScaleType.Tile
		Background.ImageColor3 = Color3.fromRGB(0, 0, 0)
		Background.TileSize = UDim2.new(0, 74, 0, 74)
		Background.Image = "rbxassetid://5553946656"
		Background.Parent = Window

		local Resize = Instance.new("ImageButton")
		Resize.Name = "Resize"
		Resize.ZIndex = 5
		Resize.AnchorPoint = Vector2.new(1, 1)
		Resize.Size = UDim2.new(0, 10, 0, 10)
		Resize.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Resize.BackgroundTransparency = 1
		Resize.Position = UDim2.new(1, 0, 1, 0)
		Resize.BorderSizePixel = 0
		Resize.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Resize.ImageColor3 = Color3.fromRGB(63, 63, 63)
		Resize.ScaleType = Enum.ScaleType.Fit
		Resize.ResampleMode = Enum.ResamplerMode.Pixelated
		Resize.Image = "rbxassetid://7368471234"
		Resize.Parent = Window

		local TabContainer = Instance.new("Frame")
		TabContainer.Name = "TabContainer"
		TabContainer.ZIndex = 4
		TabContainer.AnchorPoint = Vector2.new(0.5, 0)
		TabContainer.Size = UDim2.new(1, 0, 1, -49)
		TabContainer.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TabContainer.BackgroundTransparency = 1
		TabContainer.Position = UDim2.new(0.5, 0, 0, 49)
		TabContainer.BorderSizePixel = 0
		TabContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		TabContainer.Parent = Window

		local TabButtonContainer = Instance.new("ScrollingFrame")
		TabButtonContainer.Name = "TabButtonContainer"
		TabButtonContainer.ZIndex = 3
		TabButtonContainer.AnchorPoint = Vector2.new(0.5, 0)
		TabButtonContainer.Size = UDim2.new(1, -12, 0, 18)
		TabButtonContainer.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TabButtonContainer.Position = UDim2.new(0.5, 0, 0, 25)
		TabButtonContainer.Active = true
		TabButtonContainer.BorderSizePixel = 2
		TabButtonContainer.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		TabButtonContainer.ScrollingDirection = Enum.ScrollingDirection.X
		TabButtonContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
		TabButtonContainer.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
		TabButtonContainer.MidImage = "rbxassetid://6432766838"
		TabButtonContainer.ScrollBarThickness = 0
		TabButtonContainer.TopImage = "rbxassetid://6432766838"
		TabButtonContainer.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
		TabButtonContainer.BottomImage = "rbxassetid://6432766838"
		TabButtonContainer.Parent = Window

		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Name = "ListLayout"
		ListLayout.FillDirection = Enum.FillDirection.Horizontal
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout.Parent = TabButtonContainer

		Stroke = Instance.new("UIStroke")
		Stroke.Name = "Stroke"
		Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Stroke.LineJoinMode = Enum.LineJoinMode.Miter
		Stroke.Color = Color3.fromRGB(63, 63, 63)
		Stroke.Parent = TabButtonContainer

		return Window
	end,
	Tab = function()
		local Tab = Instance.new("ScrollingFrame")
		Tab.Name = "Tab"
		Tab.AnchorPoint = Vector2.new(0.5, 0.5)
		Tab.Size = UDim2.new(1, 0, 1, 0)
		Tab.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Tab.BackgroundTransparency = 1
		Tab.Position = UDim2.new(0.5, 0, 0.5, 0)
		Tab.Active = true
		Tab.BorderSizePixel = 0
		Tab.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Tab.ScrollingDirection = Enum.ScrollingDirection.Y
		Tab.CanvasSize = UDim2.new(0, 0, 0, 0)
		Tab.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
		Tab.MidImage = "rbxassetid://6432766838"
		Tab.ScrollBarThickness = 0
		Tab.TopImage = "rbxassetid://6432766838"
		Tab.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
		Tab.BottomImage = "rbxassetid://6432766838"

		local LeftSide = Instance.new("Frame")
		LeftSide.Name = "LeftSide"
		LeftSide.Size = UDim2.new(0.5, 0, 1, 0)
		LeftSide.BorderColor3 = Color3.fromRGB(0, 0, 0)
		LeftSide.BackgroundTransparency = 1
		LeftSide.BorderSizePixel = 0
		LeftSide.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		LeftSide.Parent = Tab

		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Name = "ListLayout"
		ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout.Padding = UDim.new(0, 14)
		ListLayout.Parent = LeftSide

		local Padding = Instance.new("UIPadding")
		Padding.Name = "Padding"
		Padding.PaddingTop = UDim.new(0, 8)
		Padding.PaddingLeft = UDim.new(0, 6)
		Padding.PaddingRight = UDim.new(0, 4)
		Padding.Parent = LeftSide

		local RightSide = Instance.new("Frame")
		RightSide.Name = "RightSide"
		RightSide.AnchorPoint = Vector2.new(1, 0)
		RightSide.Size = UDim2.new(0.5, 0, 1, 0)
		RightSide.BorderColor3 = Color3.fromRGB(0, 0, 0)
		RightSide.BackgroundTransparency = 1
		RightSide.Position = UDim2.new(1, 0, 0, 0)
		RightSide.BorderSizePixel = 0
		RightSide.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		RightSide.Parent = Tab

		ListLayout = Instance.new("UIListLayout")
		ListLayout.Name = "ListLayout"
		ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout.Padding = UDim.new(0, 14)
		ListLayout.Parent = RightSide

		Padding = Instance.new("UIPadding")
		Padding.Name = "Padding"
		Padding.PaddingTop = UDim.new(0, 8)
		Padding.PaddingLeft = UDim.new(0, 4)
		Padding.PaddingRight = UDim.new(0, 6)
		Padding.Parent = RightSide

		return Tab
	end,
	TabButton = function()
		local TabButton = Instance.new("TextButton")
		TabButton.Name = "TabButton"
		TabButton.Size = UDim2.new(0, 67, 1, 0)
		TabButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TabButton.BackgroundTransparency = 1
		TabButton.BorderSizePixel = 0
		TabButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		TabButton.AutoButtonColor = false
		TabButton.TextStrokeTransparency = 0.75
		TabButton.TextSize = 14
		TabButton.RichText = true
		TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		-- TabButton.TextYAlignment = Enum.TextYAlignment.Top
		TabButton.Text = "TabButton"
		TabButton.FontFace = Font.fromEnum(Enum.Font.SourceSans)

		local Highlight = Instance.new("Frame")
		Highlight.Name = "Highlight"
		Highlight.Visible = false
		Highlight.AnchorPoint = Vector2.new(0.5, 1)
		Highlight.Size = UDim2.new(1, 0, 0, 1)
		Highlight.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Highlight.Position = UDim2.new(0.5, 0, 1, 0)
		Highlight.BorderSizePixel = 0
		Highlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Highlight.Parent = TabButton

		local Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.25, 0),
			NumberSequenceKeypoint.new(0.75, 0),
			NumberSequenceKeypoint.new(1, 1)
		})
		Gradient.Parent = Highlight

		return TabButton
	end,
	LegacyTabButton = function()
		local TabButton = Instance.new("TextButton")
		TabButton.Name = "TabButton"
		TabButton.Size = UDim2.new(0, 243, 1, 0)
		TabButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TabButton.BackgroundTransparency = 1
		TabButton.BorderSizePixel = 0
		TabButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TabButton.AutoButtonColor = false
		TabButton.TextSize = 14
		TabButton.TextColor3 = Color3.fromRGB(0, 0, 0)
		TabButton.Text = ""
		TabButton.FontFace = Font.fromEnum(Enum.Font.SourceSans)

		local Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		Gradient.Parent = TabButton

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.AnchorPoint = Vector2.new(0.5, 0.5)
		Title.Size = UDim2.new(1, 0, 1, 0)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0.5, 0, 0.5, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Title.TextStrokeTransparency = 0.75
		Title.TextTruncate = Enum.TextTruncate.SplitWord
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		-- Title.TextYAlignment = Enum.TextYAlignment.Top
		Title.Text = "TabButton"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.Parent = TabButton

		return TabButton
	end,
	Section = function()
		local Section = Instance.new("Frame")
		Section.Name = "Section"
		Section.Size = UDim2.new(1, 0, 0, 434)
		Section.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Section.BorderSizePixel = 2
		Section.BackgroundColor3 = Color3.fromRGB(31, 31, 31)

		local Stroke = Instance.new("UIStroke")
		Stroke.Name = "Stroke"
		Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Stroke.LineJoinMode = Enum.LineJoinMode.Miter
		Stroke.Color = Color3.fromRGB(63, 63, 63)
		Stroke.Parent = Section

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.Size = UDim2.new(1, -12, 0, 14)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0, 6, 0, -9)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Title.TextStrokeTransparency = 0.75
		Title.TextTruncate = Enum.TextTruncate.SplitWord
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Section"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = Section

		local Container = Instance.new("Frame")
		Container.Name = "Container"
		Container.AnchorPoint = Vector2.new(0.5, 0)
		Container.Size = UDim2.new(1, 0, 1, -14)
		Container.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Container.BackgroundTransparency = 1
		Container.Position = UDim2.new(0.5, 0, 0, 10)
		Container.BorderSizePixel = 0
		Container.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Container.Parent = Section

		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Name = "ListLayout"
		ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout.Padding = UDim.new(0, 6)
		ListLayout.Parent = Container

		local Padding = Instance.new("UIPadding")
		Padding.Name = "Padding"
		Padding.PaddingLeft = UDim.new(0, 5)
		Padding.PaddingRight = UDim.new(0, 5)
		Padding.Parent = Container

		return Section
	end,
	Divider = function()
		local Divider = Instance.new("Frame")
		Divider.Name = "Divider"
		Divider.Size = UDim2.new(1, 0, 0, 14)
		Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Divider.BackgroundTransparency = 1
		Divider.BorderSizePixel = 0
		Divider.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

		local Left = Instance.new("Frame")
		Left.Name = "Left"
		Left.AnchorPoint = Vector2.new(0, 0.5)
		Left.Size = UDim2.new(0.5, -24, 0, 2)
		Left.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Left.Position = UDim2.new(0, 0, 0.5, 0)
		Left.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		Left.Parent = Divider

		local Right = Instance.new("Frame")
		Right.Name = "Right"
		Right.AnchorPoint = Vector2.new(1, 0.5)
		Right.Size = UDim2.new(0.5, -24, 0, 2)
		Right.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Right.Position = UDim2.new(1, 0, 0.5, 0)
		Right.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		Right.Parent = Divider

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.AnchorPoint = Vector2.new(0.5, 0.5)
		Title.Size = UDim2.new(1, 0, 1, 0)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0.5, 0, 0.5, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Divider"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.Parent = Divider

		return Divider
	end,
	Label = function()
		local Label = Instance.new("TextLabel")
		Label.Name = "Label"
		Label.Size = UDim2.new(1, 0, 0, 14)
		Label.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Label.BackgroundTransparency = 1
		Label.BorderSizePixel = 0
		Label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Label.TextStrokeTransparency = 0.75
		Label.TextSize = 14
		Label.RichText = true
		Label.TextColor3 = Color3.fromRGB(255, 255, 255)
		Label.Text = "TextLabel"
		Label.TextWrapped = true
		Label.FontFace = Font.fromEnum(Enum.Font.SourceSans)

		return Label
	end,
	Button = function()
		local Button = Instance.new("TextButton")
		Button.Name = "Button"
		Button.Size = UDim2.new(1, 0, 0, 18)
		Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Button.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		Button.AutoButtonColor = false
		Button.TextSize = 14
		Button.TextColor3 = Color3.fromRGB(0, 0, 0)
		Button.Text = ""
		Button.FontFace = Font.fromEnum(Enum.Font.SourceSans)

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.AnchorPoint = Vector2.new(0.5, 0.5)
		Title.Size = UDim2.new(1, -8, 1, 0)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0.5, 0, 0.5, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Button"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.Parent = Button

		local Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		Gradient.Parent = Button

		return Button
	end,
	Button2 = function()
		local Button = Instance.new("Frame")
		Button.Name = "Button"
		Button.Size = UDim2.new(1, 0, 0, 18)
		Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Button.BackgroundTransparency = 1
		Button.BorderSizePixel = 0
		Button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.Size = UDim2.new(1, -48, 1, 0)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Button"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = Button

		local ActualButton = Instance.new("TextButton")
		ActualButton.Name = "Button"
		ActualButton.AnchorPoint = Vector2.new(1, 0)
		ActualButton.Size = UDim2.new(0, 44, 0, 18)
		ActualButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ActualButton.Position = UDim2.new(1, 0, 0, 0)
		ActualButton.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		ActualButton.AutoButtonColor = false
		ActualButton.TextSize = 14
		ActualButton.TextColor3 = Color3.fromRGB(0, 0, 0)
		ActualButton.Text = ""
		ActualButton.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		ActualButton.Parent = Button

		Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.AnchorPoint = Vector2.new(0.5, 0.5)
		Title.Size = UDim2.new(1, -8, 1, 0)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0.5, 0, 0.5, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Button"
		-- Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.Parent = ActualButton

		local Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		Gradient.Parent = ActualButton

		return Button
	end,
	Toggle = function()
		local Toggle = Instance.new("TextButton")
		Toggle.Name = "Toggle"
		Toggle.Size = UDim2.new(1, 0, 0, 14)
		Toggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Toggle.BackgroundTransparency = 1
		Toggle.BorderSizePixel = 0
		Toggle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Toggle.AutoButtonColor = false
		Toggle.TextSize = 14
		Toggle.TextColor3 = Color3.fromRGB(0, 0, 0)
		Toggle.Text = ""
		Toggle.FontFace = Font.fromEnum(Enum.Font.SourceSans)

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.AnchorPoint = Vector2.new(0, 0.5)
		Title.Size = UDim2.new(1, -60, 1, 0)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0, 14, 0.5, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Title.TextStrokeTransparency = 0.75
		Title.TextTruncate = Enum.TextTruncate.SplitWord
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Toggle"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = Toggle

		local Tick = Instance.new("Frame")
		Tick.Name = "Tick"
		Tick.Size = UDim2.new(0, 10, 0, 10)
		Tick.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Tick.Position = UDim2.new(0, 0, 0, 2)
		Tick.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		Tick.Parent = Toggle

		local Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		Gradient.Parent = Tick

		local Layout = Instance.new("Frame")
		Layout.Name = "Layout"
		Layout.AnchorPoint = Vector2.new(1, 0)
		Layout.Size = UDim2.new(1, -14, 0, 14)
		Layout.ClipsDescendants = true
		Layout.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Layout.BackgroundTransparency = 1
		Layout.Position = UDim2.new(1, 0, 0, 0)
		Layout.BorderSizePixel = 0
		Layout.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Layout.Parent = Toggle

		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Name = "ListLayout"
		ListLayout.FillDirection = Enum.FillDirection.Horizontal
		ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		ListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout.Padding = UDim.new(0, 4)
		ListLayout.Parent = Layout

		local Padding = Instance.new("UIPadding")
		Padding.Name = "Padding"
		Padding.PaddingRight = UDim.new(0, 1)
		Padding.Parent = Layout

		return Toggle
	end,
	Slider = function()
		local Slider = Instance.new("TextButton")
		Slider.Name = "Slider"
		Slider.Size = UDim2.new(1, 0, 0, 18)
		Slider.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Slider.BackgroundTransparency = 1
		Slider.BorderSizePixel = 0
		Slider.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Slider.AutoButtonColor = false
		Slider.TextSize = 14
		Slider.TextColor3 = Color3.fromRGB(0, 0, 0)
		Slider.Text = ""
		Slider.FontFace = Font.fromEnum(Enum.Font.SourceSans)

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.ZIndex = 2
		Title.Size = UDim2.new(1, -24, 1, 0)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0, 4, 0, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Slider"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = Slider

		local Value = Instance.new("TextBox")
		Value.Name = "Value"
		Value.ZIndex = 2
		Value.AnchorPoint = Vector2.new(1, 0)
		Value.Size = UDim2.new(0, 12, 1, 0)
		Value.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Value.BackgroundTransparency = 1
		Value.Position = UDim2.new(1, -4, 0, 0)
		Value.BorderSizePixel = 0
		Value.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Value.TextStrokeTransparency = 0.75
		Value.PlaceholderColor3 = Color3.fromRGB(191, 191, 191)
		Value.TextSize = 14
		Value.TextColor3 = Color3.fromRGB(255, 255, 255)
		Value.PlaceholderText = "50"
		Value.Text = ""
		Value.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Value.TextXAlignment = Enum.TextXAlignment.Right
		Value.Parent = Slider

		local Background = Instance.new("Frame")
		Background.Name = "Background"
		Background.AnchorPoint = Vector2.new(0.5, 0.5)
		Background.Size = UDim2.new(1, 0, 1, 0)
		Background.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Background.Position = UDim2.new(0.5, 0, 0.5, 0)
		Background.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		Background.Parent = Slider

		local Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		Gradient.Parent = Background

		local Bar = Instance.new("Frame")
		Bar.Name = "Bar"
		Bar.ZIndex = 2
		Bar.AnchorPoint = Vector2.new(0, 0.5)
		Bar.Size = UDim2.new(0.5, 0, 1, 0)
		Bar.BorderColor3 = Color3.fromRGB(30, 30, 30)
		Bar.Position = UDim2.new(0, 0, 0.5, 0)
		Bar.BorderSizePixel = 0
		Bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Bar.Parent = Background

		Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		Gradient.Parent = Bar

		return Slider
	end,
	SlimSlider = function()
		local SlimSlider = Instance.new("TextButton")
		SlimSlider.Name = "SlimSlider"
		SlimSlider.Size = UDim2.new(1, 0, 0, 28)
		SlimSlider.BorderColor3 = Color3.fromRGB(0, 0, 0)
		SlimSlider.BackgroundTransparency = 1
		SlimSlider.BorderSizePixel = 0
		SlimSlider.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		SlimSlider.AutoButtonColor = false
		SlimSlider.TextSize = 14
		SlimSlider.TextColor3 = Color3.fromRGB(0, 0, 0)
		SlimSlider.Text = ""
		SlimSlider.FontFace = Font.fromEnum(Enum.Font.SourceSans)

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.Size = UDim2.new(1, -16, 0, 14)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Slider"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = SlimSlider

		local Value = Instance.new("TextBox")
		Value.Name = "Value"
		Value.AnchorPoint = Vector2.new(1, 0)
		Value.Size = UDim2.new(0, 12, 0, 14)
		Value.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Value.BackgroundTransparency = 1
		Value.Position = UDim2.new(1, 0, 0, 0)
		Value.BorderSizePixel = 0
		Value.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Value.TextStrokeTransparency = 0.75
		Value.PlaceholderColor3 = Color3.fromRGB(191, 191, 191)
		Value.TextSize = 14
		Value.TextColor3 = Color3.fromRGB(255, 255, 255)
		Value.PlaceholderText = "50"
		Value.Text = ""
		Value.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Value.TextXAlignment = Enum.TextXAlignment.Right
		Value.Parent = SlimSlider

		local Background = Instance.new("Frame")
		Background.Name = "Background"
		Background.AnchorPoint = Vector2.new(0.5, 0)
		Background.Size = UDim2.new(1, 0, 0, 10)
		Background.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Background.Position = UDim2.new(0.5, 0, 0, 18)
		Background.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		Background.Parent = SlimSlider

		local Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		Gradient.Parent = Background

		local Bar = Instance.new("Frame")
		Bar.Name = "Bar"
		Bar.AnchorPoint = Vector2.new(0, 0.5)
		Bar.Size = UDim2.new(0.5, 0, 1, 0)
		Bar.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Bar.Position = UDim2.new(0, 0, 0.5, 0)
		Bar.BorderSizePixel = 0
		Bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Bar.Parent = Background

		Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		Gradient.Parent = Bar

		return SlimSlider
	end,
	Textbox = function()
		local Textbox = Instance.new("TextButton")
		Textbox.Name = "Textbox"
		Textbox.Size = UDim2.new(1, 0, 0, 36)
		Textbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Textbox.BackgroundTransparency = 1
		Textbox.BorderSizePixel = 0
		Textbox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Textbox.AutoButtonColor = false
		Textbox.TextSize = 14
		Textbox.TextColor3 = Color3.fromRGB(0, 0, 0)
		Textbox.Text = ""
		Textbox.FontFace = Font.fromEnum(Enum.Font.SourceSans)

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.AnchorPoint = Vector2.new(0.5, 0)
		Title.Size = UDim2.new(1, 0, 0, 14)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0.5, 0, 0, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Textbox"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = Textbox

		local Background = Instance.new("Frame")
		Background.Name = "Background"
		Background.AnchorPoint = Vector2.new(0.5, 0)
		Background.Size = UDim2.new(1, 0, 0, 18)
		Background.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Background.Position = UDim2.new(0.5, 0, 0, 18)
		Background.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		Background.Parent = Textbox

		local Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		Gradient.Parent = Background

		local Input = Instance.new("TextBox")
		Input.Name = "Input"
		Input.AnchorPoint = Vector2.new(0.5, 0.5)
		Input.Size = UDim2.new(1, -10, 1, 0)
		Input.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Input.BackgroundTransparency = 1
		Input.Position = UDim2.new(0.5, 0, 0.5, 0)
		Input.BorderSizePixel = 0
		Input.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Input.TextStrokeTransparency = 0.75
		Input.TextWrapped = true
		Input.PlaceholderColor3 = Color3.fromRGB(191, 191, 191)
		Input.TextSize = 14
		Input.TextColor3 = Color3.fromRGB(255, 255, 255)
		Input.PlaceholderText = "Input here"
		Input.Text = ""
		Input.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Input.ClearTextOnFocus = false
		Input.Parent = Background

		return Textbox
	end,
	Keybind = function()
		local Keybind = Instance.new("TextButton")
		Keybind.Name = "Keybind"
		Keybind.Size = UDim2.new(1, 0, 0, 14)
		Keybind.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Keybind.BackgroundTransparency = 1
		Keybind.BorderSizePixel = 0
		Keybind.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Keybind.AutoButtonColor = false
		Keybind.TextSize = 14
		Keybind.TextColor3 = Color3.fromRGB(0, 0, 0)
		Keybind.Text = ""
		Keybind.FontFace = Font.fromEnum(Enum.Font.SourceSans)

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.AnchorPoint = Vector2.new(0, 0.5)
		Title.Size = UDim2.new(1, -46, 1, 0)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0, 0, 0.5, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Keybind"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = Keybind

		local Value = Instance.new("TextLabel")
		Value.Name = "Value"
		Value.AnchorPoint = Vector2.new(1, 0)
		Value.Size = UDim2.new(0, 42, 0, 14)
		Value.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Value.BackgroundTransparency = 1
		Value.Position = UDim2.new(1, 0, 0, 0)
		Value.BorderSizePixel = 0
		Value.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Value.TextStrokeTransparency = 0.75
		Value.TextSize = 14
		Value.RichText = true
		Value.TextColor3 = Color3.fromRGB(191, 191, 191)
		Value.Text = "[ NONE ]"
		Value.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Value.TextXAlignment = Enum.TextXAlignment.Right
		Value.Parent = Keybind

		return Keybind
	end,
	ToggleKeybind = function()
		local TKeybind = Instance.new("TextButton")
		TKeybind.Name = "TKeybind"
		TKeybind.Size = UDim2.new(0, 42, 1, 0)
		TKeybind.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TKeybind.BackgroundTransparency = 1
		TKeybind.BorderSizePixel = 0
		TKeybind.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		TKeybind.AutoButtonColor = false
		TKeybind.TextStrokeTransparency = 0.75
		TKeybind.TextSize = 14
		TKeybind.RichText = true
		TKeybind.TextColor3 = Color3.fromRGB(191, 191, 191)
		TKeybind.Text = "[ NONE ]"
		TKeybind.FontFace = Font.fromEnum(Enum.Font.SourceSans)

		return TKeybind
	end,
	Dropdown = function()
		local Dropdown = Instance.new("TextButton")
		Dropdown.Name = "Dropdown"
		Dropdown.Size = UDim2.new(1, 0, 0, 37)
		Dropdown.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Dropdown.BackgroundTransparency = 1
		Dropdown.BorderSizePixel = 0
		Dropdown.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Dropdown.AutoButtonColor = false
		Dropdown.TextSize = 14
		Dropdown.TextColor3 = Color3.fromRGB(0, 0, 0)
		Dropdown.Text = ""
		Dropdown.FontFace = Font.fromEnum(Enum.Font.SourceSans)

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.AnchorPoint = Vector2.new(0.5, 0)
		Title.Size = UDim2.new(1, 0, 0, 14)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0.5, 0, 0, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Dropdown"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = Dropdown

		local Background = Instance.new("Frame")
		Background.Name = "Background"
		Background.AnchorPoint = Vector2.new(0.5, 0)
		Background.Size = UDim2.new(1, 0, 0, 18)
		Background.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Background.Position = UDim2.new(0.5, 0, 0, 18)
		Background.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		Background.Parent = Dropdown

		local Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		Gradient.Parent = Background

		local Value = Instance.new("TextLabel")
		Value.Name = "Value"
		Value.AnchorPoint = Vector2.new(0.5, 0.5)
		Value.Size = UDim2.new(1, -10, 1, 0)
		Value.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Value.BackgroundTransparency = 1
		Value.Position = UDim2.new(0.5, 0, 0.5, 0)
		Value.BorderSizePixel = 0
		Value.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Value.TextStrokeTransparency = 0.75
		Value.TextTruncate = Enum.TextTruncate.SplitWord
		Value.TextSize = 14
		Value.TextColor3 = Color3.fromRGB(255, 255, 255)
		Value.Text = "..."
		Value.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Value.TextXAlignment = Enum.TextXAlignment.Left
		Value.Parent = Background

		return Dropdown
	end,
	OptionContainer = function()
		local OptionContainer = Instance.new("ScrollingFrame")
		OptionContainer.Name = "OptionContainer"
		OptionContainer.ZIndex = 4
		OptionContainer.Visible = false
		OptionContainer.Size = UDim2.new(0, 100, 0, 100)
		OptionContainer.BorderColor3 = Color3.fromRGB(0, 0, 0)
		OptionContainer.Position = UDim2.new(0, 100, 0, 100)
		OptionContainer.Active = true
		OptionContainer.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		OptionContainer.ScrollingDirection = Enum.ScrollingDirection.Y
		OptionContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
		OptionContainer.ScrollBarImageColor3 = Color3.fromRGB(63, 63, 63)
		OptionContainer.MidImage = "rbxassetid://6432766838"
		OptionContainer.ScrollBarThickness = 6
		OptionContainer.TopImage = "rbxassetid://6432766838"
		OptionContainer.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
		OptionContainer.BottomImage = "rbxassetid://6432766838"

		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Name = "ListLayout"
		ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout.Padding = UDim.new(0, 2)
		ListLayout.Parent = OptionContainer

		local Padding = Instance.new("UIPadding")
		Padding.Name = "Padding"
		Padding.PaddingTop = UDim.new(0, 3)
		Padding.PaddingBottom = UDim.new(0, 3)
		Padding.PaddingLeft = UDim.new(0, 5)
		Padding.PaddingRight = UDim.new(0, 5)
		Padding.Parent = OptionContainer

		return OptionContainer
	end,
	DropdownOption = function()
		local Option = Instance.new("TextButton")
		Option.Name = "Option"
		Option.Size = UDim2.new(1, 0, 0, 14)
		Option.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Option.BackgroundTransparency = 1
		Option.BorderSizePixel = 0
		Option.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Option.AutoButtonColor = false
		Option.TextSize = 14
		Option.TextColor3 = Color3.fromRGB(0, 0, 0)
		Option.Text = ""
		Option.FontFace = Font.fromEnum(Enum.Font.SourceSans)

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.AnchorPoint = Vector2.new(0, 0.5)
		Title.Size = UDim2.new(1, -38, 1, 0)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0, 14, 0.5, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Title.TextStrokeTransparency = 0.75
		Title.TextTruncate = Enum.TextTruncate.SplitWord
		Title.TextSize = 14
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Option"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = Option

		local Tick = Instance.new("Frame")
		Tick.Name = "Tick"
		Tick.Size = UDim2.new(0, 10, 0, 10)
		Tick.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Tick.Position = UDim2.new(0, 0, 0, 2)
		Tick.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		Tick.Parent = Option

		local Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		Gradient.Parent = Tick

		local Layout = Instance.new("Frame")
		Layout.Name = "Layout"
		Layout.AnchorPoint = Vector2.new(1, 0)
		Layout.Size = UDim2.new(1, -14, 0, 14)
		Layout.ClipsDescendants = true
		Layout.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Layout.BackgroundTransparency = 1
		Layout.Position = UDim2.new(1, 0, 0, 0)
		Layout.BorderSizePixel = 0
		Layout.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Layout.Parent = Option

		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Name = "ListLayout"
		ListLayout.FillDirection = Enum.FillDirection.Horizontal
		ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		ListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout.Padding = UDim.new(0, 4)
		ListLayout.Parent = Layout

		local Padding = Instance.new("UIPadding")
		Padding.Name = "Padding"
		Padding.PaddingRight = UDim.new(0, 1)
		Padding.Parent = Layout

		return Option
	end,
	Colorpicker = function()
		local Colorpicker = Instance.new("TextButton")
		Colorpicker.Name = "Colorpicker"
		Colorpicker.Size = UDim2.new(1, 0, 0, 14)
		Colorpicker.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Colorpicker.BackgroundTransparency = 1
		Colorpicker.BorderSizePixel = 0
		Colorpicker.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Colorpicker.AutoButtonColor = false
		Colorpicker.TextSize = 14
		Colorpicker.TextColor3 = Color3.fromRGB(0, 0, 0)
		Colorpicker.Text = ""
		Colorpicker.FontFace = Font.fromEnum(Enum.Font.SourceSans)

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.Size = UDim2.new(1, -24, 1, 0)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Colorpicker"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = Colorpicker

		local Color = Instance.new("Frame")
		Color.Name = "Color"
		Color.AnchorPoint = Vector2.new(1, 0)
		Color.Size = UDim2.new(0, 20, 0, 10)
		Color.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Color.Position = UDim2.new(1, 0, 0, 2)
		Color.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Color.Parent = Colorpicker

		local Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		Gradient.Parent = Color

		return Colorpicker
	end,
	ToggleColorpicker = function()
		local TColorpicker = Instance.new("TextButton")
		TColorpicker.Name = "TColorpicker"
		TColorpicker.AnchorPoint = Vector2.new(1, 0.5)
		TColorpicker.Size = UDim2.new(0, 20, 0, 10)
		TColorpicker.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TColorpicker.Position = UDim2.new(1, 0, 0.5, 0)
		TColorpicker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TColorpicker.AutoButtonColor = false
		TColorpicker.TextSize = 14
		TColorpicker.TextColor3 = Color3.fromRGB(0, 0, 0)
		TColorpicker.Text = ""
		TColorpicker.FontFace = Font.fromEnum(Enum.Font.SourceSans)

		local Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		Gradient.Parent = TColorpicker

		return TColorpicker
	end,
	ColorpickerPalette = function()
		local Palette = Instance.new("Frame")
		Palette.Name = "Palette"
		Palette.ZIndex = 4
		Palette.Visible = false
		Palette.Size = UDim2.new(0, 150, 0, 290)
		Palette.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Palette.Position = UDim2.new(0, 100, 0, 100)
		Palette.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

		local Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		Gradient.Parent = Palette

		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Name = "ListLayout"
		ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout.Padding = UDim.new(0, 6)
		ListLayout.Parent = Palette

		local Padding = Instance.new("UIPadding")
		Padding.Name = "Padding"
		Padding.PaddingTop = UDim.new(0, 5)
		Padding.PaddingBottom = UDim.new(0, 5)
		Padding.PaddingLeft = UDim.new(0, 5)
		Padding.PaddingRight = UDim.new(0, 5)
		Padding.Parent = Palette

		local SVPicker = Instance.new("TextButton")
		SVPicker.Name = "SVPicker"
		SVPicker.AnchorPoint = Vector2.new(0.5, 0)
		SVPicker.Size = UDim2.new(1, 0, 0, 180)
		SVPicker.BorderColor3 = Color3.fromRGB(0, 0, 0)
		SVPicker.Position = UDim2.new(0.5, 0, 0, 0)
		SVPicker.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		SVPicker.AutoButtonColor = false
		SVPicker.TextSize = 14
		SVPicker.TextColor3 = Color3.fromRGB(0, 0, 0)
		SVPicker.Text = ""
		SVPicker.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		SVPicker.Parent = Palette

		local Brightness = Instance.new("Frame")
		Brightness.Name = "Brightness"
		Brightness.AnchorPoint = Vector2.new(0.5, 0.5)
		Brightness.Size = UDim2.new(1, 0, 1, 0)
		Brightness.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Brightness.Position = UDim2.new(0.5, 0, 0.5, 0)
		Brightness.BorderSizePixel = 0
		Brightness.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Brightness.Parent = SVPicker

		Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Transparency = NumberSequence.new(0, 1)
		Gradient.Parent = Brightness

		local Saturation = Instance.new("Frame")
		Saturation.Name = "Saturation"
		Saturation.ZIndex = 2
		Saturation.AnchorPoint = Vector2.new(0.5, 0.5)
		Saturation.Size = UDim2.new(1, 0, 1, 0)
		Saturation.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Saturation.Position = UDim2.new(0.5, 0, 0.5, 0)
		Saturation.BorderSizePixel = 0
		Saturation.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		Saturation.Parent = SVPicker

		Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Transparency = NumberSequence.new(1, 0)
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0))
		Gradient.Parent = Saturation

		local Pin = Instance.new("Frame")
		Pin.Name = "Pin"
		Pin.ZIndex = 3
		Pin.AnchorPoint = Vector2.new(0.5, 0.5)
		Pin.Size = UDim2.new(0, 3, 0, 3)
		Pin.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Pin.Rotation = 45
		Pin.BackgroundTransparency = 1
		Pin.Position = UDim2.new(0.5, 0, 0.5, 0)
		Pin.BorderSizePixel = 0
		Pin.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Pin.Parent = SVPicker

		local Stroke = Instance.new("UIStroke")
		Stroke.Name = "Stroke"
		Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Stroke.LineJoinMode = Enum.LineJoinMode.Miter
		Stroke.Thickness = 1.5
		Stroke.Parent = Pin

		local Hue = Instance.new("TextButton")
		Hue.Name = "Hue"
		Hue.LayoutOrder = 1
		Hue.AnchorPoint = Vector2.new(0.5, 0)
		Hue.Size = UDim2.new(1, 0, 0, 10)
		Hue.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Hue.Position = UDim2.new(0.5, 0, 0, 151)
		Hue.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Hue.AutoButtonColor = false
		Hue.TextSize = 14
		Hue.TextColor3 = Color3.fromRGB(0, 0, 0)
		Hue.Text = ""
		Hue.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Hue.Parent = Palette

		Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.1666667, Color3.fromRGB(255, 0, 255)), ColorSequenceKeypoint.new(0.3333333, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)), ColorSequenceKeypoint.new(0.6666667, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.8333333, Color3.fromRGB(255, 255, 0)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))})
		Gradient.Parent = Hue

		Pin = Instance.new("Frame")
		Pin.Name = "Pin"
		Pin.ZIndex = 3
		Pin.AnchorPoint = Vector2.new(0.5, 0.5)
		Pin.Size = UDim2.new(0, 1, 1, 0)
		Pin.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Pin.Position = UDim2.new(0, 0, 0.5, 0)
		Pin.BackgroundColor3 = Color3.fromRGB(252, 252, 252)
		Pin.Parent = Hue

		local Alpha = Instance.new("TextButton")
		Alpha.Name = "Alpha"
		Alpha.LayoutOrder = 2
		Alpha.AnchorPoint = Vector2.new(0.5, 0)
		Alpha.Size = UDim2.new(1, 0, 0, 10)
		Alpha.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Alpha.Position = UDim2.new(0.5, 0, 0, 207)
		Alpha.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		Alpha.AutoButtonColor = false
		Alpha.TextSize = 14
		Alpha.TextColor3 = Color3.fromRGB(0, 0, 0)
		Alpha.Text = ""
		Alpha.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Alpha.Parent = Palette

		Stroke = Instance.new("UIStroke")
		Stroke.Name = "Stroke"
		Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Stroke.LineJoinMode = Enum.LineJoinMode.Miter
		Stroke.Parent = Alpha

		Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Transparency = NumberSequence.new(0, 1)
		Gradient.Parent = Alpha

		Pin = Instance.new("Frame")
		Pin.Name = "Pin"
		Pin.AnchorPoint = Vector2.new(0.5, 0.5)
		Pin.Size = UDim2.new(0, 1, 1, 0)
		Pin.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Pin.Position = UDim2.new(0, 0, 0.5, 0)
		Pin.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Pin.Parent = Alpha

		local Value = Instance.new("TextLabel")
		Value.Name = "Value"
		Value.AnchorPoint = Vector2.new(0.5, 0.5)
		Value.Size = UDim2.new(1, -8, 1, 0)
		Value.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Value.BackgroundTransparency = 1
		Value.Position = UDim2.new(0.5, 0, 0.5, 0)
		Value.BorderSizePixel = 0
		Value.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Value.TextStrokeTransparency = 0.75
		Value.TextSize = 12
		Value.TextColor3 = Color3.fromRGB(255, 255, 255)
		Value.TextYAlignment = Enum.TextYAlignment.Bottom
		Value.Text = "1"
		Value.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Value.TextXAlignment = Enum.TextXAlignment.Right
		Value.Parent = Alpha

		local RGB = Instance.new("Frame")
		RGB.Name = "RGB"
		RGB.LayoutOrder = 3
		RGB.AnchorPoint = Vector2.new(0.5, 0)
		RGB.Size = UDim2.new(1, 0, 0, 18)
		RGB.BorderColor3 = Color3.fromRGB(0, 0, 0)
		RGB.Position = UDim2.new(0.5, 0, 0, 223)
		RGB.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		RGB.Parent = Palette

		local RGBBox = Instance.new("TextBox")
		RGBBox.Name = "RGBBox"
		RGBBox.ZIndex = 3
		RGBBox.AnchorPoint = Vector2.new(0, 0.5)
		RGBBox.Size = UDim2.new(1, -30, 1, 0)
		RGBBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
		RGBBox.BackgroundTransparency = 1
		RGBBox.Position = UDim2.new(0, 30, 0.5, 0)
		RGBBox.BorderSizePixel = 0
		RGBBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		RGBBox.TextStrokeTransparency = 0.75
		RGBBox.PlaceholderColor3 = Color3.fromRGB(191, 191, 191)
		RGBBox.TextSize = 14
		RGBBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		RGBBox.PlaceholderText = "255, 0, 0"
		RGBBox.Text = ""
		RGBBox.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		RGBBox.TextXAlignment = Enum.TextXAlignment.Left
		RGBBox.Parent = RGB

		Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		Gradient.Parent = RGB

		local RGBText = Instance.new("TextLabel")
		RGBText.Name = "RGBText"
		RGBText.ZIndex = 3
		RGBText.AnchorPoint = Vector2.new(0, 0.5)
		RGBText.Size = UDim2.new(0, 26, 1, 0)
		RGBText.BorderColor3 = Color3.fromRGB(0, 0, 0)
		RGBText.BackgroundTransparency = 1
		RGBText.Position = UDim2.new(0, 4, 0.5, 0)
		RGBText.BorderSizePixel = 0
		RGBText.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		RGBText.TextStrokeTransparency = 0.75
		RGBText.TextSize = 14
		RGBText.TextColor3 = Color3.fromRGB(255, 255, 255)
		RGBText.Text = "RGB: "
		RGBText.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		RGBText.TextXAlignment = Enum.TextXAlignment.Left
		RGBText.Parent = RGB

		local HEX = Instance.new("Frame")
		HEX.Name = "HEX"
		HEX.LayoutOrder = 4
		HEX.AnchorPoint = Vector2.new(0.5, 0)
		HEX.Size = UDim2.new(1, 0, 0, 18)
		HEX.BorderColor3 = Color3.fromRGB(0, 0, 0)
		HEX.Position = UDim2.new(0.5, 0, 0, 249)
		HEX.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		HEX.Parent = Palette

		local HEXBox = Instance.new("TextBox")
		HEXBox.Name = "HEXBox"
		HEXBox.AnchorPoint = Vector2.new(0, 0.5)
		HEXBox.Size = UDim2.new(1, -35, 1, 0)
		HEXBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
		HEXBox.BackgroundTransparency = 1
		HEXBox.Position = UDim2.new(0, 35, 0.5, 0)
		HEXBox.BorderSizePixel = 0
		HEXBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		HEXBox.TextStrokeTransparency = 0.75
		HEXBox.PlaceholderColor3 = Color3.fromRGB(191, 191, 191)
		HEXBox.TextSize = 14
		HEXBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		HEXBox.PlaceholderText = "FF0000"
		HEXBox.Text = ""
		HEXBox.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		HEXBox.TextXAlignment = Enum.TextXAlignment.Left
		HEXBox.Parent = HEX

		local HEXText = Instance.new("TextLabel")
		HEXText.Name = "HEXText"
		HEXText.AnchorPoint = Vector2.new(0, 0.5)
		HEXText.Size = UDim2.new(0, 31, 1, 0)
		HEXText.BorderColor3 = Color3.fromRGB(0, 0, 0)
		HEXText.BackgroundTransparency = 1
		HEXText.Position = UDim2.new(0, 4, 0.5, 0)
		HEXText.BorderSizePixel = 0
		HEXText.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		HEXText.FontSize = Enum.FontSize.Size14
		HEXText.TextStrokeTransparency = 0.75
		HEXText.TextSize = 14
		HEXText.TextColor3 = Color3.fromRGB(255, 255, 255)
		HEXText.Text = "HEX: #"
		HEXText.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		HEXText.TextXAlignment = Enum.TextXAlignment.Left
		HEXText.Parent = HEX

		Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		Gradient.Parent = HEX

		local Rainbow = Instance.new("TextButton")
		Rainbow.Name = "Rainbow"
		Rainbow.LayoutOrder = 5
		Rainbow.AnchorPoint = Vector2.new(0.5, 0)
		Rainbow.Size = UDim2.new(1, 0, 0, 14)
		Rainbow.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Rainbow.BackgroundTransparency = 1
		Rainbow.Position = UDim2.new(0.5, 0, 0, 270)
		Rainbow.BorderSizePixel = 0
		Rainbow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Rainbow.AutoButtonColor = false
		Rainbow.TextSize = 14
		Rainbow.TextColor3 = Color3.fromRGB(0, 0, 0)
		Rainbow.Text = ""
		Rainbow.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Rainbow.Parent = Palette

		local Tick = Instance.new("Frame")
		Tick.Name = "Tick"
		Tick.Size = UDim2.new(0, 10, 0, 10)
		Tick.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Tick.Position = UDim2.new(0, 0, 0, 2)
		Tick.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		Tick.Parent = Rainbow

		Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		Gradient.Parent = Tick

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.Size = UDim2.new(1, -14, 1, 0)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0, 14, 0, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.TextColor3 = Color3.fromRGB(252, 252, 252)
		Title.Text = "Rainbow"
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = Rainbow

		return Palette
	end,
	PushNotification = function()
		local Push = Instance.new("Frame")
		Push.Name = "Push"
		Push.Size = UDim2.new(0, 200, 0, 48)
		Push.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Push.BorderSizePixel = 2
		Push.BackgroundColor3 = Color3.fromRGB(31, 31, 31)

		local Stroke = Instance.new("UIStroke")
		Stroke.Name = "Stroke"
		Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Stroke.LineJoinMode = Enum.LineJoinMode.Miter
		Stroke.Color = Color3.fromRGB(60, 60, 60)
		Stroke.Parent = Push

		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Name = "ListLayout"
		ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout.Padding = UDim.new(0, 5)
		ListLayout.Parent = Push

		local Padding = Instance.new("UIPadding")
		Padding.Name = "Padding"
		Padding.PaddingTop = UDim.new(0, 4)
		Padding.PaddingBottom = UDim.new(0, 4)
		Padding.PaddingLeft = UDim.new(0, 4)
		Padding.PaddingRight = UDim.new(0, 4)
		Padding.Parent = Push

		local TitleHolder = Instance.new("Frame")
		TitleHolder.Name = "TitleHolder"
		TitleHolder.Size = UDim2.new(1, 0, 0, 14)
		TitleHolder.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TitleHolder.BackgroundTransparency = 1
		TitleHolder.BorderSizePixel = 0
		TitleHolder.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		TitleHolder.Parent = Push

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.Size = UDim2.new(1, -14, 1, 0)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Title.TextStrokeTransparency = 0.75
		Title.TextTruncate = Enum.TextTruncate.SplitWord
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(252, 252, 252)
		-- Title.TextYAlignment = Enum.TextYAlignment.Top
		Title.Text = "Title"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSansSemibold)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = TitleHolder

		local Close = Instance.new("TextButton")
		Close.Name = "Close"
		Close.AnchorPoint = Vector2.new(1, 0)
		Close.Size = UDim2.new(0, 14, 0, 14)
		Close.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Close.BackgroundTransparency = 1
		Close.Position = UDim2.new(1, 0, 0, 0)
		Close.BorderSizePixel = 0
		Close.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Close.AutoButtonColor = false
		Close.TextStrokeTransparency = 0.75
		Close.TextSize = 14
		Close.TextColor3 = Color3.fromRGB(255, 255, 255)
		Close.Text = "X"
		Close.FontFace = Font.fromEnum(Enum.Font.Nunito)
		Close.Parent = TitleHolder

		local Divider = Instance.new("Frame")
		Divider.Name = "Divider"
		Divider.LayoutOrder = 1
		Divider.Size = UDim2.new(1, -2, 0, 2)
		Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Divider.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		Divider.Parent = Push

		local Description = Instance.new("TextLabel")
		Description.Name = "Description"
		Description.LayoutOrder = 2
		Description.Size = UDim2.new(1, 0, 0, 14)
		Description.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Description.BackgroundTransparency = 1
		Description.BorderSizePixel = 0
		Description.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Description.TextStrokeTransparency = 0.75
		Description.TextSize = 14
		Description.RichText = true
		Description.TextColor3 = Color3.fromRGB(255, 255, 255)
		-- Description.TextYAlignment = Enum.TextYAlignment.Top
		Description.Text = "Description"
		Description.TextWrapped = true
		Description.TextWrap = true
		Description.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Description.TextXAlignment = Enum.TextXAlignment.Left
		Description.Parent = Push

		return Push
	end,
	ToastNotification = function()
		local Toast = Instance.new("Frame")
		Toast.Name = "Toast"
		Toast.Size = UDim2.new(0, 259, 0, 24)
		Toast.ClipsDescendants = true
		Toast.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Toast.BackgroundTransparency = 1
		Toast.BorderSizePixel = 0
		Toast.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

		local Main = Instance.new("Frame")
		Main.Name = "Main"
		Main.AnchorPoint = Vector2.new(0, 0.5)
		Main.Size = UDim2.new(0, 255, 1, -4)
		Main.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Main.Position = UDim2.new(0, 2, 0.5, 0)
		Main.BorderSizePixel = 2
		Main.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Main.Parent = Toast

		local Stroke = Instance.new("UIStroke")
		Stroke.Name = "Stroke"
		Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Stroke.LineJoinMode = Enum.LineJoinMode.Miter
		Stroke.Color = Color3.fromRGB(60, 60, 60)
		Stroke.Parent = Main

		local GLine = Instance.new("Frame")
		GLine.Name = "GLine"
		GLine.AnchorPoint = Vector2.new(1, 0.5)
		GLine.Size = UDim2.new(0, 2, 1, 4)
		GLine.BorderColor3 = Color3.fromRGB(0, 0, 0)
		GLine.Position = UDim2.new(0, 0, 0.5, 0)
		GLine.BorderSizePixel = 0
		GLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		GLine.Parent = Main

		local Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.25, 0),
			NumberSequenceKeypoint.new(0.75, 0),
			NumberSequenceKeypoint.new(1, 1)
		})
		Gradient.Rotation = 90
		Gradient.Parent = GLine

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.AnchorPoint = Vector2.new(0.5, 0.5)
		Title.Size = UDim2.new(1, -10, 1, 0)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0.5, 0, 0.5, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Hit OnlyTwentyCharacters in the Head with AK47"
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = Main

		return Toast
	end
}
Bracket.Elements = {
	Screen = function()
		local ScreenAsset = Bracket.Assets:Screen()

		if not Bracket.IsLocal then sethiddenproperty(ScreenAsset, "OnTopOfCoreBlur", true) end
		ScreenAsset.Name = "Bracket " .. game:GetService("HttpService"):GenerateGUID(false)
		ScreenAsset.Parent = Bracket.IsLocal and LocalPlayer:FindFirstChildOfClass("PlayerGui") or CoreGui

		return ScreenAsset
	end,
	Tooltip = function(Parent, Tooltip)
		Tooltip = Bracket.Utilities:GetType(Tooltip, "table", {}, true)
		Tooltip.Text = Bracket.Utilities:GetType(Tooltip.Text, "string", "Tooltip")
		Tooltip.OffsetX = Bracket.Utilities:GetType(Tooltip.OffsetX, "number", 5)
		Tooltip.OffsetY = Bracket.Utilities:GetType(Tooltip.OffsetY, "number", 5)

		local TooltipAsset = Bracket.Assets.Tooltip()
		TooltipAsset.Parent = Bracket.Screen

		Tooltip.Type = "Tooltip"
		Tooltip.Asset = TooltipAsset

		TooltipAsset.Text = Tooltip.Text
		TooltipAsset.Size = UDim2.fromOffset(
			TooltipAsset.TextBounds.X + 6,
			TooltipAsset.TextBounds.Y + 6
		)

		Parent.MouseEnter:Connect(function()
			local Mouse = UserInputService:GetMouseLocation()
			TooltipAsset.Position = UDim2.fromOffset(Mouse.X + Tooltip.OffsetX, Mouse.Y - Tooltip.OffsetY)

			TooltipAsset.Visible = true
		end)
		Parent.MouseLeave:Connect(function()
			TooltipAsset.Visible = false
		end)

		UserInputService.InputChanged:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseMovement and TooltipAsset.Visible then
				local Mouse = Vector2.new(Input.Position.X, Input.Position.Y) + GuiInset -- UserInputService:GetMouseLocation()
				TooltipAsset.Position = UDim2.fromOffset(Mouse.X + Tooltip.OffsetX, Mouse.Y - Tooltip.OffsetY)
			end
		end)

		Tooltip:GetPropertyChangedSignal("Text"):Connect(function(Value)
			TooltipAsset.Text = Value
			TooltipAsset.Size = UDim2.fromOffset(
				TooltipAsset.TextBounds.X + 6,
				TooltipAsset.TextBounds.Y + 6
			)
		end)

		return Tooltip
	end,
	Snowflakes = function(WindowAsset)
		local ParticleEmitter = loadstring(game:HttpGet("https://raw.githubusercontent.com/AlexR32/rParticle/master/Main.lua"))()
		local Emitter = ParticleEmitter.new(WindowAsset.Background, WindowAsset.Snowflake)
		local NewRandom = Random.new() Emitter.SpawnRate = 20

		Emitter.OnSpawn = function(Particle)
			local RandomPosition = NewRandom:NextNumber()
			local RandomSize = NewRandom:NextInteger(10, 50)
			local RandomYVelocity = NewRandom:NextInteger(10, 50)
			local RandomXVelocity = NewRandom:NextInteger(-50, 50)

			Particle.Object.ImageTransparency = RandomSize / 50
			Particle.Object.Size = UDim2.fromOffset(RandomSize, RandomSize)
			Particle.Velocity = Vector2.new(RandomXVelocity, RandomYVelocity)
			Particle.Position = Vector2.new(RandomPosition * WindowAsset.Background.AbsoluteSize.X, 0)
			Particle.MaxAge = 20 task.wait(0.5) Particle.Object.Visible = true
		end

		Emitter.OnUpdate = function(Particle, Delta)
			Particle.Position += Particle.Velocity * Delta
		end
	end,
	Window = function(Window)
		local WindowAsset = Bracket.Assets.Window()

		Window.Flags = {}
		Window.Elements = {}
		Window.Colorable = {}
		Window.RainbowHue = 0

		Window.Type = "Window"
		Window.Asset = WindowAsset
		Window.Background = Window.Asset.Background

		local Flags = {}
		local FlagsExclude = {}

		local function IncrementKey(BaseKey)
			local Suffix = 1
			local NewKey = `{BaseKey}-{Suffix}`

			while Flags[NewKey] ~= nil do
				Suffix += 1
				NewKey = `{BaseKey}-{Suffix}`
			end

			return NewKey
		end

		setmetatable(Window.Flags, {
			__index = function(Self, Key)
				return Flags[Key]
			end,
			__newindex = function(Self, Key, Value)
				local Element = Window.Elements[#Window.Elements]
				if Flags[Key] ~= nil and not table.find(FlagsExclude, Element) then
					local Element = Window.Elements[#Window.Elements]
					local IncrementedKey = IncrementKey(Key)

					if Element.Flag then Element.Flag = IncrementedKey end
					table.insert(FlagsExclude, Element)

					warn(`Flag {Key} already exists. Renaming to {IncrementedKey}`)
					Flags[IncrementedKey] = Value
					return
				else
					table.insert(FlagsExclude, Element)
					Flags[Key] = Value
					return
				end
			end
		})

		WindowAsset.Parent = Bracket.Screen
		WindowAsset.Visible = Window.Enabled
		WindowAsset.Topbar.Title.Text = Window.Name
		WindowAsset.Position = Window.Position
		WindowAsset.Size = Window.Size

		if not Bracket.IsLocal and (Window.Enabled and Window.Blur) then
			RunService:SetRobloxGuiFocused(true)
		end

		Bracket.Utilities.MakeDraggable(WindowAsset.Topbar, WindowAsset, function(Position)
			Window.Position = Position
		end)
		Bracket.Utilities.MakeResizeable(WindowAsset.Resize, WindowAsset, Vector2.new(296, 296), Vector2.new(896, 896), function(Size)
			Window.Size = Size
		end)

		-- local Month = tonumber(os.date("%m"))
		-- if Month == 12 or Month == 1 then task.spawn(Bracket.Elements.Snowflakes, WindowAsset) end
		if not Window.LegacyTabButtons then
			WindowAsset.TabButtonContainer.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				WindowAsset.TabButtonContainer.CanvasSize = UDim2.fromOffset(WindowAsset.TabButtonContainer.ListLayout.AbsoluteContentSize.X, 0)
			end)
		end

		RunService.RenderStepped:Connect(function()
			Window.RainbowHue = os.clock() % Window.RainbowSpeed / Window.RainbowSpeed
		end)

		Window:GetPropertyChangedSignal("Enabled"):Connect(function(Enabled)
			WindowAsset.Visible = Enabled

			if not Bracket.IsLocal then
				RunService:SetRobloxGuiFocused(Enabled and Window.Blur)
			end
			if not Enabled then
				for Index, Object in pairs(Bracket.Screen:GetChildren()) do
					if Object.Name == "Palette" or Object.Name == "OptionContainer" then
						Object.Visible = false
					end
				end
			end
		end)
		Window:GetPropertyChangedSignal("Blur"):Connect(function(Blur)
			if not Bracket.IsLocal then
				RunService:SetRobloxGuiFocused(Window.Enabled and Blur)
			end
		end)
		Window:GetPropertyChangedSignal("Name"):Connect(function(Name)
			WindowAsset.Topbar.Title.Text = Name
		end)
		Window:GetPropertyChangedSignal("Position"):Connect(function(Position)
			WindowAsset.Position = Position
		end)
		Window:GetPropertyChangedSignal("Size"):Connect(function(Size)
			WindowAsset.Size = Size
		end)
		Window:GetPropertyChangedSignal("Color"):Connect(function(Color)
			for Object, ColorConfig in pairs(Window.Colorable) do
				if ColorConfig[1] then
					if ColorConfig[2] == "TextFormat" then
						local FormatColor = `rgb({Bracket.Utilities.ColorToString(Color)})`
						Object.Text = Object.Text:gsub("rgb%(%d+, %d+, %d+%)", FormatColor)
						continue
					end

					Object[ColorConfig[2]] = Color
				end
			end
		end)

		function Window.SetValue(Self, Flag, Value)
			for Index, Element in pairs(Self.Elements) do
				if Element.Flag and Element.Flag == Flag then
					Element.Value = Value
				end
			end
		end
		function Window.GetValue(Self, Flag)
			for Index, Element in pairs(Self.Elements) do
				if Element.Flag and Element.Flag == Flag then
					return Element.Value
				end
			end
		end

		function Window.Watermark(Self, Watermark)
			Watermark = Bracket.Utilities:GetType(Watermark, "table", {}, true)
			Watermark.Enabled = Bracket.Utilities:GetType(Watermark.Enabled, "boolean", false)
			Watermark.Title = Bracket.Utilities:GetType(Watermark.Title, "string", "Hello World!")
			Watermark.Flag = Bracket.Utilities:GetType(Watermark.Flag, "string", "UI/Watermark/Position")

			Watermark.Type = "Watermark"
			Watermark.Asset = Bracket.Screen.Watermark

			Bracket.Screen.Watermark.Visible = Watermark.Enabled
			Bracket.Screen.Watermark.Text = Watermark.Title

			Bracket.Screen.Watermark.Size = UDim2.fromOffset(
				Bracket.Screen.Watermark.TextBounds.X + 6,
				Bracket.Screen.Watermark.TextBounds.Y + 6
			)

			Bracket.Utilities.MakeDraggable(Bracket.Screen.Watermark, Bracket.Screen.Watermark, function(Position)
				if not Window.Enabled then return end
				Bracket.Screen.Watermark.Position = Position
			end, function(Position)
				if not Window.Enabled then return end
				Watermark.Value = {
					Position.X.Scale, Position.X.Offset,
					Position.Y.Scale, Position.Y.Offset
				}
			end)

			Watermark:GetPropertyChangedSignal("Enabled"):Connect(function(Enabled)
				Bracket.Screen.Watermark.Visible = Enabled
			end)
			Watermark:GetPropertyChangedSignal("Title"):Connect(function(Title)
				Bracket.Screen.Watermark.Text = Title
				Bracket.Screen.Watermark.Size = UDim2.fromOffset(
					Bracket.Screen.Watermark.TextBounds.X + 6,
					Bracket.Screen.Watermark.TextBounds.Y + 6
				)
			end)
			Watermark:GetPropertyChangedSignal("Value"):Connect(function(Value)
				if type(Value) ~= "table" then return end
				Bracket.Screen.Watermark.Position = UDim2.new(
					Value[1], Value[2],
					Value[3], Value[4]
				)
				Self.Flags[Watermark.Flag] = {
					Value[1], Value[2],
					Value[3], Value[4]
				}
			end)

			Self.Elements[#Self.Elements + 1] = Watermark
			Self.Watermark = Watermark
			return Watermark
		end
		function Window.KeybindList(Self, KeybindList)
			local KeybindListAsset = Bracket.Screen.KeybindList
			KeybindList = Bracket.Utilities:GetType(KeybindList, "table", {}, true)
			KeybindList.Enabled = Bracket.Utilities:GetType(KeybindList.Enabled, "boolean", false)
			KeybindList.Title = Bracket.Utilities:GetType(KeybindList.Title, "string", "Keybinds")
			KeybindList.Position = Bracket.Utilities:GetType(KeybindList.Position, "UDim2", UDim2.new(0, 10, 0.5, -123))
			KeybindList.Size = Bracket.Utilities:GetType(KeybindList.Size, "UDim2", UDim2.new(0, 121, 0, 246))

			KeybindList.Type = "KeybindList"
			KeybindList.Asset = KeybindListAsset
			KeybindList.List = KeybindList.Asset.BindContainer

			KeybindListAsset.Visible = KeybindList.Enabled
			KeybindListAsset.Topbar.Title.Text = KeybindList.Title
			KeybindListAsset.Position = KeybindList.Position
			KeybindListAsset.Size = KeybindList.Size

			Bracket.Utilities.MakeDraggable(KeybindListAsset.Topbar, KeybindListAsset, function(Position)
				KeybindList.Position = Position
			end)
			Bracket.Utilities.MakeResizeable(KeybindListAsset.Resize, KeybindListAsset, Vector2.new(121, 246), Vector2.new(896, 896), function(Size)
				KeybindList.Size = Size
			end)

			KeybindList:GetPropertyChangedSignal("Title"):Connect(function(Title)
				KeybindListAsset.Topbar.Title.Text = Title
			end)
			KeybindList:GetPropertyChangedSignal("Enabled"):Connect(function(Enabled)
				KeybindListAsset.Visible = Enabled
			end)
			KeybindList:GetPropertyChangedSignal("Position"):Connect(function(Position)
				KeybindListAsset.Position = Position
			end)
			KeybindList:GetPropertyChangedSignal("Size"):Connect(function(Size)
				KeybindListAsset.Size = Size
			end)

			WindowAsset.Background.Changed:Connect(function(Property)
				if Property == "Image" then
					KeybindListAsset.Background.Image = WindowAsset.Background.Image
				elseif Property == "ImageColor3" then
					KeybindListAsset.Background.ImageColor3 = WindowAsset.Background.ImageColor3
				elseif Property == "ImageTransparency" then
					KeybindListAsset.Background.ImageTransparency = WindowAsset.Background.ImageTransparency
				elseif Property == "TileSize" then
					KeybindListAsset.Background.TileSize = WindowAsset.Background.TileSize
				end
			end)

			for Index, Element in pairs(Self.Elements) do
				if Element.Type == "Keybind" and not Element.IgnoreList then
					Element.ListMimic = {}
					Element.ListMimic.Asset = Bracket.Assets.KeybindMimic()
					Element.ListMimic.Asset.Title.Text = Element.CustomName or Element.Name or Element.Toggle.Name
					Element.ListMimic.Asset.Visible = Element.Value ~= "NONE"
					Element.ListMimic.Asset.Layout.Keybind.Text = "[ " .. Element.Value .. " ]"
					Element.ListMimic.Asset.Parent = KeybindList.List

					Element.ListMimic.Asset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
						Element.ListMimic.Asset.Title.Size = UDim2.new(1, -(Element.ListMimic.Asset.Layout.ListLayout.AbsoluteContentSize.X + 18), 1, 0)
					end)

					Element.ListMimic.Asset.Layout.Keybind:GetPropertyChangedSignal("TextBounds"):Connect(function()
						Element.ListMimic.Asset.Layout.Keybind.Size = UDim2.new(0, Element.ListMimic.Asset.Layout.Keybind.TextBounds.X, 1, 0)
					end)

					Element.ListMimic.ColorConfig = {false, "BackgroundColor3"}
					Self.Colorable[Element.ListMimic.Asset.Tick] = Element.ListMimic.ColorConfig
				end
			end

			Self.Elements[#Self.Elements + 1] = KeybindList
			Self.KeybindList = KeybindList
			return KeybindList
		end

		function Window.SaveConfig(Self, FolderName, Name)
			local Config = {}
			for Index, Element in pairs(Self.Elements) do
				if Element.Flag and not Element.IgnoreFlag then
					local Value = Self.Flags[Element.Flag]

					if Element.Type == "Colorpicker" then
						Value = {Value[5] == true and 1 or Value[1], Value[2], Value[3], Value[4], Value[5]}
					end

					if Bracket.Utilities:DeepEquals(Element.Default, Value) then
						continue
					end

					Config[Element.Flag] = Value
				end
			end
			writefile(
				FolderName .. "\\Configs\\" .. Name .. ".json",
				HttpService:JSONEncode(Config)
			)
		end
		function Window.LoadConfig(Self, FolderName, Name)
			if table.find(Bracket.Utilities.GetConfigs(FolderName), Name) then
				local DecodedJSON = HttpService:JSONDecode(
					readfile(FolderName .. "\\Configs\\" .. Name .. ".json")
				)
				for Flag, Value in pairs(DecodedJSON) do
					local Element = Bracket.Utilities.FindElementByFlag(Self.Elements, Flag)
					if Element ~= nil then Element.Value = Value end
				end
			end
		end
		function Window:DeleteConfig(FolderName, Name)
			if table.find(Bracket.Utilities.GetConfigs(FolderName), Name) then
				delfile(FolderName .. "\\Configs\\" .. Name .. ".json")
			end
		end
		function Window:GetAutoLoadConfig(FolderName)
			if not isfolder(FolderName) then makefolder(FolderName) end
			if not isfile(FolderName .. "\\AutoLoads.json") then
				writefile(FolderName .. "\\AutoLoads.json", "[]")
			end

			local AutoLoads = HttpService:JSONDecode(
				readfile(FolderName .. "\\AutoLoads.json")
			) local AutoLoad = AutoLoads[tostring(game.GameId)]

			if table.find(Bracket.Utilities.GetConfigs(FolderName), AutoLoad) then
				return AutoLoad
			end
		end
		function Window:AddToAutoLoad(FolderName, Name)
			if not isfolder(FolderName) then makefolder(FolderName) end
			if not isfile(FolderName .. "\\AutoLoads.json") then
				writefile(FolderName .. "\\AutoLoads.json", "[]")
			end

			local AutoLoads = HttpService:JSONDecode(
				readfile(FolderName .. "\\AutoLoads.json")
			) AutoLoads[tostring(game.GameId)] = Name

			writefile(FolderName .. "\\AutoLoads.json",
				HttpService:JSONEncode(AutoLoads)
			)
		end
		function Window:RemoveFromAutoLoad(FolderName)
			if not isfolder(FolderName) then makefolder(FolderName) end
			if not isfile(FolderName .. "\\AutoLoads.json") then
				writefile(FolderName .. "\\AutoLoads.json", "[]")
				return
			end

			local AutoLoads = HttpService:JSONDecode(
				readfile(FolderName .. "\\AutoLoads.json")
			) AutoLoads[tostring(game.GameId)] = nil

			writefile(FolderName .. "\\AutoLoads.json",
				HttpService:JSONEncode(AutoLoads)
			)
		end
		function Window.AutoLoadConfig(Self, FolderName)
			if not isfolder(FolderName) then makefolder(FolderName) end
			if not isfile(FolderName .. "\\AutoLoads.json") then
				writefile(FolderName .. "\\AutoLoads.json", "[]")
			end

			local AutoLoads = HttpService:JSONDecode(
				readfile(FolderName .. "\\AutoLoads.json")
			) local AutoLoad = AutoLoads[tostring(game.GameId)]

			if table.find(Bracket.Utilities.GetConfigs(FolderName), AutoLoad) then
				Self:LoadConfig(FolderName, AutoLoad)
			end
		end

		return WindowAsset
	end,
	Tab = function(WindowAsset, Window, Tab)
		local TabAsset = Bracket.Assets.Tab()
		local TabButtonAsset = Window.LegacyTabButtons and Bracket.Assets.LegacyTabButton() or Bracket.Assets.TabButton()
		local ChooseTab = Window.LegacyTabButtons and Bracket.Utilities.ChooseTabLegacy or Bracket.Utilities.ChooseTab
		local TabButtonColorable = Window.LegacyTabButtons and TabButtonAsset or TabButtonAsset.Highlight
		local TabButtonTitle = Window.LegacyTabButtons and TabButtonAsset.Title or TabButtonAsset

		Tab.ColorConfig = {true, "BackgroundColor3"}
		Window.Colorable[TabButtonColorable] = Tab.ColorConfig

		Tab.Type = "Tab"
		Tab.Asset = TabAsset
		Tab.ButtonAsset = TabButtonAsset

		TabAsset.Visible = false
		TabAsset.Parent = WindowAsset.TabContainer

		TabButtonTitle.Text = Tab.Name
		
		if Window.LegacyTabButtons then
			TabButtonAsset.BackgroundColor3 = Window.Color
			TabButtonAsset.Size = UDim2.new(1 / Bracket.Utilities.GetNumberOfTabs() + 1, 0, 1, 0)
			WindowAsset.TabButtonContainer.ChildAdded:Connect(function()
				TabButtonAsset.Size = UDim2.new(1 / Bracket.Utilities.GetNumberOfTabs(), 0, 1, 0)
			end)
		else
			TabButtonAsset.Highlight.BackgroundColor3 = Window.Color
			TabButtonAsset.Size = UDim2.new(0, TabButtonTitle.TextBounds.X + 12, 1, 0)
			TabButtonAsset:GetPropertyChangedSignal("TextBounds"):Connect(function()
				TabButtonAsset.Size = UDim2.new(0, TabButtonTitle.TextBounds.X + 12, 1, 0)
			end)
		end
		TabButtonAsset.Parent = WindowAsset.TabButtonContainer

		TabAsset.LeftSide.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			local Side = Bracket.Utilities.GetLongestSide(TabAsset)
			TabAsset.CanvasSize = UDim2.fromOffset(0, Side.ListLayout.AbsoluteContentSize.Y + 16)
		end)
		TabAsset.RightSide.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			local Side = Bracket.Utilities.GetLongestSide(TabAsset)
			TabAsset.CanvasSize = UDim2.fromOffset(0, Side.ListLayout.AbsoluteContentSize.Y + 16)
		end)
		TabButtonAsset.MouseButton1Click:Connect(function()
			ChooseTab(TabButtonAsset, TabAsset)
		end)

		if #WindowAsset.TabContainer:GetChildren() == 1 then
			ChooseTab(TabButtonAsset, TabAsset)
		end

		Tab:GetPropertyChangedSignal("Name"):Connect(function(Name)
			TabButtonTitle.Text = Name
		end)

		return TabAsset
	end,
	Section = function(Parent, Section)
		local SectionAsset = Bracket.Assets.Section()

		Section.Type = "Section"
		Section.Asset = SectionAsset
		Section.Container = Section.Asset.Container

		SectionAsset.Parent = Parent
		SectionAsset.Title.Text = Section.Name
		SectionAsset.Title.Size = UDim2.fromOffset(
			SectionAsset.Title.TextBounds.X + 6, 14
		)

		SectionAsset.Container.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			SectionAsset.Size = UDim2.new(1, 0, 0, SectionAsset.Container.ListLayout.AbsoluteContentSize.Y + 15)
		end)

		Section:GetPropertyChangedSignal("Name"):Connect(function(Name)
			SectionAsset.Title.Text = Name
			SectionAsset.Title.Size = UDim2.fromOffset(
				Section.Title.TextBounds.X + 6, 14
			)
		end)

		return SectionAsset.Container
	end,
	Divider = function(Parent, Divider)
		local DividerAsset = Bracket.Assets.Divider()

		Divider.Type = "Divider"
		Divider.Asset = DividerAsset

		DividerAsset.Parent = Parent
		DividerAsset.Title.Text = Divider.Text

		DividerAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
			if DividerAsset.Title.TextBounds.X > 0 then
				DividerAsset.Size = UDim2.new(1, 0, 0, DividerAsset.Title.TextBounds.Y)
				DividerAsset.Left.Size = UDim2.new(0.5, -(DividerAsset.Title.TextBounds.X / 2) - 6, 0 , 2)
				DividerAsset.Right.Size = UDim2.new(0.5, -(DividerAsset.Title.TextBounds.X / 2) - 6, 0, 2)
			else
				DividerAsset.Size = UDim2.new(1, 0, 0, 14)
				DividerAsset.Left.Size = UDim2.new(1, 0, 0, 2)
				DividerAsset.Right.Size = UDim2.new(1, 0, 0, 2)
			end
		end)

		Divider:GetPropertyChangedSignal("Text"):Connect(function(Text)
			DividerAsset.Title.Text = Text
		end)
	end,
	Label = function(Parent, Label)
		local LabelAsset = Bracket.Assets.Label()

		Label.Type = "Label"
		Label.Asset = LabelAsset

		LabelAsset.Parent = Parent
		LabelAsset.Text = Label.Text

		LabelAsset:GetPropertyChangedSignal("TextBounds"):Connect(function()
			LabelAsset.Size = UDim2.new(1, 0, 0, LabelAsset.TextBounds.Y)
		end)

		Label:GetPropertyChangedSignal("Text"):Connect(function(Text)
			LabelAsset.Text = Text
		end)
	end,
	Button = function(Parent, Window, Button)
		local ButtonAsset = Bracket.Assets.Button()

		Button.Type = "Button"
		Button.Asset = ButtonAsset

		Button.ColorConfig = {false, "BorderColor3"}
		Window.Colorable[ButtonAsset] = Button.ColorConfig

		Button.Connection = ButtonAsset.MouseButton1Click:Connect(Button.Callback)

		ButtonAsset.Parent = Parent
		ButtonAsset.Title.Text = Button.Name

		ButtonAsset.MouseButton1Down:Connect(function()
			Button.ColorConfig[1] = true
			ButtonAsset.BorderColor3 = Window.Color
		end)
		ButtonAsset.MouseButton1Up:Connect(function()
			Button.ColorConfig[1] = false
			ButtonAsset.BorderColor3 = Color3.new(0, 0, 0)
		end)
		ButtonAsset.MouseLeave:Connect(function()
			Button.ColorConfig[1] = false
			ButtonAsset.BorderColor3 = Color3.new(0, 0, 0)
		end)
		ButtonAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
			ButtonAsset.Size = UDim2.new(1, 0, 0, ButtonAsset.Title.TextBounds.Y + 4)
		end)

		Button:GetPropertyChangedSignal("Name"):Connect(function(Name)
			ButtonAsset.Title.Text = Name
		end)
		Button:GetPropertyChangedSignal("Callback"):Connect(function(Callback)
			Button.Connection:Disconnect()
			Button.Connection = ButtonAsset.MouseButton1Click:Connect(Callback)
		end)

		function Button:Tooltip(Text)
			Button.Tooltip = Bracket.Elements.Tooltip(ButtonAsset, {Text = Text})
		end
	end,
	Button2 = function(Parent, Window, Button)
		local ButtonAsset = Bracket.Assets.Button2()

		Button.Type = "Button"
		Button.Asset = ButtonAsset

		Button.ColorConfig = {false, "BorderColor3"}
		Window.Colorable[ButtonAsset.Button] = Button.ColorConfig

		Button.Connection = ButtonAsset.Button.MouseButton1Click:Connect(Button.Callback)

		ButtonAsset.Parent = Parent
		ButtonAsset.Title.Text = Button.Name
		ButtonAsset.Button.Title.Text = Button.ButtonName
		ButtonAsset.Button.Size = UDim2.new(0, ButtonAsset.Button.Title.TextBounds.X + 8, 0, 18)
		ButtonAsset.Title.Size = UDim2.new(1, -(ButtonAsset.Button.Size.X.Offset + 4), 1, 0)

		ButtonAsset.Button.MouseButton1Down:Connect(function()
			Button.ColorConfig[1] = true
			ButtonAsset.Button.BorderColor3 = Window.Color
		end)
		ButtonAsset.Button.MouseButton1Up:Connect(function()
			Button.ColorConfig[1] = false
			ButtonAsset.Button.BorderColor3 = Color3.new(0, 0, 0)
		end)
		ButtonAsset.Button.MouseLeave:Connect(function()
			Button.ColorConfig[1] = false
			ButtonAsset.Button.BorderColor3 = Color3.new(0, 0, 0)
		end)
		ButtonAsset.Button.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
			ButtonAsset.Button.Size = UDim2.new(0, ButtonAsset.Button.Title.TextBounds.X + 8, 0, 18)
			ButtonAsset.Title.Size = UDim2.new(1, -(ButtonAsset.Button.Size.X.Offset + 4), 1, 0)
		end)

		Button:GetPropertyChangedSignal("Name"):Connect(function(Name)
			ButtonAsset.Title.Text = Name
		end)
		Button:GetPropertyChangedSignal("ButtonName"):Connect(function(Name)
			ButtonAsset.Button.Title.Text = Name
		end)
		Button:GetPropertyChangedSignal("Callback"):Connect(function(Callback)
			Button.Connection:Disconnect()
			Button.Connection = ButtonAsset.MouseButton1Click:Connect(Callback)
		end)

		function Button:Tooltip(Text)
			Button.Tooltip = Bracket.Elements.Tooltip(ButtonAsset, {Text = Text})
		end
	end,
	Toggle = function(Parent, Window, Toggle)
		local ToggleAsset = Bracket.Assets.Toggle()

		Toggle.Type = "Toggle"
		Toggle.Asset = ToggleAsset

		Toggle.ColorConfig = {Toggle.Value, "BackgroundColor3"}
		Window.Colorable[ToggleAsset.Tick] = Toggle.ColorConfig

		Toggle.Default = Bracket.Utilities:DeepCopy(Toggle.Value)

		ToggleAsset.Parent = Parent
		ToggleAsset.Title.Text = Toggle.Name
		ToggleAsset.Tick.BackgroundColor3 = Toggle.Value
			and Window.Color or Color3.fromRGB(63, 63, 63)

		ToggleAsset.MouseButton1Click:Connect(function()
			Toggle.Value = not Toggle.Value
		end)
		ToggleAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
			ToggleAsset.Size = UDim2.new(1, 0, 0, ToggleAsset.Title.TextBounds.Y)
			ToggleAsset.Title.Size = UDim2.new(1, -(ToggleAsset.Layout.ListLayout.AbsoluteContentSize.X + 18), 1, 0)
		end)
		ToggleAsset.Layout.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			ToggleAsset.Title.Size = UDim2.new(1, -(ToggleAsset.Layout.ListLayout.AbsoluteContentSize.X + 18), 1, 0)
		end)

		Toggle:GetPropertyChangedSignal("Name"):Connect(function(Name)
			ToggleAsset.Title.Text = Name
		end)
		Toggle:GetPropertyChangedSignal("Value"):Connect(function(Value)
			Toggle.ColorConfig[1] = Value
			ToggleAsset.Tick.BackgroundColor3 = Value
				and Window.Color or Color3.fromRGB(63, 63, 63)
			Window.Flags[Toggle.Flag] = Value
			Toggle.Callback(Value)
		end)

		function Toggle:Keybind(Keybind)
			Keybind = Bracket.Utilities:GetType(Keybind, "table", {}, true)
			Keybind.Flag = Bracket.Utilities:GetType(Keybind.Flag, "string", Toggle.Flag .. "/Keybind")

			Keybind.Value = Bracket.Utilities:GetType(Keybind.Value, "string", "NONE")
			Keybind.Mouse = Bracket.Utilities:GetType(Keybind.Mouse, "boolean", false)
			Keybind.HoldMode = Bracket.Utilities:GetType(Keybind.HoldMode, "boolean", false)
			Keybind.Callback = Bracket.Utilities:GetType(Keybind.Callback, "function", function() end)
			Keybind.Blacklist = Bracket.Utilities:GetType(Keybind.Blacklist, "table", {"W", "A", "S", "D", "Slash", "Tab", "Backspace", "Escape", "Space", "Delete", "Unknown", "Backquote"})

			Window.Elements[#Window.Elements + 1] = Keybind
			Window.Flags[Keybind.Flag] = Keybind.Value

			Bracket.Elements.ToggleKeybind(ToggleAsset.Layout, Window, Keybind, Toggle)
			return Keybind
		end
		function Toggle:Colorpicker(Colorpicker)
			Colorpicker = Bracket.Utilities:GetType(Colorpicker, "table", {}, true)
			Colorpicker.Flag = Bracket.Utilities:GetType(Colorpicker.Flag, "string", Toggle.Flag .. "/Colorpicker")

			Colorpicker.Value = Bracket.Utilities:GetType(Colorpicker.Value, "table", {1, 1, 1, 0, false})
			Colorpicker.Callback = Bracket.Utilities:GetType(Colorpicker.Callback, "function", function() end)

			Window.Elements[#Window.Elements + 1] = Colorpicker
			Window.Flags[Colorpicker.Flag] = Colorpicker.Value

			Bracket.Elements.ToggleColorpicker(ToggleAsset.Layout, Window, Colorpicker)
			return Colorpicker
		end

		function Toggle:Tooltip(Text)
			Toggle.Tooltip = Bracket.Elements.Tooltip(ToggleAsset, {Text = Text})
		end

		return ToggleAsset
	end,
	Slider = function(Parent, Window, Slider)
		local SliderAsset = Slider.Slim and Bracket.Assets.SlimSlider() or Bracket.Assets.Slider()

		Slider.Type = "Slider"
		Slider.Asset = SliderAsset

		Slider.ColorConfig = {true, "BackgroundColor3"}
		Window.Colorable[SliderAsset.Background.Bar] = Slider.ColorConfig

		Slider.Value = tonumber(string.format("%." .. Slider.Precise .. "f", Slider.Value))
		Slider.Default = Bracket.Utilities:DeepCopy(Slider.Value)
		Slider.Active = false

		SliderAsset.Parent = Parent
		SliderAsset.Title.Text = Slider.Name
		SliderAsset.Background.Bar.BackgroundColor3 = Window.Color
		SliderAsset.Background.Bar.Size = UDim2.fromScale(Bracket.Utilities.Scale(Slider.Value, Slider.Min, Slider.Max, 0, 1), 1)
		SliderAsset.Value.PlaceholderText = #Slider.Unit == 0 and Slider.Value or Slider.Value .. " " .. Slider.Unit

		local function AttachToMouse(Input)
			local ScaleX = math.clamp((Input.Position.X - SliderAsset.Background.AbsolutePosition.X) / SliderAsset.Background.AbsoluteSize.X, 0, 1)
			Slider.Value = Bracket.Utilities.Scale(ScaleX, 0, 1, Slider.Min, Slider.Max)
		end

		if Slider.Slim then
			SliderAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
				SliderAsset.Value.Size = UDim2.fromOffset(SliderAsset.Value.TextBounds.X, 14)
				SliderAsset.Title.Size = UDim2.new(1, -(SliderAsset.Value.Size.X.Offset + 4), 0, 14)
				SliderAsset.Background.Position = UDim2.new(0.5, 0, 0, SliderAsset.Title.TextBounds.Y + 4)
				SliderAsset.Size = UDim2.new(1, 0, 0, SliderAsset.Title.TextBounds.Y + 14)
			end)
			SliderAsset.Value:GetPropertyChangedSignal("TextBounds"):Connect(function()
				SliderAsset.Value.Size = UDim2.fromOffset(SliderAsset.Value.TextBounds.X, 14)
				SliderAsset.Title.Size = UDim2.new(1, -(SliderAsset.Value.Size.X.Offset + 4), 0, 14)
				SliderAsset.Background.Position = UDim2.new(0.5, 0, 0, SliderAsset.Title.TextBounds.Y + 4)
				SliderAsset.Size = UDim2.new(1, 0, 0, SliderAsset.Title.TextBounds.Y + 14)
			end)
		else
			SliderAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
				SliderAsset.Value.Size = UDim2.new(0, SliderAsset.Value.TextBounds.X, 1, 0)
				SliderAsset.Title.Size = UDim2.new(1, -(SliderAsset.Value.Size.X.Offset + 12), 1, 0)
				SliderAsset.Size = UDim2.new(1, 0, 0, SliderAsset.Title.TextBounds.Y + 4)
			end)
			SliderAsset.Value:GetPropertyChangedSignal("TextBounds"):Connect(function()
				SliderAsset.Value.Size = UDim2.new(0, SliderAsset.Value.TextBounds.X, 1, 0)
				SliderAsset.Title.Size = UDim2.new(1, -(SliderAsset.Value.Size.X.Offset + 12), 1, 0)
				SliderAsset.Size = UDim2.new(1, 0, 0, SliderAsset.Title.TextBounds.Y + 4)
			end)
		end

		SliderAsset.Value.FocusLost:Connect(function()
			if not tonumber(SliderAsset.Value.Text) then
				SliderAsset.Value.Text = ""
				return
			end

			Slider.Value = SliderAsset.Value.Text
			SliderAsset.Value.Text = ""
		end)
		SliderAsset.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				AttachToMouse(Input)
				Slider.Active = true
			end
		end)
		SliderAsset.InputEnded:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				Slider.Active = false
			end
		end)
		UserInputService.InputChanged:Connect(function(Input)
			if Slider.Active and Input.UserInputType == Enum.UserInputType.MouseMovement then
				AttachToMouse(Input)
			end
		end)

		Slider:GetPropertyChangedSignal("Name"):Connect(function(Name)
			SliderAsset.Title.Text = Name
		end)
		Slider:GetPropertyChangedSignal("Value"):Connect(function(Value)
			Value = tonumber(string.format("%." .. Slider.Precise .. "f", Value))

			if Value < Slider.Min then
				Value = Slider.Min
			elseif Value > Slider.Max then
				Value = Slider.Max
			end

			if Slider.OnlyOdd and Slider.Precise == 0 then
				if Value % 2 == 0 then return end
			elseif Slider.OnlyEven and Slider.Precise == 0 then
				if Value % 2 == 1 then return end
			end

			SliderAsset.Background.Bar.Size = UDim2.fromScale(Bracket.Utilities.Scale(Value, Slider.Min, Slider.Max, 0, 1), 1)
			SliderAsset.Value.PlaceholderText = #Slider.Unit == 0 and Value or Value .. " " .. Slider.Unit

			Slider.Internal.Value = Value
			Window.Flags[Slider.Flag] = Value
			Slider.Callback(Value)
		end)

		function Slider:Tooltip(Text)
			Slider.Tooltip = Bracket.Elements.Tooltip(SliderAsset, {Text = Text})
		end
	end,
	Textbox = function(Parent, Window, Textbox)
		local TextboxAsset = Bracket.Assets.Textbox()

		Textbox.Type = "Textbox"
		Textbox.Asset = TextboxAsset

		Textbox.Default = Bracket.Utilities:DeepCopy(Textbox.Value)
		Textbox.EnterPressed = false

		TextboxAsset.Parent = Parent
		TextboxAsset.Title.Text = Textbox.Name
		TextboxAsset.Background.Input.Text = Textbox.Value
		TextboxAsset.Background.Input.PlaceholderText = Textbox.Placeholder
		TextboxAsset.Title.Visible = not Textbox.HideName

		TextboxAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
			TextboxAsset.Title.Size = Textbox.HideName and UDim2.fromScale(1, 0)
				or UDim2.new(1, 0, 0, TextboxAsset.Title.TextBounds.Y)

			TextboxAsset.Background.Position = UDim2.new(0.5, 0, 0, TextboxAsset.Title.Size.Y.Offset + (Textbox.HideName and 0 or 4))
			TextboxAsset.Size = UDim2.new(1, 0, 0, TextboxAsset.Title.Size.Y.Offset + TextboxAsset.Background.Size.Y.Offset)
		end)
		TextboxAsset.Background.Input:GetPropertyChangedSignal("Text"):Connect(function()
			local TextBounds = Bracket.Utilities.GetTextBounds(
				TextboxAsset.Background.Input.Text,
				TextboxAsset.Background.Input.Font.Name,
				Vector2.new(TextboxAsset.Background.Input.AbsoluteSize.X, TextboxAsset.Background.Input.TextSize)
			)

			TextboxAsset.Background.Size = UDim2.new(1, 0, 0, TextBounds.Y + 4)
			TextboxAsset.Size = UDim2.new(1, 0, 0, TextboxAsset.Title.Size.Y.Offset + TextboxAsset.Background.Size.Y.Offset)
		end)

		TextboxAsset.Background.Input.Focused:Connect(function()
			local TextBounds = Bracket.Utilities.GetTextBounds(
				TextboxAsset.Background.Input.Text,
				TextboxAsset.Background.Input.Font.Name,
				Vector2.new(TextboxAsset.Background.Input.AbsoluteSize.X, TextboxAsset.Background.Input.TextSize)
			)

			TextboxAsset.Background.Size = UDim2.new(1, 0, 0, TextBounds.Y + 4)
			TextboxAsset.Size = UDim2.new(1, 0, 0, TextboxAsset.Title.Size.Y.Offset + TextboxAsset.Background.Size.Y.Offset)

			TextboxAsset.Background.Input.Text = Textbox.Value
		end)
		TextboxAsset.Background.Input.FocusLost:Connect(function(EnterPressed)
			local Input = TextboxAsset.Background.Input

			Textbox.EnterPressed = EnterPressed
			Textbox.Value = Input.Text Textbox.EnterPressed = false
		end)

		Textbox:GetPropertyChangedSignal("Name"):Connect(function(Name)
			TextboxAsset.Title.Text = Name
		end)
		Textbox:GetPropertyChangedSignal("Placeholder"):Connect(function(PlaceHolder)
			TextboxAsset.Background.Input.PlaceholderText = PlaceHolder
		end)
		Textbox:GetPropertyChangedSignal("Value"):Connect(function(Value)
			local Input = TextboxAsset.Background.Input
			Input.Text = Textbox.AutoClear and "" or Value
			if Textbox.PasswordMode then Input.Text = string.rep(utf8.char(8226), #Input.Text) end

			TextboxAsset.Background.Size = UDim2.new(1, 0, 0, Input.TextSize + 4)
			TextboxAsset.Size = UDim2.new(1, 0, 0, TextboxAsset.Title.Size.Y.Offset + TextboxAsset.Background.Size.Y.Offset)

			Window.Flags[Textbox.Flag] = Value
			Textbox.Callback(Value, Textbox.EnterPressed)
		end)

		function Textbox:Tooltip(Text)
			Textbox.Tooltip = Bracket.Elements.Tooltip(TextboxAsset, {Text = Text})
		end
	end,
	Keybind = function(Parent, Window, Keybind)
		local KeybindAsset = Bracket.Assets.Keybind()

		Keybind.Type = "Keybind"
		Keybind.Asset = KeybindAsset

		Keybind.Default = Bracket.Utilities:DeepCopy(Keybind.Value)
		Keybind.WaitingForBind = false
		Keybind.Binding = false

		KeybindAsset.Parent = Parent
		KeybindAsset.Title.Text = Keybind.Name
		KeybindAsset.Value.Text = "[ " .. Keybind.Value .. " ]"

		KeybindAsset.MouseButton1Click:Connect(function()
			KeybindAsset.Value.Text = "[ ... ]"
			Keybind.WaitingForBind = true
			Keybind.Binding = true
		end)
		KeybindAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
			KeybindAsset.Size = UDim2.new(1, 0, 0, KeybindAsset.Title.TextBounds.Y)
		end)
		KeybindAsset.Value:GetPropertyChangedSignal("TextBounds"):Connect(function()
			KeybindAsset.Value.Size = UDim2.new(0, KeybindAsset.Value.TextBounds.X, 1, 0)
			KeybindAsset.Title.Size = UDim2.new(1, -(KeybindAsset.Value.Size.X.Offset + 4), 1, 0)
		end)

		if type(Window.KeybindList) == "table" and not Keybind.IgnoreList then
			Keybind.ListMimic = {}
			Keybind.ListMimic.Asset = Bracket.Assets.KeybindMimic()
			Keybind.ListMimic.Asset.Title.Text = Keybind.CustomName or Keybind.Name
			Keybind.ListMimic.Asset.Visible = Keybind.Value ~= "NONE"
			Keybind.ListMimic.Asset.Layout.Keybind.Text = "[ " .. Keybind.Value .. " ]"
			Keybind.ListMimic.Asset.Parent = Window.KeybindList.List

			Keybind.ListMimic.Asset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
				Keybind.ListMimic.Asset.Title.Size = UDim2.new(1, -(Keybind.ListMimic.Asset.Layout.ListLayout.AbsoluteContentSize.X + 18), 1, 0)
			end)

			Keybind.ListMimic.Asset.Layout.Keybind:GetPropertyChangedSignal("TextBounds"):Connect(function()
				Keybind.ListMimic.Asset.Layout.Keybind.Size = UDim2.new(0, Keybind.ListMimic.Asset.Layout.Keybind.TextBounds.X, 1, 0)
			end)

			Keybind.ListMimic.ColorConfig = {false, "BackgroundColor3"}
			Window.Colorable[Keybind.ListMimic.Asset.Tick] = Keybind.ListMimic.ColorConfig
		end

		UserInputService.InputBegan:Connect(function(Input, GameProcessedEvent)
			if GameProcessedEvent then return end

			if Input.UserInputType.Name == "Keyboard" then
				local Key = Input.KeyCode.Name

				if Keybind.WaitingForBind then
					Keybind.Value = Key
					return
				end

				if Key == Keybind.Value and not Keybind.Binding then
					Keybind.Toggle = not Keybind.Toggle
					if Keybind.ListMimic then
						Keybind.ListMimic.ColorConfig[1] = true
						Keybind.ListMimic.Asset.Tick.BackgroundColor3 = Window.Color
					end

					Keybind.Callback(Keybind.Value, true, Keybind.Toggle)
				end
			end

			if Keybind.Mouse then
				local Key = Input.UserInputType.Name

				if Key == "MouseButton1" or Key == "MouseButton2" or Key == "MouseButton3" then
					if Keybind.WaitingForBind then
						Keybind.Value = Key
						return
					end

					if Key == Keybind.Value and not Keybind.Binding then
						Keybind.Toggle = not Keybind.Toggle
						if Keybind.ListMimic then
							Keybind.ListMimic.ColorConfig[1] = true
							Keybind.ListMimic.Asset.Tick.BackgroundColor3 = Window.Color
						end

						Keybind.Callback(Keybind.Value, true, Keybind.Toggle)
					end
				end
			end
		end)
		UserInputService.InputEnded:Connect(function(Input, GameProcessedEvent)
			if GameProcessedEvent then return end

			if Input.UserInputType.Name == "Keyboard" then
				local Key = Input.KeyCode.Name

				if Keybind.Binding then
					if Key == Keybind.Value then Keybind.Binding = false end
					return
				end

				if Key == Keybind.Value then
					if Keybind.ListMimic then
						Keybind.ListMimic.ColorConfig[1] = false
						Keybind.ListMimic.Asset.Tick.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
					end

					Keybind.Callback(Keybind.Value, false, Keybind.Toggle)
				end
			end

			if Keybind.Mouse then
				local Key = Input.UserInputType.Name

				if Key == "MouseButton1" or Key == "MouseButton2" or Key == "MouseButton3" then
					if Keybind.Binding then
						if Key == Keybind.Value then Keybind.Binding = false end
						return
					end

					if Key == Keybind.Value then
						if Keybind.ListMimic then
							Keybind.ListMimic.ColorConfig[1] = false
							Keybind.ListMimic.Asset.Tick.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
						end

						Keybind.Callback(Keybind.Value, false, Keybind.Toggle)
					end
				end
			end
		end)

		Keybind:GetPropertyChangedSignal("Name"):Connect(function(Name)
			KeybindAsset.Title.Text = Name
		end)
		Keybind:GetPropertyChangedSignal("CustomName"):Connect(function(Value)
			if Keybind.ListMimic then
				Keybind.ListMimic.Asset.Title.Text = Value or Keybind.Name
			end
		end)
		Keybind:GetPropertyChangedSignal("Value"):Connect(function(Value, OldValue)
			if table.find(Keybind.Blacklist, Value) then
				Value = Keybind.DoNotClear and OldValue or "NONE"
			end

			KeybindAsset.Value.Text = "[ " .. tostring(Value) .. " ]"
			if Keybind.ListMimic then
				Keybind.ListMimic.Asset.Visible = Value ~= "NONE"
				Keybind.ListMimic.Asset.Layout.Keybind.Text = "[ " .. tostring(Value) .. " ]"
			end

			Keybind.WaitingForBind = false
			Keybind.Internal.Value = Value
			Window.Flags[Keybind.Flag] = Value
			Keybind.Callback(Value, false, Keybind.Toggle)
		end)

		function Keybind:Tooltip(Text)
			Keybind.Tooltip = Bracket.Elements.Tooltip(KeybindAsset, {Text = Text})
		end
	end,
	ToggleKeybind = function(Parent, Window, Keybind, Toggle)
		local KeybindAsset = Bracket.Assets.ToggleKeybind()

		Keybind.Type = "Keybind"
		Keybind.Asset = KeybindAsset

		Keybind.Default = Bracket.Utilities:DeepCopy(Keybind.Value)
		Keybind.WaitingForBind = false
		Keybind.Binding = false
		Keybind.Toggle = Toggle

		KeybindAsset.Parent = Parent
		KeybindAsset.Text = "[ " .. Keybind.Value .. " ]"

		local Tooltip = Bracket.Elements.Tooltip(KeybindAsset, {Text = Keybind.HoldMode
			and `<font color=\"rgb({Bracket.Utilities.ColorToString(Window.Color)})\">Hold</font>\nToggle`
			or `Hold\n<font color=\"rgb({Bracket.Utilities.ColorToString(Window.Color)})\">Toggle</font>`})
		Window.Colorable[Tooltip] = {true, "TextFormat"}

		KeybindAsset.MouseButton1Click:Connect(function()
			KeybindAsset.Text = "[ ... ]"
			Keybind.WaitingForBind = true
			Keybind.Binding = true
		end)
		KeybindAsset.MouseButton2Click:Connect(function()
			Keybind.HoldMode = not Keybind.HoldMode
		end)

		KeybindAsset:GetPropertyChangedSignal("TextBounds"):Connect(function()
			KeybindAsset.Size = UDim2.new(0, KeybindAsset.TextBounds.X, 1, 0)
		end)

		if type(Window.KeybindList) == "table" and not Keybind.IgnoreList then
			Keybind.ListMimic = {}
			Keybind.ListMimic.Asset = Bracket.Assets.KeybindMimic()
			Keybind.ListMimic.Asset.Title.Text = Keybind.CustomName or Toggle.Name
			Keybind.ListMimic.Asset.Visible = Keybind.Value ~= "NONE"
			Keybind.ListMimic.Asset.Layout.Keybind.Text = "[ " .. Keybind.Value .. " ]"
			Keybind.ListMimic.Asset.Parent = Window.KeybindList.List

			Keybind.ListMimic.Asset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
				Keybind.ListMimic.Asset.Title.Size = UDim2.new(1, -(Keybind.ListMimic.Asset.Layout.ListLayout.AbsoluteContentSize.X + 18), 1, 0)
			end)

			Keybind.ListMimic.Asset.Layout.Keybind:GetPropertyChangedSignal("TextBounds"):Connect(function()
				Keybind.ListMimic.Asset.Layout.Keybind.Size = UDim2.new(0, Keybind.ListMimic.Asset.Layout.Keybind.TextBounds.X, 1, 0)
			end)

			Keybind.ListMimic.ColorConfig = {false, "BackgroundColor3"}
			Window.Colorable[Keybind.ListMimic.Asset.Tick] = Keybind.ListMimic.ColorConfig
		end

		UserInputService.InputBegan:Connect(function(Input, GameProcessedEvent)
			if GameProcessedEvent then return end

			if Keybind.Mouse then
				local Key = Input.UserInputType.Name

				if Key == "MouseButton1" or Key == "MouseButton2" or Key == "MouseButton3" then
					if Keybind.WaitingForBind then
						Keybind.Value = Key
						return
					end

					if Key == Keybind.Value and not Keybind.Binding then
						if not Keybind.DisableToggle then
							if Keybind.HoldMode and Toggle.Value == false then
								Toggle.Value = true
							else
								Toggle.Value = not Toggle.Value
							end
						end

						Keybind.Callback(Keybind.Value, true, Toggle.Value)
					end
				end
			end

			if Input.UserInputType.Name == "Keyboard" then
				local Key = Input.KeyCode.Name

				if Keybind.WaitingForBind then
					Keybind.Value = Key
					return
				end

				if Key == Keybind.Value and not Keybind.Binding then
					if not Keybind.DisableToggle then
						if Keybind.HoldMode and Toggle.Value == false then
							Toggle.Value = true
						else
							Toggle.Value = not Toggle.Value
						end
					end

					Keybind.Callback(Keybind.Value, true, Toggle.Value)
				end
			end
		end)
		UserInputService.InputEnded:Connect(function(Input, GameProcessedEvent)
			if GameProcessedEvent then return end

			if Keybind.Mouse then
				local Key = Input.UserInputType.Name

				if Key == "MouseButton1" or Key == "MouseButton2" or Key == "MouseButton3" then
					if Keybind.Binding then
						if Key == Keybind.Value then Keybind.Binding = false end
						return
					end

					if Key == Keybind.Value then
						if not Keybind.DisableToggle then
							if Keybind.HoldMode and Toggle.Value == true then
								Toggle.Value = false
							end
						end

						Keybind.Callback(Keybind.Value, false, Toggle.Value)
					end
				end
			end

			if Input.UserInputType.Name == "Keyboard" then
				local Key = Input.KeyCode.Name

				if Keybind.Binding then
					if Key == Keybind.Value then Keybind.Binding = false end
					return
				end

				if Key == Keybind.Value then
					if not Keybind.DisableToggle then
						if Keybind.HoldMode and Toggle.Value == true then
							Toggle.Value = false
						end
					end

					Keybind.Callback(Keybind.Value, false, Toggle.Value)
				end
			end
		end)

		Toggle:GetPropertyChangedSignal("Value"):Connect(function(Value)
			if Keybind.ListMimic then
				Keybind.ListMimic.ColorConfig[1] = Value
				Keybind.ListMimic.Asset.Tick.BackgroundColor3 = Value
					and Window.Color or Color3.fromRGB(63, 63, 63)
			end
		end)

		Keybind:GetPropertyChangedSignal("CustomName"):Connect(function(Value)
			if Keybind.ListMimic then
				Keybind.ListMimic.Asset.Title.Text = Value or Toggle.Name
			end
		end)
		Keybind:GetPropertyChangedSignal("HoldMode"):Connect(function(Value)
			Tooltip.Text = Value
				and `<font color=\"rgb({Bracket.Utilities.ColorToString(Window.Color)})\">Hold</font>\nToggle`
				or `Hold\n<font color=\"rgb({Bracket.Utilities.ColorToString(Window.Color)})\">Toggle</font>`
		end)
		Keybind:GetPropertyChangedSignal("Value"):Connect(function(Value, OldValue)
			if table.find(Keybind.Blacklist, Value) then
				Value = Keybind.DoNotClear and OldValue or "NONE"
			end

			KeybindAsset.Text = "[ " .. tostring(Value) .. " ]"
			if Keybind.ListMimic then
				Keybind.ListMimic.Asset.Visible = Value ~= "NONE"
				Keybind.ListMimic.Asset.Layout.Keybind.Text = "[ " .. tostring(Value) .. " ]"
			end

			Keybind.WaitingForBind = false
			Keybind.Internal.Value = Value
			Window.Flags[Keybind.Flag] = Value
			Keybind.Callback(Value, false, Toggle.Value)
		end)
	end,
	Dropdown = function(Parent, Window, Dropdown)
		local OptionContainerAsset = Bracket.Assets.OptionContainer()
		local DropdownAsset = Bracket.Assets.Dropdown()

		Dropdown.Type = "Dropdown"
		Dropdown.Asset = DropdownAsset

		Dropdown.OptionContainerAsset = OptionContainerAsset
		Dropdown.Internal.Value = {}
		local ContainerRender = nil

		DropdownAsset.Parent = Parent
		OptionContainerAsset.Parent = Bracket.Screen

		DropdownAsset.Title.Text = Dropdown.Name
		DropdownAsset.Title.Visible = not Dropdown.HideName

		local function RefreshSelected()
			table.clear(Dropdown.Internal.Value)

			for Index, Option in pairs(Dropdown.List) do
				if Option.Value then
					table.insert(Dropdown.Internal.Value, Option.Name)
				end
			end

			Window.Flags[Dropdown.Flag] = Dropdown.Internal.Value
			DropdownAsset.Background.Value.Text = #Dropdown.Internal.Value == 0
				and "..." or table.concat(Dropdown.Internal.Value, ", ")
		end

		local function SetValue(Option, Value)
			Option.Value = Value
			Option.ColorConfig[1] = Value
			Option.Object.Tick.BackgroundColor3 = Value
				and Window.Color or Color3.fromRGB(63, 63, 63)
			-- Option.Callback(Dropdown.Selected, Option)
		end

		local function AddOption(Option, AddToList, Order)
			Option = Bracket.Utilities:GetType(Option, "table", {}, true)
			Option.Name = Bracket.Utilities:GetType(Option.Name, "string", "Option")
			Option.Mode = Bracket.Utilities:GetType(Option.Mode, "string", "Button")
			Option.Value = Bracket.Utilities:GetType(Option.Value, "boolean", false)
			Option.Callback = Bracket.Utilities:GetType(Option.Callback, "function", function() end)

			local OptionAsset = Bracket.Assets.DropdownOption()
			Option.Object = OptionAsset

			OptionAsset.LayoutOrder = Order
			OptionAsset.Parent = OptionContainerAsset
			OptionAsset.Title.Text = Option.Name
			OptionAsset.Tick.BackgroundColor3 = Option.Value
				and Window.Color or Color3.fromRGB(63, 63, 63)

			Option.ColorConfig = {Option.Value, "BackgroundColor3"}
			Window.Colorable[OptionAsset.Tick] = Option.ColorConfig
			if AddToList then table.insert(Dropdown.List, Option) end

			OptionAsset.MouseButton1Click:Connect(function()
				Option.Value = not Option.Value
			end)
			OptionAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
				OptionAsset.Title.Size = UDim2.new(1, -(OptionAsset.Layout.ListLayout.AbsoluteContentSize.X + 18), 1, 0)
			end)

			Option:GetPropertyChangedSignal("Name"):Connect(function(Name)
				OptionAsset.Title.Text = Name
			end)
			Option:GetPropertyChangedSignal("Value"):Connect(function(Value)
				if Option.Mode == "Button" then
					for Index, OldOption in pairs(Dropdown.List) do
						SetValue(OldOption.Internal, false)
					end

					Value = true
					Option.Internal.Value = Value
					OptionContainerAsset.Visible = false
				end

				RefreshSelected()
				Option.ColorConfig[1] = Value
				Option.Object.Tick.BackgroundColor3 = Value
					and Window.Color or Color3.fromRGB(63, 63, 63)
				Option.Callback(Dropdown.Value, Option)
			end)

			for Index, Value in pairs(Option.Internal) do
				if string.find(Index, "Colorpicker") then
					Option[Index] = Bracket.Utilities:GetType(Option[Index], "table", {}, true)
					Option[Index].Flag = Bracket.Utilities:GetType(Option[Index].Flag, "string",
						Dropdown.Flag .. "/" .. Option.Name .. "/Colorpicker")

					Option[Index].Value = Bracket.Utilities:GetType(Option[Index].Value, "table", {1, 1, 1, 0, false})
					Option[Index].Callback = Bracket.Utilities:GetType(Option[Index].Callback, "function", function() end)
					Window.Elements[#Window.Elements + 1] = Option[Index]
					Window.Flags[Option[Index].Flag] = Option[Index].Value

					Bracket.Elements.ToggleColorpicker(OptionAsset.Layout, Window, Option[Index])
				end
			end

			return Option
		end

		DropdownAsset.MouseButton1Click:Connect(function()
			if not OptionContainerAsset.Visible and OptionContainerAsset.ListLayout.AbsoluteContentSize.Y ~= 0 then
				Bracket.Utilities.ClosePopUps()
				OptionContainerAsset.Visible = true

				ContainerRender = RunService.RenderStepped:Connect(function()
					if not OptionContainerAsset.Visible then ContainerRender:Disconnect() end

					local TabPosition = Window.Asset.TabContainer.AbsolutePosition.Y + Window.Asset.TabContainer.AbsoluteSize.Y
					local DropdownPosition = DropdownAsset.Background.AbsolutePosition.Y + DropdownAsset.Background.AbsoluteSize.Y
					if TabPosition < DropdownPosition then
						OptionContainerAsset.Visible = false
					end

					TabPosition = Window.Asset.TabContainer.AbsolutePosition.Y
					DropdownPosition = DropdownAsset.Background.AbsolutePosition.Y
					if TabPosition > DropdownPosition then
						OptionContainerAsset.Visible = false
					end

					OptionContainerAsset.Position = UDim2.fromOffset(
						DropdownAsset.Background.AbsolutePosition.X + 1,
						(DropdownAsset.Background.AbsolutePosition.Y + GuiInset.Y) + DropdownAsset.Background.AbsoluteSize.Y + 4
					)
					OptionContainerAsset.Size = UDim2.fromOffset(
						DropdownAsset.Background.AbsoluteSize.X,
						math.clamp(OptionContainerAsset.ListLayout.AbsoluteContentSize.Y, 14, 84) + 6
						-- OptionContainerAsset.ListLayout.AbsoluteContentSize.Y + 2
					)
				end)
			else
				OptionContainerAsset.Visible = false
			end
		end)
		DropdownAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
			DropdownAsset.Title.Size = Dropdown.HideName and UDim2.fromScale(1, 0)
				or UDim2.new(1, 0, 0, DropdownAsset.Title.TextBounds.Y)

			DropdownAsset.Background.Position = UDim2.new(0.5, 0, 0, DropdownAsset.Title.Size.Y.Offset + (Dropdown.HideName and 0 or 4))
			DropdownAsset.Size = UDim2.new(1, 0, 0, DropdownAsset.Title.Size.Y.Offset + DropdownAsset.Background.Size.Y.Offset)
		end)
		OptionContainerAsset.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			OptionContainerAsset.CanvasSize = UDim2.fromOffset(0, OptionContainerAsset.ListLayout.AbsoluteContentSize.Y + 6)
		end)
		--[[DropdownAsset.Background.Value:GetPropertyChangedSignal("TextBounds"):Connect(function()
			DropdownAsset.Background.Size = UDim2.new(1, 0, 0, DropdownAsset.Background.Value.TextBounds.Y + 2)
			DropdownAsset.Size = UDim2.new(1, 0, 0, DropdownAsset.Title.Size.Y.Offset + DropdownAsset.Background.Size.Y.Offset)
		end)]]

		Dropdown:GetPropertyChangedSignal("Name"):Connect(function(Name)
			DropdownAsset.Title.Text = Name
		end)
		Dropdown:GetPropertyChangedSignal("Value"):Connect(function(Value)
			if type(Value) ~= "table" then return end
			if #Value == 0 then RefreshSelected() return end

			for Index, Option in pairs(Dropdown.List) do
				if table.find(Value, Option.Name) then
					Option.Value = true
				else
					if Option.Mode ~= "Button" then
						Option.Value = false
					end
				end
			end
		end)

		-- Dropdown Update
		for Index, Option in pairs(Dropdown.List) do
			Dropdown.List[Index] = AddOption(Option, false, Index)
		end
		for Index, Option in pairs(Dropdown.List) do
			if Option.Value then Option.Value = true end
		end
		RefreshSelected()
		Dropdown.Default = Bracket.Utilities:DeepCopy(Dropdown.Value)

		function Dropdown:BulkAdd(Table)
			for Index, Option in pairs(Table) do
				AddOption(Option, true, Index)
			end
		end
		function Dropdown.AddOption(Self, Option)
			AddOption(Option, true, #Self.List)
		end

		function Dropdown.Clear(Self)
			for Index, Option in pairs(Self.List) do
				Option.Object:Destroy()
			end table.clear(Self.List)
		end
		function Dropdown.RemoveOption(Self, Name)
			for Index, Option in pairs(Self.List) do
				if Option.Name == Name then
					Option.Object:Destroy()
					table.remove(Self.List, Index)
				end
			end
			for Index, Option in pairs(Self.List) do
				Option.Object.LayoutOrder = Index
			end
		end
		function Dropdown.RefreshToPlayers(Self, ToggleMode)
			local Players = {}
			for Index, Player in pairs(PlayerService:GetPlayers()) do
				if Player == LocalPlayer then continue end
				table.insert(Players, {Name = Player.Name,
					Mode = ToggleMode == "Toggle" or "Button"
				})
			end
			Self:Clear()
			Self:BulkAdd(Players)
		end

		function Dropdown:Tooltip(Text)
			Dropdown.Tooltip = Bracket.Elements.Tooltip(DropdownAsset, {Text = Text})
		end
	end,
	Colorpicker = function(Parent, Window, Colorpicker)
		local ColorpickerAsset = Bracket.Assets.Colorpicker()
		local PaletteAsset = Bracket.Assets.ColorpickerPalette()

		Colorpicker.Type = "Colorpicker"
		Colorpicker.Asset = ColorpickerAsset
		Colorpicker.PaletteAsset = PaletteAsset

		Colorpicker.ColorConfig = {Colorpicker.Value[5], "BackgroundColor3"}
		Window.Colorable[PaletteAsset.Rainbow.Tick] = Colorpicker.ColorConfig

		Colorpicker.Default = Bracket.Utilities:DeepCopy(Colorpicker.Value)

		local PaletteRender, SVRender, HueRender, AlphaRender = nil, nil, nil, nil

		ColorpickerAsset.Parent = Parent
		PaletteAsset.Parent = Bracket.Screen

		ColorpickerAsset.Title.Text = Colorpicker.Name
		PaletteAsset.Rainbow.Tick.BackgroundColor3 = Colorpicker.Value[5]
			and Window.Color or Color3.fromRGB(63, 63, 63)

		ColorpickerAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
			ColorpickerAsset.Size = UDim2.new(1, 0, 0, ColorpickerAsset.Title.TextBounds.Y)
		end)

		ColorpickerAsset.MouseButton1Click:Connect(function()
			if not PaletteAsset.Visible then
				Bracket.Utilities.ClosePopUps()
				PaletteAsset.Visible = true

				PaletteRender = RunService.RenderStepped:Connect(function()
					if not PaletteAsset.Visible then PaletteRender:Disconnect() end

					local TabPosition = Window.Asset.TabContainer.AbsolutePosition.Y + Window.Asset.TabContainer.AbsoluteSize.Y
					local ColorpickerPosition = ColorpickerAsset.Color.AbsolutePosition.Y + ColorpickerAsset.Color.AbsoluteSize.Y
					if TabPosition < ColorpickerPosition then
						PaletteAsset.Visible = false
					end

					TabPosition = Window.Asset.TabContainer.AbsolutePosition.Y
					ColorpickerPosition = ColorpickerAsset.Color.AbsolutePosition.Y
					if TabPosition > ColorpickerPosition then
						PaletteAsset.Visible = false
					end

					PaletteAsset.Position = UDim2.fromOffset(
						(ColorpickerAsset.Color.AbsolutePosition.X - PaletteAsset.AbsoluteSize.X) + 20,
						(ColorpickerAsset.Color.AbsolutePosition.Y + GuiInset.Y) + 14
					)
				end)
			else
				PaletteAsset.Visible = false
			end
		end)

		PaletteAsset.Rainbow.MouseButton1Click:Connect(function()
			Colorpicker.Value[5] = not Colorpicker.Value[5]
			Colorpicker.ColorConfig[1] = Colorpicker.Value[5]
			PaletteAsset.Rainbow.Tick.BackgroundColor3 = Colorpicker.Value[5]
				and Window.Color or Color3.fromRGB(63, 63, 63)
		end)
		PaletteAsset.SVPicker.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if SVRender then SVRender:Disconnect() end
				SVRender = RunService.RenderStepped:Connect(function()
					if not PaletteAsset.Visible then SVRender:Disconnect() end
					local Mouse = UserInputService:GetMouseLocation()
					local ColorX = math.clamp(Mouse.X - PaletteAsset.SVPicker.AbsolutePosition.X, 0, PaletteAsset.SVPicker.AbsoluteSize.X) / PaletteAsset.SVPicker.AbsoluteSize.X
					local ColorY = math.clamp(Mouse.Y - (PaletteAsset.SVPicker.AbsolutePosition.Y + GuiInset.Y), 0, PaletteAsset.SVPicker.AbsoluteSize.Y) / PaletteAsset.SVPicker.AbsoluteSize.Y

					Colorpicker.Value[2] = ColorX
					Colorpicker.Value[3] = 1 - ColorY
					Colorpicker.Value = Colorpicker.Value
				end)
			end
		end)
		PaletteAsset.SVPicker.InputEnded:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if SVRender then SVRender:Disconnect() end
			end
		end)
		PaletteAsset.Hue.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if HueRender then HueRender:Disconnect() end
				HueRender = RunService.RenderStepped:Connect(function()
					if not PaletteAsset.Visible then HueRender:Disconnect() end
					local Mouse = UserInputService:GetMouseLocation()
					local ColorX = math.clamp(Mouse.X - PaletteAsset.Hue.AbsolutePosition.X, 0, PaletteAsset.Hue.AbsoluteSize.X) / PaletteAsset.Hue.AbsoluteSize.X
					Colorpicker.Value[1] = 1 - ColorX
					Colorpicker.Value = Colorpicker.Value
				end)
			end
		end)
		PaletteAsset.Hue.InputEnded:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if HueRender then HueRender:Disconnect() end
			end
		end)
		PaletteAsset.Alpha.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if AlphaRender then AlphaRender:Disconnect() end
				AlphaRender = RunService.RenderStepped:Connect(function()
					if not PaletteAsset.Visible then AlphaRender:Disconnect() end
					local Mouse = UserInputService:GetMouseLocation()
					local ColorX = math.clamp(Mouse.X - PaletteAsset.Alpha.AbsolutePosition.X, 0, PaletteAsset.Alpha.AbsoluteSize.X) / PaletteAsset.Alpha.AbsoluteSize.X
					Colorpicker.Value[4] = math.floor(ColorX * 10^2) / (10^2) -- idk %.2f little bit broken with this
					Colorpicker.Value = Colorpicker.Value
				end)
			end
		end)
		PaletteAsset.Alpha.InputEnded:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if AlphaRender then AlphaRender:Disconnect() end
			end
		end)

		PaletteAsset.RGB.RGBBox.FocusLost:Connect(function(Enter)
			if not Enter then return end
			local ColorString = string.split(string.gsub(PaletteAsset.RGB.RGBBox.Text, " ", ""), ", ")
			local Hue, Saturation, Value = Color3.fromRGB(ColorString[1], ColorString[2], ColorString[3]):ToHSV()
			PaletteAsset.RGB.RGBBox.Text = ""
			Colorpicker.Value[1] = Hue
			Colorpicker.Value[2] = Saturation
			Colorpicker.Value[3] = Value
			Colorpicker.Value = Colorpicker.Value
		end)
		PaletteAsset.HEX.HEXBox.FocusLost:Connect(function(Enter)
			if not Enter then return end
			local Hue, Saturation, Value = Color3.fromHex("#" .. PaletteAsset.HEX.HEXBox.Text):ToHSV()
			PaletteAsset.RGB.RGBBox.Text = ""
			Colorpicker.Value[1] = Hue
			Colorpicker.Value[2] = Saturation
			Colorpicker.Value[3] = Value
			Colorpicker.Value = Colorpicker.Value
		end)

		RunService.Heartbeat:Connect(function()
			if Colorpicker.Value[5] then
				if PaletteAsset.Visible then
					Colorpicker.Value[1] = Window.RainbowHue
					Colorpicker.Value = Colorpicker.Value
				else
					Colorpicker.Value[1] = Window.RainbowHue
					Colorpicker.Value[6] = Bracket.Utilities.TableToColor(Colorpicker.Value)
					ColorpickerAsset.Color.BackgroundColor3 = Colorpicker.Value[6]

					Window.Flags[Colorpicker.Flag] = Colorpicker.Value
					Colorpicker.Callback(Colorpicker.Value, Colorpicker.Value[6])
				end
			end
		end)

		Colorpicker:GetPropertyChangedSignal("Name"):Connect(function(Name)
			ColorpickerAsset.Title.Text = Name
		end)
		Colorpicker:GetPropertyChangedSignal("Value"):Connect(function(Value)
			Value[6] = Bracket.Utilities.TableToColor(Value)
			Colorpicker.ColorConfig[1] = Colorpicker.Value[5]
			ColorpickerAsset.Color.BackgroundColor3 = Value[6]

			PaletteAsset.Rainbow.Tick.BackgroundColor3 = Colorpicker.Value[5]
				and Window.Color or Color3.fromRGB(63, 63, 63)

			PaletteAsset.SVPicker.BackgroundColor3 = Color3.fromHSV(Value[1], 1, 1)
			PaletteAsset.SVPicker.Pin.Position = UDim2.fromScale(Value[2], 1 - Value[3])
			PaletteAsset.Hue.Pin.Position = UDim2.fromScale(1 - Value[1], 0.5)

			PaletteAsset.Alpha.Pin.Position = UDim2.fromScale(Value[4], 0.5)
			PaletteAsset.Alpha.Value.Text = Value[4]
			PaletteAsset.Alpha.BackgroundColor3 = Value[6]

			PaletteAsset.RGB.RGBBox.PlaceholderText = Bracket.Utilities.ColorToString(Value[6])
			PaletteAsset.HEX.HEXBox.PlaceholderText = string.upper(Value[6]:ToHex())
			Window.Flags[Colorpicker.Flag] = Value
			Colorpicker.Callback(Value, Value[6])
		end)

		function Colorpicker:Tooltip(Text)
			Colorpicker.Tooltip = Bracket.Elements.Tooltip(ColorpickerAsset, {Text = Text})
		end

		Colorpicker.Value = Colorpicker.Value
	end,
	ToggleColorpicker = function(Parent, Window, Colorpicker)
		local ColorpickerAsset = Bracket.Assets.ToggleColorpicker()
		local PaletteAsset = Bracket.Assets.ColorpickerPalette()

		Colorpicker.Type = "Colorpicker"
		Colorpicker.Asset = ColorpickerAsset
		Colorpicker.PaletteAsset = PaletteAsset

		Colorpicker.ColorConfig = {Colorpicker.Value[5], "BackgroundColor3"}
		Window.Colorable[PaletteAsset.Rainbow.Tick] = Colorpicker.ColorConfig

		Colorpicker.Default = Bracket.Utilities:DeepCopy(Colorpicker.Value)

		local PaletteRender, SVRender, HueRender, AlphaRender = nil, nil, nil, nil

		ColorpickerAsset.Parent = Parent
		PaletteAsset.Parent = Bracket.Screen

		PaletteAsset.Rainbow.Tick.BackgroundColor3 = Colorpicker.Value[5]
			and Window.Color or Color3.fromRGB(63, 63, 63)

		ColorpickerAsset.MouseButton1Click:Connect(function()
			if not PaletteAsset.Visible then
				Bracket.Utilities.ClosePopUps()
				PaletteAsset.Visible = true

				PaletteRender = RunService.RenderStepped:Connect(function()
					if not PaletteAsset.Visible then PaletteRender:Disconnect() end

					local TabPosition = Window.Asset.TabContainer.AbsolutePosition.Y + Window.Asset.TabContainer.AbsoluteSize.Y
					local ColorpickerPosition = ColorpickerAsset.AbsolutePosition.Y + ColorpickerAsset.AbsoluteSize.Y
					if TabPosition < ColorpickerPosition then
						PaletteAsset.Visible = false
					end

					TabPosition = Window.Asset.TabContainer.AbsolutePosition.Y
					ColorpickerPosition = ColorpickerAsset.AbsolutePosition.Y
					if TabPosition > ColorpickerPosition then
						PaletteAsset.Visible = false
					end

					PaletteAsset.Position = UDim2.fromOffset(
						(ColorpickerAsset.AbsolutePosition.X - PaletteAsset.AbsoluteSize.X) + 24,
						(ColorpickerAsset.AbsolutePosition.Y + GuiInset.Y) + 16
					)
				end)
			else
				PaletteAsset.Visible = false
			end
		end)

		PaletteAsset.Rainbow.MouseButton1Click:Connect(function()
			Colorpicker.Value[5] = not Colorpicker.Value[5]
			Colorpicker.ColorConfig[1] = Colorpicker.Value[5]
			PaletteAsset.Rainbow.Tick.BackgroundColor3 = Colorpicker.Value[5]
				and Window.Color or Color3.fromRGB(63, 63, 63)
		end)
		PaletteAsset.SVPicker.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if SVRender then SVRender:Disconnect() end
				SVRender = RunService.RenderStepped:Connect(function()
					if not PaletteAsset.Visible then SVRender:Disconnect() end
					local Mouse = UserInputService:GetMouseLocation()
					local ColorX = math.clamp(Mouse.X - PaletteAsset.SVPicker.AbsolutePosition.X, 0, PaletteAsset.SVPicker.AbsoluteSize.X) / PaletteAsset.SVPicker.AbsoluteSize.X
					local ColorY = math.clamp(Mouse.Y - (PaletteAsset.SVPicker.AbsolutePosition.Y + GuiInset.Y), 0, PaletteAsset.SVPicker.AbsoluteSize.Y) / PaletteAsset.SVPicker.AbsoluteSize.Y

					Colorpicker.Value[2] = ColorX
					Colorpicker.Value[3] = 1 - ColorY
					Colorpicker.Value = Colorpicker.Value
				end)
			end
		end)
		PaletteAsset.SVPicker.InputEnded:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if SVRender then SVRender:Disconnect() end
			end
		end)
		PaletteAsset.Hue.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if HueRender then HueRender:Disconnect() end
				HueRender = RunService.RenderStepped:Connect(function()
					if not PaletteAsset.Visible then HueRender:Disconnect() end
					local Mouse = UserInputService:GetMouseLocation()
					local ColorX = math.clamp(Mouse.X - PaletteAsset.Hue.AbsolutePosition.X, 0, PaletteAsset.Hue.AbsoluteSize.X) / PaletteAsset.Hue.AbsoluteSize.X
					Colorpicker.Value[1] = 1 - ColorX
					Colorpicker.Value = Colorpicker.Value
				end)
			end
		end)
		PaletteAsset.Hue.InputEnded:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if HueRender then HueRender:Disconnect() end
			end
		end)
		PaletteAsset.Alpha.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if AlphaRender then AlphaRender:Disconnect() end
				AlphaRender = RunService.RenderStepped:Connect(function()
					if not PaletteAsset.Visible then AlphaRender:Disconnect() end
					local Mouse = UserInputService:GetMouseLocation()
					local ColorX = math.clamp(Mouse.X - PaletteAsset.Alpha.AbsolutePosition.X, 0, PaletteAsset.Alpha.AbsoluteSize.X) / PaletteAsset.Alpha.AbsoluteSize.X
					Colorpicker.Value[4] = math.floor(ColorX * 10^2) / (10^2) -- idk %.2f little bit broken with this
					Colorpicker.Value = Colorpicker.Value
				end)
			end
		end)
		PaletteAsset.Alpha.InputEnded:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if AlphaRender then AlphaRender:Disconnect() end
			end
		end)

		PaletteAsset.RGB.RGBBox.FocusLost:Connect(function(Enter)
			if not Enter then return end
			local ColorString = string.split(string.gsub(PaletteAsset.RGB.RGBBox.Text, " ", ""), ", ")
			local Hue, Saturation, Value = Color3.fromRGB(ColorString[1], ColorString[2], ColorString[3]):ToHSV()
			PaletteAsset.RGB.RGBBox.Text = ""
			Colorpicker.Value[1] = Hue
			Colorpicker.Value[2] = Saturation
			Colorpicker.Value[3] = Value
			Colorpicker.Value = Colorpicker.Value
		end)
		PaletteAsset.HEX.HEXBox.FocusLost:Connect(function(Enter)
			if not Enter then return end
			local Hue, Saturation, Value = Color3.fromHex("#" .. PaletteAsset.HEX.HEXBox.Text):ToHSV()
			PaletteAsset.RGB.RGBBox.Text = ""
			Colorpicker.Value[1] = Hue
			Colorpicker.Value[2] = Saturation
			Colorpicker.Value[3] = Value
			Colorpicker.Value = Colorpicker.Value
		end)

		RunService.Heartbeat:Connect(function()
			if Colorpicker.Value[5] then
				if PaletteAsset.Visible then
					Colorpicker.Value[1] = Window.RainbowHue
					Colorpicker.Value = Colorpicker.Value
				else
					Colorpicker.Value[1] = Window.RainbowHue
					Colorpicker.Value[6] = Bracket.Utilities.TableToColor(Colorpicker.Value)
					ColorpickerAsset.BackgroundColor3 = Colorpicker.Value[6]

					Window.Flags[Colorpicker.Flag] = Colorpicker.Value
					Colorpicker.Callback(Colorpicker.Value, Colorpicker.Value[6])
				end
			end
		end)
		Colorpicker:GetPropertyChangedSignal("Value"):Connect(function(Value)
			Value[6] = Bracket.Utilities.TableToColor(Value)
			Colorpicker.ColorConfig[1] = Colorpicker.Value[5]
			ColorpickerAsset.BackgroundColor3 = Value[6]

			PaletteAsset.Rainbow.Tick.BackgroundColor3 = Colorpicker.Value[5]
				and Window.Color or Color3.fromRGB(63, 63, 63)

			PaletteAsset.SVPicker.BackgroundColor3 = Color3.fromHSV(Value[1], 1, 1)
			PaletteAsset.SVPicker.Pin.Position = UDim2.fromScale(Value[2], 1 - Value[3])
			PaletteAsset.Hue.Pin.Position = UDim2.fromScale(1 - Value[1], 0.5)

			PaletteAsset.Alpha.Pin.Position = UDim2.fromScale(Value[4], 0.5)
			PaletteAsset.Alpha.Value.Text = Value[4]
			PaletteAsset.Alpha.BackgroundColor3 = Value[6]

			PaletteAsset.RGB.RGBBox.PlaceholderText = Bracket.Utilities.ColorToString(Value[6])
			PaletteAsset.HEX.HEXBox.PlaceholderText = string.upper(Value[6]:ToHex())
			Window.Flags[Colorpicker.Flag] = Value
			Colorpicker.Callback(Value, Value[6])
		end)

		Colorpicker.Value = Colorpicker.Value
	end
}

function Bracket:Window(Window)
	Window = Bracket.Utilities:GetType(Window, "table", {}, true)
	Window.Blur = Bracket.Utilities:GetType(Window.Blur, "boolean", false)
	Window.Name = Bracket.Utilities:GetType(Window.Name, "string", "Window")
	Window.Enabled = Bracket.Utilities:GetType(Window.Enabled, "boolean", true)
	Window.RainbowSpeed = Bracket.Utilities:GetType(Window.RainbowSpeed, "number", 10)
	Window.Color = Bracket.Utilities:GetType(Window.Color, "Color3", Color3.new(1, 0.5, 0.25))
	Window.Position = Bracket.Utilities:GetType(Window.Position, "UDim2", UDim2.new(0.5, -248, 0.5, -248))
	Window.Size = Bracket.Utilities:GetType(Window.Size, "UDim2", UDim2.new(0, 496, 0, 496))

	local WindowAsset = Bracket.Elements.Window(Window)

	function Window:Tab(Tab)
		Tab = Bracket.Utilities:GetType(Tab, "table", {}, true)
		Tab.Name = Bracket.Utilities:GetType(Tab.Name, "string", "Tab")

		Bracket.Elements.Tab(WindowAsset, Window, Tab)

		function Tab.AddConfigSection(Self, FolderName, Side)
			local ConfigSection = Self:Section({Name = "Config System", Side = Side}) do
				local ConfigList = Bracket.Utilities.ConfigsToList(FolderName)
				local AutoLoadConfig = Window:GetAutoLoadConfig(FolderName)

				local ConfigDropdown = nil
				local ConfigTextbox = nil

				local function UpdateConfigList(Name)
					ConfigDropdown:Clear()
					ConfigList = Bracket.Utilities.ConfigsToList(FolderName)
					ConfigDropdown:BulkAdd(ConfigList)
					ConfigDropdown.Value = {}
					-- ConfigDropdown.Value = {Name or (ConfigList[#ConfigList] and ConfigList[#ConfigList].Name)}
				end

				ConfigTextbox = ConfigSection:Textbox({HideName = true, Placeholder = "Config Name", IgnoreFlag = true})
				ConfigSection:Button({Name = "Create", Callback = function()
					Window:SaveConfig(FolderName, ConfigTextbox.Value)
					UpdateConfigList(ConfigTextbox.Value)
				end})

				ConfigSection:Divider({Text = "Configs"})

				ConfigDropdown = ConfigSection:Dropdown({HideName = true, IgnoreFlag = true, List = ConfigList})
				-- ConfigDropdown.Value = {ConfigList[#ConfigList] and ConfigList[#ConfigList].Name}

				ConfigSection:Button({Name = "Save", Callback = function()
					if ConfigDropdown.Value and ConfigDropdown.Value[1] then
						Window:SaveConfig(FolderName, ConfigDropdown.Value[1])
					else
						Bracket:Push({
							Title = "Config System",
							Description = "Select Config First",
							Duration = 10
						})
					end
				end})
				ConfigSection:Button({Name = "Load", Callback = function()
					if ConfigDropdown.Value and ConfigDropdown.Value[1] then
						Window:LoadConfig(FolderName, ConfigDropdown.Value[1])
					else
						Bracket:Push({
							Title = "Config System",
							Description = "Select Config First",
							Duration = 10
						})
					end
				end})
				ConfigSection:Button({Name = "Delete", Callback = function()
					if ConfigDropdown.Value and ConfigDropdown.Value[1] then
						Window:DeleteConfig(FolderName, ConfigDropdown.Value[1])
						UpdateConfigList()
					else
						Bracket:Push({
							Title = "Config System",
							Description = "Select Config First",
							Duration = 10
						})
					end
				end})
				ConfigSection:Button({Name = "Refresh", Callback = UpdateConfigList})

				local ConfigDivider = ConfigSection:Divider({Text = not AutoLoadConfig and "AutoLoad Config"
					or "AutoLoad Config\n<font color=\"rgb(191, 191, 191)\">[ " .. AutoLoadConfig .. " ]</font>"})

				ConfigSection:Button({Name = "Set AutoLoad Config", Callback = function()
					if ConfigDropdown.Value and ConfigDropdown.Value[1] then
						Window:AddToAutoLoad(FolderName, ConfigDropdown.Value[1])
						ConfigDivider.Text = "AutoLoad Config\n<font color=\"rgb(191, 191, 191)\">[ " .. ConfigDropdown.Value[1] .. " ]</font>"
					else
						Bracket:Push({
							Title = "Config System",
							Description = "Select Config First",
							Duration = 10
						})
					end
				end})
				ConfigSection:Button({Name = "Clear AutoLoad Config", Callback = function()
					Window:RemoveFromAutoLoad(FolderName)
					ConfigDivider.Text = "AutoLoad Config"
				end})
			end
		end

		function Tab.Divider(Self, Divider)
			Divider = Bracket.Utilities:GetType(Divider, "table", {}, true)
			Divider.Text = Bracket.Utilities:GetType(Divider.Text, "string", "")

			local Parent = Self.Type == "Tab" and Bracket.Utilities:ChooseTabSide(Self.Asset, Divider.Side) or Self.Container
			Bracket.Elements.Divider(Parent, Divider)
			return Divider
		end
		function Tab.Label(Self, Label)
			Label = Bracket.Utilities:GetType(Label, "table", {}, true)
			Label.Text = Bracket.Utilities:GetType(Label.Text, "string", "Label")

			local Parent = Self.Type == "Tab" and Bracket.Utilities:ChooseTabSide(Self.Asset, Label.Side) or Self.Container
			Bracket.Elements.Label(Parent, Label)
			return Label
		end
		function Tab.Button(Self, Button)
			Button = Bracket.Utilities:GetType(Button, "table", {}, true)
			Button.Name = Bracket.Utilities:GetType(Button.Name, "string", "Button")
			if Button.AltStyle then Button.ButtonName = Bracket.Utilities:GetType(Button.ButtonName, "string", "Click Me!") end
			Button.Callback = Bracket.Utilities:GetType(Button.Callback, "function", function() end)

			local Parent = Self.Type == "Tab" and Bracket.Utilities:ChooseTabSide(Self.Asset, Button.Side) or Self.Container
			local ButtonElement = Button.AltStyle and Bracket.Elements.Button2 or Bracket.Elements.Button
			ButtonElement(Parent, Window, Button)
			return Button
		end
		function Tab.Toggle(Self, Toggle)
			Toggle = Bracket.Utilities:GetType(Toggle, "table", {}, true)
			Toggle.Name = Bracket.Utilities:GetType(Toggle.Name, "string", "Toggle")
			Toggle.Flag = Bracket.Utilities:GetType(Toggle.Flag, "string", Toggle.Name)

			Toggle.Value = Bracket.Utilities:GetType(Toggle.Value, "boolean", false)
			Toggle.Callback = Bracket.Utilities:GetType(Toggle.Callback, "function", function() end)

			Window.Elements[#Window.Elements + 1] = Toggle
			Window.Flags[Toggle.Flag] = Toggle.Value

			local Parent = Self.Type == "Tab" and Bracket.Utilities:ChooseTabSide(Self.Asset, Toggle.Side) or Self.Container
			Bracket.Elements.Toggle(Parent, Window, Toggle)
			return Toggle
		end
		function Tab.Slider(Self, Slider)
			Slider = Bracket.Utilities:GetType(Slider, "table", {}, true)
			Slider.Name = Bracket.Utilities:GetType(Slider.Name, "string", "Slider")
			Slider.Flag = Bracket.Utilities:GetType(Slider.Flag, "string", Slider.Name)

			Slider.Min = Bracket.Utilities:GetType(Slider.Min, "number", 0)
			Slider.Max = Bracket.Utilities:GetType(Slider.Max, "number", 100)
			Slider.Precise = Bracket.Utilities:GetType(Slider.Precise, "number", 0)
			Slider.Unit = Bracket.Utilities:GetType(Slider.Unit, "string", "")
			Slider.Value = Bracket.Utilities:GetType(Slider.Value, "number", Slider.Max / 2)
			Slider.Callback = Bracket.Utilities:GetType(Slider.Callback, "function", function() end)

			Window.Elements[#Window.Elements + 1] = Slider
			Window.Flags[Slider.Flag] = Slider.Value

			local Parent = Self.Type == "Tab" and Bracket.Utilities:ChooseTabSide(Self.Asset, Slider.Side) or Self.Container
			Bracket.Elements.Slider(Parent, Window, Slider)
			return Slider
		end
		function Tab.Textbox(Self, Textbox)
			Textbox = Bracket.Utilities:GetType(Textbox, "table", {}, true)
			Textbox.Name = Bracket.Utilities:GetType(Textbox.Name, "string", "Textbox")
			Textbox.Flag = Bracket.Utilities:GetType(Textbox.Flag, "string", Textbox.Name)

			Textbox.Value = Bracket.Utilities:GetType(Textbox.Value, "string", "")
			Textbox.NumbersOnly = Bracket.Utilities:GetType(Textbox.NumbersOnly, "boolean", false)
			Textbox.Placeholder = Bracket.Utilities:GetType(Textbox.Placeholder, "string", "Input here")
			Textbox.Callback = Bracket.Utilities:GetType(Textbox.Callback, "function", function() end)

			Window.Elements[#Window.Elements + 1] = Textbox
			Window.Flags[Textbox.Flag] = Textbox.Value

			local Parent = Self.Type == "Tab" and Bracket.Utilities:ChooseTabSide(Self.Asset, Textbox.Side) or Self.Container
			Bracket.Elements.Textbox(Parent, Window, Textbox)
			return Textbox
		end
		function Tab.Keybind(Self, Keybind)
			Keybind = Bracket.Utilities:GetType(Keybind, "table", {}, true)
			Keybind.Name = Bracket.Utilities:GetType(Keybind.Name, "string", "Keybind")
			Keybind.Flag = Bracket.Utilities:GetType(Keybind.Flag, "string", Keybind.Name)

			Keybind.Value = Bracket.Utilities:GetType(Keybind.Value, "string", "NONE")
			Keybind.Mouse = Bracket.Utilities:GetType(Keybind.Mouse, "boolean", false)
			Keybind.Callback = Bracket.Utilities:GetType(Keybind.Callback, "function", function() end)
			Keybind.Blacklist = Bracket.Utilities:GetType(Keybind.Blacklist, "table", {"W", "A", "S", "D", "Slash", "Tab", "Backspace", "Escape", "Space", "Delete", "Unknown", "Backquote"})

			Window.Elements[#Window.Elements + 1] = Keybind
			Window.Flags[Keybind.Flag] = Keybind.Value

			local Parent = Self.Type == "Tab" and Bracket.Utilities:ChooseTabSide(Self.Asset, Keybind.Side) or Self.Container
			Bracket.Elements.Keybind(Parent, Window, Keybind)
			return Keybind
		end
		function Tab.Dropdown(Self, Dropdown)
			Dropdown = Bracket.Utilities:GetType(Dropdown, "table", {}, true)
			Dropdown.Name = Bracket.Utilities:GetType(Dropdown.Name, "string", "Dropdown")
			Dropdown.Flag = Bracket.Utilities:GetType(Dropdown.Flag, "string", Dropdown.Name)
			Dropdown.List = Bracket.Utilities:GetType(Dropdown.List, "table", {})

			Window.Elements[#Window.Elements + 1] = Dropdown
			Window.Flags[Dropdown.Flag] = Dropdown.Value

			local Parent = Self.Type == "Tab" and Bracket.Utilities:ChooseTabSide(Self.Asset, Dropdown.Side) or Self.Container
			Bracket.Elements.Dropdown(Parent, Window, Dropdown)
			return Dropdown
		end
		function Tab.Colorpicker(Self, Colorpicker)
			Colorpicker = Bracket.Utilities:GetType(Colorpicker, "table", {}, true)
			Colorpicker.Name = Bracket.Utilities:GetType(Colorpicker.Name, "string", "Colorpicker")
			Colorpicker.Flag = Bracket.Utilities:GetType(Colorpicker.Flag, "string", Colorpicker.Name)

			Colorpicker.Value = Bracket.Utilities:GetType(Colorpicker.Value, "table", {1, 1, 1, 0, false})
			Colorpicker.Callback = Bracket.Utilities:GetType(Colorpicker.Callback, "function", function() end)

			Window.Elements[#Window.Elements + 1] = Colorpicker
			Window.Flags[Colorpicker.Flag] = Colorpicker.Value

			local Parent = Self.Type == "Tab" and Bracket.Utilities:ChooseTabSide(Self.Asset, Colorpicker.Side) or Self.Container
			Bracket.Elements.Colorpicker(Parent, Window, Colorpicker)
			return Colorpicker
		end
		function Tab.Section(Self, Section)
			Section = Bracket.Utilities:GetType(Section, "table", {}, true)
			Section.Name = Bracket.Utilities:GetType(Section.Name, "string", "Section")

			local Parent = Bracket.Utilities:ChooseTabSide(Self.Asset, Section.Side)
			Bracket.Elements.Section(Parent, Section)

			for Index, Value in pairs(Self.Internal) do
				if table.find(Bracket.SectionInclude, Index) then
					Section.Internal[Index] = Value
				end
			end

			return Section
		end
		return Tab
	end
	return Window
end

function Bracket:Push(Notification)
	Notification = Bracket.Utilities:GetType(Notification, "table", {})
	Notification.Title = Bracket.Utilities:GetType(Notification.Title, "string", "Title")
	Notification.Description = Bracket.Utilities:GetType(Notification.Description, "string", "Description")

	local NotificationAsset = Bracket.Assets.PushNotification()
	NotificationAsset.Parent = Bracket.Screen.PNContainer
	NotificationAsset.TitleHolder.Title.Text = Notification.Title
	NotificationAsset.Description.Text = Notification.Description
	NotificationAsset.TitleHolder.Title.Size = UDim2.new(1, 0, 0, NotificationAsset.TitleHolder.Title.TextBounds.Y)
	NotificationAsset.Description.Size = UDim2.new(1, 0, 0, NotificationAsset.Description.TextBounds.Y)

	NotificationAsset.Size = UDim2.fromOffset(
		(NotificationAsset.TitleHolder.Title.TextBounds.X > NotificationAsset.Description.TextBounds.X
			and NotificationAsset.TitleHolder.Title.TextBounds.X or NotificationAsset.Description.TextBounds.X) + 24,
		NotificationAsset.ListLayout.AbsoluteContentSize.Y + 8
	)

	if Notification.Duration then
		task.spawn(function()
			for Time = Notification.Duration, 1, -1 do
				NotificationAsset.TitleHolder.Close.Text = Time
				task.wait(1)
			end
			NotificationAsset.TitleHolder.Close.Text = 0

			NotificationAsset:Destroy()
			if Notification.Callback then
				Notification.Callback()
			end
		end)
	else
		NotificationAsset.TitleHolder.Close.MouseButton1Click:Connect(function()
			NotificationAsset:Destroy()
		end)
	end
end

function Bracket:Toast(Notification)
	Notification = Bracket.Utilities:GetType(Notification, "table", {})
	Notification.Title = Bracket.Utilities:GetType(Notification.Title, "string", "Title")
	Notification.Duration = Bracket.Utilities:GetType(Notification.Duration, "number", 5)
	Notification.Color = Bracket.Utilities:GetType(Notification.Color, "Color3", Color3.new(1, 0.5, 0.25))

	local NotificationAsset = Bracket.Assets.ToastNotification()
	NotificationAsset.Parent = Bracket.Screen.TNContainer
	NotificationAsset.Main.Title.Text = Notification.Title
	NotificationAsset.Main.GLine.BackgroundColor3 = Notification.Color

	NotificationAsset.Main.Size = UDim2.fromOffset(
		NotificationAsset.Main.Title.TextBounds.X + 10,
		NotificationAsset.Main.Title.TextBounds.Y + 6
	)
	NotificationAsset.Size = UDim2.fromOffset(0,
		NotificationAsset.Main.Size.Y.Offset + 4
	)

	local function TweenSize(X, Y, Callback)
		NotificationAsset:TweenSize(
			UDim2.fromOffset(X, Y),
			Enum.EasingDirection.InOut,
			Enum.EasingStyle.Linear,
			0.25, false, Callback
		)
	end

	TweenSize(NotificationAsset.Main.Size.X.Offset + 4, NotificationAsset.Main.Size.Y.Offset + 4, function()
		task.wait(Notification.Duration) TweenSize(0, NotificationAsset.Main.Size.Y.Offset + 4, function()
			NotificationAsset:Destroy() if Notification.Callback then Notification.Callback() end
		end)
	end)
end

if Bracket.IsLocal then
	function isfolder(path)
		print("Folder check", path)
		return true
	end
	function makefolder(path)
		print("Creating folder", path)
	end
	function isfile(path)
		print("File check", path)
		return true
	end
	function listfiles(path)
		print("Listing files", path)
		return {
			"Testing Config System",
			"Yeah I know it's dumb",
			"But what You gonna do about this?",
			"Oh also you can't use special characters in file names LOL"
		}
	end
	function writefile(path, data)
		print("Writing file", path, data)
	end
	function readfile(path)
		print("Reading file", path)
		return "[]"
	end
	function delfile(path)
		print("Deleting file", path)
	end
	function sethiddenproperty(object, prop, value)
		print("Setting property", object, prop, value)
	end
end

-- // Initialize ScreenGui
Bracket.Screen = Bracket.Elements.Screen()

return Bracket
