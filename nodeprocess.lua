-- new start again
-- first task:
-- reconstruct paragraphs from hlists in output routine
-- each paragraph starts with whatsit with subtype local_par
-- we need to deal with line breaks, resp. prehyphenchar
-- compare reconstructed paragraphs with output of pre_linebreak_filter

local Nodeprocess = {}
local hlist_id = node.id("hlist")
local glyph_id = node.id("glyph")
Nodeprocess.__index = Nodeprocess

Nodeprocess.new = function()
  local self = setmetatable({}, Nodeprocess)
  return self
end

Nodeprocess.process_hlist = function(self,hlist, nodelist)
	local nodelist = nodelist or {}
	local x 
	for n in node.traverse(hlist) do
		if n.id == glyph_id then
			--print("glyph",n.char, n.subtype)
			x = n.char .. " - ".. n.subtype
			table.insert(nodelist, x)
		elseif n.id == hlist_id then
			nodelist = self:process_hlist(n.head,nodelist)
		end
	end

	print(x, "-----------")
	return nodelist
end


Nodeprocess.make_paragraphs = function(self,lines)
	local paragraphs = {}
	local par = par
	for line in node.traverse_id(hlist_id,lines) do
		par = self:process_hlist(line.head,par)
		if par.new == true then
			table.insert(paragraphs, par)
			par = {}
		end
	end
	return paragraphs
end

return Nodeprocess
