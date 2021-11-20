local MainModule = Game:GetObjects("rbxassetid://7974127463")[1]

local function GetModule(Module)
	return loadstring(MainModule[Module].Source)()
end

local Get = {
	Utilities = GetModule("Utilities"),
	Window = GetModule("Window"),
	Tab = GetModule("Tab"),
	Section = GetModule("Section"),

	Label = GetModule("Label"),
	Button = GetModule("Button"),
	Toggle = GetModule("Toggle"),
	Slider = GetModule("Slider"),
	Textbox = GetModule("Textbox"),
	Keybind = GetModule("Keybind"),
	Dropdown = GetModule("Dropdown"),
	Colorpicker = GetModule("Colorpicker"),

	Element = function(Module,Element)
		return MainModule[Module][Element]
	end
}

return function(Window)
	Window = Get.Utilities:CheckType(Window, "table") or {}
	Window.Name = Get.Utilities:CheckType(Window.Name, "string") or "Window"
	Window.Color = Get.Utilities:CheckType(Window.Color, "Color3") or Color3.new(1,0.5,0.25)
	Window.Size = Get.Utilities:CheckType(Window.Size, "Udim2") or UDim2.new(0,296,0,296)
	Window.Position = Get.Utilities:CheckType(Window.Position, "Udim2") or UDim2.new(0.5,-248,0.5,-248)
	if Window.Enabled == nil then Window.Enabled = true end
	Window.Colorable = {}

	local LocalWindow = Get.Window(Get,Window)
	function Window:AddTab(Tab)
		Tab = Get.Utilities:CheckType(Tab, "table") or {}
		Tab.Name = Get.Utilities:CheckType(Tab.Name, "string") or "Tab"
		local LocalTab = Get.Tab(LocalWindow, Window, Get, Tab)
		function Tab:AddLabel(Label)
			Label = Get.Utilities:CheckType(Label, "table") or {}
			Label.Text = Get.Utilities:CheckType(Label.Text, "string") or "Label"
			Label.Side = Get.Utilities:CheckType(Label.Side, "string") or nil

			local LocalLabel = Get.Label(Get.Utilities:ChooseTabSide(Label.Side,LocalTab),Get,Label)
			return Label
		end
		function Tab:AddButton(Button)
			Button = Get.Utilities:CheckType(Button, "table") or {}
			Button.Name = Get.Utilities:CheckType(Button.Name, "string") or "Button"
			Button.Side = Get.Utilities:CheckType(Button.Side, "string") or nil

			Button.Callback = Get.Utilities:CheckType(Button.Callback, "function") or function() print("Hello World!") end
			local LocalButton = Get.Button(Get.Utilities:ChooseTabSide(Button.Side,LocalTab),Window,Get,Button)
			return Button
		end
		function Tab:AddToggle(Toggle)
			Toggle = Get.Utilities:CheckType(Toggle, "table") or {}
			Toggle.Name = Get.Utilities:CheckType(Toggle.Name, "string") or "Toggle"
			Toggle.Side = Get.Utilities:CheckType(Toggle.Side, "string") or nil

			Toggle.Value = Get.Utilities:CheckType(Toggle.Value, "boolean") or false
			Toggle.Callback = Get.Utilities:CheckType(Toggle.Callback, "function") or print
			local LocalToggle = Get.Toggle(Get.Utilities:ChooseTabSide(Toggle.Side,LocalTab),Window,Get,Toggle)
			return Toggle
		end
		function Tab:AddSlider(Slider)
			Slider = Get.Utilities:CheckType(Slider, "table") or {}
			Slider.Name = Get.Utilities:CheckType(Slider.Name, "string") or "Slider"
			Slider.Side = Get.Utilities:CheckType(Slider.Side, "string") or nil

			Slider.Min = Get.Utilities:CheckType(Slider.Min, "number") or 0
			Slider.Max = Get.Utilities:CheckType(Slider.Max, "number") or 100
			Slider.Precise = Get.Utilities:CheckType(Slider.Precise, "number") or 0
			Slider.Unit = Get.Utilities:CheckType(Slider.Unit, "string") or ""
			Slider.Value = Get.Utilities:CheckType(Slider.Value, "number") or (Slider.Max / 2)
			Slider.Callback = Get.Utilities:CheckType(Slider.Callback, "function") or print
			local LocalSlider = Get.Slider(Get.Utilities:ChooseTabSide(Slider.Side,LocalTab),Window,Get,Slider)
			return Slider
		end
		function Tab:AddTextbox(Textbox)
			Textbox = Get.Utilities:CheckType(Textbox, "table") or {}
			Textbox.Name = Get.Utilities:CheckType(Textbox.Name, "string") or "Textbox"
			Textbox.Side = Get.Utilities:CheckType(Textbox.Side, "string") or nil

			Textbox.Text = Get.Utilities:CheckType(Textbox.Text, "string") or "Sample Text"
			Textbox.Placeholder = Get.Utilities:CheckType(Textbox.Placeholder, "string") or "Textbox"
			Textbox.NumbersOnly = Get.Utilities:CheckType(Textbox.NumbersOnly, "boolean") or false
			Textbox.Callback = Get.Utilities:CheckType(Textbox.Callback, "function") or print
			local LocalSlider = Get.Textbox(Get.Utilities:ChooseTabSide(Textbox.Side,LocalTab),Window,Get,Textbox)
			return Textbox
		end
		function Tab:AddBind(Bind)
			Bind = Get.Utilities:CheckType(Bind, "table") or {}
			Bind.Name = Get.Utilities:CheckType(Bind.Name, "string") or "Keybind"
			Bind.Side = Get.Utilities:CheckType(Bind.Side, "string") or nil

			Bind.Key = Get.Utilities:CheckType(Bind.Key, "string") or "NONE"
			Bind.Mouse = Get.Utilities:CheckType(Bind.Mouse, "boolean") or false
			Bind.Callback = Get.Utilities:CheckType(Bind.Callback, "function") or print
			Bind.Blacklist = Get.Utilities:CheckType(Bind.Blacklist, "table") or {"W","A","S","D","Slash","Tab","Backspace","Escape","Space","Delete","Unknown","Backquote"}
			local LocalBind = Get.Keybind(Get.Utilities:ChooseTabSide(Bind.Side,LocalTab),Window,Get,Bind)
			return Bind
		end
		function Tab:AddDropdown(Dropdown)
			Dropdown = Get.Utilities:CheckType(Dropdown, "table") or {}
			Dropdown.Name = Get.Utilities:CheckType(Dropdown.Name, "string") or "Dropdown"
			Dropdown.Side = Get.Utilities:CheckType(Dropdown.Side, "string") or nil

			Dropdown.Callback = Get.Utilities:CheckType(Dropdown.Callback, "function") or print
			local LocalDropdown = Get.Dropdown(Get.Utilities:ChooseTabSide(Dropdown.Side,LocalTab),LocalWindow,Window,Get,Dropdown)
			return Dropdown
		end
		function Tab:AddColorpicker(Colorpicker)
			Colorpicker = Get.Utilities:CheckType(Colorpicker, "table") or {}
			Colorpicker.Name = Get.Utilities:CheckType(Colorpicker.Name, "string") or "Colorpicker"
			Colorpicker.Side = Get.Utilities:CheckType(Colorpicker.Side, "string") or nil
			
			Colorpicker.Color = Get.Utilities:CheckType(Colorpicker.Color, "Color3") or Color3.new(1,0,0)
			Colorpicker.Callback = Get.Utilities:CheckType(Colorpicker.Callback, "function") or print
			local LocalColorpicker = Get.Colorpicker(Get.Utilities:ChooseTabSide(Colorpicker.Side,LocalTab),LocalWindow,Window,Get,Colorpicker)
			return Colorpicker
		end
		function Tab:AddSection(Section)
			Section = Get.Utilities:CheckType(Section, "table") or {}
			Section.Name = Get.Utilities:CheckType(Section.Name, "string") or "Section"
			Section.Side = Get.Utilities:CheckType(Section.Side, "string") or nil

			local LocalSection = Get.Section(Get.Utilities:ChooseTabSide(Section.Side,LocalTab),Get,Section)
			function Section:AddLabel(Label)
				Label = Get.Utilities:CheckType(Label, "table") or {}
				Label.Text = Get.Utilities:CheckType(Label.Text, "string") or "Label"

				local LocalLabel = Get.Label(LocalSection.Container,Get,Label)
				return Label
			end
			function Section:AddButton(Button)
				Button = Get.Utilities:CheckType(Button, "table") or {}
				Button.Name = Get.Utilities:CheckType(Button.Name, "string") or "Button"

				Button.Callback = Get.Utilities:CheckType(Button.Callback, "function") or function() print("Hello World!") end
				local LocalButton = Get.Button(LocalSection.Container,Window,Get,Button)
				return Button
			end
			function Section:AddToggle(Toggle)
				Toggle = Get.Utilities:CheckType(Toggle, "table") or {}
				Toggle.Name = Get.Utilities:CheckType(Toggle.Name, "string") or "Toggle"

				Toggle.Value = Get.Utilities:CheckType(Toggle.Value, "boolean") or false
				Toggle.Callback = Get.Utilities:CheckType(Toggle.Callback, "function") or print
				local LocalToggle = Get.Toggle(LocalSection.Container,Window,Get,Toggle)
				return Toggle
			end
			function Section:AddSlider(Slider)
				Slider = Get.Utilities:CheckType(Slider, "table") or {}
				Slider.Name = Get.Utilities:CheckType(Slider.Name, "string") or "Slider"

				Slider.Min = Get.Utilities:CheckType(Slider.Min, "number") or 0
				Slider.Max = Get.Utilities:CheckType(Slider.Max, "number") or 100
				Slider.Precise = Get.Utilities:CheckType(Slider.Precise, "number") or 0
				Slider.Unit = Get.Utilities:CheckType(Slider.Unit, "string") or ""
				Slider.Value = Get.Utilities:CheckType(Slider.Value, "number") or (Slider.Max / 2)
				Slider.Callback = Get.Utilities:CheckType(Slider.Callback, "function") or print
				local LocalSlider = Get.Slider(LocalSection.Container,Window,Get,Slider)
				return Slider
			end
			function Section:AddTextbox(Textbox)
				Textbox = Get.Utilities:CheckType(Textbox, "table") or {}
				Textbox.Name = Get.Utilities:CheckType(Textbox.Name, "string") or "Textbox"
				Textbox.Side = Get.Utilities:CheckType(Textbox.Side, "string") or nil

				Textbox.Text = Get.Utilities:CheckType(Textbox.Text, "string") or "Sample Text"
				Textbox.Placeholder = Get.Utilities:CheckType(Textbox.Placeholder, "string") or "Textbox"
				Textbox.NumbersOnly = Get.Utilities:CheckType(Textbox.NumbersOnly, "boolean") or false
				Textbox.Callback = Get.Utilities:CheckType(Textbox.Callback, "function") or print
				local LocalSlider = Get.Textbox(LocalSection.Container,Window,Get,Textbox)
				return Textbox
			end
			function Section:AddBind(Bind)
				Bind = Get.Utilities:CheckType(Bind, "table") or {}
				Bind.Name = Get.Utilities:CheckType(Bind.Name, "string") or "Keybind"

				Bind.Key = Get.Utilities:CheckType(Bind.Key, "string") or "NONE"
				Bind.Mouse = Get.Utilities:CheckType(Bind.Mouse, "boolean") or false
				Bind.Callback = Get.Utilities:CheckType(Bind.Callback, "function") or print
				Bind.Blacklist = Get.Utilities:CheckType(Bind.Blacklist, "table") or {"W","A","S","D","Slash","Tab","Backspace","Escape","Space","Delete","Unknown","Backquote"}
				local LocalBind = Get.Keybind(LocalSection.Container,Window,Get,Bind)
				return Bind
			end
			function Section:AddDropdown(Dropdown)
				Dropdown = Get.Utilities:CheckType(Dropdown, "table") or {}
				Dropdown.Name = Get.Utilities:CheckType(Dropdown.Name, "string") or "Dropdown"

				Dropdown.Callback = Get.Utilities:CheckType(Dropdown.Callback, "function") or print
				local LocalDropdown = Get.Dropdown(LocalSection.Container,LocalWindow,Window,Get,Dropdown)
				return Dropdown
			end
			function Section:AddColorpicker(Colorpicker)
				Colorpicker = Get.Utilities:CheckType(Colorpicker, "table") or {}
				Colorpicker.Name = Get.Utilities:CheckType(Colorpicker.Name, "string") or "Colorpicker"
				
				Colorpicker.Color = Get.Utilities:CheckType(Colorpicker.Color, "Color3") or Color3.new(1,0,0)
				Colorpicker.Callback = Get.Utilities:CheckType(Colorpicker.Callback, "function") or print
				local LocalColorpicker = Get.Colorpicker(LocalSection.Container,LocalWindow,Window,Get,Colorpicker)
				return Colorpicker
			end
			return Section
		end
		return Tab
	end
	return Window
end
