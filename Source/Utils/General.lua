function PQLPath(to)
    return "Interface\\Addons\\PersonalQuestLog\\"..to
end

function PQLArt(file)
	return PQLPath("Art\\Themes\\"..PQL.db.profile.theme.."\\"..file)
end

function PQLPrepareForText(frame)
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT")
    frame:SetSize(500, 500)
end

function PQLSetPoints(frame, points)
    if points and type(points) == "table" then
        if type(points[1]) == "table" then
            for _, anchor in ipairs(points) do
                frame:SetPoint(unpack(anchor))
            end
        else
            frame:SetPoint(unpack(points))
        end
    end
end

function PQLAnchorTooltip(anchorTo)
	GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint("BOTTOMRIGHT", anchorTo, "TOPLEFT", -5, 5)
end

function PQLShowTooltip(tooltip, anchorTo)
	if anchorTo then PQLAnchorTooltip(anchorTo) end

	if tooltip.title then
		if type(tooltip.title) == "function" then
			tooltip.title = tooltip.title()
		end

		if type(tooltip.title) == "string" then
			GameTooltip:AddLine(tooltip.title)
		end
	end

	if tooltip.body then
		if type(tooltip.body) == "function" then
			tooltip.body = tooltip.body()
		end
		
		if type(tooltip.body) == "table" then
			for _, line in ipairs(tooltip.body) do
				if type(line) == "string" then
					line = {line, 0.9, 0.9, 0.9, true}
				end

				GameTooltip:AddLine(unpack(line))
			end
		elseif type(tooltip.body) == "string" then
			GameTooltip:AddLine(tooltip.body, 0.9, 0.9, 0.9, true)
		end
	end

	GameTooltip:Show()
end

