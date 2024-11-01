local ChatColorCache = ChatColorCache or {}

local function ColorCache(r,g,b)
	if not (isnumber(r) and isnumber(g) and isnumber(b)) then return color_white end

	local hexString = bit.tohex(r,2) .. bit.tohex(g,2) .. bit.tohex(b,2)
	local cache = ChatColorCache[hexString]
	if cache then return cache end

	local color = Color(r,g,b)
	ChatColorCache[hexString] = color
	return color
end

net.Receive("chattext_msg",function()
	local msgs = {}

	while net.ReadBool() do
		local str = net.ReadString()
		if net.ReadBool() then
			local r = net.ReadUInt(8)
			local g = net.ReadUInt(8)
			local b = net.ReadUInt(8)
			msgs[#msgs + 1] = ColorCache(r,g,b)
		else
			msgs[#msgs + 1] = color_white
		end
		msgs[#msgs + 1] = str
	end

	chat.AddText(unpack(msgs))
end)
