-- module("...",package.seeall())
local persistence = require "realpgno-persistence"
local stack      = require "realpgno-stack"

local NodeParser = function()
	local Parser = {
		start = function(self,value,t) 
			local t = t or "text"
		  return {value = value, type = t}
		end,
	  stream = {},
		current = {},
		add = function(self, n)
			local value,t = self:get_type(n)
			if value then
				local current = self.current or {}
				local stream = self.stream or {}
				if current and t == current.type then
					current.value = current.value .." + ".. value
				else
					print("Měníme stream")
					print(value,t)
					if current then 
					  table.insert(stream, self:start(current.value,current.type))
					end
					current = self:start(value,t)
				end
				self.current = current
				self.stream = stream
			end
		end,
		get_type = function(self,n)
			if type(n) =="table" then
				local nl = NodeCount.new()
				return nl:process_hlist(n), "hlist"
			else
				return n, "text"
			end
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
	for _, v in pairs(head) do
		np:add(v)
	end
	return np
end


local j = {"aaa","nnn",{"qq","qqq","www"},"qqq","ssd"}
local k = NodeCount.new()
local s = k:process_hlist(j)

local function print_r(t, depth)
	local depth = depth or 0
	local pad = string.rep(" ",depth*2)
	for k,v in pairs(t) do
		if type(v)=="table" then
			print(pad .. k)
			print_r(v, depth+1)
		elseif type(v) == "function" then
			print("Funkce :"..k)
		else
			print(pad..k..": "..v)
		end
	end
end

print_r(s)
persistence.store("pokus.txt", s)
