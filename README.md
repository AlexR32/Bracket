# BracketRewrite
Basically V3.1 but who cares lol

### Loadstring
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/AlexR32/BracketRewrite/main/Library.lua"))()
```

### Preview
```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/AlexR32/BracketRewrite/main/Library.lua"))()
local Window = Library() do
    local Tab = Window:AddTab() do
        Tab:AddLabel({Side = "Left"})
		Tab:AddButton({Side = "Left"})
		Tab:AddToggle({Side = "Left"}):AddBind()
		Tab:AddSlider({Side = "Left"})
		Tab:AddBind({Side = "Left"})
		Tab:AddDropdown({Side = "Left", Name = "Workspace", Default = game.Players.LocalPlayer.Name, List = workspace:GetChildren()})
        local Section = Tab:AddSection({Side = "Right"}) do
            Section:AddLabel()
			Section:AddButton()
			Section:AddToggle({Name = "UI Toggle",Value = true,Callback = function(Bool) 
				Window:Toggle(Bool)
			end}):AddBind({Key = "RightShift"})
			Section:AddSlider()
			Section:AddBind()
			Section:AddDropdown({Name = "Playerlist", Default = game.Players.LocalPlayer.Name, List = game.Players:GetPlayers()})
        end
    end
end
```