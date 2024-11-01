util.AddNetworkString("mu_death")
local PlayerMeta = FindMetaTable("Player")
local EntityMeta = FindMetaTable("Entity")

local BaseColor = Vector(0.5,0.5,0.5)
function GM:PlayerInitialSpawn(ply)
	ply.LootCollected = 0
	ply.MurdererChance = 1

	timer.Simple(0,function()
		if not IsValid(ply) then return end
		ply:KillSilent()
	end)

	ply.HasMoved = true
	ply:SetTeam(2)
	self:NetworkRound(ply)
	self.LastPlayerSpawn = CurTime()
	ply:SetPlayerColor(BaseColor)
end

function GM:PlayerSpawn(ply)
	-- If the player doesn't have a team
	-- then spawn him as a spectator
	if ply:Team() == 1 or ply:Team() == TEAM_UNASSIGNED then
		GAMEMODE:PlayerSpawnAsSpectator(ply)

		return
	end

	-- Stop observer mode
	ply:UnCSpectate()
	ply:SetMurdererRevealed(false)
	ply:SetFlashlightCharge(1)
	player_manager.OnPlayerSpawn(ply)
	player_manager.RunClass(ply,"Spawn")
	hook.Run("PlayerLoadout",ply)
	hook.Run("PlayerSetModel",ply)
	ply:CalculateSpeed()
	ply:SetupHands()
	local spawnPoint = self:PlayerSelectTeamSpawn(ply:Team(),ply)

	if IsValid(spawnPoint) then
		ply:SetPos(spawnPoint:GetPos())
	end
end

function GM:PlayerLoadout(ply)
	ply:Give("weapon_mu_hands")

	-- ply:Give("weapon_fists")
	if ply:GetMurderer() then
		ply:Give("weapon_mu_knife")
	end
end

local playerModels = {}

local function addModel(model,sex)
	local t = {}
	t.model = model
	t.sex = sex
	playerModels[#playerModels + 1] = t
end

addModel("male03","male")
addModel("male04","male")
addModel("male05","male")
addModel("male07","male")
addModel("male06","male")
addModel("male09","male")
addModel("male01","male")
addModel("male02","male")
addModel("male08","male")
addModel("female06","female")
addModel("female01","female")
addModel("female03","female")
addModel("female05","female")
addModel("female02","female")
addModel("female04","female")
addModel("refugee01","male")
addModel("refugee02","male")
addModel("refugee03","male")
addModel("refugee04","male")

function GM:PlayerSetModel(ply)
	local cl_playermodel = ply:GetInfo("cl_playermodel")
	local playerModel = table.Random(playerModels)
	cl_playermodel = playerModel.model
	local modelname = player_manager.TranslatePlayerModel(cl_playermodel)
	util.PrecacheModel(modelname)
	ply:SetModel(modelname)
	ply.ModelSex = playerModel.sex
end

function GM:DoPlayerDeath(ply)
	for _,weapon in ipairs(ply:GetWeapons()) do
		if weapon:GetClass() == "weapon_mu_magnum" then
			ply:DropWeapon(weapon)
		end
	end

	ply:UnMurdererDisguise()
	ply:Freeze(false) --why?, *sigh*
	ply:CreateRagdoll()
	local ent = ply:GetNWEntity("DeathRagdoll")

	if IsValid(ent) then
		ply:CSpectate(OBS_MODE_CHASE,ent)
		ent:SetBystanderName(ply:GetBystanderName())
	end
end

local plyMeta = FindMetaTable("Player")

function plyMeta:CalculateSpeed()
	-- set the defaults
	local walk,run,canrun = 250,310,false
	local jumppower = 200

	if self:GetMurderer() then
		canrun = true
	end

	if self:GetTKer() then
		walk = walk * 0.5
		run = run * 0.5
		jumppower = jumppower * 0.5
	end

	local wep = self:GetActiveWeapon()

	if IsValid(wep) and (wep.GetCarrying and wep:GetCarrying()) then
		walk = walk * 0.3
		run = run * 0.3
		jumppower = jumppower * 0.3
	end

	-- set out new speeds
	if canrun then
		self:SetRunSpeed(run)
	else
		self:SetRunSpeed(walk)
	end

	self.CanRun = canrun
	self:SetWalkSpeed(walk)
	self:SetJumpPower(jumppower)
end

local function isValid()
	return true
end

local function getPos(self)
	return self.pos
end

local function generateSpawnEntities(spawnList)
	local tbl = {}

	for _,pos in ipairs(spawnList) do
		local t = {}
		t.IsValid = isValid
		t.GetPos = getPos
		t.pos = pos
		tbl[#tbl + 1] = t
	end

	return tbl
end

function GM:PlayerSelectTeamSpawn(_,pl)
	local spawnPoints = generateSpawnEntities(TeamSpawns["spawns"])
	if not spawnPoints or table.Count(spawnPoints) == 0 then return end
	local spawnPoint = nil

	for i = 0,6 do
		spawnPoint = table.Random(spawnPoints)
		if GAMEMODE:IsSpawnpointSuitable(pl,spawnPoint,i == 6) then return spawnPoint end
	end

	return spawnPoint
end

function GM:PlayerDeathSound()
	-- don't play sound
	return true
end

function GM:ScalePlayerDamage()
end

-- Don't scale it depending on hitgroup
function GM:PlayerDeath(ply,_,attacker)
	self:DoRoundDeaths(ply,attacker)

	if not ply:GetMurderer() then
		self.MurdererLastKill = CurTime()
		local murderer
		local players = team.GetPlayers(2)

		for _,v in ipairs(players) do
			if v:GetMurderer() then
				murderer = v
			end
		end

		if murderer then
			murderer:SetMurdererRevealed(false)
		end

		if IsValid(attacker) and attacker:IsPlayer() then
			if attacker:GetMurderer() then
				if self.RemoveDisguiseOnKill:GetBool() then
					attacker:UnMurdererDisguise()
				end
			elseif attacker ~= ply then
				if self.ShowBystanderTKs:GetBool() then
					local msgs = Translator:AdvVarTranslate(translate.killedTeamKill,{
						player = {
							text = attacker:GetBystanderName() .. " (" .. attacker:Nick() .. ")",
							color = attacker:GetPlayerColor():ToColor()
						}
					})

					local ct = ChatText()
					ct:AddParts(msgs)
					ct:SendAll()
				end

				attacker:SetTKer(true)
			end
		end
	else
		if attacker ~= ply and IsValid(attacker) and attacker:IsPlayer() then
			local msgs = Translator:AdvVarTranslate(translate.killedMurderer,{
				player = {
					text = attacker:GetBystanderName() .. " (" .. attacker:Nick() .. ")",
					color = attacker:GetPlayerColor():ToColor()
				}
			})

			local ct = ChatText()
			ct:AddParts(msgs)
			ct:SendAll()
		else
			local ct = ChatText()
			ct:Add(translate.murdererDeathUnknown)
			ct:SendAll()
		end
	end

	ply.NextSpawnTime = CurTime() + 5
	ply.DeathTime = CurTime()
	ply.SpectateTime = CurTime() + 4
	net.Start("mu_death")
	net.WriteUInt(4,4)
	net.Send(ply)
end

function GM:PlayerDeathThink(ply)
	if self:CanRespawn(ply) then
		ply:Spawn()
	else
		self:ChooseSpectatee(ply)
	end
end

function EntityMeta:GetPlayerColor()
	return self.playerColor or Vector()
end

function EntityMeta:SetPlayerColor(vec)
	self.playerColor = vec
	self:SetNWVector("playerColor",vec)
end

function GM:PlayerFootstep(ply,pos,foot,sound,volume,filter)
	self:FootstepsOnFootstep(ply,pos,foot,sound,volume,filter)
end

function GM:PlayerCanPickupWeapon(ply,ent)
	-- can't pickup a weapon twice
	if ply:HasWeapon(ent:GetClass()) then return false end

	if ent:GetClass() == "weapon_mu_magnum" then
		-- murderer can't have the gun
		if ply:GetMurderer() then return false end

		-- penalty for killing a bystander
		if ply:GetTKer() then
			if ply.TempGiveMagnum then
				ply.TempGiveMagnum = nil

				return true
			end

			return false
		end
	end

	if ent:GetClass() == "weapon_mu_knife" and not ply:GetMurderer() then return false end -- bystanders can't have the knife

	return true
end

function GM:PlayerCanHearPlayersVoice(listener,talker)
	if not IsValid(talker) then return false end

	return self:PlayerCanHearChatVoice(listener,talker,"voice")
end

function GM:PlayerCanHearChatVoice(listener,talker)
	if self.RoundStage ~= 1 then return true end

	if self.LocalChat:GetBool() then
		if not talker:Alive() or talker:Team() ~= 2 then return not listener:Alive() or listener:Team() ~= 2 end
		local ply = listener

		-- listen as if spectatee when spectating
		if listener:IsCSpectating() and IsValid(listener:GetCSpectatee()) then
			ply = listener:GetCSpectatee()
		end

		local dis = ply:GetPos():Distance(talker:GetPos())
		if dis < self.LocalChatRange:GetFloat() then return true end

		return false
	else
		if not listener:Alive() or listener:Team() ~= 2 then return true end
		if talker:Team() ~= 2 then return false end
		if not talker:Alive() then return false end

		return true
	end
end

function GM:PlayerDisconnected(ply)
	self:PlayerLeavePlay(ply)
end

function GM:PlayerOnChangeTeam(ply,_,oldTeam)
	if oldTeam == 2 then
		self:PlayerLeavePlay(ply)
	end

	ply:SetMurderer(false)
	-- if newteam == 1 then
	-- end
	ply.HasMoved = true
	ply:KillSilent()
end

concommand.Add("mu_jointeam",function(ply,_,args)
	if ply.LastChangeTeam and ply.LastChangeTeam + 5 > CurTime() then return end
	ply.LastChangeTeam = CurTime()
	local curTeam = ply:Team()
	local newTeam = tonumber(args[1] or "") or 0

	if newTeam >= 1 and newTeam <= 2 and newTeam ~= curTeam then
		ply:SetTeam(newTeam)
		GAMEMODE:PlayerOnChangeTeam(ply,newTeam,curTeam)

		local msgs = Translator:AdvVarTranslate(translate.changeTeam,{
			player = {
				text = ply:Nick(),
				color = team.GetColor(curTeam)
			},
			team = {
				text = team.GetName(newTeam),
				color = team.GetColor(newTeam)
			}
		})

		local ct = ChatText()
		ct:AddParts(msgs)
		ct:SendAll()
	end
end)

concommand.Add("mu_movetospectate",function(ply,_,args)
	if not ply:IsAdmin() then return end
	if #args < 1 then return end
	local ent = Entity(tonumber(args[1]) or -1)
	if not IsValid(ent) or not ent:IsPlayer() then return end
	local curTeam = ent:Team()

	if 1 ~= curTeam then
		ent:SetTeam(1)
		GAMEMODE:PlayerOnChangeTeam(ent,1,curTeam)

		local msgs = Translator:AdvVarTranslate(translate.teamMoved,{
			player = {
				text = ent:Nick(),
				color = team.GetColor(curTeam)
			},
			team = {
				text = team.GetName(1),
				color = team.GetColor(1)
			}
		})

		local ct = ChatText()
		ct:AddParts(msgs)
		ct:SendAll()
	end
end)

concommand.Add("mu_spectate",function(ply,_,args)
	if not ply:IsAdmin() then return end
	if #args < 1 then return end
	local ent = Entity(tonumber(args[1]) or -1)
	if not IsValid(ent) or not ent:IsPlayer() then return end

	if ply:Alive() and ply:Team() ~= 1 then
		local ct = ChatText()
		ct:Add(translate.spectateFailed)
		ct:Send(ply)

		return
	end

	ply:CSpectate(OBS_MODE_IN_EYE,ent)
end)

function GM:PlayerCanSeePlayersChat(_,_,listener,speaker)
	if not IsValid(speaker) then return false end
	local canhear = self:PlayerCanHearChatVoice(listener,speaker)

	return canhear
end

function GM:PlayerSay(ply,text,say_team)
	if ply:Team() == 2 and ply:Alive() and self:GetRound() ~= 0 then
		local ct = ChatText()
		ct:Add(ply:GetBystanderName(),ply:GetPlayerColor():ToColor())
		ct:Add(": " .. text,color_white)

		for _,ply2 in ipairs(player.GetAll()) do
			local can = hook.Run("PlayerCanSeePlayersChat",text,say_team,ply2,ply)

			if can then
				ct:Send(ply2)
			end
		end

		return false
	end

	return true
end

function GM:PlayerShouldTaunt()
	return false
end

function GM:GetTKPenaltyTime()
	return math.max(0,self.TKPenaltyTime:GetFloat())
end

function GM:PlayerUse()
	return true
end

local function pressedUse(self,ply)
	local tr = ply:GetEyeTraceNoCursor()

	-- press e on windows to break them
	if IsValid(tr.Entity) and (tr.Entity:GetClass() == "func_breakable" or tr.Entity:GetClass() == "func_breakable_surf") and tr.HitPos:Distance(tr.StartPos) < 50 then
		if tr.Entity:GetClass() == "func_breakable" then
			local dmg = DamageInfo()
			dmg:SetAttacker(game.GetWorld())
			dmg:SetInflictor(game.GetWorld())
			dmg:SetDamage(10)
			dmg:SetDamageType(DMG_BULLET)
			dmg:SetDamageForce(ply:GetAimVector() * 500)
			dmg:SetDamagePosition(tr.HitPos)
			tr.Entity:TakeDamageInfo(dmg)

			return
		elseif tr.Entity:GetClass() == "func_breakable_surf" then
			tr.Entity:Fire("shatter","0.5 0.5 4",0)
		end
	end

	-- disguise as ragdolls
	if IsValid(tr.Entity) and tr.Entity:GetClass() == "prop_ragdoll" and tr.HitPos:Distance(tr.StartPos) < 80 and (ply:GetMurderer() and ply:GetLootCollected() >= 1) and (tr.Entity:GetBystanderName() ~= ply:GetBystanderName() or tr.Entity:GetPlayerColor() ~= ply:GetPlayerColor()) then
		ply:MurdererDisguise(tr.Entity)
		ply:SetLootCollected(ply:GetLootCollected() - 1)

		return
	end

	if ply:GetMurderer() then
		-- find closest button to cursor with usable range
		local _dis,dot,but

		for _,lbut in ipairs(ents.FindByClass("ttt_traitor_button")) do
			if lbut.TraitorButton then
				local vec = lbut:GetPos() - ply:GetShootPos()
				local ldis,ldot = vec:Length(),vec:GetNormal():Dot(ply:GetAimVector())

				if (ldis < lbut:GetUsableRange() and ldot > 0.95) and (not but or ldot > dot) then
					dis = ldis
					dot = ldot
					but = lbut
				end
			end
		end

		if but then
			but:TraitorButtonPressed(ply)

			return
		end
	end
end

function GM:KeyPress(ply,key)
	if key == IN_USE then
		pressedUse(self,ply)
	end
end

function PlayerMeta:MurdererDisguise(copyent)
	if not self.Disguised then
		self.DisguiseColor = self:GetPlayerColor()
		self.DisguiseName = self:GetBystanderName()
	end

	if GAMEMODE.CanDisguise:GetBool() then
		self.Disguised = true
		self.DisguisedStart = CurTime()
		self:SetBystanderName(copyent:GetBystanderName())
		self:SetPlayerColor(copyent:GetPlayerColor())
	else
		self:UnMurdererDisguise()
	end
end

function PlayerMeta:UnMurdererDisguise()
	if self.Disguised then
		self:SetPlayerColor(self.DisguiseColor)
		self:SetBystanderName(self.DisguiseName)
	end

	self.Disguised = false
end

function PlayerMeta:GetMurdererDisguised()
	return self.Disguised and true or false
end
