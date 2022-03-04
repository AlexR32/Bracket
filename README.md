# BracketRewrite
Also Known As V3.1

Since I don't update this repository that often, here is the [link to the roblox model](https://www.roblox.com/library/7974127463)

![Preview](https://imgur.com/NXzsvUu.png)

### Example
```lua
local Library = loadstring(game:GetObjects("rbxassetid://7974127463")[1].Source)()
local Window = Library({Name = "Window",Color = Color3.new(1,0.5,0.25),Size = UDim2.new(0,496,0,496),Position = UDim2.new(0.5,-248,0.5,-248)}) do
    --Window:ChangeName("Window")
    --Window:ChangeSize(UDim2.new(0,496,0,496))
    --Window:ChangePosition(UDim2.new(0.5,-248,0.5,-248))
    --Window:ChangeColor(Color3.new(1,0.5,0.25))
    --Window:Toggle(true)
    --Window.Background -- ImageLabel
    local Tab = Window:AddTab({Name = "Tab"}) do
        --Tab:ChangeName("Tab")

        --Side might be "Left", "Right" or nil for auto side choose
        --if callback nil then it will be replaced with print function
        Tab:AddDivider({Text = "Divider",Side = "Left"})

        local Label = Tab:AddLabel({Text = "Label",Side = "Left"})
        --Label:ChangeText("Label")

        local Button = Tab:AddButton({Name = "Button",Side = "Left",Callback = function()end})
        --Button:ChangeName("Button")
        --Button:ChangeCallback(function()end)
        --Button:AddToolTip("ToolTip")

        local Toggle = Tab:AddToggle({Name = "Toggle",Side = "Left",Value = false,Callback = function(Bool)end})
        --Toggle:ChangeName("Toggle")
        --Toggle:ChangeValue(true)
        --Toggle:ChangeCallback(function(Bool)end)
        --Toggle:AddToolTip("ToolTip")
        --Toggle:AddBind({Key = "NONE",Mouse = false,Callback = function(Bool,Key)end,Blacklist = {"W","A","S","D","Slash","Tab","Backspace","Escape","Space","Delete","Unknown","Backquote"}})

        local Slider = Tab:AddSlider({Name = "Slider",Side = "Left",Min = 0,Max = 100,Value = 50,Precise = 2,Unit = "",Callback = function(Number)end})
        --Slider:ChangeName("Slider")
        --Slider:ChangeValue(50)
        --Slider:ChangeCallback(function(Number)end)
        --Slider:AddToolTip("ToolTip")

        local Textbox = Tab:AddTextbox({Name = "Textbox",Side = "Left",Text = "Text",Placeholder = "Placeholder",NumberOnly = false,Callback = function(String)end})
        --Textbox:ChangeName("Textbox")
        --Textbox:ChangeText("Text")
        --Textbox:ChangePlaceholder("Placeholder")
        --Textbox:ChangeCallback(function(String)end)
        --Textbox:AddToolTip("ToolTip")

        local Keybind = Tab:AddBind({Name = "Keybind",Side = "Left",Key = "NONE",Mouse = false,Callback = function(Bool,Key)end,Blacklist = {"W","A","S","D","Slash","Tab","Backspace","Escape","Space","Delete","Unknown","Backquote"}})
        --Keybind:ChangeName("Keybind")
        --Keybind:ChangeCallback(function(Bool,Key)end)
        --Keybind:AddToolTip("ToolTip")

        local Dropdown = Tab:AddDropdown({Name = "Dropdown",Side = "Left",Default = game.Players.LocalPlayer.Name, List = workspace:GetChildren(),Callback = function(String)end})
        --Dropdown:AddOption("Option")
        --Dropdown:RemoveOption("Option")
        --Dropdown:SelectOption("Option")
        --Dropdown:ChangeName("Dropdown")
        --Dropdown:AddToolTip("ToolTip")

        local Colorpicker = Tab:AddColorpicker({Name = "Colorpicker",Side = "Left",Color = Color3.new(1,0,0),Callback = function(Color)end})
        --Colorpicker:ChangeName("Colorpicker")
        --Colorpicker:ChangeCallback(function(Color3)end)
        --Colorpicker:ChangeValue(Color3.new(1,0,0))
        --Colorpicker:AddToolTip("ToolTip")

        local Section = Tab:AddSection({Name = "Section",Side = "Right"}) do
            --Same Elements as in tab but without side option
            Section:AddDivider()
            Section:AddLabel()
            Section:AddButton()
            Section:AddToggle()
            Section:AddSlider()
            Section:AddTextbox()
            Section:AddBind()
            Section:AddDropdown({List = workspace:GetChildren()})
            Section:AddColorpicker()
        end
    end
end
```
