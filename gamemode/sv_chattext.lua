util.AddNetworkString("chattext_msg")
local meta = {}
meta.__index = meta

function meta:Add(instring,color)
	local t = {}
	t.text = instring
	t.color = color or self.default_color or color_white
	self.msgs[#self.msgs + 1] = t

	return self
end

function meta:AddPart(msg)
	self.msgs[#self.msgs + 1] = msg

	return self
end

function meta:AddParts(msgs)
	for _,msg in ipairs(msgs) do
		self.msgs[#self.msgs + 1] = msg
	end

	return self
end

function meta:SetDefaultColor(color)
	self.default_color = color

	return self
end

function meta:SendAll()
	self:NetConstructMsg()
	net.Broadcast()

	return self
end

function meta:Send(players)
	self:NetConstructMsg()

	if players == nil then
		net.Broadcast()
	else
		net.Send(players)
	end

	return self
end

function meta:NetConstructMsg()
	net.Start("chattext_msg")

	for _,msg in ipairs(self.msgs) do
		net.WriteBool(true)
		net.WriteString(msg.text)

		local color = tobool(msg.color and msg.color ~= color_white)
		net.WriteBool(color)
		if color then
			net.WriteUInt(msg.color.r,8)
			net.WriteUInt(msg.color.g,8)
			net.WriteUInt(msg.color.b,8)
		end

	end

	net.WriteBool(false)

	return self
end

function ChatText(msgs)
	local t = {}
	t.msgs = msgs or {}
	setmetatable(t,meta)

	return t
end

function meta:Print()
	for _,line in ipairs(self.msgs) do
		MsgC(line.color,line.text)
	end

	return self
end

function MsgClients(msgs)
	local t = {}
	t.msgs = msgs or {}
	setmetatable(t,meta)

	return t
end
