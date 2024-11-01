-- add cs lua all the cl_ or sh_ files
local folders = {(GM or GAMEMODE).Folder:sub(11) .. "/gamemode/"}

for _,folder in ipairs(folders) do
	local files,subfolders = file.Find(folder .. "*","LUA")

	for _,filename in ipairs(files) do
		local fntrim = filename:sub(1,3)
		if fntrim == "cl_" or fntrim == "sh_" or filename == "shared.lua" or folder:match("/sh_") or folder:match("/cl_") then
			AddCSLuaFile(folder .. filename)
		end
	end

	for _,subfolder in ipairs(subfolders) do
		table.insert(folders,folder .. subfolder .. "/")
	end
end

include("sh_translate.lua")
include("shared.lua")
include("weightedrandom.lua")
include("sv_player.lua")
include("sv_spectate.lua")
include("sv_spawns.lua")
include("sv_ragdoll.lua")
include("sv_respawn.lua")
include("sv_murderer.lua")
include("sv_rounds.lua")
include("sv_footsteps.lua")
include("sv_chattext.lua")
include("sv_loot.lua")
include("sv_create_db.lua")
include("sv_taunt.lua")
include("sv_bystandername.lua")
include("sv_adminpanel.lua")
include("sv_tker.lua")
include("sv_flashlight.lua")
resource.AddFile("materials/thieves/footprint.vmt")
resource.AddFile("materials/murder/melon_logo_scoreboard.png")
GM.ShowBystanderTKs = CreateConVar("mu_show_bystander_tks",1,{FCVAR_ARCHIVE,FCVAR_NOTIFY},"Should show name of killer in chat on a bystander team kill",0,1)
GM.MurdererFogTime = CreateConVar("mu_murderer_fogtime",60 * 4,{FCVAR_ARCHIVE,FCVAR_NOTIFY},"Time (in seconds) it takes for a Murderer to show fog for no kills, 0 to disable",0)
GM.TKPenaltyTime = CreateConVar("mu_tk_penalty_time",20,{FCVAR_ARCHIVE,FCVAR_NOTIFY},"Time (in seconds) for a bystander to be penalised for a team kill",0)
GM.LocalChat = CreateConVar("mu_localchat",0,{FCVAR_ARCHIVE,FCVAR_NOTIFY},"Local chat, when enabled only nearby players can hear other players",0,1)
GM.LocalChatRange = CreateConVar("mu_localchat_range",550,{FCVAR_ARCHIVE,FCVAR_NOTIFY},"The range at which you can hear other players",0)
GM.CanDisguise = CreateConVar("mu_disguise",1,{FCVAR_ARCHIVE,FCVAR_NOTIFY},"Whether the murderer can disguise as dead players",0,1)
GM.RemoveDisguiseOnKill = CreateConVar("mu_disguise_removeonkill",1,{FCVAR_ARCHIVE,FCVAR_NOTIFY},"Remove the murderer's disguise when he kills someone",0,1)
GM.AFKMoveToSpec = CreateConVar("mu_moveafktospectator",1,{FCVAR_ARCHIVE,FCVAR_NOTIFY},"Should we move AFK players to spectator on round end",0,1)
GM.RoundLimit = CreateConVar("mu_roundlimit",0,{FCVAR_ARCHIVE,FCVAR_NOTIFY},"Number of rounds we should play before map change",0)
GM.DelayAfterEnoughPlayers = CreateConVar("mu_delay_after_enough_players",10,{FCVAR_ARCHIVE,FCVAR_NOTIFY},"Time (in seconds) we should wait to start the round after enough players have joined",0)
GM.FlashlightBattery = CreateConVar("mu_flashlight_battery",10,{FCVAR_ARCHIVE,FCVAR_NOTIFY},"How long the flashlight should last in seconds (0 for infinite)",0)

function GM:Initialize()
	self:EnsureTablesExist()
	self:LoadSpawns()
	self.DeathRagdolls = {}
	self:StartNewRound()
	self:LoadLootModels()
	self:LoadLootData()
	self:LoadMapList()
	self:LoadBystanderNames()
end

function GM:InitPostEntity()
	local canAdd = self:CountLootItems() <= 0

	for _,ent in ipairs(ents.FindByClass("mu_loot")) do
		if canAdd then
			self:AddLootItem(ent)
		end
	end

	self:InitPostEntityAndMapCleanup()
end

function GM:InitPostEntityAndMapCleanup()
	for _,ent in ipairs(ents.GetAll()) do
		if ent:IsWeapon() or ent:GetClass():match("^weapon_") then
			ent:Remove()
		end

		if ent:GetClass():match("^item_") then
			ent:Remove()
		end
	end

	for _,ent in ipairs(ents.FindByClass("mu_loot")) do
		ent:Remove()
	end
	-- self:SpawnLoot()
end

function GM:Think()
	self:RoundThink()
	self:MurdererThink()
	self:LootThink()
	self:FlashlightThink()

	for _,ply in ipairs(player.GetAll()) do
		if ply:IsCSpectating() and IsValid(ply:GetCSpectatee()) and (not ply.LastSpectatePosSet or ply.LastSpectatePosSet < CurTime()) then
			ply.LastSpectatePosSet = CurTime() + 0.25
			ply:SetPos(ply:GetCSpectatee():GetPos())
		end

		if not ply.HasMoved and (ply:IsBot() or ply:KeyDown(IN_FORWARD) or ply:KeyDown(IN_JUMP) or ply:KeyDown(IN_ATTACK) or ply:KeyDown(IN_ATTACK2) or ply:KeyDown(IN_MOVELEFT) or ply:KeyDown(IN_MOVERIGHT) or ply:KeyDown(IN_BACK) or ply:KeyDown(IN_DUCK)) then
			ply.HasMoved = true
		end

		if ply.LastTKTime and ply.LastTKTime + self:GetTKPenaltyTime() < CurTime() then
			ply:SetTKer(false)
		end
	end
end

function GM:AllowPlayerPickup()
	return true
end

function GM:PlayerNoClip(ply)
	return ply:IsListenServerHost() or ply:GetMoveType() == MOVETYPE_NOCLIP
end

function GM:OnEndRound()
end

function GM:OnStartRound()
end

function GM:SendMessageAll(msg)
	for _,v in ipairs(player.GetAll()) do
		v:ChatPrint(msg)
	end
end

function GM:EntityTakeDamage(_,dmginfo)
	-- disable all prop damage
	if IsValid(dmginfo:GetAttacker()) and (dmginfo:GetAttacker():GetClass() == "prop_physics" or dmginfo:GetAttacker():GetClass() == "prop_physics_multiplayer" or dmginfo:GetAttacker():GetClass() == "prop_physics_respawnable" or dmginfo:GetAttacker():GetClass() == "func_physbox") then return true end
	if IsValid(dmginfo:GetInflictor()) and (dmginfo:GetInflictor():GetClass() == "prop_physics" or dmginfo:GetInflictor():GetClass() == "prop_physics_multiplayer" or dmginfo:GetInflictor():GetClass() == "prop_physics_respawnable" or dmginfo:GetInflictor():GetClass() == "func_physbox") then return true end
end

function file.ReadDataAndContent(path)
	local f = file.Read(path,"DATA")
	if f then return f end
	f = file.Read(GAMEMODE.Folder .. "/content/data/" .. path,"GAME")

	return f
end

util.AddNetworkString("reopen_round_board")

-- F2
function GM:ShowTeam(ply)
	net.Start("reopen_round_board")
	net.Send(ply)
end

concommand.Add("mu_version",function(ply)
	if IsValid(ply) then
		ply:ChatPrint("Murder by Mechanical Mind version " .. tostring(GAMEMODE.Version or "error"))
	else
		print("Murder by Mechanical Mind version " .. tostring(GAMEMODE.Version or "error"))
	end
end)

function GM:MaxDeathRagdolls()
	return 20
end
