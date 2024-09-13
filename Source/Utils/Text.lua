function PQLSetFont(frame, params)
    local type = params.type or 1
    local size = params.size or 14
    local color = params.color or {1, 1, 1, 1}

    local font

    if type == 1 then
        font = PQLPath("Fonts\\Roboto-Regular.ttf")
    end

    frame:SetFont(font, size, "")
    frame:SetTextColor(unpack(color))

    if params.text then
        frame:SetText(params.text)
    end

    if params.justify then
        frame:SetJustifyH(params.justify)
    end

    if params.align then
        frame:SetJustifyV(params.align)
    end
end
