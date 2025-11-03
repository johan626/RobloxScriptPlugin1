-- GUI → LocalScript Plugin for Roblox Studio
-- Bahasa: Indonesian
-- Alur kerja utama dan skrip inisialisasi untuk plugin GUIConvert.

local Selection = game:GetService("Selection")
local StarterPlayer = game:GetService("StarterPlayer")
local HttpService = game:GetService("HttpService")

-- Muat modul dari direktori Lib
local Utils = require(script.Lib.Utils)
local TemplateFinder = require(script.Lib.TemplateFinder)
local CodeGenerator = require(script.Lib.CodeGenerator)
local SyntaxHighlighter = require(script.Lib.SyntaxHighlighter)
local ScriptParser = require(script.Lib.ScriptParser)
local UI = require(script.Lib.UI)

-- Inisialisasi Plugin UI
local toolbar = plugin:CreateToolbar("GUI Tools")
local button = toolbar:CreateButton("Convert GUI to LocalScript", "Convert selected GUI into a LocalScript that recreates it", "rbxassetid://4458901886")
local configWidget = plugin:CreateDockWidgetPluginGui("GUIConverterConfig", DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float, true, false, 240, 480
	))
configWidget.Title = "GUI Converter"

local contextualAction = plugin:CreatePluginAction(
	"GUIConvert_ContextualConvert",
	"Convert GUI to Script",
	"Converts the selected GUI to a script using last saved settings",
	"rbxassetid://4458901886",
	false
)

-- Variabel global dan status
local controls
local syncingInstance = nil
local syncingScript = nil
local syncConnections = {}
local debounceTimer = nil
local lastSyncSettings = nil
local previewDebounceTimer = nil
local blacklistProfiles = {}
local activeProfileName = "Default"
local presets = {}
local activePresetName = "Default"
local projectDefaultPresets = {}
local outputLocation = nil
local copiedStyle = nil

-- Pre-declare functions for mutual recursion / ordering
local reSync
local showStatus 
local connectInstance
local disconnectInstance
local saveBlacklistProfiles
local applyBlacklistProfile
local updateCodePreview
local saveCurrentPreset
local deleteCurrentPreset
local applyPreset

-- Fungsi Manajemen Profil
function saveBlacklistProfiles()
	local success, encoded = pcall(HttpService.JSONEncode, HttpService, blacklistProfiles)
	if success then
		plugin:SetSetting("BlacklistProfiles", encoded)
	else
		warn("[GUIConvert] Gagal menyimpan profil daftar hitam:", encoded)
	end
end

local function loadBlacklistProfiles()
	local saved = plugin:GetSetting("BlacklistProfiles")
	if saved then
		local success, decoded = pcall(HttpService.JSONDecode, HttpService, saved)
		if success then
			blacklistProfiles = decoded
		else
			warn("[GUIConvert] Gagal memuat profil daftar hitam:", decoded)
			blacklistProfiles = {}
		end
	end
	if not blacklistProfiles["Default"] then
		blacklistProfiles["Default"] = { "Position", "Size" }
	end
	activeProfileName = plugin:GetSetting("ActiveProfile") or "Default"
end

function applyBlacklistProfile(profileName)
	activeProfileName = profileName
	plugin:SetSetting("ActiveProfile", activeProfileName)
	local profile = blacklistProfiles[activeProfileName] or {}

	local profileSet = {}
	for _, propName in ipairs(profile) do
		profileSet[propName] = true
	end

	for propName, checkboxData in pairs(controls.BlacklistCheckboxes) do
		checkboxData.Toggle(profileSet[propName] == true)
	end

	controls.updateProfileList(blacklistProfiles, activeProfileName)
	updateCodePreview()
end

local function saveCurrentProfile(profileName)
	if not profileName or profileName == "" then
		showStatus("✗ Nama profil tidak boleh kosong.", true)
		return
	end

	local blacklistedProps = {}
	for propName, checkboxData in pairs(controls.BlacklistCheckboxes) do
		if checkboxData.IsBlacklisted() then
			table.insert(blacklistedProps, propName)
		end
	end
	table.sort(blacklistedProps)

	blacklistProfiles[profileName] = blacklistedProps
	saveBlacklistProfiles()
	applyBlacklistProfile(profileName)
	showStatus("✓ Profil '" .. profileName .. "' disimpan.", false)
end

local function deleteProfile(profileName)
	if profileName == "Default" then
		showStatus("✗ Profil 'Default' tidak dapat dihapus.", true)
		return
	end

	if blacklistProfiles[profileName] then
		blacklistProfiles[profileName] = nil
		saveBlacklistProfiles()
		applyBlacklistProfile("Default")
		showStatus("✓ Profil '" .. profileName .. "' dihapus.", false)
	else
		showStatus("✗ Profil '" .. profileName .. "' tidak ditemukan.", true)
	end
end

-- Fungsi Manajemen Preset
local function savePresets()
	local success, encoded = pcall(HttpService.JSONEncode, HttpService, presets)
	if success then
		plugin:SetSetting("ConfigurationPresets", encoded)
	else
		warn("[GUIConvert] Gagal menyimpan preset:", encoded)
	end
end

local function loadPresets()
	local saved = plugin:GetSetting("ConfigurationPresets")
	if saved then
		local success, decoded = pcall(HttpService.JSONDecode, HttpService, saved)
		if success then
			presets = decoded
		else
			warn("[GUIConvert] Gagal memuat preset:", decoded)
			presets = {}
		end
	end
	if not presets["Default"] then
		presets["Default"] = {
			ScriptType = "ModuleScript",
			AddTraceComments = true,
			OverwriteExisting = true,
			LiveSyncEnabled = false,
			AutoOpen = false,
			ActiveProfileName = "Default",
		}
	end
	activePresetName = plugin:GetSetting("ActivePreset") or "Default"
end

function applyPreset(presetName)
	local preset = presets[presetName]
	if not preset then
		warn("[GUIConvert] Mencoba menerapkan preset yang tidak ada:", presetName)
		return
	end

	activePresetName = presetName
	plugin:SetSetting("ActivePreset", activePresetName)

	-- Terapkan pengaturan ke kontrol
	controls.ScriptTypeButton.Text = preset.ScriptType
	controls.SetCommentsEnabled(preset.AddTraceComments)
	controls.SetOverwriteEnabled(preset.OverwriteExisting)
	controls.SetLiveSyncEnabled(preset.LiveSyncEnabled)
	controls.SetAutoOpenEnabled(preset.AutoOpen)

	if blacklistProfiles[preset.ActiveProfileName] then
		applyBlacklistProfile(preset.ActiveProfileName)
	else
		showStatus("✗ Profil blacklist '" .. preset.ActiveProfileName .. "' tidak ditemukan. Kembali ke Default.", true)
		applyBlacklistProfile("Default")
	end

	controls.ActivePresetLabel.Text = "Preset Aktif: " .. activePresetName
	updateCodePreview()
end

function saveCurrentPreset(presetName)
	if not presetName or presetName == "" then
		showStatus("✗ Nama preset tidak boleh kosong.", true)
		return
	end

	presets[presetName] = {
		ScriptType = controls.ScriptTypeButton.Text,
		AddTraceComments = controls.IsCommentsEnabled(),
		OverwriteExisting = controls.IsOverwriteEnabled(),
		LiveSyncEnabled = controls.IsLiveSyncEnabled(),
		AutoOpen = controls.IsAutoOpenEnabled(),
		ActiveProfileName = activeProfileName,
	}

	savePresets()
	applyPreset(presetName) -- Terapkan untuk konsistensi UI
	showStatus("✓ Preset '" .. presetName .. "' disimpan.", false)
end

function deletePreset(presetName)
	if presetName == "Default" then
		showStatus("✗ Preset 'Default' tidak dapat dihapus.", true)
		return
	end

	-- Hapus juga dari default proyek jika ada
	for placeId, name in pairs(projectDefaultPresets) do
		if name == presetName then
			projectDefaultPresets[placeId] = nil
		end
	end
	saveProjectDefaultPresets() -- Simpan perubahan pada default

	if presets[presetName] then
		local deletedName = presetName
		presets[presetName] = nil
		savePresets()
		if activePresetName == deletedName then
			applyPreset("Default")
		end
		updateLoadPresetModal() -- Perbarui modal setelah menghapus
		showStatus("✓ Preset '" .. deletedName .. "' dihapus.", false)
	else
		showStatus("✗ Preset '" .. presetName .. "' tidak ditemukan.", true)
	end
end

local function saveProjectDefaultPresets()
	local success, encoded = pcall(HttpService.JSONEncode, HttpService, projectDefaultPresets)
	if success then
		plugin:SetSetting("ProjectDefaultPresets", encoded)
	else
		warn("[GUIConvert] Gagal menyimpan preset default proyek:", encoded)
	end
end

local function loadProjectDefaultPresets()
	local saved = plugin:GetSetting("ProjectDefaultPresets")
	if saved and saved ~= "" then
		local success, decoded = pcall(HttpService.JSONDecode, HttpService, saved)
		if success and type(decoded) == "table" then
			projectDefaultPresets = decoded
		else
			warn("[GUIConvert] Gagal memuat preset default proyek:", decoded)
			projectDefaultPresets = {}
		end
	end
end

local function applyProjectDefaultPreset()
	if game.PlaceId == 0 then return end -- Bukan proyek yang disimpan

	local placeIdStr = tostring(game.PlaceId)
	local defaultPresetName = projectDefaultPresets[placeIdStr]

	if defaultPresetName and presets[defaultPresetName] then
		applyPreset(defaultPresetName)
		showStatus(string.format("i Preset default '%s' untuk proyek ini dimuat.", defaultPresetName), false)
	end
end

local function updateLoadPresetModal()
	local listFrame = controls.LoadPresetListFrame
	for _, child in ipairs(listFrame:GetChildren()) do
		if child:IsA("GuiObject") and not child:IsA("UIListLayout") and not child:IsA("UICorner") and child.Name ~= "NoPresetsLabel" then
			child:Destroy()
		end
	end

	local presetNames = {}
	for name in pairs(presets) do
		table.insert(presetNames, name)
	end
	table.sort(presetNames)

	if #presetNames == 0 then
		controls.NoPresetsLabel.Visible = true
		return
	end
	controls.NoPresetsLabel.Visible = false

	for _, name in ipairs(presetNames) do
		local row = Instance.new("Frame")
		row.Name = name .. "_Row"
		row.Size = UDim2.new(1, 0, 0, 30)
		row.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
		row.BackgroundTransparency = (name == activePresetName) and 0.5 or 1
		row.Parent = listFrame
		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 4)
		rowCorner.Parent = row

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -180, 1, 0) -- Beri lebih banyak ruang untuk tombol
		nameLabel.Text = "  " .. name
		nameLabel.Font = (name == activePresetName) and Enum.Font.SourceSansBold or Enum.Font.SourceSans
		nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.BackgroundTransparency = 1
		nameLabel.Parent = row

		local buttonFrame = Instance.new("Frame")
		buttonFrame.Size = UDim2.new(0, 170, 1, 0)
		buttonFrame.Position = UDim2.new(1, -170, 0, 0)
		buttonFrame.BackgroundTransparency = 1
		buttonFrame.Parent = row
		local buttonLayout = Instance.new("UIListLayout")
		buttonLayout.FillDirection = Enum.FillDirection.Horizontal
		buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		buttonLayout.Padding = UDim.new(0, 5)
		buttonLayout.Parent = buttonFrame

		local loadButton = Instance.new("TextButton")
		loadButton.Name = "LoadButton"
		loadButton.Size = UDim2.new(0, 50, 0, 22)
		loadButton.Text = "Muat"
		loadButton.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
		loadButton.Font = Enum.Font.SourceSansBold
		loadButton.TextSize = 13
		loadButton.Parent = buttonFrame
		local loadCorner = Instance.new("UICorner")
		loadCorner.CornerRadius = UDim.new(0, 3)
		loadCorner.Parent = loadButton

		loadButton.MouseButton1Click:Connect(function()
			applyPreset(name)
			controls.LoadPresetModal.Visible = false
		end)

		local setDefaultButton = Instance.new("TextButton")
		setDefaultButton.Name = "SetDefaultButton"
		setDefaultButton.Size = UDim2.new(0, 80, 0, 22)
		setDefaultButton.Font = Enum.Font.SourceSansBold
		setDefaultButton.TextSize = 13
		setDefaultButton.Parent = buttonFrame
		local setDefaultCorner = Instance.new("UICorner")
		setDefaultCorner.CornerRadius = UDim.new(0, 3)
		setDefaultCorner.Parent = setDefaultButton

		if name ~= "Default" then
			local deleteButton = Instance.new("TextButton")
			deleteButton.Name = "DeleteButton"
			deleteButton.Size = UDim2.new(0, 50, 0, 22)
			deleteButton.Text = "Hapus"
			deleteButton.BackgroundColor3 = Color3.fromRGB(180, 80, 80)
			deleteButton.Font = Enum.Font.SourceSansBold
			deleteButton.TextSize = 13
			deleteButton.Parent = buttonFrame
			local deleteCorner = Instance.new("UICorner")
			deleteCorner.CornerRadius = UDim.new(0, 3)
			deleteCorner.Parent = deleteButton

			deleteButton.MouseButton1Click:Connect(function()
				deletePreset(name)
			end)
		end

		local placeIdStr = tostring(game.PlaceId)
		local isProjectDefault = (projectDefaultPresets[placeIdStr] == name)

		if isProjectDefault then
			setDefaultButton.Text = "Default"
			setDefaultButton.BackgroundColor3 = Color3.fromRGB(70, 150, 70)
		else
			setDefaultButton.Text = "Set Default"
			setDefaultButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		end

		setDefaultButton.MouseButton1Click:Connect(function()
			if game.PlaceId == 0 then
				showStatus("✗ Simpan proyek ini terlebih dahulu untuk mengatur default.", true)
				return
			end

			if isProjectDefault then
				-- Jika sudah default, klik lagi akan menghapusnya
				projectDefaultPresets[placeIdStr] = nil
			else
				projectDefaultPresets[placeIdStr] = name
			end

			saveProjectDefaultPresets()
			updateLoadPresetModal() -- Perbarui UI untuk merefleksikan perubahan
		end)
	end
end

function deleteCurrentPreset()
	if activePresetName == "Default" then
		showStatus("✗ Preset 'Default' tidak dapat dihapus.", true)
		return
	end

	if presets[activePresetName] then
		local deletedName = activePresetName
		presets[activePresetName] = nil
		savePresets()
		applyPreset("Default")
		showStatus("✓ Preset '" .. deletedName .. "' dihapus.", false)
	else
		showStatus("✗ Preset '" .. activePresetName .. "' tidak ditemukan.", true)
	end
end

-- Daftar properti yang akan diserialisasi
local COMMON_PROPERTIES = {
	"Name","AnchorPoint","AutomaticSize","Position","Rotation","Size","Visible","ZIndex","LayoutOrder", "Active", "SizeConstraint",
	"BackgroundColor3","BackgroundTransparency","BorderSizePixel", "BorderColor3", "BorderMode",
	"Image","ImageTransparency","ImageColor3","ScaleType","SliceCenter","SliceScale","ImageRectOffset","ImageRectSize","ClipsDescendants", "TileSize", "ResampleMode",
	"Text","TextColor3","TextSize","TextScaled","Font","TextWrapped","TextXAlignment","TextYAlignment","TextTransparency","TextStrokeTransparency","TextStrokeColor3","PlaceholderText","PlaceholderColor3","TextEditable", "FontFace", "LineHeight", "RichText", "TextDirection", "TextTruncate",
	"AutoButtonColor","ResetOnSpawn","Selectable","Modal","Style"
}
local PROPERTIES_BY_CLASS = {
	UICorner = {"CornerRadius"},
	UIGradient = {"Color", "Enabled", "Offset", "Rotation", "Transparency"},
	UIStroke = {"ApplyStrokeMode", "Color", "Enabled", "LineJoinMode", "Thickness", "Transparency", "BorderOffset", "BorderStrokePosition", "StrokeSizingMode", "ZIndex"},
	UIAspectRatioConstraint = {"AspectRatio", "AspectType", "DominantAxis"},
	UIGridLayout = {"AbsoluteContentSize", "CellPadding", "CellSize", "FillDirection", "HorizontalAlignment", "SortOrder", "StartCorner", "VerticalAlignment"},
	UIListLayout = {"AbsoluteContentSize", "FillDirection", "HorizontalAlignment", "Padding", "SortOrder", "VerticalAlignment", "HorizontalFlex", "VerticalFlex"},
	UIPadding = {"PaddingBottom", "PaddingLeft", "PaddingRight", "PaddingTop"},
	UIScale = {"Scale"},
	UISizeConstraint = {"MaxSize", "MinSize"},
	UITextSizeConstraint = {"MaxTextSize", "MinTextSize"},
	SurfaceGui = {"Adornee", "Face", "SizingMode", "CanvasSize", "PixelsPerStud", "LightInfluence", "AlwaysOnTop"}
}

-- Definisi Fungsi Inti

local function stopSyncing()
	if not syncingInstance then return end
	print("[GUIConvert] Menghentikan sinkronisasi untuk " .. syncingInstance:GetFullName())

	-- Putuskan semua koneksi yang tersimpan
	for inst, connections in pairs(syncConnections) do
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
	end

	syncConnections = {}
	syncingInstance = nil
	syncingScript = nil
	if debounceTimer then
		task.cancel(debounceTimer)
		debounceTimer = nil
	end
	if controls and controls.StatusLabel then
		controls.StatusLabel.Visible = false
		controls.StatusLabel.Text = ""
	end
end

local function generateLuaForGui(root, settings)
	return CodeGenerator.generate(root, settings, COMMON_PROPERTIES, PROPERTIES_BY_CLASS, Utils, TemplateFinder)
end

local function extractUserCode(source)
	local startMarker = "--// USER_CODE_START"
	local endMarker = "--// USER_CODE_END"
	local startIndex, _ = source:find(startMarker, 1, true)
	local _, endIndex = source:find(endMarker, 1, true)

	if startIndex and endIndex then
		local start = startIndex + #startMarker
		local extracted = source:sub(start, endIndex - 1)
		return extracted
	end
	return nil
end

reSync = function()
	if not syncingInstance or not syncingScript or not lastSyncSettings then return end
	if debounceTimer then task.cancel(debounceTimer) end

	controls.StatusLabel.Text = "Status: Mengetik..."
	controls.StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 120)
	controls.StatusLabel.Visible = true

	debounceTimer = task.delay(0.5, function()
		if not syncingInstance or not syncingInstance.Parent then
			stopSyncing()
			return
		end

		local currentUserCode = extractUserCode(syncingScript.Source)
		local success, generated = pcall(generateLuaForGui, syncingInstance, lastSyncSettings)

		if success then
			if currentUserCode then
				local startMarker = "--// USER_CODE_START"
				local endMarker = "--// USER_CODE_END"
				generated = generated:gsub(startMarker..".-"..endMarker, startMarker .. currentUserCode .. endMarker, 1)
			end
			syncingScript.Source = generated
			if lastSyncSettings.AutoOpen then
				plugin:OpenScript(syncingScript) -- Paksa editor untuk memuat ulang
			end
			controls.StatusLabel.Text = string.format("Status: Tersinkronisasi @ %s", os.date("%H:%M:%S"))
			controls.StatusLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
		else
			warn("[GUIConvert] Gagal melakukan sinkronisasi ulang:", generated)
			controls.StatusLabel.Text = "Status: Kesalahan Sinkronisasi!"
			controls.StatusLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
		end
		debounceTimer = nil
	end)
end

disconnectInstance = function(inst)
	if syncConnections[inst] then
		for _, connection in ipairs(syncConnections[inst]) do
			connection:Disconnect()
		end
		syncConnections[inst] = nil
	end
end

connectInstance = function(inst)
	if syncConnections[inst] then return end -- Sudah terhubung

	local propsToWatch, propSet = {}, {}
	if inst:IsA("GuiObject") then
		for _, prop in ipairs(COMMON_PROPERTIES) do if not propSet[prop] then table.insert(propsToWatch, prop); propSet[prop] = true end end
	end
	local classSpecificProps = PROPERTIES_BY_CLASS[inst.ClassName]
	if classSpecificProps then
		for _, prop in ipairs(classSpecificProps) do if not propSet[prop] then table.insert(propsToWatch, prop); propSet[prop] = true end end
	end

	syncConnections[inst] = {}

	for _, prop in ipairs(propsToWatch) do
		local success, signal = pcall(function()
			return inst:GetPropertyChangedSignal(prop)
		end)
		if success and signal then
			table.insert(syncConnections[inst], signal:Connect(reSync))
		end
	end

	-- Tambahkan listener untuk perubahan atribut
	table.insert(syncConnections[inst], inst.AttributeChanged:Connect(function(attributeName)
		reSync()
	end))

	-- Tambahkan listener untuk perubahan hierarki
	table.insert(syncConnections[inst], inst.ChildAdded:Connect(function(child)
		connectInstance(child) -- Pastikan turunan baru juga diamati
		reSync()
	end))
	table.insert(syncConnections[inst], inst.ChildRemoved:Connect(function(child)
		disconnectInstance(child) -- Hentikan pengamatan pada turunan yang dihapus
		reSync()
	end))
end

local function startSyncing(guiObject, script, settings)
	stopSyncing()
	syncingInstance = guiObject
	syncingScript = script
	lastSyncSettings = settings

	-- Hubungkan instance root dan semua turunannya
	connectInstance(guiObject)
	for _, inst in ipairs(guiObject:GetDescendants()) do
		connectInstance(inst)
	end

	-- Buat koneksi level-root untuk penghancuran
	syncConnections[guiObject] = syncConnections[guiObject] or {}
	table.insert(syncConnections[guiObject], guiObject.Destroying:Connect(stopSyncing))

	print("[GUIConvert] Memulai sinkronisasi untuk " .. guiObject:GetFullName())
	controls.StatusLabel.Text = "Status: Sinkronisasi aktif"
	controls.StatusLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
	controls.StatusLabel.Visible = true
end

local function performConversion(root, settings)
	if not root or (not Utils.isGuiObject(root) and not root:IsA("ScreenGui")) then
		return nil, "Objek terpilih bukan GuiObject/ScreenGui yang valid."
	end

	local success, generated = pcall(generateLuaForGui, root, settings)
	if not success then
		warn("Kesalahan pembuatan kode:", generated)
		return nil, "Gagal menghasilkan kode. Periksa Output untuk detail."
	end

	return generated, root
end

local function createFile(generated, rootName, settings)
	local scriptInstance
	if settings.ScriptType == "ModuleScript" then
		scriptInstance = Instance.new("ModuleScript")
	else
		scriptInstance = Instance.new("LocalScript")
	end

	local targetFolder = outputLocation
	if not targetFolder or not targetFolder.Parent then
		local parentService
		local folderName
		if settings.ScriptType == "ModuleScript" then
			parentService = game:GetService("ReplicatedStorage")
			folderName = "GeneratedGuis"
		else
			parentService = StarterPlayer:FindFirstChild("StarterPlayerScripts") or Instance.new("Folder", StarterPlayer)
			parentService.Name = "StarterPlayerScripts"
			folderName = "GeneratedLocalGuis"
		end
		targetFolder = parentService:FindFirstChild(folderName) or Instance.new("Folder", parentService)
		targetFolder.Name = folderName
	end

	local nameSafe = rootName:gsub("%W", "")
	if nameSafe == "" then nameSafe = "GeneratedGui" end
	scriptInstance.Name = nameSafe

	if settings.OverwriteExisting then
		local existing = targetFolder:FindFirstChild(scriptInstance.Name)
		if existing and existing:IsA(scriptInstance.ClassName) then
			local userCode = extractUserCode(existing.Source)
			if userCode then
				local startMarker = "--// USER_CODE_START"
				local endMarker = "--// USER_CODE_END"
				generated = generated:gsub(startMarker..".-"..endMarker, startMarker .. userCode .. endMarker, 1)
			end
			existing.Source = generated
			plugin:OpenScript(existing)
			return string.format("%s '%s' berhasil diperbarui.", settings.ScriptType, existing.Name), existing
		end
	end

	scriptInstance.Source = generated
	scriptInstance.Parent = targetFolder
	plugin:OpenScript(scriptInstance)

	return string.format("%s '%s' berhasil dibuat.", settings.ScriptType, scriptInstance.Name), scriptInstance
end

updateCodePreview = function()
	if previewDebounceTimer then
		task.cancel(previewDebounceTimer)
	end

	previewDebounceTimer = task.delay(0.2, function()
		local blacklistedProps = {}
		for propName, checkboxData in pairs(controls.BlacklistCheckboxes) do
			if checkboxData.IsBlacklisted() then
				table.insert(blacklistedProps, propName)
			end
		end
		table.sort(blacklistedProps)
		local blacklistJson = HttpService:JSONEncode(blacklistedProps)

		local classBlacklist = {}
		for className, checkboxData in pairs(controls.ClassBlacklistCheckboxes) do
			if checkboxData.IsBlacklisted() then
				table.insert(classBlacklist, className)
			end
		end
		table.sort(classBlacklist)

		local settings = {
			ScriptType = controls.ScriptTypeButton.Text,
			AddTraceComments = controls.IsCommentsEnabled(),
			OverwriteExisting = controls.IsOverwriteEnabled(),
			PropertyBlacklist = blacklistJson,
			ClassBlacklist = classBlacklist,
			LiveSyncEnabled = controls.IsLiveSyncEnabled(),
			AutoOpen = controls.IsAutoOpenEnabled()
		}

		if lastSyncSettings then
			lastSyncSettings = settings
		end

		local sel = Selection:Get()
		if not sel or #sel == 0 then
			controls.CodePreviewLabel.Text = "-- Pilih objek GUI untuk melihat pratinjau kode..."
			return
		end
		local root = sel[1]
		if not Utils.isGuiObject(root) and not root:IsA("ScreenGui") then
			controls.CodePreviewLabel.Text = "-- Objek yang dipilih bukan GuiObject/ScreenGui yang valid."
			return
		end

		local success, generated = pcall(generateLuaForGui, root, settings)

		if success then
			local ok, highlighted = pcall(SyntaxHighlighter.highlight, generated)
			if ok then
				controls.CodePreviewLabel.Text = highlighted
			else
				warn("[GUIConvert] Syntax highlighting failed:", highlighted)
				controls.CodePreviewLabel.Text = generated -- Fallback to plain text
			end
		else
			controls.CodePreviewLabel.Text = "-- Terjadi kesalahan saat membuat pratinjau kode:\n" .. tostring(generated)
		end
	end)
end


local function handleContextualConversion(selection)
	local classBlacklist = {}
	for className, checkboxData in pairs(controls.ClassBlacklistCheckboxes) do
		if checkboxData.IsBlacklisted() then
			table.insert(classBlacklist, className)
		end
	end

	local settings = {
		ScriptType = plugin:GetSetting("ScriptType") or "ModuleScript",
		AddTraceComments = plugin:GetSetting("AddTraceComments") ~= false,
		OverwriteExisting = plugin:GetSetting("OverwriteExisting") ~= false,
		PropertyBlacklist = plugin:GetSetting("PropertyBlacklist") or HttpService:JSONEncode({"Position", "Size"}),
		ClassBlacklist = classBlacklist,
		AutoOpen = plugin:GetSetting("AutoOpen") ~= false
	}

	if not selection or #selection == 0 then
		showStatus("✗ Tidak ada objek yang dipilih untuk konversi.", true)
		return
	end

	local successCount = 0
	local failCount = 0

	for _, rootObject in ipairs(selection) do
		local generated, err = performConversion(rootObject, settings)
		if generated then
			createFile(generated, rootObject.Name, settings)
			successCount = successCount + 1
		else
			warn(string.format("[GUIConvert] Gagal mengonversi %s: %s", rootObject:GetFullName(), tostring(err)))
			failCount = failCount + 1
		end
	end

	if successCount > 0 then
		local summary = string.format("✓ Berhasil mengonversi %d GUI.", successCount)
		if failCount > 0 then
			summary = summary .. string.format(" (%d gagal)", failCount)
		end
		showStatus(summary, false)
	else
		showStatus(string.format("✗ Gagal mengonversi %d GUI.", failCount), true)
	end
end

-- Inisialisasi UI
loadBlacklistProfiles()
loadPresets()
loadProjectDefaultPresets()

local function updateLocationLabel()
	if outputLocation and outputLocation.Parent then
		controls.LocationLabel.Text = "Lokasi: " .. outputLocation:GetFullName()
	else
		controls.LocationLabel.Text = "Lokasi: Default"
	end
end

local function loadOutputLocation()
	local savedPath = plugin:GetSetting("OutputLocation")
	if savedPath then
		outputLocation = game:FindFirstChild(savedPath, true)
	end
	updateLocationLabel()
end

local uiSettings = {
	COMMON_PROPERTIES = COMMON_PROPERTIES,
	PROPERTIES_BY_CLASS = PROPERTIES_BY_CLASS,
	stopSyncing = stopSyncing,
	updateCodePreview = updateCodePreview,
	saveProfile = saveCurrentProfile,
	deleteProfile = deleteProfile,
	applyProfile = applyBlacklistProfile,
	getProfiles = function() return blacklistProfiles end,
	getActiveProfile = function() return activeProfileName end,
}
controls = UI.create(configWidget, plugin, uiSettings)
applyPreset(activePresetName) -- Terapkan preset awal
applyProjectDefaultPreset() -- Timpa dengan default proyek jika ada
loadOutputLocation()


-- Definisi Fungsi Status (setelah `controls` ada)
local statusTimer
showStatus = function(message, isError)
	if statusTimer then task.cancel(statusTimer) end
	controls.StatusLabel.Text = message
	controls.StatusLabel.TextColor3 = isError and Color3.fromRGB(255, 120, 120) or Color3.fromRGB(120, 255, 120)
	controls.StatusLabel.Visible = true
	statusTimer = task.delay(4, function()
		controls.StatusLabel.Visible = false
		controls.StatusLabel.Text = ""
	end)
end

-- Koneksi Event
contextualAction.Triggered:Connect(handleContextualConversion)
button.Click:Connect(function() configWidget.Enabled = not configWidget.Enabled end)

-- Event Handlers untuk Modal Preset
controls.SavePresetButton.MouseButton1Click:Connect(function()
	controls.SavePresetNameInput.Text = "" -- Bersihkan input saat membuka
	controls.SavePresetModal.Visible = true
end)

controls.LoadPresetButton.MouseButton1Click:Connect(function()
	updateLoadPresetModal() -- Selalu perbarui daftar saat membuka
	controls.LoadPresetModal.Visible = true
end)

controls.ConfirmSavePresetButton.MouseButton1Click:Connect(function()
	local name = controls.SavePresetNameInput.Text
	saveCurrentPreset(name)
	controls.SavePresetModal.Visible = false
end)

controls.CancelSavePresetButton.MouseButton1Click:Connect(function()
	controls.SavePresetModal.Visible = false
end)

controls.CancelLoadPresetButton.MouseButton1Click:Connect(function()
	controls.LoadPresetModal.Visible = false
end)

controls.ConvertButton.MouseButton1Click:Connect(function()
	local blacklistedProps = {}
	for propName, checkboxData in pairs(controls.BlacklistCheckboxes) do
		if checkboxData.IsBlacklisted() then
			table.insert(blacklistedProps, propName)
		end
	end
	table.sort(blacklistedProps)
	local blacklistJson = HttpService:JSONEncode(blacklistedProps)

	local classBlacklist = {}
	for className, checkboxData in pairs(controls.ClassBlacklistCheckboxes) do
		if checkboxData.IsBlacklisted() then
			table.insert(classBlacklist, className)
		end
	end
	table.sort(classBlacklist)

	local settings = {
		ScriptType = controls.ScriptTypeButton.Text,
		AddTraceComments = controls.IsCommentsEnabled(),
		OverwriteExisting = controls.IsOverwriteEnabled(),
		PropertyBlacklist = blacklistJson,
		ClassBlacklist = classBlacklist,
		LiveSyncEnabled = controls.IsLiveSyncEnabled(),
		AutoOpen = controls.IsAutoOpenEnabled()
	}

	local selection = Selection:Get()
	if #selection == 0 then
		showStatus("✗ Tidak ada objek yang dipilih untuk dikonversi.", true)
		return
	end

	local successCount = 0
	local failCount = 0
	local lastSuccessScript = nil
	local lastSuccessRoot = nil

	for _, rootObject in ipairs(selection) do
		local generated, err = performConversion(rootObject, settings)
		if generated then
			local _, scriptInstance = createFile(generated, rootObject.Name, settings)
			lastSuccessScript = scriptInstance
			lastSuccessRoot = rootObject
			successCount = successCount + 1
		else
			warn(string.format("[GUIConvert] Gagal mengonversi %s: %s", rootObject:GetFullName(), tostring(err)))
			failCount = failCount + 1
		end
	end

	plugin:SetSetting("ScriptType", settings.ScriptType)
	plugin:SetSetting("AddTraceComments", settings.AddTraceComments)
	plugin:SetSetting("OverwriteExisting", settings.OverwriteExisting)
	plugin:SetSetting("PropertyBlacklist", settings.PropertyBlacklist)
	plugin:SetSetting("LiveSyncEnabled", settings.LiveSyncEnabled)
	plugin:SetSetting("AutoOpen", settings.AutoOpen)
	if outputLocation then
		plugin:SetSetting("OutputLocation", outputLocation:GetFullName())
	end

	if successCount > 0 then
		if settings.LiveSyncEnabled and lastSuccessScript and lastSuccessRoot then
			if #selection > 1 then
				showStatus("✓ Peringatan: Live Sync hanya aktif pada objek terakhir.", false)
				task.delay(2, function() startSyncing(lastSuccessRoot, lastSuccessScript, settings) end)
			else
				startSyncing(lastSuccessRoot, lastSuccessScript, settings)
			end
		else
			stopSyncing()
		end

		local summary = string.format("✓ Berhasil mengonversi %d GUI.", successCount)
		if failCount > 0 then
			summary = summary .. string.format(" (%d gagal)", failCount)
		end
		showStatus(summary, false)
	else
		showStatus(string.format("✗ Gagal mengonversi %d GUI.", failCount), true)
		stopSyncing()
	end
end)

controls.SelectAllButton.MouseButton1Click:Connect(updateCodePreview)
controls.ScriptTypeButton.MouseButton1Click:Connect(updateCodePreview)

controls.ExampleCodeButton.MouseButton1Click:Connect(function()
	local sel = Selection:Get()
	if not sel or #sel == 0 then showStatus("✗ Pilih ModuleScript untuk membuat contoh.", true) return end
	local moduleScript = sel[1]
	if not moduleScript:IsA("ModuleScript") then showStatus("✗ Objek terpilih bukan ModuleScript.", true) return end
	local parent = moduleScript.Parent
	if not parent then showStatus("✗ ModuleScript tidak memiliki induk.", true) return end
	local usageFolder = parent:FindFirstChild("GeneratedUsage")
	if not usageFolder then
		usageFolder = Instance.new("Folder")
		usageFolder.Name = "GeneratedUsage"
		usageFolder.Parent = parent
	end

	local rootObject = sel[2] -- Asumsikan objek root adalah item kedua yang dipilih
	if not rootObject or not (rootObject:IsA("ScreenGui") or rootObject:IsA("SurfaceGui")) then
		-- Fallback jika objek root tidak disediakan atau tidak valid
		local selRoot = Selection:Get()
		if selRoot and #selRoot > 0 and (selRoot[1]:IsA("ScreenGui") or selRoot[1]:IsA("SurfaceGui")) then
			rootObject = selRoot[1]
		end
	end

	local exampleCode = Utils.generateExampleCode(moduleScript, rootObject)
	local exampleScript = Instance.new("LocalScript")
	exampleScript.Name = "usage_for_" .. moduleScript.Name
	exampleScript.Source = exampleCode
	exampleScript.Parent = usageFolder
	Selection:Set({exampleScript})
	showStatus("✓ Contoh skrip penggunaan dibuat!", false)
end)

-- ----------------------------------------------------------------
-- Fitur Sinkronisasi Balik
-- ----------------------------------------------------------------

-- Fungsi pembantu baru untuk menemukan turunan secara rekursif berdasarkan path string
local function findDescendantByPath(root, path)
	local current = root
	for part in path:gmatch("([^%.]+)") do
		current = current:FindFirstChild(part)
		if not current then
			return nil -- Jika ada bagian dari path yang tidak ditemukan
		end
	end
	return current
end

local function applyChangesFromScript()
	local sel = Selection:Get()
	if not sel or #sel == 0 or not sel[1]:IsA("Script") then
		showStatus("✗ Pilih skrip untuk menerapkan perubahan.", true)
		return
	end
	local script = sel[1]

	showStatus("i Menganalisis skrip...", false)

	local parsedData, err = ScriptParser.parse(script.Source)
	if not parsedData then
		showStatus("✗ " .. (err or "Gagal menganalisis skrip."), true)
		return
	end

	if not parsedData.sourcePath then
		showStatus("✗ Tidak dapat menemukan path sumber di dalam skrip.", true)
		return
	end

	local rootInstance = game:FindFirstChild(parsedData.sourcePath, true)
	if not rootInstance then
		showStatus("✗ GUI asli di '" .. parsedData.sourcePath .. "' tidak ditemukan.", true)
		return
	end

	local appliedChanges = 0
	local failedChanges = 0

	for varName, props in pairs(parsedData.properties) do
		local relPath = parsedData.varPathMap[varName]
		local targetInstance

		if relPath == rootInstance.Name then -- Jika itu adalah root instance itu sendiri
			targetInstance = rootInstance
		else
			-- Hapus nama root dari awal path
			local cleanRelPath = relPath:gsub("^" .. rootInstance.Name .. ".", "")
			targetInstance = findDescendantByPath(rootInstance, cleanRelPath)
		end

		if targetInstance then
			for propName, valueString in pairs(props) do
				local value, deserializeErr = Utils.deserializeValue(valueString)

				if not deserializeErr then
					local success, setErr = pcall(function()
						targetInstance[propName] = value
					end)

					if success then
						appliedChanges = appliedChanges + 1
					else
						warn(string.format("[GUIConvert] Gagal menerapkan properti %s ke %s: %s", propName, targetInstance:GetFullName(), tostring(setErr)))
						failedChanges = failedChanges + 1
					end
				else
					warn(string.format("[GUIConvert] Gagal mendeserialisasi '%s' untuk %s.%s: %s", valueString, targetInstance:GetFullName(), propName, tostring(deserializeErr)))
					failedChanges = failedChanges + 1
				end
			end
		else
			warn("[GUIConvert] Tidak dapat menemukan instance untuk path relatif:", relPath)
			failedChanges = failedChanges + #props -- Hitung semua properti di bawahnya sebagai gagal
		end
	end

	local summary = string.format("✓ %d perubahan diterapkan.", appliedChanges)
	if failedChanges > 0 then
		summary = summary .. string.format(" (%d gagal)", failedChanges)
	end
	showStatus(summary, failedChanges > 0)

	-- Pilih root instance di explorer untuk menunjukkan pekerjaan selesai
	Selection:Set({rootInstance})
end


-- ----------------------------------------------------------------
-- PERBAIKAN DIMULAI DI SINI
-- ----------------------------------------------------------------

-- Buat fungsi khusus untuk menangani pembaruan UI pemilihan
local function updateSelectionUI()
	local sel = Selection:Get()
	local obj = sel and #sel == 1 and sel[1] or nil

	-- Atur ulang semua status tombol terlebih dahulu
	controls.IgnoreButton.Visible = false
	controls.SetScriptTypeEnabled(true)
	controls.SetApplyButtonEnabled(false)

	if not obj then
		controls.SelectionLabel.Text = "Terpilih: Tidak ada"
		controls.SelectionLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		return
	end

	if obj:IsA("Script") then
		controls.SelectionLabel.Text = string.format("Terpilih: %s (Script)", obj.Name)
		controls.SelectionLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
		controls.SetApplyButtonEnabled(true) -- Aktifkan tombol terapkan
		controls.SetScriptTypeEnabled(false) -- Nonaktifkan tombol tipe skrip
	elseif (Utils.isGuiObject(obj) or obj:IsA("ScreenGui")) then
		controls.SelectionLabel.Text = string.format("Terpilih: %s (%s)", obj.Name, obj.ClassName)
		controls.SelectionLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
		local isIgnored = obj:GetAttribute("ConvertIgnore") == true
		controls.IgnoreButton.Visible = true
		if isIgnored then
			controls.IgnoreButton.BackgroundColor3 = Color3.fromRGB(180, 80, 80)
			controls.IgnoreButton.Text = " [X] Abaikan Objek & Turunannya"
		else
			controls.IgnoreButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			controls.IgnoreButton.Text = " [ ] Abaikan Objek & Turunannya"
		end

		if obj:IsA("SurfaceGui") then
			controls.ScriptTypeButton.Text = "ModuleScript"
			controls.SetScriptTypeEnabled(false)
		end
	else
		controls.SelectionLabel.Text = "Terpilih: Objek tidak valid"
		controls.SelectionLabel.TextColor3 = Color3.fromRGB(255, 180, 180)
	end
end

-- Hubungkan sinyal ke fungsi baru
Selection.SelectionChanged:Connect(function()
	updateSelectionUI()
	updateCodePreview()
end)

controls.IgnoreButton.MouseButton1Click:Connect(function()
	local sel = Selection:Get()
	local obj = sel and sel[1]
	if obj and (Utils.isGuiObject(obj) or obj:IsA("ScreenGui")) then
		local isIgnored = obj:GetAttribute("ConvertIgnore") == true
		obj:SetAttribute("ConvertIgnore", not isIgnored)

		-- PERBAIKAN: Panggil fungsi secara langsung, bukan :Fire()
		updateSelectionUI()
		updateCodePreview()

		if syncingInstance then reSync() end
	end
end)

-- Inisialisasi status UI awal
-- PERBAIKAN: Panggil fungsi secara langsung, bukan :Fire()
updateSelectionUI()

controls.ApplyFromScriptButton.MouseButton1Click:Connect(applyChangesFromScript)

controls.SelectLocationButton.MouseButton1Click:Connect(function()
	showStatus("ℹ️ Pilih folder di Explorer lalu klik tombol ini lagi.", false)

	local sel = Selection:Get()
	if sel and #sel > 0 then
		local chosen = sel[1]
		if chosen:IsA("Folder") or chosen:IsA("ReplicatedStorage") or chosen:IsA("StarterPlayerScripts") then
			outputLocation = chosen
			updateLocationLabel()
			showStatus("✓ Lokasi output diatur ke: " .. chosen:GetFullName(), false)
		else
			showStatus("✗ Lokasi tidak valid. Silakan pilih Folder.", true)
		end
	end
end)

controls.ExportProfileButton.MouseButton1Click:Connect(function()
	local profile = blacklistProfiles[activeProfileName]
	if not profile then
		showStatus("✗ Tidak ada profil aktif untuk diekspor.", true)
		return
	end

	local success, encoded = pcall(HttpService.JSONEncode, HttpService, profile)
	if success then
		controls.ImportExportTextBox.Text = encoded
		controls.ImportExportModal.Title = "Ekspor Profil: " .. activeProfileName
		controls.ImportExportModal.Visible = true
		controls.ImportExportConfirmButton.Text = "Tutup" -- Hanya ada aksi tutup untuk ekspor
	else
		showStatus("✗ Gagal mengenkode profil untuk ekspor.", true)
		warn("[GUIConvert] Gagal mengenkode profil JSON:", encoded)
	end
end)

controls.ImportProfileButton.MouseButton1Click:Connect(function()
	controls.ImportExportTextBox.Text = "" -- Bersihkan untuk input
	controls.ImportExportTextBox.PlaceholderText = "Tempelkan data profil JSON di sini..."
	controls.ImportExportModal.Title = "Impor Profil Baru"
	controls.ImportExportModal.Visible = true
	controls.ImportExportConfirmButton.Text = "Impor"
end)

controls.ImportExportConfirmButton.MouseButton1Click:Connect(function()
	if controls.ImportExportConfirmButton.Text == "Tutup" then
		controls.ImportExportModal.Visible = false
		return
	end

	-- Logika impor
	local text = controls.ImportExportTextBox.Text
	if text == "" then
		showStatus("✗ Kotak teks kosong. Tidak ada yang diimpor.", true)
		return
	end

	local success, decoded = pcall(HttpService.JSONDecode, HttpService, text)
	if not success then
		showStatus("✗ Data JSON tidak valid.", true)
		warn("[GUIConvert] Gagal mendekode JSON impor:", decoded)
		return
	end

	-- Validasi tipe data yang didekode
	if type(decoded) ~= "table" then
		showStatus("✗ JSON harus berupa array string.", true)
		return
	end
	for _, val in ipairs(decoded) do
		if type(val) ~= "string" then
			showStatus("✗ JSON harus berupa array string.", true)
			return
		end
	end

	-- Minta nama untuk profil baru
	local newName = controls.ProfileNameInput.Text
	if newName == "" or blacklistProfiles[newName] then
		newName = "Profil Impor " .. os.date("%H%M%S")
	end

	blacklistProfiles[newName] = decoded
	table.sort(blacklistProfiles[newName])
	saveBlacklistProfiles()
	applyBlacklistProfile(newName)

	showStatus("✓ Profil '" .. newName .. "' berhasil diimpor.", false)
	controls.ImportExportModal.Visible = false
	controls.ProfileNameInput.Text = "" -- Reset input name
end)

controls.ImportExportCloseButton.MouseButton1Click:Connect(function()
	controls.ImportExportModal.Visible = false
end)

controls.ManageProfilesButton.MouseButton1Click:Connect(function()
	controls.updateProfileList(blacklistProfiles, activeProfileName) -- Selalu perbarui daftar saat dibuka
	controls.ProfileManagerModal.Visible = true
end)

controls.ProfileManagerCloseButton.MouseButton1Click:Connect(function()
	controls.ProfileManagerModal.Visible = false
end)

local function setPasteButtonEnabled(enabled)
	controls.PasteStyleButton.Selectable = enabled
	controls.PasteStyleButton.AutoButtonColor = enabled
	if enabled then
		controls.PasteStyleButton.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
		controls.PasteStyleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	else
		controls.PasteStyleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		controls.PasteStyleButton.TextColor3 = Color3.fromRGB(150, 150, 150)
	end
end

local function copyStyle()
	local sel = Selection:Get()
	local source = sel and #sel == 1 and sel[1] or nil
	if not source or not source:IsA("GuiObject") then
		showStatus("✗ Pilih satu GuiObject untuk menyalin gayanya.", true)
		return
	end

	copiedStyle = {
		Properties = {},
		Children = {}
	}

	local relevantProps = {
		"AnchorPoint", "AutomaticSize", "Position", "Rotation", "Size", "SizeConstraint",
		"BackgroundColor3", "BackgroundTransparency", "BorderSizePixel", "BorderColor3", "BorderMode",
		"Image", "ImageTransparency", "ImageColor3", "ScaleType", "SliceCenter", "SliceScale",
		"Text", "TextColor3", "TextSize", "TextScaled", "Font", "TextWrapped", "TextXAlignment", "TextYAlignment",
		"FontFace", "LineHeight", "RichText"
	}

	for _, propName in ipairs(relevantProps) do
		local success, value = pcall(function() return source[propName] end)
		if success then
			copiedStyle.Properties[propName] = value
		end
	end

	for _, child in ipairs(source:GetChildren()) do
		local childClass = child.ClassName
		if childClass == "UICorner" or childClass == "UIStroke" or childClass == "UIGradient" or childClass == "UIPadding" then
			copiedStyle.Children[childClass] = copiedStyle.Children[childClass] or {}
			local childProps = PROPERTIES_BY_CLASS[childClass] or {}
			for _, propName in ipairs(childProps) do
				local success, value = pcall(function() return child[propName] end)
				if success then
					copiedStyle.Children[childClass][propName] = value
				end
			end
		end
	end

	setPasteButtonEnabled(true)
	showStatus("✓ Gaya disalin dari '" .. source.Name .. "'.", false)
end

controls.CopyStyleButton.MouseButton1Click:Connect(copyStyle)

local pasteCheckboxes = {}
local function pasteStyle()
	local sel = Selection:Get()
	if not sel or #sel == 0 then
		showStatus("✗ Pilih satu atau lebih GuiObject target untuk menempel gaya.", true)
		return
	end
	if not copiedStyle then
		showStatus("✗ Salin gaya terlebih dahulu!", true)
		return
	end

	-- Hapus item lama dan reset
	local listFrame = controls.PasteStyleListFrame
	for _, child in ipairs(listFrame:GetChildren()) do
		if child:IsA("GuiObject") and not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
	pasteCheckboxes = {}

	-- Buat checkbox helper
	local function createCheckbox(text, group, propName, isChild)
		local isToggled = true -- Default ke terpilih
		local row = Instance.new("TextButton")
		row.Name = text
		row.Size = UDim2.new(1, 0, 0, 24)
		row.Font = Enum.Font.SourceSans
		row.TextSize = 14
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Parent = listFrame

		local function updateVisuals()
			if isToggled then
				row.Text = "  [X] " .. text
				row.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			else
				row.Text = "  [ ] " .. text
				row.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
			end
		end

		row.MouseButton1Click:Connect(function()
			isToggled = not isToggled
			updateVisuals()
		end)

		updateVisuals()
		table.insert(pasteCheckboxes, {
			IsToggled = function() return isToggled end,
			Group = group,
			PropName = propName,
			IsChild = isChild,
		})
	end

	-- Isi dengan properti utama
	for propName, _ in pairs(copiedStyle.Properties) do
		createCheckbox(propName, "Properties", propName, false)
	end

	-- Isi dengan properti turunan
	for childClass, props in pairs(copiedStyle.Children) do
		local header = Instance.new("TextLabel")
		header.Size = UDim2.new(1, 0, 0, 26)
		header.Text = "  ▾ " .. childClass
		header.Font = Enum.Font.SourceSansBold
		header.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.Parent = listFrame
		for propName, _ in pairs(props) do
			createCheckbox("  " .. propName, childClass, propName, true)
		end
	end

	controls.PasteStyleModal.Visible = true
end

controls.PasteStyleButton.MouseButton1Click:Connect(pasteStyle)

controls.CancelStyleButton.MouseButton1Click:Connect(function()
	controls.PasteStyleModal.Visible = false
end)

controls.ApplyStyleButton.MouseButton1Click:Connect(function()
	local sel = Selection:Get()
	if not sel or #sel == 0 or not copiedStyle then return end

	local changesApplied = 0
	for _, target in ipairs(sel) do
		if target:IsA("GuiObject") then
			for _, checkbox in ipairs(pasteCheckboxes) do
				if checkbox:IsToggled() then
					local propName = checkbox.PropName
					local group = checkbox.Group

					if checkbox.IsChild then
						-- Handle child properties (e.g., UICorner.CornerRadius)
						local child = target:FindFirstChildOfClass(group)
						if not child then
							child = Instance.new(group)
							child.Parent = target
						end
						local value = copiedStyle.Children[group][propName]
						local ok, err = pcall(function() child[propName] = value end)
						if ok then changesApplied = changesApplied + 1 else warn(err) end
					else
						-- Handle main object properties
						local value = copiedStyle.Properties[propName]
						local ok, err = pcall(function() target[propName] = value end)
						if ok then changesApplied = changesApplied + 1 else warn(err) end
					end
				end
			end
		end
	end

	controls.PasteStyleModal.Visible = false
	showStatus(string.format("✓ %d gaya diterapkan pada %d objek.", changesApplied, #sel), false)
end)

local function insertComponentCode()
	local sel = Selection:Get()
	if #sel ~= 2 then
		showStatus("✗ Pilih DUA objek: komponen ModuleScript & skrip target.", true)
		return
	end

	local componentScript, targetScript
	for _, obj in ipairs(sel) do
		if obj:IsA("ModuleScript") and obj:IsDescendantOf(game:GetService("ReplicatedStorage")) then
			componentScript = obj
		elseif obj:IsA("Script") or obj:IsA("ModuleScript") then
			targetScript = obj
		end
	end

	if not componentScript or not targetScript then
		showStatus("✗ Pilih komponen ModuleScript & skrip target.", true)
		return
	end

	local componentName = componentScript.Name
	local componentVarName = componentName .. "Module"
	local componentPath = componentScript:GetFullName():gsub("ReplicatedStorage", "game:GetService(\"ReplicatedStorage\")")

	local source = targetScript.Source

	-- 1. Sisipkan 'require' jika belum ada
	local requireLine = string.format("local %s = require(%s)", componentVarName, componentPath)
	if not source:find(requireLine, 1, true) then
		-- Cari baris kosong pertama setelah blok variabel atau di awal file
		local _, endOfVars = source:find("%)%s*\n\n") -- setelah GetService() block
		if endOfVars then
			source = source:sub(1, endOfVars) .. requireLine .. "\n" .. source:sub(endOfVars + 1)
		else
			source = requireLine .. "\n" .. source
		end
	end

	-- 2. Sisipkan baris 'create' di dalam USER_CODE block
	local createLine = string.format("local new%s = %s.create()", componentName, componentVarName)
	local userCodeStart = "--// USER_CODE_START"
	local startIdx, endIdx = source:find(userCodeStart, 1, true)

	if startIdx then
		local insertPos = startIdx + #userCodeStart
		source = source:sub(1, insertPos) .. "\n" .. createLine .. source:sub(insertPos + 1)
	else
		source = source .. "\n\n" .. userCodeStart .. "\n" .. createLine .. "\n--// USER_CODE_END\n"
	end

	targetScript.Source = source
	plugin:OpenScript(targetScript)
	showStatus("✓ Kode komponen '"..componentName.."' disisipkan.", false)
end

controls.InsertComponentButton.MouseButton1Click:Connect(insertComponentCode)
