-- Lib/TemplateFinder.lua
-- Modul untuk menemukan grup elemen UI yang dapat dijadikan template.

local TemplateFinder = {}

local MIN_TEMPLATE_GROUP_SIZE = 3
local MAX_VARYING_PROPS_RATIO = 0.5

function TemplateFinder.find(layout, commonProps, propsByClass, utils)
	local children = {}
	for _, child in ipairs(layout:GetChildren()) do
		if utils.isGuiObject(child) then
			table.insert(children, child)
		end
	end

	if #children < MIN_TEMPLATE_GROUP_SIZE then
		return nil
	end

	local groups = {}
	for _, child in ipairs(children) do
		local className = child.ClassName
		if not groups[className] then
			groups[className] = {}
		end
		table.insert(groups[className], child)
	end

	local templates = {}
	local processed = {}

	for className, instances in pairs(groups) do
		if #instances >= MIN_TEMPLATE_GROUP_SIZE then
			local template = instances[1]
			local clones = {}
			for i = 2, #instances do
				table.insert(clones, instances[i])
			end

			local propsToProcess, propSet = {}, {}
			if template:IsA("GuiObject") then
				for _, prop in ipairs(commonProps) do if not propSet[prop] then table.insert(propsToProcess, prop); propSet[prop] = true end end
			end
			local classSpecificProps = propsByClass[template.ClassName]
			if classSpecificProps then
				for _, prop in ipairs(classSpecificProps) do if not propSet[prop] then table.insert(propsToProcess, prop); propSet[prop] = true end end
			end

			local varyingProps = {}
			for _, prop in ipairs(propsToProcess) do
				local ok, templateVal = pcall(function() return template[prop] end)
				if ok then
					for _, clone in ipairs(clones) do
						local ok2, cloneVal = pcall(function() return clone[prop] end)
						if ok2 and not utils.valuesEqual(templateVal, cloneVal) then
							varyingProps[prop] = true
							break
						end
					end
				end
			end

			local varyingPropsCount = 0
			for _ in pairs(varyingProps) do varyingPropsCount = varyingPropsCount + 1 end

			if #propsToProcess > 0 and (varyingPropsCount / #propsToProcess <= MAX_VARYING_PROPS_RATIO) then
				local variations = {}
				local varyingPropsList = {}
				for prop in pairs(varyingProps) do table.insert(varyingPropsList, prop) end
				table.sort(varyingPropsList)

				for _, inst in ipairs(instances) do
					local instVariations = {}
					for _, prop in ipairs(varyingPropsList) do
						local ok, val = pcall(function() return inst[prop] end)
						if ok then instVariations[prop] = val end
					end
					variations[inst] = instVariations
					processed[inst] = true
				end

				templates[template] = {
					Clones = clones,
					VaryingProperties = varyingPropsList,
					Variations = variations
				}
			end
		end
	end

	return templates, processed
end

return TemplateFinder
