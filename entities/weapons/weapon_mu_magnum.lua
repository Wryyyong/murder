if CLIENT then
	function SWEP:DrawWeaponSelection()
	end
end

SWEP.Base = "weapon_mers_base"
SWEP.Slot = 1
SWEP.SlotPos = 1
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true
SWEP.ViewModel = Model("models/weapons/c_357.mdl")
SWEP.WorldModel = Model("models/weapons/w_357.mdl")
SWEP.ViewModelFOV = 70
SWEP.ViewModelFlip = false
SWEP.HoldType = "revolver"
SWEP.SequenceDraw = "draw"
SWEP.SequenceIdle = "idle01"
SWEP.SequenceHolster = "holster"
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = false
SWEP.Primary.Sound = "Weapon_357.Single"
SWEP.Primary.Sequence = "fire"
-- SWEP.Primary.Delay = 0.
SWEP.Primary.Damage = 200
SWEP.Primary.Cone = 0
SWEP.Primary.DryFireSequence = "fireempty"
SWEP.Primary.DryFireSound = Sound("Weapon_Pistol.Empty")
SWEP.Primary.Recoil = 9
SWEP.Primary.InfiniteAmmo = true
SWEP.Primary.AutoReload = true
SWEP.ReloadSequence = "reload"
SWEP.ReloadSound = "weapons/357/357_reload1.wav"
SWEP.PrintName = translate and translate.magnum or "Magnum"

function SWEP:Initialize()
	self.BaseClass.Initialize(self)
	self.PrintName = translate and translate.magnum or "Magnum"
	self:SetClip1(self:GetMaxClip1())
end

function SWEP:DoPrimaryAttackEffect(stats)
	local owner = self:GetOwner()

	-- Set up the shot
	local bullet = {
		["Num"] = self.Primary.NumShots or 1,
		["Src"] = owner:GetShootPos(),
		["Dir"] = owner:GetAimVector(),
		["Spread"] = Vector(stats.cone or 0,stats.cone or 0,0),
		["Tracer"] = 1,
		["Force"] = self.Primary.Force or (self.Primary.Damage or 1) * 3,
		["Damage"] = stats.damage or 1
	}

	owner:FireBullets(bullet)
end
