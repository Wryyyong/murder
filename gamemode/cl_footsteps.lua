GM.FootstepMaxLifeTime = CreateClientConVar("mu_footstep_maxlifetime",30,true,true)
local FootSteps = {}

if FootStepsG then
	FootSteps = FootStepsG
end

FootStepsG = FootSteps

function GM:FootStepsInit()
end

local footMat = Material("thieves/footprint")
-- local CircleMat = Material( "Decals/burn02a" )
local maxDistance = 600 ^ 2

local function renderfoot(gmTbl)
	if #FootSteps == 0 then return end
	cam.Start3D(EyePos(),EyeAngles())
	render.SetMaterial(footMat)
	-- local pos = EyePos()
	local lifeTime = math.Clamp(gmTbl.FootstepMaxLifeTime:GetInt(),0,30)

	for idx,footstep in ipairs(FootSteps) do
		if footstep.curtime + lifeTime > CurTime() then
			if (footstep.pos - EyePos()):LengthSqr() < maxDistance then
				render.DrawQuadEasy(footstep.pos + footstep.normal * 0.01,footstep.normal,10,20,footstep.col,footstep.angle)
			end
		else
			FootSteps[idx] = nil
		end
	end

	cam.End3D()
end

function GM:DrawFootprints()
	local errored,retval = pcall(renderfoot,self)
	if errored then return end
	ErrorNoHalt(retval)
end

local TraceVectorStart = Vector(0,0,-10)

function GM:AddFootstep(ply,pos,ang,foot)
	ang.p = 0
	ang.r = 0
	local fpos = pos

	if ply.LastFoot then
		fpos = fpos + ang:Right() * 5
	else
		fpos = fpos + ang:Right() * -5
	end

	ply.LastFoot = not ply.LastFoot

	local tr = util.TraceLine({
		["start"] = fpos,
		["endpos"] = fpos + TraceVectorStart,
		["filter"] = ply
	})

	if not tr.Hit then return end

	local tbl = {
		["pos"] = tr.HitPos,
		["plypos"] = fpos,
		["foot"] = foot,
		["curtime"] = CurTime(),
		["angle"] = ang.y,
		["normal"] = tr.HitNormal,
		["col"] = ply:GetPlayerColor():ToColor()
	}

	FootSteps[#FootSteps + 1] = tbl
end

function GM:FootStepsFootstep(ply,pos,foot,snd,volume,filter)
	if ply ~= LocalPlayer() then return end
	if not self:CanSeeFootsteps() then return end
	self:AddFootstep(ply,pos,ply:GetAimVector():Angle(),foot,snd,volume,filter)
end

function GM:CanSeeFootsteps()
	if self:GetAmMurderer() and LocalPlayer():Alive() then return true end

	return false
end

function GM:ClearFootsteps()
	FootSteps = {}
end

net.Receive("add_footstep",function()
	local ply = net.ReadEntity()
	local pos = net.ReadVector()
	local ang = net.ReadAngle()
	if not IsValid(ply) then return end
	if ply == LocalPlayer() then return end
	if not GAMEMODE:CanSeeFootsteps() then return end
	GAMEMODE:AddFootstep(ply,pos,ang)
end)

net.Receive("clear_footsteps",function()
	GAMEMODE:ClearFootsteps()
end)
