local rEndMenu

local colors = {
	["menuBg"] = Color(40,40,40),
	["menuIsDown"] = Color(180,180,180),
	["menuHovered"] = Color(220,220,220),
	["winnerPnlBg"] = Color(50,50,50)
}

function GM:DisplayEndRoundBoard(data)
	if IsValid(rEndMenu) then
		rEndMenu:Remove()
	end

	rEndMenu = vgui.Create("DFrame")
	rEndMenu:SetSize(ScrW() * 0.8,ScrH() * 0.8)
	rEndMenu:Center()
	rEndMenu:SetTitle("")
	rEndMenu:MakePopup()
	rEndMenu:SetKeyboardInputEnabled(false)
	rEndMenu:SetDeleteOnClose(false)

	function rEndMenu:Paint()
		surface.SetDrawColor(colors.menuBg)
		surface.DrawRect(0,0,rEndMenu:GetWide(),rEndMenu:GetTall())
	end

	local winnerPnl = vgui.Create("DPanel",rEndMenu)
	winnerPnl:DockPadding(24,24,24,24)
	winnerPnl:Dock(TOP)

	function winnerPnl:PerformLayout()
		self:SizeToChildren(false,true)
	end

	function winnerPnl:Paint(w,h)
		surface.SetDrawColor(colors.winnerPnlBg)
		surface.DrawRect(2,2,w - 4,h - 4)
	end

	local winner = vgui.Create("DLabel",winnerPnl)
	winner:Dock(TOP)
	winner:SetFont("MersRadialBig")
	winner:SetAutoStretchVertical(true)

	if data.reason == 3 then
		winner:SetText(translate.endroundMurdererQuit)
		winner:SetTextColor(color_white)
	elseif data.reason == 2 then
		winner:SetText(translate.endroundBystandersWin)
		winner:SetTextColor(self.CommonColors["Team_Bystander"])
	elseif data.reason == 1 then
		winner:SetText(translate.endroundMurdererWins)
		winner:SetTextColor(self.CommonColors["Team_Murderer"])
	end

	local murdererPnl = vgui.Create("DPanel",winnerPnl)
	murdererPnl:Dock(TOP)
	murdererPnl:SetTall(draw.GetFontHeight("MersRadialSmall"))

	function murdererPnl:Paint()
	end

	local msgs = Translator:AdvVarTranslate(translate.endroundMurdererWas,{
		murderer = {
			text = data.murderer.byName .. data.murderer.realName,
			color = data.murderer.color
		}
	})

	for _,msg in ipairs(msgs) do
		local was = vgui.Create("DLabel",murdererPnl)
		was:Dock(LEFT)
		was:SetText(msg.text)
		was:SetFont("MersRadialSmall")
		was:SetTextColor(msg.color or color_white)
		was:SetAutoStretchVertical(true)
		was:SizeToContentsX()
	end

	local lootPnl = vgui.Create("DPanel",rEndMenu)
	lootPnl:Dock(FILL)
	lootPnl:DockPadding(24,24,24,24)

	function lootPnl:Paint(w,h)
		surface.SetDrawColor(colors.winnerPnlBg)
		surface.DrawRect(2,2,w - 4,h - 4)
	end

	local desc = vgui.Create("DLabel",lootPnl)
	desc:Dock(TOP)
	desc:SetFont("MersRadial")
	desc:SetAutoStretchVertical(true)
	desc:SetText(translate.endroundLootCollected)
	desc:SetTextColor(color_white)
	local lootList = vgui.Create("DPanelList",lootPnl)
	lootList:Dock(FILL)
	table.sort(data.collectedLoot,function(a,b) return a.lootCount > b.lootCount end)

	for _,v in ipairs(data.collectedLoot) do
		if not v.realName then continue end
		local pnl = vgui.Create("DPanel")
		pnl:SetTall(draw.GetFontHeight("MersRadialSmall"))

		function pnl:Paint()
		end

		function pnl:PerformLayout()
			if self.NamePnl then
				self.NamePnl:SetWidth(self:GetWide() * 0.5)
			end

			if self.BNamePnl then
				self.BNamePnl:SetWidth(self:GetWide() * 0.3)
			end

			self:SizeToChildren(false,true)
		end

		local name = vgui.Create("DButton",pnl)
		pnl.NamePnl = name
		name:Dock(LEFT)
		name:SetAutoStretchVertical(true)
		name:SetText(v.realName)
		name:SetFont("MersRadialSmall")
		name:SetTextColor(v.color)
		name:SetContentAlignment(4)

		function name:Paint()
		end

		function name:DoClick()
			if IsValid(v.ply) then
				GAMEMODE:DoScoreboardActionPopup(v.ply)
			end
		end

		local bname = vgui.Create("DButton",pnl)
		pnl.BNamePnl = bname
		bname:Dock(LEFT)
		bname:SetAutoStretchVertical(true)
		bname:SetText(v.byName)
		bname:SetFont("MersRadialSmall")
		bname:SetTextColor(v.color)
		bname:SetContentAlignment(4)

		function bname:Paint()
		end

		bname.DoClick = name.DoClick
		local count = vgui.Create("DLabel",pnl)
		pnl.CountPnl = count
		count:Dock(FILL)
		count:SetAutoStretchVertical(true)
		count:SetText(tostring(v.lootCount))
		count:SetFont("MersRadialSmall")
		count:SetTextColor(v.color)
		count.DoClick = count.DoClick
		lootList:AddItem(pnl)
	end

	local add = vgui.Create("DButton",rEndMenu)
	add:Dock(BOTTOM)
	add:SetTall(64)
	add:SetText("")
	local mat = Material("murder/melon_logo_scoreboard.png","noclamp")

	function add:Paint(_,h)
		surface.SetMaterial(mat)

		if self:IsDown() then
			surface.SetDrawColor(colors.menuIsDown)
			surface.SetTextColor(colors.menuIsDown)
		elseif self.Hovered then
			surface.SetDrawColor(colors.menuHovered)
			surface.SetTextColor(colors.menuHovered)
		else
			surface.SetDrawColor(color_white)
			surface.SetTextColor(color_white)
		end

		local t = translate.adMelonbomberWhy
		surface.SetFont("MersRadialSmall")
		local tw,th = surface.GetTextSize(t)
		surface.SetTextPos(4,h / 2 - th / 2)
		surface.DrawText(t)
		surface.DrawTexturedRect(4 + tw + 4,0,324,64)
		surface.SetTextPos(4 + tw + 4 + 324 + 4,h / 2 - th / 2)
		surface.DrawText(translate.adMelonbomberBy)
	end

	function add:DoClick()
		gui.OpenURL("http://steamcommunity.com/sharedfiles/filedetails/?id=237537750")
		surface.PlaySound("UI/buttonclick.wav")
	end
end

net.Receive("reopen_round_board",function()
	if IsValid(rEndMenu) then
		rEndMenu:SetVisible(true)
	end
end)

function GM:CloseEndRoundBoard()
	if IsValid(rEndMenu) then
		rEndMenu:Close()
	end
end

concommand.Add("+menu_context",function()
	hook.Run("CloseEndRoundBoard")
end)
