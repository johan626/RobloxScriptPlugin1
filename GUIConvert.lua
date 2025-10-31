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

-- Pre-declare functions for mutual recursion / ordering
local reSync
local showStatus 

-- Daftar properti yang akan diserialisasi
local COMMON_PROPERTIES = {
	"Name","AnchorPoint","AutomaticSize","Position","Rotation","Size","Visible","ZIndex","LayoutOrder",
	"BackgroundColor3","BackgroundTransparency","BorderSizePixel","Image","ImageTransparency","ImageColor3","ScaleType","SliceCenter","SliceScale","ImageRectOffset","ImageRectSize","ClipsDescendants",
	"Text","TextColor3","TextSize","TextScaled","Font","TextWrapped","TextXAlignment","TextYAlignment","TextTransparency","TextStrokeTransparency","TextStrokeColor3","PlaceholderText","PlaceholderColor3","TextEditable",
	"AutoButtonColor","ResetOnSpawn","Selectable","Modal","Style"
}
local PROPERTIES_BY_CLASS = {
	UICorner = {"CornerRadius"},
	UIGradient = {"Color", "Enabled", "Offset", "Rotation", "Transparency"},
	UIStroke = {"ApplyStrokeMode", "Color", "Enabled", "LineJoinMode", "Thickness", "Transparency"},
	UIAspectRatioConstraint = {"AspectRatio", "AspectType", "DominantAxis"},
	UIGridLayout = {"AbsoluteContentSize", "CellPadding", "CellSize", "FillDirection", "HorizontalAlignment", "SortOrder", "StartCorner", "VerticalAlignment"},
	UIListLayout = {"AbsoluteContentSize", "FillDirection", "HorizontalAlignment", "Padding", "SortOrder", "VerticalAlignment"},
	UIPadding = {"PaddingBottom", "PaddingLeft", "PaddingRight", "PaddingTop"},
	UIScale = {"Scale"},
	UISizeConstraint = {"MaxSize", "MinSize"},
	UITextSizeConstraint = {"MaxTextSize", "MinTextSize"}
}

-- Definisi Fungsi Inti

local function stopSyncing()
	if not syncingInstance then return end
	print("[GUIConvert] Menghentikan sinkronisasi untuk " .. syncingInstance:GetFullName())
	for _, connection in ipairs(syncConnections) do
		connection:Disconnect()
	end
	syncConnections = {}
	syncingInstance = nil
	syncingScript = nil
	if debounceTimer then task.cancel(debounceTimer) end
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
			controls.StatusLabel.Text = "Status: Tersinkronisasi"
			controls.StatusLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
		else
			warn("[GUIConvert] Gagal melakukan sinkronisasi ulang:", generated)
			controls.StatusLabel.Text = "Status: Kesalahan Sinkronisasi!"
			controls.StatusLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
		end
	end)
end

local function startSyncing(guiObject, script, settings)
	stopSyncing()
	syncingInstance = guiObject
	syncingScript = script
	lastSyncSettings = settings

	local function connectInstance(inst)
		local propsToWatch, propSet = {}, {}
		if inst:IsA("GuiObject") then
			for _, prop in ipairs(COMMON_PROPERTIES) do if not propSet[prop] then table.insert(propsToWatch, prop); propSet[prop] = true end end
		end
		local classSpecificProps = PROPERTIES_BY_CLASS[inst.ClassName]
		if classSpecificProps then
			for _, prop in ipairs(classSpecificProps) do if not propSet[prop] then table.insert(propsToWatch, prop); propSet[prop] = true end end
		end

		for _, prop in ipairs(propsToWatch) do
			local success, signal = pcall(function()
				return inst:GetPropertyChangedSignal(prop)
			end)
			if success and signal then
				table.insert(syncConnections, signal:Connect(reSync))
			end
		end
	end

	for _, inst in ipairs(guiObject:GetDescendants()) do connectInstance(inst) end
	connectInstance(guiObject)
	table.insert(syncConnections, guiObject.DescendantAdded:Connect(function(d) connectInstance(d); reSync() end))
	table.insert(syncConnections, guiObject.DescendantRemoving:Connect(reSync))

	print("[GUIConvert] Memulai sinkronisasi untuk " .. guiObject:GetFullName())
	controls.StatusLabel.Text = "Status: Sinkronisasi aktif"
	controls.StatusLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
	controls.StatusLabel.Visible = true
end

local function performConversion(settings)
	local sel = Selection:Get()
	if not sel or #sel == 0 then
		return nil, "Pilih ScreenGui atau root GuiObject di Explorer."
	end
	local root = sel[1]
	if not Utils.isGuiObject(root) and not root:IsA("ScreenGui") then
		return nil, "Objek terpilih bukan GuiObject/ScreenGui."
	end

	local success, generated = pcall(generateLuaForGui, root, settings)
	if not success then
		warn("Kesalahan pembuatan kode:", generated)
		return nil, "Gagal menghasilkan kode. Periksa Output untuk detail."
	end

	return generated, root
end

local function createFile(generated, rootName, settings)
	local starterScripts = StarterPlayer:FindFirstChild("StarterPlayerScripts") or Instance.new("Folder", StarterPlayer)
	starterScripts.Name = "StarterPlayerScripts"

	local scriptInstance, folderName
	if settings.ScriptType == "ModuleScript" then
		scriptInstance, folderName = Instance.new("ModuleScript"), "GeneratedGuis"
	else
		scriptInstance, folderName = Instance.new("LocalScript"), "GeneratedLocalGuis"
	end

	local targetFolder = starterScripts:FindFirstChild(folderName) or Instance.new("Folder", starterScripts)
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
			return string.format("%s '%s' berhasil diperbarui.", settings.ScriptType, existing.Name), existing
		end
	end

	scriptInstance.Source = generated
	scriptInstance.Parent = targetFolder

	return string.format("%s '%s' berhasil dibuat.", settings.ScriptType, scriptInstance.Name), scriptInstance
end

local function handleContextualConversion(selection)
	local settings = {
		ScriptType = plugin:GetSetting("ScriptType") or "ModuleScript",
		AddTraceComments = plugin:GetSetting("AddTraceComments") ~= false,
		OverwriteExisting = plugin:GetSetting("OverwriteExisting") ~= false,
		PropertyBlacklist = plugin:GetSetting("PropertyBlacklist") or HttpService:JSONEncode({"Position", "Size"}),
	}
	local root = selection and selection[1]
	if not root then
		showStatus("✗ Tidak ada objek yang dipilih untuk konversi kontekstual.", true)
		return
	end
	if not (Utils.isGuiObject(root) or root:IsA("ScreenGui")) then
		showStatus("✗ Objek yang dipilih tidak valid untuk konversi.", true)
		return
	end
	local success, generated = pcall(generateLuaForGui, root, settings)
	if not success then
		showStatus("✗ Gagal menghasilkan kode.", true)
		warn("[GUIConvert] Gagal menghasilkan kode:", generated)
		return
	end
	local resultName = root.Name
	local successMsg, _ = createFile(generated, resultName, settings)
	showStatus("✓ " .. successMsg, false)
end

-- Inisialisasi UI
local uiSettings = {
	COMMON_PROPERTIES = COMMON_PROPERTIES,
	PROPERTIES_BY_CLASS = PROPERTIES_BY_CLASS,
	stopSyncing = stopSyncing,
}
controls = UI.create(configWidget, plugin, uiSettings)

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
		LiveSyncEnabled = controls.IsLiveSyncEnabled()
	}
	local generated, rootObject = performConversion(settings)
	if generated then
		local successMsg, scriptInstance = createFile(generated, rootObject.Name, settings)
		plugin:SetSetting("ScriptType", settings.ScriptType)
		plugin:SetSetting("AddTraceComments", settings.AddTraceComments)
		plugin:SetSetting("OverwriteExisting", settings.OverwriteExisting)
		plugin:SetSetting("PropertyBlacklist", settings.PropertyBlacklist)
		plugin:SetSetting("LiveSyncEnabled", settings.LiveSyncEnabled)
		if settings.LiveSyncEnabled then
			startSyncing(rootObject, scriptInstance, settings)
		else
			stopSyncing()
			showStatus("✓ " .. successMsg, false)
		end
	else
		showStatus("✗ " .. rootObject, true)
		stopSyncing()
	end
end)

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
Selection.SelectionChanged:Connect(updateSelectionUI)

controls.IgnoreButton.MouseButton1Click:Connect(function()
	local sel = Selection:Get()
	local obj = sel and sel[1]
	if obj and (Utils.isGuiObject(obj) or obj:IsA("ScreenGui")) then
		local isIgnored = obj:GetAttribute("ConvertIgnore") == true
		obj:SetAttribute("ConvertIgnore", not isIgnored)

		-- PERBAIKAN: Panggil fungsi secara langsung, bukan :Fire()
		updateSelectionUI()

		if syncingInstance then reSync() end
	end
end)

-- Inisialisasi status UI awal
-- PERBAIKAN: Panggil fungsi secara langsung, bukan :Fire()
updateSelectionUI()
