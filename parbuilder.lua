local Parbuilder = {}

local persistence = require "realpgno-persistence.lua"

local paragraphs = {}

function Parbuilder.add(par)
	table.insert(paragraphs, par)
end

function Parbuilder.save(filename)
	persistence.store(filename, paragraphs)
end

return Parbuilder
