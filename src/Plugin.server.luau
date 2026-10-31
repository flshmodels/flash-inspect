-- Flash Inspect is an edit-time, read-only checker. It never repairs or deletes objects.
local Selection = game:GetService("Selection")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Config = require(script.Config)
local Rules = require(script.Rules)
local Scanner = require(script.Scanner)

local toolbar = plugin:CreateToolbar("Flash Inspect")
local toggle = toolbar:CreateButton("FlashInspect", "Check tagged scene objects", "", "Inspect")
local widget = plugin:CreateDockWidgetPluginGui("FlashInspect_v1", DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Right, false, false, 380, 500, 300, 260
))
widget.Title = "Flash Inspect"

local background = Instance.new("Frame")
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.fromRGB(31, 34, 39)
background.BorderSizePixel = 0
background.Parent = widget

local function label(parent, text, size, position)
	local item = Instance.new("TextLabel")
	item.BackgroundTransparency = 1
	item.Text = text
	item.Font = Enum.Font.SourceSans
	item.TextSize = 16
	item.TextColor3 = Color3.fromRGB(225, 229, 234)
	item.TextWrapped = true
	item.TextXAlignment = Enum.TextXAlignment.Left
	item.Size = size
	item.Position = position
	item.Parent = parent
	return item
end

local function button(text, position)
	local item = Instance.new("TextButton")
	item.Text = text
	item.Font = Enum.Font.SourceSansSemibold
	item.TextSize = 16
	item.TextColor3 = Color3.fromRGB(235, 238, 242)
	item.BackgroundColor3 = Color3.fromRGB(55, 65, 77)
	item.BorderSizePixel = 0
	item.Size = UDim2.new(0.5, -18, 0, 34)
	item.Position = position
	item.Parent = background
	return item
end

label(background, "Scene checks / no automatic changes", UDim2.new(1, -24, 0, 30), UDim2.fromOffset(12, 8))
local scanWorkspace = button("Scan Workspace", UDim2.fromOffset(12, 44))
local scanSelection = button("Scan selection", UDim2.new(0.5, 6, 0, 44))
local status = label(background, "Uses StaticScenery and Interactable tags. Results are a snapshot.", UDim2.new(1, -24, 0, 66), UDim2.fromOffset(12, 84))
local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -24, 1, -166)
list.Position = UDim2.fromOffset(12, 154)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 5
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.ScrollingDirection = Enum.ScrollingDirection.Y
list.Parent = background
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.Parent = list

local function scan(roots, scope)
	if RunService:IsRunning() then
		status.Text = "Stop the play test before scanning."
		return
	end
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end
	if #roots == 0 then
		status.Text = "Select a model or part in Explorer first."
		return
	end
	local ok, result = pcall(function()
		local records = Scanner.collect(roots, Config, function(object, tag)
			return CollectionService:HasTag(object, tag)
		end)
		return { count = #records, issues = Rules.analyze(records) }
	end)
	if not ok then
		status.Text = "Scan stopped: " .. tostring(result)
		return
	end
	status.Text = string.format("%s: %d objects / %d findings. IDs are checked only within this scope. Showing up to %d.", scope, result.count, #result.issues, Config.maxDisplayedIssues)
	for index, issue in ipairs(result.issues) do
		if index > Config.maxDisplayedIssues then break end
		local row = Instance.new("TextButton")
		row.Size = UDim2.new(1, -8, 0, 118)
		row.LayoutOrder = index
		row.BackgroundColor3 = Color3.fromRGB(43, 47, 54)
		row.BorderSizePixel = 0
		row.Text = ""
		row.Parent = list
		local text = label(row, issue.code .. "\n" .. issue.path .. "\n" .. issue.message, UDim2.new(1, -16, 1, -12), UDim2.fromOffset(8, 6))
		text.TextSize = 14
		text.TextYAlignment = Enum.TextYAlignment.Top
		text.TextTruncate = Enum.TextTruncate.AtEnd
		row.MouseButton1Click:Connect(function()
			if issue.target:IsDescendantOf(game) then
				Selection:Set({ issue.target })
			else
				status.Text = "That object was removed. Run a new scan."
			end
		end)
	end
	list.CanvasPosition = Vector2.zero
end

scanWorkspace.MouseButton1Click:Connect(function() scan({ workspace }, "Workspace") end)
scanSelection.MouseButton1Click:Connect(function() scan(Selection:Get(), "Selection") end)
toggle.Click:Connect(function() widget.Enabled = not widget.Enabled end)
local enabledConnection = widget:GetPropertyChangedSignal("Enabled"):Connect(function()
	toggle:SetActive(widget.Enabled)
end)
toggle:SetActive(widget.Enabled)
plugin.Unloading:Connect(function()
	enabledConnection:Disconnect()
	widget:Destroy()
	toolbar:Destroy()
end)
