if SERVER then
	AddCSLuaFile()
end

SWEP.Base = "weapon_base"
SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.UseHands = true
SWEP.Author = "Mechanical Mind"
SWEP.Contact = ""
SWEP.Purpose = ""
SWEP.Instructions = ""
SWEP.ViewModelFOV = 90
SWEP.HolsterHoldTime = 0.3
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
local STATE_HOLSTER,STATE_IDLE = 0,1

function SWEP:Initialize()
	self:SetHoldType(self.HoldType or "normal")
	self:SetWeaponState(STATE_HOLSTER)
	self.IronsightsPercent = 0
end

function SWEP:SetupDataTables()
	self:NetworkVar("Int",0,"WeaponState")
	self:NetworkVar("Float",0,"ReloadEnd")
	self:NetworkVar("Float",1,"NextIdle")
	self:NetworkVar("Float",2,"DrawEnd")
end

function SWEP:IsIdle()
	local CurrentTime = CurTime()
	local ReloadEnd = self:GetReloadEnd()
	local NextPrimaryFire = self:GetNextPrimaryFire()
	local DrawEnd = self:GetDrawEnd()

	return not ((ReloadEnd > 0 and ReloadEnd >= CurrentTime) or (NextPrimaryFire > 0 and NextPrimaryFire >= CurrentTime) or (DrawEnd > 0 and DrawEnd >= CurrentTime))
end

function SWEP:PrimaryAttack()
	if not self:IsIdle() then return end

	if self:GetMaxClip1() > 0 and self:Clip1() <= 0 then
		self:Reload()

		return
	end

	local owner = self:GetOwner()
	local vm = owner:GetViewModel()

	if self.Primary.Sequence then
		local sequence = self.Primary.Sequence

		if type(sequence) == "table" then
			if IsFirstTimePredicted() then
				self.LastSequence = ((self.LastSequence or -1) + 1) % #sequence
			end

			sequence = sequence[self.LastSequence + 1]
		end

		vm:SendViewModelMatchingSequence(vm:LookupSequence(sequence))
	end

	self:SetNextPrimaryFire(CurTime() + (self.Primary.Delay or vm:SequenceDuration()))
	self:SetNextIdle(CurTime() + vm:SequenceDuration())
	self:TakePrimaryAmmo(1)

	if self.Primary.Sound then
		self:EmitSound(self.Primary.Sound)
	end

	owner:SetAnimation(PLAYER_ATTACK1)
	local stats = {}
	stats.recoil = self.Primary.Recoil or 1
	stats.damage = self.Primary.Damage or 1
	stats.cone = self.Primary.Cone or 0.1

	if self.Primary.Recoil then
		stats.recoil = stats.recoil or 1

		if IsFirstTimePredicted() and CLIENT then
			local circle = Angle(0,math.Rand(0,360),0)
			local vec = circle:Forward() * math.Rand(stats.recoil * 0.8,stats.recoil) * 0.1
			vec.y = -math.abs(vec.y) - stats.recoil * 0.2

			if ViewPosition then
				ViewPosition:Recoil(vec)
			end
		end
	end

	hook.Run("CalculateWeaponPrimaryFireStats",self,owner,stats)
	self:DoPrimaryAttackEffect(stats)
end

function SWEP:DoPrimaryAttackEffect(stats)
	local owner = self:GetOwner()
	local bullet = {
		["Num"] = self.Primary.NumShots or 1,
		["Src"] = owner:GetShootPos(),
		["Dir"] = owner:GetAimVector(),
		["Spread"] = Vector(stats.cone or 0,stats.cone or 0,0),
		["Tracer"] = self.Primary.Tracer or 1,
		["Force"] = self.Primary.Force or (self.Primary.Damage or 1) * 3,
		["Damage"] = stats.damage or 1
	}
	owner:FireBullets(bullet)
end

function SWEP:SecondaryAttack()
end

local function CustomLerp(from,to,step)
	return from < to and math.min(from + step,to) or math.max(from - step,to)
end

function SWEP:Think()
	local owner = self:GetOwner()
	if self:GetReloadEnd() > 0 and self:GetReloadEnd() < CurTime() then
		self:SetReloadEnd(0)

		if self.Primary.InfiniteAmmo then
			self:SetClip1(self:GetMaxClip1())
		else
			local spare = owner:GetAmmoCount(self:GetPrimaryAmmoType())
			local addAmmo = math.min(self:GetMaxClip1() - self:Clip1(),spare)
			self:SetClip1(self:Clip1() + addAmmo)
			owner:SetAmmo(spare - addAmmo,self:GetPrimaryAmmoType())
		end
	end

	if self:GetNextIdle() > 0 and self:GetNextIdle() < CurTime() then
		self:SetNextIdle(0)
		local sequence = self.SequenceIdle
		local vm = owner:GetViewModel()
		vm:SendViewModelMatchingSequence(vm:LookupSequence(sequence))

		if self.Primary.AutoReload and self:GetMaxClip1() > 0 and self:Clip1() <= 0 then
			self:Reload()
		end
	end

	if IsValid(owner) then
		if not owner:KeyDown(IN_RELOAD) then
			self.ReloadHoldStart = nil
		end

		self.UsingIronsights = false

		if owner:KeyDown(IN_ATTACK2) and self:GetWeaponState() ~= STATE_HOLSTER then
			self.UsingIronsights = true
		end
	end

	self.IronsightsPercent = CustomLerp(self.IronsightsPercent,self.UsingIronsights and 1 or 0,FrameTime() * 2.5)
end

function SWEP:Reload()
	if self:IsIdle() and self:GetWeaponState() == STATE_IDLE and self:GetMaxClip1() > 0 and self:Clip1() < self:GetMaxClip1() then
		local owner = self:GetOwner()
		local spare = owner:GetAmmoCount(self:GetPrimaryAmmoType())

		if spare > 0 or self.Primary.InfiniteAmmo then
			local vm = owner:GetViewModel()
			vm:SendViewModelMatchingSequence(vm:LookupSequence(self.ReloadSequence))

			if self.ReloadSound then
				self:EmitSound(self.ReloadSound)
			end

			owner:SetAnimation(PLAYER_RELOAD)
			self:SetReloadEnd(CurTime() + vm:SequenceDuration())
			self:SetNextIdle(CurTime() + vm:SequenceDuration())
		end
	end
end

function SWEP:Deploy()
	self:SetWeaponState(STATE_IDLE)
	local time = 1
	local vm = self:GetOwner():GetViewModel()

	if IsValid(vm) then
		if self.SequenceDraw then
			vm:SendViewModelMatchingSequence(vm:LookupSequence(self.SequenceDraw))
			time = vm:SequenceDuration()
		elseif self.SequenceDrawTime then
			time = self.SequenceDrawTime
		end
	end

	self:SetDrawEnd(CurTime() + 0)
	self:SetNextIdle(CurTime() + time)

	return true
end

function SWEP:Holster()
	self:SetWeaponState(STATE_HOLSTER)

	return true
end

local function Ease(val)
	return val < .5 and 2 * val ^ 2 or -1 + (4 - 2 * val) * val
end

local function AddAngle(_,targetAng,addAng)
	targetAng:RotateAroundAxis(targetAng:Up(),addAng[2]) -- yaw
	targetAng:RotateAroundAxis(targetAng:Forward(),addAng[3]) -- roll
	targetAng:RotateAroundAxis(targetAng:Right(),addAng[1]) -- pitch
end
SWEP.AddAngle = AddAngle

-- iron sights
function SWEP:CalcViewModelView(_,_,_,pos,ang)
	local sPos,sAng
	if self.Ironsights then
		sPos = self.Ironsights.Pos
		sAng = self.Ironsights.Angle
	else
		sPos = Vector(0,0,0)
		sAng = Angle(0,0,0)
	end

	local EasedPerc = Ease(self.IronsightsPercent)
	sAng:Mul(EasedPerc)
	self:AddAngle(ang,sAng)
	sPos:Mul(EasedPerc)
	sPos:Rotate(ang)
	pos:Add(sPos)

	return pos,ang
end

function SWEP:OnRemove()
end
