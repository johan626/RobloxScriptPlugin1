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

-- Pre-declare functions for mutual recursion / ordering
local reSync
local showStatus 
local connectInstance
local disconnectInstance
local saveBlacklistProfiles
local applyBlacklistProfile
local updateCodePreview

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

	controls.updateProfileDropdown(blacklistProfiles, activeProfileName)
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
	UITextSizeConstraint = {"MaxTextSize", "MinTextSize"}
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
	local scriptInstance, folderName, parentService
	if settings.ScriptType == "ModuleScript" then
		scriptInstance = Instance.new("ModuleScript")
		folderName = "GeneratedGuis"
		parentService = game:GetService("ReplicatedStorage")
	else
		scriptInstance = Instance.new("LocalScript")
		folderName = "GeneratedLocalGuis"
		parentService = StarterPlayer:FindFirstChild("StarterPlayerScripts") or Instance.new("Folder", StarterPlayer)
		parentService.Name = "StarterPlayerScripts"
	end

	local targetFolder = parentService:FindFirstChild(folderName) or Instance.new("Folder", parentService)
	targetFolder.Name = folderName

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
		local settings = {
			ScriptType = controls.ScriptTypeButton.Text,
			AddTraceComments = controls.IsCommentsEnabled(),
			OverwriteExisting = controls.IsOverwriteEnabled(),
			PropertyBlacklist = blacklistJson,
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
	local settings = {
		ScriptType = plugin:GetSetting("ScriptType") or "ModuleScript",
		AddTraceComments = plugin:GetSetting("AddTraceComments") ~= false,
		OverwriteExisting = plugin:GetSetting("OverwriteExisting") ~= false,
		PropertyBlacklist = plugin:GetSetting("PropertyBlacklist") or HttpService:JSONEncode({"Position", "Size"}),
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
applyBlacklistProfile(activeProfileName)

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

controls.ConvertButton.MouseButton1Click:Connect(function()
	local blacklistedProps = {}
	for propName, checkboxData in pairs(controls.BlacklistCheckboxes) do
		if checkboxData.IsBlacklisted() then
			table.insert(blacklistedProps, propName)
		end
	end
	table.sort(blacklistedProps)
	local blacklistJson = HttpService:JSONEncode(blacklistedProps)
	local settings = {
		ScriptType = controls.ScriptTypeButton.Text,
		AddTraceComments = controls.IsCommentsEnabled(),
		OverwriteExisting = controls.IsOverwriteEnabled(),
		PropertyBlacklist = blacklistJson,
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
	local exampleCode = Utils.generateExampleCode(moduleScript)
	local exampleScript = Instance.new("LocalScript")
	exampleScript.Name = "usage_for_" .. moduleScript.Name
	exampleScript.Source = exampleCode
	exampleScript.Parent = usageFolder
	Selection:Set({exampleScript})
	showStatus("✓ Contoh skrip penggunaan dibuat!", false)
end)

-- ----------------------------------------------------------------
-- PERBAIKAN DIMULAI DI SINI
-- ----------------------------------------------------------------

-- Buat fungsi khusus untuk menangani pembaruan UI pemilihan
local function updateSelectionUI()
	local sel = Selection:Get()
	local obj = sel and sel[1]
	if obj and (Utils.isGuiObject(obj) or obj:IsA("ScreenGui")) then
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
		-- Daftar Hitam Otomatis Cerdas
		if obj:IsA("UIListLayout") or obj:IsA("UIGridLayout") then
			controls.setBlacklistState("Position", true)
			controls.setBlacklistState("Size", true)
		end
	else
		controls.IgnoreButton.Visible = false
		if obj then
			controls.SelectionLabel.Text = "Terpilih: Objek tidak valid"
			controls.SelectionLabel.TextColor3 = Color3.fromRGB(255, 180, 180)
		else
			controls.SelectionLabel.Text = "Terpilih: Tidak ada"
			controls.SelectionLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		end
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
