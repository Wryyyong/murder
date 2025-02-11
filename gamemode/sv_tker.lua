local PlayerMeta = FindMetaTable("Player")
--local EntityMeta = FindMetaTable("Entity")
util.AddNetworkString("mu_tker")

function PlayerMeta:SetTKer(bool)
	if bool then
		self.LastTKTime = CurTime()

		timer.Simple(0,function()
			if IsValid(self) and self:HasWeapon("weapon_mu_magnum") then
				local wep = self:GetWeapon("weapon_mu_magnum")
				wep.LastTK = self
				wep.LastTKTime = CurTime()
				self:DropWeapon(wep)
			end
		end)
	else
		self.LastTKTime = nil
	end

	net.Start("mu_tker")
	net.WriteBool(bool)
	net.Send(self)
	self:CalculateSpeed()
end

function PlayerMeta:GetTKer()
	return self.LastTKTime and true or false
end
