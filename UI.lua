-- Lib/UI.lua
-- Modul untuk membuat antarmuka pengguna (UI) plugin.

local UI = {}

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

local function createSavePresetModal(parent)
	local modalFrame = Instance.new("Frame")
	modalFrame.Name = "SavePresetModal"
	modalFrame.Size = UDim2.new(0, 300, 0, 150)
	modalFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
	modalFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	modalFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	modalFrame.BorderSizePixel = 1
	modalFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
	modalFrame.Visible = false
	modalFrame.ZIndex = 11
	modalFrame.Parent = parent

	local modalCorner = Instance.new("UICorner")
	modalCorner.CornerRadius = UDim.new(0, 6)
	modalCorner.Parent = modalFrame

	local modalLayout = Instance.new("UIListLayout")
	modalLayout.Padding = UDim.new(0, 10)
	modalLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	modalLayout.SortOrder = Enum.SortOrder.LayoutOrder
	modalLayout.Parent = modalFrame

	local modalPadding = Instance.new("UIPadding")
	modalPadding.PaddingTop = UDim.new(0, 10)
	modalPadding.PaddingLeft = UDim.new(0, 10)
	modalPadding.PaddingRight = UDim.new(0, 10)
	modalPadding.Parent = modalFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.LayoutOrder = 1
	titleLabel.Text = "Simpan Preset Konfigurasi"
	titleLabel.Size = UDim2.new(1, 0, 0, 30)
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	titleLabel.TextSize = 16
	titleLabel.BackgroundTransparency = 1
	titleLabel.Parent = modalFrame

	local nameTextBox = Instance.new("TextBox")
	nameTextBox.Name = "PresetNameInput"
	nameTextBox.LayoutOrder = 2
	nameTextBox.Text = ""
	nameTextBox.PlaceholderText = "Nama Preset Baru"
	nameTextBox.Size = UDim2.new(1, 0, 0, 30)
	nameTextBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	nameTextBox.TextColor3 = Color3.fromRGB(200, 200, 200)
	nameTextBox.Font = Enum.Font.SourceSans
	nameTextBox.TextSize = 14
	nameTextBox.Parent = modalFrame
	local nameCorner = Instance.new("UICorner")
	nameCorner.CornerRadius = UDim.new(0, 4)
	nameCorner.Parent = nameTextBox

	local buttonFrame = Instance.new("Frame")
	buttonFrame.LayoutOrder = 3
	buttonFrame.Size = UDim2.new(1, 0, 0, 30)
	buttonFrame.BackgroundTransparency = 1
	buttonFrame.Parent = modalFrame
	local buttonLayout = Instance.new("UIListLayout")
	buttonLayout.FillDirection = Enum.FillDirection.Horizontal
	buttonLayout.Padding = UDim.new(0, 10)
	buttonLayout.Parent = buttonFrame

	local saveButton = Instance.new("TextButton")
	saveButton.Name = "ConfirmSaveButton"
	saveButton.Size = UDim2.new(0.5, -5, 1, 0)
	saveButton.Text = "Simpan"
	saveButton.BackgroundColor3 = Color3.fromRGB(80, 140, 80)
	saveButton.Parent = buttonFrame
	local saveCorner = Instance.new("UICorner")
	saveCorner.CornerRadius = UDim.new(0, 4)
	saveCorner.Parent = saveButton

	local cancelButton = Instance.new("TextButton")
	cancelButton.Name = "CancelSaveButton"
	cancelButton.Size = UDim2.new(0.5, -5, 1, 0)
	cancelButton.Text = "Batal"
	cancelButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	cancelButton.Parent = buttonFrame
	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 4)
	cancelCorner.Parent = cancelButton

	return {
		Modal = modalFrame,
		NameInput = nameTextBox,
		SaveButton = saveButton,
		CancelButton = cancelButton,
	}
end

local function createLoadPresetModal(parent)
	local modalFrame = Instance.new("Frame")
	modalFrame.Name = "LoadPresetModal"
	modalFrame.Size = UDim2.new(0, 350, 0, 400)
	modalFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
	modalFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	modalFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	modalFrame.BorderSizePixel = 1
	modalFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
	modalFrame.Visible = false
	modalFrame.ZIndex = 11
	modalFrame.Parent = parent
	local modalCorner = Instance.new("UICorner")
	modalCorner.CornerRadius = UDim.new(0, 6)
	modalCorner.Parent = modalFrame

	local modalPadding = Instance.new("UIPadding")
	modalPadding.PaddingTop = UDim.new(0, 10)
	modalPadding.PaddingLeft = UDim.new(0, 10)
	modalPadding.PaddingRight = UDim.new(0, 10)
	modalPadding.Parent = modalFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Text = "Muat Preset Konfigurasi"
	titleLabel.Size = UDim2.new(1, 0, 0, 30)
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	titleLabel.TextSize = 16
	titleLabel.BackgroundTransparency = 1
	titleLabel.Parent = modalFrame

	local listFrame = Instance.new("ScrollingFrame")
	listFrame.Name = "PresetListFrame"
	listFrame.Size = UDim2.new(1, 0, 1, -80)
	listFrame.Position = UDim2.new(0, 0, 0, 40)
	listFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listFrame.CanvasSize = UDim2.new(0,0,0,0)
	listFrame.ScrollBarThickness = 5
	listFrame.Parent = modalFrame
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 4)
	listLayout.Parent = listFrame
	local listCorner = Instance.new("UICorner")
	listCorner.CornerRadius = UDim.new(0, 4)
	listCorner.Parent = listFrame

	local noPresetsLabel = Instance.new("TextLabel")
	noPresetsLabel.Name = "NoPresetsLabel"
	noPresetsLabel.Text = "Tidak ada preset yang disimpan."
	noPresetsLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	noPresetsLabel.Font = Enum.Font.SourceSansItalic
	noPresetsLabel.TextSize = 14
	noPresetsLabel.Size = UDim2.new(1, 0, 0, 30)
	noPresetsLabel.BackgroundTransparency = 1
	noPresetsLabel.Visible = false
	noPresetsLabel.Parent = listFrame

	local buttonFrame = Instance.new("Frame")
	buttonFrame.Size = UDim2.new(1, 0, 0, 30)
	buttonFrame.Position = UDim2.new(0, 0, 1, -30)
	buttonFrame.BackgroundTransparency = 1
	buttonFrame.Parent = modalFrame

	local cancelButton = Instance.new("TextButton")
	cancelButton.Name = "CancelLoadButton"
	cancelButton.Size = UDim2.new(1, 0, 1, 0)
	cancelButton.Text = "Tutup"
	cancelButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	cancelButton.Parent = buttonFrame
	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 4)
	cancelCorner.Parent = cancelButton

	return {
		Modal = modalFrame,
		ListFrame = listFrame,
		NoPresetsLabel = noPresetsLabel,
		CancelButton = cancelButton,
	}
end

local function createPasteStyleModal(parent)
	local modalFrame = Instance.new("Frame")
	modalFrame.Name = "PasteStyleModal"
	modalFrame.Size = UDim2.new(0, 350, 0, 400)
	modalFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
	modalFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	modalFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	modalFrame.BorderSizePixel = 1
	modalFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
	modalFrame.Visible = false
	modalFrame.ZIndex = 12
	modalFrame.Parent = parent
	local modalCorner = Instance.new("UICorner")
	modalCorner.CornerRadius = UDim.new(0, 6)
	modalCorner.Parent = modalFrame

	local modalPadding = Instance.new("UIPadding")
	modalPadding.PaddingTop = UDim.new(0, 10)
	modalPadding.PaddingLeft = UDim.new(0, 10)
	modalPadding.PaddingRight = UDim.new(0, 10)
	modalPadding.Parent = modalFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Text = "Pilih Gaya untuk Diterapkan"
	titleLabel.Size = UDim2.new(1, 0, 0, 30)
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	titleLabel.TextSize = 16
	titleLabel.BackgroundTransparency = 1
	titleLabel.Parent = modalFrame

	local listFrame = Instance.new("ScrollingFrame")
	listFrame.Name = "PropertyListFrame"
	listFrame.Size = UDim2.new(1, 0, 1, -80)
	listFrame.Position = UDim2.new(0, 0, 0, 40)
	listFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listFrame.CanvasSize = UDim2.new(0,0,0,0)
	listFrame.ScrollBarThickness = 5
	listFrame.Parent = modalFrame
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 2)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = listFrame
	local listCorner = Instance.new("UICorner")
	listCorner.CornerRadius = UDim.new(0, 4)
	listCorner.Parent = listFrame

	local buttonFrame = Instance.new("Frame")
	buttonFrame.Size = UDim2.new(1, 0, 0, 30)
	buttonFrame.Position = UDim2.new(0, 0, 1, -30)
	buttonFrame.BackgroundTransparency = 1
	buttonFrame.Parent = modalFrame
	local buttonLayout = Instance.new("UIListLayout")
	buttonLayout.FillDirection = Enum.FillDirection.Horizontal
	buttonLayout.Padding = UDim.new(0, 10)
	buttonLayout.Parent = buttonFrame

	local applyButton = Instance.new("TextButton")
	applyButton.Name = "ApplyButton"
	applyButton.Size = UDim2.new(0.5, -5, 1, 0)
	applyButton.Text = "Terapkan"
	applyButton.BackgroundColor3 = Color3.fromRGB(80, 140, 80)
	applyButton.Parent = buttonFrame
	local applyCorner = Instance.new("UICorner")
	applyCorner.CornerRadius = UDim.new(0, 4)
	applyCorner.Parent = applyButton

	local cancelButton = Instance.new("TextButton")
	cancelButton.Name = "CancelButton"
	cancelButton.Size = UDim2.new(0.5, -5, 1, 0)
	cancelButton.Text = "Batal"
	cancelButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	cancelButton.Parent = buttonFrame
	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 4)
	cancelCorner.Parent = cancelButton

	return {
		Modal = modalFrame,
		ListFrame = listFrame,
		ApplyButton = applyButton,
		CancelButton = cancelButton,
	}
end

function UI.create(configWidget, plugin, settings)
	local mainFrame = Instance.new("ScrollingFrame")
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(41, 42, 45)
	mainFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	mainFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	mainFrame.ScrollBarThickness = 7
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = configWidget

	local savePresetModalControls = createSavePresetModal(mainFrame)
	local loadPresetModalControls = createLoadPresetModal(mainFrame)
	local pasteStyleModalControls = createPasteStyleModal(mainFrame)

	local importExportModal = Instance.new("Frame")
	importExportModal.Name = "ImportExportModal"
	importExportModal.Size = UDim2.new(1, 0, 1, 0)
	importExportModal.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	importExportModal.BackgroundTransparency = 0.5
	importExportModal.Visible = false
	importExportModal.ZIndex = 10
	importExportModal.Parent = mainFrame

	local modalContent = Instance.new("Frame")
	modalContent.Size = UDim2.new(1, -20, 0, 200)
	modalContent.Position = UDim2.new(0.5, 0, 0.5, 0)
	modalContent.AnchorPoint = Vector2.new(0.5, 0.5)
	modalContent.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	modalContent.Parent = importExportModal
	local modalCorner = Instance.new("UICorner")
	modalCorner.CornerRadius = UDim.new(0, 4)
	modalCorner.Parent = modalContent

	local modalTitle = Instance.new("TextLabel")
	modalTitle.Size = UDim2.new(1, 0, 0, 30)
	modalTitle.Text = "Impor/Ekspor Profil"
	modalTitle.Font = Enum.Font.SourceSansBold
	modalTitle.TextSize = 16
	modalTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
	modalTitle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	modalTitle.Parent = modalContent

	local modalTextBox = Instance.new("TextBox")
	modalTextBox.Name = "ModalTextBox"
	modalTextBox.Size = UDim2.new(1, -20, 1, -80)
	modalTextBox.Position = UDim2.new(0.5, 0, 0.5, 0)
	modalTextBox.AnchorPoint = Vector2.new(0.5, 0.5)
	modalTextBox.MultiLine = true
	modalTextBox.TextXAlignment = Enum.TextXAlignment.Left
	modalTextBox.TextYAlignment = Enum.TextYAlignment.Top
	modalTextBox.ClearTextOnFocus = false
	modalTextBox.Font = Enum.Font.Code
	modalTextBox.TextSize = 13
	modalTextBox.Parent = modalContent

	local confirmButton = Instance.new("TextButton")
	confirmButton.Name = "ConfirmButton"
	confirmButton.Size = UDim2.new(0.5, -15, 0, 30)
	confirmButton.Position = UDim2.new(0, 10, 1, -40)
	confirmButton.Text = "Konfirmasi"
	confirmButton.BackgroundColor3 = Color3.fromRGB(80, 140, 80)
	confirmButton.Parent = modalContent

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0.5, -15, 0, 30)
	closeButton.Position = UDim2.new(0.5, 5, 1, -40)
	closeButton.Text = "Tutup"
	closeButton.BackgroundColor3 = Color3.fromRGB(180, 80, 80)
	closeButton.Parent = modalContent

	local profileManagerModal = Instance.new("Frame")
	profileManagerModal.Name = "ProfileManagerModal"
	profileManagerModal.Size = UDim2.new(1, 0, 1, 0)
	profileManagerModal.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	profileManagerModal.BackgroundTransparency = 0.5
	profileManagerModal.Visible = false
	profileManagerModal.ZIndex = 10
	profileManagerModal.Parent = mainFrame

	local pmContent = Instance.new("Frame")
	pmContent.Size = UDim2.new(1, -40, 1, -100)
	pmContent.Position = UDim2.new(0.5, 0, 0.5, 0)
	pmContent.AnchorPoint = Vector2.new(0.5, 0.5)
	pmContent.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	pmContent.Parent = profileManagerModal
	local pmCorner = Instance.new("UICorner")
	pmCorner.CornerRadius = UDim.new(0, 4)
	pmCorner.Parent = pmContent

	local pmTitle = Instance.new("TextLabel")
	pmTitle.Size = UDim2.new(1, 0, 0, 30)
	pmTitle.Text = "Manajemen Profil"
	pmTitle.Font = Enum.Font.SourceSansBold
	pmTitle.TextSize = 16
	pmTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
	pmTitle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	pmTitle.Parent = pmContent

	local pmProfileList = Instance.new("ScrollingFrame")
	pmProfileList.Name = "ProfileListFrame"
	pmProfileList.Size = UDim2.new(1, -20, 1, -160)
	pmProfileList.Position = UDim2.new(0.5, 0, 0, 40)
	pmProfileList.AnchorPoint = Vector2.new(0.5, 0)
	pmProfileList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	pmProfileList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	pmProfileList.CanvasSize = UDim2.new(0,0,0,0)
	pmProfileList.ScrollBarThickness = 5
	pmProfileList.Parent = pmContent
	local pmListLayout = Instance.new("UIListLayout")
	pmListLayout.Padding = UDim.new(0, 4)
	pmListLayout.Parent = pmProfileList

	local pmBottomFrame = Instance.new("Frame")
	pmBottomFrame.Size = UDim2.new(1, -20, 0, 110)
	pmBottomFrame.Position = UDim2.new(0.5, 0, 1, -115)
	pmBottomFrame.AnchorPoint = Vector2.new(0.5, 0)
	pmBottomFrame.BackgroundTransparency = 1
	pmBottomFrame.Parent = pmContent

	local pmNameInput = Instance.new("TextBox")
	pmNameInput.Name = "ProfileNameInput"
	pmNameInput.Size = UDim2.new(1, 0, 0, 28)
	pmNameInput.Position = UDim2.new(0, 0, 0, 5)
	pmNameInput.Text = ""
	pmNameInput.PlaceholderText = "Nama Profil Baru/Simpan..."
	pmNameInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	pmNameInput.Font = Enum.Font.SourceSans
	pmNameInput.TextSize = 13
	pmNameInput.TextColor3 = Color3.fromRGB(200, 200, 200)
	pmNameInput.Parent = pmBottomFrame
	local pmNameInputCorner = Instance.new("UICorner")
	pmNameInputCorner.CornerRadius = UDim.new(0, 4)
	pmNameInputCorner.Parent = pmNameInput

	local pmButtonContainer = Instance.new("Frame")
	pmButtonContainer.Size = UDim2.new(1, 0, 0, 60)
	pmButtonContainer.Position = UDim2.new(0, 0, 0, 40)
	pmButtonContainer.BackgroundTransparency = 1
	pmButtonContainer.Parent = pmBottomFrame

	local pmButtonLayout = Instance.new("UIGridLayout")
	pmButtonLayout.CellSize = UDim2.new(0.5, -5, 0.5, -5)
	pmButtonLayout.FillDirection = Enum.FillDirection.Horizontal
	pmButtonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	pmButtonLayout.SortOrder = Enum.SortOrder.LayoutOrder
	pmButtonLayout.Parent = pmButtonContainer

	local function createProfileManagerButton(text, color, order, name)
		local button = Instance.new("TextButton")
		button.Name = name
		button.LayoutOrder = order
		button.Text = text
		button.BackgroundColor3 = color
		button.Font = Enum.Font.SourceSansBold
		button.TextSize = 13
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.Parent = pmButtonContainer
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = button
		return button
	end

	local pmSaveButton = createProfileManagerButton("Simpan", Color3.fromRGB(80, 140, 80), 1, "SaveProfileButton")
	local pmDeleteButton = createProfileManagerButton("Hapus", Color3.fromRGB(180, 80, 80), 2, "DeleteProfileButton")
	local pmImportButton = createProfileManagerButton("Impor", Color3.fromRGB(80, 120, 200), 3, "ImportProfileButton")
	local pmExportButton = createProfileManagerButton("Ekspor", Color3.fromRGB(60, 60, 60), 4, "ExportProfileButton")

	local pmCloseButton = Instance.new("TextButton")
	pmCloseButton.Name = "ProfileManagerCloseButton"
	pmCloseButton.Size = UDim2.new(1, 0, 0, 30)
	pmCloseButton.Position = UDim2.new(0.5, 0, 1, -30)
	pmCloseButton.AnchorPoint = Vector2.new(0.5, 1)
	pmCloseButton.Text = "Tutup"
	pmCloseButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	pmCloseButton.Parent = pmContent

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

	local presetSettingsFrame, nextLayoutOrderPreset = createCollapsibleGroup(4, "Preset Konfigurasi", mainFrame, true)
	presetSettingsFrame.LayoutOrder = 4

	local activePresetLabel = Instance.new("TextLabel")
	activePresetLabel.Name = "ActivePresetLabel"
	activePresetLabel.LayoutOrder = 1
	activePresetLabel.Text = "Preset Aktif: Default"
	activePresetLabel.Size = UDim2.new(1, 0, 0, 18)
	activePresetLabel.Font = Enum.Font.SourceSansItalic
	activePresetLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	activePresetLabel.TextSize = 13
	activePresetLabel.BackgroundTransparency = 1
	activePresetLabel.TextXAlignment = Enum.TextXAlignment.Left
	activePresetLabel.Parent = presetSettingsFrame

	local presetButtonFrame = Instance.new("Frame")
	presetButtonFrame.LayoutOrder = 2
	presetButtonFrame.Size = UDim2.new(1, 0, 0, 28)
	presetButtonFrame.BackgroundTransparency = 1
	presetButtonFrame.Parent = presetSettingsFrame
	local presetButtonLayout = Instance.new("UIListLayout")
	presetButtonLayout.FillDirection = Enum.FillDirection.Horizontal
	presetButtonLayout.Padding = UDim.new(0, 5)
	presetButtonLayout.Parent = presetButtonFrame

	local loadPresetButton = Instance.new("TextButton")
	loadPresetButton.Name = "LoadPresetButton"
	loadPresetButton.Size = UDim2.new(0.5, -2.5, 1, 0)
	loadPresetButton.Text = "Muat Preset..."
	loadPresetButton.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
	loadPresetButton.Parent = presetButtonFrame
	local loadPresetCorner = Instance.new("UICorner")
	loadPresetCorner.CornerRadius = UDim.new(0, 4)
	loadPresetCorner.Parent = loadPresetButton

	local savePresetButton = Instance.new("TextButton")
	savePresetButton.Name = "SavePresetButton"
	savePresetButton.Size = UDim2.new(0.5, -2.5, 1, 0)
	savePresetButton.Text = "Simpan Preset..."
	savePresetButton.BackgroundColor3 = Color3.fromRGB(80, 140, 80)
	savePresetButton.Parent = presetButtonFrame
	local savePresetCorner = Instance.new("UICorner")
	savePresetCorner.CornerRadius = UDim.new(0, 4)
	savePresetCorner.Parent = savePresetButton

	local designToolsFrame, nextLayoutOrderDesign = createCollapsibleGroup(5, "Alat Desain", mainFrame, true)
	designToolsFrame.LayoutOrder = 5

	local styleButtonFrame = Instance.new("Frame")
	styleButtonFrame.Size = UDim2.new(1, 0, 0, 28)
	styleButtonFrame.BackgroundTransparency = 1
	styleButtonFrame.Parent = designToolsFrame
	local styleButtonLayout = Instance.new("UIListLayout")
	styleButtonLayout.FillDirection = Enum.FillDirection.Horizontal
	styleButtonLayout.Padding = UDim.new(0, 5)
	styleButtonLayout.Parent = styleButtonFrame

	local copyStyleButton = Instance.new("TextButton")
	copyStyleButton.Name = "CopyStyleButton"
	copyStyleButton.Size = UDim2.new(1/3, -3.3, 1, 0)
	copyStyleButton.Text = "Salin Gaya"
	copyStyleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	copyStyleButton.Parent = styleButtonFrame
	local copyStyleCorner = Instance.new("UICorner")
	copyStyleCorner.CornerRadius = UDim.new(0, 4)
	copyStyleCorner.Parent = copyStyleButton

	local pasteStyleButton = Instance.new("TextButton")
	pasteStyleButton.Name = "PasteStyleButton"
	pasteStyleButton.Size = UDim2.new(1/3, -3.3, 1, 0)
	pasteStyleButton.Text = "Tempel Gaya"
	pasteStyleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60) -- Disabled color
	pasteStyleButton.TextColor3 = Color3.fromRGB(150, 150, 150)
	pasteStyleButton.Parent = styleButtonFrame
	local pasteStyleCorner = Instance.new("UICorner")
	pasteStyleCorner.CornerRadius = UDim.new(0, 4)
	pasteStyleCorner.Parent = pasteStyleButton

	local insertComponentButton = Instance.new("TextButton")
	insertComponentButton.Name = "InsertComponentButton"
	insertComponentButton.Size = UDim2.new(1/3, -3.3, 1, 0)
	insertComponentButton.Text = "Sisipkan Kode"
	insertComponentButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	insertComponentButton.Parent = styleButtonFrame
	local insertComponentCorner = Instance.new("UICorner")
	insertComponentCorner.CornerRadius = UDim.new(0, 4)
	insertComponentCorner.Parent = insertComponentButton

	local ignoreButton = Instance.new("TextButton")
	ignoreButton.Name = "IgnoreButton"
	ignoreButton.LayoutOrder = 6
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

	local currentLayoutOrder = 7

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

		control.SetToggled = function(newState, andFireCallback)
			if isToggled == newState then return end
			isToggled = newState
			updateVisuals(true)
			if andFireCallback and changeCallback then changeCallback(isToggled) end
		end

		control.SetEnabled = function(newState)
			isControlEnabled = newState
			clickDetector.Active = newState
			updateVisuals(false)
		end

		return control
	end

	local commentsSwitch = createToggleSwitch(generalSettingsFrame, 3, "Trace Comments", "Menambahkan komentar ke kode yang dihasilkan yang melacak objek asli.", "AddTraceComments", true, settings.updateCodePreview)
	local overwriteSwitch = createToggleSwitch(generalSettingsFrame, 4, "Overwrite Existing", "Jika diaktifkan, menimpa skrip yang ada dengan nama yang sama. Kode kustom Anda akan dipertahankan.", "OverwriteExisting", true, settings.updateCodePreview)

	local selectLocationButton = Instance.new("TextButton")
	selectLocationButton.Name = "SelectLocationButton"
	selectLocationButton.LayoutOrder = 5
	selectLocationButton.Text = "Pilih Lokasi Output"
	selectLocationButton.Size = UDim2.new(1, 0, 0, 28)
	selectLocationButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	selectLocationButton.TextColor3 = Color3.fromRGB(220, 220, 220)
	selectLocationButton.Font = Enum.Font.SourceSans
	selectLocationButton.TextSize = 14
	selectLocationButton.Parent = generalSettingsFrame
	local selectLocationCorner = Instance.new("UICorner")
	selectLocationCorner.CornerRadius = UDim.new(0, 4)
	selectLocationCorner.Parent = selectLocationButton

	local locationLabel = Instance.new("TextLabel")
	locationLabel.Name = "LocationLabel"
	locationLabel.LayoutOrder = 6
	locationLabel.Text = "Lokasi: Default"
	locationLabel.Size = UDim2.new(1, 0, 0, 18)
	locationLabel.Font = Enum.Font.SourceSansItalic
	locationLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	locationLabel.TextSize = 13
	locationLabel.BackgroundTransparency = 1
	locationLabel.TextXAlignment = Enum.TextXAlignment.Left
	locationLabel.Parent = generalSettingsFrame

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

	local activeProfileLabel = Instance.new("TextLabel")
	activeProfileLabel.Name = "ActiveProfileLabel"
	activeProfileLabel.LayoutOrder = 2
	activeProfileLabel.Size = UDim2.new(1, 0, 0, 18)
	activeProfileLabel.Font = Enum.Font.SourceSansItalic
	activeProfileLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	activeProfileLabel.Text = "Profil Aktif: Default"
	activeProfileLabel.TextSize = 13
	activeProfileLabel.TextXAlignment = Enum.TextXAlignment.Left
	activeProfileLabel.BackgroundTransparency = 1
	activeProfileLabel.Parent = blacklistSettingsFrame

	local manageProfilesButton = Instance.new("TextButton")
	manageProfilesButton.Name = "ManageProfilesButton"
	manageProfilesButton.LayoutOrder = 3
	manageProfilesButton.Size = UDim2.new(1, 0, 0, 28)
	manageProfilesButton.Text = "Kelola Profil..."
	manageProfilesButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	manageProfilesButton.Font = Enum.Font.SourceSans
	manageProfilesButton.TextSize = 14
	manageProfilesButton.TextColor3 = Color3.fromRGB(220, 220, 220)
	manageProfilesButton.Parent = blacklistSettingsFrame
	local manageProfilesCorner = Instance.new("UICorner")
	manageProfilesCorner.CornerRadius = UDim.new(0, 4)
	manageProfilesCorner.Parent = manageProfilesButton

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

	local classBlacklistLabel = Instance.new("TextLabel")
	classBlacklistLabel.LayoutOrder = 5
	classBlacklistLabel.Text = "Kelas yang Diabaikan:"
	classBlacklistLabel.Size = UDim2.new(1, 0, 0, 15)
	classBlacklistLabel.Font = Enum.Font.SourceSans
	classBlacklistLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	classBlacklistLabel.TextSize = 13
	classBlacklistLabel.TextXAlignment = Enum.TextXAlignment.Left
	classBlacklistLabel.BackgroundTransparency = 1
	classBlacklistLabel.Parent = blacklistSettingsFrame

	local classBlacklistFrame = Instance.new("Frame")
	classBlacklistFrame.LayoutOrder = 6
	classBlacklistFrame.Size = UDim2.new(1, 0, 0, 0)
	classBlacklistFrame.AutomaticSize = Enum.AutomaticSize.Y
	classBlacklistFrame.BackgroundTransparency = 1
	classBlacklistFrame.Parent = blacklistSettingsFrame

	local classBlacklistLayout = Instance.new("UIGridLayout")
	classBlacklistLayout.CellSize = UDim2.new(0.5, -5, 0, 24)
	classBlacklistLayout.SortOrder = Enum.SortOrder.Name
	classBlacklistLayout.Parent = classBlacklistFrame

	local bulkActionFrame = Instance.new("Frame")
	bulkActionFrame.LayoutOrder = 7
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
	blacklistFrame.LayoutOrder = 8
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

	local classBlacklistCheckboxes = {}
	local function createClassCheckbox(className)
		local checkbox = Instance.new("TextButton")
		checkbox.Name = className
		checkbox.Size = UDim2.new(1, 0, 1, 0)
		checkbox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		checkbox.Text = "  " .. className
		checkbox.Font = Enum.Font.SourceSans
		checkbox.TextSize = 13
		checkbox.TextColor3 = Color3.fromRGB(200, 200, 200)
		checkbox.TextXAlignment = Enum.TextXAlignment.Left
		checkbox.Parent = classBlacklistFrame
		local checkboxCorner = Instance.new("UICorner")
		checkboxCorner.CornerRadius = UDim.new(0, 4)
		checkboxCorner.Parent = checkbox

		local isBlacklisted = plugin:GetSetting("ClassBlacklist_" .. className) or false

		local function updateVisuals()
			if isBlacklisted then
				checkbox.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
				checkbox.Text = "  [X] " .. className
			else
				checkbox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
				checkbox.Text = "  [ ] " .. className
			end
		end

		checkbox.MouseButton1Click:Connect(function()
			isBlacklisted = not isBlacklisted
			plugin:SetSetting("ClassBlacklist_" .. className, isBlacklisted)
			updateVisuals()
			if settings.updateCodePreview then
				settings.updateCodePreview()
			end
		end)

		updateVisuals()
		classBlacklistCheckboxes[className] = {
			IsBlacklisted = function() return isBlacklisted end
		}
	end

	local classesToBlacklist = {"UICorner", "UIStroke", "UIGradient", "UIAspectRatioConstraint", "UIGridLayout", "UIListLayout", "UIPadding", "UIScale", "UISizeConstraint", "UITextSizeConstraint"}
	for _, className in ipairs(classesToBlacklist) do
		createClassCheckbox(className)
	end

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

	local applyFromScriptButton = Instance.new("TextButton")
	applyFromScriptButton.Name = "ApplyFromScriptButton"
	applyFromScriptButton.LayoutOrder = currentLayoutOrder
	currentLayoutOrder = currentLayoutOrder + 1
	applyFromScriptButton.Text = "Terapkan dari Skrip"
	applyFromScriptButton.Size = UDim2.new(1, 0, 0, 28)
	applyFromScriptButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	applyFromScriptButton.TextColor3 = Color3.fromRGB(220, 220, 220)
	applyFromScriptButton.Font = Enum.Font.SourceSans
	applyFromScriptButton.TextSize = 14
	applyFromScriptButton.Parent = mainFrame
	local applyCorner = Instance.new("UICorner")
	applyCorner.CornerRadius = UDim.new(0, 4)
	applyCorner.Parent = applyFromScriptButton
	local applyStroke = Instance.new("UIStroke")
	applyStroke.Color = Color3.fromRGB(90, 90, 90)
	applyStroke.Thickness = 1
	applyStroke.Parent = applyFromScriptButton

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

	pmSaveButton.MouseButton1Click:Connect(function()
		local name = pmNameInput.Text
		if name and name ~= "" then
			settings.saveProfile(name)
			pmNameInput.Text = ""
		end
	end)

	pmDeleteButton.MouseButton1Click:Connect(function()
		settings.deleteProfile(settings.getActiveProfile())
	end)

	local function updateProfileList(profiles, activeProfile)
		for _, child in ipairs(pmProfileList:GetChildren()) do
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
			option.BackgroundColor3 = (name == activeProfile) and Color3.fromRGB(90, 90, 90) or Color3.fromRGB(70, 70, 70)
			option.Font = (name == activeProfile) and Enum.Font.SourceSansBold or Enum.Font.SourceSans
			option.TextSize = 14
			option.TextColor3 = Color3.fromRGB(220, 220, 220)
			option.TextXAlignment = Enum.TextXAlignment.Left
			option.Parent = pmProfileList
			option.MouseButton1Click:Connect(function()
				settings.applyProfile(name)
			end)
		end
		pmProfileList.CanvasSize = UDim2.new(0,0,0, #profileNames * 28 + 8)
		activeProfileLabel.Text = "Profil Aktif: " .. activeProfile
	end

	return {
		-- Kontrol Preset Modal
		SavePresetButton = savePresetButton,      -- Tombol utama untuk membuka modal simpan
		LoadPresetButton = loadPresetButton,      -- Tombol utama untuk membuka modal muat
		ActivePresetLabel = activePresetLabel,    -- Label untuk menampilkan preset aktif
		SavePresetModal = savePresetModalControls.Modal,
		SavePresetNameInput = savePresetModalControls.NameInput,
		ConfirmSavePresetButton = savePresetModalControls.SaveButton,
		CancelSavePresetButton = savePresetModalControls.CancelButton,
		LoadPresetModal = loadPresetModalControls.Modal,
		LoadPresetListFrame = loadPresetModalControls.ListFrame,
		NoPresetsLabel = loadPresetModalControls.NoPresetsLabel,
		CancelLoadPresetButton = loadPresetModalControls.CancelButton,

		-- Kontrol Alat Desain
		CopyStyleButton = copyStyleButton,
		PasteStyleButton = pasteStyleButton,
		PasteStyleModal = pasteStyleModalControls.Modal,
		PasteStyleListFrame = pasteStyleModalControls.ListFrame,
		ApplyStyleButton = pasteStyleModalControls.ApplyButton,
		CancelStyleButton = pasteStyleModalControls.CancelButton,
		InsertComponentButton = insertComponentButton,

		SelectionLabel = selectionLabel,
		ScriptTypeButton = scriptTypeButton,
		SelectLocationButton = selectLocationButton,
		LocationLabel = locationLabel,
		BlacklistCheckboxes = blacklistCheckboxes,
		ClassBlacklistCheckboxes = classBlacklistCheckboxes,
		updateProfileList = updateProfileList,
		IsCommentsEnabled = commentsSwitch.IsToggled,
		SetCommentsEnabled = function(val) commentsSwitch.SetToggled(val) end,
		IsOverwriteEnabled = overwriteSwitch.IsToggled,
		SetOverwriteEnabled = function(val) overwriteSwitch.SetToggled(val) end,
		IsLiveSyncEnabled = liveSyncSwitch.IsToggled,
		SetLiveSyncEnabled = function(val) liveSyncSwitch.SetToggled(val, true) end, -- Fire callback
		IsAutoOpenEnabled = autoRenewSwitch.IsToggled,
		SetAutoOpenEnabled = function(val) autoRenewSwitch.SetToggled(val) end,
		ConvertButton = convertButton,
		ApplyFromScriptButton = applyFromScriptButton,
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
		-- Tombol-tombol lama (sekarang di modal PM)
		SaveProfileButton = pmSaveButton,
		DeleteProfileButton = pmDeleteButton,
		ImportProfileButton = pmImportButton,
		ExportProfileButton = pmExportButton,
		ProfileNameInput = pmNameInput,
		-- UI Modal Impor/Ekspor
		ImportExportModal = importExportModal,
		ImportExportTextBox = modalTextBox,
		ImportExportConfirmButton = confirmButton,
		ImportExportCloseButton = closeButton,
		-- UI Modal Manajemen Profil baru
		ManageProfilesButton = manageProfilesButton,
		ProfileManagerModal = profileManagerModal,
		ProfileManagerCloseButton = pmCloseButton,
		SetScriptTypeEnabled = function(isEnabled)
			scriptTypeButton.AutoButtonColor = isEnabled
			scriptTypeButton.Selectable = isEnabled
			if not isEnabled then
				typeStroke.Color = Color3.fromRGB(50, 50, 50)
				scriptTypeButton.TextColor3 = Color3.fromRGB(120, 120, 120)
			else
				typeStroke.Color = Color3.fromRGB(80, 80, 80)
				scriptTypeButton.TextColor3 = Color3.fromRGB(220, 220, 220)
			end
		end,
		SetApplyButtonEnabled = function(isEnabled)
			applyFromScriptButton.AutoButtonColor = isEnabled
			applyFromScriptButton.Selectable = isEnabled
			if isEnabled then
				applyFromScriptButton.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
				applyStroke.Color = Color3.fromRGB(120, 160, 240)
				applyFromScriptButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			else
				applyFromScriptButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
				applyStroke.Color = Color3.fromRGB(90, 90, 90)
				applyFromScriptButton.TextColor3 = Color3.fromRGB(160, 160, 160)
			end
		end,
	}
end

return UI
