net.Receive("chattext_msg",function()
	local msgs = {}

	while true do
		if not net.ReadBool() then break end
		local str = net.ReadString()
		local col = net.ReadVector()
		table.insert(msgs,Color(col.x,col.y,col.z))
		table.insert(msgs,str)
	end

	chat.AddText(unpack(msgs))
end)
