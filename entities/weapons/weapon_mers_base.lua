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

function SWEP:Initialize()
	self:SetHoldType(self.HoldType or "normal")
	self:SetWeaponState("holster")
	self.IronsightsPercent = 0
end

function SWEP:SetupDataTables()
	self:NetworkVar("String",0,"WeaponState")
	self:NetworkVar("Float",0,"ReloadEnd")
	self:NetworkVar("Float",1,"NextIdle")
	self:NetworkVar("Float",2,"DrawEnd")
end

function SWEP:IsIdle()
	if
		(self:GetReloadEnd() > 0 and self:GetReloadEnd() >= CurTime()) or
		(self:GetNextPrimaryFire() > 0 and self:GetNextPrimaryFire() >= CurTime()) or
		(self:GetDrawEnd() > 0 and self:GetDrawEnd() >= CurTime())
	then return false end

	return true
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

local function lerp(from,to,step)
	if from < to then return math.min(from + step,to) end

	return math.max(from - step,to)
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

		if owner:KeyDown(IN_ATTACK2) and self:GetWeaponState() ~= "holster" then
			self.UsingIronsights = true
		end
	end

	self.IronsightsPercent = lerp(self.IronsightsPercent,self.UsingIronsights and 1 or 0,FrameTime() * 2.5)
end

function SWEP:Reload()
	if self:IsIdle() and self:GetWeaponState() == "normal" and self:GetMaxClip1() > 0 and self:Clip1() < self:GetMaxClip1() then
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
	self:SetWeaponState("normal")
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
	self:SetWeaponState("holster")

	return true
end

local function ease(t)
	if t < .5 then
		return 2 * t * t
	else
		return -1 + (4 - 2 * t) * t
	end
end

local function addangle(ang,ang2)
	ang:RotateAroundAxis(ang:Up(),ang2.y) -- yaw
	ang:RotateAroundAxis(ang:Forward(),ang2.r) -- roll
	ang:RotateAroundAxis(ang:Right(),ang2.p) -- pitch
end

function SWEP:CalcViewModelView(_,_,_,pos,ang)
	-- iron sights
	local addpos,addang = Vector(0,0,0),Angle(0,0,0)

	if self.Ironsights then
		addpos = self.Ironsights.Pos or addpos
		addang = self.Ironsights.Angle or addang
	end

	local pos2 = addpos * ease(self.IronsightsPercent)
	addangle(ang,addang * ease(self.IronsightsPercent))
	pos2:Rotate(ang)

	return pos + pos2,ang
end

function SWEP:OnRemove()
end
