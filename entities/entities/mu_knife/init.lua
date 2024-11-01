AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel(self.KnifeModel)
	self:PhysicsInit(SOLID_VPHYSICS)
	-- self:PhysicsInitSphere(50)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:DrawShadow(false)
	-- don't do impact damage
	-- self:SetTrigger(true)
	-- self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	local phys = self:GetPhysicsObject()

	if IsValid(phys) then
		phys:Wake()
	end

	self:Fire("kill","",30)
	self.HitSomething = false
end

function ENT:Use()
	self.RemoveNext = true
end

function ENT:Think()
	if IsValid(self) and self.RemoveNext then
		self.RemoveNext = false
		self:Remove()
	end

	if self.HitSomething and self:GetVelocity():Length2D() < 1.5 then
		self.HitSomething = false
		local knife = ents.Create("weapon_mu_knife")
		knife:SetPos(self:GetPos())
		knife:SetAngles(self:GetAngles())
		knife:Spawn()
		self:Remove()
		local phys = knife:GetPhysicsObject()

		if IsValid(phys) then
			phys:SetVelocity(self:GetVelocity())
		end
	end

	self:NextThink(CurTime())

	return true
end

local function AddAngle(targetAng,addAng)
	targetAng:RotateAroundAxis(targetAng:Up(),addAng[2]) -- yaw
	targetAng:RotateAroundAxis(targetAng:Forward(),addAng[3]) -- roll
	targetAng:RotateAroundAxis(targetAng:Right(),addAng[1]) -- pitch
end

local CollideAngle,RagdollAngle = Angle(-60,0,0),Angle(30,-90,0)

function ENT:PhysicsCollide(data)
	if self.HitSomething or self.RemoveNext then return end
	local ply = data.HitEntity

	if IsValid(ply) and ply:IsPlayer() then
		local dmg = DamageInfo()
		dmg:SetDamage(120)
		dmg:SetAttacker(self:GetOwner())
		ply:TakeDamageInfo(dmg)
		self:EmitSound("physics/flesh/flesh_squishy_impact_hard" .. math.random(1,4) .. ".wav")
		local newPlyAng = ply:GetAngles()
		AddAngle(newPlyAng,CollideAngle)
		ply:SetEyeAngles(newPlyAng)

		timer.Simple(0,function()
			local rag = ply:GetRagdollEntity()

			if IsValid(rag) then
				local pos,ang = rag:GetBonePosition(0)
				local vec = Vector(0,16,-14)
				vec:Rotate(ang)
				pos:Add(vec)
				AddAngle(ang,RagdollAngle)
				rag:SetPos(pos)
				rag:SetAngles(ang)
			end
		end)
	end

	self.HitSomething = true
end
