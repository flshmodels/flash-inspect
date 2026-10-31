local Scanner = {}

function Scanner.collect(roots, config, hasTag)
	local records, seen = {}, {}
	local staticCache = {}
	local function isStatic(object)
		local trail = {}
		local ancestor = object
		local result = false
		while ancestor do
			if staticCache[ancestor] ~= nil then
				result = staticCache[ancestor]
				break
			end
			table.insert(trail, ancestor)
			if hasTag(ancestor, config.staticTag) then
				result = true
				break
			end
			ancestor = ancestor.Parent
		end
		for _, visited in ipairs(trail) do staticCache[visited] = result end
		return result
	end
	local stack = {}
	for i = #roots, 1, -1 do table.insert(stack, roots[i]) end
	while #stack > 0 do
		local object = table.remove(stack)
		if not seen[object] then
			seen[object] = true
			if #records >= config.maxObjects then
				error("Scan exceeds " .. config.maxObjects .. " objects. Select a smaller area.")
			end
			local static = isStatic(object)
			local isPart = object:IsA("BasePart")
			table.insert(records, {
				target = object, path = object:GetFullName(), isPart = isPart,
				anchored = isPart and object.Anchored or false,
				static = static, interactive = hasTag(object, config.interactiveTag),
				id = object:GetAttribute(config.idAttribute),
			})
			local children = object:GetChildren()
			for i = #children, 1, -1 do table.insert(stack, children[i]) end
		end
	end
	return records
end

return Scanner
