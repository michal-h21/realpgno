-- module("...",package.seeall())
local persistence = require "realpgno-persistence"
--local stack      = require "realpgno-stack"
local disc_id = node.id "discretionary"
local glue_id = node.id "glue"
local kern_id = node.id "kern"
local glyph_id = node.id("glyph")
local hlist_id = node.id "hlist"
local whatsit_id = node.id "whatsit"
local m = {}
local tex_write = texio.write_nl

local NodeParser = function()
  local Parser = {
    start = function(self,value,t) 
      if value then
        local t = t or "text"
        return {value = value, type = t}
      else
        return nil
      end
    end,
    stream = {},
    current = {},
    skip_one = false,
    add = function(self, n)
      local value,t = self:get_type(n)
      -- tex_write(t)
      if value then
        local current = self.current or {}
        local stream = self.stream or {}
        if current and t == current.type then
          if t == "text" then
            current.value = current.value .. value
          end
          --table.insert(current.value, value)
        else
          -- print("Měníme stream")
          if current then 
            table.insert(stream, self:start(current.value,current.type))
          end
          current = self:start(value,t)
        end
        self.current = current
        self.stream = stream
      end
      return self
    end,
    get_type = function(self,n)
      local n = n or {id=false}
      local nl = NodeCount.new()
      if n.id == glyph_id then
        if n.subtype > 0 and n.components then
          return nl:process_hlist(n.components), "components"
        else
          if not self.skip_one then
            return unicode.utf8.char(n.char), "text"
          else
            self.skip_one = false
            return nil, "skip_one"
          end
        end
      elseif n.id == hlist_id then
        return nl:process_hlist(n.head),"hlist"
      elseif n.id == glue_id then
        if n.subtype == 0 then
          return " ", "space"
        else
          return n.subtype, "glue"
        end
      elseif n.id == kern_id or n.id == disc_id then
        return nil, "kern_or_glue"
      elseif n.id == whatsit_id then
        local t = node.whatsits()
        if n.subtype == 3 then 
          --n = n.next
          local x, y, rest = string.match(n.data,"t4ht(.)(.?)(.*)")
          if not x then 
            return n.data, "special" 
          else
            return self:tex4ht(x,y,rest)
          end
          --return n.data, "text4ht"
        else
          return t[n.subtype], "whatsit"
        end
      else
        return n.id, "unknown"
      end
      --[[if type(n) =="table" then
      else
      return n, "text"
      end
      --]]
    end,
    tex4ht = function(self, t, s, data)
      if t == "@" then
        if s == "+" then 
          local ndata = data:match("x(.+){59}")
          if not ndata then
            ndata = data:match("x(.+);")
            if not ndata then return data, "tex4ht@char-error" end
           -- return type(data), "tex4ht@char"
          end
          self.skip_one = true
          return unicode.utf8.char(tonumber(ndata,16)), "text"
        else
           return s, "tex4ht@characters"
        end
      end
      return t..s, "tex4ht"
    end,
    finish = function(self)
      local stream = self.stream or {}
      local current = self.current or {}
      table.insert(stream, current)
      if #stream > 0 then
        self.stream = stream
      else 
        self.stream = nil
      end
      self.current = nil
      return self
    end
  }
  return setmetatable({},{__index = Parser})
end
NodeCount = {
  nodes = {},
  current = nil
}

NodeCount.__index = NodeCount

NodeCount.new = function()
  local self = setmetatable({}, NodeCount)
  return self
end

function NodeCount:process_hlist(head)
  --[[local n = "[" 
  local j = nil
  for _,v in pairs(head) do
  if type(v) == "table" then
  j = self:process_hlist(v)
  else
  j = v 
  end
  n = n .. ":"..j
  end
  return n .."]"
  --]]
  local np = NodeParser()
  for v in node.traverse(head) do
    print(v.id)
    np:add(v)
  end
  --print_r(np)
  return np:finish()
end


--local j = {"aaa","nnn",{"qq","qqq","www"},"qqq","ssd"}
--local k = NodeCount.new()
--local s = k:process_hlist(j)

function print_r(t, depth)
  local depth = depth or 0
  if not t then print "nil"; return nil end
  local pad = string.rep(" ",depth*2)
  for k,v in pairs(t) do
    if type(v)=="table" then
      print(pad .. k)
      print_r(v, depth+1)
    elseif type(v) == "function" then
      print("Funkce :"..k)
    elseif v == true then print "true" 
    elseif v == false then print "false"
    else
      print(pad..k..": "..v)
    end
  end
end

m.NodeParser = NodeParser
m.NodeCount  = NodeCount
return m
--print_r(s)
--persistence.store("pokus.txt", s)
