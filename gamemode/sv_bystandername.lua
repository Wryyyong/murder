GM.BystanderNameParts = {}

local function addPart(name,sex)
	local tab = {}
	tab.name = name
	tab.sex = sex
	GM.BystanderNameParts[#GM.BystanderNameParts + 1] = tab
end

-- Don't add to this list, add names to data/murder/bystander_name_parts.txt
addPart("Alfa")
addPart("Bravo")
addPart("Charlie")
addPart("Delta")
addPart("Echo")
addPart("Foxtrot")
addPart("Golf")
addPart("Hotel")
addPart("India")
addPart("Juliett")
addPart("Kilo")
addPart("Lima")
addPart("Miko")
addPart("November")
addPart("Oscar")
addPart("Papa")
addPart("Quebec")
addPart("Romeo")
addPart("Sierra")
addPart("Tango")
addPart("Uniform")
addPart("Victor")
addPart("Whiskey")
addPart("X-ray")
addPart("Yankee")
addPart("Zulu")
-- local PlayerMeta = FindMetaTable("Player")
local EntityMeta = FindMetaTable("Entity")
GM.BystanderWords = CreateClientConVar("mu_bystandername_words",1,FCVAR_ARCHIVE,"Number of words to generate for bystander name")

-- adds a name to the bystander parts generation table
function GM:AddBystanderNamePart(name,sex)
	name = tostring(name)

	if not name then
		error("arg 1 must be a string")
	end

	if sex ~= "male" and sex ~= "female" then
		sex = nil
	end

	local tab = {}
	tab.name = name
	tab.sex = sex
	self.BystanderNameParts[#self.BystanderNameParts + 1] = tab
end

-- removes a name to the bystander parts generation table
function GM:RemoveBystanderNamePart(name,sex)
	for k,v in ipairs(self.BystanderNameParts) do
		if v.name == name and v.sex == sex then
			self.BystanderNameParts[k] = nil
			break
		end
	end
end

-- returns the bystander parts generation table
function GM:GetBystanderNameParts()
	return self.BystanderNameParts
end

function GM:GenerateName(words,sex)
	if #self.BystanderNameParts <= 0 then return "error" end
	local name

	for _ = 1,words do
		local tab = {}

		for _,v in ipairs(self.BystanderNameParts) do
			if v.sex == sex or v.sex == nil then
				tab[#tab + 1] = v.name
			end
		end

		local word = tab[math.random(#tab)]

		if not name then
			name = word
		else
			name = name .. " " .. word
		end
	end

	return name
end

function GM:LoadBystanderNames()
	local text = file.ReadDataAndContent("murder/bystander_name_parts.txt")

	if text then
		local tbl = {}

		--local i = 1
		for line in text:gmatch("[^\r\n]+") do
			local name,sex = line:match("([^,]+)/([^,]+)")

			if not name then
				name = line
			end

			if sex == "m" then
				sex = "male"
			end

			if sex == "f" then
				sex = "female"
			end

			if sex ~= "male" and sex ~= "female" then
				sex = nil
			end

			local tab = {}
			tab.name = name
			tab.sex = sex
			tbl[#tbl + 1] = tab
		end

		self.BystanderNameParts = tbl
	end
end

function EntityMeta:GenerateBystanderName()
	local words = math.max(1,GAMEMODE.BystanderWords:GetInt())
	local name = GAMEMODE:GenerateName(words,self.ModelSex or "male")
	self:SetNWString("bystanderName",name)
	self.BystanderName = name
end

function EntityMeta:SetBystanderName(name)
	self:SetNWString("bystanderName",name)
	self.BystanderName = name
end

function EntityMeta:GetBystanderName()
	local name = self:GetNWString("bystanderName")
	if not name or name == "" then return "Bystander" end

	return name
end

concommand.Add("mu_print_players",function(admin)
	if not admin:IsAdmin() then return end

	for _,ply in ipairs(player.GetAll()) do
		local c = ChatText()
		c:Add(ply:Nick())
		c:Add(" " .. ply:GetBystanderName(),ply:GetPlayerColor():ToColor())
		c:Add(" " .. ply:SteamID())
		c:Add(" " .. team.GetName(ply:Team()),team.GetColor(ply:Team()))
		c:Send(admin)
	end
end)
