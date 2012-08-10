module(...,package.seeall)

local glyph_id = node.id("glyph")
local math_id = 9
local disc_id = 7
local whatsits_id = 8
fuf = io.open("fontspec4ht.txt","w")
nl ="\n"


-- simple checksum factory, return value is counting function
-- for every glyph node, 1 is added 
function checksum()  
  local to_skip = false
  local sum = 0
  -- return value is always sum
  local function chck(item)
    -- Function for processing subnodes, e.g. in ligatures
    local function loop_components(comp)
      while comp do
        chck(comp)
        comp = comp.next
      end
    end
    if item == nil then return sum end  
    if item.id == glyph_id and to_skip == false then
      -- if node has componennts, it is ligature and we need to loop over ligature glyphs
      if item.subtype > 0 and item.components then 
        loop_components(item.components)
      else 
    	  fuf:write(unicode.utf8.char(item.char))    
    	  sum = sum + 1
      end    
    elseif item.id == math_id and item.subtype == 0 then
      -- We want to skip math, because it causes problems with tex4ht
      texio.write_nl("Math skip begin")
      to_skip = true
    elseif item.id == math_id and item.subtype == 1 then
      texio.write_nl("Math skip end")
      to_skip = false	
    elseif item.id == disc_id and item.replace  then
      -- If node is discretionary that comes from ligature, field replace will 
      -- not be pointer to node. It's components field contains ligature glyphs
      -- and we can loop over them and make checksum
      if (item.replace).id == glyph_id then 
        loop_components((item.replace).components)
      else
        loop_components(item.replace)
      end
    elseif item.id == whatsits_id and item.subtype == 3 and item.data == "t4ht@[" then
      to_skip = true
      texio.write_nl("TeX4ht skip begin")
    elseif item.id == whatsits_id and item.subtype == 3 and item.data == "t4ht@]" then
      to_skip = false
      texio.write_nl("TeX4ht skip end")
    end
    return sum
  end
  return chck
end
