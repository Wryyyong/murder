GM.RoundStage = 0
GM.LootCollected = 0
GM.RoundStarted = 0

if GAMEMODE then
	GM.RoundStage = GAMEMODE.RoundStage
	GM.LootCollected = GAMEMODE.LootCollected
end

function GM:GetRound()
	return self.RoundStage or 0
end

function GM:GetRoundTime()
	local started = self.RoundStarted or 0

	return CurTime() - started
end

sound.Add({
	["channel"] = CHAN_AUTO,
	["name"] = "StartRoundScream",
	["level"] = 100,
	["sound"] = "ambient/creatures/town_child_scream1.wav",
	["pitch"] = {70,140}
})

net.Receive("SetRound",function()
	local roundState = net.ReadUInt(3)
	GAMEMODE.RoundStage = roundState
	GAMEMODE.RoundStart = net.ReadDouble()

	if roundState == GAMEMODE.Round.RoundStarting then
		GAMEMODE.StartNewRoundTime = net.ReadDouble()
	end

	if roundState == GAMEMODE.Round.Playing then
		timer.Simple(0.2,function()
			local lply = LocalPlayer()
			if not IsValid(lply) then return end
			lply:EmitSound("StartRoundScream")
		end)

		GAMEMODE.LootCollected = 0
		GAMEMODE.RoundStarted = CurTime()
	end
end)

net.Receive("DeclareWinner",function()
	local data = {}
	local plyIdxBits = math.ceil(math.log(game.MaxPlayers(),2))
	data.reason = net.ReadUInt(2)
	data.murderer = {}

	if net.ReadBool() then
		data.murderer.ply = Entity(net.ReadUInt(plyIdxBits) + 1)

		if IsValid(data.murderer.ply) then
			data.murderer.color = data.murderer.ply:GetPlayerColor():ToColor()
			data.murderer.byName = data.murderer.ply:GetBystanderName()
			data.murderer.realName = " (" .. data.murderer.ply:GetName() .. ")"
		else
			data.murderer.color = color_white
			data.murderer.byName = "unknown"
			data.murderer.realName = ""
		end
	else
		data.murderer.ply = Entity(0)
		data.murderer.color = color_white
		data.murderer.byName = "unknown"
		data.murderer.realName = ""
	end

	data.collectedLoot = {}

	while net.ReadBool() do
		local t = {}
		t.ply = Entity(net.ReadUInt(plyIdxBits) + 1)
		t.lootCount = net.ReadUInt(8)
		if not IsValid(t.ply) then continue end
		t.color = t.ply:GetPlayerColor():ToColor()
		t.byName = t.ply:GetBystanderName()
		t.realName = t.ply:GetName()
		data.collectedLoot[#data.collectedLoot + 1] = t
	end

	GAMEMODE:DisplayEndRoundBoard(data)
	local pitch = math.random(80,120)
	LocalPlayer():EmitSound("ambient/alarms/warningbell1.wav",100,pitch)
end)

net.Receive("GrabLoot",function()
	GAMEMODE.LootCollected = net.ReadUInt(8)
end)

net.Receive("SetLoot",function()
	GAMEMODE.LootCollected = net.ReadUInt(8)
end)
