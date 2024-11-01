GM.Name = "Murder"
GM.Author = "MechanicalMind"
-- credits to Minty Fresh for some styling on the scoreboard
-- credits to Waddlesworth for the logo and menu icon
GM.Email = ""
GM.Website = "www.codingconcoctions.com/murder/"
GM.Version = "30"

-- Replicated cVars
GM.ShowAdminsOnScoreboard = CreateConVar("mu_scoreboard_show_admins",1,{FCVAR_ARCHIVE,FCVAR_REPLICATED},"Should show admins on scoreboard")
GM.AdminPanelAllowed = CreateConVar("mu_allow_admin_panel",1,{FCVAR_ARCHIVE,FCVAR_REPLICATED},"Should allow admins to use mu_admin_panel")
GM.ShowSpectateInfo = CreateConVar("mu_show_spectate_info",1,{FCVAR_ARCHIVE,FCVAR_NOTIFY,FCVAR_REPLICATED},"Should show players name and color to spectators")

function GM:SetupTeams()
	team.SetUp(1,translate.teamSpectators,Color(150,150,150))
	team.SetUp(2,translate.teamPlayers,Color(26,120,245))
end

GM:SetupTeams()

GM.Round = {
	NotEnoughPlayers = 0, -- not enough players
	Playing = 1, -- playing
	RoundEnd = 2, -- 2 round ended, about to restart
	MapSwitch = 4, -- 4 waiting for map switch
	RoundStarting = 5 -- 5 waiting to start new round after enough players
}
