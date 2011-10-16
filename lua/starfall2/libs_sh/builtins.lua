-------------------------------------------------------------------------------
-- Builtins.lua
-- Functions built-in to the default environment
-- @class file
-------------------------------------------------------------------------------

local function createRefMtbl(target)
	local tbl = {}
	tbl.__index = function(self,k) if k:sub(1,2) ~= "__" then return target[k] end end
	tbl.__newindex = function() end
	SF.Typedef("Module", tbl)
	return tbl
end

local dgetmeta = debug.getmetatable

-- ------------------------- Lua Ports ------------------------- --
-- This part is messy because of LuaDoc stuff.

--- Same as the Gmod vector type
-- @name SF.DefaultEnvironment.Vector
-- @class function
-- @param x
-- @param y
-- @param z
SF.DefaultEnvironment.Vector = Vector
--- Same as the Gmod angle type
-- @name SF.DefaultEnvironment.Angle
-- @class function
-- @param p Pitch
-- @param y Yaw
-- @param r Roll
SF.DefaultEnvironment.Angle = Angle
--- Same as the Gmod VMatrix type
-- @name SF.DefaultEnvironment.VMatrix
-- @class function
SF.DefaultEnvironment.Matrix = Matrix
--- Same as Lua's tostring
-- @name SF.DefaultEnvironment.tostring
-- @class function
-- @param obj
SF.DefaultEnvironment.tostring = tostring
--- Same as Lua's tonumber
-- @name SF.DefaultEnvironment.tonumber
-- @class function
-- @param obj
SF.DefaultEnvironment.tonumber = tonumber
--- Same as Lua's ipairs
-- @name SF.DefaultEnvironment.ipairs
-- @class function
-- @param tbl
SF.DefaultEnvironment.ipairs = ipairs
--- Same as Lua's pairs
-- @name SF.DefaultEnvironment.pairs
-- @class function
-- @param tbl
SF.DefaultEnvironment.pairs = pairs
--- Same as Lua's type
-- @name SF.DefaultEnvironment.type
-- @class function
-- @param obj
SF.DefaultEnvironment.type = type
--- Same as Lua's next
-- @name SF.DefaultEnvironment.next
-- @class function
-- @param tbl
SF.DefaultEnvironment.next = next
--- Same as Lua's assert
-- @name SF.DefaultEnvironment.assert
-- @class function
-- @param condition
-- @param msg
SF.DefaultEnvironment.assert = assert

--- Same as Lua's setmetatable. Doesn't work on most internal metatables
SF.DefaultEnvironment.setmetatable = function(tbl, meta)
	SF.CheckType(tbl,"table")
	SF.CheckType(meta,"table")
	if dgetmeta(tbl).__metatable then error("cannot change a protected metatable",2) end
	return setmetatable(tbl,meta)
end
--- Same as Lua's getmetatable. Doesn't work on most internal metatables
SF.DefaultEnvironment.getmetatable = function(tbl)
	SF.CheckType(tbl,"table")
	return getmetatable(tbl)
end
--- Throws an error. Can't change the level yet.
SF.DefaultEnvironment.error = function(msg) error(msg,2) end

-- The below modules have the Gmod functions removed (the ones that begin with a capital letter),
-- as requested by Divran

-- Filters Gmod Lua files based on Garry's naming convention.
local function filterGmodLua(lib)
	local original, gm = {}, {}
	for name, func in pairs(lib) do
		local char = name:sub(1,1)
		if char:upper() == char then
			gm[name] = func
		else
			original[name] = func
		end
	end
	return original, gm
end

-- String library
local str_orig, str_gm = filterGmodLua(string)
-- Lua's (not glua's) string library
-- @class table
SF.DefaultEnvironment.string = setmetatable({},createRefMtbl(str_orig))

-- Math library
local math_orig, _ = filterGmodLua(math)
math_orig.clamp = math.Clamp
math_orig.round = math.Round
math_orig.randfloat = math.Rand
math_orig.calcBSplineN = nil

-- Lua's (not glua's) math library, plus clamp, round, and randfloat
-- @class table
SF.DefaultEnvironment.math = setmetatable({},createRefMtbl(math_orig))

-- ------------------------- Functions ------------------------- --

--- Loads a library.
function SF.DefaultEnvironment.loadLibrary(name)
	SF.CheckType(name,"string")
	local instance = SF.instance
	
	if instance.context.libs[name] then
		return setmetatable({},instance.context.libs[name])
	else
		return SF.Libraries.Get(name)
	end
end

--- Sets a hook function
function SF.DefaultEnvironment.setHook(name, func)
	SF.CheckType(name,"string")
	if func then SF.CheckType(func,"function") end
	
	local inst = SF.instance
	inst.hooks[name:lower()] = func or nil
end

if SERVER then
	--- Prints a message to the owner's chat.
	function SF.DefaultEnvironment.print(s)
		SF.instance.player:PrintMessage(HUD_PRINTTALK, tostring(s):sub(1,255))
	end
else
	function SF.DefaultEnvironment.print(s)
		SF.instance.player:PrintMessage(HUD_PRINTTALK, tostring(s))
	end
end
-- ------------------------- Restrictions ------------------------- --
-- Restricts access to builtin type's metatables

local function createSafeIndexFunc(mt)
	local old_index
	local function new_index(self, k)
		if k:sub(1,2) ~= "__" then return old_index(self,k) end
	end
	
	local function protect()
		old_index = mt.__index
		mt.__index = new_index
	end

	local function unprotect()
		mt.__index = old_index
	end

	return protect, unprotect
end

local vector_restrict, vector_unrestrict = createSafeIndexFunc(_R.Vector)
local angle_restrict, angle_unrestrict = createSafeIndexFunc(_R.Angle)
local matrix_restrict, matrix_unrestrict = createSafeIndexFunc(_R.VMatrix)

local function restrict(instance, hook)
	vector_restrict()
	angle_restrict()
	matrix_restrict()
end

local function unrestrict(instance, hook)
	vector_unrestrict()
	angle_unrestrict()
	matrix_unrestrict()
end

SF.Libraries.AddHook("prepare", restrict)
SF.Libraries.AddHook("cleanup", unrestrict)
