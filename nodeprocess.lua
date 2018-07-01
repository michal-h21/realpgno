-- new start again
-- first task:
-- reconstruct paragraphs from hlists in output routine
-- each paragraph starts with local_par node
-- we need to deal with line breaks, resp. prehyphenchar
-- compare reconstructed paragraphs with output of pre_linebreak_filter

local Nodeprocess = {}

local par_id = node.id("local_par")
local math_id = node.id("math")
local glue_id = node.id("glue")
local hlist_id = node.id("hlist")
local vlist_id = node.id("vlist")
local glyph_id = node.id("glyph")
local whatsits_id = node.id("whatsit")

local uchar = unicode.utf8.char
local prehyphenchar = lang.prehyphenchar
local languages = {}

local function load_lang(nlang)
  -- we must get current language, all languages are stored in table for 
  -- efficiency
  local l = languages[nlang] or lang.new(nlang)
  languages[nlang] = l
  return l
end


local function bit(p)
	return 2 ^ (p - 1) -- 1-based indexing
end -- Typical call: if hasbit(x, bit(3)) then .and.. i
local function hasbit(x, p)
	return x % (p + p) >= p
end


Nodeprocess.__index = Nodeprocess

Nodeprocess.new = function()
  local self = setmetatable({}, Nodeprocess)
	self.count = 0
  return self
end

Nodeprocess.process_hlist = function(self,hlist, nodelist)
	local nodelist = nodelist or {}
	local count = nodelist.count or 0
	local x 
  local linebreak = false
  local paragraphstart = false
  -- lang of the last node to be used for the hyphenation detection
  -- use English as default
  local lastlang = load_lang(0) 
	for n in node.traverse(hlist) do
		if n.id == glyph_id  then
      lastlang = load_lang(n.lang)
			if not nodelist.skip then
				count = count + n.char
			end
			x = uchar(n.char)
      table.insert(nodelist, x)
		elseif n.id == hlist_id then
			nodelist, linebreak = self:process_hlist(n.head,nodelist)
		elseif n.id == vlist_id then
			nodelist, linebreak = self:process_hlist(n.head,nodelist)
    elseif n.id == glue_id then
      table.insert(nodelist, " ")
    elseif n.id == par_id then
      -- return current paragraph on start of a new one
      -- the rest of the current list will be processed in
      -- a new call to this function
      return nodelist, n.next 
		elseif n.id == math_id then
      -- math start
			if n.subtype == 0 then
				nodelist.skip = true
      -- math end
			else
				nodelist.skip = false
			end
		else
			-- table.insert(nodelist,string.format("(%i)",n.id))
		end
	end
	-- print(table.concat(nodelist))
  -- detect hyphenation
  local currenthyphenchar = prehyphenchar(lastlang)
  local currenthyphenstr = uchar(currenthyphenchar)
  if nodelist[#nodelist] == currenthyphenstr then
    -- remove the hyphen char
    nodelist[#nodelist] = nil
    -- remove it from the count
    count = count - currenthyphenchar
    linebreak = true
  end
	nodelist.count = count
	nodelist.linebreak = linebreak
  nodelist.paragraph = paragraphstart
	return nodelist, false
end


Nodeprocess.make_paragraphs = function(self,lines)
	local paragraphs = {}
	local par = {}
	local rest
	for line in node.traverse_id(hlist_id,lines) do
		rest = nil
		par, rest = self:process_hlist(line.head,par)
    -- rest is node returned after new paragraph starts
    if rest then
      table.insert(paragraphs, par)
      par = self:process_hlist(rest, {})
      print("newpar", #par)
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
