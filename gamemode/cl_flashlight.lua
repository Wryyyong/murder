function GM:GetFlashlightCharge()
	return self.FlashlightCharge or 1
end

net.Receive("flashlight_charge",function()
	GAMEMODE.FlashlightCharge = net.ReadFloat()
end)
