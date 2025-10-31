-- Lib/UI.lua
-- Modul untuk membuat antarmuka pengguna (UI) plugin.

local UI = {}

function UI.create(configWidget, plugin, settings)
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(41, 42, 45)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = configWidget

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 8)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = mainFrame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = mainFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.LayoutOrder = 1
	titleLabel.Text = "Conversion Settings"
	titleLabel.Size = UDim2.new(1, 0, 0, 20)
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	titleLabel.TextSize = 16
	titleLabel.BackgroundTransparency = 1
	titleLabel.Parent = mainFrame

	local selectionLabel = Instance.new("TextLabel")
	selectionLabel.Name = "SelectionLabel"
	selectionLabel.LayoutOrder = 2
	selectionLabel.Text = "Terpilih: Tidak ada"
	selectionLabel.Size = UDim2.new(1, 0, 0, 18)
	selectionLabel.Font = Enum.Font.SourceSansItalic
	selectionLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	selectionLabel.TextSize = 13
	selectionLabel.BackgroundTransparency = 1
	selectionLabel.TextXAlignment = Enum.TextXAlignment.Left
	selectionLabel.Parent = mainFrame

	local ignoreButton = Instance.new("TextButton")
	ignoreButton.Name = "IgnoreButton"
	ignoreButton.LayoutOrder = 3
	ignoreButton.Size = UDim2.new(1, 0, 0, 22)
	ignoreButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	ignoreButton.Text = " Abaikan Objek & Turunannya"
	ignoreButton.Font = Enum.Font.SourceSans
	ignoreButton.TextSize = 13
	ignoreButton.TextColor3 = Color3.fromRGB(220, 220, 220)
	ignoreButton.TextXAlignment = Enum.TextXAlignment.Left
	ignoreButton.Visible = false -- Hanya terlihat jika ada objek yang valid dipilih
	ignoreButton.Parent = mainFrame

	local typeLabel = Instance.new("TextLabel")
	typeLabel.LayoutOrder = 4
	typeLabel.Text = "Output Script Type:"
	typeLabel.Size = UDim2.new(1, 0, 0, 15)
	typeLabel.Font = Enum.Font.SourceSans
	typeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	typeLabel.TextSize = 14
	typeLabel.TextXAlignment = Enum.TextXAlignment.Left
	typeLabel.BackgroundTransparency = 1
	typeLabel.Parent = mainFrame

	local savedScriptType = plugin:GetSetting("ScriptType") or "ModuleScript"
	local scriptTypes = {"ModuleScript", "LocalScript"}
	local currentTypeIndex = table.find(scriptTypes, savedScriptType) or 1

	local scriptTypeButton = Instance.new("TextButton")
	scriptTypeButton.Name = "ScriptTypeButton"
	scriptTypeButton.LayoutOrder = 5
	scriptTypeButton.Text = savedScriptType
	scriptTypeButton.Size = UDim2.new(1, 0, 0, 28)
	scriptTypeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	scriptTypeButton.TextColor3 = Color3.fromRGB(220, 220, 220)
	scriptTypeButton.Font = Enum.Font.SourceSans
	scriptTypeButton.TextSize = 14
	scriptTypeButton.Parent = mainFrame

	local function updateScriptTypeButton()
		if scriptTypeButton.Text == "ModuleScript" then
			scriptTypeButton.BackgroundColor3 = Color3.fromRGB(120, 80, 180) -- Ungu
		else
			scriptTypeButton.BackgroundColor3 = Color3.fromRGB(80, 120, 200) -- Biru
		end
	end
	updateScriptTypeButton()

	local savedAddComments = plugin:GetSetting("AddTraceComments")
	if savedAddComments == nil then savedAddComments = true end
	local commentsEnabled = savedAddComments

	local commentsButton = Instance.new("TextButton")
	commentsButton.Name = "CommentsButton"
	commentsButton.LayoutOrder = 6
	commentsButton.Size = UDim2.new(1, 0, 0, 28)
	commentsButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	commentsButton.TextColor3 = Color3.fromRGB(220, 220, 220)
	commentsButton.Font = Enum.Font.SourceSans
	commentsButton.Text = "Trace Comments"
	commentsButton.TextSize = 14
	commentsButton.Parent = mainFrame

	local function updateCommentsButton()
		if commentsEnabled then
			commentsButton.BackgroundColor3 = Color3.fromRGB(80, 160, 80) -- Hijau
		else
			commentsButton.BackgroundColor3 = Color3.fromRGB(180, 80, 80) -- Merah
		end
	end
	updateCommentsButton()

	local savedOverwrite = plugin:GetSetting("OverwriteExisting")
	if savedOverwrite == nil then savedOverwrite = true end
	local overwriteEnabled = savedOverwrite

	local overwriteButton = Instance.new("TextButton")
	overwriteButton.Name = "OverwriteButton"
	overwriteButton.LayoutOrder = 7
	overwriteButton.Size = UDim2.new(1, 0, 0, 28)
	overwriteButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	overwriteButton.TextColor3 = Color3.fromRGB(220, 220, 220)
	overwriteButton.Font = Enum.Font.SourceSans
	overwriteButton.Text = "Overwrite Existing"
	overwriteButton.TextSize = 14
	overwriteButton.Parent = mainFrame

	local function updateOverwriteButton()
		if overwriteEnabled then
			overwriteButton.BackgroundColor3 = Color3.fromRGB(80, 160, 80) -- Hijau
		else
			overwriteButton.BackgroundColor3 = Color3.fromRGB(180, 80, 80) -- Merah
		end
	end
	updateOverwriteButton()

	local savedLiveSync = plugin:GetSetting("LiveSyncEnabled")
	if savedLiveSync == nil then savedLiveSync = false end
	local liveSyncEnabled = savedLiveSync

	local liveSyncButton = Instance.new("TextButton")
	liveSyncButton.Name = "LiveSyncButton"
	liveSyncButton.LayoutOrder = 8
	liveSyncButton.Size = UDim2.new(1, 0, 0, 28)
	liveSyncButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	liveSyncButton.TextColor3 = Color3.fromRGB(220, 220, 220)
	liveSyncButton.Font = Enum.Font.SourceSans
	liveSyncButton.Text = "Live Sync"
	liveSyncButton.TextSize = 14
	liveSyncButton.Parent = mainFrame

	local function updateLiveSyncButton()
		if liveSyncEnabled then
			liveSyncButton.BackgroundColor3 = Color3.fromRGB(80, 160, 80) -- Hijau
		else
			liveSyncButton.BackgroundColor3 = Color3.fromRGB(180, 80, 80) -- Merah
		end
	end
	updateLiveSyncButton()

	liveSyncButton.MouseButton1Click:Connect(function()
		liveSyncEnabled = not liveSyncEnabled
		updateLiveSyncButton()
		if not liveSyncEnabled then
			settings.stopSyncing()
		end
	end)

	local blacklistLabel = Instance.new("TextLabel")
	blacklistLabel.LayoutOrder = 9
	blacklistLabel.Text = "Property Blacklist:"
	blacklistLabel.Size = UDim2.new(1, 0, 0, 15)
	blacklistLabel.Font = Enum.Font.SourceSans
	blacklistLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	blacklistLabel.TextSize = 13
	blacklistLabel.TextXAlignment = Enum.TextXAlignment.Left
	blacklistLabel.BackgroundTransparency = 1
	blacklistLabel.Parent = mainFrame

	local searchBox = Instance.new("TextBox")
	searchBox.Name = "SearchBox"
	searchBox.LayoutOrder = 10
	searchBox.Size = UDim2.new(1, 0, 0, 24)
	searchBox.Font = Enum.Font.SourceSans
	searchBox.TextSize = 14
	searchBox.PlaceholderText = "Cari properti..."
	searchBox.TextColor3 = Color3.fromRGB(220, 220, 220)
	searchBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	searchBox.BorderColor3 = Color3.fromRGB(50, 50, 50)
	searchBox.ClearTextOnFocus = false
	searchBox.Parent = mainFrame

	local bulkActionFrame = Instance.new("Frame")
	bulkActionFrame.LayoutOrder = 11
	bulkActionFrame.Size = UDim2.new(1, 0, 0, 22)
	bulkActionFrame.BackgroundTransparency = 1
	bulkActionFrame.Parent = mainFrame

	local bulkListLayout = Instance.new("UIListLayout")
	bulkListLayout.FillDirection = Enum.FillDirection.Horizontal
	bulkListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	bulkListLayout.Padding = UDim.new(0, 8)
	bulkListLayout.Parent = bulkActionFrame

	local selectAllButton = Instance.new("TextButton")
	selectAllButton.Name = "SelectAllButton"
	selectAllButton.Size = UDim2.new(0, 100, 1, 0)
	selectAllButton.Text = "Pilih Semua"
	selectAllButton.Font = Enum.Font.SourceSans
	selectAllButton.TextSize = 13
	selectAllButton.TextColor3 = Color3.fromRGB(200, 220, 255)
	selectAllButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	selectAllButton.Parent = bulkActionFrame

	local deselectAllButton = Instance.new("TextButton")
	deselectAllButton.Name = "DeselectAllButton"
	deselectAllButton.Size = UDim2.new(0, 100, 1, 0)
	deselectAllButton.Text = "Batal Pilih Semua"
	deselectAllButton.Font = Enum.Font.SourceSans
	deselectAllButton.TextSize = 13
	deselectAllButton.TextColor3 = Color3.fromRGB(255, 200, 200)
	deselectAllButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	deselectAllButton.Parent = bulkActionFrame

	local blacklistFrame = Instance.new("ScrollingFrame")
	blacklistFrame.LayoutOrder = 12
	blacklistFrame.Size = UDim2.new(1, 0, 1, -355) -- Adjusted size for search box and buttons
	blacklistFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	blacklistFrame.BorderSizePixel = 1
	blacklistFrame.BorderColor3 = Color3.fromRGB(50, 50, 50)
	blacklistFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	blacklistFrame.ScrollBarThickness = 6
	blacklistFrame.Parent = mainFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.Name
	listLayout.Padding = UDim.new(0, 2)
	listLayout.Parent = blacklistFrame

	local blacklistCheckboxes = {}
	local allProps = {}
	local propSet = {}
	for _, p in ipairs(settings.COMMON_PROPERTIES) do if not propSet[p] then table.insert(allProps, p); propSet[p] = true end end
	for _, classProps in pairs(settings.PROPERTIES_BY_CLASS) do
		for _, p in ipairs(classProps) do if not propSet[p] then table.insert(allProps, p); propSet[p] = true end end
	end
	table.sort(allProps)

	local savedBlacklist = {}
	local savedBlacklistSetting = plugin:GetSetting("PropertyBlacklist")
	if savedBlacklistSetting then
		local success, decoded = pcall(function() return game:GetService("HttpService"):JSONDecode(savedBlacklistSetting) end)
		if success and type(decoded) == "table" then
			for _, propName in ipairs(decoded) do
				savedBlacklist[propName] = true
			end
		else
			for propName in string.gmatch(tostring(savedBlacklistSetting), "[^,]+") do
				savedBlacklist[propName:match("^%s*(.-)%s*$")] = true
			end
		end
	else
		savedBlacklist["Position"] = true
		savedBlacklist["Size"] = true
	end

	local i = 0
	for _, propName in ipairs(allProps) do
		i = i + 1
		local bgColor = (i % 2 == 0) and Color3.fromRGB(45, 45, 45) or Color3.fromRGB(50, 50, 50)

		local row = Instance.new("Frame")
		row.Name = propName
		row.Size = UDim2.new(1, 0, 0, 24)
		row.BackgroundColor3 = bgColor
		row.BorderSizePixel = 0
		row.Parent = blacklistFrame

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.Text = propName
		label.Font = Enum.Font.SourceSans
		label.TextSize = 14
		label.TextColor3 = Color3.fromRGB(220, 220, 220)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.LineHeight = 0.8
		label.BackgroundTransparency = 1
		label.Parent = row

		local isBlacklisted = savedBlacklist[propName] or false

		local function updateCheckboxVisuals()
			if isBlacklisted then
				row.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
				label.TextColor3 = Color3.fromRGB(255, 200, 200)
			else
				row.BackgroundColor3 = bgColor
				label.TextColor3 = Color3.fromRGB(220, 220, 220)
			end
		end

		row.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				isBlacklisted = not isBlacklisted
				updateCheckboxVisuals()
			end
		end)

		blacklistCheckboxes[propName] = {
			IsBlacklisted = function() return isBlacklisted end,
			Button = row,
			Toggle = function()
				isBlacklisted = not isBlacklisted
				updateCheckboxVisuals()
			end,
		}
		updateCheckboxVisuals()
	end

	local convertButton = Instance.new("TextButton")
	convertButton.Name = "ConvertButton"
	convertButton.LayoutOrder = 13
	convertButton.Text = "Convert"
	convertButton.Size = UDim2.new(1, 0, 0, 32)
	convertButton.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
	convertButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	convertButton.Font = Enum.Font.SourceSansBold
	convertButton.TextSize = 16
	convertButton.Parent = mainFrame

	local exampleCodeButton = Instance.new("TextButton")
	exampleCodeButton.Name = "ExampleCodeButton"
	exampleCodeButton.LayoutOrder = 14
	exampleCodeButton.Text = "Get Example Code"
	exampleCodeButton.Size = UDim2.new(1, 0, 0, 28)
	exampleCodeButton.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
	exampleCodeButton.TextColor3 = Color3.fromRGB(220, 220, 220)
	exampleCodeButton.Font = Enum.Font.SourceSans
	exampleCodeButton.TextSize = 14
	exampleCodeButton.Parent = mainFrame

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.LayoutOrder = 15
	statusLabel.Size = UDim2.new(1, 0, 0, 20)
	statusLabel.Font = Enum.Font.SourceSans
	statusLabel.Text = ""
	statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	statusLabel.TextSize = 14
	statusLabel.BackgroundTransparency = 1
	statusLabel.Visible = false
	statusLabel.Parent = mainFrame

	scriptTypeButton.MouseButton1Click:Connect(function()
		currentTypeIndex = (currentTypeIndex % #scriptTypes) + 1
		scriptTypeButton.Text = scriptTypes[currentTypeIndex]
		updateScriptTypeButton()
	end)

	commentsButton.MouseButton1Click:Connect(function()
		commentsEnabled = not commentsEnabled
		updateCommentsButton()
	end)

	overwriteButton.MouseButton1Click:Connect(function()
		overwriteEnabled = not overwriteEnabled
		updateOverwriteButton()
	end)

	return {
		SelectionLabel = selectionLabel,
		ScriptTypeButton = scriptTypeButton,
		BlacklistCheckboxes = blacklistCheckboxes,
		IsCommentsEnabled = function() return commentsEnabled end,
		IsOverwriteEnabled = function() return overwriteEnabled end,
		IsLiveSyncEnabled = function() return liveSyncEnabled end,
		ConvertButton = convertButton,
		ExampleCodeButton = exampleCodeButton,
		StatusLabel = statusLabel,
		SearchBox = searchBox,
		SelectAllButton = selectAllButton,
		DeselectAllButton = deselectAllButton,
		IgnoreButton = ignoreButton,
	}
end

return UI
