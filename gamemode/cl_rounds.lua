GM.RoundStage = 0
GM.LootCollected = 0
GM.RoundSettings = {}
GM.RoundStarted = 0

if GAMEMODE then
	GM.RoundStage = GAMEMODE.RoundStage
	GM.LootCollected = GAMEMODE.LootCollected
	GM.RoundSettings = GAMEMODE.RoundSettings
end

function GM:GetRound()
	return self.RoundStage or 0
end

function GM:GetRoundTime()
	local started = self.RoundStarted or 0

	return CurTime() - started
end

net.Receive("ChangeMaxLength",function()
	local time = net.ReadInt(32)
	GAMEMODE.RoundSettings.RoundMaxLength = time
end)

net.Receive("SetRound",function()
	local r = net.ReadUInt(8)
	local start = net.ReadDouble()
	GAMEMODE.RoundStage = r
	GAMEMODE.RoundStart = start
	GAMEMODE.RoundSettings = {}
	local settings = net.ReadBool()

	if settings then
		GAMEMODE.RoundSettings.ShowAdminsOnScoreboard = net.ReadBool()
		GAMEMODE.RoundSettings.AdminPanelAllowed = net.ReadBool()
		GAMEMODE.RoundSettings.ShowSpectateInfo = net.ReadBool()
		GAMEMODE.RoundSettings.RoundMaxLength = net.ReadInt(32)
	end

	if r == GAMEMODE.Round.RoundStarting then
		GAMEMODE.StartNewRoundTime = net.ReadDouble()
	end

	if r == GAMEMODE.Round.Playing then
		timer.Simple(0.2,function()
			local pitch = math.random(70,140)

			if IsValid(LocalPlayer()) then
				LocalPlayer():EmitSound("ambient/creatures/town_child_scream1.wav",100,pitch)
			end
		end)

		GAMEMODE.LootCollected = 0
		GAMEMODE.RoundStarted = CurTime()
	end
end)

net.Receive("DeclareWinner",function()
	local data = {}
	data.reason = net.ReadUInt(2)
	data.murderer = net.ReadEntity()
	data.murdererColor = net.ReadVector()
	data.murdererName = net.ReadString()
	-- if IsValid(data.murderer) then
	-- end
	data.collectedLoot = {}

	while net.ReadBool() do
		local t = {}
		t.player = net.ReadEntity()

		if IsValid(t.player) then
			t.playerName = t.player:Nick()
		end

		t.count = net.ReadUInt(32)
		t.playerColor = net.ReadVector()
		t.playerBystanderName = net.ReadString()
		table.insert(data.collectedLoot,t)
	end

	GAMEMODE:DisplayEndRoundBoard(data)
	local pitch = math.random(80,120)

	if IsValid(LocalPlayer()) then
		LocalPlayer():EmitSound("ambient/alarms/warningbell1.wav",100,pitch)
	end
end)

net.Receive("GrabLoot",function()
	GAMEMODE.LootCollected = net.ReadUInt(32)
end)

net.Receive("SetLoot",function()
	GAMEMODE.LootCollected = net.ReadUInt(32)
end)
