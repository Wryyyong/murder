util.AddNetworkString("chattext_msg")
local meta = {}
meta.__index = meta

function meta:Add(string,color)
	local t = {}
	t.text = string
	t.color = color or self.default_color or color_white
	table.insert(self.msgs,t)

	return self
end

function meta:AddPart(msg)
	table.insert(self.msgs,msg)

	return self
end

function meta:AddParts(msgs)
	for _,msg in pairs(msgs) do
		table.insert(self.msgs,msg)
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

	for _,msg in pairs(self.msgs) do
		net.WriteBool(true)
		net.WriteString(msg.text)

		if not msg.color then
			msg.color = self.default_color or color_white
		end

		net.WriteVector(Vector(msg.color.r,msg.color.g,msg.color.b))
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
	for _,line in pairs(self.msgs) do
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
