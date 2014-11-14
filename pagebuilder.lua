local Pagebuilder = {}

local persistence = require "realpgno-persistence.lua"

local warning = function(s) print("Pagebuilder: "..s) end
local allparagraphs = {}
function Pagebuilder.add(page, paragraphs)
	local pageobj = {page = page, type="page"}
	local parcnt = #paragraphs
	local i = 1
	if parcnt < 1 or (parcnt == 1 and #paragraphs[i]==0) then 
		-- at least one non empty paragraph must be on a page
		warning ("no paragraphs on page "..page)
		return nil,"Empty paragraphs" 
	else
		warning(parcnt .. " paragraphs on page "..page)
	end
	if #paragraphs[i] == 0 then
		-- if first table is empty, page starts with new paragraph
		warning("Page "..page.." starts with paragraphs")
		i = i + 1
		local curr = paragraphs[i]  or {}
		table.insert(curr,1, pageobj)
		curr.page = page
		table.insert(allparagraphs,curr)
	else
		-- we need to join last paragraph from previous page with first from new 
		-- page. curr.linebreak is set to true when last page ended with hyphenated
		-- word. we doesn't insert page number, because it is set already
		local curr = allparagraphs[#allparagraphs] or {}
		local new = paragraphs[i]
		table.insert(curr, pageobj)
		for _,node in ipairs(new) do
			table.insert(curr,node)
		end
		allparagraphs[#allparagraphs] = curr
	end
	i = i + 1
	allparagraphs[#allparagraphs].pagebreak = true
	for i = i, #paragraphs do
		local curr = paragraphs[i]
		curr.page = page
		table.insert(allparagraphs,curr)
	end
end

function Pagebuilder.save(filename)
	persistence.store(filename, allparagraphs)
end

return Pagebuilder
