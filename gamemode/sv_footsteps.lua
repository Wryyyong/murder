util.AddNetworkString("add_footstep")
util.AddNetworkString("clear_footsteps")

function GM:FootstepsOnFootstep(ply,pos)
	net.Start("add_footstep")
	net.WriteEntity(ply)
	net.WriteVector(pos)
	net.WriteAngle(ply:GetAimVector():Angle())
	local tab = {}

	for _,plyr in ipairs(player.GetAll()) do
		if self:CanSeeFootsteps(plyr) then
			table.insert(tab,plyr)
		end
	end

	net.Send(tab)
end

function GM:CanSeeFootsteps(ply)
	if ply:GetMurderer() and ply:Alive() then return true end

	return false
end

function GM:ClearAllFootsteps()
	net.Start("clear_footsteps")
	net.Broadcast()
end
