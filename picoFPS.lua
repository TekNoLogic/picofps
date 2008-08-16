
------------------------------
--      Are you local?      --
------------------------------

local UPDATEPERIOD, MEMTHRESH = 0.5, 32
local prevmem, elapsed, tipshown = collectgarbage("count"), 0.5
local string_format, math_modf, GetNetStats, GetFramerate, collectgarbage = string.format, math.modf, GetNetStats, GetFramerate, collectgarbage

local addons = {}
for i=1,GetNumAddOns() do table.insert(addons, (GetAddOnInfo(i))) end
table.sort(addons, function(a,b) return a and b and a:lower() < b:lower() end)


local function ColorGradient(perc, r1, g1, b1, r2, g2, b2, r3, g3, b3)
	if perc >= 1 then return r3, g3, b3 elseif perc <= 0 then return r1, g1, b1 end

	local segment, relperc = math_modf(perc*2)
	if segment == 1 then r1, g1, b1, r2, g2, b2 = r2, g2, b2, r3, g3, b3 end
	return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
end


-------------------------------------------
--      Namespace and all that shit      --
-------------------------------------------

local f = CreateFrame("frame")
local dataobj = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("picoFPS", {text = "75.0 FPS", OnClick = function() collectgarbage("collect") end})
local about = LibStub("tekKonfig-AboutPanel").new(nil, "picoFPS")


--------------------------------
--      OnUpdate Handler      --
--------------------------------

f:SetScript("OnUpdate", function(self, elap)
	elapsed = elapsed + elap
	if elapsed < UPDATEPERIOD then return end

	elapsed = 0
	local fps = GetFramerate()
	local r, g, b = ColorGradient(fps/75, 1,0,0, 1,1,0, 0,1,0)
	dataobj.text = string_format("|cff%02x%02x%02x%.1f|r FPS", r*255, g*255, b*255, fps)

	if tipshown then dataobj.OnEnter(tipshown) end
end)


------------------------
--      Tooltip!      --
------------------------

local function GetTipAnchor(frame)
	local x,y = frame:GetCenter()
	if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
	local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end


function dataobj.OnLeave()
	GameTooltip:Hide()
	tipshown = nil
end


function dataobj.OnEnter(self)
	tipshown = self
 	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint(GetTipAnchor(self))
	GameTooltip:ClearLines()

	GameTooltip:AddLine("picoFPS")

	local fps = GetFramerate()
	local r, g, b = ColorGradient(fps/75, 1,0,0, 1,1,0, 0,1,0)
	GameTooltip:AddDoubleLine("FPS:", string_format("%.1f", fps), nil,nil,nil, r,g,b)

	local _, _, lag = GetNetStats()
	local r, g, b = ColorGradient(lag/1000, 0,1,0, 1,1,0, 1,0,0)
	GameTooltip:AddDoubleLine("Lag:", lag.. " ms", nil,nil,nil, r,g,b)

	GameTooltip:AddLine(" ")

	local addonmem = 0
	UpdateAddOnMemoryUsage()
	for i,name in ipairs(addons) do
		local mem = GetAddOnMemoryUsage(name)
		addonmem = addonmem + mem
		if mem > MEMTHRESH then
			local r, g, b = ColorGradient((mem - MEMTHRESH)/768, 0,1,0, 1,1,0, 1,0,0)
			local memstr = mem > 1024 and string_format("%.1f MiB", mem/1024) or string_format("%.1f KiB", mem)
			GameTooltip:AddDoubleLine(name, memstr, 1,1,1, r,g,b)
		end
	end
	local r, g, b = ColorGradient(addonmem/(40*1024), 0,1,0, 1,1,0, 1,0,0)
	GameTooltip:AddDoubleLine("Addon memory:", string_format("%.2f MiB", addonmem/1024), nil,nil,nil, r,g,b)

	local mem = collectgarbage("count")
	local deltamem = mem - prevmem
	prevmem = mem
	local r, g, b = ColorGradient(mem/(20*1024), 0,1,0, 1,1,0, 1,0,0)
	GameTooltip:AddDoubleLine("Default UI memory:", string_format("%.2f MiB", (mem-addonmem)/1024), nil,nil,nil, r,g,b)

	local r, g, b = ColorGradient(deltamem/15, 0,1,0, 1,1,0, 1,0,0)
	GameTooltip:AddDoubleLine("Garbage churn:", string_format("%.2f KiB/sec", deltamem), nil,nil,nil, r,g,b)

	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("Click to force garbage collection")

	GameTooltip:Show()
end
