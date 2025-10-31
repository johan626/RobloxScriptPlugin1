-- Lib/CodeGenerator.lua
-- Modul untuk menghasilkan string kode Luau dari hierarki GUI.

local CodeGenerator = {}

function CodeGenerator.generate(root, settings, commonProps, propsByClass, utils, templateFinder)
	local blacklist = {}
	local blacklistJson = settings.PropertyBlacklist or "[]"
	local success, decoded = pcall(function() return game:GetService("HttpService"):JSONDecode(blacklistJson) end)
	if success and type(decoded) == "table" then
		for _, propName in ipairs(decoded) do
			blacklist[propName] = true
		end
	end

	local instances = utils.collectGuiInstances(root)
	local varMap = {}
	local lines = {}
	local rootVarName = ""
	local processedInstances = {}

	local allTemplates = {}
	for _, inst in ipairs(instances) do
		if inst:IsA("UIListLayout") or inst:IsA("UIGridLayout") then
			local templates, processed = templateFinder.find(inst, commonProps, propsByClass, utils)
			if templates then
				for template, data in pairs(templates) do
					allTemplates[template] = data
				end
				for pInst, _ in pairs(processed) do
					processedInstances[pInst] = true
				end
			end
		end
	end

	local classCounts = {}
	for _, inst in ipairs(instances) do
		classCounts[inst.ClassName] = (classCounts[inst.ClassName] or 0) + 1
	end
	local statsParts = {}
	local sortedClasses = {}
	for className in pairs(classCounts) do table.insert(sortedClasses, className) end
	table.sort(sortedClasses)
	for _, className in ipairs(sortedClasses) do
		table.insert(statsParts, string.format("%s: %d", className, classCounts[className]))
	end
	local statsSummary = string.format("Total Instance: %d (%s)", #instances, table.concat(statsParts, ", "))

	local header = {
		string.format("\tSumber: %s", root:GetFullName()),
		string.format("\tDibuat pada: %s", os.date("!%Y-%m-%d %H:%M:%S UTC")),
		string.format("\t%s", statsSummary)
	}
	table.insert(lines, "--[[")
	for _, headerLine in ipairs(header) do table.insert(lines, headerLine) end
	table.insert(lines, "]]")
	table.insert(lines, "")

	local isModule = (settings.ScriptType == "ModuleScript")
	local indent = isModule and "\t" or ""

	if isModule then
		table.insert(lines, "local module = {}")
		table.insert(lines, "")
		table.insert(lines, "function module.create(parent)")
	else
		table.insert(lines, "local Players = game:GetService('Players')")
		table.insert(lines, "local player = Players.LocalPlayer")
		table.insert(lines, "local playerGui = player:WaitForChild('PlayerGui')")
		table.insert(lines, "")
	end

	local nameCounts = {}

	local function generateInstanceCode(inst, currentIndent, parentVar, isTemplate)
		local baseName = utils.generateSafeVarName(inst.Name)
		local varName = baseName
		if nameCounts[baseName] then
			nameCounts[baseName] = nameCounts[baseName] + 1
			varName = baseName .. tostring(nameCounts[baseName])
		else
			nameCounts[baseName] = 1
		end
		varMap[inst] = varName
		if inst == root and not isTemplate then rootVarName = varName end

		table.insert(lines, "")
		local line = string.format("%slocal %s = Instance.new(%q)", currentIndent, varName, inst.ClassName)
		if settings.AddTraceComments then
			line = line .. string.format(" -- Original: %s", utils.getRelativePath(inst, root))
		end
		table.insert(lines, line)
		table.insert(lines, string.format("%s%s.Name = %q", currentIndent, varName, inst.Name))

		local propsToProcess, propSet = {}, {}
		if inst:IsA("GuiObject") then
			for _, prop in ipairs(commonProps) do if not propSet[prop] then table.insert(propsToProcess, prop); propSet[prop] = true end end
		end
		local classSpecificProps = propsByClass[inst.ClassName]
		if classSpecificProps then
			for _, prop in ipairs(classSpecificProps) do if not propSet[prop] then table.insert(propsToProcess, prop); propSet[prop] = true end end
		end

		local varyingPropsForTemplate = (allTemplates[inst] and allTemplates[inst].VaryingProperties) or {}
		local varyingPropsSet = {}
		for _, p in ipairs(varyingPropsForTemplate) do varyingPropsSet[p] = true end

		-- Kelompokkan properti untuk keterbacaan yang lebih baik
		local layoutProps = {}
		local visualProps = {}
		local textProps = {}
		local otherProps = {}

		local propGroups = {
			Layout = {"AnchorPoint", "Position", "Size", "AutomaticSize", "Rotation", "ZIndex", "LayoutOrder"},
			Visual = {"BackgroundColor3", "BackgroundTransparency", "BorderSizePixel", "Image", "ImageTransparency", "ImageColor3", "ScaleType", "SliceCenter", "SliceScale", "ImageRectOffset", "ImageRectSize", "ClipsDescendants"},
			Text = {"Text", "TextColor3", "TextSize", "TextScaled", "Font", "TextWrapped", "TextXAlignment", "TextYAlignment", "TextTransparency", "TextStrokeTransparency", "TextStrokeColor3", "PlaceholderText", "PlaceholderColor3", "TextEditable"}
		}
		local propGroupMap = {}
		for groupName, props in pairs(propGroups) do
			for _, prop in ipairs(props) do propGroupMap[prop] = groupName end
		end

		for _, prop in ipairs(propsToProcess) do
			if prop ~= "Name" and not blacklist[prop] and not varyingPropsSet[prop] then
				local ok, val = pcall(function() return inst[prop] end)
				if ok and val ~= nil then
					local defaultVal, _ = utils.getClassDefaultValue(inst.ClassName, prop)
					if not utils.valuesEqual(val, defaultVal) and prop ~= "Parent" then
						local success, serialized = pcall(function() return utils.serializeValue(val) end)
						if success and serialized then
							local line = string.format("%s%s.%s = %s", currentIndent, varName, prop, serialized)
							local group = propGroupMap[prop]
							if group == "Layout" then table.insert(layoutProps, line)
							elseif group == "Visual" then table.insert(visualProps, line)
							elseif group == "Text" then table.insert(textProps, line)
							else table.insert(otherProps, line) end
						end
					end
				end
			end
		end

		-- Gabungkan dan urutkan properti dalam kelompok mereka
		local function sortAndAdd(propList)
			table.sort(propList)
			for _, line in ipairs(propList) do table.insert(lines, line) end
		end

		if #layoutProps > 0 then table.insert(lines, ""); sortAndAdd(layoutProps) end
		if #visualProps > 0 then table.insert(lines, ""); sortAndAdd(visualProps) end
		if #textProps > 0 then table.insert(lines, ""); sortAndAdd(textProps) end
		if #otherProps > 0 then table.insert(lines, ""); sortAndAdd(otherProps) end

		local attributes = inst:GetAttributes()
		local attributeLines = {}
		for name, value in pairs(attributes) do
			local t = typeof(value)
			if t == "Instance" or t == "RBXScriptSignal" or t == "function" or t == "thread" then
			else
				local success, serialized = pcall(function() return utils.serializeValue(value) end)
				if success and serialized then
					table.insert(attributeLines, string.format('%s%s:SetAttribute(%q, %s)', currentIndent, varName, name, serialized))
				end
			end
		end

		if #attributeLines > 0 then
			table.insert(lines, "")
			table.sort(attributeLines)
			for _, attrLine in ipairs(attributeLines) do table.insert(lines, attrLine) end
		end

		if parentVar then
			table.insert(lines, string.format("%s%s.Parent = %s", currentIndent, varName, parentVar))
		end

		for _, child in ipairs(inst:GetChildren()) do
			if (utils.isGuiObject(child) or child:IsA("UIBase")) and not processedInstances[child] then
				generateInstanceCode(child, currentIndent .. "\t", varName, isTemplate)
			end
		end

		return varName
	end

	for _, inst in ipairs(instances) do
		if processedInstances[inst] then continue end

		if allTemplates[inst] then
			table.insert(lines, ("\n%s-- GENERASI TEMPLATE CERDAS UNTUK %s"):format(indent, inst.Parent.Name))
			local templateData = allTemplates[inst]
			local templateVarName = generateInstanceCode(inst, indent, nil, true)

			local variationsVarName = utils.generateSafeVarName(inst.Name) .. "Variations"
			table.insert(lines, string.format("\n%slocal %s = {", indent, variationsVarName))
			local allTemplateInstances = {inst}; for _, c in ipairs(templateData.Clones) do table.insert(allTemplateInstances, c) end

			for _, item in ipairs(allTemplateInstances) do
				table.insert(lines, string.format("%s\t{", indent))
				for _, prop in ipairs(templateData.VaryingProperties) do
					local value = templateData.Variations[item][prop]
					local success, serialized = pcall(function() return utils.serializeValue(value) end)
					if success and serialized then
						table.insert(lines, string.format("%s\t\t%s = %s,", indent, prop, serialized))
					end
				end
				table.insert(lines, string.format("%s\t},", indent))
			end
			table.insert(lines, string.format("%s}", indent))

			table.insert(lines, "")
			table.insert(lines, string.format("%sfor _, data in ipairs(%s) do", indent, variationsVarName))
			table.insert(lines, string.format("%s\tlocal newInstance = %s:Clone()", indent, templateVarName))
			table.insert(lines, string.format("%s\tfor prop, value in pairs(data) do", indent))
			table.insert(lines, string.format("%s\t\tnewInstance[prop] = value", indent))
			table.insert(lines, string.format("%s\tend", indent))
			local parentVarName = varMap[inst.Parent]
			if parentVarName then
				table.insert(lines, string.format("%s\tnewInstance.Parent = %s", indent, parentVarName))
			end
			table.insert(lines, string.format("%send", indent))
			table.insert(lines, string.format("%s%s:Destroy()", indent, templateVarName))
		else
			local parentVar
			if inst == root then
				parentVar = isModule and "parent" or "playerGui"
			else
				parentVar = varMap[inst.Parent]
			end
			generateInstanceCode(inst, indent, parentVar, false)
		end
	end

	if #lines > 0 and lines[#lines] == "" then
		table.remove(lines)
	end

	if isModule then
		table.insert(lines, "\n" .. indent .. "local elements = {")
		for inst, varName in pairs(varMap) do
			if utils.isGuiObject(inst) or inst:IsA("UIConstraint") then
				table.insert(lines, string.format("%s\t%s = %s,", indent, varName, varName))
			end
		end
		table.insert(lines, indent .. "}")
		table.insert(lines, "")
		table.insert(lines, indent .. "--// USER_CODE_START -- Letakkan kode kustom di bawah baris ini")
		table.insert(lines, indent .. "--// USER_CODE_END -- Letakkan kode kustom di atas baris ini")
		table.insert(lines, "")
		table.insert(lines, string.format("%sreturn elements", indent))
		table.insert(lines, "end")
		table.insert(lines, "")
		table.insert(lines, "return module")
	else
		table.insert(lines, "")
		table.insert(lines, "--// USER_CODE_START -- Letakkan kode kustom di bawah baris ini")
		table.insert(lines, "--// USER_CODE_END -- Letakkan kode kustom di atas baris ini")
	end

	return table.concat(lines, "\n")
end

return CodeGenerator
