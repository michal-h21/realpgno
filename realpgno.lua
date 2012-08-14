module(...,package.seeall)

local glyph_id = node.id("glyph")
local math_id = 9
local disc_id = 7
local whatsits_id = 8
local hlist_id = 0
local vlist_id = 1
fuf = io.open("bez4ht.txt","w")
nl ="\n"

-- char value of hyphen, we need to skip it
hyphenchar = 45


-- simple checksum factory, return value is counting function
-- for every glyph node, 1 is added 
function checksum()  
  local to_skip = false
  -- Another hack for tex4ht. It writes some nodes to tmp file, which results
  -- in wrong checksum
  skip_hlist = false
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
    local skip_now = to_skip  or (node.has_attribute(item,224) == 33)
    if item.id == glyph_id and skip_now == false and item.char ~= hyphenchar then-- to_skip == false and node.has_attribute(item,224) ~= 33 then
      -- if node has components, it is ligature and we need to loop over ligature glyphs
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
      fuf:write("\nTex4ht skip begin\n")
    elseif item.id == whatsits_id and item.subtype == 3 and item.data == "t4ht@]" then
      to_skip = false
      texio.write_nl("TeX4ht skip end")
      fuf:write("\nTeX4ht skip end\n")
    elseif item.id == hlist_id and item.subtype == 2 then
      fuf:write("[:hlist:"..item.subtype.."]")   
      loop_components(item.head)
      fuf:write("[:/hlist:]")
      for kk in node.traverse(item.head) do
	if kk.id == glyph_id then
   	  texio.write_nl("hlist node: ".. unicode.utf8.char(kk.char))
        else
          texio.write_nl("hlist je jinej: "..kk.id)
	end
      end
    elseif item.id == vlist_id  then 
      loop_components(item.head)
    elseif item.id == whatsits_id and item.subtype == 3  and sum < 3 then
      if(item.data:find("t4ht>.*tmp$")) and to_skip == false then
	to_skip = true
        skip_hlist = true
	texio.write_nl("Temp file skip begin") 
      elseif item.data:find("t4ht<") and skip_hlist == true then
	to_skip = false
	skip_hlist = false
	texio.write_nl("Temp file skip end")
      end
      fuf:write("["..item.data.."]")
    else 
      if item.id == glyph_id then
	 if to_skip then fuj = "true" else fuj = "false" end
	 if  node.has_attribute(item,224) == 33 then node_attr = "true" else node_attr ="false" end	 

	 fuf:write("(glyph :" ..unicode.utf8.char(item.char) .. " to skip: ".. fuj .." attribute ".. node_attr ..")")
      elseif item.id == 8 and item.subtype==3 then
	 fuf:write("(tex4ht: "..item.data..")")
      else
        fuf:write("("..item.id..")")
      end
    end
    return sum
  end
  return chck
end
