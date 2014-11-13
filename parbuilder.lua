local Parbuilder = {}

local persistence = require "realpgno-persistence.lua"

local paragraphs = {}

function Parbuilder.add(par)
	table.insert(paragraphs, par)
end

function save(filename)
	persistence.store(filename, paragraphs)
end
