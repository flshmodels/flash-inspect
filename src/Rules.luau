-- Rules consume plain records so they can be tested without Studio.
local Rules = {}

function Rules.analyze(records)
	local issues = {}
	local identifiers = {}
	local function add(record, code, message)
		table.insert(issues, { target = record.target, path = record.path, code = code, message = message })
	end
	for _, record in ipairs(records) do
		if record.isPart and record.static and not record.anchored then
			add(record, "STATIC_UNANCHORED", "Marked as static scenery, but this part is not anchored. Check whether it should move.")
		end
		if record.interactive then
			local id = record.id
			if type(id) ~= "string" or #id < 1 or #id > 64 or not string.match(id, "^[A-Za-z][A-Za-z0-9_%-]*$") then
				add(record, "INVALID_INTERACTION_ID", "Interactable needs a string ID: a letter, then letters, digits, _ or -, up to 64 characters.")
			else
				local group = identifiers[id]
				if not group then
					group = {}
					identifiers[id] = group
				end
				table.insert(group, record)
			end
		end
	end
	-- Walk input order for stable reports, rather than hash-table order.
	for _, record in ipairs(records) do
		local group = record.interactive and identifiers[record.id]
		if group and #group > 1 then
			add(record, "DUPLICATE_INTERACTION_ID", "Interaction ID is shared by " .. #group .. " objects in this scan: " .. record.id)
		end
	end
	return issues
end

return Rules
