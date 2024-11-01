-- Proxy Example:
--
--	Proxies
--	{
--		PlayerColor
--		{
--			resultVar	$color2
--		}
--	}
local BaseColor = Vector(62 / 255,88 / 255,106 / 255)
matproxy.Add({
	name = "PlayerColor",
	init = function(self,_,values)
		-- Store the name of the variable we want to set
		self.ResultTo = values.resultvar
	end,
	bind = function(self,mat,ent)
		if not IsValid(ent) then return end

		-- retarded garry shit
		-- if ( ent:IsRagdoll() ) then
		-- 	ent = ent:GetRagdollOwner()
		-- 	if ( !IsValid( ent ) ) then return end
		-- end
		if ent.GetPlayerColor then
			local col = ent:GetPlayerColor()

			if isvector(col) then
				mat:SetVector(self.ResultTo,col)
			end
		else
			mat:SetVector(self.ResultTo,BaseColor)
		end
	end
})
