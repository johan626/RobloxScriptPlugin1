-- GUI → LocalScript Plugin for Roblox Studio
-- Bahasa: Indonesian
-- Usage: Select a ScreenGui (atau Frame/any GuiObject root) di Explorer, lalu klik toolbar "GUI Tools" -> "Convert GUI to LocalScript".
-- Plugin akan membuat sebuah LocalScript di StarterPlayer > StarterPlayerScripts bernama "GeneratedGui_<NamaGUI>".
-- LocalScript yang dihasilkan akan membuat ulang hirarki GUI dan menyet properti-properti umum.
-- Catatan: Event/Connections, Functions, dan beberapa property khusus tidak diserialisasi.

local Selection = game:GetService("Selection")
local StarterPlayer = game:GetService("StarterPlayer")

local toolbar = plugin:CreateToolbar("GUI Tools")
local button = toolbar:CreateButton("Convert GUI to LocalScript", "Convert selected GUI into a LocalScript that recreates it", "rbxassetid://4458901886")

-- UI Konfigurasi untuk Plugin
local configWidget = plugin:CreateDockWidgetPluginGui("GUIConverterConfig", DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float, true, false, 220, 280 -- Ukuran tetap
	))
configWidget.Title = "GUI Converter"

-- Membuat elemen UI secara terprogram
local function createUI()
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

	local typeLabel = Instance.new("TextLabel")
	typeLabel.LayoutOrder = 2
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
	scriptTypeButton.LayoutOrder = 3
	scriptTypeButton.Text = savedScriptType
	scriptTypeButton.Size = UDim2.new(1, 0, 0, 28)
	scriptTypeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	scriptTypeButton.TextColor3 = Color3.fromRGB(220, 220, 220)
	scriptTypeButton.Font = Enum.Font.SourceSans
	scriptTypeButton.TextSize = 14
	scriptTypeButton.Parent = mainFrame

	local savedAddComments = plugin:GetSetting("AddTraceComments")
	if savedAddComments == nil then savedAddComments = true end
	local commentsEnabled = savedAddComments

	local commentsButton = Instance.new("TextButton")
	commentsButton.Name = "CommentsButton"
	commentsButton.LayoutOrder = 4
	commentsButton.Size = UDim2.new(1, 0, 0, 28)
	commentsButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	commentsButton.TextColor3 = Color3.fromRGB(220, 220, 220)
	commentsButton.Font = Enum.Font.SourceSans
	commentsButton.TextSize = 14
	commentsButton.Parent = mainFrame

	local function updateCommentsButton()
		if commentsEnabled then
			commentsButton.Text = "✓  Add Trace Comments"
		else
			commentsButton.Text = "✗  Add Trace Comments"
		end
	end
	updateCommentsButton()

	local savedOverwrite = plugin:GetSetting("OverwriteExisting")
	if savedOverwrite == nil then savedOverwrite = true end
	local overwriteEnabled = savedOverwrite

	local overwriteButton = Instance.new("TextButton")
	overwriteButton.Name = "OverwriteButton"
	overwriteButton.LayoutOrder = 5
	overwriteButton.Size = UDim2.new(1, 0, 0, 28)
	overwriteButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	overwriteButton.TextColor3 = Color3.fromRGB(220, 220, 220)
	overwriteButton.Font = Enum.Font.SourceSans
	overwriteButton.TextSize = 14
	overwriteButton.Parent = mainFrame

	local function updateOverwriteButton()
		if overwriteEnabled then
			overwriteButton.Text = "✓  Overwrite Existing"
		else
			overwriteButton.Text = "✗  Overwrite Existing"
		end
	end
	updateOverwriteButton()

	local convertButton = Instance.new("TextButton")
	convertButton.Name = "ConvertButton"
	convertButton.LayoutOrder = 6
	convertButton.Text = "Convert"
	convertButton.Size = UDim2.new(1, 0, 0, 32)
	convertButton.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
	convertButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	convertButton.Font = Enum.Font.SourceSansBold
	convertButton.TextSize = 16
	convertButton.Parent = mainFrame

	local exampleCodeButton = Instance.new("TextButton")
	exampleCodeButton.Name = "ExampleCodeButton"
	exampleCodeButton.LayoutOrder = 7
	exampleCodeButton.Text = "Get Example Code"
	exampleCodeButton.Size = UDim2.new(1, 0, 0, 28)
	exampleCodeButton.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
	exampleCodeButton.TextColor3 = Color3.fromRGB(220, 220, 220)
	exampleCodeButton.Font = Enum.Font.SourceSans
	exampleCodeButton.TextSize = 14
	exampleCodeButton.Parent = mainFrame

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.LayoutOrder = 8
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
		ScriptTypeButton = scriptTypeButton,
		IsCommentsEnabled = function() return commentsEnabled end,
		IsOverwriteEnabled = function() return overwriteEnabled end,
		ConvertButton = convertButton,
		ExampleCodeButton = exampleCodeButton,
		StatusLabel = statusLabel,
	}
end

local controls = createUI()

-- Daftar properti GUI yang akan di-serialize
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

local function isGuiObject(inst)
	return inst and inst:IsA("GuiObject")
end

local function quoteString(s)
	return string.format("%q", tostring(s))
end

local function serializeValue(v)
	local t = typeof(v)
	if t == "UDim2" then
		return string.format("UDim2.new(%s,%s,%s,%s)", tostring(v.X.Scale), tostring(v.X.Offset), tostring(v.Y.Scale), tostring(v.Y.Offset))
	elseif t == "UDim" then
		return string.format("UDim.new(%s,%s)", tostring(v.Scale), tostring(v.Offset))
	elseif t == "Vector2" then
		return string.format("Vector2.new(%s,%s)", tostring(v.X), tostring(v.Y))
	elseif t == "Vector3" then
		return string.format("Vector3.new(%s,%s,%s)", tostring(v.X), tostring(v.Y), tostring(v.Z))
	elseif t == "Color3" then
		local r = math.floor(v.R * 255 + 0.5)
		local g = math.floor(v.G * 255 + 0.5)
		local b = math.floor(v.B * 255 + 0.5)
		return string.format("Color3.fromRGB(%d,%d,%d)", r, g, b)
	elseif t == "ColorSequence" then
		local keypoints = {}
		for _, keypoint in ipairs(v.Keypoints) do
			table.insert(keypoints, string.format("ColorSequenceKeypoint.new(%s, %s)", tostring(keypoint.Time), serializeValue(keypoint.Value)))
		end
		return string.format("ColorSequence.new({%s})", table.concat(keypoints, ", "))
	elseif t == "NumberSequence" then
		local keypoints = {}
		for _, keypoint in ipairs(v.Keypoints) do
			table.insert(keypoints, string.format("NumberSequenceKeypoint.new(%s, %s)", tostring(keypoint.Time), tostring(keypoint.Value)))
		end
		return string.format("NumberSequence.new({%s})", table.concat(keypoints, ", "))
	elseif t == "EnumItem" then
		return tostring(v)
	elseif t == "boolean" then
		return tostring(v)
	elseif t == "number" then
		return tostring(v)
	elseif t == "string" then
		return quoteString(v)
	else
		return quoteString(tostring(v))
	end
end

local function generateSafeVarName(s)
	if not s or s == "" then return "obj" end
	local name = tostring(s):gsub("%s+(%w)", function(c) return c:upper() end):gsub("[^%w_]", "")
	if name:match("^[0-9]") then name = "v" .. name end
	if #name > 0 then name = name:sub(1,1):lower() .. name:sub(2) end
	if name == "" then return "unnamedGui" end
	return name
end

local classDefaults = {}
local function getClassDefaultValue(className, prop)
	if classDefaults[className] == nil then
		local ok, inst = pcall(function() return Instance.new(className) end)
		classDefaults[className] = (ok and inst) and inst or false
	end
	local inst = classDefaults[className]
	if not inst then return nil, false end
	local ok, val = pcall(function() return inst[prop] end)
	if ok then return val, true end
	return nil, false
end

local function getRelativePath(instance, root)
	local path = {}
	local current = instance
	while current and current ~= root do
		table.insert(path, 1, current.Name)
		current = current.Parent
	end
	if current == root then
		table.insert(path, 1, root.Name)
		return table.concat(path, ".")
	else
		return instance:GetFullName() -- Fallback
	end
end

local function valuesEqual(a, b)
	if a == nil and b == nil then return true end
	if a == nil or b == nil then return false end
	local ta, tb = typeof(a), typeof(b)
	if ta ~= tb then return false end
	if ta == "UDim2" or ta == "UDim" or ta == "Vector2" or ta == "Vector3" or ta == "Color3" or ta == "EnumItem" or ta == "boolean" or ta == "number" or ta == "string" then
		return a == b
	end
	return tostring(a) == tostring(b)
end

local function collectGuiInstances(root)
	local list = {}
	local queue = {root}
	while #queue > 0 do
		local node = table.remove(queue, 1)
		table.insert(list, node)
		for _, child in ipairs(node:GetChildren()) do
			if child:IsA("GuiBase") or child:IsA("UIBase") then
				table.insert(queue, child)
			end
		end
	end
	return list
end

local function generateLuaForGui(root, settings)
	settings = settings or {}
	local instances = collectGuiInstances(root)
	local varMap = {}
	local lines = {}
	local rootVarName = ""

	local isModule = (settings.ScriptType == "ModuleScript")
	local indent = isModule and "\t" or ""

	if isModule then
		table.insert(lines, "-- Generated by GUI → ModuleScript plugin")
		table.insert(lines, "local module = {}")
		table.insert(lines, "")
		table.insert(lines, "function module.create(parent)")
	else
		table.insert(lines, "-- Generated by GUI → LocalScript plugin")
		table.insert(lines, "local Players = game:GetService('Players')")
		table.insert(lines, "local player = Players.LocalPlayer")
		table.insert(lines, "local playerGui = player:WaitForChild('PlayerGui')")
		table.insert(lines, "")
	end

	local nameCounts = {}
	for _, inst in ipairs(instances) do
		local baseName = generateSafeVarName(inst.Name)
		local varName = baseName
		if nameCounts[baseName] then
			nameCounts[baseName] = nameCounts[baseName] + 1
			varName = baseName .. tostring(nameCounts[baseName])
		else
			nameCounts[baseName] = 1
		end
		varMap[inst] = varName
		if inst == root then rootVarName = varName end

		local line = string.format("%slocal %s = Instance.new(%s)", indent, varName, quoteString(inst.ClassName))
		if settings.AddTraceComments then
			line = line .. string.format(" -- Original: %s", getRelativePath(inst, root))
		end
		table.insert(lines, line)
	end
	table.insert(lines, "")

	for _, inst in ipairs(instances) do
		local varName = varMap[inst]
		local propsToProcess, propSet = {}, {}

		if inst:IsA("GuiObject") then
			for _, prop in ipairs(COMMON_PROPERTIES) do if not propSet[prop] then table.insert(propsToProcess, prop); propSet[prop] = true end end
		end
		local classSpecificProps = PROPERTIES_BY_CLASS[inst.ClassName]
		if classSpecificProps then
			for _, prop in ipairs(classSpecificProps) do if not propSet[prop] then table.insert(propsToProcess, prop); propSet[prop] = true end end
		end

		if inst:IsA("Instance") then table.insert(lines, string.format("%s%s.Name = %s", indent, varName, quoteString(inst.Name))) end

		local propertyLines = {}
		for _, prop in ipairs(propsToProcess) do
			if prop ~= "Name" then
				local ok, val = pcall(function() return inst[prop] end)
				if ok and val ~= nil then
					local defaultVal, _ = getClassDefaultValue(inst.ClassName, prop)
					if not valuesEqual(val, defaultVal) and prop ~= "Parent" then
						local success, serialized = pcall(function() return serializeValue(val) end)
						if success and serialized then
							table.insert(propertyLines, string.format("%s%s.%s = %s", indent, varName, prop, serialized))
						end
					end
				end
			end
		end

		table.sort(propertyLines)
		for _, line in ipairs(propertyLines) do
			table.insert(lines, line)
		end

		local attributes = inst:GetAttributes()
		local attributeLines = {}
		for name, value in pairs(attributes) do
			local t = typeof(value)
			if t == "Instance" or t == "RBXScriptSignal" or t == "function" or t == "thread" then
				table.insert(attributeLines, string.format("%s-- Melewati atribut %s yang tidak didukung (tipe: %s)", indent, quoteString(name), t))
			else
				local success, serialized = pcall(function() return serializeValue(value) end)
				if success and serialized then
					table.insert(attributeLines, string.format('%s%s:SetAttribute(%s, %s)', indent, varName, quoteString(name), serialized))
				else
					table.insert(attributeLines, string.format("%s-- Gagal melakukan serialisasi atribut %s", indent, quoteString(name)))
				end
			end
		end

		if #attributeLines > 0 then
			table.insert(lines, "")
			table.insert(lines, string.format("%s-- Attributes", indent))
			table.sort(attributeLines)
			for _, attrLine in ipairs(attributeLines) do table.insert(lines, attrLine) end
		end

		table.insert(lines, "")
	end

	for _, inst in ipairs(instances) do
		if inst ~= root then
			local varName, parent = varMap[inst], inst.Parent
			if varMap[parent] then
				table.insert(lines, string.format("%s%s.Parent = %s", indent, varName, varMap[parent]))
			end
		end
	end

	if isModule then
		table.insert(lines, string.format("%s%s.Parent = parent", indent, rootVarName))
		table.insert(lines, "")
		table.insert(lines, indent .. "local elements = {")
		for inst, varName in pairs(varMap) do
			if inst:IsA("GuiObject") or inst:IsA("UIConstraint") then
				table.insert(lines, string.format("%s\t%s = %s,", indent, varName, varName))
			end
		end
		table.insert(lines, indent .. "}")
		table.insert(lines, "")
		table.insert(lines, string.format("%sreturn elements", indent))
		table.insert(lines, "end")
		table.insert(lines, "")
		table.insert(lines, "return module")
	else
		table.insert(lines, string.format("%s.Parent = playerGui", rootVarName))
	end

	return table.concat(lines, "\n")
end

function generateExampleCode(moduleScript)
	local path = moduleScript:GetFullName()
	-- Hapus awalan hingga dan termasuk "StarterPlayerScripts."
	path = path:gsub("^.*StarterPlayerScripts%.", "") 

	local moduleName = moduleScript.Name
	local varName = generateSafeVarName(moduleName)

	local lines = {
		string.format("-- Contoh penggunaan untuk '%s'", moduleName),
		"",
		"local Players = game:GetService('Players')",
		"",
		string.format("-- Pastikan path ini benar! Mungkin perlu disesuaikan jika Anda memindahkan skrip."),
		string.format("local %sModule = require(Players.LocalPlayer.PlayerScripts.%s)", varName, path),
		"",
		"local player = Players.LocalPlayer",
		"local playerGui = player:WaitForChild('PlayerGui')",
		"",
		string.format("local guiElements = %sModule.create(playerGui)", varName),
		"",
		"-- Sekarang Anda dapat mengakses elemen UI:",
		"-- guiElements.someButton.MouseButton1Click:Connect(function()",
		"-- 	print('Tombol ditekan!')",
		"-- end)"
	}

	return table.concat(lines, "\n")
end

local function performConversion(settings)
	local sel = Selection:Get()
	if not sel or #sel == 0 then
		return nil, "Pilih ScreenGui atau root GuiObject di Explorer."
	end
	local root = sel[1]
	if not isGuiObject(root) and not root:IsA("ScreenGui") then
		return nil, "Objek terpilih bukan GuiObject/ScreenGui."
	end

	local success, generated = pcall(function() return generateLuaForGui(root, settings) end)
	if not success then
		warn("Kesalahan pembuatan kode:", generated)
		return nil, "Gagal menghasilkan kode. Periksa Output untuk detail."
	end

	return generated, root.Name
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
			existing.Source = generated
			return string.format("%s '%s' berhasil diperbarui.", settings.ScriptType, existing.Name)
		end
	end

	scriptInstance.Source = generated
	scriptInstance.Parent = targetFolder

	return string.format("%s '%s' berhasil dibuat.", settings.ScriptType, scriptInstance.Name)
end

-- Hubungkan Logika
button.Click:Connect(function()
	configWidget.Enabled = not configWidget.Enabled
end)

local statusTimer
local function showStatus(message, isError)
	if statusTimer then task.cancel(statusTimer) end

	controls.StatusLabel.Text = message
	controls.StatusLabel.TextColor3 = isError and Color3.fromRGB(255, 120, 120) or Color3.fromRGB(120, 255, 120)
	controls.StatusLabel.Visible = true

	statusTimer = task.delay(4, function()
		controls.StatusLabel.Visible = false
		controls.StatusLabel.Text = ""
	end)
end

controls.ConvertButton.MouseButton1Click:Connect(function()
	local settings = {
		ScriptType = controls.ScriptTypeButton.Text,
		AddTraceComments = controls.IsCommentsEnabled(),
		OverwriteExisting = controls.IsOverwriteEnabled()
	}

	local generated, result = performConversion(settings)
	if generated then
		local successMsg = createFile(generated, result, settings)
		showStatus("✓ " .. successMsg, false)
		plugin:SetSetting("ScriptType", settings.ScriptType)
		plugin:SetSetting("AddTraceComments", settings.AddTraceComments)
		plugin:SetSetting("OverwriteExisting", settings.OverwriteExisting)
	else
		showStatus("✗ " .. result, true)
	end
end)

local function handleGetExampleCode()
	local sel = Selection:Get()
	if not sel or #sel == 0 then
		showStatus("✗ Pilih ModuleScript untuk membuat contoh.", true)
		return
	end

	local moduleScript = sel[1]
	if not moduleScript:IsA("ModuleScript") then
		showStatus("✗ Objek terpilih bukan ModuleScript.", true)
		return
	end

	local parent = moduleScript.Parent
	if not parent then
		showStatus("✗ ModuleScript tidak memiliki induk.", true)
		return
	end

	local usageFolder = parent:FindFirstChild("GeneratedUsage")
	if not usageFolder then
		usageFolder = Instance.new("Folder")
		usageFolder.Name = "GeneratedUsage"
		usageFolder.Parent = parent
	end

	local exampleCode = generateExampleCode(moduleScript)

	local exampleScript = Instance.new("LocalScript")
	exampleScript.Name = "usage_for_" .. moduleScript.Name
	exampleScript.Source = exampleCode
	exampleScript.Parent = usageFolder

	Selection:Set({exampleScript}) -- Pilih skrip yang baru dibuat
	showStatus("✓ Contoh skrip penggunaan dibuat!", false)
end

controls.ExampleCodeButton.MouseButton1Click:Connect(handleGetExampleCode)
