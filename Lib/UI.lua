-- Lib/UI.lua
-- Modul untuk membuat antarmuka pengguna (UI) plugin.

local UI = {}

function UI.create(configWidget, plugin, settings)
	local mainFrame = Instance.new("ScrollingFrame")
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(41, 42, 45)
	mainFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	mainFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	mainFrame.ScrollBarThickness = 7
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = configWidget

	local mainListLayout = Instance.new("UIListLayout")
	mainListLayout.Padding = UDim.new(0, 8)
	mainListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	mainListLayout.Parent = mainFrame

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
	local ignoreCorner = Instance.new("UICorner")
	ignoreCorner.CornerRadius = UDim.new(0, 4)
	ignoreCorner.Parent = ignoreButton

	local currentLayoutOrder = 4

	local function createCollapsibleGroup(layoutOrder, title, parent, isInitiallyExpanded)
		local isExpanded = isInitiallyExpanded == nil and true or isInitiallyExpanded

		local header = Instance.new("TextButton")
		header.Name = title:gsub(" ", "") .. "Header"
		header.LayoutOrder = layoutOrder
		header.Size = UDim2.new(1, 0, 0, 28)
		header.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
		header.Text = (isExpanded and "  ▾ " or "  ▸ ") .. title
		header.Font = Enum.Font.SourceSansBold
		header.TextSize = 15
		header.TextColor3 = Color3.fromRGB(210, 210, 210)
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.Parent = parent
		local headerCorner = Instance.new("UICorner")
		headerCorner.CornerRadius = UDim.new(0, 4)
		headerCorner.Parent = header

		local contentFrame = Instance.new("Frame")
		contentFrame.Name = title:gsub(" ", "") .. "Content"
		contentFrame.LayoutOrder = layoutOrder + 1
		contentFrame.Size = UDim2.new(1, 0, 0, 0)
		contentFrame.AutomaticSize = Enum.AutomaticSize.Y
		contentFrame.BackgroundTransparency = 1
		contentFrame.ClipsDescendants = true
		contentFrame.Parent = parent
		contentFrame.Visible = isExpanded

		local contentLayout = Instance.new("UIListLayout")
		contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
		contentLayout.Padding = UDim.new(0, 5)
		contentLayout.Parent = contentFrame

		local contentPadding = Instance.new("UIPadding")
		contentPadding.PaddingTop = UDim.new(0, 8)
		contentPadding.PaddingLeft = UDim.new(0, 8)
		contentPadding.PaddingRight = UDim.new(0, 8)
		contentPadding.Parent = contentFrame

		header.MouseButton1Click:Connect(function()
			isExpanded = not isExpanded
			contentFrame.Visible = isExpanded
			header.Text = (isExpanded and "  ▾ " or "  ▸ ") .. title
		end)

		return contentFrame, layoutOrder + 2
	end

	local generalSettingsFrame, nextLayoutOrder = createCollapsibleGroup(currentLayoutOrder, "Pengaturan Umum", mainFrame, true)
	currentLayoutOrder = nextLayoutOrder

	local typeLabel = Instance.new("TextLabel")
	typeLabel.LayoutOrder = 1
	typeLabel.Text = "Output Script Type:"
	typeLabel.Size = UDim2.new(1, 0, 0, 15)
	typeLabel.Font = Enum.Font.SourceSans
	typeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	typeLabel.TextSize = 14
	typeLabel.TextXAlignment = Enum.TextXAlignment.Left
	typeLabel.BackgroundTransparency = 1
	typeLabel.Parent = generalSettingsFrame

	local savedScriptType = plugin:GetSetting("ScriptType") or "ModuleScript"
	local scriptTypes = {"ModuleScript", "LocalScript"}
	local currentTypeIndex = table.find(scriptTypes, savedScriptType) or 1

	local scriptTypeButton = Instance.new("TextButton")
	scriptTypeButton.Name = "ScriptTypeButton"
	scriptTypeButton.LayoutOrder = 2
	scriptTypeButton.Text = savedScriptType
	scriptTypeButton.Size = UDim2.new(1, 0, 0, 28)
	scriptTypeButton.TextColor3 = Color3.fromRGB(220, 220, 220)
	scriptTypeButton.Font = Enum.Font.SourceSans
	scriptTypeButton.TextSize = 14
	scriptTypeButton.Parent = generalSettingsFrame
	local typeCorner = Instance.new("UICorner")
	typeCorner.CornerRadius = UDim.new(0, 4)
	typeCorner.Parent = scriptTypeButton
	local typeStroke = Instance.new("UIStroke")
	typeStroke.Color = Color3.fromRGB(80, 80, 80)
	typeStroke.Thickness = 1
	typeStroke.Parent = scriptTypeButton

	local function updateScriptTypeButton()
		if scriptTypeButton.Text == "ModuleScript" then
			scriptTypeButton.BackgroundColor3 = Color3.fromRGB(120, 80, 180) -- Ungu
		else
			scriptTypeButton.BackgroundColor3 = Color3.fromRGB(80, 120, 200) -- Biru
		end
	end
	updateScriptTypeButton()

	-- Fungsi pembantu baru untuk sakelar geser modern
	local function createToggleSwitch(parent, layoutOrder, text, tooltip, settingKey, defaultValue, changeCallback)
		local savedValue = plugin:GetSetting(settingKey)
		local isToggled = (savedValue == nil) and defaultValue or savedValue
		local isControlEnabled = true

		local container = Instance.new("Frame")
		container.LayoutOrder = layoutOrder
		container.Size = UDim2.new(1, 0, 0, 28)
		container.BackgroundTransparency = 1
		container.Parent = parent

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -50, 1, 0)
		label.Font = Enum.Font.SourceSans
		label.Text = text
		label.TextColor3 = Color3.fromRGB(220, 220, 220)
		label.TextSize = 14
		label.BackgroundTransparency = 1
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = container

		local switchTrack = Instance.new("Frame")
		switchTrack.Name = "Track"
		switchTrack.Size = UDim2.new(0, 40, 0, 20)
		switchTrack.Position = UDim2.new(1, -40, 0.5, -10)
		switchTrack.AnchorPoint = Vector2.new(0, 0.5)
		switchTrack.Parent = container
		local trackCorner = Instance.new("UICorner")
		trackCorner.CornerRadius = UDim.new(0, 10)
		trackCorner.Parent = switchTrack

		local switchKnob = Instance.new("Frame")
		switchKnob.Name = "Knob"
		switchKnob.Size = UDim2.new(0, 16, 0, 16)
		switchKnob.Position = UDim2.new(0, 2, 0.5, -8)
		switchKnob.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
		switchKnob.BorderSizePixel = 0
		switchKnob.Parent = switchTrack
		local knobCorner = Instance.new("UICorner")
		knobCorner.CornerRadius = UDim.new(0, 8)
		knobCorner.Parent = switchKnob

		local clickDetector = Instance.new("TextButton")
		clickDetector.Size = UDim2.new(1, 0, 1, 0)
		clickDetector.BackgroundTransparency = 1
		clickDetector.Text = ""
		clickDetector.Parent = switchTrack

		local function updateVisuals(isAnimated)
			local goalPos, trackColor, knobColor, labelColor

			if isControlEnabled then
				labelColor = Color3.fromRGB(220, 220, 220)
				knobColor = Color3.fromRGB(220, 220, 220)
				if isToggled then
					goalPos = UDim2.new(1, -18, 0.5, -8) -- Kanan
					trackColor = Color3.fromRGB(80, 160, 80) -- Hijau
				else
					goalPos = UDim2.new(0, 2, 0.5, -8) -- Kiri
					trackColor = Color3.fromRGB(180, 80, 80) -- Merah
				end
			else
				labelColor = Color3.fromRGB(120, 120, 120)
				knobColor = Color3.fromRGB(160, 160, 160)
				trackColor = Color3.fromRGB(80, 80, 80)
				if isToggled then
					goalPos = UDim2.new(1, -18, 0.5, -8)
				else
					goalPos = UDim2.new(0, 2, 0.5, -8)
				end
			end

			if isAnimated then
				game:GetService("TweenService"):Create(switchKnob, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Position = goalPos, BackgroundColor3 = knobColor}):Play()
				game:GetService("TweenService"):Create(switchTrack, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = trackColor}):Play()
				game:GetService("TweenService"):Create(label, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {TextColor3 = labelColor}):Play()
			else
				switchKnob.Position = goalPos
				switchKnob.BackgroundColor3 = knobColor
				switchTrack.BackgroundColor3 = trackColor
				label.TextColor3 = labelColor
			end
		end

		clickDetector.MouseButton1Click:Connect(function()
			if not isControlEnabled then return end
			isToggled = not isToggled
			updateVisuals(true)
			if changeCallback then changeCallback(isToggled) end
		end)

		updateVisuals(false)

		local control = {}
		control.IsToggled = function() return isToggled end
		control.SetEnabled = function(newState)
			isControlEnabled = newState
			clickDetector.Active = newState
			updateVisuals(false)
		end

		return control
	end

	local commentsSwitch = createToggleSwitch(generalSettingsFrame, 3, "Trace Comments", "Menambahkan komentar ke kode yang dihasilkan yang melacak objek asli.", "AddTraceComments", true, settings.updateCodePreview)
	local overwriteSwitch = createToggleSwitch(generalSettingsFrame, 4, "Overwrite Existing", "Jika diaktifkan, menimpa skrip yang ada dengan nama yang sama. Kode kustom Anda akan dipertahankan.", "OverwriteExisting", true, settings.updateCodePreview)

	local syncSettingsFrame, nextLayoutOrder2 = createCollapsibleGroup(currentLayoutOrder, "Pengaturan Sinkronisasi Langsung", mainFrame, false)
	currentLayoutOrder = nextLayoutOrder2

	local autoRenewSwitch
	local liveSyncSwitch = createToggleSwitch(syncSettingsFrame, 1, "Live Sync", "Secara otomatis memperbarui skrip saat Anda mengedit GUI sumber secara real-time.", "LiveSyncEnabled", false, function(enabled)
		if not enabled then
			settings.stopSyncing()
		end
		if autoRenewSwitch then
			autoRenewSwitch.SetEnabled(enabled)
		end
		settings.updateCodePreview()
	end)
	autoRenewSwitch = createToggleSwitch(syncSettingsFrame, 2, "Auto Open", "Secara otomatis membuka skrip pada setiap perubahan. Dapat mengganggu alur kerja Anda.", "AutoOpen", true, settings.updateCodePreview)
	autoRenewSwitch.SetEnabled(liveSyncSwitch.IsToggled())

	local blacklistSettingsFrame, nextLayoutOrder3 = createCollapsibleGroup(currentLayoutOrder, "Pengaturan Blacklist", mainFrame, true)
	currentLayoutOrder = nextLayoutOrder3

	local profileLabel = Instance.new("TextLabel")
	profileLabel.LayoutOrder = 1
	profileLabel.Text = "Blacklist Profiles:"
	profileLabel.Size = UDim2.new(1, 0, 0, 15)
	profileLabel.Font = Enum.Font.SourceSans
	profileLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	profileLabel.TextSize = 13
	profileLabel.TextXAlignment = Enum.TextXAlignment.Left
	profileLabel.BackgroundTransparency = 1
	profileLabel.Parent = blacklistSettingsFrame

	local profileFrame = Instance.new("Frame")
	profileFrame.LayoutOrder = 2
	profileFrame.Size = UDim2.new(1, 0, 0, 60)
	profileFrame.BackgroundTransparency = 1
	profileFrame.Parent = blacklistSettingsFrame

	local profileDropdown = Instance.new("TextButton")
	profileDropdown.Name = "ProfileDropdown"
	profileDropdown.Size = UDim2.new(1, 0, 0, 28)
	profileDropdown.Text = "  Default"
	profileDropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	profileDropdown.Font = Enum.Font.SourceSans
	profileDropdown.TextSize = 14
	profileDropdown.TextColor3 = Color3.fromRGB(220, 220, 220)
	profileDropdown.TextXAlignment = Enum.TextXAlignment.Left
	profileDropdown.Parent = profileFrame
	local profileDropdownCorner = Instance.new("UICorner")
	profileDropdownCorner.CornerRadius = UDim.new(0, 4)
	profileDropdownCorner.Parent = profileDropdown

	local profileNameInput = Instance.new("TextBox")
	profileNameInput.Name = "ProfileNameInput"
	profileNameInput.Size = UDim2.new(1, -120, 0, 28)
	profileNameInput.Position = UDim2.new(0, 0, 0, 32)
	profileNameInput.Text = ""
	profileNameInput.PlaceholderText = "Nama Profil Baru..."
	profileNameInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	profileNameInput.Font = Enum.Font.SourceSans
	profileNameInput.TextSize = 13
	profileNameInput.TextColor3 = Color3.fromRGB(200, 200, 200)
	profileNameInput.Parent = profileFrame
	local profileNameInputCorner = Instance.new("UICorner")
	profileNameInputCorner.CornerRadius = UDim.new(0, 4)
	profileNameInputCorner.Parent = profileNameInput

	local saveProfileButton = Instance.new("TextButton")
	saveProfileButton.Name = "SaveProfileButton"
	saveProfileButton.Size = UDim2.new(0, 55, 0, 28)
	saveProfileButton.Position = UDim2.new(1, -115, 0, 32)
	saveProfileButton.Text = "Simpan"
	saveProfileButton.BackgroundColor3 = Color3.fromRGB(80, 140, 80)
	saveProfileButton.Font = Enum.Font.SourceSansBold
	saveProfileButton.TextSize = 13
	saveProfileButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	saveProfileButton.Parent = profileFrame
	local saveProfileCorner = Instance.new("UICorner")
	saveProfileCorner.CornerRadius = UDim.new(0, 4)
	saveProfileCorner.Parent = saveProfileButton

	local deleteProfileButton = Instance.new("TextButton")
	deleteProfileButton.Name = "DeleteProfileButton"
	deleteProfileButton.Size = UDim2.new(0, 55, 0, 28)
	deleteProfileButton.Position = UDim2.new(1, -55, 0, 32)
	deleteProfileButton.Text = "Hapus"
	deleteProfileButton.BackgroundColor3 = Color3.fromRGB(180, 80, 80)
	deleteProfileButton.Font = Enum.Font.SourceSansBold
	deleteProfileButton.TextSize = 13
	deleteProfileButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	deleteProfileButton.Parent = profileFrame
	local deleteProfileCorner = Instance.new("UICorner")
	deleteProfileCorner.CornerRadius = UDim.new(0, 4)
	deleteProfileCorner.Parent = deleteProfileButton

	local blacklistLabel = Instance.new("TextLabel")
	blacklistLabel.LayoutOrder = 3
	blacklistLabel.Text = "Property Blacklist:"
	blacklistLabel.Size = UDim2.new(1, 0, 0, 15)
	blacklistLabel.Font = Enum.Font.SourceSans
	blacklistLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	blacklistLabel.TextSize = 13
	blacklistLabel.TextXAlignment = Enum.TextXAlignment.Left
	blacklistLabel.BackgroundTransparency = 1
	blacklistLabel.Parent = blacklistSettingsFrame

	local blacklistCheckboxes = {}

	local searchBox = Instance.new("TextBox")
	searchBox.Name = "PropertySearchBox"
	searchBox.LayoutOrder = 4
	searchBox.Size = UDim2.new(1, 0, 0, 28)
	searchBox.Font = Enum.Font.SourceSans
	searchBox.TextSize = 13
	searchBox.PlaceholderText = "Cari properti..."
	searchBox.TextColor3 = Color3.fromRGB(220, 220, 220)
	searchBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	searchBox.ClearTextOnFocus = false
	searchBox.Parent = blacklistSettingsFrame
	local searchBoxCorner = Instance.new("UICorner")
	searchBoxCorner.CornerRadius = UDim.new(0, 4)
	searchBoxCorner.Parent = searchBox

	local bulkActionFrame = Instance.new("Frame")
	bulkActionFrame.LayoutOrder = 5
	bulkActionFrame.Size = UDim2.new(1, 0, 0, 22)
	bulkActionFrame.BackgroundTransparency = 1
	bulkActionFrame.Parent = blacklistSettingsFrame

	local bulkActionListLayout = Instance.new("UIListLayout")
	bulkActionListLayout.FillDirection = Enum.FillDirection.Horizontal
	bulkActionListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	bulkActionListLayout.Padding = UDim.new(0, 8)
	bulkActionListLayout.Parent = bulkActionFrame

	local selectAllButton = Instance.new("TextButton")
	selectAllButton.Name = "SelectAllButton"
	selectAllButton.Size = UDim2.new(0, 120, 1, 0)
	selectAllButton.Text = "Pilih Semua"
	selectAllButton.Font = Enum.Font.SourceSans
	selectAllButton.TextSize = 13
	selectAllButton.TextColor3 = Color3.fromRGB(200, 220, 255)
	selectAllButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	selectAllButton.Parent = bulkActionFrame
	local selectAllCorner = Instance.new("UICorner")
	selectAllCorner.CornerRadius = UDim.new(0, 4)
	selectAllCorner.Parent = selectAllButton

	local allSelected = false
	selectAllButton.MouseButton1Click:Connect(function()
		allSelected = not allSelected
		for _, checkboxData in pairs(blacklistCheckboxes) do
			checkboxData.Toggle(allSelected)
		end
		if allSelected then
			selectAllButton.Text = "Batal Pilih Semua"
		else
			selectAllButton.Text = "Pilih Semua"
		end
		if settings.updateCodePreview then settings.updateCodePreview() end
	end)

	local blacklistFrame = Instance.new("ScrollingFrame")
	blacklistFrame.LayoutOrder = 6
	blacklistFrame.Size = UDim2.new(1, 0, 1, -367)
	blacklistFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	blacklistFrame.BorderSizePixel = 1
	blacklistFrame.BorderColor3 = Color3.fromRGB(50, 50, 50)
	blacklistFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	blacklistFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	blacklistFrame.ScrollBarThickness = 6
	blacklistFrame.Parent = blacklistSettingsFrame
	local blacklistCorner = Instance.new("UICorner")
	blacklistCorner.CornerRadius = UDim.new(0, 4)
	blacklistCorner.Parent = blacklistFrame

	local blacklistContainerLayout = Instance.new("UIListLayout")
	blacklistContainerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	blacklistContainerLayout.Padding = UDim.new(0, 2)
	blacklistContainerLayout.Parent = blacklistFrame

	-- Kelompokkan properti
	local groupedProps = {Common = {}}
	local propSet = {}
	for _, p in ipairs(settings.COMMON_PROPERTIES) do if not propSet[p] then table.insert(groupedProps.Common, p); propSet[p] = true end end
	for className, props in pairs(settings.PROPERTIES_BY_CLASS) do
		groupedProps[className] = {}
		for _, p in ipairs(props) do if not propSet[p] then table.insert(groupedProps[className], p); propSet[p] = true end end
	end

	local savedBlacklist = {}
	local savedBlacklistSetting = plugin:GetSetting("PropertyBlacklist")
	if savedBlacklistSetting then
		local success, decoded = pcall(function() return game:GetService("HttpService"):JSONDecode(savedBlacklistSetting) end)
		if success and type(decoded) == "table" then
			for _, propName in ipairs(decoded) do savedBlacklist[propName] = true end
		end
	else
		savedBlacklist["Position"] = true
		savedBlacklist["Size"] = true
	end

	local groupDataStore = {}

	local groupOrder = 0
	local groupKeys = {}
	for key in pairs(groupedProps) do table.insert(groupKeys, key) end
	table.sort(groupKeys, function(a, b)
		if a == "Common" then return true end
		if b == "Common" then return false end
		return a < b
	end)

	for _, groupName in ipairs(groupKeys) do
		local propsInGroup = groupedProps[groupName]
		if #propsInGroup == 0 then continue end
		table.sort(propsInGroup)
		groupOrder = groupOrder + 1

		local header = Instance.new("TextButton")
		header.Name = groupName .. "Header"
		header.LayoutOrder = groupOrder
		header.Size = UDim2.new(1, 0, 0, 26)
		header.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		header.Text = "  ▾ " .. groupName
		header.Font = Enum.Font.SourceSansBold
		header.TextSize = 14
		header.TextColor3 = Color3.fromRGB(200, 200, 200)
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.Parent = blacklistFrame
		local headerCorner = Instance.new("UICorner")
		headerCorner.CornerRadius = UDim.new(0, 3)
		headerCorner.Parent = header

		local contentFrame = Instance.new("Frame")
		contentFrame.Name = groupName .. "Content"
		contentFrame.LayoutOrder = groupOrder
		contentFrame.Size = UDim2.new(1, 0, 0, 0)
		contentFrame.AutomaticSize = Enum.AutomaticSize.Y
		contentFrame.BackgroundTransparency = 1
		contentFrame.ClipsDescendants = true
		contentFrame.Parent = blacklistFrame

		local contentLayout = Instance.new("UIListLayout")
		contentLayout.SortOrder = Enum.SortOrder.Name
		contentLayout.Parent = contentFrame

		local isExpanded = true
		header.MouseButton1Click:Connect(function()
			isExpanded = not isExpanded
			if header.Visible then
				contentFrame.Visible = isExpanded
			end
			header.Text = (isExpanded and "  ▾ " or "  ▸ ") .. groupName
		end)

		local rowsInGroup = {}
		local i = 0
		for _, propName in ipairs(propsInGroup) do
			i = i + 1
			local bgColor = (i % 2 == 0) and Color3.fromRGB(45, 45, 45) or Color3.fromRGB(50, 50, 50)

			local row = Instance.new("TextButton")
			row.Name = propName
			row.Size = UDim2.new(1, 0, 0, 24)
			row.BackgroundColor3 = bgColor
			row.BorderSizePixel = 0
			row.Text = "   " .. propName
			row.Font = Enum.Font.SourceSans
			row.TextSize = 14
			row.TextColor3 = Color3.fromRGB(220, 220, 220)
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.Parent = contentFrame
			table.insert(rowsInGroup, row)

			local isBlacklisted = savedBlacklist[propName] or false

			local function updateCheckboxVisuals()
				if isBlacklisted then
					row.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
					row.TextColor3 = Color3.fromRGB(255, 200, 200)
				else
					row.BackgroundColor3 = bgColor
					row.TextColor3 = Color3.fromRGB(220, 220, 220)
				end
			end

			row.MouseButton1Click:Connect(function()
				isBlacklisted = not isBlacklisted
				updateCheckboxVisuals()
				if settings.updateCodePreview then
					settings.updateCodePreview()
				end
			end)

			row.MouseEnter:Connect(function() if not isBlacklisted then row.BackgroundColor3 = bgColor:Lerp(Color3.fromRGB(255, 255, 255), 0.1) end end)
			row.MouseLeave:Connect(function() if not isBlacklisted then row.BackgroundColor3 = bgColor end end)

			blacklistCheckboxes[propName] = {
				IsBlacklisted = function() return isBlacklisted end,
				Button = row,
				Toggle = function(state)
					local changed = (isBlacklisted ~= state)
					isBlacklisted = state
					if changed then
						updateCheckboxVisuals()
					end
				end,
			}
			updateCheckboxVisuals()
		end

		groupDataStore[groupName] = {
			header = header,
			content = contentFrame,
			rows = rowsInGroup,
			isExpanded = function() return isExpanded end,
		}
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local searchText = searchBox.Text:lower()

		for groupName, groupData in pairs(groupDataStore) do
			local hasVisibleChildren = false
			for _, row in ipairs(groupData.rows) do
				local propName = row.Name:lower()
				local isVisible = searchText == "" or propName:find(searchText, 1, true)
				row.Visible = isVisible
				if isVisible then
					hasVisibleChildren = true
				end
			end

			groupData.header.Visible = hasVisibleChildren
			groupData.content.Visible = hasVisibleChildren and groupData.isExpanded()
		end
	end)

	local previewHeaderFrame = Instance.new("Frame")
	previewHeaderFrame.LayoutOrder = currentLayoutOrder
	currentLayoutOrder = currentLayoutOrder + 1
	previewHeaderFrame.Size = UDim2.new(1, 0, 0, 15)
	previewHeaderFrame.BackgroundTransparency = 1
	previewHeaderFrame.Parent = mainFrame

	local previewLabel = Instance.new("TextLabel")
	previewLabel.Text = "Live Code Preview: (Ctrl+C to Copy)"
	previewLabel.Size = UDim2.new(0, 0, 1, 0) -- Automatic size
	previewLabel.Font = Enum.Font.SourceSans
	previewLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	previewLabel.TextSize = 13
	previewLabel.TextXAlignment = Enum.TextXAlignment.Left
	previewLabel.BackgroundTransparency = 1
	previewLabel.AutomaticSize = Enum.AutomaticSize.X
	previewLabel.Parent = previewHeaderFrame

	local previewFrame = Instance.new("ScrollingFrame")
	previewFrame.LayoutOrder = currentLayoutOrder
	currentLayoutOrder = currentLayoutOrder + 1
	previewFrame.Size = UDim2.new(1, 0, 0, 200) -- Tinggi tetap untuk area pratinjau
	previewFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	previewFrame.BorderSizePixel = 1
	previewFrame.BorderColor3 = Color3.fromRGB(50, 50, 50)
	previewFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	previewFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	previewFrame.ScrollBarThickness = 6
	previewFrame.Parent = mainFrame
	local previewCorner = Instance.new("UICorner")
	previewCorner.CornerRadius = UDim.new(0, 4)
	previewCorner.Parent = previewFrame

	local codePreviewBox = Instance.new("TextBox")
	codePreviewBox.Name = "CodePreviewLabel" -- Keep the same name for compatibility
	codePreviewBox.RichText = true
	codePreviewBox.TextEditable = false
	codePreviewBox.MultiLine = true
	codePreviewBox.ClearTextOnFocus = false
	codePreviewBox.Font = Enum.Font.Code
	codePreviewBox.Text = "-- Pilih objek GUI untuk melihat pratinjau kode..."
	codePreviewBox.TextColor3 = Color3.fromRGB(200, 200, 200)
	codePreviewBox.TextSize = 13
	codePreviewBox.TextXAlignment = Enum.TextXAlignment.Left
	codePreviewBox.TextYAlignment = Enum.TextYAlignment.Top
	codePreviewBox.Size = UDim2.new(1, -12, 0, 0) -- Beri ruang untuk scrollbar
	codePreviewBox.Position = UDim2.new(0, 6, 0, 6)
	codePreviewBox.AutomaticSize = Enum.AutomaticSize.Y
	codePreviewBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	codePreviewBox.BorderSizePixel = 0
	codePreviewBox.Parent = previewFrame

	codePreviewBox:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		previewFrame.CanvasSize = UDim2.new(0, 0, 0, codePreviewBox.AbsoluteSize.Y + 12)
	end)

	local convertButton = Instance.new("TextButton")
	convertButton.Name = "ConvertButton"
	convertButton.LayoutOrder = currentLayoutOrder
	currentLayoutOrder = currentLayoutOrder + 1
	convertButton.Text = "Convert"
	convertButton.Size = UDim2.new(1, 0, 0, 32)
	convertButton.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
	convertButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	convertButton.Font = Enum.Font.SourceSansBold
	convertButton.TextSize = 16
	convertButton.Parent = mainFrame
	local convertCorner = Instance.new("UICorner")
	convertCorner.CornerRadius = UDim.new(0, 4)
	convertCorner.Parent = convertButton
	local convertStroke = Instance.new("UIStroke")
	convertStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	convertStroke.Color = Color3.fromRGB(120, 160, 240)
	convertStroke.Thickness = 1
	convertStroke.Parent = convertButton
	local convertGradient = Instance.new("UIGradient")
	convertGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 130, 210)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 110, 190)),
	})
	convertGradient.Rotation = 90
	convertGradient.Parent = convertButton

	local exampleCodeButton = Instance.new("TextButton")
	exampleCodeButton.Name = "ExampleCodeButton"
	exampleCodeButton.LayoutOrder = currentLayoutOrder
	currentLayoutOrder = currentLayoutOrder + 1
	exampleCodeButton.Text = "Get Example Code"
	exampleCodeButton.Size = UDim2.new(1, 0, 0, 28)
	exampleCodeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	exampleCodeButton.TextColor3 = Color3.fromRGB(220, 220, 220)
	exampleCodeButton.Font = Enum.Font.SourceSans
	exampleCodeButton.TextSize = 14
	exampleCodeButton.Parent = mainFrame
	local exampleCorner = Instance.new("UICorner")
	exampleCorner.CornerRadius = UDim.new(0, 4)
	exampleCorner.Parent = exampleCodeButton
	local exampleStroke = Instance.new("UIStroke")
	exampleStroke.Color = Color3.fromRGB(80, 80, 80)
	exampleStroke.Thickness = 1
	exampleStroke.Parent = exampleCodeButton

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.LayoutOrder = currentLayoutOrder
	currentLayoutOrder = currentLayoutOrder + 1
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

	mainListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		mainFrame.CanvasSize = UDim2.new(0, 0, 0, mainListLayout.AbsoluteContentSize.Y)
	end)

	saveProfileButton.MouseButton1Click:Connect(function()
		local name = profileNameInput.Text
		if name and name ~= "" then
			settings.saveProfile(name)
			profileNameInput.Text = ""
		end
	end)

	deleteProfileButton.MouseButton1Click:Connect(function()
		settings.deleteProfile(settings.getActiveProfile())
	end)

	local dropdownFrame = Instance.new("ScrollingFrame")
	dropdownFrame.Name = "DropdownFrame"
	dropdownFrame.Size = UDim2.new(1, 0, 0, 100)
	dropdownFrame.Position = UDim2.new(0, 0, 0, 28)
	dropdownFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	dropdownFrame.BorderSizePixel = 0
	dropdownFrame.Visible = false
	dropdownFrame.ZIndex = 2
	dropdownFrame.ScrollBarThickness = 5
	dropdownFrame.Parent = profileDropdown
	local dropdownListLayout = Instance.new("UIListLayout")
	dropdownListLayout.Parent = dropdownFrame

	local function updateProfileDropdown(profiles, activeProfile)
		profileDropdown.Text = "  " .. activeProfile
		dropdownFrame.Visible = false
		for _, child in ipairs(dropdownFrame:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end

		local profileNames = {}
		for name in pairs(profiles) do table.insert(profileNames, name) end
		table.sort(profileNames)

		for _, name in ipairs(profileNames) do
			local option = Instance.new("TextButton")
			option.Name = name
			option.Size = UDim2.new(1, 0, 0, 28)
			option.Text = "  " .. name
			option.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
			option.Font = Enum.Font.SourceSans
			option.TextSize = 14
			option.TextColor3 = Color3.fromRGB(220, 220, 220)
			option.TextXAlignment = Enum.TextXAlignment.Left
			option.Parent = dropdownFrame
			option.MouseButton1Click:Connect(function()
				settings.applyProfile(name)
				dropdownFrame.Visible = false
			end)
		end
		dropdownFrame.CanvasSize = UDim2.new(0,0,0, #profileNames * 28)
	end

	profileDropdown.MouseButton1Click:Connect(function()
		dropdownFrame.Visible = not dropdownFrame.Visible
	end)

	return {
		SelectionLabel = selectionLabel,
		ScriptTypeButton = scriptTypeButton,
		BlacklistCheckboxes = blacklistCheckboxes,
		updateProfileDropdown = updateProfileDropdown,
		IsCommentsEnabled = commentsSwitch.IsToggled,
		IsOverwriteEnabled = overwriteSwitch.IsToggled,
		IsLiveSyncEnabled = liveSyncSwitch.IsToggled,
		IsAutoOpenEnabled = autoRenewSwitch.IsToggled,
		ConvertButton = convertButton,
		ExampleCodeButton = exampleCodeButton,
		StatusLabel = statusLabel,
		CodePreviewLabel = codePreviewBox,
		SelectAllButton = selectAllButton,
		IgnoreButton = ignoreButton,
		setBlacklistState = function(propName, shouldBeBlacklisted)
			local checkboxData = blacklistCheckboxes[propName]
			if checkboxData and checkboxData.IsBlacklisted() ~= shouldBeBlacklisted then
				checkboxData.Toggle()
			end
		end,
	}
end

return UI
