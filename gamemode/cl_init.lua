include("sh_translate.lua")
include("shared.lua")
include("cl_hud.lua")
include("cl_scoreboard.lua")
include("cl_footsteps.lua")
include("cl_respawn.lua")
include("cl_murderer.lua")
include("cl_player.lua")
include("cl_fixplayercolor.lua")
include("cl_ragdoll.lua")
include("cl_chattext.lua")
include("cl_voicepanels.lua")
include("cl_rounds.lua")
include("cl_endroundboard.lua")
include("cl_qmenu.lua")
include("cl_spectate.lua")
include("cl_adminpanel.lua")
include("cl_flashlight.lua")
include("cl_halos.lua")
include("cl_spawns.lua")
GM.Debug = CreateClientConVar("mu_debug",0,true,true,"Enable debug info.",0,1)
GM.HaloRender = CreateClientConVar("mu_halo_render",1,true,true,"Render halos.",0,1) -- should we render halos
GM.HaloRenderLoot = CreateClientConVar("mu_halo_loot",1,true,true,"Render halos for loot.",0,1) -- shouuld we render loot halos
GM.HaloRenderKnife = CreateClientConVar("mu_halo_knife",1,true,true,"Render halos for the Murderer's knife.",0,1) -- shouuld we render murderer's knife halos

function GM:Initialize()
	self:FootStepsInit()
end

GM.FogEmitters = {}

if GAMEMODE then
	GM.FogEmitters = GAMEMODE.FogEmitters
end

local BasePos,BaseVel = Vector(0,0,30),Vector(0,0,4)

function GM:Think()
	for _,ply in ipairs(player.GetAll()) do
		if ply:Alive() and ply:GetNWBool("MurdererFog") then
			if not ply.FogEmitter then
				ply.FogEmitter = ParticleEmitter(ply:GetPos())
				self.FogEmitters[ply] = ply.FogEmitter
			end

			if not ply.FogNextPart then
				ply.FogNextPart = CurTime()
			end

			local pos = ply:GetPos()
			pos:Add(BasePos)
			local client = LocalPlayer()

			if ply.FogNextPart < CurTime() then
				if client:GetPos():Distance(pos) > 1000 then return end
				ply.FogEmitter:SetPos(pos)
				ply.FogNextPart = CurTime() + math.Rand(0.01,0.03)
				local vec = Vector(math.Rand(-8,8),math.Rand(-8,8),math.Rand(10,55))
				local fog_pos = ply:LocalToWorld(vec)
				local particle = ply.FogEmitter:Add("particle/snow.vmt",fog_pos)
				local particleVec = VectorRand()
				particleVec:Add(BaseVel)
				particleVec:Mul(3)
				particle:SetVelocity(particleVec)
				particle:SetDieTime(5)
				particle:SetStartAlpha(180)
				particle:SetEndAlpha(0)
				particle:SetStartSize(6)
				particle:SetEndSize(7)
				particle:SetRoll(0)
				particle:SetRollDelta(0)
				particle:SetColor(0,0,0)
				--particle:SetGravity( Vector( 0, 0, 10 ) )
			end
		else
			if ply.FogEmitter then
				ply.FogEmitter:Finish()
				ply.FogEmitter = nil
				self.FogEmitters[ply] = nil
			end
		end
	end

	-- clean up old fog emitters
	for ply,emitter in pairs(self.FogEmitters) do
		if not IsValid(ply) or not ply:IsPlayer() then
			emitter:Finish()
			self.FogEmitters[ply] = nil
		end
	end
end

function GM:EntityRemoved()
end

function GM:PostDrawViewModel(_,_,weapon)
	if not (IsValid(weapon) and weapon.UseHands) then return end
	local hands = LocalPlayer():GetHands()
	if not IsValid(hands) then return end
	hands:DrawModel()
end

function GM:RenderScene()
end

-- self:FootStepsRenderScene(origin, angles, fov)
function GM:PostDrawTranslucentRenderables()
	self:DrawFootprints()
end

local HaloColors = {Color(0,220,0),Color(220,0,0),Color(0,110,220)}

function GM:PreDrawMurderHalos(Add)
	local client = LocalPlayer()
	if not (IsValid(client) and client:Alive() and self.HaloRender:GetBool()) then return end
	local LootHalos = {}
	local WeaponHalos = {}

	if self.HaloRenderLoot:GetBool() then
		for _,v in ipairs(ents.FindByClass("weapon_mu_magnum")) do
			if IsValid(v.Owner) then continue end

			WeaponHalos[#WeaponHalos + 1] = {
				["ent"] = v,
				["color"] = 3
			}
		end

		for _,v in ipairs(ents.FindByClass("mu_loot")) do
			LootHalos[#LootHalos + 1] = {
				["ent"] = v,
				["color"] = 1
			}
		end
	end

	if self:GetAmMurderer() and self.HaloRenderKnife:GetBool() then
		for _,v in ipairs(ents.FindByClass("weapon_mu_knife")) do
			if IsValid(v:GetOwner()) then continue end

			WeaponHalos[#WeaponHalos + 1] = {
				["ent"] = v,
				["color"] = 2
			}
		end

		for _,v in ipairs(ents.FindByClass("mu_knife")) do
			WeaponHalos[#WeaponHalos + 1] = {
				["ent"] = v,
				["color"] = 2
			}
		end
	end

	Add(LootHalos,HaloColors,5,5,5,true,false)
	Add(WeaponHalos,HaloColors,2,2,10,true,false)
end

net.Receive("mu_tker",function()
	GAMEMODE.TKerPenalty = net.ReadBool()
end)
