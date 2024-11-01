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
		data.murderer.ent = Entity(net.ReadUInt(plyIdxBits) + 1)
		data.murderer.color = data.murderer:GetPlayerColor():ToColor()
		data.murderer.byName = data.murderer:GetBystanderName()
		data.murderer.realName = " (" .. data.murderer:GetName() .. ")"
	else
		data.murderer.ent = Entity(0)
		data.murderer.color = color_white
		data.murderer.byName = "unknown"
		data.murderer.realName = ""
	end

	data.collectedLoot = {}

	while net.ReadBool() do
		local t = {}
		t.ent = net.ReadEntity()
		t.lootCount = net.ReadUInt(8)

		if IsValid(t.ent) then
			t.color = t.ent:GetPlayerColor():ToColor()
			t.byName = t.ent:GetBystanderName()
			t.realName = t.ent:GetName()
		end

		table.insert(data.collectedLoot,t)
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
