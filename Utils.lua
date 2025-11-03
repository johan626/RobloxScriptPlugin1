-- Lib/Utils.lua
-- Kumpulan fungsi utilitas umum untuk plugin GUIConvert.

local Utils = {}

-- Fungsi internal yang tidak diekspos
local function quoteString(s)
	return string.format("%q", tostring(s))
end

local function roundDecimal(n)
	if typeof(n) ~= "number" then return n end
	return math.floor(n * 10000 + 0.5) / 10000
end

-- Fungsi yang diekspos
function Utils.serializeValue(v)
	local t = typeof(v)
	if t == "UDim2" then
		return string.format("UDim2.new(%s, %s, %s, %s)", tostring(roundDecimal(v.X.Scale)), tostring(v.X.Offset), tostring(roundDecimal(v.Y.Scale)), tostring(v.Y.Offset))
	elseif t == "UDim" then
		return string.format("UDim.new(%s, %s)", tostring(roundDecimal(v.Scale)), tostring(v.Offset))
	elseif t == "Vector2" then
		return string.format("Vector2.new(%s, %s)", tostring(roundDecimal(v.X)), tostring(roundDecimal(v.Y)))
	elseif t == "Vector3" then
		return string.format("Vector3.new(%s, %s, %s)", tostring(roundDecimal(v.X)), tostring(roundDecimal(v.Y)), tostring(roundDecimal(v.Z)))
	elseif t == "Color3" then
		return string.format("Color3.fromRGB(%d, %d, %d)", math.floor(v.R * 255), math.floor(v.G * 255), math.floor(v.B * 255))
	elseif t == "ColorSequence" then
		local keypoints = {}
		for _, keypoint in ipairs(v.Keypoints) do
			table.insert(keypoints, string.format("ColorSequenceKeypoint.new(%s, %s)", tostring(keypoint.Time), Utils.serializeValue(keypoint.Value)))
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

function Utils.generateSafeVarName(s, className)
	local name = tostring(s):gsub("%%s+(%%w)", function(c) return c:upper() end):gsub("[^%%w_]", "")
	if name:match("^[0-9]") then name = "v" .. name end

	if #name > 0 then
		name = name:sub(1,1):lower() .. name:sub(2)
	elseif className and #className > 0 then
		name = className:sub(1,1):lower() .. className:sub(2)
	end

	if name == "" then
		return "obj"
	end

	return name
end

local classDefaults = {}
function Utils.getClassDefaultValue(className, prop)
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

function Utils.getRelativePath(instance, root)
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

function Utils.valuesEqual(a, b)
	if a == nil and b == nil then return true end
	if a == nil or b == nil then return false end
	local ta, tb = typeof(a), typeof(b)
	if ta ~= tb then return false end
	if ta == "UDim2" or ta == "UDim" or ta == "Vector2" or ta == "Vector3" or ta == "Color3" or ta == "EnumItem" or ta == "boolean" or ta == "number" or ta == "string" then
		return a == b
	end
	return tostring(a) == tostring(b)
end

function Utils.isGuiObject(inst)
	return inst and (inst:IsA("GuiObject") or inst:IsA("SurfaceGui"))
end

function Utils.collectGuiInstances(root, settings)
	local classBlacklist = settings and settings.ClassBlacklist or {}
	local classBlacklistSet = {}
	for _, className in ipairs(classBlacklist) do
		classBlacklistSet[className] = true
	end

	local instances = {}
	if (Utils.isGuiObject(root) or root:IsA("ScreenGui") or root:IsA("UIBase")) and not classBlacklistSet[root.ClassName] then
		table.insert(instances, root)
	end
	for _, child in ipairs(root:GetDescendants()) do
		if (Utils.isGuiObject(child) or child:IsA("UIBase")) and child:GetAttribute("ConvertIgnore") ~= true and not classBlacklistSet[child.ClassName] then
			table.insert(instances, child)
		end
	end
	return instances
end

function Utils.generateExampleCode(moduleScript, rootInstance)
	local path = moduleScript:GetFullName()
	path = path:gsub("^.*ReplicatedStorage%.", "")
	local moduleName = moduleScript.Name
	local varName = Utils.generateSafeVarName(moduleName)
	local lines = {}

	if rootInstance and rootInstance:IsA("SurfaceGui") then
		lines = {
			string.format("-- Contoh penggunaan untuk SurfaceGui '%s'", moduleName),
			"",
			"local ReplicatedStorage = game:GetService('ReplicatedStorage')",
			"local Workspace = game:GetService('Workspace')",
			"",
			string.format("-- Pastikan path ini benar! Mungkin perlu disesuaikan jika Anda memindahkan skrip."),
			string.format("local %sModule = require(ReplicatedStorage.%s)", varName, path),
			"",
			"-- Tentukan Part di Workspace yang akan menjadi induk dari SurfaceGui ini",
			"local targetPart = Workspace:FindFirstChild('MyGuiPart') -- Ganti 'MyGuiPart' dengan nama Part Anda",
			"if not targetPart then",
			"\ttargetPart = Instance.new('Part')",
			"\ttargetPart.Name = 'MyGuiPart'",
			"\ttargetPart.Size = Vector3.new(10, 1, 10)",
			"\ttargetPart.Anchored = true",
			"\ttargetPart.Parent = Workspace",
			"end",
			"",
			string.format("local guiElements = %sModule.create(targetPart)", varName),
			""
		}
	else
		lines = {
			string.format("-- Contoh penggunaan untuk '%s'", moduleName),
			"",
			"local ReplicatedStorage = game:GetService('ReplicatedStorage')",
			"local Players = game:GetService('Players')",
			"",
			string.format("-- Pastikan path ini benar! Mungkin perlu disesuaikan jika Anda memindahkan skrip."),
			string.format("local %sModule = require(ReplicatedStorage.%s)", varName, path),
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
	end
	return table.concat(lines, "\n")
end

function Utils.deserializeValue(valueString)
	local env = {
		UDim2 = UDim2,
		UDim = UDim,
		Vector2 = Vector2,
		Vector3 = Vector3,
		Color3 = Color3,
		ColorSequence = ColorSequence,
		ColorSequenceKeypoint = ColorSequenceKeypoint,
		NumberSequence = NumberSequence,
		NumberSequenceKeypoint = NumberSequenceKeypoint,
		Enum = Enum,
		-- Tambahkan fungsi global aman lainnya jika diperlukan
	}

	-- Coba parsing langsung untuk number dan boolean
	local num = tonumber(valueString)
	if num then return num end
	if valueString == "true" then return true end
	if valueString == "false" then return false end

	-- Untuk string, hilangkan tanda kutipnya
	if valueString:sub(1,1) == '"' and valueString:sub(-1,-1) == '"' then
		return valueString:sub(2, -2)
	end

	local func, err = loadstring("return " .. valueString)
	if not func then
		warn("GUIConvert deserialize error (loadstring): ", err)
		return nil, err
	end

	setfenv(func, env)

	local success, result = pcall(func)
	if not success then
		warn("GUIConvert deserialize error (pcall): ", result)
		return nil, result
	end

	return result, nil
end

return Utils
