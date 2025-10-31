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
		local r = math.floor(v.R * 255 + 0.5)
		local g = math.floor(v.G * 255 + 0.5)
		local b = math.floor(v.B * 255 + 0.5)
		return string.format("Color3.fromRGB(%d, %d, %d)", r, g, b)
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

function Utils.generateSafeVarName(s)
	if not s or s == "" then return "obj" end
	local name = tostring(s):gsub("%%s+(%%w)", function(c) return c:upper() end):gsub("[^%%w_]", "")
	if name:match("^[0-9]") then name = "v" .. name end
	if #name > 0 then name = name:sub(1,1):lower() .. name:sub(2) end
	if name == "" then return "unnamedGui" end
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
	return inst and inst:IsA("GuiObject")
end

function Utils.generateExampleCode(moduleScript)
	local path = moduleScript:GetFullName()
	path = path:gsub("^.*StarterPlayerScripts%.", "")
	local moduleName = moduleScript.Name
	local varName = Utils.generateSafeVarName(moduleName)
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

return Utils
