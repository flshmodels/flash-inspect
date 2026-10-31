local Rules = require("../src/Rules")
local Scanner = require("../src/Scanner")
local Config = require("../src/Config")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
luau.compile(fs.readFile("src/Plugin.server.luau"))
local function record(changes)
	local r = { target = {}, path = "Workspace.Part", isPart = true, anchored = true, static = false, interactive = false }
	for k, v in pairs(changes or {}) do r[k] = v end
	return r
end
assert(#Rules.analyze({ record() }) == 0)
assert(#Rules.analyze({ record({ static = true }) }) == 0)
assert(Rules.analyze({ record({ static = true, anchored = false }) })[1].code == "STATIC_UNANCHORED")
assert(#Rules.analyze({ record({ static = true, anchored = false, isPart = false }) }) == 0)
for _, id in ipairs({ "", "1a", "a b", string.rep("a", 65), 123, false }) do
	assert(Rules.analyze({ record({ interactive = true, id = id }) })[1].code == "INVALID_INTERACTION_ID")
end
assert(#Rules.analyze({ record({ interactive = true }) }) == 1)
assert(#Rules.analyze({ record({ interactive = true, id = "Door_1-A" }) }) == 0)
local duplicate = Rules.analyze({ record({ interactive = true, id = "a" }), record({ interactive = true, id = "a" }) })
assert(#duplicate == 2 and duplicate[1].code == "DUPLICATE_INTERACTION_ID")

local function object(name, parent, part, tags, attributes)
	local node = { Name = name, Parent = parent, Anchored = false, children = {}, tags = tags or {}, attributes = attributes or {} }
	function node:IsA(class) return class == "BasePart" and part == true end
	function node:GetChildren() return self.children end
	function node:GetFullName() return self.Name end
	function node:GetAttribute(key) return self.attributes[key] end
	if parent then table.insert(parent.children, node) end
	return node
end
local model = object("Static", nil, false, { StaticScenery = true })
local part = object("Part", model, true)
local door = object("Door", nil, true, { Interactable = true }, { InteractionId = "DoorA" })
local function hasTag(node, tag) return node.tags[tag] == true end
local records = Scanner.collect({ model, part, door }, Config, hasTag)
assert(#records == 3, "overlapping selection must not duplicate objects")
assert(records[2].target == part and records[2].static, "static tag must inherit")
assert(records[3].id == "DoorA" and records[3].interactive)
assert(#Rules.analyze(records) == 1)
assert(Scanner.collect({ part }, Config, hasTag)[1].static, "ancestor outside selection still applies")
assert(#Scanner.collect({}, Config, hasTag) == 0)
assert(not pcall(function() Scanner.collect({ model }, { maxObjects = 1, staticTag = "StaticScenery", interactiveTag = "Interactable", idAttribute = "InteractionId" }, hasTag) end))
print("Rules and scanner checks passed")
