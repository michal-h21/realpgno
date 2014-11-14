local Parbuilder = {}

local persistence = require "realpgno-persistence.lua"

local paragraphs = {}

local suppress_groupcodes = {
	insert = true
}
function Parbuilder.add(par, groupcode)
	local suppress = suppress_groupcodes[groupcode]
	if not suppress then
  	table.insert(paragraphs, par)
	end
end

function Parbuilder.save(filename)
	persistence.store(filename, paragraphs)
end

return Parbuilder
