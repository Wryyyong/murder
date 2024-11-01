function GM:SetAmMurderer(bool)
	self.Murderer = bool
end

function GM:GetAmMurderer()
	return self.Murderer
end

net.Receive("you_are_a_murderer",function()
	GAMEMODE:SetAmMurderer(net.ReadBool())
end)
