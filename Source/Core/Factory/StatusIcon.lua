PQL.FACTORY.StatusIcon = {}

function PQL.FACTORY.StatusIcon:Create(parent, params)
    local icon = parent:CreateTexture(nil, "ARTWORK")

    icon:SetSize(params.size or 12, params.size or 12)
    icon:SetTexture(PQLArt("Status-"..params.icon..".png"))

    if params.anchor then
        PQLSetPoints(icon, params.anchor)
    end

    function icon:SetStatus(isToggled)
        if isToggled then
            icon:SetTexCoord(0.5, 1, 0, 1)
        else
            icon:SetTexCoord(0, 0.5, 0, 1)
        end
    end

	icon:SetStatus(params.status)

    return icon
end
