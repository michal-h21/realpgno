module(...,package.seeall)

local glyph_id = node.id("glyph")
local math_id = 9
fuf = io.open("fontspec4ht.txt","w")

function buildLigaTable()
end

function checksum()
  local is_m = false
  local sum = 0
  local function chck(item)
    if item == nil then return sum end  
    if item.id == glyph_id and is_m == false then
	if item.char > 128 then texio.write_nl("Máme fi") end
	if sum == 823 then print("Máme: "..item.char) end
	fuf:write(unicode.utf8.char(item.char).."\n")    
	sum = sum + 1    
    elseif item.id == math_id and item.subtype == 0 then
      is_m = true
    elseif item.id == math_id and item.subtype == 1 then
      is_m = false	
    end
    return sum
  end
  return chck
end
