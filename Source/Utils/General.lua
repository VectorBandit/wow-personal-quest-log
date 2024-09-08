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

function PQLAttachTooltip(anchorTo)
	GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint("BOTTOMRIGHT", anchorTo, "TOPLEFT", -5, 5)
end

