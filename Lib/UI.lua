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
	ignoreButton.Tooltip = "Jika dicentang, objek ini dan semua turunannya akan diabaikan selama proses konversi."
	local ignoreCorner = Instance.new("UICorner")
	ignoreCorner.CornerRadius = UDim.new(0, 4)
	ignoreCorner.Parent = ignoreButton

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
	scriptTypeButton.TextColor3 = Color3.fromRGB(220, 220, 220)
	scriptTypeButton.Font = Enum.Font.SourceSans
	scriptTypeButton.TextSize = 14
	scriptTypeButton.Parent = mainFrame
	scriptTypeButton.Tooltip = "ModuleScript menghasilkan kode yang dapat digunakan kembali. LocalScript akan berjalan secara otomatis untuk pemain."
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
	local function createToggleSwitch(layoutOrder, text, tooltip, settingKey, defaultValue, callback)
		local savedValue = plugin:GetSetting(settingKey)
		local isEnabled = (savedValue == nil) and defaultValue or savedValue

		local container = Instance.new("Frame")
		container.LayoutOrder = layoutOrder
		container.Size = UDim2.new(1, 0, 0, 28)
		container.BackgroundTransparency = 1
		container.Parent = mainFrame
		container.Tooltip = tooltip

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
			local goalPos, trackColor
			if isEnabled then
				goalPos = UDim2.new(1, -18, 0.5, -8) -- Kanan
				trackColor = Color3.fromRGB(80, 160, 80) -- Hijau
			else
				goalPos = UDim2.new(0, 2, 0.5, -8) -- Kiri
				trackColor = Color3.fromRGB(180, 80, 80) -- Merah
			end

			if isAnimated then
				game:GetService("TweenService"):Create(switchKnob, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Position = goalPos}):Play()
				game:GetService("TweenService"):Create(switchTrack, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = trackColor}):Play()
			else
				switchKnob.Position = goalPos
				switchTrack.BackgroundColor3 = trackColor
			end
		end

		clickDetector.MouseButton1Click:Connect(function()
			isEnabled = not isEnabled
			updateVisuals(true)
			if callback then callback(isEnabled) end
		end)

		updateVisuals(false) -- Atur status visual awal

		return container, function() return isEnabled end
	end

	-- Buat sakelar geser menggunakan fungsi pembantu baru
	local _, isCommentsEnabled = createToggleSwitch(6, "Trace Comments", "Menambahkan komentar ke kode yang dihasilkan yang melacak objek asli.", "AddTraceComments", true)
	local _, isOverwriteEnabled = createToggleSwitch(7, "Overwrite Existing", "Jika diaktifkan, menimpa skrip yang ada dengan nama yang sama. Kode kustom Anda akan dipertahankan.", "OverwriteExisting", true)
	local _, isLiveSyncEnabled = createToggleSwitch(8, "Live Sync", "Secara otomatis memperbarui skrip saat Anda mengedit GUI sumber secara real-time.", "LiveSyncEnabled", false, function(enabled)
		if not enabled then
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
	local searchCorner = Instance.new("UICorner")
	searchCorner.CornerRadius = UDim.new(0, 4)
	searchCorner.Parent = searchBox

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
	selectAllButton.Text = "Hapus Semua"
	selectAllButton.Font = Enum.Font.SourceSans
	selectAllButton.TextSize = 13
	selectAllButton.TextColor3 = Color3.fromRGB(200, 220, 255)
	selectAllButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	selectAllButton.Parent = bulkActionFrame
	selectAllButton.Tooltip = "Menghapus semua properti yang terlihat dari daftar hitam (membatalkan centang)."
	local selectAllCorner = Instance.new("UICorner")
	selectAllCorner.CornerRadius = UDim.new(0, 4)
	selectAllCorner.Parent = selectAllButton

	local deselectAllButton = Instance.new("TextButton")
	deselectAllButton.Name = "DeselectAllButton"
	deselectAllButton.Size = UDim2.new(0, 100, 1, 0)
	deselectAllButton.Text = "Tambah Semua"
	deselectAllButton.Font = Enum.Font.SourceSans
	deselectAllButton.TextSize = 13
	deselectAllButton.TextColor3 = Color3.fromRGB(255, 200, 200)
	deselectAllButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	deselectAllButton.Parent = bulkActionFrame
	deselectAllButton.Tooltip = "Menambahkan semua properti yang terlihat ke daftar hitam (mencentang)."
	local deselectAllCorner = Instance.new("UICorner")
	deselectAllCorner.CornerRadius = UDim.new(0, 4)
	deselectAllCorner.Parent = deselectAllButton

	local blacklistFrame = Instance.new("ScrollingFrame")
	blacklistFrame.LayoutOrder = 12
	blacklistFrame.Size = UDim2.new(1, 0, 1, -355) -- Adjusted size for search box and buttons
	blacklistFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	blacklistFrame.BorderSizePixel = 1
	blacklistFrame.BorderColor3 = Color3.fromRGB(50, 50, 50)
	blacklistFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	blacklistFrame.ScrollBarThickness = 6
	blacklistFrame.Parent = mainFrame
	local blacklistCorner = Instance.new("UICorner")
	blacklistCorner.CornerRadius = UDim.new(0, 4)
	blacklistCorner.Parent = blacklistFrame

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
		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 3)
		rowCorner.Parent = row

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

		row.MouseEnter:Connect(function()
			if not isBlacklisted then
				row.BackgroundColor3 = bgColor:Lerp(Color3.fromRGB(255, 255, 255), 0.1)
			end
		end)

		row.MouseLeave:Connect(function()
			if not isBlacklisted then
				row.BackgroundColor3 = bgColor
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
	convertButton.Tooltip = "Mengonversi objek GUI yang dipilih menjadi skrip Luau menggunakan pengaturan saat ini."
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
	exampleCodeButton.LayoutOrder = 14
	exampleCodeButton.Text = "Get Example Code"
	exampleCodeButton.Size = UDim2.new(1, 0, 0, 28)
	exampleCodeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	exampleCodeButton.TextColor3 = Color3.fromRGB(220, 220, 220)
	exampleCodeButton.Font = Enum.Font.SourceSans
	exampleCodeButton.TextSize = 14
	exampleCodeButton.Parent = mainFrame
	exampleCodeButton.Tooltip = "Membuat skrip contoh yang menunjukkan cara memuat dan menggunakan ModuleScript yang dihasilkan."
	local exampleCorner = Instance.new("UICorner")
	exampleCorner.CornerRadius = UDim.new(0, 4)
	exampleCorner.Parent = exampleCodeButton
	local exampleStroke = Instance.new("UIStroke")
	exampleStroke.Color = Color3.fromRGB(80, 80, 80)
	exampleStroke.Thickness = 1
	exampleStroke.Parent = exampleCodeButton

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

	return {
		SelectionLabel = selectionLabel,
		ScriptTypeButton = scriptTypeButton,
		BlacklistCheckboxes = blacklistCheckboxes,
		IsCommentsEnabled = isCommentsEnabled,
		IsOverwriteEnabled = isOverwriteEnabled,
		IsLiveSyncEnabled = isLiveSyncEnabled,
		ConvertButton = convertButton,
		ExampleCodeButton = exampleCodeButton,
		StatusLabel = statusLabel,
		SearchBox = searchBox,
		SelectAllButton = selectAllButton,
		DeselectAllButton = deselectAllButton,
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
