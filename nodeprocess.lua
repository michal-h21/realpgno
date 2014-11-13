-- new start again
-- first task:
-- reconstruct paragraphs from hlists in output routine
-- each paragraph starts with whatsit with subtype local_par
-- we need to deal with line breaks, resp. prehyphenchar
-- compare reconstructed paragraphs with output of pre_linebreak_filter

local Nodeprocess = {}
local hlist_id = node.id("hlist")
local vlist_id = node.id("vlist")
local glyph_id = node.id("glyph")
local whatsits_id = node.id("whatsit")
local uchar = unicode.utf8.char
local prehyphenchar = lang.prehyphenchar
local languages = {}


function bit(p)
	return 2 ^ (p - 1) -- 1-based indexing
end -- Typical call: if hasbit(x, bit(3)) then .and.. i
function hasbit(x, p)
	return x % (p + p) >= p
end


Nodeprocess.__index = Nodeprocess

Nodeprocess.new = function()
  local self = setmetatable({}, Nodeprocess)
  return self
end

Nodeprocess.process_hlist = function(self,hlist, nodelist)
	local nodelist = nodelist or {}
	local x, linebreak
	for n in node.traverse(hlist) do
		if n.id == glyph_id  then
			local nlang = n.lang
			-- we must get current language, all languages are stored in table for 
			-- efficiency
			local l = languages[nlang] or lang.new(nlang)
			languages[nlang] = l
			--print("glyph",n.char, n.subtype)
			x = uchar(n.char)
			if n.subtype ~= 0 or n.char ~= prehyphenchar(l) then 
			  table.insert(nodelist, x)
				linebreak = false
			else
				linebreak = true
			end
		elseif n.id == hlist_id then
			nodelist, linebreak = self:process_hlist(n.head,nodelist)
		elseif n.id == vlist_id then
			nodelist, linebreak = self:process_hlist(n.head,nodelist)
		elseif n.id == whatsits_id and n.subtype == 6 then
			-- subtype 6 is paragraph start
			-- nodelist.new = true
			return nodelist, n.next
		else
			-- table.insert(nodelist,string.format("(%i)",n.id))
		end
	end
	-- print(table.concat(nodelist))
	nodelist.linebreak = linebreak
	return nodelist, false
end


Nodeprocess.make_paragraphs = function(self,lines)
	local paragraphs = {}
	local par = {}
	local rest
	for line in node.traverse_id(hlist_id,lines) do
		rest = nil
		par, rest = self:process_hlist(line.head,par)
		-- if par.new == true then
		if rest then
			table.insert(paragraphs, par)
			par = self:process_hlist(rest,{})
		end
	end
	table.insert(paragraphs, par)
	print("Page")
	for i, par in ipairs(paragraphs) do
		print("Linebreak", par.linebreak)
		print(table.concat(par))
	end
	return paragraphs
end

return Nodeprocess
