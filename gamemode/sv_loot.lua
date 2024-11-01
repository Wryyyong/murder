local PlayerMeta = FindMetaTable("Player")

if not LootItems then
	LootItems = {}
end

if not LootModels then
	LootModels = {}
end

local FruitModels = {"models/props/cs_italy/bananna_bunch.mdl","models/props/cs_italy/orange.mdl","models/props/cs_italy/bananna.mdl","models/props_junk/watermelon01.mdl"}

util.AddNetworkString("GrabLoot")
util.AddNetworkString("SetLoot")

function GM:LoadLootModels()
	local lootResult = sql.Query("SELECT alias,file FROM mu_models")

	if lootResult ~= false then
		-- PrintTable(lootResult)
		for _,v in ipairs(lootResult) do
			LootModels[v.alias] = v.file
		end
	else
		Msg("Looks like there is no loot models! \n")
	end
end

function GM:LoadLootData()
	local mapName = game.GetMap()
	local jason = file.ReadDataAndContent("murder/" .. mapName .. "/loot.txt")

	if jason then
		local tbl = util.JSONToTable(jason)
		LootItems = tbl
	end
end

function GM:CountLootItems()
	return #LootItems
end

function GM:SpawnLoot()
	for _,ent in ipairs(ents.FindByClass("mu_loot")) do
		ent:Remove()
	end

	for _,data in ipairs(LootItems) do
		self:SpawnLootItem(data)
	end
end

function GM:SpawnLootItem(data)
	for _,ent in ipairs(ents.FindByClass("mu_loot")) do
		if ent.LootData == data then return end
	end

	local ent = ents.Create("mu_loot")
	ent:SetModel(data.model)
	ent:SetPos(data.pos)
	ent:SetAngles(data.angle)
	ent:Spawn()
	ent.LootData = data
	self.ActiveLoot = math.Clamp(self.ActiveLoot + 1,0,#LootItems)
	-- print(data.pos, data.model, ent)

	return ent
end

function GM:LootThink()
	if not (self:GetRound() == 1 and self.ActiveLoot < #LootItems and self.NextSpawnLoot < CurTime() and self:SpawnLootItem(LootItems[math.random(1,#LootItems)])) then return end
	self.NextSpawnLoot = CurTime() + math.random(15,30)
end

function GM:SaveLootData()
	-- ensure the folders are there
	if not file.Exists("murder/","DATA") then
		file.CreateDir("murder")
	end

	local mapName = game.GetMap()

	if not file.Exists("murder/" .. mapName .. "/","DATA") then
		file.CreateDir("murder/" .. mapName)
	end

	-- JSON!
	local jason = util.TableToJSON(LootItems)
	file.Write("murder/" .. mapName .. "/loot.txt",jason)
end

function GM:AddLootItem(ent)
	local data = {}
	data.model = ent:GetModel()
	data.material = ent:GetMaterial()
	data.pos = ent:GetPos()
	data.angle = ent:GetAngles()
	LootItems[#LootItems + 1] = data
end

local function giveMagnum(ply)
	-- if they already have the gun, drop the first and give them a new one
	if ply:HasWeapon("weapon_mu_magnum") then
		ply:DropWeapon(ply:GetWeapon("weapon_mu_magnum"))
	end

	if ply:GetTKer() then
		-- if they are penalised, drop the gun on the floor
		ply.TempGiveMagnum = true -- temporarily allow them to pickup the gun
		ply:Give("weapon_mu_magnum")
		ply:DropWeapon(ply:GetWeapon("weapon_mu_magnum"))
	else
		ply:Give("weapon_mu_magnum")
		ply:SelectWeapon("weapon_mu_magnum")
	end
end

function GM:PlayerPickupLoot(ply,ent)
	ply.LootCollected = math.Clamp(ply.LootCollected + 1,0,255)

	if not ply:GetMurderer() and ply.LootCollected % 10 == 5 then
		giveMagnum(ply)
	end

	ply:EmitSound("ambient/levels/canals/windchime2.wav",100,math.random(40,160))
	ent:Remove()
	self.ActiveLoot = math.Clamp(self.ActiveLoot - 1,0,#LootItems)
	net.Start("GrabLoot")
	net.WriteUInt(ply.LootCollected,8)
	net.Send(ply)
end

function PlayerMeta:GetLootCollected()
	return self.LootCollected
end

function PlayerMeta:SetLootCollected(loot)
	self.LootCollected = loot
	net.Start("SetLoot")
	net.WriteUInt(self.LootCollected,8)
	net.Send(self)
end

local function getLootPrintString(data,plyPos)
	local str = math.Round(data.pos.x) .. "," .. math.Round(data.pos.y) .. "," .. math.Round(data.pos.z) .. " " .. math.Round(data.pos:Distance(plyPos) / 12) .. "ft"
	str = str .. " " .. data.model

	return str
end

concommand.Add("mu_loot_add",function(ply,_,args,_)
	if not ply:IsAdmin() then return end

	if #args < 1 then
		ply:ChatPrint("Too few args (model)")

		return
	end

	local mdl = args[1]
	local name = args[1]:lower()

	if name == "rand" or name == "random" then
		mdl = table.Random(LootModels)
	elseif name == "fruit" then
		mdl = table.Random(FruitModels)
	elseif not name:find("%.mdl$") then
		if not LootModels[name] then
			ply:ChatPrint("Invalid model alias " .. name)

			return
		end

		mdl = LootModels[name]
	end

	local data = {}
	data.model = mdl
	data.pos = ply:GetEyeTrace().HitPos
	data.angle = ply:GetAngles() * 1
	data.angle.p = 0
	LootItems[#LootItems + 1] = data
	ply:ChatPrint("Added " .. #LootItems .. ": " .. getLootPrintString(data,ply:GetPos()))
	GAMEMODE:SaveLootData()
	local ent = GAMEMODE:SpawnLootItem(data)
	local mins = ent:OBBMins()
	local pos = ent:GetPos()
	pos.z = pos.z - mins.z
	ent:SetPos(pos)
	data.pos = pos
	GAMEMODE:SaveLootData()
end)

concommand.Add("mu_loot_list",function(ply,_,args)
	if not ply:IsAdmin() then return end

	if #args < 0 then
		ply:ChatPrint("Too few args ()")

		return
	end

	ply:ChatPrint("Loot items ")

	for k,pos in ipairs(LootItems) do
		ply:ChatPrint(k .. ": " .. getLootPrintString(pos,ply:GetPos()))
	end
end)

concommand.Add("mu_loot_closest",function(ply,_,args)
	if not ply:IsAdmin() then return end

	if #args < 0 then
		ply:ChatPrint("Too few args ()")

		return
	end

	if #LootItems <= 0 then
		ply:ChatPrint("Loot list is empty")

		return
	end

	local closest

	for k,data in ipairs(LootItems) do
		if not closest or LootItems[closest].pos:Distance(ply:GetPos()) > data.pos:Distance(ply:GetPos()) then
			closest = k
		end
	end

	ply:ChatPrint(closest .. ": " .. getLootPrintString(LootItems[closest],ply:GetPos()))
end)

concommand.Add("mu_loot_remove",function(ply,_,args)
	if not ply:IsAdmin() then return end

	if #args < 1 then
		ply:ChatPrint("Too few args (key)")

		return
	end

	local key = tonumber(args[1]) or 0

	if not LootItems[key] then
		ply:ChatPrint("Invalid key, position inexists")

		return
	end

	local data = LootItems[key]
	LootItems[key] = nil
	ply:ChatPrint("Remove " .. key .. ": " .. getLootPrintString(data,ply:GetPos()))
	GAMEMODE:SaveLootData()
end)

local MdlColor = Color(255,125,255)
local PosColor = Color(200,0,0)
local AngColor = Color(255,244,0)

concommand.Add("mu_whats_this",function(ply)
	if not ply:IsAdmin() then return end
	local ent = ply:GetEyeTrace().Entity
	print(ent)

	if IsValid(ent) then
		local data = ent:GetKeyValues()
		local name = ent:GetName()
		local model = ent:GetModel()
		local pos = ent:GetPos()
		local angle = ent:GetAngles()
		local c = ChatText()
		c:Add(name)
		c:Add("Model: ")
		c:Add(model,MdlColor)
		c:Add("\nPos: ")
		c:Add(tostring(pos),PosColor)
		c:Add("\nAngle: ")
		c:Add(tostring(angle),AngColor)
		c:Add("\nClass: " .. data.classname)
		c:Add("\nHammer_ID: " .. data.hammerid)
		c:Send(ply)
	end
end)

concommand.Add("mu_loot_adjustpos",function(ply,_,args)
	if not ply:IsAdmin() then return end

	if #args < 0 then
		ply:ChatPrint("Too few args ()")

		return
	end

	local key
	local ent = ply:GetEyeTrace().Entity

	if IsValid(ent) and ent:GetClass() == "mu_loot" and ent.LootData then
		for k,v in ipairs(LootItems) do
			if v == ent.LootData then
				key = k
			end
		end
	end

	if not key then
		ply:ChatPrint("Not a loot item")

		return
	end

	ent.LootData.pos = ent:GetPos()
	ent.LootData.angle = ent:GetAngles()
	ply:ChatPrint("Adjusted " .. key .. ": " .. getLootPrintString(ent.LootData,ply:GetPos()))
	GAMEMODE:SaveLootData()
end)

concommand.Add("mu_loot_respawn",function(ply)
	if not ply:IsAdmin() then return end
	GAMEMODE:SpawnLoot()
end)

concommand.Add("mu_loot_models_list",function(ply)
	if not ply:IsAdmin() then return end
	ply:ChatPrint("Loot models")

	for alias,model in pairs(LootModels) do
		ply:ChatPrint(alias .. ": " .. model)
	end
end)
