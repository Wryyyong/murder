function GM:SetAmMurderer(bool)
	self.Murderer = bool
end

function GM:GetAmMurderer()
	return self.Murderer
end

net.Receive("your_are_a_murderer",function()
	local am = net.ReadUInt(8) ~= 0
	GAMEMODE:SetAmMurderer(am)
end)
