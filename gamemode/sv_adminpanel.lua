util.AddNetworkString("mu_adminpanel_details")

net.Receive("mu_adminpanel_details",function(_,ply)
	if not ply:IsAdmin() then return end
	if not GAMEMODE.AdminPanelAllowed:GetBool() then return end
	local sendData = {}
	local tab = {}
	local lootTab = {}
	tab.players = {}
	tab.weightMul = GAMEMODE.MurdererWeight:GetFloat()
	local total = 0
	local teamPlys = team.GetPlayers(2)

	for _,teamply in ipairs(teamPlys) do
		total = total + (teamply.MurdererChance or 1) ^ tab.weightMul
	end

	for _,teamply in ipairs(teamPlys) do
		local t = {}
		t.player = teamply:EntIndex() -- cant send players via JSON
		t.murderer = teamply:GetMurderer()
		t.murdererChance = (teamply.MurdererChance or 1) ^ tab.weightMul / total
		t.murdererWeight = teamply.MurdererChance or 1
		tab.players[teamply:EntIndex()] = t
	end

	lootTab = LootItems
	sendData.playerData = tab
	sendData.lootData = lootTab
	local json = util.Compress(util.TableToJSON(sendData))
	net.Start("mu_adminpanel_details")
		net.WriteData(json)
	net.Send(ply)
end)
