if CLIENT then
	function SWEP:DrawWeaponSelection()
	end
end

SWEP.Base = "weapon_mers_base"
SWEP.Slot = 0
SWEP.SlotPos = 1
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true
SWEP.ViewModel = ""
SWEP.WorldModel = ""
SWEP.ViewModelFlip = false
SWEP.HoldType = "normal"
SWEP.SequenceDraw = "fists_draw"
SWEP.SequenceIdle = "fists_idle_01"
SWEP.PrintName = translate and translate.hands or "Hands"

function SWEP:Initialize()
	self.BaseClass.Initialize(self)
	self.PrintName = translate and translate.hands or "Hands"
end

function SWEP:DoPrimaryAttackEffect()
end

local BasePos,BaseAng = Vector(-35,0,0),Angle(-90,0,0)

function SWEP:CalcViewModelView(_,_,_,pos,ang)
	-- iron sights
	self:AddAngle(ang,BaseAng)
	pos:Rotate(ang)
	pos:Add(BasePos)

	return pos,ang
end

local pickupWhiteList = {
	prop_ragdoll = true,
	prop_physics = true,
	prop_physics_multiplayer = true
}

if SERVER then
	function SWEP:CanPickup(ent)
		if ent:IsWeapon() or ent:IsPlayer() or ent:IsNPC() then return false end
		if pickupWhiteList[ent:GetClass()] then return true end

		return false
	end
end

function SWEP:SecondaryAttack()
	if SERVER then
		self:SetCarrying()
		local tr = self:GetOwner():GetEyeTraceNoCursor()

		if IsValid(tr.Entity) and self:CanPickup(tr.Entity) then
			self:SetCarrying(tr.Entity,tr.PhysicsBone)
			self:ApplyForce()
		end
	end
end

function SWEP:ApplyForce()
	local owner = self:GetOwner()
	local target = owner:GetAimVector() * 30 + owner:GetShootPos()
	local phys = self.CarryEnt:GetPhysicsObjectNum(self.CarryBone)

	if IsValid(phys) then
		local vec = target - phys:GetPos()
		local len = vec:Length()

		if len > 40 then
			self:SetCarrying()

			return
		end

		vec:Normalize()
		local tvec = vec * len * 15
		local avec = tvec - phys:GetVelocity()
		avec = avec:GetNormal() * math.min(45,avec:Length())
		avec = avec / phys:GetMass() * 16
		phys:AddVelocity(avec)
	end
end

function SWEP:GetCarrying()
	return self.CarryEnt
end

function SWEP:SetCarrying(ent,bone)
	if IsValid(ent) then
		self.CarryEnt = ent
		self.CarryBone = bone
	else
		self.CarryEnt = nil
		self.CarryBone = nil
	end

	self:GetOwner():CalculateSpeed()
end

function SWEP:Think()
	self.BaseClass.Think(self)
	local owner = self:GetOwner()

	if IsValid(owner) and owner:KeyDown(IN_ATTACK2) then
		if IsValid(self.CarryEnt) then
			self:ApplyForce()
		end
	elseif self.CarryEnt then
		self:SetCarrying()
	end
end

function SWEP:PrimaryAttack()
	local owner = self:GetOwner()

	if SERVER then
		if owner:HasWeapon("weapon_mu_knife") then
			owner:SelectWeapon("weapon_mu_knife")
		elseif owner:HasWeapon("weapon_mu_magnum") then
			owner:SelectWeapon("weapon_mu_magnum")
		end
	end
end
