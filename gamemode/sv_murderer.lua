local PlayerMeta = FindMetaTable("Player")
util.AddNetworkString("you_are_a_murderer")

GM.MurdererWeight = CreateConVar("mu_murder_weight_multiplier",2,{FCVAR_ARCHIVE,FCVAR_NOTIFY},"Multiplier for the weight of the murderer chance",0)

function PlayerMeta:SetMurderer(bool)
	self.Murderer = bool

	if bool then
		self.MurdererChance = 1
	end

	net.Start("you_are_a_murderer")
	net.WriteBool(bool)
	net.Send(self)
end

function PlayerMeta:GetMurderer()
	return self.Murderer
end

function PlayerMeta:SetMurdererRevealed(bool)
	self:SetNWBool("MurdererFog",bool)
	-- if bool then
	-- 	if !self.MurdererRevealed then
	-- 	end
	-- else
	-- 	if self.MurdererRevealed then
	-- 	end
	-- end
	self.MurdererRevealed = bool
end

function PlayerMeta:GetMurdererRevealed()
	return self.MurdererRevealed
end

local NO_KNIFE_TIME = 30

function GM:MurdererThink()
	local players = team.GetPlayers(2)
	local murderer

	for _,ply in ipairs(players) do
		if ply:GetMurderer() then
			murderer = ply
			break
		end
	end

	-- regenerate knife if on ground
	if IsValid(murderer) and murderer:Alive() then
		if murderer:HasWeapon("weapon_mu_knife") then
			murderer.LastHadKnife = CurTime()
		else
			if murderer.LastHadKnife and murderer.LastHadKnife + NO_KNIFE_TIME < CurTime() then
				for _,ent in ipairs(ents.FindByClass("weapon_mu_knife")) do
					ent:Remove()
				end

				for _,ent in ipairs(ents.FindByClass("mu_knife")) do
					ent:Remove()
				end

				murderer:Give("weapon_mu_knife")
			end
		end
	end
end
