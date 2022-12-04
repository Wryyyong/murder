function GM:EnsureTablesExist()
	if sql.TableExists("mu_maps") and sql.TableExists("mu_models") and sql.TableExists("mu_spawns") and sql.TableExists("mu_loots") then
		Msg("tables already exist !")
	else
		--! = not
		if not sql.TableExists("mu_maps") then
			query = "CREATE TABLE mu_maps (	id INTEGER NOT NULL UNIQUE, name TEXT NOT NULL UNIQUE,	PRIMARY KEY(id AUTOINCREMENT))"
			result = sql.Query(query)

			if sql.TableExists("mu_maps") then
				Msg("Success! mu_maps table created \n")
			else
				Msg("Something went wrong with the mu_maps query ! \n")
				Msg(sql.LastError(result) .. "\n")
			end
		end

		if not sql.TableExists("mu_models") then
			query = "CREATE TABLE mu_models (id INTEGER NOT NULL UNIQUE, alias TEXT NOT NULL UNIQUE, file	TEXT NOT NULL UNIQUE,PRIMARY KEY(id AUTOINCREMENT))"
			result = sql.Query(query)

			if sql.TableExists("mu_maps") then
				Msg("Success! mu_models table created \n")
				fillDefaultModels()
			else
				Msg("Something went wrong with the mu_models query ! \n")
				Msg(sql.LastError(result) .. "\n")
			end
		end

		if not sql.TableExists("mu_spawns") then
			query = "CREATE TABLE mu_spawns (id INTEGER NOT NULL UNIQUE, map_id INTEGER NOT NULL, x DOUBLE NOT NULL, y DOUBLE NOT NULL, z DOUBLE NOT NULL, FOREIGN KEY(map_id) REFERENCES mu_maps(id), PRIMARY KEY(id AUTOINCREMENT))"
			result = sql.Query(query)

			if sql.TableExists("mu_spawns") then
				Msg("Success! mu_spawns table created \n")
			else
				Msg("Something went wrong with the mu_spawns query ! \n")
				Msg(sql.LastError(result) .. "\n")
			end
		end

		if not sql.TableExists("mu_loots") then
			query = "CREATE TABLE mu_loots (id INTEGER NOT NULL UNIQUE, map_id INTEGER NOT NULL, model_id INTEGER NOT NULL, x DOUBLE NOT NULL, y DOUBLE NOT NULL, z DOUBLE NOT NULL, a_x DOUBLE NOT NULL, a_y DOUBLE NOT NULL, a_z DOUBLE NOT NULL, PRIMARY KEY(id AUTOINCREMENT), FOREIGN KEY(map_id) REFERENCES mu_maps(id), FOREIGN KEY(model_id) REFERENCES mu_models(id))"
			result = sql.Query(query)

			if sql.TableExists("mu_loots") then
				Msg("Success! mu_loots table created \n")
			else
				Msg("Something went wrong with the mu_loots query ! \n")
				Msg(sql.LastError(result) .. "\n")
			end
		end
		-- if (!sql.TableExists("mu_players")) then
		-- 	-- Create the table here
		-- end
	end
end

function fillDefaultModels()
	Msg("Adding default models to table. \n")
	query = [[INSERT INTO mu_models(alias, file) VALUES ("breenbust", "models/props_combine/breenbust.mdl"),
			("huladoll", "models/props_lab/huladoll.mdl"),
			("beer1", "models/props_junk/glassbottle01a.mdl"),
			("beer2", "models/props_junk/glassjug01.mdl"),
			("cactus", "models/props_lab/cactus.mdl"),
			("lamp", "models/props_lab/desklamp01.mdl"),
			("clipboard", "models/props_lab/clipboard.mdl"),
			("suitcase1", "models/props_c17/suitcase_passenger_physics.mdl"),
			("suitcase2", "models/props_c17/suitcase001a.mdl"),
			("battery", "models/items/car_battery01.mdl"),
			("turtle", "models/props/de_tides/vending_turtle.mdl"),
			("toothbrush", "models/props/cs_militia/toothbrushset01.mdl"),
			("circlesaw", "models/props/cs_militia/circularsaw01.mdl"),
			("axe", "models/props/cs_militia/axe.mdl"),
			("skull", "models/Gibs/HGIBS.mdl"),
			("baby", "models/props_c17/doll01.mdl"),
			("antlionhead", "models/Gibs/Antlion_gib_Large_2.mdl"),
			("briefcase", "models/props_c17/BriefCase001a.mdl"),
			("breenclock", "models/props_combine/breenclock.mdl"),
			("sawblade", "models/props_junk/sawblade001a.mdl"),
			("wrench", "models/props_c17/tools_wrench01a.mdl"),
			("consolebox", "models/props_c17/consolebox01a.mdl"),
			("cashregister", "models/props_c17/cashregister01a.mdl"),
			("bananabunch", "models/props/cs_italy/bananna_bunch.mdl"),
			("banana", "models/props/cs_italy/bananna.mdl"),
			("orange", "models/props/cs_italy/orange.mdl"),
			("familyphoto", "models/props_	lab/frame002a.mdl")]]
	result = sql.Query(query)

	if result ~= false then
		Msg("Success! Added models to table \n")
	else
		Msg("Something went wrong with adding models! \n")
		Msg(sql.LastError(result) .. "\n")
	end
end
