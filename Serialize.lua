--[[

Serialize
Author: g_captain
Serializes Roblox datatypes into tables. A serialized value looks like this:
{"Vector3",{13,4,3}}

BrickColor
CFrame
Color3
EnumItem
NumberRange
UDim
UDim2
Vector2
Vector3

Serialize.Serialize(value)
Serialize.Deserialize(packed)
Serialize.SerializeAll(tuple values)
Serialize.DeserializeAll(tuple values)

]]

local Serialize = {}

function Serialize.pack(dtype, value)
	return {dtype, value}
end
local pack = Serialize.pack

Serialize.lib = {
	["BrickColor"] = {
		serialize = function(value) 
			return pack("BrickColor", {tostring(value)})
		end,
		deserialize = function(value)
			return BrickColor.new(value)
		end
	},
	["CFrame"] = {
		serialize = function(value)
			return pack("CFrame", {value:GetComponents()})
		end,
		deserialize = function(value)
			return CFrame.new(table.unpack(value))
		end
	},
	["Color3"] = {
		serialize = function(value)
			local f = math.floor
			return pack("Color3", {f(value.R*255), f(value.G*255), f(value.B*255)})
		end,
		deserialize = function(value)
			return Color3.fromRGB(table.unpack(value))
		end
	},
	["EnumItem"] = {
		serialize = function(value)
			local str = tostring(value)
			local _, _, k, v = str:find("Enum%.(%a+)%.(%a+)")
			local split = {k, v}
			return pack("EnumItem", split)
		end,
		deserialize = function(value)
			return Enum[value[1]][value[2]]
		end
	},
	["NumberRange"] = {
		serialize = function(value)
			return pack("NumberRange", {value.Min, value.Max})
		end,
		deserialize = function(value)
			return NumberRange.new(table.unpack(value))
		end
	},
	["UDim"] = {
		serialize = function(value)
			return pack("UDim", {value.Scale, value.Offset})
		end,
		deserialize = function(value)
			return UDim.new(table.unpack(value))
		end
	},
	["UDim2"] = {
		serialize = function(value)
			return pack("UDim2", {value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset})
		end,
		deserialize = function(value)
			return UDim2.new(table.unpack(value))
		end
	},
	["Vector2"] = {
		serialize = function(value)
			return pack("Vector2", {value.X, value.Y})
		end,
		deserialize = function(value)
			return Vector2.new(table.unpack(value))
		end
	},
	["Vector3"] = {
		serialize = function(value)
			return pack("Vector3", {value.X, value.Y, value.Z})
		end,
		deserialize = function(value)
			return Vector3.new(table.unpack(value))
		end
	}
}

function Serialize.Serialize(value)
	local Type = typeof(value)
	if Serialize.lib[Type] then
		return Serialize.lib[Type].serialize(value)
	else
		return value
	end
end

function Serialize.Deserialize(packed)
	local Type = typeof(packed)
	Type = Type=="table" and packed[1] or Type
	if Serialize.lib[Type] then
		return Serialize.lib[Type].deserialize(packed[2])
	else
		return packed
	end
end

function Serialize.SerializeAll(...)
	local toSerialize = {...}
	local serialized = {}
	for _, value in pairs(toSerialize) do
		table.insert(serialized, Serialize.Serialize(value))
	end
	return table.unpack(serialized)
end

function Serialize.DeserializeAll(...)
	local toDeserialize = {...}
	local deserialized = {}
	for _, packed in pairs(toDeserialize) do
		table.insert(deserialized, Serialize.Deserialize(packed))
	end
	return table.unpack(deserialized)
end

return Serialize
