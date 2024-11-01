net.Receive("spectating_status",function()
	GAMEMODE.SpectateMode = net.ReadInt(8)
	GAMEMODE.Spectating = false
	GAMEMODE.Spectatee = nil

	if GAMEMODE.SpectateMode >= 0 then
		GAMEMODE.Spectating = true
		GAMEMODE.Spectatee = net.ReadEntity()
	end
end)

function GM:IsCSpectating()
	return self.Spectating
end

function GM:GetCSpectatee()
	return self.Spectatee
end

function GM:GetCSpectateMode()
	return self.SpectateMode
end

local function drawTextShadow(t,f,x,y,c,px,py)
	color_black.a = c.a
	draw.SimpleText(t,f,x + 1,y + 1,color_black,px,py)
	draw.SimpleText(t,f,x,y,c,px,py)
	color_black.a = 255
end

function GM:RenderSpectate()
	if self:IsCSpectating() then
		local textpos = ScrW() / 2,ScrH() - 30 - draw.GetFontHeight("MersRadial")
		drawTextShadow(translate.spectating,"MersRadial",textpos * 2,self.CommonColors["Team_Bystander"],1)
		local client = LocalPlayer()
		local spectating = self:GetCSpectatee()

		if IsValid(spectating) and spectating:IsPlayer() then
			if IsValid(client) and client:IsAdmin() then
				drawTextShadow(spectating:Nick(),"MersRadialSmall",textpos,color_white,1)
			end

			if self.DrawGameHUD and GAMEMODE.ShowSpectateInfo:GetBool() then
				self:DrawGameHUD(spectating)
			end
		end
	end
end
