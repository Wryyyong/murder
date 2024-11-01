GM.Name = "Murder"
GM.Author = "MechanicalMind"
-- credits to Minty Fresh for some styling on the scoreboard
-- credits to Waddlesworth for the logo and menu icon
GM.Email = ""
GM.Website = "www.codingconcoctions.com/murder/"
GM.Version = "30"

-- cVars
GM.Language = CreateConVar("mu_language","",{FCVAR_ARCHIVE,FCVAR_NOTIFY,FCVAR_REPLICATED},"The language Murder should use")
GM.RoundMaxLength = CreateConVar("mu_round_length",-1,{FCVAR_ARCHIVE,FCVAR_NOTIFY,FCVAR_REPLICATED},"How long are the rounds in seconds? (-1 to disable)",-1,32767)
GM.ShowAdminsOnScoreboard = CreateConVar("mu_scoreboard_show_admins",1,{FCVAR_ARCHIVE,FCVAR_REPLICATED},"Should show admins on scoreboard",0,1)
GM.AdminPanelAllowed = CreateConVar("mu_allow_admin_panel",1,{FCVAR_ARCHIVE,FCVAR_REPLICATED},"Should allow admins to use mu_admin_panel",0,1)
GM.ShowSpectateInfo = CreateConVar("mu_show_spectate_info",1,{FCVAR_ARCHIVE,FCVAR_NOTIFY,FCVAR_REPLICATED},"Should show players name and color to spectators",0,1)

GM.CommonColors = {
	["Team_Bystander"] = Color(20,120,255),
	["Team_Murderer"] = Color(190,20,20),
	["Team_Spectator"] = Color(150,150,150)
}

function GM:SetupTeams()
	team.SetUp(1,translate.teamSpectators,self.CommonColors["Team_Spectator"])
	team.SetUp(2,translate.teamPlayers,self.CommonColors["Team_Bystander"])
end

GM:SetupTeams()

GM.Round = {
	NotEnoughPlayers = 0, -- not enough players
	Playing = 1, -- playing
	RoundEnd = 2, -- 2 round ended, about to restart
	MapSwitch = 4, -- 4 waiting for map switch
	RoundStarting = 5 -- 5 waiting to start new round after enough players
}
