util.AddNetworkString("SetRound")
util.AddNetworkString("DeclareWinner")

concommand.Add("mu_update_length",function(ply,_,args)
	if not ply:IsUserGroup("superadmin") then return end
	local seconds = tonumber(args[1])

	if seconds ~= nil then
		if seconds ~= -1 then
			seconds = seconds + GAMEMODE:GetRoundTime()
		end

		GAMEMODE:ChangeRoundMaxLength(seconds)
	end
end)

GM.RoundStage = 0
GM.RoundCount = 0
GM.RoundStarted = 0

if GAMEMODE then
	GM.RoundStage = GAMEMODE.RoundStage
	GM.RoundCount = GAMEMODE.RoundCount
	GM.RoundStarted = GAMEMODE.RoundStarted
end

function GM:GetRound()
	return self.RoundStage or 0
end

function GM:GetRoundTime()
	--local started = self.RoundStarted or 0

	return CurTime() - self.RoundStarted
end

function GM:CheckRoundTime()
	local max = self.RoundMaxLength:GetInt() or -1
	if max == -1 then return true end -- Disabled
	local time = self:GetRoundTime()
	time = max - time

	if time <= 0 then
		-- Ran out of time
		return false
	else
		-- Still got time
		return true
	end
end

function GM:SetRound(round)
	self.RoundStage = round
	self.RoundTime = CurTime()
	self:NetworkRound()
end

function GM:NetworkRound(ply)
	net.Start("SetRound")
	net.WriteUInt(self.RoundStage,3)
	net.WriteDouble(self.RoundTime)

	if self.RoundStage == 5 then
		net.WriteDouble(self.StartNewRoundTime)
	end

	if ply == nil then
		net.Broadcast()
	else
		net.Send(ply)
	end
end

function GM:RoundThink()
	local players = team.GetPlayers(2)

	if self.RoundStage == self.Round.NotEnoughPlayers then
		if #players > 1 and (not self.LastPlayerSpawn or self.LastPlayerSpawn + 1 < CurTime()) then
			self.StartNewRoundTime = CurTime() + self.DelayAfterEnoughPlayers:GetFloat()
			self:SetRound(self.Round.RoundStarting)
		end
	elseif self.RoundStage == self.Round.Playing then
		if not self.RoundLastDeath or self.RoundLastDeath < CurTime() then
			self:RoundCheckForWin()
		end

		if self.RoundUnFreezePlayers and self.RoundUnFreezePlayers < CurTime() then
			self.RoundUnFreezePlayers = nil

			for _,ply in ipairs(players) do
				if ply:Alive() then
					ply:Freeze(false)
					ply.Frozen = false
				end
			end
		end

		-- after x minutes without a kill reveal the murderer
		local time = self.MurdererFogTime:GetFloat()
		time = math.max(0,time)

		if time > 0 and self.MurdererLastKill and self.MurdererLastKill + time < CurTime() then
			local murderer
			players = team.GetPlayers(2)

			for _,v in ipairs(players) do
				if v:GetMurderer() then
					murderer = v
				end
			end

			if murderer and not murderer:GetMurdererRevealed() then
				murderer:SetMurdererRevealed(true)
				self.MurdererLastKill = nil
			end
		end
	elseif self.RoundStage == self.Round.RoundEnd then
		if self.RoundTime + 5 < CurTime() then
			self:StartNewRound()
		end
	elseif self.RoundStage == self.Round.RoundStarting then
		if #players <= 1 then
			self:SetRound(0)
		elseif CurTime() >= self.StartNewRoundTime then
			self:StartNewRound()
		end
	end
end

function GM:RoundCheckForWin()
	local murderer
	local players = team.GetPlayers(2)

	if #players <= 0 then
		self:SetRound(0)

		return
	end

	local survivors = {}

	for _,v in ipairs(players) do
		if v:Alive() and not v:GetMurderer() then
			table.insert(survivors,v)
		end

		if v:GetMurderer() then
			murderer = v
		end
	end

	-- check we have a murderer
	if not IsValid(murderer) then
		self:EndTheRound(3,murderer)

		return
	end

	-- has the murderer killed everyone?
	if #survivors < 1 then
		self:EndTheRound(1,murderer)

		return
	end

	-- is the murderer dead?
	if not murderer:Alive() then
		self:EndTheRound(2,murderer)

		return
	end

	-- Ran out of time?
	if not self:CheckRoundTime() then
		self:EndTheRound(2,murderer)

		return
	end
	-- keep playing.
end

function GM:DoRoundDeaths()
	if self.RoundStage == self.Round.Playing then
		self.RoundLastDeath = CurTime() + 2
	end
end

-- 1 Murderer wins
-- 2 Murderer loses
-- 3 Murderer rage quit
function GM:EndTheRound(reason,murderer)
	if self.RoundStage ~= self.Round.Playing then return end
	local players = team.GetPlayers(2)

	for _,ply in ipairs(players) do
		ply:SetTKer(false)
		ply:SetMurdererRevealed(false)
		ply:UnMurdererDisguise()
	end

	if reason == 3 then
		if murderer then
			local msgs = Translator:AdvVarTranslate(translate.murdererDisconnectKnown,{
				murderer = {
					text = murderer:GetBystanderName() .. " (" .. murderer:Nick() .. ")",
					color = murderer:GetPlayerColor():ToColor()
				}
			})

			local ct = ChatText(msgs)
			ct:SendAll()
		else
			local ct = ChatText()
			ct:Add(translate.murdererDisconnect)
			ct:SendAll()
		end
	elseif reason == 2 then
		local msgs = Translator:AdvVarTranslate(translate.winBystandersMurdererWas,{
			murderer = {
				text = murderer:GetBystanderName() .. " (" .. murderer:Nick() .. ")",
				color = murderer:GetPlayerColor():ToColor()
			}
		})

		local ct = ChatText()
		ct:Add(translate.winBystanders,self.CommonColors["Team_Bystander"])
		ct:AddParts(msgs)
		ct:SendAll()
	elseif reason == 1 then
		local msgs = Translator:AdvVarTranslate(translate.winMurdererMurdererWas,{
			murderer = {
				text = murderer:GetBystanderName() .. " (" .. murderer:Nick() .. ")",
				color = murderer:GetPlayerColor():ToColor()
			}
		})

		local ct = ChatText()
		ct:Add(translate.winMurderer,self.CommonColors["Team_Murderer"])
		ct:AddParts(msgs)
		ct:SendAll()
	end

	net.Start("DeclareWinner")
	net.WriteUInt(reason,2)

	local plyIdxBits = math.ceil(math.log(game.MaxPlayers(),2))
	local isMurdererHere = IsValid(murderer)

	net.WriteBool(isMurdererHere)
	if isMurdererHere then
		net.WriteUInt(murderer:EntIndex() - 1,plyIdxBits)
	end

	for _,ply in ipairs(team.GetPlayers(2)) do
		net.WriteBool(true)
		net.WriteUInt(ply:EntIndex() - 1,plyIdxBits)
		net.WriteUInt(ply.LootCollected,8)
	end

	net.WriteBool(false)
	net.Broadcast()

	for _,ply in ipairs(players) do
		if not ply.HasMoved and not ply.Frozen and self.AFKMoveToSpec:GetBool() then
			local oldTeam = ply:Team()
			ply:SetTeam(1)
			GAMEMODE:PlayerOnChangeTeam(ply,1,oldTeam)
			local msgs = Translator:AdvVarTranslate(translate.teamMovedAFK,{
				player = {
					text = ply:Nick(),
					color = ply:GetPlayerColor():ToColor()
				},
				team = {
					text = team.GetName(1),
					color = team.GetColor(2)
				}
			})

			local ct = ChatText()
			ct:AddParts(msgs)
			ct:SendAll()
		end

		if ply:Alive() then
			ply:Freeze(false)
			ply.Frozen = false
		end
	end

	self.RoundUnFreezePlayers = nil
	self.MurdererLastKill = nil
	hook.Run("OnEndRound")
	hook.Run("OnEndRoundResult",reason)
	self.RoundCount = self.RoundCount + 1
	local limit = self.RoundLimit:GetInt()

	if limit > 0 and self.RoundCount >= limit then
		self:ChangeMap()
		self:SetRound(4)

		return
	end

	self:SetRound(2)
end

local NotEnoughPlayersColor = Color(255,150,50)
function GM:StartNewRound()
	local players = team.GetPlayers(2)

	if #players <= 1 then
		local ct = ChatText()
		ct:Add(translate.minimumPlayers,NotEnoughPlayersColor)
		ct:SendAll()
		self:SetRound(self.Round.NotEnoughPlayers)

		return
	end

	local ct = ChatText()
	local curTime = CurTime()
	ct:Add(translate.roundStarted)
	ct:SendAll()
	self.RoundUnFreezePlayers = curTime + 10
	players = team.GetPlayers(2)

	for _,ply in ipairs(players) do
		ply:UnSpectate()
	end

	game.CleanUpMap()
	self:InitPostEntityAndMapCleanup()
	self:ClearAllFootsteps()
	local murderer
	-- get the weight multiplier
	local weightMul = self.MurdererWeight:GetFloat()
	-- pick a random murderer, weighted
	local rand = WeightedRandom()

	for _,ply in ipairs(players) do
		rand:Add(ply.MurdererChance ^ weightMul,ply)
		ply.MurdererChance = ply.MurdererChance + 1
	end

	murderer = rand:Roll()

	-- allow admins to specify next murderer
	if self.ForceNextMurderer and IsValid(self.ForceNextMurderer) and self.ForceNextMurderer:Team() == 2 then
		murderer = self.ForceNextMurderer
		self.ForceNextMurderer = nil
	end

	if IsValid(murderer) then
		murderer:SetMurderer(true)
	end

	for _,ply in ipairs(players) do
		if ply ~= murderer then
			ply:SetMurderer(false)
		end

		ply:StripWeapons()
		ply:KillSilent()
		ply:Spawn()
		ply:Freeze(true)
		ply:SetPlayerColor(Vector(math.Rand(0,1),math.Rand(0,1),math.Rand(0,1)))
		ply.LootCollected = 0
		ply.HasMoved = false
		ply.Frozen = true
		ply:SetTKer(false)
		ply:CalculateSpeed()
		ply:GenerateBystanderName()
	end

	local bystanders = table.Copy(players)
	table.RemoveByValue(bystanders,murderer)
	local magnum = bystanders[math.random(1,#bystanders)]

	if IsValid(magnum) then
		magnum:Give("weapon_mu_magnum")
	end

	self.MurdererLastKill = curTime
	self:SetRound(self.Round.Playing)
	self.RoundStarted = curTime
	self.NextSpawnLoot = curTime
	self.ActiveLoot = 0
	hook.Run("OnStartRound")
end

function GM:PlayerLeavePlay(ply)
	if ply:HasWeapon("weapon_mu_magnum") then
		ply:DropWeapon(ply:GetWeapon("weapon_mu_magnum"))
	end

	if self.RoundStage == 1 and ply:GetMurderer() then
		self:EndTheRound(3,ply)
	end
end

concommand.Add("mu_forcenextmurderer",function(ply,_,args)
	if not ply:IsAdmin() then return end
	if #args < 1 then return end
	local ent = Entity(tonumber(args[1]) or -1)

	if not IsValid(ent) or not ent:IsPlayer() then
		ply:ChatPrint("not a player")

		return
	end

	GAMEMODE.ForceNextMurderer = ent

	local msgs = Translator:AdvVarTranslate(translate.adminMurdererSelect,{
		player = {
			text = ent:Nick(),
			color = team.GetColor(2)
		}
	})

	local ct = ChatText()
	ct:AddParts(msgs)
	ct:Send(ply)
end)

function GM:ChangeMap()
	if MapVote then
		MapVote.Start()
	elseif #self.MapList > 0 then
		self:RotateMap()
	end
end

function GM:RotateMap()
	local map = game.GetMap()
	local index

	for k,map2 in ipairs(self.MapList) do
		if map == map2 then
			index = k
		end
	end

	if not index then
		index = 1
	end

	index = index + 1

	if index > #self.MapList then
		index = 1
	end

	local nextMap = self.MapList[index]
	print("[Murder] Rotate changing map to " .. nextMap)
	local ct = ChatText()
	ct:Add(Translator:QuickVar(translate.mapChange,"map",nextMap))
	ct:SendAll()
	hook.Run("OnChangeMap")

	timer.Simple(5,function()
		RunConsoleCommand("changelevel",nextMap)
	end)
end

GM.MapList = {}

local defaultMapList = {"clue","cs_italy","ttt_clue","cs_office","de_chateau","de_tides","de_prodigy","mu_nightmare_church","dm_lockdown","housewithgardenv2","de_forest"}

function GM:SaveMapList()
	-- ensure the folders are there
	if not file.Exists("murder/","DATA") then
		file.CreateDir("murder")
	end

	local txt = ""

	for _,map in ipairs(self.MapList) do
		txt = txt .. map .. "\r\n"
	end

	file.Write("murder/maplist.txt",txt)
end

function GM:LoadMapList()
	local jason = file.ReadDataAndContent("murder/maplist.txt")

	if jason then
		local tbl = {}

		for map in jason:gmatch("[^\r\n]+") do
			table.insert(tbl,map)
		end

		self.MapList = tbl
	else
		local tbl = {}

		for _,map in ipairs(defaultMapList) do
			if file.Exists("maps/" .. map .. ".bsp","GAME") then
				table.insert(tbl,map)
			end
		end

		self.MapList = tbl
		self:SaveMapList()
	end
end
